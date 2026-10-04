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
    fbStorage      : FB_Storage;       // magazyn przekładek / M8

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
    xModeTray      : BOOL;   // TRUE = tacki, FALSE = kuwety (z HMI / przełącznik)
    xModeBox       : BOOL;

    (* --- Opróżnianie stacji --- *)
    xEmptyButtonPhysical       : BOOL;
    rtEmptyButtonPhysical      : R_TRIG;
    rtEmptyStationHmi          : R_TRIG;
    xStartFullEmpty            : BOOL;
    xCycleStartedAtScanStart   : BOOL;
    xProductionCycleStarted    : BOOL;
    xEmptyBottomAvailable      : BOOL;
    xEmptyBottomRearmRequired  : BOOL;
    xEmptyBottomControlClaim   : BOOL;
    xEmptyReclassArmed         : BOOL;
    xEmptyBottomHealthy        : BOOL;
    xEmptyBottomActuallyActive : BOOL;
    xEmptyRunning              : BOOL;       // flaga: trwa pełne opróżnianie
    xElevatorLoadPresent       : BOOL;       // zatrzaśnięta informacja o ładunku na windzie
    uiTrayCountPrev            : UINT;
    xStationNotEmpty           : BOOL;
    uiEmptyState               : UINT;       // 0=idle, 10=top_flush, 20=elev_down, 30=discharge, 40=elev_up, 50=done, 60=bottom_flush, 70=wait_reclassify

    (* --- Własność i odzyskanie transferu P4->P5 --- *)
    xBottomAutoStepInProgress  : BOOL;
    xBottomNotQuiescent        : BOOL;
    xBottomStepTakeoverActive  : BOOL;
    xBottomRecoveryRequired    : BOOL;
    xBottomAutoStepControlClaim : BOOL;
    xBottomTransferOwnerTray   : BOOL;
    xBottomTransferOwnerBox    : BOOL;
    xBottomDonePendingTray     : BOOL;
    xBottomDonePendingBox      : BOOL;
    xBottomReqFromTray         : BOOL;
    xBottomReqFromBox          : BOOL;
    eTrayStateBeforeCall       : E_TraySeqState;
    eBoxStateBeforeCall        : E_BoxSeqState;
    eBottomStateBeforeCall     : E_Bottom567State;

    (* --- Miganie LED przycisku opróżniania --- *)
    tEmptyFastBlinkOn  : TON;
    tEmptyFastBlinkOff : TON;
    tEmptySlowBlinkOn  : TON;
    tEmptySlowBlinkOff : TON;
    xEmptyFastBlinkReq : BOOL;
    xEmptySlowBlinkReq : BOOL;
    xEmptyFastBlink    : BOOL := TRUE;
    xEmptySlowBlink    : BOOL := TRUE;

    (* --- Kontynuuj --- *)
    rtContinue        : R_TRIG;
    xContinueReq      : BOOL;

    (* --- Podawanie próbek --- *)
    rtSamplesButton   : R_TRIG;
    tSamplesBlinkOn   : TON;
    tSamplesBlinkOff  : TON;
    xSamplesAvailable : BOOL;
    xSamplesRequest   : BOOL;
    xSamplesBlink     : BOOL;

    (* --- Załadunek P1 / M1 --- *)
    rtContainerReady      : R_TRIG;
    xLoadAcceptedPending  : BOOL;
    xLoadAcceptPulseSent  : BOOL;
    xM1RetractForTopFlow  : BOOL;

    (* --- HMI Manual Override --- *)
    xHmiManualMode       : BOOL;   // TRUE = tryb ręczny z HMI
    xHmiElevManUp        : BOOL;
    xHmiElevManDown      : BOOL;
    xHmiElevManFast      : BOOL;
    xHmiConvTopFwd       : BOOL;
    xHmiConvElevFwd      : BOOL;
    xHmiConvElevBwd      : BOOL;
    xHmiConvBottomFwd    : BOOL;
    xHmiConvBottomBwd    : BOOL;
    xHmiM1Fwd            : BOOL;
    xHmiM1Bwd            : BOOL;
    xHmiM2Fwd            : BOOL;
    xHmiM2Bwd            : BOOL;
    xHmiM3Fwd            : BOOL;
    xHmiM3Bwd            : BOOL;
    xHmiM4Fwd            : BOOL;
    xHmiM4Bwd            : BOOL;
    xHmiM5Fwd            : BOOL;
    xHmiM5Bwd            : BOOL;
    xHmiM6Fwd            : BOOL;
    xHmiM6Bwd            : BOOL;
    xHmiM7Fwd            : BOOL;
    xHmiM7Bwd            : BOOL;
    xHmiM8Fwd            : BOOL;
    xHmiM8Bwd            : BOOL;
    xStorageManRobotOpen : BOOL;

    (* --- Timery opróżniania --- *)
    tEmptyTO         : TON;
    tEmptyTransfer   : TON;
    tElevTransferDone : TON;
    xElevTransferDone : BOOL;

    (* --- Pomocnicze --- *)
    xSafetyOK      : BOOL;          // TRUE gdy Euchner OD potwierdza rygiel drzwi celi
    xGlobalEnable  : BOOL;
    xResetAll      : BOOL;          // globalny reset błędów (tylko HMI Reset)
    xAutoActive    : BOOL;          // TRUE gdy którykolwiek sekwencer jest aktywny
END_VAR

// ================================================================
// 0) Kopiowanie RAW I/O -> abstrakcja
// ================================================================
PRG_IO_Read();

// ================================================================
// 0a) DRZWI CELI ROBOTA - klamka bezpieczenstwa Euchner
// ================================================================

xResetAll := GVL_HMI.hmiCmd.xResetFaults;

fbSafetyDoor.Enable := TRUE;
fbSafetyDoor.ResetFault := xResetAll;
fbSafetyDoor.Inp.BtnOpenClose := GVL_IO.di.ind_button_open_close_robot_cell_doors;
fbSafetyDoor.Inp.DoorLocked := GVL_IO.di.ind_robot_cell_doors_locked;
fbSafetyDoor.Inp.DeviceError := NOT GVL_IO.di.ind_robot_cell_doors_error;
fbSafetyDoor();

GVL_IO.dout.ctrl_open_robot_cell_doors_lock := fbSafetyDoor.Outp.Q_Unlock;
GVL_IO.dout.ctrl_robot_cell_doors_LED_open_close := fbSafetyDoor.Outp.Q_LEDOpenClose;
GVL_IO.dout.ctrl_reset_robot_cell_doors := fbSafetyDoor.Outp.Q_DeviceReset;

xSafetyOK := 	TRUE; //fbSafetyDoor.Sts.ReadyToRun;

xGlobalEnable := xSafetyOK AND (NOT GVL_IO.di.ind_low_pressure);

// ================================================================
// 1) HMI KOMENDY -> zmienne lokalne  (odczyt na początku skanu!)
// ================================================================

