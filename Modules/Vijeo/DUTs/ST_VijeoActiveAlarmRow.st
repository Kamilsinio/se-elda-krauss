TYPE ST_VijeoActiveAlarmRow :
STRUCT
    valid : BOOL;
    code : UINT;
    station : UINT;
    level : STRING[24];
    text : STRING[80];
END_STRUCT
END_TYPE
