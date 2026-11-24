"""Integration regressions for audited failures. Runs real ST, hardware is synthetic."""
import copy
import unittest
import check_station
from check_station import station_runtime
from check_plc_robot import context,plant

class AuditedFailures(unittest.TestCase):
    def setUp(self):self.r=station_runtime()
    def test_transport_reconcile_requires_request_validity_and_standstill(self):
        blocks = [
            ('FB_TopFlowManager', 'ST_TopFlowCfg', 'ST_TopFlowCmd', 'ST_TopFlowIn', ('OccP1','OccP2','OccP3'), ('TopConveyor_Run','ElevConv_RunFwd')),
            ('FB_BottomAccumulator_567', 'ST_Bottom567Cfg', 'ST_Bottom567Cmd', 'ST_Bottom567In', ('Occ5','Occ6','Occ7'), ('ConvRun','ElevConv_RunBwd')),
        ]
        for block,cfg_type,cmd_type,input_type,occupied,motion in blocks:
            for mask in range(8):
                for request,valid,stopped in [(False,True,True),(True,False,True),(True,True,False),(True,True,True)]:
                    with self.subTest(block=block,mask=mask,request=request,valid=valid,stopped=stopped):
                        f=self.r.instance(block)
                        initial=[True,False,True]
                        for key,value in zip(occupied,initial):f.v['Sts'][key]=value
                        f.v['Sts']['State']=40
                        inp=self.r.value(input_type)
                        inp.update(Reconcile=request,Valid=valid,BeltsStopped=stopped)
                        restored=[bool(mask & (1 << bit)) for bit in range(3)]
                        inp['Restored'].update({index+1:value for index,value in enumerate(restored)})
                        f.run(Cfg=self.r.value(cfg_type),Cmd=self.r.value(cmd_type),Inp=inp)
                        accepted=request and valid and stopped
                        self.assertEqual([f.v['Sts'][key] for key in occupied],restored if accepted else initial)
                        self.assertEqual(f.v['Sts']['State'],10 if accepted else 40)
                        self.assertFalse(any(f.v['Outp'][key] for key in motion))

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
        f.run(Inp=a,Drain=d);f.run(Inp=a,Drain=d);self.assertEqual(f.v['Sts']['action_'],0)
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
        cmd=cell.r.value('ST_ElevatorDriveCmd');cmd.update(enable=True,forward=True,reference_=100)
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
    def test_next_box_order_waits_for_new_container_and_measured_edge(self):
        from plc_station_cosim import StationCell
        c = StationCell(1)
        c.start()
        def wire():
            return c.controller.v['Outp']['robot_Tx']
        c.until(lambda: wire()['area_elevator_ready'])
        c.begin()
        c.until(lambda: c.c['goodCount'] == 7)
        old_stack = c.c['stackId']
        c.command('orderEnd')
        c.until(lambda: not c.c['orderActive'], limit=500)
        self.assertFalse(c.hmi['permit']['orderOpen']['xAllowed'])
        self.assertIsNone(c.positions[4])
        self.assertEqual(c.axis, 4)
        self.assertNotEqual(c.c['stackId'], old_stack)
        self.assertEqual(c.c['goodCount'], 7)
        c.until(lambda: c.native.get(c.native.p, 'state') == 720 and not c.controller.v['Outp']['robot_Sts']['order']['settled'])
        c.native.set(c.native.b, 'stationIdleConfirmed', True)
        c.native.set(c.native.b, 'newApproved', True)
        c.until(lambda: not c.native.get(c.native.b, 'needsRecovery') and not c.native.get(c.native.b, 'newApproved'))
        c.until(lambda: c.native.get(c.native.p, 'state') == 710 and c.hmi['permit']['orderOpen']['xAllowed'])
        c.command('orderOpen')
        c.start()
        self.assertTrue(c.controller.v['Outp']['robot_Sts']['order']['running'])
        for _ in range(30):
            c.scan()
            self.assertFalse(wire()['area_elevator_ready'] or wire()['area_elevator_granted'])
        c.positions[1] = {'trays': 1}
        c.until(lambda: c.controller.v['fbTopFlow'].v['Sts']['Pos1SensorStable'])
        c.inp['io_di']['ind_button_container_ready'] = True
        c.scan()
        c.inp['io_di']['ind_button_container_ready'] = False
        for _ in range(300):
            c.scan()
            if wire()['area_elevator_ready']:
                break
            self.assertFalse(wire()['area_elevator_granted'])
        self.assertTrue(wire()['area_elevator_ready'], c.debug())
        self.assertIsNotNone(c.positions[4])
        self.assertGreater(c.axis, c.p4edge)
        self.assertLess(c.axis, 4)
        self.assertTrue(c.controller.v['elevStat']['xStandstill'])
        c.begin()
        c.until(lambda: c.c['goodCount'] == 14)

    def test_box_stop_keeps_edge_and_recovery_remeasures_same_load(self):
        from plc_station_cosim import StationCell
        c = StationCell(1)
        c.start()
        def ready():
            return c.controller.v['Outp']['robot_Tx']['area_elevator_ready']
        def stop():
            c.physicalStop = True
            c.scan()
            c.physicalStop = False
            c.until(lambda: c.controller.v['Outp']['robot_Sts']['order']['stopped'])
        c.until(ready)
        position = c.axis
        stack = c.c['stackId']
        stop()
        c.start()
        c.until(ready)
        self.assertEqual(c.axis, position)
        self.assertEqual(c.c['stackId'], stack)
        stop()
        c.command('modeManual')
        c.inp['station_ManualInterlocks']['allowPositive'][4] = True
        c.hmi['link']['uiActivePanel'] = 112
        jog = c.hmi['stationManual']
        jog['sessionId'] = c.hmi['link']['udiSessionId']
        c.scan()
        jog['positive'][4] = True
        for _ in range(12):
            jog['holdCounter'][4] += 1
            c.scan()
        jog['positive'][4] = False
        c.until(lambda: c.controller.v['physicalIdle'] and not c.controller.v['manual'].v['Sts']['active'])
        self.assertIsNotNone(c.positions[4])
        self.assertTrue(c.inp['station_Inputs']['occupied'][4])
        self.assertFalse(c.controller.v['elevStat']['xContainerEdgeReached'])
        c.command('modeAuto')
        c.proposal.update(copy.deepcopy(c.c))
        c.proposal['occupancyKnown'] = True
        c.proposal['occupied'] = {i: load is not None for i, load in c.positions.items()}
        c.proposal['elevatorLoadPresent'] = c.positions[4] is not None
        c.command('recoveryConfirm')
        for _ in range(4):
            c.scan()
            self.assertFalse(ready())
        c.start()
        c.until(ready)
        self.assertEqual(c.c['stackId'], stack)
        self.assertGreater(c.axis, c.p4edge)

    def test_standalone_cycles_and_high_start_across_mode_change(self):
        from plc_station_cosim import StationCell
        c = StationCell(2)
        c.command('robotDisable')
        imm = c.inp['robot_Plant']['imm']
        tx = lambda: c.controller.v['Outp']['robot_Tx']
        first_cycle = c.c['nextCycleId']
        for _ in range(4):
            imm['startConfirmed'] = False
            c.scan()
            imm['startConfirmed'] = True
            c.scan()
            self.assertEqual(tx()['imm_unsettledCount'], 0)
            self.assertTrue(tx()['imm_applied_mouldClose'])
        c.command('robotEnable')
        c.start()
        self.assertEqual(c.c['nextCycleId'], first_cycle)
        self.assertEqual(tx()['imm_unsettledCount'], 0)
        c.begin()
        c.until(lambda: c.c['goodCount'] == 7)
        self.assertEqual(c.c['nextCycleId'], (first_cycle + 1) % 65536)

    def test_drain_takes_unaccepted_p1_and_routes_each_unload_through_p6(self):
        from plc_station_cosim import StationCell
        c = StationCell(1)
        c.positions[1] = {'trays': 1}
        c.until(lambda: c.c['occupied'][1])
        self.assertFalse(c.controller.v['fbTopFlow'].v['Sts']['Pos1Accepted'])
        c.command('orderEnd')
        c.start()
        lower_moves = []
        passed_barrier = False
        for _ in range(700):
            c.scan()
            top = c.controller.v['fbTopFlow'].v
            if top['Sts']['SrcPos'] == 1 and top['Cmd']['EmptyingMode']:
                passed_barrier |= top['Inp']['LoadBarrierBlocked']
                self.assertFalse(top['Sts']['P1ReleasedForLoad'])
            bottom = c.controller.v['fbBottom567'].v['Outp']
            if bottom['MaterialMovedPulse']:
                lower_moves.append((bottom['MaterialSource'], bottom['MaterialTarget'], bottom['AcceptedId']))
            if not c.c['orderActive']:
                break
        self.assertTrue(passed_barrier)
        self.assertFalse(c.c['orderActive'], c.debug())
        self.assertFalse(any(c.positions.values()))
        to_p6 = [ident for source, target, ident in lower_moves if (source, target) == (5, 6)]
        to_p7 = [ident for source, target, ident in lower_moves if (source, target) == (6, 7)]
        self.assertEqual(len(to_p6), 3)
        self.assertEqual(to_p6, to_p7)
        self.assertEqual(len(set(to_p6)), 3)

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
    def test_hmi_pause_finishes_started_production_and_resumes_open_order(self):
        from plc_station_cosim import StationCell
        for mode in [1, 2]:
            with self.subTest(mode=mode):
                c = StationCell(mode)
                self.assertFalse(c.hmi['permit']['resume']['xAllowed'])
                c.start()
                c.begin()
                c.command('pause')
                self.assertTrue(c.hmi['state']['xHmiPausePending'])
                self.assertFalse(c.hmi['permit']['resume']['xAllowed'])
                self.assertFalse(c.controller.v['Outp']['robot_Tx']['imm_newCyclePermit'])
                c.until(lambda: c.hmi['state']['xHmiPaused'])
                self.assertTrue(c.c['orderActive'])
                self.assertEqual(c.c['goodCount'], 7)
                c.until(lambda: c.hmi['permit']['resume']['xAllowed'])
                c.command('resume')
                self.assertFalse(c.hmi['state']['xHmiPaused'])
                self.assertTrue(c.controller.v['Outp']['robot_Sts']['order']['newPermit'])
                self.assertEqual(c.c['goodCount'], 7)

    def test_hmi_pause_finishes_current_drain_transfer_before_resuming(self):
        from plc_station_cosim import StationCell
        c = StationCell(2)
        c.command('orderEnd')
        c.start()
        c.until(lambda: c.controller.v['Outp']['io_dout']['ctrl_turn_on_top_conveyor'])
        operation = c.controller.v['transport'].v['Sts']['operationId']
        c.command('pause')
        c.until(lambda: c.hmi['state']['xHmiPaused'])
        self.assertEqual(c.controller.v['transport'].v['Sts']['operationId'], operation)
        self.assertFalse(c.controller.v['Outp']['drain']['runPermit'])
        self.assertTrue(c.c['orderActive'])
        c.until(lambda: c.hmi['permit']['resume']['xAllowed'])
        c.command('resume')
        c.until(lambda: not c.c['orderActive'], limit=400)
        self.assertFalse(any(c.positions.values()))

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

