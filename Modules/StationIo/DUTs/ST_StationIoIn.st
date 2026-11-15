TYPE ST_StationIoIn :
STRUCT
    mappingVerified : BOOL;
    gatewayHealthy : BOOL;
    imageFresh : BOOL;
    moduleHealthy : ARRAY[1..12] OF BOOL;
    occupied : ARRAY[1..7] OF BOOL;
    positionValid : ARRAY[1..7] OF BOOL;
    barrierBlocked : BOOL;
    barrierValid : BOOL;
    beltsStopped : ARRAY[1..3] OF BOOL;
    v201 : ST_Cyl2PosIn;
    v202 : ST_Cyl2PosIn;
    lowerStop : ARRAY[1..2] OF ST_StopperPairIn;
    lowerFeedbackValid : BOOL;
END_STRUCT
END_TYPE
