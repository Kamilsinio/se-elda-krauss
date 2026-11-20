TYPE ST_VijeoImmManual :
STRUCT
    sessionId : UDINT;
    positive : ARRAY[0..3] OF BOOL;
    holdCounter : ARRAY[0..3] OF UINT;
END_STRUCT
END_TYPE
