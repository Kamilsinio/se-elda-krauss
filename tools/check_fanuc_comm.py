"""Offline checks of emitted LS, using a deliberately limited LS interpreter.

This is not a FANUC compiler, motion simulator, scanner or device connection.
"""
from __future__ import annotations
import ast
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
COMM = ROOT/'ROBOT/TEST/COMM'
RES = json.loads((COMM/'resources.json').read_text(encoding='utf-8'))
MAP = json.loads((COMM/'mapping.json').read_text(encoding='utf-8'))
REF = r'(?:(?:R|F|DI|DO|GI|GO|UO|SI|SO)\[\d+\]|PR\[\d+(?:,\d+)?\])'


def expression(source):
    native=r'\$[A-Za-z_][A-Za-z0-9_.$\[\]]*'
    source = re.sub(native+'|'+REF, lambda m: f'read("{m[0]}")', source)
    source = source.replace('LPOS-LPOS','read("ZERO_OFFSET")')
    source = re.sub(r'\bON\b','True',source)
    source = re.sub(r'\bOFF\b','False',source)
    source = source.replace('<>','!=')
    source = re.sub(r'(?<![<>!=])=(?!=)','==',source)
    source = re.sub(r'!(?!=)',' not ',source)
    for old,new in [('AND','and'),('OR','or'),('MOD','%'),('DIV','//')]:
        source = re.sub(r'\b'+old+r'\b',new,source)
    tree = ast.parse(source.strip(),mode='eval')
    allowed = (ast.Expression,ast.BoolOp,ast.BinOp,ast.UnaryOp,ast.Compare,
               ast.Call,ast.Name,ast.Load,ast.Constant,ast.And,ast.Or,ast.Not,
               ast.USub,ast.UAdd,ast.Add,ast.Sub,ast.Mult,ast.Div,ast.FloorDiv,
               ast.Mod,ast.Eq,ast.NotEq,ast.Lt,ast.LtE,ast.Gt,ast.GtE)
    for node in ast.walk(tree):
        assert isinstance(node,allowed), ast.dump(node)
        if isinstance(node,ast.Call):
            assert isinstance(node.func,ast.Name) and node.func.id=='read'
            assert len(node.args)==1 and isinstance(node.args[0],ast.Constant)
            assert re.fullmatch(REF+'|'+native+r'|ZERO_OFFSET',node.args[0].value)
        if isinstance(node,ast.Name):assert node.id=='read'
    return compile(tree,'<LS expression>','eval')


def instruction(line):
    if line.startswith('!'):return ('comment',)
    m=re.fullmatch(r'SELECT (R\[\d+\])=(\d+),CALL (\w+)',line)
    if m:return ('selection_start',m[1],int(m[2]),m[3])
    m=re.fullmatch(r'=(\d+),CALL (\w+)',line)
    if m:return ('selection_case',int(m[1]),m[2])
    m=re.fullmatch(r'ELSE,CALL (\w+)',line)
    if m:return ('selection_else',m[1])
    m=re.fullmatch(r'IF \((.*)\),(.*)',line)
    if m:return ('if',expression(m[1]),instruction(m[2]))
    m=re.fullmatch(r'('+REF+r')=\((.*)\)',line)
    if m:return ('set',m[1],expression(m[2]))
    m=re.fullmatch(r'(CALL|RUN) (\w+)',line)
    if m:return (m[1].lower(),m[2])
    m=re.fullmatch(r'(JMP LBL|LBL)\[(\d+)\]',line)
    if m:return ('jmp' if m[1]=='JMP LBL' else 'label',int(m[2]))
    m=re.fullmatch(r'(PR\[\d+(?:,\d+)?\])=(.*)',line)
    if m:return ('set',m[1],expression(m[2]))
    m=re.fullmatch(r'(UTOOL_NUM|UFRAME_NUM)=(R\[\d+\])',line)
    if m:return ('setting',m[1],m[2])
    m=re.fullmatch(r'([JL]) (PR\[\d+\]) (R\[\d+\])(%|mm/sec) FINE(?: Offset,(PR\[\d+\]))?',line)
    if m:return ('move',m[1],m[2],m[3],m[5])
    m=re.fullmatch(r'UALM\[(\d+)\]',line)
    if m:return ('alarm',int(m[1]))
    if re.fullmatch(r'WAIT\s+\.02\(sec\)',line):return ('wait',)
    raise AssertionError('Unsupported LS instruction: '+line)


