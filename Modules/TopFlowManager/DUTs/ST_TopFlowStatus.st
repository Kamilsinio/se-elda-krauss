TYPE ST_TopFlowStatus :
STRUCT
    // stan logiczny bufora (nie oparty “na żywo” o migające czujniki w trakcie ruchu)
    OccP1 : BOOL;
    OccP2 : BOOL;
    OccP3 : BOOL;

    Pos1Accepted : BOOL; // token operatora przypisany do pojemnika na P1
    P1ReleasedForLoad : BOOL; // bieżący pojemnik przejechał przez P2
    Pos1SensorStable : BOOL; // stabilna obecność pojemnika na P1

    Busy : BOOL;
    State : E_TopFlowState;

    SrcPos : E_TopPos;
    Target : E_TopTarget;

    BufferFull : BOOL;  // P1..P3 zajęte
    Starved : BOOL;     // brak pojemników do podania na windę mimo żądania

    // TrayMode: stos na P3, M4 podniesiony i potwierdzony — gotowe dla robota
    StackReadyAtP3 : BOOL;

    // TRUE po zakonczonym transferze TG_ELEV, kasowane gdy P4 fizycznie sie zwolni.
    ElevDeliveredAtP4 : BOOL;
END_STRUCT
END_TYPE
