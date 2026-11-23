"""Station behavior tests executing actual ST. Synthetic mechanics; no device access."""
from __future__ import annotations
import copy
import itertools
import re
import unittest
from check_plc_robot import runtime, context


def station_runtime():
    r=runtime()
    r.load('Modules/TopFlowManager/FB_TopFlowManager.st',
           'Modules/BottomAccumulator/FB_BottomAccumulator_567.st',
           'Modules/Cyl2Pos/FB_Cyl2Pos.st','Modules/StopperPair/FB_StopperPair.st')
    return r


class DrainCell:
    """Real order/drain/transport/material. Only travel and pickup are synthetic."""
    def __init__(self,r,occupied,mode=2):
        self.r=r;self.order=r.instance('FB_OrderManager');self.drain=r.instance('FB_StationDrain')
        self.transport=r.instance('FB_StationTransport');self.material=r.instance('FB_StationMaterial')
        self.c=context(r);self.c.update(orderActive=True,program_=mode)
        self.d=r.value('ST_RobotDrain');self.cmd=r.value('ST_RobotCommands')
        self.di=r.value('ST_StationDrainIn');self.ti=r.value('ST_StationTransportIn')
        self.mi=r.value('ST_StationMaterialIn');self.occ={i:i in occupied for i in range(1,8)}
        self.mi.update(valid=True,reconcile=True,restored=copy.deepcopy(self.occ))
        self.material.run(Inp=self.mi);self.mi['reconcile']=False
        self.top=True;self.timer=0;self.action=0;self.picked=0;self.physicalBusy=False
        self.autoPickup=True;self.lastAction=0
        self.di.update(enable=True,known=True)
        self.drain.run(Inp=self.di,Drain=self.d) # connected, neutral before first request
        self.start=False;self.stop=False
        self.scan();self.start=True;self.scan();self.start=False
        self.cmd['endOrder']=True;self.scan();self.cmd['endOrder']=False
    def scan(self):
        o=self.order.run(Cmd=self.cmd,Context=self.c,Drain=self.d,PhysicalStart=self.start,
            PhysicalStop=self.stop,Session=True,ProgramOK=True,HomeValid=True,ProcessOK=True,
            OperationsSettled=True,TransferBusy=self.physicalBusy,AreasClear=True,StationIdle=not self.physicalBusy)
        self.di.update(occupied=copy.deepcopy(self.material.v['Sts']['occupied']),
            emptyConfirmed=self.material.v['Sts']['emptyConfirmed'],atTop=self.top,atBottom=not self.top,
            lowerCanAccept=not self.occ[5],actionAccepted=self.transport.v['Sts']['start'] and self.transport.v['Sts']['owner']==20,
            actionDone=self.transport.v['Sts']['done'] and self.transport.v['Sts']['completedOwner']==20)
        self.drain.run(Inp=self.di,Drain=self.d)
        self.ti.update(permit=True,drainPermit=self.d['runPermit'],drainAction=self.drain.v['Sts']['action_'],actionDone=False)
        if self.action:
            self.timer-=1
            if self.timer<=0 and (self.action!=60 or self.autoPickup):
                if self.action==10:self.top=True
                elif self.action==20:self.top=False
                elif self.action==30:
                    source=max(i for i in (1,2,3) if self.occ[i]);self.occ[source]=False;self.occ[4]=True
                elif self.action==40:self.occ[4]=False;self.occ[5]=True
                elif self.action==60:
                    source=max(i for i in (5,6,7) if self.occ[i]);self.occ[source]=False;self.picked+=1
                self.ti['actionDone']=True;self.action=0;self.physicalBusy=False
        self.transport.run(Inp=self.ti)
        if self.transport.v['Sts']['start']:
            self.action=self.transport.v['Sts']['action_'];self.lastAction=self.action;self.timer=3;self.physicalBusy=True
        self.mi.update(observed=copy.deepcopy(self.occ),sensed=copy.deepcopy(self.occ),
            moving=self.physicalBusy,commit=self.ti['actionDone'],pending=self.transport.v['Sts']['busy'])
        self.material.run(Inp=self.mi)
    def finish(self,limit=300):
        for _ in range(limit):
            self.scan()
            if not self.c['orderActive']:return
        raise AssertionError((self.c,self.d,self.drain.v['Sts'],self.transport.v['Sts'],self.occ))


class StationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.r=station_runtime()
    def test_every_initial_occupancy_both_modes_drains_once(self):
        for mode in (1,2):
            for mask in range(128):
                occupied={i for i in range(1,8) if mask & (1<<(i-1))}
                with self.subTest(mode=mode,mask=mask):
                    cell=DrainCell(self.r,occupied,mode);cell.finish()
                    self.assertEqual(cell.picked,len(occupied));self.assertFalse(any(cell.occ.values()))
    def test_stop_during_transfer_finishes_then_pauses_until_fresh_start(self):
        cell=DrainCell(self.r,{3,4,5})
        for _ in range(15):
            cell.scan()
            if cell.action:break
        self.assertTrue(cell.action);cell.stop=True;cell.scan();cell.stop=False
        for _ in range(12):cell.scan()
        self.assertTrue(cell.c['orderActive']);self.assertTrue(cell.d['request'])
        self.assertFalse(cell.d['runPermit']);self.assertEqual(cell.action,0)
        cell.cmd['manual']=True;cell.scan();cell.cmd['manual']=False
        self.assertTrue(cell.order.v['Sts']['manual'])
        cell.cmd['automatic']=True;cell.scan();cell.cmd['automatic']=False
        self.assertFalse(cell.d['runPermit'])
        cell.start=True;cell.scan();cell.start=False;cell.finish()
        self.assertEqual(cell.picked,3)
    def test_last_pickup_required_before_order_closes(self):
        cell=DrainCell(self.r,{7});cell.autoPickup=False
        for _ in range(30):cell.scan()
        self.assertTrue(cell.c['orderActive']);self.assertFalse(cell.d['done'])
        cell.autoPickup=True;cell.finish();self.assertEqual(cell.picked,1)
    def test_end_from_stopped_requires_start_and_keeps_request_during_transfer(self):
        f=self.r.instance('FB_OrderManager');c=context(self.r);c['orderActive']=True
        d=self.r.value('ST_RobotDrain');cmd=self.r.value('ST_RobotCommands');cmd['endOrder']=True
        a=dict(Cmd=cmd,Context=c,Drain=d,Session=True,ProgramOK=True,HomeValid=True,ProcessOK=True,
            OperationsSettled=True,AreasClear=True,StationIdle=True)
        f.run(**a);self.assertTrue(d['request']);self.assertFalse(d['runPermit'])
        cmd['endOrder']=False;f.run(**a,PhysicalStart=True);self.assertTrue(d['runPermit'])
        f.run(**a,PhysicalStart=False,TransferBusy=True);self.assertTrue(d['request'])
        f.run(**a,PhysicalStop=True,TransferBusy=True);self.assertTrue(d['request']);self.assertFalse(d['runPermit'])
    def test_restart_ending_context_never_restores_move_authorization(self):
        f=self.r.instance('FB_OrderManager');c=context(self.r)
        c.update(orderActive=True,ending=True,drainRequested=True)
        d=self.r.value('ST_RobotDrain')
        f.run(Cmd=self.r.value('ST_RobotCommands'),Context=c,Drain=d,Session=True,ProgramOK=True,
              HomeValid=True,ProcessOK=True,OperationsSettled=True,AreasClear=True)
        self.assertTrue(d['request']);self.assertFalse(d['runPermit']);self.assertTrue(c['drainResumeRequired'])
    def test_unknown_material_cannot_be_empty_or_recover_itself_on_valid_image(self):
        f=self.r.instance('FB_StationMaterial');a=self.r.value('ST_StationMaterialIn')
        a.update(valid=True,reconcile=True);a['restored'][4]=True;f.run(Inp=a)
        a.update(reconcile=False,valid=False);f.run(Inp=a)
        a.update(valid=True,commit=True);f.run(Inp=a)
        self.assertFalse(f.v['Sts']['known']);self.assertFalse(f.v['Sts']['emptyConfirmed'])
        self.assertTrue(f.v['Sts']['occupied'][4])
    def test_material_between_sensors_retained_through_movement(self):
        f=self.r.instance('FB_StationMaterial');a=self.r.value('ST_StationMaterialIn')
        a.update(valid=True,reconcile=True);a['restored'][3]=True;f.run(Inp=a)
        a.update(reconcile=False,moving=True,commit=True);f.run(Inp=a)
        self.assertTrue(f.v['Sts']['occupied'][3]);self.assertFalse(f.v['Sts']['emptyConfirmed'])
    def test_material_commit_during_motion_is_not_lost_when_event_ends(self):
        f=self.r.instance('FB_StationMaterial');a=self.r.value('ST_StationMaterialIn')
        a.update(valid=True,reconcile=True);f.run(Inp=a)
        a.update(reconcile=False,moving=True,commit=True);a['observed'][4]=True;f.run(Inp=a)
        a.update(moving=False,commit=False);f.run(Inp=a)
        self.assertTrue(f.v['Sts']['occupied'][4]);self.assertFalse(f.v['Sts']['emptyConfirmed'])
    def test_unbound_io_and_bad_module_revoke_validity_without_false_empty(self):
        f=self.r.instance('FB_StationIo');cfg=self.r.value('ST_StationIoCfg');a=self.r.value('ST_StationIoIn')
        f.run(Cfg=cfg,Inp=a);self.assertFalse(f.v['Sts']['valid'])
        cfg.update(configured=True,stable=20);cfg['required'][2]=True
        a.update(mappingVerified=True,gatewayHealthy=True,imageFresh=True)
        a['positionValid']={i:True for i in range(1,8)};a['moduleHealthy'][2]=True;a['occupied'][4]=True
        for _ in range(3):f.run(Cfg=cfg,Inp=a)
        self.assertTrue(f.v['Sts']['valid']);self.assertTrue(f.v['Sts']['occupied'][4])
        a['moduleHealthy'][2]=False;f.run(Cfg=cfg,Inp=a)
        self.assertFalse(f.v['Sts']['valid']);self.assertTrue(f.v['Sts']['occupied'][4])
    def test_transport_keeps_owner_after_stop_and_critical_requires_reconcile(self):
        f=self.r.instance('FB_StationTransport');a=self.r.value('ST_StationTransportIn')
        a.update(permit=True,drainPermit=True,drainAction=40);f.run(Inp=a)
        self.assertEqual(f.v['Sts']['owner'],20)
        a.update(drainPermit=False,drainAction=0,localRequest=True,localReady=True,localAllowed=True)
        f.run(Inp=a);self.assertEqual(f.v['Sts']['owner'],20)
        a['critical']=True;f.run(Inp=a);self.assertTrue(f.v['Sts']['fault'])
        a['critical']=False;f.run(Inp=a);self.assertTrue(f.v['Sts']['fault'])
        a.update(reconcile=True,localRequest=False);f.run(Inp=a);self.assertFalse(f.v['Sts']['fault'])
    def test_local_unload_in_pause_does_not_resume_drain(self):
        f=self.r.instance('FB_StationTransport');a=self.r.value('ST_StationTransportIn')
        a.update(permit=True,localRequest=True,localReady=True,localAllowed=True,drainPermit=False)
        f.run(Inp=a);self.assertEqual(f.v['Sts']['owner'],30)
        a.update(localRequest=False,actionDone=True);f.run(Inp=a);self.assertTrue(f.v['Sts']['done'])
        a['actionDone']=False;f.run(Inp=a);self.assertEqual(f.v['Sts']['owner'],0)
    def test_rejected_local_request_not_queued(self):
        f=self.r.instance('FB_StationTransport');a=self.r.value('ST_StationTransportIn')
        a.update(permit=True,localRequest=True,localAllowed=True);f.run(Inp=a)
        a.update(localRequest=False,localReady=True);f.run(Inp=a);self.assertEqual(f.v['Sts']['owner'],0)
    def test_unknown_alarm_policy_blocks_production_without_assigning_severity(self):
        f=self.r.instance('FB_AlarmManager');cfg=self.r.value('ST_StationAlarmCfg');a=self.r.value('ST_StationAlarmIn')
        cfg['policyVerified']=True;a['active'][14]=True;f.run(Cfg=cfg,Inp=a)
        self.assertFalse(f.v['Sts']['policyReady']);self.assertFalse(f.v['Sts']['critical'])
        cfg['configured']={i:True for i in range(1,65)};cfg['critical'][14]=True
        f.run(Cfg=cfg,Inp=a);self.assertTrue(f.v['Sts']['critical']);self.assertTrue(f.v['Sts']['policyReady'])
    def test_active_unclassified_extension_blocks_policy_ready(self):
        f=self.r.instance('FB_AlarmManager');cfg=self.r.value('ST_StationAlarmCfg');a=self.r.value('ST_StationAlarmIn')
        cfg['policyVerified']=True
        for i in range(12,53):cfg['configured'][i]=True
        a['active'][53]=True;f.run(Cfg=cfg,Inp=a)
        self.assertFalse(f.v['Sts']['policyReady']);self.assertFalse(f.v['Sts']['critical'])
    def test_cylinder_warning_never_global_critical_and_reset_does_not_clear_active(self):
        f=self.r.instance('FB_AlarmManager');cfg=self.r.value('ST_StationAlarmCfg');a=self.r.value('ST_StationAlarmIn')
        cfg['critical'][6]=True;a['active'][6]=True;a['reset']=True
        for _ in range(50):f.run(Cfg=cfg,Inp=a)
        self.assertTrue(f.v['Sts']['warning']);self.assertFalse(f.v['Sts']['critical'])
        self.assertTrue(f.v['Sts']['entries'][6]['active'])
    def test_alarm_ack_return_reset_are_separate(self):
        f=self.r.instance('FB_AlarmManager');cfg=self.r.value('ST_StationAlarmCfg');a=self.r.value('ST_StationAlarmIn')
        cfg['configured'][14]=True;cfg['latched'][14]=True;a['active'][14]=True;f.run(Cfg=cfg,Inp=a)
        a['acknowledge']=True;f.run(Cfg=cfg,Inp=a);self.assertTrue(f.v['Sts']['entries'][14]['latched'])
        a['active'][14]=False;f.run(Cfg=cfg,Inp=a);self.assertTrue(f.v['Sts']['entries'][14]['returned'])
        a['reset']=True;f.run(Cfg=cfg,Inp=a);self.assertFalse(f.v['Sts']['entries'][14]['latched'])
    def test_parameters_atomic_validation_revisions_and_station2_speed(self):
        f=self.r.instance('FB_StationParameters');cfg=self.r.value('ST_StationParameterCfg')
        cfg.update(limitsVerified=True,minTimeMs=1,maxTimeMs=10000,maxHz=50)
        active={i:self.r.value('ST_StationParameterSet') for i in range(1,5)};edit=copy.deepcopy(active);revision={i:0 for i in range(1,5)}
        snap=self.r.value('ST_StationParameterSet');snap.update(verified=True,sensorStableMs=10,stopDelayMs=20,moveTimeoutMs=500,actuatorTimeoutMs=100,slowHz=5,fastHz=20)
        inp=self.r.value('ST_StationParametersIn');inp.update(apply=2,idle=True)
        args=dict(Cfg=cfg,Inp=inp,Snapshot=snap,Edit=edit,Active=active,Revision=revision)
        f.run(**args);self.assertTrue(f.v['Sts']['applied']);self.assertEqual(revision[2],1)
        before=copy.deepcopy(active);snap['fastHz']=1;inp['expectedRevision']=1;f.run(**args)
        self.assertEqual(active,before);self.assertEqual(revision[2],1)
        snap['fastHz']=25;inp['expectedRevision']=0;f.run(**args);self.assertEqual(active,before)
        inp.update(apply=0,reload=2);f.run(**args);self.assertEqual(edit[2],active[2])
    def test_parameters_no_apply_while_moving_and_no_time_overflow(self):
        f=self.r.instance('FB_StationParameters');cfg=self.r.value('ST_StationParameterCfg')
        inp=self.r.value('ST_StationParametersIn');inp['apply']=1
        active={i:self.r.value('ST_StationParameterSet') for i in range(1,5)};edit=copy.deepcopy(active);revision={i:0 for i in range(1,5)}
        f.run(Cfg=cfg,Inp=inp,Snapshot=self.r.value('ST_StationParameterSet'),Edit=edit,Active=active,Revision=revision)
        self.assertEqual(revision[1],0);self.assertNotEqual(f.v['Sts']['reason'],0)
    def manual_fixture(self):
        f=self.r.instance('FB_StationManual');cmd=self.r.value('ST_StationManualCmd');a=self.r.value('ST_StationManualIn')
        a.update(armed=True,sessionId=4,panel=112,manual=True,idle=True,safe=True,timeout=30)
        cmd['sessionId']=4;a['allowPositive']={i:True for i in range(1,17)};a['allowNegative']=copy.deepcopy(a['allowPositive'])
        f.run(Cmd=cmd,Inp=a);return f,cmd,a
    def test_manual_watchdogs_separate_and_expired_command_needs_release(self):
        f,c,a=self.manual_fixture();c['positive'][10]=True;c['holdCounter'][10]=1
        f.run(Cmd=c,Inp=a);self.assertTrue(f.v['Sts']['positive'][10])
        for _ in range(5):c['holdCounter'][11]+=1;f.run(Cmd=c,Inp=a)
        self.assertFalse(f.v['Sts']['positive'][10])
        c['holdCounter'][10]+=1;f.run(Cmd=c,Inp=a);self.assertFalse(f.v['Sts']['positive'][10])
        c['positive'][10]=False;f.run(Cmd=c,Inp=a);c['positive'][10]=True;c['holdCounter'][10]+=1
        f.run(Cmd=c,Inp=a);self.assertTrue(f.v['Sts']['positive'][10])
    def test_manual_page_session_and_conflicts_require_new_press(self):
        f,c,a=self.manual_fixture();c['positive'][10]=True;c['negative'][10]=True;f.run(Cmd=c,Inp=a)
        self.assertFalse(f.v['Sts']['active']);c['negative'][10]=False;f.run(Cmd=c,Inp=a);self.assertFalse(f.v['Sts']['active'])
        c['positive'][10]=False;f.run(Cmd=c,Inp=a);c['positive'][10]=True;c['holdCounter'][10]+=1;f.run(Cmd=c,Inp=a)
        a['panel']=111;f.run(Cmd=c,Inp=a);self.assertFalse(f.v['Sts']['active'])
        a['panel']=112;f.run(Cmd=c,Inp=a);self.assertFalse(f.v['Sts']['active'])
    def bottom_fixture(self,occupied):
        f=self.r.instance('FB_BottomAccumulator_567');cfg=self.r.value('ST_Bottom567Cfg');cfg.update(stopsConfigured=True,tSensorStable=20,tMotorStopDelay=20,tStepTimeout=500)
        c=self.r.value('ST_Bottom567Cmd');c.update(EnableAuto=True,FinishPermit=True,SafetyOK=True)
        a=self.r.value('ST_Bottom567In');a.update(Valid=True,Reconcile=True,BeltsStopped=True,Stop5Holding=True,Stop6Holding=True)
        a['Restored']={i:i+4 in occupied for i in range(1,4)}
        for i in (5,6,7):a[f'sPos{i}_raw']=i in occupied
        f.run(Cfg=cfg,Cmd=c,Inp=a);a['Reconcile']=False
        return f,cfg,c,a
    def test_bottom_b304_stuck_low_or_high_cannot_complete(self):
        for sensed in (False,True):
            f,cfg,c,a=self.bottom_fixture({7});a['sPos7_raw']=sensed;c['SingleUnloadReq']=True
            done=False
            for _ in range(30):f.run(Cfg=cfg,Cmd=c,Inp=a);done|=f.v['Outp']['SingleUnloadDonePulse']
            self.assertFalse(done);self.assertTrue(f.v['Sts']['Occ7'])
    def test_bottom_one_hold_request_one_pickup_and_no_global_empty(self):
        f,cfg,c,a=self.bottom_fixture({5,6,7});c['SingleUnloadReq']=True
        for _ in range(4):f.run(Cfg=cfg,Cmd=c,Inp=a)
        a['sPos7_raw']=False
        count=0
        for _ in range(25):f.run(Cfg=cfg,Cmd=c,Inp=a);count+=f.v['Outp']['SingleUnloadDonePulse']
        self.assertEqual(count,1);self.assertTrue(f.v['Sts']['Occ5']);self.assertTrue(f.v['Sts']['Occ6'])
    def test_b304_receipt_survives_concurrent_transfer(self):
        for request, occupied in [('DischargeReq', {7}), ('AdvanceReq', {5, 7})]:
            with self.subTest(request=request):
                f, cfg, cmd, inputs = self.bottom_fixture(occupied)
                cmd.update(SingleUnloadReq=True, UnloadId=21)
                for _ in range(5):
                    f.run(Cfg=cfg, Cmd=cmd, Inp=inputs)
                self.assertTrue(f.v['Sts']['PickupSeen'])
                cmd.update(SingleUnloadReq=False, DischargeId=22, AdvanceId=22)
                cmd[request] = True
                inputs['sPos7_raw'] = False
                receipts = []
                for _ in range(7):
                    f.run(Cfg=cfg, Cmd=cmd, Inp=inputs)
                    if f.v['Outp']['SingleUnloadDonePulse']:
                        receipts.append(f.v['Outp']['UnloadDoneId'])
                self.assertEqual(f.v['Outp']['AcceptedId'], 22)
                self.assertEqual(receipts, [21])
                self.assertFalse(f.v['Sts']['WaitingPickup'])

    def test_bottom_transfer_stop_keeps_owner_and_stoppers_wait_for_belt(self):
        f,cfg,c,a=self.bottom_fixture(set());c['DischargeReq']=True;f.run(Cfg=cfg,Cmd=c,Inp=a)
        c.update(EnableAuto=False,DischargeReq=False);a['BeltsStopped']=False
        for _ in range(4):f.run(Cfg=cfg,Cmd=c,Inp=a)
        self.assertFalse(f.v['Outp']['ConvRun']);a['BeltsStopped']=True
        f.run(Cfg=cfg,Cmd=c,Inp=a);f.run(Cfg=cfg,Cmd=c,Inp=a)
        self.assertTrue(f.v['Outp']['ConvRun']);self.assertTrue(f.v['Outp']['ElevConv_RunBwd'])
        a['sElevatorEmptied_raw']=True;f.run(Cfg=cfg,Cmd=c,Inp=a)
        a['sElevatorEmptied_raw']=False;a['sPos5_raw']=True
        done=False
        for _ in range(12):f.run(Cfg=cfg,Cmd=c,Inp=a);done|=f.v['Outp']['DischargeDonePulse']
        self.assertTrue(done);self.assertTrue(f.v['Sts']['Occ5'])
    def test_bottom_warning_blocks_without_secondary_critical_timeout(self):
        f,cfg,c,a=self.bottom_fixture({5});c['SingleUnloadReq']=True;f.run(Cfg=cfg,Cmd=c,Inp=a)
        a['StopWarning']=True
        for _ in range(100):f.run(Cfg=cfg,Cmd=c,Inp=a)
        self.assertFalse(f.v['Diag']['Fault']);self.assertFalse(f.v['Outp']['ConvRun'])
    def test_top_barrier_is_not_replaced_by_b102(self):
        f=self.r.instance('FB_TopFlowManager');cfg=self.r.value('ST_TopFlowCfg')
        cmd=self.r.value('ST_TopFlowCmd');cmd.update(EnableAuto=True,SafetyOK=True)
        a=self.r.value('ST_TopFlowIn');a.update(LoadBarrierValid=True,TopConveyorRunning=True)
        f.v['Sts'].update(State=40,SrcPos=1,Target=2);a['sPos2_raw']=True
        f.run(Cfg=cfg,Cmd=cmd,Inp=a);a['sPos2_raw']=False;f.run(Cfg=cfg,Cmd=cmd,Inp=a)
        self.assertFalse(f.v['Sts']['P1ReleasedForLoad'])
    def test_top_device_wait_never_escalates_warning(self):
        f=self.r.instance('FB_TopFlowManager');cfg=self.r.value('ST_TopFlowCfg');cfg['tStopperTimeout']=10
        cmd=self.r.value('ST_TopFlowCmd');cmd.update(EnableAuto=True,SafetyOK=True)
        a=self.r.value('ST_TopFlowIn');f.v['Sts'].update(State=70,Target=1)
        for _ in range(100):f.run(Cfg=cfg,Cmd=cmd,Inp=a)
        self.assertFalse(f.v['Diag']['Fault'])
    def test_vijeo_guide_matches_published_contract_version(self):
        panel = self.r.instance('FB_RobotHmi')
        hmi = self.r.value('ST_RobotHmiV2')
        panel.run(Hmi=hmi, Context=context(self.r))
        guide = (self.r.root / 'docs/hmi-instructions.md').read_text(encoding='utf-8')
        versions = re.findall(r'uiContractVersion=(\d+)\b', guide)
        self.assertEqual(versions, [str(hmi['link']['uiContractVersion'])])


