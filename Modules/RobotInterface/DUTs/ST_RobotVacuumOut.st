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
    fault : BOOL; // Usterka zatrzasnieta; odmowa 10/30/40 nie jest usterka urzadzenia.
    faultCode : UINT;
END_STRUCT
END_TYPE
