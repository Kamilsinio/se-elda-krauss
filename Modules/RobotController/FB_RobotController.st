(* Jeden cykl nadzoru; FB urzadzen i timery wywolywane raz na skan. *)
FUNCTION_BLOCK FB_RobotController
VAR_INPUT
    Cfg : ST_RobotCfg;
    ScannerHealthy : BOOL;
    ImageFresh : BOOL;
    Rx : ST_RobotRxV2;
    Plant : ST_RobotPlant;
END_VAR
VAR_IN_OUT
    Context : ST_RobotContext;
    Proposal : ST_RobotContext;
    Drain : ST_RobotDrain;
    Hmi : ST_RobotHmiV2;
END_VAR
VAR_OUTPUT
    Tx : ST_RobotTxV2;
    Sts : ST_RobotStatus;
END_VAR
VAR
    Link : FB_RobotLink;
    Events : FB_RobotEvents;
    Ledger : FB_RobotCycleLedger;
    Gripper : FB_RobotGripper;
    Areas : FB_RobotAreas;
    Imm : FB_ImmInterface;
    Order : FB_OrderManager;
    Recovery : FB_RobotRecovery;
    Panel : FB_RobotHmi;
    Manual : FB_RobotManual;
    inputEvents : ARRAY[1..10] OF ST_RobotEvent;
    committed : ARRAY[1..10] OF BOOL;
    cylHome : ARRAY[1..5] OF BOOL;
    cylWork : ARRAY[1..5] OF BOOL;
    vacValid : ARRAY[1..5] OF BOOL;
    vacHold : ARRAY[1..5] OF BOOL;
    blowReq : ARRAY[1..5] OF BOOL;
    manualBlowAck : ARRAY[1..5] OF BOOL;
    accessReq : ARRAY[1..3] OF BOOL;
    areaClear : ARRAY[1..3] OF BOOL;
    wasSession : BOOL;
    wasRecovery : BOOL;
    protocolFault : BOOL;
    neutral : BOOL;
    allTasksIdle : BOOL;
    areasClearNow : BOOL;
    programOK : BOOL;
    homeValid : BOOL;
    criticalNow : BOOL;
    processOK : BOOL;
    replyReason : UINT;
    replyComplete : BOOL;
    sampleReq : BOOL;
    sampleState : UINT;
    reconciledIdle : BOOL;
    resumeReady : BOOL;
    sampleEdge : R_TRIG;
    i : INT;
    emptyTx : ST_RobotTxV2;
    emptyEvent : ST_RobotEvent;
