(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotVacuumOut :
STRUCT
hold : BOOL;
    blow : BOOL;
    valid : BOOL;
    ok : BOOL;
    accepted : BOOL;
    busy : BOOL;
    blowAck : BOOL;
    blowResult : UINT;
    reason : UINT;
END_STRUCT
END_TYPE
