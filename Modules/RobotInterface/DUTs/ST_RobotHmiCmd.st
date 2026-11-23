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
    station1ParamApply : ST_RobotHmiRequest;
    station2ParamApply : ST_RobotHmiRequest;
    station3ParamApply : ST_RobotHmiRequest;
    station4ParamApply : ST_RobotHmiRequest;
    station1ParamReload : ST_RobotHmiRequest;
    station2ParamReload : ST_RobotHmiRequest;
    station3ParamReload : ST_RobotHmiRequest;
    station4ParamReload : ST_RobotHmiRequest;
    station5ParamReload : ST_RobotHmiRequest;
    station1ResetState : ST_RobotHmiRequest;
    station2ResetState : ST_RobotHmiRequest;
    station3ResetState : ST_RobotHmiRequest;
    station4ResetState : ST_RobotHmiRequest;
    station5ResetState : ST_RobotHmiRequest;
    alarmAckAll : ST_RobotHmiRequest;
    pause : ST_RobotHmiRequest;
    resume : ST_RobotHmiRequest;
END_STRUCT
END_TYPE
