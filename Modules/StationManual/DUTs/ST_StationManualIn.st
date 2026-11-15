TYPE ST_StationManualIn :
STRUCT
    armed : BOOL;
    sessionId : UDINT;
    panel : UINT;
    manual : BOOL;
    idle : BOOL;
    safe : BOOL;
    timeout : TIME;
    allowPositive : ARRAY[1..16] OF BOOL;
    allowNegative : ARRAY[1..16] OF BOOL;
    panelOverride : UINT;
END_STRUCT
END_TYPE
