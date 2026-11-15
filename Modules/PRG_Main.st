(* ============================================================
   PRG_Main — Główny program cykliczny (PROGRAM POU)
   Instancjonuje wszystkie FB, mapuje I/O z GVL_IO na struktury
   wejść/wyjść poszczególnych bloków funkcyjnych.
   Wywoływany w MAST task.
   ============================================================ *)

PROGRAM PRG_Main
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
    drain : FB_StationDrain;
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
END_VAR

PRG_IO_Read();
io(Cfg := GVL_Station.IoCfg, Inp := GVL_Station.Inputs);
GVL_Station.Io := io.Sts;
stationParametersReady := TRUE;
FOR i := 1 TO 4 DO
 stationParametersReady := stationParametersReady AND GVL_RobotRetain.Context.stationParameters[i].verified;
END_FOR;
stationIdle := GVL_Station.Inputs.beltsStopped[1] AND GVL_Station.Inputs.beltsStopped[2] AND GVL_Station.Inputs.beltsStopped[3] AND NOT fbConvTop.Sts.Running AND NOT fbConvElev.Sts.Running AND NOT fbConvBottom.Sts.Running AND
 NOT elevStat.xBusy AND NOT elevStat.xVfdRunning AND NOT fbTopFlow.Sts.Busy AND NOT fbBottom567.Sts.Busy;

xResetAll := robot.Panel.Cmd.reset AND GVL_HMI.hmiV2.link.xArmed;
fbSafetyDoor.Enable := GVL_Robot.stationIoBound;
fbSafetyDoor.ResetFault := xResetAll;
fbSafetyDoor.Inp.BtnOpenClose := GVL_IO.di.ind_button_open_close_robot_cell_doors;
fbSafetyDoor.Inp.DoorLocked := GVL_IO.di.ind_robot_cell_doors_locked;
fbSafetyDoor.Inp.DeviceError := NOT GVL_IO.di.ind_robot_cell_doors_error;
fbSafetyDoor();
xSafetyOK := GVL_Robot.Plant.safetyValid AND GVL_Robot.Plant.safetyOK AND fbSafetyDoor.Sts.ReadyToRun;
xGlobalEnable := io.Sts.valid AND GVL_Station.ElevatorCfgVerified AND GVL_Robot.stationIoBound AND GVL_Robot.stationCoilPolicyVerified AND xSafetyOK AND NOT GVL_IO.di.ind_low_pressure;
GVL_IO.dout.ctrl_open_robot_cell_doors_lock := fbSafetyDoor.Outp.Q_Unlock;
GVL_IO.dout.ctrl_robot_cell_doors_LED_open_close := fbSafetyDoor.Outp.Q_LEDOpenClose;
GVL_IO.dout.ctrl_reset_robot_cell_doors := fbSafetyDoor.Outp.Q_DeviceReset;
plantNow := GVL_Robot.Plant;
plantNow.physicalStart := GVL_IO.di.ind_button_start_process AND GVL_Robot.stationIoBound;
(* physicalStop pozostaje osobnym, niewypelnionym bindingiem. Nie uzywamy starego Continue. *)
plantNow.sampleButton := GVL_IO.di.ind_button_samples AND GVL_Robot.stationIoBound;
plantNow.processOK := plantNow.processOK AND xGlobalEnable AND alarms.Sts.policyReady AND stationParametersReady;
plantNow.stationRecoveryRequired := (NOT material.Sts.known AND GVL_RobotRetain.Context.valid) OR GVL_Station.ReconcileRequired;
IF material.Sts.known THEN plantNow.stationEmptyConfirmed := material.Sts.emptyConfirmed; END_IF;
plantNow.imm.processInterlocks := plantNow.imm.processInterlocks AND xGlobalEnable;
topTransferActive := fbTopFlow.Sts.State <> E_TopFlowState.IDLE AND fbTopFlow.Sts.State <> E_TopFlowState.INIT;
plantNow.transferBusy := plantNow.transferBusy OR topTransferActive OR elevStat.xBusy OR
    transport.Sts.owner = E_StationOwner.DRAIN OR transport.Sts.owner = E_StationOwner.LOCAL OR
    ((fbBottom567.Sts.State <> E_Bottom567State.IDLE) AND (fbBottom567.Sts.State <> E_Bottom567State.INIT));
plantNow.critical := plantNow.critical OR alarms.Sts.critical OR stationCoils.Fault OR elevStat.xFault OR fbConvTop.Diag.Fault OR
    fbConvElev.Diag.Fault OR fbConvBottom.Diag.Fault OR fbTraySeq.Diag.Fault OR fbBoxSeq.Diag.Fault;
plantNow.warning := plantNow.warning OR fbPosM1.Diag.Fault OR fbStopM2.Diag.Fault OR
    fbStopM3.Diag.Fault OR fbStopM4.Diag.Fault OR fbPosM5.Diag.Fault OR (fbV201.Diag.Fault OR fbV202.Diag.Fault) OR
    fbPosM7.Diag.Fault OR fbStorage.Diag.Fault;
sourceEmpty(IN := io.Sts.positionValid[3] AND NOT io.Sts.occupied[3] AND NOT fbConvTop.Sts.Running,
    PT := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].sensorStableMs));
plantNow.sourceEmptyConfirmed := GVL_RobotRetain.Context.stationParameters[1].sensorStableMs > 0 AND sourceEmpty.Q;
plantNow.areas[1].ready := fbTopFlow.Sts.StackReadyAtP3 AND NOT fbConvTop.Sts.Running AND
    NOT fbConvTop.Outp.Q_Fwd AND NOT fbTopFlow.Sts.Busy AND fbTopFlow.Sts.State = E_TopFlowState.IDLE;
plantNow.areas[2].ready := NOT elevStat.xBusy AND NOT fbConvElev.Sts.Running AND NOT elevStat.xVfdRunning AND
    NOT fbConvElev.Outp.Q_Fwd AND NOT fbConvElev.Outp.Q_Bwd AND
    ((fbTraySeq.Outp.ElevatorReady AND GVL_RobotRetain.Context.program = 2) OR
     (fbBoxSeq.Outp.ElevatorReady AND GVL_RobotRetain.Context.program = 1));
plantNow.areas[3].ready := fbStorage.Sts.RobotSideOpen AND fbStorage.Sts.RobotAccessGranted AND NOT fbStorage.Sts.Empty;
plantNow.areas[1].blocked := plantNow.areas[1].blocked OR fbStopM4.Diag.Fault OR fbPosM5.Diag.Fault;
plantNow.areas[2].blocked := plantNow.areas[2].blocked OR (fbV201.Diag.Fault OR fbV202.Diag.Fault) OR fbPosM7.Diag.Fault;
plantNow.areas[3].blocked := plantNow.areas[3].blocked OR fbStorage.Diag.Fault;
robot(Cfg := GVL_Robot.Cfg, ScannerHealthy := GVL_Robot.ScannerHealthy, ImageFresh := GVL_Robot.ImageFresh,
    Rx := GVL_Robot.Rx, Plant := plantNow, Context := GVL_RobotRetain.Context, Proposal := GVL_Robot.Proposal,
    Drain := GVL_Robot.Drain, Hmi := GVL_HMI.hmiV2);
GVL_Robot.Sts := robot.Sts;
GVL_Robot.Tx := robot.Tx;
IF robot.Recovery.Approved THEN
    (* Operator uzgodnil transfery w postoju; odtwarzamy model, nie ruch w polowie kroku. *)
    fbTopFlow.Sts.OccP1 := GVL_RobotRetain.Context.occupied[1];
    fbTopFlow.Sts.OccP2 := GVL_RobotRetain.Context.occupied[2];
    fbTopFlow.Sts.OccP3 := GVL_RobotRetain.Context.occupied[3];
    fbTopFlow.Sts.State := E_TopFlowState.IDLE;
    fbBottom567.Sts.Occ5 := GVL_RobotRetain.Context.occupied[5];
    fbBottom567.Sts.Occ6 := GVL_RobotRetain.Context.occupied[6];
    fbBottom567.Sts.Occ7 := GVL_RobotRetain.Context.occupied[7];
    fbBottom567.Sts.State := E_Bottom567State.IDLE;
    xElevatorLoadPresent := GVL_RobotRetain.Context.elevatorLoadPresent;
    xBottomDonePendingTray := GVL_RobotRetain.Context.bottomDonePendingTray;
    xBottomDonePendingBox := GVL_RobotRetain.Context.bottomDonePendingBox;
    xBottomTransferOwnerTray := FALSE;
    xBottomTransferOwnerBox := FALSE;
END_IF;
FOR i := 1 TO 10 DO GVL_Robot.Plant.taskDone[i] := FALSE; END_FOR;
xResetAll := robot.Panel.Cmd.reset AND GVL_HMI.hmiV2.link.xArmed;
xModeTray := GVL_RobotRetain.Context.program = 2;
xModeBox := GVL_RobotRetain.Context.program = 1;
xHmiManualMode := robot.Sts.order.manual;
xEmptyRunning := GVL_Robot.Drain.request;
xGlobalEnable := xGlobalEnable AND NOT plantNow.critical AND
 (NOT robot.Sts.recoveryRequired OR (robot.Sts.order.manual AND NOT robot.Recovery.Required AND NOT GVL_Station.ReconcileRequired));
IF xResetAll AND (fbTopFlow.Diag.Fault OR fbBottom567.Diag.Fault) THEN GVL_Station.ReconcileRequired := TRUE; END_IF;
productionPermit := robot.Sts.order.newPermit OR robot.Sts.order.finishPermit;
outputPermit := robot.Sts.session AND xGlobalEnable AND (productionPermit OR GVL_Robot.Drain.runPermit OR
 transport.Sts.owner = E_StationOwner.DRAIN OR transport.Sts.owner = E_StationOwner.LOCAL OR xHmiManualMode);
rtContainerReady(CLK := GVL_IO.di.ind_button_container_ready);
IF rtContainerReady.Q AND robot.Sts.order.newPermit AND NOT GVL_RobotRetain.Context.ending THEN xLoadAcceptedPending := TRUE; END_IF;
fbTopFlow.Cmd.Pos1AcceptedPulse := FALSE;
fbPosM1.Cfg.tStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].sensorStableMs);
fbPosM1.Cfg.tTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].actuatorTimeoutMs);
fbStopM2.Cfg.tStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].sensorStableMs);
fbStopM2.Cfg.tTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].actuatorTimeoutMs);
fbStopM3.Cfg.tStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].sensorStableMs);
fbStopM3.Cfg.tTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].actuatorTimeoutMs);
fbStopM4.Cfg.tStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].sensorStableMs);
fbStopM4.Cfg.tTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].actuatorTimeoutMs);
fbPosM5.Cfg.tStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].sensorStableMs);
fbPosM5.Cfg.tTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].actuatorTimeoutMs);
fbPosM7.Cfg.tStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[2].sensorStableMs);
fbPosM7.Cfg.tTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[2].actuatorTimeoutMs);
fbLowerStop5.Cfg.tStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[3].sensorStableMs);
fbLowerStop5.Cfg.tTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[3].actuatorTimeoutMs);
fbLowerStop6.Cfg.tStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[3].sensorStableMs);
fbLowerStop6.Cfg.tTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[3].actuatorTimeoutMs);
fbV201.Cfg.tStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[2].sensorStableMs);
fbV201.Cfg.tTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[2].actuatorTimeoutMs);
fbV202.Cfg.tStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[2].sensorStableMs);
fbV202.Cfg.tTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[2].actuatorTimeoutMs);

// 3) STOPERY — konfiguracja i mapowanie I/O
// ================================================================

// --- M2: stoper pozycja 1 ---
fbStopM2.Enable := outputPermit;
fbStopM2.ResetFault := xResetAll;
fbStopM2.Inp.ind_1_fwd := GVL_IO.di.ind_M2_1_fwd;
fbStopM2.Inp.ind_2_fwd := GVL_IO.di.ind_M2_2_fwd;
fbStopM2.Inp.ind_1_bwd := GVL_IO.di.ind_M2_1_bwd;
fbStopM2.Inp.ind_2_bwd := GVL_IO.di.ind_M2_2_bwd;
// HoldUp ustawiany przez TopFlowManager (poniżej)

// --- M3: stoper pozycja 2 ---
fbStopM3.Enable := outputPermit;
fbStopM3.ResetFault := xResetAll;
fbStopM3.Inp.ind_1_fwd := GVL_IO.di.ind_M3_1_fwd;
fbStopM3.Inp.ind_2_fwd := GVL_IO.di.ind_M3_2_fwd;
fbStopM3.Inp.ind_1_bwd := GVL_IO.di.ind_M3_1_bwd;
fbStopM3.Inp.ind_2_bwd := GVL_IO.di.ind_M3_2_bwd;

// --- M4: stoper pozycja 3 ---
fbStopM4.Enable := outputPermit;
fbStopM4.ResetFault := xResetAll;
fbStopM4.Inp.ind_1_fwd := GVL_IO.di.ind_M4_1_fwd;
fbStopM4.Inp.ind_2_fwd := GVL_IO.di.ind_M4_2_fwd;
fbStopM4.Inp.ind_1_bwd := GVL_IO.di.ind_M4_1_bwd;
fbStopM4.Inp.ind_2_bwd := GVL_IO.di.ind_M4_2_bwd;


// ================================================================
// 4) POZYCJONERY — konfiguracja i mapowanie I/O
// ================================================================

// --- M1: pozycjoner załadunku ---
fbPosM1.Enable := outputPermit;
fbPosM1.ResetFault := xResetAll;
fbPosM1.Inp.ind_1_fwd := GVL_IO.di.ind_M1_1_fwd;
fbPosM1.Inp.ind_2_fwd := GVL_IO.di.ind_M1_2_fwd;
fbPosM1.Inp.ind_1_bwd := GVL_IO.di.ind_M1_1_bwd;
fbPosM1.Inp.ind_2_bwd := GVL_IO.di.ind_M1_2_bwd;
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
fbPosM5.Inp.ind_1_fwd := GVL_IO.di.ind_M5_1_fwd;
fbPosM5.Inp.ind_2_fwd := GVL_IO.di.ind_M5_2_fwd;
fbPosM5.Inp.ind_1_bwd := GVL_IO.di.ind_M5_1_bwd;
fbPosM5.Inp.ind_2_bwd := GVL_IO.di.ind_M5_2_bwd;
// HoldUp zarządzane przez TopFlowManager (bramka tacek P3 w trybie tray)

(* Dwa niezalezne zawory i potwierdzenia; Auto zadaje ten sam cel. *)
fbV201.Enable := outputPermit; fbV202.Enable := outputPermit;
fbV201.ResetFault := xResetAll; fbV202.ResetFault := xResetAll;
fbV201.Inp := GVL_Station.Inputs.v201; fbV202.Inp := GVL_Station.Inputs.v202;

