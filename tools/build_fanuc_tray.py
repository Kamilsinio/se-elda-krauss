"""Generate BOX/TRAY production, COMMON and BG LS. No device access or taught coordinates."""
from __future__ import annotations
import argparse
import csv
import io
import json
import re
from pathlib import Path
import build_fanuc_comm

ROOT=Path(__file__).resolve().parents[1]
CFG=[*[f'mask{i}' for i in range(1,6)],*[f'qty{i}' for i in range(1,6)],
     'gridX','gridY','pitchX','pitchY','trayHeight','traysPerStack',
     'searchStep','searchLimit','maxAttempts','speed','timeout','tool','frame',
     'cylFold','cylStraight','trayMask']
RUNTIME=['state','dispatch','lastState','phaseSince','cycleId','batchCount','remaining',
         'group','slot','trayIndex','stackId','lastStart','mask','qty','searchDepth',
         'attempt','destination','work','sum','capacity','groupCount','resumeState']
FLAGS=['initApproved','newApproved','recoveryApproved','contextChecked','stationIdleConfirmed',
       'profileApproved','motionApproved','alarmApproved','bindingsVerified','sourceBound',
       'statusValid','cfgApplied','candidateValid','selected','armed','needsRecovery',
       'batchAssigned','pickupConfirmed','trayReady','motionDone','safe','deviceDone',
       'eventDone','cylDone','vacDone','releaseDone','sourceExited','elevatorExited',
       'storageExited','immExited','cycleExecuting','applyDenied','guardFault','timeoutFault',
       'maskValid','samplePending','cfgFrozen','booted','sourceInside','elevatorInside','releasing','fullStackWait','guardLoaded','guardReleasing','orderWasActive','statusRouteStable']
RAW=['autoMode','t1Mode','t2Mode','tpEnabled','systemReady','estopActive','fault',
     'inputSimulated','outputSimulated','home','taskRunning','taskPaused']
POINTS={1:'HOME',2:'SOURCE_ENTRY',3:'SOURCE_APPROACH',4:'SOURCE_SEARCH_START',
        5:'SOURCE_SEARCH_LIMIT',6:'SOURCE_LIFT',7:'SOURCE_EXIT',8:'ELEVATOR_ENTRY',
        9:'TRAY_APPROACH',10:'TRAY_PLACE',11:'ELEVATOR_EXIT',12:'IMM_ENTRY',
        13:'IMM_WAIT',14:'IMM_APPROACH',15:'IMM_PICK',16:'IMM_RETRACT',17:'IMM_EXIT',
        **{18+i:f'PRODUCT_GROUP_{i+1}' for i in range(5)},23:'PRODUCT_APPROACH',
        **{24+i:f'SAMPLE_GROUP_{i+1}' for i in range(5)},29:'OFFSET_WORK',
        30:'SEARCH_WORK',31:'POSE_WORK',32:'SAMPLE_ENTRY',33:'SAMPLE_EXIT',
        34:'HOME_ENTRY',35:'TRAY_LIFT',**{i:'RESERVE' for i in range(36,41)}}


