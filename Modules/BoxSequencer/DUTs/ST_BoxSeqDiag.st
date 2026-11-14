TYPE ST_BoxSeqDiag :
STRUCT
    Fault     : BOOL;
    FaultCode : E_BoxSeqFault;
    FaultText : STRING[120];
END_STRUCT
END_TYPE
