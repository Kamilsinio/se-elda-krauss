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
    stationManual : ST_StationManualCmd;
    stationEdit : ARRAY[1..4] OF ST_StationParameterSet;
    stationActual : ARRAY[1..4] OF ST_StationParameterSet;
    stationRevision : ARRAY[1..4] OF UINT;
    stationEditRevision : ARRAY[1..4] OF UINT;
    station : ST_StationHmiStatus;
END_STRUCT
END_TYPE
