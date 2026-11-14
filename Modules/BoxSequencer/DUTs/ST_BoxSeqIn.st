TYPE ST_BoxSeqIn :
STRUCT
    (* --- Z TopFlowManager --- *)
    TopFlow_Busy         : BOOL;
    TopFlow_Fault        : BOOL;
    TopFlow_ElevDeliveredAtP4 : BOOL; // TopFlow potwierdzil stabilny transfer na P4

    (* --- Z Elevator --- *)
    Elev_AtTop           : BOOL;
    Elev_AtBottom        : BOOL;
    Elev_AtTarget        : BOOL;
    Elev_Busy            : BOOL;
    Elev_CommandReady    : BOOL;
    Elev_Fault           : BOOL;

    (* --- Z BottomAccumulator --- *)
    Bottom_CanAccept     : BOOL;
    Bottom_Busy          : BOOL;
    Bottom_Fault         : BOOL;
    Bottom_DischargeDonePulse : BOOL;

    (* --- Czujniki --- *)
    ind_container_in_pos_4 : BOOL;

    (* --- Pozycjoner M7 (z FB_StopperPair) --- *)
    M7_AtExt  : BOOL;
    M7_AtRet  : BOOL;

    (* --- Robot --- *)
    Robot_SystemReady    : BOOL;
    Robot_PrgRunning     : BOOL;
    Robot_AutoMode       : BOOL;
    Robot_Fault          : BOOL;
    Robot_StackFinished  : BOOL;  // dla kuwet = "kuweta zapełniona"
    Robot_CmdAck         : BOOL;
    Robot_BoxProgress    : BOOL;  // impuls po odlozeniu kompletu detali
END_STRUCT
END_TYPE
