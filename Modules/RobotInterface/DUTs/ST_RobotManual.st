TYPE ST_RobotManual :
STRUCT
    udiSessionId : UDINT;
    cylHome : ARRAY[1..5] OF BOOL;
    cylWork : ARRAY[1..5] OF BOOL;
    vacValid : ARRAY[1..5] OF BOOL;
    vacHold : ARRAY[1..5] OF BOOL;
    blowReq : ARRAY[1..5] OF BOOL;
    holdCounter : ARRAY[1..10] OF UINT;
END_STRUCT
END_TYPE
