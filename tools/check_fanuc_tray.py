"""Behavior tests executing emitted LIVE LS with explicit PLC and motion models.

The native status inputs and PR coordinates below are synthetic test fixtures,
not facts about the physical robot. No device connection or native compilation.
"""
from __future__ import annotations
from collections import Counter
import json
from pathlib import Path
import re
import unittest
import check_fanuc_comm as core

ROOT=Path(__file__).resolve().parents[1]
RES=json.loads((ROOT/'ROBOT/TRAY/resources.json').read_text(encoding='utf-8'))
COM=json.loads((ROOT/'ROBOT/COMM/resources.json').read_text(encoding='utf-8'))
MAP=json.loads((ROOT/'ROBOT/COMM/mapping.json').read_text(encoding='utf-8'))
PROGRAMS=core.load_programs([ROOT/'ROBOT/COMM',ROOT/'ROBOT/TRAY',ROOT/'ROBOT/BG',ROOT/'ROBOT/COMMON',ROOT/'ROBOT/BOX'])
BOX=json.loads((ROOT/'ROBOT/BOX/resources.json').read_text(encoding='utf-8'))
COMMON=json.loads((ROOT/'ROBOT/COMMON/resources.json').read_text(encoding='utf-8'))
WIRE={s['id']:f"{s['io']}[{s['number']}]" for s in MAP['signals']}


