TYPE ST_SafetyDoorStatus :
STRUCT
    State         : E_SafetyDoorState;
    DoorClosed    : BOOL; // kompatybilnosc: TRUE tylko gdy OD/locked jest aktywne
    DoorLocked    : BOOL;
    DeviceError   : BOOL;
    UnlockRequest : BOOL;
    ReadyToRun    : BOOL; // TRUE gdy OD potwierdza rygiel i nie ma zadania otwarcia
    Busy          : BOOL;
END_STRUCT
END_TYPE
