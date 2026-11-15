TYPE ST_StationTransportStatus :
STRUCT
    owner : E_StationOwner;
    completedOwner : E_StationOwner;
    action : E_StationAction;
    start : BOOL;
    busy : BOOL;
    done : BOOL;
    fault : BOOL;
    reason : UINT;
END_STRUCT
END_TYPE
