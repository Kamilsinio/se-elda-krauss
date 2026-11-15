"""Integration regressions for audited failures. Runs real ST, hardware is synthetic."""
import copy
import unittest
import check_station
from check_station import station_runtime
from check_plc_robot import context,plant

class AuditedFailures(unittest.TestCase):
    def setUp(self):self.r=station_runtime()
    def test_stopper_timeout_does_not_publish_new_movement(self):
        f=self.r.instance('FB_StopperPair');cfg=self.r.value('ST_StopperPairCfg')
        cfg.update(tStable=10,tTimeout=20,HoldCoilInEndPos=True)
        for _ in range(2):f.run(Cfg=cfg,Enable=True,HoldUp=True,Inp=self.r.value('ST_StopperPairIn'))
        self.assertTrue(f.v['Diag']['Fault']);self.assertFalse(f.v['Outp']['Q_Fwd'])
    def test_disabled_cylinder_still_reports_observed_home(self):
        f=self.r.instance('FB_Cyl2Pos');cfg=self.r.value('ST_Cyl2PosCfg');cfg.update(tStable=10,tTimeout=100)
        a=self.r.value('ST_Cyl2PosIn');a['IsRet']=True;f.run(Cfg=cfg,Enable=False,Inp=a)
        self.assertTrue(f.v['Sts']['AtRet'])
    def test_release_waits_for_gate_and_is_not_forgotten(self):
        f=self.r.instance('FB_StationCoils');cmd={i:self.r.value('ST_StationCoil') for i in range(1,11)}
        loss=copy.deepcopy(cmd);release=copy.deepcopy(cmd);cmd[1]['work']=True;release[1]['home']=True
        allow={i:True for i in range(1,11)};active={i:False for i in range(1,11)};active[1]=True
        a=dict(Cmd=cmd,LossPolicy=loss,PolicyVerified=True,NewPermit=True,Manual=True,
               GateChanges=True,ChangeAllowed=allow,ManualActive=active,ReleaseVerified=True,ReleasePolicy=release)
        f.run(**a);active[1]=False;allow[1]=False;f.run(**a);allow[1]=True;f.run(**a)
        self.assertFalse(f.v['Applied'][1]['work']);self.assertTrue(f.v['Applied'][1]['home'])
    def test_device_request_is_held_until_accepted(self):
        t=check_station.StationTests();t.r=self.r;f,cfg,c,a=t.bottom_fixture({6})
        a['BeltsStopped']=False;c['SingleUnloadReq']=True;f.run(Cfg=cfg,Cmd=c,Inp=a)
        self.assertFalse(f.v['Outp']['AcceptedPulse'])
        a['BeltsStopped']=True;f.run(Cfg=cfg,Cmd=c,Inp=a)
        self.assertTrue(f.v['Outp']['AcceptedPulse'])
    def test_loaded_elevator_cannot_return_top_when_lower_is_blocked(self):
        f=self.r.instance('FB_StationDrain');a=self.r.value('ST_StationDrainIn')
        a.update(enable=True,known=True,atBottom=True,lowerCanAccept=False);a['occupied'][4]=True;a['occupied'][3]=True
        d=self.r.value('ST_RobotDrain');d.update(request=True,runPermit=True)
        f.run(Inp=a,Drain=d);f.run(Inp=a,Drain=d);self.assertEqual(f.v['Sts']['action'],0)
    def test_stopping_timeout_never_certifies_standstill(self):
        from plc_station_main import MainCell
        cell=MainCell();r=cell.r;f=r.instance('FB_Elevator');a=r.value('ST_ElevatorIn')
        a.update(xSafetyOk=True,xDoorClosed=True,xCommOk=True,xInPos1=True)
        a['stVfdRx']['uiOutFreq_0p1Hz_3202']=200
        cfg=r.value('ST_ElevatorPar');cfg.update(tStopTimeout=20,rStopSpeedThreshold_Hz=1.0,rMaxSpeed_Hz=50,tMoveTimeout=1000)
        f.v['stStat']['eState']=40;f.v['Altivar_320']=False
        for _ in range(3):f.run(xEnable=True,stIn=a,stPar=cfg,stCmd=r.value('ST_ElevatorCmd'))
        self.assertNotEqual(f.v['stStat']['eState'],10);self.assertTrue(f.v['stStat']['xFault'])
    def test_recovery_can_resolve_idle_mechanics_with_retained_owner(self):
        r=self.r;f=r.instance('FB_RobotRecovery');p=plant(r);p.update(transferBusy=True,physicalIdle=True)
        c=context(r);c['station']['nextOperationId']=400;c['station']['nextMaterialEventId']=90
        proposal=copy.deepcopy(c);proposal['station']['nextOperationId']=1;proposal['station']['nextMaterialEventId']=2
        cmd=r.value('ST_RobotCommands');cmd['recover']=True
        rx=r.value('ST_RobotRxV2');rx.update(production_home=True,production_loadKnown=True)
        f.run(AtRecovery=True,Neutral=True,Cmd=cmd,Plant=p,Rx=rx,Proposal=proposal,Context=c)
        self.assertTrue(f.v['Approved']);self.assertEqual(c['station']['nextOperationId'],400)
        self.assertEqual(c['station']['nextMaterialEventId'],90)

