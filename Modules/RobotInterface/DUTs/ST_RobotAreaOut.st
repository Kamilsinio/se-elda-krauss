(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotAreaOut :
STRUCT
valid : BOOL;
    ready : BOOL;
    granted : BOOL;
    reserved : BOOL;
    reason : UINT;
END_STRUCT
END_TYPE
