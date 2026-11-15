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
    fault : BOOL; // Usterka zatrzasnieta; odmowa 10/30/40 nie jest usterka urzadzenia.
    faultCode : UINT;
END_STRUCT
END_TYPE
