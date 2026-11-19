TYPE ST_SafetyDoorDiag :
STRUCT
    Fault : BOOL;
    Code  : E_SafetyDoorFault;
    Text  : STRING[80];
END_STRUCT
END_TYPE
