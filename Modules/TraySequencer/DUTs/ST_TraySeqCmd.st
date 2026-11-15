TYPE ST_TraySeqCmd :
STRUCT
    Enable : BOOL;
    NewOperations : BOOL;
    FinishOperations : BOOL;
    StopRequested : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    RecoveryRequired : BOOL;
    SafetyOK : BOOL;
    ResetFault : BOOL;
END_STRUCT
END_TYPE
