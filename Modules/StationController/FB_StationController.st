(* Sterowanie stacją bez adresów sprzętowych i bez zapisu do GVL. *)
FUNCTION_BLOCK FB_StationController
VAR_INPUT
 Cfg : ST_StationCfg;
 Inp : ST_StationInputs;
END_VAR
VAR_IN_OUT
 Context : ST_RobotContext;
 Proposal : ST_RobotContext;
 Hmi : ST_RobotHmiV2;
END_VAR
VAR_OUTPUT
 Outp : ST_StationOutputs;
END_VAR
VAR
    (* --- Transportery --- *)
    fbConvTop      : FB_Conveyor;
    fbConvElev     : FB_Conveyor;
    fbConvBottom   : FB_Conveyor;

    (* --- Stopery (pary siłowników) --- *)
    fbStopM2       : FB_StopperPair;   // stoper pozycja 1
    fbStopM3       : FB_StopperPair;   // stoper pozycja 2
    fbStopM4       : FB_StopperPair;   // stoper pozycja 3

    (* --- Pozycjonery --- *)
    fbPosM1        : FB_StopperPair;   // pozycjoner załadunku
    fbPosM5        : FB_StopperPair;   // pozycjoner tacek P3 (para)
    fbV201 : FB_Cyl2Pos;
    fbV202 : FB_Cyl2Pos;
    fbLowerStop5 : FB_StopperPair;
    fbLowerStop6 : FB_StopperPair;
    fbPosM7        : FB_StopperPair;   // pozycjoner kuwet winda
    fbStorage      : FB_Storage;       // V401/V402, oddzielne wyjscia

    (* --- Winda --- *)
    fbElevator     : FB_Elevator;        // instancja FB windy
    uiElevState    : UINT;

    elevCmd        : ST_ElevatorCmd;
    elevIn         : ST_ElevatorIn;
    elevPar        : ST_ElevatorPar;
    elevOut        : ST_ElevatorOut;
    elevStat       : ST_ElevatorStat;

    (* --- Menadżery przepływu --- *)
    fbTopFlow      : FB_TopFlowManager;
    fbBottom567    : FB_BottomAccumulator_567;

    (* --- Sekwencer tacek --- *)
    fbTraySeq      : FB_TraySequencer;

    (* --- Sekwencer kuwet --- *)
    fbBoxSeq       : FB_BoxSequencer;

    (* --- Klamka bezpieczenstwa drzwi celi --- *)
    fbSafetyDoor   : FB_SafetyDoor;

    (* --- Tryb produkcji --- *)
    xModeTray      : BOOL;   // Typ zatwierdzony przy otwarciu zlecenia
    xModeBox       : BOOL;

    (* --- Opróżnianie stacji --- *)
    xEmptyRunning              : BOOL;       // flaga: trwa pełne opróżnianie
    xElevatorLoadPresent       : BOOL;       // zatrzaśnięta informacja o ładunku na windzie

    (* --- Własność i odzyskanie transferu P4->P5 --- *)
    xBottomStepTakeoverActive  : BOOL;
    xBottomRecoveryRequired    : BOOL;
    xBottomTransferOwnerTray   : BOOL;
    xBottomTransferOwnerBox    : BOOL;
    xBottomDonePendingTray     : BOOL;
    xBottomDonePendingBox      : BOOL;
    xBottomReqFromTray         : BOOL;
    xBottomReqFromBox          : BOOL;
    eBottomStateBeforeCall     : E_Bottom567State;

    (* --- Załadunek P1 / M1 --- *)
    rtContainerReady      : R_TRIG;
    xLoadAcceptedPending  : BOOL;
    xLoadAcceptPulseSent  : BOOL;
    xM1RetractForTopFlow  : BOOL;

    (* --- Tryb zatwierdzony przez OrderManager --- *)
    xHmiManualMode       : BOOL;   // TRUE = tryb ręczny z HMI

    (* --- Potwierdzenie transferu na P4 --- *)
    xElevTransferDone : BOOL;

    (* --- Pomocnicze --- *)
    xSafetyOK      : BOOL;          // TRUE gdy Euchner OD potwierdza rygiel drzwi celi
    xGlobalEnable  : BOOL;
    xResetAll      : BOOL;          // globalny reset błędów (tylko HMI Reset)
    xAutoActive    : BOOL;          // TRUE gdy którykolwiek sekwencer jest aktywny

    robot : FB_RobotController;
    plantNow : ST_RobotPlant;
    sourceEmpty : TON;
    elevatorTransfer : TON;
    localUnload : R_TRIG;
    i : INT;
    stackAdvancePending : BOOL;
    topTransferActive : BOOL;
    outputPermit : BOOL;
    stationCoils : FB_StationCoils;
    stationCmd : ARRAY[1..10] OF ST_StationCoil;
    io : FB_StationIo;
    material : FB_StationMaterial;
    transport : FB_StationTransport;
    fbStationDrain : FB_StationDrain;
    alarms : FB_AlarmManager;
    parameters : FB_StationParameters;
    manual : FB_StationManual;
    stationPanel : FB_StationHmi;
    materialIn : ST_StationMaterialIn;
    transportIn : ST_StationTransportIn;
    drainIn : ST_StationDrainIn;
    manualIn : ST_StationManualIn;
    parameterIn : ST_StationParametersIn;
    panelIn : ST_StationHmiIn;
    alarmIn : ST_StationAlarmIn;
    changeAllowed : ARRAY[1..10] OF BOOL;
    manualCoilActive : ARRAY[1..10] OF BOOL;
    productionPermit : BOOL;
    actionPermit : BOOL;
    stationIdle : BOOL;
    stationParametersReady : BOOL;
    lowerWasBusy : BOOL;
    topWasBusy : BOOL;
    manualMoved : BOOL;
    stationCommandReason : UINT;
    stationReset : UINT;

 Drain : ST_RobotDrain;
 taskDoneNext : ARRAY[1..10] OF BOOL;
 stationCommandComplete : BOOL;
 stationCommandResult : UINT;
 reconcileRequired : BOOL;
 stationRecovery : FB_StationRecovery;
 reconciledNow : BOOL;
 physicalIdle : BOOL;
 valveCommandValid : ARRAY[1..10] OF BOOL;
 materialEvents : ARRAY[1..8] OF ST_StationMaterialEvent;
 emptyMaterialEvent : ST_StationMaterialEvent;
 placedSeen : BOOL;
 materialOverflow : BOOL;
 topCompleted : BOOL;
 eventCount : INT;
 immManual : FB_StationManual;
 immManualIn : ST_StationManualIn;
 productionTopId : UDINT;
 productionDischargeId : UDINT;
 productionAdvanceId : UDINT;
 productionElevatorId : UDINT;
 autoGoRequest : R_TRIG;
  outputPolicy : FB_StationOutputPolicy;
  localValveFault : ARRAY[1..10] OF BOOL;
  stationCommandFault : BOOL;
  currentCritical : BOOL;
  appliedVacuumHold : ARRAY[1..5] OF BOOL;
  boxLoadAtFillPosition : BOOL;
  localRestart : R_TRIG;
END_VAR



io(Cfg := Cfg.station_IoCfg, Inp := Inp.station_Inputs);
Outp.station_Io := io.Sts;
localRestart(CLK := Inp.io_di.ind_button_start_process AND Cfg.robot_stationIoBound AND io.Sts.valid);
outputPolicy(Cfg := Cfg, Plant := Inp.robot_Plant, Storage := Inp.robot_storageIn);
stationParametersReady := TRUE;
FOR i := 1 TO 4 DO
 stationParametersReady := stationParametersReady AND Context.stationParameters[i].verified;
END_FOR;
stationIdle := Inp.drive.valid AND Inp.drive.commHealthy AND
 ABS(Inp.drive.actualHz) < Cfg.station_ElevatorCfg.rStopSpeedThreshold_Hz AND Inp.station_Inputs.beltsStopped[1] AND Inp.station_Inputs.beltsStopped[2] AND Inp.station_Inputs.beltsStopped[3] AND NOT fbConvTop.Sts.Running AND NOT fbConvElev.Sts.Running AND NOT fbConvBottom.Sts.Running AND
 NOT elevStat.xBusy AND NOT elevStat.xVfdRunning AND NOT fbTopFlow.Sts.Busy AND NOT fbBottom567.Sts.Busy;

xResetAll := robot.Panel.Cmd.reset AND Hmi.link.xArmed;
fbSafetyDoor.Enable := Cfg.robot_stationIoBound;
fbSafetyDoor.ResetFault := xResetAll;
fbSafetyDoor.Inp.BtnOpenClose := Inp.io_di.ind_button_open_close_robot_cell_doors;
fbSafetyDoor.Inp.DoorLocked := Inp.io_di.ind_robot_cell_doors_locked;
fbSafetyDoor.Inp.DeviceError := NOT Inp.io_di.ind_robot_cell_doors_error;
fbSafetyDoor();
xSafetyOK := Inp.robot_Plant.safetyValid AND Inp.robot_Plant.safetyOK AND fbSafetyDoor.Sts.ReadyToRun;
xGlobalEnable := outputPolicy.Ready AND io.Sts.valid AND Inp.drive.valid AND Inp.drive.commHealthy AND Cfg.station_ElevatorCfgVerified AND Cfg.robot_stationIoBound AND Cfg.robot_stationCoilPolicyVerified AND xSafetyOK AND NOT Inp.io_di.ind_low_pressure;
Outp.io_dout.ctrl_open_robot_cell_doors_lock := fbSafetyDoor.Outp.Q_Unlock;
Outp.io_dout.ctrl_robot_cell_doors_LED_open_close := fbSafetyDoor.Outp.Q_LEDOpenClose;
Outp.io_dout.ctrl_reset_robot_cell_doors := fbSafetyDoor.Outp.Q_DeviceReset;
plantNow := Inp.robot_Plant;
plantNow.taskDone := taskDoneNext;
plantNow.stationCommandComplete := stationCommandComplete;
plantNow.stationCommandReason := stationCommandResult;
plantNow.stationRecoveryConfirmed := stationRecovery.Approved;
plantNow.physicalStart := Inp.io_di.ind_button_start_process AND Cfg.robot_stationIoBound;
(* physicalStop pozostaje osobnym, niewypelnionym bindingiem. Nie uzywamy starego Continue. *)
plantNow.sampleButton := Inp.io_di.ind_button_samples AND Cfg.robot_stationIoBound;
plantNow.processOK := plantNow.processOK AND xGlobalEnable AND alarms.Sts.policyReady AND stationParametersReady;
physicalIdle := Inp.station_Inputs.beltsStopped[1] AND Inp.station_Inputs.beltsStopped[2] AND
 Inp.station_Inputs.beltsStopped[3] AND Inp.drive.valid AND
 ABS(Inp.drive.actualHz) < Cfg.station_ElevatorCfg.rStopSpeedThreshold_Hz;
plantNow.physicalIdle := physicalIdle;
stationIdle := stationIdle AND io.Sts.valid AND
 (fbPosM1.Sts.IsUp OR fbPosM1.Sts.IsDown) AND (fbStopM2.Sts.IsUp OR fbStopM2.Sts.IsDown) AND
 (fbStopM3.Sts.IsUp OR fbStopM3.Sts.IsDown) AND (fbStopM4.Sts.IsUp OR fbStopM4.Sts.IsDown) AND
 (fbPosM5.Sts.IsUp OR fbPosM5.Sts.IsDown) AND (fbPosM7.Sts.IsUp OR fbPosM7.Sts.IsDown) AND
 (fbV201.Sts.AtExt OR fbV201.Sts.AtRet) AND (fbV202.Sts.AtExt OR fbV202.Sts.AtRet) AND
 (fbLowerStop5.Sts.IsUp OR fbLowerStop5.Sts.IsDown) AND (fbLowerStop6.Sts.IsUp OR fbLowerStop6.Sts.IsDown) AND
 Inp.robot_storageIn.Left.valid AND Inp.robot_storageIn.Right.valid AND
 (Inp.robot_storageIn.Left.atHome XOR Inp.robot_storageIn.Left.atWork) AND
 (Inp.robot_storageIn.Right.atHome XOR Inp.robot_storageIn.Right.atWork) AND NOT fbStorage.Sts.Busy;
FOR i := 1 TO 16 DO
 stationIdle := stationIdle AND NOT Hmi.stationManual.positive[i] AND NOT Hmi.stationManual.negative[i] AND
  NOT Hmi.immManual.positive[i] AND NOT Hmi.immManual.negative[i];
END_FOR;
plantNow.stationIdleConfirmed := stationIdle;
plantNow.stationRecoveryRequired := Context.valid AND stationRecovery.Required;
IF material.Sts.known THEN plantNow.stationEmptyConfirmed := material.Sts.emptyConfirmed; END_IF;
plantNow.imm.processInterlocks := plantNow.imm.processInterlocks AND xGlobalEnable;
topTransferActive := fbTopFlow.Sts.State <> E_TopFlowState.IDLE AND fbTopFlow.Sts.State <> E_TopFlowState.INIT;
plantNow.transferBusy := plantNow.transferBusy OR (topTransferActive AND NOT physicalIdle) OR (elevStat.xBusy AND NOT physicalIdle) OR
    (fbBottom567.Sts.Busy AND NOT physicalIdle);
plantNow.critical := plantNow.critical OR outputPolicy.Fault OR alarms.Sts.critical OR stationCoils.Fault OR elevStat.xFault OR fbConvTop.Diag.Fault OR
    fbConvElev.Diag.Fault OR fbConvBottom.Diag.Fault OR fbTraySeq.Diag.Fault OR fbBoxSeq.Diag.Fault;
plantNow.warning := plantNow.warning OR fbPosM1.Diag.Fault OR fbStopM2.Diag.Fault OR
    fbStopM3.Diag.Fault OR fbStopM4.Diag.Fault OR fbPosM5.Diag.Fault OR (fbV201.Diag.Fault OR fbV202.Diag.Fault) OR
    fbPosM7.Diag.Fault OR fbStorage.Diag.Fault;
sourceEmpty(IN := io.Sts.positionValid[3] AND NOT io.Sts.occupied[3] AND NOT fbConvTop.Sts.Running,
    PT := TO_TIME(Context.stationParameters[1].sensorStableMs));
plantNow.sourceEmptyConfirmed := Context.stationParameters[1].sensorStableMs > 0 AND sourceEmpty.Q;
plantNow.areas[1].ready := material.Sts.known AND material.Sts.occupied[3] AND fbTopFlow.Sts.StackReadyAtP3 AND NOT fbConvTop.Sts.Running AND
    NOT fbConvTop.Outp.Q_Fwd AND NOT fbTopFlow.Sts.Busy AND fbTopFlow.Sts.State = E_TopFlowState.IDLE;
boxLoadAtFillPosition := material.Sts.known AND material.Sts.occupied[4] AND
    io.Sts.positionValid[4] AND NOT io.Sts.occupied[4] AND NOT Inp.io_di.ind_elevator_in_bottom_pos AND
    ABS(Inp.drive.actualHz) < Cfg.station_ElevatorCfg.rStopSpeedThreshold_Hz AND
    elevStat.xContainerEdgeReached AND elevStat.xStandstill AND NOT elevStat.xBusy;
plantNow.areas[2].ready := Inp.drive.valid AND Inp.drive.commHealthy AND elevStat.xStandstill AND NOT elevStat.xBusy AND NOT fbConvElev.Sts.Running AND NOT elevStat.xVfdRunning AND
    NOT fbConvElev.Outp.Q_Fwd AND NOT fbConvElev.Outp.Q_Bwd AND
    ((fbTraySeq.Outp.ElevatorReady AND Context.program_ = 2) OR
     (fbBoxSeq.Outp.ElevatorReady AND boxLoadAtFillPosition AND Context.program_ = 1));
plantNow.areas[3].ready := fbStorage.Sts.RobotSideOpen AND fbStorage.Sts.RobotAccessGranted AND NOT fbStorage.Sts.Empty;
plantNow.areas[1].blocked := plantNow.areas[1].blocked OR fbStopM4.Diag.Fault OR fbPosM5.Diag.Fault OR stationCoils.RestartRequired[4] OR stationCoils.RestartRequired[5];
plantNow.areas[2].blocked := plantNow.areas[2].blocked OR (fbV201.Diag.Fault OR fbV202.Diag.Fault) OR fbPosM7.Diag.Fault OR stationCoils.RestartRequired[6] OR stationCoils.RestartRequired[8] OR stationCoils.RestartRequired[7];
plantNow.areas[3].blocked := plantNow.areas[3].blocked OR fbStorage.Diag.Fault;
immManualIn.armed := Hmi.link.xArmed;
immManualIn.sessionId := Hmi.link.udiSessionId; immManualIn.panel := Hmi.link.uiActivePanel;
immManualIn.panelOverride := 201; immManualIn.manual := robot.Sts.order.manual;
immManualIn.idle := physicalIdle; immManualIn.safe := io.Sts.valid AND xSafetyOK AND
 robot.Sts.session AND Inp.robot_Rx.production_home AND NOT Context.withRobot;
immManualIn.timeout := Cfg.robot_Cfg.hmiTimeout;
FOR i := 1 TO 4 DO
 immManualIn.allowPositive[i] := plantNow.imm.configured AND plantNow.imm.valid AND plantNow.imm.processInterlocks;
END_FOR;
immManual(Cmd := Hmi.immManual, Inp := immManualIn);
plantNow.imm.manualMouldClose := immManual.Sts.positive[1] AND NOT immManual.Sts.positive[2];
plantNow.imm.manualFullOpen := immManual.Sts.positive[2] AND NOT immManual.Sts.positive[1];
plantNow.imm.manualEjectorBack := immManual.Sts.positive[3] AND NOT immManual.Sts.positive[4];
plantNow.imm.manualEjectorForward := immManual.Sts.positive[4] AND NOT immManual.Sts.positive[3];
robot(Cfg := Cfg.robot_Cfg, ScannerHealthy := Inp.robot_ScannerHealthy, ImageFresh := Inp.robot_ImageFresh,
    Rx := Inp.robot_Rx, Plant := plantNow, PreviousOutputBlocked := currentCritical,
    AppliedVacuumHold := appliedVacuumHold, Context := Context, Proposal := Proposal,
    Drain := Drain, Hmi := Hmi);
stationRecovery(Invalidate := NOT io.Sts.valid OR NOT Inp.drive.valid OR NOT Inp.drive.commHealthy OR manual.Sts.active OR reconcileRequired OR transport.Sts.fault,
 Blocked := NOT io.Sts.valid OR NOT Inp.drive.valid OR NOT Inp.drive.commHealthy OR manual.Sts.active OR NOT xSafetyOK OR plantNow.critical,
 PhysicalIdle := physicalIdle, Confirm := robot.Panel.Cmd.recover,
 RobotApproved := robot.Recovery.Approved, RobotReady := robot.Sts.session OR robot.Recovery.Approved,
 Proposal := Proposal, Context := Context);
reconciledNow := robot.Recovery.Approved OR stationRecovery.Approved;
Outp.robot_Sts := robot.Sts;
Outp.robot_Tx := robot.Tx;
IF reconciledNow THEN
    Context.station.lastMaterialEventId := Context.station.nextMaterialEventId;
    productionTopId := 0; productionDischargeId := 0; productionAdvanceId := 0; productionElevatorId := 0;
    (* Operator uzgodnil transfery w postoju; odtwarzamy model, nie ruch w polowie kroku. *)
    (* Odtworzenie statusow transportu przez Inp.Reconcile/Restored
       w ich FB; bez zewnetrznego zapisu do VAR_OUTPUT Sts. *)
    xElevatorLoadPresent := Context.elevatorLoadPresent;
    IF Context.orderActive AND NOT Context.ending AND Context.program_ = 1 AND
       Context.boxStep = E_BoxSeqState.WAIT_PALLET_DONE AND NOT Context.tasks[8].pending AND
       Context.elevatorLoadPresent AND NOT elevStat.xContainerEdgeReached AND
       io.Sts.positionValid[4] AND io.Sts.occupied[4] THEN
        (* Po uzgodnieniu przy aktywnym B205 ponownie zmierz krawedz po fizycznym Starcie. *)
        Context.boxStep := E_BoxSeqState.POS_M7_FWD;
    END_IF;
    xBottomDonePendingTray := Context.bottomDonePendingTray;
    xBottomDonePendingBox := Context.bottomDonePendingBox;
    xBottomTransferOwnerTray := FALSE;
    xBottomTransferOwnerBox := FALSE;
END_IF;
FOR i := 1 TO 10 DO taskDoneNext[i] := FALSE; END_FOR;
xResetAll := robot.Panel.Cmd.reset AND Hmi.link.xArmed;
xModeTray := Context.program_ = 2;
xModeBox := Context.program_ = 1;
xHmiManualMode := robot.Sts.order.manual;
xEmptyRunning := Drain.request;
xGlobalEnable := xGlobalEnable AND NOT plantNow.critical AND
 (NOT robot.Sts.recoveryRequired OR (robot.Sts.order.manual AND NOT robot.Recovery.Required AND NOT reconcileRequired));
IF xResetAll AND (fbTopFlow.Diag.Fault OR fbBottom567.Diag.Fault) THEN reconcileRequired := TRUE; END_IF;
productionPermit := robot.Sts.order.newPermit OR robot.Sts.order.finishPermit;
outputPermit := robot.Sts.session AND xGlobalEnable AND (productionPermit OR Drain.runPermit OR
 transport.Sts.owner = E_StationOwner.DRAIN OR transport.Sts.owner = E_StationOwner.LOCAL OR xHmiManualMode);
