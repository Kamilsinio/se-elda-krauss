TYPE ST_StationManualCmd :
STRUCT
    sessionId : UDINT;
    positive : ARRAY[1..16] OF BOOL;
    negative : ARRAY[1..16] OF BOOL;
    holdCounter : ARRAY[1..16] OF UINT;
END_STRUCT
END_TYPE
