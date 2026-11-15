TYPE ST_BoxSeqCfg :
STRUCT
    tPositionerTimeout : TIME := T#3s; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    tRobotAckTimeout   : TIME := T#180s; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    tDischargeTimeout  : TIME := T#15s; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    tTransferTimeout   : TIME := T#12s; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    tElevReturnTimeout : TIME := T#30s; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
END_STRUCT
END_TYPE
