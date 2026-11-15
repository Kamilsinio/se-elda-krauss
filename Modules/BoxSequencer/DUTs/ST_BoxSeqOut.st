TYPE ST_BoxSeqOut :
STRUCT
    TopFlow_Enable : BOOL;
    TopFlow_Elev_RequestFeed : BOOL;
    TopFlow_Elev_CanAccept : BOOL;
    TopFlow_StackConsumed : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    Elev_AutoGo : BOOL;
    Elev_AutoTarget : E_ElevatorTarget;
    Elev_Stop : BOOL;
    Bottom_Enable : BOOL;
    Bottom_DischargeReq : BOOL;
    M7_Extend : BOOL;
    SourceReady : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    ElevatorReady : BOOL;
    ConsumePicked : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    ConsumePlaced : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    ConsumeFinished : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    ConsumeStack : BOOL;
    NewStackReady : BOOL;
    AutoRunning : BOOL;
END_STRUCT
END_TYPE
