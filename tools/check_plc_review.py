"""Review regressions: actual ST/LS; no device access or hardware approval."""
import copy
import unittest
from check_plc_robot import runtime, plant, config


class DeviceReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls): cls.r=runtime()

    def test_manual_belt_interlock_return_requires_release(self):
        r=self.r; f=r.instance('FB_StationManual')
        cmd=r.value('ST_StationManualCmd'); inp=r.value('ST_StationManualIn')
        inp.update(armed=True,manual=True,safe=True,idle=True,timeout=100,sessionId=1,panel=111)
        cmd['sessionId']=1; inp['allowPositive'][1]=True
        f.run(Cmd=cmd,Inp=inp)
        cmd['positive'][1]=True; cmd['holdCounter'][1]+=1; f.run(Cmd=cmd,Inp=inp)
        self.assertTrue(f.v['Sts']['positive'][1])
        inp['allowPositive'][1]=False; cmd['holdCounter'][1]+=1; f.run(Cmd=cmd,Inp=inp)
        inp['allowPositive'][1]=True; cmd['holdCounter'][1]+=1; f.run(Cmd=cmd,Inp=inp)
        self.assertFalse(f.v['Sts']['positive'][1])
        cmd['positive'][1]=False; f.run(Cmd=cmd,Inp=inp)
        cmd['positive'][1]=True; cmd['holdCounter'][1]+=1; f.run(Cmd=cmd,Inp=inp)
        self.assertTrue(f.v['Sts']['positive'][1])

    def test_latched_cylinder_checks_direction_after_request_release(self):
        r=self.r; p=plant(r); f=r.instance('FB_RobotGripper')
        home={i:False for i in range(1,6)}; work=dict(home); work[1]=True
        a=dict(Cfg=config(r)['gripper'],Session=True,Permit=True,CylHome=home,CylWork=work,
               CylIn=p['cylinders'],VacIn=p['vacuum'])
        f.run(**a); self.assertTrue(f.v['Cyl'][1]['work'])
        work[1]=False; f.run(**a); self.assertTrue(f.v['Cyl'][1]['work'])
        p['cylinders'][1]['workAllowed']=False; f.run(**a)
        self.assertFalse(f.v['Cyl'][1]['work']); self.assertFalse(f.v['Cyl'][1]['acceptedWork'])

    def test_storage_permission_loss_keeps_reservation_but_removes_open_command(self):
        r=self.r; p=plant(r); f=r.instance('FB_Storage')
        cfg=r.value('ST_StorageCfg'); cfg.update(tStable=10,tM8Timeout=1000)
        cmd=r.value('ST_StorageCmd'); cmd.update(Enable=True,RobotAccessReq=True,RobotAccessPermit=True,RobotReserved=True)
        inp=r.value('ST_StorageIn'); inp.update(RobotSideOpeningPermission=True)
        inp['Left']=p['cylinders'][1]; inp['Right']=p['cylinders'][2]
        f.run(Cfg=cfg,Cmd=cmd,Inp=inp); self.assertTrue(f.v['Outp']['Q_V401Home'])
        inp['RobotSideOpeningPermission']=False
        f.run(Cfg=cfg,Cmd=cmd,Inp=inp)
        self.assertFalse(f.v['Outp']['Q_V401Home']); self.assertFalse(f.v['Sts']['RobotAccessGranted'])
        self.assertTrue(f.v['Sts']['RobotAccessActive'])

    def test_fault_reason_remains_after_timeout_and_idle_is_not_fault(self):
        r=self.r; p=plant(r); f=r.instance('FB_RobotGripper')
        work={i:False for i in range(1,6)}; work[1]=True
        cfg=config(r)['gripper']; cfg['motionTimeout']=20
        a=dict(Cfg=cfg,Session=True,Permit=True,CylWork=work,CylIn=p['cylinders'],VacIn=p['vacuum'])
        for _ in range(5): f.run(**a)
        self.assertTrue(f.v['Cyl'][1]['fault']); self.assertEqual(f.v['Cyl'][1]['faultCode'],60)
        f.run(**{**a,'Permit':False})
        self.assertEqual(f.v['Cyl'][1]['reason'],60)
        idle=r.instance('FB_RobotGripper'); idle.run(**{**a,'Permit':False})
        self.assertFalse(idle.v['Cyl'][1]['fault']); self.assertFalse(idle.v['Vac'][1]['fault'])

    def test_local_timeout_reaches_final_coil_without_global_critical(self):
        r=self.r; stopper=r.instance('FB_StopperPair'); coils=r.instance('FB_StationCoils')
        cfg=r.value('ST_StopperPairCfg'); cfg.update(requireValid=True,requireApplied=True,tStable=10,tTimeout=20)
        inp=r.value('ST_StopperPairIn'); inp.update(valid=True,commandApplied=True)
        cmd={i:r.value('ST_StationCoil') for i in range(1,11)}; loss=copy.deepcopy(cmd)
        local=copy.deepcopy(cmd); valid={i:True for i in cmd}; fault={i:False for i in cmd}
        for _ in range(5):
            stopper.run(Cfg=cfg,Enable=True,HoldUp=True,Inp=inp)
            cmd[1].update(home=stopper.v['Outp']['Q_Bwd'],work=stopper.v['Outp']['Q_Fwd'])
            valid[1]=not stopper.v['Diag']['Fault']; fault[1]=not valid[1]
            coils.run(NewPermit=True,UseCommandValid=True,CommandValid=valid,PolicyVerified=True,
                      Cmd=cmd,LossPolicy=loss,LocalFault=fault,LocalFaultPolicyVerified=True,LocalFaultPolicy=local)
        self.assertTrue(stopper.v['Diag']['Fault']); self.assertFalse(coils.v['Applied'][1]['work'])
        self.assertFalse(coils.v['Fault'])


