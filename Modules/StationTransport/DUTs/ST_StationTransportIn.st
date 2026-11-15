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
    resourcesUsed : BOOL;
    productionTopBusy : BOOL;
    productionAxisBusy : BOOL;
    productionElevatorBusy : BOOL;
    productionBottomBusy : BOOL;
    storageBusy : BOOL;
    robotReserved : ARRAY[1..3] OF BOOL;
    outputPending : BOOL;
    executorAccepted : BOOL;
    executorStarted : BOOL;
    unloadIssued : BOOL;
    requireIds : BOOL;
    acceptedId : UDINT;
    startedId : UDINT;
    doneId : UDINT;
END_STRUCT
END_TYPE
