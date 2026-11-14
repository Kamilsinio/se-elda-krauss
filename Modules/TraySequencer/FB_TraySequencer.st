(* ============================================================
   FB_TraySequencer — Sekwencer produkcji tacek (tryb AUTO)
   Koordynuje: TopFlowManager, Elevator, BottomAccumulator,
   pozycjonery M5/M6, oraz handshake z robotem FANUC.
   ============================================================ *)










FUNCTION_BLOCK FB_TraySequencer
VAR_INPUT
    Cfg : ST_TraySeqCfg;
    Cmd : ST_TraySeqCmd;
    Inp : ST_TraySeqIn;
END_VAR
VAR_OUTPUT
    Outp : ST_TraySeqOut;
    Sts  : ST_TraySeqStatus;
    Diag : ST_TraySeqDiag;
END_VAR
VAR
    rtStart          : R_TRIG;
    rtPalletFinished : R_TRIG;

    tTimeout         : TON;

    xM6CyclePhase    : BOOL;  // FALSE=extend, TRUE=retract
    xAckStackFinished : BOOL;
    eResumeState     : E_TraySeqState;
END_VAR


// --- Zbocza ---
rtStart(CLK := Cmd.StartAuto);
rtPalletFinished(CLK := Inp.Robot_PalletFinished);

// ACK pozostaje aktywne do czasu skasowania sygnału StackFinished przez robota.
IF xAckStackFinished AND (NOT Inp.Robot_StackFinished) THEN
    xAckStackFinished := FALSE;
END_IF;

// --- Reset błędu ---
IF Cmd.ResetFault THEN
    Diag.Fault := FALSE;
    Diag.FaultCode := E_TraySeqFault.NONE;
    Diag.FaultText := '';
    tTimeout(IN := FALSE);
    IF Sts.State = E_TraySeqState.FAULT THEN
        IF (eResumeState <> E_TraySeqState.DISABLED) AND
           (eResumeState <> E_TraySeqState.PAUSED) AND
           (eResumeState <> E_TraySeqState.FAULT) THEN
            Sts.State := E_TraySeqState.PAUSED;
        ELSE
            Sts.State := E_TraySeqState.DISABLED;
        END_IF;
    END_IF;
END_IF;

// --- Domyślne wyjścia (nadpisywane w stanach) ---
Outp.Elev_AutoGo := FALSE;
Outp.Elev_Stop := FALSE;
Outp.Bottom_DischargeReq := FALSE;
Outp.M6_Extend := FALSE;
Outp.Robot_StackReady := FALSE;
Outp.Robot_ElevatorReady := FALSE;
Outp.Robot_AckStackFinished := xAckStackFinished;
Outp.Robot_TrayProduction := (Sts.State <> E_TraySeqState.DISABLED) AND
                             (Sts.State <> E_TraySeqState.PAUSED) AND
                             (Sts.State <> E_TraySeqState.FAULT);
Outp.TopFlow_Enable := Outp.Robot_TrayProduction;
Outp.Bottom_Enable := Outp.Robot_TrayProduction;
Outp.AutoRunning := Outp.Robot_TrayProduction;
// Reset impulsowych wyjść co skan (stany nadpisują je jawnie gdy potrzeba)
Outp.TopFlow_StackConsumed    := FALSE;
Outp.TopFlow_Elev_CanAccept   := FALSE;
Outp.TopFlow_Elev_RequestFeed := FALSE;

// --- Globalne permisywy ---
IF NOT Cmd.SafetyOK THEN
    Outp.Elev_Stop := TRUE;
    RETURN;
END_IF;