// --- M7: pozycjoner kuwet winda ---
fbPosM7.Enable := outputPermit;
fbPosM7.ResetFault := xResetAll;
fbPosM7.Inp.ind_1_fwd := GVL_IO.di.ind_M7_fwd;
fbPosM7.Inp.ind_2_fwd := GVL_IO.di.ind_M7_fwd;
fbPosM7.Inp.ind_1_bwd := GVL_IO.di.ind_M7_bwd;
fbPosM7.Inp.ind_2_bwd := GVL_IO.di.ind_M7_bwd;

// --- Magazyn przekladek / M8 ---
// FB_Storage jest mapowany po wywolaniu sekwencerow i odczycie zadania robota.


// ================================================================
// 5) TRANSPORTERY — konfiguracja i blokady programowe
// ================================================================

// --- Górny transporter (jednokierunkowy w normalnej pracy, FWD = do robota) ---
fbConvTop.Cfg.tReversalDelay := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].stopDelayMs);
fbConvTop.Inp.Enable := xGlobalEnable;
fbConvTop.Inp.SafetyOK := xSafetyOK;
fbConvTop.Cmd.ResetFault := xResetAll;
// RunFwd zarządzany wyłącznie przez TopFlowManager.
// Górny transporter nie ma osobnego wyjścia BWD w GVL_IO — jest jednokierunkowy sprzętowo

// --- Transporter windy (dwukierunkowy: IN = do robota, OUT = do rozładunku) ---
fbConvElev.Cfg.tReversalDelay := TO_TIME(GVL_RobotRetain.Context.stationParameters[2].stopDelayMs);
fbConvElev.Inp.Enable := xGlobalEnable;
fbConvElev.Inp.SafetyOK := xSafetyOK;
fbConvElev.Cmd.ResetFault := xResetAll;

// --- Dolny transporter (dwukierunkowy: FWD = do wyjścia, BWD = do windy) ---
fbConvBottom.Cfg.tReversalDelay := TO_TIME(GVL_RobotRetain.Context.stationParameters[3].stopDelayMs);
fbConvBottom.Inp.Enable := xGlobalEnable;
fbConvBottom.Inp.SafetyOK := xSafetyOK;
fbConvBottom.Cmd.ResetFault := xResetAll;


// ================================================================
// 6) WINDA — konfiguracja i mapowanie wejść
// ================================================================

// Mapowanie wejść windy
elevIn.xInPos1 := GVL_IO.di.ind_elevator_in_top_pos;
elevIn.xInPos2 := GVL_IO.di.ind_elevator_in_intermediate_top_pos;
elevIn.xInPos3 := GVL_IO.di.ind_elevator_in_intermediate_bottom_pos;
elevIn.xInPos4 := GVL_IO.di.ind_elevator_in_bottom_pos;
elevIn.xContainerInPos4 := io.Sts.occupied[4];
elevIn.xSafetyOk := xSafetyOK;
elevIn.xDoorClosed := fbSafetyDoor.Sts.DoorClosed;
elevIn.xCommOk := GVL_Robot.vfdCommHealthy; // Binding diagnostyki ATV320, GAP-06.
elevIn.stVfdRx.uiOutFreq_0p1Hz_3202 := WORD_TO_UINT(GVL_IO.di.ATV320_currentFreq);

(* Konfiguracja napedu pochodzi z zatwierdzonego adaptera, nie ze stalych testowych. *)
elevPar := GVL_Station.ElevatorCfg;
elevPar.tMoveTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[2].moveTimeoutMs);
elevPar.tClearPos4Timeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[2].moveTimeoutMs);
elevPar.tStopTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[2].stopDelayMs);
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
elevCmd.rSpeedFast_Hz := GVL_RobotRetain.Context.stationParameters[2].fastHz;
elevCmd.rSpeedSlow_Hz := GVL_RobotRetain.Context.stationParameters[2].slowHz;
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

// Mapowanie czujników
fbTopFlow.Inp.sPos1_raw := io.Sts.occupied[1];
fbTopFlow.Inp.sPos2_raw := io.Sts.occupied[2];
fbTopFlow.Inp.sPos3_raw := io.Sts.occupied[3];
fbTopFlow.Inp.sPos4_raw := io.Sts.occupied[4];
fbTopFlow.Inp.TopConveyorRunning := NOT GVL_Station.Inputs.beltsStopped[1];
fbTopFlow.Inp.LoadBarrierValid := io.Sts.barrierValid;
fbTopFlow.Inp.LoadBarrierBlocked := io.Sts.barrierBlocked;
fbTopFlow.Inp.DeviceWarning := fbPosM1.Diag.Fault OR fbStopM2.Diag.Fault OR fbStopM3.Diag.Fault OR fbStopM4.Diag.Fault OR fbPosM5.Diag.Fault;
fbTopFlow.Cfg.tSensorStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].sensorStableMs);
fbTopFlow.Cfg.tMotorStopDelay := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].stopDelayMs);
fbTopFlow.Cfg.tMoveTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[1].moveTimeoutMs);

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
elevatorTransfer(IN := io.Sts.occupied[4] AND GVL_Robot.stationIoBound,
    PT := TO_TIME(GVL_RobotRetain.Context.stationParameters[2].sensorStableMs));
xElevTransferDone := elevatorTransfer.Q AND GVL_RobotRetain.Context.stationParameters[2].sensorStableMs > 0;
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
fbBottom567.Inp.sElevatorEmptied_raw := GVL_IO.di.ind_elevator_emptied;
fbBottom567.Inp.Valid := io.Sts.valid AND GVL_Station.Inputs.lowerFeedbackValid;
fbBottom567.Inp.Reconcile := robot.Recovery.Approved;
fbBottom567.Inp.Restored[1] := GVL_RobotRetain.Context.occupied[5];
fbBottom567.Inp.Restored[2] := GVL_RobotRetain.Context.occupied[6];
fbBottom567.Inp.Restored[3] := GVL_RobotRetain.Context.occupied[7];
fbBottom567.Inp.BeltsStopped := GVL_Station.Inputs.beltsStopped[2] AND GVL_Station.Inputs.beltsStopped[3];
fbBottom567.Inp.Stop5Holding := fbLowerStop5.Sts.IsUp;
fbBottom567.Inp.Stop5Released := fbLowerStop5.Sts.IsDown;
fbBottom567.Inp.Stop6Holding := fbLowerStop6.Sts.IsUp;
fbBottom567.Inp.Stop6Released := fbLowerStop6.Sts.IsDown;
fbBottom567.Inp.StopWarning := fbLowerStop5.Diag.Fault OR fbLowerStop6.Diag.Fault;
fbBottom567.Cfg.stopsConfigured := GVL_Station.Inputs.lowerFeedbackValid AND GVL_Robot.stationCoilPolicyVerified;
fbBottom567.Cfg.tSensorStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[3].sensorStableMs);
fbBottom567.Cfg.tMotorStopDelay := TO_TIME(GVL_RobotRetain.Context.stationParameters[3].stopDelayMs);
fbBottom567.Cfg.tStepTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[3].moveTimeoutMs);



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

fbTraySeq.Cfg.tP4ConfirmTimeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[2].moveTimeoutMs);
fbTraySeq.Cmd.Enable := xModeTray AND NOT xHmiManualMode AND GVL_RobotRetain.Context.orderActive;
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
fbTraySeq.Inp.RobotClear := robot.Sts.session AND GVL_Robot.Rx.area_elevator_clear;
fbTraySeq.Inp.TaskPicked := GVL_RobotRetain.Context.tasks[1].pending;
fbTraySeq.Inp.TaskPlaced := GVL_RobotRetain.Context.tasks[2].pending;
fbTraySeq.Inp.TaskFinished := GVL_RobotRetain.Context.tasks[3].pending;
fbTraySeq.Inp.TaskStack := GVL_RobotRetain.Context.tasks[8].pending;
fbTraySeq.Inp.SourceEmptyConfirmed := plantNow.sourceEmptyConfirmed;
fbTraySeq.Inp.Warning := plantNow.warning;
fbTraySeq(Context := GVL_RobotRetain.Context);

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
        GVL_Robot.Plant.taskDone[8] := TRUE;
        xBottomDonePendingTray := FALSE;
        xBottomTransferOwnerTray := FALSE;
    END_IF;
    IF fbTraySeq.Outp.NewStackReady AND GVL_RobotRetain.Context.stackFull THEN stackAdvancePending := TRUE; END_IF;
END_IF;

fbBoxSeq.Cmd.Enable := xModeBox AND NOT xHmiManualMode AND GVL_RobotRetain.Context.orderActive;
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
fbBoxSeq.Inp.RobotClear := robot.Sts.session AND GVL_Robot.Rx.area_elevator_clear;
fbBoxSeq.Inp.TaskPicked := GVL_RobotRetain.Context.tasks[1].pending;
fbBoxSeq.Inp.TaskPlaced := GVL_RobotRetain.Context.tasks[2].pending;
fbBoxSeq.Inp.TaskFinished := GVL_RobotRetain.Context.tasks[3].pending;
fbBoxSeq.Inp.TaskStack := GVL_RobotRetain.Context.tasks[8].pending;
fbBoxSeq.Inp.SourceEmptyConfirmed := plantNow.sourceEmptyConfirmed;
fbBoxSeq.Inp.Warning := plantNow.warning;
fbBoxSeq(Context := GVL_RobotRetain.Context);

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
        GVL_Robot.Plant.taskDone[8] := TRUE;
        xBottomDonePendingBox := FALSE;
        xBottomTransferOwnerBox := FALSE;
    END_IF;
    IF fbBoxSeq.Outp.NewStackReady AND GVL_RobotRetain.Context.stackFull THEN stackAdvancePending := TRUE; END_IF;
END_IF;

IF fbTraySeq.Outp.ConsumePicked THEN GVL_Robot.Plant.taskDone[1] := TRUE; END_IF;
(* Opoznione potwierdzenie pustego zrodla nie ginie wraz z odbiorem zdarzenia picked. *)
IF plantNow.sourceEmptyConfirmed AND robot.Sts.session AND NOT robot.Sts.areas[1].reserved AND
   GVL_Robot.Rx.area_source_clear AND GVL_RobotRetain.Context.pickedCount > 0 THEN
    fbTopFlow.Inp.StackConsumedAtP3 := TRUE;
END_IF;
IF fbTraySeq.Outp.ConsumePlaced THEN GVL_Robot.Plant.taskDone[2] := TRUE; END_IF;
IF GVL_RobotRetain.Context.tasks[2].pending OR io.Sts.occupied[4] THEN
    xElevatorLoadPresent := TRUE;
END_IF;
IF fbTraySeq.Outp.ConsumeFinished THEN GVL_Robot.Plant.taskDone[3] := TRUE; END_IF;
(* Warstwa/przekladka maja skutki licznikowe, bez ruchu windy. *)
GVL_Robot.Plant.taskDone[4] := GVL_RobotRetain.Context.tasks[4].pending;
GVL_Robot.Plant.taskDone[7] := GVL_RobotRetain.Context.tasks[7].pending;
IF stackAdvancePending AND robot.Sts.allChannelsIdle AND NOT GVL_RobotRetain.Context.tasks[8].pending THEN
    GVL_RobotRetain.Context.stackId := TO_UINT((TO_UDINT(GVL_RobotRetain.Context.stackId) + 1) MOD 65536);
    GVL_RobotRetain.Context.blisterCount := 0;
    GVL_RobotRetain.Context.layerCount := 0;
    GVL_RobotRetain.Context.stackFull := FALSE;
    stackAdvancePending := FALSE;
END_IF;
GVL_Robot.Tx.production_stackId := GVL_RobotRetain.Context.stackId;
xBottomReqFromTray := xModeTray AND fbTraySeq.Outp.Bottom_DischargeReq;
xBottomReqFromBox := xModeBox AND fbBoxSeq.Outp.Bottom_DischargeReq;
(* Zwykly Stop nie odbiera wlasnosci zaakceptowanemu transferowi. *)
fbTopFlow.Cmd.EnableAuto := outputPermit AND (fbTopFlow.Cmd.EnableAuto OR topTransferActive);
fbBottom567.Cmd.EnableAuto := outputPermit AND (fbBottom567.Cmd.EnableAuto OR
    ((fbBottom567.Sts.State <> E_Bottom567State.IDLE) AND (fbBottom567.Sts.State <> E_Bottom567State.INIT)));
(* Manual i koordynacja zadan korzystaja z tego samego wlasciciela wyjsc. *)
manualIn := GVL_Station.ManualInterlocks;
manualIn.armed := GVL_HMI.hmiV2.link.xArmed;
manualIn.sessionId := GVL_HMI.hmiV2.link.udiSessionId;
manualIn.panel := GVL_HMI.hmiV2.link.uiActivePanel;
manualIn.timeout := GVL_Robot.Cfg.hmiTimeout;
manualIn.manual := xHmiManualMode;
manualIn.idle := NOT productionPermit AND NOT GVL_Robot.Drain.runPermit AND
 (transport.Sts.owner = E_StationOwner.NONE OR transport.Sts.owner = E_StationOwner.MANUAL);
manualIn.safe := xGlobalEnable AND stationParametersReady AND robot.Sts.session AND GVL_Robot.Rx.production_home AND
 GVL_Robot.Rx.production_loadKnown AND GVL_Station.ManualReleaseVerified;
FOR i := 1 TO 16 DO
 IF i >= 5 AND i <= 9 THEN
  manualIn.allowPositive[i] := manualIn.allowPositive[i] AND GVL_Station.Inputs.beltsStopped[1] AND NOT robot.Sts.areas[1].reserved;
  manualIn.allowNegative[i] := manualIn.allowNegative[i] AND GVL_Station.Inputs.beltsStopped[1] AND NOT robot.Sts.areas[1].reserved;
 ELSIF i >= 10 AND i <= 12 THEN
  manualIn.allowPositive[i] := manualIn.allowPositive[i] AND GVL_Station.Inputs.beltsStopped[2] AND NOT elevStat.xBusy AND NOT robot.Sts.areas[2].reserved;
  manualIn.allowNegative[i] := manualIn.allowNegative[i] AND GVL_Station.Inputs.beltsStopped[2] AND NOT elevStat.xBusy AND NOT robot.Sts.areas[2].reserved;
 ELSIF i = 13 OR i = 14 THEN
  manualIn.allowPositive[i] := manualIn.allowPositive[i] AND GVL_Station.Inputs.beltsStopped[3];
  manualIn.allowNegative[i] := manualIn.allowNegative[i] AND GVL_Station.Inputs.beltsStopped[3];
 END_IF;
