(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotHmiV2 :
STRUCT
link : ST_RobotHmiLink;
    cmd : ST_RobotHmiCmd;
    rsp : ST_RobotHmiRsp;
    permit : ST_RobotHmiPermits;
    state : ST_RobotHmiState;
    edit : ST_RobotHmiParameters;
    actual : ST_RobotHmiParameters;
    manual : ST_RobotManual;
END_STRUCT
END_TYPE
