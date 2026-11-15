TYPE ST_StationAlarmEntry :
STRUCT
    active : BOOL;
    returned : BOOL;
    acknowledged : BOOL;
    latched : BOOL;
    configured : BOOL;
    critical : BOOL;
    canReset : BOOL;
    station : UINT;
    code : UINT;
    text : STRING[120];
    actionText : STRING[120];
END_STRUCT
END_TYPE
