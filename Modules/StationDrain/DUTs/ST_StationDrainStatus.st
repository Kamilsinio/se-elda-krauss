TYPE ST_StationDrainStatus :
STRUCT
    state : E_StationDrainState;
    action : E_StationAction;
    paused : BOOL;
    reason : UINT;
END_STRUCT
END_TYPE
