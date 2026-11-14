TYPE ST_SafetyDoorCfg :
STRUCT
    tStable        : TIME := T#50ms;
    tBlink         : TIME := T#500ms;
    tUnlockTimeout : TIME := T#5s;
    tDeviceResetPulse : TIME := T#3500ms;
END_STRUCT
END_TYPE