END_FOR;
manualIn.allowPositive[2] := manualIn.allowPositive[2] AND NOT robot.Sts.areas[2].reserved AND NOT elevStat.xBusy;
manualIn.allowNegative[2] := manualIn.allowNegative[2] AND NOT robot.Sts.areas[2].reserved AND NOT elevStat.xBusy;
manualIn.allowPositive[4] := manualIn.allowPositive[4] AND NOT robot.Sts.areas[2].reserved AND GVL_Station.Inputs.beltsStopped[2];
manualIn.allowNegative[4] := manualIn.allowNegative[4] AND NOT robot.Sts.areas[2].reserved AND GVL_Station.Inputs.beltsStopped[2];
manual(Cmd := GVL_HMI.hmiV2.stationManual, Inp := manualIn);
localUnload(CLK := GVL_IO.di.ind_button_start_emptying_process);
GVL_Robot.singleUnloadReady := fbBottom567.Sts.SingleUnloadReady AND xGlobalEnable AND
 GVL_RobotRetain.Context.orderActive AND GVL_RobotRetain.Context.withRobot AND NOT xHmiManualMode AND
 NOT robot.Sts.recoveryRequired AND NOT plantNow.critical AND alarms.Sts.policyReady AND stationParametersReady;
GVL_Robot.singleUnloadRequest := localUnload.Q AND GVL_Robot.singleUnloadReady;
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
drainIn.reconcile := robot.Recovery.Approved;
drain(Inp := drainIn, Drain := GVL_Robot.Drain);
transportIn.permit := xGlobalEnable AND robot.Sts.session;
transportIn.critical := plantNow.critical OR robot.Sts.recoveryRequired;
transportIn.productionPermit := productionPermit;
transportIn.productionBusy := topTransferActive OR elevStat.xBusy OR fbBottom567.Sts.Busy;
transportIn.productionNeedsLower := fbBottom567.Cmd.DischargeReq;
transportIn.drainAction := drain.Sts.action;
transportIn.drainPermit := GVL_Robot.Drain.runPermit;
transportIn.localRequest := GVL_Robot.singleUnloadRequest;
transportIn.localReady := GVL_Robot.singleUnloadReady;
transportIn.localAllowed := GVL_RobotRetain.Context.orderActive AND NOT xHmiManualMode;
transportIn.manual := xHmiManualMode;
transportIn.manualActive := manual.Sts.active;
transportIn.reconcile := robot.Recovery.Approved;
transportIn.actionDone := FALSE;
CASE transport.Sts.action OF
 E_StationAction.ELEV_TOP: transportIn.actionDone := drainIn.atTop AND NOT elevStat.xBusy;
 E_StationAction.ELEV_BOTTOM: transportIn.actionDone := drainIn.atBottom AND NOT elevStat.xBusy;
 E_StationAction.FEED: transportIn.actionDone := fbTopFlow.Sts.ElevDeliveredAtP4 AND NOT fbTopFlow.Sts.Busy;
 E_StationAction.DISCHARGE: transportIn.actionDone := fbBottom567.Outp.DischargeDonePulse;
 E_StationAction.ADVANCE: transportIn.actionDone := fbBottom567.Outp.StepDonePulse;
 E_StationAction.UNLOAD: transportIn.actionDone := fbBottom567.Outp.SingleUnloadDonePulse;
END_CASE;
transportIn.actionFault := fbTopFlow.Diag.Fault OR fbBottom567.Diag.Fault OR elevStat.xFault;
transport(Inp := transportIn);
GVL_Station.Transport := transport.Sts;
GVL_Station.DrainStatus := drain.Sts;
fbTopFlow.Cmd.AllowNewTransfers := robot.Sts.order.newPermit;
fbBottom567.Cmd.FinishPermit := productionPermit;
fbBottom567.Cmd.SingleUnloadReq := FALSE;
fbBottom567.Cmd.AdvanceReq := transport.Sts.owner = E_StationOwner.PRODUCTION AND fbBottom567.Sts.CanAdvance AND NOT fbBottom567.Cmd.DischargeReq AND
 (robot.Sts.order.newPermit OR GVL_RobotRetain.Context.tasks[8].pending);
IF transport.Sts.owner <> E_StationOwner.PRODUCTION THEN
 fbTopFlow.Cmd.EnableAuto := FALSE; fbTopFlow.Inp.Elev_RequestFeed := FALSE;
 fbBottom567.Cmd.EnableAuto := FALSE; fbBottom567.Cmd.DischargeReq := FALSE;
 elevCmd.xAutoGo := FALSE;
END_IF;
actionPermit := xGlobalEnable AND robot.Sts.session AND NOT transport.Sts.fault;
IF transport.Sts.owner = E_StationOwner.DRAIN OR transport.Sts.owner = E_StationOwner.LOCAL THEN
 fbV201.CmdExtend := FALSE; fbV202.CmdExtend := FALSE; fbPosM7.HoldUp := FALSE;
 fbBottom567.Cmd.FinishPermit := actionPermit;
 CASE transport.Sts.action OF
  E_StationAction.ELEV_TOP:
   elevCmd.eAutoTarget := E_ElevatorTarget.posTop;
   IF transport.Sts.action = E_StationAction.ELEV_BOTTOM THEN elevCmd.eAutoTarget := E_ElevatorTarget.posBottom; END_IF;
   elevCmd.xAutoGo := actionPermit AND fbV201.Sts.AtRet AND fbV202.Sts.AtRet AND fbPosM7.Sts.IsDown AND
    elevStat.eState = E_ElevatorState.IDLE;
   elevCmd.xStop := NOT actionPermit;
  E_StationAction.ELEV_BOTTOM:
   elevCmd.eAutoTarget := E_ElevatorTarget.posTop;
   IF transport.Sts.action = E_StationAction.ELEV_BOTTOM THEN elevCmd.eAutoTarget := E_ElevatorTarget.posBottom; END_IF;
   elevCmd.xAutoGo := actionPermit AND fbV201.Sts.AtRet AND fbV202.Sts.AtRet AND fbPosM7.Sts.IsDown AND
    elevStat.eState = E_ElevatorState.IDLE;
   elevCmd.xStop := NOT actionPermit;
  E_StationAction.FEED:
   fbTopFlow.Cmd.EnableAuto := actionPermit AND (NOT fbTopFlow.Sts.ElevDeliveredAtP4 OR topTransferActive);
   fbTopFlow.Cmd.AllowNewTransfers := GVL_Robot.Drain.runPermit;
   fbTopFlow.Cmd.EmptyingMode := TRUE;
   fbTopFlow.Inp.Elev_RequestFeed := TRUE;
   fbTopFlow.Inp.Elev_CanAccept := drainIn.atTop AND NOT material.Sts.occupied[4];
  E_StationAction.DISCHARGE:
   fbBottom567.Cmd.EnableAuto := actionPermit;
   fbBottom567.Cmd.DischargeReq := transport.Sts.start;
  E_StationAction.UNLOAD:
   fbBottom567.Cmd.EnableAuto := actionPermit;
   fbBottom567.Cmd.SingleUnloadReq := transport.Sts.start;
 END_CASE;
END_IF;
IF robot.Sts.areas[1].reserved OR NOT outputPermit THEN
    fbTopFlow.Cmd.SafetyOK := FALSE;
END_IF;
topWasBusy := fbTopFlow.Sts.Busy;
fbTopFlow();

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

eBottomStateBeforeCall := fbBottom567.Sts.State;
lowerWasBusy := fbBottom567.Sts.Busy;
fbBottom567();
fbLowerStop5.Enable := outputPermit AND GVL_Station.Inputs.lowerFeedbackValid;
fbLowerStop6.Enable := fbLowerStop5.Enable;
fbLowerStop5.ResetFault := xResetAll; fbLowerStop6.ResetFault := xResetAll;
fbLowerStop5.Inp := GVL_Station.Inputs.lowerStop[1]; fbLowerStop6.Inp := GVL_Station.Inputs.lowerStop[2];
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
    xElevatorLoadPresent := FALSE;
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


fbStopM2();
stationCmd[2].work := fbStopM2.Outp.Q_Fwd;
stationCmd[2].home := fbStopM2.Outp.Q_Bwd;

fbStopM3();
stationCmd[3].work := fbStopM3.Outp.Q_Fwd;
stationCmd[3].home := fbStopM3.Outp.Q_Bwd;

fbStopM4();
stationCmd[4].work := fbStopM4.Outp.Q_Fwd;
stationCmd[4].home := fbStopM4.Outp.Q_Bwd;

fbPosM1();
stationCmd[1].work := fbPosM1.Outp.Q_Fwd;
stationCmd[1].home := fbPosM1.Outp.Q_Bwd;

fbPosM5();
stationCmd[5].work := fbPosM5.Outp.Q_Fwd;
stationCmd[5].home := fbPosM5.Outp.Q_Bwd;

fbV201(); fbV202();
stationCmd[6].work := fbV201.Outp.Q_Ext; stationCmd[6].home := fbV201.Outp.Q_Ret;
stationCmd[8].work := fbV202.Outp.Q_Ext; stationCmd[8].home := fbV202.Outp.Q_Ret;
fbLowerStop5(); fbLowerStop6();
stationCmd[9].work := fbLowerStop5.Outp.Q_Fwd; stationCmd[9].home := fbLowerStop5.Outp.Q_Bwd;
stationCmd[10].work := fbLowerStop6.Outp.Q_Fwd; stationCmd[10].home := fbLowerStop6.Outp.Q_Bwd;

fbPosM7();
stationCmd[7].work := fbPosM7.Outp.Q_Fwd;
stationCmd[7].home := fbPosM7.Outp.Q_Bwd;


fbConvTop();
GVL_IO.dout.ctrl_turn_on_top_conveyor := fbConvTop.Outp.Q_Fwd;

fbConvElev();
GVL_IO.dout.ctrl_turn_on_elevator_conveyor_in := fbConvElev.Outp.Q_Fwd;
GVL_IO.dout.ctrl_turn_on_elevator_conveyor_out := fbConvElev.Outp.Q_Bwd;

fbConvBottom();
GVL_IO.dout.ctrl_turn_on_bottom_conveyor := fbConvBottom.Outp.Q_Fwd;
GVL_IO.dout.ctrl_turn_on_bottom_conveyor_in := fbConvBottom.Outp.Q_Bwd;


xAutoActive := robot.Sts.order.running OR robot.Sts.order.stopping;
GVL_IO.dout.ctrl_turn_on_light_red := plantNow.critical OR robot.Sts.diag.fault;
GVL_IO.dout.ctrl_turn_on_light_yellow := plantNow.warning OR robot.Sts.order.stopping;
GVL_IO.dout.ctrl_turn_on_light_green := robot.Sts.order.running AND NOT GVL_IO.dout.ctrl_turn_on_light_red;
GVL_IO.dout.ctrl_turn_on_buzzer := GVL_IO.dout.ctrl_turn_on_light_red;
GVL_IO.dout.ctrl_LED_button_start_process := robot.Sts.order.canStart;
GVL_IO.dout.ctrl_LED_button_continue_process := FALSE;
GVL_IO.dout.ctrl_LED_button_samples := GVL_HMI.hmiV2.permit.samples.xAllowed;
GVL_IO.dout.ctrl_LED_button_start_emptying_process := FALSE;
(* Odpowiedz granted moze zostac tylko odebrana po zmianie gotowosci urzadzen. *)
GVL_Robot.Tx.area_elevator_granted := GVL_Robot.Tx.area_elevator_granted AND NOT stackAdvancePending;
GVL_Robot.Tx.area_storage_granted := GVL_Robot.Tx.area_storage_granted AND fbStorage.Sts.RobotAccessGranted;

materialIn.valid := io.Sts.valid;
materialIn.reconcile := robot.Recovery.Approved;
materialIn.restored := GVL_RobotRetain.Context.occupied;
materialIn.observed[1] := fbTopFlow.Sts.OccP1; materialIn.observed[2] := fbTopFlow.Sts.OccP2;
materialIn.observed[3] := fbTopFlow.Sts.OccP3; materialIn.observed[4] := xElevatorLoadPresent;
materialIn.observed[5] := fbBottom567.Sts.Occ5; materialIn.observed[6] := fbBottom567.Sts.Occ6;
materialIn.observed[7] := fbBottom567.Sts.Occ7;
materialIn.sensed := io.Sts.occupied;
(* B205 jest czujnikiem krawedzi: brak aktywnosci nie oznacza braku zapamietanego ladunku. *)
materialIn.moving := fbTopFlow.Sts.Busy OR fbBottom567.Sts.Busy OR elevStat.xBusy;
materialIn.commit := (topWasBusy AND NOT fbTopFlow.Sts.Busy) OR (lowerWasBusy AND NOT fbBottom567.Sts.Busy) OR
 fbTopFlow.Sts.Pos1Accepted OR plantNow.sourceEmptyConfirmed OR GVL_RobotRetain.Context.tasks[2].pending;
materialIn.manualMoved := manual.Sts.active;
materialIn.pending := fbBottom567.Sts.WaitingPickup OR (transport.Sts.busy AND transport.Sts.owner <> E_StationOwner.PRODUCTION) OR
 xBottomDonePendingTray OR xBottomDonePendingBox;
material(Inp := materialIn);
GVL_Station.Material := material.Sts;
IF material.Sts.known THEN
 GVL_RobotRetain.Context.occupied := material.Sts.occupied;
 GVL_RobotRetain.Context.elevatorLoadPresent := material.Sts.occupied[4];
END_IF;
GVL_RobotRetain.Context.occupancyKnown := material.Sts.known;
GVL_RobotRetain.Context.topTransferState := fbTopFlow.Sts.State;
GVL_RobotRetain.Context.bottomTransferState := fbBottom567.Sts.State;
GVL_RobotRetain.Context.bottomTransferOwner := 0;
IF xBottomTransferOwnerTray THEN GVL_RobotRetain.Context.bottomTransferOwner := 2; END_IF;
IF xBottomTransferOwnerBox THEN GVL_RobotRetain.Context.bottomTransferOwner := 1; END_IF;
GVL_RobotRetain.Context.bottomDonePendingTray := xBottomDonePendingTray;
GVL_RobotRetain.Context.bottomDonePendingBox := xBottomDonePendingBox;
GVL_RobotRetain.Context.stationDrainStep := drain.Sts.state;
GVL_RobotRetain.Context.stationOwner := transport.Sts.owner;
GVL_RobotRetain.Context.stationAction := transport.Sts.action;
GVL_RobotRetain.Context.pickupPending := fbBottom567.Sts.WaitingPickup;
GVL_RobotRetain.Context.pickupSeen := fbBottom567.Sts.PickupSeen;

// 15) ALARM MANAGER — zbieranie faultów
// ================================================================