class ResourceAndLedgerTests(unittest.TestCase):
    def setUp(self):self.r=station_runtime()
    def test_receipt_releases_belt_but_keeps_output_reserved(self):
        r=self.r;f=r.instance('FB_StationTransport');a=r.value('ST_StationTransportIn')
        a.update(permit=True,resourcesUsed=True,localRequest=True,localReady=True,localAllowed=True)
        f.run(Inp=a);localId=f.v['Sts']['operationId']
        a.update(localRequest=False,unloadIssued=True,outputPending=True,productionPermit=True)
        f.run(Inp=a)
        self.assertTrue(f.v['Sts']['productionTopAllowed']);self.assertTrue(f.v['Sts']['productionBottomAllowed'])
        self.assertTrue(f.v['Sts']['resources'][5]['accepted'])
        a['productionBottomBusy']=True;f.run(Inp=a);beltId=f.v['Sts']['resources'][4]['id']
        self.assertNotEqual(beltId,localId)
        a.update(actionDone=True,outputPending=False);f.run(Inp=a)
        self.assertEqual(f.v['Sts']['resources'][4]['id'],beltId)
        self.assertTrue(f.v['Sts']['resources'][4]['accepted']);self.assertFalse(f.v['Sts']['resources'][5]['accepted'])
    def test_latched_reconciliation_fault_does_not_block_physical_idle_recovery(self):
        r=self.r;f=r.instance('FB_StationRecovery');c=context(r);p=copy.deepcopy(c)
        f.run(Context=c,Proposal=p,Invalidate=True,Blocked=True,PhysicalIdle=True,RobotReady=True,Confirm=True)
        self.assertFalse(f.v['Approved'])
        f.run(Context=c,Proposal=p,Invalidate=True,Blocked=False,PhysicalIdle=True,RobotReady=True,Confirm=True)
        self.assertTrue(f.v['Approved']);self.assertFalse(f.v['Required'])
    def test_old_completion_cannot_release_new_operation(self):
        r=self.r;f=r.instance('FB_StationTransport');a=r.value('ST_StationTransportIn')
        a.update(permit=True,resourcesUsed=True,localRequest=True,localReady=True,localAllowed=True,requireIds=True)
        f.run(Inp=a);ident=f.v['Sts']['operationId']
        a.update(localRequest=False,actionDone=True,doneId=ident+1);f.run(Inp=a)
        self.assertEqual(f.v['Sts']['operationId'],ident);self.assertFalse(f.v['Sts']['done'])
        self.assertTrue(f.v['Sts']['resources'][5]['accepted'])
        a['doneId']=ident;f.run(Inp=a);self.assertTrue(f.v['Sts']['done'])
    def test_material_events_are_atomic_and_duplicates_have_no_effect(self):
        r=self.r;f=r.instance('FB_StationMaterial');a=r.value('ST_StationMaterialIn')
        a.update(valid=True,reconcile=True,useEvents=True);a['restored'][4]=True;a['restored'][7]=True
        f.run(Inp=a);a['reconcile']=False
        a['events'][1].update(id=1,source=4,target=5);a['events'][2].update(id=2,source=7,target=0)
        f.run(Inp=a);self.assertTrue(f.v['Sts']['occupied'][5]);self.assertFalse(f.v['Sts']['occupied'][7])
        snapshot=copy.deepcopy(f.v['Sts']['occupied']);f.run(Inp=a);self.assertEqual(f.v['Sts']['occupied'],snapshot)
        a['events'][1].update(id=3,source=5,target=6);a['events'][2].update(id=4,source=4,target=1)
        f.run(Inp=a);self.assertTrue(f.v['Sts']['fault']);self.assertEqual(f.v['Sts']['occupied'],snapshot)
    def test_station_recovery_preserves_generations_and_operation_ids(self):
        r=self.r;f=r.instance('FB_StationRecovery');c=context(r);p=copy.deepcopy(c)
        c['hmiGeneration']=42;c['station']['nextOperationId']=100
        p['hmiGeneration']=1;p['occupied'][4]=True;p['elevatorLoadPresent']=False
        a=dict(Context=c,Proposal=p,PhysicalIdle=True,RobotReady=True,Confirm=True)
        f.run(**a);self.assertFalse(f.v['Approved'])
        p['elevatorLoadPresent']=True;f.run(**a);self.assertTrue(f.v['Approved'])
        self.assertEqual(c['hmiGeneration'],42);self.assertEqual(c['station']['nextOperationId'],100)
    def test_driver_ignores_unverified_mapping(self):
        from plc_station_main import MainCell
        cell=MainCell();f=cell.r.instance('FB_ElevatorDriveAdapter');f.v['Altivar_320']=False
        cmd=cell.r.value('ST_ElevatorDriveCmd');cmd.update(enable=True,forward=True,reference=100)
        f.run(Cmd=cmd,MappingVerified=False,CommHealthy=True,FrequencyValid=True)
        self.assertFalse(f.v['Feedback']['valid']);self.assertFalse(f.v['fbAtv'].v['i_xEn'])
        f.run(Cmd=cmd,MappingVerified=True,CommHealthy=True,FrequencyValid=False)
        self.assertFalse(f.v['fbAtv'].v['i_xFwd'])