// --- Propagacja faultów z sub-FB ---
IF (NOT Diag.Fault) THEN
    IF Inp.Elev_Fault THEN
        Diag.Fault := TRUE;
        Diag.FaultCode := E_TraySeqFault.ELEVATOR_FAULT;
        Diag.FaultText := 'TraySeq: błąd windy.';
        eResumeState := Sts.State;
        Sts.State := E_TraySeqState.FAULT;
    ELSIF Inp.TopFlow_Fault THEN
        Diag.Fault := TRUE;
        Diag.FaultCode := E_TraySeqFault.TOP_FLOW_FAULT;
        Diag.FaultText := 'TraySeq: błąd TopFlowManager.';
        eResumeState := Sts.State;
        Sts.State := E_TraySeqState.FAULT;
    ELSIF Inp.Bottom_Fault THEN
        Diag.Fault := TRUE;
        Diag.FaultCode := E_TraySeqFault.BOTTOM_FAULT;
        Diag.FaultText := 'TraySeq: błąd BottomAccumulator.';
        eResumeState := Sts.State;
        Sts.State := E_TraySeqState.FAULT;
    END_IF;
END_IF;

IF Cmd.AbortAuto THEN
    tTimeout(IN := FALSE);
    eResumeState := E_TraySeqState.DISABLED;
    Sts.State := E_TraySeqState.DISABLED;
END_IF;

IF Cmd.PauseAuto AND (NOT Diag.Fault) AND
   (Sts.State <> E_TraySeqState.DISABLED) AND
   (Sts.State <> E_TraySeqState.PAUSED) AND
   (Sts.State <> E_TraySeqState.FAULT) THEN
    tTimeout(IN := FALSE);
    eResumeState := Sts.State;
    Sts.State := E_TraySeqState.PAUSED;
END_IF;


// --- Automat stanów ---
CASE Sts.State OF

    // =============================================
    E_TraySeqState.DISABLED:
        Outp.AutoRunning := FALSE;
        Outp.TopFlow_Enable := FALSE;
        Outp.Bottom_Enable := FALSE;
        Outp.Robot_TrayProduction := FALSE;
        Sts.Busy := FALSE;

        IF (NOT Cmd.AbortAuto) AND rtStart.Q THEN
            Sts.TrayCount := 0;
            Sts.StackCount := 0;
            eResumeState := E_TraySeqState.DISABLED;
            tTimeout(IN := FALSE);

            IF Inp.ind_container_in_pos_4 THEN
                Diag.Fault := TRUE;
                Diag.FaultCode := E_TraySeqFault.STARTUP_P4_OCCUPIED;
                Diag.FaultText := 'TraySeq: start z zajętym P4.';
                Sts.State := E_TraySeqState.FAULT;
            ELSIF Inp.Elev_AtTop THEN
                Sts.State := E_TraySeqState.IDLE;
            ELSE
                Sts.State := E_TraySeqState.ELEV_RETURN_TOP;
            END_IF;
        END_IF;

    // =============================================
    E_TraySeqState.PAUSED:
        Outp.AutoRunning := FALSE;
        Outp.TopFlow_Enable := FALSE;
        Outp.Bottom_Enable := FALSE;
        Outp.Robot_TrayProduction := FALSE;
        Outp.Elev_Stop := TRUE;
        Sts.Busy := FALSE;

        IF (NOT Cmd.AbortAuto) AND (NOT Cmd.PauseAuto) AND Cmd.ResumeAuto THEN
            IF (eResumeState <> E_TraySeqState.DISABLED) AND
               (eResumeState <> E_TraySeqState.PAUSED) AND
               (eResumeState <> E_TraySeqState.FAULT) THEN
                Sts.State := eResumeState;
            ELSE
                Sts.State := E_TraySeqState.IDLE;
            END_IF;
        END_IF;

    // =============================================
    E_TraySeqState.IDLE:
        Outp.AutoRunning := TRUE;
        Outp.TopFlow_Enable := TRUE;
        Outp.Bottom_Enable := TRUE;
        Sts.Busy := FALSE;

        IF Inp.Elev_AtTop AND (NOT Inp.ind_container_in_pos_4) THEN
            // Winda gotowa — czekaj na TopFlowManager, który sam dostarczy stos do P3
            Sts.State := E_TraySeqState.WAIT_STACK_READY;
        END_IF;

    // =============================================
    E_TraySeqState.WAIT_STACK_READY:
        // TopFlowManager obsługuje transport stosu do P3 (M5 bramka, M4 blokada)
        // TraySeq czeka na sygnał StackReadyAtP3: P3 zajęte + M4 góra + M5 cofnięte
        Sts.Busy := TRUE;
        Outp.TopFlow_Enable := TRUE;
        Outp.Bottom_Enable := TRUE;

        IF Inp.TopFlow_StackReadyAtP3 THEN
            Sts.State := E_TraySeqState.SIGNAL_ROBOT;
        END_IF;

    // =============================================
    E_TraySeqState.SIGNAL_ROBOT:
        // Daj robotowi sygnał: stos gotowy + winda gotowa
        // (M4 jest już w górze — TopFlowManager potwierdził StackReadyAtP3)
        Outp.Robot_StackReady := TRUE;
        Outp.Robot_ElevatorReady := TRUE;
        Sts.TrayCount := 0;
        tTimeout(IN := TRUE, PT := Cfg.tRobotAckTimeout);

        // Czekamy na potwierdzenie że robot zaczął
        IF Inp.Robot_PrgRunning AND Inp.Robot_AutoMode AND Inp.Robot_SystemReady THEN
            tTimeout(IN := FALSE);
            Sts.State := E_TraySeqState.WAIT_TRAY_DONE;
        END_IF;
        
