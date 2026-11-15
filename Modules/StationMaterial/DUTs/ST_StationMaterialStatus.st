TYPE ST_StationMaterialStatus :
STRUCT
    known : BOOL;
    occupied : ARRAY[1..7] OF BOOL;
    emptyConfirmed : BOOL;
    reason : UINT;
    lastEventId : UDINT;
    fault : BOOL;
END_STRUCT
END_TYPE