def load_programs(directories=None):
    programs={}
    for path in [p for d in (directories or [COMM]) for p in d.glob('*.LS')]:
        text=path.read_text(encoding='ascii')
        assert text.startswith('/PROG '+path.stem+'\n')
        assert re.search(r'DEFAULT_GROUP = [1*],\*,\*,\*,\*;',text)
        body=text.split('/MN\n')[1].split('/POS')[0]
        lines=[]
        for number,line in enumerate(body.strip().splitlines(),1):
            m=re.fullmatch(r'\s*(\d+):\s+(.*?)\s*;',line)
            assert m and int(m[1])==number,(path,line)
            assert len(m[2])<=254,(path,number,'statement too long')
            lines.append(instruction(m[2]))
        for i,s in enumerate(lines):
            if s[0]!='selection_start':continue
            cases={s[2]:s[3]};j=i+1
            while j<len(lines) and lines[j][0]=='selection_case':
                case=lines[j];assert case[1] not in cases
                cases[case[1]]=case[2];lines[j]=('comment',);j+=1
            assert j<len(lines) and lines[j][0]=='selection_else'
            lines[i]=('select',s[1],cases,lines[j][1]);lines[j]=('comment',)
        programs[path.stem]=lines
    return programs


PROGRAMS=load_programs()


class Pose(tuple):
    def __sub__(self,other):return Pose(a-b for a,b in zip(self,other))
    def __add__(self,other):return Pose(a+b for a,b in zip(self,other))


class VM:
    """Executes emitted /MN statements, with bounded CALL/JMP and virtual I/O."""
    def __init__(self,programs=None):
        self.memory={};self.writes=[];self.steps=0;self.programs=programs or PROGRAMS
        self.motions=[];self.alarms=[];self.motion_hook=None
    def read(self,ref):
        if ref=='ZERO_OFFSET':return Pose([0]*6)
        m=re.fullmatch(r'PR\[(\d+)(?:,(\d+))?\]',ref)
        if m:
            key='PR['+m[1]+']'
            assert key in self.memory,'Uninitialized model point: '+key
            return self.memory[key][int(m[2])-1] if m[2] else self.memory[key]
        return self.memory.get(ref,0)
    def write(self,ref,value):
        m=re.fullmatch(r'PR\[(\d+),(\d+)\]',ref)
        if m:
            key='PR['+m[1]+']';pose=list(self.read(key));pose[int(m[2])-1]=value
            self.memory[key]=Pose(pose);self.writes.append((self.program,ref,value));return
        if ref.startswith(('F[','DO[')):value=bool(value)
        if ref.startswith('GO['):assert 0<=value<=65535 and int(value)==value
        self.memory[ref]=value;self.writes.append((self.program,ref,value))
    def run(self,name):
        previous=getattr(self,'program',None);self.program=name
        instructions=self.programs[name]
        labels={s[1]:i for i,s in enumerate(instructions) if s[0]=='label'}
        pc=0
        while pc<len(instructions):
            self.steps+=1
            assert self.steps<10000000,'Execution did not terminate'
            jump=self.execute(instructions[pc])
            pc=labels[jump] if jump is not None else pc+1
        self.program=previous
    def execute(self,s):
        op=s[0]
        if op=='if':
            if eval(s[1],{'__builtins__':{}},{'read':self.read}):return self.execute(s[2])
        elif op=='set':self.write(s[1],eval(s[2],{'__builtins__':{}},{'read':self.read}))
        elif op=='call':self.run(s[1])
        elif op=='jmp':return s[1]
        elif op=='select':self.run(s[2].get(self.read(s[1]),s[3]))
        elif op=='setting':self.memory[s[1]]=self.read(s[2])
        elif op=='move':
            assert self.read(s[3])>0,'Nonpositive motion speed'
            pose=self.read(s[2]);pose=pose+self.read(s[4]) if s[4] else pose
            self.motions.append((self.program,s[1],s[2],pose))
            if self.motion_hook:self.motion_hook(s[2],pose)
        elif op=='alarm':self.alarms.append(s[1])
        elif op=='run':raise AssertionError('Background task launch requires controller')
        elif op=='wait':raise AssertionError('Real-time wait requires controller')
        else:assert op in ('label','comment'),op
        return None


