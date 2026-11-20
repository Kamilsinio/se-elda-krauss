TYPE ST_VijeoExchange :
STRUCT
    value : ST_VijeoIoBits;
    valid : ST_VijeoIoBits;
    modules : ARRAY[0..11] OF BOOL;
    positionsValid : ARRAY[0..6] OF BOOL;
    occupied : ARRAY[0..6] OF BOOL;
    unloadCoils : ARRAY[0..1] OF ST_StationCoil;
    alarms : ST_VijeoAlarmStatus;
    manual : ST_VijeoRobotManual;
    stationManual : ST_VijeoStationManual;
    immManual : ST_VijeoImmManual;
    stationEdit : ARRAY[0..2] OF ST_VijeoStationParams;
    storageEdit : ST_VijeoStorageParams;
    elevatorSpeedEdit : ST_VijeoElevatorSpeed;
    stationActual : ARRAY[0..2] OF ST_VijeoStationParams;
    storageActual : ST_VijeoStorageParams;
    elevatorSpeedActual : ST_VijeoElevatorSpeed;
    stationRevision : ARRAY[0..3] OF UINT;
    stationEditRevision : ARRAY[0..3] OF UINT;
    stationOccupied : ARRAY[0..6] OF BOOL;
    beltsStopped : ARRAY[0..2] OF BOOL;
    allowManualPositive : ARRAY[0..15] OF BOOL;
    allowManualNegative : ARRAY[0..15] OF BOOL;
    hmiTimeoutMs : UDINT;
    localRestartRequired : ARRAY[0..9] OF BOOL;
    sourceArea : ST_VijeoArea;
    elevatorAreaReserved : BOOL;
    cylinders : ARRAY[0..4] OF ST_VijeoCylinder;
    vacuum : ARRAY[0..4] OF ST_VijeoVacuum;
    vacuumInput : ARRAY[0..4] OF ST_VijeoVacuumPermit;
    gripperStableMs : UDINT;
    gripperMotionTimeoutMs : UDINT;
    gripperVacuumTimeoutMs : UDINT;
    gripperBlowMs : UDINT;
    gripperReleaseTimeoutMs : UDINT;
END_STRUCT
END_TYPE
