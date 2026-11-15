TYPE ST_StationContext :
STRUCT
    nextOperationId : UDINT;
    nextMaterialEventId : UDINT;
    lastMaterialEventId : UDINT;
    operations : ARRAY[1..6] OF ST_StationOperation;
END_STRUCT
END_TYPE
