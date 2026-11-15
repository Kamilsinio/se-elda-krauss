(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotHmiLink :
STRUCT
uiContractVersion : UINT;
    uiPlcHeartbeat : UINT;
    uiHmiHeartbeat : UINT;
    uiActivePanel : UINT;
    xArmReq : BOOL;
    udiSessionId : UDINT;
    xArmed : BOOL;
    xDataValid : BOOL;
    uiSessionState : UINT;
    sDiag : STRING[120];
END_STRUCT
END_TYPE
