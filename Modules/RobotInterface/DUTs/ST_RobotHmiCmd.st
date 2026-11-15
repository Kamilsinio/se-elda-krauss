(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotHmiCmd :
STRUCT
orderOpen : ST_RobotHmiRequest;
    orderEnd : ST_RobotHmiRequest;
    modeManual : ST_RobotHmiRequest;
    modeAuto : ST_RobotHmiRequest;
    robotEnable : ST_RobotHmiRequest;
    robotDisable : ST_RobotHmiRequest;
    resetFaults : ST_RobotHmiRequest;
    recoveryConfirm : ST_RobotHmiRequest;
    newEmptyContext : ST_RobotHmiRequest;
    station5ParamApply : ST_RobotHmiRequest;
    samples : ST_RobotHmiRequest;
END_STRUCT
END_TYPE
