TYPE ST_StationOutputs :
STRUCT
    robot_Sts : ST_RobotStatus;
    robot_Tx : ST_RobotTxV2;
    robot_storageOut : ST_StorageOut;
    robot_singleUnloadReady : BOOL;
    robot_singleUnloadRequest : BOOL;
    station_Io : ST_StationIoStatus;
    station_Alarms : ST_StationAlarmStatus;
    station_Coils : ARRAY[1..10] OF ST_StationCoil;
    station_LocalRestartRequired : ARRAY[1..10] OF BOOL;
    station_Transport : ST_StationTransportStatus;
    station_DrainStatus : ST_StationDrainStatus;
    station_Material : ST_StationMaterialStatus;
    station_V201Out : ST_StationCoil;
    station_V202Out : ST_StationCoil;
    station_LowerStopOut : ARRAY[1..2] OF ST_StationCoil;
    io_dout : ST_IO_DO;
    hmi_hmiStatus : ST_HmiStationStatus;
    hmi_hmiIo : ST_StationHmiIo;
    hmi_reloadedStation : UINT;
    drive : ST_ElevatorDriveCmd;
    drain : ST_RobotDrain;
    reconcileRequired : BOOL;

END_STRUCT
END_TYPE
