TYPE ST_TraySeqCfg :
STRUCT
    uiTraysInStack     : UINT := 8; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    tPositionerTimeout : TIME := T#3s; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    tRobotAckTimeout   : TIME := T#120s; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    tP4ConfirmTimeout  : TIME := T#2s;   // timeout potwierdzenia P4 po sygnale robota
    tDischargeTimeout  : TIME := T#15s; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    tElevReturnTimeout : TIME := T#30s; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
END_STRUCT
END_TYPE