GVL_HMI.hmiAlarms.xM1_Fault         := fbPosM1.Diag.Fault;
GVL_HMI.hmiAlarms.xM2_Fault         := fbStopM2.Diag.Fault;
GVL_HMI.hmiAlarms.xM3_Fault         := fbStopM3.Diag.Fault;
GVL_HMI.hmiAlarms.xM4_Fault         := fbStopM4.Diag.Fault;
GVL_HMI.hmiAlarms.xM5_Fault         := fbPosM5.Diag.Fault;
GVL_HMI.hmiAlarms.xM6_Fault         := (fbV201.Diag.Fault OR fbV202.Diag.Fault);
GVL_HMI.hmiAlarms.xM7_Fault         := fbPosM7.Diag.Fault;
GVL_HMI.hmiAlarms.xM8_Fault         := fbStorage.Diag.Fault;
GVL_HMI.hmiAlarms.xConvTop_Fault    := fbConvTop.Diag.Fault;
GVL_HMI.hmiAlarms.xConvElev_Fault   := fbConvElev.Diag.Fault;
GVL_HMI.hmiAlarms.xConvBottom_Fault := fbConvBottom.Diag.Fault;
GVL_HMI.hmiAlarms.xElev_Fault       := elevStat.xFault;
GVL_HMI.hmiAlarms.xElev_CommLost    := FALSE; // osobny alarm komunikacji windy nieużywany
GVL_HMI.hmiAlarms.xTopFlow_Fault    := fbTopFlow.Diag.Fault;
GVL_HMI.hmiAlarms.xBottom_Fault     := fbBottom567.Diag.Fault;
GVL_HMI.hmiAlarms.xTraySeq_Fault    := fbTraySeq.Diag.Fault;
GVL_HMI.hmiAlarms.xBoxSeq_Fault     := fbBoxSeq.Diag.Fault;
GVL_HMI.hmiAlarms.xRobot_Fault      := (GVL_Robot.Rx.production_fault AND robot.Sts.diagnosticValid);
GVL_HMI.hmiAlarms.xRobot_EStop      := (GVL_Robot.Rx.production_estopActive AND robot.Sts.diagnosticValid);
GVL_HMI.hmiAlarms.xRobot_CommLost   := NOT robot.Sts.session;
GVL_HMI.hmiAlarms.xVfd_CommLost     := xGlobalEnable AND (NOT elevStat.xVfdCommOk);
GVL_HMI.hmiAlarms.xLowPressure      := GVL_IO.di.ind_low_pressure;
GVL_HMI.hmiAlarms.xSafetyTrip       := NOT xSafetyOK;

GVL_HMI.hmiAlarmCount := 
    TO_UINT(GVL_HMI.hmiAlarms.xM1_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xM2_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xM3_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xM4_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xM5_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xM6_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xM7_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xM8_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xConvTop_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xConvElev_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xConvBottom_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xElev_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xElev_CommLost) +
    TO_UINT(GVL_HMI.hmiAlarms.xTopFlow_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xBottom_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xTraySeq_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xBoxSeq_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xRobot_Fault) +
    TO_UINT(GVL_HMI.hmiAlarms.xRobot_EStop) +
    TO_UINT(GVL_HMI.hmiAlarms.xRobot_CommLost) +
    TO_UINT(GVL_HMI.hmiAlarms.xVfd_CommLost) +
    TO_UINT(GVL_HMI.hmiAlarms.xRobot_MbLost) +
    TO_UINT(GVL_HMI.hmiAlarms.xLowPressure) +
    TO_UINT(GVL_HMI.hmiAlarms.xSafetyTrip);

// ================================================================
// 16) HMI STATUS — aktualizacja statusu stacji dla wizualizacji
// ================================================================

GVL_HMI.hmiStatus.xAutoRunning     := xAutoActive;
GVL_HMI.hmiStatus.xManualMode      := xHmiManualMode;
GVL_HMI.hmiStatus.xEmptyingStation := xEmptyRunning;
GVL_HMI.hmiStatus.xModeTray        := xModeTray;
GVL_HMI.hmiStatus.xModeBox         := xModeBox;
GVL_HMI.hmiStatus.xGlobalEnable    := xGlobalEnable;
GVL_HMI.hmiStatus.xSafetyOK        := xSafetyOK;

// Pozycje
GVL_HMI.hmiStatus.xOccP1 := fbTopFlow.Sts.OccP1;
GVL_HMI.hmiStatus.xOccP2 := fbTopFlow.Sts.OccP2;
GVL_HMI.hmiStatus.xOccP3 := fbTopFlow.Sts.OccP3;
GVL_HMI.hmiStatus.xOccP4 := io.Sts.occupied[4];
GVL_HMI.hmiStatus.xOccP5 := fbBottom567.Sts.Occ5;
GVL_HMI.hmiStatus.xOccP6 := fbBottom567.Sts.Occ6;
GVL_HMI.hmiStatus.xOccP7 := fbBottom567.Sts.Occ7;

// Winda
GVL_HMI.hmiStatus.uiElevState   := uiElevState;
GVL_HMI.hmiStatus.xElevAtTop    := elevStat.ePos = E_ElevatorPos.posTop;
GVL_HMI.hmiStatus.xElevAtBottom := elevStat.ePos = E_ElevatorPos.posBottom;
GVL_HMI.hmiStatus.xElevBusy     := elevStat.xBusy;
GVL_HMI.hmiStatus.xElevFault    := elevStat.xFault;
GVL_HMI.hmiStatus.rElevFreq_Hz  := elevStat.rVfdOutHz;
GVL_HMI.hmiStatus.sElevDiagText := elevStat.sDiagText;

// Transportery
GVL_HMI.hmiStatus.xConvTopRunning    := fbConvTop.Sts.Running;
GVL_HMI.hmiStatus.xConvElevRunning   := fbConvElev.Sts.Running;
GVL_HMI.hmiStatus.xConvBottomRunning := fbConvBottom.Sts.Running;
GVL_HMI.hmiStatus.uiConvTopState      := TO_UINT(fbConvTop.Sts.State);
GVL_HMI.hmiStatus.uiConvElevState     := TO_UINT(fbConvElev.Sts.State);
GVL_HMI.hmiStatus.uiConvBottomState   := TO_UINT(fbConvBottom.Sts.State);
GVL_HMI.hmiStatus.iConvTopDirection   := fbConvTop.Sts.Direction;
GVL_HMI.hmiStatus.iConvElevDirection  := fbConvElev.Sts.Direction;
GVL_HMI.hmiStatus.iConvBottomDirection := fbConvBottom.Sts.Direction;
GVL_HMI.hmiStatus.xConvTopFault       := fbConvTop.Diag.Fault;
GVL_HMI.hmiStatus.xConvElevFault      := fbConvElev.Diag.Fault;
GVL_HMI.hmiStatus.xConvBottomFault    := fbConvBottom.Diag.Fault;
GVL_HMI.hmiStatus.sConvTopDiagText    := fbConvTop.Diag.Text;
GVL_HMI.hmiStatus.sConvElevDiagText   := fbConvElev.Diag.Text;
GVL_HMI.hmiStatus.sConvBottomDiagText := fbConvBottom.Diag.Text;

// Siłowniki — stan zagregowany (kompatybilność wstecz)
GVL_HMI.hmiStatus.xM1_Extended := fbPosM1.Sts.IsUp;
GVL_HMI.hmiStatus.xM2_Up       := fbStopM2.Sts.IsUp;
GVL_HMI.hmiStatus.xM3_Up       := fbStopM3.Sts.IsUp;
GVL_HMI.hmiStatus.xM4_Up       := fbStopM4.Sts.IsUp;
GVL_HMI.hmiStatus.xM5_Up       := fbPosM5.Sts.IsUp;
GVL_HMI.hmiStatus.xM6_Up       := (fbV201.Sts.AtExt AND fbV202.Sts.AtExt);
GVL_HMI.hmiStatus.xM7_Extended := fbPosM7.Sts.IsUp;
GVL_HMI.hmiStatus.xM8_Extended := fbStorage.Sts.RobotSideOpen;
GVL_HMI.hmiStatus.xM1_Retracted := fbPosM1.Sts.IsDown;
GVL_HMI.hmiStatus.xM2_Down      := fbStopM2.Sts.IsDown;
GVL_HMI.hmiStatus.xM3_Down      := fbStopM3.Sts.IsDown;
GVL_HMI.hmiStatus.xM4_Down      := fbStopM4.Sts.IsDown;
GVL_HMI.hmiStatus.xM5_Down      := fbPosM5.Sts.IsDown;
GVL_HMI.hmiStatus.xM6_Down      := (fbV201.Sts.AtRet AND fbV202.Sts.AtRet);
GVL_HMI.hmiStatus.xM7_Retracted := fbPosM7.Sts.IsDown;
GVL_HMI.hmiStatus.xM8_Retracted := fbStorage.Sts.RobotSideClosed;
GVL_HMI.hmiStatus.xM1_Busy      := fbPosM1.Sts.Busy;
GVL_HMI.hmiStatus.xM2_Busy      := fbStopM2.Sts.Busy;
GVL_HMI.hmiStatus.xM3_Busy      := fbStopM3.Sts.Busy;
GVL_HMI.hmiStatus.xM4_Busy      := fbStopM4.Sts.Busy;
GVL_HMI.hmiStatus.xM5_Busy      := fbPosM5.Sts.Busy;
GVL_HMI.hmiStatus.xM6_Busy      := (fbV201.Sts.Busy OR fbV202.Sts.Busy);
GVL_HMI.hmiStatus.xM7_Busy      := fbPosM7.Sts.Busy;
GVL_HMI.hmiStatus.xM8_Busy      := fbStorage.Sts.Busy;
GVL_HMI.hmiStatus.xM1_Fault     := fbPosM1.Diag.Fault;
GVL_HMI.hmiStatus.xM2_Fault     := fbStopM2.Diag.Fault;
GVL_HMI.hmiStatus.xM3_Fault     := fbStopM3.Diag.Fault;
GVL_HMI.hmiStatus.xM4_Fault     := fbStopM4.Diag.Fault;
GVL_HMI.hmiStatus.xM5_Fault     := fbPosM5.Diag.Fault;
GVL_HMI.hmiStatus.xM6_Fault     := (fbV201.Diag.Fault OR fbV202.Diag.Fault);
GVL_HMI.hmiStatus.xM7_Fault     := fbPosM7.Diag.Fault;
GVL_HMI.hmiStatus.xM8_Fault     := fbStorage.Diag.Fault;
GVL_HMI.hmiStatus.sM1DiagText   := fbPosM1.Diag.Text;
GVL_HMI.hmiStatus.sM2DiagText   := fbStopM2.Diag.Text;
GVL_HMI.hmiStatus.sM3DiagText   := fbStopM3.Diag.Text;
GVL_HMI.hmiStatus.sM4DiagText   := fbStopM4.Diag.Text;
GVL_HMI.hmiStatus.sM5DiagText   := fbPosM5.Diag.Text;
GVL_HMI.hmiStatus.sM6DiagText   := 'V201/V202: sprawdz osobna diagnostyke osi';
GVL_HMI.hmiStatus.sM7DiagText   := fbPosM7.Diag.Text;
GVL_HMI.hmiStatus.sM8DiagText   := fbStorage.Diag.Text;

// Krańcówki siłowników — surowe czujniki fizyczne
// M1 — pozycjoner załadunku
GVL_HMI.hmiStatus.xM1_1_Fwd := GVL_IO.di.ind_M1_1_fwd;
GVL_HMI.hmiStatus.xM1_2_Fwd := GVL_IO.di.ind_M1_2_fwd;
GVL_HMI.hmiStatus.xM1_1_Bwd := GVL_IO.di.ind_M1_1_bwd;
GVL_HMI.hmiStatus.xM1_2_Bwd := GVL_IO.di.ind_M1_2_bwd;
// M2 — stoper P1
GVL_HMI.hmiStatus.xM2_1_Fwd := GVL_IO.di.ind_M2_1_fwd;
GVL_HMI.hmiStatus.xM2_2_Fwd := GVL_IO.di.ind_M2_2_fwd;
GVL_HMI.hmiStatus.xM2_1_Bwd := GVL_IO.di.ind_M2_1_bwd;
GVL_HMI.hmiStatus.xM2_2_Bwd := GVL_IO.di.ind_M2_2_bwd;
// M3 — stoper P2
GVL_HMI.hmiStatus.xM3_1_Fwd := GVL_IO.di.ind_M3_1_fwd;
GVL_HMI.hmiStatus.xM3_2_Fwd := GVL_IO.di.ind_M3_2_fwd;
GVL_HMI.hmiStatus.xM3_1_Bwd := GVL_IO.di.ind_M3_1_bwd;
GVL_HMI.hmiStatus.xM3_2_Bwd := GVL_IO.di.ind_M3_2_bwd;
// M4 — stoper P3
GVL_HMI.hmiStatus.xM4_1_Fwd := GVL_IO.di.ind_M4_1_fwd;
GVL_HMI.hmiStatus.xM4_2_Fwd := GVL_IO.di.ind_M4_2_fwd;
GVL_HMI.hmiStatus.xM4_1_Bwd := GVL_IO.di.ind_M4_1_bwd;
GVL_HMI.hmiStatus.xM4_2_Bwd := GVL_IO.di.ind_M4_2_bwd;
// M5 — pozycjoner tacek P3
GVL_HMI.hmiStatus.xM5_1_Fwd := GVL_IO.di.ind_M5_1_fwd;
GVL_HMI.hmiStatus.xM5_2_Fwd := GVL_IO.di.ind_M5_2_fwd;
GVL_HMI.hmiStatus.xM5_1_Bwd := GVL_IO.di.ind_M5_1_bwd;
GVL_HMI.hmiStatus.xM5_2_Bwd := GVL_IO.di.ind_M5_2_bwd;
// M6 — pozycjoner tacek winda
GVL_HMI.hmiStatus.xM6_1_Fwd := GVL_IO.di.ind_M6_1_fwd;
GVL_HMI.hmiStatus.xM6_2_Fwd := GVL_IO.di.ind_M6_2_fwd;
GVL_HMI.hmiStatus.xM6_1_Bwd := GVL_IO.di.ind_M6_1_bwd;
GVL_HMI.hmiStatus.xM6_2_Bwd := GVL_IO.di.ind_M6_2_bwd;
// M7 — pozycjoner kuwet winda
GVL_HMI.hmiStatus.xM7_Fwd := GVL_IO.di.ind_M7_fwd;
GVL_HMI.hmiStatus.xM7_Bwd := GVL_IO.di.ind_M7_bwd;
// M8 — osłona magazynu przekładek
GVL_HMI.hmiStatus.xM8_Fwd := GVL_IO.di.ind_M8_fwd;
GVL_HMI.hmiStatus.xM8_Bwd := GVL_IO.di.ind_M8_bwd;

// Drzwi celi robota
GVL_HMI.hmiStatus.uiSafetyDoorState        := TO_UINT(fbSafetyDoor.Sts.State);
GVL_HMI.hmiStatus.xSafetyDoorClosed        := fbSafetyDoor.Sts.DoorClosed;
GVL_HMI.hmiStatus.xSafetyDoorLocked        := fbSafetyDoor.Sts.DoorLocked;
GVL_HMI.hmiStatus.xSafetyDoorDeviceError   := fbSafetyDoor.Sts.DeviceError;
GVL_HMI.hmiStatus.xSafetyDoorUnlockRequest := fbSafetyDoor.Sts.UnlockRequest;
GVL_HMI.hmiStatus.xSafetyDoorReadyToRun    := fbSafetyDoor.Sts.ReadyToRun;
GVL_HMI.hmiStatus.xSafetyDoorBusy          := fbSafetyDoor.Sts.Busy;
GVL_HMI.hmiStatus.xSafetyDoorFault         := fbSafetyDoor.Diag.Fault;
GVL_HMI.hmiStatus.sSafetyDoorDiagText      := fbSafetyDoor.Diag.Text;

