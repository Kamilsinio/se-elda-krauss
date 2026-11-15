TYPE ST_StationDrainIn :
STRUCT
    enable : BOOL;
    known : BOOL;
    occupied : ARRAY[1..7] OF BOOL;
    emptyConfirmed : BOOL;
    atTop : BOOL;
    atBottom : BOOL;
    lowerCanAccept : BOOL;
    lowerCanAdvance : BOOL;
    actionAccepted : BOOL;
    actionDone : BOOL;
    actionFault : BOOL;
    reconcile : BOOL;
END_STRUCT
END_TYPE
