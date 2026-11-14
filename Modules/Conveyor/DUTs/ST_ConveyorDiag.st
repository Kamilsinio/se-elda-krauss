TYPE ST_ConveyorDiag :
STRUCT
    Fault : BOOL;
    Code  : E_ConveyorFault;
    Text  : STRING[120];
END_STRUCT
END_TYPE
