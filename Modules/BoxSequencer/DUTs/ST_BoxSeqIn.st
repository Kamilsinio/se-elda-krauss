TYPE ST_BoxSeqIn :
STRUCT
    TopFlow_OccP3 : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    TopFlow_StackReadyAtP3 : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    TopFlow_Busy : BOOL;
    TopFlow_Fault : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    TopFlow_ElevDeliveredAtP4 : BOOL;
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
    TaskPicked : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    TaskPlaced : BOOL;
    TaskFinished : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    TaskStack : BOOL;
    SourceEmptyConfirmed : BOOL; // LEGACY: nieuzywane w v4; patrz docs/plc-review-fixes.md.
    Warning : BOOL;
END_STRUCT
END_TYPE
