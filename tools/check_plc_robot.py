"""Offline behavior checks executing the PLC ST sources. No device access."""
from __future__ import annotations
import copy
import json
from pathlib import Path
import unittest
from plc_st_runtime import Runtime, Parser
from build_plc_robot import field, artifacts

ROOT=Path(__file__).resolve().parents[1]
POUS=[f'Modules/{n.removeprefix("FB_")}/{n}.st' for n in (
    'FB_RobotCodec','FB_RobotLink','FB_RobotEvents','FB_RobotCycleLedger',
    'FB_RobotGripper','FB_RobotAreas','FB_RobotHmi','FB_RobotManual','FB_RobotController')]
POUS += ['Modules/ImmInterface/FB_ImmInterface.st','Modules/OrderManager/FB_OrderManager.st',
         'Modules/RobotRecovery/FB_RobotRecovery.st','Modules/TraySequencer/FB_TraySequencer.st',
         'Modules/BoxSequencer/FB_BoxSequencer.st','Modules/Storage/FB_Storage.st']
POUS += ['Modules/StationCoils/FB_StationCoils.st','Modules/StationOutputPolicy/FB_StationOutputPolicy.st']
POUS += [f'Modules/{n}/FB_{n}.st' for n in ('StationIo','StationMaterial','StationTransport','StationDrain','AlarmManager','StationManual','StationParameters','StationHmi')]
POUS += [f'Modules/{n}/FB_{n}.st' for n in ('Cyl2Pos','StopperPair','Conveyor','TopFlowManager','Elevator','SafetyDoor','StationController','ElevatorDriveAdapter','StationRecovery')]
POUS += ['Modules/BottomAccumulator/FB_BottomAccumulator_567.st']

def runtime():
    r=Runtime(ROOT);r.load(*POUS);return r

def context(r):
    c=r.value('ST_RobotContext')
    c.update(schema=4,valid=True,program=2,batchCount=7,stackId=10,withRobot=True,occupancyKnown=True)
    return c

def plant(r):
    p=r.value('ST_RobotPlant')
    for k in ['safetyValid','safetyOK','processOK','mappingVerified','retentionVerified','contextRestored',
              'physicalIdle','stationIdleConfirmed','robotContextConfirmed','loadsConfirmed','cyclesConfirmed','stationEmptyConfirmed','transfersConfirmedIdle']:
        p[k]=True
    for a in p['areas'].values():a.update(valid=True,ready=True,recoveryClearConfirmed=True)
    p['imm'].update(configured=True,valid=True,startSignalValid=True,cycleKnown=True,
                    settled=True,processInterlocks=True,sharedSupplyVerified=True,withRobot=True,
                    mouldClosed=True,ejectorBack=True)
    for c in p['cylinders'].values():
        c.update(configured=True,valid=True,atHome=True,homeAllowed=True,workAllowed=True,lossPolicyVerified=True)
    for v in p['vacuum'].values():
        v.update(configured=True,valid=True,onAllowed=True,offAllowed=True,blowAllowed=True,
                 releaseConfirmed=True,blowConfigured=True,lossPolicyVerified=True,holdOnLoss=True)
    return p

def config(r):
    c=r.value('ST_RobotCfg')
    c['link'].update(configured=True,heartbeatPeriod=20,peerTimeout=200,syncTimeout=1000)
    c['gripper'].update(stable=10,motionTimeout=200,vacuumTimeout=200,blowTime=20,releaseTimeout=100)
    c['hmiTimeout']=500
    return c

