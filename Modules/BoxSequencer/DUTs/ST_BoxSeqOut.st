TYPE ST_BoxSeqOut :
STRUCT
    (* --- Do TopFlowManager --- *)
    TopFlow_Enable           : BOOL;
    TopFlow_Elev_RequestFeed : BOOL;
    TopFlow_Elev_CanAccept   : BOOL;

    (* --- Do Elevator --- *)
    Elev_AutoGo            : BOOL;
    Elev_AutoTarget        : E_ElevatorTarget;  // typ enumów celów windy
    Elev_Stop              : BOOL;

    (* --- Do BottomAccumulator --- *)
    Bottom_Enable          : BOOL;
    Bottom_DischargeReq    : BOOL;

    (* --- Pozycjoner M7 --- *)
    M7_Extend              : BOOL;

    (* --- Robot --- *)
    Robot_BoxProduction     : BOOL;
    Robot_StackReady        : BOOL;
    Robot_ElevatorReady     : BOOL;
    Robot_AckStackFinished  : BOOL;

    AutoRunning            : BOOL;
END_STRUCT
END_TYPE
