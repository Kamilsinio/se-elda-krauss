"""Compose BOX/TRAY with one BG owner and one R/F mailbox for shared helpers.

Only emitted LS runs on the robot. Python does not connect to any device.
"""
from __future__ import annotations
import json
import re
from pathlib import Path

def body(text):
    return [m[1] for line in text.splitlines() if (m:=re.fullmatch(r'\s*\d+:\s*(.*?)\s*;',line))]
def emit(name,lines,motion=False):
    return '\n'.join(['/PROG '+name,'/ATTR','OWNER = MNEDITOR;','COMMENT = "Krauss produkcja";',
        'PROTECT = READ_WRITE;','DEFAULT_GROUP = '+('1' if motion else '*')+',*,*,*,*;',
        'CONTROL_CODE = 00000000 00000000;','/MN']+[f'{i:4}:  {v} ;' for i,v in enumerate(lines,1)]+['/POS','/END',''])
def put(ref,val):return f'{ref}=({val})'
def yes(ref):return put(ref,'ON')
def no(ref):return put(ref,'OFF')
def iff(cond,stmt):return f'IF ({cond}),{stmt}'
def replace_refs(text,refs):
    return re.sub(r'\b(?:R|F)\[\d+\]',lambda m:refs.get(m[0],m[0]),text)

