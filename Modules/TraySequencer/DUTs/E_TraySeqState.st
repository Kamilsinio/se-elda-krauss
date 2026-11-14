{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_TraySeqState :
(
    DISABLED        := 0,
    IDLE            := 10,
    PAUSED          := 15,

    (* --- Faza: oczekiwanie na stos gotowy do pobrania przez robota --- *)
    // TopFlowManager dostarcza stos do P3, wysuwa M5 (bramkę), cofa M5, podnosi M4
    // TraySeq czeka na sygnał StackReadyAtP3 z TopFlowManagera
    WAIT_STACK_READY := 20,

    (* --- Faza: paletyzacja --- *)
    SIGNAL_ROBOT    := 70,    // sygnalizuj robotowi: stack_ready + elevator_ready
    WAIT_TRAY_DONE  := 80,    // czekaj na sts_pallet_finished (robot położył tackę)
    CHECK_P4_OCCUPIED := 82,  // po sygnale robota potwierdz czujnik P4 przed M6
    POS_M6_CYCLE    := 85,    // wysuń M6, cofnij M6 (pozycjonowanie tacki na windzie)
    ELEV_TO_EDGE    := 90,    // winda w dół do krawędzi pojemnika (ind_container_in_pos_4 OFF)

    (* --- Faza: rozładunek --- *)
    RETRACT_POS     := 110,   // powiadom TopFlowManager: stos zużyty (TopFlow opuszcza M4)
    ELEV_TO_BOTTOM  := 120,   // winda jedzie na dół
    DISCHARGE       := 130,   // uruchom elev_out + bottom_conv (transfer na dolny transporter)
    WAIT_ELEV_EMPTY := 140,   // rozladunek P4->P5 potwierdzony przez BottomAccumulator
    ELEV_RETURN_TOP := 150,   // winda wraca na górę

    FAULT           := 900
);
END_TYPE
