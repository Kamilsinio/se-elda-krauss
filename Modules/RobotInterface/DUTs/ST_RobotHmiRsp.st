(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotHmiRsp :
STRUCT
orderOpen : ST_RobotHmiResponse;
    orderEnd : ST_RobotHmiResponse;
    modeManual : ST_RobotHmiResponse;
    modeAuto : ST_RobotHmiResponse;
    robotEnable : ST_RobotHmiResponse;
    robotDisable : ST_RobotHmiResponse;
    resetFaults : ST_RobotHmiResponse;
    recoveryConfirm : ST_RobotHmiResponse;
    newEmptyContext : ST_RobotHmiResponse;
    station5ParamApply : ST_RobotHmiResponse;
    samples : ST_RobotHmiResponse;
END_STRUCT
END_TYPE
