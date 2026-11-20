TYPE ST_VijeoStationStatus :
STRUCT
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
END_STRUCT
END_TYPE