class ControllerReviewTests(unittest.TestCase):
    def cell(self):
        from plc_station_cosim import StationCell
        return StationCell(2)

    def test_invalid_loss_policy_never_applies_two_coils_and_retains_last_valid_policy(self):
        c=self.cell(); c.inp['robot_Plant']['cylinders'][1].update(lossHome=True,lossWork=False)
        c.scan()
        c.inp['robot_Plant']['cylinders'][1]['lossWork']=True
        c.inp['robot_Plant']['critical']=True; c.scan()
        coil=c.controller.v['Outp']['robot_Sts']['cylinders'][1]
        self.assertTrue(coil['home']); self.assertFalse(coil['work'])
        self.assertTrue(c.controller.v['Outp']['robot_Tx']['production_criticalBlock'])

    def test_new_coil_configuration_fault_stops_belt_in_current_scan(self):
        c=self.cell(); c.command('modeManual')
        c.hmi['link']['uiActivePanel']=111; cmd=c.hmi['stationManual']
        cmd['sessionId']=c.hmi['link']['udiSessionId']
        c.inp['station_ManualInterlocks']['allowPositive'][1]=True; c.scan()
        cmd['positive'][1]=True
        for _ in range(4): cmd['holdCounter'][1]+=1; c.scan()
        self.assertTrue(c.controller.v['Outp']['io_dout']['ctrl_turn_on_top_conveyor'])
        c.cfg['robot_stationCoilLossPolicy'][10].update(home=True,work=True)
        cmd['holdCounter'][1]+=1; c.scan(); out=c.controller.v['Outp']
        self.assertFalse(out['io_dout']['ctrl_turn_on_top_conveyor'])
        self.assertTrue(out['robot_Tx']['production_criticalBlock'])

    def test_manual_elevator_axis_and_belt_cannot_start_across_scan_boundary(self):
        for simultaneous in (False,True):
            with self.subTest(simultaneous=simultaneous):
                c=self.cell(); c.command('modeManual'); c.hmi['link']['uiActivePanel']=112
                cmd=c.hmi['stationManual']; cmd['sessionId']=c.hmi['link']['udiSessionId']
                c.inp['station_ManualInterlocks']['allowPositive'][2]=True
                c.inp['station_ManualInterlocks']['allowNegative'][4]=True; c.scan()
                cmd['positive'][2]=True
                if simultaneous: cmd['negative'][4]=True
                cmd['holdCounter'][2]+=1; c.scan()
                cmd['negative'][4]=True
                for _ in range(4):
                    cmd['holdCounter'][2]+=1; cmd['holdCounter'][4]+=1; c.scan()
                    out=c.controller.v['Outp']
                    belt=out['io_dout']['ctrl_turn_on_elevator_conveyor_in']
                    axis=out['drive']['forward'] or out['drive']['reverse']
                    self.assertFalse(belt and axis)
                self.assertFalse(c.controller.v['manual'].v['Sts']['active'])

    def test_recovery_rebases_discarded_material_event_without_reusing_id(self):
        c=self.cell(); v=c.controller.v
        c.c['station'].update(nextMaterialEventId=1,lastMaterialEventId=0)
        v['material'].v['Sts'].update(known=False,fault=True,lastEventId=0)
        v['reconcileRequired']=True; c.scan()
        c.proposal.update(copy.deepcopy(c.c)); c.proposal['occupancyKnown']=True
        c.proposal['occupied']={i:c.positions[i] is not None for i in range(1,8)}
        c.proposal['elevatorLoadPresent']=False; c.command('recoveryConfirm'); c.scan()
        self.assertTrue(v['material'].v['Sts']['known'])
        c.positions[1]={'trays':4}
        for _ in range(3): c.scan()
        self.assertTrue(v['material'].v['Sts']['known']); self.assertFalse(v['material'].v['Sts']['fault'])
        self.assertTrue(v['material'].v['Sts']['occupied'][1])
        self.assertGreater(c.c['station']['nextMaterialEventId'],1)

    def test_quantity_apply_rejected_during_manual_gripper_motion(self):
        c=self.cell(); c.command('modeManual'); c.command('robotDisable'); c.c['orderActive']=False
        c.inp['robot_Plant']['manualGripperHandover']=True
        c.hmi['link']['uiActivePanel']=115; c.hmi['manual']['udiSessionId']=c.hmi['link']['udiSessionId']
        original=c.inputs
        def inputs():
            original(); c.inp['robot_Plant']['cylinders'][1].update(atHome=False,atWork=False)
            c.hmi['manual']['holdCounter'][1]+=1
        c.inputs=inputs; c.scan(); c.hmi['manual']['cylWork'][1]=True; c.scan(); c.scan()
        self.assertTrue(c.controller.v['Outp']['robot_Sts']['cylinders'][1]['busy'])
        old=c.c['batchCount']; c.hmi['edit']['uiBatchCount']=9; c.reqid+=1
        req=c.hmi['cmd']['station5ParamApply']
        req.update(xReq=True,udiSessionId=c.hmi['link']['udiSessionId'],udiRequestId=c.reqid)
        c.until(lambda:c.hmi['rsp']['station5ParamApply']['xAck'],limit=40)
        self.assertEqual(c.hmi['rsp']['station5ParamApply']['uiResult'],2)
        self.assertEqual(c.c['batchCount'],old)

    def test_idle_gripper_is_not_ten_device_alarms(self):
        c=self.cell()
        for i in range(31,41): self.assertFalse(c.controller.v['alarmIn']['active'][i],i)

    def test_final_vacuum_applied_matches_wire_and_preserves_existing_hold(self):
        for held in (False,True):
            with self.subTest(held=held):
                c=self.cell(); c.controller.v['robot'].v['Gripper'].v['Vac'][1]['hold']=held
                c.inp['robot_Plant']['critical']=True; c.scan(); out=c.controller.v['Outp']
                self.assertEqual(out['robot_Sts']['vacuum'][1]['hold'],held)
                self.assertEqual(out['robot_Tx']['vac_1_holdApplied'],held)
                self.assertFalse(out['robot_Sts']['vacuum'][1]['blow'])

    def test_prg_main_decodes_signed_rfr_before_scaling(self):
        from plc_station_main import MainCell
        c=MainCell()
        for raw,expected in ((0,0.0),(50,5.0),(65535,-0.1),(65486,-5.0)):
            c.g['GVL_IO_RAW']['di']['ATV320_currentFrequency_RFR3202']=raw
            c.scan()
            self.assertAlmostEqual(c.main.v['driveAdapter'].v['Feedback']['actualHz'],expected)


class RetryAndArithmeticReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls): cls.r=runtime()

    def test_local_reset_does_not_restart_auto_coil_without_fresh_start(self):
        r=self.r; f=r.instance('FB_StationCoils')
        cmd={i:r.value('ST_StationCoil') for i in range(1,11)}
        loss=copy.deepcopy(cmd); local=copy.deepcopy(cmd)
        fault={i:False for i in cmd}; valid={i:True for i in cmd}
        cmd[1]['work']=True
        args=dict(NewPermit=True,PolicyVerified=True,Cmd=cmd,LossPolicy=loss,
                  UseCommandValid=True,CommandValid=valid,LocalFault=fault,
                  LocalFaultPolicyVerified=True,LocalFaultPolicy=local)
        f.run(**args); self.assertTrue(f.v['Applied'][1]['work'])
        fault[1]=True; f.run(**args)
        self.assertTrue(f.v['RestartRequired'][1]); self.assertFalse(f.v['Applied'][1]['work'])
        fault[1]=False
        for _ in range(3): f.run(**args)
        self.assertFalse(f.v['Applied'][1]['work']); self.assertFalse(f.v['Fault'])
        f.run(**args,RestartPulse=True)
        self.assertTrue(f.v['Applied'][1]['work']); self.assertFalse(f.v['RestartRequired'][1])

    def test_manual_timeout_requires_release_then_new_press(self):
        r=self.r; f=r.instance('FB_StationCoils')
        cmd={i:r.value('ST_StationCoil') for i in range(1,11)}
        loss=copy.deepcopy(cmd); local=copy.deepcopy(cmd); active={i:False for i in cmd}
        fault=copy.deepcopy(active); active[1]=True; cmd[1]['work']=True
        a=dict(NewPermit=True,Manual=True,ManualActive=active,ReleaseVerified=True,ReleasePolicy=local,
               PolicyVerified=True,Cmd=cmd,LossPolicy=loss,LocalFault=fault,
               LocalFaultPolicyVerified=True,LocalFaultPolicy=local)
        f.run(**a); fault[1]=True; f.run(**a); fault[1]=False; f.run(**a)
        self.assertFalse(f.v['Applied'][1]['work'])
        active[1]=False; f.run(**a); active[1]=True; f.run(**a)
        self.assertTrue(f.v['Applied'][1]['work']); self.assertFalse(f.v['Fault'])

    def test_scalar_assignments_and_real_conversion_follow_declared_boundaries(self):
        from plc_st_runtime import Ref, TypedValues, Parser
        values=TypedValues(dict(unsigned=0,signed=0),dict(unsigned='UINT',signed='INT'))
        Ref(values,'unsigned').set(65536); Ref(values,'signed').set(65535)
        self.assertEqual(values['unsigned'],0); self.assertEqual(values['signed'],-1)
        for number,expected in ((1.6,2),(2.5,2),(3.5,4)):
            expr=Parser('REAL_TO_UINT('+str(number)+')').expr()
            self.assertEqual(self.r.eval(expr,{}),expected)
        with self.assertRaises(ValueError): self.r.eval(Parser('REAL_TO_UINT(65536.0)').expr(),{})

    def test_impossible_cycle_components_cannot_hide_in_overflow(self):
        from check_plc_robot import context
        r=self.r; c=context(r)
        c['cycles'][1].update(occupied=True,id=1,quantity=7,good=4294967295,samples=1)
        f=r.instance('FB_RobotCycleLedger')
        f.run(Context=c,Session=True,StartValid=True,CyclesKnown=True,Quantity=7,StackId=10,Program_=2)
        self.assertTrue(f.v['Fault'])
        proposal=copy.deepcopy(c); cmd=r.value('ST_RobotCommands'); cmd['recover']=True
        rx=r.value('ST_RobotRxV2'); rx.update(production_home=True,production_loadKnown=True)
        recovery=r.instance('FB_RobotRecovery')
        recovery.run(Context=c,Proposal=proposal,Plant=plant(r),Rx=rx,Cmd=cmd,AtRecovery=True,Neutral=True)
        self.assertFalse(recovery.v['Approved'])

    def test_unverified_local_policy_blocks_station_without_fabricated_approval(self):
        r=self.r; f=r.instance('FB_StationOutputPolicy'); cfg=r.value('ST_StationCfg')
        p=plant(r); storage=r.value('ST_StorageIn')
        storage['Left']=p['cylinders'][1]; storage['Right']=p['cylinders'][2]
        cfg['robot_stationCoilPolicyVerified']=True
        f.run(Cfg=cfg,Plant=p,Storage=storage); self.assertFalse(f.v['Ready'])
        cfg['station_LocalFaultPolicyVerified']=True
        f.run(Cfg=cfg,Plant=p,Storage=storage); self.assertTrue(f.v['Ready'])
        cfg['robot_stationCoilLossPolicy'][1]['home']=True; f.run(Cfg=cfg,Plant=p,Storage=storage)
        cfg['robot_stationCoilLossPolicy'][1]['work']=True; f.run(Cfg=cfg,Plant=p,Storage=storage)
        self.assertFalse(f.v['Ready']); self.assertTrue(f.v['StationLoss'][1]['home'])
        self.assertFalse(f.v['StationLoss'][1]['work'])


