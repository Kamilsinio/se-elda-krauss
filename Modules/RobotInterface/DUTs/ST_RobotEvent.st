(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotEvent :
STRUCT
req : BOOL;
    stackId : UINT;
    cycleId : UINT;
    count : UINT;
    index : UINT;
END_STRUCT
END_TYPE
