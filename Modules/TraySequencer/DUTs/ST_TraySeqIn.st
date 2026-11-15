TYPE ST_TraySeqIn :
STRUCT
    TopFlow_OccP3 : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    TopFlow_StackReadyAtP3 : BOOL;
    TopFlow_Busy : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    TopFlow_Fault : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    TopFlow_ElevDeliveredAtP4 : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    Elev_AtTop : BOOL;
    Elev_AtBottom : BOOL;
    Elev_AtTarget : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    Elev_Busy : BOOL;
    Elev_CommandReady : BOOL;
    Elev_Fault : BOOL;
    Bottom_CanAccept : BOOL;
    Bottom_Busy : BOOL;
    Bottom_Fault : BOOL;
    Bottom_DischargeDonePulse : BOOL;
    ind_container_in_pos_4 : BOOL;
    PositionerHome : BOOL;
    PositionerWork : BOOL;
    Session : BOOL;
    RobotReserved : BOOL;
    RobotClear : BOOL;
    TaskPicked : BOOL;
    TaskPlaced : BOOL;
    TaskFinished : BOOL;
    TaskStack : BOOL;
    SourceEmptyConfirmed : BOOL;
    Warning : BOOL;
END_STRUCT
END_TYPE