class FullStationTests(unittest.TestCase):
    def test_two_complete_stacks_each_mode_with_real_controller_and_ls(self):
        from plc_station_cosim import StationCell
        for mode,batches in [(2,8),(1,12)]:
            with self.subTest(mode=mode):
                c=StationCell(mode);c.start()
                for n in range(batches):
                    c.begin();c.until(lambda:c.c['goodCount']==7*(n+1))
                    c.until(lambda:c.controller.v['robot'].v['Ledger'].v['Unsettled']==0)
                c.until(lambda:c.c['stackCount']==2)
                self.assertEqual(c.events.count('stackFinished'),2)
                self.assertFalse(c.controller.v['Outp']['robot_Sts']['recoveryRequired'])
    def test_manual_movement_does_not_revoke_its_own_authorization(self):
        from plc_station_cosim import StationCell
        c=StationCell(2);c.command('modeManual')
        c.inp['station_ManualInterlocks']['allowPositive'][10]=True
        c.inp['station_ManualInterlocks']['allowNegative'][10]=True
        c.hmi['link']['uiActivePanel']=112;c.hmi['stationManual']['sessionId']=c.hmi['link']['udiSessionId']
        c.scan();c.hmi['stationManual']['positive'][10]=True
        for _ in range(5):c.hmi['stationManual']['holdCounter'][10]+=1;c.scan()
        self.assertTrue(c.controller.v['Outp']['station_V201Out']['work'])
        self.assertTrue(c.controller.v['stationRecovery'].v['Required'])
        self.assertFalse(c.controller.v['transport'].v['Sts']['fault'])
        c.hmi['stationManual']['positive'][10]=False;c.scan();c.scan()
        c.command('modeAuto');self.assertFalse(c.controller.v['Outp']['robot_Sts']['order']['newPermit'])
        c.proposal.update(copy.deepcopy(c.c));c.proposal['occupancyKnown']=True
        c.proposal['occupied']={i:c.positions[i] is not None for i in range(1,8)}
        c.proposal['elevatorLoadPresent']=c.positions[4] is not None
        c.command('recoveryConfirm');c.scan()
        self.assertFalse(c.controller.v['stationRecovery'].v['Required'])
        self.assertFalse(c.controller.v['Outp']['robot_Sts']['order']['running'])
    def test_invalid_drive_measurement_revokes_permits_and_requires_reconciliation(self):
        from plc_station_cosim import StationCell
        c=StationCell(2);c.start();c.driveValid=False;c.scan()
        out=c.controller.v['Outp']
        self.assertFalse(out['robot_Tx']['production_newOperationPermit'])
        self.assertFalse(out['robot_Tx']['area_elevator_granted'])
        self.assertFalse(out['drive']['forward']);self.assertFalse(out['drive']['reverse'])
        c.driveValid=True
        for _ in range(5):c.scan()
        self.assertFalse(c.controller.v['Outp']['robot_Sts']['order']['running'])
        self.assertTrue(c.controller.v['stationRecovery'].v['Required'])
    def test_io_return_does_not_resume_production(self):
        from plc_station_cosim import StationCell
        c=StationCell(2);c.start();c.inp['station_Inputs']['gatewayHealthy']=False;c.scan()
        out=c.controller.v['Outp'];self.assertFalse(out['robot_Tx']['production_newOperationPermit'])
        self.assertFalse(out['drive']['forward']);self.assertFalse(out['drive']['reverse'])
        c.inp['station_Inputs']['gatewayHealthy']=True
        for _ in range(10):c.scan()
        self.assertFalse(c.controller.v['Outp']['robot_Sts']['order']['running'])
        self.assertTrue(c.controller.v['stationRecovery'].v['Required'])
    def test_manual_imm_requires_current_panel_and_individual_heartbeat(self):
        from plc_station_cosim import StationCell
        c=StationCell(2);c.command('robotDisable');c.command('modeManual')
        c.cfg['robot_Cfg']['hmiTimeout']=30
        c.hmi['link']['uiActivePanel']=201;c.hmi['immManual']['sessionId']=c.hmi['link']['udiSessionId'];c.scan()
        c.hmi['immManual']['positive'][1]=True;c.hmi['immManual']['holdCounter'][1]+=1;c.scan()
        self.assertTrue(c.controller.v['Outp']['robot_Sts']['imm']['mouldClose'])
        for _ in range(5):c.hmi['immManual']['holdCounter'][2]+=1;c.scan()
        self.assertFalse(c.controller.v['Outp']['robot_Sts']['imm']['mouldClose'])
        c.hmi['immManual']['positive'][1]=False;c.scan()
        c.hmi['immManual']['positive'][1]=True;c.hmi['immManual']['holdCounter'][1]+=1;c.scan()
        self.assertTrue(c.controller.v['Outp']['robot_Sts']['imm']['mouldClose'])
        c.hmi['link']['uiActivePanel']=112;c.scan()
        self.assertFalse(c.controller.v['Outp']['robot_Sts']['imm']['mouldClose'])
    def test_current_scan_critical_blocks_tx_and_drive(self):
        from plc_station_cosim import StationCell
        c=StationCell(2);c.start();c.scan()
        c.cfg['station_AlarmCfg']['critical'][53]=True;c.inp['station_AlarmInputs']['active'][53]=True
        c.scan();out=c.controller.v['Outp']
        self.assertFalse(out['robot_Tx']['production_newOperationPermit'])
        self.assertFalse(out['robot_Tx']['imm_newCyclePermit']);self.assertFalse(out['drive']['forward'])
        self.assertFalse(out['drive']['reverse'])
    def test_stop_finishes_overlapping_injections_without_restart(self):
        from plc_station_cosim import StationCell
        for mode in [1,2]:
            with self.subTest(mode=mode):
                c=StationCell(mode);c.start();c.begin()
                c.until(lambda:c.c['cycles'][1]['picked'])
                c.begin();c.physicalStop=True;c.scan();c.physicalStop=False
                self.assertFalse(c.controller.v['Outp']['robot_Tx']['imm_newCyclePermit'])
                c.until(lambda:c.c['goodCount']==14)
                c.until(lambda:c.controller.v['Outp']['robot_Sts']['order']['settled'])
                self.assertEqual(c.events.count('immPickupCompleted'),2)
                for _ in range(10):c.scan()
                self.assertFalse(c.controller.v['Outp']['robot_Sts']['order']['running'])
    def test_drain_stop_finishes_transfer_then_waits_for_start_and_last_pickup(self):
        from plc_station_cosim import StationCell
        c=StationCell(2);c.command('orderEnd');c.start()
        c.until(lambda:c.controller.v['Outp']['io_dout']['ctrl_turn_on_top_conveyor'])
        ident=c.controller.v['transport'].v['Sts']['operationId']
        c.physicalStop=True;c.scan();c.physicalStop=False
        c.until(lambda:c.controller.v['transport'].v['Sts']['owner']==0)
        self.assertEqual(c.controller.v['transport'].v['Sts']['operationId'],ident)
        for _ in range(8):c.scan()
        self.assertFalse(c.controller.v['Outp']['drain']['runPermit'])
        self.assertTrue(c.c['orderActive']);self.assertIsNotNone(c.positions[4])
        c.autoPickup=False;c.start()
        c.until(lambda:c.controller.v['fbBottom567'].v['Sts']['WaitingPickup'])
        for _ in range(8):c.scan()
        self.assertTrue(c.c['orderActive']);self.assertFalse(c.controller.v['Outp']['drain']['done'])
        c.autoPickup=True;c.until(lambda:not c.c['orderActive'],limit=400)
        self.assertFalse(any(c.positions.values()))
    def test_end_order_drains_actual_buffers_then_closes(self):
        from plc_station_cosim import StationCell
        c=StationCell(2);c.command('orderEnd');self.assertTrue(c.c['orderActive'])
        for _ in range(4):c.scan()
        self.assertFalse(c.controller.v['Outp']['drain']['runPermit'])
        c.start();c.until(lambda:not c.c['orderActive'],limit=400)
        self.assertFalse(any(c.positions.values()))
        self.assertTrue(c.controller.v['Outp']['station_Material']['emptyConfirmed'])

if __name__=='__main__':unittest.main(verbosity=2)