class AdditionalControllerReviewTests(unittest.TestCase):
    def test_manual_local_timeout_reaches_output_and_reset_needs_new_press(self):
        from plc_station_cosim import StationCell
        c=StationCell(2); c.command('modeManual')
        c.hmi['link']['uiActivePanel']=112; cmd=c.hmi['stationManual']
        cmd['sessionId']=c.hmi['link']['udiSessionId']
        c.inp['station_ManualInterlocks']['allowPositive'][10]=True
        c.c['stationParameters'][2]['actuatorTimeoutMs']=20
        original=c.inputs
        def inputs():
            original(); c.inp['station_Inputs']['v201'].update(IsExt=False,IsRet=False)
            cmd['holdCounter'][10]+=1
        c.inputs=inputs; c.scan(); cmd['positive'][10]=True
        for _ in range(6): c.scan()
        v=c.controller.v
        self.assertTrue(v['fbV201'].v['Diag']['Fault'])
        self.assertFalse(v['Outp']['station_V201Out']['work'])
        self.assertFalse(v['currentCritical'])
        c.command('resetFaults')
        self.assertFalse(v['Outp']['station_V201Out']['work'])
        cmd['positive'][10]=False; c.scan(); cmd['positive'][10]=True; c.scan()
        self.assertTrue(v['Outp']['station_V201Out']['work'])
        self.assertFalse(v['currentCritical'])

    def test_station_parameters_also_reject_active_gripper(self):
        from plc_station_cosim import StationCell
        c=StationCell(2); c.command('modeManual'); c.command('robotDisable')
        c.inp['robot_Plant']['manualGripperHandover']=True
        c.hmi['link']['uiActivePanel']=115
        c.hmi['manual']['udiSessionId']=c.hmi['link']['udiSessionId']
        original=c.inputs
        def inputs():
            original(); c.inp['robot_Plant']['cylinders'][1].update(atHome=False,atWork=False)
            c.hmi['manual']['holdCounter'][1]+=1
        c.inputs=inputs; c.scan(); c.hmi['manual']['cylWork'][1]=True; c.scan(); c.scan()
        old=copy.deepcopy(c.c['stationParameters'][1])
        c.hmi['stationEdit'][1]=copy.deepcopy(old); c.hmi['stationEdit'][1]['sensorStableMs']=15
        c.hmi['stationEditRevision'][1]=c.c['stationParamRevision'][1]; c.reqid+=1
        req=c.hmi['cmd']['station1ParamApply']
        req.update(xReq=True,udiSessionId=c.hmi['link']['udiSessionId'],udiRequestId=c.reqid)
        c.until(lambda:c.hmi['rsp']['station1ParamApply']['xAck'],limit=40)
        self.assertEqual(c.hmi['rsp']['station1ParamApply']['uiResult'],2)
        self.assertEqual(c.c['stationParameters'][1],old)


if __name__=='__main__': unittest.main(verbosity=2)
