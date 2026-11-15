TYPE ST_TopFlowIn :
STRUCT
    // surowe czujniki (migają w ruchu!)
    sPos1_raw : BOOL; // ind_container_in_pos_1
    sPos2_raw : BOOL; // ind_container_in_pos_2
    sPos3_raw : BOOL; // ind_container_in_pos_3
    sPos4_raw : BOOL; // ind_container_in_pos_4
    TopConveyorRunning : BOOL; // status sterowania górnym transporterem

    // statusy stoperów (z FB_StopperPair)
    StopP1_IsUp   : BOOL; StopP1_IsDown : BOOL; // M2 (pozycja 1)
    StopP2_IsUp   : BOOL; StopP2_IsDown : BOOL; // M3
    StopP3_IsUp   : BOOL; StopP3_IsDown : BOOL; // M4

    // handshake z windą/sek. windy (tylko do transferu na pozycję 4, tryb kuwet)
    Elev_CanAccept    : BOOL; // winda na górze, P4 puste, gotowa do przyjęcia
    Elev_RequestFeed  : BOOL; // "daj mi pojemnik teraz" (priorytet)
    Elev_TransferDone : BOOL; // TRUE gdy P4 jest aktywne stabilnie przez 2 s

    // feedback z pozycjonera M5 (bramka stosu na P3, tylko TrayMode)
    M5_IsUp   : BOOL;
    M5_IsDown : BOOL;

    // sygnał z TraySeq: robot skończył pobierać ze stosu — zwolnij P3
    StackConsumedAtP3 : BOOL;
    LoadBarrierValid : BOOL;
    LoadBarrierBlocked : BOOL;
    DeviceWarning : BOOL;
END_STRUCT
END_TYPE