class Cell:
    def __init__(self,mode=2,settings=None):
        self.mode=mode;self.main='MAIN_TRAY' if mode==2 else 'MAIN_BOX'
        self.res=RES if mode==2 else json.loads((ROOT/"ROBOT/BOX/resources.json").read_text(encoding="utf-8"))
        self.v=core.VM(PROGRAMS);self.t=0;self.inputs={};self.events=[];self.blow_counts=Counter()
        self.jobs=[];self.acked=set();self.active_events={};self.blow_active=set()
        self.area_block=set();self.vac_fail=set();self.suppress_events=set();self.pause_heartbeat=False
        self.fail_blow={};self.stack=10
        self.p=self.res['runtime'];self.b=self.res['flags'];self.a=self.res['active'];self.s=self.res['staging']
        self.c=COM['controls'];self.app=COM['application'];self.native=self.res['native'];self.global_flags=COMMON['flags'];self.task=COMMON['tasks']['tray' if mode==2 else 'box']
        self.v.run('PLC_INIT')
        # Wyłącznie model dostarcza tutaj syntetyczne, zweryfikowane źródła statusów.
        for name in ['sourceBound','bindingsVerified','profileApproved','motionApproved','alarmApproved']:
            self.set(self.b,name,True)
        for name in ['autoMode','systemReady','home']:self.set(self.native,name,True)
        for n in map(int,self.res['taught']):
            self.v.memory[f'PR[{n}]']=core.Pose([100+n,200+n,1000,0,0,0])
            self.set(self.res['taught'],str(n),True)
        self.v.memory['PR[5]' if mode==2 else 'PR[44]']=core.Pose([104,204,500,0,0,0])
        self.v.motion_hook=lambda ref,pose:self.set(self.native,'home',ref=='PR[1]')
        defaults={f'mask{i}':0 for i in range(1,6)}
        defaults.update({f'qty{i}':0 for i in range(1,6)})
        defaults.update(mask1=1,mask2=2,qty1=5,qty2=2,gridX=2,gridY=2,pitchX=100,pitchY=80,
                        trayHeight=40,traysPerStack=2,searchStep=1,searchLimit=20,maxAttempts=3,
                        speed=10,timeout=50,tool=1,frame=1,cylFold=96,cylStraight=3,trayMask=16)
        if mode==1:
            defaults.update({f'p{j}{key}':value for j in (2,3) for key,value in [('X',2),('Y',1),('pitchX',100),('pitchY',80)]})
            defaults.update({f'cylGroup{i}':96 for i in range(1,6)})
            defaults.update(productClearance=50,spacerClearance=50,gridX=2,gridY=1)
        defaults.update(settings or {})
        for name,value in defaults.items():self.set(self.s,name,value)
        self.set(self.c,'configured',True);self.set(self.c,'run',True)
        self.inputs.update({'p2r.link.version':2,'p2r.link.ready':True,'p2r.link.heartbeat':0,
             'p2r.production.expectedProgram':mode,'p2r.production.withRobot':True,
             'p2r.production.newOperationPermit':True,'p2r.production.finishPermit':True,
             'p2r.production.stackId':self.stack,'p2r.production.startToken':0,
             'p2r.imm.valid':True,'p2r.imm.withRobot':True,'p2r.imm.cycleKnown':True,'p2r.imm.newCyclePermit':True,
             'p2r.imm.settled':True,'p2r.imm.mouldClosed':True,
             'p2r.imm.ejectorBack':True,'p2r.imm.ejectorForward':False})
        self.set(self.global_flags,'capacityVerified',True)
        self.set(self.global_flags,'initApproved',True);self.set(self.global_flags,'emptyConfirmed',True)
        self.devices()
        self.inputs['p2r.link.syncRequest']=True
        self.scan(False);self.scan(False)
        self.inputs['p2r.link.syncAck']=True;self.scan(False)
        self.inputs['p2r.link.syncRequest']=False;self.inputs['p2r.link.syncAck']=False;self.scan(False)
        assert self.get(self.c,'state')==30
        self.v.run('PLC_REC');self.scan(False)
        assert self.get(self.c,'session')
        # Start the actual annotated MAIN. Only native status is a synthetic fixture.
        self.set(self.task,'running',True)
        self.v.start_task(self.main);self.v.resume_task(self.main)
        self.set(self.global_flags,'sourceBound',True)
        self.scan(False)
        assert self.v.read(COMMON['owner'])==mode
        self.scan()
        # BOOT deliberately requires a fresh bilateral synchronization/recovery.
        self.inputs['p2r.link.syncRequest']=True;self.scan()
        self.inputs['p2r.link.syncAck']=True;self.scan()
        self.inputs['p2r.link.syncRequest']=False;self.inputs['p2r.link.syncAck']=False;self.scan()
        self.set(self.b,'newApproved',True);self.scan()
        self.scan()
        self.set(self.b,'stationIdleConfirmed',True);self.control('APPLY')
        assert self.get(self.b,'cfgApplied')
        self.set(self.b,'selected',True);self.set(self.c,'productionRequired',True)
        self.inputs['p2r.production.orderActive']=True
        self.scan(False)

    def set(self,group,key,value):
        self.v.memory[group[key]]=value
        if group is getattr(self,'native',None) and key in ('taskRunning','taskPaused'):
            self.v.memory[self.task['running' if key=='taskRunning' else 'paused']]=value
    def get(self,group,key):return self.v.read(group[key])
    def output(self,key):return self.v.read(WIRE[key])
    def snapshot(self):
        for key,ref in WIRE.items():
            if key.startswith('p2r.'):self.v.memory[ref]=self.inputs.get(key,0)
    def begin(self,id,count=7,reject=False):
        self.jobs.append(dict(id=id,count=count,reject=reject,picked=False,placed=0))
        self.update_jobs()
    def update_jobs(self):
        pending=next((j for j in self.jobs if not j['picked']),None)
        if pending:
            self.inputs.update({'p2r.imm.pickupPending':True,'p2r.imm.cycleId':pending['id'],
                                'p2r.imm.batchCount':pending['count'],'p2r.imm.reject':pending['reject']})
        else:self.inputs['p2r.imm.pickupPending']=False
        n=sum(j['placed']<j['count'] for j in self.jobs)
        self.inputs['p2r.imm.unsettledCount']=n;self.inputs['p2r.imm.settled']=n==0
    def devices(self):
        for area in ['source','elevator','storage']:
            self.inputs[f'p2r.area.{area}.valid']=True
            self.inputs[f'p2r.area.{area}.ready']=True
            self.inputs[f'p2r.area.{area}.granted']=area not in self.area_block
        for n in range(501,506):
            h=self.output(f'r2p.cyl.V{n}.home');w=self.output(f'r2p.cyl.V{n}.work')
            self.inputs[f'p2r.cyl.V{n}.valid']=True
            self.inputs[f'p2r.cyl.V{n}.acceptedHome']=h
            self.inputs[f'p2r.cyl.V{n}.acceptedWork']=w
            if h or w:
                self.inputs[f'p2r.cyl.V{n}.atHome']=h;self.inputs[f'p2r.cyl.V{n}.atWork']=w
        for n in range(1,6):
            valid=self.output(f'r2p.vac.{n}.cmdValid');hold=self.output(f'r2p.vac.{n}.hold')
            self.inputs[f'p2r.vac.{n}.valid']=True
            self.inputs[f'p2r.vac.{n}.accepted']=valid
            self.inputs[f'p2r.vac.{n}.holdApplied']=valid and hold
            if valid:self.inputs[f'p2r.vac.{n}.ok']=hold and n not in self.vac_fail
            req=self.output(f'r2p.vac.{n}.blowReq')
            if req and n not in self.blow_active:
                self.blow_active.add(n);self.blow_counts[n]+=1
            if not req:self.blow_active.discard(n)
            self.inputs[f'p2r.vac.{n}.blowAck']=req
            self.inputs[f'p2r.vac.{n}.blowResult']=self.fail_blow.get(n,1) if req else 0
        if self.output('r2p.imm.req.mouldFullOpen'):
            self.inputs['p2r.imm.mouldOpen']=True;self.inputs['p2r.imm.mouldClosed']=False
        if self.output('r2p.imm.req.ejectorForward'):
            self.inputs['p2r.imm.ejectorForward']=True;self.inputs['p2r.imm.ejectorBack']=False
        if self.output('r2p.imm.req.ejectorBack'):
            self.inputs['p2r.imm.ejectorBack']=True;self.inputs['p2r.imm.ejectorForward']=False
    def plc_events(self):
        for ch in COM['channels']:
            if ch['kind']!='event':continue
            name=ch['name'];req=self.output(ch['output'])
            ackkey=f'p2r.event.{name}.ack'
            if name in self.suppress_events:
                self.inputs[ackkey]=False;continue
            if req and name not in self.active_events:
                payload={key.rsplit('.',1)[1]:self.output(key) for key in ch['payload']}
                self.active_events[name]=payload;self.events.append((name,payload.copy()))
                if name=='immPickupCompleted':
                    job=next(j for j in self.jobs if j['id']==payload['cycleId'] and not j['picked'])
                    job['picked']=True
                if name in ['productsPlaced','samplesPlaced','rejectsPlaced']:
                    job=next(j for j in self.jobs if j['id']==payload['cycleId'])
                    job['placed']+=payload['count']
                    assert job['placed']<=job['count'],'PLC model rejects over-accounting'
                self.update_jobs()
            if not req and name in self.active_events:
                self.active_events.pop(name)
                if name=='stackFinished':
                    self.stack+=1;self.inputs['p2r.production.stackId']=self.stack
            self.inputs[ackkey]=req
        if self.output('r2p.samples.ack'):self.inputs['p2r.samples.req']=False
    def scan(self,production=True,advance=1,monitors=True,service=True):
        self.t+=advance;self.v.memory['$FAST_CLOCK']=self.t
        if not self.pause_heartbeat:self.inputs['p2r.link.heartbeat']=(self.inputs['p2r.link.heartbeat']+1)%65536
        self.snapshot();self.v.run('PLC_RX')
        if monitors:self.v.run('BG_STATUS');self.v.run('BG_GUARD')
        self.v.run('BG_PLC')
        if service:self.v.run('PLC_SCAN')
        if production:self.v.resume_task(self.main)
        self.devices();self.plc_events()
    def control(self,action):
        key={'INIT':'initApproved','APPLY':'applyRequest','NEW':'newApproved',
             'RECOV':'recoveryApproved','EXIT':'exitRequest'}[action]
        self.set(self.b,key,True);self.scan()
    def start_other(self,mode):
        name='MAIN_TRAY' if mode==2 else 'MAIN_BOX'
        self.set(COMMON['tasks']['tray' if mode==2 else 'box'],'running',True)
        self.v.start_task(name);self.v.resume_task(name)
        # The source values here are test-only synthetic native inputs.
        self.set(self.global_flags,'sourceBound',True)
    def start(self):
        self.inputs['p2r.production.startToken']=(self.inputs['p2r.production.startToken']+1)%65536
        self.scan()
    def stop(self):
        self.inputs['p2r.production.stopRequest']=True;self.inputs['p2r.production.newOperationPermit']=False
    def until(self,predicate,limit=600):
        for _ in range(limit):
            if predicate():return
            self.scan()
            assert self.get(self.p,'state')!=900,('unexpected recovery',self.get(self.app,'r2p.production.faultCode'),self.get(self.p,'resumeState'))
        raise AssertionError(('did not reach condition',self.get(self.p,'state'),self.events[-4:]))
    def event_count(self,name):return sum(1 for n,_ in self.events if n==name)
    def total(self,name):return sum(v.get('count',0) for n,v in self.events if n==name)


