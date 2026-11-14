TYPE ST_BoxSeqCfg :
STRUCT
    tPositionerTimeout : TIME := T#3s;
    tRobotAckTimeout   : TIME := T#180s;  // kuweta ma więcej produktów niż tacka
    tDischargeTimeout  : TIME := T#15s;
    tTransferTimeout   : TIME := T#12s;   // timeout transferu top->elev razem ze stabilnym P4
    tElevReturnTimeout : TIME := T#30s;
END_STRUCT
END_TYPE
