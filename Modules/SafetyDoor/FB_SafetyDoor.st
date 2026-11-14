(* ============================================================
   FB_SafetyDoor - obsluga klamki/rygla bezpieczenstwa Euchner.
   Blok steruje cewka odryglowania, RST i LED przycisku. Nie zastepuje
   ukladu safety; bezpieczne zatrzymanie musi zostac w torze safety.
   ============================================================ *)









FUNCTION_BLOCK FB_SafetyDoor
VAR_INPUT
    Cfg : ST_SafetyDoorCfg;
    Enable : BOOL;
    ResetFault : BOOL;
    Inp : ST_SafetyDoorIn;
END_VAR
VAR_OUTPUT
    Outp : ST_SafetyDoorOut;
    Sts  : ST_SafetyDoorStatus;
    Diag : ST_SafetyDoorDiag;
END_VAR
VAR
    tLockedStable : TON;
    tErrorStable  : TON;
    tBlink        : TON;
    tUnlockTO     : TON;
    tDeviceReset  : TP;

    xBtnPrev      : BOOL;
    xBtnRise      : BOOL;
    xResetPrev    : BOOL;
    xResetRise    : BOOL;
    xUnlockReq    : BOOL;
    xBlinkEnable  : BOOL;
    xBlinkPulse   : BOOL;
END_VAR

// Stabilizacja sygnalow z Euchnera.
tLockedStable(IN := Inp.DoorLocked, PT := Cfg.tStable);
tErrorStable(IN := Inp.DeviceError, PT := Cfg.tStable);

Sts.DoorLocked := tLockedStable.Q;
Sts.DoorClosed := Sts.DoorLocked; // brak osobnego sygnalu closed; locked implikuje zamkniecie
Sts.DeviceError := tErrorStable.Q;

xResetRise := ResetFault AND (NOT xResetPrev);
xResetPrev := ResetFault;

// RST Euchnera jest fizycznym wejsciem resetu; impuls generujemy tylko po aktywnym OI.
tDeviceReset(IN := Enable AND xResetRise AND Sts.DeviceError, PT := Cfg.tDeviceResetPulse);

// Reset bledu z HMI/przycisku resetu.
IF ResetFault THEN
    Diag.Fault := FALSE;
    Diag.Code := E_SafetyDoorFault.NONE;
    Diag.Text := '';
END_IF;

xBtnRise := Inp.BtnOpenClose AND (NOT xBtnPrev);
xBtnPrev := Inp.BtnOpenClose;

IF NOT Enable THEN
    xUnlockReq := FALSE;
END_IF;

// Przycisk dziala bistabilnie: kazde zbocze przelacza Q_Unlock do nastepnego klikniecia.
IF Enable AND xBtnRise THEN
    xUnlockReq := NOT xUnlockReq;
END_IF;

IF Enable AND Sts.DeviceError AND (NOT Diag.Fault) THEN
    Diag.Fault := TRUE;
    Diag.Code := E_SafetyDoorFault.DEVICE_ERROR;
    Diag.Text := 'SafetyDoor: blad OI klamki Euchner.';
END_IF;

// Timeout odryglowania: po podaniu cewki sygnal zaryglowania powinien zniknac.
tUnlockTO(
    IN := Enable AND xUnlockReq AND Sts.DoorLocked AND (NOT Diag.Fault),
    PT := Cfg.tUnlockTimeout
);
IF tUnlockTO.Q AND (NOT Diag.Fault) THEN
    Diag.Fault := TRUE;
    Diag.Code := E_SafetyDoorFault.UNLOCK_TIMEOUT;
    Diag.Text := 'SafetyDoor: timeout odryglowania drzwi.';
END_IF;

Sts.UnlockRequest := xUnlockReq;
Sts.ReadyToRun := Enable AND (NOT Diag.Fault) AND Sts.DoorLocked AND (NOT xUnlockReq);
Sts.Busy := Enable AND (NOT Diag.Fault) AND (
    xUnlockReq AND Sts.DoorLocked
);

IF NOT Enable THEN
    Sts.State := E_SafetyDoorState.DISABLED;
ELSIF Diag.Fault THEN
    Sts.State := E_SafetyDoorState.FAULT;
ELSIF xUnlockReq AND Sts.DoorLocked THEN
    Sts.State := E_SafetyDoorState.UNLOCK_REQUEST;
ELSIF Sts.DoorLocked THEN
    Sts.State := E_SafetyDoorState.LOCKED;
ELSE
    Sts.State := E_SafetyDoorState.UNLOCKED;
END_IF;

Outp.Q_Unlock := Enable AND xUnlockReq;

// LED otworz/zamknij:
// - stale swieci gdy drzwi sa gotowe do pracy,
// - miga gdy aktywne jest zadanie odryglowania,
// - gasnie przy odryglowanych drzwiach bez zadania ruchu.
xBlinkEnable := Enable AND (NOT Diag.Fault) AND xUnlockReq;

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

IF Sts.ReadyToRun THEN
    Outp.Q_LEDOpenClose := TRUE;
ELSIF xBlinkEnable THEN
    Outp.Q_LEDOpenClose := xBlinkPulse;
ELSE
    Outp.Q_LEDOpenClose := FALSE;
END_IF;

Outp.Q_DeviceReset := Enable AND Sts.DeviceError AND tDeviceReset.Q;
