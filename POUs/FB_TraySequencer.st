(* ============================================================
   FB_TraySequencer — Sekwencer produkcji tacek (tryb AUTO)
   Koordynuje: TopFlowManager, Elevator, BottomAccumulator,
   pozycjonery M5/M6, oraz handshake z robotem FANUC.
   ============================================================ *)

{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_TraySeqFault :
(
    NONE := 0,
    ROBOT_NOT_READY := 10,
    ELEVATOR_FAULT := 20,
    TOP_FLOW_FAULT := 30,
    BOTTOM_FAULT := 40,
    POSITIONER_TIMEOUT := 50,
    ROBOT_TIMEOUT := 60,
    P4_NOT_DETECTED := 65,
    DISCHARGE_TIMEOUT := 70,
    STARTUP_P4_OCCUPIED := 75
);
END_TYPE

{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_TraySeqState :
(
    DISABLED        := 0,
    IDLE            := 10,
    PAUSED          := 15,

    (* --- Faza: oczekiwanie na stos gotowy do pobrania przez robota --- *)
    // TopFlowManager dostarcza stos do P3, wysuwa M5 (bramkę), cofa M5, podnosi M4
    // TraySeq czeka na sygnał StackReadyAtP3 z TopFlowManagera
    WAIT_STACK_READY := 20,

    (* --- Faza: paletyzacja --- *)
    SIGNAL_ROBOT    := 70,    // sygnalizuj robotowi: stack_ready + elevator_ready
    WAIT_TRAY_DONE  := 80,    // czekaj na sts_pallet_finished (robot położył tackę)
    CHECK_P4_OCCUPIED := 82,  // po sygnale robota potwierdz czujnik P4 przed M6
    POS_M6_CYCLE    := 85,    // wysuń M6, cofnij M6 (pozycjonowanie tacki na windzie)
    ELEV_TO_EDGE    := 90,    // winda w dół do krawędzi pojemnika (ind_container_in_pos_4 OFF)

    (* --- Faza: rozładunek --- *)
    RETRACT_POS     := 110,   // powiadom TopFlowManager: stos zużyty (TopFlow opuszcza M4)
    ELEV_TO_BOTTOM  := 120,   // winda jedzie na dół
    DISCHARGE       := 130,   // uruchom elev_out + bottom_conv (transfer na dolny transporter)
    WAIT_ELEV_EMPTY := 140,   // rozladunek P4->P5 potwierdzony przez BottomAccumulator
    ELEV_RETURN_TOP := 150,   // winda wraca na górę

    FAULT           := 900
);
END_TYPE

TYPE ST_TraySeqCfg :
STRUCT
    uiTraysInStack     : UINT := 8;     // ilość tacek w stosie (konfigurowalna)
    tPositionerTimeout : TIME := T#3s;  // timeout pozycjonerów (M4/M5/M6)
    tRobotAckTimeout   : TIME := T#120s; // timeout oczekiwania na tackę od robota
    tP4ConfirmTimeout  : TIME := T#2s;   // timeout potwierdzenia P4 po sygnale robota
    tDischargeTimeout  : TIME := T#15s;  // timeout rozładunku windy
    tElevReturnTimeout : TIME := T#30s;  // timeout powrotu windy na górę
END_STRUCT
END_TYPE

TYPE ST_TraySeqCmd :
STRUCT
    StartAuto      : BOOL;  // impuls startu trybu AUTO
    ResumeAuto     : BOOL;  // poziom: wznowienie po przerwie/fault bez zerowania licznikow
    PauseAuto      : BOOL;  // pauza AUTO z mozliwoscia wznowienia
    AbortAuto      : BOOL;  // abort AUTO do DISABLED
    SafetyOK       : BOOL;
    ResetFault     : BOOL;
END_STRUCT
END_TYPE

TYPE ST_TraySeqIn :
STRUCT
    (* --- Z TopFlowManager --- *)
    TopFlow_OccP3        : BOOL;  // stos na pozycji 3 (logiczna zajętość)
    TopFlow_StackReadyAtP3 : BOOL; // P3 zajęte + M4 góra + M5 cofnięte — gotowe dla robota
    TopFlow_Busy         : BOOL;
    TopFlow_Fault        : BOOL;

    (* --- Z Elevator --- *)
    Elev_AtTop           : BOOL;  // winda w pozycji górnej
    Elev_AtBottom        : BOOL;
    Elev_AtTarget        : BOOL;
    Elev_Busy            : BOOL;
    Elev_CommandReady    : BOOL;
    Elev_Fault           : BOOL;

    (* --- Z BottomAccumulator --- *)
    Bottom_CanAccept     : BOOL;
    Bottom_Busy          : BOOL;
    Bottom_Fault         : BOOL;
    Bottom_DischargeDonePulse : BOOL;

    (* --- Czujniki windowe --- *)
    ind_container_in_pos_4 : BOOL;  // pojemnik na windzie

    (* --- Pozycjoner M6 (feedback z FB_StopperPair) --- *)
    M6_IsUp   : BOOL;
    M6_IsDown : BOOL;

    (* --- Robot (z GVL_Robot.robotIn) --- *)
    Robot_SystemReady    : BOOL;
    Robot_PrgRunning     : BOOL;
    Robot_InHome         : BOOL;
    Robot_AutoMode       : BOOL;
    Robot_Fault          : BOOL;
    Robot_PalletFinished : BOOL;  // impuls: tacka ułożona
    Robot_StackFinished  : BOOL;  // poziom: cały stos ukończony, aktywny do ACK
    Robot_CmdAck         : BOOL;
END_STRUCT
END_TYPE

TYPE ST_TraySeqOut :
STRUCT
    (* --- Do TopFlowManager --- *)
    TopFlow_Enable           : BOOL;
    TopFlow_Elev_RequestFeed : BOOL;  // (tylko tryb kuwet) priorytet karmienia windy
    TopFlow_Elev_CanAccept   : BOOL;  // (tylko tryb kuwet) winda gotowa na pojemnik
    TopFlow_StackConsumed    : BOOL;  // stos pobrany przez robota — TopFlow zwalnia P3/M4

    (* --- Do Elevator --- *)
    Elev_AutoGo            : BOOL;
    Elev_AutoTarget        : E_ElevatorTarget;  // typ enumów celów windy
    Elev_Stop              : BOOL;

    (* --- Do BottomAccumulator --- *)
    Bottom_Enable          : BOOL;
    Bottom_DischargeReq    : BOOL;

    (* --- Do pozycjonera M6 --- *)
    M6_Extend   : BOOL;  // pozycjoner tacek winda

    (* --- Do robota (GVL_Robot.robotOut) --- *)
    Robot_TrayProduction   : BOOL;
    Robot_StackReady       : BOOL;
    Robot_ElevatorReady    : BOOL;
    Robot_AckStackFinished : BOOL;

    (* --- Status --- *)
    AutoRunning : BOOL;
END_STRUCT
END_TYPE

TYPE ST_TraySeqStatus :
STRUCT
    State         : E_TraySeqState;
    TrayCount     : UINT;   // ile tacek ułożono w bieżącym stosie
    StackCount    : UINT;   // ile stosów ukończono od startu
    Busy          : BOOL;
END_STRUCT
END_TYPE

TYPE ST_TraySeqDiag :
STRUCT
    Fault     : BOOL;
    FaultCode : E_TraySeqFault;
    FaultText : STRING[120];
END_STRUCT
END_TYPE


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
