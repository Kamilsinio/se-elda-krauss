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
    fbPosM6        : FB_StopperPair;   // pozycjoner tacek winda (para)
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
    stationCmd : ARRAY[1..7] OF ST_StationCoil;
END_VAR

PRG_IO_Read();
xResetAll := robot.Panel.Cmd.reset AND GVL_HMI.hmiV2.link.xArmed;
fbSafetyDoor.Enable := GVL_Robot.stationIoBound;
fbSafetyDoor.ResetFault := xResetAll;
fbSafetyDoor.Inp.BtnOpenClose := GVL_IO.di.ind_button_open_close_robot_cell_doors;
fbSafetyDoor.Inp.DoorLocked := GVL_IO.di.ind_robot_cell_doors_locked;
fbSafetyDoor.Inp.DeviceError := NOT GVL_IO.di.ind_robot_cell_doors_error;
fbSafetyDoor();
xSafetyOK := GVL_Robot.Plant.safetyValid AND GVL_Robot.Plant.safetyOK AND fbSafetyDoor.Sts.ReadyToRun;
xGlobalEnable := GVL_Robot.stationIoBound AND GVL_Robot.stationCoilPolicyVerified AND xSafetyOK AND NOT GVL_IO.di.ind_low_pressure AND
    GVL_Robot.elevatorTransferStable > T#0ms AND GVL_Robot.elevatorSlow_Hz > 0.0 AND
    GVL_Robot.elevatorFast_Hz >= GVL_Robot.elevatorSlow_Hz;
GVL_IO.dout.ctrl_open_robot_cell_doors_lock := fbSafetyDoor.Outp.Q_Unlock;
GVL_IO.dout.ctrl_robot_cell_doors_LED_open_close := fbSafetyDoor.Outp.Q_LEDOpenClose;
GVL_IO.dout.ctrl_reset_robot_cell_doors := fbSafetyDoor.Outp.Q_DeviceReset;
plantNow := GVL_Robot.Plant;
plantNow.physicalStart := GVL_IO.di.ind_button_start_process AND GVL_Robot.stationIoBound;
(* physicalStop pozostaje osobnym, niewypelnionym bindingiem. Nie uzywamy starego Continue. *)
plantNow.sampleButton := GVL_IO.di.ind_button_samples AND GVL_Robot.stationIoBound;
plantNow.processOK := plantNow.processOK AND xGlobalEnable;
plantNow.imm.processInterlocks := plantNow.imm.processInterlocks AND xGlobalEnable;
topTransferActive := fbTopFlow.Sts.State <> E_TopFlowState.IDLE AND fbTopFlow.Sts.State <> E_TopFlowState.INIT;
plantNow.transferBusy := plantNow.transferBusy OR topTransferActive OR elevStat.xBusy OR
    ((fbBottom567.Sts.State <> E_Bottom567State.IDLE) AND (fbBottom567.Sts.State <> E_Bottom567State.INIT));
plantNow.critical := plantNow.critical OR stationCoils.Fault OR elevStat.xFault OR fbConvTop.Diag.Fault OR
    fbConvElev.Diag.Fault OR fbConvBottom.Diag.Fault OR fbTraySeq.Diag.Fault OR fbBoxSeq.Diag.Fault;
plantNow.warning := plantNow.warning OR fbPosM1.Diag.Fault OR fbStopM2.Diag.Fault OR
    fbStopM3.Diag.Fault OR fbStopM4.Diag.Fault OR fbPosM5.Diag.Fault OR fbPosM6.Diag.Fault OR
    fbPosM7.Diag.Fault OR fbStorage.Diag.Fault;
sourceEmpty(IN := NOT GVL_IO.di.ind_container_in_pos_3 AND NOT fbConvTop.Sts.Running,
    PT := GVL_Robot.sourceEmptyStable);
