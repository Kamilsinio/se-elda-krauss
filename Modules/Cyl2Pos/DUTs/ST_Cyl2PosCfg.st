TYPE ST_Cyl2PosCfg :
STRUCT
    tStable  : TIME := T#50ms;
    tTimeout : TIME := T#2s;
    requireValid : BOOL;
    requireApplied : BOOL;
END_STRUCT
END_TYPE