rtContainerReady(CLK := Inp.io_di.ind_button_container_ready);
IF NOT Context.orderActive OR Context.ending THEN xLoadAcceptedPending := FALSE; END_IF;
IF rtContainerReady.Q AND robot.Sts.order.newPermit AND NOT Context.ending THEN xLoadAcceptedPending := TRUE; END_IF;
fbTopFlow.Cmd.Pos1AcceptedPulse := FALSE;
fbPosM1.Cfg.requireValid := TRUE; fbPosM1.Cfg.requireApplied := TRUE;
fbPosM1.Inp.valid := io.Sts.valid;
fbPosM1.Inp.commandApplied := stationCoils.Applied[1].home OR stationCoils.Applied[1].work;
fbPosM1.Cfg.tStable := TO_TIME(Context.stationParameters[1].sensorStableMs);
fbPosM1.Cfg.tTimeout := TO_TIME(Context.stationParameters[1].actuatorTimeoutMs);
fbStopM2.Cfg.requireValid := TRUE; fbStopM2.Cfg.requireApplied := TRUE;
fbStopM2.Inp.valid := io.Sts.valid;
fbStopM2.Inp.commandApplied := stationCoils.Applied[2].home OR stationCoils.Applied[2].work;
fbStopM2.Cfg.tStable := TO_TIME(Context.stationParameters[1].sensorStableMs);
fbStopM2.Cfg.tTimeout := TO_TIME(Context.stationParameters[1].actuatorTimeoutMs);
fbStopM3.Cfg.requireValid := TRUE; fbStopM3.Cfg.requireApplied := TRUE;
fbStopM3.Inp.valid := io.Sts.valid;
fbStopM3.Inp.commandApplied := stationCoils.Applied[3].home OR stationCoils.Applied[3].work;
fbStopM3.Cfg.tStable := TO_TIME(Context.stationParameters[1].sensorStableMs);
fbStopM3.Cfg.tTimeout := TO_TIME(Context.stationParameters[1].actuatorTimeoutMs);
fbStopM4.Cfg.requireValid := TRUE; fbStopM4.Cfg.requireApplied := TRUE;
fbStopM4.Inp.valid := io.Sts.valid;
fbStopM4.Inp.commandApplied := stationCoils.Applied[4].home OR stationCoils.Applied[4].work;
fbStopM4.Cfg.tStable := TO_TIME(Context.stationParameters[1].sensorStableMs);
fbStopM4.Cfg.tTimeout := TO_TIME(Context.stationParameters[1].actuatorTimeoutMs);
fbPosM5.Cfg.requireValid := TRUE; fbPosM5.Cfg.requireApplied := TRUE;
fbPosM5.Inp.valid := io.Sts.valid;
fbPosM5.Inp.commandApplied := stationCoils.Applied[5].home OR stationCoils.Applied[5].work;
fbPosM5.Cfg.tStable := TO_TIME(Context.stationParameters[1].sensorStableMs);
fbPosM5.Cfg.tTimeout := TO_TIME(Context.stationParameters[1].actuatorTimeoutMs);
fbPosM7.Cfg.requireValid := TRUE; fbPosM7.Cfg.requireApplied := TRUE;
fbPosM7.Inp.valid := io.Sts.valid;
fbPosM7.Inp.commandApplied := stationCoils.Applied[7].home OR stationCoils.Applied[7].work;
fbPosM7.Cfg.tStable := TO_TIME(Context.stationParameters[2].sensorStableMs);
fbPosM7.Cfg.tTimeout := TO_TIME(Context.stationParameters[2].actuatorTimeoutMs);
fbLowerStop5.Cfg.requireValid := TRUE; fbLowerStop5.Cfg.requireApplied := TRUE;
fbLowerStop5.Inp.valid := io.Sts.valid;
fbLowerStop5.Inp.commandApplied := stationCoils.Applied[9].home OR stationCoils.Applied[9].work;
fbLowerStop5.Cfg.tStable := TO_TIME(Context.stationParameters[3].sensorStableMs);
fbLowerStop5.Cfg.tTimeout := TO_TIME(Context.stationParameters[3].actuatorTimeoutMs);
fbLowerStop6.Cfg.requireValid := TRUE; fbLowerStop6.Cfg.requireApplied := TRUE;
fbLowerStop6.Inp.valid := io.Sts.valid;
fbLowerStop6.Inp.commandApplied := stationCoils.Applied[10].home OR stationCoils.Applied[10].work;
fbLowerStop6.Cfg.tStable := TO_TIME(Context.stationParameters[3].sensorStableMs);
fbLowerStop6.Cfg.tTimeout := TO_TIME(Context.stationParameters[3].actuatorTimeoutMs);
fbV201.Cfg.requireValid := TRUE; fbV201.Cfg.requireApplied := TRUE;
fbV201.Inp.valid := io.Sts.valid;
fbV201.Inp.commandApplied := stationCoils.Applied[6].home OR stationCoils.Applied[6].work;
fbV201.Cfg.tStable := TO_TIME(Context.stationParameters[2].sensorStableMs);
fbV201.Cfg.tTimeout := TO_TIME(Context.stationParameters[2].actuatorTimeoutMs);
fbV202.Cfg.requireValid := TRUE; fbV202.Cfg.requireApplied := TRUE;
fbV202.Inp.valid := io.Sts.valid;
fbV202.Inp.commandApplied := stationCoils.Applied[8].home OR stationCoils.Applied[8].work;
fbV202.Cfg.tStable := TO_TIME(Context.stationParameters[2].sensorStableMs);
fbV202.Cfg.tTimeout := TO_TIME(Context.stationParameters[2].actuatorTimeoutMs);

// 3) STOPERY — konfiguracja i mapowanie I/O
// ================================================================

// --- M2: stoper pozycja 1 ---
fbStopM2.Enable := outputPermit;
fbStopM2.ResetFault := xResetAll;
fbStopM2.Inp.ind_1_fwd := Inp.io_di.ind_M2_1_fwd;
fbStopM2.Inp.ind_2_fwd := Inp.io_di.ind_M2_2_fwd;
fbStopM2.Inp.ind_1_bwd := Inp.io_di.ind_M2_1_bwd;
fbStopM2.Inp.ind_2_bwd := Inp.io_di.ind_M2_2_bwd;
// HoldUp ustawiany przez TopFlowManager (poniżej)

// --- M3: stoper pozycja 2 ---
fbStopM3.Enable := outputPermit;
fbStopM3.ResetFault := xResetAll;
fbStopM3.Inp.ind_1_fwd := Inp.io_di.ind_M3_1_fwd;
fbStopM3.Inp.ind_2_fwd := Inp.io_di.ind_M3_2_fwd;
fbStopM3.Inp.ind_1_bwd := Inp.io_di.ind_M3_1_bwd;
fbStopM3.Inp.ind_2_bwd := Inp.io_di.ind_M3_2_bwd;

// --- M4: stoper pozycja 3 ---
fbStopM4.Enable := outputPermit;
fbStopM4.ResetFault := xResetAll;
fbStopM4.Inp.ind_1_fwd := Inp.io_di.ind_M4_1_fwd;
fbStopM4.Inp.ind_2_fwd := Inp.io_di.ind_M4_2_fwd;
fbStopM4.Inp.ind_1_bwd := Inp.io_di.ind_M4_1_bwd;
fbStopM4.Inp.ind_2_bwd := Inp.io_di.ind_M4_2_bwd;


// ================================================================
// 4) POZYCJONERY — konfiguracja i mapowanie I/O
// ================================================================

// --- M1: pozycjoner załadunku ---
fbPosM1.Enable := outputPermit;
fbPosM1.ResetFault := xResetAll;
fbPosM1.Inp.ind_1_fwd := Inp.io_di.ind_M1_1_fwd;
fbPosM1.Inp.ind_2_fwd := Inp.io_di.ind_M1_2_fwd;
fbPosM1.Inp.ind_1_bwd := Inp.io_di.ind_M1_1_bwd;
fbPosM1.Inp.ind_2_bwd := Inp.io_di.ind_M1_2_bwd;
// HoldUp ustawiany przez logikę załadunku (poniżej)

IF xLoadAcceptedPending AND (NOT xLoadAcceptPulseSent) AND
   xGlobalEnable AND (NOT xResetAll) AND
   (NOT xHmiManualMode) AND (NOT xEmptyRunning) AND
   io.Sts.occupied[1] AND fbTopFlow.Sts.Pos1SensorStable AND
   fbPosM1.HoldUp AND fbStopM2.HoldUp AND
   fbPosM1.Sts.IsUp AND fbStopM2.Sts.IsUp AND
   (NOT fbPosM1.Diag.Fault) AND (NOT fbStopM2.Diag.Fault) AND
   (NOT fbTopFlow.Diag.Fault) THEN
    fbTopFlow.Cmd.Pos1AcceptedPulse := TRUE;
END_IF;
xLoadAcceptPulseSent := fbTopFlow.Cmd.Pos1AcceptedPulse;

// --- M5: pozycjoner tacek P3 (para) ---
fbPosM5.Enable := outputPermit;
fbPosM5.ResetFault := xResetAll;
fbPosM5.Inp.ind_1_fwd := Inp.io_di.ind_M5_1_fwd;
fbPosM5.Inp.ind_2_fwd := Inp.io_di.ind_M5_2_fwd;
fbPosM5.Inp.ind_1_bwd := Inp.io_di.ind_M5_1_bwd;
fbPosM5.Inp.ind_2_bwd := Inp.io_di.ind_M5_2_bwd;
// HoldUp zarządzane przez TopFlowManager (bramka tacek P3 w trybie tray)

(* Dwa niezalezne zawory i potwierdzenia; Auto zadaje ten sam cel. *)
fbV201.Enable := outputPermit; fbV202.Enable := outputPermit;
fbV201.ResetFault := xResetAll; fbV202.ResetFault := xResetAll;
fbV201.Inp := Inp.station_Inputs.v201;
fbV201.Inp.valid := io.Sts.valid;
fbV201.Inp.commandApplied := stationCoils.Applied[6].home OR stationCoils.Applied[6].work; fbV202.Inp := Inp.station_Inputs.v202;
fbV202.Inp.valid := io.Sts.valid;
fbV202.Inp.commandApplied := stationCoils.Applied[8].home OR stationCoils.Applied[8].work;

// --- M7: pozycjoner kuwet winda ---
fbPosM7.Enable := outputPermit;
fbPosM7.ResetFault := xResetAll;
fbPosM7.Inp.ind_1_fwd := Inp.io_di.ind_M7_fwd;
fbPosM7.Inp.ind_2_fwd := Inp.io_di.ind_M7_fwd;
fbPosM7.Inp.ind_1_bwd := Inp.io_di.ind_M7_bwd;
fbPosM7.Inp.ind_2_bwd := Inp.io_di.ind_M7_bwd;

// --- Magazyn przekladek / M8 ---
// FB_Storage jest mapowany po wywolaniu sekwencerow i odczycie zadania robota.


// ================================================================
// 5) TRANSPORTERY — konfiguracja i blokady programowe
// ================================================================

// --- Górny transporter (jednokierunkowy w normalnej pracy, FWD = do robota) ---
fbConvTop.Cfg.tReversalDelay := TO_TIME(Context.stationParameters[1].stopDelayMs);
fbConvTop.Cfg.requireStoppedFeedback := TRUE;
fbConvTop.Inp.feedbackValid := io.Sts.valid;
fbConvTop.Inp.stopped := Inp.station_Inputs.beltsStopped[1];
fbConvTop.Inp.Enable := xGlobalEnable;
fbConvTop.Inp.SafetyOK := xSafetyOK;
fbConvTop.Cmd.ResetFault := xResetAll;
// RunFwd zarządzany wyłącznie przez TopFlowManager.
// Górny transporter nie ma osobnego wyjścia BWD w GVL_IO — jest jednokierunkowy sprzętowo

// --- Transporter windy (dwukierunkowy: IN = do robota, OUT = do rozładunku) ---
fbConvElev.Cfg.tReversalDelay := TO_TIME(Context.stationParameters[2].stopDelayMs);
fbConvElev.Cfg.requireStoppedFeedback := TRUE;
fbConvElev.Inp.feedbackValid := io.Sts.valid;
fbConvElev.Inp.stopped := Inp.station_Inputs.beltsStopped[2];
fbConvElev.Inp.Enable := xGlobalEnable;
fbConvElev.Inp.SafetyOK := xSafetyOK;
fbConvElev.Cmd.ResetFault := xResetAll;

// --- Dolny transporter (dwukierunkowy: FWD = do wyjścia, BWD = do windy) ---
fbConvBottom.Cfg.tReversalDelay := TO_TIME(Context.stationParameters[3].stopDelayMs);
fbConvBottom.Cfg.requireStoppedFeedback := TRUE;
fbConvBottom.Inp.feedbackValid := io.Sts.valid;
fbConvBottom.Inp.stopped := Inp.station_Inputs.beltsStopped[3];
fbConvBottom.Inp.Enable := xGlobalEnable;
fbConvBottom.Inp.SafetyOK := xSafetyOK;
fbConvBottom.Cmd.ResetFault := xResetAll;


// ================================================================
// 6) WINDA — konfiguracja i mapowanie wejść
// ================================================================

// Mapowanie wejść windy
elevIn.xInPos1 := Inp.io_di.ind_elevator_in_top_pos;
elevIn.xInPos2 := Inp.io_di.ind_elevator_in_intermediate_top_pos;
elevIn.xInPos3 := Inp.io_di.ind_elevator_in_intermediate_bottom_pos;
elevIn.xInPos4 := Inp.io_di.ind_elevator_in_bottom_pos;
elevIn.xContainerInPos4 := io.Sts.occupied[4];
elevIn.xSafetyOk := xSafetyOK;
elevIn.xDoorClosed := fbSafetyDoor.Sts.DoorClosed;
elevIn.drive := Inp.drive;
elevIn.xCommOk := Inp.robot_vfdCommHealthy; // Binding diagnostyki ATV320, GAP-06.
elevIn.stVfdRx.uiOutFreq_0p1Hz_3202 := WORD_TO_UINT(Inp.io_di.ATV320_currentFreq);

(* Konfiguracja napedu pochodzi z zatwierdzonego adaptera, nie ze stalych testowych. *)
elevPar := Cfg.station_ElevatorCfg;
elevPar.requireDriveFeedback := TRUE;
elevPar.tStandstillStable := TO_TIME(Context.stationParameters[2].sensorStableMs);
elevPar.tMoveTimeout := TO_TIME(Context.stationParameters[2].moveTimeoutMs);
elevPar.tClearPos4Timeout := TO_TIME(Context.stationParameters[2].moveTimeoutMs);
elevPar.tStopTimeout := TO_TIME(Context.stationParameters[2].stopDelayMs);
// Komendy windy z TraySequencer (poniżej)
// Tryb AUTO tylko poza ręcznym — w ręcznym sekcja 2 ustawia MANUAL
IF NOT xHmiManualMode THEN
    elevCmd.eMode := E_ElevatorMode.AUTO;
    elevCmd.xStop := FALSE;
    elevCmd.xAutoGo := FALSE;
    elevCmd.xAutoStop := FALSE;
    elevCmd.eAutoTarget := E_ElevatorTarget.NONE;
    elevCmd.xManUp := FALSE;
    elevCmd.xManDown := FALSE;
    elevCmd.xManFast := FALSE;
END_IF;
elevCmd.rSpeedFast_Hz := Context.stationParameters[2].fastHz;
elevCmd.rSpeedSlow_Hz := Context.stationParameters[2].slowHz;
elevCmd.xReset := xResetAll;



// ================================================================
// 7) TOP FLOW MANAGER — zarządza buforem P1-P3
// ================================================================

fbTopFlow.Cmd.SafetyOK := xGlobalEnable;
fbTopFlow.Cmd.ResetFault := xResetAll;
fbTopFlow.Cmd.EmptyingMode := xEmptyRunning;
// TrayMode: TRUE = produkcja tacek (M5 bramka, brak TG_ELEV)
//           FALSE = produkcja kuwet (TG_ELEV możliwe, dwa transportery jednocześnie)
fbTopFlow.Cmd.TrayMode := xModeTray;

// Odtworzenie zajętości ma jawne wejście, ważność i potwierdzony postój.
fbTopFlow.Inp.Valid := io.Sts.valid;
fbTopFlow.Inp.Reconcile := reconciledNow;
fbTopFlow.Inp.Restored[1] := Context.occupied[1];
fbTopFlow.Inp.Restored[2] := Context.occupied[2];
fbTopFlow.Inp.Restored[3] := Context.occupied[3];
fbTopFlow.Inp.BeltsStopped := Inp.station_Inputs.beltsStopped[1] AND Inp.station_Inputs.beltsStopped[2];

// Mapowanie czujników
fbTopFlow.Inp.sPos1_raw := io.Sts.occupied[1];
fbTopFlow.Inp.sPos2_raw := io.Sts.occupied[2];
fbTopFlow.Inp.sPos3_raw := io.Sts.occupied[3];
fbTopFlow.Inp.sPos4_raw := io.Sts.occupied[4];
fbTopFlow.Inp.TopConveyorRunning := NOT Inp.station_Inputs.beltsStopped[1];
fbTopFlow.Inp.LoadBarrierValid := io.Sts.barrierValid;
fbTopFlow.Inp.LoadBarrierBlocked := io.Sts.barrierBlocked;
fbTopFlow.Inp.DeviceWarning := fbPosM1.Diag.Fault OR fbStopM2.Diag.Fault OR fbStopM3.Diag.Fault OR fbStopM4.Diag.Fault OR fbPosM5.Diag.Fault OR stationCoils.RestartRequired[1] OR stationCoils.RestartRequired[2] OR stationCoils.RestartRequired[3] OR stationCoils.RestartRequired[4] OR stationCoils.RestartRequired[5];
fbTopFlow.Cfg.tSensorStable := TO_TIME(Context.stationParameters[1].sensorStableMs);
fbTopFlow.Cfg.tMotorStopDelay := TO_TIME(Context.stationParameters[1].stopDelayMs);
fbTopFlow.Cfg.tMoveTimeout := TO_TIME(Context.stationParameters[1].moveTimeoutMs);

// Mapowanie statusów stoperów
fbTopFlow.Inp.StopP1_IsUp := fbStopM2.Sts.IsUp;
fbTopFlow.Inp.StopP1_IsDown := fbStopM2.Sts.IsDown;
fbTopFlow.Inp.StopP2_IsUp := fbStopM3.Sts.IsUp;
fbTopFlow.Inp.StopP2_IsDown := fbStopM3.Sts.IsDown;
fbTopFlow.Inp.StopP3_IsUp := fbStopM4.Sts.IsUp;
fbTopFlow.Inp.StopP3_IsDown := fbStopM4.Sts.IsDown;

// Feedback z M5 (bramka tacek P3) — niezbędny dla TopFlow w trybie TrayMode
fbTopFlow.Inp.M5_IsUp := fbPosM5.Sts.IsUp;
fbTopFlow.Inp.M5_IsDown := fbPosM5.Sts.IsDown;
elevatorTransfer(IN := io.Sts.occupied[4] AND Cfg.robot_stationIoBound,
    PT := TO_TIME(Context.stationParameters[2].sensorStableMs));
xElevTransferDone := elevatorTransfer.Q AND Context.stationParameters[2].sensorStableMs > 0;
fbTopFlow.Inp.Elev_TransferDone := xElevTransferDone;

// Komendy do TopFlow sa wybierane po wywolaniu sekwencerow.
// Sam fbTopFlow() jest wywolany pod koniec skanu, przed FB wykonawczymi.


// ================================================================
// 8) BOTTOM ACCUMULATOR — rozładunek P5-P7
// ================================================================

fbBottom567.Cmd.SafetyOK := xGlobalEnable;
fbBottom567.Cmd.ResetFault := xResetAll;

fbBottom567.Inp.sPos5_raw := io.Sts.occupied[5];
fbBottom567.Inp.sPos6_raw := io.Sts.occupied[6];
fbBottom567.Inp.sPos7_raw := io.Sts.occupied[7];
fbBottom567.Inp.sElevatorEmptied_raw := Inp.io_di.ind_elevator_emptied;
fbBottom567.Inp.Valid := io.Sts.valid AND Inp.station_Inputs.lowerFeedbackValid;
fbBottom567.Inp.Reconcile := reconciledNow;
fbBottom567.Inp.Restored[1] := Context.occupied[5];
fbBottom567.Inp.Restored[2] := Context.occupied[6];
fbBottom567.Inp.Restored[3] := Context.occupied[7];
fbBottom567.Inp.BeltsStopped := Inp.station_Inputs.beltsStopped[2] AND Inp.station_Inputs.beltsStopped[3];
fbBottom567.Inp.Stop5Holding := fbLowerStop5.Sts.IsUp;
fbBottom567.Inp.Stop5Released := fbLowerStop5.Sts.IsDown;
fbBottom567.Inp.Stop6Holding := fbLowerStop6.Sts.IsUp;
fbBottom567.Inp.Stop6Released := fbLowerStop6.Sts.IsDown;
fbBottom567.Inp.StopWarning := fbLowerStop5.Diag.Fault OR fbLowerStop6.Diag.Fault OR stationCoils.RestartRequired[9] OR stationCoils.RestartRequired[10];
fbBottom567.Cfg.stopsConfigured := Inp.station_Inputs.lowerFeedbackValid AND Cfg.robot_stationCoilPolicyVerified;
fbBottom567.Cfg.tSensorStable := TO_TIME(Context.stationParameters[3].sensorStableMs);
fbBottom567.Cfg.tMotorStopDelay := TO_TIME(Context.stationParameters[3].stopDelayMs);
fbBottom567.Cfg.tStepTimeout := TO_TIME(Context.stationParameters[3].moveTimeoutMs);



// ================================================================

(* Sekwencery odbieraja trwale zadania; nie surowe impulsy z sieci. *)
fbTopFlow.Cmd.EnableAuto := FALSE;
fbTopFlow.Inp.Elev_RequestFeed := FALSE;
fbTopFlow.Inp.Elev_CanAccept := FALSE;
fbTopFlow.Inp.StackConsumedAtP3 := FALSE;
fbBottom567.Cmd.EnableAuto := FALSE;
fbBottom567.Cmd.DischargeReq := FALSE;
fbBottom567.Cmd.EmptyBottomHold := FALSE;
fbConvTop.Cmd.RunFwd := FALSE;
fbConvTop.Cmd.RunBwd := FALSE;
fbConvElev.Cmd.RunFwd := FALSE;
fbConvElev.Cmd.RunBwd := FALSE;
fbConvBottom.Cmd.RunFwd := FALSE;
fbConvBottom.Cmd.RunBwd := FALSE;

