TYPE ST_RobotHmiPermits :
STRUCT
    orderOpen : ST_RobotHmiPermit;
    orderEnd : ST_RobotHmiPermit;
    modeManual : ST_RobotHmiPermit;
    modeAuto : ST_RobotHmiPermit;
    robotEnable : ST_RobotHmiPermit;
    robotDisable : ST_RobotHmiPermit;
    resetFaults : ST_RobotHmiPermit;
    recoveryConfirm : ST_RobotHmiPermit;
    newEmptyContext : ST_RobotHmiPermit;
    station5ParamApply : ST_RobotHmiPermit;
    samples : ST_RobotHmiPermit;
    station1ParamApply : ST_RobotHmiPermit;
    station2ParamApply : ST_RobotHmiPermit;
    station3ParamApply : ST_RobotHmiPermit;
    station4ParamApply : ST_RobotHmiPermit;
    station1ParamReload : ST_RobotHmiPermit;
    station2ParamReload : ST_RobotHmiPermit;
    station3ParamReload : ST_RobotHmiPermit;
    station4ParamReload : ST_RobotHmiPermit;
    station5ParamReload : ST_RobotHmiPermit;
    station1ResetState : ST_RobotHmiPermit;
    station2ResetState : ST_RobotHmiPermit;
    station3ResetState : ST_RobotHmiPermit;
    station4ResetState : ST_RobotHmiPermit;
    station5ResetState : ST_RobotHmiPermit;
    alarmAckAll : ST_RobotHmiPermit;
    pause : ST_RobotHmiPermit;
    resume : ST_RobotHmiPermit;
END_STRUCT
END_TYPE
