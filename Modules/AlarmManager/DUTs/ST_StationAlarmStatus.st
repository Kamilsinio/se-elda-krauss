TYPE ST_StationAlarmStatus :
STRUCT
    entries : ARRAY[1..64] OF ST_StationAlarmEntry;
    critical : BOOL;
    warning : BOOL;
    policyReady : BOOL;
    count : UINT;
    activeCount : UINT;
    activeCodes : ARRAY[1..12] OF INT; (* 0 oznacza puste miejsce. *)
END_STRUCT
END_TYPE
