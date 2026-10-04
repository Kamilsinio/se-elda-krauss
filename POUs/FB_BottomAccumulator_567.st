{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_Bottom567Fault :
(
    NONE := 0,
    FULL_QUEUE := 10,
    MOVE_TIMEOUT := 20
);
END_TYPE
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_Bottom567State :
(
    INIT := 0,
    IDLE := 10,
    PRECHECK := 20,
    RUN_STEP := 30,
    WAIT_STOP := 40,
    COMPLETE := 50,
    EMPTY_HOLD := 60,
    EMPTY_RESYNC := 70,
    FAULT := 900
);
END_TYPE
TYPE ST_Bottom567Cfg :
STRUCT
    tMotorStopDelay : TIME := T#300ms; // do korekty po testach
    tStepTimeout    : TIME := T#8s;    // timeout pojedynczego kroku
    tSensorStable   : TIME := T#80ms;  // stabilizacja przy STOP
END_STRUCT
END_TYPE
TYPE ST_Bottom567Cmd :
STRUCT
    EnableAuto : BOOL;
    SafetyOK   : BOOL;
    DischargeReq : BOOL; // żądanie „zrób krok bo winda chce oddać pojemnik”
    EmptyBottomHold : BOOL;
    ResetFault : BOOL;
END_STRUCT
END_TYPE
TYPE ST_Bottom567Diag :
STRUCT
    Fault : BOOL;
    Code  : E_Bottom567Fault;
    Text  : STRING[120];
END_STRUCT
END_TYPE
TYPE ST_Bottom567In :
STRUCT
    sPos5_raw : BOOL;
    sPos6_raw : BOOL;
    sPos7_raw : BOOL;
    sElevatorEmptied_raw : BOOL;
END_STRUCT
END_TYPE
TYPE ST_Bottom567Out :
STRUCT
    ConvRun : BOOL;
    ElevConv_RunBwd : BOOL;

    AlarmQueueFull : BOOL;   // do logiki lamp/buzzer
    StepDonePulse  : BOOL;   // 1 scan
    DischargeDonePulse : BOOL; // 1 scan, rozladunek P4->P5 zakonczony
END_STRUCT
END_TYPE
TYPE ST_Bottom567Status :
STRUCT
    State : E_Bottom567State;
    Busy  : BOOL;
    EmptyBottomActive : BOOL;

    Occ5 : BOOL;
    Occ6 : BOOL;
    Occ7 : BOOL;

    CanAcceptFromElev : BOOL; // = NOT Occ7 (i brak fault)
END_STRUCT
END_TYPE

FUNCTION_BLOCK FB_BottomAccumulator_567
VAR_INPUT
    Cfg : ST_Bottom567Cfg;
    Cmd : ST_Bottom567Cmd;
    Inp : ST_Bottom567In;
END_VAR
VAR_OUTPUT
    Outp : ST_Bottom567Out;
    Sts  : ST_Bottom567Status;
    Diag : ST_Bottom567Diag;
END_VAR
VAR
    autoPermissive : BOOL;
    activeStepPermissive : BOOL;
    emptyPermissive : BOOL;

    // stabilizacja tylko gdy taśma stoi
    t5 : TON; t6 : TON; t7 : TON;
    s5_stable : BOOL; s6_stable : BOOL; s7_stable : BOOL;

    // krok
    pos5WasOccupied : BOOL;
    seenPos5Off : BOOL;
    p5StepReached : BOOL;
    xStepMovementStarted : BOOL;

    tStepTO : TON;
    tStopDelay : TON;
    tResyncStable : TON;
    xResyncSampled : BOOL;
    resyncPos5 : BOOL;
    resyncPos6 : BOOL;
    resyncPos7 : BOOL;

    rDischarge : R_TRIG;
    ftElevatorEmptied : F_TRIG;
    xElevatorEmptiedSeen : BOOL;
END_VAR

autoPermissive := Cmd.EnableAuto AND Cmd.SafetyOK AND (NOT Diag.Fault);
activeStepPermissive := (Cmd.EnableAuto OR Cmd.EmptyBottomHold) AND
                        Cmd.SafetyOK AND (NOT Diag.Fault);
emptyPermissive := Cmd.EmptyBottomHold AND Cmd.SafetyOK AND (NOT Diag.Fault);
ftElevatorEmptied(CLK := Inp.sElevatorEmptied_raw);

IF Cmd.ResetFault THEN
    Diag.Fault := FALSE;
    Diag.Code := E_Bottom567Fault.NONE;
    Diag.Text := '';
    xElevatorEmptiedSeen := FALSE;
    seenPos5Off := FALSE;
    p5StepReached := FALSE;
    xStepMovementStarted := FALSE;
    tStepTO(IN := FALSE);
    tStopDelay(IN := FALSE);
    tResyncStable(IN := FALSE);
    xResyncSampled := FALSE;
    IF Sts.State = E_Bottom567State.FAULT THEN
        Sts.State := E_Bottom567State.INIT;
    END_IF;
END_IF;

// default
Outp.StepDonePulse := FALSE;
Outp.DischargeDonePulse := FALSE;
Sts.EmptyBottomActive := FALSE;
Sts.CanAcceptFromElev := FALSE;

// stabilizacja przy STOP
t5(IN := (NOT Outp.ConvRun) AND Inp.sPos5_raw, PT := Cfg.tSensorStable);
t6(IN := (NOT Outp.ConvRun) AND Inp.sPos6_raw, PT := Cfg.tSensorStable);
t7(IN := (NOT Outp.ConvRun) AND Inp.sPos7_raw, PT := Cfg.tSensorStable);

s5_stable := t5.Q;
s6_stable := t6.Q;
s7_stable := t7.Q;

// Po rozpoczęciu kroku obserwuj postęp także podczas zatrzymania i wybiegu.
IF (Sts.State = E_Bottom567State.RUN_STEP) AND xStepMovementStarted THEN
    IF ftElevatorEmptied.Q THEN
        xElevatorEmptiedSeen := TRUE;
    END_IF;

    IF pos5WasOccupied THEN
        IF NOT Inp.sPos5_raw THEN
            seenPos5Off := TRUE;
        END_IF;

        IF seenPos5Off AND Inp.sPos5_raw THEN
            p5StepReached := TRUE;
        END_IF;
    ELSIF Inp.sPos5_raw THEN
        p5StepReached := TRUE;
    END_IF;
END_IF;

IF NOT Cmd.SafetyOK THEN
    Outp.ConvRun := FALSE;
    Outp.ElevConv_RunBwd := FALSE;
    tStepTO(IN := FALSE);
    tStopDelay(IN := FALSE);
    tResyncStable(IN := FALSE);
    xResyncSampled := FALSE;
    rDischarge(CLK := FALSE);

    IF Sts.State = E_Bottom567State.EMPTY_HOLD THEN
        Sts.State := E_Bottom567State.EMPTY_RESYNC;
    END_IF;

    IF Sts.State = E_Bottom567State.EMPTY_RESYNC THEN
        Sts.Busy := TRUE;
    ELSE
        Sts.Busy := FALSE;
    END_IF;
    RETURN;
END_IF;

// Przy wyłączonym AUTO i podczas opróżniania chwilowego nie przechwytuj żądania rozładunku.
IF (NOT Cmd.EnableAuto) OR
   (Sts.State = E_Bottom567State.EMPTY_HOLD) OR
   (Sts.State = E_Bottom567State.EMPTY_RESYNC) THEN
    rDischarge(CLK := FALSE);
ELSE
    rDischarge(CLK := Cmd.DischargeReq);
END_IF;

CASE Sts.State OF

    E_Bottom567State.INIT:
        Outp.ConvRun := FALSE;
        Outp.ElevConv_RunBwd := FALSE;
        Sts.Busy := FALSE;
        xStepMovementStarted := FALSE;

        // seed zajętości z czujników (gdy stoi)
        Sts.Occ5 := s5_stable;
        Sts.Occ6 := s6_stable;
        Sts.Occ7 := s7_stable;
        Sts.State := E_Bottom567State.IDLE;

    E_Bottom567State.IDLE:
        Outp.ConvRun := FALSE;
        Outp.ElevConv_RunBwd := FALSE;
        Sts.Busy := FALSE;
        xStepMovementStarted := FALSE;

        // odśwież occupancy przy postoju
        Sts.Occ5 := s5_stable;
        Sts.Occ6 := s6_stable;
        Sts.Occ7 := s7_stable;

        Sts.CanAcceptFromElev := (NOT Sts.Occ7) AND (NOT Diag.Fault);

        Outp.AlarmQueueFull := Sts.Occ7; // “pos7 zajęta” -> alarm

        // Automatyczny transfer P4->P5 ma pierwszeństwo przed opróżnianiem chwilowym.
        IF autoPermissive AND rDischarge.Q THEN
            Sts.State := E_Bottom567State.PRECHECK;
        ELSIF emptyPermissive THEN
            tStopDelay(IN := FALSE);
            tResyncStable(IN := FALSE);
            xResyncSampled := FALSE;
            Sts.Busy := TRUE;
            Sts.CanAcceptFromElev := FALSE;
            Sts.State := E_Bottom567State.EMPTY_HOLD;
        END_IF;

    E_Bottom567State.PRECHECK:
        Outp.ConvRun := FALSE;
        Outp.ElevConv_RunBwd := FALSE;
        Sts.Busy := activeStepPermissive;

        IF activeStepPermissive THEN
            // pos7 zajęta -> nie możemy zrobić kroku
            IF Sts.Occ7 THEN
                Diag.Fault := TRUE;
                Diag.Code := E_Bottom567Fault.FULL_QUEUE;
                Diag.Text := 'Bottom457: pozycja 7 zajęta, brak miejsca na krok 4->5.';
                xStepMovementStarted := FALSE;
                Sts.State := E_Bottom567State.FAULT;
            ELSE
                pos5WasOccupied := Sts.Occ5;
                seenPos5Off := FALSE;
                p5StepReached := FALSE;
                xElevatorEmptiedSeen := FALSE;
                xStepMovementStarted := FALSE;
                Sts.State := E_Bottom567State.RUN_STEP;
            END_IF;
        END_IF;

    E_Bottom567State.RUN_STEP:
        Outp.ConvRun := FALSE;
        Outp.ElevConv_RunBwd := FALSE;
        Sts.Busy := activeStepPermissive;

        IF activeStepPermissive THEN
            xStepMovementStarted := TRUE;
            Outp.ConvRun := TRUE;
            Outp.ElevConv_RunBwd := TRUE;
            Outp.AlarmQueueFull := FALSE;

            tStepTO(IN := TRUE, PT := Cfg.tStepTimeout);

            IF p5StepReached AND xElevatorEmptiedSeen THEN
                Outp.ConvRun := FALSE;
                Outp.ElevConv_RunBwd := FALSE;
                tStepTO(IN := FALSE);
                Sts.State := E_Bottom567State.WAIT_STOP;
            END_IF;

            IF tStepTO.Q THEN
                Outp.ConvRun := FALSE;
                Outp.ElevConv_RunBwd := FALSE;
                Diag.Fault := TRUE;
                Diag.Code := E_Bottom567Fault.MOVE_TIMEOUT;
                Diag.Text := 'Bottom457: timeout kroku transportera.';
                xStepMovementStarted := FALSE;
                Sts.State := E_Bottom567State.FAULT;
            END_IF;
        ELSE
            tStepTO(IN := FALSE);
        END_IF;

    E_Bottom567State.WAIT_STOP:
        Outp.ConvRun := FALSE;
        Outp.ElevConv_RunBwd := FALSE;
        Sts.Busy := activeStepPermissive;

        IF activeStepPermissive THEN
            // zwłoka po stopie (dobierasz na obiekcie)
            tStopDelay(IN := TRUE, PT := Cfg.tMotorStopDelay);

            IF tStopDelay.Q THEN
                tStopDelay(IN := FALSE);

                // modelowe przesunięcie occupancy o 1 krok:
                // 6->7, 5->6, 4->5 (nowy zawsze pojawia się na 5)
                Sts.Occ7 := Sts.Occ6;
                Sts.Occ6 := Sts.Occ5;
                Sts.Occ5 := TRUE;

                Sts.State := E_Bottom567State.COMPLETE;
            END_IF;
        ELSE
            tStopDelay(IN := FALSE);
        END_IF;

    E_Bottom567State.COMPLETE:
        Outp.ConvRun := FALSE;
        Outp.ElevConv_RunBwd := FALSE;
        Sts.Busy := FALSE;
        xStepMovementStarted := FALSE;
        Outp.StepDonePulse := TRUE;
        Outp.DischargeDonePulse := TRUE;
        Sts.State := E_Bottom567State.IDLE;

    E_Bottom567State.EMPTY_HOLD:
        Outp.ConvRun := FALSE;
        Outp.ElevConv_RunBwd := FALSE;
        Outp.AlarmQueueFull := FALSE;
        Sts.Busy := TRUE;
        tStepTO(IN := FALSE);
        tStopDelay(IN := FALSE);
        tResyncStable(IN := FALSE);
        xResyncSampled := FALSE;
        xStepMovementStarted := FALSE;

        IF emptyPermissive THEN
            Outp.ConvRun := TRUE;
            Sts.EmptyBottomActive := TRUE;
        ELSE
            // Najpierw zatrzymaj taśmę, potem odtwórz model zajętości.
            Sts.State := E_Bottom567State.EMPTY_RESYNC;
        END_IF;

    E_Bottom567State.EMPTY_RESYNC:
        Outp.ConvRun := FALSE;
        Outp.ElevConv_RunBwd := FALSE;
        Outp.AlarmQueueFull := FALSE;
        Sts.Busy := TRUE;
        tStepTO(IN := FALSE);
        xStepMovementStarted := FALSE;

        tStopDelay(IN := TRUE, PT := Cfg.tMotorStopDelay);

        IF NOT tStopDelay.Q THEN
            tResyncStable(IN := FALSE);
            xResyncSampled := FALSE;
        ELSIF NOT xResyncSampled THEN
            resyncPos5 := Inp.sPos5_raw;
            resyncPos6 := Inp.sPos6_raw;
            resyncPos7 := Inp.sPos7_raw;
            xResyncSampled := TRUE;
            tResyncStable(IN := FALSE);
        ELSIF (Inp.sPos5_raw <> resyncPos5) OR
              (Inp.sPos6_raw <> resyncPos6) OR
              (Inp.sPos7_raw <> resyncPos7) THEN
            resyncPos5 := Inp.sPos5_raw;
            resyncPos6 := Inp.sPos6_raw;
            resyncPos7 := Inp.sPos7_raw;
            tResyncStable(IN := FALSE);
        ELSE
            tResyncStable(IN := TRUE, PT := Cfg.tSensorStable);
        END_IF;

        IF tResyncStable.Q THEN
            Sts.Occ5 := resyncPos5;
            Sts.Occ6 := resyncPos6;
            Sts.Occ7 := resyncPos7;
            tStopDelay(IN := FALSE);
            tResyncStable(IN := FALSE);
            xResyncSampled := FALSE;

            IF Diag.Fault THEN
                Sts.State := E_Bottom567State.FAULT;
            ELSE
                Sts.State := E_Bottom567State.IDLE;
            END_IF;
        END_IF;

    E_Bottom567State.FAULT:
        Outp.ConvRun := FALSE;
        Outp.ElevConv_RunBwd := FALSE;
        Sts.Busy := FALSE;
        xStepMovementStarted := FALSE;

        // alarm: pos7 zajęta -> sygnalizuj operatorowi
        Outp.AlarmQueueFull := TRUE;

END_CASE;
