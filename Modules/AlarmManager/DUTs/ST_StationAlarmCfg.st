TYPE ST_StationAlarmCfg :
STRUCT
    policyVerified : BOOL;
    configured : ARRAY[1..64] OF BOOL;
    critical : ARRAY[1..64] OF BOOL;
    latched : ARRAY[1..64] OF BOOL;
    station : ARRAY[1..64] OF UINT;
END_STRUCT
END_TYPE
