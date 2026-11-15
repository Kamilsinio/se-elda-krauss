"""BOX specialization of the production template. All coordinates remain untaught."""
from __future__ import annotations
from pathlib import Path

def configure(mode):
    import build_fanuc_tray as base
    cfg=list(base.CFG); runtime=list(base.RUNTIME); flags=list(base.FLAGS); points=dict(base.POINTS)
    if mode=='BOX':
        cfg += [f'p{j}{key}' for j in (2,3) for key in ('X','Y','pitchX','pitchY')]
        cfg += [f'cylGroup{i}' for i in range(1,6)]+['productClearance','spacerClearance']
        runtime += ['sectionIndex','sectionCapacity','loadKind']
        flags += ['spacerNeeded','spacerStarted','terminalPending','storageInside']
        for j in (2,3):
            for i in range(1,6):points[80+(j-2)*5+i-1]=f'P{j}_PRODUCT_GROUP_{i}'
        for n in (4,5,6):points[n]=points[n].replace('SOURCE','SPACER')
        points.update({n:'RESERVE' for n in range(90,96)})
        points[9]='SPACER_APPROACH_FIRST_LAYER';points[10]='SPACER_PLACE_FIRST_LAYER';points[35]='SPACER_LIFT'
    return cfg,runtime,flags,points

