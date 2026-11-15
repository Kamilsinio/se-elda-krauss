TYPE ST_RobotStatus :
STRUCT
    session : BOOL;
    diagnosticValid : BOOL;
    recoveryRequired : BOOL;
    allChannelsIdle : BOOL;
    settled : BOOL;
    order : ST_RobotOrderStatus;
    diag : ST_RobotDiag;
    cylinders : ARRAY[1..5] OF ST_RobotCylinderOut;
    vacuum : ARRAY[1..5] OF ST_RobotVacuumOut;
    areas : ARRAY[1..3] OF ST_RobotAreaOut;
    imm : ST_RobotImmOut;
END_STRUCT
END_TYPE
