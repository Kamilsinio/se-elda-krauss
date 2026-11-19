(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotHmiState :
STRUCT
uiMode : UINT;
    uiProduction : UINT;
    uiOrderState : UINT;
    uiExecutionState : UINT;
    xWorkWithRobot : BOOL;
    xRobotHomeValid : BOOL;
    xCanPhysicalStart : BOOL;
    sStartBlockReason : STRING[80];
    xOpsSettled : BOOL;
    xStationEmpty : BOOL;
    uiRobotStep : UINT;
    uiRobotPhase : UINT;
    uiRobotWaitCode : UINT;
    uiRobotFaultCode : UINT;
    xRobotDataValid : BOOL;
    xRecoveryRequired : BOOL;
    uiUnsettled : UINT;
    udiGood : UDINT;
    udiSamples : UDINT;
    udiRejects : UDINT;
END_STRUCT
END_TYPE
