TYPE ST_StationParametersStatus :
STRUCT
    actual : ARRAY[1..4] OF ST_StationParameterSet;
    revision : ARRAY[1..4] OF UINT;
    reason : UINT;
    applied : BOOL;
END_STRUCT
END_TYPE