def combine(tray,box):
    root=Path(__file__).resolve().parents[1];art={}
    import build_fanuc_comm
    com=json.loads(build_fanuc_comm.build()[root/'ROBOT/COMM/resources.json'])
    c=com['controls'];app=com['application'];rx=com['rx'];channels=com['channels']
    modes={2:(tray,'TRAY','RT'),1:(box,'BOX','RX')}
    manifests={i:json.loads(src[root/f'ROBOT/{folder}/resources.json']) for i,(src,folder,_) in modes.items()}
    allocations=[];nr=331;nf=401
    def reg(name):
        nonlocal nr
        ref=f'R[{nr}]';allocations.append(dict(name=name,bank='R',number=nr));nr+=1;return ref
    def flag(name):
        nonlocal nf
        ref=f'F[{nf}]';allocations.append(dict(name=name,bank='F',number=nf));nf+=1;return ref
    owner=reg('owner');snapshot=reg('api.ownerSnapshot')
    gb={n:flag(n) for n in ['sourceBound','bindingsVerified','statusValid','capacityVerified','initialized','initApproved',
        'emptyConfirmed','conflict','ownershipSafe','apiBusy','apiValid','boxRequest','trayRequest','boxRelease','trayRelease']}
    raw={n:flag('native.'+n) for n in manifests[2]['native']}
    tasks={name:{key:flag('native.'+name+'.'+key) for key in ('running','paused')} for name in ('box','tray')}
    ar={};af={}
    for name in ['mask1','mask2','mask3','mask4','mask5','trayMask','cylFold','cylStraight']:ar['active.'+name]=reg('api.active.'+name)
    for name in ['mask','qty','stackId','cycleId','trayIndex','work','state','resumeState','capacity']:ar['runtime.'+name]=reg('api.runtime.'+name)
    for name in ['safe','needsRecovery','armed','batchAssigned','pickupConfirmed','immExited','releasing','cylDone','vacDone','releaseDone','eventDone','deviceDone']:
        af[name]=flag('api.'+name)
    assert nr<=361 and nf<=481,(nr,nf)
    # Alias native status and verification to COMMON; retain private flag numbering.
    for mode,(src,folder,prefix) in modes.items():
        m=manifests[mode];refs={}
        for name in ('sourceBound','bindingsVerified','statusValid'):refs[m['flags'][name]]=gb[name];m['flags'][name]=gb[name]
        for name,ref in raw.items():refs[m['native'][name]]=ref;m['native'][name]=ref
        aliased=set(refs)
        m['allocations']=[a for a in m['allocations'] if f'{a["bank"]}[{a["number"]}]' not in aliased]
        for path,text in src.items():
            if path.suffix=='.LS':art[path]=replace_refs(text,refs)
            elif path.name!='resources.json':art[path]=text
    def path(mode,name):
        return root/'ROBOT'/modes[mode][1]/(name+'.LS')
    def save(mode,name,lines,motion=False):art[path(mode,name)]=emit(name,lines,motion)
    def common(name,lines):art[root/'ROBOT/COMMON'/(name+'.LS')]=emit(name,lines)
    # Shared routines read an immutable snapshot of the current owner's arguments.
    reads=[no(gb['apiValid']),put(snapshot,owner)]
    writes=[iff(f'{snapshot}<>{owner}','JMP LBL[999]')]
    for mode in (1,2):
        m=manifests[mode];p=m['runtime'];b=m['flags']
        reads.append(iff(f'{owner}<>{mode}',f'JMP LBL[{mode}]'))
        for key,ref in ar.items():
            group,name=key.split('.');reads.append(put(ref,m[group][name]))
        for key,ref in af.items():reads.append(put(ref,b[key]))
        reads += [yes(gb['apiBusy']),yes(gb['apiValid']),'JMP LBL[999]',f'LBL[{mode}]']
        writes.append(iff(f'{owner}<>{mode}',f'JMP LBL[{mode}]'))
        for key in ['safe','releasing','cylDone','vacDone','releaseDone','eventDone','deviceDone']:
            writes.append(put(b[key],af[key]))
        # Never clear a BG fault from an older helper snapshot.
        writes += [iff(af['needsRecovery'],yes(b['needsRecovery'])),
                   iff(af['needsRecovery'],yes(c['guardRequest'])),
                   iff(af['needsRecovery'],put(p['resumeState'],ar['runtime.resumeState'])),
                   iff(af['needsRecovery'],put(p['state'],900)),
                   'JMP LBL[999]',f'LBL[{mode}]']
    common('RF_READ',reads+['LBL[999]']);common('RF_WRITE',writes+['LBL[999]',no(gb['apiBusy'])])
    # Extract one implementation, with R/F API, rather than task argument registers.
    helpers=['RG_FOLD','RG_STRAIGHT','RG_VACON','RG_RELEASE','RG_RELEASED','RE_BLPICK','RE_BLPLACE',
             'RE_BLFULL','RE_STACK','RE_IMMPICK','RE_PROD','RE_SAMPLE','RE_REJECT','RE_DONE','RE_LAYER','RE_SPACER']
    for name in helpers+['RF_SAFE','RF_IMMREQ','RG_TARGET']:
        mode=1 if name in ('RE_DONE','RE_LAYER','RE_SPACER') else 2
        m=manifests[mode];prefix=modes[mode][2]
        source=prefix+'_SAFE' if name=='RF_SAFE' else prefix+'_IMMREQ' if name=='RF_IMMREQ' else 'RG_FOLD' if name=='RG_TARGET' else name
        lines=body(art[path(mode,source)])
        refs={m[g][n]:ref for key,ref in ar.items() for g,n in [key.split('.')]}
        refs.update({m['flags'][key]:ref for key,ref in af.items()})
        if name=='RG_TARGET':refs[m['active']['cylFold']]=ar['runtime.capacity']
        lines=[replace_refs(v,refs).replace('LBL[999]','LBL[998]') for v in lines]
        if not lines or lines[-1]!='LBL[998]':lines.append('LBL[998]')
        # Names RT_IMMREQ / RT_SAFE are replaced at callsites below.
        gate=[]
        if name not in ('RF_SAFE','RF_IMMREQ','RE_DONE'):
            gate=[iff(f'!{c["appArm"]} OR !{c["productionPermit"]}','JMP LBL[996]'),iff(f'!{c["allowCommands"]} OR {c["guardRequest"]}','JMP LBL[996]')]
        tail=['CALL RF_WRITE','JMP LBL[999]']
        if gate:tail += ['LBL[996]',yes(af['needsRecovery']),put(ar['runtime.resumeState'],ar['runtime.state']),put(app['r2p.production.faultCode'],1100),'CALL RF_WRITE']
        common(name,['CALL RF_READ',iff('!'+gb['apiValid'],'JMP LBL[999]')]+gate+lines+tail+['LBL[999]'])
    for mode,(_,folder,prefix) in modes.items():
        m=manifests[mode];p=m['runtime'];b=m['flags'];native=m['native']
        request=gb['boxRequest' if mode==1 else 'trayRequest'];release=gb['boxRelease' if mode==1 else 'trayRelease']
        for name in helpers+['RG_TARGET']:
            art.pop(path(mode,name),None)
        # SAFE wrapper clears its private result before using the shared routine.
        save(mode,prefix+'_SAFE',[no(b['safe']),iff(f'{owner}<>{mode}','JMP LBL[999]'),'CALL RF_SAFE','LBL[999]'])
        save(mode,prefix+'_IMMREQ',[iff(f'{owner}<>{mode}','JMP LBL[999]'),'CALL RF_IMMREQ','LBL[999]'])
        # Inactive helper calls cannot drive another owner's pneumatics or events.
        # Production routines and each motion also get an ownership gate.
        for name in [prefix+'_INIT',prefix+'_APPLY',prefix+'_NEW',prefix+'_RECOV']:
            lines=body(art[path(mode,name)])
            if name.endswith('_INIT'):
                # Init only the local bank. Never reset COMMON/native or live load.
                lines=[v for v in lines if not any(v.startswith(ref+'=') for ref in list(gb.values())+list(raw.values())+list(c.values())+list(app.values())) and v!='CALL RB_BIND']
                guard=[iff(f'({owner}<>0) AND ({owner}<>{mode})','JMP LBL[999]'),
                       iff(f'{rx["p2r.production.orderActive"]} OR {native["taskRunning"]} OR {native["taskPaused"]}','JMP LBL[999]')]
            else:guard=[iff(f'{owner}<>{mode}','JMP LBL[999]')]
            save(mode,name,guard+lines)
        save(mode,prefix+'_BOOT',[
            'CALL RB_BIND',yes(b['selected']),no(b['armed']),no(b['booted']),yes(request)])
        # Tick is silent while waiting for the BG-owned lease. A released task ends.
        lines=body(art[path(mode,prefix+'_TICK')])
        pre=[iff(f'({owner}<>{mode}) AND !{request}',no(b['selected'])),
             iff(f'{owner}<>{mode}','JMP LBL[999]'),iff(b['booted'],'JMP LBL[997]'),
             yes(c['productionRequired']),no(c['appArm']),no(b['armed']),put(p['lastStart'],rx['p2r.production.startToken']),
             yes(b['booted']),iff(f'{p["state"]}<>710',yes(b['needsRecovery'])),iff(b['needsRecovery'],put(p['state'],900)),'LBL[997]']
        save(mode,prefix+'_TICK',pre+lines)
        save(mode,prefix+'_EXIT',[iff(f'{owner}<>{mode}','JMP LBL[999]'),
            iff(f'({p["state"]}<>710) AND ({p["state"]}<>900)','JMP LBL[999]'),
            iff(b['batchAssigned'],'JMP LBL[999]'),iff(f'{p["remaining"]}<>0','JMP LBL[999]'),yes(release),'LBL[999]'])
        # Every exported private routine also refuses calls without its lease.
        for item in list(art):
            if item.parent==root/'ROBOT'/folder and item.suffix=='.LS' and item.stem not in [prefix+'_INIT',prefix+'_BOOT',prefix+'_MAIN',prefix+'_TICK']:
                if item.stem.startswith(('RM_','XM_',prefix+'_')):
                    lines=body(art[item]);lines.insert(0,iff(f'{owner}<>{mode}','JMP LBL[999]'))
                    art[item]=emit(item.stem,lines,'DEFAULT_GROUP = 1,' in art[item])
    binding=json.loads((root/'ROBOT/BG/bindings.json').read_text(encoding='utf-8'))
    sources=binding['sources']
    expressions=[(raw[n],sources.get(n)) for n in list(raw)[:10]]
    expressions += [(tasks[n][key],binding.get('programs',{}).get(n,{}).get(key)) for n in tasks for key in tasks[n]]
    complete=all(expr for _,expr in expressions)
    art[root/'ROBOT/BG/RB_BIND.LS']=emit('RB_BIND',[put(gb['sourceBound'],'ON' if complete else 'OFF')])
    native_lines=[]
    for ref,expr in expressions:
        if expr:
            refs=r'(?:\$[A-Za-z_][A-Za-z0-9_.$\[\]]*|(?:UO|SI|SO|F)\[\d+\])'
            assert re.search(refs,expr),expr
            assert re.fullmatch(r'[\s0-9().!<>=+*/-]*(?:(?:AND|OR|MOD|DIV)[\s0-9().!<>=+*/-]*)*',re.sub(refs,' ',expr)),expr
            native_lines.append(put(ref,expr))
    busy={n:f'({tasks[n]["running"]} OR {tasks[n]["paused"]})' for n in tasks}
    idle=[]
    for ch in channels:idle += [f'({ch["state"]}=0)',f'!{ch["submit"]}',f'!{ch["ack"]}']
    # Chain each condition to stay within the FANUC Mixed Logic item limit.
    safe=gb['ownershipSafe']
    closed=[put(safe,f'!{rx["p2r.production.orderActive"]} AND {gb["statusValid"]} AND {raw["home"]}')]
    for cond in [rx['p2r.imm.cycleKnown'],rx['p2r.imm.settled'],f'({rx["p2r.imm.unsettledCount"]}=0)',
                 '!'+rx['p2r.imm.pickupPending']]+idle:
        closed.append(put(safe,safe+' AND '+cond))
    status=native_lines+[put(gb['statusValid'],f'{gb["sourceBound"]} AND {gb["bindingsVerified"]} AND {gb["capacityVerified"]}')]+closed
    # Explicit cold initialization; this is the only initialization path for owner.
    status += [iff(f'!{gb["initApproved"]}','JMP LBL[901]'),
               iff(f'!{safe} OR !{gb["emptyConfirmed"]}','JMP LBL[901]'),
               iff(f'{busy["box"]} OR {busy["tray"]}','JMP LBL[901]'),
               put(owner,0),yes(gb['initialized']),no(gb['initApproved']),no(gb['emptyConfirmed']),no(gb['conflict']),
               no(gb['apiBusy']),no(gb['apiValid']),no(gb['boxRequest']),no(gb['trayRequest']),no(gb['boxRelease']),no(gb['trayRelease']),
               yes(app['r2p.production.loadKnown']),put(app['r2p.production.loadMask'],0),'LBL[901]']
    status += [put(safe,safe+' AND !'+gb['apiBusy']),put(safe,safe+' AND '+app['r2p.production.loadKnown']),
               put(safe,safe+f' AND ({app["r2p.production.loadMask"]}=0)')]
    # Both native mains / both claims are a latched conflict, never a race winner.
    status += [iff(f'{busy["box"]} AND {busy["tray"]}',yes(gb['conflict'])),
               iff(f'{gb["boxRequest"]} AND {gb["trayRequest"]}',yes(gb['conflict']))]
    for mode,name in [(1,'box'),(2,'tray')]:
        m=manifests[mode];b=m['flags'];p=m['runtime'];other='tray' if name=='box' else 'box'
        status += [iff(f'({owner}<>{mode}) OR !{gb[name+"Release"]}',f'JMP LBL[{910+mode}]'),
                   iff(f'!{safe} OR !{b["stationIdleConfirmed"]}',f'JMP LBL[{910+mode}]'),
                   iff(f'{b["batchAssigned"]} OR ({p["remaining"]}<>0)',f'JMP LBL[{910+mode}]'),
                   iff(f'({p["state"]}<>710) AND ({p["state"]}<>900)',f'JMP LBL[{910+mode}]'),
                   put(owner,0),no(gb[name+'Request']),no(gb[name+'Release']),no(b['selected']),no(b['armed']),no(b['booted']),
                   no(c['appArm']),no(c['productionRequired']),no(c['productionPermit']),f'LBL[{910+mode}]']
        status += [iff(f'({owner}<>0) OR !{gb["initialized"]}',f'JMP LBL[{920+mode}]'),
                   iff(f'!{safe} OR {gb["conflict"]}',f'JMP LBL[{920+mode}]'),
                   iff(f'!{gb[name+"Request"]} OR !{busy[name]} OR {busy[other]}',f'JMP LBL[{920+mode}]'),
                   put(owner,mode),f'LBL[{920+mode}]']
    status += [no(raw['taskRunning']),no(raw['taskPaused'])]
    for mode,name in [(1,'box'),(2,'tray')]:
        status += [iff(f'{owner}={mode}',put(raw['taskRunning'],tasks[name]['running'])),
                   iff(f'{owner}={mode}',put(raw['taskPaused'],tasks[name]['paused']))]
    # The rest of each monitor is generated from the same verified template.
    for mode in (1,2):
        text=box[root/'ROBOT/BG/RB_STATUS.LS'] if mode==1 else tray[root/'ROBOT/BG/RB_STATUS.LS']
        m0=json.loads((box if mode==1 else tray)[root/f'ROBOT/{modes[mode][1]}/resources.json'])
        refs={m0['native'][k]:v for k,v in raw.items()};refs.update({m0['flags'][k]:gb[k] for k in ('statusValid','sourceBound','bindingsVerified')})
        lines=[replace_refs(v,refs) for v in body(text)]
        lines=lines[next(i for i,v in enumerate(lines) if '$FAST_CLOCK' in v):]
        lines=[v for v in lines if not v.startswith(gb['statusValid']+'=')]
        if mode==1:lines=[v.replace('=(2)','=(1)') if app['r2p.production.program']+'=' in v else v for v in lines]
        status += [iff(f'{owner}<>{mode}',f'JMP LBL[{930+mode}]')]+lines+['JMP LBL[939]',f'LBL[{930+mode}]']
    status += [put(manifests[2]['bg']['statusAt'],'$FAST_CLOCK'),put(app['r2p.production.program'],0),no(app['r2p.production.running'])]
    for n in list(raw)[:10]:status.append(put(app['r2p.production.'+n],f'{raw[n]} AND {gb["statusValid"]}'))
    for area in ('source','elevator','storage'):status.append(put(app[f'r2p.area.{area}.clear'],f'{gb["statusValid"]} AND {raw["home"]} AND !{app[f"r2p.area.{area}.accessReq"]}'))
    status += ['LBL[939]',iff(gb['conflict'],yes(c['guardRequest'])),iff(gb['conflict'],no(c['appArm'])),
               iff(gb['conflict'],no(c['productionPermit']))]
    art[root/'ROBOT/BG/RB_STATUS.LS']=emit('RB_STATUS',status)
    guard=[]
    for mode in (1,2):
        m0=json.loads((box if mode==1 else tray)[root/f'ROBOT/{modes[mode][1]}/resources.json'])
        refs={m0['native'][k]:v for k,v in raw.items()};refs.update({m0['flags'][k]:gb[k] for k in ('statusValid','sourceBound','bindingsVerified')})
        text=(box if mode==1 else tray)[root/'ROBOT/BG/RB_GUARD.LS']
        lines=[replace_refs(v,refs) for v in body(text)]
        if mode==1:lines=[v.replace(rx['p2r.production.expectedProgram']+'=2',rx['p2r.production.expectedProgram']+'=1').replace(rx['p2r.production.expectedProgram']+'<>2',rx['p2r.production.expectedProgram']+'<>1') for v in lines]
        b=manifests[mode]['flags']
        lines.insert(lines.index(no(b['guardFault']))+1,iff(gb['conflict'],yes(b['guardFault'])))
        if mode==1:
            b=manifests[mode]['flags']
            cond=f'{b["storageInside"]} AND (!{rx["p2r.area.storage.valid"]} OR !{rx["p2r.area.storage.granted"]})'
            lines.insert(lines.index(no(b['guardFault']))+1,iff(cond,yes(b['guardFault'])))
            pm=manifests[mode]['runtime']
            cond=f'{b["trayReady"]} AND ({pm["state"]}<600) AND ({pm["stackId"]}<>{rx["p2r.production.stackId"]})'
            lines.insert(lines.index(no(b['guardFault']))+1,iff(cond,yes(b['guardFault'])))
        guard += [iff(f'{owner}<>{mode}',f'JMP LBL[{940+mode}]')]+lines+['JMP LBL[949]',f'LBL[{940+mode}]']
    guard += [put(manifests[2]['bg']['guardAt'],'$FAST_CLOCK'),no(c['productionPermit']),no(c['appArm']),no(c['productionRequired']),'LBL[949]']
    for cond in [gb['conflict'],'!'+gb['statusValid'],'!'+gb['initialized']]:
        guard += [iff(cond,no(c['productionPermit'])),iff(cond,no(c['appArm']))]
    art[root/'ROBOT/BG/RB_GUARD.LS']=emit('RB_GUARD',guard)
    # Actual mode constants in BOX generated TICK (status/guard handled above).
    for item in list(art):
        if item.parent==root/'ROBOT/BOX' and item.suffix=='.LS':
            art[item]=art[item].replace(rx['p2r.production.expectedProgram']+'=2',rx['p2r.production.expectedProgram']+'=1').replace(rx['p2r.production.expectedProgram']+'<>2',rx['p2r.production.expectedProgram']+'<>1')
    for mode,m in manifests.items():art[root/f'ROBOT/{modes[mode][1]}/resources.json']=json.dumps(m,ensure_ascii=False,indent=2)+'\n'
    common_manifest=dict(status='PREPARED_NOT_COMMISSIONED',owner=owner,flags=gb,native=raw,tasks=tasks,
        api_registers=ar,api_flags=af,allocations=allocations,required_numeric_capacity=400,
        owner_values={'NONE':0,'BOX':1,'TRAY':2},reserved={'BOX_R':[201,330],'COMMON_R':[331,360],'SPARE_R':[361,400],'BOX_F':[101,300],'COMMON_F':[401,480],'BOX_PR':[41,95]})
    art[root/'ROBOT/COMMON/resources.json']=json.dumps(common_manifest,ensure_ascii=False,indent=2)+'\n'
    return art
