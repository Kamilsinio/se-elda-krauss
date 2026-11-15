(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotCylinderIn :
STRUCT
configured : BOOL;
    valid : BOOL;
    atHome : BOOL;
    atWork : BOOL;
    homeAllowed : BOOL;
    workAllowed : BOOL;
    lossPolicyVerified : BOOL;
    lossHome : BOOL;
    lossWork : BOOL;
END_STRUCT
END_TYPE
