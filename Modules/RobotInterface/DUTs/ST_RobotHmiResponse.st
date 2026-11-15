(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotHmiResponse :
STRUCT
udiSessionId : UDINT;
    udiRequestId : UDINT;
    xAck : BOOL;
    uiResult : UINT;
    uiReason : UINT;
    sReason : STRING[120];
END_STRUCT
END_TYPE
