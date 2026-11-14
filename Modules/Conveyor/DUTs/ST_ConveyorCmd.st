TYPE ST_ConveyorCmd :
STRUCT
    RunFwd     : BOOL;  // komenda: jedź "do przodu" (kierunek normalny)
    RunBwd     : BOOL;  // komenda: jedź "do tyłu"
    ResetFault : BOOL;
END_STRUCT
END_TYPE
