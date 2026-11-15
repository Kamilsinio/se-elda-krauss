(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotLinkCfg :
STRUCT
configured : BOOL;
    heartbeatPeriod : TIME;
    peerTimeout : TIME;
    syncTimeout : TIME;
END_STRUCT
END_TYPE
