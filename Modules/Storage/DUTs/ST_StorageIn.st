TYPE ST_StorageIn :
STRUCT
    BtnOpenClose : BOOL;
    Left : ST_RobotCylinderIn;
    Right : ST_RobotCylinderIn;
    RobotSideOpeningPermission : BOOL;
    OperatorSideOpeningPermission : BOOL;
    LowLevel : BOOL;
    Empty : BOOL;
END_STRUCT
END_TYPE
