TYPE ST_StationInputs :
STRUCT
    robot_ScannerHealthy : BOOL;
    robot_ImageFresh : BOOL;
    robot_Plant : ST_RobotPlant;
    robot_Rx : ST_RobotRxV2;
    robot_storageIn : ST_StorageIn;
    robot_vfdCommHealthy : BOOL;
    station_Inputs : ST_StationIoIn;
    station_AlarmInputs : ST_StationAlarmIn;
    station_DiagnosticValue : ST_StationIoValues;
    station_DiagnosticValid : ST_StationIoValues;
    station_ManualInterlocks : ST_StationManualIn;
    io_di : ST_IO_DI;
    drive : ST_ElevatorDriveIn;

END_STRUCT
END_TYPE
