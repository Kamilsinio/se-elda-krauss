"""Generate the FANUC-only communication package from the canonical contract.

No device access. --check compares generated artifacts without writing files.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import io
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ROBOT/COMM'
EVENTS = ['blisterPicked','blisterPlaced','blisterFinished','spacerPlaced','productsPlaced','samplesPlaced','layerFinished','stackFinished','immPickupCompleted','rejectsPlaced']


def build(test=False):
    out = ROOT / ('ROBOT/TEST/COMM' if test else 'ROBOT/COMM')
    contract = json.loads((ROOT/'docs/robot-plc-signals.json').read_text(encoding='utf-8'))
    signals = contract['signals']
    additions={s['id'] for s in signals if s['id'] in {'p2r.imm.batchCount','p2r.production.startToken'} or '.rejectsPlaced.' in s['id']}
    mapping = []
    for direction, prefix, bool_words in [('PLC_TO_ROBOT','p2r',8),('ROBOT_TO_PLC','r2p',4)]:
        fields = [s for s in signals if s['direction']==direction and s['id'] not in additions]
        bs = sorted((s for s in fields if s['type']=='BOOL'),key=lambda s:s['id'])
        us = sorted((s for s in fields if s['type']=='UINT'),key=lambda s:(s['id'] not in [prefix+'.link.version',prefix+'.link.heartbeat'], 0 if s['id']==prefix+'.link.version' else 1 if s['id']==prefix+'.link.heartbeat' else 2,s['id']))
        for i,s in enumerate(bs):
            mapping.append(dict(id=s['id'],type='BOOL',direction=direction,word=i//16,bit=i%16,io=('DI' if prefix=='p2r' else 'DO'),number=121+i,rack=89,slot=1,port=1+i,width=1))
        for i,s in enumerate(us):
            mapping.append(dict(id=s['id'],type='UINT',direction=direction,word=bool_words+i,bit=0,io=('GI' if prefix=='p2r' else 'GO'),number=1+i,rack=89,slot=1,port=1+16*(bool_words+i),width=16))
    layout_hash=hashlib.sha256(json.dumps(mapping,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    assert contract['contract_version']==2 and layout_hash=='753c39d4c333d67d8ad09dc0988598d3d5e5ae8ece86b807a5731920ef6b7f3c', 'Wire layout changed: review and version both peers before regeneration'
    # Rozszerzenie zajmuje rezerwy v1; dotychczasowe 220 adresów pozostaje bez zmian.
    for id,bank,number,word,bit,width in [
        ('p2r.imm.batchCount','GI',27,34,0,16),
        ('p2r.production.startToken','GI',28,35,0,16),
        ('p2r.event.rejectsPlaced.ack','DI',227,6,10,1),
        ('r2p.event.rejectsPlaced.req','DO',184,3,15,1),
        ('r2p.event.rejectsPlaced.count','GO',26,29,0,16),
        ('r2p.event.rejectsPlaced.cycleId','GO',27,30,0,16),
        ('r2p.event.rejectsPlaced.stackId','GO',28,31,0,16)]:
        mapping.append(dict(id=id,type='BOOL' if width==1 else 'UINT',direction='PLC_TO_ROBOT' if id.startswith('p2r.') else 'ROBOT_TO_PLC',word=word,bit=bit,io=bank,number=number,rack=89,slot=1,port=16*word+bit+1,width=width))
    layout_hash=hashlib.sha256(json.dumps(mapping,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    assert layout_hash=='58e7661e84feb471e528d2102f5ca6862b377241f160bf8f3f650dbcdaccb87e', 'v2 layout changed: review and version both peers'
    wire={s['id']:s for s in mapping}
    assert len(wire)==227
    allocations=[]; reg=51; flag=501
    def alloc(name,bank,owner):
        nonlocal reg,flag
        n=reg if bank=='R' else flag
        if bank=='R': reg+=1
        else: flag+=1
        allocations.append(dict(name=name,bank=bank,number=n,owner=owner))
        return f'{bank}[{n}]'
    # Explicit application API, receive snapshot, mock input and frozen payloads.
    rx={s['id']:alloc('rx.'+s['id'],'R' if s['type']=='UINT' else 'F','RC_RX') for s in mapping if s['direction']=='PLC_TO_ROBOT'}
    app={s['id']:alloc('app.'+s['id'],'R' if s['type']=='UINT' else 'F','APPLICATION') for s in mapping if s['direction']=='ROBOT_TO_PLC'}
    buf={s['id']:alloc('tx.'+s['id'],'R' if s['type']=='UINT' else 'F','RC_CMD') for s in mapping if s['direction']=='ROBOT_TO_PLC' and s['type']=='BOOL'}
    frozen={s['id']:alloc('frozen.'+s['id'],'R','RC_EVENTS') for s in mapping if s['id'].startswith('r2p.event.') and s['type']=='UINT'}
    ctl={}
    for name in ['state','serviceSeq','lastServiceSeq','now','lastNow','peerChangedAt','serviceChangedAt','lastPeerHeartbeat','heartbeatAt','heartbeat','heartbeatPeriod','peerTimeout','serviceTimeout','syncTimeout','stateSince','fault','mockClock','sampleState','sampleStatus','sampleResult','testResult']:
        ctl[name]=alloc('control.'+name,'R','RC_MON' if name in ['now','lastNow','peerChangedAt','serviceChangedAt','lastPeerHeartbeat','lastServiceSeq','heartbeatAt','heartbeat'] else 'RC_LINK')
    for name in ['run','test','configured','appArm','recover','peerSeen','serviceSeen','monitorOk','clockOk','session','localReady','syncReq','syncAck','peerSyncSeen','wasSession','protocolFault','allowCommands','testFail','heartbeatPulse','allAckLow','productionRequired','productionPermit','bgHealthy','guardRequest']:
        ctl[name]=alloc('control.'+name,'F','RC_MON' if name in ['peerSeen','serviceSeen','monitorOk','clockOk'] else 'RC_LINK')
    channels=[]
    for event in EVENTS:
        channels.append(dict(name=event,kind='event',submit=app[f'r2p.event.{event}.req'],ack=rx[f'p2r.event.{event}.ack'],output=f'r2p.event.{event}.req',payload=[s['id'] for s in mapping if s['id'].startswith(f'r2p.event.{event}.') and s['type']=='UINT']))
    for n in range(1,6):
        channels.append(dict(name=f'blow{n}',kind='blow',submit=app[f'r2p.vac.{n}.blowReq'],ack=rx[f'p2r.vac.{n}.blowAck'],result=rx[f'p2r.vac.{n}.blowResult'],output=f'r2p.vac.{n}.blowReq',payload=[],number=n))
    for ch in channels:
        ch['state']=alloc('channel.'+ch['name']+'.state','R','RC_EVENTS')
        ch['status']=alloc('channel.'+ch['name']+'.status','R','RC_EVENTS')
    # Frozen payloads are re-used as output storage; no second scalar transmit copy.
    assert reg<=201, f'Register allocation exceeds 200: {reg-1}'
    assert flag<=1025, f'Flag allocation exceeds 1024: {flag-1}'
    primary_end=reg-1
    mock={};mock_reg=1
    if test:
        for item in mapping:
            if item['direction']!='PLC_TO_ROBOT':continue
            if item['type']=='UINT':
                n=mock_reg;mock_reg+=1;bank='R'
            else:
                n=flag;flag+=1;bank='F'
            allocations.append(dict(name='mock.'+item['id'],bank=bank,number=n,owner='TEST_ONLY'))
            mock[item['id']]=f'{bank}[{n}]'
    artifacts={}
    def program(name,lines,bg=False):
        body=['/PROG '+name,'/ATTR','OWNER = MNEDITOR;','COMMENT = "EIP bez ruchu";','PROTECT = READ_WRITE;','DEFAULT_GROUP = *,*,*,*,*;','CONTROL_CODE = 00000000 00000000;','/MN']
        body += [f'{i:4}:  {line} ;' for i,line in enumerate(lines,1)]
        body += ['/POS','/END']
        artifacts[out/(name+'.LS')]='\n'.join(body)+'\n'
    def setv(ref,value): return f'{ref}=({value})'
    def iff(cond,statement): return f'IF ({cond}),{statement}'
    def on(ref): return setv(ref,'ON')
    def off(ref): return setv(ref,'OFF')
    def wref(s):
        m=wire[s];return f"{m['io']}[{m['number']}]"
    # INIT changes local resources only. No writes to DO/GO, no automatic RUN.
    lines=['! Inicjalizacja tylko przy zatrzymanym SVC i BG']
    for a in allocations:lines.append(setv(f"{a['bank']}[{a['number']}]",'0' if a['bank']=='R' else 'OFF'))
    lines += [setv(ctl['test'],'ON' if test else 'OFF'),setv(ctl['heartbeatPeriod'],64),setv(ctl['peerTimeout'],512),setv(ctl['serviceTimeout'],256),setv(ctl['syncTimeout'],2048)]
    program('RC_INIT',lines)
    # RX uses an explicit, isolated mock image only in test mode.
    lines=[]
    for s in mapping:
        if s['direction']=='PLC_TO_ROBOT':
            lines.append(setv(rx[s['id']],mock[s['id']] if test else wref(s['id'])))
    program('RC_RX',lines)
    # BG scan: only mixed-logic assignments, no WAIT/CALL/backward jumps.
    lines=[setv(ctl['now'],ctl['mockClock'] if test else '$FAST_CLOCK'),setv(ctl['clockOk'],f"{ctl['now']}>={ctl['lastNow']}"),iff('!'+ctl['clockOk'],off(ctl['peerSeen'])),iff('!'+ctl['clockOk'],off(ctl['serviceSeen'])),iff('!'+ctl['clockOk'],setv(ctl['heartbeatAt'],ctl['now']))]
    peer=rx['p2r.link.heartbeat']
    lines += [iff(f"{peer}<>{ctl['lastPeerHeartbeat']}",setv(ctl['peerChangedAt'],ctl['now'])),iff(f"{peer}<>{ctl['lastPeerHeartbeat']}",on(ctl['peerSeen'])),setv(ctl['lastPeerHeartbeat'],peer),iff(f"{ctl['serviceSeq']}<>{ctl['lastServiceSeq']}",setv(ctl['serviceChangedAt'],ctl['now'])),iff(f"{ctl['serviceSeq']}<>{ctl['lastServiceSeq']}",on(ctl['serviceSeen'])),setv(ctl['lastServiceSeq'],ctl['serviceSeq'])]
    lines += [setv(ctl['bgHealthy'],f"({ctl['now']}>={ctl['mockClock']}) AND ({ctl['mockClock']}>0)"),setv(ctl['bgHealthy'],f"{ctl['bgHealthy']} AND ({ctl['now']}-{ctl['mockClock']}<{ctl['serviceTimeout']})"),setv(ctl['bgHealthy'],f"{ctl['bgHealthy']} AND ({ctl['now']}>={ctl['testResult']}) AND ({ctl['testResult']}>0)"),setv(ctl['bgHealthy'],f"{ctl['bgHealthy']} AND ({ctl['now']}-{ctl['testResult']}<{ctl['serviceTimeout']})")]
    healthy=f"{ctl['configured']} AND {ctl['run']} AND {ctl['clockOk']} AND {ctl['peerSeen']} AND {ctl['serviceSeen']} AND ({rx['p2r.link.version']}=2) AND ({ctl['now']}-{ctl['peerChangedAt']}<{ctl['peerTimeout']}) AND ({ctl['now']}-{ctl['serviceChangedAt']}<{ctl['serviceTimeout']}) AND ({ctl['heartbeatPeriod']}>0) AND ({ctl['peerTimeout']}>{ctl['heartbeatPeriod']}) AND ({ctl['serviceTimeout']}>0)"
    healthy += f" AND (!{ctl['productionRequired']} OR {ctl['bgHealthy']})"
    terms = healthy.split(' AND ')
    lines.append(setv(ctl['monitorOk'],terms[0]))
    for term in terms[1:]:
        lines.append(setv(ctl['monitorOk'],f"{ctl['monitorOk']} AND {term}"))
    # Heartbeat lives independently of application WAIT, but stops if service stops.
    hbcond=f"{ctl['run']} AND {ctl['configured']} AND {ctl['serviceSeen']} AND ({ctl['now']}-{ctl['serviceChangedAt']}<{ctl['serviceTimeout']}) AND ({ctl['now']}-{ctl['heartbeatAt']}>={ctl['heartbeatPeriod']})"
    # Save condition before updating timestamp, to avoid evaluating it twice differently.
    pulse=ctl['heartbeatPulse']
    lines += [setv(pulse,hbcond),iff(pulse,setv(ctl['heartbeat'],f"({ctl['heartbeat']}+1) MOD 65536")),iff(pulse,setv(ctl['heartbeatAt'],ctl['now'])),setv(ctl['lastNow'],ctl['now']),setv(wref('r2p.link.heartbeat'),'0' if test else ctl['heartbeat'])]
    program('RC_MON',lines,True)
    # DROP invalidates command mailboxes, retaining frozen payload and load knowledge.
    lines=[off(ctl['session']),off(ctl['localReady']),off(ctl['appArm']),off(ctl['recover']),off(ctl['wasSession']),off(ctl['peerSyncSeen']),off(ctl['syncReq']),off(ctl['syncAck']),setv(ctl['state'],0),setv(ctl['stateSince'],ctl['now'])]
    for s in mapping:
        k=s['id']
        if k.startswith(('r2p.cyl.','r2p.vac.','r2p.imm.req.','r2p.area.')) or k.startswith('r2p.event.') and s['type']=='BOOL': lines.append(off(app[k]))
    lines += [off(app['r2p.samples.ack']),setv(app['r2p.samples.result'],0),iff(f"{ctl['sampleState']}<>0",setv(ctl['sampleStatus'],900)),setv(ctl['sampleState'],0)]
    for ch in channels:lines += [iff(f"{ch['state']}<>0",setv(ch['status'],900)),setv(ch['state'],0)]
    program('RC_DROP',lines)
    # Non-blocking link state machine. Remember peer request during the full exchange.
    lines=[iff(f"!{ctl['run']} OR !{ctl['monitorOk']} OR (({ctl['protocolFault']} OR {ctl['guardRequest']}) AND ({ctl['state']}=40))",'CALL RC_DROP'),iff(f"!{ctl['run']} OR !{ctl['monitorOk']}",'JMP LBL[90]'),iff(f"({ctl['state']}=40) AND ({rx['p2r.link.syncRequest']} OR ({ctl['wasSession']} AND !{rx['p2r.link.ready']}))",'CALL RC_DROP'),setv(ctl['syncAck'],rx['p2r.link.syncRequest']),iff(rx['p2r.link.syncRequest'],on(ctl['peerSyncSeen'])),iff(f"({ctl['state']}=0) AND !{rx['p2r.link.syncAck']}",setv(ctl['stateSince'],ctl['now'])),iff(f"({ctl['state']}=0) AND !{rx['p2r.link.syncAck']}",setv(ctl['state'],10)),setv(ctl['syncReq'],f"{ctl['state']}=10"),iff(f"({ctl['state']}=10) AND {rx['p2r.link.syncAck']}",setv(ctl['state'],20)),setv(ctl['syncReq'],f"{ctl['state']}=10"),iff(f"({ctl['state']}=20) AND {ctl['peerSyncSeen']} AND !{rx['p2r.link.syncRequest']} AND !{rx['p2r.link.syncAck']}",setv(ctl['state'],30))]
    lines.append(on(ctl['allAckLow']))
    for ch in channels:lines.append(setv(ctl['allAckLow'],f"{ctl['allAckLow']} AND !{ch['ack']}"))
    recover=f"({ctl['state']}=30) AND {ctl['recover']} AND !{rx['p2r.production.recoveryRequired']} AND !{rx['p2r.production.criticalBlock']} AND {ctl['allAckLow']} AND !{rx['p2r.samples.req']}"
    lines += [iff(recover,setv(ctl['state'],40)),off(ctl['recover']),iff(f"(({ctl['state']}=10) OR ({ctl['state']}=20)) AND ({ctl['now']}-{ctl['stateSince']}>{ctl['syncTimeout']})",setv(ctl['fault'],902)),iff(f"(({ctl['state']}=10) OR ({ctl['state']}=20)) AND ({ctl['now']}-{ctl['stateSince']}>{ctl['syncTimeout']})",'CALL RC_DROP'),setv(ctl['localReady'],f"({ctl['state']}=40) AND {ctl['monitorOk']} AND !{ctl['protocolFault']} AND !{ctl['guardRequest']}"),setv(ctl['session'],f"{ctl['localReady']} AND {rx['p2r.link.ready']} AND !{rx['p2r.link.syncRequest']} AND !{rx['p2r.link.syncAck']}"),iff(ctl['session'],on(ctl['wasSession'])),'LBL[90]',iff(f"!{ctl['session']} OR {rx['p2r.production.criticalBlock']} OR {rx['p2r.production.recoveryRequired']} OR {ctl['guardRequest']}",off(ctl['appArm']))]
    program('RC_LINK',lines)
    # Independent event and blow handshakes. No pulse, no automatic retry.
    lines=[]; label=100
    for ch in channels:
        start,fail,end=label,label+1,label+2;label+=10
        lines += [f"! Kanal {ch['name']}",iff(f"!{ctl['session']} AND ({ch['state']}<>0)",setv(ch['status'],900)),iff('!'+ctl['session'],setv(ch['state'],0)),iff(f"!{ch['submit']}",f'JMP LBL[{start}]'),off(ch['submit']),iff(f"{ch['state']}<>0",setv(ctl['fault'],905)),iff(f"{ch['state']}<>0",f'JMP LBL[{start}]'),setv(ch['status'],901),iff(f"!{ctl['allowCommands']}",f'JMP LBL[{start}]'),setv(ch['status'],903),iff(ch['ack'],f'JMP LBL[{start}]'),setv(ch['status'],904)]
        for k in ch['payload']:
            ref=app[k];lines.append(iff(f"({ref}<0) OR ({ref}>65535) OR (({ref} MOD 1)<>0)",f'JMP LBL[{start}]'))
            if k.endswith('.count'):lines.append(iff(f'{ref}<1',f'JMP LBL[{start}]'))
        if ch['kind']=='blow':
            n=ch['number'];lines += [iff(f"!{app[f'r2p.vac.{n}.cmdValid']} OR {app[f'r2p.vac.{n}.hold']}",f'JMP LBL[{start}]')]
        for k in ch['payload']:lines.append(setv(frozen[k],app[k]))
        lines += [setv(ch['state'],10),setv(ch['status'],10),f'LBL[{start}]']
        if ch['kind']=='event':lines += [iff(f"({ch['state']}=10) AND {ch['ack']}",setv(ch['status'],20))]
        else:
            for value,status in [(1,20),(2,30),(3,40)]:lines.append(iff(f"({ch['state']}=10) AND {ch['ack']} AND ({ch['result']}={value})",setv(ch['status'],status)))
            bad=f"({ch['state']}=10) AND {ch['ack']} AND (({ch['result']}<1) OR ({ch['result']}>3) OR (({ch['result']} MOD 1)<>0))"
            lines += [iff(bad,on(ctl['protocolFault'])),iff(bad,setv(ctl['fault'],906))]
        lines += [iff(f"({ch['state']}=10) AND {ch['ack']}",setv(ch['state'],20)),iff(f"({ch['state']}=20) AND !{ch['ack']}",setv(ch['state'],0)),setv(buf[ch['output']],f"({ch['state']}=10) AND {ctl['session']}")]
    program('RC_EVENTS',lines)
    # Incoming sample request: caller decides acceptance, service holds response.
    lines=[iff('!'+ctl['session'],setv(ctl['sampleState'],0)),iff(f"({ctl['sampleState']}=0) AND {ctl['session']} AND {rx['p2r.samples.req']}",setv(ctl['sampleStatus'],10)),iff(f"({ctl['sampleState']}=0) AND {ctl['session']} AND {rx['p2r.samples.req']}",setv(ctl['sampleState'],10)),iff(f"({ctl['sampleState']}=10) AND !{rx['p2r.samples.req']}",setv(ctl['sampleState'],0))]
    invalid=f"({ctl['sampleState']}=10) AND {app['r2p.samples.ack']} AND ({app['r2p.samples.result']}<>1) AND ({app['r2p.samples.result']}<>2)"
    lines += [iff(invalid,setv(ctl['sampleStatus'],904))]
    for result in [1,2]:
        cond=f"({ctl['sampleState']}=10) AND {app['r2p.samples.ack']} AND ({app['r2p.samples.result']}={result})"
        lines += [iff(cond,setv(ctl['sampleResult'],str(result))),iff(cond,setv(ctl['sampleStatus'],'20' if result==1 else '30')),iff(cond,setv(ctl['sampleState'],20))]
    lines += [off(app['r2p.samples.ack']),iff(f"({ctl['sampleState']}=20) AND !{rx['p2r.samples.req']}",setv(ctl['sampleState'],0)),setv(buf['r2p.samples.ack'],f"({ctl['sampleState']}=20) AND {ctl['session']}")]
    program('RC_SMPL',lines)
    # Level command helpers. Applications own desired state, helpers own validation.
    lines=[]
    for n in range(501,506):
        h=app[f'r2p.cyl.V{n}.home'];w=app[f'r2p.cyl.V{n}.work'];lines += [iff(f'{h} AND {w}',setv(ctl['fault'],907)),setv(buf[f'r2p.cyl.V{n}.home'],f"{h} AND !{w} AND {ctl['allowCommands']}"),setv(buf[f'r2p.cyl.V{n}.work'],f"{w} AND !{h} AND {ctl['allowCommands']}")]
    program('RC_CYL',lines)
    lines=[]
    for n in range(1,6):
        for field in ['cmdValid','hold']:
            k=f'r2p.vac.{n}.{field}';lines.append(setv(buf[k],f"{app[k]} AND {ctl['allowCommands']}"))
    program('RC_VAC',lines)
    for pname,prefix in [('RC_AREA','r2p.area.'),('RC_IMM','r2p.imm.req.')]:
        lines=[]
        for k in app:
            if k.startswith(prefix):
                gate=ctl['session'] if pname=='RC_AREA' else ctl['allowCommands']
                lines.append(setv(buf[k],f"{app[k]} AND {gate}"))
        program(pname,lines)
    # CMD always creates a complete image. Data fields never masquerade as permits.
    lines=[]
    for k in buf:lines.append(setv(buf[k],app[k]))
    for k,ref in app.items():
        if k.startswith('r2p.production.') and ref.startswith('R['):
            bad=f"({ref}<0) OR ({ref}>65535) OR (({ref} MOD 1)<>0)"
            lines += [iff(bad,on(ctl['protocolFault'])),iff(bad,setv(ctl['fault'],908))]
    lines += [setv(ctl['allowCommands'],ctl['session']),setv(ctl['allowCommands'],f"{ctl['allowCommands']} AND !{ctl['protocolFault']} AND !{ctl['guardRequest']}"),setv(ctl['allowCommands'],f"{ctl['allowCommands']} AND {ctl['appArm']}"),setv(ctl['allowCommands'],f"{ctl['allowCommands']} AND !{rx['p2r.production.criticalBlock']} AND !{rx['p2r.production.recoveryRequired']}"),setv(ctl['allowCommands'],f"{ctl['allowCommands']} AND ({rx['p2r.production.newOperationPermit']} OR {rx['p2r.production.finishPermit']})"),setv(ctl['allowCommands'],f"{ctl['allowCommands']} AND (!{ctl['productionRequired']} OR {ctl['productionPermit']})"),setv(buf['r2p.link.ready'],ctl['localReady']),setv(buf['r2p.link.syncRequest'],ctl['syncReq']),setv(buf['r2p.link.syncAck'],ctl['syncAck']),'CALL RC_CYL','CALL RC_VAC','CALL RC_AREA','CALL RC_IMM','CALL RC_EVENTS','CALL RC_SMPL']
    program('RC_CMD',lines)
    # One physical writer for every output except heartbeat. During test every output is zero.
    lines=[]
    for s in mapping:
        k=s['id']
        if s['direction']!='ROBOT_TO_PLC' or k=='r2p.link.heartbeat':continue
        val=buf[k] if s['type']=='BOOL' else frozen.get(k,app[k])
        if k=='r2p.link.version':val='2'
        if k=='r2p.samples.result':val=ctl['sampleResult']
        if test:
            lines.append(setv(wref(k),'OFF' if s['type']=='BOOL' else '0'))
        elif s['type']=='UINT':
            valid=f"({val}>=0) AND ({val}<=65535) AND (({val} MOD 1)=0)"
            lines += [iff(f"!{ctl['test']} AND ({valid})",setv(wref(k),val)),iff(f"{ctl['test']} OR !({valid})",setv(wref(k),'0'))]
        else:
            lines += [iff('!'+ctl['test'],setv(wref(k),val)),iff(ctl['test'],setv(wref(k),'OFF'))]
    program('RC_TX',lines)
    program('RC_TICK',['CALL RC_RX','CALL RC_LINK','CALL RC_CMD',iff(f"{ctl['protocolFault']} AND ({ctl['state']}=40)",'CALL RC_DROP'),iff(ctl['protocolFault'],'CALL RC_CMD'),'CALL RC_TX',setv(ctl['serviceSeq'],f"({ctl['serviceSeq']}+1) MOD 65536")])
    program('RC_SVC',['! Jedyna petla obslugi zadan','LBL[1]','CALL RC_TICK','WAIT   .02(sec)',iff(ctl['run'],'JMP LBL[1]'),'CALL RC_DROP','CALL RC_CMD','CALL RC_TX'])
    program('RC_LIVE',(['JMP LBL[90]'] if test else [])+['! Najpierw konfiguracja i zatwierdzenie zasobow',iff('!'+ctl['configured'],'JMP LBL[90]'),off(ctl['test']),on(ctl['run']),'RUN RC_SVC','LBL[90]'])
    # Recovery is an explicit manual/application decision, not a RESET side effect.
    program('RC_RECOV',[iff(f"{ctl['state']}<>30",'JMP LBL[90]'),off(ctl['protocolFault']),on(ctl['recover']),'LBL[90]'])
    if test:
        # Real LS smoke test against the internal mock image; leaves network disabled.
        products=next(ch for ch in channels if ch['name']=='productsPlaced')
        lines=['! Zatrzymac SVC i BG przed testem','CALL RC_INIT',on(ctl['configured']),on(ctl['run']),setv(ctl['testResult'],0),setv(mock['p2r.link.version'],2),on(mock['p2r.link.syncRequest']),setv(mock['p2r.link.heartbeat'],1),setv(ctl['mockClock'],1),'CALL RC_RX','CALL RC_MON','CALL RC_TICK',setv(mock['p2r.link.heartbeat'],2),setv(ctl['mockClock'],2),'CALL RC_RX','CALL RC_MON','CALL RC_TICK',on(mock['p2r.link.syncAck']),'CALL RC_TICK',off(mock['p2r.link.syncRequest']),off(mock['p2r.link.syncAck']),'CALL RC_TICK','CALL RC_RECOV','CALL RC_TICK',on(mock['p2r.link.ready']),on(mock['p2r.production.newOperationPermit']),on(ctl['appArm']),setv(app['r2p.event.productsPlaced.count'],7),setv(app['r2p.event.productsPlaced.cycleId'],32768),setv(app['r2p.event.productsPlaced.stackId'],65535),on(products['submit']),'CALL RC_TICK',iff(f"{products['state']}<>10",on(ctl['testFail'])),setv(app['r2p.event.productsPlaced.count'],99),'CALL RC_TICK',iff(f"{frozen['r2p.event.productsPlaced.count']}<>7",on(ctl['testFail'])),on(mock['p2r.event.productsPlaced.ack']),'CALL RC_TICK',iff(f"{products['status']}<>20",on(ctl['testFail'])),off(mock['p2r.event.productsPlaced.ack']),'CALL RC_TICK',iff(f"{products['state']}<>0",on(ctl['testFail'])),setv(ctl['testResult'],1),iff(ctl['testFail'],setv(ctl['testResult'],900)),off(ctl['run']),off(ctl['configured'])]
        program('RC_TEST',lines)
    profile=dict(contract_version=2,profile='TEST_ISOLATED' if test else 'LIVE',layout_sha256=layout_hash,status='PREPARED_NOT_COMMISSIONED',words_per_direction=40,bytes_per_direction=80,rack=89,slot=1,config_assembly=100,plc_to_robot_assembly=151,robot_to_plc_assembly=101,word_byte_order='little',bit_order='LSB0',signals=mapping)
    resources=dict(status='RESERVED_OFFLINE_VERIFY_BEFORE_IMPORT',profile='TEST_ISOLATED' if test else 'LIVE',register_range=[51,primary_end],mock_register_range=[1,mock_reg-1] if test else None,flag_range=[501,flag-1],clock_source='$FAST_CLOCK',clock_units='raw_ticks; verify rate on V9.40 before commissioning',controls=ctl,rx=rx,mock=mock,application=app,output_bool=buf,frozen_payload=frozen,channels=channels,allocations=allocations)
    artifacts[out/'mapping.json']=json.dumps(profile,ensure_ascii=False,indent=2)+'\n'
    artifacts[out/'resources.json']=json.dumps(resources,ensure_ascii=False,indent=2)+'\n'
    stream=io.StringIO(newline='');writer=csv.DictWriter(stream,fieldnames=list(mapping[0]),lineterminator='\n');writer.writeheader();writer.writerows(mapping);artifacts[out/'mapping.csv']=stream.getvalue()
    return artifacts


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
    artifacts={**build(),**build(test=True)};different=[]
    for path,text in artifacts.items():
        if args.check:
            if not path.exists() or path.read_text(encoding='utf-8')!=text.replace('\r\n','\n'):different.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8',newline='\n')
    if different:raise SystemExit('Generated files differ: '+', '.join(different))
    print(('Checked' if args.check else 'Generated'),len(artifacts),'FANUC artifacts; no device access')

if __name__=='__main__':main()
