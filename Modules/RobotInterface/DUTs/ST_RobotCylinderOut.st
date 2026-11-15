(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotCylinderOut :
STRUCT
home : BOOL;
    work : BOOL;
    valid : BOOL;
    atHome : BOOL;
    atWork : BOOL;
    acceptedHome : BOOL;
    acceptedWork : BOOL;
    busy : BOOL;
    reason : UINT;
END_STRUCT
END_TYPE