// Magazyn przekładek
GVL_HMI.hmiStatus.uiStorageState               := TO_UINT(fbStorage.Sts.State);
GVL_HMI.hmiStatus.xStorageRobotSideOpen        := fbStorage.Sts.RobotSideOpen;
GVL_HMI.hmiStatus.xStorageRobotSideClosed      := fbStorage.Sts.RobotSideClosed;
GVL_HMI.hmiStatus.xStorageRobotAccessActive    := fbStorage.Sts.RobotAccessActive;
GVL_HMI.hmiStatus.xStorageOperatorAccessActive := fbStorage.Sts.OperatorAccessActive;
GVL_HMI.hmiStatus.xStorageOperatorRequest      := fbStorage.Sts.OperatorRequest;
GVL_HMI.hmiStatus.xStorageRobotPermission      :=
    GVL_IO.di.ind_spacer_storage_robot_side_doors_opening_permission;
GVL_HMI.hmiStatus.xStorageOperatorPermission   :=
    GVL_IO.di.ind_spacer_storage_operator_side_doors_opening_permission;
GVL_HMI.hmiStatus.xStorageLowLevel             := fbStorage.Sts.LowLevel;
GVL_HMI.hmiStatus.xStorageEmpty                := fbStorage.Sts.Empty;
GVL_HMI.hmiStatus.xStorageBusy                 := fbStorage.Sts.Busy;
GVL_HMI.hmiStatus.xStorageFault                := fbStorage.Diag.Fault;
GVL_HMI.hmiStatus.sStorageDiagText             := fbStorage.Diag.Text;

// Robot
GVL_HMI.hmiStatus.xRobotAutoMode := (GVL_Robot.Rx.production_autoMode AND robot.Sts.session);
GVL_HMI.hmiStatus.xRobotReady    := (GVL_Robot.Rx.production_systemReady AND robot.Sts.session);
GVL_HMI.hmiStatus.xRobotRunning  := (GVL_Robot.Rx.production_running AND robot.Sts.session);
GVL_HMI.hmiStatus.xRobotFault    := (GVL_Robot.Rx.production_fault AND robot.Sts.diagnosticValid);
GVL_HMI.hmiStatus.xRobotHome     := (GVL_Robot.Rx.production_home AND robot.Sts.session);
GVL_HMI.hmiStatus.xRobotCommOk   := robot.Sts.session;
GVL_HMI.hmiStatus.xVfdCommOk     := elevStat.xVfdCommOk;

// Stany sekwencerów
GVL_HMI.hmiStatus.uiTraySeqState := TO_UINT(fbTraySeq.Sts.State);
GVL_HMI.hmiStatus.uiBoxSeqState  := TO_UINT(fbBoxSeq.Sts.State);
GVL_HMI.hmiStatus.uiTopFlowState := TO_UINT(fbTopFlow.Sts.State);
GVL_HMI.hmiStatus.uiBottomState  := TO_UINT(fbBottom567.Sts.State);
GVL_HMI.hmiStatus.sTopFlowDiagText := fbTopFlow.Diag.FaultText;
GVL_HMI.hmiStatus.sBottomDiagText  := fbBottom567.Diag.Text;
GVL_HMI.hmiStatus.sTraySeqDiagText := fbTraySeq.Diag.FaultText;
GVL_HMI.hmiStatus.sBoxSeqDiagText  := fbBoxSeq.Diag.FaultText;

GVL_HMI.hmiStatus.uiTraysDone  := fbTraySeq.Sts.TrayCount;
GVL_HMI.hmiStatus.uiStacksDone := fbTraySeq.Sts.StackCount;
GVL_HMI.hmiStatus.uiBoxesDone  := fbBoxSeq.Sts.BoxCount;

(* Rozszerzenie HMI: 12..15 Apply ST1..4, 16..20 Reload ST1..5, 21..25 ResetState ST1..5. *)
parameterIn.apply := 0; parameterIn.reload := 0;
parameterIn.idle := stationIdle AND NOT robot.Sts.order.running AND NOT GVL_Robot.Drain.runPermit;
parameterIn.recovery := robot.Sts.recoveryRequired;
parameterIn.expectedRevision := robot.Panel.StationRevision;
stationReset := 0; stationCommandReason := 0;
IF robot.Panel.StationKey >= 12 AND robot.Panel.StationKey <= 15 THEN parameterIn.apply := TO_UINT(robot.Panel.StationKey - 11); END_IF;
IF robot.Panel.StationKey >= 16 AND robot.Panel.StationKey <= 19 THEN parameterIn.reload := TO_UINT(robot.Panel.StationKey - 15); END_IF;
IF robot.Panel.StationKey = 20 THEN
 GVL_HMI.hmiV2.edit.uiBatchCount := GVL_RobotRetain.Context.batchCount;
 GVL_HMI.hmiV2.edit.uiProgram := GVL_RobotRetain.Context.program;
END_IF;
IF robot.Panel.StationKey >= 21 AND robot.Panel.StationKey <= 25 THEN stationReset := TO_UINT(robot.Panel.StationKey - 20); END_IF;
parameters(Cfg := GVL_Station.ParameterCfg, Inp := parameterIn, Snapshot := robot.Panel.StationSnapshot,
 Edit := GVL_HMI.hmiV2.stationEdit, Active := GVL_RobotRetain.Context.stationParameters,
 Revision := GVL_RobotRetain.Context.stationParamRevision);
stationCommandReason := parameters.Sts.reason;
IF parameterIn.reload > 0 THEN
 GVL_HMI.hmiV2.stationEditRevision[parameterIn.reload] := parameters.Sts.revision[parameterIn.reload];
END_IF;
GVL_HMI.hmiV2.stationActual := parameters.Sts.actual;
GVL_HMI.hmiV2.stationRevision := parameters.Sts.revision;
IF stationReset > 0 THEN
 IF NOT xHmiManualMode OR NOT stationIdle OR GVL_Robot.Drain.runPermit THEN stationCommandReason := 30;
 ELSE
  (* Reset kroku nie usuwa ladunkow, licznikow, ACK ani zobowiazan. *)
  GVL_Station.ReconcileRequired := TRUE;
 END_IF;
END_IF;
IF robot.Recovery.Approved THEN GVL_Station.ReconcileRequired := FALSE; END_IF;
GVL_Robot.Plant.stationCommandComplete := robot.Panel.StationKey > 0;
GVL_Robot.Plant.stationCommandReason := stationCommandReason;

(* Katalog 1..11: ostrzezenia silownikow, 12..28: klasy do uzgodnienia GAP-12. *)
alarmIn := GVL_Station.AlarmInputs;
alarmIn.reset := xResetAll;
alarmIn.acknowledge := robot.Panel.StationKey = 26;
alarmIn.active[1] := fbPosM1.Diag.Fault; alarmIn.active[2] := fbStopM2.Diag.Fault;
alarmIn.active[3] := fbStopM3.Diag.Fault; alarmIn.active[4] := fbStopM4.Diag.Fault;
alarmIn.active[5] := fbPosM5.Diag.Fault; alarmIn.active[6] := fbV201.Diag.Fault;
alarmIn.active[7] := fbV202.Diag.Fault; alarmIn.active[8] := fbPosM7.Diag.Fault;
alarmIn.active[9] := fbLowerStop5.Diag.Fault; alarmIn.active[10] := fbLowerStop6.Diag.Fault;
alarmIn.active[11] := fbStorage.Diag.Fault;
alarmIn.active[12] := NOT xSafetyOK; alarmIn.active[13] := GVL_IO.di.ind_low_pressure;
alarmIn.active[14] := NOT GVL_Robot.vfdCommHealthy; alarmIn.active[15] := elevStat.xFault;
alarmIn.active[16] := fbConvTop.Diag.Fault; alarmIn.active[17] := fbConvElev.Diag.Fault;
alarmIn.active[18] := fbConvBottom.Diag.Fault; alarmIn.active[19] := fbTopFlow.Diag.Fault;
alarmIn.active[20] := fbBottom567.Diag.Fault; alarmIn.active[21] := fbTraySeq.Diag.Fault;
alarmIn.active[22] := fbBoxSeq.Diag.Fault; alarmIn.active[23] := robot.Sts.diagnosticValid AND GVL_Robot.Rx.production_fault;
alarmIn.active[24] := robot.Sts.diag.fault; alarmIn.active[25] := NOT io.Sts.valid;
alarmIn.active[26] := NOT material.Sts.known; alarmIn.active[27] := transport.Sts.fault;
alarmIn.active[28] := stationCoils.Fault;
alarmIn.active[29] := NOT GVL_HMI.hmiV2.link.xArmed;
alarmIn.active[30] := NOT GVL_Robot.Plant.imm.valid;
FOR i := 1 TO 5 DO
 alarmIn.active[i + 30] := robot.Sts.cylinders[i].reason <> 0;
 alarmIn.active[i + 35] := robot.Sts.vacuum[i].reason <> 0;
END_FOR;
FOR i := 1 TO 12 DO
 alarmIn.active[i + 40] := GVL_Station.IoCfg.required[i] AND NOT io.Sts.moduleValid[i];
END_FOR;
alarms(Cfg := GVL_Station.AlarmCfg, Inp := alarmIn);
GVL_Station.Alarms := alarms.Sts;
fbStorage.Cmd.Enable := xGlobalEnable AND NOT alarms.Sts.critical;
fbStorage.Cmd.ResetFault := xResetAll;
fbStorage.Cmd.RobotAccessReq := GVL_Robot.Rx.area_storage_accessReq AND robot.Sts.session;
fbStorage.Cmd.RobotAccessPermit := outputPermit;
fbStorage.Cmd.RobotReserved := robot.Sts.areas[3].reserved;
fbStorage.Cmd.Manual := xHmiManualMode;
fbStorage.Cmd.ManualHome[1] := manual.Sts.negative[15]; fbStorage.Cmd.ManualWork[1] := manual.Sts.positive[15];
fbStorage.Cmd.ManualHome[2] := manual.Sts.negative[16]; fbStorage.Cmd.ManualWork[2] := manual.Sts.positive[16];
fbStorage.Inp := GVL_Robot.storageIn;
fbStorage.Cfg.tStable := TO_TIME(GVL_RobotRetain.Context.stationParameters[4].sensorStableMs);
fbStorage.Cfg.tM8Timeout := TO_TIME(GVL_RobotRetain.Context.stationParameters[4].actuatorTimeoutMs);
fbStorage();
GVL_Robot.storageOut := fbStorage.Outp;
(* Dawne M8 i proznia 5 nie sa rownoleglym torem nowego chwytaka. *)
GVL_IO.dout.ctrl_move_M8_actuator_forward := FALSE;
GVL_IO.dout.ctrl_move_M8_actuator_backward := FALSE;
GVL_IO.dout.ctrl_turn_on_robot_gripper_vacuum := FALSE;
GVL_IO.dout.ctrl_turn_on_robot_gripper_blow_off := FALSE;
GVL_IO.dout.ctrl_open_spacer_storage_robot_side_lock := fbStorage.Outp.Q_UnlockRobotSide;
GVL_IO.dout.ctrl_open_spacer_storage_operator_side_lock := fbStorage.Outp.Q_UnlockOperatorSide;
GVL_IO.dout.ctrl_LED_button_open_close_spacer_storage := fbStorage.Outp.Q_LEDOpenClose;

FOR i := 1 TO 10 DO
 changeAllowed[i] := GVL_Station.Inputs.beltsStopped[1] AND NOT robot.Sts.areas[1].reserved;
 IF i = 6 OR i = 7 OR i = 8 THEN changeAllowed[i] := GVL_Station.Inputs.beltsStopped[2] AND NOT elevStat.xBusy AND NOT robot.Sts.areas[2].reserved; END_IF;
 IF i >= 9 THEN changeAllowed[i] := GVL_Station.Inputs.beltsStopped[3]; END_IF;
 manualCoilActive[i] := FALSE;
END_FOR;
FOR i := 1 TO 6 DO manualCoilActive[i] := manual.Sts.positive[i + 4] OR manual.Sts.negative[i + 4]; END_FOR;
manualCoilActive[7] := manual.Sts.positive[12] OR manual.Sts.negative[12];
manualCoilActive[8] := manual.Sts.positive[11] OR manual.Sts.negative[11];
manualCoilActive[9] := manual.Sts.positive[13] OR manual.Sts.negative[13];
manualCoilActive[10] := manual.Sts.positive[14] OR manual.Sts.negative[14];
stationCoils(NewPermit := outputPermit, GateChanges := TRUE, ChangeAllowed := changeAllowed,
    Manual := xHmiManualMode, ManualActive := manualCoilActive,
    ReleaseVerified := GVL_Station.ManualReleaseVerified, ReleasePolicy := GVL_Station.ManualRelease, Critical := plantNow.critical OR alarms.Sts.critical OR NOT xSafetyOK OR robot.Sts.recoveryRequired,
    PolicyVerified := GVL_Robot.stationCoilPolicyVerified,
    Cmd := stationCmd, LossPolicy := GVL_Robot.stationCoilLossPolicy);
GVL_IO.dout.ctrl_move_M1_actuator_forward := stationCoils.Applied[1].work;
GVL_IO.dout.ctrl_move_M1_actuator_backward := stationCoils.Applied[1].home;
GVL_IO.dout.ctrl_move_M2_actuator_forward := stationCoils.Applied[2].work;
GVL_IO.dout.ctrl_move_M2_actuator_backward := stationCoils.Applied[2].home;
GVL_IO.dout.ctrl_move_M3_actuator_forward := stationCoils.Applied[3].work;
GVL_IO.dout.ctrl_move_M3_actuator_backward := stationCoils.Applied[3].home;
GVL_IO.dout.ctrl_move_M4_actuator_forward := stationCoils.Applied[4].work;
GVL_IO.dout.ctrl_move_M4_actuator_backward := stationCoils.Applied[4].home;
GVL_IO.dout.ctrl_move_M5_actuator_forward := stationCoils.Applied[5].work;
GVL_IO.dout.ctrl_move_M5_actuator_backward := stationCoils.Applied[5].home;
GVL_IO.dout.ctrl_move_M6_actuator_forward := FALSE; // Legacy M6 odlaczony: dwa nowe wyjscia ponizej.
GVL_IO.dout.ctrl_move_M6_actuator_backward := FALSE;
GVL_Station.Coils := stationCoils.Applied;
GVL_Station.V201Out := stationCoils.Applied[6]; GVL_Station.V202Out := stationCoils.Applied[8];
GVL_Station.LowerStopOut[1] := stationCoils.Applied[9]; GVL_Station.LowerStopOut[2] := stationCoils.Applied[10];
GVL_IO.dout.ctrl_move_M7_actuator_forward := stationCoils.Applied[7].work;
GVL_IO.dout.ctrl_move_M7_actuator_backward := stationCoils.Applied[7].home;


