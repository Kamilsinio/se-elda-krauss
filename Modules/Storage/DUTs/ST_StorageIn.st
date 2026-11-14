TYPE ST_StorageIn :
STRUCT
    BtnOpenClose                  : BOOL;
    M8_Fwd                        : BOOL;
    M8_Bwd                        : BOOL;
    RobotSideOpeningPermission    : BOOL; // TRUE: strona operatora zaryglowana
    OperatorSideOpeningPermission : BOOL; // TRUE: strona robota zaryglowana
    LowLevel                      : BOOL;
    Empty                         : BOOL;
END_STRUCT
END_TYPE