class IntegrationTests(unittest.TestCase):
    def test_vijeo_manual_indices_keep_requests_and_counters_together(self):
        from plc_station_main import MainCell
        cell = MainCell()
        shared = cell.g['GVL_HMI']
        hmi = cell.main.v['hmiRuntime']
        vijeo = shared['vijeo']
        for key, session in (('stationManual', 11), ('immManual', 12), ('manual', 13)):
            channels = vijeo[key]
            for field, values in channels.items():
                if field.lower().endswith('sessionid'):
                    channels[field] = session
                else:
                    for index in values:
                        values[index] = index + 1 if field == 'holdCounter' else index % 2 == 0
        cell.scan()
        for key in ('stationManual', 'immManual', 'manual'):
            for field, exported in vijeo[key].items():
                source_field = 'negative' if field == 'negativeFrom2' else field
                value = hmi[key][source_field]
                if isinstance(value, dict):
                    first = 2 if field == 'negativeFrom2' else 1
                    self.assertEqual([value[i + first] for i in exported], list(exported.values()), (key, field))
                else:
                    self.assertEqual(value, exported, (key, field))
        self.assertFalse(hmi['stationManual']['negative'][1])
        self.assertFalse(any(hmi['immManual']['negative'].values()))
        self.assertTrue(all(not hmi['immManual']['positive'][i] for i in range(5, 17)))
        self.assertTrue(all(hmi['immManual']['holdCounter'][i] == 0 for i in range(5, 17)))
        vijeo['stationManual']['positive'][0] = False
        cell.scan()
        self.assertFalse(hmi['stationManual']['positive'][1])

    def test_vijeo_reload_refreshes_one_buffer_and_preserves_later_edits(self):
        from plc_station_main import MainCell
        cell = MainCell()
        shared = cell.g['GVL_HMI']
        hmi, vijeo = shared['hmiV2'], shared['vijeo']
        plc = cell.g['GVL_Robot']
        plc['ScannerHealthy'] = plc['ImageFresh'] = True
        plc['Plant']['retentionVerified'] = True
        plc['Cfg']['hmiTimeout'] = 500
        ctx = cell.g['GVL_RobotRetain']['Context']
        ctx['stationParameters'][4].update(sensorStableMs=12, stopDelayMs=38, moveTimeoutMs=90, verified=True)
        ctx['stationParamRevision'][4] = 9
        hmi['link']['uiHmiHeartbeat'] = 1
        cell.scan()
        hmi['link'].update(xArmReq=True, uiHmiHeartbeat=2)
        cell.scan()
        hmi['link']['xArmReq'] = False
        self.assertTrue(hmi['link']['xArmed'])
        vijeo['stationEdit'][0]['sensorStableMs'] = 99
        hmi['cmd']['station4ParamReload'].update(
            udiSessionId=hmi['link']['udiSessionId'], udiRequestId=1, xReq=True)
        cell.scan()
        self.assertEqual(vijeo['storageEdit']['sensorStableMs'], 12)
        self.assertEqual(vijeo['stationEditRevision'][3], 9)
        self.assertEqual(vijeo['stationRevision'][3], 9)
        self.assertEqual(vijeo['stationEdit'][0]['sensorStableMs'], 99)
        vijeo['storageEdit'].update(sensorStableMs=23, verified=False)
        cell.scan()
        runtime_edit = cell.main.v['hmiRuntime']['stationEdit'][4]
        self.assertEqual(runtime_edit['sensorStableMs'], 23)
        self.assertTrue(runtime_edit['verified'])
        self.assertEqual(runtime_edit['stopDelayMs'], 38)
        self.assertEqual(runtime_edit['moveTimeoutMs'], 90)
        self.assertTrue(vijeo['storageEdit']['verified'])
        self.assertEqual(vijeo['storageEdit']['sensorStableMs'], 23)
        self.assertEqual(vijeo['storageActual']['sensorStableMs'], 12)
        self.assertTrue(hmi['rsp']['station4ParamReload']['xAck'])

    def test_vijeo_io_publishes_every_alias(self):
        from plc_station_main import MainCell
        cell = MainCell()
        shared = cell.g['GVL_HMI']
        io = cell.r.value('ST_StationHmiIo')
        vijeo = shared['vijeo']
        source = (cell.r.root / 'Modules/Vijeo/FB_VijeoPublish.st').read_text(encoding='utf-8')
        assignments = re.findall(
            r'GVL_HMI\.vijeo\.value\.(\w+) := Io\.value\.(\w+);', source)
        aliases = {name: alias for alias, name in assignments}
        self.assertEqual(len(assignments), 159)
        self.assertEqual(len(aliases), 159)
        self.assertEqual(set(aliases), set(io['value']))
        self.assertEqual(set(aliases.values()), set(vijeo['value']))
        self.assertEqual(len({alias.lower() for alias in aliases.values()}), 159)
        self.assertTrue(all(len(alias) <= 32 for alias in aliases.values()))
        guide = (cell.r.root / 'docs/hmi-instructions.md').read_text(encoding='utf-8')
        rows = re.findall(r'^\| [^|]+ \| (?:Wejście|Komenda PLC) \| `(\w+)` \|$', guide, re.M)
        self.assertTrue(rows)
        self.assertEqual(len(rows), len(set(rows)))
        controller = (cell.r.root / 'Modules/StationController/FB_StationController.st').read_text(encoding='utf-8')
        unavailable = set(re.findall(r'Outp\.hmi_hmiIo\.valid\.(\w+) := FALSE;', controller))
        self.assertTrue(set(rows) <= {alias for name, alias in aliases.items() if name not in unavailable})
        publisher = cell.main.v['vijeoPublish']
        io['dataValid'] = True
        io['barrierBlocked'] = True
        io['appliedCoils'][9]['home'] = True
        io['appliedCoils'][10]['work'] = True
        io['alarms']['entries'][1]['code'] = 1
        io['alarms']['entries'][64]['code'] = 64
        for bit in range(8):
            for n, source in enumerate(aliases):
                io['value'][source] = bool(n & (1 << bit))
                io['valid'][source] = not io['value'][source]
            publisher.run(Hmi=cell.main.v['hmiRuntime'], Io=io, ReloadedStation=0)
            for source, alias in aliases.items():
                self.assertEqual(vijeo['value'][alias], io['value'][source], alias)
                self.assertEqual(vijeo['valid'][alias], io['valid'][source], alias)
        self.assertEqual(vijeo['alarms']['entries'][0]['code'], 1)
        self.assertEqual(vijeo['alarms']['entries'][63]['code'], 64)
        self.assertEqual(shared['hmiIo'], {'dataValid': True, 'barrierValid': False, 'barrierBlocked': True})
        self.assertEqual(vijeo['unloadCoils'][0], {'home': True, 'work': False})
        self.assertEqual(vijeo['unloadCoils'][1], {'home': False, 'work': True})

    def test_vijeo_active_alarm_rows_are_recent_compact_and_independent_of_latches(self):
        from plc_station_main import MainCell
        cell = MainCell()
        manager = cell.r.instance('FB_AlarmManager')
        cfg = cell.r.value('ST_StationAlarmCfg')
        cfg['configured'][14] = cfg['critical'][14] = cfg['latched'][14] = True
        cfg['station'][14] = 2
        inp = cell.r.value('ST_StationAlarmIn')
        io = cell.r.value('ST_StationHmiIo')
        publisher = cell.main.v['vijeoPublish']
        alarms = cell.g['GVL_HMI']['vijeo']['alarms']
        empty = dict(valid=False, code=0, station=0, level='', text='')

        def publish(active, expected):
            inp['active'] = {code: code in active for code in range(1, 65)}
            manager.run(Cfg=cfg, Inp=inp)
            io['alarms'] = manager.v['Sts']
            publisher.run(Hmi=cell.main.v['hmiRuntime'], Io=io, ReloadedStation=0)
            rows = alarms['activeRows']
            self.assertEqual(alarms['activeCount'], len(active))
            self.assertEqual([row['code'] for row in rows.values() if row['valid']], expected)
            self.assertEqual([rows[i] for i in range(len(expected), 12)], [empty] * (12 - len(expected)))

        publish(set(), [])
        publish({2, 6}, [6, 2])
        self.assertEqual(alarms['activeRows'][0],
                         dict(valid=True, code=6, station=2, level='Warning', text='ST.2 V201'))
        publish({2, 6, 14}, [14, 6, 2])
        self.assertEqual(alarms['activeRows'][0],
                         dict(valid=True, code=14, station=2, level='Alarm', text='Komunikacja ATV320'))
        publish({2, 3, 6, 14}, [3, 14, 6, 2])
        inp.update(acknowledge=True, reset=True)
        publish({2, 3, 6, 14}, [3, 14, 6, 2])
        inp.update(acknowledge=False, reset=False)
        publish({2, 3, 6}, [3, 6, 2])
        self.assertTrue(alarms['entries'][13]['latched'])
        publish({2, 3, 6, 14}, [14, 3, 6, 2])
        overflow = {2, 3, 6, 14, *range(15, 27)}
        publish(overflow, list(range(26, 14, -1)))
        self.assertEqual(alarms['activeRows'][0]['level'], 'Klasa niezatwierdzona')
        publish(overflow - {26}, [*range(25, 14, -1), 14])
        publish(set(), [])
        self.assertEqual(alarms['count'], 1)
        publish(set(range(1, 65)), list(range(64, 52, -1)))
        publish(set(), [])

    def test_vijeo_elevator_and_batch_reload_publish_only_the_requested_buffers(self):
        from plc_station_main import MainCell
        cell = MainCell()
        plc = cell.g['GVL_Robot']
        plc['ScannerHealthy'] = plc['ImageFresh'] = True
        plc['Plant']['retentionVerified'] = True
        plc['Cfg']['hmiTimeout'] = 500
        ctx = cell.g['GVL_RobotRetain']['Context']
        ctx['stationParameters'][2].update(slowHz=12.0, fastHz=24.0)
        ctx.update(program_=2, batchCount=7)
        shared = cell.g['GVL_HMI']
        hmi, vijeo = shared['hmiV2'], shared['vijeo']
        hmi['link']['uiHmiHeartbeat'] = 1
        cell.scan()
        hmi['link'].update(xArmReq=True, uiHmiHeartbeat=2)
        cell.scan()
        hmi['link']['xArmReq'] = False
        session = hmi['link']['udiSessionId']
        self.assertTrue(hmi['link']['xArmed'])
        hmi['edit'].update(uiProgram=1, uiBatchCount=99)
        vijeo['storageEdit']['sensorStableMs'] = 55
        first = hmi['cmd']['station2ParamReload']
        first.update(udiSessionId=session, udiRequestId=1, xReq=True)
        cell.scan()
        self.assertEqual(vijeo['elevatorSpeedEdit'], {'slowHz': 12.0, 'fastHz': 24.0})
        self.assertEqual(hmi['edit']['uiBatchCount'], 99)
        self.assertEqual(vijeo['storageEdit']['sensorStableMs'], 55)
        cell.scan()
        first['xReq'] = False
        cell.scan()
        vijeo['elevatorSpeedEdit']['slowHz'] = 14.0
        batch = hmi['cmd']['station5ParamReload']
        batch.update(udiSessionId=session, udiRequestId=2, xReq=True)
        cell.scan()
        self.assertEqual(hmi['edit'], {'uiProgram': 2, 'uiBatchCount': 7})
        self.assertEqual(vijeo['elevatorSpeedEdit']['slowHz'], 14.0)
        self.assertEqual(cell.main.v['hmiRuntime']['stationEdit'][2]['slowHz'], 14.0)
        hmi['edit']['uiBatchCount'] = 77
        cell.scan()
        self.assertEqual(hmi['edit']['uiBatchCount'], 77)
        self.assertTrue(hmi['rsp']['station5ParamReload']['xAck'])

    def test_vijeo_gvl_contains_exactly_the_listed_symbols(self):
        from plc_station_main import MainCell
        cell = MainCell()
        exported = cell.g['GVL_HMI']
        doc = (cell.r.root / 'docs/hmi-vijeo-symbols.txt').read_text(encoding='utf-8')
        expected = {line.split()[-1] for line in doc.splitlines()
                    if line.startswith(('R ', 'RW ')) and line.split()[-1].startswith('GVL_HMI.')}

        def leaves(value, path):
            if not isinstance(value, dict):
                return {path}
            if all(isinstance(k, int) for k in value):
                self.assertEqual(sorted(value), list(range(len(value))), path)
                return {p for k, elem in value.items() for p in leaves(elem, f'{path}[{k}]')}
            self.assertTrue(all(len(k) <= 32 for k in value), path)
            return {p for k, elem in value.items() for p in leaves(elem, f'{path}.{k}')}

        self.assertEqual(leaves(exported, 'GVL_HMI'), expected)

    def test_main_unbound_has_no_motion_and_no_false_empty(self):
        from plc_station_main import MainCell
        cell=MainCell()
        for _ in range(3):cell.scan()
        output=cell.g['GVL_IO']['dout']
        for key in ['ctrl_turn_on_top_conveyor','ctrl_turn_on_bottom_conveyor',
                    'ctrl_turn_on_elevator_conveyor_in','ctrl_turn_on_elevator_conveyor_out']:
            self.assertFalse(output[key],key)
        self.assertFalse(cell.g['GVL_Station']['Material']['emptyConfirmed'])
        self.assertFalse(cell.g['GVL_Robot']['Drain']['done'])
        self.assertFalse(cell.g['GVL_Station']['Alarms']['policyReady'])
    def test_leaving_home_during_started_cycle_does_not_revoke_finish_permission(self):
        r=runtime();f=r.instance('FB_OrderManager');c=context(r);c['orderActive']=True
        a=dict(Cmd=r.value('ST_RobotCommands'),Context=c,Drain=r.value('ST_RobotDrain'),
            Session=True,ProgramOK=True,HomeValid=True,ProcessOK=True,OperationsSettled=True,AreasClear=True)
        f.run(**a,PhysicalStart=True)
        a.update(HomeValid=False,OperationsSettled=False)
        f.run(**a,PhysicalStart=False)
        self.assertTrue(f.v['Sts']['finishPermit'])
        f.run(**a,PhysicalStop=True);self.assertTrue(f.v['Sts']['finishPermit']);self.assertFalse(f.v['Sts']['newPermit'])
    def test_manual_handover_does_not_move_unselected_cylinders_and_releases_on_auto(self):
        r=runtime();f=r.instance('FB_StationCoils');cmd={i:r.value('ST_StationCoil') for i in range(1,11)}
        loss=copy.deepcopy(cmd);release=copy.deepcopy(cmd);release[2]['home']=True
        mask={i:False for i in range(1,11)};mask[1]=True
        args=dict(Cmd=cmd,LossPolicy=loss,PolicyVerified=True,NewPermit=True,Manual=True,
                  ManualActive=mask,ReleaseVerified=True,ReleasePolicy=release)
        cmd[1]['work']=True;f.run(**args)
        self.assertTrue(f.v['Applied'][1]['work']);self.assertFalse(f.v['Applied'][2]['home'])
        args.update(Manual=False,NewPermit=False);mask[1]=False;f.run(**args)
        self.assertFalse(f.v['Applied'][1]['work'])
    def test_station_hmi_freezes_payload_waits_for_semantic_result_and_rejects_duplicate(self):
        r=runtime();f=r.instance('FB_RobotHmi');c=context(r);h=r.value('ST_RobotHmiV2')
        args=dict(Hmi=h,Context=c,DataValid=True,GenerationValid=True,Timeout=500)
        h['link']['uiHmiHeartbeat']=1;f.run(**args)
        h['link']['xArmReq']=True;h['link']['uiHmiHeartbeat']=2;f.run(**args)
        h['link']['xArmReq']=False
        req=h['cmd']['station1ParamApply'];req.update(udiSessionId=h['link']['udiSessionId'],udiRequestId=1,xReq=True)
        h['stationEdit'][1]['sensorStableMs']=15;f.run(**args)
        self.assertEqual(f.v['StationKey'],12);self.assertEqual(f.v['StationSnapshot']['sensorStableMs'],15)
        h['stationEdit'][1]['sensorStableMs']=999;f.run(**args)
        self.assertEqual(f.v['StationSnapshot']['sensorStableMs'],15);self.assertFalse(h['rsp']['station1ParamApply']['xAck'])
        f.run(**args,Complete=True,CompleteReason=50)
        self.assertEqual(h['rsp']['station1ParamApply']['uiResult'],2)
        req['xReq']=False;f.run(**args,Complete=False)
        req['xReq']=True;f.run(**args)
        self.assertEqual(h['rsp']['station1ParamApply']['uiReason'],120);self.assertEqual(f.v['StationKey'],0)
    def test_coil_goal_cannot_change_while_its_belt_moves(self):
        r=runtime();f=r.instance('FB_StationCoils');cmd={i:r.value('ST_StationCoil') for i in range(1,11)}
        loss=copy.deepcopy(cmd);allowed={i:True for i in range(1,11)}
        a=dict(Cmd=cmd,LossPolicy=loss,PolicyVerified=True,NewPermit=True,GateChanges=True,ChangeAllowed=allowed)
        cmd[9]['work']=True;f.run(**a);allowed[9]=False;cmd[9].update(work=False,home=True);f.run(**a)
        self.assertTrue(f.v['Applied'][9]['work']);self.assertFalse(f.v['Applied'][9]['home'])
        allowed[9]=True;f.run(**a);self.assertTrue(f.v['Applied'][9]['home'])

if __name__=='__main__':unittest.main(verbosity=2)