class EtherNetIpImageTests(unittest.TestCase):
    """Execute the actual I/O programs; hardware transport remains synthetic."""
    def setUp(self):
        from plc_station_main import MainCell
        self.cell = MainCell()
        self.robot = self.cell.g['GVL_Robot']

    def test_input_bit_positions_endianness_and_current_scan_decode(self):
        import struct
        frames = [[0] * 40, [65535] * 40]
        frames += [[1 << bit] * 40 for bit in range(16)]
        frames += [[((index + 1) * 0x0102 + 0x0080) & 65535 for index in range(40)], [0] * 40]
        self.robot['EipOutWords'].update({index: 0xA55A for index in range(40)})
        self.robot['RawOut'].update({index: 0x5A for index in range(80)})
        for number, words in enumerate(frames):
            with self.subTest(frame=number):
                self.robot['EipInWords'].update(dict(enumerate(words)))
                self.robot['RawIn'].update({index: 0xCC for index in range(80)})
                self.cell.g['PRG_IO_Read'].run()
                self.assertEqual(bytes(self.robot['RawIn'][index] for index in range(80)),
                                 struct.pack('<40H', *words))
                self.assertEqual(self.robot['Rx']['link_version'], words[4])
                self.assertEqual(self.robot['Rx']['link_heartbeat'], words[5])
                self.assertEqual(list(self.robot['EipInWords'].values()), words)
                self.assertTrue(all(value == 0xA55A for value in self.robot['EipOutWords'].values()))
                self.assertTrue(all(value == 0x5A for value in self.robot['RawOut'].values()))

    def test_festo_input_bits_reach_only_the_documented_hmi_signal(self):
        def limit_switches(first, last):
            return [f'V{valve}_{position}' for valve in range(first, last + 1)
                    for position in ('HP', 'WP')]

        expected = {
            0: limit_switches(401, 402) + ['B401', 'B402'],
            2: limit_switches(101, 104),
            3: limit_switches(105, 108),
            4: limit_switches(109, 110) + ['B101', 'B102', 'B103'],
            5: limit_switches(301, 304),
            6: [None, 'B302', 'B303', 'B304'],
            9: limit_switches(201, 203),
            11: limit_switches(501, 501),
        }
        station = self.cell.g['GVL_Station']
        station['Inputs'].update(mappingVerified=True, gatewayHealthy=True, imageFresh=True)
        station['Inputs']['moduleHealthy'].update({i: True for i in range(1, 12)})
        image = self.cell.g['GVL_Festo']['EipInBytes']
        hmi = self.cell.g['GVL_HMI']['vijeo']
        all_signals = {f'ind_{alias}' for aliases in expected.values() for alias in aliases if alias}
        for byte, aliases in expected.items():
            for bit in range(8):
                with self.subTest(byte=byte, bit=bit):
                    image[byte] = 1 << bit
                    self.cell.scan()
                    alias = aliases[bit] if bit < len(aliases) else None
                    active = {name for name in all_signals if hmi['value'][name]}
                    self.assertEqual(active, {f'ind_{alias}'} if alias else set())
                    if alias:
                        self.assertTrue(hmi['valid'][f'ind_{alias}'])
                    image[byte] = 0

    def test_v501_hmi_indicates_the_sensor_without_authorizing_motion(self):
        festo = self.cell.g['GVL_Festo']
        hmi = self.cell.g['GVL_HMI']['vijeo']
        for byte, home, work in ((2, False, True), (1, True, False),
                                 (3, False, False), (0, False, False)):
            with self.subTest(byte=byte):
                festo['EipInBytes'][11] = byte
                self.cell.scan()
                self.assertEqual(hmi['cylinders'][0]['atHome'], home)
                self.assertEqual(hmi['cylinders'][0]['atWork'], work)
                self.assertFalse(hmi['valid']['ind_V501_HP'])
                self.assertFalse(hmi['valid']['ind_V501_WP'])
                self.assertFalse(hmi['cylinders'][0]['valid'])
                self.assertFalse(self.robot['Tx']['cyl_V501_atHome'])
                self.assertFalse(self.robot['Tx']['cyl_V501_atWork'])
                self.assertEqual(festo['EipOutWords'][2] & 0x03, 0)
                self.assertFalse(hmi['cylinders'][1]['atHome'])
                self.assertFalse(hmi['cylinders'][1]['atWork'])

    def test_feedback_reaches_consumers_and_stale_values_lose_validity(self):
        station = self.cell.g['GVL_Station']
        station['IoCfg'].update(configured=True, stable=10)
        station['Inputs'].update(mappingVerified=True, gatewayHealthy=True, imageFresh=True)
        station['Inputs']['moduleHealthy'].update({i: True for i in range(1, 12)})
        station['Inputs']['positionValid'][4] = True
        station.update(LocalIoHealthy=True, PhysicalStopValid=True)
        self.robot['stationIoBound'] = True
        self.robot['storageIn']['Left']['configured'] = True
        self.robot['storageIn']['Right']['configured'] = True
        self.robot['Plant']['imm']['valid'] = True
        raw = self.cell.g['GVL_IO_RAW']['di']
        raw.update(ind_gripper_1_work=True, ind_e67_imm_mould_open=True,
                   ind_spacer_storage_robot_side_doors_opening_permission=True)
        festo = self.cell.g['GVL_Festo']['EipInBytes']
        festo.update({0: 0x29, 4: 0x50, 5: 0x41, 6: 0x0B, 11: 0x01})
        self.cell.scan()
        inp = self.cell.main.v['inp']
        inputs = inp['station_Inputs']
        self.assertEqual(list(inputs['occupied'].values()), [True, False, True, False, True, False, True])
        self.assertTrue(inputs['lowerStop'][1]['ind_1_bwd'])
        self.assertTrue(inputs['lowerStop'][2]['ind_2_bwd'])
        self.assertTrue(inputs['lowerFeedbackValid'])
        self.assertTrue(inp['robot_storageIn']['Left']['atHome'])
        self.assertTrue(inp['robot_storageIn']['Right']['atWork'])
        self.assertTrue(inp['robot_storageIn']['Empty'])
        self.assertTrue(inp['robot_storageIn']['RobotSideOpeningPermission'])
        self.assertTrue(inp['robot_Plant']['cylinders'][1]['atHome'])
        self.assertTrue(inp['robot_Plant']['cylinders'][2]['atWork'])
        self.assertTrue(inp['robot_Plant']['imm']['mouldOpen'])
        hmi = self.cell.g['GVL_HMI']['vijeo']
        self.assertFalse(hmi['valid']['ind_B301'])
        self.assertFalse(self.cell.main.v['station'].v['fbBottom567'].v['Inp']['Valid'])
        station['B301PolarityVerified'] = True
        self.cell.scan()
        bottom = self.cell.main.v['station'].v['fbBottom567']
        self.assertTrue(bottom.v['Inp']['Valid'])
        self.assertTrue(bottom.v['Inp']['sElevatorEmptied_raw'])
        self.assertTrue(hmi['valid']['ind_B301'])
        self.assertFalse(hmi['value']['ind_B301'])
        festo[6] &= ~1
        self.cell.scan()
        self.assertFalse(bottom.v['Inp']['sElevatorEmptied_raw'])
        self.assertTrue(hmi['value']['ind_B301'])
        station['B301HighWhenOccupied'] = False
        self.cell.scan()
        self.assertTrue(bottom.v['Inp']['sElevatorEmptied_raw'])
        self.assertFalse(hmi['value']['ind_B301'])
        station['Inputs']['moduleHealthy'][8] = False
        station['Inputs']['moduleHealthy'][11] = False
        station['LocalIoHealthy'] = False
        station['PhysicalStopValid'] = False
        self.cell.scan()
        inp = self.cell.main.v['inp']
        self.assertFalse(hmi['valid']['ind_B301'])
        self.assertFalse(hmi['value']['ind_B301'])
        self.assertFalse(bottom.v['Inp']['Valid'])
        self.assertTrue(hmi['valid']['ind_V301_HP'])
        self.assertFalse(hmi['valid']['ind_B302'])
        self.assertFalse(hmi['valid']['ind_V501_HP'])
        self.assertFalse(hmi['valid']['ind_V502_WP'])
        self.assertFalse(inp['robot_Plant']['cylinders'][1]['atHome'])
        self.assertFalse(inp['robot_Plant']['imm']['valid'])
        self.assertTrue(inp['robot_Plant']['physicalStop'])

    def test_held_start_requires_release_after_io_returns(self):
        station = self.cell.g['GVL_Station']
        self.robot['stationIoBound'] = True
        raw = self.cell.g['GVL_IO_RAW']['di']
        raw['ind_button_start_process'] = True
        self.cell.scan()
        station.update(LocalIoHealthy=True, PhysicalStopValid=True)
        self.cell.scan()
        self.assertFalse(self.cell.main.v['inp']['io_di']['ind_button_start_process'])
        self.assertTrue(self.cell.g['GVL_HMI']['vijeo']['value']['ind_S5'])
        raw['ind_button_start_process'] = False
        self.cell.scan()
        raw['ind_button_start_process'] = True
        self.cell.scan()
        self.assertTrue(self.cell.main.v['inp']['io_di']['ind_button_start_process'])

    def test_wired_output_addresses_are_unique_and_leave_sto_out(self):
        import re

        source = self.cell.r.root / 'GVLs/ST_GVL_IO_DO_RAW.st'
        pairs = re.findall(r'(\w+)\s+AT\s+(%QX\d+\.\d+)\s*:', source.read_text(encoding='utf-8'))
        addresses = dict(pairs)
        self.assertEqual(len(pairs), len(set(addresses.values())))
        self.assertNotIn('%QX7.1', addresses.values())
        self.assertNotIn('%QX7.5', addresses.values())
        self.assertNotIn('%QX7.7', addresses.values())
        for name, address in (
            ('ctrl_turn_on_elevator_conveyor_out', '%QX1.0'),
            ('ctrl_turn_on_elevator_conveyor_in', '%QX1.1'),
            ('ctrl_turn_on_buzzer', '%QX7.6'),
        ):
            with self.subTest(name=name):
                self.assertEqual(addresses[name], address)
                commands = self.cell.g['GVL_IO']['dout']
                commands[name] = True
                self.cell.g['PRG_IO_Write'].run()
                raw = self.cell.g['GVL_IO_RAW']['dout']
                self.assertEqual({n for n, value in raw.items() if value}, {name})
                commands[name] = False

    def test_festo_output_bits_have_independent_owners_and_clear_reserves(self):
        coil_order = (
            (0, 8, 2), (0, 10, 3), (0, 12, 4), (0, 14, 1), (1, 0, 5),
            (1, 2, 9), (1, 4, 10), (1, 8, 6), (1, 10, 8), (1, 12, 7),
        )
        commands = self.cell.g['GVL_Station']['Coils']
        storage = self.robot['storageOut']
        bindings = [(word, bit + index, commands[coil], key)
                    for word, bit, coil in coil_order
                    for index, key in enumerate(('work', 'home'))]
        bindings += [(0, index, storage, name) for index, name in enumerate(
            ('Q_V401Work', 'Q_V401Home', 'Q_V402Work', 'Q_V402Home'))]
        for i in range(1, 6):
            bindings += [(2, 2 * (i - 1) + bit, self.robot['Sts']['cylinders'][i], key)
                         for bit, key in enumerate(('work', 'home'))]
            bindings += [(i + 2, bit, self.robot['Sts']['vacuum'][i], key)
                         for bit, key in enumerate(('hold', 'blow'))]
        self.assertEqual(len(bindings), 44)
        actual = self.cell.g['GVL_Festo']['EipOutWords']
        for word, bit, owner, key in bindings:
            with self.subTest(word=word, bit=bit):
                actual.update({i: 0xFFFF for i in range(8)})
                owner[key] = True
                self.cell.g['PRG_IO_Write'].run()
                self.assertEqual(list(actual.values()), [1 << bit if i == word else 0 for i in range(8)])
                owner[key] = False

    def test_output_uses_current_encoded_frame_and_clears_stale_reserves(self):
        import json
        import struct
        from check_plc_robot import ROOT
        from build_plc_robot import field
        signals = json.loads((ROOT / 'ROBOT/COMM/mapping.json').read_text(encoding='utf-8'))['signals']
        self.robot['EipInWords'].update({index: 0xA55A for index in range(40)})
        self.robot['RawIn'].update({index: 0x5A for index in range(80)})
        for number, value in enumerate([0, 1, 32768, 65535, 0]):
            with self.subTest(value=value, frame=number):
                tx = self.cell.r.value('ST_RobotTxV2')
                for index, row in enumerate(signals):
                    if row['id'].startswith('p2r.'):
                        tx[field(row['id'])] = bool((index + number) % 2) if row['type'] == 'BOOL' else value
                self.robot['Tx'] = tx
                self.robot['EipOutWords'].update({index: 0xDEAD for index in range(40)})
                self.cell.g['PRG_IO_Write'].run()
                packet = bytes(self.robot['RawOut'][index] for index in range(80))
                self.assertEqual(tuple(self.robot['EipOutWords'][index] for index in range(40)),
                                 struct.unpack('<40H', packet))
                self.assertEqual(self.robot['EipOutWords'][8], value)
                self.assertEqual(self.robot['EipOutWords'][9], value)
                self.assertTrue(all(self.robot['EipOutWords'][index] == 0 for index in range(36, 40)))
                self.assertTrue(all(value == 0xA55A for value in self.robot['EipInWords'].values()))
                self.assertTrue(all(value == 0x5A for value in self.robot['RawIn'].values()))

if __name__=='__main__':unittest.main(verbosity=2)
