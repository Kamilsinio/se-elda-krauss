(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotDiag :
STRUCT
fault : BOOL;
    code : UINT;
    text : STRING[120];
END_STRUCT
END_TYPE
