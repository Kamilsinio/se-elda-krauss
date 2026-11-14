TYPE ST_ConveyorStatus :
STRUCT
    State      : E_ConveyorState;
    Running    : BOOL;
    Direction  : INT;  // 0=stop, 1=fwd, -1=bwd
END_STRUCT
END_TYPE
