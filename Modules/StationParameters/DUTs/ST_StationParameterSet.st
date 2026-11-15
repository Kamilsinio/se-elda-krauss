TYPE ST_StationParameterSet :
STRUCT
    verified : BOOL;
    sensorStableMs : UDINT;
    stopDelayMs : UDINT;
    moveTimeoutMs : UDINT;
    actuatorTimeoutMs : UDINT;
    slowHz : REAL;
    fastHz : REAL;
END_STRUCT
END_TYPE
