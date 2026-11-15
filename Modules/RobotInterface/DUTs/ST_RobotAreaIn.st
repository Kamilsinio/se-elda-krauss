(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotAreaIn :
STRUCT
valid : BOOL;
    ready : BOOL;
    blocked : BOOL;
    recoveryClearConfirmed : BOOL;
END_STRUCT
END_TYPE