fbTraySeq.Cfg.tP4ConfirmTimeout := TO_TIME(Context.stationParameters[2].moveTimeoutMs);
fbTraySeq.Cmd.Enable := xModeTray AND NOT xHmiManualMode AND Context.orderActive;
fbTraySeq.Cmd.NewOperations := robot.Sts.order.newPermit;
fbTraySeq.Cmd.FinishOperations := robot.Sts.order.finishPermit;
fbTraySeq.Cmd.StopRequested := robot.Tx.production_stopRequest;
fbTraySeq.Cmd.RecoveryRequired := robot.Sts.recoveryRequired;
fbTraySeq.Cmd.SafetyOK := xGlobalEnable;
fbTraySeq.Cmd.ResetFault := xResetAll;
fbTraySeq.Inp.TopFlow_OccP3 := fbTopFlow.Sts.OccP3;
fbTraySeq.Inp.TopFlow_StackReadyAtP3 := fbTopFlow.Sts.StackReadyAtP3;
fbTraySeq.Inp.TopFlow_ElevDeliveredAtP4 := fbTopFlow.Sts.ElevDeliveredAtP4;
fbTraySeq.Inp.TopFlow_Busy := fbTopFlow.Sts.Busy;
fbTraySeq.Inp.TopFlow_Fault := fbTopFlow.Diag.Fault;
fbTraySeq.Inp.Elev_AtTop := elevStat.ePos = E_ElevatorPos.posTop;
fbTraySeq.Inp.Elev_AtBottom := elevStat.ePos = E_ElevatorPos.posBottom;
fbTraySeq.Inp.Elev_AtTarget := elevStat.xAtTarget;
fbTraySeq.Inp.Elev_Busy := elevStat.xBusy;
fbTraySeq.Inp.Elev_CommandReady := elevStat.eState = E_ElevatorState.IDLE;
fbTraySeq.Inp.Elev_Fault := elevStat.xFault;
fbTraySeq.Inp.Bottom_CanAccept := fbBottom567.Sts.CanAcceptFromElev;
fbTraySeq.Inp.Bottom_Busy := fbBottom567.Sts.Busy;
fbTraySeq.Inp.Bottom_Fault := fbBottom567.Diag.Fault;
fbTraySeq.Inp.Bottom_DischargeDonePulse := xBottomDonePendingTray;
fbTraySeq.Inp.ind_container_in_pos_4 := io.Sts.occupied[4];
fbTraySeq.Inp.PositionerHome := (fbV201.Sts.AtRet AND fbV202.Sts.AtRet);
fbTraySeq.Inp.PositionerWork := (fbV201.Sts.AtExt AND fbV202.Sts.AtExt);
fbTraySeq.Inp.Session := robot.Sts.session;
fbTraySeq.Inp.RobotReserved := robot.Sts.areas[2].reserved;
fbTraySeq.Inp.RobotClear := robot.Sts.session AND Inp.robot_Rx.area_elevator_clear;
fbTraySeq.Inp.TaskPicked := Context.tasks[1].pending;
fbTraySeq.Inp.TaskPlaced := Context.tasks[2].pending;
fbTraySeq.Inp.TaskFinished := Context.tasks[3].pending;
fbTraySeq.Inp.TaskStack := Context.tasks[8].pending;
fbTraySeq.Inp.SourceEmptyConfirmed := plantNow.sourceEmptyConfirmed;
fbTraySeq.Inp.Warning := fbV201.Diag.Fault OR fbV202.Diag.Fault OR fbPosM7.Diag.Fault OR stationCoils.RestartRequired[6] OR stationCoils.RestartRequired[8] OR stationCoils.RestartRequired[7];
fbTraySeq(Context := Context);

IF xModeTray THEN
    fbTopFlow.Cmd.EnableAuto := fbTraySeq.Outp.TopFlow_Enable;
    fbTopFlow.Inp.Elev_RequestFeed := fbTraySeq.Outp.TopFlow_Elev_RequestFeed;
    fbTopFlow.Inp.Elev_CanAccept := fbTraySeq.Outp.TopFlow_Elev_CanAccept;
    fbTopFlow.Inp.StackConsumedAtP3 := fbTraySeq.Outp.TopFlow_StackConsumed;
    elevCmd.xAutoGo := fbTraySeq.Outp.Elev_AutoGo;
    elevCmd.xAutoStop := fbTraySeq.Outp.Elev_Stop;
    elevCmd.eAutoTarget := fbTraySeq.Outp.Elev_AutoTarget;
    fbV201.CmdExtend := fbTraySeq.Outp.M6_Extend;
    fbV202.CmdExtend := fbTraySeq.Outp.M6_Extend;
    fbBottom567.Cmd.EnableAuto := fbTraySeq.Outp.Bottom_Enable;
    fbBottom567.Cmd.DischargeReq := fbTraySeq.Outp.Bottom_DischargeReq;
    IF fbTraySeq.Outp.ConsumeStack THEN
        taskDoneNext[8] := TRUE;
        xBottomDonePendingTray := FALSE;
        xBottomTransferOwnerTray := FALSE;
    END_IF;
    IF fbTraySeq.Outp.NewStackReady AND Context.stackFull THEN stackAdvancePending := TRUE; END_IF;
END_IF;

fbBoxSeq.Cmd.Enable := xModeBox AND NOT xHmiManualMode AND Context.orderActive;
fbBoxSeq.Cmd.NewOperations := robot.Sts.order.newPermit;
fbBoxSeq.Cmd.FinishOperations := robot.Sts.order.finishPermit;
fbBoxSeq.Cmd.StopRequested := robot.Tx.production_stopRequest;
fbBoxSeq.Cmd.RecoveryRequired := robot.Sts.recoveryRequired;
fbBoxSeq.Cmd.SafetyOK := xGlobalEnable;
fbBoxSeq.Cmd.ResetFault := xResetAll;
fbBoxSeq.Inp.TopFlow_OccP3 := fbTopFlow.Sts.OccP3;
fbBoxSeq.Inp.TopFlow_StackReadyAtP3 := fbTopFlow.Sts.StackReadyAtP3;
fbBoxSeq.Inp.TopFlow_ElevDeliveredAtP4 := fbTopFlow.Sts.ElevDeliveredAtP4;
fbBoxSeq.Inp.TopFlow_Busy := fbTopFlow.Sts.Busy;
fbBoxSeq.Inp.TopFlow_Fault := fbTopFlow.Diag.Fault;
fbBoxSeq.Inp.Elev_AtTop := elevStat.ePos = E_ElevatorPos.posTop;
fbBoxSeq.Inp.Elev_AtBottom := elevStat.ePos = E_ElevatorPos.posBottom;
fbBoxSeq.Inp.Elev_AtTarget := elevStat.xAtTarget;
fbBoxSeq.Inp.LoadAtFillPosition := boxLoadAtFillPosition;
fbBoxSeq.Inp.Elev_Busy := elevStat.xBusy;
fbBoxSeq.Inp.Elev_CommandReady := elevStat.eState = E_ElevatorState.IDLE;
fbBoxSeq.Inp.Elev_Fault := elevStat.xFault;
fbBoxSeq.Inp.Bottom_CanAccept := fbBottom567.Sts.CanAcceptFromElev;
fbBoxSeq.Inp.Bottom_Busy := fbBottom567.Sts.Busy;
fbBoxSeq.Inp.Bottom_Fault := fbBottom567.Diag.Fault;
fbBoxSeq.Inp.Bottom_DischargeDonePulse := xBottomDonePendingBox;
fbBoxSeq.Inp.ind_container_in_pos_4 := io.Sts.occupied[4];
fbBoxSeq.Inp.PositionerHome := fbPosM7.Sts.IsDown;
fbBoxSeq.Inp.PositionerWork := fbPosM7.Sts.IsUp;
fbBoxSeq.Inp.Session := robot.Sts.session;
fbBoxSeq.Inp.RobotReserved := robot.Sts.areas[2].reserved;
fbBoxSeq.Inp.RobotClear := robot.Sts.session AND Inp.robot_Rx.area_elevator_clear;
fbBoxSeq.Inp.TaskPicked := Context.tasks[1].pending;
fbBoxSeq.Inp.TaskPlaced := Context.tasks[2].pending;
fbBoxSeq.Inp.TaskFinished := Context.tasks[3].pending;
fbBoxSeq.Inp.TaskStack := Context.tasks[8].pending;
fbBoxSeq.Inp.SourceEmptyConfirmed := plantNow.sourceEmptyConfirmed;
fbBoxSeq.Inp.Warning := fbPosM7.Diag.Fault OR stationCoils.RestartRequired[7];
fbBoxSeq(Context := Context);

IF xModeBox THEN
    fbTopFlow.Cmd.EnableAuto := fbBoxSeq.Outp.TopFlow_Enable;
    fbTopFlow.Inp.Elev_RequestFeed := fbBoxSeq.Outp.TopFlow_Elev_RequestFeed;
    fbTopFlow.Inp.Elev_CanAccept := fbBoxSeq.Outp.TopFlow_Elev_CanAccept;
    fbTopFlow.Inp.StackConsumedAtP3 := fbBoxSeq.Outp.TopFlow_StackConsumed;
    elevCmd.xAutoGo := fbBoxSeq.Outp.Elev_AutoGo;
    elevCmd.xAutoStop := fbBoxSeq.Outp.Elev_Stop;
    elevCmd.eAutoTarget := fbBoxSeq.Outp.Elev_AutoTarget;
    fbPosM7.HoldUp := fbBoxSeq.Outp.M7_Extend;
    fbBottom567.Cmd.EnableAuto := fbBoxSeq.Outp.Bottom_Enable;
    fbBottom567.Cmd.DischargeReq := fbBoxSeq.Outp.Bottom_DischargeReq;
    IF fbBoxSeq.Outp.ConsumeStack THEN
        taskDoneNext[8] := TRUE;
        xBottomDonePendingBox := FALSE;
        xBottomTransferOwnerBox := FALSE;
    END_IF;
    IF fbBoxSeq.Outp.NewStackReady AND Context.stackFull THEN stackAdvancePending := TRUE; END_IF;
END_IF;

IF fbTraySeq.Outp.ConsumePicked THEN taskDoneNext[1] := TRUE; END_IF;
(* Opoznione potwierdzenie pustego zrodla nie ginie wraz z odbiorem zdarzenia picked. *)
IF plantNow.sourceEmptyConfirmed AND robot.Sts.session AND NOT robot.Sts.areas[1].reserved AND
   Inp.robot_Rx.area_source_clear AND Context.pickedCount > 0 THEN
    fbTopFlow.Inp.StackConsumedAtP3 := TRUE;
END_IF;
IF fbTraySeq.Outp.ConsumePlaced THEN taskDoneNext[2] := TRUE; END_IF;

IF fbTraySeq.Outp.ConsumeFinished THEN taskDoneNext[3] := TRUE; END_IF;
(* Warstwa/przekladka maja skutki licznikowe, bez ruchu windy. *)
taskDoneNext[4] := Context.tasks[4].pending;
taskDoneNext[7] := Context.tasks[7].pending;
IF NOT Context.orderActive THEN stackAdvancePending := FALSE; END_IF;
IF stackAdvancePending AND robot.Sts.allChannelsIdle AND NOT Context.tasks[8].pending THEN
    Context.stackId := TO_UINT((TO_UDINT(Context.stackId) + 1) MOD 65536);
    Context.blisterCount := 0;
    Context.layerCount := 0;
    Context.stackFull := FALSE;
    stackAdvancePending := FALSE;
END_IF;
Outp.robot_Tx.production_stackId := Context.stackId;
xBottomReqFromTray := xModeTray AND fbTraySeq.Outp.Bottom_DischargeReq;
xBottomReqFromBox := xModeBox AND fbBoxSeq.Outp.Bottom_DischargeReq;
(* Zwykly Stop nie odbiera wlasnosci zaakceptowanemu transferowi. *)
fbTopFlow.Cmd.EnableAuto := outputPermit AND (fbTopFlow.Cmd.EnableAuto OR topTransferActive);
fbBottom567.Cmd.EnableAuto := outputPermit AND (fbBottom567.Cmd.EnableAuto OR
    ((fbBottom567.Sts.State <> E_Bottom567State.IDLE) AND (fbBottom567.Sts.State <> E_Bottom567State.INIT)));
(* Manual i koordynacja zadan korzystaja z tego samego wlasciciela wyjsc. *)
manualIn := Inp.station_ManualInterlocks;
manualIn.armed := Hmi.link.xArmed;
manualIn.sessionId := Hmi.link.udiSessionId;
manualIn.panel := Hmi.link.uiActivePanel;
manualIn.timeout := Cfg.robot_Cfg.hmiTimeout;
manualIn.manual := xHmiManualMode;
manualIn.idle := NOT productionPermit AND NOT Drain.runPermit AND
 (transport.Sts.owner = E_StationOwner.NONE OR transport.Sts.owner = E_StationOwner.MANUAL);
manualIn.safe := xGlobalEnable AND stationParametersReady AND robot.Sts.session AND Inp.robot_Rx.production_home AND
 Inp.robot_Rx.production_loadKnown AND Cfg.station_ManualReleaseVerified;
FOR i := 1 TO 16 DO
 IF i >= 5 AND i <= 9 THEN
  manualIn.allowPositive[i] := manualIn.allowPositive[i] AND Inp.station_Inputs.beltsStopped[1] AND NOT robot.Sts.areas[1].reserved;
  manualIn.allowNegative[i] := manualIn.allowNegative[i] AND Inp.station_Inputs.beltsStopped[1] AND NOT robot.Sts.areas[1].reserved;
 ELSIF i >= 10 AND i <= 12 THEN
  manualIn.allowPositive[i] := manualIn.allowPositive[i] AND Inp.station_Inputs.beltsStopped[2] AND NOT elevStat.xBusy AND NOT robot.Sts.areas[2].reserved;
  manualIn.allowNegative[i] := manualIn.allowNegative[i] AND Inp.station_Inputs.beltsStopped[2] AND NOT elevStat.xBusy AND NOT robot.Sts.areas[2].reserved;
 ELSIF i = 13 OR i = 14 THEN
  manualIn.allowPositive[i] := manualIn.allowPositive[i] AND Inp.station_Inputs.beltsStopped[3];
  manualIn.allowNegative[i] := manualIn.allowNegative[i] AND Inp.station_Inputs.beltsStopped[3];
 END_IF;
END_FOR;
manualIn.allowPositive[2] := manualIn.allowPositive[2] AND NOT robot.Sts.areas[2].reserved AND NOT elevStat.xBusy;
manualIn.allowNegative[2] := manualIn.allowNegative[2] AND NOT robot.Sts.areas[2].reserved AND NOT elevStat.xBusy;
manualIn.allowPositive[4] := manualIn.allowPositive[4] AND NOT robot.Sts.areas[2].reserved AND Inp.station_Inputs.beltsStopped[2];
manualIn.allowNegative[4] := manualIn.allowNegative[4] AND NOT robot.Sts.areas[2].reserved AND Inp.station_Inputs.beltsStopped[2];
manual(Cmd := Hmi.stationManual, Inp := manualIn);
localUnload(CLK := Inp.io_di.ind_button_start_emptying_process);
Outp.robot_singleUnloadReady := fbBottom567.Sts.SingleUnloadReady AND xGlobalEnable AND
 Context.orderActive AND Context.withRobot AND NOT xHmiManualMode AND
 NOT robot.Sts.recoveryRequired AND NOT plantNow.critical AND alarms.Sts.policyReady AND stationParametersReady;
Outp.robot_singleUnloadRequest := localUnload.Q AND Outp.robot_singleUnloadReady;
drainIn.enable := xGlobalEnable AND robot.Sts.session AND NOT xHmiManualMode;
drainIn.known := material.Sts.known;
drainIn.occupied := material.Sts.occupied;
drainIn.emptyConfirmed := material.Sts.emptyConfirmed;
drainIn.atTop := elevStat.ePos = E_ElevatorPos.posTop;
drainIn.atBottom := elevStat.ePos = E_ElevatorPos.posBottom;
drainIn.lowerCanAccept := fbBottom567.Sts.CanAcceptFromElev;
drainIn.lowerCanAdvance := fbBottom567.Sts.CanAdvance;
drainIn.actionAccepted := transport.Sts.start AND transport.Sts.owner = E_StationOwner.DRAIN;
drainIn.actionDone := transport.Sts.done AND transport.Sts.completedOwner = E_StationOwner.DRAIN;
drainIn.actionFault := transport.Sts.fault;
drainIn.reconcile := reconciledNow;
fbStationDrain(Inp := drainIn, Drain := Drain);
transportIn.permit := xGlobalEnable AND robot.Sts.session;
transportIn.critical := plantNow.critical OR robot.Recovery.Required OR (stationRecovery.Required AND NOT xHmiManualMode);
transportIn.productionPermit := productionPermit;
transportIn.resourcesUsed := TRUE;
transportIn.productionTopBusy := topTransferActive;
transportIn.productionAxisBusy := elevStat.xBusy;
transportIn.productionElevatorBusy := fbConvElev.Sts.Running;
transportIn.productionBottomBusy := fbBottom567.Sts.Busy;
transportIn.storageBusy := fbStorage.Sts.Busy;
FOR i := 1 TO 3 DO transportIn.robotReserved[i] := robot.Sts.areas[i].reserved; END_FOR;
transportIn.outputPending := fbBottom567.Sts.WaitingPickup;
transportIn.unloadIssued := fbBottom567.Outp.SingleUnloadIssuedPulse OR fbBottom567.Sts.WaitingPickup;
transportIn.executorAccepted := fbBottom567.Outp.AcceptedPulse;
transportIn.executorStarted := fbConvBottom.Sts.Running OR fbConvElev.Sts.Running OR elevStat.xBusy;
transportIn.productionBusy := topTransferActive OR elevStat.xBusy OR fbBottom567.Sts.Busy;
transportIn.productionNeedsLower := fbBottom567.Cmd.DischargeReq;
transportIn.drainAction := fbStationDrain.Sts.action_;
transportIn.drainPermit := Drain.runPermit;
transportIn.localRequest := Outp.robot_singleUnloadRequest;
transportIn.localReady := Outp.robot_singleUnloadReady;
transportIn.localAllowed := Context.orderActive AND NOT xHmiManualMode;
transportIn.manual := xHmiManualMode;
transportIn.manualActive := manual.Sts.active;
transportIn.reconcile := reconciledNow;
transportIn.requireIds := TRUE;
transportIn.acceptedId := 0; transportIn.startedId := 0; transportIn.doneId := 0;
transportIn.actionDone := FALSE; transportIn.executorAccepted := FALSE; transportIn.executorStarted := FALSE;
CASE transport.Sts.action_ OF
 E_StationAction.ELEV_TOP:
  transportIn.actionDone := elevStat.CompletedId = transport.Sts.operationId AND elevStat.xStandstill AND elevStat.ePos = E_ElevatorPos.posTop;
  transportIn.doneId := elevStat.CompletedId; transportIn.acceptedId := elevStat.AcceptedId;
  transportIn.executorStarted := Outp.drive.forward OR Outp.drive.reverse;
 E_StationAction.ELEV_BOTTOM:
  transportIn.actionDone := elevStat.CompletedId = transport.Sts.operationId AND elevStat.xStandstill AND elevStat.ePos = E_ElevatorPos.posBottom;
  transportIn.doneId := elevStat.CompletedId; transportIn.acceptedId := elevStat.AcceptedId;
  transportIn.executorStarted := Outp.drive.forward OR Outp.drive.reverse;
 E_StationAction.FEED:
  transportIn.actionDone := fbTopFlow.Outp.CompletedId = transport.Sts.operationId;
  transportIn.doneId := fbTopFlow.Outp.CompletedId; transportIn.acceptedId := fbTopFlow.Outp.AcceptedId;
  transportIn.executorStarted := fbConvTop.Sts.Running;
 E_StationAction.DISCHARGE:
  transportIn.actionDone := fbBottom567.Outp.DischargeDonePulse;
  transportIn.doneId := fbBottom567.Outp.DischargeDoneId; transportIn.acceptedId := fbBottom567.Outp.AcceptedId;
  transportIn.executorStarted := fbConvBottom.Sts.Running AND fbConvElev.Sts.Running;
 E_StationAction.UNLOAD:
  transportIn.actionDone := fbBottom567.Outp.SingleUnloadDonePulse;
  transportIn.doneId := fbBottom567.Outp.UnloadDoneId; transportIn.acceptedId := fbBottom567.Outp.AcceptedId;
  transportIn.executorStarted := fbConvBottom.Sts.Running OR fbBottom567.Sts.WaitingPickup;
END_CASE;
transportIn.executorAccepted := transportIn.acceptedId = transport.Sts.operationId AND transport.Sts.operationId > 0;
IF transportIn.executorStarted THEN transportIn.startedId := transport.Sts.operationId; END_IF;
transportIn.actionFault := fbTopFlow.Diag.Fault OR fbBottom567.Diag.Fault OR elevStat.xFault;
transport(Inp := transportIn, Context := Context.station);
Outp.station_Transport := transport.Sts;
Outp.station_DrainStatus := fbStationDrain.Sts;
fbTopFlow.Cmd.AllowNewTransfers := robot.Sts.order.newPermit;
fbBottom567.Cmd.FinishPermit := productionPermit;
fbBottom567.Cmd.SingleUnloadReq := FALSE;
fbBottom567.Cmd.AdvanceReq := transport.Sts.productionBottomAllowed AND fbBottom567.Sts.CanAdvance AND NOT fbBottom567.Cmd.DischargeReq AND
 (robot.Sts.order.newPermit OR Context.tasks[8].pending);
IF NOT transport.Sts.productionTopAllowed THEN fbTopFlow.Cmd.EnableAuto := FALSE; END_IF;
IF NOT transport.Sts.productionElevatorAllowed THEN fbTopFlow.Inp.Elev_RequestFeed := FALSE; END_IF;
IF NOT transport.Sts.productionBottomAllowed THEN fbBottom567.Cmd.EnableAuto := FALSE; fbBottom567.Cmd.DischargeReq := FALSE; END_IF;
IF NOT transport.Sts.productionAxisAllowed THEN elevCmd.xAutoGo := FALSE; END_IF;

