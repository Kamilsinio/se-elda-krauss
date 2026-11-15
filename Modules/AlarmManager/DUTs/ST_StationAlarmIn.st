TYPE ST_StationAlarmIn :
STRUCT
    active : ARRAY[1..64] OF BOOL;
    acknowledge : BOOL;
    reset : BOOL;
END_STRUCT
END_TYPE
