(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotDrain :
STRUCT
connected : BOOL;
    request : BOOL;
    accepted : BOOL;
    busy : BOOL;
    done : BOOL;
    fault : BOOL;
    emptyConfirmed : BOOL;
END_STRUCT
END_TYPE