xModeTray       := GVL_HMI.hmiCmd.xSelectModeTray AND (NOT GVL_HMI.hmiCmd.xSelectModeBox);
xModeBox        := GVL_HMI.hmiCmd.xSelectModeBox AND (NOT GVL_HMI.hmiCmd.xSelectModeTray);
xHmiManualMode  := GVL_HMI.hmiCmd.xManualMode;
xHmiElevManUp   := GVL_HMI.hmiCmd.xElevUp;
xHmiElevManDown := GVL_HMI.hmiCmd.xElevDown;
xHmiElevManFast := GVL_HMI.hmiCmd.xElevFast;
xHmiConvTopFwd  := GVL_HMI.hmiCmd.xConvTopFwd;
xHmiConvElevFwd := GVL_HMI.hmiCmd.xConvElevFwd;
xHmiConvElevBwd := GVL_HMI.hmiCmd.xConvElevBwd;
xHmiConvBottomFwd := GVL_HMI.hmiCmd.xConvBottomFwd;
xHmiConvBottomBwd := GVL_HMI.hmiCmd.xConvBottomBwd;
xHmiM1Fwd       := GVL_HMI.hmiCmd.xM1Fwd;
xHmiM1Bwd       := GVL_HMI.hmiCmd.xM1Bwd;
xHmiM2Fwd       := GVL_HMI.hmiCmd.xM2Fwd;
xHmiM2Bwd       := GVL_HMI.hmiCmd.xM2Bwd;
xHmiM3Fwd       := GVL_HMI.hmiCmd.xM3Fwd;
xHmiM3Bwd       := GVL_HMI.hmiCmd.xM3Bwd;
xHmiM4Fwd       := GVL_HMI.hmiCmd.xM4Fwd;
xHmiM4Bwd       := GVL_HMI.hmiCmd.xM4Bwd;
xHmiM5Fwd       := GVL_HMI.hmiCmd.xM5Fwd;
xHmiM5Bwd       := GVL_HMI.hmiCmd.xM5Bwd;
xHmiM6Fwd       := GVL_HMI.hmiCmd.xM6Fwd;
xHmiM6Bwd       := GVL_HMI.hmiCmd.xM6Bwd;
xHmiM7Fwd       := GVL_HMI.hmiCmd.xM7Fwd;
xHmiM7Bwd       := GVL_HMI.hmiCmd.xM7Bwd;
xHmiM8Fwd       := GVL_HMI.hmiCmd.xM8Fwd;
xHmiM8Bwd       := GVL_HMI.hmiCmd.xM8Bwd;

// ================================================================
// 2) HMI MANUAL OVERRIDE — ręczne sterowanie z panelu HMI
//     (musi być przed finalnym blokiem wywołań FB)
// ================================================================

IF xHmiManualMode AND (NOT xEmptyRunning) THEN
    // Winda w trybie manualnym
    elevCmd.eMode := E_ElevatorMode.MANUAL;
    elevCmd.xManUp := xHmiElevManUp;
    elevCmd.xManDown := xHmiElevManDown;
    elevCmd.xManFast := xHmiElevManFast;

    // Transportery
    fbConvTop.Cmd.RunFwd := xHmiConvTopFwd;
    fbConvElev.Cmd.RunFwd := xHmiConvElevFwd;
    fbConvElev.Cmd.RunBwd := xHmiConvElevBwd;
    fbConvBottom.Cmd.RunFwd := xHmiConvBottomFwd;
    fbConvBottom.Cmd.RunBwd := xHmiConvBottomBwd;

    // Siłowniki — bistabilne komendy przód/tył z HMI
    IF xHmiM1Fwd AND NOT xHmiM1Bwd THEN
        fbPosM1.HoldUp := TRUE;
    ELSIF NOT xHmiM1Fwd AND xHmiM1Bwd THEN
        fbPosM1.HoldUp := FALSE;
    END_IF;
    IF xHmiM2Fwd AND NOT xHmiM2Bwd THEN
        fbStopM2.HoldUp := TRUE;
    ELSIF NOT xHmiM2Fwd AND xHmiM2Bwd THEN
        fbStopM2.HoldUp := FALSE;
    END_IF;
    IF xHmiM3Fwd AND NOT xHmiM3Bwd THEN
        fbStopM3.HoldUp := TRUE;
    ELSIF NOT xHmiM3Fwd AND xHmiM3Bwd THEN
        fbStopM3.HoldUp := FALSE;
    END_IF;
    IF xHmiM4Fwd AND NOT xHmiM4Bwd THEN
        fbStopM4.HoldUp := TRUE;
    ELSIF NOT xHmiM4Fwd AND xHmiM4Bwd THEN
        fbStopM4.HoldUp := FALSE;
    END_IF;
    IF xHmiM5Fwd AND NOT xHmiM5Bwd THEN
        fbPosM5.HoldUp := TRUE;
    ELSIF NOT xHmiM5Fwd AND xHmiM5Bwd THEN
        fbPosM5.HoldUp := FALSE;
    END_IF;
    IF xHmiM6Fwd AND NOT xHmiM6Bwd THEN
        fbPosM6.HoldUp := TRUE;
    ELSIF NOT xHmiM6Fwd AND xHmiM6Bwd THEN
        fbPosM6.HoldUp := FALSE;
    END_IF;
    IF xHmiM7Fwd AND NOT xHmiM7Bwd THEN
        fbPosM7.HoldUp := TRUE;
    ELSIF NOT xHmiM7Fwd AND xHmiM7Bwd THEN
        fbPosM7.HoldUp := FALSE;
    END_IF;
    IF xHmiM8Fwd AND NOT xHmiM8Bwd THEN
        xStorageManRobotOpen := TRUE;
    ELSIF NOT xHmiM8Fwd AND xHmiM8Bwd THEN
        xStorageManRobotOpen := FALSE;
    END_IF;
ELSE
    xStorageManRobotOpen := FALSE;
END_IF;

// xAutoActive obliczane po wywołaniu sekwencerów.

// Stan cyklu z początku skanu służy wyłącznie do klasyfikacji zbocza fizycznego.
xCycleStartedAtScanStart :=
    (xModeTray AND (fbTraySeq.Sts.State <> E_TraySeqState.DISABLED)) OR
    (xModeBox AND (fbBoxSeq.Sts.State <> E_BoxSeqState.DISABLED));

// --- Zbocza przycisków ---
xEmptyButtonPhysical := GVL_IO.di.ind_button_start_emptying_process;
rtEmptyButtonPhysical(CLK := xEmptyButtonPhysical);
rtEmptyStationHmi(CLK := GVL_HMI.hmiCmd.xEmptyStation);
xStartFullEmpty := rtEmptyStationHmi.Q OR
                   (rtEmptyButtonPhysical.Q AND (NOT xCycleStartedAtScanStart));
rtContinue(CLK := GVL_IO.di.ind_button_continue_process OR GVL_HMI.hmiCmd.xContiniue);
rtContainerReady(CLK := GVL_IO.di.ind_button_container_ready);
fbTopFlow.Cmd.Pos1AcceptedPulse := FALSE;

// Po utracie zezwolenia lub błędzie wymagane jest puszczenie przycisku.
IF NOT xEmptyButtonPhysical THEN
    xEmptyBottomRearmRequired := FALSE;
ELSIF (NOT xGlobalEnable) OR fbBottom567.Diag.Fault OR fbConvBottom.Diag.Fault THEN
    xEmptyBottomRearmRequired := TRUE;
END_IF;

xBottomAutoStepInProgress :=
    (fbBottom567.Sts.State = E_Bottom567State.PRECHECK) OR
    (fbBottom567.Sts.State = E_Bottom567State.RUN_STEP) OR
    (fbBottom567.Sts.State = E_Bottom567State.WAIT_STOP) OR
    (fbBottom567.Sts.State = E_Bottom567State.COMPLETE);
xBottomNotQuiescent :=
    fbBottom567.Sts.State <> E_Bottom567State.IDLE;

// Impuls Bottom powstaje po wywołaniu sekwencerów, dlatego trafia do nich przez pending.
IF fbBottom567.Outp.DischargeDonePulse THEN
    IF xBottomTransferOwnerTray THEN
        xBottomDonePendingTray := TRUE;
    ELSIF xBottomTransferOwnerBox THEN
        xBottomDonePendingBox := TRUE;
    END_IF;
END_IF;