plantNow.sourceEmptyConfirmed := GVL_Robot.sourceEmptyStable > T#0ms AND sourceEmpty.Q;
plantNow.areas[1].ready := fbTopFlow.Sts.StackReadyAtP3 AND NOT fbConvTop.Sts.Running AND
    NOT fbConvTop.Outp.Q_Fwd AND NOT fbTopFlow.Sts.Busy AND fbTopFlow.Sts.State = E_TopFlowState.IDLE;
plantNow.areas[2].ready := NOT elevStat.xBusy AND NOT fbConvElev.Sts.Running AND NOT elevStat.xVfdRunning AND
    NOT fbConvElev.Outp.Q_Fwd AND NOT fbConvElev.Outp.Q_Bwd AND
    ((fbTraySeq.Outp.ElevatorReady AND GVL_RobotRetain.Context.program = 2) OR
     (fbBoxSeq.Outp.ElevatorReady AND GVL_RobotRetain.Context.program = 1));
plantNow.areas[3].ready := fbStorage.Sts.RobotSideOpen AND fbStorage.Sts.RobotAccessGranted AND NOT fbStorage.Sts.Empty;
plantNow.areas[1].blocked := plantNow.areas[1].blocked OR fbStopM4.Diag.Fault OR fbPosM5.Diag.Fault;
plantNow.areas[2].blocked := plantNow.areas[2].blocked OR fbPosM6.Diag.Fault OR fbPosM7.Diag.Fault;
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
xEmptyRunning := FALSE; (* Tylko interfejs Drain; stary wykonawca jest odlaczony. *)
xGlobalEnable := xGlobalEnable AND NOT plantNow.critical AND NOT robot.Sts.recoveryRequired;
outputPermit := robot.Sts.session AND (robot.Sts.order.newPermit OR robot.Sts.order.finishPermit) AND xGlobalEnable;
rtContainerReady(CLK := GVL_IO.di.ind_button_container_ready);
IF rtContainerReady.Q AND outputPermit THEN xLoadAcceptedPending := TRUE; END_IF;
fbTopFlow.Cmd.Pos1AcceptedPulse := FALSE;
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
   GVL_IO.di.ind_container_in_pos_1 AND fbTopFlow.Sts.Pos1SensorStable AND
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

// --- M6: pozycjoner tacek winda (para) ---
fbPosM6.Enable := outputPermit;
fbPosM6.ResetFault := xResetAll;
fbPosM6.Inp.ind_1_fwd := GVL_IO.di.ind_M6_1_fwd;
fbPosM6.Inp.ind_2_fwd := GVL_IO.di.ind_M6_2_fwd;
fbPosM6.Inp.ind_1_bwd := GVL_IO.di.ind_M6_1_bwd;
fbPosM6.Inp.ind_2_bwd := GVL_IO.di.ind_M6_2_bwd;

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
fbConvTop.Inp.Enable := xGlobalEnable;
fbConvTop.Inp.SafetyOK := xSafetyOK;
fbConvTop.Cmd.ResetFault := xResetAll;
// RunFwd zarządzany wyłącznie przez TopFlowManager.
// Górny transporter nie ma osobnego wyjścia BWD w GVL_IO — jest jednokierunkowy sprzętowo

// --- Transporter windy (dwukierunkowy: IN = do robota, OUT = do rozładunku) ---
fbConvElev.Inp.Enable := xGlobalEnable;
fbConvElev.Inp.SafetyOK := xSafetyOK;
fbConvElev.Cmd.ResetFault := xResetAll;

// --- Dolny transporter (dwukierunkowy: FWD = do wyjścia, BWD = do windy) ---
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
elevIn.xContainerInPos4 := GVL_IO.di.ind_container_in_pos_4;
elevIn.xSafetyOk := xSafetyOK;
elevIn.xDoorClosed := fbSafetyDoor.Sts.DoorClosed;
elevIn.xCommOk := GVL_Robot.vfdCommHealthy; // Binding diagnostyki ATV320, GAP-06.
elevIn.stVfdRx.uiOutFreq_0p1Hz_3202 := WORD_TO_UINT(GVL_IO.di.ATV320_currentFreq);

