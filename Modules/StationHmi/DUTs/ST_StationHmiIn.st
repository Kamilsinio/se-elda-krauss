TYPE ST_StationHmiIn :
STRUCT
    io : ST_StationIoStatus;
    material : ST_StationMaterialStatus;
    drain : ST_StationDrainStatus;
    transport : ST_StationTransportStatus;
    localReady : BOOL;
    waitingPickup : BOOL;
    idle : BOOL;
    manual : BOOL;
    recovery : BOOL;
END_STRUCT
END_TYPE