// STOP lub zmiana trybu osieroca zaakceptowany krok. Nowy cykl czeka na jego odzyskanie.
IF GVL_HMI.hmiCmd.xStopAuto OR
   ((fbTraySeq.Sts.State <> E_TraySeqState.DISABLED) AND (NOT xModeTray)) OR
   ((fbBoxSeq.Sts.State <> E_BoxSeqState.DISABLED) AND (NOT xModeBox)) OR
   (xBottomTransferOwnerTray AND (NOT xModeTray)) OR
   (xBottomTransferOwnerBox AND (NOT xModeBox)) THEN
    IF xBottomNotQuiescent THEN
        xBottomRecoveryRequired := TRUE;
    END_IF;
    xBottomStepTakeoverActive := FALSE;
    xBottomTransferOwnerTray := FALSE;
    xBottomTransferOwnerBox := FALSE;
    xBottomDonePendingTray := FALSE;
    xBottomDonePendingBox := FALSE;
END_IF;

IF fbBottom567.Sts.State = E_Bottom567State.IDLE THEN
    IF NOT xEmptyRunning THEN
        xBottomRecoveryRequired := FALSE;
    END_IF;
    xBottomStepTakeoverActive := FALSE;
END_IF;

// "Kontynuuj" pozostaje aktywne do potwierdzenia odbioru przez robota.
IF GVL_Robot.robotIn.ack_cmd_continue THEN
    xContinueReq := FALSE;
ELSIF rtContinue.Q THEN
    xContinueReq := TRUE;
END_IF;
// Reset faultow tylko z HMI Reset, nie z Kontynuuj.

