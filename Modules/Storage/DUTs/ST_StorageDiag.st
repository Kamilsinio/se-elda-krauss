TYPE ST_StorageDiag :
STRUCT
    Fault : BOOL;
    Code  : E_StorageFault;
    Text  : STRING[120];
    LeftFault : BOOL;
    RightFault : BOOL;
END_STRUCT
END_TYPE
