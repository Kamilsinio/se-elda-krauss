(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotCycle :
STRUCT
occupied : BOOL;
    picked : BOOL;
    id : UINT;
    stackId : UINT;
    quantity : UINT;
    reject : BOOL;
    good : UDINT;
    samples : UDINT;
    rejects : UDINT;
END_STRUCT
END_TYPE
