"""Full StationController + real FANUC LS. Only physics/native inputs are synthetic."""
import copy,json
from check_station import station_runtime
from check_plc_robot import context,plant,config
from check_fanuc_tray import Cell,WIRE

class StationCell:
    def __init__(self,mode=2,bootstrap=True):
        self.r=station_runtime();r=self.r
        self.controller=r.instance('FB_StationController');self.codec=r.instance('FB_RobotCodec')
        self.native=Cell(mode=mode);self.mode=mode;self.step=0;self.reqid=0
        self.cfg=r.value('ST_StationCfg');self.inp=r.value('ST_StationInputs')
        self.c=context(r);self.c['program_']=mode;self.c['occupied'][2]=True;self.c['occupied'][3]=True
        self.proposal=copy.deepcopy(self.c);self.hmi=r.value('ST_RobotHmiV2')
        self.cfg['robot_Cfg']=config(r);self.cfg['robot_Cfg']['link'].update(peerTimeout=20000,syncTimeout=50000)
        self.cfg.update(robot_stationIoBound=True,robot_stationCoilPolicyVerified=True,
            station_ElevatorCfgVerified=True,station_ManualReleaseVerified=True,station_LocalFaultPolicyVerified=True)
        self.cfg['station_IoCfg'].update(configured=True,stable=10)
        self.cfg['station_IoCfg']['required']={i:True for i in range(1,13)}
        self.cfg['station_AlarmCfg']['policyVerified']=True
        self.cfg['station_AlarmCfg']['configured']={i:True for i in range(1,65)}
        self.cfg['station_ParameterCfg'].update(limitsVerified=True,minTimeMs=1,maxTimeMs=20000,maxHz=50)
        self.cfg['station_ElevatorCfg'].update(rMaxSpeed_Hz=50,tVfdResetPulse=20,xFwdIsUp=True,
            wStsMask_Fault=8,wStsMask_Ready=1,wStsMask_Running=4,wStsMask_Remote=512,
            rStopSpeedThreshold_Hz=1,tStopTimeout=1000)
        for n in range(1,5):self.c['stationParameters'][n].update(verified=True,sensorStableMs=10,
            stopDelayMs=30,moveTimeoutMs=10000,actuatorTimeoutMs=3000,slowHz=5,fastHz=20)
        self.inp.update(robot_ScannerHealthy=True,robot_ImageFresh=True,robot_vfdCommHealthy=True)
        self.inp['robot_Plant']=plant(r)
        self.inp['station_Inputs'].update(mappingVerified=True,gatewayHealthy=True,imageFresh=True,
            barrierValid=True,lowerFeedbackValid=True)
        self.inp['station_Inputs']['positionValid']={i:True for i in range(1,8)}
        self.inp['station_Inputs']['moduleHealthy']={i:True for i in range(1,13)}
        self.inp['io_di'].update(ind_robot_cell_doors_locked=True,ind_robot_cell_doors_error=True)
        self.inp['drive'].update(valid=True,commHealthy=True,statusword=513,actualHz=0)
        self.inp['robot_storageIn']['Left']=copy.deepcopy(self.inp['robot_Plant']['cylinders'][1])
        self.inp['robot_storageIn']['Right']=copy.deepcopy(self.inp['robot_Plant']['cylinders'][1])
        self.inp['robot_storageIn'].update(RobotSideOpeningPermission=True,OperatorSideOpeningPermission=True,Empty=False)
        self.controller.v['fbSafetyDoor'].v['Cfg']['tStable']=10
        self.positions={1:None,2:{'trays':4},3:{'trays':4},4:None,5:None,6:None,7:None}
        self.axis=1.;self.coast=0;self.p4edge=1.15
        self.coils={i:False for i in range(1,11)};self.topTransit=None;self.lowerTransit=None
        self.previousEvents={};self.events=[];self.receiptAge=0;self.autoPickup=True;self.driveValid=True
        self.rows=json.loads((r.root/'ROBOT/COMM/mapping.json').read_text())['signals']
        self.native.set(self.native.b,'contextChecked',True);self.native.set(self.native.b,'recoveryApproved',True)
        self.physicalStart=False;self.physicalStop=False
        if bootstrap:
            for _ in range(25):self.scan()
            self.hmi['link']['xArmReq']=True
            for _ in range(3):self.scan()
            self.hmi['link']['xArmReq']=False
            self.until(lambda:self.controller.v['robot'].v['Link'].v['State']==30)
            self.proposal.update(copy.deepcopy(self.c))
            self.proposal['occupancyKnown']=True
            self.proposal['occupied']={i:self.positions[i] is not None for i in range(1,8)}
            self.proposal['elevatorLoadPresent']=self.positions[4] is not None
            self.command('recoveryConfirm')
            self.native.set(self.native.b,'contextChecked',True);self.native.set(self.native.b,'recoveryApproved',True)
            self.until(lambda:self.controller.v['Outp']['robot_Sts']['session'] and not self.controller.v['stationRecovery'].v['Required'])
            self.until(lambda:self.controller.v['Outp']['robot_Sts']['order']['settled'])
            self.hmi['edit'].update(uiProgram=mode,uiBatchCount=7);self.command('orderOpen')
    def debug(self):
        v=self.controller.v
        return dict(step=self.step,order=v['robot'].v['Sts']['order'],recovery=v['robot'].v['Sts']['recoveryRequired'],
            stationRecovery=v['stationRecovery'].v['Required'],robotLink=v['robot'].v['Link'].v['State'],
            robotPhase=self.inp['robot_Rx']['production_phase'],robotFault=self.inp['robot_Rx']['production_faultCode'],
            material=v['material'].v['Sts'],transport=v['transport'].v['Sts'],elevator=v['elevStat'],
            top=v['fbTopFlow'].v['Sts'],bottom=v['fbBottom567'].v['Sts'],
            positions=self.positions,axis=self.axis,critical=v['plantNow']['critical'],globalEnable=v['xGlobalEnable'])
    def until(self,predicate,limit=300):
        for _ in range(limit):
            if predicate():return
            self.scan()
        raise AssertionError(self.debug())
    def command(self,key):
        self.reqid+=1;req=self.hmi['cmd'][key]
        req.update(xReq=True,udiSessionId=self.hmi['link']['udiSessionId'],udiRequestId=self.reqid)
        self.until(lambda:self.hmi['rsp'][key]['xAck'],limit=40)
        response=copy.deepcopy(self.hmi['rsp'][key]);req['xReq']=False;self.scan()
        assert response['uiResult']==1,(key,response,self.debug())
    def start(self):
        self.physicalStart=False;self.scan();self.physicalStart=True;self.scan();self.physicalStart=False;self.scan()
    def begin(self,reject=False):
        p=self.inp['robot_Plant']['imm'];p['reject']=reject;p['startConfirmed']=False;self.scan()
        p['startConfirmed']=True;p['settled']=False;self.scan();p['startConfirmed']=False
    def inputs(self):
        v=self.controller.v;out=v['Outp'];d=self.inp['io_di'];a=self.inp['station_Inputs']
        for i in range(1,11):
            cmd=out['station_Coils'][i]
            if cmd['work'] or cmd['home']:self.coils[i]=cmd['work']
        for i in range(1,6):
            for axis in (1,2):
                d[f'ind_M{i}_{axis}_fwd']=self.coils[i];d[f'ind_M{i}_{axis}_bwd']=not self.coils[i]
        d['ind_M7_fwd']=self.coils[7];d['ind_M7_bwd']=not self.coils[7]
        for key,i in [('v201',6),('v202',8)]:a[key].update(IsExt=self.coils[i],IsRet=not self.coils[i],valid=True)
        for n,i in [(1,9),(2,10)]:
            a['lowerStop'][n].update(ind_1_fwd=self.coils[i],ind_2_fwd=self.coils[i],ind_1_bwd=not self.coils[i],ind_2_bwd=not self.coils[i],valid=True)
        for side,key in [('Left','Q_V401Work'),('Right','Q_V402Work')]:
            c=out['robot_storageOut'];home=c['Q_V401Home' if side=='Left' else 'Q_V402Home']
            if c[key] or home:self.inp['robot_storageIn'][side].update(atHome=home,atWork=c[key])
        drive=out['drive'];moving=drive['enable'] and (drive['forward'] or drive['reverse'])
        if moving:
            self.axis=max(1.,min(4.,self.axis+(-.2 if drive['forward'] else .2)));self.coast=2
        elif self.coast:self.coast-=1
        self.inp['drive'].update(valid=self.driveValid,commHealthy=True,statusword=517 if moving else 513,actualHz=5 if moving or self.coast else 0)
        for key,value in [('top',abs(self.axis-1)<.05),('intermediate_top',abs(self.axis-2)<.11),('intermediate_bottom',abs(self.axis-3)<.11),('bottom',abs(self.axis-4)<.05)]:d[f'ind_elevator_in_{key}_pos']=value
        topRun=out['io_dout']['ctrl_turn_on_top_conveyor'];lowerRun=out['io_dout']['ctrl_turn_on_bottom_conveyor']
        elevRun=out['io_dout']['ctrl_turn_on_elevator_conveyor_in'] or out['io_dout']['ctrl_turn_on_elevator_conveyor_out']
        a['beltsStopped'].update({1:not topRun,2:not elevRun,3:not lowerRun})
        d['ind_elevator_emptied']=False
        if topRun and self.topTransit is None and self.positions[v['fbTopFlow'].v['Sts']['SrcPos']] is not None:
            t=v['fbTopFlow'].v['Sts'];source=t['SrcPos'];target=t['Target']
            self.topTransit=[source,target,self.positions[source],0];self.positions[source]=None
        if self.topTransit and topRun:
            self.topTransit[3]+=1
            if self.topTransit[3]>=4:
                source,target,load,_=self.topTransit;self.positions[target]=load;self.topTransit=None
                if target==4:self.p4edge=self.axis+.15
        if lowerRun and self.lowerTransit is None and self.positions.get(v['fbBottom567'].v['source']) is not None:
            b=v['fbBottom567'].v;source=b['source'];target=b['target']
            self.lowerTransit=[source,target,self.positions[source],0];self.positions[source]=None
        if self.lowerTransit and lowerRun:
            self.lowerTransit[3]+=1;d['ind_elevator_emptied']=self.lowerTransit[0]==4 and self.lowerTransit[3]<4
            if self.lowerTransit[3]>=4:
                source,target,load,_=self.lowerTransit;self.positions[target]=load;self.lowerTransit=None
        # Stopped belts prevent a second synthetic carrier from being advanced by a stale run command.
        if self.autoPickup and v['fbBottom567'].v['Sts']['WaitingPickup'] and self.positions[7] is not None:
            self.receiptAge+=1
            if self.receiptAge>=8:self.positions[7]=None;self.receiptAge=0
        a['occupied']={i:self.positions[i] is not None for i in range(1,8)}
        a['occupied'][4]=self.positions[4] is not None and self.axis<=self.p4edge
        self.inp['io_di']['ind_button_start_process']=self.physicalStart
        self.inp['robot_Plant']['physicalStop']=self.physicalStop
        status=out['robot_Sts'];p=self.inp['robot_Plant']
        for i in range(1,6):
            c=status['cylinders'][i]
            if c['home'] or c['work']:p['cylinders'][i].update(atHome=c['home'],atWork=c['work'])
            p['vacuum'][i].update(ok=status['vacuum'][i]['hold'],releaseConfirmed=not status['vacuum'][i]['hold'])
        imm=status['imm']
        if imm['mouldFullOpen']:p['imm'].update(mouldOpen=True,mouldClosed=False)
        if imm['ejectorForward']:p['imm'].update(ejectorForward=True,ejectorBack=False)
        if imm['ejectorBack']:p['imm'].update(ejectorBack=True,ejectorForward=False)
        if status['session'] and v['robot'].v['Ledger'].v['Unsettled']==0:p['imm']['settled']=True
    def scan(self):
        self.step+=1;self.inputs();raw={i:0 for i in range(80)}
        for row in self.rows:
            if not row['id'].startswith('r2p.'):continue
            value=self.native.output(row['id']);byte=2*row['word']
            if row['type']=='BOOL':
                if value:raw[byte+row['bit']//8]|=1<<(row['bit']%8)
            else:raw[byte]=int(value)&255;raw[byte+1]=int(value)>>8
        self.codec.run(RawIn=raw);self.inp['robot_Rx']=copy.deepcopy(self.codec.v['Rx'])
        self.hmi['link']['uiHmiHeartbeat']=(self.hmi['link']['uiHmiHeartbeat']+1)%65536
        self.controller.run(Cfg=self.cfg,Inp=self.inp,Context=self.c,Proposal=self.proposal,Hmi=self.hmi)
        self.codec.run(Tx=self.controller.v['Outp']['robot_Tx']);out=self.codec.v['RawOut'];rob=self.native
        for row in self.rows:
            if not row['id'].startswith('p2r.'):continue
            word=out[2*row['word']]|out[2*row['word']+1]<<8
            rob.v.memory[WIRE[row['id']]]=bool(word&(1<<row['bit'])) if row['type']=='BOOL' else word
        rob.t+=1;rob.v.memory['$FAST_CLOCK']=rob.t
        rob.v.steps=0 # bounded per scan, WAIT task program counter remains persistent
        for program in ['PLC_RX','BG_STATUS','BG_GUARD','BG_PLC','PLC_SCAN']:rob.v.run(program)
        rob.v.resume_task(rob.main)
        for event in ['productsPlaced','samplesPlaced','rejectsPlaced','blisterPicked','blisterPlaced','stackFinished','immPickupCompleted']:
            active=rob.output('r2p.event.'+event+'.req')
            if active and not self.previousEvents.get(event,False):
                self.events.append(event)
                if event=='blisterPicked' and self.positions[3]:
                    self.positions[3]['trays']-=1
                    if self.positions[3]['trays']==0:self.positions[3]=None
                if event=='blisterPlaced':
                    if self.positions[4] is None:self.positions[4]={'trays':0}
                    self.positions[4]['trays']+=1;self.p4edge=self.axis+.15
            self.previousEvents[event]=active