END_VAR
Tx := emptyTx;
neutral := TRUE;
FOR i := 1 TO 10 DO inputEvents[i] := emptyEvent; END_FOR;
inputEvents[1].req := Rx.event_blisterPicked_req;
inputEvents[1].stackId := Rx.event_blisterPicked_stackId;
inputEvents[2].req := Rx.event_blisterPlaced_req;
inputEvents[2].stackId := Rx.event_blisterPlaced_stackId;
inputEvents[3].req := Rx.event_blisterFinished_req;
inputEvents[3].stackId := Rx.event_blisterFinished_stackId;
inputEvents[3].index := Rx.event_blisterFinished_index;
inputEvents[4].req := Rx.event_spacerPlaced_req;
inputEvents[4].stackId := Rx.event_spacerPlaced_stackId;
inputEvents[5].req := Rx.event_productsPlaced_req;
inputEvents[5].stackId := Rx.event_productsPlaced_stackId;
inputEvents[5].cycleId := Rx.event_productsPlaced_cycleId;
inputEvents[5].count := Rx.event_productsPlaced_count;
inputEvents[6].req := Rx.event_samplesPlaced_req;
inputEvents[6].stackId := Rx.event_samplesPlaced_stackId;
inputEvents[6].cycleId := Rx.event_samplesPlaced_cycleId;
inputEvents[6].count := Rx.event_samplesPlaced_count;
inputEvents[7].req := Rx.event_layerFinished_req;
inputEvents[7].stackId := Rx.event_layerFinished_stackId;
inputEvents[7].index := Rx.event_layerFinished_index;
inputEvents[8].req := Rx.event_stackFinished_req;
inputEvents[8].stackId := Rx.event_stackFinished_stackId;
inputEvents[9].req := Rx.event_immPickupCompleted_req;
inputEvents[9].stackId := Rx.event_immPickupCompleted_stackId;
inputEvents[9].cycleId := Rx.event_immPickupCompleted_cycleId;
inputEvents[10].req := Rx.event_rejectsPlaced_req;
inputEvents[10].stackId := Rx.event_rejectsPlaced_stackId;
inputEvents[10].cycleId := Rx.event_rejectsPlaced_cycleId;
inputEvents[10].count := Rx.event_rejectsPlaced_count;
cylHome[1] := Rx.cyl_V501_home;
cylWork[1] := Rx.cyl_V501_work;
vacValid[1] := Rx.vac_1_cmdValid;
vacHold[1] := Rx.vac_1_hold;
blowReq[1] := Rx.vac_1_blowReq;
neutral := neutral AND NOT blowReq[1];
cylHome[2] := Rx.cyl_V502_home;
cylWork[2] := Rx.cyl_V502_work;
vacValid[2] := Rx.vac_2_cmdValid;
vacHold[2] := Rx.vac_2_hold;
blowReq[2] := Rx.vac_2_blowReq;
neutral := neutral AND NOT blowReq[2];
cylHome[3] := Rx.cyl_V503_home;
cylWork[3] := Rx.cyl_V503_work;
vacValid[3] := Rx.vac_3_cmdValid;
vacHold[3] := Rx.vac_3_hold;
blowReq[3] := Rx.vac_3_blowReq;
neutral := neutral AND NOT blowReq[3];
cylHome[4] := Rx.cyl_V504_home;
cylWork[4] := Rx.cyl_V504_work;
vacValid[4] := Rx.vac_4_cmdValid;
vacHold[4] := Rx.vac_4_hold;
blowReq[4] := Rx.vac_4_blowReq;
neutral := neutral AND NOT blowReq[4];
cylHome[5] := Rx.cyl_V505_home;
cylWork[5] := Rx.cyl_V505_work;
vacValid[5] := Rx.vac_5_cmdValid;
vacHold[5] := Rx.vac_5_hold;
blowReq[5] := Rx.vac_5_blowReq;
neutral := neutral AND NOT blowReq[5];
accessReq[1] := Rx.area_source_accessReq;
areaClear[1] := Rx.area_source_clear;
accessReq[2] := Rx.area_elevator_accessReq;
areaClear[2] := Rx.area_elevator_clear;
accessReq[3] := Rx.area_storage_accessReq;
areaClear[3] := Rx.area_storage_clear;
FOR i := 1 TO 10 DO neutral := neutral AND NOT inputEvents[i].req; END_FOR;
neutral := neutral AND NOT Rx.samples_ack AND NOT sampleReq;
FOR i := 1 TO 5 DO neutral := neutral AND NOT cylHome[i] AND NOT cylWork[i] AND NOT vacValid[i]; END_FOR;
FOR i := 1 TO 3 DO neutral := neutral AND NOT accessReq[i]; END_FOR;
neutral := neutral AND NOT Rx.imm_req_mouldClose AND NOT Rx.imm_req_mouldFullOpen AND
    NOT Rx.imm_req_ejectorBack AND NOT Rx.imm_req_ejectorForward;
criticalNow := Plant.critical OR NOT Plant.safetyValid OR NOT Plant.safetyOK OR
    (Rx.production_fault AND Rx.production_phase <> 900) OR Rx.production_estopActive OR Rx.production_inputSimulated OR Rx.production_outputSimulated;
processOK := Plant.mappingVerified AND Plant.retentionVerified AND Plant.processOK AND
    Plant.imm.configured AND Plant.imm.valid AND Plant.imm.startSignalValid AND Plant.imm.cycleKnown AND
    Plant.imm.sharedSupplyVerified AND Plant.imm.processInterlocks;
FOR i := 1 TO 5 DO
    processOK := processOK AND Plant.cylinders[i].configured AND Plant.cylinders[i].valid AND
        Plant.cylinders[i].lossPolicyVerified AND Plant.vacuum[i].configured AND Plant.vacuum[i].valid AND
        Plant.vacuum[i].lossPolicyVerified AND Plant.vacuum[i].blowConfigured;
END_FOR;
processOK := processOK AND Cfg.gripper.stable > T#0ms AND Cfg.gripper.motionTimeout > T#0ms AND
    Cfg.gripper.vacuumTimeout > T#0ms AND Cfg.gripper.blowTime > T#0ms AND Cfg.gripper.releaseTimeout > Cfg.gripper.blowTime;
IF Panel.Pending AND Panel.Key > 11 THEN
 replyComplete := Plant.stationCommandComplete;
 replyReason := Plant.stationCommandReason;
