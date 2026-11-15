(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotDrain :
STRUCT
connected : BOOL;
    request : BOOL;
    runPermit : BOOL; // Nowy ruch tylko po Start; request pozostaje w pauzie.
    paused : BOOL;
    accepted : BOOL;
    busy : BOOL;
    done : BOOL;
    fault : BOOL;
    emptyConfirmed : BOOL;
END_STRUCT
END_TYPE
