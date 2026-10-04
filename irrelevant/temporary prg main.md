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

    (* --- Pozycjonery (pojedyncze siłowniki 2-poz.) --- *)
    fbPosM1        : FB_Cyl2Pos;       // pozycjoner załadunku
    fbPosM5        : FB_StopperPair;   // pozycjoner tacek P3 (para)
    fbPosM6        : FB_StopperPair;   // pozycjoner tacek winda (para)
    fbPosM7        : FB_Cyl2Pos;       // pozycjoner kuwet winda (pojedynczy)
    fbPosM8        : FB_Cyl2Pos;       // magazyn przekładek

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

    (* --- Komunikacja Modbus TCP --- *)
    fbModbusComm   : FB_ModbusComm;

    (* --- Tryb produkcji --- *)
    xModeTray      : BOOL;   // TRUE = tacki, FALSE = kuwety (z HMI / przełącznik)
    xModeBox       : BOOL;

    (* --- Opróżnianie stacji --- *)
    xEmptyStation     : BOOL;       // przycisk "opróżnij stację"
    rtEmptyStation    : R_TRIG;
    xEmptyRunning     : BOOL;       // flaga: trwa opróżnianie
    uiEmptyState      : UINT;       // 0=idle, 10=top_flush, 20=elev_down, 30=discharge, 40=elev_up, 50=done

    (* --- Kontynuuj --- *)
    rtContinue        : R_TRIG;
    xContinueReq      : BOOL;
    tpRobotContinue   : TP;

    (* --- Załadunek P1 / M1 --- *)
    rtContainerReady      : R_TRIG;
    xLoadAcceptedPending  : BOOL;
    xTopFlowAcceptPulse   : BOOL;

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

    (* --- Timery opróżniania --- *)
    tEmptyTO         : TON;
    tEmptyTransfer   : TON;
    tElevTransferDone : TON;
    xElevTransferDone : BOOL;

    (* --- Pomocnicze --- *)
    xSafetyOK      : BOOL := TRUE;  // z zewn. sterownika safety — domyślnie TRUE do testów
    xGlobalEnable  : BOOL;
    xResetAll      : BOOL;          // globalny reset błędów (z HMI)
    xAutoActive    : BOOL;          // TRUE gdy którykolwiek sekwencer jest aktywny
END_VAR

// ================================================================
// 0) Kopiowanie RAW I/O -> abstrakcja
// ================================================================
PRG_IO_Read();


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
        fbPosM1.CmdExtend := TRUE;
    ELSIF NOT xHmiM1Fwd AND xHmiM1Bwd THEN
        fbPosM1.CmdExtend := FALSE;
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
        fbPosM7.CmdExtend := TRUE;
    ELSIF NOT xHmiM7Fwd AND xHmiM7Bwd THEN
        fbPosM7.CmdExtend := FALSE;
    END_IF;
    IF xHmiM8Fwd AND NOT xHmiM8Bwd THEN
        fbPosM8.CmdExtend := TRUE;
    ELSIF NOT xHmiM8Fwd AND xHmiM8Bwd THEN
        fbPosM8.CmdExtend := FALSE;
    END_IF;
END_IF;

// xAutoActive obliczane PO wywołaniu sekwencerów (patrz dalej po sek. 10)