END_IF;
IF Panel.Pending AND Panel.Key = 8 AND Plant.stationRecoveryConfirmed THEN replyReason := 0; END_IF;
Panel(DataValid := ScannerHealthy AND ImageFresh, GenerationValid := Plant.retentionVerified,
    Timeout := Cfg.hmiTimeout, Complete := replyComplete, CompleteReason := replyReason,
    Hmi := Hmi, Context := Context);
replyComplete := Panel.Pending AND Panel.Key <= 11;
replyReason := 0;
(* Sesja jest uniewazniana w tym samym skanie co bledy wejscia. *)
Link(Cfg := Cfg.link, ScannerHealthy := ScannerHealthy, ImageFresh := ImageFresh, Rx := Rx,
    Recover := Recovery.Approved, Neutral := neutral,
    Invalidate := Link.Session AND (protocolFault OR criticalNow));
IF wasSession AND NOT Link.Session THEN sampleReq := FALSE; sampleState := 0; END_IF;
IF Recovery.Required AND NOT wasRecovery THEN Proposal := Context; END_IF;
Recovery(Invalidate := (wasSession AND NOT Link.Session) OR criticalNow OR (protocolFault AND NOT Recovery.Required) OR
        (NOT Recovery.Required AND Link.State <> E_RobotLinkState.READY),
    AtRecovery := Link.State = E_RobotLinkState.RECOVERY, Neutral := neutral,
    Cmd := Panel.Cmd, Plant := Plant, Rx := Rx, Proposal := Proposal, Context := Context);
wasRecovery := Recovery.Required;
IF (Panel.Cmd.recover OR Panel.Cmd.newEmptyContext) AND NOT Recovery.Approved THEN replyReason := 80; END_IF;
IF Recovery.Approved THEN protocolFault := FALSE; END_IF;
IF Recovery.Required OR criticalNow OR NOT Link.HeaderValid THEN reconciledIdle := FALSE; resumeReady := FALSE; END_IF;
IF Recovery.Approved THEN resumeReady := TRUE; END_IF;
Events(Session := Link.Session AND NOT Recovery.Required, Reset := Recovery.Approved,
    Rx := inputEvents, Commit := committed, Reject := FALSE);
Ledger(Session := Link.Session AND NOT Recovery.Required, Reset := Recovery.Approved,
    StartConfirmed := Plant.imm.startConfirmed, StartValid := Plant.imm.startSignalValid,
    CyclesKnown := Plant.imm.cycleKnown, Quantity := Context.batchCount,
    RejectBatch := Plant.imm.reject, StackId := Context.stackId, Program := Context.program,
    Pending := Events.Pending, Events := Events.Frozen, TaskDone := Plant.taskDone, Context := Context);
committed := Ledger.Commit;
IF Events.Diag.fault OR Ledger.Fault THEN protocolFault := TRUE; END_IF;
allTasksIdle := TRUE;
FOR i := 1 TO 10 DO allTasksIdle := allTasksIdle AND NOT Context.tasks[i].pending; END_FOR;
areasClearNow := TRUE;
FOR i := 1 TO 3 DO
    IF Link.Session AND accessReq[i] AND Areas.Outp[i].granted THEN Context.areaReserved[i] := TRUE; END_IF;
    areasClearNow := areasClearNow AND NOT Context.areaReserved[i];
END_FOR;
programOK := (Context.program > 0) AND (Rx.production_program = Context.program);
homeValid := Link.Session AND Rx.production_home AND Rx.production_loadKnown;
IF Recovery.Approved AND Ledger.Unsettled = 0 AND allTasksIdle AND Plant.stationEmptyConfirmed AND
   Plant.loadsConfirmed AND Plant.cyclesConfirmed AND Plant.robotContextConfirmed AND Rx.production_loadMask = 0 THEN
    reconciledIdle := TRUE;
END_IF;
Order(Cmd := Panel.Cmd, PhysicalStart := Plant.physicalStart, PhysicalStop := Plant.physicalStop,
    Session := Link.Session, ProgramOK := programOK, HomeValid := homeValid,
    ProcessOK := processOK AND NOT Rx.production_fault AND Rx.production_autoMode AND
        Rx.production_systemReady AND Rx.production_running AND NOT Rx.production_tpEnabled,
    RecoveryRequired := Recovery.Required OR protocolFault OR Plant.stationRecoveryRequired,
    Critical := criticalNow, OperationsSettled := Link.Session AND (Rx.production_operationsSettled OR reconciledIdle) AND
    Plant.imm.settled AND Plant.imm.cycleKnown AND Ledger.Unsettled = 0 AND Events.Idle AND allTasksIdle,
    TransferBusy := Plant.transferBusy, AreasClear := areasClearNow, StationIdle := NOT Plant.transferBusy,
    RecoveryResumeAllowed := resumeReady AND Rx.production_loadKnown AND Plant.robotContextConfirmed AND Plant.loadsConfirmed,
    Context := Context, Drain := Drain);
