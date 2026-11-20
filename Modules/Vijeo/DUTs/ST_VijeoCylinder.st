TYPE ST_VijeoCylinder :
STRUCT
    valid : BOOL;
    atHome : BOOL;
    atWork : BOOL;
    acceptedHome : BOOL;
    acceptedWork : BOOL;
    busy : BOOL;
    reason : UINT;
    fault : BOOL;
    faultCode : UINT;
END_STRUCT
END_TYPE