// Potwierdzenie transferu na winde: P4 musi byc zasloniete stabilnie przez 2 s.
tElevTransferDone(IN := GVL_IO.di.ind_container_in_pos_4, PT := T#2s);
xElevTransferDone := tElevTransferDone.Q;

// Ciągły model ładunku windy. Licznik tacek jest używany tylko przez wykrycie wzrostu.
IF fbBottom567.Outp.DischargeDonePulse THEN
    xElevatorLoadPresent := FALSE;
ELSIF GVL_IO.di.ind_container_in_pos_4 OR
      (xModeTray AND (fbTraySeq.Sts.TrayCount > uiTrayCountPrev)) THEN
    xElevatorLoadPresent := TRUE;
END_IF;
uiTrayCountPrev := fbTraySeq.Sts.TrayCount;

// Obsługa przycisku "Opróżnij stację"
IF xStartFullEmpty AND (NOT xEmptyRunning) THEN
    xEmptyRunning := TRUE;
    uiEmptyState := 70;
    xEmptyReclassArmed := FALSE;

    IF xBottomNotQuiescent THEN
        xBottomRecoveryRequired := TRUE;
    END_IF;
    xBottomStepTakeoverActive := FALSE;
    xBottomTransferOwnerTray := FALSE;
    xBottomTransferOwnerBox := FALSE;
    xBottomDonePendingTray := FALSE;
    xBottomDonePendingBox := FALSE;

    // Zatrzymaj aktywne sekwencery
    fbTraySeq.Cmd.AbortAuto := TRUE;
    fbBoxSeq.Cmd.AbortAuto := TRUE;
END_IF;

IF xHmiManualMode OR xEmptyRunning OR xResetAll OR (NOT GVL_IO.di.ind_container_in_pos_1) THEN
    xLoadAcceptedPending := FALSE;
ELSIF rtContainerReady.Q THEN
    xLoadAcceptedPending := TRUE;
END_IF;

// ================================================================
// 3) STOPERY — konfiguracja i mapowanie I/O
// ================================================================

// --- M2: stoper pozycja 1 ---
fbStopM2.Enable := xGlobalEnable;
fbStopM2.ResetFault := xResetAll;
fbStopM2.Inp.ind_1_fwd := GVL_IO.di.ind_M2_1_fwd;
fbStopM2.Inp.ind_2_fwd := GVL_IO.di.ind_M2_2_fwd;
fbStopM2.Inp.ind_1_bwd := GVL_IO.di.ind_M2_1_bwd;
fbStopM2.Inp.ind_2_bwd := GVL_IO.di.ind_M2_2_bwd;
// HoldUp ustawiany przez TopFlowManager (poniżej)

// --- M3: stoper pozycja 2 ---
fbStopM3.Enable := xGlobalEnable;
fbStopM3.ResetFault := xResetAll;
fbStopM3.Inp.ind_1_fwd := GVL_IO.di.ind_M3_1_fwd;
fbStopM3.Inp.ind_2_fwd := GVL_IO.di.ind_M3_2_fwd;
fbStopM3.Inp.ind_1_bwd := GVL_IO.di.ind_M3_1_bwd;
fbStopM3.Inp.ind_2_bwd := GVL_IO.di.ind_M3_2_bwd;

// --- M4: stoper pozycja 3 ---
fbStopM4.Enable := xGlobalEnable;
fbStopM4.ResetFault := xResetAll;
fbStopM4.Inp.ind_1_fwd := GVL_IO.di.ind_M4_1_fwd;
fbStopM4.Inp.ind_2_fwd := GVL_IO.di.ind_M4_2_fwd;
fbStopM4.Inp.ind_1_bwd := GVL_IO.di.ind_M4_1_bwd;
fbStopM4.Inp.ind_2_bwd := GVL_IO.di.ind_M4_2_bwd;


// ================================================================
// 4) POZYCJONERY — konfiguracja i mapowanie I/O
// ================================================================

// --- M1: pozycjoner załadunku ---
fbPosM1.Enable := xGlobalEnable;
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
fbPosM5.Enable := xGlobalEnable;
fbPosM5.ResetFault := xResetAll;
fbPosM5.Inp.ind_1_fwd := GVL_IO.di.ind_M5_1_fwd;
fbPosM5.Inp.ind_2_fwd := GVL_IO.di.ind_M5_2_fwd;
fbPosM5.Inp.ind_1_bwd := GVL_IO.di.ind_M5_1_bwd;
fbPosM5.Inp.ind_2_bwd := GVL_IO.di.ind_M5_2_bwd;
// HoldUp zarządzane przez TopFlowManager (bramka tacek P3 w trybie tray)

// --- M6: pozycjoner tacek winda (para) ---
fbPosM6.Enable := xGlobalEnable;
fbPosM6.ResetFault := xResetAll;
fbPosM6.Inp.ind_1_fwd := GVL_IO.di.ind_M6_1_fwd;
fbPosM6.Inp.ind_2_fwd := GVL_IO.di.ind_M6_2_fwd;
fbPosM6.Inp.ind_1_bwd := GVL_IO.di.ind_M6_1_bwd;
fbPosM6.Inp.ind_2_bwd := GVL_IO.di.ind_M6_2_bwd;

// --- M7: pozycjoner kuwet winda ---
fbPosM7.Enable := xGlobalEnable;
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
elevIn.xCommOk := TRUE; // Control_ATV/Axis_Ref obsługuje komunikację z ATV320
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
IF GVL_HMI.hmiCmd.rElevSpeedFast_Hz > 0.0 THEN
    elevCmd.rSpeedFast_Hz := GVL_HMI.hmiCmd.rElevSpeedFast_Hz;
ELSE
    elevCmd.rSpeedFast_Hz := 15.0;
END_IF;

IF GVL_HMI.hmiCmd.rElevSpeedSlow_Hz > 0.0 THEN
    elevCmd.rSpeedSlow_Hz := GVL_HMI.hmiCmd.rElevSpeedSlow_Hz;
ELSE
    elevCmd.rSpeedSlow_Hz := 5.0;
END_IF;
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
// 9) TRAY SEQUENCER — orkiestracja trybu AUTO tacek
// ================================================================

fbTopFlow.Cmd.EnableAuto := FALSE;
fbTopFlow.Inp.Elev_RequestFeed := FALSE;
fbTopFlow.Inp.Elev_CanAccept := FALSE;
fbTopFlow.Inp.StackConsumedAtP3 := FALSE;

fbBottom567.Cmd.EnableAuto := FALSE;
fbBottom567.Cmd.DischargeReq := FALSE;
fbBottom567.Cmd.EmptyBottomHold := FALSE;

IF NOT xHmiManualMode THEN
    fbConvTop.Cmd.RunFwd := FALSE;
    fbConvTop.Cmd.RunBwd := FALSE;
    fbConvElev.Cmd.RunFwd := FALSE;
    fbConvElev.Cmd.RunBwd := FALSE;
    fbConvBottom.Cmd.RunFwd := FALSE;
    fbConvBottom.Cmd.RunBwd := FALSE;
END_IF;

IF xModeTray AND (NOT xHmiManualMode) AND (NOT xEmptyRunning) AND
   (NOT xBottomRecoveryRequired) THEN
    fbTraySeq.Cmd.StartAuto := GVL_IO.di.ind_button_start_process OR GVL_HMI.hmiCmd.xStartAuto;
ELSE
    fbTraySeq.Cmd.StartAuto := FALSE;
END_IF;
fbTraySeq.Cmd.ResumeAuto := xModeTray AND (NOT xHmiManualMode) AND
                            (NOT xEmptyRunning) AND
                            (NOT xBottomRecoveryRequired) AND rtContinue.Q;
fbTraySeq.Cmd.SafetyOK := xGlobalEnable;
fbTraySeq.Cmd.ResetFault := xResetAll;
fbTraySeq.Cmd.PauseAuto := xHmiManualMode OR GVL_HMI.hmiCmd.xPauseAuto;
fbTraySeq.Cmd.AbortAuto := xEmptyRunning OR GVL_HMI.hmiCmd.xStopAuto OR (NOT xModeTray);
IF GVL_HMI.hmiCmd.uiTraysInStack > 0 THEN
    fbTraySeq.Cfg.uiTraysInStack := GVL_HMI.hmiCmd.uiTraysInStack;
ELSE
    fbTraySeq.Cfg.uiTraysInStack := 8;
END_IF;

// Wejścia z sub-FB
fbTraySeq.Inp.TopFlow_OccP3         := fbTopFlow.Sts.OccP3;
fbTraySeq.Inp.TopFlow_StackReadyAtP3 := fbTopFlow.Sts.StackReadyAtP3;
fbTraySeq.Inp.TopFlow_Busy          := fbTopFlow.Sts.Busy;
fbTraySeq.Inp.TopFlow_Fault         := fbTopFlow.Diag.Fault;

fbTraySeq.Inp.Elev_AtTop    := elevStat.ePos = E_ElevatorPos.posTop;
fbTraySeq.Inp.Elev_AtBottom := elevStat.ePos = E_ElevatorPos.posBottom;
fbTraySeq.Inp.Elev_AtTarget := elevStat.xAtTarget;
fbTraySeq.Inp.Elev_Busy     := elevStat.xBusy;
fbTraySeq.Inp.Elev_CommandReady := elevStat.eState = E_ElevatorState.IDLE;
fbTraySeq.Inp.Elev_Fault    := elevStat.xFault;

fbTraySeq.Inp.Bottom_CanAccept := fbBottom567.Sts.CanAcceptFromElev;
fbTraySeq.Inp.Bottom_Busy      := fbBottom567.Sts.Busy;
fbTraySeq.Inp.Bottom_Fault     := fbBottom567.Diag.Fault;
fbTraySeq.Inp.Bottom_DischargeDonePulse := xBottomDonePendingTray;

fbTraySeq.Inp.ind_container_in_pos_4 := GVL_IO.di.ind_container_in_pos_4;

// Pozycjoner M6 feedback (M4, M5 są teraz obsługiwane przez TopFlowManager)
fbTraySeq.Inp.M6_IsUp   := fbPosM6.Sts.IsUp;
fbTraySeq.Inp.M6_IsDown := fbPosM6.Sts.IsDown;

// Robot feedback (z IOScanner)
fbTraySeq.Inp.Robot_SystemReady    := GVL_Robot.robotIn.sts_system_ready;
fbTraySeq.Inp.Robot_PrgRunning     := GVL_Robot.robotIn.sts_prg_running;
fbTraySeq.Inp.Robot_InHome         := GVL_Robot.robotIn.sts_in_home_pos;
fbTraySeq.Inp.Robot_AutoMode       := GVL_Robot.robotIn.sts_auto_mode;
fbTraySeq.Inp.Robot_Fault          := GVL_Robot.robotIn.sts_fault;
fbTraySeq.Inp.Robot_PalletFinished := GVL_Robot.robotIn.sts_pallet_finished;
fbTraySeq.Inp.Robot_StackFinished  := GVL_Robot.robotIn.sts_stack_finished;
fbTraySeq.Inp.Robot_CmdAck         := GVL_Robot.robotIn.sts_cmd_ack;

// Wywołanie sekwencera
eTrayStateBeforeCall := fbTraySeq.Sts.State;
fbTraySeq();

IF xBottomDonePendingTray AND
   (eTrayStateBeforeCall = E_TraySeqState.DISCHARGE) AND
   (fbTraySeq.Sts.State = E_TraySeqState.WAIT_ELEV_EMPTY) THEN
    xBottomDonePendingTray := FALSE;
    xBottomTransferOwnerTray := FALSE;
END_IF;


// ================================================================
// 10) Mapowanie wyjść TraySequencer -> sub-FB
// ================================================================

IF NOT xHmiManualMode THEN
    // TopFlowManager: wejscia z sekwencera. Sam FB liczy wyjscia pod koniec skanu.
    fbTopFlow.Cmd.EnableAuto := fbTraySeq.Outp.TopFlow_Enable;
    fbTopFlow.Inp.Elev_RequestFeed  := fbTraySeq.Outp.TopFlow_Elev_RequestFeed;  // dla trybu kuwet
    fbTopFlow.Inp.Elev_CanAccept    := fbTraySeq.Outp.TopFlow_Elev_CanAccept;    // dla trybu kuwet
    fbTopFlow.Inp.StackConsumedAtP3 := fbTraySeq.Outp.TopFlow_StackConsumed;    // stos zużyty — zwolnij P3/M4

    // Rozladunkiem P4->P5 steruje BottomAccumulator.

    // Winda (komendy z TraySequencer)
    elevCmd.xAutoGo := fbTraySeq.Outp.Elev_AutoGo;
    elevCmd.xAutoStop := fbTraySeq.Outp.Elev_Stop;
    elevCmd.eAutoTarget := fbTraySeq.Outp.Elev_AutoTarget;
    elevCmd.xReset := xResetAll;

    // Pozycjonery M6 (komendy z TraySequencer)
    // M4 i M5 sa sterowane przez TopFlowManager.
    fbPosM6.HoldUp := fbTraySeq.Outp.M6_Extend;

    // BottomAccumulator
    fbBottom567.Cmd.EnableAuto := fbTraySeq.Outp.Bottom_Enable;
    fbBottom567.Cmd.DischargeReq := fbTraySeq.Outp.Bottom_DischargeReq;
END_IF;



// ================================================================
// 11) BOX SEQUENCER — orkiestracja trybu AUTO kuwet
// ================================================================

IF xModeBox AND (NOT xHmiManualMode) AND (NOT xEmptyRunning) AND
   (NOT xBottomRecoveryRequired) THEN
    fbBoxSeq.Cmd.StartAuto := GVL_IO.di.ind_button_start_process OR GVL_HMI.hmiCmd.xStartAuto;
ELSE
    fbBoxSeq.Cmd.StartAuto := FALSE;
END_IF;
fbBoxSeq.Cmd.ResumeAuto := xModeBox AND (NOT xHmiManualMode) AND
                           (NOT xEmptyRunning) AND
                           (NOT xBottomRecoveryRequired) AND rtContinue.Q;
fbBoxSeq.Cmd.SafetyOK := xGlobalEnable;
fbBoxSeq.Cmd.ResetFault := xResetAll;
// Analogicznie jak TraySeq: manual/HMI pauzuje, emptying/stop/zmiana trybu abortuje.
fbBoxSeq.Cmd.PauseAuto := xHmiManualMode OR GVL_HMI.hmiCmd.xPauseAuto;
fbBoxSeq.Cmd.AbortAuto := xEmptyRunning OR GVL_HMI.hmiCmd.xStopAuto OR (NOT xModeBox);

// Wejścia z sub-FB (analogiczne do TraySeq)
fbBoxSeq.Inp.TopFlow_Busy := fbTopFlow.Sts.Busy;
fbBoxSeq.Inp.TopFlow_Fault := fbTopFlow.Diag.Fault;
fbBoxSeq.Inp.TopFlow_ElevDeliveredAtP4 := fbTopFlow.Sts.ElevDeliveredAtP4;

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

fbBoxSeq.Inp.M7_AtExt := fbPosM7.Sts.IsUp;
fbBoxSeq.Inp.M7_AtRet := fbPosM7.Sts.IsDown;

fbBoxSeq.Inp.Robot_SystemReady := GVL_Robot.robotIn.sts_system_ready;
fbBoxSeq.Inp.Robot_PrgRunning := GVL_Robot.robotIn.sts_prg_running;
fbBoxSeq.Inp.Robot_AutoMode := GVL_Robot.robotIn.sts_auto_mode;
fbBoxSeq.Inp.Robot_Fault := GVL_Robot.robotIn.sts_fault;
fbBoxSeq.Inp.Robot_StackFinished := GVL_Robot.robotIn.sts_stack_finished;
fbBoxSeq.Inp.Robot_CmdAck := GVL_Robot.robotIn.sts_cmd_ack;
fbBoxSeq.Inp.Robot_BoxProgress := GVL_Robot.robotIn.box_progress;

eBoxStateBeforeCall := fbBoxSeq.Sts.State;
fbBoxSeq();

IF xBottomDonePendingBox AND
   (eBoxStateBeforeCall = E_BoxSeqState.DISCHARGE) AND
   (fbBoxSeq.Sts.State = E_BoxSeqState.WAIT_ELEV_EMPTY) THEN
    xBottomDonePendingBox := FALSE;
    xBottomTransferOwnerBox := FALSE;
END_IF;

// xAutoActive — oblicz PO wywołaniu obu sekwencerów (aktualne wartości tego skanu)
xAutoActive := (xModeTray AND fbTraySeq.Outp.AutoRunning) OR
               (xModeBox AND fbBoxSeq.Outp.AutoRunning);

// Rozpoczęty cykl obejmuje również PAUSED i FAULT wybranego sekwencera.
xProductionCycleStarted :=
    (xModeTray AND (fbTraySeq.Sts.State <> E_TraySeqState.DISABLED)) OR
    (xModeBox AND (fbBoxSeq.Sts.State <> E_BoxSeqState.DISABLED));

xEmptyBottomAvailable := xProductionCycleStarted AND xGlobalEnable AND
                         (NOT xEmptyRunning) AND
                         (NOT GVL_HMI.hmiCmd.xStopAuto) AND
                         (NOT fbBottom567.Diag.Fault) AND
                         (NOT fbConvBottom.Diag.Fault);

// Mapowanie wyjść BoxSeq (gdy aktywny)
IF xModeBox AND (NOT xHmiManualMode) AND fbBoxSeq.Outp.AutoRunning THEN
    fbTopFlow.Cmd.EnableAuto := fbBoxSeq.Outp.TopFlow_Enable;
    fbTopFlow.Inp.Elev_RequestFeed := fbBoxSeq.Outp.TopFlow_Elev_RequestFeed;
    fbTopFlow.Inp.Elev_CanAccept := fbBoxSeq.Outp.TopFlow_Elev_CanAccept;

    elevCmd.xAutoGo := fbBoxSeq.Outp.Elev_AutoGo;
    elevCmd.xAutoStop := fbBoxSeq.Outp.Elev_Stop;
    elevCmd.eAutoTarget := fbBoxSeq.Outp.Elev_AutoTarget;

    fbBottom567.Cmd.EnableAuto := fbBoxSeq.Outp.Bottom_Enable;
    fbBottom567.Cmd.DischargeReq := fbBoxSeq.Outp.Bottom_DischargeReq;

END_IF;

xBottomReqFromTray := xModeTray AND (NOT xEmptyRunning) AND
                      fbTraySeq.Outp.Bottom_DischargeReq;
xBottomReqFromBox := xModeBox AND (NOT xEmptyRunning) AND
                     fbBoxSeq.Outp.Bottom_DischargeReq;

// Fizyczny poziom steruje chwilowym opróżnianiem tylko podczas rozpoczętego cyklu.
fbBottom567.Cmd.EmptyBottomHold := xEmptyButtonPhysical AND
                                       xEmptyBottomAvailable AND
                                       (NOT xEmptyBottomRearmRequired);

// Przejęcie zaakceptowanego kroku pozostaje zatrzaśnięte do jego rozwiązania.
IF fbBottom567.Cmd.EmptyBottomHold AND xBottomAutoStepInProgress THEN
    xBottomStepTakeoverActive := TRUE;
END_IF;

// W trybie ręcznym chwilowe opróżnianie ma priorytet nad komendami z HMI.
xEmptyBottomControlClaim := fbBottom567.Cmd.EmptyBottomHold OR
                            fbBottom567.Sts.EmptyBottomActive OR
                            (fbBottom567.Sts.State = E_Bottom567State.EMPTY_HOLD) OR
                            (fbBottom567.Sts.State = E_Bottom567State.EMPTY_RESYNC);
xBottomAutoStepControlClaim := xBottomStepTakeoverActive OR
                               xBottomRecoveryRequired;
IF xHmiManualMode AND
   (xEmptyRunning OR xEmptyBottomControlClaim OR xBottomAutoStepControlClaim) THEN
    fbConvBottom.Cmd.RunFwd := FALSE;
    fbConvBottom.Cmd.RunBwd := FALSE;
END_IF;
IF xHmiManualMode AND (xEmptyRunning OR xBottomAutoStepControlClaim) THEN
    fbConvElev.Cmd.RunFwd := FALSE;
    fbConvElev.Cmd.RunBwd := FALSE;
END_IF;

// Pozycjoner M7 wraca do stanu bezpiecznego poza aktywnym trybem kuwet.
IF NOT xHmiManualMode THEN
    fbPosM7.HoldUp := xModeBox AND fbBoxSeq.Outp.AutoRunning AND fbBoxSeq.Outp.M7_Extend;
END_IF;


// ================================================================
// 12) OPRÓŻNIANIE STACJI — dostarczaj pojemniki do wyjścia, pomijaj paletyzację
// ================================================================

IF xEmptyRunning AND GVL_HMI.hmiCmd.xStopAuto THEN
    // STOP z HMI przerywa opróżnianie natychmiast, bez resetowania mapy zajętości.
    xEmptyRunning := FALSE;
    uiEmptyState := 0;
    xEmptyReclassArmed := FALSE;

    IF xBottomNotQuiescent THEN
        xBottomRecoveryRequired := TRUE;
    END_IF;
    xBottomStepTakeoverActive := FALSE;
    xBottomTransferOwnerTray := FALSE;
    xBottomTransferOwnerBox := FALSE;
    xBottomDonePendingTray := FALSE;
    xBottomDonePendingBox := FALSE;

    tEmptyTO(IN := FALSE);
    tEmptyTransfer(IN := FALSE);

    fbTopFlow.Cmd.EnableAuto := FALSE;
    fbTopFlow.Cmd.EmptyingMode := FALSE;
    fbTopFlow.Inp.Elev_RequestFeed := FALSE;
    fbTopFlow.Inp.Elev_CanAccept := FALSE;

    fbBottom567.Cmd.EnableAuto := FALSE;
    fbBottom567.Cmd.DischargeReq := FALSE;
    fbBottom567.Cmd.EmptyBottomHold := FALSE;

    fbConvTop.Cmd.RunFwd := FALSE;
    fbConvTop.Cmd.RunBwd := FALSE;
    fbConvElev.Cmd.RunFwd := FALSE;
    fbConvElev.Cmd.RunBwd := FALSE;
    fbConvBottom.Cmd.RunFwd := FALSE;
    fbConvBottom.Cmd.RunBwd := FALSE;

    elevCmd.xAutoGo := FALSE;
    elevCmd.xAutoStop := TRUE;
    elevCmd.xStop := TRUE;
    elevCmd.eAutoTarget := E_ElevatorTarget.NONE;

ELSIF xEmptyRunning THEN
    CASE uiEmptyState OF

        70: // WAIT_RECLASSIFY: domknij zaakceptowany krok i odśwież model przed wyborem
            fbBottom567.Cmd.DischargeReq := FALSE;
            tEmptyTO(IN := FALSE);
            tEmptyTransfer(IN := FALSE);

            IF (fbBottom567.Sts.State = E_Bottom567State.PRECHECK) OR
               (fbBottom567.Sts.State = E_Bottom567State.RUN_STEP) OR
               (fbBottom567.Sts.State = E_Bottom567State.WAIT_STOP) OR
               (fbBottom567.Sts.State = E_Bottom567State.COMPLETE) THEN
                fbBottom567.Cmd.EnableAuto := TRUE;
                xEmptyReclassArmed := TRUE;
            ELSIF (fbBottom567.Sts.State = E_Bottom567State.IDLE) OR
                  (fbBottom567.Sts.State = E_Bottom567State.FAULT) THEN
                IF xEmptyReclassArmed THEN
                    xEmptyReclassArmed := FALSE;

                    IF xElevatorLoadPresent THEN
                        uiEmptyState := 20;
                    ELSIF fbTopFlow.Sts.OccP1 OR fbTopFlow.Sts.OccP2 OR fbTopFlow.Sts.OccP3 THEN
                        uiEmptyState := 10;
                    ELSIF fbBottom567.Sts.Occ5 OR fbBottom567.Sts.Occ6 OR fbBottom567.Sts.Occ7 THEN
                        uiEmptyState := 60;
                    ELSE
                        uiEmptyState := 50;
                    END_IF;
                ELSE
                    // Co najmniej jedno wywołanie Bottom musi odświeżyć status po starcie.
                    xEmptyReclassArmed := TRUE;
                END_IF;
            ELSE
                // INIT, EMPTY_HOLD i EMPTY_RESYNC muszą najpierw dojść do stanu ustalonego.
                xEmptyReclassArmed := TRUE;
            END_IF;

        10: // TOP_FLUSH: dopóki jest pojemnik na P1/P2/P3, przesuń go na windę i dalej
            // Żądaj podawania na windę przez TopFlowManager
            fbTopFlow.Cmd.EnableAuto := TRUE;
            fbTopFlow.Cmd.EmptyingMode := TRUE;
            fbTopFlow.Inp.Elev_RequestFeed := TRUE;
            fbTopFlow.Inp.Elev_CanAccept := elevStat.ePos = E_ElevatorPos.posTop
                                            AND (NOT xElevatorLoadPresent)
                                            AND (NOT GVL_IO.di.ind_container_in_pos_4);

            // Jeśli pojemnik dotarł na windę -> jedź na dół
            IF GVL_IO.di.ind_container_in_pos_4 AND (NOT fbTopFlow.Sts.Busy) THEN
                xElevatorLoadPresent := TRUE;
                uiEmptyState := 20;
                tEmptyTO(IN := FALSE);
            END_IF;

            // Jeśli nic już nie ma na górze -> sprawdź windę
            IF (NOT fbTopFlow.Sts.OccP1) AND (NOT fbTopFlow.Sts.OccP2) AND (NOT fbTopFlow.Sts.OccP3) THEN
                IF xElevatorLoadPresent OR GVL_IO.di.ind_container_in_pos_4 THEN
                    xElevatorLoadPresent := TRUE;
                    uiEmptyState := 20; // jest na windzie
                ELSIF fbBottom567.Sts.Occ5 OR fbBottom567.Sts.Occ6 OR fbBottom567.Sts.Occ7 THEN
                    uiEmptyState := 60; // opróżnij dolny transporter
                ELSE
                    uiEmptyState := 50; // nic nigdzie — gotowe
                END_IF;
            END_IF;

        20: // ELEV_DOWN: winda na dół
            elevCmd.eMode := E_ElevatorMode.AUTO;
            elevCmd.xAutoGo := TRUE;
            elevCmd.eAutoTarget := E_ElevatorTarget.posBottom;

            IF elevStat.ePos = E_ElevatorPos.posBottom THEN
                elevCmd.xAutoGo := FALSE;
                uiEmptyState := 30;
                tEmptyTO(IN := FALSE);
            END_IF;

        30: // DISCHARGE: rozladunek P4->P5 przez BottomAccumulator
            fbBottom567.Cmd.EnableAuto := TRUE;
            fbBottom567.Cmd.DischargeReq := TRUE;

            tEmptyTO(IN := TRUE, PT := T#15s);

            IF fbBottom567.Outp.DischargeDonePulse THEN
                fbBottom567.Cmd.DischargeReq := FALSE;
                xElevatorLoadPresent := FALSE;
                tEmptyTO(IN := FALSE);
                uiEmptyState := 40;
            ELSIF tEmptyTO.Q THEN
                fbBottom567.Cmd.DischargeReq := FALSE;
                uiEmptyState := 50; // timeout — zakończ
            END_IF;

        40: // ELEV_UP: winda na górę
            elevCmd.xAutoGo := TRUE;
            elevCmd.eAutoTarget := E_ElevatorTarget.posTop;

            IF elevStat.ePos = E_ElevatorPos.posTop THEN
                elevCmd.xAutoGo := FALSE;
                // Wróć do sprawdzenia czy jest jeszcze coś na górze
                IF fbTopFlow.Sts.OccP1 OR fbTopFlow.Sts.OccP2 OR fbTopFlow.Sts.OccP3 THEN
                    uiEmptyState := 10;
                ELSIF fbBottom567.Sts.Occ5 OR fbBottom567.Sts.Occ6 OR fbBottom567.Sts.Occ7 THEN
                    uiEmptyState := 60;
                ELSE
                    uiEmptyState := 50;
                END_IF;
            END_IF;

        60: // BOTTOM_FLUSH: oproznij pozycje P5-P7 do wyjscia
            // Pełna sekwencja czeka na zatrzymanie i resynchronizację po ruchu chwilowym.
            IF (fbBottom567.Sts.State = E_Bottom567State.EMPTY_HOLD) OR
               (fbBottom567.Sts.State = E_Bottom567State.EMPTY_RESYNC) THEN
                fbConvBottom.Cmd.RunFwd := FALSE;
                tEmptyTO(IN := FALSE);
                tEmptyTransfer(IN := FALSE);
            ELSE
                fbConvBottom.Cmd.RunFwd := TRUE;
                tEmptyTO(IN := TRUE, PT := T#30s);
                tEmptyTransfer(
                    IN := (NOT GVL_IO.di.ind_container_in_pos_5) AND
                          (NOT GVL_IO.di.ind_container_in_pos_6) AND
                          (NOT GVL_IO.di.ind_container_in_pos_7),
                    PT := T#5s
                );

                IF tEmptyTransfer.Q THEN
                    fbConvBottom.Cmd.RunFwd := FALSE;
                    tEmptyTO(IN := FALSE);
                    tEmptyTransfer(IN := FALSE);
                    uiEmptyState := 50;
                ELSIF tEmptyTO.Q THEN
                    fbConvBottom.Cmd.RunFwd := FALSE;
                    tEmptyTO(IN := FALSE);
                    tEmptyTransfer(IN := FALSE);
                    uiEmptyState := 50;
                END_IF;
            END_IF;

        50: // DONE
            xEmptyRunning := FALSE;
            uiEmptyState := 0;
            xEmptyReclassArmed := FALSE;
            fbTopFlow.Cmd.EmptyingMode := FALSE;

    END_CASE;
END_IF;


// ================================================================
// 13) WYWOŁANIA FB WYKONAWCZYCH
//     Najpierw TopFlow/Bottom/Elevator licza aktualne wyjscia,
//     potem silowniki i transportery dostaja gotowe komendy.
// ================================================================

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
GVL_IO.dout.ctrl_move_M2_actuator_forward := fbStopM2.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M2_actuator_backward := fbStopM2.Outp.Q_Bwd;

fbStopM3();
GVL_IO.dout.ctrl_move_M3_actuator_forward := fbStopM3.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M3_actuator_backward := fbStopM3.Outp.Q_Bwd;

fbStopM4();
GVL_IO.dout.ctrl_move_M4_actuator_forward := fbStopM4.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M4_actuator_backward := fbStopM4.Outp.Q_Bwd;

fbPosM1();
GVL_IO.dout.ctrl_move_M1_actuator_forward := fbPosM1.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M1_actuator_backward := fbPosM1.Outp.Q_Bwd;

fbPosM5();
GVL_IO.dout.ctrl_move_M5_actuator_forward := fbPosM5.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M5_actuator_backward := fbPosM5.Outp.Q_Bwd;

fbPosM6();
GVL_IO.dout.ctrl_move_M6_actuator_forward := fbPosM6.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M6_actuator_backward := fbPosM6.Outp.Q_Bwd;

fbPosM7();
GVL_IO.dout.ctrl_move_M7_actuator_forward := fbPosM7.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M7_actuator_backward := fbPosM7.Outp.Q_Bwd;

fbStorage.Cmd.Enable := xGlobalEnable;
fbStorage.Cmd.ResetFault := xResetAll;
fbStorage.Cmd.RobotAccessReq := GVL_Robot.robotIn.req_storage_access;
fbStorage.Cmd.RobotAccessPermit := xModeBox AND fbBoxSeq.Outp.AutoRunning AND
                                   (NOT xHmiManualMode) AND (NOT xEmptyRunning);
fbStorage.Cmd.ManRobotOpen := xHmiManualMode AND (NOT xEmptyRunning) AND xStorageManRobotOpen;
fbStorage.Cmd.ManRobotClose := xHmiManualMode AND (NOT xEmptyRunning) AND (NOT xStorageManRobotOpen);
fbStorage.Inp.BtnOpenClose := GVL_IO.di.ind_button_open_close_spacer_storage;
fbStorage.Inp.M8_Fwd := GVL_IO.di.ind_M8_fwd;
fbStorage.Inp.M8_Bwd := GVL_IO.di.ind_M8_bwd;
fbStorage.Inp.RobotSideOpeningPermission :=
    GVL_IO.di.ind_spacer_storage_robot_side_doors_opening_permission;
fbStorage.Inp.OperatorSideOpeningPermission :=
    GVL_IO.di.ind_spacer_storage_operator_side_doors_opening_permission;
fbStorage.Inp.LowLevel := GVL_IO.di.ind_low_level_of_spacers;
fbStorage.Inp.Empty := GVL_IO.di.ind_spacer_storage_empty;
fbStorage();
GVL_Robot.robotOut.storage_ready :=
    GVL_Robot.robotIn.req_storage_access AND
    fbStorage.Sts.RobotAccessGranted AND fbStorage.Sts.RobotSideOpen AND
    fbStorage.Inp.RobotSideOpeningPermission AND fbStorage.Outp.Q_UnlockRobotSide AND
    (NOT fbStorage.Sts.Empty) AND
    (NOT fbStorage.Diag.Fault);
GVL_IO.dout.ctrl_move_M8_actuator_forward := fbStorage.Outp.Q_M8Fwd;
GVL_IO.dout.ctrl_move_M8_actuator_backward := fbStorage.Outp.Q_M8Bwd;
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

// Sygnalizacja i LED przyciskow po aktualizacji wszystkich FB.
GVL_IO.dout.ctrl_turn_on_light_green :=
    xAutoActive AND (NOT fbTraySeq.Diag.Fault) AND (NOT fbBoxSeq.Diag.Fault);

GVL_IO.dout.ctrl_turn_on_light_yellow :=
    xAutoActive AND (fbTraySeq.Sts.Busy OR fbBoxSeq.Sts.Busy);

GVL_IO.dout.ctrl_turn_on_light_red :=
    fbTraySeq.Diag.Fault OR fbBoxSeq.Diag.Fault OR
    fbTopFlow.Diag.Fault OR fbBottom567.Diag.Fault OR
    elevStat.xFault OR fbSafetyDoor.Diag.Fault OR fbStorage.Diag.Fault;

GVL_IO.dout.ctrl_turn_on_buzzer :=
    GVL_IO.dout.ctrl_turn_on_light_red;

// Stan stacji i niezależne generatory migania LED przycisku opróżniania.
xStationNotEmpty := fbTopFlow.Sts.OccP1 OR
                    fbTopFlow.Sts.OccP2 OR
                    fbTopFlow.Sts.OccP3 OR
                    GVL_IO.di.ind_container_in_pos_4 OR
                    xElevatorLoadPresent OR
                    fbBottom567.Sts.Occ5 OR
                    fbBottom567.Sts.Occ6 OR
                    fbBottom567.Sts.Occ7;

xEmptyBottomHealthy := xGlobalEnable AND
                       (NOT fbBottom567.Diag.Fault) AND
                       (NOT fbConvBottom.Diag.Fault);

xEmptyBottomActuallyActive := fbBottom567.Sts.EmptyBottomActive AND
                              fbConvBottom.Outp.Q_Fwd;

xEmptyFastBlinkReq := xEmptyBottomHealthy AND
                      (xEmptyRunning OR xEmptyBottomActuallyActive);
xEmptySlowBlinkReq := xEmptyBottomHealthy AND
                      (NOT xEmptyRunning) AND
                      (NOT xProductionCycleStarted) AND
                      xStationNotEmpty;

tEmptyFastBlinkOn(
    IN := xEmptyFastBlinkReq AND xEmptyFastBlink,
    PT := T#250ms
);
tEmptyFastBlinkOff(
    IN := xEmptyFastBlinkReq AND (NOT xEmptyFastBlink),
    PT := T#250ms
);

IF NOT xEmptyFastBlinkReq THEN
    xEmptyFastBlink := TRUE;
ELSIF tEmptyFastBlinkOn.Q THEN
    xEmptyFastBlink := FALSE;
ELSIF tEmptyFastBlinkOff.Q THEN
    xEmptyFastBlink := TRUE;
END_IF;

tEmptySlowBlinkOn(
    IN := xEmptySlowBlinkReq AND xEmptySlowBlink,
    PT := T#1s
);
tEmptySlowBlinkOff(
    IN := xEmptySlowBlinkReq AND (NOT xEmptySlowBlink),
    PT := T#1s
);

IF NOT xEmptySlowBlinkReq THEN
    xEmptySlowBlink := TRUE;
ELSIF tEmptySlowBlinkOn.Q THEN
    xEmptySlowBlink := FALSE;
ELSIF tEmptySlowBlinkOff.Q THEN
    xEmptySlowBlink := TRUE;
END_IF;

GVL_IO.dout.ctrl_LED_button_start_process := NOT xAutoActive;
GVL_IO.dout.ctrl_LED_button_container_ready := NOT fbTopFlow.Sts.BufferFull;
GVL_IO.dout.ctrl_LED_button_continue_process :=
    xContinueReq OR fbTraySeq.Diag.Fault OR fbBoxSeq.Diag.Fault;

IF NOT xEmptyBottomHealthy THEN
    GVL_IO.dout.ctrl_LED_button_start_emptying_process := FALSE;
ELSIF xEmptyFastBlinkReq THEN
    GVL_IO.dout.ctrl_LED_button_start_emptying_process := xEmptyFastBlink;
ELSIF xProductionCycleStarted THEN
    GVL_IO.dout.ctrl_LED_button_start_emptying_process := TRUE;
ELSIF xEmptySlowBlinkReq THEN
    GVL_IO.dout.ctrl_LED_button_start_emptying_process := xEmptySlowBlink;
ELSE
    GVL_IO.dout.ctrl_LED_button_start_emptying_process := FALSE;
END_IF;

// Podawanie próbek: żądanie zatrzaśnięte do potwierdzenia przez robota.
xSamplesAvailable :=
    ((xModeTray AND fbTraySeq.Outp.AutoRunning) OR
     (xModeBox AND fbBoxSeq.Outp.AutoRunning)) AND
    GVL_Robot.xRobotCommOk AND GVL_Robot.robotIn.sts_auto_mode AND
    GVL_Robot.robotIn.sts_system_ready AND GVL_Robot.robotIn.sts_prg_running AND
    (NOT GVL_Robot.robotIn.sts_fault) AND
    (NOT GVL_Robot.robotIn.sts_samples_placed);

rtSamplesButton(CLK := GVL_IO.di.ind_button_samples);

IF rtSamplesButton.Q AND xSamplesAvailable AND (NOT xSamplesRequest) THEN
    xSamplesRequest := TRUE;
END_IF;

IF GVL_Robot.robotIn.sts_samples_placed THEN
    xSamplesRequest := FALSE;
END_IF;

tSamplesBlinkOn(IN := xSamplesRequest AND (NOT xSamplesBlink), PT := T#500ms);
tSamplesBlinkOff(IN := xSamplesRequest AND xSamplesBlink, PT := T#500ms);

IF NOT xSamplesRequest THEN
    xSamplesBlink := FALSE;
ELSIF tSamplesBlinkOn.Q THEN
    xSamplesBlink := TRUE;
ELSIF tSamplesBlinkOff.Q THEN
    xSamplesBlink := FALSE;
END_IF;

GVL_IO.dout.ctrl_LED_button_samples :=
    (xSamplesAvailable AND (NOT xSamplesRequest)) OR
    (xSamplesRequest AND xSamplesBlink);

// ================================================================
// 14) KOMUNIKACJA — Control_ATV (ATV320) + IOScanner (Robot FANUC)
// ================================================================

// ATV320 sterowany jest w FB_Elevator przez GIATV.Control_ATV i Axis_Ref.
// Robot FANUC komunikuje się przez IOScanner; PRG_IO_Read/Write mapują sygnały.

// --- IOScanner: robot FANUC ---
GVL_Robot.robotOut.cmd_tray_production :=
    xModeTray AND fbTraySeq.Outp.AutoRunning AND fbTraySeq.Outp.Robot_TrayProduction;
GVL_Robot.robotOut.cmd_box_production :=
    xModeBox AND fbBoxSeq.Outp.AutoRunning AND fbBoxSeq.Outp.Robot_BoxProduction;
GVL_Robot.robotOut.cmd_continue_job := xContinueReq;
GVL_Robot.robotOut.cmd_samples := xSamplesRequest;
GVL_Robot.robotOut.cmd_stack_ready :=
    (xModeTray AND fbTraySeq.Outp.AutoRunning AND fbTraySeq.Outp.Robot_StackReady AND
     (NOT fbTraySeq.Outp.Robot_AckStackFinished)) OR
    (xModeBox AND fbBoxSeq.Outp.AutoRunning AND fbBoxSeq.Outp.Robot_StackReady AND
     (NOT fbBoxSeq.Outp.Robot_AckStackFinished));
GVL_Robot.robotOut.cmd_elevator_ready :=
    (xModeTray AND fbTraySeq.Outp.AutoRunning AND fbTraySeq.Outp.Robot_ElevatorReady) OR
    (xModeBox AND fbBoxSeq.Outp.AutoRunning AND fbBoxSeq.Outp.Robot_ElevatorReady);
GVL_Robot.robotOut.ack_stack_finished :=
    (xModeTray AND fbTraySeq.Outp.Robot_AckStackFinished) OR
    fbBoxSeq.Outp.Robot_AckStackFinished;
GVL_Robot.robotOut.vacuum_5_ok := GVL_IO.di.ind_robot_gripper_vacuum_ok;

GVL_IO.dout.ctrl_turn_on_robot_gripper_vacuum := GVL_Robot.robotIn.cmd_vacuum_5;
GVL_IO.dout.ctrl_turn_on_robot_gripper_blow_off := GVL_Robot.robotIn.cmd_blow_off_5;


// ================================================================
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
GVL_HMI.hmiAlarms.xRobot_Fault      := GVL_Robot.robotIn.sts_fault;
GVL_HMI.hmiAlarms.xRobot_EStop      := GVL_Robot.robotIn.sts_estop;
GVL_HMI.hmiAlarms.xRobot_CommLost   := NOT GVL_Robot.xRobotCommOk;
GVL_HMI.hmiAlarms.xVfd_CommLost     := xGlobalEnable AND (NOT elevStat.xVfdCommOk);
GVL_HMI.hmiAlarms.xLowPressure      := GVL_IO.di.ind_low_pressure;
GVL_HMI.hmiAlarms.xSafetyTrip       := NOT xSafetyOK;

GVL_HMI.hmiAlarmCount := 
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xM1_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xM2_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xM3_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xM4_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xM5_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xM6_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xM7_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xM8_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xConvTop_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xConvElev_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xConvBottom_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xElev_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xElev_CommLost) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xTopFlow_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xBottom_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xTraySeq_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xBoxSeq_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xRobot_Fault) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xRobot_EStop) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xRobot_CommLost) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xVfd_CommLost) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xRobot_MbLost) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xLowPressure) +
    BOOL_TO_UINT(GVL_HMI.hmiAlarms.xSafetyTrip);

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
GVL_HMI.hmiStatus.xRobotAutoMode := GVL_Robot.robotIn.sts_auto_mode;
GVL_HMI.hmiStatus.xRobotReady    := GVL_Robot.robotIn.sts_system_ready;
GVL_HMI.hmiStatus.xRobotRunning  := GVL_Robot.robotIn.sts_prg_running;
GVL_HMI.hmiStatus.xRobotFault    := GVL_Robot.robotIn.sts_fault;
GVL_HMI.hmiStatus.xRobotHome     := GVL_Robot.robotIn.sts_in_home_pos;
GVL_HMI.hmiStatus.xRobotCommOk   := GVL_Robot.xRobotCommOk;
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

PRG_IO_Write();
