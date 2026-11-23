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
    station1ParamApply : ST_RobotHmiResponse;
    station2ParamApply : ST_RobotHmiResponse;
    station3ParamApply : ST_RobotHmiResponse;
    station4ParamApply : ST_RobotHmiResponse;
    station1ParamReload : ST_RobotHmiResponse;
    station2ParamReload : ST_RobotHmiResponse;
    station3ParamReload : ST_RobotHmiResponse;
    station4ParamReload : ST_RobotHmiResponse;
    station5ParamReload : ST_RobotHmiResponse;
    station1ResetState : ST_RobotHmiResponse;
    station2ResetState : ST_RobotHmiResponse;
    station3ResetState : ST_RobotHmiResponse;
    station4ResetState : ST_RobotHmiResponse;
    station5ResetState : ST_RobotHmiResponse;
    alarmAckAll : ST_RobotHmiResponse;
    pause : ST_RobotHmiResponse;
    resume : ST_RobotHmiResponse;
END_STRUCT
END_TYPE
