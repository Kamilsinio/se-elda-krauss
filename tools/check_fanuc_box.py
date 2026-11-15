"""Behavior checks of actual emitted BOX, COMMON and BG LS (synthetic cell only)."""
from __future__ import annotations
import unittest
from check_fanuc_tray import Cell, RES, BOX, COMMON, COM, PROGRAMS, ROOT
import check_fanuc_comm as core
import re

class BoxCell(Cell):
    def __init__(self):super().__init__(1)
    def configure(self,**values):
        self.inputs['p2r.production.orderActive']=False;self.scan(False)
        for key,value in values.items():self.set(self.s,key,value)
        self.set(self.b,'stationIdleConfirmed',True);self.control('APPLY')
        assert self.get(self.b,'cfgApplied') and not self.get(self.b,'applyDenied')
        self.set(self.b,'newApproved',True);self.control('NEW')
        self.inputs['p2r.production.orderActive']=True;self.scan(False)
    def batch(self,n,count=7,reject=False):
        self.begin(n,count,reject)
        self.until(lambda:self.jobs[-1]['placed']==count)
        self.until(lambda:not self.get(self.b,'batchAssigned'))
    def resync(self):
        self.inputs['p2r.link.syncRequest']=True;self.scan()
        self.inputs['p2r.link.syncAck']=True;self.scan()
        self.inputs['p2r.link.syncRequest']=False;self.inputs['p2r.link.syncAck']=False;self.scan()

