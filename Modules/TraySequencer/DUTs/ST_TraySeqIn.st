TYPE ST_TraySeqIn :
STRUCT
    (* --- Z TopFlowManager --- *)
    TopFlow_OccP3        : BOOL;  // stos na pozycji 3 (logiczna zajętość)
    TopFlow_StackReadyAtP3 : BOOL; // P3 zajęte + M4 góra + M5 cofnięte — gotowe dla robota
    TopFlow_Busy         : BOOL;
    TopFlow_Fault        : BOOL;

    (* --- Z Elevator --- *)
    Elev_AtTop           : BOOL;  // winda w pozycji górnej
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

    (* --- Czujniki windowe --- *)
    ind_container_in_pos_4 : BOOL;  // pojemnik na windzie

    (* --- Pozycjoner M6 (feedback z FB_StopperPair) --- *)
    M6_IsUp   : BOOL;
    M6_IsDown : BOOL;

    (* --- Robot (z GVL_Robot.robotIn) --- *)
    Robot_SystemReady    : BOOL;
    Robot_PrgRunning     : BOOL;
    Robot_InHome         : BOOL;
    Robot_AutoMode       : BOOL;
    Robot_Fault          : BOOL;
    Robot_PalletFinished : BOOL;  // impuls: tacka ułożona
    Robot_StackFinished  : BOOL;  // poziom: cały stos ukończony, aktywny do ACK
    Robot_CmdAck         : BOOL;
END_STRUCT
END_TYPE
