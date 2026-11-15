TYPE ST_StationAlarmStatus :
STRUCT
    entries : ARRAY[1..64] OF ST_StationAlarmEntry;
    critical : BOOL;
    warning : BOOL;
    policyReady : BOOL;
    count : UINT;
END_STRUCT
END_TYPE