actionPermit := xGlobalEnable AND robot.Sts.session AND NOT transport.Sts.fault;
IF transport.Sts.owner = E_StationOwner.DRAIN OR transport.Sts.owner = E_StationOwner.LOCAL THEN
 IF transport.Sts.action_ <> E_StationAction.UNLOAD AND transport.Sts.action_ <> E_StationAction.ADVANCE THEN
  fbV201.CmdExtend := FALSE; fbV202.CmdExtend := FALSE; fbPosM7.HoldUp := FALSE;
 END_IF;
 fbBottom567.Cmd.FinishPermit := actionPermit;
 CASE transport.Sts.action_ OF
  E_StationAction.ELEV_TOP:
   elevCmd.eAutoTarget := E_ElevatorTarget.posTop;
   IF transport.Sts.action_ = E_StationAction.ELEV_BOTTOM THEN elevCmd.eAutoTarget := E_ElevatorTarget.posBottom; END_IF;
   elevCmd.xAutoGo := actionPermit AND fbV201.Sts.AtRet AND fbV202.Sts.AtRet AND fbPosM7.Sts.IsDown AND
    elevStat.eState = E_ElevatorState.IDLE;
   elevCmd.xStop := NOT actionPermit;
  E_StationAction.ELEV_BOTTOM:
   elevCmd.eAutoTarget := E_ElevatorTarget.posTop;
   IF transport.Sts.action_ = E_StationAction.ELEV_BOTTOM THEN elevCmd.eAutoTarget := E_ElevatorTarget.posBottom; END_IF;
   elevCmd.xAutoGo := actionPermit AND fbV201.Sts.AtRet AND fbV202.Sts.AtRet AND fbPosM7.Sts.IsDown AND
    elevStat.eState = E_ElevatorState.IDLE;
   elevCmd.xStop := NOT actionPermit;
  E_StationAction.FEED:
   fbTopFlow.Cmd.EnableAuto := actionPermit AND fbTopFlow.Outp.CompletedId <> transport.Sts.operationId;
   fbTopFlow.Cmd.AllowNewTransfers := Drain.runPermit;
   fbTopFlow.Cmd.EmptyingMode := TRUE;
   fbTopFlow.Inp.Elev_RequestFeed := TRUE;
   fbTopFlow.Inp.Elev_CanAccept := drainIn.atTop AND NOT material.Sts.occupied[4];
  E_StationAction.DISCHARGE:
   fbBottom567.Cmd.EnableAuto := actionPermit;
   fbBottom567.Cmd.DischargeReq := actionPermit;
  E_StationAction.UNLOAD:
   fbBottom567.Cmd.EnableAuto := actionPermit;
   fbBottom567.Cmd.SingleUnloadReq := actionPermit;
 END_CASE;
END_IF;
IF robot.Sts.areas[1].reserved OR NOT outputPermit THEN
    fbTopFlow.Cmd.SafetyOK := FALSE;
END_IF;
IF productionTopId = 0 AND fbTopFlow.Cmd.EnableAuto AND transport.Sts.owner <> E_StationOwner.DRAIN THEN
 IF Context.station.nextOperationId < 16#FFFFFFFF THEN
  Context.station.nextOperationId := Context.station.nextOperationId + 1; productionTopId := Context.station.nextOperationId;
 ELSE reconcileRequired := TRUE; END_IF;
END_IF;
fbTopFlow.Cmd.OperationId := productionTopId;
IF transport.Sts.owner = E_StationOwner.DRAIN AND transport.Sts.action_ = E_StationAction.FEED THEN fbTopFlow.Cmd.OperationId := transport.Sts.operationId; END_IF;
topWasBusy := fbTopFlow.Sts.Busy;
fbTopFlow();
IF fbTopFlow.Outp.TransferDonePulse THEN productionTopId := 0; END_IF;

// Kasuj pamięć przycisku dopiero po przyjęciu potwierdzenia przez TopFlow.
IF xLoadAcceptPulseSent AND fbTopFlow.Sts.Pos1Accepted THEN
    xLoadAcceptedPending := FALSE;
END_IF;

IF NOT xHmiManualMode THEN
    xM1RetractForTopFlow := (fbTopFlow.Sts.SrcPos = E_TopPos.P1) AND
                            (fbTopFlow.Sts.State <> E_TopFlowState.INIT) AND
                            (fbTopFlow.Sts.State <> E_TopFlowState.IDLE) AND
                            (NOT fbTopFlow.Sts.P1ReleasedForLoad);
    fbPosM1.HoldUp := NOT xM1RetractForTopFlow;

    fbStopM2.HoldUp := fbTopFlow.Outp.HoldPos1_Up;
    fbStopM3.HoldUp := fbTopFlow.Outp.HoldPos2_Up;
    fbStopM4.HoldUp := fbTopFlow.Outp.HoldPos3_Up;
    fbPosM5.HoldUp  := fbTopFlow.Outp.M5_Extend;
ELSE
    xM1RetractForTopFlow := FALSE;
END_IF;

IF NOT fbBottom567.Cmd.DischargeReq AND NOT fbBottom567.Sts.Busy THEN productionDischargeId := 0; END_IF;
IF NOT fbBottom567.Cmd.AdvanceReq AND NOT fbBottom567.Sts.Busy THEN productionAdvanceId := 0; END_IF;
IF fbBottom567.Cmd.DischargeReq AND productionDischargeId = 0 AND transport.Sts.action_ <> E_StationAction.DISCHARGE THEN
 IF Context.station.nextOperationId < 16#FFFFFFFF THEN Context.station.nextOperationId := Context.station.nextOperationId + 1; productionDischargeId := Context.station.nextOperationId; ELSE reconcileRequired := TRUE; END_IF;
END_IF;
IF fbBottom567.Cmd.AdvanceReq AND productionAdvanceId = 0 THEN
 IF Context.station.nextOperationId < 16#FFFFFFFF THEN Context.station.nextOperationId := Context.station.nextOperationId + 1; productionAdvanceId := Context.station.nextOperationId; ELSE reconcileRequired := TRUE; END_IF;
END_IF;
fbBottom567.Cmd.DischargeId := productionDischargeId; fbBottom567.Cmd.AdvanceId := productionAdvanceId;
fbBottom567.Cmd.UnloadId := 0;
IF transport.Sts.action_ = E_StationAction.DISCHARGE THEN fbBottom567.Cmd.DischargeId := transport.Sts.operationId; END_IF;
IF transport.Sts.action_ = E_StationAction.UNLOAD THEN fbBottom567.Cmd.UnloadId := transport.Sts.operationId; END_IF;
eBottomStateBeforeCall := fbBottom567.Sts.State;
lowerWasBusy := fbBottom567.Sts.Busy;
fbBottom567();
fbLowerStop5.Enable := outputPermit AND Inp.station_Inputs.lowerFeedbackValid;
fbLowerStop6.Enable := fbLowerStop5.Enable;
fbLowerStop5.ResetFault := xResetAll; fbLowerStop6.ResetFault := xResetAll;
fbLowerStop5.Inp := Inp.station_Inputs.lowerStop[1]; fbLowerStop6.Inp := Inp.station_Inputs.lowerStop[2];
fbLowerStop5.Inp.valid := io.Sts.valid AND Inp.station_Inputs.lowerFeedbackValid;
fbLowerStop6.Inp.valid := fbLowerStop5.Inp.valid;
fbLowerStop5.Inp.commandApplied := stationCoils.Applied[9].home OR stationCoils.Applied[9].work;
fbLowerStop6.Inp.commandApplied := stationCoils.Applied[10].home OR stationCoils.Applied[10].work;
fbLowerStop5.HoldUp := fbBottom567.Outp.HoldStop5;
fbLowerStop6.HoldUp := fbBottom567.Outp.HoldStop6;

// Owner jest nadawany dopiero po rzeczywistym zaakceptowaniu zbocza przez Bottom.
IF (eBottomStateBeforeCall = E_Bottom567State.IDLE) AND
   (fbBottom567.Sts.State = E_Bottom567State.PRECHECK) THEN
    IF xBottomReqFromTray THEN
        xBottomTransferOwnerTray := TRUE;
        xBottomTransferOwnerBox := FALSE;
        xBottomDonePendingTray := FALSE;
        xBottomDonePendingBox := FALSE;
    ELSIF xBottomReqFromBox THEN
        xBottomTransferOwnerTray := FALSE;
        xBottomTransferOwnerBox := TRUE;
        xBottomDonePendingTray := FALSE;
        xBottomDonePendingBox := FALSE;
    END_IF;
END_IF;

IF fbBottom567.Outp.DischargeDonePulse THEN
    (* Ładunek P4 rozlicza zdarzenie transferu w StationMaterial. *)
    IF xBottomTransferOwnerTray THEN
        xBottomDonePendingTray := TRUE;
    ELSIF xBottomTransferOwnerBox THEN
        xBottomDonePendingBox := TRUE;
    END_IF;
END_IF;

IF fbBottom567.Sts.State = E_Bottom567State.IDLE THEN
    IF NOT xEmptyRunning THEN
        xBottomRecoveryRequired := FALSE;
    END_IF;
    xBottomStepTakeoverActive := FALSE;
END_IF;

IF NOT xHmiManualMode THEN
    fbConvTop.Cmd.RunFwd := fbTopFlow.Outp.TopConveyor_Run AND
                             ((fbTopFlow.Sts.SrcPos <> E_TopPos.P1) OR
                              fbPosM1.Sts.IsDown OR fbTopFlow.Sts.P1ReleasedForLoad);
    fbConvElev.Cmd.RunFwd := fbConvElev.Cmd.RunFwd OR
                              (fbTopFlow.Outp.ElevConv_RunFwd AND (xModeBox OR xEmptyRunning));
END_IF;

// BottomAccumulator ma priorytet na obu transporterach również w trybie ręcznym.
IF fbBottom567.Outp.ElevConv_RunBwd THEN
    fbConvElev.Cmd.RunFwd := FALSE;
    fbConvElev.Cmd.RunBwd := TRUE;
END_IF;
IF fbBottom567.Outp.ConvRun THEN
    fbConvBottom.Cmd.RunBwd := FALSE;
    fbConvBottom.Cmd.RunFwd := TRUE;
END_IF;

IF xHmiManualMode THEN
 fbConvTop.Cmd.RunFwd := manual.Sts.positive[1]; fbConvTop.Cmd.RunBwd := FALSE;
 fbConvElev.Cmd.RunFwd := manual.Sts.positive[2]; fbConvElev.Cmd.RunBwd := manual.Sts.negative[2];
 fbConvBottom.Cmd.RunFwd := manual.Sts.positive[3]; fbConvBottom.Cmd.RunBwd := manual.Sts.negative[3];
 elevCmd.eMode := E_ElevatorMode.MANUAL;
 elevCmd.xManUp := manual.Sts.positive[4]; elevCmd.xManDown := manual.Sts.negative[4];
 elevCmd.xManFast := FALSE; elevCmd.xStop := NOT (elevCmd.xManUp OR elevCmd.xManDown);
 fbPosM1.HoldUp := manual.Sts.positive[5]; fbStopM2.HoldUp := manual.Sts.positive[6];
 fbStopM3.HoldUp := manual.Sts.positive[7]; fbStopM4.HoldUp := manual.Sts.positive[8];
 fbPosM5.HoldUp := manual.Sts.positive[9]; fbV201.CmdExtend := manual.Sts.positive[10];
 fbV202.CmdExtend := manual.Sts.positive[11]; fbPosM7.HoldUp := manual.Sts.positive[12];
 fbLowerStop5.HoldUp := manual.Sts.positive[13]; fbLowerStop6.HoldUp := manual.Sts.positive[14];
END_IF;
(* Ostateczna blokada windy/taśmy obszaru robota przed wykonaniem. *)
IF robot.Sts.areas[2].reserved OR NOT outputPermit THEN
    elevCmd.xAutoGo := FALSE;
    elevCmd.xStop := TRUE;
    fbConvElev.Cmd.RunFwd := FALSE;
    fbConvElev.Cmd.RunBwd := FALSE;
END_IF;
IF fbConvTop.Sts.Running OR robot.Sts.areas[1].reserved THEN
    fbStopM4.Enable := FALSE;
    fbPosM5.Enable := FALSE;
END_IF;
IF fbConvElev.Sts.Running OR robot.Sts.areas[2].reserved THEN
    fbV201.Enable := FALSE; fbV202.Enable := FALSE;
    fbPosM7.Enable := FALSE;
END_IF;


fbStopM2.Inp.commandApplied := (fbStopM2.HoldUp AND stationCoils.Applied[2].work) OR (NOT fbStopM2.HoldUp AND stationCoils.Applied[2].home);
fbStopM2();
stationCmd[2].work := fbStopM2.Outp.Q_Fwd;
stationCmd[2].home := fbStopM2.Outp.Q_Bwd;

fbStopM3.Inp.commandApplied := (fbStopM3.HoldUp AND stationCoils.Applied[3].work) OR (NOT fbStopM3.HoldUp AND stationCoils.Applied[3].home);
fbStopM3();
stationCmd[3].work := fbStopM3.Outp.Q_Fwd;
stationCmd[3].home := fbStopM3.Outp.Q_Bwd;

fbStopM4.Inp.commandApplied := (fbStopM4.HoldUp AND stationCoils.Applied[4].work) OR (NOT fbStopM4.HoldUp AND stationCoils.Applied[4].home);
fbStopM4();
stationCmd[4].work := fbStopM4.Outp.Q_Fwd;
stationCmd[4].home := fbStopM4.Outp.Q_Bwd;

fbPosM1.Inp.commandApplied := (fbPosM1.HoldUp AND stationCoils.Applied[1].work) OR (NOT fbPosM1.HoldUp AND stationCoils.Applied[1].home);
fbPosM1();
stationCmd[1].work := fbPosM1.Outp.Q_Fwd;
stationCmd[1].home := fbPosM1.Outp.Q_Bwd;

fbPosM5.Inp.commandApplied := (fbPosM5.HoldUp AND stationCoils.Applied[5].work) OR (NOT fbPosM5.HoldUp AND stationCoils.Applied[5].home);
fbPosM5();
stationCmd[5].work := fbPosM5.Outp.Q_Fwd;
stationCmd[5].home := fbPosM5.Outp.Q_Bwd;

fbV201.Inp.commandApplied := (fbV201.CmdExtend AND stationCoils.Applied[6].work) OR (NOT fbV201.CmdExtend AND stationCoils.Applied[6].home);
fbV201(); fbV202.Inp.commandApplied := (fbV202.CmdExtend AND stationCoils.Applied[8].work) OR (NOT fbV202.CmdExtend AND stationCoils.Applied[8].home);
fbV202();
stationCmd[6].work := fbV201.Outp.Q_Ext; stationCmd[6].home := fbV201.Outp.Q_Ret;
stationCmd[8].work := fbV202.Outp.Q_Ext; stationCmd[8].home := fbV202.Outp.Q_Ret;
fbLowerStop5.Inp.commandApplied := (fbLowerStop5.HoldUp AND stationCoils.Applied[9].work) OR (NOT fbLowerStop5.HoldUp AND stationCoils.Applied[9].home);
fbLowerStop5(); fbLowerStop6.Inp.commandApplied := (fbLowerStop6.HoldUp AND stationCoils.Applied[10].work) OR (NOT fbLowerStop6.HoldUp AND stationCoils.Applied[10].home);
fbLowerStop6();
stationCmd[9].work := fbLowerStop5.Outp.Q_Fwd; stationCmd[9].home := fbLowerStop5.Outp.Q_Bwd;
stationCmd[10].work := fbLowerStop6.Outp.Q_Fwd; stationCmd[10].home := fbLowerStop6.Outp.Q_Bwd;

fbPosM7.Inp.commandApplied := (fbPosM7.HoldUp AND stationCoils.Applied[7].work) OR (NOT fbPosM7.HoldUp AND stationCoils.Applied[7].home);
fbPosM7();
stationCmd[7].work := fbPosM7.Outp.Q_Fwd;
stationCmd[7].home := fbPosM7.Outp.Q_Bwd;


fbConvTop();
Outp.io_dout.ctrl_turn_on_top_conveyor := fbConvTop.Outp.Q_Fwd;

fbConvElev();
Outp.io_dout.ctrl_turn_on_elevator_conveyor_in := fbConvElev.Outp.Q_Fwd;
Outp.io_dout.ctrl_turn_on_elevator_conveyor_out := fbConvElev.Outp.Q_Bwd;

fbConvBottom();
Outp.io_dout.ctrl_turn_on_bottom_conveyor := fbConvBottom.Outp.Q_Fwd;
Outp.io_dout.ctrl_turn_on_bottom_conveyor_in := fbConvBottom.Outp.Q_Bwd;


xAutoActive := robot.Sts.order.running OR robot.Sts.order.stopping;
Outp.io_dout.ctrl_turn_on_light_red := plantNow.critical OR robot.Sts.diag.fault;
Outp.io_dout.ctrl_turn_on_light_yellow := plantNow.warning OR robot.Sts.order.stopping;
Outp.io_dout.ctrl_turn_on_light_green := robot.Sts.order.running AND NOT Outp.io_dout.ctrl_turn_on_light_red;
Outp.io_dout.ctrl_turn_on_buzzer := Outp.io_dout.ctrl_turn_on_light_red;
Outp.io_dout.ctrl_LED_button_start_process := robot.Sts.order.canStart;
Outp.io_dout.ctrl_LED_button_continue_process := FALSE;
Outp.io_dout.ctrl_LED_button_samples := Hmi.permit.samples.xAllowed;
Outp.io_dout.ctrl_LED_button_start_emptying_process := FALSE;
(* Odpowiedz granted moze zostac tylko odebrana po zmianie gotowosci urzadzen. *)
Outp.robot_Tx.area_elevator_granted := Outp.robot_Tx.area_elevator_granted AND NOT stackAdvancePending;
Outp.robot_Tx.area_storage_granted := Outp.robot_Tx.area_storage_granted AND fbStorage.Sts.RobotAccessGranted;

(* Trwałe skutki transportu trafiają do jednego modelu przez monotoniczne zdarzenia. *)
FOR i := 1 TO 8 DO materialEvents[i] := emptyMaterialEvent; END_FOR;
eventCount := 0;
IF NOT reconciledNow THEN
IF io.Sts.occupied[1] AND NOT material.Sts.occupied[1] AND NOT topTransferActive AND material.Sts.known THEN
 eventCount := eventCount + 1; materialEvents[eventCount].source := 0; materialEvents[eventCount].target := 1;
END_IF;
topCompleted := fbTopFlow.Outp.TransferDonePulse;
IF topCompleted THEN
 eventCount := eventCount + 1;
 CASE fbTopFlow.Sts.SrcPos OF
  E_TopPos.P1: materialEvents[eventCount].source := 1;
  E_TopPos.P2: materialEvents[eventCount].source := 2;
  E_TopPos.P3: materialEvents[eventCount].source := 3;
 END_CASE;
 CASE fbTopFlow.Sts.Target OF
  E_TopTarget.TG_P2: materialEvents[eventCount].target := 2;
  E_TopTarget.TG_P3: materialEvents[eventCount].target := 3;
  E_TopTarget.TG_ELEV: materialEvents[eventCount].target := 4;
 END_CASE;
END_IF;
IF fbBottom567.Outp.MaterialMovedPulse THEN
 eventCount := eventCount + 1; materialEvents[eventCount].source := fbBottom567.Outp.MaterialSource;
 materialEvents[eventCount].target := fbBottom567.Outp.MaterialTarget;
END_IF;
IF fbBottom567.Outp.SingleUnloadDonePulse THEN
 eventCount := eventCount + 1; materialEvents[eventCount].source := 7; materialEvents[eventCount].target := 0;
END_IF;
IF Context.tasks[2].pending AND NOT placedSeen AND NOT material.Sts.occupied[4] THEN
 eventCount := eventCount + 1; materialEvents[eventCount].source := 0; materialEvents[eventCount].target := 4;
END_IF;
placedSeen := Context.tasks[2].pending;
IF material.Sts.occupied[3] AND plantNow.sourceEmptyConfirmed AND NOT topTransferActive AND NOT topCompleted AND
 NOT robot.Sts.areas[1].reserved AND Context.pickedCount > 0 THEN
 eventCount := eventCount + 1; materialEvents[eventCount].source := 3; materialEvents[eventCount].target := 0;
END_IF;
END_IF;
placedSeen := Context.tasks[2].pending;
FOR i := 1 TO eventCount DO
 IF Context.station.nextMaterialEventId < 16#FFFFFFFF THEN
  Context.station.nextMaterialEventId := Context.station.nextMaterialEventId + 1;
  materialEvents[i].id := Context.station.nextMaterialEventId;
 ELSE materialOverflow := TRUE; END_IF;
END_FOR;
materialIn.useEvents := TRUE;
materialIn.events := materialEvents;
materialIn.restoredEventId := Context.station.lastMaterialEventId;
materialIn.valid := io.Sts.valid;
materialIn.reconcile := reconciledNow;
materialIn.restored := Context.occupied;
materialIn.observed[1] := fbTopFlow.Sts.OccP1; materialIn.observed[2] := fbTopFlow.Sts.OccP2;
materialIn.observed[3] := fbTopFlow.Sts.OccP3; materialIn.observed[4] := material.Sts.occupied[4];
materialIn.observed[5] := fbBottom567.Sts.Occ5; materialIn.observed[6] := fbBottom567.Sts.Occ6;
materialIn.observed[7] := fbBottom567.Sts.Occ7;
materialIn.sensed := io.Sts.occupied;
(* B205 jest czujnikiem krawedzi: brak aktywnosci nie oznacza braku zapamietanego ladunku. *)
materialIn.moving := fbTopFlow.Sts.Busy OR fbBottom567.Sts.Busy OR elevStat.xBusy;
materialIn.commit := (topWasBusy AND NOT fbTopFlow.Sts.Busy) OR (lowerWasBusy AND NOT fbBottom567.Sts.Busy) OR
 fbTopFlow.Sts.Pos1Accepted OR plantNow.sourceEmptyConfirmed OR Context.tasks[2].pending;
materialIn.manualMoved := manual.Sts.active;
materialIn.pending := fbBottom567.Sts.WaitingPickup OR (transport.Sts.busy AND transport.Sts.owner <> E_StationOwner.PRODUCTION) OR
 xBottomDonePendingTray OR xBottomDonePendingBox;
material(Inp := materialIn);
Context.station.lastMaterialEventId := material.Sts.lastEventId;
xElevatorLoadPresent := material.Sts.occupied[4];
IF materialOverflow OR material.Sts.fault THEN reconcileRequired := TRUE; END_IF;
Outp.station_Material := material.Sts;
IF material.Sts.known THEN
 Context.occupied := material.Sts.occupied;
 Context.elevatorLoadPresent := material.Sts.occupied[4];
END_IF;
Context.occupancyKnown := material.Sts.known;
Context.topTransferState := fbTopFlow.Sts.State;
Context.bottomTransferState := fbBottom567.Sts.State;
Context.bottomTransferOwner := 0;
IF xBottomTransferOwnerTray THEN Context.bottomTransferOwner := 2; END_IF;
IF xBottomTransferOwnerBox THEN Context.bottomTransferOwner := 1; END_IF;
Context.bottomDonePendingTray := xBottomDonePendingTray;
Context.bottomDonePendingBox := xBottomDonePendingBox;
Context.stationDrainStep := fbStationDrain.Sts.state;
Context.stationOwner := transport.Sts.owner;
Context.stationAction := transport.Sts.action_;
Context.pickupPending := fbBottom567.Sts.WaitingPickup;
Context.pickupSeen := fbBottom567.Sts.PickupSeen;

