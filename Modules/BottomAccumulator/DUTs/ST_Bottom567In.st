TYPE ST_Bottom567In :
STRUCT
    sPos5_raw : BOOL;
    sPos6_raw : BOOL;
    sPos7_raw : BOOL;
    sElevatorEmptied_raw : BOOL;
    Valid : BOOL;
    Reconcile : BOOL;
    Restored : ARRAY[1..3] OF BOOL;
    BeltsStopped : BOOL;
    Stop5Holding : BOOL;
    Stop5Released : BOOL;
    Stop6Holding : BOOL;
    Stop6Released : BOOL;
    StopWarning : BOOL;
END_STRUCT
END_TYPE