def template(mode="TRAY"):
    from fanuc_box import configure, extend
    CFG, RUNTIME, FLAGS, POINTS = configure(mode)
    cr=json.loads(build_fanuc_comm.build()[ROOT/'ROBOT/COMM/resources.json'])
    c=cr['controls'];rx=cr['rx'];app=cr['application']
    channels={ch['name']:ch for ch in cr['channels']}
    binding=json.loads((ROOT/'ROBOT/BG/bindings.json').read_text(encoding='utf-8'))
    available=(list(range(1,51))+list(range(177,201))) if mode=="TRAY" else list(range(201,331));alloc=[]
    def reg(name):
        n=available.pop(0);alloc.append(dict(name=name,bank='R',number=n));return f'R[{n}]'
    staging={n:reg('staging.'+n) for n in CFG}
    active={n:reg('active.'+n) for n in CFG}
    p={n:reg('runtime.'+n) for n in RUNTIME}
    assert mode!="TRAY" or not available
    fnum=1 if mode=="TRAY" else 101
    def flag(name):
        nonlocal fnum
        n=fnum;fnum+=1;alloc.append(dict(name=name,bank='F',number=n));return f'F[{n}]'
    b={n:flag('control.'+n) for n in FLAGS}
    raw={n:flag('native.'+n) for n in RAW}
    taught={str(i):flag('taught.PR'+str(i)) for i in range(1,41)}
    # Dwa rejestry zegara/wyniku TEST mają jawne aliasy monitorów w LIVE.
    bg={'statusAt':c['mockClock'],'guardAt':c['testResult']}
    artifacts={};states={}
    def ls(name,lines,folder='TRAY',motion=False):
        body=['/PROG '+name,'/ATTR','OWNER = MNEDITOR;','COMMENT = "Krauss tacki";',
              'PROTECT = READ_WRITE;','DEFAULT_GROUP = '+('1' if motion else '*')+',*,*,*,*;',
              'CONTROL_CODE = 00000000 00000000;','/MN']
        body += [f'{i:4}:  {line} ;' for i,line in enumerate(lines,1)]
        body += ['/POS','/END']
        artifacts[ROOT/'ROBOT'/folder/(name+'.LS')]='\n'.join(body)+'\n'
    def put(ref,val):return f'{ref}=({val})'
    def yes(ref):return put(ref,'ON')
    def no(ref):return put(ref,'OFF')
    def iff(cond,stmt):return f'IF ({cond}),{stmt}'
    def goto(n):return put(p['state'],n)
    def fail(code):return [iff(f"{p['state']}<>900",put(p['resumeState'],p['state'])),put(app['r2p.production.faultCode'],code),yes(b['needsRecovery']),yes(c['guardRequest']),goto(900)]
    def checked(lines,condition,code):
        lines += [iff('!('+condition+')',put(app['r2p.production.faultCode'],code)),
                  iff('!('+condition+')','JMP LBL[9000]')]
    def bit(mask,i):return f'(({mask} DIV {1<<i}) MOD 2)=1'
    def state(n,title,lines):states[n]=dict(title=title,lines=lines)
    def moved(name,n):return ['CALL '+name,iff(b['motionDone'],goto(n))]
    def wait(n):return put(app['r2p.production.waitCode'],n)

    lines=[iff('!'+b['initApproved'],'JMP LBL[999]'),
           iff(f"{b['selected']} AND {raw['taskRunning']}",'JMP LBL[999]'),
           iff(f"{app['r2p.production.loadKnown']} AND ({app['r2p.production.loadMask']}<>0)",'JMP LBL[999]')]
    for a in alloc:lines.append(put(f"{a['bank']}[{a['number']}]",'0' if a['bank']=='R' else 'OFF'))
    lines += ['CALL RB_BIND',no(c['productionRequired']),no(c['productionPermit']),no(c['guardRequest']),
              no(c['appArm']),no(app['r2p.production.loadKnown']),put(app['r2p.production.loadMask'],0),'LBL[999]']
    ls('RT_INIT',lines)

    # Zastosowanie tylko przy potwierdzonym postoju i zamkniętym zleceniu; ruch nie czyta nastaw roboczych.
    lines=[no(b['applyDenied']),yes(b['candidateValid'])]
    idle=f"!{rx['p2r.production.orderActive']} AND !{b['batchAssigned']} AND {b['stationIdleConfirmed']} AND !{b['trayReady']}"
    lines += [put(b['safe'],idle),put(b['safe'],f"{b['safe']} AND {c['session']} AND {b['statusValid']} AND {raw['home']}"),put(b['safe'],f"{b['safe']} AND {rx['p2r.imm.cycleKnown']} AND {rx['p2r.imm.settled']} AND !{rx['p2r.imm.pickupPending']}"),put(b['safe'],f"{b['safe']} AND ({rx['p2r.imm.unsettledCount']}=0) AND {app['r2p.production.loadKnown']} AND ({app['r2p.production.loadMask']}=0)")]
    idle=b['safe']
    lines += [iff('!('+idle+')',yes(b['applyDenied'])),iff(b['applyDenied'],'JMP LBL[999]')]
    for name in CFG:
        v=staging[name]
        cond=f'({v}<0) OR ({v}>65535)'
        if name not in ['pitchX','pitchY','trayHeight','searchStep','searchLimit','speed','productClearance','spacerClearance'] and not name.endswith(('pitchX','pitchY')):cond+=f' OR (({v} MOD 1)<>0)'
        if name in ['pitchX','pitchY'] or name.endswith(('pitchX','pitchY')):cond=f'({v}<-65535) OR ({v}>65535)'
        lines.append(iff(cond,no(b['candidateValid'])))
    for name in ['gridX','gridY','traysPerStack','trayHeight','searchStep','searchLimit','maxAttempts','speed','timeout','trayMask']:
        lines.append(iff(f"{staging[name]}<1",no(b['candidateValid'])))
    for cond in [f"{staging['gridX']}*{staging['gridY']}>65535",f"{staging['speed']}>100",
                 f"{staging['trayMask']}>31",f"{staging['searchStep']}>{staging['searchLimit']}",f"{staging['searchStep']}>{staging['trayHeight']}"]:
        lines.append(iff(cond,no(b['candidateValid'])))
    lines += [put(p['groupCount'],0),put(p['sum'],0)]
    for i in range(1,6):
        m=staging[f'mask{i}'];q=staging[f'qty{i}']
        lines += [iff(f'({m}>31) OR (({m}=0) AND ({q}<>0)) OR (({m}<>0) AND ({q}=0))',no(b['candidateValid'])),
                  iff(f'{q}>0',put(p['groupCount'],p['groupCount']+'+1')),put(p['sum'],p['sum']+'+'+q)]
    for i in range(5):
        lines.append(put(p['work'],0))
        for m in [staging[f'mask{j}'] for j in range(1,6)]+[staging['trayMask']]:
            lines.append(iff(bit(m,i),put(p['work'],p['work']+'+1')))
        lines.append(iff(f"{p['work']}>1",no(b['candidateValid'])))
    for name in ['cylFold','cylStraight']:
        v=staging[name];lines.append(iff(f'({v}<1) OR ({v}>1023)',no(b['candidateValid'])))
        for i in range(5):lines.append(iff(f'({bit(v,i)}) AND ({bit(v,i+5)})',no(b['candidateValid'])))
    for name in ['cylFold','cylStraight']:
        lines.append(iff(f"!({bit(staging[name],0)}) AND !({bit(staging[name],5)})",no(b['candidateValid'])))
    lines.append(iff(f"({staging['cylFold']} MOD 2)=({staging['cylStraight']} MOD 2)",no(b['candidateValid'])))
    lines += [iff(f"({p['groupCount']}<1) OR ({p['sum']}<1) OR ({p['sum']}>65535)",no(b['candidateValid'])),
              iff('!'+b['candidateValid'],'JMP LBL[9000]'),
              iff(f"({staging['gridX']}*{staging['gridY']}) MOD {p['groupCount']}<>0",'JMP LBL[9000]')]
    for name in CFG:lines.append(put(active[name],staging[name]))
    lines += [yes(b['cfgApplied']),no(b['stationIdleConfirmed']),'JMP LBL[999]',
              'LBL[9000]',no(b['cfgApplied']),put(app['r2p.production.faultCode'],1001),'LBL[999]']
    ls('RT_APPLY',lines)

    complete=all(binding['sources'].get(n) for n in RAW)
    ls('RB_BIND',[put(b['sourceBound'],'ON' if complete else 'OFF')],folder='BG')
    lines=[]
    for name in RAW:
        source=binding['sources'].get(name)
        if source:
            refs=r'(?:\$[A-Za-z_][A-Za-z0-9_.$\[\]]*|(?:UO|SI|SO|F)\[\d+\])'
            assert re.search(refs,source),source
            remainder=re.sub(refs,' ',source)
            assert re.fullmatch(r'[\s0-9().!<>=+*/-]*(?:(?:AND|OR|MOD|DIV)[\s0-9().!<>=+*/-]*)*',remainder),source
            lines.append(put(raw[name],source))
    lines += [put(bg['statusAt'],'$FAST_CLOCK'),put(b['statusValid'],f"{b['sourceBound']} AND {b['bindingsVerified']}")]
    for name in RAW[:10]:lines.append(put(app['r2p.production.'+name],f"{raw[name]} AND {b['statusValid']}"))
    lines += [put(app['r2p.production.program'],0),iff(f"{b['selected']} AND {b['statusValid']} AND ({raw['taskRunning']} OR {raw['taskPaused']})",put(app['r2p.production.program'],2)),
              put(app['r2p.production.running'],f"{b['selected']} AND {raw['taskRunning']} AND !{raw['taskPaused']} AND {b['statusValid']}"),
              put(app['r2p.production.fault'],f"{app['r2p.production.fault']} OR {b['needsRecovery']}")]
    lines.append(put(b['statusRouteStable'],f"{b['selected']} AND {raw['autoMode']} AND !{raw['tpEnabled']} AND {raw['taskRunning']} AND !{raw['taskPaused']}"))
    for area,exited in [('source','sourceExited'),('elevator','elevatorExited'),('storage','storageExited')]:
        lines.append(put(app[f'r2p.area.{area}.clear'],f"{b['statusValid']} AND ({raw['home']} OR ({b[exited]} AND {b['statusRouteStable']})) AND !{b['needsRecovery']} AND !{app[f'r2p.area.{area}.accessReq']}"))
    for stamp in [bg['guardAt'],c['now']]:
        lines.append(iff(f"{b['armed']} AND {b['alarmApproved']} AND !{b['recoveryApproved']} AND ($FAST_CLOCK-{stamp}>{c['serviceTimeout']})",'UALM[1]'))
    ls('RB_STATUS',lines,folder='BG')
    lines=[put(bg['guardAt'],'$FAST_CLOCK'),put(c['productionPermit'],b['cfgApplied'])]
    for cond in [b['profileApproved'],b['motionApproved'],b['alarmApproved'],b['statusValid'],c['bgHealthy'],c['session'],
                 rx['p2r.production.orderActive'],rx['p2r.production.withRobot'],f"({rx['p2r.production.expectedProgram']}=2)",
                 f"({rx['p2r.production.newOperationPermit']} OR {rx['p2r.production.finishPermit']})",raw['autoMode'],'!'+raw['tpEnabled'],raw['systemReady'],'!'+raw['estopActive'],'!'+raw['fault'],
                 '!'+raw['inputSimulated'],'!'+raw['outputSimulated'],'!'+b['needsRecovery'],'!'+c['guardRequest']]:
        lines.append(put(c['productionPermit'],c['productionPermit']+' AND '+cond))
    lines += [put(b['cycleExecuting'],f"({p['state']}>=200) AND ({p['state']}<700)"),no(b['guardFault'])]
    for cond in ['!'+c['session'],rx['p2r.production.criticalBlock'],rx['p2r.production.recoveryRequired'],
                 '!'+b['statusValid'],raw['estopActive'],raw['fault'],raw['tpEnabled'],'!'+raw['autoMode'],
                 f"$FAST_CLOCK-{c['now']}>{c['serviceTimeout']}",f"$FAST_CLOCK-{bg['statusAt']}>{c['serviceTimeout']}"]:
        lines.append(iff(f"{b['armed']} AND ({cond})",yes(b['guardFault'])))
    lines.append(iff(f"{b['selected']} AND {b['statusValid']} AND !{raw['taskRunning']} AND !{raw['taskPaused']}",yes(b['guardFault'])))
    for condition in [f"!{rx['p2r.production.withRobot']}",f"!{rx['p2r.production.orderActive']}",f"{rx['p2r.production.expectedProgram']}<>2"]:
        lines.append(iff(f"{b['armed']} AND ({condition})",yes(b['guardFault'])))
    for condition in [f"!{raw['autoMode']}",raw['tpEnabled'],f"!{b['statusValid']}"]:
        lines.append(iff(f"{b['selected']} AND ({condition})",yes(b['guardFault'])))
    for v in range(501,506):
        lines.append(iff(f"{b['cycleExecuting']} AND ({app[f'r2p.cyl.V{v}.home']} OR {app[f'r2p.cyl.V{v}.work']}) AND !{rx[f'p2r.cyl.V{v}.valid']}",yes(b['guardFault'])))
        lines.append(iff(f"{b['cycleExecuting']} AND {rx[f'p2r.cyl.V{v}.atHome']} AND {rx[f'p2r.cyl.V{v}.atWork']}",yes(b['guardFault'])))
    for i in range(5):
        lines += [put(b['guardLoaded'],f"{b['cycleExecuting']} AND {app['r2p.production.loadKnown']} AND ({bit(app['r2p.production.loadMask'],i)})"),
                  put(b['guardReleasing'],f"{b['releasing']} AND ({bit(p['mask'],i)})"),
                  iff(f"{b['guardLoaded']} AND !{rx[f'p2r.vac.{i+1}.valid']}",yes(b['guardFault'])),
                  iff(f"{b['guardLoaded']} AND !{rx[f'p2r.vac.{i+1}.ok']} AND !{b['guardReleasing']}",yes(b['guardFault']))]
    for field in [f'mask{i}' for i in range(1,6)]+['trayMask']:
        for i in range(5):lines.append(iff(f"{b['armed']} AND ({bit(active[field],i)}) AND !{rx[f'p2r.vac.{i+1}.valid']}",yes(b['guardFault'])))
    for area,exited in [('source','sourceExited'),('elevator','elevatorExited')]:
        # Kontrola po wejściu: oczekiwanie na przyznanie dostępu nie jest alarmem.
        lines.append(iff(f"{b['cycleExecuting']} AND {app[f'r2p.area.{area}.accessReq']} AND {b['sourceInside'] if area=='source' else b['elevatorInside']} AND (!{rx[f'p2r.area.{area}.valid']} OR !{rx[f'p2r.area.{area}.granted']})",yes(b['guardFault'])))
    lines += [iff(f"{b['guardFault']} AND ({app['r2p.production.faultCode']}=0)",put(app['r2p.production.faultCode'],1800)),iff(b['guardFault'],yes(b['needsRecovery'])),iff(b['guardFault'],yes(c['guardRequest'])),
              iff(b['guardFault'],no(c['productionPermit'])),iff(b['guardFault'],no(c['appArm'])),iff(b['guardFault'],no(app['r2p.production.loadKnown']))]
    for name in ['sourceExited','elevatorExited','storageExited','immExited']:lines.append(iff(b['guardFault'],no(b[name])))
    lines.append(iff(f"{b['guardFault']} AND {b['alarmApproved']} AND !{raw['fault']} AND !{b['recoveryApproved']}",'UALM[1]'))
    ls('RB_GUARD',lines,folder='BG')

    # Kontrola przed każdym ruchem, również wewnątrz procedury.
    lines=[put(b['safe'],c['productionPermit'])]
    for cond in [c['allowCommands'],c['appArm'],b['armed'],'!'+c['guardRequest'],'!'+b['needsRecovery']]:
        lines.append(put(b['safe'],b['safe']+' AND '+cond))
    for field in [f'mask{i}' for i in range(1,6)]+['trayMask']:
        for i in range(5):lines.append(iff(f"({bit(active[field],i)}) AND !{rx[f'p2r.vac.{i+1}.valid']}",no(b['safe'])))
    lines += [iff(b['safe'],'JMP LBL[999]')]+fail(1100)+['LBL[999]']
    ls('RT_SAFE',lines)
    def motion(name,points,offset=False,search=False):
        lines=[no(b['motionDone']),f"UTOOL_NUM={active['tool']}",f"UFRAME_NUM={active['frame']}"]
        for number,kind in points:
            lines += ['CALL RT_SAFE',iff('!'+b['safe'],'JMP LBL[999]'),
                      iff('!'+taught[str(number)],'JMP LBL[9000]')]
            if search:
                lines += [f"PR[30]=PR[{number}]",f"PR[30,3]=PR[{number},3]-{p['searchDepth']}"]
                lines += [iff('!'+taught['5'],'JMP LBL[9000]'),iff('PR[30,3]<PR[5,3]','JMP LBL[9000]')]
                target='PR[30]'
            else:target=f'PR[{number}]'
            speed=active['speed']+('%' if kind=='J' else 'mm/sec')
            lines.append(f'{kind} {target} {speed} FINE'+(' Offset,PR[29]' if offset else ''))
        lines += [yes(b['motionDone']),'JMP LBL[999]','LBL[9000]']+fail(1101)+['LBL[999]']
        ls(name,lines,motion=True)
    for name,points in {
        'RM_HOME':[(34,'J'),(1,'J')],'RM_SRCIN':[(2,'J'),(3,'L'),(4,'L')],
        'RM_SRCOUT':[(6,'L'),(7,'J')],'RM_TRAYIN':[(8,'J'),(9,'L'),(10,'L')],
        'RM_TRAYOUT':[(35,'L'),(11,'J')],'RM_IMMIN':[(12,'J'),(13,'L')],
        'RM_PICK':[(14,'L'),(15,'L')],'RM_RETRACT':[(16,'L')],'RM_IMMOUT':[(17,'L')],
        'RM_PLACEIN':[(8,'J'),(23,'L')],'RM_PLACEOUT':[(23,'L'),(11,'J')],
        'RM_SAMPLEIN':[(32,'J')],'RM_SAMPLEOUT':[(33,'J')]
    }.items():motion(name,points)
    motion('RM_SEARCH',[(4,'L')],search=True)
    for i in range(1,6):
        motion(f'RM_PROD{i}',[(17+i,'L')],offset=True)
        motion(f'RM_SAMP{i}',[(23+i,'L')])
    ls('RT_OFFSET',['PR[29]=LPOS-LPOS',
       f"PR[29,1]=({p['slot']} MOD {active['gridX']})*{active['pitchX']}",
       f"PR[29,2]=({p['slot']} DIV {active['gridX']})*{active['pitchY']}"],motion=True)

    for name,cfgname in [('RG_FOLD','cylFold'),('RG_STRAIGHT','cylStraight')]:
        lines=[yes(b['cylDone'])]
        for i in range(5):
            h=f'({bit(active[cfgname],i)})';w=f'({bit(active[cfgname],i+5)})';v=501+i
            lines += [put(app[f'r2p.cyl.V{v}.home'],h),put(app[f'r2p.cyl.V{v}.work'],w),
                      iff(f"({h} OR {w}) AND !{rx[f'p2r.cyl.V{v}.valid']}",no(b['cylDone'])),
                      iff(f"{h} AND (!{rx[f'p2r.cyl.V{v}.acceptedHome']} OR !{rx[f'p2r.cyl.V{v}.atHome']} OR {rx[f'p2r.cyl.V{v}.atWork']})",no(b['cylDone'])),
                      iff(f"{w} AND (!{rx[f'p2r.cyl.V{v}.acceptedWork']} OR !{rx[f'p2r.cyl.V{v}.atWork']} OR {rx[f'p2r.cyl.V{v}.atHome']})",no(b['cylDone']))]
        ls(name,lines)
    lines=[yes(b['vacDone'])]
    for i in range(5):
        selected=bit(p['mask'],i)
        lines += [iff(selected,yes(app[f'r2p.vac.{i+1}.cmdValid'])),
                  iff(selected,yes(app[f'r2p.vac.{i+1}.hold'])),
                  iff(f"({selected}) AND (!{rx[f'p2r.vac.{i+1}.valid']} OR !{rx[f'p2r.vac.{i+1}.accepted']} OR !{rx[f'p2r.vac.{i+1}.holdApplied']} OR !{rx[f'p2r.vac.{i+1}.ok']})",no(b['vacDone']))]
    ls('RG_VACON',lines)
    lines=[yes(b['releasing'])]
    for i in range(5):
        ch=channels[f'blow{i+1}'];selected=bit(p['mask'],i)
        lines += [iff(selected,yes(app[f'r2p.vac.{i+1}.cmdValid'])),
                  iff(selected,no(app[f'r2p.vac.{i+1}.hold'])),iff(selected,yes(ch['submit']))]
    ls('RG_RELEASE',lines)
    lines=[yes(b['releaseDone'])]
    for i in range(5):
        ch=channels[f'blow{i+1}'];selected=bit(p['mask'],i)
        good=f"({ch['state']}=0) AND ({ch['status']}=20) AND !{ch['submit']}"
        lines += [iff(f"({selected}) AND !({good})",no(b['releaseDone'])),
                  iff(f"({selected}) AND !{rx[f'p2r.vac.{i+1}.valid']}",no(b['releaseDone'])),
                  iff(f"({selected}) AND {rx[f'p2r.vac.{i+1}.ok']}",no(b['releaseDone']))]
        for status in [30,40,900,901,903,904]:
            cond=f"({selected}) AND !{ch['submit']} AND ({ch['status']}={status})"
            lines += [iff(cond,put(app['r2p.production.faultCode'],1201)),iff(cond,yes(b['needsRecovery']))]
    for i in range(5):
        cond=f"{b['releaseDone']} AND ({bit(p['mask'],i)}) AND ({bit(app['r2p.production.loadMask'],i)})"
        lines.append(iff(cond,put(app['r2p.production.loadMask'],app['r2p.production.loadMask']+f'-{1<<i}')))
    lines.append(iff(b['releaseDone'],no(b['releasing'])))
    ls('RG_RELEASED',lines)

    event_names=['blisterPicked','blisterPlaced','blisterFinished','stackFinished',
                 'immPickupCompleted','productsPlaced','samplesPlaced','rejectsPlaced']
    wrappers=['RE_BLPICK','RE_BLPLACE','RE_BLFULL','RE_STACK','RE_IMMPICK','RE_PROD','RE_SAMPLE','RE_REJECT']
    for event,name in zip(event_names,wrappers):
        ch=channels[event]
        lines=[no(b['eventDone']),iff(f"({ch['state']}<>0) OR {ch['submit']}",'JMP LBL[999]')]
        for key in ch['payload']:
            value=p['stackId'] if key.endswith('.stackId') else p['cycleId'] if key.endswith('.cycleId') else p['qty'] if key.endswith('.count') else p['trayIndex']
            lines.append(put(app[key],value))
        lines += [yes(ch['submit']),'LBL[999]'];ls(name,lines)
    lines=[no(b['eventDone'])]
    for code,event in enumerate(event_names,1):
        ch=channels[event]
        cond=f"({p['work']}={code}) AND ({ch['state']}=0) AND ({ch['status']}=20) AND !{ch['submit']}"
        lines.append(iff(cond,yes(b['eventDone'])))
        for status in [900,901,903,904]:
            lines.append(iff(f"({p['work']}={code}) AND !{ch['submit']} AND ({ch['status']}={status})",yes(b['needsRecovery'])))
    ls('RE_DONE',lines)

    lines=[put(p['sum'],0),put(p['groupCount'],0)]
    for i in range(1,6):
        lines += [put(p['sum'],p['sum']+'+'+active[f'qty{i}']),
                  iff(f"{active[f'qty{i}']}>0",put(p['groupCount'],p['groupCount']+'+1'))]
    checked(lines,f"{rx['p2r.imm.cycleKnown']} AND {rx['p2r.imm.pickupPending']}",1301)
    checked(lines,f"({rx['p2r.imm.batchCount']}={p['sum']}) AND ({p['sum']}>0)",1302)
    checked(lines,f"{b['cfgApplied']} AND !{b['batchAssigned']}",1303)
    lines += [put(p['cycleId'],rx['p2r.imm.cycleId']),put(p['batchCount'],rx['p2r.imm.batchCount']),
              put(p['remaining'],rx['p2r.imm.batchCount']),put(p['destination'],0),put(p['group'],1),
              yes(b['batchAssigned']),no(b['pickupConfirmed']),yes(b['cfgFrozen']),
              iff(rx['p2r.imm.reject'],put(p['destination'],2)),
              iff(f"({p['destination']}=0) AND ({c['sampleState']}=10)",put(p['destination'],1))]
    for dest,result in [(1,1),(2,2)]:
        cond=f"({p['destination']}={dest}) AND ({c['sampleState']}=10)"
        lines += [iff(cond,put(app['r2p.samples.result'],result)),iff(cond,yes(app['r2p.samples.ack']))]
    lines += ['JMP LBL[999]','LBL[9000]',yes(b['needsRecovery']),yes(c['guardRequest']),goto(900),'LBL[999]']
    ls('RT_ASSIGN',lines)
    lines=[put(p['mask'],0),put(p['qty'],0)]
    for i in range(1,6):
        lines += [iff(f"{p['group']}={i}",put(p['mask'],active[f'mask{i}'])),
                  iff(f"{p['group']}={i}",put(p['qty'],active[f'qty{i}']))]
    ls('RT_GROUP',lines)
    new=f"{rx['p2r.production.newOperationPermit']} AND {rx['p2r.imm.newCyclePermit']} AND !{rx['p2r.production.stopRequest']} AND !{rx['p2r.production.endOrderRequest']}"
    finish=f"{rx['p2r.production.finishPermit']} AND ({rx['p2r.imm.unsettledCount']}>0) AND !{rx['p2r.imm.pickupPending']}"
    ls('RT_IMMREQ',[put(b['safe'],new),put(b['deviceDone'],finish),
        put(app['r2p.imm.req.mouldClose'],f"{b['armed']} AND {b['immExited']} AND ({b['safe']} OR {b['deviceDone']})"),
        put(app['r2p.imm.req.mouldClose'],f"{app['r2p.imm.req.mouldClose']} AND !({b['batchAssigned']} AND !{b['pickupConfirmed']})"),
        iff(b['immExited'],put(app['r2p.imm.req.mouldFullOpen'],f"{rx['p2r.imm.pickupPending']} AND {b['batchAssigned']} AND !{b['pickupConfirmed']}"))])

    base=[iff('!'+b['statusValid'],'JMP LBL[999]'),iff('!'+raw['home'],'JMP LBL[999]'),iff(f"!{raw['autoMode']} OR {raw['tpEnabled']}",'JMP LBL[999]'),
          iff(f"{rx['p2r.production.criticalBlock']} OR {rx['p2r.production.recoveryRequired']}",'JMP LBL[999]'),
          iff(f"({c['state']}<>30) AND ({c['state']}<>40)",'JMP LBL[999]')]
    for ch in channels.values():base.append(iff(f"({ch['state']}<>0) OR {ch['ack']}",'JMP LBL[999]'))
    lines=[iff('!'+b['newApproved'],'JMP LBL[999]'),iff(f"{rx['p2r.production.orderActive']} OR {b['armed']}",'JMP LBL[999]')]+base
    lines += [iff(b['batchAssigned'],'JMP LBL[999]'),
              iff(f"{app['r2p.production.loadMask']}<>0",'JMP LBL[999]'),
              put(p['slot'],0),put(p['trayIndex'],0),put(p['remaining'],0),put(p['group'],1),no(b['trayReady']),no(b['fullStackWait']),no(b['releasing']),no(b['sourceInside']),no(b['elevatorInside']),
              put(p['stackId'],rx['p2r.production.stackId']),yes(app['r2p.production.loadKnown']),
              no(b['needsRecovery']),no(c['guardRequest']),no(c['appArm']),no(b['armed']),
              put(app['r2p.production.faultCode'],0),put(p['lastStart'],rx['p2r.production.startToken']),goto(10)]
    for name in ['sourceExited','elevatorExited','storageExited','immExited']:lines.append(yes(b[name]))
    lines += [no(b['newApproved']),'CALL RC_RECOV','LBL[999]'];ls('RT_NEW',lines)
    lines=[iff(f"!{b['recoveryApproved']} OR !{b['contextChecked']}",'JMP LBL[999]')]+base
    checked(lines,f"{b['cfgApplied']} AND {app['r2p.production.loadKnown']}",1401)
    lines += [put(p['sum'],0),put(p['mask'],0)]
    for i in range(1,6):
        cond=f"{p['group']}<={i}"
        lines += [iff(cond,put(p['sum'],p['sum']+'+'+active[f'qty{i}'])),
                  iff(cond,put(p['mask'],p['mask']+'+'+active[f'mask{i}']))]
    checked(lines,f"!{b['pickupConfirmed']} OR ({p['remaining']}={p['sum']})",1402)
    checked(lines,f"!{b['pickupConfirmed']} OR ({app['r2p.production.loadMask']}={p['mask']})",1403)
    checked(lines,f"!{b['pickupConfirmed']} OR !{rx['p2r.imm.pickupPending']}",1404)
    checked(lines,f"{b['pickupConfirmed']} OR !{b['batchAssigned']} OR ({rx['p2r.imm.cycleId']}={p['cycleId']})",1405)
    checked(lines,f"{b['pickupConfirmed']} OR ({app['r2p.production.loadMask']}=0)",1406)
    checked(lines,f"!{b['batchAssigned']} OR {b['pickupConfirmed']} OR {rx['p2r.imm.pickupPending']}",1407)
    checked(lines,f"({p['remaining']}<>0) OR ({p['slot']}<{active['gridX']}*{active['gridY']})",1408)
    completed=f"{b['pickupConfirmed']} AND ({p['remaining']}=0)"
    lines += [iff(completed,no(b['batchAssigned'])),iff(completed,no(b['cfgFrozen'])),iff(completed,no(b['pickupConfirmed']))]
    lines += [goto(10),iff(f"{b['batchAssigned']} AND !{b['pickupConfirmed']}",goto(300)),
              iff(f"{b['pickupConfirmed']} AND ({p['remaining']}>0)",goto(400)),iff(f"{b['fullStackWait']} AND ({p['remaining']}=0)",goto(620)),
              no(b['needsRecovery']),no(c['guardRequest']),no(c['appArm']),no(b['armed']),no(b['releasing']),
              put(p['lastStart'],rx['p2r.production.startToken']),put(app['r2p.production.faultCode'],0)]
    for name in ['sourceExited','elevatorExited','storageExited','immExited']:lines.append(yes(b[name]))
    lines += [no(b['sourceInside']),no(b['elevatorInside']),no(b['recoveryApproved']),no(b['contextChecked']),'CALL RC_RECOV','JMP LBL[999]',
              'LBL[9000]',yes(b['needsRecovery']),goto(900),'LBL[999]'];ls('RT_RECOV',lines)
    ls('RT_BOOT',['CALL RB_BIND',yes(b['selected']),yes(c['productionRequired']),no(b['armed']),no(c['appArm']),
                 put(p['lastStart'],rx['p2r.production.startToken']),yes(b['booted']),
                 iff(f"{p['state']}<>710",yes(b['needsRecovery'])),iff(b['needsRecovery'],goto(900))])

    state(10,'Oczekiwanie i przypisanie partii',[
        wait(20),iff('!'+b['armed'],'JMP LBL[999]'),iff(b['fullStackWait'],goto(620)),iff(b['fullStackWait'],'JMP LBL[999]'),
        iff(f"{b['batchAssigned']} AND ({p['remaining']}>0)",goto(300)),
        iff(f"{b['batchAssigned']} AND ({p['remaining']}>0)",'JMP LBL[999]'),
        iff(rx['p2r.imm.pickupPending'],'CALL RT_ASSIGN'),
        iff(b['needsRecovery'],'JMP LBL[9000]'),iff(b['batchAssigned'],goto(300)),
        iff(f"{b['batchAssigned']} AND ({p['destination']}=0) AND !{b['trayReady']}",goto(200)),
        iff(b['batchAssigned'],'JMP LBL[999]'),
        iff(f"({rx['p2r.production.stopRequest']} OR {rx['p2r.production.endOrderRequest']}) AND {rx['p2r.imm.settled']} AND ({rx['p2r.imm.unsettledCount']}=0)",goto(700)),
        iff(f"{p['state']}=700",'JMP LBL[999]'),
        iff(f"!{b['trayReady']} AND {rx['p2r.production.newOperationPermit']}",goto(200))])
    stop_before_entry = (
        f"({rx['p2r.production.stopRequest']} OR {rx['p2r.production.endOrderRequest']})"
        f" AND {rx['p2r.imm.settled']} AND ({rx['p2r.imm.unsettledCount']}=0)"
        f" AND !{rx['p2r.imm.pickupPending']} AND !{b['batchAssigned']}")
    cancel_source = [
        put(b['safe'],stop_before_entry),
        iff(f"{b['safe']} AND !{b['sourceInside']} AND ({b['sourceExited']} OR {raw['home']})",goto(700)),
        iff(f"{p['state']}=700",no(app['r2p.area.source.accessReq'])),
        iff(f"{p['state']}=700",'JMP LBL[999]')]
    state(205,'Oczekiwanie na dostep do zrodla',[wait(60)]+cancel_source+[
        iff(f"{rx['p2r.area.source.valid']} AND {rx['p2r.area.source.granted']}",goto(210))])
    empty_checks=[]
    for i in range(5):
        checked(empty_checks,f"!({bit(active['trayMask'],i)}) OR !{rx[f'p2r.vac.{i+1}.ok']}",1502)
    state(200,'Zadanie dostepu do zrodla',empty_checks+[
        yes(app['r2p.area.source.accessReq']),
        put(p['mask'],active['trayMask']),put(p['searchDepth'],0),put(p['attempt'],0),goto(205)])
    state(210,'Dostep i dojazd do stosu',[
        wait(60),'CALL RG_FOLD',iff('!'+b['cylDone'],'JMP LBL[999]')]+cancel_source+[
        iff(f"!{rx['p2r.area.source.valid']} OR !{rx['p2r.area.source.granted']}",'JMP LBL[999]'),
        no(b['sourceExited']),yes(b['sourceInside'])]+moved('RM_SRCIN',220))
    state(220,'Wlaczenie prozni tacki',[
        'CALL RG_VACON',iff(b['vacDone'],goto(240)),iff('!'+b['vacDone'],goto(225))])
    lines=[wait(50),'CALL RG_VACON',iff(b['vacDone'],goto(240)),iff(b['vacDone'],'JMP LBL[999]'),
           iff(f"{c['now']}-{p['phaseSince']}<{active['timeout']}",'JMP LBL[999]'),
           put(p['searchDepth'],p['searchDepth']+'+'+active['searchStep']),
           put(p['attempt'],p['attempt']+'+1')]
    checked(lines,f"({p['searchDepth']}<={active['searchLimit']}) AND ({p['attempt']}<={active['maxAttempts']})",1501)
    state(225,'Ograniczone szukanie tacki',lines+moved('RM_SEARCH',220))
    state(240,'Podniesienie i wyjazd ze zrodla',[
        put(app['r2p.production.loadMask'],active['trayMask']),yes(app['r2p.production.loadKnown'])]+moved('RM_SRCOUT',245))
    state(245,'Potwierdzenie pobrania tacki',[
        yes(b['sourceExited']),no(b['sourceInside']),no(app['r2p.area.source.accessReq']),
        'CALL RE_BLPICK',goto(250)])
    state(250,'ACK pobrania tacki',[put(p['work'],1),wait(70),'CALL RE_DONE',iff(b['eventDone'],goto(260))])
    state(260,'Zadanie dostepu do windy',[
        no(b['elevatorExited']),yes(app['r2p.area.elevator.accessReq']),goto(270)])
    state(270,'Odlozenie pustej tacki',[
        wait(60),iff(f"!{rx['p2r.area.elevator.valid']} OR !{rx['p2r.area.elevator.granted']}",'JMP LBL[999]'),
        yes(b['elevatorInside'])]+moved('RM_TRAYIN',275))
    state(275,'Zwolnienie tacki',[put(p['mask'],active['trayMask']),'CALL RG_RELEASE',goto(280)])
    state(280,'Potwierdzenie zwolnienia tacki',[
        wait(50),'CALL RG_RELEASED',iff(b['releaseDone'],'CALL RE_BLPLACE'),iff(b['releaseDone'],goto(285))])
    state(285,'ACK odlozenia tacki',[put(p['work'],2),wait(70),'CALL RE_DONE',iff(b['eventDone'],goto(290))])
    state(290,'Wycofanie z windy',moved('RM_TRAYOUT',295))
    state(295,'Tacka gotowa',[
        yes(b['elevatorExited']),no(b['elevatorInside']),no(app['r2p.area.elevator.accessReq']),
        yes(b['trayReady']),goto(10),iff(b['batchAssigned'],goto(300))])

    state(300,'Przygotowanie pobrania z formy',[
        'CALL RG_STRAIGHT',wait(40),iff('!'+b['cylDone'],'JMP LBL[999]')]+moved('RM_IMMIN',310))
    state(310,'Oczekiwanie na otwarta forme',[
        wait(30),no(app['r2p.imm.req.mouldClose']),yes(app['r2p.imm.req.mouldFullOpen']),
        iff(f"!{rx['p2r.imm.valid']} OR !{rx['p2r.imm.withRobot']} OR !{rx['p2r.imm.mouldOpen']} OR {rx['p2r.imm.mouldClosed']}",'JMP LBL[999]'),goto(320)])
    lines=[put(p['mask'],0)]
    for i in range(1,6):lines.append(put(p['mask'],p['mask']+'+'+active[f'mask{i}']))
    state(320,'Wejscie i proznia detali',lines+['CALL RG_VACON',no(b['immExited'])]+moved('RM_PICK',330))
    state(330,'Zadanie wyrzutnika',[
        no(app['r2p.imm.req.ejectorBack']),yes(app['r2p.imm.req.ejectorForward']),goto(340)])
    state(340,'Potwierdzenie detali i wyrzutnika',[
        wait(50),'CALL RG_VACON',
        iff(f"!{b['vacDone']} OR !{rx['p2r.imm.ejectorForward']} OR {rx['p2r.imm.ejectorBack']}",'JMP LBL[999]'),
        put(app['r2p.production.loadMask'],p['mask']),yes(app['r2p.production.loadKnown'])]+moved('RM_RETRACT',350))
    state(350,'Powrot wyrzutnika',[
        no(app['r2p.imm.req.ejectorForward']),yes(app['r2p.imm.req.ejectorBack']),goto(360)])
    state(360,'Wyjazd z formy',[
        wait(30),iff(f"!{rx['p2r.imm.valid']} OR !{rx['p2r.imm.ejectorBack']} OR {rx['p2r.imm.ejectorForward']}",'JMP LBL[999]')]+moved('RM_IMMOUT',370))
    state(370,'Zdarzenie pobrania partii',[
        yes(b['pickupConfirmed']),yes(b['immExited']),no(app['r2p.imm.req.ejectorBack']),
        no(app['r2p.imm.req.mouldFullOpen']),'CALL RE_IMMPICK',goto(380)])
    state(380,'ACK pobrania IMM',[put(p['work'],5),wait(70),'CALL RE_DONE',iff(b['eventDone'],goto(400))])

    state(400,'Wybor kolejnej grupy',[
        'CALL RT_GROUP',iff(f"{p['group']}>5",goto(490)),iff(f"{p['group']}>5",'JMP LBL[999]'),
        iff(f"{p['qty']}=0",put(p['group'],p['group']+'+1')),iff(f"{p['qty']}=0",'JMP LBL[999]'),
        iff(f"{p['destination']}=0",goto(410)),iff(f"{p['destination']}<>0",goto(415))])
    state(412,'Oczekiwanie na dostep do windy',[wait(60),iff(f"{rx['p2r.area.elevator.valid']} AND {rx['p2r.area.elevator.granted']}",goto(420))])
    state(410,'Zadanie dostepu do odkladania',[
        no(b['elevatorExited']),yes(app['r2p.area.elevator.accessReq']),goto(412)])
    state(415,'Droga do probek lub odrzutow',[
        'CALL RG_FOLD',iff('!'+b['cylDone'],'JMP LBL[999]')]+moved('RM_SAMPLEIN',430))
    state(420,'Dojazd nad tacke',[
        wait(60),'CALL RG_FOLD',
        iff(f"!{b['cylDone']} OR !{rx['p2r.area.elevator.valid']} OR !{rx['p2r.area.elevator.granted']}",'JMP LBL[999]'),
        yes(b['elevatorInside'])]+moved('RM_PLACEIN',430))
    lines=['CALL RT_OFFSET']
    checked(lines,f"({p['destination']}<>0) OR ({p['slot']}<{active['gridX']}*{active['gridY']})",1601)
    for i in range(1,6):
        lines += [iff(f"({p['group']}={i}) AND ({p['destination']}=0)",f'CALL RM_PROD{i}'),
                  iff(f"({p['group']}={i}) AND ({p['destination']}<>0)",f'CALL RM_SAMP{i}')]
    state(430,'Pozycja odlozenia grupy',lines+[iff(b['motionDone'],goto(440))])
    state(440,'Jednorazowe zwolnienie grupy',['CALL RG_RELEASE',goto(450)])
    lines=[wait(50),'CALL RG_RELEASED',iff('!'+b['releaseDone'],'JMP LBL[999]')]
    for dest,name in [(0,'RE_PROD'),(1,'RE_SAMPLE'),(2,'RE_REJECT')]:
        lines.append(iff(f"{p['destination']}={dest}",'CALL '+name))
    state(450,'Potwierdzenie fizycznego odlozenia',lines+[goto(460)])
    state(460,'ACK rozliczenia grupy',[
        put(p['work'],p['destination']+'+6'),wait(70),'CALL RE_DONE',iff(b['eventDone'],goto(470))])
    state(470,'Zapis postepu po ACK',[
        put(p['remaining'],p['remaining']+'-'+p['qty']),
        iff(f"{p['destination']}=0",put(p['slot'],p['slot']+'+1')),
        put(p['group'],p['group']+'+1'),goto(480)])
    state(480,'Wycofanie po odlozeniu',[
        iff(f"{p['destination']}=0",'CALL RM_PLACEOUT'),
        iff(f"{p['destination']}<>0",'CALL RM_SAMPLEOUT'),iff(b['motionDone'],goto(485))])
    state(485,'Zwolnienie obszaru windy',[
        yes(b['elevatorExited']),no(b['elevatorInside']),no(app['r2p.area.elevator.accessReq']),goto(400)])
    state(490,'Partia rozliczona',[
        iff(f"{p['remaining']}<>0",'JMP LBL[9000]'),
        no(b['batchAssigned']),no(b['pickupConfirmed']),no(b['cfgFrozen']),goto(10),
        iff(f"({p['destination']}=0) AND ({p['slot']}={active['gridX']}*{active['gridY']})",goto(500))])
    state(500,'Zdarzenie pelnej tacki',['CALL RE_BLFULL',goto(510)])
    state(510,'ACK pelnej tacki',[put(p['work'],3),wait(70),'CALL RE_DONE',iff(b['eventDone'],goto(520))])
    state(520,'Nastepna tacka',[
        put(p['trayIndex'],p['trayIndex']+'+1'),put(p['slot'],0),no(b['trayReady']),goto(10),
        iff(f"{p['trayIndex']}={active['traysPerStack']}",goto(600))])
    state(600,'Zdarzenie pelnego stosu',['CALL RE_STACK',goto(610)])
    state(610,'ACK stosu',[put(p['work'],4),wait(70),'CALL RE_DONE',iff(b['eventDone'],yes(b['fullStackWait'])),iff(b['eventDone'],goto(620))])
    state(620,'Oczekiwanie na nowy stos',[
        wait(60),iff(f"({rx['p2r.production.stopRequest']} OR {rx['p2r.production.endOrderRequest']}) AND {rx['p2r.imm.settled']} AND ({rx['p2r.imm.unsettledCount']}=0)",goto(700)),iff(f"{p['state']}=700",'JMP LBL[999]'),iff(f"{rx['p2r.production.stackId']}={p['stackId']}",'JMP LBL[999]'),no(b['fullStackWait']),
        put(p['stackId'],rx['p2r.production.stackId']),put(p['trayIndex'],0),goto(10)])
    state(700,'Dojazd do postoju',[
        iff(raw['home'],goto(710)),iff(raw['home'],'JMP LBL[999]')]+moved('RM_HOME',710))
    state(710,'Postoj po rozliczeniu',[
        no(b['armed']),no(c['appArm']),
        iff(f"{rx['p2r.imm.pickupPending']} OR ({rx['p2r.imm.unsettledCount']}>0)",no(app['r2p.production.operationsSettled'])),
        iff(f"({rx['p2r.imm.pickupPending']} OR ({rx['p2r.imm.unsettledCount']}>0)) AND {rx['p2r.production.finishPermit']}",yes(b['armed'])),
        iff(b['armed'],yes(c['appArm'])),iff(b['armed'],goto(10)),iff(b['armed'],'JMP LBL[999]'),
        iff(f"{rx['p2r.imm.pickupPending']} OR ({rx['p2r.imm.unsettledCount']}>0)",'JMP LBL[999]'),
        no(b['armed']),no(c['appArm']),yes(app['r2p.production.operationsSettled']),
        put(app['r2p.production.waitingResume'],rx['p2r.production.orderActive']),wait(80)])
    state(720,'Zlecenie zamkniete - oczekiwanie na lokalne NEW',[
        wait(80),put(b['safe'],f"{c['session']} AND {rx['p2r.imm.cycleKnown']} AND {rx['p2r.imm.settled']} AND ({rx['p2r.imm.unsettledCount']}=0) AND !{rx['p2r.imm.pickupPending']}"),
        iff(f"{b['safe']} AND {b['newApproved']} AND {b['stationIdleConfirmed']}",'CALL RT_NEW'),
        iff(f"{p['state']}=10",no(b['stationIdleConfirmed']))])
    state(900,'Wymagane uzgodnienie stanu',[
        no(b['armed']),no(c['appArm']),yes(b['needsRecovery']),wait(80),iff(b['newApproved'],'CALL RT_NEW'),
        iff(f"{b['recoveryApproved']} AND {b['contextChecked']}",'CALL RT_RECOV')])

    if mode=='BOX':extend(locals())

    groups={'RT_IDLE':[10],'RT_TACK':[n for n in states if 200<=n<300],
            'RT_PICK':[n for n in states if 300<=n<400],
            'RT_PLACE':[n for n in states if 400<=n<500],
            'RT_FULL':[n for n in states if 500<=n<700],'RT_STOP':[700,710,720,900]}
    for name,numbers in groups.items():
        lines=[iff(f"{p['dispatch']}={n}",f'JMP LBL[{n}]') for n in numbers]+['CALL RT_BADSTATE','JMP LBL[999]']
        for n in numbers:lines += [f'LBL[{n}]','! '+states[n]['title']]+states[n]['lines']+['JMP LBL[999]']
        lines += ['LBL[9000]',iff(f"{app['r2p.production.faultCode']}=0",put(app['r2p.production.faultCode'],1900)),yes(b['needsRecovery']),goto(900),'LBL[999]']
        ls(name,lines)

    lines=[iff('!'+b['selected'],'JMP LBL[999]'),iff(f"{p['state']}<>900",put(p['resumeState'],p['state'])),put(p['dispatch'],p['state']),put(app['r2p.production.step'],p['state']),wait(0),
           iff(f"{p['state']}<>{p['lastState']}",put(p['phaseSince'],c['now'])),
           put(p['lastState'],p['state'])]
    lines += [put(b['safe'],f"{b['orderWasActive']} AND !{rx['p2r.production.orderActive']}"),
              iff(f"{b['safe']} AND ({p['state']}=710) AND !{b['armed']} AND {app['r2p.production.operationsSettled']} AND {raw['home']}",goto(720)),
              iff(f"{b['safe']} AND ({p['state']}=720) AND ({b['batchAssigned']} OR ({p['remaining']}<>0) OR !{app['r2p.production.loadKnown']} OR ({app['r2p.production.loadMask']}<>0))",goto(900)),
              iff(f"{b['safe']} AND ({p['state']}=720)",no(b['newApproved'])),
              iff(f"{b['safe']} AND ({p['state']}=720)",no(b['stationIdleConfirmed'])),
              iff(f"{b['safe']} AND ({p['state']}<>720)",yes(b['needsRecovery'])),
              iff(f"{b['safe']} AND ({p['state']}<>720)",goto(900)),
              put(b['orderWasActive'],rx['p2r.production.orderActive'])]
    start=f"({rx['p2r.production.startToken']}<>{p['lastStart']}) AND ({p['state']}<>720) AND {c['productionPermit']} AND {rx['p2r.production.orderActive']}"
    lines += [put(b['safe'],start),
              put(b['safe'],f"{b['safe']} AND {rx['p2r.production.withRobot']} AND ({rx['p2r.production.expectedProgram']}=2)"),
              put(b['safe'],f"{b['safe']} AND !{rx['p2r.production.stopRequest']} AND !{rx['p2r.production.endOrderRequest']}"),
              iff(b['safe'],yes(b['armed'])),iff(b['safe'],yes(c['appArm'])),
              iff(b['safe'],no(app['r2p.production.waitingResume'])),
              iff(f"{b['safe']} AND ({p['state']}=710)",goto(10)),
              put(p['lastStart'],rx['p2r.production.startToken']),
              put(app['r2p.production.stopping'],f"{rx['p2r.production.stopRequest']} OR {rx['p2r.production.endOrderRequest']}"),
              iff(f"!{c['session']} OR {c['guardRequest']} OR {b['needsRecovery']}",goto(900)),
              iff(f"{rx['p2r.production.expectedProgram']}<>2",goto(900)),
              iff(f"{b['armed']} AND !{rx['p2r.production.orderActive']}",goto(900)),
              # Po recovery zlecenie można zakończyć przed pierwszym Start produkcji.
              # Potwierdzamy wyłącznie już obserwowany HOME z pustym chwytakiem i bez partii.
              put(b['safe'],f"({p['state']}=10) AND !{b['armed']} AND !{b['batchAssigned']}"),
              put(b['safe'],f"{b['safe']} AND !{b['pickupConfirmed']} AND ({p['remaining']}=0) AND {raw['home']}"),
              put(b['safe'],f"{b['safe']} AND {app['r2p.production.loadKnown']} AND ({app['r2p.production.loadMask']}=0)"),
              put(b['safe'],f"{b['safe']} AND ({rx['p2r.production.stopRequest']} OR {rx['p2r.production.endOrderRequest']})"),
              put(b['safe'],f"{b['safe']} AND {rx['p2r.imm.settled']} AND ({rx['p2r.imm.unsettledCount']}=0)"),
              iff(b['safe'],goto(710)),
              put(p['dispatch'],p['state']),
              iff(f"{p['state']}<>710",no(app['r2p.production.operationsSettled'])),
              'CALL RT_IMMREQ',
              put(b['safe'],f"!{b['batchAssigned']} AND ({rx['p2r.production.stopRequest']} OR {rx['p2r.production.endOrderRequest']} OR !{rx['p2r.production.orderActive']})"),
              put(b['safe'],f"{b['safe']} OR ({b['batchAssigned']} AND ({p['destination']}=1))"),
              put(b['safe'],f"{b['safe']} AND ({c['sampleState']}=10)"),
              iff(b['safe'],put(app['r2p.samples.result'],2)),iff(b['safe'],yes(app['r2p.samples.ack'])),
              iff(f"!{b['armed']} AND ({p['state']}<>10) AND ({p['state']}<>710) AND ({p['state']}<>720) AND ({p['state']}<>900)",'JMP LBL[999]')]
    lines.append(put(p['work'],p['dispatch']+' DIV 100'))
    for index,(family,name) in enumerate([(0,'RT_IDLE'),(2,'RT_TACK'),(3,'RT_PICK'),(4,'RT_PLACE'),(5,'RT_FULL'),(6,'RT_FULL'),(7,'RT_STOP'),(9,'RT_STOP')]):
        lines.append((f"SELECT {p['work']}" if index==0 else '')+f'={family},CALL {name}')
    lines.append('ELSE,CALL RT_BADSTATE')
    for n in [210,250,280,285,300,310,340,360,380,415,420,450,460,510,610]+([550,586,590,482] if mode=='BOX' else []):
        cond=f"({p['dispatch']}={n}) AND ({c['now']}-{p['phaseSince']}>{active['timeout']})"
        lines += [iff(cond,yes(b['needsRecovery'])),
                  iff(cond,put(app['r2p.production.faultCode'],1700+n)),iff(cond,goto(900))]
    lines += [iff(b['needsRecovery'],yes(c['guardRequest'])),put(app['r2p.production.phase'],10)]
    for lo,hi,phase in [(200,300,40),(300,400,20),(400,500,30),(500,700,40),(700,710,60),(710,711,70),(720,721,70),(900,901,900)]:
        lines.append(iff(f"({p['state']}>={lo}) AND ({p['state']}<{hi})",put(app['r2p.production.phase'],phase)))
    lines += [iff(f"({p['state']}>=400) AND ({p['state']}<500) AND ({p['destination']}<>0)",put(app['r2p.production.phase'],50)),
              'LBL[999]']
    ls('RT_TICK',lines)
    ls('RT_BADSTATE',fail(1102))
    ls('RT_MAIN',['CALL RT_BOOT','LBL[1]','CALL RT_TICK','WAIT   .02(sec)',iff(b['selected'],'JMP LBL[1]')],motion=True)
    ls('RT_EXIT',[iff(f"({p['state']}<>710) OR {b['batchAssigned']} OR ({app['r2p.production.loadMask']}<>0)",'JMP LBL[999]'),no(b['selected']),no(b['armed']),
                  no(c['appArm']),no(c['productionRequired']),'LBL[999]'])
    manifest=dict(status='PREPARED_NOT_COMMISSIONED',contract_version=2,staging=staging,active=active,
                  runtime=p,flags=b,native=raw,taught=taught,bg=bg,points=POINTS,allocations=alloc,
                  register_ranges=[[1,50],[177,200]],flag_range=[1,fnum-1],
                  states={str(n):{'title':v['title']} for n,v in sorted(states.items())})
    artifacts[ROOT/'ROBOT/TRAY/resources.json']=json.dumps(manifest,ensure_ascii=False,indent=2)+'\n'
    out=io.StringIO(newline='');w=csv.writer(out,lineterminator='\n');w.writerow(['PR','name','status'])
    for n,name in POINTS.items():w.writerow([n,name,'COMPUTED' if n in [29,30,31] else 'UNTAUGHT'])
    artifacts[ROOT/'ROBOT/TRAY/points.csv']=out.getvalue()
    if mode=='BOX':
        # TRAY coordinates are a template only. BOX owns a separate PR bank.
        remap={1:1,**{i:i+39 for i in range(2,41)}}
        def convert(value):
            if isinstance(value,str):
                value=re.sub(r'\bRT_', 'RX_',value)
                value=re.sub(r'\bRM_', 'XM_',value)
                return re.sub(r'PR\[(\d+)(?=[,\]])',lambda m:'PR['+str(remap.get(int(m[1]),int(m[1]))),value)
            if isinstance(value,dict):return {k:convert(v) for k,v in value.items()}
            if isinstance(value,list):return [convert(v) for v in value]
            return value
        converted={}
        for path,text in artifacts.items():
            path=Path(str(path).replace('/TRAY/','/BOX/').replace('\\TRAY\\','\\BOX\\').replace('RT_','RX_').replace('RM_','XM_'))
            if path.suffix=='.json':
                data=convert(json.loads(text));data['register_ranges']=[[201,330]]
                data['parameter_meanings']={'trayHeight':'layerPitchZ','traysPerStack':'layerCount','trayMask':'spacerMask','trayIndex':'zero_based_layer_index'}
                data['loadKind_values']={'NONE':0,'PRODUCTS':1,'SPACER':2}
                data['taught']={str(remap.get(int(k),int(k))):v for k,v in data['taught'].items()}
                data['points']={str(remap.get(int(k),int(k))):v for k,v in data['points'].items()}
                text=json.dumps(data,ensure_ascii=False,indent=2)+'\n'
            elif path.suffix=='.csv':
                text='PR,name,status\n'+''.join(str(remap.get(int(row[0]),int(row[0])))+','+','.join(row[1:])+'\n' for row in csv.reader(io.StringIO(text)) if row and row[0]!='PR')
            else:text=convert(text).replace('Krauss tacki','Krauss box').replace('nad tacke','nad pojemnik').replace('ACK stosu','ACK pojemnika').replace('pelnego stosu','pelnego pojemnika')
            converted[path]=text
        artifacts=converted
    return artifacts


