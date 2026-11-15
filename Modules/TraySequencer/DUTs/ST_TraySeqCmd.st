TYPE ST_TraySeqCmd :
STRUCT
    Enable : BOOL;
    NewOperations : BOOL;
    FinishOperations : BOOL;
    StopRequested : BOOL;
    RecoveryRequired : BOOL;
    SafetyOK : BOOL;
    ResetFault : BOOL;
END_STRUCT
END_TYPE
