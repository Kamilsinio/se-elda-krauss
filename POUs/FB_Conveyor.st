(* ============================================================
   FB_Conveyor — Transporter dwukierunkowy z blokadą programową
   Blokada jednoczesnego ruchu w dwóch kierunkach + konfigurowalny
   czas zwłoki przy zmianie kierunku (tReversalDelay).
   ============================================================ *)

{attribute 'qualified_only'}
{attribute 'strict'} 
TYPE E_ConveyorFault :
(
    NONE := 0,
    SIMULTANEOUS_CMD := 10,   // jednoczesna komenda FWD+BWD
    REVERSAL_BLOCKED := 20    // próba zmiany kierunku przed upływem zwłoki
);
END_TYPE

{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_ConveyorState :
(
    IDLE      := 0,
    RUN_FWD   := 10,
    RUN_BWD   := 20,
    DELAY_FWD := 30,  // czekanie na zwłokę przed startem FWD (po BWD)
    DELAY_BWD := 40,  // czekanie na zwłokę przed startem BWD (po FWD)
    FAULT     := 900
);
END_TYPE

TYPE ST_ConveyorCfg :
STRUCT
    tReversalDelay : TIME := T#500ms;  // czas zwłoki po zatrzymaniu przed zmianą kierunku
END_STRUCT
END_TYPE

TYPE ST_ConveyorCmd :
STRUCT
    RunFwd     : BOOL;  // komenda: jedź "do przodu" (kierunek normalny)
    RunBwd     : BOOL;  // komenda: jedź "do tyłu"
    ResetFault : BOOL;
END_STRUCT
END_TYPE

TYPE ST_ConveyorIn :
STRUCT
    SafetyOK : BOOL;
    Enable   : BOOL;
END_STRUCT
END_TYPE

TYPE ST_ConveyorOut :
STRUCT
    Q_Fwd : BOOL;  // wyjście na stycznik kierunku "do przodu"
    Q_Bwd : BOOL;  // wyjście na stycznik kierunku "do tyłu"
END_STRUCT
END_TYPE

TYPE ST_ConveyorStatus :
STRUCT
    State      : E_ConveyorState;
    Running    : BOOL;
    Direction  : INT;  // 0=stop, 1=fwd, -1=bwd
END_STRUCT
END_TYPE

TYPE ST_ConveyorDiag :
STRUCT
    Fault : BOOL;
    Code  : E_ConveyorFault;
    Text  : STRING[120];
END_STRUCT
END_TYPE


FUNCTION_BLOCK FB_Conveyor
VAR_INPUT
    Cfg : ST_ConveyorCfg;
    Cmd : ST_ConveyorCmd;
    Inp : ST_ConveyorIn;
END_VAR
VAR_OUTPUT
    Outp : ST_ConveyorOut;
    Sts  : ST_ConveyorStatus;
    Diag : ST_ConveyorDiag;
END_VAR
VAR
    tReversal : TON;
    lastDir   : INT;  // ostatni kierunek przed zatrzymaniem: 1=fwd, -1=bwd, 0=brak
END_VAR


// --- Reset błędu ---
IF Cmd.ResetFault THEN
    Diag.Fault := FALSE;
    Diag.Code := E_ConveyorFault.NONE;
    Diag.Text := '';
    IF Sts.State = E_ConveyorState.FAULT THEN
        Sts.State := E_ConveyorState.IDLE;
    END_IF;
END_IF;

// --- Blokada jednoczesnej komendy FWD+BWD ---
IF Cmd.RunFwd AND Cmd.RunBwd AND (NOT Diag.Fault) THEN
    Diag.Fault := TRUE;
    Diag.Code := E_ConveyorFault.SIMULTANEOUS_CMD;
    Diag.Text := 'Conveyor: jednoczesna komenda FWD i BWD.';
    Sts.State := E_ConveyorState.FAULT;
END_IF;

// --- Brak enable / safety -> natychmiast stop ---
IF (NOT Inp.Enable) OR (NOT Inp.SafetyOK) OR Diag.Fault THEN
    Outp.Q_Fwd := FALSE;
    Outp.Q_Bwd := FALSE;
    Sts.Running := FALSE;
    Sts.Direction := 0;

    IF Diag.Fault THEN
        Sts.State := E_ConveyorState.FAULT;
    ELSIF Sts.State <> E_ConveyorState.IDLE THEN
        Sts.State := E_ConveyorState.IDLE;
    END_IF;

    RETURN;
END_IF;

// --- Automat stanów ---
CASE Sts.State OF

    E_ConveyorState.IDLE:
        Outp.Q_Fwd := FALSE;
        Outp.Q_Bwd := FALSE;
        Sts.Running := FALSE;
        Sts.Direction := 0;

        IF Cmd.RunFwd AND (NOT Cmd.RunBwd) THEN
            // zmiana kierunku? (poprzednio jechaliśmy BWD)
            IF lastDir = -1 THEN
                tReversal(IN := FALSE); // reset
                Sts.State := E_ConveyorState.DELAY_FWD;
            ELSE
                Sts.State := E_ConveyorState.RUN_FWD;
            END_IF;

        ELSIF Cmd.RunBwd AND (NOT Cmd.RunFwd) THEN
            IF lastDir = 1 THEN
                tReversal(IN := FALSE);
                Sts.State := E_ConveyorState.DELAY_BWD;
            ELSE
                Sts.State := E_ConveyorState.RUN_BWD;
            END_IF;
        END_IF;

    E_ConveyorState.RUN_FWD:
        Outp.Q_Fwd := TRUE;
        Outp.Q_Bwd := FALSE;
        Sts.Running := TRUE;
        Sts.Direction := 1;
        lastDir := 1;

        IF NOT Cmd.RunFwd THEN
            Outp.Q_Fwd := FALSE;
            Sts.State := E_ConveyorState.IDLE;
        END_IF;

    E_ConveyorState.RUN_BWD:
        Outp.Q_Fwd := FALSE;
        Outp.Q_Bwd := TRUE;
        Sts.Running := TRUE;
        Sts.Direction := -1;
        lastDir := -1;

        IF NOT Cmd.RunBwd THEN
            Outp.Q_Bwd := FALSE;
            Sts.State := E_ConveyorState.IDLE;
        END_IF;

    E_ConveyorState.DELAY_FWD:
        // czekaj na upływ zwłoki przed uruchomieniem w kierunku FWD
        Outp.Q_Fwd := FALSE;
        Outp.Q_Bwd := FALSE;
        Sts.Running := FALSE;
        Sts.Direction := 0;

        tReversal(IN := TRUE, PT := Cfg.tReversalDelay);

        IF NOT Cmd.RunFwd THEN
            // operator zwolnił komendę - wracamy do IDLE
            tReversal(IN := FALSE);
            Sts.State := E_ConveyorState.IDLE;
        ELSIF tReversal.Q THEN
            tReversal(IN := FALSE);
            Sts.State := E_ConveyorState.RUN_FWD;
        END_IF;

    E_ConveyorState.DELAY_BWD:
        Outp.Q_Fwd := FALSE;
        Outp.Q_Bwd := FALSE;
        Sts.Running := FALSE;
        Sts.Direction := 0;

        tReversal(IN := TRUE, PT := Cfg.tReversalDelay);

        IF NOT Cmd.RunBwd THEN
            tReversal(IN := FALSE);
            Sts.State := E_ConveyorState.IDLE;
        ELSIF tReversal.Q THEN
            tReversal(IN := FALSE);
            Sts.State := E_ConveyorState.RUN_BWD;
        END_IF;

    E_ConveyorState.FAULT:
        Outp.Q_Fwd := FALSE;
        Outp.Q_Bwd := FALSE;
        Sts.Running := FALSE;
        Sts.Direction := 0;

END_CASE;
