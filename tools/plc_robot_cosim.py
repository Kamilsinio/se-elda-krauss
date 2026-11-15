"""Co-simulation: actual ST controller/sequencer <-> actual LIVE LS via 80-byte images.
Only native status, geometry, machine, pneumatic and conveyor physics are fixtures.
"""
from __future__ import annotations
import copy
import json
from check_fanuc_tray import Cell, WIRE
from check_plc_robot import runtime, context, plant, config
from build_plc_robot import field

class CoupledCell:
    def __init__(self,mode=2,bootstrap=True):
        # Reuse validated synthetic native/geometry setup, then replace its PLC peer.
        self.robot=Cell(mode=mode)
        self.mode=mode;self.r=runtime();self.c=context(self.r);self.c['program_']=mode
        self.proposal=copy.deepcopy(self.c);self.p=plant(self.r);self.cfg=config(self.r)
        self.cfg['link'].update(peerTimeout=2000,syncTimeout=5000)
        self.hmi=self.r.value('ST_RobotHmiV2');self.drain=self.r.value('ST_RobotDrain')
        self.plc=self.r.instance('FB_RobotController');self.codec=self.r.instance('FB_RobotCodec')
        self.seq=self.r.instance('FB_TraySequencer' if mode==2 else 'FB_BoxSequencer')
        self.rows=json.loads((self.r.root/'ROBOT/COMM/mapping.json').read_text())['signals']
        self.frame={i:0 for i in range(80)};self.tx=self.r.value('ST_RobotTxV2')
        self.step=0;self.reqid=0;self.events=[];self.previous_req={}
        self.top=True;self.bottom=False;self.p4=False;self.positioner=False;self.delivered=False
        self.discharge=False;self.advanceStack=False;self.physicalStart=False;self.physicalStop=False
        self.wasPlaced=False
        self.sourceStock=2;self.delayEvents=set()
        self.robot.set(self.robot.b,'contextChecked',True)
        self.robot.set(self.robot.b,'recoveryApproved',True)
        if not bootstrap:return
        for _ in range(20):self.scan()
        self.hmi['link']['xArmReq']=True
        for _ in range(3):self.scan()
        self.hmi['link']['xArmReq']=False
        assert self.hmi['link']['xArmed'],self.debug()
        self.until(lambda:self.plc.v['Link'].v['State']==30,limit=100)
        self.proposal.update(self.c)
        self.command('recoveryConfirm')
        self.robot.set(self.robot.b,'contextChecked',True)
        self.robot.set(self.robot.b,'recoveryApproved',True)
        self.until(lambda:self.plc.v['Sts']['session'],limit=100)
        # Ordinary Stop reaches the defined settled/home status before opening an order.
        self.until(lambda:self.plc.v['Sts']['order']['settled'],limit=150)
        self.hmi['edit'].update(uiProgram=mode,uiBatchCount=7)
        self.command('orderOpen')
        assert self.c['orderActive'],self.debug()

    def debug(self):
        rob=self.robot
        return dict(step=self.step,plcState=self.plc.v['Link'].v['State'],
            recovery=self.plc.v['Sts']['recoveryRequired'],diag=self.plc.v['Sts']['diag'],
            protocol=self.plc.v['protocolFault'],ledger=self.plc.v['Ledger'].v['Fault'],critical=self.plc.v['criticalNow'],
            rawStatus={k:v for k,v in self.plc.v['Rx'].items() if k.startswith('production')},
            robotState=rob.get(rob.p,'state'),robotFault=rob.output('r2p.production.faultCode'),
            robotLink=rob.get(rob.c,'state'),ctx=self.c,tx={k:v for k,v in self.tx.items() if k.startswith(('link','production'))})

    def until(self,predicate,limit=500):
        for _ in range(limit):
            if predicate():return
            self.scan()
        raise AssertionError(self.debug())

    def command(self,key):
        self.reqid+=1
        req=self.hmi['cmd'][key]
        req.update(xReq=True,udiRequestId=self.reqid,udiSessionId=self.hmi['link']['udiSessionId'])
        self.until(lambda:self.hmi['rsp'][key]['xAck'],limit=20)
        response=copy.deepcopy(self.hmi['rsp'][key]);req['xReq']=False
        self.scan()
        assert response['uiResult']==1,(key,response,self.debug())

    def start(self):
        self.physicalStart=False;self.scan();self.physicalStart=True;self.scan();self.physicalStart=False;self.scan()

    def begin(self,reject=False):
        self.p['imm']['reject']=reject;self.p['imm']['startConfirmed']=False;self.scan()
        self.p['imm']['startConfirmed']=True;self.p['imm']['settled']=False;self.scan()
        self.p['imm']['startConfirmed']=False

    def devices(self):
        status=self.plc.v['Sts']
        for i in range(1,6):
            output=status['cylinders'][i]
            if output['home'] or output['work']:
                self.p['cylinders'][i].update(atHome=output['home'],atWork=output['work'])
            v=status['vacuum'][i]
            self.p['vacuum'][i].update(ok=v['hold'],releaseConfirmed=not v['hold'])
        imm=status['imm']
        if imm['mouldFullOpen']:self.p['imm'].update(mouldOpen=True,mouldClosed=False)
        if imm['ejectorForward']:self.p['imm'].update(ejectorForward=True,ejectorBack=False)
        if imm['ejectorBack']:self.p['imm'].update(ejectorBack=True,ejectorForward=False)
        if status['session'] and self.plc.v['Ledger'].v['Unsettled']==0:self.p['imm']['settled']=True

    def station(self):
        ctx=self.c;status=self.plc.v['Sts']
        if ctx['tasks'][2]['pending'] and not self.wasPlaced:self.p4=True
        self.wasPlaced=ctx['tasks'][2]['pending']
        cmd=self.r.value('ST_TraySeqCmd' if self.mode==2 else 'ST_BoxSeqCmd')
        cmd.update(Enable=ctx['orderActive'],NewOperations=status['order']['newPermit'],
                   FinishOperations=status['order']['finishPermit'],SafetyOK=True,
                   RecoveryRequired=status['recoveryRequired'])
        inp=self.r.value('ST_TraySeqIn' if self.mode==2 else 'ST_BoxSeqIn')
        inp.update(TopFlow_OccP3=self.sourceStock>0,TopFlow_StackReadyAtP3=self.sourceStock>0,
            TopFlow_ElevDeliveredAtP4=self.delivered,Elev_AtTop=self.top,Elev_AtBottom=self.bottom,
            Elev_CommandReady=True,Bottom_CanAccept=True,Bottom_DischargeDonePulse=self.discharge,
            ind_container_in_pos_4=self.p4,PositionerHome=not self.positioner,PositionerWork=self.positioner,
            Session=status['session'],RobotReserved=status['areas'][2]['reserved'],
            RobotClear=self.robot.output('r2p.area.elevator.clear'),
            TaskPicked=ctx['tasks'][1]['pending'],TaskPlaced=ctx['tasks'][2]['pending'],
            TaskFinished=ctx['tasks'][3]['pending'],TaskStack=ctx['tasks'][8]['pending'],
            SourceEmptyConfirmed=self.sourceStock==0)
        self.seq.run(Cmd=cmd,Inp=inp,Context=ctx)
        out=self.seq.v['Outp'];self.discharge=False
        self.positioner=out['M6_Extend' if self.mode==2 else 'M7_Extend']
        if out['TopFlow_Elev_RequestFeed'] and out['TopFlow_Elev_CanAccept']:self.p4=True;self.delivered=True
        if out['Elev_AutoGo']:
            target=out['Elev_AutoTarget']
            if target==1:self.top=True;self.bottom=False
            if target==4:self.top=False;self.bottom=True
            if target==10:self.p4=False
        if out['Bottom_DischargeReq']:
            self.discharge=True;self.p4=False;self.delivered=False
        done={i:False for i in range(1,11)}
        for i,key in [(1,'ConsumePicked'),(2,'ConsumePlaced'),(3,'ConsumeFinished'),(8,'ConsumeStack')]:
            done[i]=out[key]
        done[4]=ctx['tasks'][4]['pending'];done[7]=ctx['tasks'][7]['pending']
        if out['TopFlow_StackConsumed'] and self.sourceStock==0:self.sourceStock=2
        self.p['taskDone']=done
        self.p['areas'][1]['ready']=self.sourceStock>0
        self.p['areas'][2]['ready']=out['ElevatorReady']
        self.p['transferBusy']=False
        if out['NewStackReady'] and ctx['stackFull']:self.advanceStack=True
        if self.advanceStack and status['allChannelsIdle'] and not ctx['tasks'][8]['pending']:
            ctx['stackId']=(ctx['stackId']+1)%65536;ctx['blisterCount']=0;ctx['layerCount']=0
            ctx['stackFull']=False
            self.advanceStack=False
        self.tx['production_stackId']=ctx['stackId']

    def scan(self):
        self.step+=1;rob=self.robot
        # Bus: robot DO/GO -> 80 bytes, then execute actual PLC codec and controller.
        raw={i:0 for i in range(80)}
        for row in self.rows:
            if not row['id'].startswith('r2p.'):continue
            value=rob.output(row['id']);byte=2*row['word']
            if row['type']=='BOOL':
                if value:raw[byte+row['bit']//8] |= 1 << (row['bit']%8)
            else:raw[byte]=int(value)&255;raw[byte+1]=int(value)>>8
        self.codec.run(RawIn=raw,Tx=self.tx)
        rx=copy.deepcopy(self.codec.v['Rx'])
        self.hmi['link']['uiHmiHeartbeat']=(self.hmi['link']['uiHmiHeartbeat']+1)%65536
        self.p.update(physicalStart=self.physicalStart,physicalStop=self.physicalStop)
        self.plc.run(Cfg=self.cfg,ScannerHealthy=True,ImageFresh=True,Rx=rx,Plant=self.p,
                     Context=self.c,Proposal=self.proposal,Drain=self.drain,Hmi=self.hmi)
        self.tx=copy.deepcopy(self.plc.v['Tx'])
        self.station();self.devices()
        self.codec.run(Tx=self.tx)
        out=self.codec.v['RawOut']
        # Bus: 80 PLC bytes -> robot DI/GI; no synthetic ACK or permissions.
        for row in self.rows:
            if not row['id'].startswith('p2r.'):continue
            w=out[2*row['word']] | out[2*row['word']+1]<<8
            value=bool(w&(1<<row['bit'])) if row['type']=='BOOL' else w
            rob.v.memory[WIRE[row['id']]]=value
        rob.t+=1;rob.v.memory['$FAST_CLOCK']=rob.t
        rob.v.run('PLC_RX');rob.v.run('BG_STATUS');rob.v.run('BG_GUARD');rob.v.run('BG_PLC');rob.v.run('PLC_SCAN')
        rob.v.resume_task(rob.main)
        for event in ['productsPlaced','samplesPlaced','rejectsPlaced','blisterPicked','blisterPlaced',
                      'blisterFinished','layerFinished','spacerPlaced','stackFinished','immPickupCompleted']:
            req=rob.output('r2p.event.'+event+'.req')
            if req and not self.previous_req.get(event,False):
                self.events.append(event)
                if event=='blisterPicked':self.sourceStock-=1
            self.previous_req[event]=req

