TYPE ST_VijeoRobotManual :
STRUCT
    udiSessionId : UDINT;
    cylHome : ARRAY[0..4] OF BOOL;
    cylWork : ARRAY[0..4] OF BOOL;
    vacValid : ARRAY[0..4] OF BOOL;
    vacHold : ARRAY[0..4] OF BOOL;
    blowReq : ARRAY[0..4] OF BOOL;
    holdCounter : ARRAY[0..9] OF UINT;
END_STRUCT
END_TYPE