IF Order.Sts.startAccepted THEN reconciledIdle := FALSE; resumeReady := FALSE; END_IF;
IF Order.Sts.reason <> 0 THEN replyReason := Order.Sts.reason; END_IF;
sampleEdge(CLK := Plant.sampleButton);
IF (Panel.Cmd.samples OR sampleEdge.Q) THEN
    IF Order.Sts.newPermit AND NOT Context.sampleAccepted AND sampleState = 0 AND NOT Rx.samples_ack THEN
        sampleReq := TRUE; sampleState := 10;
    ELSE replyReason := 30;
    END_IF;
END_IF;
IF Link.Session AND sampleState = 10 AND Rx.samples_ack THEN
    IF Rx.samples_result = 1 THEN
        Context.sampleAccepted := TRUE; Context.sampleAwaitCycle := TRUE;
    ELSIF Rx.samples_result <> 2 THEN protocolFault := TRUE;
    END_IF;
    sampleReq := FALSE; sampleState := 20;
END_IF;
IF Link.Session AND sampleState = 20 AND NOT Rx.samples_ack THEN sampleState := 0; END_IF;
FOR i := 1 TO 5 DO manualBlowAck[i] := Gripper.Vac[i].blowAck; END_FOR;
Manual(Cmd := Hmi.manual, SessionId := Hmi.link.udiSessionId, Armed := Hmi.link.xArmed,
    ActivePanel := Hmi.link.uiActivePanel, Permit := Order.Sts.manual AND NOT Context.withRobot AND
    Plant.manualGripperHandover AND homeValid AND areasClearNow AND NOT Plant.transferBusy,
    Timeout := Cfg.hmiTimeout, BlowAck := manualBlowAck);
IF Order.Sts.manual THEN
    cylHome := Manual.CylHome; cylWork := Manual.CylWork;
    vacValid := Manual.VacValid; vacHold := Manual.VacHold; blowReq := Manual.BlowReq;
END_IF;
Gripper(Cfg := Cfg.gripper, Session := Link.Session AND NOT Recovery.Required AND NOT protocolFault,
    Permit := Order.Sts.newPermit OR Order.Sts.finishPermit OR (Order.Sts.manual AND NOT Context.withRobot AND
        Plant.manualGripperHandover AND homeValid AND areasClearNow AND NOT Plant.transferBusy), Critical := criticalNow,
    Reset := Recovery.Approved, CylHome := cylHome, CylWork := cylWork,
    VacValid := vacValid, VacHold := vacHold, BlowReq := blowReq,
    CylIn := Plant.cylinders, VacIn := Plant.vacuum);
IF Gripper.Fault THEN protocolFault := TRUE; END_IF;
Areas(Session := Link.Session AND NOT Recovery.Required AND NOT protocolFault,
    Permit := (Order.Sts.newPermit OR Order.Sts.finishPermit) AND NOT criticalNow,
    Recover := Recovery.Approved, AccessReq := accessReq, Clear := areaClear, Inp := Plant.areas, Context := Context);
Imm(Inp := Plant.imm, Session := Link.Session, HomeValid := homeValid,
    WithRobot := Context.withRobot, Manual := Order.Sts.manual,
    NewPermit := Order.Sts.newPermit AND NOT protocolFault,
    FinishPermit := Order.Sts.finishPermit AND NOT protocolFault,
    Critical := criticalNow OR Recovery.Required OR protocolFault,
    FreeSlot := Ledger.FreeSlot, Unsettled := Ledger.Unsettled,
    ReqClose := Rx.imm_req_mouldClose, ReqOpen := Rx.imm_req_mouldFullOpen,
    ReqBack := Rx.imm_req_ejectorBack, ReqForward := Rx.imm_req_ejectorForward);