def extend(x):
    p=x['p'];a=x['active'];s=x['staging'];b=x['b'];c=x['c'];rx=x['rx'];app=x['app']
    ls=x['ls'];put=x['put'];yes=x['yes'];no=x['no'];iff=x['iff'];goto=x['goto'];checked=x['checked']
    state=x['state'];states=x['states'];moved=x['moved'];wait=x['wait'];art=x['artifacts'];root=Path(__file__).resolve().parents[1]
    bit=x['bit'];fail=x['fail'];taught=x['taught']
    # Additional P2/P3 bases get their own approval flags (PR80..89).
    for n in range(80,90):taught[str(n)]=x['flag']('taught.PR'+str(n))
    init_path=root/'ROBOT/TRAY/RT_INIT.LS'
    init_lines=[v.split(':  ',1)[1].rsplit(' ;',1)[0] for v in art[init_path].splitlines() if ':  ' in v]
    init_lines[-1:-1]=[no(taught[str(n)]) for n in range(80,90)]
    ls('RT_INIT',init_lines)
    # Extend APPLY before copying, so a bad candidate never partially changes active parameters.
    path=root/'ROBOT/TRAY/RT_APPLY.LS'
    text=art[path];lines=[v.split(':  ',1)[1].rsplit(' ;',1)[0] for v in text.splitlines() if ':  ' in v]
    insert=next(i for i,v in enumerate(lines) if v==put(a['mask1'],s['mask1']))
    validation=[]
    for j in (2,3):
        gx=s[f'p{j}X'];gy=s[f'p{j}Y']
        for k in ('X','Y'):
            v=s[f'p{j}{k}'];validation.append(iff(f'({v}<0) OR ({v}>65535) OR (({v} MOD 1)<>0)',no(b['candidateValid'])))
        validation += [iff(f'(({gx}=0) AND ({gy}<>0)) OR (({gx}<>0) AND ({gy}=0))',no(b['candidateValid'])),
                       iff(f'{gx}*{gy}>65535',no(b['candidateValid'])),
                       iff(f'({gx}*{gy}) MOD {p["groupCount"]}<>0',no(b['candidateValid']))]
    for key in ['productClearance','spacerClearance']:
        validation.append(iff(f'{s[key]}<1',no(b['candidateValid'])))
    for i in range(1,6):
        v=s[f'cylGroup{i}']
        validation.append(iff(f'({v}<0) OR ({v}>1023) OR (({v} MOD 1)<>0)',no(b['candidateValid'])))
        for j in range(5):validation.append(iff(f'({bit(v,j)}) AND ({bit(v,j+5)})',no(b['candidateValid'])))
        # Each fitted cylinder must have an explicit target in each phase.
        for j in range(5):
            fitted=f'({bit(s["cylFold"],j)}) OR ({bit(s["cylFold"],j+5)})'
            validation += [put(b['safe'],s[f'qty{i}']+'>0'),put(b['deviceDone'],fitted),put(b['safe'],b['safe']+' AND '+b['deviceDone']),put(b['safe'],b['safe']+' AND !('+bit(v,j)+')'),put(b['safe'],b['safe']+' AND !('+bit(v,j+5)+')'),iff(b['safe'],no(b['candidateValid']))]
    validation += [iff('!'+b['candidateValid'],'JMP LBL[9000]')]
    ls('RT_APPLY',lines[:insert]+validation+lines[insert:])
    ls('RT_SECT',[put(p['sectionCapacity'],a['gridX']+'*'+a['gridY'])]+[
        iff(f'{p["sectionIndex"]}={j}',put(p['sectionCapacity'],a[f'p{j}X']+'*'+a[f'p{j}Y'])) for j in (2,3)])
    lines=['PR[29]=LPOS-LPOS',f'PR[29,3]={p["trayIndex"]}*{a["trayHeight"]}']
    for j in (1,2,3):
        gx=a['gridX'] if j==1 else a[f'p{j}X'];px=a['pitchX'] if j==1 else a[f'p{j}pitchX'];py=a['pitchY'] if j==1 else a[f'p{j}pitchY']
        lines += [iff(f'{p["sectionIndex"]}<>{j}',f'JMP LBL[{j}]'),
                  f'PR[29,1]=({p["slot"]} MOD {gx})*{px}',f'PR[29,2]=({p["slot"]} DIV {gx})*{py}',f'LBL[{j}]']
    ls('RT_OFFSET',lines,motion=True)
    # Per group: approach above its own section base, cylinder target, descend, release,
    # lift at the same XY, then home cylinders. No lateral move while extended.
    for i in range(1,6):
        for suffix,lift in [('',False),('UP',True)]:
            lines=[no(b['motionDone']),f'UTOOL_NUM={a["tool"]}',f'UFRAME_NUM={a["frame"]}']
            for j in (1,2,3):
                n=17+i if j==1 else 80+(j-2)*5+i-1
                lines += [iff(f'{p["sectionIndex"]}<>{j}',f'JMP LBL[{j}]'),'CALL RT_SAFE',
                          iff('!'+b['safe'],'JMP LBL[999]'),iff('!'+taught[str(n)],'JMP LBL[9000]'),
                          f'PR[31]=PR[{n}]+PR[29]']
                if lift:
                    lines += [f'PR[31,3]=PR[31,3]+{a["productClearance"]}',f'L PR[31] {a["speed"]}mm/sec FINE']
                else:
                    lines += [f'PR[31,3]=PR[31,3]+{a["productClearance"]}',f'L PR[31] {a["speed"]}mm/sec FINE',
                              'CALL RT_SAFE',iff('!'+b['safe'],'JMP LBL[999]'),f'PR[31]=PR[{n}]+PR[29]',f'L PR[31] {a["speed"]}mm/sec FINE']
                lines += [yes(b['motionDone']),'JMP LBL[999]',f'LBL[{j}]']
            lines += ['LBL[9000]']+fail(2101)+['LBL[999]'];ls(f'RM_PROD{i}{suffix}',lines,motion=True)
    # Spacer approach/place/lift are based on the top of the first product layer.
    for name,n,clearance in [('RM_TRAYIN',10,False),('RM_TRAYOUT',10,True)]:
        lines=[no(b['motionDone']),f'UTOOL_NUM={a["tool"]}',f'UFRAME_NUM={a["frame"]}',
               'CALL RT_SAFE',iff('!'+b['safe'],'JMP LBL[999]'),iff('!'+taught[str(n)],'JMP LBL[9000]'),
               f'PR[31]=PR[{n}]',f'PR[31,3]=PR[31,3]+{p["trayIndex"]}*{a["trayHeight"]}']
        if not clearance:
            at=next(k for k,v in enumerate(lines) if v.startswith('PR[31]='))
            lines[at:at]=[iff('!'+taught['8'],'JMP LBL[9000]'),f'J PR[8] {a["speed"]}% FINE','CALL RT_SAFE',iff('!'+b['safe'],'JMP LBL[999]')]
        if clearance:lines += [f'PR[31,3]=PR[31,3]+{a["spacerClearance"]}',f'L PR[31] {a["speed"]}mm/sec FINE']
        else:
            lines += [f'PR[31,3]=PR[31,3]+{a["spacerClearance"]}',f'L PR[31] {a["speed"]}mm/sec FINE',
                      'CALL RT_SAFE',iff('!'+b['safe'],'JMP LBL[999]'),f'PR[31,3]=PR[31,3]-{a["spacerClearance"]}',f'L PR[31] {a["speed"]}mm/sec FINE']
        if clearance:
            lines += ['CALL RT_SAFE',iff('!'+b['safe'],'JMP LBL[999]'),iff('!'+taught['11'],'JMP LBL[9000]'),f'J PR[11] {a["speed"]}% FINE']
        lines += [yes(b['motionDone']),'JMP LBL[999]','LBL[9000]']+fail(2101)+['LBL[999]'];ls(name,lines,motion=True)
    states[340]['lines'].insert(0,put(p['loadKind'],1))
    # Additional wrappers use existing v2 channels; numbering is internal only.
    for event,name in [('layerFinished','RE_LAYER'),('spacerPlaced','RE_SPACER')]:
        ch=x['channels'][event];lines=[no(b['eventDone']),iff(f'({ch["state"]}<>0) OR {ch["submit"]}','JMP LBL[999]')]
        for key in ch['payload']:
            lines.append(put(app[key],p['stackId'] if key.endswith('.stackId') else p['trayIndex']))
        ls(name,lines+[yes(ch['submit']),'LBL[999]'])
    done=root/'ROBOT/TRAY/RE_DONE.LS'
    lines=[v.split(':  ',1)[1].rsplit(' ;',1)[0] for v in art[done].splitlines() if ':  ' in v]
    for code,event in [(9,'layerFinished'),(10,'spacerPlaced')]:
        ch=x['channels'][event]
        lines.append(iff(f'({p["work"]}={code}) AND ({ch["state"]}=0) AND ({ch["status"]}=20) AND !{ch["submit"]}',yes(b['eventDone'])))
        for status in [900,901,903,904]:
            lines.append(iff(f'({p["work"]}={code}) AND !{ch["submit"]} AND ({ch["status"]}={status})',yes(b['needsRecovery'])))
    ls('RE_DONE',lines)
    for n in list(states):
        if 200<=n<300:del states[n]
    state(200,'Oczekiwanie na pojemnik',[wait(60),iff(f'({rx["p2r.production.stopRequest"]} OR {rx["p2r.production.endOrderRequest"]}) AND {rx["p2r.imm.settled"]} AND ({rx["p2r.imm.unsettledCount"]}=0)',goto(700)),iff(f'{p["state"]}=700','JMP LBL[999]'),iff(f'{rx["p2r.area.elevator.valid"]} AND {rx["p2r.area.elevator.ready"]}',goto(210))])
    state(210,'Pojemnik przygotowany',[put(p['stackId'],rx['p2r.production.stackId']),yes(b['trayReady']),goto(10)])
    # NEW establishes first layer and P1 only on explicit empty-station confirmation.
    path=root/'ROBOT/TRAY/RT_NEW.LS'
    lines=[v.split(':  ',1)[1].rsplit(' ;',1)[0] for v in art[path].splitlines() if ':  ' in v]
    pos=next(i for i,v in enumerate(lines) if v.startswith(p['slot']+'='))
    lines[pos:pos]=[put(p['sectionIndex'],1),put(p['loadKind'],0),no(b['spacerNeeded']),no(b['spacerStarted']),no(b['terminalPending'])]
    ls('RT_NEW',lines)
    # Never reconstruct an uncertain layer/spacer/stack ACK automatically.
    path=root/'ROBOT/TRAY/RT_RECOV.LS'
    lines=[v.split(':  ',1)[1].rsplit(' ;',1)[0] for v in art[path].splitlines() if ':  ' in v]
    lines.insert(0,iff(f'{b["terminalPending"]} OR {b["spacerStarted"]} OR ({p["loadKind"]}=2)','JMP LBL[999]'))
    lines.insert(1,'CALL RT_SECT')
    lines=[v.replace(a['gridX']+'*'+a['gridY'],p['sectionCapacity']) for v in lines]
    ls('RT_RECOV',lines)
    # Replace idle explicitly to keep ordering easy to audit.
    stop=f'{rx["p2r.production.stopRequest"]} OR {rx["p2r.production.endOrderRequest"]}'
    settled=f'{rx["p2r.imm.settled"]} AND ({rx["p2r.imm.unsettledCount"]}=0)'
    state(10,'Gotowosc pojemnika i przypisanie partii',[
        wait(20),iff('!'+b['armed'],'JMP LBL[999]'),
        iff(b['fullStackWait'],goto(620)),iff(b['fullStackWait'],'JMP LBL[999]'),
        iff(b['spacerNeeded'],goto(540)),iff(b['spacerNeeded'],'JMP LBL[999]'),
        iff(f'({stop}) AND {settled}',goto(700)),iff(f'{p["state"]}=700','JMP LBL[999]'),
        iff('!'+b['trayReady'],goto(200)),iff('!'+b['trayReady'],'JMP LBL[999]'),
        'CALL RT_SECT',iff(rx['p2r.imm.pickupPending'],'CALL RT_ASSIGN'),iff(b['needsRecovery'],'JMP LBL[9000]'),
        iff(b['batchAssigned'],goto(300))])
    # Apply per-group cylinder target before approaching product/sample location.
    states[420]['lines']=[v.replace('CALL RG_FOLD','CALL RG_TARGET') for v in states[420]['lines']]
    states[415]['lines']=[v.replace('CALL RG_FOLD','CALL RG_TARGET') for v in states[415]['lines']]
    states[400]['lines'].insert(1,put(p['capacity'],a['cylGroup1']))
    for i in range(2,6):states[400]['lines'].insert(i,iff(f'{p["group"]}={i}',put(p['capacity'],a[f'cylGroup{i}'])))
    states[430]['lines']=[v.replace(a['gridX']+'*'+a['gridY'],p['sectionCapacity']) for v in states[430]['lines']]
    state(480,'Podniesienie po zwolnieniu',[
        no(b['motionDone'])]+[iff(f'({p["destination"]}=0) AND ({p["group"]}={i+1})',f'CALL RM_PROD{i}UP') for i in range(1,6)]+[
        iff(f'{p["destination"]}<>0','CALL RM_SAMPLEOUT'),iff(b['motionDone'],goto(482))])
    state(482,'Powrot silownikow po podniesieniu',['CALL RG_FOLD',iff(b['cylDone'],goto(484))])
    state(484,'Wyjazd z obszaru odkladania',[
        iff(f'{p["destination"]}=0','CALL RM_PLACEOUT'),iff(f'{p["destination"]}<>0',yes(b['motionDone'])),iff(b['motionDone'],goto(485))])
    state(490,'Partia rozliczona',[
        iff(f'{p["remaining"]}<>0','JMP LBL[9000]'),no(b['batchAssigned']),no(b['pickupConfirmed']),no(b['cfgFrozen']),put(p['loadKind'],0),goto(10),
        iff(f'({p["destination"]}=0) AND ({p["slot"]}={p["sectionCapacity"]})',goto(495))])
    state(495,'Nastepna sekcja albo koniec warstwy',[
        iff(f'({p["sectionIndex"]}=1) AND ({a["p2X"]}>0)',goto(496)),iff(f'{p["state"]}=496','JMP LBL[999]'),
        iff(f'({p["sectionIndex"]}<3) AND ({a["p3X"]}>0)',goto(497)),iff(f'{p["state"]}=497','JMP LBL[999]'),goto(500)])
    state(496,'Sekcja P2',[put(p['sectionIndex'],2),put(p['slot'],0),goto(10)])
    state(497,'Sekcja P3',[put(p['sectionIndex'],3),put(p['slot'],0),goto(10)])
    state(500,'Zdarzenie konca warstwy',[yes(b['terminalPending']),'CALL RE_LAYER',goto(510)])
    state(510,'ACK warstwy',[put(p['work'],9),wait(70),'CALL RE_DONE',iff(b['eventDone'],no(b['terminalPending'])),iff(b['eventDone'],goto(520))])
    state(520,'Przekladka tylko pomiedzy warstwami',[
        iff(f'{p["trayIndex"]}+1={a["traysPerStack"]}',goto(600)),iff(f'{p["state"]}=600','JMP LBL[999]'),
        yes(b['spacerNeeded']),goto(540)])
    cancel=[iff(f'!{b["spacerStarted"]} AND ({stop}) AND {settled}',no(app['r2p.area.storage.accessReq'])),
            iff(f'!{b["spacerStarted"]} AND ({stop}) AND {settled}',yes(b['storageExited'])),
            iff(f'!{b["spacerStarted"]} AND ({stop}) AND {settled}',goto(700)),iff(f'{p["state"]}=700','JMP LBL[999]')]
    state(540,'Zadanie przekladki',cancel+[yes(app['r2p.area.storage.accessReq']),no(b['storageExited']),goto(545)])
    state(545,'Oczekiwanie na magazyn przekladek',cancel+[wait(60),
        iff(f'{rx["p2r.area.storage.valid"]} AND {rx["p2r.area.storage.granted"]} AND {rx["p2r.area.storage.ready"]}',goto(550))])
    state(550,'Rozpoczecie pobrania przekladki',cancel+[
        'CALL RG_FOLD',iff('!'+b['cylDone'],'JMP LBL[999]'),
        iff(f'!{rx["p2r.area.storage.valid"]} OR !{rx["p2r.area.storage.granted"]}','JMP LBL[999]'),
        yes(b['spacerStarted']),yes(b['storageInside']),put(p['loadKind'],2),
        put(p['mask'],a['trayMask']),put(p['searchDepth'],0),put(p['attempt'],0)]+moved('RM_SRCIN',560))
    empty=[]
    for i in range(5):checked(empty,f'!({bit(a["trayMask"],i)}) OR !{rx[f"p2r.vac.{i+1}.ok"]}',1502)
    states[550]['lines'][len(cancel):len(cancel)]=empty
    state(560,'Proznia przekladki',['CALL RG_VACON',iff(b['vacDone'],goto(570)),iff('!'+b['vacDone'],goto(565))])
    state(565,'Ograniczone szukanie przekladki',[
        wait(50),'CALL RG_VACON',iff(b['vacDone'],goto(570)),iff(b['vacDone'],'JMP LBL[999]'),
        iff(f'{c["now"]}-{p["phaseSince"]}<{a["timeout"]}','JMP LBL[999]'),
        put(p['searchDepth'],p['searchDepth']+'+'+a['searchStep']),put(p['attempt'],p['attempt']+'+1'),
        iff(f'({p["searchDepth"]}>{a["searchLimit"]}) OR ({p["attempt"]}>{a["maxAttempts"]})','JMP LBL[9000]')]+moved('RM_SEARCH',560))
    state(570,'Podniesienie przekladki',[put(app['r2p.production.loadMask'],a['trayMask']),yes(app['r2p.production.loadKnown'])]+moved('RM_SRCOUT',575))
    state(575,'Wyjazd z magazynu',[yes(b['storageExited']),no(b['storageInside']),no(app['r2p.area.storage.accessReq']),
        yes(app['r2p.area.elevator.accessReq']),no(b['elevatorExited']),goto(580)])
    state(580,'Odlozenie przekladki',[wait(60),iff(f'!{rx["p2r.area.elevator.valid"]} OR !{rx["p2r.area.elevator.granted"]}','JMP LBL[999]'),
        yes(b['elevatorInside'])]+moved('RM_TRAYIN',585))
    state(585,'Zwolnienie przekladki',['CALL RG_RELEASE',goto(586)])
    state(586,'Potwierdzenie zwolnienia przekladki',[wait(50),'CALL RG_RELEASED',iff('!'+b['releaseDone'],'JMP LBL[999]'),
        yes(b['terminalPending']),'CALL RE_SPACER',goto(590)])
    state(590,'ACK przekladki',[put(p['work'],10),wait(70),'CALL RE_DONE',iff(b['eventDone'],no(b['terminalPending'])),iff(b['eventDone'],goto(595))])
    state(595,'Wyjazd po przekladce',moved('RM_TRAYOUT',598))
    state(598,'Nowa warstwa',[yes(b['elevatorExited']),no(b['elevatorInside']),no(app['r2p.area.elevator.accessReq']),
        no(b['spacerNeeded']),no(b['spacerStarted']),put(p['loadKind'],0),put(p['trayIndex'],p['trayIndex']+'+1'),
        put(p['sectionIndex'],1),put(p['slot'],0),goto(10)])
    states[600]['lines'].insert(0,yes(b['terminalPending']))
    states[610]['lines'].insert(-1,iff(b['eventDone'],no(b['terminalPending'])))
    states[620]['lines'] += [iff(f'{p["state"]}=10',no(b['trayReady'])),iff(f'{p["state"]}=10',put(p['sectionIndex'],1)),iff(f'{p["state"]}=10',put(p['slot'],0))]