class Checks(unittest.TestCase):
    def setUp(self):
        self.v=VM();self.v.run('RC_INIT');self.c=RES['controls'];self.t=0
        self.put(self.c,'configured',True);self.put(self.c,'run',True)
        self.peer('p2r.link.version',2)
    def put(self,group,key,value):self.v.memory[group[key]]=value
    def get(self,group,key):return self.v.read(group[key])
    def peer(self,key,value):self.put(RES['mock'],key,value)
    def app(self,key,value):self.put(RES['application'],key,value)
    def ch(self,name):return next(c for c in RES['channels'] if c['name']==name)
    def scan(self,advance=1,heartbeat=True):
        self.t+=advance
        self.put(self.c,'mockClock',self.t)
        if heartbeat:
            self.peer('p2r.link.heartbeat',(self.get(RES['mock'],'p2r.link.heartbeat')+1)%65536)
        self.v.run('RC_RX');self.v.run('RC_MON');self.v.run('RC_TICK')
    def ready(self):
        self.peer('p2r.link.syncRequest',True)
        self.scan();self.scan();self.assertEqual(self.get(self.c,'state'),10)
        self.peer('p2r.link.syncAck',True);self.scan()
        self.peer('p2r.link.syncRequest',False);self.peer('p2r.link.syncAck',False)
        self.scan();self.assertEqual(self.get(self.c,'state'),30)
        self.scan();self.assertFalse(self.get(self.c,'session'))
        self.v.run('RC_RECOV');self.scan()
        self.assertTrue(self.get(self.c,'localReady'))
        self.peer('p2r.link.ready',True);self.peer('p2r.production.newOperationPermit',True)
        self.scan();self.put(self.c,'appArm',True);self.scan()
        self.assertTrue(self.get(self.c,'session'))
    def submit(self,name,count=7):
        ch=self.ch(name)
        for key in ch['payload']:
            self.app(key,count if key.endswith('.count') else 32768)
        self.v.memory[ch['submit']]=True
        self.scan()
        return ch

    def test_mapping_bounds_uniqueness_and_contract(self):
        signals=MAP['signals'];contract=json.loads((ROOT/'docs/robot-plc-signals.json').read_text(encoding='utf-8'))
        self.assertEqual({(s['id'],s['type'],s['direction']) for s in signals},
                         {(s['id'],s['type'],s['direction']) for s in contract['signals']})
        self.assertEqual(MAP['bytes_per_direction'],80)
        self.assertEqual((MAP['plc_to_robot_assembly'],MAP['robot_to_plc_assembly'],MAP['config_assembly']),(151,101,100))
        for direction,boolwords,numbools,numuints in [('PLC_TO_ROBOT',8,107,28),('ROBOT_TO_PLC',4,64,28)]:
            fields=[s for s in signals if s['direction']==direction]
            self.assertEqual(sum(s['type']=='BOOL' for s in fields),numbools)
            self.assertEqual(sum(s['type']=='UINT' for s in fields),numuints)
            used=set()
            for s in fields:
                self.assertEqual((s['rack'],s['slot']),(89,1))
                bits=set(range(s['port'],s['port']+s['width']))
                self.assertFalse(used & bits);used |= bits
                self.assertLessEqual(max(bits),640)
                if s['type']=='BOOL':
                    self.assertEqual(s['number'],120+s['port'])
                    self.assertLess(s['word'],boolwords)
                else:
                    self.assertEqual(s['word'],boolwords+s['number']-1)
                    self.assertEqual(s['port'],16*s['word']+1)
            prefix='p2r' if direction=='PLC_TO_ROBOT' else 'r2p'
            byid={s['id']:s for s in fields}
            self.assertEqual(byid[prefix+'.link.version']['word'],boolwords)
            self.assertEqual(byid[prefix+'.link.heartbeat']['word'],boolwords+1)
        # Independent little-endian bit/word test at every wire position.
        for s in signals:
            for value in ([0,1] if s['type']=='BOOL' else [0,1,32768,65535]):
                packet=bytearray(80)
                if s['type']=='BOOL':
                    bit=s['port']-1;packet[bit//8]=value << (bit%8)
                    decoded=(int.from_bytes(packet[2*s['word']:2*s['word']+2],'little')>>s['bit'])&1
                else:
                    packet[2*s['word']:2*s['word']+2]=value.to_bytes(2,'little')
                    decoded=int.from_bytes(packet,'little')>>(s['port']-1)&65535
                self.assertEqual(decoded,value)
                self.assertFalse(any(packet[72:] if s['direction']=='PLC_TO_ROBOT' else packet[64:]))

    def test_static_subset_resources_and_output_owners(self):
        allocations=RES['allocations'];keys=[(a['bank'],a['number']) for a in allocations]
        self.assertEqual(len(keys),len(set(keys)))
        for path in COMM.glob('*.LS'):
            for bank,number in re.findall(r'\b(R|F)\[(\d+)\]',path.read_text(encoding='ascii')):
                self.assertIn((bank,int(number)),keys)
        self.assertLessEqual(RES['register_range'][1],200)
        self.assertLessEqual(RES['flag_range'][1],1024)
        owners={}
        def inspect(s,name):
            if s[0]=='if':inspect(s[2],name)
            if s[0]=='set':
                ref=s[1]
                if ref.startswith(('DO[','GO[')):owners.setdefault(ref,set()).add(name)
                else:self.assertIn((ref.split('[')[0],int(ref.split('[')[1][:-1])),keys)
            if s[0] in ('call','run'):self.assertIn(s[1],PROGRAMS)
            if name=='RC_MON':self.assertIn(s[0],('if','set','comment'))
        for name,lines in PROGRAMS.items():
            for line in lines:inspect(line,name)
        hb=next(s for s in MAP['signals'] if s['id']=='r2p.link.heartbeat')
        for s in MAP['signals']:
            if s['direction']=='ROBOT_TO_PLC':
                ref=f"{s['io']}[{s['number']}]"
                self.assertEqual(owners[ref],{'RC_MON' if s==hb else 'RC_TX'})
        self.assertEqual(owners['DO[184]'],{'RC_TX'})
        self.assertEqual(len(owners),92)

    def test_emitted_smoke_program_and_test_output_isolation(self):
        self.v.run('RC_TEST')
        self.assertEqual(self.get(self.c,'testResult'),1)
        self.assertTrue(self.get(self.c,'test'))
        self.assertFalse(self.get(self.c,'configured'))
        self.assertTrue(all(not value for _,ref,value in self.v.writes if ref.startswith(('DO[','GO['))))

    def test_sync_requires_both_directions_and_explicit_recovery(self):
        self.scan();self.scan()
        self.peer('p2r.link.syncAck',True);self.scan()
        self.peer('p2r.link.syncAck',False);self.scan()
        self.assertEqual(self.get(self.c,'state'),20)
        self.assertFalse(self.get(self.c,'session'))
        self.peer('p2r.link.syncRequest',True);self.scan()
        self.assertTrue(self.get(self.c,'syncAck'))
        self.peer('p2r.link.syncRequest',False);self.scan()
        self.assertEqual(self.get(self.c,'state'),30)
        self.peer('p2r.link.ready',True);self.scan()
        self.assertFalse(self.get(self.c,'session'))
        self.v.run('RC_RECOV');self.scan();self.assertTrue(self.get(self.c,'session'))
        self.assertFalse(self.get(self.c,'appArm'))

    def test_version_watchdog_clock_and_sync_timeout(self):
        self.ready();self.peer('p2r.link.version',3);self.scan()
        self.assertFalse(self.get(self.c,'session'))
        self.assertEqual(self.get(self.c,'state'),0)
        self.peer('p2r.link.version',2);self.scan()
        self.scan(self.get(self.c,'syncTimeout')+1)
        self.assertEqual(self.get(self.c,'fault'),902)
        self.assertFalse(self.get(self.c,'localReady'))
        self.t=-2;self.scan()
        self.assertFalse(self.get(self.c,'monitorOk'))
        self.assertFalse(self.get(self.c,'session'))
        previous=self.get(self.c,'heartbeat')
        self.scan(self.get(self.c,'heartbeatPeriod')+1)
        self.assertNotEqual(self.get(self.c,'heartbeat'),previous)

    def test_loss_preserves_load_and_does_not_replay_payload(self):
        self.ready();self.app('r2p.production.loadKnown',True);self.app('r2p.production.loadMask',19)
        ch=self.submit('productsPlaced');self.assertEqual(self.v.read(ch['state']),10)
        self.scan(self.get(self.c,'peerTimeout')+1,heartbeat=False)
        self.assertEqual(self.v.read(ch['status']),900)
        self.assertEqual(self.v.read(ch['state']),0)
        self.assertFalse(self.get(self.c,'session'))
        self.assertTrue(self.get(RES['application'],'r2p.production.loadKnown'))
        self.assertEqual(self.get(RES['application'],'r2p.production.loadMask'),19)
        self.scan();self.assertFalse(self.v.read(ch['submit']))
        self.assertFalse(self.get(RES['output_bool'],ch['output']))

    def test_monitor_independent_of_application_but_detects_stopped_service(self):
        self.ready();self.put(self.c,'heartbeat',65535)
        self.scan(self.get(self.c,'heartbeatPeriod'))
        self.assertEqual(self.get(self.c,'heartbeat'),0)
        for _ in range(6):
            self.t+=self.get(self.c,'heartbeatPeriod')
            self.put(self.c,'mockClock',self.t);self.v.run('RC_MON')
        self.assertFalse(self.get(self.c,'monitorOk'))
        stopped=self.get(self.c,'heartbeat')
        self.t+=100;self.put(self.c,'mockClock',self.t);self.v.run('RC_MON')
        self.assertEqual(self.get(self.c,'heartbeat'),stopped)

    def test_events_freeze_payload_independent_ack_and_full_return_to_zero(self):
        self.ready();a=self.submit('productsPlaced',7);b=self.submit('samplesPlaced',5)
        self.app('r2p.event.productsPlaced.count',99)
        self.v.memory[a['submit']]=True;self.scan()
        self.assertEqual(self.get(RES['frozen_payload'],'r2p.event.productsPlaced.count'),7)
        self.assertEqual(self.get(self.c,'fault'),905)
        self.peer('p2r.event.productsPlaced.ack',True);self.scan()
        self.assertEqual(self.v.read(a['status']),20)
        self.assertEqual(self.v.read(b['state']),10)
        self.assertFalse(self.get(RES['output_bool'],a['output']))
        self.scan();self.assertEqual(self.v.read(a['state']),20)
        self.peer('p2r.event.productsPlaced.ack',False);self.scan()
        self.assertEqual(self.v.read(a['state']),0)
        self.assertEqual(self.get(RES['frozen_payload'],'r2p.event.samplesPlaced.count'),5)

    def test_reject_invalid_payload_and_stale_ack(self):
        self.ready()
        for count in [0,-1,1.5,65536]:
            ch=self.submit('productsPlaced',count)
            self.assertEqual(self.v.read(ch['status']),904)
            self.assertEqual(self.v.read(ch['state']),0)
        for count in [1,65535]:
            ch=self.submit('productsPlaced',count)
            self.assertEqual(self.v.read(ch['state']),10)
            self.peer('p2r.event.productsPlaced.ack',True);self.scan()
            self.peer('p2r.event.productsPlaced.ack',False);self.scan()
        self.peer('p2r.event.productsPlaced.ack',True)
        ch=self.submit('productsPlaced',7)
        self.assertEqual(self.v.read(ch['status']),903)
        self.assertEqual(self.v.read(ch['state']),0)

    def test_blows_conflicts_terminal_results_and_bad_result_recovery(self):
        self.ready()
        for n,result,status in [(1,1,20),(2,2,30),(3,3,40)]:
            self.app(f'r2p.vac.{n}.cmdValid',True)
            ch=self.submit(f'blow{n}')
            self.assertEqual(self.v.read(ch['state']),10)
            self.peer(f'p2r.vac.{n}.blowAck',True);self.peer(f'p2r.vac.{n}.blowResult',result);self.scan()
            self.assertEqual(self.v.read(ch['status']),status)
        self.app('r2p.vac.4.cmdValid',True);self.app('r2p.vac.4.hold',True)
        ch=self.submit('blow4');self.assertEqual(self.v.read(ch['status']),904)
        self.assertTrue(self.get(RES['output_bool'],'r2p.vac.4.hold'))
        self.app('r2p.vac.5.cmdValid',True);ch=self.submit('blow5')
        self.peer('p2r.vac.5.blowAck',True);self.peer('p2r.vac.5.blowResult',0);self.scan()
        self.assertFalse(self.get(self.c,'session'))
        self.assertTrue(self.get(self.c,'protocolFault'))
        self.assertEqual(self.get(self.c,'fault'),906)
        # Clear PLC channels, complete a fresh bilateral sync, then explicit recovery.
        for n in range(1,6):self.peer(f'p2r.vac.{n}.blowAck',False)
        self.peer('p2r.link.syncRequest',True);self.scan()
        self.peer('p2r.link.syncAck',True);self.scan()
        self.peer('p2r.link.syncAck',False);self.peer('p2r.link.syncRequest',False);self.scan()
        self.assertEqual(self.get(self.c,'state'),30)
        self.v.run('RC_RECOV');self.scan()
        self.assertTrue(self.get(self.c,'session'))
        self.assertFalse(self.get(self.c,'appArm'))
        self.assertFalse(self.v.read(ch['submit']))

    def test_samples_hold_accept_or_reject_until_request_low(self):
        self.ready()
        self.peer('p2r.samples.req',True);self.scan()
        self.app('r2p.samples.result',3);self.app('r2p.samples.ack',True);self.scan()
        self.assertEqual(self.get(self.c,'sampleStatus'),904)
        self.assertFalse(self.get(RES['output_bool'],'r2p.samples.ack'))
        for result,status in [(1,20),(2,30)]:
            self.peer('p2r.samples.req',True);self.scan()
            self.assertEqual(self.get(self.c,'sampleState'),10)
            self.app('r2p.samples.result',result);self.app('r2p.samples.ack',True);self.scan()
            self.assertTrue(self.get(RES['output_bool'],'r2p.samples.ack'))
            self.assertEqual(self.get(self.c,'sampleStatus'),status)
            self.app('r2p.samples.result',3-result);self.scan()
            self.assertEqual(self.get(self.c,'sampleResult'),result)
            self.peer('p2r.samples.req',False);self.scan()
            self.assertFalse(self.get(RES['output_bool'],'r2p.samples.ack'))

    def test_stop_finish_permit_critical_and_cylinder_conflict(self):
        self.ready()
        self.app('r2p.cyl.V501.home',True);self.app('r2p.cyl.V501.work',True)
        self.app('r2p.cyl.V502.work',True);self.scan()
        self.assertFalse(self.get(RES['output_bool'],'r2p.cyl.V501.home'))
        self.assertFalse(self.get(RES['output_bool'],'r2p.cyl.V501.work'))
        self.assertTrue(self.get(RES['output_bool'],'r2p.cyl.V502.work'))
        self.peer('p2r.production.newOperationPermit',False);self.peer('p2r.production.finishPermit',True);self.scan()
        self.assertTrue(self.get(RES['output_bool'],'r2p.cyl.V502.work'))
        self.peer('p2r.production.criticalBlock',True);self.scan()
        self.assertFalse(self.get(RES['output_bool'],'r2p.cyl.V502.work'))
        self.assertTrue(self.get(self.c,'session'))
        self.assertFalse(self.get(self.c,'appArm'))
        self.peer('p2r.production.criticalBlock',False);self.scan()
        self.assertFalse(self.get(RES['output_bool'],'r2p.cyl.V502.work'))
        self.put(self.c,'appArm',True);self.scan()
        self.assertTrue(self.get(RES['output_bool'],'r2p.cyl.V502.work'))

    def test_peer_restart_and_service_disarm_clear_requests(self):
        self.ready();ch=self.submit('productsPlaced')
        self.peer('p2r.link.syncRequest',True);self.scan()
        self.assertFalse(self.get(self.c,'session'))
        self.assertEqual(self.v.read(ch['status']),900)
        self.assertFalse(self.v.read(ch['submit']))
        self.put(self.c,'run',False);self.v.run('RC_TICK')
        self.assertEqual(self.get(self.c,'state'),0)
        self.assertFalse(self.get(self.c,'localReady'))

    def test_unconfigured_live_start_is_blocked(self):
        self.v=VM(load_programs([ROOT/'ROBOT/COMM']));self.v.run('RC_INIT');self.v.run('RC_LIVE')
        self.assertFalse(self.get(self.c,'run'))
        self.assertFalse(self.get(self.c,'test'))

    def test_invalid_scalar_is_zeroed_and_requires_recovery(self):
        self.ready();self.app('r2p.production.phase',1.5);self.scan()
        self.assertEqual(self.get(self.c,'fault'),908)
        self.assertFalse(self.get(self.c,'session'))
        self.put(self.c,'test',False);self.v.run('RC_TX')
        s=next(s for s in MAP['signals'] if s['id']=='r2p.production.phase')
        self.assertEqual(self.v.read(f"GO[{s['number']}]"),0)

    def test_live_io_translation_without_devices(self):
        # In-memory digital/group banks only; RC_LIVE is deliberately never launched.
        self.v=VM(load_programs([ROOT/'ROBOT/COMM']));self.v.run('RC_INIT')
        self.put(self.c,'test',False)
        incoming={s['id']:s for s in MAP['signals'] if s['direction']=='PLC_TO_ROBOT'}
        for key,value in [('p2r.link.version',2),('p2r.link.heartbeat',65535),('p2r.cyl.V501.valid',True)]:
            s=incoming[key];self.v.memory[f"{s['io']}[{s['number']}]"]=value
        self.v.run('RC_RX')
        self.assertEqual(self.get(RES['rx'],'p2r.link.heartbeat'),65535)
        self.assertTrue(self.get(RES['rx'],'p2r.cyl.V501.valid'))
        self.app('r2p.production.loadMask',32768);self.v.run('RC_TX')
        s=next(s for s in MAP['signals'] if s['id']=='r2p.production.loadMask')
        self.assertEqual(self.v.read(f"GO[{s['number']}]"),32768)


if __name__=='__main__':unittest.main(verbosity=2)