Sts.session := Link.Session AND NOT Recovery.Required AND NOT protocolFault AND NOT criticalNow;
Sts.diagnosticValid := Link.HeaderValid;
Sts.recoveryRequired := Recovery.Required OR protocolFault OR criticalNow OR Plant.stationRecoveryRequired;
Sts.allChannelsIdle := Events.Idle AND Gripper.Neutral AND sampleState = 0;
Sts.settled := Order.Sts.settled;
Sts.order := Order.Sts;
Sts.order.newPermit := Order.Sts.newPermit AND Sts.session;
Sts.order.finishPermit := Order.Sts.finishPermit AND Sts.session;
Sts.areas := Areas.Outp;
Sts.cylinders := Gripper.Cyl;
Sts.vacuum := Gripper.Vac;
Sts.imm := Imm.Outp;
Sts.diag := Link.Diag;
IF protocolFault THEN Sts.diag.fault := TRUE; Sts.diag.code := 120; Sts.diag.text := 'Wymagane uzgodnienie protokolu, partii lub chwytaka.'; END_IF;
IF NOT Sts.session THEN
    FOR i := 1 TO 3 DO Sts.areas[i].granted := FALSE; END_FOR;
END_IF;
Tx.link_version := 2;
Tx.link_heartbeat := Link.Heartbeat;
Tx.link_syncRequest := Link.SyncRequest;
Tx.link_syncAck := Link.SyncAck;
Tx.link_ready := Link.LocalReady AND NOT Recovery.Required AND NOT protocolFault AND NOT criticalNow;
Tx.production_orderActive := Context.orderActive;
Tx.production_expectedProgram := Context.program;
Tx.production_withRobot := Context.withRobot;
Tx.production_newOperationPermit := Sts.order.newPermit;
Tx.production_finishPermit := Sts.order.finishPermit;
Tx.production_stopRequest := NOT Sts.order.newPermit;
Tx.production_endOrderRequest := Context.ending;
Tx.production_criticalBlock := criticalNow OR protocolFault;
Tx.production_recoveryRequired := Sts.recoveryRequired;
Tx.production_blockCode := Sts.diag.code;
Tx.production_startToken := Order.Sts.startToken;
Tx.production_stackId := Context.stackId;
Tx.samples_req := sampleReq AND Sts.session;
Tx.imm_valid := Imm.Outp.valid AND Link.HeaderValid;
Tx.imm_reject := Ledger.BatchReject;
Tx.imm_mouldClosed := Plant.imm.mouldClosed;
Tx.imm_mouldOpen := Plant.imm.mouldOpen;
Tx.imm_mouldIntermediate := Plant.imm.mouldIntermediate;
Tx.imm_withRobot := Plant.imm.withRobot;
Tx.imm_ejectorBack := Plant.imm.ejectorBack;
Tx.imm_ejectorForward := Plant.imm.ejectorForward;
Tx.imm_cycleKnown := Plant.imm.cycleKnown AND NOT Ledger.Fault;
Tx.imm_cycleId := Ledger.CycleId;
Tx.imm_unsettledCount := Ledger.Unsettled;
Tx.imm_newCyclePermit := Imm.Outp.newCyclePermit;
Tx.imm_settled := Plant.imm.settled AND Ledger.Unsettled = 0 AND NOT Ledger.Fault;
Tx.imm_reason := Imm.Outp.reason;
Tx.imm_pickupPending := Ledger.PickupPending AND Sts.session;
Tx.imm_batchCount := Ledger.BatchCount;
Tx.imm_applied_mouldClose := Imm.Outp.mouldClose;
Tx.imm_applied_mouldFullOpen := Imm.Outp.mouldFullOpen;
Tx.imm_applied_ejectorBack := Imm.Outp.ejectorBack;
Tx.imm_applied_ejectorForward := Imm.Outp.ejectorForward;
Tx.event_blisterPicked_ack := Events.Ack[1] AND Sts.session;
Tx.event_blisterPlaced_ack := Events.Ack[2] AND Sts.session;
Tx.event_blisterFinished_ack := Events.Ack[3] AND Sts.session;
Tx.event_spacerPlaced_ack := Events.Ack[4] AND Sts.session;
Tx.event_productsPlaced_ack := Events.Ack[5] AND Sts.session;
Tx.event_samplesPlaced_ack := Events.Ack[6] AND Sts.session;
Tx.event_layerFinished_ack := Events.Ack[7] AND Sts.session;
Tx.event_stackFinished_ack := Events.Ack[8] AND Sts.session;
Tx.event_immPickupCompleted_ack := Events.Ack[9] AND Sts.session;
Tx.event_rejectsPlaced_ack := Events.Ack[10] AND Sts.session;
Tx.cyl_V501_valid := Sts.cylinders[1].valid;
Tx.cyl_V501_atHome := Sts.cylinders[1].atHome;
Tx.cyl_V501_atWork := Sts.cylinders[1].atWork;
Tx.cyl_V501_acceptedHome := Sts.cylinders[1].acceptedHome;
Tx.cyl_V501_acceptedWork := Sts.cylinders[1].acceptedWork;
Tx.cyl_V501_busy := Sts.cylinders[1].busy;
Tx.cyl_V501_reason := Sts.cylinders[1].reason;
Tx.vac_1_valid := Sts.vacuum[1].valid;
Tx.vac_1_ok := Sts.vacuum[1].ok;
Tx.vac_1_accepted := Sts.vacuum[1].accepted;
Tx.vac_1_busy := Sts.vacuum[1].busy;
Tx.vac_1_blowAck := Sts.vacuum[1].blowAck;
Tx.vac_1_blowResult := Sts.vacuum[1].blowResult;
Tx.vac_1_reason := Sts.vacuum[1].reason;
Tx.vac_1_holdApplied := Sts.vacuum[1].hold;
Tx.cyl_V502_valid := Sts.cylinders[2].valid;
Tx.cyl_V502_atHome := Sts.cylinders[2].atHome;
Tx.cyl_V502_atWork := Sts.cylinders[2].atWork;
Tx.cyl_V502_acceptedHome := Sts.cylinders[2].acceptedHome;
Tx.cyl_V502_acceptedWork := Sts.cylinders[2].acceptedWork;
Tx.cyl_V502_busy := Sts.cylinders[2].busy;
Tx.cyl_V502_reason := Sts.cylinders[2].reason;
Tx.vac_2_valid := Sts.vacuum[2].valid;
Tx.vac_2_ok := Sts.vacuum[2].ok;
Tx.vac_2_accepted := Sts.vacuum[2].accepted;
Tx.vac_2_busy := Sts.vacuum[2].busy;
Tx.vac_2_blowAck := Sts.vacuum[2].blowAck;
Tx.vac_2_blowResult := Sts.vacuum[2].blowResult;
Tx.vac_2_reason := Sts.vacuum[2].reason;
Tx.vac_2_holdApplied := Sts.vacuum[2].hold;
Tx.cyl_V503_valid := Sts.cylinders[3].valid;
Tx.cyl_V503_atHome := Sts.cylinders[3].atHome;
Tx.cyl_V503_atWork := Sts.cylinders[3].atWork;
Tx.cyl_V503_acceptedHome := Sts.cylinders[3].acceptedHome;
Tx.cyl_V503_acceptedWork := Sts.cylinders[3].acceptedWork;
Tx.cyl_V503_busy := Sts.cylinders[3].busy;
Tx.cyl_V503_reason := Sts.cylinders[3].reason;
Tx.vac_3_valid := Sts.vacuum[3].valid;
Tx.vac_3_ok := Sts.vacuum[3].ok;
Tx.vac_3_accepted := Sts.vacuum[3].accepted;
Tx.vac_3_busy := Sts.vacuum[3].busy;
Tx.vac_3_blowAck := Sts.vacuum[3].blowAck;
Tx.vac_3_blowResult := Sts.vacuum[3].blowResult;
Tx.vac_3_reason := Sts.vacuum[3].reason;
Tx.vac_3_holdApplied := Sts.vacuum[3].hold;
Tx.cyl_V504_valid := Sts.cylinders[4].valid;
Tx.cyl_V504_atHome := Sts.cylinders[4].atHome;
Tx.cyl_V504_atWork := Sts.cylinders[4].atWork;
Tx.cyl_V504_acceptedHome := Sts.cylinders[4].acceptedHome;
Tx.cyl_V504_acceptedWork := Sts.cylinders[4].acceptedWork;
Tx.cyl_V504_busy := Sts.cylinders[4].busy;
Tx.cyl_V504_reason := Sts.cylinders[4].reason;
Tx.vac_4_valid := Sts.vacuum[4].valid;
Tx.vac_4_ok := Sts.vacuum[4].ok;
Tx.vac_4_accepted := Sts.vacuum[4].accepted;
Tx.vac_4_busy := Sts.vacuum[4].busy;
Tx.vac_4_blowAck := Sts.vacuum[4].blowAck;
Tx.vac_4_blowResult := Sts.vacuum[4].blowResult;
Tx.vac_4_reason := Sts.vacuum[4].reason;
Tx.vac_4_holdApplied := Sts.vacuum[4].hold;
Tx.cyl_V505_valid := Sts.cylinders[5].valid;
Tx.cyl_V505_atHome := Sts.cylinders[5].atHome;
Tx.cyl_V505_atWork := Sts.cylinders[5].atWork;
Tx.cyl_V505_acceptedHome := Sts.cylinders[5].acceptedHome;
Tx.cyl_V505_acceptedWork := Sts.cylinders[5].acceptedWork;
Tx.cyl_V505_busy := Sts.cylinders[5].busy;
Tx.cyl_V505_reason := Sts.cylinders[5].reason;
Tx.vac_5_valid := Sts.vacuum[5].valid;
Tx.vac_5_ok := Sts.vacuum[5].ok;
Tx.vac_5_accepted := Sts.vacuum[5].accepted;
Tx.vac_5_busy := Sts.vacuum[5].busy;
Tx.vac_5_blowAck := Sts.vacuum[5].blowAck;
Tx.vac_5_blowResult := Sts.vacuum[5].blowResult;
Tx.vac_5_reason := Sts.vacuum[5].reason;
Tx.vac_5_holdApplied := Sts.vacuum[5].hold;
Tx.area_source_valid := Sts.areas[1].valid;
Tx.area_source_ready := Sts.areas[1].ready;
Tx.area_source_granted := Sts.areas[1].granted;
Tx.area_source_reason := Sts.areas[1].reason;
Tx.area_elevator_valid := Sts.areas[2].valid;
Tx.area_elevator_ready := Sts.areas[2].ready;
Tx.area_elevator_granted := Sts.areas[2].granted;
Tx.area_elevator_reason := Sts.areas[2].reason;
Tx.area_storage_valid := Sts.areas[3].valid;
Tx.area_storage_ready := Sts.areas[3].ready;
Tx.area_storage_granted := Sts.areas[3].granted;
Tx.area_storage_reason := Sts.areas[3].reason;
Hmi.actual.uiProgram := Context.program;
Hmi.actual.uiBatchCount := Context.batchCount;
Hmi.state.uiMode := 20;
IF Order.Sts.manual THEN Hmi.state.uiMode := 10; END_IF;
Hmi.state.uiProduction := Context.program * 10;
Hmi.state.uiOrderState := 0;
IF Context.orderActive THEN Hmi.state.uiOrderState := 10; END_IF;
IF Context.ending THEN Hmi.state.uiOrderState := 20; END_IF;
IF Drain.request THEN Hmi.state.uiOrderState := 30; END_IF;
IF Sts.recoveryRequired THEN Hmi.state.uiOrderState := 90; END_IF;
Hmi.state.uiExecutionState := 0;
IF Order.Sts.canStart THEN Hmi.state.uiExecutionState := 10; END_IF;
IF Order.Sts.running THEN Hmi.state.uiExecutionState := 20; END_IF;
IF Order.Sts.stopping THEN Hmi.state.uiExecutionState := 30; END_IF;
IF Order.Sts.stopped THEN Hmi.state.uiExecutionState := 40; END_IF;
IF Drain.request THEN Hmi.state.uiExecutionState := 50; END_IF;
IF Sts.recoveryRequired THEN Hmi.state.uiExecutionState := 90; END_IF;
Hmi.state.xWorkWithRobot := Context.withRobot;
Hmi.state.xRobotHomeValid := homeValid;
Hmi.state.xCanPhysicalStart := Order.Sts.canStart;
Hmi.state.xOpsSettled := Sts.settled;
Hmi.state.xStationEmpty := Plant.stationEmptyConfirmed;
Hmi.state.xRobotDataValid := Sts.session;
Hmi.state.xRecoveryRequired := Sts.recoveryRequired;
Hmi.state.uiRobotStep := Rx.production_step;
Hmi.state.uiRobotPhase := Rx.production_phase;
Hmi.state.uiRobotWaitCode := Rx.production_waitCode;
Hmi.state.uiRobotFaultCode := Rx.production_faultCode;
Hmi.state.uiUnsettled := Ledger.Unsettled;
Hmi.state.udiGood := Context.goodCount;
Hmi.state.udiSamples := Context.sampleCount;
Hmi.state.udiRejects := Context.rejectCount;
Hmi.state.sStartBlockReason := '';
IF NOT Order.Sts.canStart THEN Hmi.state.sStartBlockReason := 'Sprawdz zlecenie, program, postoj, lacze, konfiguracje i recovery.'; END_IF;
Hmi.permit.orderOpen.xAllowed := Hmi.link.xArmed;
Hmi.permit.orderOpen.sReason := '';
Hmi.permit.orderEnd.xAllowed := Hmi.link.xArmed;
Hmi.permit.orderEnd.sReason := '';
Hmi.permit.modeManual.xAllowed := Hmi.link.xArmed;
Hmi.permit.modeManual.sReason := '';
Hmi.permit.modeAuto.xAllowed := Hmi.link.xArmed;
Hmi.permit.modeAuto.sReason := '';
Hmi.permit.robotEnable.xAllowed := Hmi.link.xArmed;
Hmi.permit.robotEnable.sReason := '';
Hmi.permit.robotDisable.xAllowed := Hmi.link.xArmed;
Hmi.permit.robotDisable.sReason := '';
Hmi.permit.resetFaults.xAllowed := Hmi.link.xArmed;
Hmi.permit.resetFaults.sReason := '';
Hmi.permit.recoveryConfirm.xAllowed := Hmi.link.xArmed;
Hmi.permit.recoveryConfirm.sReason := '';
Hmi.permit.newEmptyContext.xAllowed := Hmi.link.xArmed;
Hmi.permit.newEmptyContext.sReason := '';
Hmi.permit.station5ParamApply.xAllowed := Hmi.link.xArmed;
Hmi.permit.station5ParamApply.sReason := '';
Hmi.permit.samples.xAllowed := Hmi.link.xArmed;
Hmi.permit.samples.sReason := '';
Hmi.permit.orderOpen.xAllowed := Hmi.link.xArmed AND NOT Context.orderActive AND NOT Sts.recoveryRequired AND Sts.settled AND Context.batchCount > 0;
Hmi.permit.orderOpen.xAllowed := Hmi.permit.orderOpen.xAllowed AND NOT Order.Sts.manual AND
    ((Hmi.edit.uiProgram = 1) OR (Hmi.edit.uiProgram = 2));
