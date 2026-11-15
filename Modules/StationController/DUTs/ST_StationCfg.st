TYPE ST_StationCfg :
STRUCT
    robot_Cfg : ST_RobotCfg;
    robot_stationIoBound : BOOL;
    robot_stationCoilPolicyVerified : BOOL;
    robot_stationCoilLossPolicy : ARRAY[1..10] OF ST_StationCoil;
    station_IoCfg : ST_StationIoCfg;
    station_AlarmCfg : ST_StationAlarmCfg;
    station_ParameterCfg : ST_StationParameterCfg;
    station_ElevatorCfg : ST_ElevatorPar;
    station_ElevatorCfgVerified : BOOL;
    station_ManualReleaseVerified : BOOL;
    station_ManualRelease : ARRAY[1..10] OF ST_StationCoil;

END_STRUCT
END_TYPE