fbElevator(
    xEnable := xGlobalEnable AND NOT alarms.Sts.critical AND NOT stationCoils.Fault,
    stCmd := elevCmd,
    stIn := elevIn,
    stPar := elevPar,
    stOut => elevOut,
    stStat => elevStat
);
uiElevState := TO_UINT(elevStat.eState);

GVL_HMI.hmiAlarmCount := alarms.Sts.count;
GVL_IO.dout.ctrl_turn_on_light_red := alarms.Sts.critical OR plantNow.critical;
GVL_IO.dout.ctrl_turn_on_light_yellow := alarms.Sts.warning OR robot.Sts.order.stopping;
GVL_IO.dout.ctrl_turn_on_light_green := robot.Sts.order.running AND NOT GVL_IO.dout.ctrl_turn_on_light_red;
GVL_IO.dout.ctrl_turn_on_buzzer := GVL_IO.dout.ctrl_turn_on_light_red;
GVL_IO.dout.ctrl_LED_button_start_emptying_process := GVL_Robot.singleUnloadReady;
panelIn.io := io.Sts; panelIn.material := material.Sts; panelIn.drain := drain.Sts;
panelIn.transport := transport.Sts; panelIn.localReady := GVL_Robot.singleUnloadReady;
panelIn.waitingPickup := fbBottom567.Sts.WaitingPickup; panelIn.idle := parameterIn.idle;
panelIn.manual := xHmiManualMode; panelIn.recovery := robot.Sts.recoveryRequired;
stationPanel(Inp := panelIn); GVL_HMI.hmiV2.station := stationPanel.Sts;
GVL_HMI.hmiIo.dataValid := io.Sts.valid;
GVL_HMI.hmiIo.modules := io.Sts.moduleValid;
GVL_HMI.hmiIo.positionsValid := io.Sts.positionValid;
GVL_HMI.hmiIo.occupied := io.Sts.occupied;
GVL_HMI.hmiIo.barrierValid := io.Sts.barrierValid;
GVL_HMI.hmiIo.barrierBlocked := io.Sts.barrierBlocked;
GVL_HMI.hmiIo.appliedCoils := stationCoils.Applied;
GVL_HMI.hmiIo.alarms := alarms.Sts;
GVL_HMI.hmiV2.permit.station1ParamApply.xAllowed := GVL_HMI.hmiV2.link.xArmed AND stationPanel.Sts.canApply;
GVL_HMI.hmiV2.permit.station1ParamApply.sReason := 'Wymagany potwierdzony postoj, zgodna rewizja i zakres nastaw.';
GVL_HMI.hmiV2.permit.station2ParamApply.xAllowed := GVL_HMI.hmiV2.link.xArmed AND stationPanel.Sts.canApply;
GVL_HMI.hmiV2.permit.station2ParamApply.sReason := 'Wymagany potwierdzony postoj, zgodna rewizja i zakres nastaw.';
GVL_HMI.hmiV2.permit.station3ParamApply.xAllowed := GVL_HMI.hmiV2.link.xArmed AND stationPanel.Sts.canApply;
GVL_HMI.hmiV2.permit.station3ParamApply.sReason := 'Wymagany potwierdzony postoj, zgodna rewizja i zakres nastaw.';
GVL_HMI.hmiV2.permit.station4ParamApply.xAllowed := GVL_HMI.hmiV2.link.xArmed AND stationPanel.Sts.canApply;
GVL_HMI.hmiV2.permit.station4ParamApply.sReason := 'Wymagany potwierdzony postoj, zgodna rewizja i zakres nastaw.';
GVL_HMI.hmiV2.permit.station1ParamReload.xAllowed := GVL_HMI.hmiV2.link.xArmed;
GVL_HMI.hmiV2.permit.station1ResetState.xAllowed := GVL_HMI.hmiV2.link.xArmed AND stationPanel.Sts.canResetState;
GVL_HMI.hmiV2.permit.station1ResetState.sReason := 'Manual i postoj; po resecie wymagane uzgodnienie ladunkow.';
GVL_HMI.hmiV2.permit.station2ParamReload.xAllowed := GVL_HMI.hmiV2.link.xArmed;
GVL_HMI.hmiV2.permit.station2ResetState.xAllowed := GVL_HMI.hmiV2.link.xArmed AND stationPanel.Sts.canResetState;
GVL_HMI.hmiV2.permit.station2ResetState.sReason := 'Manual i postoj; po resecie wymagane uzgodnienie ladunkow.';
GVL_HMI.hmiV2.permit.station3ParamReload.xAllowed := GVL_HMI.hmiV2.link.xArmed;
GVL_HMI.hmiV2.permit.station3ResetState.xAllowed := GVL_HMI.hmiV2.link.xArmed AND stationPanel.Sts.canResetState;
GVL_HMI.hmiV2.permit.station3ResetState.sReason := 'Manual i postoj; po resecie wymagane uzgodnienie ladunkow.';
GVL_HMI.hmiV2.permit.station4ParamReload.xAllowed := GVL_HMI.hmiV2.link.xArmed;
GVL_HMI.hmiV2.permit.station4ResetState.xAllowed := GVL_HMI.hmiV2.link.xArmed AND stationPanel.Sts.canResetState;
GVL_HMI.hmiV2.permit.station4ResetState.sReason := 'Manual i postoj; po resecie wymagane uzgodnienie ladunkow.';
GVL_HMI.hmiV2.permit.station5ParamReload.xAllowed := GVL_HMI.hmiV2.link.xArmed;
GVL_HMI.hmiV2.permit.station5ResetState.xAllowed := GVL_HMI.hmiV2.link.xArmed AND stationPanel.Sts.canResetState;
GVL_HMI.hmiV2.permit.station5ResetState.sReason := 'Manual i postoj; po resecie wymagane uzgodnienie ladunkow.';

(* Koncowa blokada transportu przed zapisem wyjsc, z biezacej diagnozy. *)
IF alarms.Sts.critical OR NOT xSafetyOK OR NOT io.Sts.valid THEN
 GVL_IO.dout.ctrl_turn_on_top_conveyor := FALSE;
 GVL_IO.dout.ctrl_turn_on_elevator_conveyor_in := FALSE; GVL_IO.dout.ctrl_turn_on_elevator_conveyor_out := FALSE;
 GVL_IO.dout.ctrl_turn_on_bottom_conveyor := FALSE; GVL_IO.dout.ctrl_turn_on_bottom_conveyor_in := FALSE;
END_IF;