class Checks(unittest.TestCase):
    def setUp(self):self.r=runtime()

    def test_codec_every_field_boundaries_reserves_and_generator(self):
        rows=json.loads((ROOT/'ROBOT/COMM/mapping.json').read_text())['signals']
        c=self.r.instance('FB_RobotCodec')
        for value in [0,1,32768,65535]:
            raw={i:0 for i in range(80)};tx=self.r.value('ST_RobotTxV2')
            expected={}
            for row in rows:
                v=bool(value) if row['type']=='BOOL' else value
                expected[row['id']]=v
                if row['id'].startswith('p2r.'):tx[field(row['id'])]=v
                elif row['type']=='BOOL' and v:raw[row['word']*2+row['bit']//8] |= 1 << (row['bit']%8)
                elif row['type']=='UINT':
                    raw[2*row['word']]=v & 255;raw[2*row['word']+1]=v >> 8
            c.run(RawIn=raw,Tx=tx)
            for row in rows:
                if row['id'].startswith('r2p.'):
                    self.assertEqual(c.v['Rx'][field(row['id'])],expected[row['id']])
                else:
                    w=c.v['RawOut'][2*row['word']] | c.v['RawOut'][2*row['word']+1]<<8
                    self.assertEqual(bool(w & (1<<row['bit'])) if row['type']=='BOOL' else w,expected[row['id']])
            self.assertTrue(all(c.v['RawOut'][i]==0 for i in range(72,80)))
        for name,source in artifacts().items():self.assertEqual((ROOT/name).read_text(encoding='utf-8'),source)

    def linked(self):
        f=self.r.instance('FB_RobotLink')
        rx=self.r.value('ST_RobotRxV2');rx.update(link_version=2,link_heartbeat=1)
        args=dict(Cfg=config(self.r)['link'],ScannerHealthy=True,ImageFresh=True,Rx=rx,Neutral=True)
        f.run(**args);self.assertTrue(f.v['SyncRequest'])
        rx.update(link_heartbeat=2,link_syncRequest=True,link_syncAck=True);f.run(**args)
        rx.update(link_heartbeat=3,link_syncRequest=False,link_syncAck=False);f.run(**args)
        self.assertEqual(f.v['State'],30);self.assertFalse(f.v['Session'])
        rx.update(link_heartbeat=4,link_ready=True);f.run(**args,Recover=True)
        self.assertTrue(f.v['Session']);return f,args,rx

    def test_link_requires_bilateral_sync_and_explicit_recovery(self):
        f,args,rx=self.linked()
        rx['link_syncRequest']=True;f.run(**args,Recover=False)
        self.assertFalse(f.v['Session'])
        f.run(**args);self.assertFalse(f.v['Session'])

    def test_link_heartbeat_wrap_timeout_version_and_invalid_image(self):
        f,args,rx=self.linked()
        rx['link_heartbeat']=65535;f.run(**args,Recover=False)
        rx['link_heartbeat']=0;f.run(**args);self.assertTrue(f.v['Session'])
        for _ in range(25):f.run(**args)
        self.assertFalse(f.v['Session'])
        rx['link_version']=1;rx['link_heartbeat']=1;f.run(**args)
        self.assertFalse(f.v['HeaderValid'])
        rx['link_version']=2;args['ImageFresh']=False;f.run(**args)
        self.assertFalse(f.v['HeaderValid'])

    def test_event_ack_follows_commit_and_full_reset(self):
        f=self.r.instance('FB_RobotEvents');e={i:self.r.value('ST_RobotEvent') for i in range(1,11)}
        commit={i:False for i in range(1,11)}
        args=dict(Session=True,Rx=e,Commit=commit)
        f.run(**args)
        e[5].update(req=True,count=3,cycleId=0,stackId=10);f.run(**args)
        self.assertTrue(f.v['Pending'][5]);self.assertFalse(f.v['Ack'][5])
        commit[5]=True;f.run(**args)
        self.assertTrue(f.v['Ack'][5]);self.assertFalse(f.v['Pending'][5])
        for _ in range(5):f.run(**args)
        self.assertTrue(f.v['Ack'][5])
        e[5]['req']=False;f.run(**args)
        self.assertFalse(f.v['Ack'][5]);self.assertTrue(f.v['Idle'])

    def test_event_mutated_payload_and_early_req_drop_require_recovery(self):
        for mutate in [True,False]:
            f=self.r.instance('FB_RobotEvents')
            e={i:self.r.value('ST_RobotEvent') for i in range(1,11)}
            args=dict(Session=True,Rx=e,Commit={i:False for i in e})
            f.run(**args);e[5].update(req=True,count=3);f.run(**args)
            if mutate:e[5]['count']=4
            else:e[5]['req']=False
            f.run(**args);self.assertTrue(f.v['Diag']['fault'])

    def ledger(self):
        f=self.r.instance('FB_RobotCycleLedger');c=context(self.r)
        events={i:self.r.value('ST_RobotEvent') for i in range(1,11)}
        pending={i:False for i in events}
        args=dict(Session=True,Context=c,StartValid=True,CyclesKnown=True,Quantity=7,StackId=10,Program=2,
                  Pending=pending,Events=events,TaskDone={i:False for i in events})
        f.run(**args,StartConfirmed=False)
        f.run(**args,StartConfirmed=True)
        self.assertTrue(c['assigned']);self.assertEqual(f.v['BatchCount'],7)
        return f,c,args,pending,events

    def pickup(self,f,c,args,pending,events):
        pending[9]=True;events[9].update(req=True,stackId=10,cycleId=f.v['CycleId'])
        f.run(**args,StartConfirmed=False);self.assertTrue(f.v['Commit'][9])
        pending[9]=False;events[9]['req']=False;f.run(**args)
        self.assertFalse(c['assigned'] and f.v['CycleId'] == events[9]['cycleId'])

    def test_ledger_n_plus_one_frozen_assignment_and_partial_placements(self):
        f,c,args,p,e=self.ledger()
        first=f.v['CycleId']
        f.run(**args,StartConfirmed=False);f.run(**args,StartConfirmed=True)
        self.assertEqual(f.v['Unsettled'],2);self.assertFalse(f.v['FreeSlot']);self.assertEqual(f.v['CycleId'],first)
        self.pickup(f,c,args,p,e)
        second=f.v['CycleId'];self.assertNotEqual(first,second)
        for amount in [2,5]:
            p[5]=True;e[5].update(req=True,stackId=10,cycleId=first,count=amount)
            f.run(**args);self.assertFalse(f.v['Fault']);self.assertTrue(f.v['Commit'][5])
            p[5]=False;e[5]['req']=False;f.run(**args)
        self.assertEqual(c['goodCount'],7);self.assertEqual(f.v['Unsettled'],1)

    def test_ledger_parallel_dispositions_validate_sum_before_write(self):
        f,c,args,p,e=self.ledger();cycle=f.v['CycleId'];self.pickup(f,c,args,p,e)
        c.update(sampleAccepted=True,sampleAwaitCycle=False,sampleCycleId=cycle)
        for i,amount in [(5,5),(6,3)]:
            p[i]=True;e[i].update(req=True,stackId=10,cycleId=cycle,count=amount)
        f.run(**args)
        self.assertTrue(f.v['Fault']);self.assertEqual(c['goodCount'],0);self.assertEqual(c['sampleCount'],0)
        self.assertFalse(any(f.v['Commit'].values()))

    def test_ledger_no_start_on_permission_and_no_overwrite_when_full(self):
        f,c,args,p,e=self.ledger()
        f.run(**args,StartConfirmed=False);self.assertEqual(f.v['Unsettled'],1)
        f.run(**args,StartConfirmed=True);f.run(**args,StartConfirmed=False)
        snapshot=copy.deepcopy(c['cycles'])
        f.run(**args,StartConfirmed=True)
        self.assertTrue(f.v['Fault']);self.assertEqual(snapshot,c['cycles'])

    def test_ledger_quantity_snapshot_and_restart_do_not_clear_load(self):
        f,c,args,p,e=self.ledger()
        args['Quantity']=99;f.run(**args,StartConfirmed=False)
        self.assertEqual(f.v['BatchCount'],7)
        snapshot=copy.deepcopy(c)
        g=self.r.instance('FB_RobotCycleLedger');g.run(**{**args,'Session':False},StartConfirmed=False)
        self.assertEqual(c['cycles'],snapshot['cycles']);self.assertEqual(g.v['Unsettled'],1)

    def test_areas_reserve_only_grant_or_presence_keep_on_loss(self):
        f=self.r.instance('FB_RobotAreas');c=context(self.r)
        inp=plant(self.r)['areas'];req={i:False for i in range(1,4)};clear={i:True for i in req}
        req[2]=True;inp[2]['ready']=False
        args=dict(Session=True,Permit=True,AccessReq=req,Clear=clear,Inp=inp,Context=c)
        f.run(**args);self.assertFalse(c['areaReserved'][2])
        inp[2]['ready']=True;f.run(**args);self.assertTrue(f.v['Outp'][2]['granted'])
        f.run(**{**args,'Session':False});self.assertTrue(c['areaReserved'][2]);self.assertFalse(f.v['Outp'][2]['granted'])
        req[2]=False;clear[2]=False;f.run(**args);self.assertTrue(c['areaReserved'][2])
        clear[2]=True;f.run(**args);self.assertFalse(c['areaReserved'][2])

    def gripper(self):
        f=self.r.instance('FB_RobotGripper');p=plant(self.r)
        args=dict(Cfg=config(self.r)['gripper'],Session=True,Permit=True,CylIn=p['cylinders'],VacIn=p['vacuum'])
        for key in ['CylHome','CylWork','VacValid','VacHold','BlowReq']:args[key]={i:False for i in range(1,6)}
        f.run(**args);return f,p,args

    def test_gripper_00_is_no_new_target_11_conflict(self):
        f,p,a=self.gripper();a['CylWork'][1]=True;f.run(**a)
        self.assertTrue(f.v['Cyl'][1]['work']);self.assertTrue(f.v['Cyl'][1]['acceptedWork'])
        a['CylWork'][1]=False;f.run(**a)
        self.assertTrue(f.v['Cyl'][1]['work']);self.assertFalse(f.v['Cyl'][1]['acceptedHome'])
        a['CylHome'][1]=True;a['CylWork'][1]=True;f.run(**a)
        self.assertEqual(f.v['Cyl'][1]['reason'],40)

    def test_gripper_hold_survives_missing_command_and_loss(self):
        f,p,a=self.gripper();a['VacValid'][1]=True;a['VacHold'][1]=True
        p['vacuum'][1]['ok']=True;f.run(**a);self.assertTrue(f.v['Vac'][1]['hold'])
        a['VacValid'][1]=False;f.run(**a);self.assertTrue(f.v['Vac'][1]['hold'])
        f.run(**{**a,'Session':False});self.assertTrue(f.v['Vac'][1]['hold']);self.assertFalse(f.v['Vac'][1]['blow'])

    def test_gripper_blow_terminal_once_and_conflict_not_release(self):
        f,p,a=self.gripper()
        a['VacValid'][1]=True;a['VacHold'][1]=True;a['BlowReq'][1]=True
        f.run(**a);self.assertTrue(f.v['Vac'][1]['hold']);self.assertEqual(f.v['Vac'][1]['blowResult'],2)
        a['BlowReq'][1]=False;f.run(**a)
        a['VacHold'][1]=False;f.run(**a);a['BlowReq'][1]=True;f.run(**a)
        self.assertTrue(f.v['Vac'][1]['blow']);self.assertFalse(f.v['Vac'][1]['blowAck'])
        for _ in range(4):f.run(**a)
        self.assertTrue(f.v['Vac'][1]['blowAck']);self.assertEqual(f.v['Vac'][1]['blowResult'],1)
        for _ in range(10):f.run(**a);self.assertFalse(f.v['Vac'][1]['blow'])
        a['BlowReq'][1]=False;f.run(**a);self.assertFalse(f.v['Vac'][1]['blowAck'])

    def test_gripper_release_missing_sensor_no_success(self):
        f,p,a=self.gripper()
        p['vacuum'][1]['releaseConfirmed']=False
        a['VacValid'][1]=True;a['BlowReq'][1]=True
        for _ in range(12):f.run(**a)
        self.assertEqual(f.v['Vac'][1]['blowResult'],3);self.assertTrue(f.v['Fault'])

    def test_order_physical_start_stop_finish_manual_and_drain_boundary(self):
        f=self.r.instance('FB_OrderManager');c=context(self.r);d=self.r.value('ST_RobotDrain');cmd=self.r.value('ST_RobotCommands')
        a=dict(Context=c,Drain=d,Cmd=cmd,Session=True,ProgramOK=True,HomeValid=True,ProcessOK=True,
               OperationsSettled=True,AreasClear=True,StationIdle=True)
        cmd.update(openOrder=True,program=2);f.run(**a)
        self.assertTrue(c['orderActive']);self.assertFalse(f.v['Sts']['running'])
        cmd['openOrder']=False;f.run(**a,PhysicalStart=True);self.assertEqual(f.v['Sts']['startToken'],1)
        f.run(**{**a,'OperationsSettled':False},PhysicalStart=False,PhysicalStop=True)
        self.assertFalse(f.v['Sts']['newPermit']);self.assertTrue(f.v['Sts']['finishPermit'])
        cmd['manual']=True;f.run(**{**a,'OperationsSettled':False},PhysicalStop=False)
        self.assertFalse(f.v['Sts']['manual']);self.assertEqual(f.v['Sts']['reason'],30)
        cmd['manual']=False;f.run(**a);self.assertTrue(f.v['Sts']['stopped'])
        cmd['endOrder']=True;f.run(**a)
        self.assertTrue(d['request']);self.assertTrue(c['orderActive'])
        d.update(done=True,accepted=True,emptyConfirmed=True);cmd['endOrder']=False;f.run(**a)
        self.assertTrue(c['orderActive']) # no connected executor
        d['connected']=True;f.run(**a);self.assertTrue(c['orderActive']) # stale DONE is not a new completion
        d.update(done=False,accepted=False);f.run(**a)
        d.update(done=True,accepted=True);f.run(**a);self.assertFalse(c['orderActive'])

    def test_order_rejected_start_not_queued_and_reset_does_not_start(self):
        f=self.r.instance('FB_OrderManager');c=context(self.r);c['orderActive']=True
        a=dict(Context=c,Drain=self.r.value('ST_RobotDrain'),Session=True,ProgramOK=True,HomeValid=True,
               ProcessOK=True,OperationsSettled=True,AreasClear=True,RecoveryRequired=False)
        f.run(**{**a,'RecoveryRequired':True},PhysicalStart=True)
        f.run(**a,PhysicalStart=True);self.assertFalse(f.v['Sts']['running'])
        f.run(**a,PhysicalStart=False);f.run(**a,PhysicalStart=True)
        self.assertTrue(f.v['Sts']['running']);self.assertEqual(f.v['Sts']['startToken'],1)

    def test_imm_standalone_and_stop_shared_supply(self):
        f=self.r.instance('FB_ImmInterface');p=plant(self.r)['imm']
        f.run(Inp=p,HomeValid=True,WithRobot=False)
        self.assertTrue(f.v['Outp']['mouldClose'])
        p.update(completionFullOpen=True,completionEjectorBack=True)
        f.run(Inp=p,Session=True,WithRobot=True,FinishPermit=True,Unsettled=1,ReqClose=True)
        self.assertFalse(f.v['Outp']['newCyclePermit']);self.assertFalse(f.v['Outp']['mouldClose'])
        self.assertTrue(f.v['Outp']['ejectorBack'])
        p['completionFullOpen']=False
        f.run(Inp=p,Session=True,WithRobot=True,FinishPermit=True,Unsettled=1)
        self.assertFalse(f.v['Outp']['ejectorBack'])

    def test_recovery_requires_evidence_and_preserves_partial_batch(self):
        f=self.r.instance('FB_RobotRecovery');c=context(self.r);c['goodCount']=42
        proposal=copy.deepcopy(c);p=plant(self.r);rx=self.r.value('ST_RobotRxV2')
        rx.update(production_home=True,production_loadKnown=True)
        cmd=self.r.value('ST_RobotCommands');cmd['recover']=True
        a=dict(Context=c,Proposal=proposal,Plant=p,Rx=rx,Cmd=cmd,AtRecovery=True,Neutral=True)
        p['robotContextConfirmed']=False;f.run(**a);self.assertTrue(f.v['Required'])
        p['robotContextConfirmed']=True;f.run(**a)
        self.assertFalse(f.v['Required']);self.assertTrue(f.v['Approved']);self.assertEqual(c['goodCount'],42)
        f.run(**a,Invalidate=True);self.assertTrue(f.v['Required']) # invalidation wins over stale approval

    def test_box_keeps_elevator_fixed_and_reservation_blocks_discharge(self):
        f=self.r.instance('FB_BoxSequencer');c=context(self.r);c['boxStep']=70
        cmd=self.r.value('ST_BoxSeqCmd');cmd.update(Enable=True,NewOperations=True,SafetyOK=True)
        inp=self.r.value('ST_BoxSeqIn');inp.update(Session=True,RobotClear=True,PositionerWork=True)
        f.run(Cmd=cmd,Inp=inp,Context=c)
        self.assertTrue(f.v['Outp']['ElevatorReady']);self.assertFalse(f.v['Outp']['Elev_AutoGo'])
        c['boxStep']=90;inp.update(RobotReserved=True,Elev_CommandReady=True)
        f.run(Cmd=cmd,Inp=inp,Context=c);self.assertFalse(f.v['Outp']['Elev_AutoGo'])

    def test_warning_no_global_fault_or_timeout_escalation(self):
        f=self.r.instance('FB_TraySequencer');c=context(self.r);c['trayStep']=90
        cmd=self.r.value('ST_TraySeqCmd');cmd.update(Enable=True,FinishOperations=True,SafetyOK=True)
        inp=self.r.value('ST_TraySeqIn');inp.update(Session=True,RobotClear=True,Warning=True,ind_container_in_pos_4=True)
        for _ in range(100):f.run(Cmd=cmd,Inp=inp,Context=c,dt=10000)
        self.assertFalse(f.v['Diag']['Fault']);self.assertFalse(f.v['Outp']['Elev_AutoGo'])

    def test_controller_unbound_fails_closed_and_sources_execute(self):
        f=self.r.instance('FB_RobotController')
        f.run(Context=context(self.r),Proposal=context(self.r),Drain=self.r.value('ST_RobotDrain'),Hmi=self.r.value('ST_RobotHmiV2'))
        self.assertFalse(f.v['Sts']['session']);self.assertFalse(f.v['Tx']['production_newOperationPermit'])
        self.assertFalse(f.v['Tx']['imm_applied_mouldClose'])

    def test_runtime_rejects_unsupported_syntax(self):
        with self.assertRaises(ValueError): Parser("WHILE TRUE DO END_WHILE;").block({'<EOF>'})
        with self.assertRaises(ValueError): Parser("x := @bad;").block({'<EOF>'})


class AdditionalChecks(unittest.TestCase):
    setUp = Checks.setUp
    ledger = Checks.ledger
    pickup = Checks.pickup
    def test_hmi_session_ids_duplicates_conflicts_and_snapshot(self):
        f=self.r.instance('FB_RobotHmi');c=context(self.r);h=self.r.value('ST_RobotHmiV2')
        a=dict(Context=c,Hmi=h,DataValid=True,GenerationValid=True,Timeout=100)
        h['link']['uiHmiHeartbeat']=1;f.run(**a)
        h['link']['xArmReq']=True;f.run(**a);self.assertTrue(h['link']['xArmed'])
        session=h['link']['udiSessionId']
        h['cmd']['orderOpen'].update(xReq=True,udiSessionId=session,udiRequestId=1)
        f.run(**a);self.assertTrue(f.v['Cmd']['openOrder'])
        f.run(**a,Complete=True,CompleteReason=30)
        self.assertEqual(h['rsp']['orderOpen']['uiResult'],2)
        snapshot=copy.deepcopy(h['rsp']['orderOpen'])
        f.run(**a,Complete=False,CompleteReason=0)
        self.assertEqual(h['rsp']['orderOpen'],snapshot)
        h['cmd']['orderOpen']['xReq']=False;f.run(**a)
        h['cmd']['orderOpen']['xReq']=True;f.run(**a)
        self.assertFalse(f.v['Cmd']['openOrder']);self.assertEqual(h['rsp']['orderOpen']['uiReason'],120)

    def test_manual_per_device_watchdogs_and_no_replay_after_page_change(self):
        f=self.r.instance('FB_RobotManual');c=self.r.value('ST_RobotManual')
        a=dict(Cmd=c,SessionId=3,Armed=True,ActivePanel=115,Permit=True,Timeout=30)
        c['udiSessionId']=3;f.run(**a)
        c['cylWork'][1]=True;c['holdCounter'][1]=1;f.run(**a)
        self.assertTrue(f.v['CylWork'][1])
        for _ in range(4):
            c['holdCounter'][2]+=1;f.run(**a)
        self.assertFalse(f.v['CylWork'][1])
        c['holdCounter'][1]+=1;f.run(**a);self.assertFalse(f.v['CylWork'][1])
        c['cylWork'][1]=False;f.run(**a)
        c['cylWork'][1]=True;c['holdCounter'][1]+=1;f.run(**a);self.assertTrue(f.v['CylWork'][1])
        f.run(**{**a,'ActivePanel':105})
        c['holdCounter'][1]+=1;f.run(**a);self.assertFalse(f.v['CylWork'][1])

    def test_recovery_cannot_roll_back_hmi_generation(self):
        f=self.r.instance('FB_RobotRecovery');c=context(self.r);c['hmiGeneration']=45
        proposal=copy.deepcopy(c);proposal['hmiGeneration']=1
        rx=self.r.value('ST_RobotRxV2');rx.update(production_home=True,production_loadKnown=True)
        cmd=self.r.value('ST_RobotCommands');cmd['recover']=True
        f.run(Context=c,Proposal=proposal,Plant=plant(self.r),Rx=rx,Cmd=cmd,AtRecovery=True,Neutral=True)
        self.assertTrue(f.v['Approved']);self.assertEqual(c['hmiGeneration'],45)

    def test_partial_recovery_needs_fresh_start_before_finish_permit(self):
        f=self.r.instance('FB_OrderManager');c=context(self.r);c['orderActive']=True
        a=dict(Context=c,Drain=self.r.value('ST_RobotDrain'),Session=True,ProgramOK=True,HomeValid=True,
            ProcessOK=True,OperationsSettled=False,AreasClear=True,RecoveryResumeAllowed=True)
        f.run(**a,RecoveryRequired=True,PhysicalStart=False)
        f.run(**a,RecoveryRequired=False)
        self.assertFalse(f.v['Sts']['finishPermit']);self.assertTrue(f.v['Sts']['canStart'])
        f.run(**a,PhysicalStart=True)
        self.assertTrue(f.v['Sts']['finishPermit'])

    def test_counter_overflow_fails_without_accounting(self):
        f,c,a,p,e=self.ledger();cycle=f.v['CycleId'];self.pickup(f,c,a,p,e)
        c['goodCount']=0xFFFFFFFF
        p[5]=True;e[5].update(req=True,count=1,cycleId=cycle,stackId=10)
        f.run(**a)
        self.assertTrue(f.v['Fault']);self.assertEqual(c['goodCount'],0xFFFFFFFF)

    def test_storage_requires_both_work_and_no_robot_reservation_for_operator(self):
        f=self.r.instance('FB_Storage');inp=self.r.value('ST_StorageIn')
        p=plant(self.r);inp.update(Left=p['cylinders'][1],Right=p['cylinders'][2],
                                 OperatorSideOpeningPermission=True,RobotSideOpeningPermission=True)
        cfg=self.r.value('ST_StorageCfg');cmd=self.r.value('ST_StorageCmd');cmd['Enable']=True
        for side in ['Left','Right']:inp[side].update(atHome=False,atWork=True)
        for _ in range(10):f.run(Inp=inp,Cfg=cfg,Cmd=cmd)
        self.assertTrue(f.v['Sts']['RobotSideClosed'])
        cmd['RobotReserved']=True;inp['BtnOpenClose']=True;f.run(Inp=inp,Cfg=cfg,Cmd=cmd)
        self.assertFalse(f.v['Outp']['Q_UnlockOperatorSide'])
        inp['BtnOpenClose']=False;cmd['RobotReserved']=False;f.run(Inp=inp,Cfg=cfg,Cmd=cmd)
        inp['Right']['atWork']=False;inp['BtnOpenClose']=True;f.run(Inp=inp,Cfg=cfg,Cmd=cmd)
        self.assertFalse(f.v['Outp']['Q_UnlockOperatorSide'])

    def test_manual_imm_old_commands_need_neutral_after_auto(self):
        f=self.r.instance('FB_ImmInterface');p=plant(self.r)['imm'];p['manualMouldClose']=True
        a=dict(Inp=p,HomeValid=True,WithRobot=False,Manual=True)
        f.run(**a);self.assertFalse(f.v['Outp']['mouldClose'])
        p['manualMouldClose']=False;f.run(**a)
        p['manualMouldClose']=True;f.run(**a);self.assertTrue(f.v['Outp']['mouldClose'])
        f.run(**{**a,'Manual':False});f.run(**a);self.assertFalse(f.v['Outp']['mouldClose'])

    def test_area_ready_drop_does_not_revoke_grant_before_exit(self):
        f=self.r.instance('FB_RobotAreas');c=context(self.r);inp=plant(self.r)['areas']
        req={1:False,2:True,3:False};clear={1:True,2:False,3:True}
        a=dict(Session=True,Permit=True,AccessReq=req,Clear=clear,Inp=inp,Context=c)
        inp[2]['ready']=False;f.run(**a);self.assertFalse(f.v['Outp'][2]['granted'])
        inp[2]['ready']=True;f.run(**a);self.assertTrue(f.v['Outp'][2]['granted'])
        inp[2]['ready']=False;f.run(**a);self.assertTrue(f.v['Outp'][2]['granted'])


    def test_manual_blow_is_finite_transaction_after_button_release(self):
        f=self.r.instance('FB_RobotManual');cmd=self.r.value('ST_RobotManual');cmd['udiSessionId']=2
        ack={i:False for i in range(1,6)}
        a=dict(Cmd=cmd,SessionId=2,Armed=True,ActivePanel=115,Permit=True,Timeout=30,BlowAck=ack)
        f.run(**a);cmd['vacValid'][1]=True;cmd['blowReq'][1]=True;cmd['holdCounter'][6]=1
        f.run(**a);self.assertTrue(f.v['BlowReq'][1])
        cmd['vacValid'][1]=False;cmd['blowReq'][1]=False
        for _ in range(4):f.run(**a)
        self.assertTrue(f.v['BlowReq'][1])
        ack[1]=True;f.run(**a);self.assertFalse(f.v['BlowReq'][1])

    def test_late_channel_fault_cancels_earlier_new_cylinder_goal(self):
        f,p,a=Checks.gripper(self)
        a['CylWork'][1]=True
        p['cylinders'][5].update(atHome=True,atWork=True)
        f.run(**a)
        self.assertTrue(f.v['Fault']);self.assertFalse(f.v['Cyl'][1]['acceptedWork'])
        self.assertFalse(f.v['Cyl'][1]['work'])

    def test_station_coils_do_not_move_before_start_and_hold_at_normal_stop(self):
        f=self.r.instance('FB_StationCoils')
        cmd={i:self.r.value('ST_StationCoil') for i in range(1,11)}
        loss=copy.deepcopy(cmd);cmd[1]['work']=True;loss[1]['home']=True
        a=dict(Cmd=cmd,LossPolicy=loss,PolicyVerified=True)
        f.run(**a,NewPermit=False);self.assertFalse(f.v['Applied'][1]['work'])
        f.run(**a,NewPermit=True);self.assertTrue(f.v['Applied'][1]['work'])
        cmd[1].update(work=False,home=True)
        f.run(**a,NewPermit=False)
        self.assertTrue(f.v['Applied'][1]['work']);self.assertFalse(f.v['Applied'][1]['home'])
        f.run(**a,Critical=True);self.assertTrue(f.v['Applied'][1]['home'])

    def test_station_coils_unverified_or_conflicting_policy_cannot_start(self):
        f=self.r.instance('FB_StationCoils')
        cmd={i:self.r.value('ST_StationCoil') for i in range(1,11)}
        loss=copy.deepcopy(cmd);cmd[7]['work']=True
        f.run(Cmd=cmd,LossPolicy=loss,NewPermit=True,PolicyVerified=False)
        self.assertTrue(f.v['Fault']);self.assertFalse(f.v['Applied'][7]['work'])
        loss[1].update(home=True,work=True)
        f.run(Cmd=cmd,LossPolicy=loss,NewPermit=True,PolicyVerified=True)
        self.assertTrue(f.v['Fault']);self.assertFalse(f.v['Applied'][7]['work'])

    def test_static_main_member_and_call_audit(self):
        from check_plc_structure import validate
        self.assertEqual(validate(),[])

    def test_missing_p4_after_placement_is_not_silently_completed(self):
        f=self.r.instance('FB_TraySequencer');c=context(self.r);c['trayStep']=82
        cmd=self.r.value('ST_TraySeqCmd');cmd.update(Enable=True,FinishOperations=True,SafetyOK=True)
        inp=self.r.value('ST_TraySeqIn');inp.update(Session=True,RobotClear=True,TaskPlaced=True)
        cfg=self.r.value('ST_TraySeqCfg');cfg['tP4ConfirmTimeout']=30
        for _ in range(4):f.run(Cmd=cmd,Inp=inp,Cfg=cfg,Context=c)
        self.assertTrue(f.v['Diag']['Fault']);self.assertFalse(f.v['Outp']['ConsumePlaced'])

class CoupledChecks(unittest.TestCase):
    def test_two_full_cycles_both_programs(self):
        from plc_robot_cosim import CoupledCell
        for mode,batches in [(2,8),(1,12)]:
            with self.subTest(mode=mode):
                c=CoupledCell(mode);c.start()
                for n in range(batches):
                    c.begin();c.until(lambda:c.c['goodCount']==7*(n+1))
                    c.until(lambda:c.plc.v['Ledger'].v['Unsettled']==0)
                c.until(lambda:c.c['stackCount']==2)
                self.assertEqual(c.c['goodCount'],batches*7)
                self.assertEqual(c.events.count('immPickupCompleted'),batches)
                self.assertEqual(c.events.count('stackFinished'),2)
                self.assertFalse(c.plc.v['Sts']['recoveryRequired'])

    def test_stop_finishes_started_n_plus_one(self):
        from plc_robot_cosim import CoupledCell
        for mode in [1,2]:
            c=CoupledCell(mode);c.start();c.begin()
            c.until(lambda:c.c['cycles'][1]['picked'])
            c.begin();c.physicalStop=True;c.scan();c.physicalStop=False
            self.assertFalse(c.plc.v['Tx']['imm_newCyclePermit'])
            c.until(lambda:c.c['goodCount']==14)
            c.until(lambda:c.plc.v['Sts']['order']['settled'])
            self.assertEqual(c.events.count('immPickupCompleted'),2)
            self.assertFalse(c.plc.v['Sts']['order']['running'])
            self.assertEqual(c.c['stackCount'],0)

    def test_samples_and_rejects_do_not_fill_container(self):
        from plc_robot_cosim import CoupledCell
        for mode in [1,2]:
            c=CoupledCell(mode);c.start();c.command('samples');c.begin()
            c.until(lambda:c.c['sampleCount']==7)
            c.until(lambda:c.plc.v['Ledger'].v['Unsettled']==0)
            c.begin(reject=True);c.until(lambda:c.c['rejectCount']==7)
            self.assertEqual(c.c['goodCount'],0)
            self.assertEqual(c.events.count('immPickupCompleted'),2)
            self.assertFalse(c.plc.v['Sts']['recoveryRequired'])

    def test_lost_peer_does_not_replay_or_resume_context(self):
        from plc_robot_cosim import CoupledCell
        c=CoupledCell();c.start();c.begin()
        c.until(lambda:c.c['cycles'][1]['picked'])
        snapshot=copy.deepcopy(c.c['cycles'])
        cfg=c.cfg['link'];cfg['configured']=False
        for _ in range(4):c.scan()
        self.assertTrue(c.plc.v['Sts']['recoveryRequired'])
        self.assertEqual(c.c['cycles'],snapshot)
        cfg['configured']=True
        for _ in range(10):c.scan()
        self.assertFalse(c.plc.v['Sts']['order']['newPermit'])
        self.assertFalse(c.plc.v['Sts']['order']['finishPermit'])

if __name__=='__main__':unittest.main(verbosity=2)

