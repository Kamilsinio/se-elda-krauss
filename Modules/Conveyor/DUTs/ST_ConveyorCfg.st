TYPE ST_ConveyorCfg :
STRUCT
    tReversalDelay : TIME := T#500ms;  // czas zwłoki po zatrzymaniu przed zmianą kierunku
    requireStoppedFeedback : BOOL;
END_STRUCT
END_TYPE