// 15) ALARM MANAGER — zbieranie faultów
// ================================================================

Outp.hmi_hmiAlarms.xM1_Fault         := fbPosM1.Diag.Fault;
Outp.hmi_hmiAlarms.xM2_Fault         := fbStopM2.Diag.Fault;
Outp.hmi_hmiAlarms.xM3_Fault         := fbStopM3.Diag.Fault;
Outp.hmi_hmiAlarms.xM4_Fault         := fbStopM4.Diag.Fault;
Outp.hmi_hmiAlarms.xM5_Fault         := fbPosM5.Diag.Fault;
Outp.hmi_hmiAlarms.xM6_Fault         := (fbV201.Diag.Fault OR fbV202.Diag.Fault);
Outp.hmi_hmiAlarms.xM7_Fault         := fbPosM7.Diag.Fault;
Outp.hmi_hmiAlarms.xM8_Fault         := fbStorage.Diag.Fault;
Outp.hmi_hmiAlarms.xConvTop_Fault    := fbConvTop.Diag.Fault;
Outp.hmi_hmiAlarms.xConvElev_Fault   := fbConvElev.Diag.Fault;
Outp.hmi_hmiAlarms.xConvBottom_Fault := fbConvBottom.Diag.Fault;
Outp.hmi_hmiAlarms.xElev_Fault       := elevStat.xFault;
Outp.hmi_hmiAlarms.xElev_CommLost    := FALSE; // osobny alarm komunikacji windy nieużywany
Outp.hmi_hmiAlarms.xTopFlow_Fault    := fbTopFlow.Diag.Fault;
Outp.hmi_hmiAlarms.xBottom_Fault     := fbBottom567.Diag.Fault;
Outp.hmi_hmiAlarms.xTraySeq_Fault    := fbTraySeq.Diag.Fault;
Outp.hmi_hmiAlarms.xBoxSeq_Fault     := fbBoxSeq.Diag.Fault;
Outp.hmi_hmiAlarms.xRobot_Fault      := (Inp.robot_Rx.production_fault AND robot.Sts.diagnosticValid);
Outp.hmi_hmiAlarms.xRobot_EStop      := (Inp.robot_Rx.production_estopActive AND robot.Sts.diagnosticValid);
Outp.hmi_hmiAlarms.xRobot_CommLost   := NOT robot.Sts.session;
Outp.hmi_hmiAlarms.xVfd_CommLost     := xGlobalEnable AND (NOT elevStat.xVfdCommOk);
Outp.hmi_hmiAlarms.xLowPressure      := Inp.io_di.ind_low_pressure;
Outp.hmi_hmiAlarms.xSafetyTrip       := NOT xSafetyOK;

Outp.hmi_hmiAlarmCount :=
    TO_UINT(Outp.hmi_hmiAlarms.xM1_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xM2_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xM3_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xM4_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xM5_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xM6_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xM7_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xM8_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xConvTop_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xConvElev_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xConvBottom_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xElev_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xElev_CommLost) +
    TO_UINT(Outp.hmi_hmiAlarms.xTopFlow_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xBottom_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xTraySeq_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xBoxSeq_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xRobot_Fault) +
    TO_UINT(Outp.hmi_hmiAlarms.xRobot_EStop) +
    TO_UINT(Outp.hmi_hmiAlarms.xRobot_CommLost) +
    TO_UINT(Outp.hmi_hmiAlarms.xVfd_CommLost) +
    TO_UINT(Outp.hmi_hmiAlarms.xRobot_MbLost) +
    TO_UINT(Outp.hmi_hmiAlarms.xLowPressure) +
    TO_UINT(Outp.hmi_hmiAlarms.xSafetyTrip);

// ================================================================
// 16) HMI STATUS — aktualizacja statusu stacji dla wizualizacji
// ================================================================

Outp.hmi_hmiStatus.xAutoRunning     := xAutoActive;
Outp.hmi_hmiStatus.xManualMode      := xHmiManualMode;
Outp.hmi_hmiStatus.xEmptyingStation := xEmptyRunning;
Outp.hmi_hmiStatus.xModeTray        := xModeTray;
Outp.hmi_hmiStatus.xModeBox         := xModeBox;
Outp.hmi_hmiStatus.xGlobalEnable    := xGlobalEnable;
Outp.hmi_hmiStatus.xSafetyOK        := xSafetyOK;

// Pozycje
Outp.hmi_hmiStatus.xOccP1 := fbTopFlow.Sts.OccP1;
Outp.hmi_hmiStatus.xOccP2 := fbTopFlow.Sts.OccP2;
Outp.hmi_hmiStatus.xOccP3 := fbTopFlow.Sts.OccP3;
Outp.hmi_hmiStatus.xOccP4 := io.Sts.occupied[4];
Outp.hmi_hmiStatus.xOccP5 := fbBottom567.Sts.Occ5;
Outp.hmi_hmiStatus.xOccP6 := fbBottom567.Sts.Occ6;
Outp.hmi_hmiStatus.xOccP7 := fbBottom567.Sts.Occ7;

// Winda
Outp.hmi_hmiStatus.uiElevState   := uiElevState;
Outp.hmi_hmiStatus.xElevAtTop    := elevStat.ePos = E_ElevatorPos.posTop;
Outp.hmi_hmiStatus.xElevAtBottom := elevStat.ePos = E_ElevatorPos.posBottom;
Outp.hmi_hmiStatus.xElevBusy     := elevStat.xBusy;
Outp.hmi_hmiStatus.xElevFault    := elevStat.xFault;
Outp.hmi_hmiStatus.rElevFreq_Hz  := elevStat.rVfdOutHz;
Outp.hmi_hmiStatus.sElevDiagText := elevStat.sDiagText;

// Transportery
Outp.hmi_hmiStatus.xConvTopRunning    := fbConvTop.Sts.Running;
Outp.hmi_hmiStatus.xConvElevRunning   := fbConvElev.Sts.Running;
Outp.hmi_hmiStatus.xConvBottomRunning := fbConvBottom.Sts.Running;
Outp.hmi_hmiStatus.uiConvTopState      := TO_UINT(fbConvTop.Sts.State);
Outp.hmi_hmiStatus.uiConvElevState     := TO_UINT(fbConvElev.Sts.State);
Outp.hmi_hmiStatus.uiConvBottomState   := TO_UINT(fbConvBottom.Sts.State);
Outp.hmi_hmiStatus.iConvTopDirection   := fbConvTop.Sts.Direction;
Outp.hmi_hmiStatus.iConvElevDirection  := fbConvElev.Sts.Direction;
Outp.hmi_hmiStatus.iConvBottomDirection := fbConvBottom.Sts.Direction;
Outp.hmi_hmiStatus.xConvTopFault       := fbConvTop.Diag.Fault;
Outp.hmi_hmiStatus.xConvElevFault      := fbConvElev.Diag.Fault;
Outp.hmi_hmiStatus.xConvBottomFault    := fbConvBottom.Diag.Fault;
Outp.hmi_hmiStatus.sConvTopDiagText    := fbConvTop.Diag.Text;
Outp.hmi_hmiStatus.sConvElevDiagText   := fbConvElev.Diag.Text;
Outp.hmi_hmiStatus.sConvBottomDiagText := fbConvBottom.Diag.Text;

// Siłowniki — stan zagregowany (kompatybilność wstecz)
Outp.hmi_hmiStatus.xM1_Extended := fbPosM1.Sts.IsUp;
Outp.hmi_hmiStatus.xM2_Up       := fbStopM2.Sts.IsUp;
Outp.hmi_hmiStatus.xM3_Up       := fbStopM3.Sts.IsUp;
Outp.hmi_hmiStatus.xM4_Up       := fbStopM4.Sts.IsUp;
Outp.hmi_hmiStatus.xM5_Up       := fbPosM5.Sts.IsUp;
Outp.hmi_hmiStatus.xM6_Up       := (fbV201.Sts.AtExt AND fbV202.Sts.AtExt);
Outp.hmi_hmiStatus.xM7_Extended := fbPosM7.Sts.IsUp;
Outp.hmi_hmiStatus.xM8_Extended := fbStorage.Sts.RobotSideOpen;
Outp.hmi_hmiStatus.xM1_Retracted := fbPosM1.Sts.IsDown;
Outp.hmi_hmiStatus.xM2_Down      := fbStopM2.Sts.IsDown;
Outp.hmi_hmiStatus.xM3_Down      := fbStopM3.Sts.IsDown;
Outp.hmi_hmiStatus.xM4_Down      := fbStopM4.Sts.IsDown;
Outp.hmi_hmiStatus.xM5_Down      := fbPosM5.Sts.IsDown;
Outp.hmi_hmiStatus.xM6_Down      := (fbV201.Sts.AtRet AND fbV202.Sts.AtRet);
Outp.hmi_hmiStatus.xM7_Retracted := fbPosM7.Sts.IsDown;
Outp.hmi_hmiStatus.xM8_Retracted := fbStorage.Sts.RobotSideClosed;
Outp.hmi_hmiStatus.xM1_Busy      := fbPosM1.Sts.Busy;
Outp.hmi_hmiStatus.xM2_Busy      := fbStopM2.Sts.Busy;
Outp.hmi_hmiStatus.xM3_Busy      := fbStopM3.Sts.Busy;
Outp.hmi_hmiStatus.xM4_Busy      := fbStopM4.Sts.Busy;
Outp.hmi_hmiStatus.xM5_Busy      := fbPosM5.Sts.Busy;
Outp.hmi_hmiStatus.xM6_Busy      := (fbV201.Sts.Busy OR fbV202.Sts.Busy);
Outp.hmi_hmiStatus.xM7_Busy      := fbPosM7.Sts.Busy;
Outp.hmi_hmiStatus.xM8_Busy      := fbStorage.Sts.Busy;
Outp.hmi_hmiStatus.xM1_Fault     := fbPosM1.Diag.Fault;
Outp.hmi_hmiStatus.xM2_Fault     := fbStopM2.Diag.Fault;
Outp.hmi_hmiStatus.xM3_Fault     := fbStopM3.Diag.Fault;
Outp.hmi_hmiStatus.xM4_Fault     := fbStopM4.Diag.Fault;
Outp.hmi_hmiStatus.xM5_Fault     := fbPosM5.Diag.Fault;
Outp.hmi_hmiStatus.xM6_Fault     := (fbV201.Diag.Fault OR fbV202.Diag.Fault);
Outp.hmi_hmiStatus.xM7_Fault     := fbPosM7.Diag.Fault;
Outp.hmi_hmiStatus.xM8_Fault     := fbStorage.Diag.Fault;
Outp.hmi_hmiStatus.sM1DiagText   := fbPosM1.Diag.Text;
Outp.hmi_hmiStatus.sM2DiagText   := fbStopM2.Diag.Text;
Outp.hmi_hmiStatus.sM3DiagText   := fbStopM3.Diag.Text;
Outp.hmi_hmiStatus.sM4DiagText   := fbStopM4.Diag.Text;
Outp.hmi_hmiStatus.sM5DiagText   := fbPosM5.Diag.Text;
Outp.hmi_hmiStatus.sM6DiagText   := 'V201/V202: sprawdz osobna diagnostyke osi';
Outp.hmi_hmiStatus.sM7DiagText   := fbPosM7.Diag.Text;
Outp.hmi_hmiStatus.sM8DiagText   := fbStorage.Diag.Text;

// Krańcówki siłowników — surowe czujniki fizyczne
// M1 — pozycjoner załadunku
Outp.hmi_hmiStatus.xM1_1_Fwd := Inp.io_di.ind_M1_1_fwd;
Outp.hmi_hmiStatus.xM1_2_Fwd := Inp.io_di.ind_M1_2_fwd;
Outp.hmi_hmiStatus.xM1_1_Bwd := Inp.io_di.ind_M1_1_bwd;
Outp.hmi_hmiStatus.xM1_2_Bwd := Inp.io_di.ind_M1_2_bwd;
// M2 — stoper P1
Outp.hmi_hmiStatus.xM2_1_Fwd := Inp.io_di.ind_M2_1_fwd;
Outp.hmi_hmiStatus.xM2_2_Fwd := Inp.io_di.ind_M2_2_fwd;
Outp.hmi_hmiStatus.xM2_1_Bwd := Inp.io_di.ind_M2_1_bwd;
Outp.hmi_hmiStatus.xM2_2_Bwd := Inp.io_di.ind_M2_2_bwd;
// M3 — stoper P2
Outp.hmi_hmiStatus.xM3_1_Fwd := Inp.io_di.ind_M3_1_fwd;
Outp.hmi_hmiStatus.xM3_2_Fwd := Inp.io_di.ind_M3_2_fwd;
Outp.hmi_hmiStatus.xM3_1_Bwd := Inp.io_di.ind_M3_1_bwd;
Outp.hmi_hmiStatus.xM3_2_Bwd := Inp.io_di.ind_M3_2_bwd;
// M4 — stoper P3
Outp.hmi_hmiStatus.xM4_1_Fwd := Inp.io_di.ind_M4_1_fwd;
Outp.hmi_hmiStatus.xM4_2_Fwd := Inp.io_di.ind_M4_2_fwd;
Outp.hmi_hmiStatus.xM4_1_Bwd := Inp.io_di.ind_M4_1_bwd;
Outp.hmi_hmiStatus.xM4_2_Bwd := Inp.io_di.ind_M4_2_bwd;
// M5 — pozycjoner tacek P3
Outp.hmi_hmiStatus.xM5_1_Fwd := Inp.io_di.ind_M5_1_fwd;
Outp.hmi_hmiStatus.xM5_2_Fwd := Inp.io_di.ind_M5_2_fwd;
Outp.hmi_hmiStatus.xM5_1_Bwd := Inp.io_di.ind_M5_1_bwd;
Outp.hmi_hmiStatus.xM5_2_Bwd := Inp.io_di.ind_M5_2_bwd;
// M6 — pozycjoner tacek winda
Outp.hmi_hmiStatus.xM6_1_Fwd := Inp.station_Inputs.v201.IsExt;
Outp.hmi_hmiStatus.xM6_2_Fwd := Inp.station_Inputs.v202.IsExt;
Outp.hmi_hmiStatus.xM6_1_Bwd := Inp.station_Inputs.v201.IsRet;
Outp.hmi_hmiStatus.xM6_2_Bwd := Inp.station_Inputs.v202.IsRet;
// M7 — pozycjoner kuwet winda
Outp.hmi_hmiStatus.xM7_Fwd := Inp.io_di.ind_M7_fwd;
Outp.hmi_hmiStatus.xM7_Bwd := Inp.io_di.ind_M7_bwd;
// M8 — osłona magazynu przekładek
Outp.hmi_hmiStatus.xM8_Fwd := Inp.io_di.ind_M8_fwd;
Outp.hmi_hmiStatus.xM8_Bwd := Inp.io_di.ind_M8_bwd;

// Drzwi celi robota
Outp.hmi_hmiStatus.uiSafetyDoorState        := TO_UINT(fbSafetyDoor.Sts.State);
Outp.hmi_hmiStatus.xSafetyDoorClosed        := fbSafetyDoor.Sts.DoorClosed;
Outp.hmi_hmiStatus.xSafetyDoorLocked        := fbSafetyDoor.Sts.DoorLocked;
Outp.hmi_hmiStatus.xSafetyDoorDeviceError   := fbSafetyDoor.Sts.DeviceError;
Outp.hmi_hmiStatus.xSafetyDoorUnlockRequest := fbSafetyDoor.Sts.UnlockRequest;
Outp.hmi_hmiStatus.xSafetyDoorReadyToRun    := fbSafetyDoor.Sts.ReadyToRun;
Outp.hmi_hmiStatus.xSafetyDoorBusy          := fbSafetyDoor.Sts.Busy;
Outp.hmi_hmiStatus.xSafetyDoorFault         := fbSafetyDoor.Diag.Fault;
Outp.hmi_hmiStatus.sSafetyDoorDiagText      := fbSafetyDoor.Diag.Text;

// Magazyn przekładek
Outp.hmi_hmiStatus.uiStorageState               := TO_UINT(fbStorage.Sts.State);
Outp.hmi_hmiStatus.xStorageRobotSideOpen        := fbStorage.Sts.RobotSideOpen;
Outp.hmi_hmiStatus.xStorageRobotSideClosed      := fbStorage.Sts.RobotSideClosed;
Outp.hmi_hmiStatus.xStorageRobotAccessActive    := fbStorage.Sts.RobotAccessActive;
Outp.hmi_hmiStatus.xStorageOperatorAccessActive := fbStorage.Sts.OperatorAccessActive;
Outp.hmi_hmiStatus.xStorageOperatorRequest      := fbStorage.Sts.OperatorRequest;
Outp.hmi_hmiStatus.xStorageRobotPermission      :=
    Inp.robot_storageIn.RobotSideOpeningPermission;
Outp.hmi_hmiStatus.xStorageOperatorPermission   :=
    Inp.robot_storageIn.OperatorSideOpeningPermission;
Outp.hmi_hmiStatus.xStorageLowLevel             := fbStorage.Sts.LowLevel;
Outp.hmi_hmiStatus.xStorageEmpty                := fbStorage.Sts.Empty;
Outp.hmi_hmiStatus.xStorageBusy                 := fbStorage.Sts.Busy;
Outp.hmi_hmiStatus.xStorageFault                := fbStorage.Diag.Fault;
Outp.hmi_hmiStatus.sStorageDiagText             := fbStorage.Diag.Text;

// Robot
Outp.hmi_hmiStatus.xRobotAutoMode := (Inp.robot_Rx.production_autoMode AND robot.Sts.session);
Outp.hmi_hmiStatus.xRobotReady    := (Inp.robot_Rx.production_systemReady AND robot.Sts.session);
Outp.hmi_hmiStatus.xRobotRunning  := (Inp.robot_Rx.production_running AND robot.Sts.session);
Outp.hmi_hmiStatus.xRobotFault    := (Inp.robot_Rx.production_fault AND robot.Sts.diagnosticValid);
Outp.hmi_hmiStatus.xRobotHome     := (Inp.robot_Rx.production_home AND robot.Sts.session);
Outp.hmi_hmiStatus.xRobotCommOk   := robot.Sts.session;
Outp.hmi_hmiStatus.xVfdCommOk     := elevStat.xVfdCommOk;

// Stany sekwencerów
Outp.hmi_hmiStatus.uiTraySeqState := TO_UINT(fbTraySeq.Sts.State);
Outp.hmi_hmiStatus.uiBoxSeqState  := TO_UINT(fbBoxSeq.Sts.State);
Outp.hmi_hmiStatus.uiTopFlowState := TO_UINT(fbTopFlow.Sts.State);
Outp.hmi_hmiStatus.uiBottomState  := TO_UINT(fbBottom567.Sts.State);
Outp.hmi_hmiStatus.sTopFlowDiagText := fbTopFlow.Diag.FaultText;
Outp.hmi_hmiStatus.sBottomDiagText  := fbBottom567.Diag.Text;
Outp.hmi_hmiStatus.sTraySeqDiagText := fbTraySeq.Diag.FaultText;
Outp.hmi_hmiStatus.sBoxSeqDiagText  := fbBoxSeq.Diag.FaultText;

Outp.hmi_hmiStatus.uiTraysDone  := fbTraySeq.Sts.TrayCount;
Outp.hmi_hmiStatus.uiStacksDone := fbTraySeq.Sts.StackCount;
Outp.hmi_hmiStatus.uiBoxesDone  := fbBoxSeq.Sts.BoxCount;

(* Rozszerzenie HMI: 12..15 Apply ST1..4, 16..20 Reload ST1..5, 21..25 ResetState ST1..5. *)
parameterIn.apply := 0; parameterIn.reload := 0;
parameterIn.idle := robot.Sts.allMotionIdle AND NOT manual.Sts.active AND NOT fbStorage.Sts.Busy AND
 (fbV201.Sts.AtExt OR fbV201.Sts.AtRet) AND (fbV202.Sts.AtExt OR fbV202.Sts.AtRet) AND NOT robot.Sts.order.running AND NOT Drain.runPermit;
parameterIn.recovery := robot.Sts.recoveryRequired;
parameterIn.expectedRevision := robot.Panel.StationRevision;
stationReset := 0; stationCommandReason := 0;
IF robot.Panel.StationKey >= 12 AND robot.Panel.StationKey <= 15 THEN parameterIn.apply := TO_UINT(robot.Panel.StationKey - 11); END_IF;
IF robot.Panel.StationKey >= 16 AND robot.Panel.StationKey <= 19 THEN parameterIn.reload := TO_UINT(robot.Panel.StationKey - 15); END_IF;
IF robot.Panel.StationKey = 20 THEN
 Hmi.edit.uiBatchCount := Context.batchCount;
 Hmi.edit.uiProgram := Context.program_;
END_IF;
IF robot.Panel.StationKey >= 21 AND robot.Panel.StationKey <= 25 THEN stationReset := TO_UINT(robot.Panel.StationKey - 20); END_IF;
parameters(Cfg := Cfg.station_ParameterCfg, Inp := parameterIn, Snapshot := robot.Panel.StationSnapshot,
 Edit := Hmi.stationEdit, Active := Context.stationParameters,
 Revision := Context.stationParamRevision);
stationCommandReason := parameters.Sts.reason;
IF parameterIn.reload > 0 THEN
 Hmi.stationEditRevision[parameterIn.reload] := parameters.Sts.revision[parameterIn.reload];
END_IF;
Hmi.stationActual := parameters.Sts.actual;
Hmi.stationRevision := parameters.Sts.revision;
IF stationReset > 0 THEN
 IF NOT xHmiManualMode OR NOT stationIdle OR Drain.runPermit THEN stationCommandReason := 30;
 ELSE
  (* Reset kroku nie usuwa ladunkow, licznikow, ACK ani zobowiazan. *)
  reconcileRequired := TRUE;
 END_IF;
END_IF;
IF reconciledNow THEN reconcileRequired := FALSE; END_IF;
stationCommandComplete := robot.Panel.StationKey > 0;
stationCommandResult := stationCommandReason;

fbStorage.Cmd.Enable := xGlobalEnable AND NOT alarms.Sts.critical AND
 (outputPermit OR Inp.robot_storageIn.BtnOpenClose OR fbStorage.Sts.OperatorRequest);
