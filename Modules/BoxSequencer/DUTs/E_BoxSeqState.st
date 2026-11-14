{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_BoxSeqState :
(
    DISABLED        := 0,
    IDLE            := 10,
    PAUSED          := 15,

    (* --- Faza: kuweta na windę --- *)
    REQUEST_ELEVATOR_FEED := 20, // zadaj TopFlowManagerowi podanie kuwety na P4
    FEED_ELEVATOR   := 30,    // transfer z top na windę (dwa transportery jednocześnie)
    POS_M7_FWD      := 40,    // wysuń pozycjoner kuwet M7

    (* --- Faza: bazowanie windy + paletyzacja --- *)
    ELEV_TO_EDGE    := 50,    // winda w dół do krawędzi (ind_container_in_pos_4 OFF)
    SIGNAL_ROBOT    := 60,    // sygnalizuj robotowi
    WAIT_PALLET_DONE := 70,   // czekaj na zakończenie paletyzacji

    (* --- Faza: rozładunek --- *)
    RETRACT_M7      := 80,    // cofnij M7
    ELEV_TO_BOTTOM  := 90,    // winda na dół
    DISCHARGE       := 100,   // elev_out + bottom jednocześnie
    WAIT_ELEV_EMPTY := 110,   // rozladunek P4->P5 potwierdzony przez BottomAccumulator
    ELEV_RETURN_TOP := 120,   // winda wraca na górę

    FAULT           := 900
);
END_TYPE