// Parametry domyślne windy
elevPar.rMaxSpeed_Hz := 50.0;
elevPar.tMoveTimeout := T#25s;
elevPar.tClearPos4Timeout := T#5s;
elevPar.tVfdResetPulse := T#200ms;
elevPar.xFwdIsUp := TRUE;
elevPar.wStsMask_Fault   := 16#0008; // bit 3 = Fault
elevPar.wStsMask_Ready   := 16#0001; // bit 0 = Ready to Switch On
elevPar.wStsMask_Running := 16#0004; // bit 2 = Operation Enabled (napęd jedzie)
elevPar.wStsMask_Remote  := 16#0200; // bit 9 = Remote / sterowanie z sieci
elevPar.rStopSpeedThreshold_Hz := 1.5; // [Hz] próg "zatrzymany"
elevPar.tStopTimeout     := T#5s;    // bezpieczny timeout STOPPING

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
elevCmd.rSpeedFast_Hz := GVL_Robot.elevatorFast_Hz;
elevCmd.rSpeedSlow_Hz := GVL_Robot.elevatorSlow_Hz;
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
fbTopFlow.Inp.sPos1_raw := GVL_IO.di.ind_container_in_pos_1;
fbTopFlow.Inp.sPos2_raw := GVL_IO.di.ind_container_in_pos_2;
fbTopFlow.Inp.sPos3_raw := GVL_IO.di.ind_container_in_pos_3;
fbTopFlow.Inp.sPos4_raw := GVL_IO.di.ind_container_in_pos_4;
fbTopFlow.Inp.TopConveyorRunning := fbConvTop.Sts.Running;

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
elevatorTransfer(IN := GVL_IO.di.ind_container_in_pos_4 AND GVL_Robot.stationIoBound,
    PT := GVL_Robot.elevatorTransferStable);
xElevTransferDone := elevatorTransfer.Q AND GVL_Robot.elevatorTransferStable > T#0ms;
fbTopFlow.Inp.Elev_TransferDone := xElevTransferDone;

// Komendy do TopFlow sa wybierane po wywolaniu sekwencerow.
// Sam fbTopFlow() jest wywolany pod koniec skanu, przed FB wykonawczymi.


// ================================================================
// 8) BOTTOM ACCUMULATOR — rozładunek P5-P7
// ================================================================

fbBottom567.Cmd.SafetyOK := xGlobalEnable;
fbBottom567.Cmd.ResetFault := xResetAll;

fbBottom567.Inp.sPos5_raw := GVL_IO.di.ind_container_in_pos_5;
fbBottom567.Inp.sPos6_raw := GVL_IO.di.ind_container_in_pos_6;
fbBottom567.Inp.sPos7_raw := GVL_IO.di.ind_container_in_pos_7;
fbBottom567.Inp.sElevatorEmptied_raw := GVL_IO.di.ind_elevator_emptied;



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
fbTraySeq.Inp.ind_container_in_pos_4 := GVL_IO.di.ind_container_in_pos_4;
fbTraySeq.Inp.PositionerHome := fbPosM6.Sts.IsDown;
fbTraySeq.Inp.PositionerWork := fbPosM6.Sts.IsUp;
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
    fbPosM6.HoldUp := fbTraySeq.Outp.M6_Extend;
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
fbBoxSeq.Inp.ind_container_in_pos_4 := GVL_IO.di.ind_container_in_pos_4;
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
IF GVL_RobotRetain.Context.tasks[2].pending OR GVL_IO.di.ind_container_in_pos_4 THEN
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
localUnload(CLK := GVL_IO.di.ind_button_start_emptying_process);
(* Jedno nacisniecie, bez hold; wydanie gotowego ladunku nie uruchamia Drain. *)
GVL_Robot.singleUnloadRequest := localUnload.Q AND GVL_Robot.singleUnloadReady AND
    xGlobalEnable AND NOT GVL_Robot.Drain.request;
