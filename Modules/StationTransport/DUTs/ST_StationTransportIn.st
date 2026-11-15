TYPE ST_StationTransportIn :
STRUCT
    permit : BOOL;
    critical : BOOL;
    productionPermit : BOOL;
    productionBusy : BOOL;
    productionNeedsLower : BOOL;
    drainAction : E_StationAction;
    drainPermit : BOOL;
    localRequest : BOOL;
    localReady : BOOL;
    localAllowed : BOOL;
    manual : BOOL;
    manualActive : BOOL;
    actionDone : BOOL;
    actionFault : BOOL;
    reconcile : BOOL;
END_STRUCT
END_TYPE