// --- Zbocza przycisków ---
xEmptyStation := GVL_IO.di.ind_button_start_emptying_process OR GVL_HMI.hmiCmd.xEmptyStation;
rtEmptyStation(CLK := xEmptyStation);
rtContinue(CLK := GVL_IO.di.ind_button_continue_process);
tpRobotContinue(IN := rtContinue.Q, PT := T#1s);
rtContainerReady(CLK := GVL_IO.di.ind_button_container_ready);
xTopFlowAcceptPulse := FALSE;

// "Kontynuuj" daje 1 s na reset podblokow i wznowienie sekwencji bez zerowania licznikow.
xContinueReq := tpRobotContinue.Q;
xResetAll := GVL_HMI.hmiCmd.xResetFaults OR xContinueReq;

// Potwierdzenie transferu na winde: P4 musi byc zasloniete stabilnie przez 2 s.
tElevTransferDone(IN := GVL_IO.di.ind_container_in_pos_4, PT := T#2s);
xElevTransferDone := tElevTransferDone.Q;

// Obsługa przycisku "Opróżnij stację"
IF rtEmptyStation.Q AND (NOT xEmptyRunning) THEN
    xEmptyRunning := TRUE;
    uiEmptyState := 10;
    // Zatrzymaj aktywne sekwencery
    fbTraySeq.Cmd.StopAuto := TRUE;
    fbBoxSeq.Cmd.StopAuto := TRUE;
END_IF;

IF xHmiManualMode OR xEmptyRunning OR xResetAll OR (NOT GVL_IO.di.ind_container_in_pos_1) THEN
    xLoadAcceptedPending := FALSE;
ELSIF rtContainerReady.Q THEN
    xLoadAcceptedPending := TRUE;
END_IF;

IF NOT xHmiManualMode THEN
    fbPosM1.CmdExtend := xLoadAcceptedPending AND
                          GVL_IO.di.ind_container_in_pos_1 AND
                          (NOT xEmptyRunning);
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
fbStopM2();
GVL_IO.dout.ctrl_move_M2_actuator_forward := fbStopM2.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M2_actuator_backward := fbStopM2.Outp.Q_Bwd;

// --- M3: stoper pozycja 2 ---
fbStopM3.Enable := xGlobalEnable;
fbStopM3.ResetFault := xResetAll;
fbStopM3.Inp.ind_1_fwd := GVL_IO.di.ind_M3_1_fwd;
fbStopM3.Inp.ind_2_fwd := GVL_IO.di.ind_M3_2_fwd;
fbStopM3.Inp.ind_1_bwd := GVL_IO.di.ind_M3_1_bwd;
fbStopM3.Inp.ind_2_bwd := GVL_IO.di.ind_M3_2_bwd;
fbStopM3();
GVL_IO.dout.ctrl_move_M3_actuator_forward := fbStopM3.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M3_actuator_backward := fbStopM3.Outp.Q_Bwd;

// --- M4: stoper pozycja 3 ---
fbStopM4.Enable := xGlobalEnable;
fbStopM4.ResetFault := xResetAll;
fbStopM4.Inp.ind_1_fwd := GVL_IO.di.ind_M4_1_fwd;
fbStopM4.Inp.ind_2_fwd := GVL_IO.di.ind_M4_2_fwd;
fbStopM4.Inp.ind_1_bwd := GVL_IO.di.ind_M4_1_bwd;
fbStopM4.Inp.ind_2_bwd := GVL_IO.di.ind_M4_2_bwd;
fbStopM4();
GVL_IO.dout.ctrl_move_M4_actuator_forward := fbStopM4.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M4_actuator_backward := fbStopM4.Outp.Q_Bwd;


// ================================================================
// 2) POZYCJONERY — M1, M5, M6, M7, M8
// ================================================================

// --- M1: pozycjoner załadunku (pojedynczy cyl) ---
fbPosM1.Enable := xGlobalEnable;
fbPosM1.ResetFault := xResetAll;
fbPosM1.Inp.IsExt := GVL_IO.di.ind_M1_1_fwd AND GVL_IO.di.ind_M1_2_fwd;
fbPosM1.Inp.IsRet := GVL_IO.di.ind_M1_1_bwd AND GVL_IO.di.ind_M1_2_bwd;
// CmdExtend ustawiany przez logikę załadunku (poniżej)
fbPosM1();
GVL_IO.dout.ctrl_move_M1_actuator_forward := fbPosM1.Outp.Q_Ext;
GVL_IO.dout.ctrl_move_M1_actuator_backward := fbPosM1.Outp.Q_Ret;

// --- M5: pozycjoner tacek P3 (para) ---
fbPosM5.Enable := xGlobalEnable;
fbPosM5.ResetFault := xResetAll;
fbPosM5.Inp.ind_1_fwd := GVL_IO.di.ind_M5_1_fwd;
fbPosM5.Inp.ind_2_fwd := GVL_IO.di.ind_M5_2_fwd;
fbPosM5.Inp.ind_1_bwd := GVL_IO.di.ind_M5_1_bwd;
fbPosM5.Inp.ind_2_bwd := GVL_IO.di.ind_M5_2_bwd;
// HoldUp zarządzane przez TopFlowManager (bramka tacek P3 w trybie tray)
fbPosM5();
GVL_IO.dout.ctrl_move_M5_actuator_forward := fbPosM5.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M5_actuator_backward := fbPosM5.Outp.Q_Bwd;

// --- M6: pozycjoner tacek winda (para) ---
fbPosM6.Enable := xGlobalEnable;
fbPosM6.ResetFault := xResetAll;
fbPosM6.Inp.ind_1_fwd := GVL_IO.di.ind_M6_1_fwd;
fbPosM6.Inp.ind_2_fwd := GVL_IO.di.ind_M6_2_fwd;
fbPosM6.Inp.ind_1_bwd := GVL_IO.di.ind_M6_1_bwd;
fbPosM6.Inp.ind_2_bwd := GVL_IO.di.ind_M6_2_bwd;
fbPosM6();
GVL_IO.dout.ctrl_move_M6_actuator_forward := fbPosM6.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M6_actuator_backward := fbPosM6.Outp.Q_Bwd;


// --- M7: pozycjoner kuwet winda (pojedynczy cyl) ---
fbPosM7.Enable := xGlobalEnable;
fbPosM7.ResetFault := xResetAll;
fbPosM7.Inp.IsExt := GVL_IO.di.ind_M7_fwd;
fbPosM7.Inp.IsRet := GVL_IO.di.ind_M7_bwd;
fbPosM7();
GVL_IO.dout.ctrl_move_M7_actuator_forward := fbPosM7.Outp.Q_Ext;
GVL_IO.dout.ctrl_move_M7_actuator_backward := fbPosM7.Outp.Q_Ret;

// --- M8: magazyn przekładek ---
fbPosM8.Enable := xGlobalEnable;
fbPosM8.ResetFault := xResetAll;
fbPosM8.Inp.IsExt := GVL_IO.di.ind_M8_fwd;
fbPosM8.Inp.IsRet := GVL_IO.di.ind_M8_bwd;
fbPosM8();
GVL_IO.dout.ctrl_move_M8_actuator_forward := fbPosM8.Outp.Q_Ext;
GVL_IO.dout.ctrl_move_M8_actuator_backward := fbPosM8.Outp.Q_Ret;


// ================================================================
// 3) TRANSPORTERY — z blokadą programową
// ================================================================

// --- Górny transporter (jednokierunkowy w normalnej pracy, FWD = do robota) ---
fbConvTop.Inp.Enable := xGlobalEnable;
fbConvTop.Inp.SafetyOK := xSafetyOK;
fbConvTop.Cmd.ResetFault := xResetAll;
// RunFwd zarządzany wyłącznie przez TopFlowManager (patrz sekcja 8)
fbConvTop();
GVL_IO.dout.ctrl_turn_on_top_conveyor := fbConvTop.Outp.Q_Fwd;
// Górny transporter nie ma osobnego wyjścia BWD w GVL_IO — jest jednokierunkowy sprzętowo

// --- Transporter windy (dwukierunkowy: IN = do robota, OUT = do rozładunku) ---
fbConvElev.Inp.Enable := xGlobalEnable;
fbConvElev.Inp.SafetyOK := xSafetyOK;
fbConvElev.Cmd.ResetFault := xResetAll;
fbConvElev();
GVL_IO.dout.ctrl_turn_on_elevator_conveyor_in := fbConvElev.Outp.Q_Fwd;
GVL_IO.dout.ctrl_turn_on_elevator_conveyor_out := fbConvElev.Outp.Q_Bwd;

// --- Dolny transporter (dwukierunkowy: FWD = do wyjścia, BWD = do windy) ---
fbConvBottom.Inp.Enable := xGlobalEnable;
fbConvBottom.Inp.SafetyOK := xSafetyOK;
fbConvBottom.Cmd.ResetFault := xResetAll;
fbConvBottom();
GVL_IO.dout.ctrl_turn_on_bottom_conveyor := fbConvBottom.Outp.Q_Fwd;
GVL_IO.dout.ctrl_turn_on_bottom_conveyor_in := fbConvBottom.Outp.Q_Bwd;


// ================================================================
// 4) WINDA (FUNCTION — wywołanie bezpośrednie)
// ================================================================

// Mapowanie wejść windy
elevIn.xInPos1 := GVL_IO.di.ind_elevator_in_top_pos;
elevIn.xInPos2 := GVL_IO.di.ind_elevator_in_intermediate_top_pos;
elevIn.xInPos3 := GVL_IO.di.ind_elevator_in_intermediate_bottom_pos;
elevIn.xInPos4 := GVL_IO.di.ind_elevator_in_bottom_pos;
elevIn.xSafetyOk := xSafetyOK;
elevIn.xDoorClosed := GVL_IO.di.ind_robot_cell_doors_closed;
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
// Tryb AUTO tylko poza ręcznym — w ręcznym sekcja 12 ustawia MANUAL
IF NOT xHmiManualMode THEN
    elevCmd.eMode := E_ElevatorMode.AUTO;
END_IF;
elevCmd.rSpeedFast_Hz := 40.0;
elevCmd.rSpeedSlow_Hz := 15.0;

fbElevator(
    xEnable := xGlobalEnable,
    stCmd := elevCmd,
    stIn := elevIn,
    stPar := elevPar,
    stOut => elevOut,
    stStat => elevStat
);
uiElevState := TO_UINT(elevStat.eState);


// ================================================================
// 5) TOP FLOW MANAGER — zarządza buforem P1-P3
// ================================================================

fbTopFlow.Cmd.SafetyOK := xSafetyOK;
fbTopFlow.Cmd.ResetFault := xResetAll;
fbTopFlow.Cmd.Pos1AcceptedPulse := GVL_IO.di.ind_button_container_ready;
// TrayMode: TRUE = produkcja tacek (M5 bramka, brak TG_ELEV)
//           FALSE = produkcja kuwet (TG_ELEV możliwe, dwa transportery jednocześnie)
fbTopFlow.Cmd.TrayMode := xModeTray;

// Mapowanie czujników
fbTopFlow.Inp.sPos1_raw := GVL_IO.di.ind_container_in_pos_1;
fbTopFlow.Inp.sPos2_raw := GVL_IO.di.ind_container_in_pos_2;
fbTopFlow.Inp.sPos3_raw := GVL_IO.di.ind_container_in_pos_3;
fbTopFlow.Inp.sPos4_raw := GVL_IO.di.ind_container_in_pos_4;

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

// Wyjścia TraySeq -> wejścia TopFlow ustawiane są TU (przed wywołaniem), żeby wyeliminować
// opóźnienie 1 skan z poprzedniej wersji gdzie były ustawiane po wywołaniu.
// Wartości są dostępne dzięki temu, że TraySeq jest wywoływany wcześniej (sekcja 7_pre).
// UWAGA: dlatego wywołanie fbTraySeq() zostało przeniesione PRZED fbTopFlow() poniżej.

// Wywołanie sekwencera (PRZED TopFlow, aby wejścia TopFlow były aktualne)
// Sekcja 7 (wywołanie fbTraySeq) przeniesiona tu górę — patrz poniżej

// Wywołanie
fbTopFlow();

// Mapowanie wyjść TopFlow -> stopery i M5
// TopFlowManager jest wyłącznym właścicielem M4 i M5 w trybie AUTO
// (TraySeq już nie nadpisuje M4 — usunieto konflikt z poprzedniej wersji)
IF NOT xHmiManualMode THEN
    fbStopM2.HoldUp := fbTopFlow.Outp.HoldPos1_Up;
    fbStopM3.HoldUp := fbTopFlow.Outp.HoldPos2_Up;
    fbStopM4.HoldUp := fbTopFlow.Outp.HoldPos3_Up;  // M4 — TopFlow jest jedynym właścicielem
    fbPosM5.HoldUp  := fbTopFlow.Outp.M5_Extend;    // M5 — TopFlow steruje bramką
END_IF;


// ================================================================
// 6) BOTTOM ACCUMULATOR — rozładunek P5-P7
// ================================================================

fbBottom567.Cmd.SafetyOK := xSafetyOK;
fbBottom567.Cmd.ResetFault := xResetAll;

fbBottom567.Inp.sPos5_raw := GVL_IO.di.ind_container_in_pos_5;
fbBottom567.Inp.sPos6_raw := GVL_IO.di.ind_container_in_pos_6;
fbBottom567.Inp.sPos7_raw := GVL_IO.di.ind_container_in_pos_7;

fbBottom567();


// ================================================================
// 7) TRAY SEQUENCER — orkiestracja trybu AUTO tacek
// ================================================================

IF xModeTray AND (NOT xHmiManualMode) AND (NOT xEmptyRunning) THEN
    fbTraySeq.Cmd.StartAuto := GVL_IO.di.ind_button_start_process OR xContinueReq;
ELSE
    fbTraySeq.Cmd.StartAuto := FALSE;
END_IF;
fbTraySeq.Cmd.SafetyOK := xSafetyOK;
fbTraySeq.Cmd.ResetFault := xResetAll;
fbTraySeq.Cmd.StopAuto := xHmiManualMode OR xEmptyRunning OR GVL_HMI.hmiCmd.xStopAuto;
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
fbTraySeq.Inp.Elev_Fault    := elevStat.xFault;

fbTraySeq.Inp.Bottom_CanAccept := fbBottom567.Sts.CanAcceptFromElev;
fbTraySeq.Inp.Bottom_Busy      := fbBottom567.Sts.Busy;
fbTraySeq.Inp.Bottom_Fault     := fbBottom567.Diag.Fault;

fbTraySeq.Inp.ind_container_in_pos_4 := GVL_IO.di.ind_container_in_pos_4;
fbTraySeq.Inp.ind_elevator_emptied   := GVL_IO.di.ind_elevator_emptied;

// Pozycjoner M6 feedback (M4, M5 są teraz obsługiwane przez TopFlowManager)
fbTraySeq.Inp.M6_IsUp   := fbPosM6.Sts.IsUp;
fbTraySeq.Inp.M6_IsDown := fbPosM6.Sts.IsDown;

// Robot feedback (z Modbus)
fbTraySeq.Inp.Robot_SystemReady    := GVL_Robot.robotIn.sts_system_ready;
fbTraySeq.Inp.Robot_PrgRunning     := GVL_Robot.robotIn.sts_prg_running;
fbTraySeq.Inp.Robot_InHome         := GVL_Robot.robotIn.sts_in_home_pos;
fbTraySeq.Inp.Robot_AutoMode       := GVL_Robot.robotIn.sts_auto_mode;
fbTraySeq.Inp.Robot_Fault          := GVL_Robot.robotIn.sts_fault;
fbTraySeq.Inp.Robot_PalletFinished := GVL_Robot.robotIn.sts_pallet_finished;
fbTraySeq.Inp.Robot_StackFinished  := GVL_Robot.robotIn.sts_stack_finished;
fbTraySeq.Inp.Robot_CmdAck         := GVL_Robot.robotIn.sts_cmd_ack;

// Wywołanie sekwencera
fbTraySeq();


// ================================================================
// 8) Mapowanie wyjść TraySequencer -> sub-FB
// ================================================================

// TopFlowManager — komendy sterowania + nowe sygnały
fbTopFlow.Cmd.EnableAuto := fbTraySeq.Outp.TopFlow_Enable;
fbTopFlow.Inp.Elev_RequestFeed  := fbTraySeq.Outp.TopFlow_Elev_RequestFeed;  // dla trybu kuwet
fbTopFlow.Inp.Elev_CanAccept    := fbTraySeq.Outp.TopFlow_Elev_CanAccept;    // dla trybu kuwet
fbTopFlow.Inp.StackConsumedAtP3 := fbTraySeq.Outp.TopFlow_StackConsumed;    // stos zużyty — zwolnij P3/M4

// Transportery
// Górny transporter: wyłącznie TopFlowManager (TraySeq nie ingeruje w trybie tray)
fbConvTop.Cmd.RunFwd := fbTopFlow.Outp.TopConveyor_Run;
fbConvElev.Cmd.RunFwd := fbTraySeq.Outp.ElevConv_RunFwd OR
                         (fbTopFlow.Outp.Elev_TransferActive AND (xModeBox OR xEmptyRunning));
fbConvElev.Cmd.RunBwd := fbTraySeq.Outp.ElevConv_RunBwd;
fbConvBottom.Cmd.RunFwd := fbTraySeq.Outp.BottomConv_RunFwd;

// Winda (komendy z TraySequencer)
elevCmd.xAutoGo := fbTraySeq.Outp.Elev_AutoGo;
elevCmd.xAutoStop := fbTraySeq.Outp.Elev_Stop;
elevCmd.eAutoTarget := fbTraySeq.Outp.Elev_AutoTarget;
elevCmd.xReset := xResetAll;

// Pozycjonery M6 (komendy z TraySequencer)
// M4 i M5 są już sterowane przez TopFlowManager w sekcji 5
IF NOT xHmiManualMode THEN
    fbPosM6.HoldUp := fbTraySeq.Outp.M6_Extend;
END_IF;

// BottomAccumulator
fbBottom567.Cmd.EnableAuto := fbTraySeq.Outp.Bottom_Enable;
fbBottom567.Cmd.DischargeReq := fbTraySeq.Outp.Bottom_DischargeReq;

// Robot wyjścia (do Modbus)
GVL_Robot.robotOut.cmd_tray_production := fbTraySeq.Outp.Robot_TrayProduction;
GVL_Robot.robotOut.cmd_stack_ready := fbTraySeq.Outp.Robot_StackReady;
GVL_Robot.robotOut.cmd_elevator_ready := fbTraySeq.Outp.Robot_ElevatorReady;


// ================================================================
// 9) Sygnalizacja świetlna (prosta logika)
// ================================================================

GVL_IO.dout.ctrl_turn_on_light_green :=
    xAutoActive AND (NOT fbTraySeq.Diag.Fault) AND (NOT fbBoxSeq.Diag.Fault);

GVL_IO.dout.ctrl_turn_on_light_yellow :=
    xAutoActive AND (fbTraySeq.Sts.Busy OR fbBoxSeq.Sts.Busy);

GVL_IO.dout.ctrl_turn_on_light_red :=
    fbTraySeq.Diag.Fault OR fbBoxSeq.Diag.Fault OR
    fbTopFlow.Diag.Fault OR fbBottom567.Diag.Fault OR
    elevStat.xFault;

GVL_IO.dout.ctrl_turn_on_buzzer :=
    GVL_IO.dout.ctrl_turn_on_light_red;

// Podświetlenie przycisków
GVL_IO.dout.ctrl_LED_button_start_process := NOT xAutoActive;
GVL_IO.dout.ctrl_LED_button_container_ready := NOT fbTopFlow.Sts.BufferFull;
GVL_IO.dout.ctrl_LED_button_continue_process := fbTraySeq.Diag.Fault OR fbBoxSeq.Diag.Fault;
GVL_IO.dout.ctrl_LED_button_start_emptying_process := NOT xEmptyRunning;


// ================================================================
// 10) BOX SEQUENCER — orkiestracja trybu AUTO kuwet
// ================================================================

IF xModeBox AND (NOT xHmiManualMode) AND (NOT xEmptyRunning) THEN
    fbBoxSeq.Cmd.StartAuto := GVL_IO.di.ind_button_start_process OR xContinueReq;
ELSE
    fbBoxSeq.Cmd.StartAuto := FALSE;
END_IF;
fbBoxSeq.Cmd.SafetyOK := xSafetyOK;
fbBoxSeq.Cmd.ResetFault := xResetAll;
// Analogicznie jak TraySeq — wymuś DISABLED w trybie ręcznym lub opróżniania:
fbBoxSeq.Cmd.StopAuto := xHmiManualMode OR xEmptyRunning OR GVL_HMI.hmiCmd.xStopAuto;

// Wejścia z sub-FB (analogiczne do TraySeq)
fbBoxSeq.Inp.TopFlow_OccP3 := fbTopFlow.Sts.OccP3;
fbBoxSeq.Inp.TopFlow_Busy := fbTopFlow.Sts.Busy;
fbBoxSeq.Inp.TopFlow_Fault := fbTopFlow.Diag.Fault;

fbBoxSeq.Inp.Elev_AtTop := elevStat.ePos = E_ElevatorPos.posTop;
fbBoxSeq.Inp.Elev_AtBottom := elevStat.ePos = E_ElevatorPos.posBottom;
fbBoxSeq.Inp.Elev_AtTarget := elevStat.xAtTarget;
fbBoxSeq.Inp.Elev_Busy := elevStat.xBusy;
fbBoxSeq.Inp.Elev_Fault := elevStat.xFault;

fbBoxSeq.Inp.Bottom_CanAccept := fbBottom567.Sts.CanAcceptFromElev;
fbBoxSeq.Inp.Bottom_Busy := fbBottom567.Sts.Busy;
fbBoxSeq.Inp.Bottom_Fault := fbBottom567.Diag.Fault;

fbBoxSeq.Inp.ind_container_in_pos_4 := GVL_IO.di.ind_container_in_pos_4;
fbBoxSeq.Inp.ind_elevator_emptied := GVL_IO.di.ind_elevator_emptied;

fbBoxSeq.Inp.M7_AtExt := fbPosM7.Sts.AtExt;
fbBoxSeq.Inp.M7_AtRet := fbPosM7.Sts.AtRet;

fbBoxSeq.Inp.Robot_SystemReady := GVL_Robot.robotIn.sts_system_ready;
fbBoxSeq.Inp.Robot_PrgRunning := GVL_Robot.robotIn.sts_prg_running;
fbBoxSeq.Inp.Robot_AutoMode := GVL_Robot.robotIn.sts_auto_mode;
fbBoxSeq.Inp.Robot_Fault := GVL_Robot.robotIn.sts_fault;
fbBoxSeq.Inp.Robot_StackFinished := GVL_Robot.robotIn.sts_stack_finished;
fbBoxSeq.Inp.Robot_CmdAck := GVL_Robot.robotIn.sts_cmd_ack;

fbBoxSeq();

// xAutoActive — oblicz PO wywołaniu obu sekwencerów (aktualne wartości tego skanu)
xAutoActive := fbTraySeq.Outp.AutoRunning OR fbBoxSeq.Outp.AutoRunning;

// Mapowanie wyjść BoxSeq (gdy aktywny)
IF fbBoxSeq.Outp.AutoRunning THEN
    fbTopFlow.Cmd.EnableAuto := fbBoxSeq.Outp.TopFlow_Enable;
    fbTopFlow.Inp.Elev_RequestFeed := fbBoxSeq.Outp.TopFlow_Elev_RequestFeed;
    fbTopFlow.Inp.Elev_CanAccept := fbBoxSeq.Outp.TopFlow_Elev_CanAccept;

    fbConvTop.Cmd.RunFwd := fbTopFlow.Outp.TopConveyor_Run;
    fbConvElev.Cmd.RunFwd := fbTopFlow.Outp.Elev_TransferActive AND (xModeBox OR xEmptyRunning);
    fbConvElev.Cmd.RunBwd := fbBoxSeq.Outp.ElevConv_RunBwd;
    fbConvBottom.Cmd.RunFwd := fbBoxSeq.Outp.BottomConv_RunFwd;

    elevCmd.xAutoGo := fbBoxSeq.Outp.Elev_AutoGo;
    elevCmd.xAutoStop := fbBoxSeq.Outp.Elev_Stop;
    elevCmd.eAutoTarget := fbBoxSeq.Outp.Elev_AutoTarget;

    // (tylko w trybie AUTO — w trybie ręcznym nie nadpisujemy bistabilnego CmdExtend)
    IF NOT xHmiManualMode THEN
        fbPosM7.CmdExtend := fbBoxSeq.Outp.M7_Extend;
    END_IF;

    fbBottom567.Cmd.EnableAuto := fbBoxSeq.Outp.Bottom_Enable;
    fbBottom567.Cmd.DischargeReq := fbBoxSeq.Outp.Bottom_DischargeReq;

    GVL_Robot.robotOut.cmd_box_production := fbBoxSeq.Outp.Robot_BoxProduction;
    GVL_Robot.robotOut.cmd_stack_ready := fbBoxSeq.Outp.Robot_StackReady;
    GVL_Robot.robotOut.cmd_elevator_ready := fbBoxSeq.Outp.Robot_ElevatorReady;
END_IF;


// ================================================================
// 11) OPRÓŻNIANIE STACJI — dostarczaj pojemniki do wyjścia, pomijaj paletyzację
// ================================================================

IF xEmptyRunning THEN
    CASE uiEmptyState OF

        10: // TOP_FLUSH: dopóki jest pojemnik na P1/P2/P3, przesuń go na windę i dalej
            // Żądaj podawania na windę przez TopFlowManager
            fbTopFlow.Cmd.EnableAuto := TRUE;
            fbTopFlow.Cmd.EmptyingMode := TRUE;
            fbTopFlow.Inp.Elev_RequestFeed := TRUE;
            fbTopFlow.Inp.Elev_CanAccept := elevStat.ePos = E_ElevatorPos.posTop
                                            AND (NOT GVL_IO.di.ind_container_in_pos_4);

            // Jeśli pojemnik dotarł na windę -> jedź na dół
            IF GVL_IO.di.ind_container_in_pos_4 AND (NOT fbTopFlow.Sts.Busy) THEN
                uiEmptyState := 20;
                tEmptyTO(IN := FALSE);
            END_IF;

            // Jeśli nic już nie ma na górze -> sprawdź windę
            IF (NOT fbTopFlow.Sts.OccP1) AND (NOT fbTopFlow.Sts.OccP2) AND (NOT fbTopFlow.Sts.OccP3) THEN
                IF GVL_IO.di.ind_container_in_pos_4 THEN
                    uiEmptyState := 20; // jest na windzie
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

        30: // DISCHARGE: transportery winda_out + dolny
            fbConvElev.Cmd.RunBwd := TRUE;
            fbConvBottom.Cmd.RunFwd := TRUE;
            fbBottom567.Cmd.EnableAuto := TRUE;
            fbBottom567.Cmd.DischargeReq := TRUE;

            tEmptyTO(IN := TRUE, PT := T#15s);

            IF GVL_IO.di.ind_elevator_emptied THEN
                fbConvElev.Cmd.RunBwd := FALSE;
                fbConvBottom.Cmd.RunFwd := FALSE;
                tEmptyTO(IN := FALSE);
                uiEmptyState := 40;
            ELSIF tEmptyTO.Q THEN
                fbConvElev.Cmd.RunBwd := FALSE;
                fbConvBottom.Cmd.RunFwd := FALSE;
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
                ELSE
                    uiEmptyState := 50;
                END_IF;
            END_IF;

        50: // DONE
            xEmptyRunning := FALSE;
            uiEmptyState := 0;
            fbTopFlow.Cmd.EmptyingMode := FALSE;

    END_CASE;
END_IF;


// ================================================================
// 13) KOMUNIKACJA — Control_ATV (ATV320) + Modbus TCP (Robot FANUC)
// ================================================================

// ATV320 sterowany jest w FB_Elevator przez GIATV.Control_ATV i Axis_Ref.
// Nie zapisujemy już ręcznie słów CMD/LFR do %QW7/%QW8.

// --- Modbus TCP: tylko robot FANUC ---
fbModbusComm.Cfg.cfgRobot := GVL_ModbusTCP.cfgRobot;
fbModbusComm.Cmd.xEnable     := xGlobalEnable;
fbModbusComm.Cmd.xResetFault := xResetAll;
fbModbusComm.Inp.stRobotOut := GVL_Robot.robotOut;
fbModbusComm();
GVL_Robot.robotIn := fbModbusComm.Outp.stRobotIn;


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
GVL_HMI.hmiAlarms.xM8_Fault         := fbPosM8.Diag.Fault;
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
GVL_HMI.hmiAlarms.xRobot_CommLost   := NOT fbModbusComm.Outp.stStatus.xRobotCommOk;
GVL_HMI.hmiAlarms.xVfd_CommLost     := xGlobalEnable AND (NOT elevStat.xVfdCommOk);
GVL_HMI.hmiAlarms.xRobot_MbLost     := NOT fbModbusComm.Outp.stStatus.xRobotCommOk;
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

// Transportery
GVL_HMI.hmiStatus.xConvTopRunning    := fbConvTop.Sts.Running;
GVL_HMI.hmiStatus.xConvElevRunning   := fbConvElev.Sts.Running;
GVL_HMI.hmiStatus.xConvBottomRunning := fbConvBottom.Sts.Running;

// Siłowniki — stan zagregowany (kompatybilność wstecz)
GVL_HMI.hmiStatus.xM1_Extended := fbPosM1.Sts.AtExt;
GVL_HMI.hmiStatus.xM2_Up       := fbStopM2.Sts.IsUp;
GVL_HMI.hmiStatus.xM3_Up       := fbStopM3.Sts.IsUp;
GVL_HMI.hmiStatus.xM4_Up       := fbStopM4.Sts.IsUp;
GVL_HMI.hmiStatus.xM5_Up       := fbPosM5.Sts.IsUp;
GVL_HMI.hmiStatus.xM6_Up       := fbPosM6.Sts.IsUp;
GVL_HMI.hmiStatus.xM7_Extended := fbPosM7.Sts.AtExt;
GVL_HMI.hmiStatus.xM8_Extended := fbPosM8.Sts.AtExt;

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

// Robot
GVL_HMI.hmiStatus.xRobotAutoMode := GVL_Robot.robotIn.sts_auto_mode;
GVL_HMI.hmiStatus.xRobotReady    := GVL_Robot.robotIn.sts_system_ready;
GVL_HMI.hmiStatus.xRobotRunning  := GVL_Robot.robotIn.sts_prg_running;
GVL_HMI.hmiStatus.xRobotFault    := GVL_Robot.robotIn.sts_fault;
GVL_HMI.hmiStatus.xRobotHome     := GVL_Robot.robotIn.sts_in_home_pos;
GVL_HMI.hmiStatus.xRobotCommOk   := fbModbusComm.Outp.stStatus.xRobotCommOk;
GVL_HMI.hmiStatus.xVfdCommOk     := elevStat.xVfdCommOk;

// Stany sekwencerów
GVL_HMI.hmiStatus.uiTraySeqState := fbTraySeq.Sts.State;
GVL_HMI.hmiStatus.uiBoxSeqState  := fbBoxSeq.Sts.State;
GVL_HMI.hmiStatus.uiTopFlowState := fbTopFlow.Sts.State;
GVL_HMI.hmiStatus.uiBottomState  := fbBottom567.Sts.State;

GVL_HMI.hmiStatus.uiTraysDone  := fbTraySeq.Sts.TrayCount;
GVL_HMI.hmiStatus.uiStacksDone := fbTraySeq.Sts.StackCount;
GVL_HMI.hmiStatus.uiBoxesDone  := fbBoxSeq.Sts.BoxCount;

PRG_IO_Write();
