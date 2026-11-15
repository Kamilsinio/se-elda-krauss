TYPE ST_StationHmiStatus :
STRUCT
    occupied : ARRAY[1..7] OF BOOL;
    dataValid : BOOL;
    materialKnown : BOOL;
    emptyConfirmed : BOOL;
    draining : BOOL;
    paused : BOOL;
    waitingPickup : BOOL;
    localReady : BOOL;
    drainStep : E_StationDrainState;
    owner : E_StationOwner;
    action_ : E_StationAction;
    reason : UINT;
    canApply : BOOL;
    canResetState : BOOL;
END_STRUCT
END_TYPE
