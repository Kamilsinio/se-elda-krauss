TYPE ST_TraySeqCfg :
STRUCT
    uiTraysInStack     : UINT := 8;     // ilość tacek w stosie (konfigurowalna)
    tPositionerTimeout : TIME := T#3s;  // timeout pozycjonerów (M4/M5/M6)
    tRobotAckTimeout   : TIME := T#120s; // timeout oczekiwania na tackę od robota
    tP4ConfirmTimeout  : TIME := T#2s;   // timeout potwierdzenia P4 po sygnale robota
    tDischargeTimeout  : TIME := T#15s;  // timeout rozładunku windy
    tElevReturnTimeout : TIME := T#30s;  // timeout powrotu windy na górę
END_STRUCT
END_TYPE
