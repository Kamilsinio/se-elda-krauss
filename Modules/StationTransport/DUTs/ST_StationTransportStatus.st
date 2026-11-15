TYPE ST_StationTransportStatus :
STRUCT
    owner : E_StationOwner;
    completedOwner : E_StationOwner;
    action_ : E_StationAction;
    start : BOOL;
    busy : BOOL;
    done : BOOL;
    fault : BOOL;
    reason : UINT;
    operationId : UDINT;
    resources : ARRAY[1..6] OF ST_StationOperation;
    productionTopAllowed : BOOL;
    productionAxisAllowed : BOOL;
    productionElevatorAllowed : BOOL;
    productionBottomAllowed : BOOL;
END_STRUCT
END_TYPE
