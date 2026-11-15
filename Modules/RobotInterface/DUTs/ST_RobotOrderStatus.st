(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotOrderStatus :
STRUCT
manual : BOOL;
    running : BOOL;
    stopping : BOOL;
    stopped : BOOL;
    newPermit : BOOL;
    finishPermit : BOOL;
    canStart : BOOL;
    startToken : UINT;
    startAccepted : BOOL;
    settled : BOOL;
    reason : UINT;
END_STRUCT
END_TYPE
