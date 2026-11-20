TYPE ST_VijeoAlarmStatus :
STRUCT
    entries : ARRAY[0..63] OF ST_StationAlarmEntry;
    critical : BOOL;
    warning : BOOL;
    policyReady : BOOL;
    count : UINT;
END_STRUCT
END_TYPE