Hmi.permit.orderEnd.xAllowed := Hmi.link.xArmed AND Context.orderActive AND NOT Context.ending;
Hmi.permit.modeManual.xAllowed := Hmi.link.xArmed AND NOT Order.Sts.running AND Sts.settled AND NOT Drain.runPermit;
Hmi.permit.modeAuto.xAllowed := Hmi.link.xArmed AND NOT Order.Sts.running AND Sts.settled;
Hmi.permit.robotEnable.xAllowed := Hmi.link.xArmed AND NOT Order.Sts.running AND Sts.settled AND homeValid;
Hmi.permit.robotDisable.xAllowed := Hmi.permit.robotEnable.xAllowed;
Hmi.permit.station5ParamApply.xAllowed := Hmi.link.xArmed AND NOT Context.orderActive AND Sts.settled AND NOT Sts.recoveryRequired;
Hmi.permit.recoveryConfirm.xAllowed := Hmi.link.xArmed AND (Link.State = E_RobotLinkState.RECOVERY OR (Plant.stationRecoveryRequired AND Plant.physicalIdle));
Hmi.permit.newEmptyContext.xAllowed := Hmi.permit.recoveryConfirm.xAllowed AND Plant.stationEmptyConfirmed;
Hmi.permit.samples.xAllowed := Hmi.link.xArmed AND Sts.order.newPermit AND NOT Context.sampleAccepted AND sampleState = 0;
IF NOT Hmi.permit.orderOpen.xAllowed THEN Hmi.permit.orderOpen.sReason := 'Wymagany zamkniety uzgodniony postoj, Auto, ilosc i wybor produkcji.'; END_IF;
IF NOT Hmi.permit.modeManual.xAllowed THEN Hmi.permit.modeManual.sReason := 'Najpierw zakoncz Stop i zwolnij obszary robota.'; END_IF;
IF NOT Hmi.permit.robotEnable.xAllowed THEN Hmi.permit.robotEnable.sReason := 'Wymagane aktualne HOME i rozliczone operacje.'; END_IF;
IF NOT Hmi.permit.robotDisable.xAllowed THEN Hmi.permit.robotDisable.sReason := 'Wymagane aktualne HOME i zakonczony Stop.'; END_IF;
IF NOT Hmi.permit.station5ParamApply.xAllowed THEN Hmi.permit.station5ParamApply.sReason := 'Zamknij zlecenie i potwierdz niepracujaca stacje.'; END_IF;
wasSession := Link.Session;
