(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotImmOut :
STRUCT
mouldClose : BOOL;
    mouldFullOpen : BOOL;
    ejectorBack : BOOL;
    ejectorForward : BOOL;
    withRobot : BOOL;
    newCyclePermit : BOOL;
    valid : BOOL;
    reason : UINT;
END_STRUCT
END_TYPE