def build():
    from fanuc_common import combine
    from fanuc_main import consolidate
    from fanuc_descriptions import describe_artifacts
    artifacts=consolidate(combine(template('TRAY'),template('BOX')),ROOT)
    manifests={d:json.loads(artifacts[ROOT/f'ROBOT/{d}/resources.json']) for d in ['TRAY','BOX','COMMON']}
    comm=build_fanuc_comm.build()
    return describe_artifacts(artifacts,manifests,json.loads(comm[ROOT/'ROBOT/COMM/resources.json']),json.loads(comm[ROOT/'ROBOT/COMM/mapping.json']),ROOT/'ROBOT/COMMON')


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
    artifacts=build();different=[]
    for folder in ['TRAY','BOX','COMMON','BG']:
        for old in (ROOT/'ROBOT'/folder).glob('*.LS'):
            if old not in artifacts and old.stem.startswith(('RT_','RX_','RM_','XM_','RG_','RE_','RF_','RB_')):
                if args.check:different.append(str(old.relative_to(ROOT)))
                else:old.unlink()
    for path,text in artifacts.items():
        if args.check:
            if not path.exists() or path.read_text(encoding='utf-8')!=text:different.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8',newline='\n')
    if different:raise SystemExit('Generated files differ: '+', '.join(different))
    print(('Checked' if args.check else 'Generated'),len(artifacts),'production/BG artifacts; no device access')

if __name__=='__main__':main()
