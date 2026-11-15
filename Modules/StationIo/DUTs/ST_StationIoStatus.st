TYPE ST_StationIoStatus :
STRUCT
    valid : BOOL;
    occupied : ARRAY[1..7] OF BOOL;
    positionValid : ARRAY[1..7] OF BOOL;
    moduleValid : ARRAY[1..12] OF BOOL;
    barrierBlocked : BOOL;
    barrierValid : BOOL;
    reason : UINT;
END_STRUCT
END_TYPE