fbStorage.Cmd.ResetFault := xResetAll;
fbStorage.Cmd.RobotAccessReq := Inp.robot_Rx.area_storage_accessReq AND robot.Sts.session;
fbStorage.Cmd.RobotAccessPermit := outputPermit;
fbStorage.Cmd.RobotReserved := robot.Sts.areas[3].reserved;
fbStorage.Cmd.Manual := xHmiManualMode;
fbStorage.Cmd.ManualHome[1] := manual.Sts.negative[15]; fbStorage.Cmd.ManualWork[1] := manual.Sts.positive[15];
fbStorage.Cmd.ManualHome[2] := manual.Sts.negative[16]; fbStorage.Cmd.ManualWork[2] := manual.Sts.positive[16];
fbStorage.Inp := Inp.robot_storageIn;
fbStorage.Cfg.tStable := TO_TIME(Context.stationParameters[4].sensorStableMs);
fbStorage.Cfg.tM8Timeout := TO_TIME(Context.stationParameters[4].actuatorTimeoutMs);
fbStorage();
Outp.robot_storageOut := fbStorage.Outp;
(* Dawne M8 i proznia 5 nie sa rownoleglym torem nowego chwytaka. *)
Outp.io_dout.ctrl_move_M8_actuator_forward := FALSE;
Outp.io_dout.ctrl_move_M8_actuator_backward := FALSE;
Outp.io_dout.ctrl_turn_on_robot_gripper_vacuum := FALSE;
Outp.io_dout.ctrl_turn_on_robot_gripper_blow_off := FALSE;
Outp.io_dout.ctrl_open_spacer_storage_robot_side_lock := fbStorage.Outp.Q_UnlockRobotSide;
Outp.io_dout.ctrl_open_spacer_storage_operator_side_lock := fbStorage.Outp.Q_UnlockOperatorSide;
Outp.io_dout.ctrl_LED_button_open_close_spacer_storage := fbStorage.Outp.Q_LEDOpenClose;

FOR i := 1 TO 10 DO
 changeAllowed[i] := Inp.station_Inputs.beltsStopped[1] AND NOT robot.Sts.areas[1].reserved;
 IF i = 6 OR i = 7 OR i = 8 THEN changeAllowed[i] := Inp.station_Inputs.beltsStopped[2] AND NOT elevStat.xBusy AND NOT robot.Sts.areas[2].reserved; END_IF;
 IF i >= 9 THEN changeAllowed[i] := Inp.station_Inputs.beltsStopped[3]; END_IF;
 manualCoilActive[i] := FALSE;
END_FOR;
FOR i := 1 TO 6 DO manualCoilActive[i] := manual.Sts.positive[i + 4] OR manual.Sts.negative[i + 4]; END_FOR;
manualCoilActive[7] := manual.Sts.positive[12] OR manual.Sts.negative[12];
manualCoilActive[8] := manual.Sts.positive[11] OR manual.Sts.negative[11];
manualCoilActive[9] := manual.Sts.positive[13] OR manual.Sts.negative[13];
manualCoilActive[10] := manual.Sts.positive[14] OR manual.Sts.negative[14];
valveCommandValid[1] := fbPosM1.Sts.Valid AND NOT fbPosM1.Diag.Fault;
valveCommandValid[2] := fbStopM2.Sts.Valid AND NOT fbStopM2.Diag.Fault;
valveCommandValid[3] := fbStopM3.Sts.Valid AND NOT fbStopM3.Diag.Fault;
valveCommandValid[4] := fbStopM4.Sts.Valid AND NOT fbStopM4.Diag.Fault;
valveCommandValid[5] := fbPosM5.Sts.Valid AND NOT fbPosM5.Diag.Fault;
valveCommandValid[6] := fbV201.Sts.Valid AND NOT fbV201.Diag.Fault;
valveCommandValid[7] := fbPosM7.Sts.Valid AND NOT fbPosM7.Diag.Fault;
valveCommandValid[8] := fbV202.Sts.Valid AND NOT fbV202.Diag.Fault;
valveCommandValid[9] := fbLowerStop5.Sts.Valid AND NOT fbLowerStop5.Diag.Fault;
valveCommandValid[10] := fbLowerStop6.Sts.Valid AND NOT fbLowerStop6.Diag.Fault;

stationCommandFault := xHmiManualMode AND NOT Cfg.station_ManualReleaseVerified;
FOR i := 1 TO 10 DO
 IF stationCmd[i].home AND stationCmd[i].work THEN stationCommandFault := TRUE; END_IF;
END_FOR;
localValveFault[1] := fbPosM1.Diag.Fault; localValveFault[2] := fbStopM2.Diag.Fault;
localValveFault[3] := fbStopM3.Diag.Fault; localValveFault[4] := fbStopM4.Diag.Fault;
localValveFault[5] := fbPosM5.Diag.Fault; localValveFault[6] := fbV201.Diag.Fault;
localValveFault[7] := fbPosM7.Diag.Fault; localValveFault[8] := fbV202.Diag.Fault;
localValveFault[9] := fbLowerStop5.Diag.Fault; localValveFault[10] := fbLowerStop6.Diag.Fault;

autoGoRequest(CLK := elevCmd.xAutoGo);
IF autoGoRequest.Q AND transport.Sts.owner <> E_StationOwner.DRAIN THEN
 IF Context.station.nextOperationId < 16#FFFFFFFF THEN Context.station.nextOperationId := Context.station.nextOperationId + 1; productionElevatorId := Context.station.nextOperationId; ELSE reconcileRequired := TRUE; END_IF;
END_IF;
elevCmd.OperationId := productionElevatorId;
IF transport.Sts.owner = E_StationOwner.DRAIN AND (transport.Sts.action_ = E_StationAction.ELEV_TOP OR transport.Sts.action_ = E_StationAction.ELEV_BOTTOM) THEN elevCmd.OperationId := transport.Sts.operationId; END_IF;
fbElevator(
    xEnable := xGlobalEnable AND NOT plantNow.critical AND NOT alarms.Sts.critical AND NOT stationCommandFault,
    stCmd := elevCmd,
    stIn := elevIn,
    stPar := elevPar,
    stOut => elevOut,
    stStat => elevStat
);
uiElevState := TO_UINT(elevStat.eState);

(* Agregacja biezacych diagnoz dopiero po wszystkich wykonawcach, bez drugiego skanu FB. *)
plantNow.critical := plantNow.critical OR outputPolicy.Fault OR stationCommandFault OR elevStat.xFault OR
 fbConvTop.Diag.Fault OR fbConvElev.Diag.Fault OR fbConvBottom.Diag.Fault OR fbTraySeq.Diag.Fault OR fbBoxSeq.Diag.Fault;
(* Katalog 1..11: ostrzezenia silownikow, 12..28: klasy do uzgodnienia GAP-12. *)
alarmIn := Inp.station_AlarmInputs;
alarmIn.reset := xResetAll;
alarmIn.acknowledge := robot.Panel.StationKey = 26;
alarmIn.active[1] := fbPosM1.Diag.Fault OR stationCoils.RestartRequired[1]; alarmIn.active[2] := fbStopM2.Diag.Fault OR stationCoils.RestartRequired[2];
alarmIn.active[3] := fbStopM3.Diag.Fault OR stationCoils.RestartRequired[3]; alarmIn.active[4] := fbStopM4.Diag.Fault OR stationCoils.RestartRequired[4];
alarmIn.active[5] := fbPosM5.Diag.Fault OR stationCoils.RestartRequired[5]; alarmIn.active[6] := fbV201.Diag.Fault OR stationCoils.RestartRequired[6];
alarmIn.active[7] := fbV202.Diag.Fault OR stationCoils.RestartRequired[8]; alarmIn.active[8] := fbPosM7.Diag.Fault OR stationCoils.RestartRequired[7];
alarmIn.active[9] := fbLowerStop5.Diag.Fault OR stationCoils.RestartRequired[9]; alarmIn.active[10] := fbLowerStop6.Diag.Fault OR stationCoils.RestartRequired[10];
alarmIn.active[11] := fbStorage.Diag.Fault;
alarmIn.active[12] := NOT xSafetyOK; alarmIn.active[13] := Inp.io_di.ind_low_pressure;
alarmIn.active[14] := NOT Inp.robot_vfdCommHealthy; alarmIn.active[15] := elevStat.xFault;
alarmIn.active[16] := fbConvTop.Diag.Fault; alarmIn.active[17] := fbConvElev.Diag.Fault;
alarmIn.active[18] := fbConvBottom.Diag.Fault; alarmIn.active[19] := fbTopFlow.Diag.Fault;
alarmIn.active[20] := fbBottom567.Diag.Fault; alarmIn.active[21] := fbTraySeq.Diag.Fault;
alarmIn.active[22] := fbBoxSeq.Diag.Fault; alarmIn.active[23] := robot.Sts.diagnosticValid AND Inp.robot_Rx.production_fault;
alarmIn.active[24] := robot.Sts.diag.fault; alarmIn.active[25] := NOT io.Sts.valid;
alarmIn.active[26] := NOT material.Sts.known; alarmIn.active[27] := transport.Sts.fault;
alarmIn.active[28] := outputPolicy.Fault OR stationCommandFault;
alarmIn.active[29] := NOT Hmi.link.xArmed;
alarmIn.active[30] := NOT Inp.robot_Plant.imm.valid;
FOR i := 1 TO 5 DO
 alarmIn.active[i + 30] := robot.Sts.cylinders[i].fault;
 alarmIn.active[i + 35] := robot.Sts.vacuum[i].fault;
END_FOR;
FOR i := 1 TO 12 DO
 alarmIn.active[i + 40] := Cfg.station_IoCfg.required[i] AND NOT io.Sts.moduleValid[i];
END_FOR;
alarms(Cfg := Cfg.station_AlarmCfg, Inp := alarmIn);
Outp.station_Alarms := alarms.Sts;

currentCritical := plantNow.critical OR alarms.Sts.critical OR robot.Tx.production_criticalBlock OR
 NOT xSafetyOK OR NOT io.Sts.valid;
stationCoils(NewPermit := outputPermit, RestartPulse := localRestart.Q, LocalFault := localValveFault, LocalFaultPolicyVerified := Cfg.station_LocalFaultPolicyVerified,
    LocalFaultPolicy := Cfg.station_LocalFaultPolicy, UseCommandValid := TRUE, CommandValid := valveCommandValid, GateChanges := TRUE, ChangeAllowed := changeAllowed,
    Manual := xHmiManualMode, ManualActive := manualCoilActive,
    ReleaseVerified := Cfg.station_ManualReleaseVerified, ReleasePolicy := Cfg.station_ManualRelease, Critical := currentCritical OR robot.Recovery.Required,
    PolicyVerified := outputPolicy.StationLossReady,
    Cmd := stationCmd, LossPolicy := outputPolicy.StationLoss);
Outp.io_dout.ctrl_move_M1_actuator_forward := stationCoils.Applied[1].work;
Outp.io_dout.ctrl_move_M1_actuator_backward := stationCoils.Applied[1].home;
Outp.io_dout.ctrl_move_M2_actuator_forward := stationCoils.Applied[2].work;
Outp.io_dout.ctrl_move_M2_actuator_backward := stationCoils.Applied[2].home;
Outp.io_dout.ctrl_move_M3_actuator_forward := stationCoils.Applied[3].work;
Outp.io_dout.ctrl_move_M3_actuator_backward := stationCoils.Applied[3].home;
Outp.io_dout.ctrl_move_M4_actuator_forward := stationCoils.Applied[4].work;
Outp.io_dout.ctrl_move_M4_actuator_backward := stationCoils.Applied[4].home;
Outp.io_dout.ctrl_move_M5_actuator_forward := stationCoils.Applied[5].work;
Outp.io_dout.ctrl_move_M5_actuator_backward := stationCoils.Applied[5].home;
Outp.io_dout.ctrl_move_M6_actuator_forward := FALSE; // Legacy M6 odlaczony: dwa nowe wyjscia ponizej.
Outp.io_dout.ctrl_move_M6_actuator_backward := FALSE;
Outp.station_Coils := stationCoils.Applied;
Outp.station_LocalRestartRequired := stationCoils.RestartRequired;
Outp.station_V201Out := stationCoils.Applied[6]; Outp.station_V202Out := stationCoils.Applied[8];
Outp.station_LowerStopOut[1] := stationCoils.Applied[9]; Outp.station_LowerStopOut[2] := stationCoils.Applied[10];
Outp.io_dout.ctrl_move_M7_actuator_forward := stationCoils.Applied[7].work;
Outp.io_dout.ctrl_move_M7_actuator_backward := stationCoils.Applied[7].home;


Outp.hmi_hmiAlarmCount := alarms.Sts.count;
Outp.io_dout.ctrl_turn_on_light_red := alarms.Sts.critical OR plantNow.critical;
Outp.io_dout.ctrl_turn_on_light_yellow := alarms.Sts.warning OR robot.Sts.order.stopping;
Outp.io_dout.ctrl_turn_on_light_green := robot.Sts.order.running AND NOT Outp.io_dout.ctrl_turn_on_light_red;
Outp.io_dout.ctrl_turn_on_buzzer := Outp.io_dout.ctrl_turn_on_light_red;
Outp.io_dout.ctrl_LED_button_start_emptying_process := Outp.robot_singleUnloadReady;
panelIn.io := io.Sts; panelIn.material := material.Sts; panelIn.drain := fbStationDrain.Sts;
panelIn.transport := transport.Sts; panelIn.localReady := Outp.robot_singleUnloadReady;
panelIn.waitingPickup := fbBottom567.Sts.WaitingPickup; panelIn.idle := parameterIn.idle;
panelIn.manual := xHmiManualMode; panelIn.recovery := robot.Sts.recoveryRequired;
stationPanel(Inp := panelIn); Hmi.station := stationPanel.Sts;
Outp.hmi_hmiIo.dataValid := io.Sts.valid;
Outp.hmi_hmiIo.modules := io.Sts.moduleValid;
Outp.hmi_hmiIo.positionsValid := io.Sts.positionValid;
Outp.hmi_hmiIo.occupied := io.Sts.occupied;
Outp.hmi_hmiIo.barrierValid := io.Sts.barrierValid;
Outp.hmi_hmiIo.barrierBlocked := io.Sts.barrierBlocked;
Outp.hmi_hmiIo.appliedCoils := stationCoils.Applied;
Outp.hmi_hmiIo.alarms := alarms.Sts;
Hmi.permit.station1ParamApply.xAllowed := Hmi.link.xArmed AND stationPanel.Sts.canApply;
Hmi.permit.station1ParamApply.sReason := 'Wymagany potwierdzony postoj, zgodna rewizja i zakres nastaw.';
Hmi.permit.station2ParamApply.xAllowed := Hmi.link.xArmed AND stationPanel.Sts.canApply;
Hmi.permit.station2ParamApply.sReason := 'Wymagany potwierdzony postoj, zgodna rewizja i zakres nastaw.';
Hmi.permit.station3ParamApply.xAllowed := Hmi.link.xArmed AND stationPanel.Sts.canApply;
Hmi.permit.station3ParamApply.sReason := 'Wymagany potwierdzony postoj, zgodna rewizja i zakres nastaw.';
Hmi.permit.station4ParamApply.xAllowed := Hmi.link.xArmed AND stationPanel.Sts.canApply;
Hmi.permit.station4ParamApply.sReason := 'Wymagany potwierdzony postoj, zgodna rewizja i zakres nastaw.';
Hmi.permit.station1ParamReload.xAllowed := Hmi.link.xArmed;
Hmi.permit.station1ResetState.xAllowed := Hmi.link.xArmed AND stationPanel.Sts.canResetState;
Hmi.permit.station1ResetState.sReason := 'Manual i postoj; po resecie wymagane uzgodnienie ladunkow.';
Hmi.permit.station2ParamReload.xAllowed := Hmi.link.xArmed;
Hmi.permit.station2ResetState.xAllowed := Hmi.link.xArmed AND stationPanel.Sts.canResetState;
Hmi.permit.station2ResetState.sReason := 'Manual i postoj; po resecie wymagane uzgodnienie ladunkow.';
Hmi.permit.station3ParamReload.xAllowed := Hmi.link.xArmed;
Hmi.permit.station3ResetState.xAllowed := Hmi.link.xArmed AND stationPanel.Sts.canResetState;
Hmi.permit.station3ResetState.sReason := 'Manual i postoj; po resecie wymagane uzgodnienie ladunkow.';
Hmi.permit.station4ParamReload.xAllowed := Hmi.link.xArmed;
Hmi.permit.station4ResetState.xAllowed := Hmi.link.xArmed AND stationPanel.Sts.canResetState;
Hmi.permit.station4ResetState.sReason := 'Manual i postoj; po resecie wymagane uzgodnienie ladunkow.';
Hmi.permit.station5ParamReload.xAllowed := Hmi.link.xArmed;
Hmi.permit.station5ResetState.xAllowed := Hmi.link.xArmed AND stationPanel.Sts.canResetState;
Hmi.permit.station5ResetState.sReason := 'Manual i postoj; po resecie wymagane uzgodnienie ladunkow.';

(* Koncowa blokada transportu przed zapisem wyjsc, z biezacej diagnozy. *)
IF currentCritical THEN
 Outp.io_dout.ctrl_turn_on_top_conveyor := FALSE;
 Outp.io_dout.ctrl_turn_on_elevator_conveyor_in := FALSE; Outp.io_dout.ctrl_turn_on_elevator_conveyor_out := FALSE;
 Outp.io_dout.ctrl_turn_on_bottom_conveyor := FALSE; Outp.io_dout.ctrl_turn_on_bottom_conveyor_in := FALSE;
END_IF;

(* Końcowa finalizacja nie wykonuje ponownie timerów ani zdarzeń. *)
IF currentCritical THEN
 Outp.robot_Tx.production_newOperationPermit := FALSE; Outp.robot_Tx.production_finishPermit := FALSE;
 Outp.robot_Tx.production_criticalBlock := TRUE; Outp.robot_Tx.production_stopRequest := TRUE;
 Outp.robot_Tx.imm_newCyclePermit := FALSE;
 Outp.robot_Tx.area_source_granted := FALSE; Outp.robot_Tx.area_elevator_granted := FALSE; Outp.robot_Tx.area_storage_granted := FALSE;
 Outp.robot_Sts.order.newPermit := FALSE; Outp.robot_Sts.order.finishPermit := FALSE;
 Outp.robot_Sts.imm.mouldClose := FALSE; Outp.robot_Sts.imm.mouldFullOpen := FALSE;
 Outp.robot_Sts.imm.ejectorBack := FALSE; Outp.robot_Sts.imm.ejectorForward := FALSE;
 Outp.robot_Sts.imm.newCyclePermit := FALSE;
 Outp.robot_Tx.imm_applied_mouldClose := FALSE; Outp.robot_Tx.imm_applied_mouldFullOpen := FALSE;
 Outp.robot_Tx.imm_applied_ejectorBack := FALSE; Outp.robot_Tx.imm_applied_ejectorForward := FALSE;
 Outp.drive.forward := FALSE; Outp.drive.reverse := FALSE; Outp.drive.reference_ := 0;
  Outp.robot_storageOut.Q_UnlockRobotSide := FALSE; Outp.robot_storageOut.Q_UnlockOperatorSide := FALSE;
  Outp.robot_storageOut.Q_V401Home := outputPolicy.StorageLoss[1].home;
  Outp.robot_storageOut.Q_V401Work := outputPolicy.StorageLoss[1].work;
  Outp.robot_storageOut.Q_V402Home := outputPolicy.StorageLoss[2].home;
  Outp.robot_storageOut.Q_V402Work := outputPolicy.StorageLoss[2].work;
  Outp.io_dout.ctrl_open_spacer_storage_robot_side_lock := FALSE;
  Outp.io_dout.ctrl_open_spacer_storage_operator_side_lock := FALSE;
  FOR i := 1 TO 5 DO
   Outp.robot_Sts.cylinders[i].home := outputPolicy.CylinderLoss[i].home;
   Outp.robot_Sts.cylinders[i].work := outputPolicy.CylinderLoss[i].work;
   Outp.robot_Sts.cylinders[i].acceptedHome := FALSE; Outp.robot_Sts.cylinders[i].acceptedWork := FALSE;
   Outp.robot_Sts.cylinders[i].busy := FALSE;
   (* Zachowaj faktycznie zalaczona proznie; alarm nie jest poleceniem zrzutu ani nowego ssania. *)
   Outp.robot_Sts.vacuum[i].hold := appliedVacuumHold[i];
   Outp.robot_Sts.vacuum[i].blow := FALSE; Outp.robot_Sts.vacuum[i].accepted := FALSE;
   Outp.robot_Sts.vacuum[i].blowAck := FALSE; Outp.robot_Sts.vacuum[i].blowResult := 0;
   Outp.robot_Sts.vacuum[i].busy := FALSE;
 END_FOR;
ELSE
 FOR i := 1 TO 5 DO appliedVacuumHold[i] := Outp.robot_Sts.vacuum[i].hold; END_FOR;
END_IF;
Outp.robot_Tx.cyl_V501_acceptedWork := Outp.robot_Tx.cyl_V501_acceptedWork AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.vac_1_accepted := Outp.robot_Tx.vac_1_accepted AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.cyl_V501_acceptedHome := Outp.robot_Tx.cyl_V501_acceptedHome AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.cyl_V502_acceptedWork := Outp.robot_Tx.cyl_V502_acceptedWork AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.vac_2_accepted := Outp.robot_Tx.vac_2_accepted AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.cyl_V502_acceptedHome := Outp.robot_Tx.cyl_V502_acceptedHome AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.cyl_V503_acceptedWork := Outp.robot_Tx.cyl_V503_acceptedWork AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.vac_3_accepted := Outp.robot_Tx.vac_3_accepted AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.cyl_V503_acceptedHome := Outp.robot_Tx.cyl_V503_acceptedHome AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.cyl_V504_acceptedWork := Outp.robot_Tx.cyl_V504_acceptedWork AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.vac_4_accepted := Outp.robot_Tx.vac_4_accepted AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.cyl_V504_acceptedHome := Outp.robot_Tx.cyl_V504_acceptedHome AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.cyl_V505_acceptedWork := Outp.robot_Tx.cyl_V505_acceptedWork AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.vac_5_accepted := Outp.robot_Tx.vac_5_accepted AND NOT Outp.robot_Tx.production_criticalBlock;
Outp.robot_Tx.cyl_V505_acceptedHome := Outp.robot_Tx.cyl_V505_acceptedHome AND NOT Outp.robot_Tx.production_criticalBlock;

