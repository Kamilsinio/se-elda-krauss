TYPE ST_Bottom567Status :
STRUCT
    State : E_Bottom567State;
    Busy  : BOOL;
    EmptyBottomActive : BOOL;

    Occ5 : BOOL;
    Occ6 : BOOL;
    Occ7 : BOOL;

    CanAcceptFromElev : BOOL; // = NOT Occ7 (i brak fault)
    Known : BOOL;
    SingleUnloadReady : BOOL;
    WaitingPickup : BOOL;
    PickupSeen : BOOL;
    CanAdvance : BOOL;
END_STRUCT
END_TYPE
