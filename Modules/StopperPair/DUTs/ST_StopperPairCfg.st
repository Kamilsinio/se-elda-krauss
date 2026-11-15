TYPE ST_StopperPairCfg :
STRUCT
    tStable   : TIME := T#50ms;  // filtr/stabilizacja potwierdzeń
    tTimeout  : TIME := T#2s;    // timeout dojazdu
    HoldCoilInEndPos : BOOL := TRUE; // TRUE: trzyma cewkę w pozycji docelowej
    requireValid : BOOL;
    requireApplied : BOOL;
END_STRUCT
END_TYPE
