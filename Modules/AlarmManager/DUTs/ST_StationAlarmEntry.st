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
    text : STRING[80];
    actionText : STRING[80];
END_STRUCT
END_TYPE