(* Wykonawca pojedynczego wydania jest osobnym pakietem stacji, nie transferem P4->P5. *)
IF robot.Sts.areas[1].reserved OR NOT outputPermit THEN
    fbTopFlow.Cmd.SafetyOK := FALSE;
END_IF;
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
fbBottom567();

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
    fbPosM6.Enable := FALSE;
    fbPosM7.Enable := FALSE;
END_IF;
fbElevator(
    xEnable := xGlobalEnable,
    stCmd := elevCmd,
    stIn := elevIn,
    stPar := elevPar,
    stOut => elevOut,
    stStat => elevStat
);
uiElevState := TO_UINT(elevStat.eState);

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

fbPosM6();
stationCmd[6].work := fbPosM6.Outp.Q_Fwd;
stationCmd[6].home := fbPosM6.Outp.Q_Bwd;

fbPosM7();
stationCmd[7].work := fbPosM7.Outp.Q_Fwd;
stationCmd[7].home := fbPosM7.Outp.Q_Bwd;


stationCoils(NewPermit := outputPermit, Critical := plantNow.critical OR NOT xSafetyOK OR robot.Sts.recoveryRequired,
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
GVL_IO.dout.ctrl_move_M6_actuator_forward := stationCoils.Applied[6].work;
GVL_IO.dout.ctrl_move_M6_actuator_backward := stationCoils.Applied[6].home;
GVL_IO.dout.ctrl_move_M7_actuator_forward := stationCoils.Applied[7].work;
GVL_IO.dout.ctrl_move_M7_actuator_backward := stationCoils.Applied[7].home;

fbStorage.Cmd.Enable := xGlobalEnable;
fbStorage.Cmd.ResetFault := xResetAll;
fbStorage.Cmd.RobotAccessReq := GVL_Robot.Rx.area_storage_accessReq AND robot.Sts.session;
fbStorage.Cmd.RobotAccessPermit := outputPermit;
fbStorage.Cmd.RobotReserved := robot.Sts.areas[3].reserved;
fbStorage.Inp := GVL_Robot.storageIn;
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
PRG_IO_Write();
IF robot.Sts.session AND GVL_RobotRetain.Context.occupancyKnown THEN
    GVL_RobotRetain.Context.occupied[1] := fbTopFlow.Sts.OccP1;
    GVL_RobotRetain.Context.occupied[2] := fbTopFlow.Sts.OccP2;
    GVL_RobotRetain.Context.occupied[3] := fbTopFlow.Sts.OccP3;
    GVL_RobotRetain.Context.occupied[4] := xElevatorLoadPresent;
    GVL_RobotRetain.Context.occupied[5] := fbBottom567.Sts.Occ5;
    GVL_RobotRetain.Context.occupied[6] := fbBottom567.Sts.Occ6;
    GVL_RobotRetain.Context.occupied[7] := fbBottom567.Sts.Occ7;
    GVL_RobotRetain.Context.elevatorLoadPresent := xElevatorLoadPresent;
    GVL_RobotRetain.Context.topTransferState := fbTopFlow.Sts.State;
    GVL_RobotRetain.Context.bottomTransferState := fbBottom567.Sts.State;
    GVL_RobotRetain.Context.bottomTransferOwner := 0;
    IF xBottomTransferOwnerTray THEN GVL_RobotRetain.Context.bottomTransferOwner := 2; END_IF;
    IF xBottomTransferOwnerBox THEN GVL_RobotRetain.Context.bottomTransferOwner := 1; END_IF;
    GVL_RobotRetain.Context.bottomDonePendingTray := xBottomDonePendingTray;
    GVL_RobotRetain.Context.bottomDonePendingBox := xBottomDonePendingBox;
END_IF;
// 15) ALARM MANAGER — zbieranie faultów
// ================================================================

GVL_HMI.hmiAlarms.xM1_Fault         := fbPosM1.Diag.Fault;
GVL_HMI.hmiAlarms.xM2_Fault         := fbStopM2.Diag.Fault;
GVL_HMI.hmiAlarms.xM3_Fault         := fbStopM3.Diag.Fault;
GVL_HMI.hmiAlarms.xM4_Fault         := fbStopM4.Diag.Fault;
GVL_HMI.hmiAlarms.xM5_Fault         := fbPosM5.Diag.Fault;
GVL_HMI.hmiAlarms.xM6_Fault         := fbPosM6.Diag.Fault;
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
GVL_HMI.hmiStatus.xOccP4 := GVL_IO.di.ind_container_in_pos_4;
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
GVL_HMI.hmiStatus.xM6_Up       := fbPosM6.Sts.IsUp;
GVL_HMI.hmiStatus.xM7_Extended := fbPosM7.Sts.IsUp;
GVL_HMI.hmiStatus.xM8_Extended := fbStorage.Sts.RobotSideOpen;
GVL_HMI.hmiStatus.xM1_Retracted := fbPosM1.Sts.IsDown;
GVL_HMI.hmiStatus.xM2_Down      := fbStopM2.Sts.IsDown;
GVL_HMI.hmiStatus.xM3_Down      := fbStopM3.Sts.IsDown;
GVL_HMI.hmiStatus.xM4_Down      := fbStopM4.Sts.IsDown;
GVL_HMI.hmiStatus.xM5_Down      := fbPosM5.Sts.IsDown;
GVL_HMI.hmiStatus.xM6_Down      := fbPosM6.Sts.IsDown;
GVL_HMI.hmiStatus.xM7_Retracted := fbPosM7.Sts.IsDown;
GVL_HMI.hmiStatus.xM8_Retracted := fbStorage.Sts.RobotSideClosed;
GVL_HMI.hmiStatus.xM1_Busy      := fbPosM1.Sts.Busy;
GVL_HMI.hmiStatus.xM2_Busy      := fbStopM2.Sts.Busy;
GVL_HMI.hmiStatus.xM3_Busy      := fbStopM3.Sts.Busy;
GVL_HMI.hmiStatus.xM4_Busy      := fbStopM4.Sts.Busy;
GVL_HMI.hmiStatus.xM5_Busy      := fbPosM5.Sts.Busy;
GVL_HMI.hmiStatus.xM6_Busy      := fbPosM6.Sts.Busy;
GVL_HMI.hmiStatus.xM7_Busy      := fbPosM7.Sts.Busy;
GVL_HMI.hmiStatus.xM8_Busy      := fbStorage.Sts.Busy;
GVL_HMI.hmiStatus.xM1_Fault     := fbPosM1.Diag.Fault;
GVL_HMI.hmiStatus.xM2_Fault     := fbStopM2.Diag.Fault;
GVL_HMI.hmiStatus.xM3_Fault     := fbStopM3.Diag.Fault;
GVL_HMI.hmiStatus.xM4_Fault     := fbStopM4.Diag.Fault;
GVL_HMI.hmiStatus.xM5_Fault     := fbPosM5.Diag.Fault;
GVL_HMI.hmiStatus.xM6_Fault     := fbPosM6.Diag.Fault;
GVL_HMI.hmiStatus.xM7_Fault     := fbPosM7.Diag.Fault;
GVL_HMI.hmiStatus.xM8_Fault     := fbStorage.Diag.Fault;
GVL_HMI.hmiStatus.sM1DiagText   := fbPosM1.Diag.Text;
GVL_HMI.hmiStatus.sM2DiagText   := fbStopM2.Diag.Text;
GVL_HMI.hmiStatus.sM3DiagText   := fbStopM3.Diag.Text;
GVL_HMI.hmiStatus.sM4DiagText   := fbStopM4.Diag.Text;
GVL_HMI.hmiStatus.sM5DiagText   := fbPosM5.Diag.Text;
GVL_HMI.hmiStatus.sM6DiagText   := fbPosM6.Diag.Text;
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
