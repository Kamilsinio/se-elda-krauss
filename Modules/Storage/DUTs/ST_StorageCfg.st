TYPE ST_StorageCfg :
STRUCT
    tStable            : TIME := T#50ms;
    tBlink             : TIME := T#500ms;
    tM8Timeout         : TIME := T#3s;
    tPermissionTimeout : TIME := T#5s;
END_STRUCT
END_TYPE
