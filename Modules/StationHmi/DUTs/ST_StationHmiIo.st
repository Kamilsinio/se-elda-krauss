TYPE ST_StationHmiIo :
STRUCT
    dataValid : BOOL;
    value : ST_StationIoValues;
    valid : ST_StationIoValues;
    modules : ARRAY[1..12] OF BOOL;
    positionsValid : ARRAY[1..7] OF BOOL;
    occupied : ARRAY[1..7] OF BOOL;
    barrierValid : BOOL;
    barrierBlocked : BOOL;
    appliedCoils : ARRAY[1..10] OF ST_StationCoil;
    alarms : ST_StationAlarmStatus;
END_STRUCT
END_TYPE
