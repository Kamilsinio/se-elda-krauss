(* ============================================================
   FB_BoxSequencer — Sekwencer produkcji kuwet (tryb AUTO)
   Koordynuje: TopFlowManager, Elevator, BottomAccumulator,
   pozycjoner M7, oraz handshake z robotem FANUC.
   
   Różnice vs TraySequencer:
   - Kuweta jedzie od razu na windę (P1 -> P4 lub P3 -> P4)
   - Pozycjonowanie M7 (nie M5/M6)
   - Brak stosu — 1 kuweta = 1 cykl paletyzacji
   - Po paletyzacji winda zjeżdża, rozładunek, winda wraca
   ============================================================ *)

{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_BoxSeqFault :
(
    NONE := 0,
    ROBOT_NOT_READY := 10,
    ELEVATOR_FAULT := 20,
    TOP_FLOW_FAULT := 30,
    BOTTOM_FAULT := 40,
    POSITIONER_TIMEOUT := 50,
    ROBOT_TIMEOUT := 60,
    DISCHARGE_TIMEOUT := 70,
    STARTUP_P4_OCCUPIED := 75,
    TRANSFER_TIMEOUT := 80
);
END_TYPE

{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_BoxSeqState :
(
    DISABLED        := 0,
    IDLE            := 10,
    PAUSED          := 15,

    (* --- Faza: kuweta na windę --- *)
    REQUEST_ELEVATOR_FEED := 20, // zadaj TopFlowManagerowi podanie kuwety na P4
    FEED_ELEVATOR   := 30,    // transfer z top na windę (dwa transportery jednocześnie)
    POS_M7_FWD      := 40,    // wysuń pozycjoner kuwet M7

    (* --- Faza: bazowanie windy + paletyzacja --- *)
    ELEV_TO_EDGE    := 50,    // winda w dół do krawędzi (ind_container_in_pos_4 OFF)
    SIGNAL_ROBOT    := 60,    // sygnalizuj robotowi
    WAIT_PALLET_DONE := 70,   // czekaj na zakończenie paletyzacji

    (* --- Faza: rozładunek --- *)
    RETRACT_M7      := 80,    // cofnij M7
    ELEV_TO_BOTTOM  := 90,    // winda na dół
    DISCHARGE       := 100,   // elev_out + bottom jednocześnie
    WAIT_ELEV_EMPTY := 110,   // rozladunek P4->P5 potwierdzony przez BottomAccumulator
    ELEV_RETURN_TOP := 120,   // winda wraca na górę

    FAULT           := 900
);
END_TYPE

TYPE ST_BoxSeqCfg :
STRUCT
    tPositionerTimeout : TIME := T#3s;
    tRobotAckTimeout   : TIME := T#180s;  // kuweta ma więcej produktów niż tacka
    tDischargeTimeout  : TIME := T#15s;
    tTransferTimeout   : TIME := T#12s;   // timeout transferu top->elev razem ze stabilnym P4
    tElevReturnTimeout : TIME := T#30s;
END_STRUCT
END_TYPE

TYPE ST_BoxSeqCmd :
STRUCT
    StartAuto      : BOOL;
    ResumeAuto     : BOOL;  // poziom: wznowienie po przerwie/fault bez zerowania licznika
    PauseAuto      : BOOL;  // pauza AUTO z mozliwoscia wznowienia
    AbortAuto      : BOOL;  // abort AUTO do DISABLED
    SafetyOK       : BOOL;
    ResetFault     : BOOL;
END_STRUCT
END_TYPE

TYPE ST_BoxSeqIn :
STRUCT
    (* --- Z TopFlowManager --- *)
    TopFlow_Busy         : BOOL;
    TopFlow_Fault        : BOOL;
    TopFlow_ElevDeliveredAtP4 : BOOL; // TopFlow potwierdzil stabilny transfer na P4

    (* --- Z Elevator --- *)
    Elev_AtTop           : BOOL;
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

    (* --- Czujniki --- *)
    ind_container_in_pos_4 : BOOL;

    (* --- Pozycjoner M7 (z FB_StopperPair) --- *)
    M7_AtExt  : BOOL;
    M7_AtRet  : BOOL;

    (* --- Robot --- *)
    Robot_SystemReady    : BOOL;
    Robot_PrgRunning     : BOOL;
    Robot_AutoMode       : BOOL;
    Robot_Fault          : BOOL;
    Robot_StackFinished  : BOOL;  // dla kuwet = "kuweta zapełniona"
    Robot_CmdAck         : BOOL;
    Robot_BoxProgress    : BOOL;  // impuls po odlozeniu kompletu detali
END_STRUCT
END_TYPE

TYPE ST_BoxSeqOut :
STRUCT
    (* --- Do TopFlowManager --- *)
    TopFlow_Enable           : BOOL;
    TopFlow_Elev_RequestFeed : BOOL;
    TopFlow_Elev_CanAccept   : BOOL;

    (* --- Do Elevator --- *)
    Elev_AutoGo            : BOOL;
    Elev_AutoTarget        : E_ElevatorTarget;  // typ enumów celów windy
    Elev_Stop              : BOOL;

    (* --- Do BottomAccumulator --- *)
    Bottom_Enable          : BOOL;
    Bottom_DischargeReq    : BOOL;

    (* --- Pozycjoner M7 --- *)
    M7_Extend              : BOOL;

    (* --- Robot --- *)
    Robot_BoxProduction     : BOOL;
    Robot_StackReady        : BOOL;
    Robot_ElevatorReady     : BOOL;
    Robot_AckStackFinished  : BOOL;

    AutoRunning            : BOOL;
END_STRUCT
END_TYPE

TYPE ST_BoxSeqStatus :
STRUCT
    State      : E_BoxSeqState;
    BoxCount   : UINT;
    Busy       : BOOL;
END_STRUCT
END_TYPE

TYPE ST_BoxSeqDiag :
STRUCT
    Fault     : BOOL;
    FaultCode : E_BoxSeqFault;
    FaultText : STRING[120];
END_STRUCT
END_TYPE


FUNCTION_BLOCK FB_BoxSequencer
VAR_INPUT
    Cfg : ST_BoxSeqCfg;
    Cmd : ST_BoxSeqCmd;
    Inp : ST_BoxSeqIn;
END_VAR
VAR_OUTPUT
    Outp : ST_BoxSeqOut;
    Sts  : ST_BoxSeqStatus;
    Diag : ST_BoxSeqDiag;
END_VAR
VAR
    rtStart          : R_TRIG;
    rtResetFault     : R_TRIG;
    rtBoxProgress    : R_TRIG;
    tTimeout         : TON;
    xAckStackFinished : BOOL;
    eResumeState     : E_BoxSeqState;
END_VAR


// --- Zbocza ---
rtStart(CLK := Cmd.StartAuto);
rtResetFault(CLK := Cmd.ResetFault);
rtBoxProgress(CLK := Inp.Robot_BoxProgress);

// ACK pozostaje aktywne do czasu skasowania sygnalu StackFinished przez robota.
IF xAckStackFinished AND (NOT Inp.Robot_StackFinished) THEN
    xAckStackFinished := FALSE;
END_IF;

// --- Reset ---
IF rtResetFault.Q THEN
    Diag.Fault := FALSE;
    Diag.FaultCode := E_BoxSeqFault.NONE;
    Diag.FaultText := '';
    tTimeout(IN := FALSE);
    IF Sts.State = E_BoxSeqState.FAULT THEN
        IF (eResumeState <> E_BoxSeqState.DISABLED) AND
           (eResumeState <> E_BoxSeqState.PAUSED) AND
           (eResumeState <> E_BoxSeqState.FAULT) THEN
            Sts.State := E_BoxSeqState.PAUSED;
        ELSE
            Sts.State := E_BoxSeqState.DISABLED;
        END_IF;
    END_IF;
END_IF;

// --- Domyślne ---
Outp.Elev_AutoGo := FALSE;
Outp.Elev_Stop := FALSE;
Outp.Bottom_DischargeReq := FALSE;
Outp.TopFlow_Elev_RequestFeed := FALSE;
Outp.TopFlow_Elev_CanAccept := FALSE;
Outp.M7_Extend := FALSE;
Outp.Robot_StackReady := FALSE;
Outp.Robot_ElevatorReady := FALSE;
Outp.Robot_AckStackFinished := xAckStackFinished;
Outp.Robot_BoxProduction := (Sts.State <> E_BoxSeqState.DISABLED) AND
                            (Sts.State <> E_BoxSeqState.PAUSED) AND
                            (Sts.State <> E_BoxSeqState.FAULT);
Outp.TopFlow_Enable := Outp.Robot_BoxProduction;
Outp.Bottom_Enable := Outp.Robot_BoxProduction;
Outp.AutoRunning := Outp.Robot_BoxProduction;

// --- Safety ---
IF NOT Cmd.SafetyOK THEN
    Outp.Elev_Stop := TRUE;
    Outp.AutoRunning := Outp.Robot_BoxProduction;
    RETURN;
END_IF;

// --- Propagacja faultów ---
IF (NOT Diag.Fault) THEN
    IF Inp.Elev_Fault THEN
        Diag.Fault := TRUE;
        Diag.FaultCode := E_BoxSeqFault.ELEVATOR_FAULT;
        Diag.FaultText := 'BoxSeq: błąd windy.';
        eResumeState := Sts.State;
        Sts.State := E_BoxSeqState.FAULT;
    ELSIF Inp.TopFlow_Fault THEN
        Diag.Fault := TRUE;
        Diag.FaultCode := E_BoxSeqFault.TOP_FLOW_FAULT;
        Diag.FaultText := 'BoxSeq: błąd TopFlowManager.';
        eResumeState := Sts.State;
        Sts.State := E_BoxSeqState.FAULT;
    ELSIF Inp.Bottom_Fault THEN
        Diag.Fault := TRUE;
        Diag.FaultCode := E_BoxSeqFault.BOTTOM_FAULT;
        Diag.FaultText := 'BoxSeq: błąd BottomAccumulator.';
        eResumeState := Sts.State;
        Sts.State := E_BoxSeqState.FAULT;
    END_IF;
END_IF;

IF Cmd.AbortAuto THEN
    tTimeout(IN := FALSE);
    eResumeState := E_BoxSeqState.DISABLED;
    Sts.State := E_BoxSeqState.DISABLED;
END_IF;

IF Cmd.PauseAuto AND (NOT Diag.Fault) AND
   (Sts.State <> E_BoxSeqState.DISABLED) AND
   (Sts.State <> E_BoxSeqState.PAUSED) AND
   (Sts.State <> E_BoxSeqState.FAULT) THEN
    tTimeout(IN := FALSE);
    eResumeState := Sts.State;
    Sts.State := E_BoxSeqState.PAUSED;
END_IF;


// --- Automat stanów ---
CASE Sts.State OF

    // =============================================
    E_BoxSeqState.DISABLED:
        Outp.AutoRunning := FALSE;
        Outp.TopFlow_Enable := FALSE;
        Outp.Bottom_Enable := FALSE;
        Outp.Robot_BoxProduction := FALSE;
        Sts.Busy := FALSE;

        IF (NOT Cmd.AbortAuto) AND rtStart.Q THEN
            Sts.BoxCount := 0;
            eResumeState := E_BoxSeqState.DISABLED;
            tTimeout(IN := FALSE);

            IF Inp.ind_container_in_pos_4 THEN
                Diag.Fault := TRUE;
                Diag.FaultCode := E_BoxSeqFault.STARTUP_P4_OCCUPIED;
                Diag.FaultText := 'BoxSeq: start z zajętym P4.';
                Sts.State := E_BoxSeqState.FAULT;
            ELSIF Inp.Elev_AtTop THEN
                Sts.State := E_BoxSeqState.IDLE;
            ELSE
                Sts.State := E_BoxSeqState.ELEV_RETURN_TOP;
            END_IF;
        END_IF;

    // =============================================
    E_BoxSeqState.PAUSED:
        Outp.AutoRunning := FALSE;
        Outp.TopFlow_Enable := FALSE;
        Outp.Bottom_Enable := FALSE;
        Outp.Robot_BoxProduction := FALSE;
        Outp.Elev_Stop := TRUE;
        Sts.Busy := FALSE;

        IF (NOT Cmd.AbortAuto) AND (NOT Cmd.PauseAuto) AND Cmd.ResumeAuto THEN
            IF (eResumeState <> E_BoxSeqState.DISABLED) AND
               (eResumeState <> E_BoxSeqState.PAUSED) AND
               (eResumeState <> E_BoxSeqState.FAULT) THEN
                Sts.State := eResumeState;
            ELSE
                Sts.State := E_BoxSeqState.IDLE;
            END_IF;
        END_IF;

    // =============================================
    E_BoxSeqState.IDLE:
        Outp.AutoRunning := TRUE;
        Outp.TopFlow_Enable := TRUE;
        Outp.Bottom_Enable := TRUE;
        Sts.Busy := FALSE;

        // Wyzeruj wyjścia
        Outp.M7_Extend := FALSE;
        Outp.Robot_StackReady := FALSE;
        Outp.Robot_ElevatorReady := FALSE;

        IF Inp.TopFlow_ElevDeliveredAtP4 AND Inp.ind_container_in_pos_4 THEN
            // TopFlowManager potwierdzil stabilny transfer P1/P2/P3 -> P4.
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.POS_M7_FWD;
        ELSIF Inp.Elev_AtTop AND (NOT Inp.ind_container_in_pos_4) THEN
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.REQUEST_ELEVATOR_FEED;
        END_IF;

    // =============================================
    E_BoxSeqState.REQUEST_ELEVATOR_FEED:
        // Zadaj podanie kuwety, ale nie licz timeoutu dopoki TopFlow nie ruszy.
        Outp.AutoRunning := TRUE;
        Outp.TopFlow_Enable := TRUE;
        Outp.Bottom_Enable := TRUE;
        Outp.TopFlow_Elev_RequestFeed := TRUE;
        Outp.TopFlow_Elev_CanAccept := Inp.Elev_AtTop AND (NOT Inp.ind_container_in_pos_4);
        Sts.Busy := FALSE;

        IF Inp.TopFlow_ElevDeliveredAtP4 AND Inp.ind_container_in_pos_4 THEN
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.POS_M7_FWD;
        ELSIF NOT (Inp.Elev_AtTop AND (NOT Inp.ind_container_in_pos_4)) THEN
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.IDLE;
        ELSIF Inp.TopFlow_Busy THEN
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.FEED_ELEVATOR;
        END_IF;

    // =============================================
    E_BoxSeqState.FEED_ELEVATOR:
        // Kuweta z P3/P1 na P4: transferem steruje TopFlowManager
        Sts.Busy := TRUE;
        Outp.TopFlow_Elev_RequestFeed := TRUE;
        Outp.TopFlow_Elev_CanAccept := Inp.Elev_AtTop AND (NOT Inp.ind_container_in_pos_4);

        tTimeout(IN := TRUE, PT := Cfg.tTransferTimeout);

        IF Inp.TopFlow_ElevDeliveredAtP4 AND Inp.ind_container_in_pos_4 THEN
            Outp.TopFlow_Elev_RequestFeed := FALSE;
            Outp.TopFlow_Elev_CanAccept := FALSE;
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.POS_M7_FWD;
        ELSIF NOT Inp.TopFlow_Busy THEN
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.REQUEST_ELEVATOR_FEED;
        ELSIF tTimeout.Q THEN
            Outp.TopFlow_Elev_RequestFeed := FALSE;
            Outp.TopFlow_Elev_CanAccept := FALSE;
            Diag.Fault := TRUE;
            Diag.FaultCode := E_BoxSeqFault.TRANSFER_TIMEOUT;
            Diag.FaultText := 'BoxSeq: timeout transferu kuwety na windę.';
            eResumeState := Sts.State;
            Sts.State := E_BoxSeqState.FAULT;
        END_IF;

    // =============================================
    E_BoxSeqState.POS_M7_FWD:
        // Pozycjonowanie kuwety siłownikiem M7
        Outp.M7_Extend := TRUE;
        tTimeout(IN := NOT Inp.M7_AtExt, PT := Cfg.tPositionerTimeout);

        IF Inp.M7_AtExt THEN
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.ELEV_TO_EDGE;
        ELSIF tTimeout.Q THEN
            Diag.Fault := TRUE;
            Diag.FaultCode := E_BoxSeqFault.POSITIONER_TIMEOUT;
            Diag.FaultText := 'BoxSeq: timeout M7 (pozycjoner kuwet).';
            eResumeState := Sts.State;
            Sts.State := E_BoxSeqState.FAULT;
        END_IF;

    // =============================================
    E_BoxSeqState.ELEV_TO_EDGE:
        // Winda w dół aż ind_container_in_pos_4 zgaśnie
        Outp.M7_Extend := TRUE;
        
        Outp.Elev_AutoTarget := E_ElevatorTarget.posContainerEdge;
        Outp.Elev_AutoGo := TRUE;
        
        IF NOT Inp.ind_container_in_pos_4 AND NOT Inp.Elev_Busy THEN
            Outp.Elev_AutoGo := FALSE;
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.SIGNAL_ROBOT;
        END_IF;

    // =============================================
    E_BoxSeqState.SIGNAL_ROBOT:
        Outp.M7_Extend := TRUE;
        Outp.Robot_StackReady := TRUE;
        Outp.Robot_ElevatorReady := TRUE;
        tTimeout(IN := TRUE, PT := Cfg.tRobotAckTimeout);

        IF Inp.Robot_CmdAck AND Inp.Robot_PrgRunning AND
           Inp.Robot_AutoMode AND Inp.Robot_SystemReady THEN
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.WAIT_PALLET_DONE;
        END_IF;

        IF Inp.Robot_Fault AND (NOT Diag.Fault) THEN
            Diag.Fault := TRUE;
            Diag.FaultCode := E_BoxSeqFault.ROBOT_NOT_READY;
            Diag.FaultText := 'BoxSeq: robot w stanie błędu.';
            eResumeState := Sts.State;
            Sts.State := E_BoxSeqState.FAULT;
        ELSIF tTimeout.Q AND (NOT Diag.Fault) THEN
            Diag.Fault := TRUE;
            Diag.FaultCode := E_BoxSeqFault.ROBOT_NOT_READY;
            Diag.FaultText := 'BoxSeq: robot nie potwierdzil gotowosci/startu.';
            eResumeState := Sts.State;
            Sts.State := E_BoxSeqState.FAULT;
        END_IF;

    // =============================================
    E_BoxSeqState.WAIT_PALLET_DONE:
        // Czekaj aż robot skończy paletyzację kuwety
        Outp.M7_Extend := TRUE;
        Outp.Robot_StackReady := TRUE;
        Outp.Robot_ElevatorReady := TRUE;

        // Kazdy impuls DO23 rozpoczyna od nowa 180 s watchdog postepu robota.
        tTimeout(IN := NOT rtBoxProgress.Q, PT := Cfg.tRobotAckTimeout);

        IF Inp.Robot_StackFinished AND (NOT xAckStackFinished) THEN
            tTimeout(IN := FALSE);
            xAckStackFinished := TRUE;
            Outp.Robot_AckStackFinished := TRUE;
            Outp.Robot_StackReady := FALSE;
            Outp.Robot_ElevatorReady := FALSE;
            Sts.BoxCount := Sts.BoxCount + 1;
            Sts.State := E_BoxSeqState.RETRACT_M7;
        ELSIF tTimeout.Q THEN
            Diag.Fault := TRUE;
            Diag.FaultCode := E_BoxSeqFault.ROBOT_TIMEOUT;
            Diag.FaultText := 'BoxSeq: timeout oczekiwania na robota.';
            eResumeState := Sts.State;
            Sts.State := E_BoxSeqState.FAULT;
        END_IF;

    // =============================================
    E_BoxSeqState.RETRACT_M7:
        Outp.M7_Extend := FALSE;
        Outp.Robot_StackReady := FALSE;
        Outp.Robot_ElevatorReady := FALSE;

        tTimeout(IN := TRUE, PT := Cfg.tPositionerTimeout);

        IF Inp.M7_AtRet THEN
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.ELEV_TO_BOTTOM;
        ELSIF tTimeout.Q THEN
            Diag.Fault := TRUE;
            Diag.FaultCode := E_BoxSeqFault.POSITIONER_TIMEOUT;
            Diag.FaultText := 'BoxSeq: timeout cofania M7.';
            eResumeState := Sts.State;
            Sts.State := E_BoxSeqState.FAULT;
        END_IF;

    // =============================================
    E_BoxSeqState.ELEV_TO_BOTTOM:
        Outp.Elev_AutoGo := TRUE;
        Outp.Elev_AutoTarget := E_ElevatorTarget.posBottom;

        IF Inp.Elev_AtBottom THEN
            Outp.Elev_AutoGo := FALSE;
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.DISCHARGE;
        END_IF;

    // =============================================
    E_BoxSeqState.DISCHARGE:
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
            Sts.State := E_BoxSeqState.WAIT_ELEV_EMPTY;
        ELSIF tTimeout.Q THEN
            Outp.Bottom_DischargeReq := FALSE;
            Diag.Fault := TRUE;
            Diag.FaultCode := E_BoxSeqFault.DISCHARGE_TIMEOUT;
            Diag.FaultText := 'BoxSeq: timeout rozładunku windy.';
            eResumeState := Sts.State;
            Sts.State := E_BoxSeqState.FAULT;
        END_IF;

    // =============================================
    E_BoxSeqState.WAIT_ELEV_EMPTY:
        // Rozladunek potwierdzony przez BottomAccumulator.
        Sts.State := E_BoxSeqState.ELEV_RETURN_TOP;

    // =============================================
    E_BoxSeqState.ELEV_RETURN_TOP:
        Outp.Elev_AutoGo := Inp.Elev_CommandReady AND (NOT Inp.Elev_AtTop);
        Outp.Elev_AutoTarget := E_ElevatorTarget.posTop;

        tTimeout(IN := NOT Inp.Elev_AtTop, PT := Cfg.tElevReturnTimeout);

        IF Inp.Elev_AtTop THEN
            Outp.Elev_AutoGo := FALSE;
            tTimeout(IN := FALSE);
            Sts.State := E_BoxSeqState.IDLE;
        ELSIF tTimeout.Q THEN
            Diag.Fault := TRUE;
            Diag.FaultCode := E_BoxSeqFault.ELEVATOR_FAULT;
            Diag.FaultText := 'BoxSeq: timeout powrotu windy.';
            eResumeState := Sts.State;
            Sts.State := E_BoxSeqState.FAULT;
        END_IF;

    // =============================================
    E_BoxSeqState.FAULT:
        Outp.AutoRunning := FALSE;
        Outp.TopFlow_Enable := FALSE;
        Outp.Bottom_Enable := FALSE;
        Outp.Elev_Stop := TRUE;
        Outp.Robot_BoxProduction := FALSE;
        Outp.Robot_StackReady := FALSE;
        Outp.Robot_ElevatorReady := FALSE;
        Sts.Busy := FALSE;

END_CASE;

Sts.Busy := (Sts.State <> E_BoxSeqState.DISABLED) AND
            (Sts.State <> E_BoxSeqState.PAUSED) AND
            (Sts.State <> E_BoxSeqState.IDLE) AND
            (Sts.State <> E_BoxSeqState.REQUEST_ELEVATOR_FEED) AND
            (Sts.State <> E_BoxSeqState.FAULT);
