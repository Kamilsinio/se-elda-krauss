TYPE ST_VijeoHmiV2 :
STRUCT
    link : ST_RobotHmiLink;
    cmd : ST_RobotHmiCmd;
    rsp : ST_RobotHmiRsp;
    permit : ST_RobotHmiPermits;
    state : ST_RobotHmiState;
    edit : ST_RobotHmiParameters;
    actual : ST_RobotHmiParameters;
    station : ST_VijeoStationStatus;
END_STRUCT
END_TYPE