(*      do testów
        // Sprawdź czy robot jest w stanie pracować
        IF Inp.Robot_Fault AND (NOT Diag.Fault) THEN
            Diag.Fault := TRUE;
            Diag.FaultCode := E_TraySeqFault.ROBOT_NOT_READY;
            Diag.FaultText := 'TraySeq: robot w stanie błędu.';
            eResumeState := Sts.State;
            Sts.State := E_TraySeqState.FAULT;
        ELSIF tTimeout.Q AND (NOT Diag.Fault) THEN
            Diag.Fault := TRUE;
            Diag.FaultCode := E_TraySeqFault.ROBOT_NOT_READY;
            Diag.FaultText := 'TraySeq: robot nie potwierdzil gotowosci/startu.';
            eResumeState := Sts.State;
            Sts.State := E_TraySeqState.FAULT;
        END_IF;
*)


    // =============================================
    E_TraySeqState.WAIT_TRAY_DONE:
        // Czekaj aż robot położy tackę (Robot_PalletFinished) lub skończy stos
        // M4 trzyma stos na P3 — zarządza tym TopFlowManager (OccP3=TRUE)
        Outp.M6_Extend := FALSE;  // M6 cofnięty — robot kładzie tackę
        Outp.Robot_StackReady := TRUE;
        Outp.Robot_ElevatorReady := TRUE;

        tTimeout(IN := TRUE, PT := Cfg.tRobotAckTimeout);

        IF Inp.Robot_StackFinished AND (NOT xAckStackFinished) THEN
            // Cały stos skończony — przejdź do rozładunku
            tTimeout(IN := FALSE);
            xAckStackFinished := TRUE;
            Outp.Robot_AckStackFinished := TRUE;
            Outp.Robot_StackReady := FALSE;
            Outp.Robot_ElevatorReady := FALSE;
            Sts.StackCount := Sts.StackCount + 1;
            Sts.State := E_TraySeqState.RETRACT_POS;

        ELSIF rtPalletFinished.Q THEN
            // Robot zglosil odlozenie tacki; najpierw potwierdz P4, dopiero potem M6.
            tTimeout(IN := FALSE);
            Sts.State := E_TraySeqState.CHECK_P4_OCCUPIED;

        ELSIF tTimeout.Q THEN
            Diag.Fault := TRUE;
            Diag.FaultCode := E_TraySeqFault.ROBOT_TIMEOUT;
            Diag.FaultText := 'TraySeq: timeout oczekiwania na robota.';
            eResumeState := Sts.State;
            Sts.State := E_TraySeqState.FAULT;
        END_IF;

    // =============================================
    E_TraySeqState.CHECK_P4_OCCUPIED:
        // Po sygnale robota czujnik P4 musi potwierdzic tacke przed startem M6.
        Outp.M6_Extend := FALSE;
        Outp.Robot_StackReady := TRUE;

        tTimeout(IN := NOT Inp.ind_container_in_pos_4, PT := Cfg.tP4ConfirmTimeout);

        IF Inp.ind_container_in_pos_4 THEN
            tTimeout(IN := FALSE);
            Sts.TrayCount := Sts.TrayCount + 1;
            xM6CyclePhase := FALSE;
            Sts.State := E_TraySeqState.POS_M6_CYCLE;
        ELSIF tTimeout.Q THEN
            Diag.Fault := TRUE;
            Diag.FaultCode := E_TraySeqFault.P4_NOT_DETECTED;
            Diag.FaultText := 'TraySeq: P4 not detected after robot tray placed.';
            eResumeState := Sts.State;
            Sts.State := E_TraySeqState.FAULT;
        END_IF;

    // =============================================
    E_TraySeqState.POS_M6_CYCLE:
        // Po ułożeniu tacki: wysuń M6 (pozycjonowanie), potem cofnij
        // M4 trzyma stos — zarządza tym TopFlowManager
        Outp.M6_Extend := FALSE;  // nadpisane niżej jeśli faza 1
        Outp.Robot_StackReady := TRUE;

        IF NOT xM6CyclePhase THEN
            // Faza 1: wysuń M6
            Outp.M6_Extend := TRUE;
            tTimeout(IN := NOT Inp.M6_IsUp, PT := Cfg.tPositionerTimeout);

            IF Inp.M6_IsUp THEN
                tTimeout(IN := FALSE);
                xM6CyclePhase := TRUE;  // przejdź do cofania
            ELSIF tTimeout.Q THEN
                Diag.Fault := TRUE;
                Diag.FaultCode := E_TraySeqFault.POSITIONER_TIMEOUT;
                Diag.FaultText := 'TraySeq: timeout M6 extend w cyklu.';
                eResumeState := Sts.State;
                Sts.State := E_TraySeqState.FAULT;
            END_IF;
        ELSE
            // Faza 2: cofnij M6
            Outp.M6_Extend := FALSE;
            tTimeout(IN := NOT Inp.M6_IsDown, PT := Cfg.tPositionerTimeout);

            IF Inp.M6_IsDown THEN
                tTimeout(IN := FALSE);
                // Teraz bazuj windę do krawędzi pojemnika
                Sts.State := E_TraySeqState.ELEV_TO_EDGE;
            ELSIF tTimeout.Q THEN
                Diag.Fault := TRUE;
                Diag.FaultCode := E_TraySeqFault.POSITIONER_TIMEOUT;
                Diag.FaultText := 'TraySeq: timeout M6 retract w cyklu.';
                eResumeState := Sts.State;
                Sts.State := E_TraySeqState.FAULT;
            END_IF;
        END_IF;

    // =============================================
    E_TraySeqState.ELEV_TO_EDGE:
        // Winda jedzie w dół aż ind_container_in_pos_4 zgaśnie
        // M4 trzyma stos — zarządza tym TopFlowManager
        Outp.Robot_StackReady := TRUE;

        // Wyślij komendę do windy: target = posContainerEdge (= 10)
        Outp.Elev_AutoGo := TRUE;
        Outp.Elev_AutoTarget := E_ElevatorTarget.posContainerEdge;

        IF (NOT Inp.ind_container_in_pos_4) AND (NOT Inp.Elev_Busy) THEN
            // Ruch do krawedzi zakonczony — daj robotowi pozwolenie na kolejna tacke.
            Outp.Elev_AutoGo := FALSE;
            tTimeout(IN := FALSE);
            Sts.State := E_TraySeqState.WAIT_TRAY_DONE;
        END_IF;

    // =============================================
    E_TraySeqState.RETRACT_POS:
        // Powiadom TopFlowManager: stos zużyty przez robota
        // TopFlowManager samodzielnie opuszcza M4 i zwalnia P3 dla kolejnego stosu
        Outp.TopFlow_StackConsumed := TRUE;
        Outp.M6_Extend := FALSE;
        Outp.Robot_StackReady := FALSE;
        Outp.Robot_ElevatorReady := FALSE;
        // Od razu przejdź do zjazdu windy — M4 jest opuszczane przez TopFlow asynchronicznie
        Sts.State := E_TraySeqState.ELEV_TO_BOTTOM;

    // =============================================
    E_TraySeqState.ELEV_TO_BOTTOM:
        // Winda jedzie na dół (posBottom)
        Outp.Elev_AutoGo := TRUE;
        Outp.Elev_AutoTarget := E_ElevatorTarget.posBottom;

        IF Inp.Elev_AtBottom THEN
            Outp.Elev_AutoGo := FALSE;
            tTimeout(IN := FALSE);
            Sts.State := E_TraySeqState.DISCHARGE;
        END_IF;

    // =============================================
    E_TraySeqState.DISCHARGE:
        // Zlec rozladunek P4->P5 do BottomAccumulator.
        IF Inp.Bottom_CanAccept THEN
            Outp.Bottom_DischargeReq := TRUE;
            tTimeout(IN := TRUE, PT := Cfg.tDischargeTimeout);
        ELSE
            Outp.Bottom_DischargeReq := FALSE;
            tTimeout(IN := FALSE);
        END_IF;

        IF Inp.Bottom_DischargeDonePulse THEN
            Outp.Bottom_DischargeReq := FALSE;
            tTimeout(IN := FALSE);
            Sts.State := E_TraySeqState.WAIT_ELEV_EMPTY;
        ELSIF tTimeout.Q THEN
            Outp.Bottom_DischargeReq := FALSE;
            Diag.Fault := TRUE;
            Diag.FaultCode := E_TraySeqFault.DISCHARGE_TIMEOUT;
            Diag.FaultText := 'TraySeq: timeout rozładunku windy.';
            eResumeState := Sts.State;
            Sts.State := E_TraySeqState.FAULT;
        END_IF;

    // =============================================
    E_TraySeqState.WAIT_ELEV_EMPTY:
        // Rozladunek potwierdzony przez BottomAccumulator.

        // Winda wraca na górę
        Sts.State := E_TraySeqState.ELEV_RETURN_TOP;

    // =============================================
    E_TraySeqState.ELEV_RETURN_TOP:
        // Winda jedzie na górę (posTop)
        Outp.Elev_AutoGo := Inp.Elev_CommandReady AND (NOT Inp.Elev_AtTop);
        Outp.Elev_AutoTarget := E_ElevatorTarget.posTop;

        tTimeout(IN := NOT Inp.Elev_AtTop, PT := Cfg.tElevReturnTimeout);

        IF Inp.Elev_AtTop THEN
            Outp.Elev_AutoGo := FALSE;
            tTimeout(IN := FALSE);
            // Wróć do IDLE — TopFlowManager w międzyczasie buforował kolejny stos
            Sts.State := E_TraySeqState.IDLE;
        ELSIF tTimeout.Q THEN
            Diag.Fault := TRUE;
            Diag.FaultCode := E_TraySeqFault.ELEVATOR_FAULT;
            Diag.FaultText := 'TraySeq: timeout powrotu windy na górę.';
            eResumeState := Sts.State;
            Sts.State := E_TraySeqState.FAULT;
        END_IF;

    // =============================================
    E_TraySeqState.FAULT:
        // Bezpieczne zatrzymanie
        Outp.AutoRunning := FALSE;
        Outp.TopFlow_Enable := FALSE;
        Outp.Bottom_Enable := FALSE;
        Outp.Elev_Stop := TRUE;
        Outp.Robot_TrayProduction := FALSE;
        Outp.Robot_StackReady := FALSE;
        Outp.Robot_ElevatorReady := FALSE;
        Sts.Busy := FALSE;

END_CASE;

// --- Busy ogólne ---
Sts.Busy := (Sts.State <> E_TraySeqState.DISABLED) AND
            (Sts.State <> E_TraySeqState.PAUSED) AND
            (Sts.State <> E_TraySeqState.IDLE) AND
            (Sts.State <> E_TraySeqState.WAIT_STACK_READY) AND
            (Sts.State <> E_TraySeqState.FAULT);
