TYPE ST_StationManualStatus :
STRUCT
    positive : ARRAY[1..16] OF BOOL;
    negative : ARRAY[1..16] OF BOOL;
    active : BOOL;
    reason : UINT;
END_STRUCT
END_TYPE
