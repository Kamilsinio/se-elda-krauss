TYPE ST_StationOperation :
STRUCT
    id : UDINT;
    owner : E_StationOwner;
    action : E_StationAction;
    accepted : BOOL;
    started : BOOL;
    done : BOOL;
    fault : BOOL;
END_STRUCT
END_TYPE
