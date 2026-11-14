TYPE ST_StorageCmd :
STRUCT
    Enable         : BOOL;
    ResetFault     : BOOL;
    RobotAccessReq : BOOL;
    RobotAccessPermit : BOOL;
    ManRobotOpen   : BOOL;
    ManRobotClose  : BOOL;
END_STRUCT
END_TYPE