class TrayChecks(unittest.TestCase):
    def test_full_stack_partial_groups_no_double_counting(self):
        cell=Cell();cell.start()
        for i in range(4):
            cell.begin(100+i);cell.until(lambda:cell.jobs[-1]['placed']==7)
            cell.until(lambda:not cell.get(cell.b,'batchAssigned'))
        cell.until(lambda:cell.event_count('stackFinished')==1)
        cell.until(lambda:not cell.get(cell.b,'fullStackWait') and cell.get(cell.p,'stackId')==11)
        self.assertEqual(cell.total('productsPlaced'),28)
        self.assertEqual(cell.event_count('productsPlaced'),8)
        self.assertEqual(cell.event_count('blisterFinished'),2)
        self.assertEqual(cell.event_count('immPickupCompleted'),4)
        self.assertEqual(cell.blow_counts[1],4);self.assertEqual(cell.blow_counts[2],4)
        self.assertTrue(cell.v.motions)

    def test_samples_entire_next_batch_and_rejects_separate(self):
        cell=Cell();cell.inputs['p2r.samples.req']=True;cell.start();cell.begin(1)
        cell.until(lambda:cell.total('samplesPlaced')==7)
        cell.until(lambda:not cell.get(cell.b,'batchAssigned'))
        self.assertEqual(cell.get(cell.p,'slot'),0)
        cell.inputs['p2r.samples.req']=True;cell.begin(2,reject=True)
        cell.until(lambda:cell.total('rejectsPlaced')==7)
        cell.until(lambda:not cell.get(cell.b,'batchAssigned'))
        self.assertEqual(cell.get(cell.p,'slot'),0)
        self.assertEqual(cell.total('productsPlaced'),0)
        self.assertEqual(cell.event_count('samplesPlaced'),2)
        self.assertEqual(cell.event_count('rejectsPlaced'),2)

    def test_stop_finishes_n_and_already_begun_n_plus_one(self):
        cell=Cell();cell.start();cell.begin(1)
        cell.until(lambda:cell.event_count('immPickupCompleted')==1)
        cell.begin(2);cell.stop()
        cell.until(lambda:cell.get(cell.p,'state')==710 and cell.get(cell.app,'r2p.production.operationsSettled'))
        self.assertEqual(cell.total('productsPlaced'),14)
        self.assertEqual(cell.event_count('immPickupCompleted'),2)
        self.assertEqual(cell.event_count('blisterFinished'),1)
        self.assertFalse(cell.get(cell.b,'armed'))

    def test_stop_without_n_plus_one_keeps_partial_tray(self):
        cell=Cell();cell.start();cell.begin(1)
        cell.until(lambda:cell.event_count('immPickupCompleted')==1);cell.stop()
        cell.until(lambda:cell.get(cell.p,'state')==710)
        self.assertEqual(cell.total('productsPlaced'),7)
        self.assertEqual(cell.event_count('blisterFinished'),0)
        self.assertEqual(cell.get(cell.p,'slot'),2)
        cell.set(cell.b,'newApproved',True);cell.control('NEW')
        self.assertEqual(cell.get(cell.p,'slot'),2)
        cell.set(cell.b,'newApproved',False)
        before=len(cell.v.motions)
        cell.inputs['p2r.production.stopRequest']=False
        cell.inputs['p2r.production.newOperationPermit']=True
        for _ in range(5):cell.scan()
        self.assertEqual(len(cell.v.motions),before)
        cell.start();self.assertTrue(cell.get(cell.b,'armed'))

    def test_config_apply_and_active_snapshot(self):
        cell=Cell();cell.start();cell.begin(1)
        cell.until(lambda:cell.get(cell.b,'pickupConfirmed'))
        cell.set(cell.s,'qty1',99);cell.set(cell.b,'stationIdleConfirmed',True);cell.control('APPLY')
        self.assertTrue(cell.get(cell.b,'applyDenied'))
        self.assertEqual(cell.get(cell.a,'qty1'),5)
        cell.until(lambda:cell.jobs[0]['placed']==7)
        self.assertEqual(cell.total('productsPlaced'),7)

    def test_bad_masks_quantities_capacity_and_cycle_quantity(self):
        for changes in [dict(mask2=1),dict(qty1=0),dict(gridX=3,gridY=1),dict(trayMask=2),dict(cylFold=33)]:
            cell=Cell();cell.inputs['p2r.production.orderActive']=False
            cell.set(cell.b,'stationIdleConfirmed',True)
            for k,v in changes.items():cell.set(cell.s,k,v)
            cell.snapshot();cell.v.run('PLC_RX');cell.control('APPLY')
            self.assertFalse(cell.get(cell.b,'cfgApplied'),changes)
        cell=Cell();cell.start();cell.begin(8,count=8)
        for _ in range(100):
            cell.scan()
            if cell.get(cell.p,'state')==900:break
        self.assertEqual(cell.get(cell.p,'state'),900)
        self.assertEqual(cell.get(cell.app,'r2p.production.faultCode'),1302)

    def test_ack_loss_no_replay_or_early_counter(self):
        cell=Cell();cell.suppress_events.add('productsPlaced');cell.start();cell.begin(1)
        cell.until(lambda:cell.get(cell.p,'state')==460)
        self.assertEqual(cell.get(cell.p,'slot'),0)
        self.assertEqual(cell.get(cell.p,'remaining'),7)
        cell.pause_heartbeat=True
        cell.scan(advance=cell.get(cell.c,'peerTimeout')+1)
        self.assertEqual(cell.get(cell.p,'state'),900)
        self.assertEqual(cell.get(cell.p,'remaining'),7)
        self.assertTrue(cell.get(cell.b,'needsRecovery'))
        before=len(cell.v.motions)
        for _ in range(3):cell.scan()
        self.assertEqual(len(cell.v.motions),before)

    def test_bound_search_attempts_and_release_failure(self):
        cell=Cell();cell.vac_fail.add(5);cell.start()
        for _ in range(400):
            cell.scan()
            if cell.get(cell.p,'state')==900:break
        self.assertEqual(cell.get(cell.p,'state'),900)
        self.assertLessEqual(cell.get(cell.p,'searchDepth'),4)
        cell=Cell();cell.fail_blow[5]=2;cell.start()
        for _ in range(100):
            cell.scan()
            if cell.get(cell.p,'state')==900:break
        self.assertEqual(cell.get(cell.p,'state'),900)
        self.assertEqual(cell.event_count('blisterPlaced'),0)

    def test_waiting_area_warning_does_not_become_global_fault(self):
        cell=Cell();cell.area_block.add('source');cell.start()
        for _ in range(100):cell.scan()
        self.assertEqual(cell.get(cell.p,'state'),205)
        self.assertFalse(cell.get(cell.b,'needsRecovery'))
        self.assertFalse(cell.v.motions)
        cell.area_block.clear();cell.until(lambda:cell.get(cell.b,'trayReady'))

    def test_unbound_untaught_and_native_abort_block_motion(self):
        cell=Cell();cell.v.run('BG_BIND');cell.scan()
        cell.start();self.assertFalse(cell.v.motions)
        self.assertFalse(cell.get(cell.b,'sourceBound'))
        cell=Cell();cell.set(RES['taught'],'2',False);cell.start()
        for _ in range(10):cell.scan()
        self.assertEqual(cell.get(cell.p,'state'),900)
        self.assertFalse(cell.v.motions)
        cell=Cell();cell.start();cell.set(cell.native,'taskRunning',False);cell.scan()
        self.assertEqual(cell.get(cell.p,'state'),900)
        self.assertFalse(cell.get(cell.c,'appArm'))
        self.assertEqual(cell.get(cell.app,'r2p.production.program'),0)

    def test_status_not_service_running_and_monitor_failure(self):
        cell=Cell();cell.set(cell.native,'taskRunning',False);cell.v.run('BG_STATUS')
        self.assertFalse(cell.get(cell.app,'r2p.production.running'))
        cell.set(cell.native,'taskRunning',True);cell.v.run('BG_STATUS')
        self.assertTrue(cell.get(cell.app,'r2p.production.running'))
        cell.start();cell.scan(advance=cell.get(cell.c,'serviceTimeout')+1,monitors=False)
        self.assertFalse(cell.get(cell.c,'session'))
        self.assertEqual(cell.get(cell.p,'state'),900)

    def test_area_clear_survives_normal_stop_without_execution_permit(self):
        cell=Cell();cell.inputs['p2r.production.newOperationPermit']=False
        cell.inputs['p2r.production.finishPermit']=False
        cell.set(cell.b,'elevatorExited',True);cell.scan(False)
        self.assertTrue(cell.output('r2p.area.elevator.clear'))
        self.assertFalse(cell.get(cell.c,'allowCommands'))

    def test_recovery_needs_home_consistent_load_and_new_start(self):
        cell=Cell();cell.start();cell.begin(1)
        cell.until(lambda:cell.get(cell.b,'pickupConfirmed') and cell.get(cell.p,'state')==400)
        cell.set(cell.b,'needsRecovery',True);cell.scan()
        self.assertEqual(cell.get(cell.p,'state'),900)
        cell.set(cell.b,'recoveryApproved',True);cell.set(cell.b,'contextChecked',True)
        cell.control('RECOV');self.assertEqual(cell.get(cell.p,'state'),900)
        cell.set(cell.native,'home',True)
        cell.inputs['p2r.link.syncRequest']=True;cell.scan()
        cell.inputs['p2r.link.syncAck']=True;cell.scan()
        cell.inputs['p2r.link.syncRequest']=False;cell.inputs['p2r.link.syncAck']=False;cell.scan()
        cell.set(cell.app,'r2p.production.loadKnown',True)
        cell.control('RECOV')
        self.assertFalse(cell.get(cell.b,'armed'))
        self.assertNotEqual(cell.get(cell.p,'state'),900)
        self.assertEqual(cell.get(cell.p,'remaining'),7)
        before=len(cell.v.motions)
        for _ in range(3):cell.scan()
        self.assertEqual(len(cell.v.motions),before)
        self.assertFalse(cell.get(cell.b,'needsRecovery'))
        cell.start();cell.until(lambda:cell.jobs[0]['placed']==7)

    def test_closed_order_requires_new_context_and_fresh_start(self):
        cell=Cell();cell.start();cell.begin(1)
        cell.until(lambda:cell.event_count('immPickupCompleted')==1);cell.stop()
        cell.until(lambda:cell.get(cell.p,'state')==710)
        cell.inputs['p2r.production.orderActive']=False;cell.scan()
        self.assertEqual(cell.get(cell.p,'state'),900)
        self.assertTrue(cell.get(cell.b,'needsRecovery'))
        before=len(cell.v.motions)
        cell.inputs['p2r.production.orderActive']=True
        cell.inputs['p2r.production.stopRequest']=False
        cell.inputs['p2r.production.newOperationPermit']=True
        cell.start()
        self.assertEqual(len(cell.v.motions),before)

    def test_manual_jog_invalidates_area_release_after_stopping(self):
        cell=Cell();cell.set(cell.b,'sourceExited',True)
        cell.set(cell.native,'home',False);cell.set(cell.native,'autoMode',False)
        cell.set(cell.native,'tpEnabled',True);cell.scan(False)
        self.assertFalse(cell.output('r2p.area.source.clear'))
        self.assertTrue(cell.get(cell.b,'needsRecovery'))
        cell.set(cell.native,'autoMode',True);cell.set(cell.native,'tpEnabled',False)
        cell.scan(False)
        self.assertFalse(cell.output('r2p.area.source.clear'))

    def test_load_loss_preserves_mask_but_invalidates_knowledge(self):
        cell=Cell();cell.start();cell.begin(1)
        cell.until(lambda:cell.get(cell.b,'pickupConfirmed'))
        before=cell.get(cell.app,'r2p.production.loadMask')
        cell.vac_fail.add(1)
        cell.scan();cell.scan()
        self.assertEqual(cell.get(cell.p,'state'),900)
        self.assertEqual(cell.get(cell.app,'r2p.production.loadMask'),before)
        self.assertFalse(cell.get(cell.app,'r2p.production.loadKnown'))

    def test_sample_request_after_stop_is_rejected_without_new_cycle(self):
        cell=Cell();cell.start();cell.stop()
        cell.until(lambda:cell.get(cell.p,'state')==710)
        cell.inputs['p2r.samples.req']=True
        for _ in range(5):cell.scan()
        self.assertEqual(cell.get(cell.c,'sampleResult'),2)
        self.assertEqual(cell.event_count('immPickupCompleted'),0)

    def test_unknown_sequence_state_fails_closed(self):
        cell=Cell();cell.start();cell.set(cell.p,'state',444)
        before=len(cell.v.motions);cell.scan()
        self.assertEqual(cell.get(cell.p,'state'),900)
        self.assertEqual(len(cell.v.motions),before)
        self.assertEqual(cell.get(cell.app,'r2p.production.faultCode'),1102)

    def test_recovery_after_last_group_does_not_pick_same_batch_again(self):
        cell=Cell();cell.start();cell.begin(1)
        cell.until(lambda:cell.get(cell.p,'remaining')==0 and cell.get(cell.b,'pickupConfirmed'))
        cell.set(cell.b,'needsRecovery',True);cell.scan()
        cell.inputs['p2r.link.syncRequest']=True;cell.scan()
        cell.inputs['p2r.link.syncAck']=True;cell.scan()
        cell.inputs['p2r.link.syncRequest']=False;cell.inputs['p2r.link.syncAck']=False;cell.scan()
        cell.set(cell.native,'home',True);cell.set(cell.app,'r2p.production.loadKnown',True)
        cell.set(cell.b,'recoveryApproved',True);cell.set(cell.b,'contextChecked',True)
        cell.control('RECOV')
        self.assertEqual(cell.get(cell.p,'state'),10)
        self.assertFalse(cell.get(cell.b,'batchAssigned'))
        self.assertFalse(cell.get(cell.b,'pickupConfirmed'))
        cell.scan();cell.begin(2);cell.start()
        cell.until(lambda:cell.jobs[-1]['placed']==7)
        self.assertEqual(cell.total('productsPlaced'),14)
        self.assertEqual(cell.event_count('immPickupCompleted'),2)

    def test_full_tray_recovery_requires_terminal_reconciliation(self):
        cell=Cell();cell.start();cell.begin(1)
        cell.until(lambda:not cell.get(cell.b,'batchAssigned') and cell.jobs[0]['placed']==7)
        cell.begin(2)
        cell.until(lambda:cell.get(cell.p,'remaining')==0 and cell.get(cell.b,'pickupConfirmed'))
        cell.set(cell.b,'needsRecovery',True);cell.scan()
        cell.inputs['p2r.link.syncRequest']=True;cell.scan()
        cell.inputs['p2r.link.syncAck']=True;cell.scan()
        cell.inputs['p2r.link.syncRequest']=False;cell.inputs['p2r.link.syncAck']=False;cell.scan()
        cell.set(cell.native,'home',True);cell.set(cell.app,'r2p.production.loadKnown',True)
        cell.set(cell.b,'recoveryApproved',True);cell.set(cell.b,'contextChecked',True)
        cell.control('RECOV')
        self.assertEqual(cell.get(cell.p,'state'),900)
        self.assertEqual(cell.get(cell.app,'r2p.production.faultCode'),1408)
        self.assertEqual(cell.event_count('blisterFinished'),0)

    def test_static_resources_calls_and_real_motion_guard(self):
        declarations={(a['bank'],a['number']) for a in COM['allocations']+RES['allocations']+BOX['allocations']+COMMON['allocations']}
        self.assertEqual(len(declarations),len(COM['allocations'])+len(RES['allocations'])+len(BOX['allocations'])+len(COMMON['allocations']))
        self.assertLessEqual(max(n for b,n in declarations if b=='R'),360)
        self.assertLessEqual(max(n for b,n in declarations if b=='F'),1024)
        for path in [p for d in ['COMM','TRAY','BOX','BG','COMMON'] for p in (ROOT/'ROBOT'/d).glob('*.LS')]:
            text=path.read_text(encoding='ascii')
            text=re.sub(r'((?:PR|R|F|DI|DO|GI|GO|UO|SI|SO)\[\d+(?:,\d+)?):[^\]]+\]',r'\1]',text)
            item_pattern=r'(?:PR\[\d+(?:,\d+)?\]|(?:R|F|DI|DO|GI|GO)\[\d+\]|\$[A-Z0-9_.$\[\]]+)|\d+(?:\.\d+)?|AND|OR|MOD|DIV|<>|>=|<=|[=+*/!<>-]'
            for line in text.splitlines():
                m=re.match(r'\s*\d+:\s*(.*?)\s*;',line)
                if not m or m[1].startswith('!'):continue
                expression=m[1][4:].split('),',1)[0] if m[1].startswith('IF ') else m[1]
                if any(x in expression for x in ['=(','IF ',' AND ',' OR ']):
                    self.assertLessEqual(len(re.findall(item_pattern,expression)),20,(path.name,line))
            for bank,num in re.findall(r'\b(R|F)\[(\d+)\]',text):self.assertIn((bank,int(num)),declarations)
            for callee in re.findall(r'\b(?:CALL|RUN) (\w+)',text):self.assertIn(callee,PROGRAMS)
            if path.stem not in ['PLC_TX','BG_PLC']:
                self.assertNotRegex(text,r'(?:DO|GO)\[\d+\]=')
            if path.stem.startswith('MAIN_'):
                self.assertNotRegex(text,r'CALL (?:RT|RX|RF|RG|RE|RM|XM)_')
                self.assertIn('DEFAULT_GROUP = 1,*,*,*,*;',text)
            code='\n'.join(m[1] for row in text.splitlines() if (m:=re.match(r'\s*\d+:\s*(.*?)\s*;',row)) and not m[1].startswith('!'))
            if path.stem in ['BG_STATUS','BG_GUARD','BG_PLC']:
                self.assertNotRegex(code,r'\b(CALL|RUN|WAIT)\b')
                self.assertNotRegex(code,r'\b[JL] PR\[')
                self.assertIn('DEFAULT_GROUP = *,*,*,*,*;',text)
        # Inspect the offset reached in the actual MAIN on its fourth single-group batch.
        cell=Cell(settings={'qty2':0,'mask2':0});cell.start()
        for n in range(3):
            cell.begin(n+1,count=5);cell.until(lambda:cell.jobs[-1]['placed']==5)
            cell.until(lambda:not cell.get(cell.b,'batchAssigned'))
        cell.begin(4,count=5);cell.until(lambda:cell.get(cell.p,'state')==440)
        self.assertEqual(cell.v.read('PR[29,1]'),100);self.assertEqual(cell.v.read('PR[29,2]'),80)


if __name__=='__main__':unittest.main(verbosity=2)