(* Wejscia diagnostyczne z adaptera: wartosc i waznosc oddzielnie. *)
GVL_HMI.hmiIo.value.ind_loading_elevator_1_left_in_home_position := GVL_Station.DiagnosticValue.ind_loading_elevator_1_left_in_home_position;
GVL_HMI.hmiIo.valid.ind_loading_elevator_1_left_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_elevator_1_left_in_home_position;
GVL_HMI.hmiIo.value.ind_loading_elevator_1_left_in_work_position := GVL_Station.DiagnosticValue.ind_loading_elevator_1_left_in_work_position;
GVL_HMI.hmiIo.valid.ind_loading_elevator_1_left_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_elevator_1_left_in_work_position;
GVL_HMI.hmiIo.value.ind_loading_elevator_1_right_in_home_position := GVL_Station.DiagnosticValue.ind_loading_elevator_1_right_in_home_position;
GVL_HMI.hmiIo.valid.ind_loading_elevator_1_right_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_elevator_1_right_in_home_position;
GVL_HMI.hmiIo.value.ind_loading_elevator_1_right_in_work_position := GVL_Station.DiagnosticValue.ind_loading_elevator_1_right_in_work_position;
GVL_HMI.hmiIo.valid.ind_loading_elevator_1_right_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_elevator_1_right_in_work_position;
GVL_HMI.hmiIo.value.ind_loading_elevator_2_left_in_home_position := GVL_Station.DiagnosticValue.ind_loading_elevator_2_left_in_home_position;
GVL_HMI.hmiIo.valid.ind_loading_elevator_2_left_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_elevator_2_left_in_home_position;
GVL_HMI.hmiIo.value.ind_loading_elevator_2_left_in_work_position := GVL_Station.DiagnosticValue.ind_loading_elevator_2_left_in_work_position;
GVL_HMI.hmiIo.valid.ind_loading_elevator_2_left_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_elevator_2_left_in_work_position;
GVL_HMI.hmiIo.value.ind_loading_elevator_2_right_in_home_position := GVL_Station.DiagnosticValue.ind_loading_elevator_2_right_in_home_position;
GVL_HMI.hmiIo.valid.ind_loading_elevator_2_right_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_elevator_2_right_in_home_position;
GVL_HMI.hmiIo.value.ind_loading_elevator_2_right_in_work_position := GVL_Station.DiagnosticValue.ind_loading_elevator_2_right_in_work_position;
GVL_HMI.hmiIo.valid.ind_loading_elevator_2_right_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_elevator_2_right_in_work_position;
GVL_HMI.hmiIo.value.ind_loading_elevator_3_left_in_home_position := GVL_Station.DiagnosticValue.ind_loading_elevator_3_left_in_home_position;
GVL_HMI.hmiIo.valid.ind_loading_elevator_3_left_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_elevator_3_left_in_home_position;
GVL_HMI.hmiIo.value.ind_loading_elevator_3_left_in_work_position := GVL_Station.DiagnosticValue.ind_loading_elevator_3_left_in_work_position;
GVL_HMI.hmiIo.valid.ind_loading_elevator_3_left_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_elevator_3_left_in_work_position;
GVL_HMI.hmiIo.value.ind_loading_elevator_3_right_in_home_position := GVL_Station.DiagnosticValue.ind_loading_elevator_3_right_in_home_position;
GVL_HMI.hmiIo.valid.ind_loading_elevator_3_right_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_elevator_3_right_in_home_position;
GVL_HMI.hmiIo.value.ind_loading_elevator_3_right_in_work_position := GVL_Station.DiagnosticValue.ind_loading_elevator_3_right_in_work_position;
GVL_HMI.hmiIo.valid.ind_loading_elevator_3_right_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_elevator_3_right_in_work_position;
GVL_HMI.hmiIo.value.ind_loading_stopper_1_left_in_home_position := GVL_Station.DiagnosticValue.ind_loading_stopper_1_left_in_home_position;
GVL_HMI.hmiIo.valid.ind_loading_stopper_1_left_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_stopper_1_left_in_home_position;
GVL_HMI.hmiIo.value.ind_loading_stopper_1_left_in_work_position := GVL_Station.DiagnosticValue.ind_loading_stopper_1_left_in_work_position;
GVL_HMI.hmiIo.valid.ind_loading_stopper_1_left_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_stopper_1_left_in_work_position;
GVL_HMI.hmiIo.value.ind_loading_stopper_1_right_in_home_position := GVL_Station.DiagnosticValue.ind_loading_stopper_1_right_in_home_position;
GVL_HMI.hmiIo.valid.ind_loading_stopper_1_right_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_stopper_1_right_in_home_position;
GVL_HMI.hmiIo.value.ind_loading_stopper_1_right_in_work_position := GVL_Station.DiagnosticValue.ind_loading_stopper_1_right_in_work_position;
GVL_HMI.hmiIo.valid.ind_loading_stopper_1_right_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_stopper_1_right_in_work_position;
GVL_HMI.hmiIo.value.ind_loading_stopper_2_left_in_home_position := GVL_Station.DiagnosticValue.ind_loading_stopper_2_left_in_home_position;
GVL_HMI.hmiIo.valid.ind_loading_stopper_2_left_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_stopper_2_left_in_home_position;
GVL_HMI.hmiIo.value.ind_loading_stopper_2_left_in_work_position := GVL_Station.DiagnosticValue.ind_loading_stopper_2_left_in_work_position;
GVL_HMI.hmiIo.valid.ind_loading_stopper_2_left_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_stopper_2_left_in_work_position;
GVL_HMI.hmiIo.value.ind_loading_stopper_2_right_in_home_position := GVL_Station.DiagnosticValue.ind_loading_stopper_2_right_in_home_position;
GVL_HMI.hmiIo.valid.ind_loading_stopper_2_right_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_stopper_2_right_in_home_position;
GVL_HMI.hmiIo.value.ind_loading_stopper_2_right_in_work_position := GVL_Station.DiagnosticValue.ind_loading_stopper_2_right_in_work_position;
GVL_HMI.hmiIo.valid.ind_loading_stopper_2_right_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_loading_stopper_2_right_in_work_position;
GVL_HMI.hmiIo.value.ind_container_in_loading_position_1 := GVL_Station.DiagnosticValue.ind_container_in_loading_position_1;
GVL_HMI.hmiIo.valid.ind_container_in_loading_position_1 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_container_in_loading_position_1;
GVL_HMI.hmiIo.value.ind_container_in_loading_position_2 := GVL_Station.DiagnosticValue.ind_container_in_loading_position_2;
GVL_HMI.hmiIo.valid.ind_container_in_loading_position_2 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_container_in_loading_position_2;
GVL_HMI.hmiIo.value.ind_container_in_loading_position_3 := GVL_Station.DiagnosticValue.ind_container_in_loading_position_3;
GVL_HMI.hmiIo.valid.ind_container_in_loading_position_3 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_container_in_loading_position_3;
GVL_HMI.hmiIo.value.ind_blister_positioner_left_in_home_position := GVL_Station.DiagnosticValue.ind_blister_positioner_left_in_home_position;
GVL_HMI.hmiIo.valid.ind_blister_positioner_left_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_blister_positioner_left_in_home_position;
GVL_HMI.hmiIo.value.ind_blister_positioner_left_in_work_position := GVL_Station.DiagnosticValue.ind_blister_positioner_left_in_work_position;
GVL_HMI.hmiIo.valid.ind_blister_positioner_left_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_blister_positioner_left_in_work_position;
GVL_HMI.hmiIo.value.ind_blister_positioner_right_in_home_position := GVL_Station.DiagnosticValue.ind_blister_positioner_right_in_home_position;
GVL_HMI.hmiIo.valid.ind_blister_positioner_right_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_blister_positioner_right_in_home_position;
GVL_HMI.hmiIo.value.ind_blister_positioner_right_in_work_position := GVL_Station.DiagnosticValue.ind_blister_positioner_right_in_work_position;
GVL_HMI.hmiIo.valid.ind_blister_positioner_right_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_blister_positioner_right_in_work_position;
GVL_HMI.hmiIo.value.ind_blue_box_positioner_left_in_home_position := GVL_Station.DiagnosticValue.ind_blue_box_positioner_left_in_home_position;
GVL_HMI.hmiIo.valid.ind_blue_box_positioner_left_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_blue_box_positioner_left_in_home_position;
GVL_HMI.hmiIo.value.ind_blue_box_positioner_left_in_work_position := GVL_Station.DiagnosticValue.ind_blue_box_positioner_left_in_work_position;
GVL_HMI.hmiIo.valid.ind_blue_box_positioner_left_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_blue_box_positioner_left_in_work_position;
GVL_HMI.hmiIo.value.ind_elevator_in_top_position := GVL_Station.DiagnosticValue.ind_elevator_in_top_position;
GVL_HMI.hmiIo.valid.ind_elevator_in_top_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_elevator_in_top_position;
GVL_HMI.hmiIo.value.ind_elevator_in_intermediate_top_position := GVL_Station.DiagnosticValue.ind_elevator_in_intermediate_top_position;
GVL_HMI.hmiIo.valid.ind_elevator_in_intermediate_top_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_elevator_in_intermediate_top_position;
GVL_HMI.hmiIo.value.ind_elevator_in_intermediate_bottom_position := GVL_Station.DiagnosticValue.ind_elevator_in_intermediate_bottom_position;
GVL_HMI.hmiIo.valid.ind_elevator_in_intermediate_bottom_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_elevator_in_intermediate_bottom_position;
GVL_HMI.hmiIo.value.ind_elevator_in_bottom_position := GVL_Station.DiagnosticValue.ind_elevator_in_bottom_position;
GVL_HMI.hmiIo.valid.ind_elevator_in_bottom_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_elevator_in_bottom_position;
GVL_HMI.hmiIo.value.ind_container_in_elevator_position := GVL_Station.DiagnosticValue.ind_container_in_elevator_position;
GVL_HMI.hmiIo.valid.ind_container_in_elevator_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_container_in_elevator_position;
GVL_HMI.hmiIo.value.ind_unloading_stopper_1_left_in_home_position := GVL_Station.DiagnosticValue.ind_unloading_stopper_1_left_in_home_position;
GVL_HMI.hmiIo.valid.ind_unloading_stopper_1_left_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_unloading_stopper_1_left_in_home_position;
GVL_HMI.hmiIo.value.ind_unloading_stopper_1_left_in_work_position := GVL_Station.DiagnosticValue.ind_unloading_stopper_1_left_in_work_position;
GVL_HMI.hmiIo.valid.ind_unloading_stopper_1_left_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_unloading_stopper_1_left_in_work_position;
GVL_HMI.hmiIo.value.ind_unloading_stopper_1_right_in_home_position := GVL_Station.DiagnosticValue.ind_unloading_stopper_1_right_in_home_position;
GVL_HMI.hmiIo.valid.ind_unloading_stopper_1_right_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_unloading_stopper_1_right_in_home_position;
GVL_HMI.hmiIo.value.ind_unloading_stopper_1_right_in_work_position := GVL_Station.DiagnosticValue.ind_unloading_stopper_1_right_in_work_position;
GVL_HMI.hmiIo.valid.ind_unloading_stopper_1_right_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_unloading_stopper_1_right_in_work_position;
GVL_HMI.hmiIo.value.ind_unloading_stopper_2_left_in_home_position := GVL_Station.DiagnosticValue.ind_unloading_stopper_2_left_in_home_position;
GVL_HMI.hmiIo.valid.ind_unloading_stopper_2_left_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_unloading_stopper_2_left_in_home_position;
GVL_HMI.hmiIo.value.ind_unloading_stopper_2_left_in_work_position := GVL_Station.DiagnosticValue.ind_unloading_stopper_2_left_in_work_position;
GVL_HMI.hmiIo.valid.ind_unloading_stopper_2_left_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_unloading_stopper_2_left_in_work_position;
GVL_HMI.hmiIo.value.ind_unloading_stopper_2_right_in_home_position := GVL_Station.DiagnosticValue.ind_unloading_stopper_2_right_in_home_position;
GVL_HMI.hmiIo.valid.ind_unloading_stopper_2_right_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_unloading_stopper_2_right_in_home_position;
GVL_HMI.hmiIo.value.ind_unloading_stopper_2_right_in_work_position := GVL_Station.DiagnosticValue.ind_unloading_stopper_2_right_in_work_position;
GVL_HMI.hmiIo.valid.ind_unloading_stopper_2_right_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_unloading_stopper_2_right_in_work_position;
GVL_HMI.hmiIo.value.ind_elevator_unloading_area_empty := GVL_Station.DiagnosticValue.ind_elevator_unloading_area_empty;
GVL_HMI.hmiIo.valid.ind_elevator_unloading_area_empty := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_elevator_unloading_area_empty;
GVL_HMI.hmiIo.value.ind_container_in_unloading_position_1 := GVL_Station.DiagnosticValue.ind_container_in_unloading_position_1;
GVL_HMI.hmiIo.valid.ind_container_in_unloading_position_1 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_container_in_unloading_position_1;
GVL_HMI.hmiIo.value.ind_container_in_unloading_position_2 := GVL_Station.DiagnosticValue.ind_container_in_unloading_position_2;
GVL_HMI.hmiIo.valid.ind_container_in_unloading_position_2 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_container_in_unloading_position_2;
GVL_HMI.hmiIo.value.ind_container_in_unloading_position_3 := GVL_Station.DiagnosticValue.ind_container_in_unloading_position_3;
GVL_HMI.hmiIo.valid.ind_container_in_unloading_position_3 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_container_in_unloading_position_3;
GVL_HMI.hmiIo.value.ind_spacer_barrier_left_in_home_position := GVL_Station.DiagnosticValue.ind_spacer_barrier_left_in_home_position;
GVL_HMI.hmiIo.valid.ind_spacer_barrier_left_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_spacer_barrier_left_in_home_position;
GVL_HMI.hmiIo.value.ind_spacer_barrier_left_in_work_position := GVL_Station.DiagnosticValue.ind_spacer_barrier_left_in_work_position;
GVL_HMI.hmiIo.valid.ind_spacer_barrier_left_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_spacer_barrier_left_in_work_position;
GVL_HMI.hmiIo.value.ind_spacer_barrier_right_in_home_position := GVL_Station.DiagnosticValue.ind_spacer_barrier_right_in_home_position;
GVL_HMI.hmiIo.valid.ind_spacer_barrier_right_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_spacer_barrier_right_in_home_position;
GVL_HMI.hmiIo.value.ind_spacer_barrier_right_in_work_position := GVL_Station.DiagnosticValue.ind_spacer_barrier_right_in_work_position;
GVL_HMI.hmiIo.valid.ind_spacer_barrier_right_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_spacer_barrier_right_in_work_position;
GVL_HMI.hmiIo.value.ind_low_level_of_spacers := GVL_Station.DiagnosticValue.ind_low_level_of_spacers;
GVL_HMI.hmiIo.valid.ind_low_level_of_spacers := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_low_level_of_spacers;
GVL_HMI.hmiIo.value.ind_spacer_storage_empty := GVL_Station.DiagnosticValue.ind_spacer_storage_empty;
GVL_HMI.hmiIo.valid.ind_spacer_storage_empty := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_spacer_storage_empty;
GVL_HMI.hmiIo.value.ind_robot_axis_7_in_home_position := GVL_Station.DiagnosticValue.ind_robot_axis_7_in_home_position;
GVL_HMI.hmiIo.valid.ind_robot_axis_7_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_axis_7_in_home_position;
GVL_HMI.hmiIo.value.ind_robot_axis_7_in_work_position := GVL_Station.DiagnosticValue.ind_robot_axis_7_in_work_position;
GVL_HMI.hmiIo.valid.ind_robot_axis_7_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_axis_7_in_work_position;
GVL_HMI.hmiIo.value.ind_robot_gripper_1_in_home_position := GVL_Station.DiagnosticValue.ind_robot_gripper_1_in_home_position;
GVL_HMI.hmiIo.valid.ind_robot_gripper_1_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_gripper_1_in_home_position;
GVL_HMI.hmiIo.value.ind_robot_gripper_1_in_work_position := GVL_Station.DiagnosticValue.ind_robot_gripper_1_in_work_position;
GVL_HMI.hmiIo.valid.ind_robot_gripper_1_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_gripper_1_in_work_position;
GVL_HMI.hmiIo.value.ind_robot_gripper_2_in_home_position := GVL_Station.DiagnosticValue.ind_robot_gripper_2_in_home_position;
GVL_HMI.hmiIo.valid.ind_robot_gripper_2_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_gripper_2_in_home_position;
GVL_HMI.hmiIo.value.ind_robot_gripper_2_in_work_position := GVL_Station.DiagnosticValue.ind_robot_gripper_2_in_work_position;
GVL_HMI.hmiIo.valid.ind_robot_gripper_2_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_gripper_2_in_work_position;
GVL_HMI.hmiIo.value.ind_robot_gripper_3_in_home_position := GVL_Station.DiagnosticValue.ind_robot_gripper_3_in_home_position;
GVL_HMI.hmiIo.valid.ind_robot_gripper_3_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_gripper_3_in_home_position;
GVL_HMI.hmiIo.value.ind_robot_gripper_3_in_work_position := GVL_Station.DiagnosticValue.ind_robot_gripper_3_in_work_position;
GVL_HMI.hmiIo.valid.ind_robot_gripper_3_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_gripper_3_in_work_position;
GVL_HMI.hmiIo.value.ind_robot_gripper_4_in_home_position := GVL_Station.DiagnosticValue.ind_robot_gripper_4_in_home_position;
GVL_HMI.hmiIo.valid.ind_robot_gripper_4_in_home_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_gripper_4_in_home_position;
GVL_HMI.hmiIo.value.ind_robot_gripper_4_in_work_position := GVL_Station.DiagnosticValue.ind_robot_gripper_4_in_work_position;
GVL_HMI.hmiIo.valid.ind_robot_gripper_4_in_work_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_gripper_4_in_work_position;
GVL_HMI.hmiIo.value.ind_e67_imm_reject := GVL_Station.DiagnosticValue.ind_e67_imm_reject;
GVL_HMI.hmiIo.valid.ind_e67_imm_reject := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_e67_imm_reject;
GVL_HMI.hmiIo.value.ind_e67_imm_mould_closed := GVL_Station.DiagnosticValue.ind_e67_imm_mould_closed;
GVL_HMI.hmiIo.valid.ind_e67_imm_mould_closed := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_e67_imm_mould_closed;
GVL_HMI.hmiIo.value.ind_e67_imm_mould_open := GVL_Station.DiagnosticValue.ind_e67_imm_mould_open;
GVL_HMI.hmiIo.valid.ind_e67_imm_mould_open := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_e67_imm_mould_open;
GVL_HMI.hmiIo.value.ind_e67_imm_mould_in_intermediate_position := GVL_Station.DiagnosticValue.ind_e67_imm_mould_in_intermediate_position;
GVL_HMI.hmiIo.valid.ind_e67_imm_mould_in_intermediate_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_e67_imm_mould_in_intermediate_position;
GVL_HMI.hmiIo.value.ind_e67_imm_operation_with_robot_enabled := GVL_Station.DiagnosticValue.ind_e67_imm_operation_with_robot_enabled;
GVL_HMI.hmiIo.valid.ind_e67_imm_operation_with_robot_enabled := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_e67_imm_operation_with_robot_enabled;
GVL_HMI.hmiIo.value.ind_e67_imm_ejector_in_back_position := GVL_Station.DiagnosticValue.ind_e67_imm_ejector_in_back_position;
GVL_HMI.hmiIo.valid.ind_e67_imm_ejector_in_back_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_e67_imm_ejector_in_back_position;
GVL_HMI.hmiIo.value.ind_e67_imm_ejector_in_forward_position := GVL_Station.DiagnosticValue.ind_e67_imm_ejector_in_forward_position;
GVL_HMI.hmiIo.valid.ind_e67_imm_ejector_in_forward_position := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_e67_imm_ejector_in_forward_position;
GVL_HMI.hmiIo.value.ind_e67_imm_core_1_in_position_1 := GVL_Station.DiagnosticValue.ind_e67_imm_core_1_in_position_1;
GVL_HMI.hmiIo.valid.ind_e67_imm_core_1_in_position_1 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_e67_imm_core_1_in_position_1;
GVL_HMI.hmiIo.value.ind_e67_imm_core_1_in_position_2 := GVL_Station.DiagnosticValue.ind_e67_imm_core_1_in_position_2;
GVL_HMI.hmiIo.valid.ind_e67_imm_core_1_in_position_2 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_e67_imm_core_1_in_position_2;
GVL_HMI.hmiIo.value.ind_e67_imm_core_2_in_position_1 := GVL_Station.DiagnosticValue.ind_e67_imm_core_2_in_position_1;
GVL_HMI.hmiIo.valid.ind_e67_imm_core_2_in_position_1 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_e67_imm_core_2_in_position_1;
GVL_HMI.hmiIo.value.ind_e67_imm_core_2_in_position_2 := GVL_Station.DiagnosticValue.ind_e67_imm_core_2_in_position_2;
GVL_HMI.hmiIo.valid.ind_e67_imm_core_2_in_position_2 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_e67_imm_core_2_in_position_2;
GVL_HMI.hmiIo.value.ind_robot_mould_closed := GVL_Station.DiagnosticValue.ind_robot_mould_closed;
GVL_HMI.hmiIo.valid.ind_robot_mould_closed := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_mould_closed;
GVL_HMI.hmiIo.value.ind_robot_mould_open := GVL_Station.DiagnosticValue.ind_robot_mould_open;
GVL_HMI.hmiIo.valid.ind_robot_mould_open := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_mould_open;
GVL_HMI.hmiIo.value.ind_robot_operation_with_imm_enabled := GVL_Station.DiagnosticValue.ind_robot_operation_with_imm_enabled;
GVL_HMI.hmiIo.valid.ind_robot_operation_with_imm_enabled := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_operation_with_imm_enabled;
GVL_HMI.hmiIo.value.ind_robot_mould_area_free := GVL_Station.DiagnosticValue.ind_robot_mould_area_free;
GVL_HMI.hmiIo.valid.ind_robot_mould_area_free := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_mould_area_free;
GVL_HMI.hmiIo.value.ind_robot_enable_mould_closure := GVL_Station.DiagnosticValue.ind_robot_enable_mould_closure;
GVL_HMI.hmiIo.valid.ind_robot_enable_mould_closure := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_enable_mould_closure;
GVL_HMI.hmiIo.value.ind_robot_kf403_tbd := GVL_Station.DiagnosticValue.ind_robot_kf403_tbd;
GVL_HMI.hmiIo.valid.ind_robot_kf403_tbd := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_kf403_tbd;
GVL_HMI.hmiIo.value.ind_robot_reserved_output_1 := GVL_Station.DiagnosticValue.ind_robot_reserved_output_1;
GVL_HMI.hmiIo.valid.ind_robot_reserved_output_1 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_reserved_output_1;
GVL_HMI.hmiIo.value.ind_robot_reserved_output_2 := GVL_Station.DiagnosticValue.ind_robot_reserved_output_2;
GVL_HMI.hmiIo.valid.ind_robot_reserved_output_2 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_reserved_output_2;
GVL_HMI.hmiIo.value.ind_robot_reserved_output_3 := GVL_Station.DiagnosticValue.ind_robot_reserved_output_3;
GVL_HMI.hmiIo.valid.ind_robot_reserved_output_3 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_reserved_output_3;
GVL_HMI.hmiIo.value.ind_robot_reserved_output_4 := GVL_Station.DiagnosticValue.ind_robot_reserved_output_4;
GVL_HMI.hmiIo.valid.ind_robot_reserved_output_4 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_reserved_output_4;
GVL_HMI.hmiIo.value.ind_robot_reserved_output_5 := GVL_Station.DiagnosticValue.ind_robot_reserved_output_5;
GVL_HMI.hmiIo.valid.ind_robot_reserved_output_5 := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_reserved_output_5;
GVL_HMI.hmiIo.value.ind_button_open_close_spacer_storage := GVL_Station.DiagnosticValue.ind_button_open_close_spacer_storage;
GVL_HMI.hmiIo.valid.ind_button_open_close_spacer_storage := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_button_open_close_spacer_storage;
GVL_HMI.hmiIo.value.ind_button_samples := GVL_Station.DiagnosticValue.ind_button_samples;
GVL_HMI.hmiIo.valid.ind_button_samples := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_button_samples;
GVL_HMI.hmiIo.value.ind_button_continue_process := GVL_Station.DiagnosticValue.ind_button_continue_process;
GVL_HMI.hmiIo.valid.ind_button_continue_process := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_button_continue_process;
GVL_HMI.hmiIo.value.ind_button_start_process := GVL_Station.DiagnosticValue.ind_button_start_process;
GVL_HMI.hmiIo.valid.ind_button_start_process := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_button_start_process;
GVL_HMI.hmiIo.value.ind_button_container_ready := GVL_Station.DiagnosticValue.ind_button_container_ready;
GVL_HMI.hmiIo.valid.ind_button_container_ready := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_button_container_ready;
GVL_HMI.hmiIo.value.ind_button_start_emptying_process := GVL_Station.DiagnosticValue.ind_button_start_emptying_process;
GVL_HMI.hmiIo.valid.ind_button_start_emptying_process := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_button_start_emptying_process;
GVL_HMI.hmiIo.value.ind_button_open_close_robot_cell_doors := GVL_Station.DiagnosticValue.ind_button_open_close_robot_cell_doors;
GVL_HMI.hmiIo.valid.ind_button_open_close_robot_cell_doors := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_button_open_close_robot_cell_doors;
GVL_HMI.hmiIo.value.ind_robot_cell_doors_closed := GVL_Station.DiagnosticValue.ind_robot_cell_doors_closed;
GVL_HMI.hmiIo.valid.ind_robot_cell_doors_closed := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_cell_doors_closed;
GVL_HMI.hmiIo.value.ind_robot_cell_doors_locked := GVL_Station.DiagnosticValue.ind_robot_cell_doors_locked;
GVL_HMI.hmiIo.valid.ind_robot_cell_doors_locked := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_robot_cell_doors_locked;
GVL_HMI.hmiIo.value.ind_spacer_storage_robot_side_doors_opening_permission := GVL_Station.DiagnosticValue.ind_spacer_storage_robot_side_doors_opening_permission;
GVL_HMI.hmiIo.valid.ind_spacer_storage_robot_side_doors_opening_permission := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_spacer_storage_robot_side_doors_opening_permission;
GVL_HMI.hmiIo.value.ind_spacer_storage_operator_side_doors_opening_permission := GVL_Station.DiagnosticValue.ind_spacer_storage_operator_side_doors_opening_permission;
GVL_HMI.hmiIo.valid.ind_spacer_storage_operator_side_doors_opening_permission := io.Sts.valid AND GVL_Station.DiagnosticValid.ind_spacer_storage_operator_side_doors_opening_permission;
GVL_HMI.hmiIo.value.ctrl_move_loading_elevator_1_to_work_position := stationCoils.Applied[2].work;
GVL_HMI.hmiIo.valid.ctrl_move_loading_elevator_1_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_loading_elevator_2_to_work_position := stationCoils.Applied[3].work;
GVL_HMI.hmiIo.valid.ctrl_move_loading_elevator_2_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_loading_elevator_3_to_work_position := stationCoils.Applied[4].work;
GVL_HMI.hmiIo.valid.ctrl_move_loading_elevator_3_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_loading_stopper_1_to_work_position := stationCoils.Applied[1].work;
GVL_HMI.hmiIo.valid.ctrl_move_loading_stopper_1_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_loading_stopper_2_to_work_position := stationCoils.Applied[5].work;
GVL_HMI.hmiIo.valid.ctrl_move_loading_stopper_2_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_blister_positioner_left_to_work_position := stationCoils.Applied[6].work;
GVL_HMI.hmiIo.valid.ctrl_move_blister_positioner_left_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_blister_positioner_right_to_work_position := stationCoils.Applied[8].work;
GVL_HMI.hmiIo.valid.ctrl_move_blister_positioner_right_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_blue_box_positioner_left_to_work_position := stationCoils.Applied[7].work;
GVL_HMI.hmiIo.valid.ctrl_move_blue_box_positioner_left_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_unloading_stopper_1_to_work_position := stationCoils.Applied[9].work;
GVL_HMI.hmiIo.valid.ctrl_move_unloading_stopper_1_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_unloading_stopper_2_to_work_position := stationCoils.Applied[10].work;
GVL_HMI.hmiIo.valid.ctrl_move_unloading_stopper_2_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_spacer_barrier_left_to_work_position := fbStorage.Outp.Q_V401Work;
GVL_HMI.hmiIo.valid.ctrl_move_spacer_barrier_left_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_spacer_barrier_right_to_work_position := fbStorage.Outp.Q_V402Work;
GVL_HMI.hmiIo.valid.ctrl_move_spacer_barrier_right_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_robot_axis_7_to_work_position := robot.Sts.cylinders[1].work;
GVL_HMI.hmiIo.valid.ctrl_move_robot_axis_7_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_robot_gripper_1_to_work_position := robot.Sts.cylinders[2].work;
GVL_HMI.hmiIo.valid.ctrl_move_robot_gripper_1_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_robot_gripper_2_to_work_position := robot.Sts.cylinders[3].work;
GVL_HMI.hmiIo.valid.ctrl_move_robot_gripper_2_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_robot_gripper_3_to_work_position := robot.Sts.cylinders[4].work;
GVL_HMI.hmiIo.valid.ctrl_move_robot_gripper_3_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_move_robot_gripper_4_to_work_position := robot.Sts.cylinders[5].work;
GVL_HMI.hmiIo.valid.ctrl_move_robot_gripper_4_to_work_position := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_spare_v506 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_spare_v506 := FALSE;
GVL_HMI.hmiIo.value.ctrl_spare_v507 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_spare_v507 := FALSE;
GVL_HMI.hmiIo.value.ctrl_spare_v508 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_spare_v508 := FALSE;
GVL_HMI.hmiIo.value.ctrl_turn_on_robot_gripper_vacuum_1 := robot.Sts.vacuum[1].hold;
GVL_HMI.hmiIo.valid.ctrl_turn_on_robot_gripper_vacuum_1 := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_turn_on_robot_gripper_vacuum_2 := robot.Sts.vacuum[2].hold;
GVL_HMI.hmiIo.valid.ctrl_turn_on_robot_gripper_vacuum_2 := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_turn_on_robot_gripper_vacuum_3 := robot.Sts.vacuum[3].hold;
GVL_HMI.hmiIo.valid.ctrl_turn_on_robot_gripper_vacuum_3 := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_turn_on_robot_gripper_vacuum_4 := robot.Sts.vacuum[4].hold;
GVL_HMI.hmiIo.valid.ctrl_turn_on_robot_gripper_vacuum_4 := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_turn_on_robot_gripper_vacuum_5 := robot.Sts.vacuum[5].hold;
GVL_HMI.hmiIo.valid.ctrl_turn_on_robot_gripper_vacuum_5 := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_e67_imm_mould_area_free := FALSE;
GVL_HMI.hmiIo.valid.ctrl_e67_imm_mould_area_free := FALSE;
GVL_HMI.hmiIo.value.ctrl_e67_imm_enable_mould_closure := FALSE;
GVL_HMI.hmiIo.valid.ctrl_e67_imm_enable_mould_closure := FALSE;
GVL_HMI.hmiIo.value.ctrl_e67_imm_enable_full_mould_opening := FALSE;
GVL_HMI.hmiIo.valid.ctrl_e67_imm_enable_full_mould_opening := FALSE;
GVL_HMI.hmiIo.value.ctrl_e67_imm_robot_operation_mode := FALSE;
GVL_HMI.hmiIo.valid.ctrl_e67_imm_robot_operation_mode := FALSE;
GVL_HMI.hmiIo.value.ctrl_e67_imm_enable_ejector_back := FALSE;
GVL_HMI.hmiIo.valid.ctrl_e67_imm_enable_ejector_back := FALSE;
GVL_HMI.hmiIo.value.ctrl_e67_imm_enable_ejector_forward := FALSE;
GVL_HMI.hmiIo.valid.ctrl_e67_imm_enable_ejector_forward := FALSE;
GVL_HMI.hmiIo.value.ctrl_e67_imm_enable_core_1_position_1 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_e67_imm_enable_core_1_position_1 := FALSE;
GVL_HMI.hmiIo.value.ctrl_e67_imm_enable_core_1_position_2 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_e67_imm_enable_core_1_position_2 := FALSE;
GVL_HMI.hmiIo.value.ctrl_e67_imm_enable_core_2_position_1 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_e67_imm_enable_core_2_position_1 := FALSE;
GVL_HMI.hmiIo.value.ctrl_e67_imm_enable_core_2_position_2 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_e67_imm_enable_core_2_position_2 := FALSE;
GVL_HMI.hmiIo.value.ctrl_e67_imm_kf211_tbd := FALSE;
GVL_HMI.hmiIo.valid.ctrl_e67_imm_kf211_tbd := FALSE;
GVL_HMI.hmiIo.value.ctrl_e73_imm_safety_acknowledgement := FALSE;
GVL_HMI.hmiIo.valid.ctrl_e73_imm_safety_acknowledgement := FALSE;
GVL_HMI.hmiIo.value.ctrl_robot_reserved_input_1 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_robot_reserved_input_1 := FALSE;
GVL_HMI.hmiIo.value.ctrl_robot_reserved_input_2 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_robot_reserved_input_2 := FALSE;
GVL_HMI.hmiIo.value.ctrl_robot_reserved_input_3 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_robot_reserved_input_3 := FALSE;
GVL_HMI.hmiIo.value.ctrl_robot_reserved_input_4 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_robot_reserved_input_4 := FALSE;
GVL_HMI.hmiIo.value.ctrl_robot_reserved_input_5 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_robot_reserved_input_5 := FALSE;
GVL_HMI.hmiIo.value.ctrl_led_button_open_close_spacer_storage := GVL_IO.dout.ctrl_LED_button_open_close_spacer_storage;
GVL_HMI.hmiIo.valid.ctrl_led_button_open_close_spacer_storage := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_led_button_samples := GVL_IO.dout.ctrl_LED_button_samples;
GVL_HMI.hmiIo.valid.ctrl_led_button_samples := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_led_button_continue_process := GVL_IO.dout.ctrl_LED_button_continue_process;
GVL_HMI.hmiIo.valid.ctrl_led_button_continue_process := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_led_button_start_process := GVL_IO.dout.ctrl_LED_button_start_process;
GVL_HMI.hmiIo.valid.ctrl_led_button_start_process := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_led_button_container_ready := FALSE;
GVL_HMI.hmiIo.valid.ctrl_led_button_container_ready := FALSE;
GVL_HMI.hmiIo.value.ctrl_led_button_start_emptying_process := GVL_IO.dout.ctrl_LED_button_start_emptying_process;
GVL_HMI.hmiIo.valid.ctrl_led_button_start_emptying_process := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_turn_on_loading_conveyor := GVL_IO.dout.ctrl_turn_on_top_conveyor;
GVL_HMI.hmiIo.valid.ctrl_turn_on_loading_conveyor := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_turn_on_unloading_conveyor_out := GVL_IO.dout.ctrl_turn_on_bottom_conveyor;
GVL_HMI.hmiIo.valid.ctrl_turn_on_unloading_conveyor_out := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_turn_on_elevator_conveyor_out := GVL_IO.dout.ctrl_turn_on_elevator_conveyor_out;
GVL_HMI.hmiIo.valid.ctrl_turn_on_elevator_conveyor_out := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_turn_on_elevator_conveyor_in := GVL_IO.dout.ctrl_turn_on_elevator_conveyor_in;
GVL_HMI.hmiIo.valid.ctrl_turn_on_elevator_conveyor_in := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_run_elevator := elevOut.xRunUp OR elevOut.xRunDown;
GVL_HMI.hmiIo.valid.ctrl_run_elevator := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_open_spacer_storage_robot_side_lock := GVL_IO.dout.ctrl_open_spacer_storage_robot_side_lock;
GVL_HMI.hmiIo.valid.ctrl_open_spacer_storage_robot_side_lock := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_open_spacer_storage_operator_side_lock := GVL_IO.dout.ctrl_open_spacer_storage_operator_side_lock;
GVL_HMI.hmiIo.valid.ctrl_open_spacer_storage_operator_side_lock := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_open_robot_cell_doors_lock := GVL_IO.dout.ctrl_open_robot_cell_doors_lock;
GVL_HMI.hmiIo.valid.ctrl_open_robot_cell_doors_lock := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_reset_robot_cell_doors_safety := GVL_IO.dout.ctrl_reset_robot_cell_doors;
GVL_HMI.hmiIo.valid.ctrl_reset_robot_cell_doors_safety := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_robot_cell_doors_led := GVL_IO.dout.ctrl_robot_cell_doors_LED_open_close;
GVL_HMI.hmiIo.valid.ctrl_robot_cell_doors_led := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_bypass_elevator_sto := FALSE;
GVL_HMI.hmiIo.valid.ctrl_bypass_elevator_sto := FALSE;
GVL_HMI.hmiIo.value.ctrl_turn_on_light_green := GVL_IO.dout.ctrl_turn_on_light_green;
GVL_HMI.hmiIo.valid.ctrl_turn_on_light_green := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_turn_on_light_yellow := GVL_IO.dout.ctrl_turn_on_light_yellow;
GVL_HMI.hmiIo.valid.ctrl_turn_on_light_yellow := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_turn_on_light_red := GVL_IO.dout.ctrl_turn_on_light_red;
GVL_HMI.hmiIo.valid.ctrl_turn_on_light_red := io.Sts.valid AND GVL_Robot.stationIoBound;
GVL_HMI.hmiIo.value.ctrl_turn_on_signal_tower_level_4 := FALSE;
GVL_HMI.hmiIo.valid.ctrl_turn_on_signal_tower_level_4 := FALSE;
GVL_HMI.hmiIo.value.ctrl_turn_on_buzzer := GVL_IO.dout.ctrl_turn_on_buzzer;
GVL_HMI.hmiIo.valid.ctrl_turn_on_buzzer := io.Sts.valid AND GVL_Robot.stationIoBound;

GVL_HMI.hmiV2.permit.alarmAckAll.xAllowed := GVL_HMI.hmiV2.link.xArmed;
PRG_IO_Write();
