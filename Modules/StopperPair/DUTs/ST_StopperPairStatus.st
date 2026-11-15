TYPE ST_StopperPairStatus :
STRUCT
    IsUp   : BOOL; // oba fwd stabilne
    IsDown : BOOL; // oba bwd stabilne
    Busy   : BOOL;
    Valid : BOOL;
END_STRUCT
END_TYPE
