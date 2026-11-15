(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotImmIn :
STRUCT
configured : BOOL;
    valid : BOOL;
    startConfirmed : BOOL;
    startSignalValid : BOOL;
    settled : BOOL;
    cycleKnown : BOOL;
    reject : BOOL;
    mouldClosed : BOOL;
    mouldOpen : BOOL;
    mouldIntermediate : BOOL;
    withRobot : BOOL;
    ejectorBack : BOOL;
    ejectorForward : BOOL;
    processInterlocks : BOOL;
    completionMouldClose : BOOL;
    completionFullOpen : BOOL;
    completionEjectorBack : BOOL;
    completionEjectorForward : BOOL;
    sharedSupplyVerified : BOOL;
    manualMouldClose : BOOL;
    manualFullOpen : BOOL;
    manualEjectorBack : BOOL;
    manualEjectorForward : BOOL;
END_STRUCT
END_TYPE
