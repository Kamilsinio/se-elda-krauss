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
END_STRUCT
END_TYPE
