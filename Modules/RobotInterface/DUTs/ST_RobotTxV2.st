(* GENEROWANE: tools/build_plc_robot.py; kontrakt v2. *)
TYPE ST_RobotTxV2 :
STRUCT
    (* p2r.area.elevator.granted: 1: przyznany dostęp do tego obszaru przy utrzymanym accessReq i blokadach. *)
    area_elevator_granted : BOOL;
    (* p2r.area.elevator.ready: 1: materiał/urządzenie gotowe; nie jest przyznaniem dostępu. *)
    area_elevator_ready : BOOL;
    (* p2r.area.elevator.valid: 1: aktualne dane zależnych urządzeń. *)
    area_elevator_valid : BOOL;
    (* p2r.area.source.granted: 1: przyznany dostęp do tego obszaru przy utrzymanym accessReq i blokadach. *)
    area_source_granted : BOOL;
    (* p2r.area.source.ready: 1: materiał/urządzenie gotowe; nie jest przyznaniem dostępu. *)
    area_source_ready : BOOL;
    (* p2r.area.source.valid: 1: aktualne dane zależnych urządzeń. *)
    area_source_valid : BOOL;
    (* p2r.area.storage.granted: 1: przyznany dostęp do tego obszaru przy utrzymanym accessReq i blokadach. *)
    area_storage_granted : BOOL;
    (* p2r.area.storage.ready: 1: materiał/urządzenie gotowe; nie jest przyznaniem dostępu. *)
    area_storage_ready : BOOL;
    (* p2r.area.storage.valid: 1: aktualne dane zależnych urządzeń. *)
    area_storage_valid : BOOL;
    (* p2r.cyl.V501.acceptedHome: 1: bieżące żądanie HOME przyjęte przez arbitraż. *)
    cyl_V501_acceptedHome : BOOL;
    (* p2r.cyl.V501.acceptedWork: 1: bieżące żądanie WORK przyjęte przez arbitraż. *)
    cyl_V501_acceptedWork : BOOL;
    (* p2r.cyl.V501.atHome: 1: rzeczywiste HOME po filtracji; 0: brak potwierdzenia HOME. *)
    cyl_V501_atHome : BOOL;
    (* p2r.cyl.V501.atWork: 1: rzeczywiste WORK po filtracji; 0: brak potwierdzenia WORK. *)
    cyl_V501_atWork : BOOL;
    (* p2r.cyl.V501.busy: 1: trwa ruch do przyjętego celu. *)
    cyl_V501_busy : BOOL;
    (* p2r.cyl.V501.valid: 1: aktualne czujniki i diagnostyka; 0: nie używać potwierdzeń. *)
    cyl_V501_valid : BOOL;
    (* p2r.cyl.V502.acceptedHome: 1: bieżące żądanie HOME przyjęte przez arbitraż. *)
    cyl_V502_acceptedHome : BOOL;
    (* p2r.cyl.V502.acceptedWork: 1: bieżące żądanie WORK przyjęte przez arbitraż. *)
    cyl_V502_acceptedWork : BOOL;
    (* p2r.cyl.V502.atHome: 1: rzeczywiste HOME po filtracji; 0: brak potwierdzenia HOME. *)
    cyl_V502_atHome : BOOL;
    (* p2r.cyl.V502.atWork: 1: rzeczywiste WORK po filtracji; 0: brak potwierdzenia WORK. *)
    cyl_V502_atWork : BOOL;
    (* p2r.cyl.V502.busy: 1: trwa ruch do przyjętego celu. *)
    cyl_V502_busy : BOOL;
    (* p2r.cyl.V502.valid: 1: aktualne czujniki i diagnostyka; 0: nie używać potwierdzeń. *)
    cyl_V502_valid : BOOL;
    (* p2r.cyl.V503.acceptedHome: 1: bieżące żądanie HOME przyjęte przez arbitraż. *)
    cyl_V503_acceptedHome : BOOL;
    (* p2r.cyl.V503.acceptedWork: 1: bieżące żądanie WORK przyjęte przez arbitraż. *)
    cyl_V503_acceptedWork : BOOL;
    (* p2r.cyl.V503.atHome: 1: rzeczywiste HOME po filtracji; 0: brak potwierdzenia HOME. *)
    cyl_V503_atHome : BOOL;
    (* p2r.cyl.V503.atWork: 1: rzeczywiste WORK po filtracji; 0: brak potwierdzenia WORK. *)
    cyl_V503_atWork : BOOL;
    (* p2r.cyl.V503.busy: 1: trwa ruch do przyjętego celu. *)
    cyl_V503_busy : BOOL;
    (* p2r.cyl.V503.valid: 1: aktualne czujniki i diagnostyka; 0: nie używać potwierdzeń. *)
    cyl_V503_valid : BOOL;
    (* p2r.cyl.V504.acceptedHome: 1: bieżące żądanie HOME przyjęte przez arbitraż. *)
    cyl_V504_acceptedHome : BOOL;
    (* p2r.cyl.V504.acceptedWork: 1: bieżące żądanie WORK przyjęte przez arbitraż. *)
    cyl_V504_acceptedWork : BOOL;
    (* p2r.cyl.V504.atHome: 1: rzeczywiste HOME po filtracji; 0: brak potwierdzenia HOME. *)
    cyl_V504_atHome : BOOL;
    (* p2r.cyl.V504.atWork: 1: rzeczywiste WORK po filtracji; 0: brak potwierdzenia WORK. *)
    cyl_V504_atWork : BOOL;
    (* p2r.cyl.V504.busy: 1: trwa ruch do przyjętego celu. *)
    cyl_V504_busy : BOOL;
    (* p2r.cyl.V504.valid: 1: aktualne czujniki i diagnostyka; 0: nie używać potwierdzeń. *)
    cyl_V504_valid : BOOL;
    (* p2r.cyl.V505.acceptedHome: 1: bieżące żądanie HOME przyjęte przez arbitraż. *)
    cyl_V505_acceptedHome : BOOL;
    (* p2r.cyl.V505.acceptedWork: 1: bieżące żądanie WORK przyjęte przez arbitraż. *)
    cyl_V505_acceptedWork : BOOL;
    (* p2r.cyl.V505.atHome: 1: rzeczywiste HOME po filtracji; 0: brak potwierdzenia HOME. *)
    cyl_V505_atHome : BOOL;
    (* p2r.cyl.V505.atWork: 1: rzeczywiste WORK po filtracji; 0: brak potwierdzenia WORK. *)
    cyl_V505_atWork : BOOL;
    (* p2r.cyl.V505.busy: 1: trwa ruch do przyjętego celu. *)
    cyl_V505_busy : BOOL;
    (* p2r.cyl.V505.valid: 1: aktualne czujniki i diagnostyka; 0: nie używać potwierdzeń. *)
    cyl_V505_valid : BOOL;
    (* p2r.event.blisterFinished.ack: 1: ukończenie pojedynczego blistra zarejestrowane raz. *)
    event_blisterFinished_ack : BOOL;
    (* p2r.event.blisterPicked.ack: 1: zdarzenie blisterPicked zarejestrowane dokładnie raz w bieżącej sesji; 0: kanał wolny po req=0. *)
    event_blisterPicked_ack : BOOL;
    (* p2r.event.blisterPlaced.ack: 1: zdarzenie blisterPlaced zarejestrowane dokładnie raz w bieżącej sesji; 0: kanał wolny po req=0. *)
    event_blisterPlaced_ack : BOOL;
    (* p2r.event.immPickupCompleted.ack: 1: zdarzenie immPickupCompleted zarejestrowane dokładnie raz w bieżącej sesji; 0: kanał wolny po req=0. *)
    event_immPickupCompleted_ack : BOOL;
    (* p2r.event.layerFinished.ack: 1: zdarzenie layerFinished zarejestrowane dokładnie raz w bieżącej sesji; 0: kanał wolny po req=0. *)
    event_layerFinished_ack : BOOL;
    (* p2r.event.productsPlaced.ack: 1: zdarzenie productsPlaced zarejestrowane dokładnie raz w bieżącej sesji; 0: kanał wolny po req=0. *)
    event_productsPlaced_ack : BOOL;
    (* p2r.event.samplesPlaced.ack: 1: zdarzenie samplesPlaced zarejestrowane dokładnie raz w bieżącej sesji; 0: kanał wolny po req=0. *)
    event_samplesPlaced_ack : BOOL;
    (* p2r.event.spacerPlaced.ack: 1: zdarzenie spacerPlaced zarejestrowane dokładnie raz w bieżącej sesji; 0: kanał wolny po req=0. *)
    event_spacerPlaced_ack : BOOL;
    (* p2r.event.stackFinished.ack: 1: zdarzenie stackFinished zarejestrowane dokładnie raz w bieżącej sesji; 0: kanał wolny po req=0. *)
    event_stackFinished_ack : BOOL;
    (* p2r.imm.applied.ejectorBack: 1: końcowy procesowy sygnał ejectorBack wystawiony po arbitrażu; 0: niewystawiony. Nie potwierdza ruchu maszyny. *)
    imm_applied_ejectorBack : BOOL;
    (* p2r.imm.applied.ejectorForward: 1: końcowy procesowy sygnał ejectorForward wystawiony po arbitrażu; 0: niewystawiony. Nie potwierdza ruchu maszyny. *)
    imm_applied_ejectorForward : BOOL;
    (* p2r.imm.applied.mouldClose: 1: końcowy procesowy sygnał mouldClose wystawiony po arbitrażu; 0: niewystawiony. Nie potwierdza ruchu maszyny. *)
    imm_applied_mouldClose : BOOL;
    (* p2r.imm.applied.mouldFullOpen: 1: końcowy procesowy sygnał mouldFullOpen wystawiony po arbitrażu; 0: niewystawiony. Nie potwierdza ruchu maszyny. *)
    imm_applied_mouldFullOpen : BOOL;
    (* p2r.imm.cycleKnown: 1: model rozpoczętych wtrysków uzgodniony; 0: stan nieznany, blokada nowych cykli. *)
    imm_cycleKnown : BOOL;
    (* p2r.imm.ejectorBack: 1: wyrzutnik w pozycji tylnej. *)
    imm_ejectorBack : BOOL;
    (* p2r.imm.ejectorForward: 1: wyrzutnik w pozycji przedniej. *)
    imm_ejectorForward : BOOL;
    (* p2r.imm.mouldClosed: 1: potwierdzona forma zamknięta; nie dowodzi rozpoczęcia wtrysku. *)
    imm_mouldClosed : BOOL;
    (* p2r.imm.mouldIntermediate: 1: potwierdzona pozycja pośrednia; dostępność wg GAP-05. *)
    imm_mouldIntermediate : BOOL;
    (* p2r.imm.mouldOpen: 1: potwierdzona forma otwarta. *)
    imm_mouldOpen : BOOL;
    (* p2r.imm.newCyclePermit: 1: PLC pozwala na nowy wtrysk w bieżącej fazie; 0: blokada nowych wtrysków. *)
    imm_newCyclePermit : BOOL;
    (* p2r.imm.pickupPending: 1: cycleId przydzielono do nowego pobrania i jeszcze go nie potwierdzono przez immPickupCompleted; 0: nie rozpoczynać ponownego pobrania tego identyfikatora. *)
    imm_pickupPending : BOOL;
    (* p2r.imm.reject: 1: odrzut detali w powiązanym cyklu; 0: brak odrzutu. *)
    imm_reject : BOOL;
    (* p2r.imm.settled: 1: rozliczone rozpoczęte wtryski i wymagane operacje maszyny. *)
    imm_settled : BOOL;
    (* p2r.imm.valid: 1: dane EUROMAP aktualne i znormalizowane; 0: nieważne. *)
    imm_valid : BOOL;
    (* p2r.imm.withRobot: 1: maszyna potwierdza współpracę z robotem po normalizacji. *)
    imm_withRobot : BOOL;
    (* p2r.link.ready: 1: lokalny interfejs gotowy; 0: brak gotowości, nie jest to pozwolenie ruchu. *)
    link_ready : BOOL;
    (* p2r.link.syncAck: 1: potwierdzenie żądania synchronizacji partnera; 0: brak potwierdzenia. *)
    link_syncAck : BOOL;
    (* p2r.link.syncRequest: 1: żądanie nowej synchronizacji; 0: brak żądania. *)
    link_syncRequest : BOOL;
    (* p2r.production.criticalBlock: 1: blokada krytyczna; 0: brak zgłoszonej blokady. Nie jest sygnałem safety. *)
    production_criticalBlock : BOOL;
    (* p2r.production.endOrderRequest: 1: zakończyć operacje; PLC następnie opróżnia stację. *)
    production_endOrderRequest : BOOL;
    (* p2r.production.finishPermit: 1: dozwolone dokończenie rozliczanych operacji przy spełnionych blokadach; 0: brak pozwolenia. *)
    production_finishPermit : BOOL;
    (* p2r.production.newOperationPermit: 1: można rozpocząć nową operację produkcyjną; 0: nie rozpoczynać kolejnej. *)
    production_newOperationPermit : BOOL;
    (* p2r.production.orderActive: 1: zlecenie otwarte; 0: brak aktywnego zlecenia. *)
    production_orderActive : BOOL;
    (* p2r.production.recoveryRequired: 1: wymagane uzgodnienie stanu; 0: uzgodniony stan. *)
    production_recoveryRequired : BOOL;
    (* p2r.production.stopRequest: 1: normalny Stop; trzymać do rozliczenia i świadomego wznowienia. *)
    production_stopRequest : BOOL;
    (* p2r.production.withRobot: 1: współpraca wybrana; 0: samodzielny Krauss po wymaganym Stop i HOME. *)
    production_withRobot : BOOL;
    (* p2r.samples.req: 1: jednorazowe żądanie odłożenia próbek; 0: zwolnienie kanału po ACK. *)
    samples_req : BOOL;
    (* p2r.vac.1.accepted: 1: bieżący cmdValid/hold został przyjęty. *)
    vac_1_accepted : BOOL;
    (* p2r.vac.1.blowAck: 1: terminalny wynik przedmuchu dostępny; trzymany do blowReq=0. *)
    vac_1_blowAck : BOOL;
    (* p2r.vac.1.busy: 1: wykonywanie przedmuchu lub oczekiwanie na próg po przyjętym zadaniu. *)
    vac_1_busy : BOOL;
    (* p2r.vac.1.holdApplied: 1: końcowa komenda próżni jest załączona; nie jest pomiarem podciśnienia. *)
    vac_1_holdApplied : BOOL;
    (* p2r.vac.1.ok: 1: rzeczywiste podciśnienie OK; 0: próg nieosiągnięty; ważne z valid. *)
    vac_1_ok : BOOL;
    (* p2r.vac.1.valid: 1: aktualne wejścia i diagnostyka obwodu. *)
    vac_1_valid : BOOL;
    (* p2r.vac.2.accepted: 1: bieżący cmdValid/hold został przyjęty. *)
    vac_2_accepted : BOOL;
    (* p2r.vac.2.blowAck: 1: terminalny wynik przedmuchu dostępny; trzymany do blowReq=0. *)
    vac_2_blowAck : BOOL;
    (* p2r.vac.2.busy: 1: wykonywanie przedmuchu lub oczekiwanie na próg po przyjętym zadaniu. *)
    vac_2_busy : BOOL;
    (* p2r.vac.2.holdApplied: 1: końcowa komenda próżni jest załączona; nie jest pomiarem podciśnienia. *)
    vac_2_holdApplied : BOOL;
    (* p2r.vac.2.ok: 1: rzeczywiste podciśnienie OK; 0: próg nieosiągnięty; ważne z valid. *)
    vac_2_ok : BOOL;
    (* p2r.vac.2.valid: 1: aktualne wejścia i diagnostyka obwodu. *)
    vac_2_valid : BOOL;
    (* p2r.vac.3.accepted: 1: bieżący cmdValid/hold został przyjęty. *)
    vac_3_accepted : BOOL;
    (* p2r.vac.3.blowAck: 1: terminalny wynik przedmuchu dostępny; trzymany do blowReq=0. *)
    vac_3_blowAck : BOOL;
    (* p2r.vac.3.busy: 1: wykonywanie przedmuchu lub oczekiwanie na próg po przyjętym zadaniu. *)
    vac_3_busy : BOOL;
    (* p2r.vac.3.holdApplied: 1: końcowa komenda próżni jest załączona; nie jest pomiarem podciśnienia. *)
    vac_3_holdApplied : BOOL;
    (* p2r.vac.3.ok: 1: rzeczywiste podciśnienie OK; 0: próg nieosiągnięty; ważne z valid. *)
    vac_3_ok : BOOL;
    (* p2r.vac.3.valid: 1: aktualne wejścia i diagnostyka obwodu. *)
    vac_3_valid : BOOL;
    (* p2r.vac.4.accepted: 1: bieżący cmdValid/hold został przyjęty. *)
    vac_4_accepted : BOOL;
    (* p2r.vac.4.blowAck: 1: terminalny wynik przedmuchu dostępny; trzymany do blowReq=0. *)
    vac_4_blowAck : BOOL;
    (* p2r.vac.4.busy: 1: wykonywanie przedmuchu lub oczekiwanie na próg po przyjętym zadaniu. *)
    vac_4_busy : BOOL;
    (* p2r.vac.4.holdApplied: 1: końcowa komenda próżni jest załączona; nie jest pomiarem podciśnienia. *)
    vac_4_holdApplied : BOOL;
    (* p2r.vac.4.ok: 1: rzeczywiste podciśnienie OK; 0: próg nieosiągnięty; ważne z valid. *)
    vac_4_ok : BOOL;
    (* p2r.vac.4.valid: 1: aktualne wejścia i diagnostyka obwodu. *)
    vac_4_valid : BOOL;
    (* p2r.vac.5.accepted: 1: bieżący cmdValid/hold został przyjęty. *)
    vac_5_accepted : BOOL;
    (* p2r.vac.5.blowAck: 1: terminalny wynik przedmuchu dostępny; trzymany do blowReq=0. *)
    vac_5_blowAck : BOOL;
    (* p2r.vac.5.busy: 1: wykonywanie przedmuchu lub oczekiwanie na próg po przyjętym zadaniu. *)
    vac_5_busy : BOOL;
    (* p2r.vac.5.holdApplied: 1: końcowa komenda próżni jest załączona; nie jest pomiarem podciśnienia. *)
    vac_5_holdApplied : BOOL;
    (* p2r.vac.5.ok: 1: rzeczywiste podciśnienie OK; 0: próg nieosiągnięty; ważne z valid. *)
    vac_5_ok : BOOL;
    (* p2r.vac.5.valid: 1: aktualne wejścia i diagnostyka obwodu. *)
    vac_5_valid : BOOL;
    (* p2r.link.version: Wersja kontraktu: 2; inna wartość blokuje uzbrojenie. *)
    link_version : UINT;
    (* p2r.link.heartbeat: Licznik 0..65535 modulo 65536; cykliczny niezależnie od WAIT programu. *)
    link_heartbeat : UINT;
    (* p2r.area.elevator.reason: Kod blokady/oczekiwania; jak dla urządzeń. *)
    area_elevator_reason : UINT;
    (* p2r.area.source.reason: Kod blokady/oczekiwania; jak dla urządzeń. *)
    area_source_reason : UINT;
    (* p2r.area.storage.reason: Kod blokady/oczekiwania; jak dla urządzeń. *)
    area_storage_reason : UINT;
    (* p2r.cyl.V501.reason: 0 brak; 10 brak sesji; 20 tryb; 30 blokada; 40 konflikt; 50 nieaktualne wejścia; 60 timeout; 70 sprzeczne czujniki; 80 odzyskiwanie. *)
    cyl_V501_reason : UINT;
    (* p2r.cyl.V502.reason: 0 brak; 10 brak sesji; 20 tryb; 30 blokada; 40 konflikt; 50 nieaktualne wejścia; 60 timeout; 70 sprzeczne czujniki; 80 odzyskiwanie. *)
    cyl_V502_reason : UINT;
    (* p2r.cyl.V503.reason: 0 brak; 10 brak sesji; 20 tryb; 30 blokada; 40 konflikt; 50 nieaktualne wejścia; 60 timeout; 70 sprzeczne czujniki; 80 odzyskiwanie. *)
    cyl_V503_reason : UINT;
    (* p2r.cyl.V504.reason: 0 brak; 10 brak sesji; 20 tryb; 30 blokada; 40 konflikt; 50 nieaktualne wejścia; 60 timeout; 70 sprzeczne czujniki; 80 odzyskiwanie. *)
    cyl_V504_reason : UINT;
    (* p2r.cyl.V505.reason: 0 brak; 10 brak sesji; 20 tryb; 30 blokada; 40 konflikt; 50 nieaktualne wejścia; 60 timeout; 70 sprzeczne czujniki; 80 odzyskiwanie. *)
    cyl_V505_reason : UINT;
    (* p2r.imm.cycleId: Identyfikator rzeczywiście rozpoczętego cyklu przydzielonego do pobrania; utrzymać do końca handshake immPickupCompleted. Następne starty PLC zapisuje osobno. Modulo 65536. *)
    imm_cycleId : UINT;
    (* p2r.imm.reason: Kod blokady w ImmInterface; jak dla urządzeń. *)
    imm_reason : UINT;
    (* p2r.imm.unsettledCount: Liczba rozpoczętych wtrysków, których robot jeszcze nie rozliczył; prowadzi PLC. *)
    imm_unsettledCount : UINT;
    (* p2r.production.blockCode: 0: brak; kody diagnostyczne według kontraktu. *)
    production_blockCode : UINT;
    (* p2r.production.expectedProgram: 0: brak wyboru; 1: Pojemniki; 2: Blistry. Nie wybiera programu na FANUC. *)
    production_expectedProgram : UINT;
    (* p2r.production.stackId: Identyfikator aktualnego stosu/pojemnika nadany przez PLC; nie zmieniać przed zakończeniem wymian tego stosu. *)
    production_stackId : UINT;
    (* p2r.vac.1.blowResult: 0 brak; 1 impuls zakończony i potwierdzenie zwolnienia aktualne; 2 odrzucono; 3 usterka/timeout. Stabilne przy blowAck=1. *)
    vac_1_blowResult : UINT;
    (* p2r.vac.1.reason: Kody przyczyn jak dla siłowników; 90 utrata próżni; 100 brak potwierdzonej konfiguracji przedmuchu. *)
    vac_1_reason : UINT;
    (* p2r.vac.2.blowResult: 0 brak; 1 impuls zakończony i potwierdzenie zwolnienia aktualne; 2 odrzucono; 3 usterka/timeout. Stabilne przy blowAck=1. *)
    vac_2_blowResult : UINT;
    (* p2r.vac.2.reason: Kody przyczyn jak dla siłowników; 90 utrata próżni; 100 brak potwierdzonej konfiguracji przedmuchu. *)
    vac_2_reason : UINT;
    (* p2r.vac.3.blowResult: 0 brak; 1 impuls zakończony i potwierdzenie zwolnienia aktualne; 2 odrzucono; 3 usterka/timeout. Stabilne przy blowAck=1. *)
    vac_3_blowResult : UINT;
    (* p2r.vac.3.reason: Kody przyczyn jak dla siłowników; 90 utrata próżni; 100 brak potwierdzonej konfiguracji przedmuchu. *)
    vac_3_reason : UINT;
    (* p2r.vac.4.blowResult: 0 brak; 1 impuls zakończony i potwierdzenie zwolnienia aktualne; 2 odrzucono; 3 usterka/timeout. Stabilne przy blowAck=1. *)
    vac_4_blowResult : UINT;
    (* p2r.vac.4.reason: Kody przyczyn jak dla siłowników; 90 utrata próżni; 100 brak potwierdzonej konfiguracji przedmuchu. *)
    vac_4_reason : UINT;
    (* p2r.vac.5.blowResult: 0 brak; 1 impuls zakończony i potwierdzenie zwolnienia aktualne; 2 odrzucono; 3 usterka/timeout. Stabilne przy blowAck=1. *)
    vac_5_blowResult : UINT;
    (* p2r.vac.5.reason: Kody przyczyn jak dla siłowników; 90 utrata próżni; 100 brak potwierdzonej konfiguracji przedmuchu. *)
    vac_5_reason : UINT;
    (* p2r.imm.batchCount: Ilość sztuk przypisana do przydzielonego cycleId (1..65535). Stabilna wraz z cycleId i reject do końca handshake immPickupCompleted; nie bieżący parametr HMI. *)
    imm_batchCount : UINT;
    (* p2r.production.startToken: Licznik modulo 65536 zwiększany wyłącznie po przyjętym fizycznym Start. Zastana wartość po inicjalizacji/recovery nie uruchamia pracy; potrzebna kolejna zmiana. Nie jest zdalnym START UOP. *)
    production_startToken : UINT;
    (* p2r.event.rejectsPlaced.ack: Odrzut zarejestrowany raz dla bieżącego REQ; utrzymać ACK do REQ=0. *)
    event_rejectsPlaced_ack : BOOL;
END_STRUCT
END_TYPE