(* Biezace ostrzezenie odbiera zalezne granted, lecz nie rezerwacje obszaru. *)
IF fbStopM4.Diag.Fault OR fbPosM5.Diag.Fault OR stationCoils.RestartRequired[4] OR stationCoils.RestartRequired[5] THEN
 Outp.robot_Tx.area_source_granted := FALSE; Outp.robot_Sts.areas[1].granted := FALSE;
END_IF;
IF fbV201.Diag.Fault OR fbV202.Diag.Fault OR fbPosM7.Diag.Fault OR
 stationCoils.RestartRequired[6] OR stationCoils.RestartRequired[7] OR stationCoils.RestartRequired[8] THEN
 Outp.robot_Tx.area_elevator_granted := FALSE; Outp.robot_Sts.areas[2].granted := FALSE;
END_IF;
Outp.robot_Tx.area_storage_granted := Outp.robot_Tx.area_storage_granted AND fbStorage.Sts.RobotAccessGranted AND NOT fbStorage.Diag.Fault;
Outp.robot_Sts.areas[3].granted := Outp.robot_Sts.areas[3].granted AND Outp.robot_Tx.area_storage_granted;
(* applied oznacza koncowa komende PLC po wszystkich blokadach; nie pomiar cewki. *)
Outp.robot_Tx.vac_1_holdApplied := Outp.robot_Sts.vacuum[1].hold;
Outp.robot_Tx.vac_1_blowAck := Outp.robot_Sts.vacuum[1].blowAck;
Outp.robot_Tx.vac_1_blowResult := Outp.robot_Sts.vacuum[1].blowResult;
Outp.robot_Tx.cyl_V501_busy := Outp.robot_Sts.cylinders[1].busy;
Outp.robot_Tx.vac_1_busy := Outp.robot_Sts.vacuum[1].busy;
Outp.robot_Tx.vac_2_holdApplied := Outp.robot_Sts.vacuum[2].hold;
Outp.robot_Tx.vac_2_blowAck := Outp.robot_Sts.vacuum[2].blowAck;
Outp.robot_Tx.vac_2_blowResult := Outp.robot_Sts.vacuum[2].blowResult;
Outp.robot_Tx.cyl_V502_busy := Outp.robot_Sts.cylinders[2].busy;
Outp.robot_Tx.vac_2_busy := Outp.robot_Sts.vacuum[2].busy;
Outp.robot_Tx.vac_3_holdApplied := Outp.robot_Sts.vacuum[3].hold;
Outp.robot_Tx.vac_3_blowAck := Outp.robot_Sts.vacuum[3].blowAck;
Outp.robot_Tx.vac_3_blowResult := Outp.robot_Sts.vacuum[3].blowResult;
Outp.robot_Tx.cyl_V503_busy := Outp.robot_Sts.cylinders[3].busy;
Outp.robot_Tx.vac_3_busy := Outp.robot_Sts.vacuum[3].busy;
Outp.robot_Tx.vac_4_holdApplied := Outp.robot_Sts.vacuum[4].hold;
Outp.robot_Tx.vac_4_blowAck := Outp.robot_Sts.vacuum[4].blowAck;
Outp.robot_Tx.vac_4_blowResult := Outp.robot_Sts.vacuum[4].blowResult;
Outp.robot_Tx.cyl_V504_busy := Outp.robot_Sts.cylinders[4].busy;
Outp.robot_Tx.vac_4_busy := Outp.robot_Sts.vacuum[4].busy;
Outp.robot_Tx.vac_5_holdApplied := Outp.robot_Sts.vacuum[5].hold;
Outp.robot_Tx.vac_5_blowAck := Outp.robot_Sts.vacuum[5].blowAck;
Outp.robot_Tx.vac_5_blowResult := Outp.robot_Sts.vacuum[5].blowResult;
Outp.robot_Tx.cyl_V505_busy := Outp.robot_Sts.cylinders[5].busy;
Outp.robot_Tx.vac_5_busy := Outp.robot_Sts.vacuum[5].busy;
Outp.hmi_hmiStatus.xOccP4 := material.Sts.occupied[4];
Outp.hmi_hmiStatus.uiElevState := uiElevState;
Outp.hmi_hmiStatus.xElevBusy := elevStat.xBusy;
Outp.hmi_hmiStatus.xElevFault := elevStat.xFault;
Outp.hmi_hmiStatus.rElevFreq_Hz := elevStat.rVfdOutHz;
Outp.hmi_hmiStatus.sElevDiagText := elevStat.sDiagText;
Outp.hmi_hmiStatus.xGlobalEnable := xGlobalEnable AND NOT currentCritical;
Outp.io_dout.ctrl_turn_on_light_red := currentCritical;
Outp.io_dout.ctrl_turn_on_light_green := robot.Sts.order.running AND NOT currentCritical;
Outp.io_dout.ctrl_turn_on_buzzer := currentCritical;