class BoxChecks(unittest.TestCase):
    def test_three_sections_two_layers_one_spacer_no_bottom_or_top(self):
        c=BoxCell();c.start()
        positions=[]
        for n in range(6):
            c.batch(n+1);positions.append((c.get(c.p,'sectionIndex'),c.get(c.p,'trayIndex')))
        c.until(lambda:c.event_count('stackFinished')==1)
        self.assertEqual(positions,[(1,0),(2,0),(3,0),(1,1),(2,1),(3,1)])
        self.assertEqual(c.total('productsPlaced'),42)
        self.assertEqual(c.event_count('spacerPlaced'),1)
        self.assertEqual([v['index'] for n,v in c.events if n=='layerFinished'],[0,1])
        names=[n for n,_ in c.events]
        self.assertLess(names.index('layerFinished'),names.index('spacerPlaced'))
        self.assertLess(names.index('spacerPlaced'),names.index('stackFinished'))
        self.assertNotIn('blisterPicked',names)
        self.assertNotIn('blisterPlaced',names)
        self.assertNotIn('blisterFinished',names)

    def test_disabled_p2_p3_and_single_layer(self):
        c=BoxCell();c.configure(p2X=0,p2Y=0,p3X=0,p3Y=0,traysPerStack=1)
        c.start();c.batch(1);c.until(lambda:c.event_count('stackFinished')==1)
        self.assertEqual(c.event_count('spacerPlaced'),0)
        self.assertEqual(c.event_count('layerFinished'),1)
        self.assertEqual(c.total('productsPlaced'),7)

    def test_disabled_middle_section_skips_to_p3(self):
        c=BoxCell();c.configure(p2X=0,p2Y=0,traysPerStack=1)
        c.start();c.batch(1);c.until(lambda:c.get(c.p,'sectionIndex')==3)
        c.batch(2);c.until(lambda:c.event_count('stackFinished')==1)
        self.assertEqual(c.total('productsPlaced'),14)

    def test_offsets_row_major_layer_z_and_negative_pitch(self):
        c=BoxCell();c.configure(gridX=2,gridY=2,pitchX=-120,pitchY=80,
            p2X=0,p2Y=0,traysPerStack=3,qty2=0,mask2=0)
        c.start()
        # Six single-group batches per layer: four in P1, then two in P3.
        for n in range(1,17):
            c.begin(n,count=5);c.until(lambda:c.get(c.p,'state')==440)
            if n==6:self.assertEqual(tuple(c.v.read('PR[68]')),(100,0,0,0,0,0))
            if n==16:self.assertEqual(tuple(c.v.read('PR[68]')),(-120,80,80,0,0,0))
            c.until(lambda:c.jobs[-1]['placed']==5)
            c.until(lambda:not c.get(c.b,'batchAssigned'))

    def test_cylinder_target_per_group_then_lift_before_home(self):
        c=BoxCell();c.configure(cylGroup1=65,cylGroup2=34)
        c.start();c.begin(1)
        c.until(lambda:c.get(c.p,'state')==430 and c.get(c.p,'group')==1)
        self.assertTrue(c.output('r2p.cyl.V501.home'));self.assertTrue(c.output('r2p.cyl.V502.work'))
        c.until(lambda:c.get(c.p,'state')==482)
        self.assertTrue(c.output('r2p.cyl.V502.work'))
        # Last product move is a lift, strictly above the group's release point.
        self.assertGreater(c.v.motions[-1][3][2],c.v.motions[-2][3][2])
        c.until(lambda:c.get(c.p,'state')==430 and c.get(c.p,'group')==2)
        self.assertTrue(c.output('r2p.cyl.V501.work'));self.assertTrue(c.output('r2p.cyl.V502.home'))
        c.until(lambda:c.jobs[0]['placed']==7)

    def test_parameter_rejections_and_independent_snapshots(self):
        for changes in [dict(p2X=3),dict(p2Y=0),dict(cylGroup1=33),dict(cylGroup1=1),
                        dict(qty1=0),dict(mask2=1),dict(productClearance=0)]:
            with self.subTest(changes=changes):
                c=BoxCell();before={k:c.get(c.a,k) for k in c.a}
                c.inputs['p2r.production.orderActive']=False;c.scan(False)
                for key,value in changes.items():c.set(c.s,key,value)
                c.set(c.b,'stationIdleConfirmed',True);c.control('APPLY')
                self.assertEqual({k:c.get(c.a,k) for k in c.a},before)
                self.assertFalse(c.get(c.b,'cfgApplied'))
        c=BoxCell();before=c.get(c.a,'qty1')
        c.set(c.s,'qty1',100);c.set(c.b,'stationIdleConfirmed',True);c.control('APPLY')
        self.assertTrue(c.get(c.b,'applyDenied'));self.assertEqual(c.get(c.a,'qty1'),before)
        c.v.memory[RES['staging']['qty1']]=123
        self.assertEqual(c.get(c.s,'qty1'),100);self.assertEqual(c.get(c.a,'qty1'),before)
        c.start();c.begin(1,8)
        for _ in range(15):c.scan()
        self.assertEqual(c.get(c.p,'state'),900);self.assertEqual(c.event_count('immPickupCompleted'),0)

    def test_all_next_batch_samples_and_rejects_do_not_fill_slots(self):
        c=BoxCell();c.start();c.inputs['p2r.samples.req']=True
        for _ in range(5):c.scan()
        c.batch(1)
        self.assertEqual(c.total('samplesPlaced'),7);self.assertEqual(c.get(c.p,'slot'),0)
        c.batch(2,reject=True)
        self.assertEqual(c.total('rejectsPlaced'),7);self.assertEqual(c.get(c.p,'slot'),0)
        self.assertEqual(c.total('productsPlaced'),0);self.assertEqual(c.event_count('layerFinished'),0)

    def test_stop_before_spacer_entry_cancels_wait_and_keeps_partial_box(self):
        c=BoxCell();c.configure(p2X=0,p2Y=0,p3X=0,p3Y=0)
        c.area_block.add('storage');c.start();c.batch(1)
        c.until(lambda:c.get(c.p,'state')==545)
        c.stop();c.until(lambda:c.get(c.p,'state')==710)
        self.assertFalse(c.get(c.b,'spacerStarted'));self.assertTrue(c.get(c.b,'spacerNeeded'))
        self.assertFalse(c.output('r2p.area.storage.accessReq'))
        self.assertEqual(c.event_count('spacerPlaced'),0);self.assertEqual(c.event_count('stackFinished'),0)

    def test_stop_after_spacer_entry_finishes_only_started_spacer(self):
        c=BoxCell();c.configure(p2X=0,p2Y=0,p3X=0,p3Y=0)
        c.start();c.batch(1);c.until(lambda:c.get(c.b,'spacerStarted'))
        c.stop();c.until(lambda:c.get(c.p,'state')==710)
        self.assertEqual(c.event_count('spacerPlaced'),1);self.assertEqual(c.event_count('stackFinished'),0)
        self.assertEqual(c.get(c.p,'trayIndex'),1)
        self.assertEqual(c.event_count('immPickupCompleted'),1)

    def test_stop_n_plus_one_needs_spacer_and_finishes_new_batch(self):
        c=BoxCell();c.configure(p2X=0,p2Y=0,p3X=0,p3Y=0)
        c.start();c.begin(1)
        c.until(lambda:c.get(c.p,'state')==440)
        c.begin(2);c.stop()
        c.until(lambda:c.get(c.p,'state')==710,limit=1000)
        self.assertEqual(c.total('productsPlaced'),14);self.assertEqual(c.event_count('immPickupCompleted'),2)
        self.assertEqual(c.event_count('spacerPlaced'),1);self.assertEqual(c.event_count('stackFinished'),1)
        self.assertEqual(c.output('r2p.imm.req.mouldClose'),False)
        c.until(lambda:c.output('r2p.production.operationsSettled') and not c.get(c.b,'armed'))
        self.assertTrue(c.output('r2p.production.operationsSettled'))

    def test_stop_before_first_box_ready_does_not_wait_forever(self):
        c=BoxCell();c.inputs['p2r.area.elevator.ready']=False
        # Model keeps ready false explicitly for this test.
        c.devices=lambda:None
        c.start();c.until(lambda:c.get(c.p,'state')==200);c.stop()
        c.until(lambda:c.get(c.p,'state')==710)
        self.assertEqual(c.event_count('immPickupCompleted'),0)

    def test_lost_ack_no_counter_advance_and_terminal_no_replay(self):
        for name in ['productsPlaced','layerFinished','spacerPlaced','stackFinished']:
            with self.subTest(event=name):
                c=BoxCell();c.configure(p2X=0,p2Y=0,p3X=0,p3Y=0)
                c.suppress_events.add(name);c.start();c.begin(1)
                if name=='stackFinished':
                    c.until(lambda:not c.get(c.b,'batchAssigned') and c.get(c.p,'trayIndex')==1)
                    c.begin(2)
                for _ in range(500):
                    c.scan()
                    if c.get(c.p,'state')==900:break
                self.assertEqual(c.get(c.p,'state'),900)
                self.assertEqual(c.event_count(name),0)
                if name=='productsPlaced':
                    self.assertEqual(c.get(c.p,'remaining'),7);self.assertEqual(c.get(c.p,'slot'),0)
                else:self.assertTrue(c.get(c.b,'terminalPending'))
                before=list(c.events);c.resync()
                c.set(c.native,'home',True);c.set(c.app,'r2p.production.loadKnown',True)
                c.set(c.b,'recoveryApproved',True);c.set(c.b,'contextChecked',True)
                c.control('RECOV')
                self.assertEqual(c.get(c.p,'state'),900)
                for _ in range(10):c.scan()
                self.assertEqual(c.events,before)

    def test_spacer_search_bounded_and_loss_of_storage_grant(self):
        c=BoxCell();c.configure(p2X=0,p2Y=0,p3X=0,p3Y=0);c.vac_fail.add(5)
        c.start();c.batch(1)
        for _ in range(500):
            c.scan()
            if c.get(c.p,'state')==900:break
        self.assertEqual(c.get(c.p,'state'),900);self.assertEqual(c.event_count('spacerPlaced'),0)
        self.assertTrue(c.get(c.b,'spacerStarted'))
        c=BoxCell();c.configure(p2X=0,p2Y=0,p3X=0,p3Y=0);c.start();c.batch(1)
        c.until(lambda:c.get(c.b,'storageInside'))
        c.area_block.add('storage');c.devices();before=len(c.v.motions);c.scan();c.scan()
        self.assertEqual(c.get(c.p,'state'),900);self.assertEqual(len(c.v.motions),before)

    def test_no_motion_without_capacity_bindings_or_taught_points(self):
        for field in ['capacityVerified','bindingsVerified']:
            c=BoxCell();c.set(c.global_flags,field,False);c.start();c.begin(1)
            before=len(c.v.motions)
            for _ in range(20):c.scan()
            self.assertEqual(len(c.v.motions),before)
        c=BoxCell();c.start();c.begin(1);c.set(c.res['taught'],'51',False)
        for _ in range(30):c.scan()
        self.assertEqual(c.get(c.p,'state'),900);self.assertEqual(c.event_count('immPickupCompleted'),0)

    def test_owner_conflict_denies_second_task_without_resetting_context(self):
        c=BoxCell();c.start();c.begin(1);c.until(lambda:c.get(c.p,'state')==440)
        saved={k:c.get(c.p,k) for k in ['cycleId','remaining','sectionIndex','slot']}
        c.v.memory[RES['runtime']['remaining']]=999
        c.start_other(2)
        # BG_BIND is deliberately UNBOUND in the repo; synthetic fixture rebinds here only.
        c.set(c.global_flags,'sourceBound',True);c.v.memory[COMMON['tasks']['tray']['running']]=True
        before=len(c.v.motions);c.scan()
        self.assertEqual(c.v.read(COMMON['owner']),1);self.assertTrue(c.get(c.global_flags,'conflict'))
        self.assertEqual({k:c.get(c.p,k) for k in saved},saved)
        self.assertEqual(c.v.read(RES['runtime']['remaining']),999)
        self.assertEqual(len(c.v.motions),before)
        c.v.memory[RES['flags']['newApproved']]=True;c.v.memory[RES['flags']['applyRequest']]=True;c.v.resume_task('MAIN_TRAY')
        self.assertEqual({k:c.get(c.p,k) for k in saved},saved)

    def test_release_requires_closed_empty_station_then_waits_for_old_native_task_end(self):
        c=BoxCell();c.start();c.stop();c.until(lambda:c.output('r2p.production.operationsSettled') and not c.get(c.b,'armed'))
        c.control('EXIT');c.scan(False);self.assertEqual(c.v.read(COMMON['owner']),1)
        c.inputs['p2r.production.orderActive']=False;c.scan()
        c.set(c.b,'stationIdleConfirmed',True);c.control('EXIT');c.scan(False)
        self.assertEqual(c.v.read(COMMON['owner']),0)
        c.start_other(2);c.set(c.global_flags,'sourceBound',True)
        c.set(COMMON['tasks']['tray'],'running',True);c.scan(False)
        self.assertEqual(c.v.read(COMMON['owner']),0)
        self.assertTrue(c.get(c.global_flags,'conflict'))
        # Both native tasks running is a real conflict and must be reset with both stopped.
        c.set(c.task,'running',False);c.set(COMMON['tasks']['tray'],'running',False)
        c.set(c.global_flags,'initApproved',True);c.set(c.global_flags,'emptyConfirmed',True);c.scan(False)
        self.assertFalse(c.get(c.global_flags,'conflict'))
        c.set(c.global_flags,'trayRequest',True);c.set(COMMON['tasks']['tray'],'running',True);c.scan(False)
        self.assertEqual(c.v.read(COMMON['owner']),2)
        self.assertEqual(c.output('r2p.production.program'),2)

    def test_technology_is_only_in_two_main_and_commands_remain_gated(self):
        for folder,name in [('TRAY','MAIN_TRAY'),('BOX','MAIN_BOX')]:
            paths=list((ROOT/'ROBOT'/folder).glob('*.LS'))
            self.assertEqual([p.stem for p in paths],[name])
            text=paths[0].read_text(encoding='ascii')
            self.assertNotRegex(text,r'CALL (?:RT|RX|RF|RG|RE|RM|XM)_')
            self.assertRegex(text,r'\b[JL] PR\[')
        self.assertFalse(list((ROOT/'ROBOT/COMMON').glob('*.LS')))
        all_alloc=COM['allocations']+RES['allocations']+BOX['allocations']+COMMON['allocations']
        declared={(v['bank'],v['number']) for v in all_alloc}
        self.assertEqual(len(declared),len(all_alloc))
        self.assertLessEqual(max(n for b,n in declared if b=='R'),360)
        self.assertEqual(COMMON['required_numeric_capacity'],400)
        self.assertEqual(set(RES['taught']) & set(BOX['taught']),{'1'})
        c=BoxCell();c.start();c.begin(1);c.until(lambda:c.get(c.p,'state')==440)
        c.set(c.c,'appArm',False);before=c.get(c.app,'r2p.production.loadMask');c.scan()
        self.assertEqual(c.get(c.p,'state'),900)
        self.assertEqual(c.get(c.app,'r2p.production.loadMask'),before)
        self.assertEqual(c.total('productsPlaced'),0)

    def test_ack_falling_edge_is_required_after_plc_has_counted(self):
        for name in ['productsPlaced','layerFinished','spacerPlaced','stackFinished']:
            with self.subTest(event=name):
                c=BoxCell();c.configure(p2X=0,p2Y=0,p3X=0,p3Y=0)
                original=c.plc_events
                def hold_ack():
                    original()
                    if c.event_count(name):c.inputs[f'p2r.event.{name}.ack']=True
                c.plc_events=hold_ack
                c.start();c.begin(1)
                if name=='stackFinished':
                    c.until(lambda:not c.get(c.b,'batchAssigned') and c.get(c.p,'trayIndex')==1)
                    c.begin(2)
                for _ in range(500):
                    c.scan()
                    if c.get(c.p,'state')==900:break
                self.assertEqual(c.event_count(name),1)
                self.assertEqual(c.get(c.p,'state'),900)
                if name=='productsPlaced':
                    self.assertEqual(c.get(c.p,'remaining'),7);self.assertEqual(c.get(c.p,'slot'),0)
                if name=='spacerPlaced':self.assertEqual(c.get(c.p,'trayIndex'),0)
                if name=='stackFinished':self.assertFalse(c.get(c.b,'fullStackWait'))

    def test_partial_batch_recovery_preserves_remaining_and_needs_fresh_start(self):
        c=BoxCell();c.start();c.begin(1)
        c.until(lambda:c.get(c.p,'remaining')==2 and c.get(c.p,'group')==2)
        c.set(c.b,'needsRecovery',True);c.scan()
        c.resync();c.set(c.native,'home',True)
        c.set(c.app,'r2p.production.loadKnown',True)
        c.set(c.b,'recoveryApproved',True);c.set(c.b,'contextChecked',True)
        c.control('RECOV')
        self.assertEqual(c.get(c.p,'state'),400);self.assertEqual(c.get(c.p,'remaining'),2)
        before=len(c.v.motions)
        for _ in range(5):c.scan()
        self.assertEqual(len(c.v.motions),before)
        c.start();c.until(lambda:c.jobs[0]['placed']==7)
        self.assertEqual(c.total('productsPlaced'),7)
        self.assertEqual(c.event_count('immPickupCompleted'),1)

    def test_withdrawn_execution_permit_cannot_reuse_old_event_success(self):
        c=BoxCell();c.start();c.begin(1)
        c.until(lambda:c.get(c.p,'state')==440 and c.get(c.p,'group')==2)
        old_remaining=c.get(c.p,'remaining');old_slot=c.get(c.p,'slot')
        c.inputs['p2r.production.newOperationPermit']=False;c.inputs['p2r.production.finishPermit']=False
        for _ in range(5):c.scan()
        self.assertEqual(c.get(c.p,'state'),900)
        self.assertEqual(c.get(c.p,'remaining'),old_remaining);self.assertEqual(c.get(c.p,'slot'),old_slot)
        self.assertEqual(c.total('productsPlaced'),5)

    def test_native_program_status_ignores_plc_expected_mode(self):
        c=BoxCell();self.assertEqual(c.output('r2p.production.program'),1)
        c.inputs['p2r.production.expectedProgram']=2;c.scan(False)
        self.assertEqual(c.output('r2p.production.program'),1)
        c.set(c.task,'running',False);c.set(c.task,'paused',True);c.scan(False)
        self.assertEqual(c.output('r2p.production.program'),1);self.assertFalse(c.output('r2p.production.running'))
        c.set(c.task,'paused',False);c.scan(False)
        self.assertEqual(c.output('r2p.production.program'),0);self.assertFalse(c.output('r2p.production.running'))




    def test_unexpected_stack_change_invalidates_box_context(self):
        c=BoxCell();c.start();c.begin(1);c.until(lambda:c.get(c.p,'state')==440)
        c.inputs['p2r.production.stackId']=99;before=len(c.v.motions)
        c.scan();c.scan()
        self.assertEqual(c.get(c.p,'state'),900);self.assertEqual(c.get(c.p,'stackId'),10)
        self.assertEqual(len(c.v.motions),before);self.assertFalse(c.get(c.app,'r2p.production.loadKnown'))

    def test_spacer_pick_rejects_preexisting_vacuum(self):
        c=BoxCell();c.configure(p2X=0,p2Y=0,p3X=0,p3Y=0);c.start();c.batch(1)
        c.until(lambda:c.get(c.p,'state')==550)
        c.inputs['p2r.vac.5.ok']=True;before=len(c.v.motions);c.scan()
        self.assertEqual(c.get(c.p,'state'),900)
        self.assertEqual(c.get(c.app,'r2p.production.faultCode'),1502)
        self.assertFalse(c.get(c.b,'spacerStarted'));self.assertEqual(len(c.v.motions),before)

    def test_box_init_clears_all_private_taught_flags_and_preserves_other_banks(self):
        c=BoxCell();c.inputs['p2r.production.orderActive']=False
        c.snapshot();c.v.run('PLC_RX');c.v.run('BG_STATUS')
        c.v.memory[RES['staging']['qty1']]=321
        c.set(c.global_flags,'bindingsVerified',True);c.set(c.b,'stationIdleConfirmed',True);c.control('INIT')
        self.assertTrue(c.get(c.global_flags,'bindingsVerified'))
        self.assertEqual(c.v.read(RES['staging']['qty1']),321)
        for ref in BOX['taught'].values():self.assertFalse(c.v.read(ref))


if __name__=='__main__':unittest.main(verbosity=2)
