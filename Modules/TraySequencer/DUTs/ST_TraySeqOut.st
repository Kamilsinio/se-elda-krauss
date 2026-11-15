TYPE ST_TraySeqOut :
STRUCT
    TopFlow_Enable : BOOL;
    TopFlow_Elev_RequestFeed : BOOL;
    TopFlow_Elev_CanAccept : BOOL;
    TopFlow_StackConsumed : BOOL;
    Elev_AutoGo : BOOL;
    Elev_AutoTarget : E_ElevatorTarget;
    Elev_Stop : BOOL;
    Bottom_Enable : BOOL;
    Bottom_DischargeReq : BOOL;
    M6_Extend : BOOL;
    SourceReady : BOOL;
    ElevatorReady : BOOL;
    ConsumePicked : BOOL;
    ConsumePlaced : BOOL;
    ConsumeFinished : BOOL;
    ConsumeStack : BOOL;
    NewStackReady : BOOL;
    AutoRunning : BOOL;
END_STRUCT
END_TYPE