(* Wejscia diagnostyczne z adaptera: wartosc i waznosc oddzielnie. *)
Outp.hmi_hmiIo.value.ind_loading_elevator_1_left_in_home_position := Inp.station_DiagnosticValue.ind_loading_elevator_1_left_in_home_position;
Outp.hmi_hmiIo.valid.ind_loading_elevator_1_left_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_elevator_1_left_in_home_position;
Outp.hmi_hmiIo.value.ind_loading_elevator_1_left_in_work_position := Inp.station_DiagnosticValue.ind_loading_elevator_1_left_in_work_position;
Outp.hmi_hmiIo.valid.ind_loading_elevator_1_left_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_elevator_1_left_in_work_position;
Outp.hmi_hmiIo.value.ind_loading_elevator_1_right_in_home_position := Inp.station_DiagnosticValue.ind_loading_elevator_1_right_in_home_position;
Outp.hmi_hmiIo.valid.ind_loading_elevator_1_right_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_elevator_1_right_in_home_position;
Outp.hmi_hmiIo.value.ind_loading_elevator_1_right_in_work_position := Inp.station_DiagnosticValue.ind_loading_elevator_1_right_in_work_position;
Outp.hmi_hmiIo.valid.ind_loading_elevator_1_right_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_elevator_1_right_in_work_position;
Outp.hmi_hmiIo.value.ind_loading_elevator_2_left_in_home_position := Inp.station_DiagnosticValue.ind_loading_elevator_2_left_in_home_position;
Outp.hmi_hmiIo.valid.ind_loading_elevator_2_left_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_elevator_2_left_in_home_position;
Outp.hmi_hmiIo.value.ind_loading_elevator_2_left_in_work_position := Inp.station_DiagnosticValue.ind_loading_elevator_2_left_in_work_position;
Outp.hmi_hmiIo.valid.ind_loading_elevator_2_left_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_elevator_2_left_in_work_position;
Outp.hmi_hmiIo.value.ind_loading_elevator_2_right_in_home_position := Inp.station_DiagnosticValue.ind_loading_elevator_2_right_in_home_position;
Outp.hmi_hmiIo.valid.ind_loading_elevator_2_right_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_elevator_2_right_in_home_position;
Outp.hmi_hmiIo.value.ind_loading_elevator_2_right_in_work_position := Inp.station_DiagnosticValue.ind_loading_elevator_2_right_in_work_position;
Outp.hmi_hmiIo.valid.ind_loading_elevator_2_right_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_elevator_2_right_in_work_position;
Outp.hmi_hmiIo.value.ind_loading_elevator_3_left_in_home_position := Inp.station_DiagnosticValue.ind_loading_elevator_3_left_in_home_position;
Outp.hmi_hmiIo.valid.ind_loading_elevator_3_left_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_elevator_3_left_in_home_position;
Outp.hmi_hmiIo.value.ind_loading_elevator_3_left_in_work_position := Inp.station_DiagnosticValue.ind_loading_elevator_3_left_in_work_position;
Outp.hmi_hmiIo.valid.ind_loading_elevator_3_left_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_elevator_3_left_in_work_position;
Outp.hmi_hmiIo.value.ind_loading_elevator_3_right_in_home_position := Inp.station_DiagnosticValue.ind_loading_elevator_3_right_in_home_position;
Outp.hmi_hmiIo.valid.ind_loading_elevator_3_right_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_elevator_3_right_in_home_position;
Outp.hmi_hmiIo.value.ind_loading_elevator_3_right_in_work_position := Inp.station_DiagnosticValue.ind_loading_elevator_3_right_in_work_position;
Outp.hmi_hmiIo.valid.ind_loading_elevator_3_right_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_elevator_3_right_in_work_position;
Outp.hmi_hmiIo.value.ind_loading_stopper_1_left_in_home_position := Inp.station_DiagnosticValue.ind_loading_stopper_1_left_in_home_position;
Outp.hmi_hmiIo.valid.ind_loading_stopper_1_left_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_stopper_1_left_in_home_position;
Outp.hmi_hmiIo.value.ind_loading_stopper_1_left_in_work_position := Inp.station_DiagnosticValue.ind_loading_stopper_1_left_in_work_position;
Outp.hmi_hmiIo.valid.ind_loading_stopper_1_left_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_stopper_1_left_in_work_position;
Outp.hmi_hmiIo.value.ind_loading_stopper_1_right_in_home_position := Inp.station_DiagnosticValue.ind_loading_stopper_1_right_in_home_position;
Outp.hmi_hmiIo.valid.ind_loading_stopper_1_right_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_stopper_1_right_in_home_position;
Outp.hmi_hmiIo.value.ind_loading_stopper_1_right_in_work_position := Inp.station_DiagnosticValue.ind_loading_stopper_1_right_in_work_position;
Outp.hmi_hmiIo.valid.ind_loading_stopper_1_right_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_stopper_1_right_in_work_position;
Outp.hmi_hmiIo.value.ind_loading_stopper_2_left_in_home_position := Inp.station_DiagnosticValue.ind_loading_stopper_2_left_in_home_position;
Outp.hmi_hmiIo.valid.ind_loading_stopper_2_left_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_stopper_2_left_in_home_position;
Outp.hmi_hmiIo.value.ind_loading_stopper_2_left_in_work_position := Inp.station_DiagnosticValue.ind_loading_stopper_2_left_in_work_position;
Outp.hmi_hmiIo.valid.ind_loading_stopper_2_left_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_stopper_2_left_in_work_position;
Outp.hmi_hmiIo.value.ind_loading_stopper_2_right_in_home_position := Inp.station_DiagnosticValue.ind_loading_stopper_2_right_in_home_position;
Outp.hmi_hmiIo.valid.ind_loading_stopper_2_right_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_stopper_2_right_in_home_position;
Outp.hmi_hmiIo.value.ind_loading_stopper_2_right_in_work_position := Inp.station_DiagnosticValue.ind_loading_stopper_2_right_in_work_position;
Outp.hmi_hmiIo.valid.ind_loading_stopper_2_right_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_loading_stopper_2_right_in_work_position;
Outp.hmi_hmiIo.value.ind_container_in_loading_position_1 := Inp.station_DiagnosticValue.ind_container_in_loading_position_1;
Outp.hmi_hmiIo.valid.ind_container_in_loading_position_1 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_container_in_loading_position_1;
Outp.hmi_hmiIo.value.ind_container_in_loading_position_2 := Inp.station_DiagnosticValue.ind_container_in_loading_position_2;
Outp.hmi_hmiIo.valid.ind_container_in_loading_position_2 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_container_in_loading_position_2;
Outp.hmi_hmiIo.value.ind_container_in_loading_position_3 := Inp.station_DiagnosticValue.ind_container_in_loading_position_3;
Outp.hmi_hmiIo.valid.ind_container_in_loading_position_3 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_container_in_loading_position_3;
Outp.hmi_hmiIo.value.ind_blister_positioner_left_in_home_position := Inp.station_DiagnosticValue.ind_blister_positioner_left_in_home_position;
Outp.hmi_hmiIo.valid.ind_blister_positioner_left_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_blister_positioner_left_in_home_position;
Outp.hmi_hmiIo.value.ind_blister_positioner_left_in_work_position := Inp.station_DiagnosticValue.ind_blister_positioner_left_in_work_position;
Outp.hmi_hmiIo.valid.ind_blister_positioner_left_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_blister_positioner_left_in_work_position;
Outp.hmi_hmiIo.value.ind_blister_positioner_right_in_home_position := Inp.station_DiagnosticValue.ind_blister_positioner_right_in_home_position;
Outp.hmi_hmiIo.valid.ind_blister_positioner_right_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_blister_positioner_right_in_home_position;
Outp.hmi_hmiIo.value.ind_blister_positioner_right_in_work_position := Inp.station_DiagnosticValue.ind_blister_positioner_right_in_work_position;
Outp.hmi_hmiIo.valid.ind_blister_positioner_right_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_blister_positioner_right_in_work_position;
Outp.hmi_hmiIo.value.ind_blue_box_positioner_left_in_home_position := Inp.station_DiagnosticValue.ind_blue_box_positioner_left_in_home_position;
Outp.hmi_hmiIo.valid.ind_blue_box_positioner_left_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_blue_box_positioner_left_in_home_position;
Outp.hmi_hmiIo.value.ind_blue_box_positioner_left_in_work_position := Inp.station_DiagnosticValue.ind_blue_box_positioner_left_in_work_position;
Outp.hmi_hmiIo.valid.ind_blue_box_positioner_left_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_blue_box_positioner_left_in_work_position;
Outp.hmi_hmiIo.value.ind_elevator_in_top_position := Inp.station_DiagnosticValue.ind_elevator_in_top_position;
Outp.hmi_hmiIo.valid.ind_elevator_in_top_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_elevator_in_top_position;
Outp.hmi_hmiIo.value.ind_elevator_in_intermediate_top_position := Inp.station_DiagnosticValue.ind_elevator_in_intermediate_top_position;
Outp.hmi_hmiIo.valid.ind_elevator_in_intermediate_top_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_elevator_in_intermediate_top_position;
Outp.hmi_hmiIo.value.ind_elevator_in_intermediate_bottom_position := Inp.station_DiagnosticValue.ind_elevator_in_intermediate_bottom_position;
Outp.hmi_hmiIo.valid.ind_elevator_in_intermediate_bottom_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_elevator_in_intermediate_bottom_position;
Outp.hmi_hmiIo.value.ind_elevator_in_bottom_position := Inp.station_DiagnosticValue.ind_elevator_in_bottom_position;
Outp.hmi_hmiIo.valid.ind_elevator_in_bottom_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_elevator_in_bottom_position;
Outp.hmi_hmiIo.value.ind_container_in_elevator_position := Inp.station_DiagnosticValue.ind_container_in_elevator_position;
Outp.hmi_hmiIo.valid.ind_container_in_elevator_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_container_in_elevator_position;
Outp.hmi_hmiIo.value.ind_unloading_stopper_1_left_in_home_position := Inp.station_DiagnosticValue.ind_unloading_stopper_1_left_in_home_position;
Outp.hmi_hmiIo.valid.ind_unloading_stopper_1_left_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_unloading_stopper_1_left_in_home_position;
Outp.hmi_hmiIo.value.ind_unloading_stopper_1_left_in_work_position := Inp.station_DiagnosticValue.ind_unloading_stopper_1_left_in_work_position;
Outp.hmi_hmiIo.valid.ind_unloading_stopper_1_left_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_unloading_stopper_1_left_in_work_position;
Outp.hmi_hmiIo.value.ind_unloading_stopper_1_right_in_home_position := Inp.station_DiagnosticValue.ind_unloading_stopper_1_right_in_home_position;
Outp.hmi_hmiIo.valid.ind_unloading_stopper_1_right_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_unloading_stopper_1_right_in_home_position;
Outp.hmi_hmiIo.value.ind_unloading_stopper_1_right_in_work_position := Inp.station_DiagnosticValue.ind_unloading_stopper_1_right_in_work_position;
Outp.hmi_hmiIo.valid.ind_unloading_stopper_1_right_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_unloading_stopper_1_right_in_work_position;
Outp.hmi_hmiIo.value.ind_unloading_stopper_2_left_in_home_position := Inp.station_DiagnosticValue.ind_unloading_stopper_2_left_in_home_position;
Outp.hmi_hmiIo.valid.ind_unloading_stopper_2_left_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_unloading_stopper_2_left_in_home_position;
Outp.hmi_hmiIo.value.ind_unloading_stopper_2_left_in_work_position := Inp.station_DiagnosticValue.ind_unloading_stopper_2_left_in_work_position;
Outp.hmi_hmiIo.valid.ind_unloading_stopper_2_left_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_unloading_stopper_2_left_in_work_position;
Outp.hmi_hmiIo.value.ind_unloading_stopper_2_right_in_home_position := Inp.station_DiagnosticValue.ind_unloading_stopper_2_right_in_home_position;
Outp.hmi_hmiIo.valid.ind_unloading_stopper_2_right_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_unloading_stopper_2_right_in_home_position;
Outp.hmi_hmiIo.value.ind_unloading_stopper_2_right_in_work_position := Inp.station_DiagnosticValue.ind_unloading_stopper_2_right_in_work_position;
Outp.hmi_hmiIo.valid.ind_unloading_stopper_2_right_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_unloading_stopper_2_right_in_work_position;
Outp.hmi_hmiIo.value.ind_elevator_unloading_area_empty := Inp.station_DiagnosticValue.ind_elevator_unloading_area_empty;
Outp.hmi_hmiIo.valid.ind_elevator_unloading_area_empty := io.Sts.valid AND Inp.station_DiagnosticValid.ind_elevator_unloading_area_empty;
Outp.hmi_hmiIo.value.ind_container_in_unloading_position_1 := Inp.station_DiagnosticValue.ind_container_in_unloading_position_1;
Outp.hmi_hmiIo.valid.ind_container_in_unloading_position_1 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_container_in_unloading_position_1;
Outp.hmi_hmiIo.value.ind_container_in_unloading_position_2 := Inp.station_DiagnosticValue.ind_container_in_unloading_position_2;
Outp.hmi_hmiIo.valid.ind_container_in_unloading_position_2 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_container_in_unloading_position_2;
Outp.hmi_hmiIo.value.ind_container_in_unloading_position_3 := Inp.station_DiagnosticValue.ind_container_in_unloading_position_3;
Outp.hmi_hmiIo.valid.ind_container_in_unloading_position_3 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_container_in_unloading_position_3;
Outp.hmi_hmiIo.value.ind_spacer_barrier_left_in_home_position := Inp.station_DiagnosticValue.ind_spacer_barrier_left_in_home_position;
Outp.hmi_hmiIo.valid.ind_spacer_barrier_left_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_spacer_barrier_left_in_home_position;
Outp.hmi_hmiIo.value.ind_spacer_barrier_left_in_work_position := Inp.station_DiagnosticValue.ind_spacer_barrier_left_in_work_position;
Outp.hmi_hmiIo.valid.ind_spacer_barrier_left_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_spacer_barrier_left_in_work_position;
Outp.hmi_hmiIo.value.ind_spacer_barrier_right_in_home_position := Inp.station_DiagnosticValue.ind_spacer_barrier_right_in_home_position;
Outp.hmi_hmiIo.valid.ind_spacer_barrier_right_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_spacer_barrier_right_in_home_position;
Outp.hmi_hmiIo.value.ind_spacer_barrier_right_in_work_position := Inp.station_DiagnosticValue.ind_spacer_barrier_right_in_work_position;
Outp.hmi_hmiIo.valid.ind_spacer_barrier_right_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_spacer_barrier_right_in_work_position;
Outp.hmi_hmiIo.value.ind_low_level_of_spacers := Inp.station_DiagnosticValue.ind_low_level_of_spacers;
Outp.hmi_hmiIo.valid.ind_low_level_of_spacers := io.Sts.valid AND Inp.station_DiagnosticValid.ind_low_level_of_spacers;
Outp.hmi_hmiIo.value.ind_spacer_storage_empty := Inp.station_DiagnosticValue.ind_spacer_storage_empty;
Outp.hmi_hmiIo.valid.ind_spacer_storage_empty := io.Sts.valid AND Inp.station_DiagnosticValid.ind_spacer_storage_empty;
Outp.hmi_hmiIo.value.ind_robot_axis_7_in_home_position := Inp.station_DiagnosticValue.ind_robot_axis_7_in_home_position;
Outp.hmi_hmiIo.valid.ind_robot_axis_7_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_axis_7_in_home_position;
Outp.hmi_hmiIo.value.ind_robot_axis_7_in_work_position := Inp.station_DiagnosticValue.ind_robot_axis_7_in_work_position;
Outp.hmi_hmiIo.valid.ind_robot_axis_7_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_axis_7_in_work_position;
Outp.hmi_hmiIo.value.ind_robot_gripper_1_in_home_position := Inp.station_DiagnosticValue.ind_robot_gripper_1_in_home_position;
Outp.hmi_hmiIo.valid.ind_robot_gripper_1_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_gripper_1_in_home_position;
Outp.hmi_hmiIo.value.ind_robot_gripper_1_in_work_position := Inp.station_DiagnosticValue.ind_robot_gripper_1_in_work_position;
Outp.hmi_hmiIo.valid.ind_robot_gripper_1_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_gripper_1_in_work_position;
Outp.hmi_hmiIo.value.ind_robot_gripper_2_in_home_position := Inp.station_DiagnosticValue.ind_robot_gripper_2_in_home_position;
Outp.hmi_hmiIo.valid.ind_robot_gripper_2_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_gripper_2_in_home_position;
Outp.hmi_hmiIo.value.ind_robot_gripper_2_in_work_position := Inp.station_DiagnosticValue.ind_robot_gripper_2_in_work_position;
Outp.hmi_hmiIo.valid.ind_robot_gripper_2_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_gripper_2_in_work_position;
Outp.hmi_hmiIo.value.ind_robot_gripper_3_in_home_position := Inp.station_DiagnosticValue.ind_robot_gripper_3_in_home_position;
Outp.hmi_hmiIo.valid.ind_robot_gripper_3_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_gripper_3_in_home_position;
Outp.hmi_hmiIo.value.ind_robot_gripper_3_in_work_position := Inp.station_DiagnosticValue.ind_robot_gripper_3_in_work_position;
Outp.hmi_hmiIo.valid.ind_robot_gripper_3_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_gripper_3_in_work_position;
Outp.hmi_hmiIo.value.ind_robot_gripper_4_in_home_position := Inp.station_DiagnosticValue.ind_robot_gripper_4_in_home_position;
Outp.hmi_hmiIo.valid.ind_robot_gripper_4_in_home_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_gripper_4_in_home_position;
Outp.hmi_hmiIo.value.ind_robot_gripper_4_in_work_position := Inp.station_DiagnosticValue.ind_robot_gripper_4_in_work_position;
Outp.hmi_hmiIo.valid.ind_robot_gripper_4_in_work_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_gripper_4_in_work_position;
Outp.hmi_hmiIo.value.ind_e67_imm_reject := Inp.station_DiagnosticValue.ind_e67_imm_reject;
Outp.hmi_hmiIo.valid.ind_e67_imm_reject := io.Sts.valid AND Inp.station_DiagnosticValid.ind_e67_imm_reject;
Outp.hmi_hmiIo.value.ind_e67_imm_mould_closed := Inp.station_DiagnosticValue.ind_e67_imm_mould_closed;
Outp.hmi_hmiIo.valid.ind_e67_imm_mould_closed := io.Sts.valid AND Inp.station_DiagnosticValid.ind_e67_imm_mould_closed;
Outp.hmi_hmiIo.value.ind_e67_imm_mould_open := Inp.station_DiagnosticValue.ind_e67_imm_mould_open;
Outp.hmi_hmiIo.valid.ind_e67_imm_mould_open := io.Sts.valid AND Inp.station_DiagnosticValid.ind_e67_imm_mould_open;
Outp.hmi_hmiIo.value.ind_e67_imm_mould_in_intermediate_position := Inp.station_DiagnosticValue.ind_e67_imm_mould_in_intermediate_position;
Outp.hmi_hmiIo.valid.ind_e67_imm_mould_in_intermediate_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_e67_imm_mould_in_intermediate_position;
Outp.hmi_hmiIo.value.ind_e67_imm_operation_with_robot_enabled := Inp.station_DiagnosticValue.ind_e67_imm_operation_with_robot_enabled;
Outp.hmi_hmiIo.valid.ind_e67_imm_operation_with_robot_enabled := io.Sts.valid AND Inp.station_DiagnosticValid.ind_e67_imm_operation_with_robot_enabled;
Outp.hmi_hmiIo.value.ind_e67_imm_ejector_in_back_position := Inp.station_DiagnosticValue.ind_e67_imm_ejector_in_back_position;
Outp.hmi_hmiIo.valid.ind_e67_imm_ejector_in_back_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_e67_imm_ejector_in_back_position;
Outp.hmi_hmiIo.value.ind_e67_imm_ejector_in_forward_position := Inp.station_DiagnosticValue.ind_e67_imm_ejector_in_forward_position;
Outp.hmi_hmiIo.valid.ind_e67_imm_ejector_in_forward_position := io.Sts.valid AND Inp.station_DiagnosticValid.ind_e67_imm_ejector_in_forward_position;
Outp.hmi_hmiIo.value.ind_e67_imm_core_1_in_position_1 := Inp.station_DiagnosticValue.ind_e67_imm_core_1_in_position_1;
Outp.hmi_hmiIo.valid.ind_e67_imm_core_1_in_position_1 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_e67_imm_core_1_in_position_1;
Outp.hmi_hmiIo.value.ind_e67_imm_core_1_in_position_2 := Inp.station_DiagnosticValue.ind_e67_imm_core_1_in_position_2;
Outp.hmi_hmiIo.valid.ind_e67_imm_core_1_in_position_2 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_e67_imm_core_1_in_position_2;
Outp.hmi_hmiIo.value.ind_e67_imm_core_2_in_position_1 := Inp.station_DiagnosticValue.ind_e67_imm_core_2_in_position_1;
Outp.hmi_hmiIo.valid.ind_e67_imm_core_2_in_position_1 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_e67_imm_core_2_in_position_1;
Outp.hmi_hmiIo.value.ind_e67_imm_core_2_in_position_2 := Inp.station_DiagnosticValue.ind_e67_imm_core_2_in_position_2;
Outp.hmi_hmiIo.valid.ind_e67_imm_core_2_in_position_2 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_e67_imm_core_2_in_position_2;
Outp.hmi_hmiIo.value.ind_robot_mould_closed := Inp.station_DiagnosticValue.ind_robot_mould_closed;
Outp.hmi_hmiIo.valid.ind_robot_mould_closed := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_mould_closed;
Outp.hmi_hmiIo.value.ind_robot_mould_open := Inp.station_DiagnosticValue.ind_robot_mould_open;
Outp.hmi_hmiIo.valid.ind_robot_mould_open := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_mould_open;
Outp.hmi_hmiIo.value.ind_robot_operation_with_imm_enabled := Inp.station_DiagnosticValue.ind_robot_operation_with_imm_enabled;
Outp.hmi_hmiIo.valid.ind_robot_operation_with_imm_enabled := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_operation_with_imm_enabled;
Outp.hmi_hmiIo.value.ind_robot_mould_area_free := Inp.station_DiagnosticValue.ind_robot_mould_area_free;
Outp.hmi_hmiIo.valid.ind_robot_mould_area_free := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_mould_area_free;
Outp.hmi_hmiIo.value.ind_robot_enable_mould_closure := Inp.station_DiagnosticValue.ind_robot_enable_mould_closure;
Outp.hmi_hmiIo.valid.ind_robot_enable_mould_closure := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_enable_mould_closure;
Outp.hmi_hmiIo.value.ind_robot_kf403_tbd := Inp.station_DiagnosticValue.ind_robot_kf403_tbd;
Outp.hmi_hmiIo.valid.ind_robot_kf403_tbd := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_kf403_tbd;
Outp.hmi_hmiIo.value.ind_robot_reserved_output_1 := Inp.station_DiagnosticValue.ind_robot_reserved_output_1;
Outp.hmi_hmiIo.valid.ind_robot_reserved_output_1 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_reserved_output_1;
Outp.hmi_hmiIo.value.ind_robot_reserved_output_2 := Inp.station_DiagnosticValue.ind_robot_reserved_output_2;
Outp.hmi_hmiIo.valid.ind_robot_reserved_output_2 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_reserved_output_2;
Outp.hmi_hmiIo.value.ind_robot_reserved_output_3 := Inp.station_DiagnosticValue.ind_robot_reserved_output_3;
Outp.hmi_hmiIo.valid.ind_robot_reserved_output_3 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_reserved_output_3;
Outp.hmi_hmiIo.value.ind_robot_reserved_output_4 := Inp.station_DiagnosticValue.ind_robot_reserved_output_4;
Outp.hmi_hmiIo.valid.ind_robot_reserved_output_4 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_reserved_output_4;
Outp.hmi_hmiIo.value.ind_robot_reserved_output_5 := Inp.station_DiagnosticValue.ind_robot_reserved_output_5;
Outp.hmi_hmiIo.valid.ind_robot_reserved_output_5 := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_reserved_output_5;
Outp.hmi_hmiIo.value.ind_button_open_close_spacer_storage := Inp.station_DiagnosticValue.ind_button_open_close_spacer_storage;
Outp.hmi_hmiIo.valid.ind_button_open_close_spacer_storage := io.Sts.valid AND Inp.station_DiagnosticValid.ind_button_open_close_spacer_storage;
Outp.hmi_hmiIo.value.ind_button_samples := Inp.station_DiagnosticValue.ind_button_samples;
Outp.hmi_hmiIo.valid.ind_button_samples := io.Sts.valid AND Inp.station_DiagnosticValid.ind_button_samples;
Outp.hmi_hmiIo.value.ind_button_continue_process := Inp.station_DiagnosticValue.ind_button_continue_process;
Outp.hmi_hmiIo.valid.ind_button_continue_process := io.Sts.valid AND Inp.station_DiagnosticValid.ind_button_continue_process;
Outp.hmi_hmiIo.value.ind_button_start_process := Inp.station_DiagnosticValue.ind_button_start_process;
Outp.hmi_hmiIo.valid.ind_button_start_process := io.Sts.valid AND Inp.station_DiagnosticValid.ind_button_start_process;
Outp.hmi_hmiIo.value.ind_button_container_ready := Inp.station_DiagnosticValue.ind_button_container_ready;
Outp.hmi_hmiIo.valid.ind_button_container_ready := io.Sts.valid AND Inp.station_DiagnosticValid.ind_button_container_ready;
Outp.hmi_hmiIo.value.ind_button_start_emptying_process := Inp.station_DiagnosticValue.ind_button_start_emptying_process;
Outp.hmi_hmiIo.valid.ind_button_start_emptying_process := io.Sts.valid AND Inp.station_DiagnosticValid.ind_button_start_emptying_process;
Outp.hmi_hmiIo.value.ind_button_open_close_robot_cell_doors := Inp.station_DiagnosticValue.ind_button_open_close_robot_cell_doors;
Outp.hmi_hmiIo.valid.ind_button_open_close_robot_cell_doors := io.Sts.valid AND Inp.station_DiagnosticValid.ind_button_open_close_robot_cell_doors;
Outp.hmi_hmiIo.value.ind_robot_cell_doors_closed := Inp.station_DiagnosticValue.ind_robot_cell_doors_closed;
Outp.hmi_hmiIo.valid.ind_robot_cell_doors_closed := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_cell_doors_closed;
Outp.hmi_hmiIo.value.ind_robot_cell_doors_locked := Inp.station_DiagnosticValue.ind_robot_cell_doors_locked;
Outp.hmi_hmiIo.valid.ind_robot_cell_doors_locked := io.Sts.valid AND Inp.station_DiagnosticValid.ind_robot_cell_doors_locked;
Outp.hmi_hmiIo.value.ind_spacer_storage_robot_side_doors_opening_permission := Inp.station_DiagnosticValue.ind_spacer_storage_robot_side_doors_opening_permission;
Outp.hmi_hmiIo.valid.ind_spacer_storage_robot_side_doors_opening_permission := io.Sts.valid AND Inp.station_DiagnosticValid.ind_spacer_storage_robot_side_doors_opening_permission;
Outp.hmi_hmiIo.value.ind_spacer_storage_operator_side_doors_opening_permission := Inp.station_DiagnosticValue.ind_spacer_storage_operator_side_doors_opening_permission;
Outp.hmi_hmiIo.valid.ind_spacer_storage_operator_side_doors_opening_permission := io.Sts.valid AND Inp.station_DiagnosticValid.ind_spacer_storage_operator_side_doors_opening_permission;
Outp.hmi_hmiIo.value.ctrl_move_loading_elevator_1_to_work_position := stationCoils.Applied[2].work;
Outp.hmi_hmiIo.valid.ctrl_move_loading_elevator_1_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_loading_elevator_2_to_work_position := stationCoils.Applied[3].work;
Outp.hmi_hmiIo.valid.ctrl_move_loading_elevator_2_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_loading_elevator_3_to_work_position := stationCoils.Applied[4].work;
Outp.hmi_hmiIo.valid.ctrl_move_loading_elevator_3_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_loading_stopper_1_to_work_position := stationCoils.Applied[1].work;
Outp.hmi_hmiIo.valid.ctrl_move_loading_stopper_1_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_loading_stopper_2_to_work_position := stationCoils.Applied[5].work;
Outp.hmi_hmiIo.valid.ctrl_move_loading_stopper_2_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_blister_positioner_left_to_work_position := stationCoils.Applied[6].work;
Outp.hmi_hmiIo.valid.ctrl_move_blister_positioner_left_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_blister_positioner_right_to_work_position := stationCoils.Applied[8].work;
Outp.hmi_hmiIo.valid.ctrl_move_blister_positioner_right_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_blue_box_positioner_left_to_work_position := stationCoils.Applied[7].work;
Outp.hmi_hmiIo.valid.ctrl_move_blue_box_positioner_left_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_unloading_stopper_1_to_work_position := stationCoils.Applied[9].work;
Outp.hmi_hmiIo.valid.ctrl_move_unloading_stopper_1_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_unloading_stopper_2_to_work_position := stationCoils.Applied[10].work;
Outp.hmi_hmiIo.valid.ctrl_move_unloading_stopper_2_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_spacer_barrier_left_to_work_position := Outp.robot_storageOut.Q_V401Work;
Outp.hmi_hmiIo.valid.ctrl_move_spacer_barrier_left_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_spacer_barrier_right_to_work_position := Outp.robot_storageOut.Q_V402Work;
Outp.hmi_hmiIo.valid.ctrl_move_spacer_barrier_right_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_robot_axis_7_to_work_position := Outp.robot_Sts.cylinders[1].work;
Outp.hmi_hmiIo.valid.ctrl_move_robot_axis_7_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_robot_gripper_1_to_work_position := Outp.robot_Sts.cylinders[2].work;
Outp.hmi_hmiIo.valid.ctrl_move_robot_gripper_1_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_robot_gripper_2_to_work_position := Outp.robot_Sts.cylinders[3].work;
Outp.hmi_hmiIo.valid.ctrl_move_robot_gripper_2_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_robot_gripper_3_to_work_position := Outp.robot_Sts.cylinders[4].work;
Outp.hmi_hmiIo.valid.ctrl_move_robot_gripper_3_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_move_robot_gripper_4_to_work_position := Outp.robot_Sts.cylinders[5].work;
Outp.hmi_hmiIo.valid.ctrl_move_robot_gripper_4_to_work_position := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_spare_v506 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_spare_v506 := FALSE;
Outp.hmi_hmiIo.value.ctrl_spare_v507 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_spare_v507 := FALSE;
Outp.hmi_hmiIo.value.ctrl_spare_v508 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_spare_v508 := FALSE;
Outp.hmi_hmiIo.value.ctrl_turn_on_robot_gripper_vacuum_1 := Outp.robot_Sts.vacuum[1].hold;
Outp.hmi_hmiIo.valid.ctrl_turn_on_robot_gripper_vacuum_1 := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_turn_on_robot_gripper_vacuum_2 := Outp.robot_Sts.vacuum[2].hold;
Outp.hmi_hmiIo.valid.ctrl_turn_on_robot_gripper_vacuum_2 := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_turn_on_robot_gripper_vacuum_3 := Outp.robot_Sts.vacuum[3].hold;
Outp.hmi_hmiIo.valid.ctrl_turn_on_robot_gripper_vacuum_3 := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_turn_on_robot_gripper_vacuum_4 := Outp.robot_Sts.vacuum[4].hold;
Outp.hmi_hmiIo.valid.ctrl_turn_on_robot_gripper_vacuum_4 := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_turn_on_robot_gripper_vacuum_5 := Outp.robot_Sts.vacuum[5].hold;
Outp.hmi_hmiIo.valid.ctrl_turn_on_robot_gripper_vacuum_5 := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_e67_imm_mould_area_free := FALSE;
Outp.hmi_hmiIo.valid.ctrl_e67_imm_mould_area_free := FALSE;
Outp.hmi_hmiIo.value.ctrl_e67_imm_enable_mould_closure := FALSE;
Outp.hmi_hmiIo.valid.ctrl_e67_imm_enable_mould_closure := FALSE;
Outp.hmi_hmiIo.value.ctrl_e67_imm_enable_full_mould_opening := FALSE;
Outp.hmi_hmiIo.valid.ctrl_e67_imm_enable_full_mould_opening := FALSE;
Outp.hmi_hmiIo.value.ctrl_e67_imm_robot_operation_mode := FALSE;
Outp.hmi_hmiIo.valid.ctrl_e67_imm_robot_operation_mode := FALSE;
Outp.hmi_hmiIo.value.ctrl_e67_imm_enable_ejector_back := FALSE;
Outp.hmi_hmiIo.valid.ctrl_e67_imm_enable_ejector_back := FALSE;
Outp.hmi_hmiIo.value.ctrl_e67_imm_enable_ejector_forward := FALSE;
Outp.hmi_hmiIo.valid.ctrl_e67_imm_enable_ejector_forward := FALSE;
Outp.hmi_hmiIo.value.ctrl_e67_imm_enable_core_1_position_1 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_e67_imm_enable_core_1_position_1 := FALSE;
Outp.hmi_hmiIo.value.ctrl_e67_imm_enable_core_1_position_2 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_e67_imm_enable_core_1_position_2 := FALSE;
Outp.hmi_hmiIo.value.ctrl_e67_imm_enable_core_2_position_1 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_e67_imm_enable_core_2_position_1 := FALSE;
Outp.hmi_hmiIo.value.ctrl_e67_imm_enable_core_2_position_2 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_e67_imm_enable_core_2_position_2 := FALSE;
Outp.hmi_hmiIo.value.ctrl_e67_imm_kf211_tbd := FALSE;
Outp.hmi_hmiIo.valid.ctrl_e67_imm_kf211_tbd := FALSE;
Outp.hmi_hmiIo.value.ctrl_e73_imm_safety_acknowledgement := FALSE;
Outp.hmi_hmiIo.valid.ctrl_e73_imm_safety_acknowledgement := FALSE;
Outp.hmi_hmiIo.value.ctrl_robot_reserved_input_1 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_robot_reserved_input_1 := FALSE;
Outp.hmi_hmiIo.value.ctrl_robot_reserved_input_2 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_robot_reserved_input_2 := FALSE;
Outp.hmi_hmiIo.value.ctrl_robot_reserved_input_3 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_robot_reserved_input_3 := FALSE;
Outp.hmi_hmiIo.value.ctrl_robot_reserved_input_4 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_robot_reserved_input_4 := FALSE;
Outp.hmi_hmiIo.value.ctrl_robot_reserved_input_5 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_robot_reserved_input_5 := FALSE;
Outp.hmi_hmiIo.value.ctrl_led_button_open_close_spacer_storage := Outp.io_dout.ctrl_LED_button_open_close_spacer_storage;
Outp.hmi_hmiIo.valid.ctrl_led_button_open_close_spacer_storage := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_led_button_samples := Outp.io_dout.ctrl_LED_button_samples;
Outp.hmi_hmiIo.valid.ctrl_led_button_samples := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_led_button_continue_process := Outp.io_dout.ctrl_LED_button_continue_process;
Outp.hmi_hmiIo.valid.ctrl_led_button_continue_process := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_led_button_start_process := Outp.io_dout.ctrl_LED_button_start_process;
Outp.hmi_hmiIo.valid.ctrl_led_button_start_process := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_led_button_container_ready := FALSE;
Outp.hmi_hmiIo.valid.ctrl_led_button_container_ready := FALSE;
Outp.hmi_hmiIo.value.ctrl_led_button_start_emptying_process := Outp.io_dout.ctrl_LED_button_start_emptying_process;
Outp.hmi_hmiIo.valid.ctrl_led_button_start_emptying_process := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_turn_on_loading_conveyor := Outp.io_dout.ctrl_turn_on_top_conveyor;
Outp.hmi_hmiIo.valid.ctrl_turn_on_loading_conveyor := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_turn_on_unloading_conveyor_out := Outp.io_dout.ctrl_turn_on_bottom_conveyor;
Outp.hmi_hmiIo.valid.ctrl_turn_on_unloading_conveyor_out := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_turn_on_elevator_conveyor_out := Outp.io_dout.ctrl_turn_on_elevator_conveyor_out;
Outp.hmi_hmiIo.valid.ctrl_turn_on_elevator_conveyor_out := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_turn_on_elevator_conveyor_in := Outp.io_dout.ctrl_turn_on_elevator_conveyor_in;
Outp.hmi_hmiIo.valid.ctrl_turn_on_elevator_conveyor_in := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_run_elevator := elevOut.xRunUp OR elevOut.xRunDown;
Outp.hmi_hmiIo.valid.ctrl_run_elevator := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_open_spacer_storage_robot_side_lock := Outp.io_dout.ctrl_open_spacer_storage_robot_side_lock;
Outp.hmi_hmiIo.valid.ctrl_open_spacer_storage_robot_side_lock := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_open_spacer_storage_operator_side_lock := Outp.io_dout.ctrl_open_spacer_storage_operator_side_lock;
Outp.hmi_hmiIo.valid.ctrl_open_spacer_storage_operator_side_lock := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_open_robot_cell_doors_lock := Outp.io_dout.ctrl_open_robot_cell_doors_lock;
Outp.hmi_hmiIo.valid.ctrl_open_robot_cell_doors_lock := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_reset_robot_cell_doors_safety := Outp.io_dout.ctrl_reset_robot_cell_doors;
Outp.hmi_hmiIo.valid.ctrl_reset_robot_cell_doors_safety := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_robot_cell_doors_led := Outp.io_dout.ctrl_robot_cell_doors_LED_open_close;
Outp.hmi_hmiIo.valid.ctrl_robot_cell_doors_led := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_bypass_elevator_sto := FALSE;
Outp.hmi_hmiIo.valid.ctrl_bypass_elevator_sto := FALSE;
Outp.hmi_hmiIo.value.ctrl_turn_on_light_green := Outp.io_dout.ctrl_turn_on_light_green;
Outp.hmi_hmiIo.valid.ctrl_turn_on_light_green := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_turn_on_light_yellow := Outp.io_dout.ctrl_turn_on_light_yellow;
Outp.hmi_hmiIo.valid.ctrl_turn_on_light_yellow := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_turn_on_light_red := Outp.io_dout.ctrl_turn_on_light_red;
Outp.hmi_hmiIo.valid.ctrl_turn_on_light_red := io.Sts.valid AND Cfg.robot_stationIoBound;
Outp.hmi_hmiIo.value.ctrl_turn_on_signal_tower_level_4 := FALSE;
Outp.hmi_hmiIo.valid.ctrl_turn_on_signal_tower_level_4 := FALSE;
Outp.hmi_hmiIo.value.ctrl_turn_on_buzzer := Outp.io_dout.ctrl_turn_on_buzzer;
Outp.hmi_hmiIo.valid.ctrl_turn_on_buzzer := io.Sts.valid AND Cfg.robot_stationIoBound;

Hmi.permit.alarmAckAll.xAllowed := Hmi.link.xArmed;


Outp.hmi_hmiStatus.xConvTopRunning := Outp.io_dout.ctrl_turn_on_top_conveyor;
Outp.hmi_hmiStatus.xConvElevRunning := Outp.io_dout.ctrl_turn_on_elevator_conveyor_in OR Outp.io_dout.ctrl_turn_on_elevator_conveyor_out;
Outp.hmi_hmiStatus.xConvBottomRunning := Outp.io_dout.ctrl_turn_on_bottom_conveyor OR Outp.io_dout.ctrl_turn_on_bottom_conveyor_in;
Outp.drive := elevOut.Drive;
IF currentCritical THEN Outp.drive.forward := FALSE; Outp.drive.reverse := FALSE; Outp.drive.reference_ := 0; END_IF;
Outp.hmi_hmiIo.value.ctrl_run_elevator := Outp.drive.enable AND (Outp.drive.forward OR Outp.drive.reverse);
Outp.drain := Drain;
Outp.reconcileRequired := reconcileRequired;
