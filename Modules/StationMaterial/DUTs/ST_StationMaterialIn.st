TYPE ST_StationMaterialIn :
STRUCT
    valid : BOOL;
    reconcile : BOOL;
    restored : ARRAY[1..7] OF BOOL;
    observed : ARRAY[1..7] OF BOOL;
    sensed : ARRAY[1..7] OF BOOL;
    moving : BOOL;
    commit : BOOL;
    manualMoved : BOOL;
    pending : BOOL;
END_STRUCT
END_TYPE
