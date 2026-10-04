{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_StopperFault :
(
    NONE := 0,
    SENSOR_CONTRADICTION := 10,
    TIMEOUT := 20
);
END_TYPE
TYPE ST_StopperPairCfg :
STRUCT
    tStable   : TIME := T#50ms;  // filtr/stabilizacja potwierdzeń
    tTimeout  : TIME := T#2s;    // timeout dojazdu
    HoldCoilInEndPos : BOOL := TRUE; // TRUE: trzyma cewkę w pozycji docelowej
END_STRUCT
END_TYPE
TYPE ST_StopperPairDiag :
STRUCT
    Fault : BOOL;
    Code  : E_StopperFault;
    Text  : STRING[100];
END_STRUCT
END_TYPE
TYPE ST_StopperPairIn :
STRUCT
    ind_1_fwd : BOOL;
    ind_2_fwd : BOOL;
    ind_1_bwd : BOOL;
    ind_2_bwd : BOOL;
END_STRUCT
END_TYPE
TYPE ST_StopperPairOut :
STRUCT
    Q_Fwd : BOOL;
    Q_Bwd : BOOL;
END_STRUCT
END_TYPE
TYPE ST_StopperPairStatus :
STRUCT
    IsUp   : BOOL; // oba fwd stabilne
    IsDown : BOOL; // oba bwd stabilne
    Busy   : BOOL;
END_STRUCT
END_TYPE

FUNCTION_BLOCK FB_StopperPair
VAR_INPUT
    Cfg : ST_StopperPairCfg;
    Enable : BOOL;
    HoldUp : BOOL;        // TRUE -> UP (FWD), FALSE -> DOWN (BWD)
    ResetFault : BOOL;
    Inp : ST_StopperPairIn;
END_VAR
VAR_OUTPUT
    Outp : ST_StopperPairOut;
    Sts  : ST_StopperPairStatus;
    Diag : ST_StopperPairDiag;
END_VAR
VAR
    // stabilizacja potwierdzeń
    tFwdStable : TON;
    tBwdStable : TON;
    fwdStable : BOOL;
    bwdStable : BOOL;

    // timeout ruchu
    tMoveTO : TON;

    contradiction : BOOL;
    targetReached : BOOL;
END_VAR

// reset błędu
IF ResetFault THEN
    Diag.Fault := FALSE;
    Diag.Code := E_StopperFault.NONE;
    Diag.Text := '';
END_IF;

IF NOT Enable OR Diag.Fault THEN
    Outp.Q_Fwd := FALSE;
    Outp.Q_Bwd := FALSE;
    Sts.Busy := FALSE;

    // statusy liczymy nadal (przydaje się do diagnostyki)
END_IF;

// 1) wykrywanie sprzeczności czujników (na każdej z 2 osi)
contradiction :=
    (Inp.ind_1_fwd AND Inp.ind_1_bwd) OR
    (Inp.ind_2_fwd AND Inp.ind_2_bwd);

// 2) stabilizacja: uznaj “UP” dopiero jak oba fwd są TRUE przez tStable, analogicznie dla DOWN
tFwdStable(IN := (Inp.ind_1_fwd AND Inp.ind_2_fwd) AND (NOT contradiction), PT := Cfg.tStable);
tBwdStable(IN := (Inp.ind_1_bwd AND Inp.ind_2_bwd) AND (NOT contradiction), PT := Cfg.tStable);

fwdStable := tFwdStable.Q;
bwdStable := tBwdStable.Q;

Sts.IsUp := fwdStable;
Sts.IsDown := bwdStable;

// 3) błąd sprzeczności
IF contradiction AND Enable AND (NOT Diag.Fault) THEN
    Diag.Fault := TRUE;
    Diag.Code := E_StopperFault.SENSOR_CONTRADICTION;
    Diag.Text := 'Stopper: sprzeczne czujniki FWD/BWD na jednym z siłowników.';
END_IF;

// 4) sterowanie ruchem
IF Enable AND (NOT Diag.Fault) THEN

    // cel osiągnięty?
    IF HoldUp THEN
        targetReached := Sts.IsUp;
    ELSE
        targetReached := Sts.IsDown;
    END_IF;

    // Busy gdy nie w celu
    Sts.Busy := NOT targetReached;

    // timeout liczony tylko gdy jedziemy i cel nie osiagniety
    tMoveTO(IN := Sts.Busy, PT := Cfg.tTimeout);

    IF tMoveTO.Q THEN
        Diag.Fault := TRUE;
        Diag.Code := E_StopperFault.TIMEOUT;
        Diag.Text := 'Stopper: timeout dojazdu do pozycji.';
    END_IF;

    // Wyjścia cewek:
    // - jeśli HoldCoilInEndPos=TRUE: trzymaj odpowiednią cewkę cały czas
    // - jeśli FALSE: zgaś cewki po osiągnięciu celu
    IF HoldUp THEN
        Outp.Q_Bwd := FALSE;
        IF Cfg.HoldCoilInEndPos THEN
            Outp.Q_Fwd := TRUE;
        ELSE
            Outp.Q_Fwd := NOT targetReached;
        END_IF;
    ELSE
        Outp.Q_Fwd := FALSE;
        IF Cfg.HoldCoilInEndPos THEN
            Outp.Q_Bwd := TRUE;
        ELSE
            Outp.Q_Bwd := NOT targetReached;
        END_IF;
    END_IF;

END_IF;
