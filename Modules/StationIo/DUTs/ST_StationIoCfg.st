TYPE ST_StationIoCfg :
STRUCT
    configured : BOOL;
    stable : TIME;
    required : ARRAY[1..12] OF BOOL;
END_STRUCT
END_TYPE
