TYPE ST_Bottom567Cmd :
STRUCT
    EnableAuto : BOOL;
    SafetyOK   : BOOL;
    DischargeReq : BOOL; // żądanie „zrób krok bo winda chce oddać pojemnik”
    EmptyBottomHold : BOOL;
    ResetFault : BOOL;
    AdvanceReq : BOOL;
    SingleUnloadReq : BOOL;
    FinishPermit : BOOL;
    DischargeId : UDINT;
    UnloadId : UDINT;
    AdvanceId : UDINT;
END_STRUCT
END_TYPE
