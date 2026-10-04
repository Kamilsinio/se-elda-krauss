(* ============================================================
   FB_Storage - obsluga magazynu przekladek.
   Steruje strona robota (rygiel + M8) i strona operatora
   (rygiel), pilnujac wzajemnych blokad dostepu.
   ============================================================ *)

{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_StorageFault :
(
    NONE := 0,
    SENSOR_CONTRADICTION := 10,
    M8_TIMEOUT := 20,
    ROBOT_PERMISSION_TIMEOUT := 30,
    OPERATOR_PERMISSION_TIMEOUT := 40,
    SPACER_EMPTY := 50,
    MANUAL_CMD_CONFLICT := 60
);
END_TYPE

{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_StorageState :
(
    DISABLED := 0,
    IDLE := 10,
    ROBOT_WAIT_PERMISSION := 20,
    ROBOT_OPENING := 30,
    ROBOT_OPEN := 40,
    ROBOT_CLOSING := 50,
    CLOSING_FOR_OPERATOR := 60,
    OPERATOR_WAIT_PERMISSION := 70,
    OPERATOR_UNLOCKED := 80,
    WAIT_OPERATOR_LOCK := 90,
    FAULT := 900
);
END_TYPE

TYPE ST_StorageCfg :
STRUCT
    tStable            : TIME := T#50ms;
    tBlink             : TIME := T#500ms;
    tM8Timeout         : TIME := T#3s;
    tPermissionTimeout : TIME := T#5s;
END_STRUCT
END_TYPE

TYPE ST_StorageCmd :
STRUCT
    Enable         : BOOL;
    ResetFault     : BOOL;
    RobotAccessReq : BOOL;
    RobotAccessPermit : BOOL;
    ManRobotOpen   : BOOL;
    ManRobotClose  : BOOL;
END_STRUCT
END_TYPE

TYPE ST_StorageIn :
STRUCT
    BtnOpenClose                  : BOOL;
    M8_Fwd                        : BOOL;
    M8_Bwd                        : BOOL;
    RobotSideOpeningPermission    : BOOL; // TRUE: strona operatora zaryglowana
    OperatorSideOpeningPermission : BOOL; // TRUE: strona robota zaryglowana
    LowLevel                      : BOOL;
    Empty                         : BOOL;
END_STRUCT
END_TYPE

TYPE ST_StorageOut :
STRUCT
    Q_M8Fwd              : BOOL;
    Q_M8Bwd              : BOOL;
    Q_UnlockRobotSide    : BOOL;
    Q_UnlockOperatorSide : BOOL;
    Q_LEDOpenClose       : BOOL;
END_STRUCT
END_TYPE

TYPE ST_StorageStatus :
STRUCT
    State                : E_StorageState;
    RobotSideOpen        : BOOL;
    RobotSideClosed      : BOOL;
    RobotAccessActive    : BOOL;
    RobotAccessGranted   : BOOL;
    OperatorAccessActive : BOOL;
    OperatorRequest      : BOOL;
    LowLevel             : BOOL;
    Empty                : BOOL;
    Busy                 : BOOL;
END_STRUCT
END_TYPE

TYPE ST_StorageDiag :
STRUCT
    Fault : BOOL;
    Code  : E_StorageFault;
    Text  : STRING[120];
END_STRUCT
END_TYPE


FUNCTION_BLOCK FB_Storage
VAR_INPUT
    Cfg : ST_StorageCfg;
    Cmd : ST_StorageCmd;
    Inp : ST_StorageIn;
END_VAR
VAR_OUTPUT
    Outp : ST_StorageOut;
    Sts  : ST_StorageStatus;
    Diag : ST_StorageDiag;
END_VAR
VAR
    tM8FwdStable : TON;
    tM8BwdStable : TON;
    tMoveTO      : TON;
    tPermTO      : TON;
    tBlink       : TON;

    xBtnPrev          : BOOL;
    xBtnRise          : BOOL;
    xOperatorReq      : BOOL;
    xWaitOperatorLock : BOOL;
    xRobotAccessLatched : BOOL;
    xWantRobotOpen    : BOOL;
    xMovePending      : BOOL;
    xPermPending      : BOOL;
    xBlinkEnable      : BOOL;
    xBlinkPulse       : BOOL;
    xContradiction    : BOOL;
    xHardFault        : BOOL;
END_VAR

// Stabilizacja krancowek i statusy podstawowe.
xContradiction := Inp.M8_Fwd AND Inp.M8_Bwd;
tM8FwdStable(IN := Inp.M8_Fwd AND (NOT xContradiction), PT := Cfg.tStable);
tM8BwdStable(IN := Inp.M8_Bwd AND (NOT xContradiction), PT := Cfg.tStable);

Sts.RobotSideOpen := tM8FwdStable.Q;
Sts.RobotSideClosed := tM8BwdStable.Q;
Sts.LowLevel := Inp.LowLevel;
Sts.Empty := Inp.Empty;

// Zbocze przycisku operatora.
xBtnRise := Inp.BtnOpenClose AND (NOT xBtnPrev);
xBtnPrev := Inp.BtnOpenClose;

IF Cmd.ResetFault THEN
    Diag.Fault := FALSE;
    Diag.Code := E_StorageFault.NONE;
    Diag.Text := '';
END_IF;

xHardFault := Diag.Fault AND (Diag.Code <> E_StorageFault.SPACER_EMPTY);

IF NOT Cmd.Enable THEN
    xOperatorReq := FALSE;
    xWaitOperatorLock := FALSE;
    xRobotAccessLatched := FALSE;
    Outp.Q_M8Fwd := FALSE;
    Outp.Q_M8Bwd := FALSE;
    Outp.Q_UnlockRobotSide := FALSE;
    Outp.Q_UnlockOperatorSide := FALSE;
    Outp.Q_LEDOpenClose := FALSE;
    Sts.OperatorRequest := FALSE;
    Sts.OperatorAccessActive := FALSE;
    Sts.RobotAccessActive := FALSE;
    Sts.RobotAccessGranted := FALSE;
    Sts.Busy := FALSE;
    Sts.State := E_StorageState.DISABLED;
    tMoveTO(IN := FALSE);
    tPermTO(IN := FALSE);
    tBlink(IN := FALSE);
    RETURN;
END_IF;

IF xBtnRise AND (NOT xHardFault) AND (NOT xRobotAccessLatched) THEN
    IF xOperatorReq THEN
        xOperatorReq := FALSE;
        xWaitOperatorLock := TRUE;
    ELSE
        xOperatorReq := TRUE;
        xWaitOperatorLock := FALSE;
    END_IF;
END_IF;

IF (NOT xOperatorReq) AND Inp.RobotSideOpeningPermission THEN
    xWaitOperatorLock := FALSE;
END_IF;

// Po przyjeciu zadania utrzymuj dostep az robot jawnie skasuje DO22 po wyjezdzie.
IF Cmd.RobotAccessPermit AND Cmd.RobotAccessReq AND (NOT Inp.Empty) AND
   (NOT xOperatorReq) AND (NOT Diag.Fault) THEN
    xRobotAccessLatched := TRUE;
ELSIF NOT Cmd.RobotAccessReq THEN
    xRobotAccessLatched := FALSE;
END_IF;
Sts.RobotAccessGranted := xRobotAccessLatched;

// Domyslnie wyjscia sa zerowane, a nizej ustawiane przez wybrany tryb.
Outp.Q_M8Fwd := FALSE;
Outp.Q_M8Bwd := FALSE;
Outp.Q_UnlockRobotSide := FALSE;
Outp.Q_UnlockOperatorSide := FALSE;

IF xContradiction AND (NOT xHardFault) THEN
    Diag.Fault := TRUE;
    Diag.Code := E_StorageFault.SENSOR_CONTRADICTION;
    Diag.Text := 'Storage: sprzeczne krancowki M8 FWD/BWD.';
END_IF;

IF Cmd.ManRobotOpen AND Cmd.ManRobotClose AND (NOT xHardFault) THEN
    Diag.Fault := TRUE;
    Diag.Code := E_StorageFault.MANUAL_CMD_CONFLICT;
    Diag.Text := 'Storage: jednoczesna komenda manualna M8 FWD/BWD.';
END_IF;

xHardFault := Diag.Fault AND (Diag.Code <> E_StorageFault.SPACER_EMPTY);

IF Cmd.RobotAccessPermit AND Cmd.RobotAccessReq AND Inp.Empty AND
   (NOT xRobotAccessLatched) AND
   (NOT xOperatorReq) AND (NOT Diag.Fault) THEN
    Diag.Fault := TRUE;
    Diag.Code := E_StorageFault.SPACER_EMPTY;
    Diag.Text := 'Storage: magazyn przekladek pusty - dostep robota zablokowany.';
END_IF;

IF xHardFault THEN
    Outp.Q_LEDOpenClose := TRUE;
    Sts.OperatorRequest := xOperatorReq;
    Sts.OperatorAccessActive := FALSE;
    Sts.RobotAccessActive := FALSE;
    Sts.Busy := FALSE;
    Sts.State := E_StorageState.FAULT;
    tMoveTO(IN := FALSE);
    tPermTO(IN := FALSE);
    RETURN;
END_IF;

xWantRobotOpen := (NOT xOperatorReq) AND
                  (xRobotAccessLatched OR
                   ((NOT Cmd.ManRobotClose) AND Cmd.ManRobotOpen));

IF xOperatorReq THEN
    // Priorytet operatora: najpierw zamknij M8, potem odrygluj strone operatora.
    Outp.Q_M8Bwd := TRUE;

    IF NOT Sts.RobotSideClosed THEN
        Sts.State := E_StorageState.CLOSING_FOR_OPERATOR;
    ELSIF Inp.OperatorSideOpeningPermission THEN
        Outp.Q_UnlockOperatorSide := TRUE;
        Sts.State := E_StorageState.OPERATOR_UNLOCKED;
    ELSE
        Sts.State := E_StorageState.OPERATOR_WAIT_PERMISSION;
    END_IF;

ELSIF xWaitOperatorLock THEN
    // Po zamknieciu drzwi operatora czekamy na potwierdzenie zaryglowania tej strony.
    Outp.Q_M8Bwd := TRUE;
    Sts.State := E_StorageState.WAIT_OPERATOR_LOCK;

ELSIF xWantRobotOpen THEN
    IF Inp.RobotSideOpeningPermission THEN
        Outp.Q_UnlockRobotSide := TRUE;
        Outp.Q_M8Fwd := TRUE;

        IF Sts.RobotSideOpen THEN
            Sts.State := E_StorageState.ROBOT_OPEN;
        ELSE
            Sts.State := E_StorageState.ROBOT_OPENING;
        END_IF;
    ELSE
        Sts.State := E_StorageState.ROBOT_WAIT_PERMISSION;
    END_IF;

ELSE
    // Stan bezpieczny: strona robota zamknieta.
    Outp.Q_M8Bwd := TRUE;

    IF Sts.RobotSideClosed THEN
        Sts.State := E_StorageState.IDLE;
    ELSE
        Sts.State := E_StorageState.ROBOT_CLOSING;
    END_IF;
END_IF;

// Diagnostyka timeoutu ruchu M8.
xMovePending := (Outp.Q_M8Fwd AND (NOT Sts.RobotSideOpen)) OR
                (Outp.Q_M8Bwd AND (NOT Sts.RobotSideClosed));
tMoveTO(IN := xMovePending, PT := Cfg.tM8Timeout);
IF tMoveTO.Q AND (NOT xHardFault) THEN
    Diag.Fault := TRUE;
    Diag.Code := E_StorageFault.M8_TIMEOUT;
    Diag.Text := 'Storage: timeout ruchu M8.';
END_IF;

xHardFault := Diag.Fault AND (Diag.Code <> E_StorageFault.SPACER_EMPTY);

// Diagnostyka oczekiwania na potwierdzenie zaryglowania przeciwnej strony.
xPermPending :=
    (xOperatorReq AND Sts.RobotSideClosed AND (NOT Inp.OperatorSideOpeningPermission)) OR
    ((xWantRobotOpen OR xWaitOperatorLock) AND (NOT Inp.RobotSideOpeningPermission));
tPermTO(IN := xPermPending, PT := Cfg.tPermissionTimeout);
IF tPermTO.Q AND (NOT xHardFault) THEN
    Diag.Fault := TRUE;
    IF xOperatorReq THEN
        Diag.Code := E_StorageFault.OPERATOR_PERMISSION_TIMEOUT;
        Diag.Text := 'Storage: timeout zezwolenia otwarcia strony operatora.';
    ELSE
        Diag.Code := E_StorageFault.ROBOT_PERMISSION_TIMEOUT;
        Diag.Text := 'Storage: timeout zezwolenia otwarcia strony robota.';
    END_IF;
END_IF;

xHardFault := Diag.Fault AND (Diag.Code <> E_StorageFault.SPACER_EMPTY);

IF xHardFault THEN
    Outp.Q_M8Fwd := FALSE;
    Outp.Q_M8Bwd := FALSE;
    Outp.Q_UnlockRobotSide := FALSE;
    Outp.Q_UnlockOperatorSide := FALSE;
    Outp.Q_LEDOpenClose := TRUE;
    Sts.OperatorRequest := xOperatorReq;
    Sts.OperatorAccessActive := FALSE;
    Sts.RobotAccessActive := FALSE;
    Sts.Busy := FALSE;
    Sts.State := E_StorageState.FAULT;
    tBlink(IN := FALSE);
    RETURN;
END_IF;

Sts.OperatorRequest := xOperatorReq;
Sts.OperatorAccessActive := xOperatorReq OR Outp.Q_UnlockOperatorSide OR xWaitOperatorLock;
Sts.RobotAccessActive := xWantRobotOpen OR Outp.Q_UnlockRobotSide OR Outp.Q_M8Fwd;
Sts.Busy := xMovePending OR xPermPending;

// LED przycisku magazynu: swieci przy dostepie operatora, miga w trakcie ruchu/oczekiwania.
xBlinkEnable := Sts.Busy OR xWaitOperatorLock;
IF xBlinkEnable THEN
    tBlink(IN := TRUE, PT := Cfg.tBlink);
    IF tBlink.Q THEN
        xBlinkPulse := NOT xBlinkPulse;
        tBlink(IN := FALSE);
    END_IF;
ELSE
    tBlink(IN := FALSE);
    xBlinkPulse := FALSE;
END_IF;

IF Outp.Q_UnlockOperatorSide THEN
    Outp.Q_LEDOpenClose := TRUE;
ELSIF xBlinkEnable THEN
    Outp.Q_LEDOpenClose := xBlinkPulse;
ELSE
    Outp.Q_LEDOpenClose := FALSE;
END_IF;
