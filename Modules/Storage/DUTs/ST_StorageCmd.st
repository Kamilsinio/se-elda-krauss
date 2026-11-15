TYPE ST_StorageCmd :
STRUCT
    Enable : BOOL;
    ResetFault : BOOL;
    RobotAccessReq : BOOL;
    RobotAccessPermit : BOOL;
    RobotReserved : BOOL;
    Manual : BOOL;
    ManualHome : ARRAY[1..2] OF BOOL;
    ManualWork : ARRAY[1..2] OF BOOL;
END_STRUCT
END_TYPE
