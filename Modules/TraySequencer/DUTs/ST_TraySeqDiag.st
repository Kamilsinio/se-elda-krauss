TYPE ST_TraySeqDiag :
STRUCT
    Fault     : BOOL;
    FaultCode : E_TraySeqFault;
    FaultText : STRING[120];
END_STRUCT
END_TYPE
