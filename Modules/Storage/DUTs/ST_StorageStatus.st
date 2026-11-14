TYPE ST_StorageStatus :
STRUCT
    State                : E_StorageState;
    RobotSideOpen        : BOOL;
    RobotSideClosed      : BOOL;
    RobotAccessActive    : BOOL;
    RobotAccessGranted   : BOOL;
    OperatorAccessActive : BOOL;
    OperatorRequest      : BOOL;
    LowLevel             : BOOL;
    Empty                : BOOL;
    Busy                 : BOOL;
END_STRUCT
END_TYPE
