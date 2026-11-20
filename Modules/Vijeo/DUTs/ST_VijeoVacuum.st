TYPE ST_VijeoVacuum :
STRUCT
    hold : BOOL;
    blow : BOOL;
    valid : BOOL;
    ok : BOOL;
    accepted : BOOL;
    blowAck : BOOL;
    blowResult : UINT;
    reason : UINT;
    fault : BOOL;
    faultCode : UINT;
END_STRUCT
END_TYPE
