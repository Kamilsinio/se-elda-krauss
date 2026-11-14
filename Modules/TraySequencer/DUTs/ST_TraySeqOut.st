TYPE ST_TraySeqOut :
STRUCT
    (* --- Do TopFlowManager --- *)
    TopFlow_Enable           : BOOL;
    TopFlow_Elev_RequestFeed : BOOL;  // (tylko tryb kuwet) priorytet karmienia windy
    TopFlow_Elev_CanAccept   : BOOL;  // (tylko tryb kuwet) winda gotowa na pojemnik
    TopFlow_StackConsumed    : BOOL;  // stos pobrany przez robota — TopFlow zwalnia P3/M4

    (* --- Do Elevator --- *)
    Elev_AutoGo            : BOOL;
    Elev_AutoTarget        : E_ElevatorTarget;  // typ enumów celów windy
    Elev_Stop              : BOOL;

    (* --- Do BottomAccumulator --- *)
    Bottom_Enable          : BOOL;
    Bottom_DischargeReq    : BOOL;

    (* --- Do pozycjonera M6 --- *)
    M6_Extend   : BOOL;  // pozycjoner tacek winda

    (* --- Do robota (GVL_Robot.robotOut) --- *)
    Robot_TrayProduction   : BOOL;
    Robot_StackReady       : BOOL;
    Robot_ElevatorReady    : BOOL;
    Robot_AckStackFinished : BOOL;

    (* --- Status --- *)
    AutoRunning : BOOL;
END_STRUCT
END_TYPE
