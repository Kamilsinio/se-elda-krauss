TYPE ST_VijeoStationManual :
STRUCT
    sessionId : UDINT;
    positive : ARRAY[0..15] OF BOOL;
    negativeFrom2 : ARRAY[0..14] OF BOOL;
    holdCounter : ARRAY[0..15] OF UINT;
END_STRUCT
END_TYPE
