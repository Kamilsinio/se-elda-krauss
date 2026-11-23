TYPE ST_VijeoAlarmStatus :
STRUCT
    entries : ARRAY[0..63] OF ST_StationAlarmEntry;
    critical : BOOL;
    warning : BOOL;
    policyReady : BOOL;
    count : UINT;
    activeCount : UINT;
    activeRows : ARRAY[0..11] OF ST_VijeoActiveAlarmRow;
END_STRUCT
END_TYPE
