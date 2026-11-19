TYPE ST_BoxSeqDiag :
STRUCT
    Fault     : BOOL;
    FaultCode : E_BoxSeqFault;
    FaultText : STRING[80];
END_STRUCT
END_TYPE
