(* GENEROWANE: tools/build_plc_robot.py; kontrakt v2. *)
TYPE ST_RobotRxV2 :
STRUCT
    (* r2p.area.elevator.accessReq: 1: robot żąda dostępu; 0: zwalnia żądanie po opuszczeniu obszaru. *)
    area_elevator_accessReq : BOOL;
    (* r2p.area.elevator.clear: 1: robot faktycznie poza obszarem i nie planuje wejścia bez nowego przyznania; 0: brak zwolnienia. Nie jest safety. *)
    area_elevator_clear : BOOL;
    (* r2p.area.source.accessReq: 1: robot żąda dostępu; 0: zwalnia żądanie po opuszczeniu obszaru. *)
    area_source_accessReq : BOOL;
    (* r2p.area.source.clear: 1: robot faktycznie poza obszarem i nie planuje wejścia bez nowego przyznania; 0: brak zwolnienia. Nie jest safety. *)
    area_source_clear : BOOL;
    (* r2p.area.storage.accessReq: 1: robot żąda dostępu; 0: zwalnia żądanie po opuszczeniu obszaru. *)
    area_storage_accessReq : BOOL;
    (* r2p.area.storage.clear: 1: robot faktycznie poza obszarem i nie planuje wejścia bez nowego przyznania; 0: brak zwolnienia. Nie jest safety. *)
    area_storage_clear : BOOL;
    (* r2p.cyl.V501.home: 1: żądanie pozycji HOME; 0: brak tego żądania. Para 00=brak nowego ruchu, 11=odrzuć. *)
    cyl_V501_home : BOOL;
    (* r2p.cyl.V501.work: 1: żądanie pozycji WORK; 0: brak tego żądania. Para 00=brak nowego ruchu, 11=odrzuć. *)
    cyl_V501_work : BOOL;
    (* r2p.cyl.V502.home: 1: żądanie pozycji HOME; 0: brak tego żądania. Para 00=brak nowego ruchu, 11=odrzuć. *)
    cyl_V502_home : BOOL;
    (* r2p.cyl.V502.work: 1: żądanie pozycji WORK; 0: brak tego żądania. Para 00=brak nowego ruchu, 11=odrzuć. *)
    cyl_V502_work : BOOL;
    (* r2p.cyl.V503.home: 1: żądanie pozycji HOME; 0: brak tego żądania. Para 00=brak nowego ruchu, 11=odrzuć. *)
    cyl_V503_home : BOOL;
    (* r2p.cyl.V503.work: 1: żądanie pozycji WORK; 0: brak tego żądania. Para 00=brak nowego ruchu, 11=odrzuć. *)
    cyl_V503_work : BOOL;
    (* r2p.cyl.V504.home: 1: żądanie pozycji HOME; 0: brak tego żądania. Para 00=brak nowego ruchu, 11=odrzuć. *)
    cyl_V504_home : BOOL;
    (* r2p.cyl.V504.work: 1: żądanie pozycji WORK; 0: brak tego żądania. Para 00=brak nowego ruchu, 11=odrzuć. *)
    cyl_V504_work : BOOL;
    (* r2p.cyl.V505.home: 1: żądanie pozycji HOME; 0: brak tego żądania. Para 00=brak nowego ruchu, 11=odrzuć. *)
    cyl_V505_home : BOOL;
    (* r2p.cyl.V505.work: 1: żądanie pozycji WORK; 0: brak tego żądania. Para 00=brak nowego ruchu, 11=odrzuć. *)
    cyl_V505_work : BOOL;
    (* r2p.event.blisterFinished.req: 1: pojedynczy blister napełniony; nie oznacza ukończenia stosu. *)
    event_blisterFinished_req : BOOL;
    (* r2p.event.blisterPicked.req: 1: nowe zdarzenie blisterPicked; utrzymać do ACK; następne po pełnym wyzerowaniu kanału. *)
    event_blisterPicked_req : BOOL;
    (* r2p.event.blisterPlaced.req: 1: nowe zdarzenie blisterPlaced; utrzymać do ACK; następne po pełnym wyzerowaniu kanału. *)
    event_blisterPlaced_req : BOOL;
    (* r2p.event.immPickupCompleted.req: 1: nowe zdarzenie immPickupCompleted; utrzymać do ACK; następne po pełnym wyzerowaniu kanału. *)
    event_immPickupCompleted_req : BOOL;
    (* r2p.event.layerFinished.req: 1: nowe zdarzenie layerFinished; utrzymać do ACK; następne po pełnym wyzerowaniu kanału. *)
    event_layerFinished_req : BOOL;
    (* r2p.event.productsPlaced.req: 1: nowe zdarzenie productsPlaced; utrzymać do ACK; następne po pełnym wyzerowaniu kanału. *)
    event_productsPlaced_req : BOOL;
    (* r2p.event.samplesPlaced.req: 1: nowe zdarzenie samplesPlaced; utrzymać do ACK; następne po pełnym wyzerowaniu kanału. *)
    event_samplesPlaced_req : BOOL;
    (* r2p.event.spacerPlaced.req: 1: nowe zdarzenie spacerPlaced; utrzymać do ACK; następne po pełnym wyzerowaniu kanału. *)
    event_spacerPlaced_req : BOOL;
    (* r2p.event.stackFinished.req: 1: nowe zdarzenie stackFinished; utrzymać do ACK; następne po pełnym wyzerowaniu kanału. *)
    event_stackFinished_req : BOOL;
    (* r2p.imm.req.ejectorBack: 1: robot żąda procesowego pozwolenia ejectorBack; 0: nie żąda. PLC kontroluje końcowe wyjście. *)
    imm_req_ejectorBack : BOOL;
    (* r2p.imm.req.ejectorForward: 1: robot żąda procesowego pozwolenia ejectorForward; 0: nie żąda. PLC kontroluje końcowe wyjście. *)
    imm_req_ejectorForward : BOOL;
    (* r2p.imm.req.mouldClose: 1: robot żąda procesowego pozwolenia mouldClose; 0: nie żąda. PLC kontroluje końcowe wyjście. *)
    imm_req_mouldClose : BOOL;
    (* r2p.imm.req.mouldFullOpen: 1: robot żąda procesowego pozwolenia mouldFullOpen; 0: nie żąda. PLC kontroluje końcowe wyjście. *)
    imm_req_mouldFullOpen : BOOL;
    (* r2p.link.ready: 1: lokalny interfejs gotowy; 0: brak gotowości, nie jest to pozwolenie ruchu. *)
    link_ready : BOOL;
    (* r2p.link.syncAck: 1: potwierdzenie żądania synchronizacji partnera; 0: brak potwierdzenia. *)
    link_syncAck : BOOL;
    (* r2p.link.syncRequest: 1: żądanie nowej synchronizacji; 0: brak żądania. *)
    link_syncRequest : BOOL;
    (* r2p.production.autoMode: 1: AUTO; 0: poza AUTO. *)
    production_autoMode : BOOL;
    (* r2p.production.estopActive: 1: diagnostyczny E-STOP; nie zastępuje toru bezpieczeństwa. *)
    production_estopActive : BOOL;
    (* r2p.production.fault: 1: błąd FANUC; 0: brak zgłoszonego błędu. *)
    production_fault : BOOL;
    (* r2p.production.home: 1: potwierdzone HOME z monitorowania pozycji; nie ustawiać stale w programie. *)
    production_home : BOOL;
    (* r2p.production.inputSimulated: 1: symulowane wejścia; blokada odbioru produkcyjnego. *)
    production_inputSimulated : BOOL;
    (* r2p.production.loadKnown: 1: maska ładunku uzgodniona z czujnikami; 0: stan nieznany, nie traktować jako pusty. *)
    production_loadKnown : BOOL;
    (* r2p.production.operationsSettled: 1: robot rozliczył pobranie/odłożenie wszystkich przypisanych rozpoczętych wtrysków; nie potwierdza transferów PLC. *)
    production_operationsSettled : BOOL;
    (* r2p.production.outputSimulated: 1: symulowane wyjścia; blokada odbioru produkcyjnego. *)
    production_outputSimulated : BOOL;
    (* r2p.production.running: 1: program produkcyjny wykonuje się; 0: nie wykonuje się. *)
    production_running : BOOL;
    (* r2p.production.stopping: 1: kończenie rozpoczętych operacji. *)
    production_stopping : BOOL;
    (* r2p.production.systemReady: 1: gotowość systemu; 0: brak. *)
    production_systemReady : BOOL;
    (* r2p.production.t1Mode: 1: T1; 0: nie T1. *)
    production_t1Mode : BOOL;
    (* r2p.production.t2Mode: 1: T2; 0: nie T2. *)
    production_t2Mode : BOOL;
    (* r2p.production.tpEnabled: 1: pendant aktywny; 0: nieaktywny. *)
    production_tpEnabled : BOOL;
    (* r2p.production.waitingResume: 1: oczekiwanie na świadome wznowienie. *)
    production_waitingResume : BOOL;
    (* r2p.samples.ack: 1: żądanie próbek przyjęte; nie oznacza odłożenia; ukończenie przez event.samplesPlaced. *)
    samples_ack : BOOL;
    (* r2p.vac.1.blowReq: 1: jednorazowy przedmuch; utrzymać do blowAck; 0: brak/zwolnienie żądania. *)
    vac_1_blowReq : BOOL;
    (* r2p.vac.1.cmdValid: 1: jawnie zadany stan próżni; 0: brak nowego zadania, nie wyłącza samoczynnie podciśnienia. *)
    vac_1_cmdValid : BOOL;
    (* r2p.vac.1.hold: 1: utrzymuj próżnię; 0: żądaj wyłączenia, tylko gdy cmdValid=1. *)
    vac_1_hold : BOOL;
    (* r2p.vac.2.blowReq: 1: jednorazowy przedmuch; utrzymać do blowAck; 0: brak/zwolnienie żądania. *)
    vac_2_blowReq : BOOL;
    (* r2p.vac.2.cmdValid: 1: jawnie zadany stan próżni; 0: brak nowego zadania, nie wyłącza samoczynnie podciśnienia. *)
    vac_2_cmdValid : BOOL;
    (* r2p.vac.2.hold: 1: utrzymuj próżnię; 0: żądaj wyłączenia, tylko gdy cmdValid=1. *)
    vac_2_hold : BOOL;
    (* r2p.vac.3.blowReq: 1: jednorazowy przedmuch; utrzymać do blowAck; 0: brak/zwolnienie żądania. *)
    vac_3_blowReq : BOOL;
    (* r2p.vac.3.cmdValid: 1: jawnie zadany stan próżni; 0: brak nowego zadania, nie wyłącza samoczynnie podciśnienia. *)
    vac_3_cmdValid : BOOL;
    (* r2p.vac.3.hold: 1: utrzymuj próżnię; 0: żądaj wyłączenia, tylko gdy cmdValid=1. *)
    vac_3_hold : BOOL;
    (* r2p.vac.4.blowReq: 1: jednorazowy przedmuch; utrzymać do blowAck; 0: brak/zwolnienie żądania. *)
    vac_4_blowReq : BOOL;
    (* r2p.vac.4.cmdValid: 1: jawnie zadany stan próżni; 0: brak nowego zadania, nie wyłącza samoczynnie podciśnienia. *)
    vac_4_cmdValid : BOOL;
    (* r2p.vac.4.hold: 1: utrzymuj próżnię; 0: żądaj wyłączenia, tylko gdy cmdValid=1. *)
    vac_4_hold : BOOL;
    (* r2p.vac.5.blowReq: 1: jednorazowy przedmuch; utrzymać do blowAck; 0: brak/zwolnienie żądania. *)
    vac_5_blowReq : BOOL;
    (* r2p.vac.5.cmdValid: 1: jawnie zadany stan próżni; 0: brak nowego zadania, nie wyłącza samoczynnie podciśnienia. *)
    vac_5_cmdValid : BOOL;
    (* r2p.vac.5.hold: 1: utrzymuj próżnię; 0: żądaj wyłączenia, tylko gdy cmdValid=1. *)
    vac_5_hold : BOOL;
    (* r2p.link.version: Wersja kontraktu: 2; inna wartość blokuje uzbrojenie. *)
    link_version : UINT;
    (* r2p.link.heartbeat: Licznik 0..65535 modulo 65536; cykliczny niezależnie od WAIT programu. *)
    link_heartbeat : UINT;
    (* r2p.event.blisterFinished.index: Indeks ukończonego blistra od 0, stabilny w całej wymianie. *)
    event_blisterFinished_index : UINT;
    (* r2p.event.blisterFinished.stackId: Identyfikator stosu blistrów, stabilny w całej wymianie. *)
    event_blisterFinished_stackId : UINT;
    (* r2p.event.blisterPicked.stackId: Identyfikator stosu/pojemnika nadany przez PLC; echo production.stackId. Stabilne przed REQ=1 aż do ACK=0; osobny payload każdego kanału. *)
    event_blisterPicked_stackId : UINT;
    (* r2p.event.blisterPlaced.stackId: Identyfikator stosu/pojemnika nadany przez PLC; echo production.stackId. Stabilne przed REQ=1 aż do ACK=0; osobny payload każdego kanału. *)
    event_blisterPlaced_stackId : UINT;
    (* r2p.event.immPickupCompleted.cycleId: Identyfikator rzeczywiście rozpoczętego wtrysku; wiąże zdarzenie z rozliczeniem detali. Stabilne przed REQ=1 aż do ACK=0; osobny payload każdego kanału. *)
    event_immPickupCompleted_cycleId : UINT;
    (* r2p.event.immPickupCompleted.stackId: Identyfikator stosu/pojemnika nadany przez PLC; echo production.stackId. Stabilne przed REQ=1 aż do ACK=0; osobny payload każdego kanału. *)
    event_immPickupCompleted_stackId : UINT;
    (* r2p.event.layerFinished.index: Indeks ukończonej warstwy od 0. Stabilne przed REQ=1 aż do ACK=0; osobny payload każdego kanału. *)
    event_layerFinished_index : UINT;
    (* r2p.event.layerFinished.stackId: Identyfikator stosu/pojemnika nadany przez PLC; echo production.stackId. Stabilne przed REQ=1 aż do ACK=0; osobny payload każdego kanału. *)
    event_layerFinished_stackId : UINT;
    (* r2p.event.productsPlaced.count: Potwierdzona liczba odłożonych detali: UINT 1..65535, nie więcej niż nierozliczona ilość przypisanej partii; niezależna od obwodów próżni. Nastawę stosować tylko przy wyłączonym zleceniu i niepracującej stacji (DEC-18). Payload stabilny przed REQ=1 aż do ACK=0. *)
    event_productsPlaced_count : UINT;
    (* r2p.event.productsPlaced.cycleId: Identyfikator rzeczywiście rozpoczętego wtrysku; wiąże zdarzenie z rozliczeniem detali. Stabilne przed REQ=1 aż do ACK=0; osobny payload każdego kanału. *)
    event_productsPlaced_cycleId : UINT;
    (* r2p.event.productsPlaced.stackId: Identyfikator stosu/pojemnika nadany przez PLC; echo production.stackId. Stabilne przed REQ=1 aż do ACK=0; osobny payload każdego kanału. *)
    event_productsPlaced_stackId : UINT;
    (* r2p.event.samplesPlaced.count: Potwierdzona liczba odłożonych detali: UINT 1..65535, nie więcej niż nierozliczona ilość przypisanej partii; niezależna od obwodów próżni. Nastawę stosować tylko przy wyłączonym zleceniu i niepracującej stacji (DEC-18). Payload stabilny przed REQ=1 aż do ACK=0. *)
    event_samplesPlaced_count : UINT;
    (* r2p.event.samplesPlaced.cycleId: Identyfikator rzeczywiście rozpoczętego wtrysku; wiąże zdarzenie z rozliczeniem detali. Stabilne przed REQ=1 aż do ACK=0; osobny payload każdego kanału. *)
    event_samplesPlaced_cycleId : UINT;
    (* r2p.event.samplesPlaced.stackId: Identyfikator stosu/pojemnika nadany przez PLC; echo production.stackId. Stabilne przed REQ=1 aż do ACK=0; osobny payload każdego kanału. *)
    event_samplesPlaced_stackId : UINT;
    (* r2p.event.spacerPlaced.stackId: Identyfikator stosu/pojemnika nadany przez PLC; echo production.stackId. Stabilne przed REQ=1 aż do ACK=0; osobny payload każdego kanału. *)
    event_spacerPlaced_stackId : UINT;
    (* r2p.event.stackFinished.stackId: Identyfikator stosu/pojemnika nadany przez PLC; echo production.stackId. Stabilne przed REQ=1 aż do ACK=0; osobny payload każdego kanału. *)
    event_stackFinished_stackId : UINT;
    (* r2p.production.faultCode: 0 brak; kod przyczyny, odrębny od miejsca. *)
    production_faultCode : UINT;
    (* r2p.production.loadMask: Bity 0..4: zajęcie fizycznych obwodów próżni 1..5 według potwierdzonego profilu narzędzia; nie liczba detali. W F-2680 obwód 3 dotyczy blistrów. Pozostałe bity 0. Ważne tylko z loadKnown=1. *)
    production_loadMask : UINT;
    (* r2p.production.phase: 0 nieznana; 10 oczekiwanie; 20 pobranie IMM; 30 odkładanie; 40 blister/przekładka; 50 próbki; 60 zatrzymywanie; 70 zatrzymany; 900 błąd/odzyskiwanie. *)
    production_phase : UINT;
    (* r2p.production.program: 0: żaden/nieznany; 1: Pojemniki; 2: Blistry; identyfikacja programu faktycznie uruchomionego. *)
    production_program : UINT;
    (* r2p.production.step: Kod miejsca w procedurze wg robot-modernization.md. *)
    production_step : UINT;
    (* r2p.production.waitCode: 0 brak; 10 synchronizacja; 20 pozwolenie; 30 IMM; 40 siłownik; 50 próżnia; 60 obszar; 70 ACK; 80 operator. *)
    production_waitCode : UINT;
    (* r2p.samples.result: 0 brak; 1 przyjęto; 2 odrzucono; stabilne przy samples.ack=1. *)
    samples_result : UINT;
    (* r2p.event.rejectsPlaced.req: Potwierdzone odłożenie odrzutu do miejsca próbek. Osobny kanał i rozliczenie; nie zwiększa dobrych sztuk ani próbek. Pełny REQ/ACK. *)
    event_rejectsPlaced_req : BOOL;
    (* r2p.event.rejectsPlaced.count: Potwierdzona ilość odłożonej grupy odrzutów 1..65535; nie więcej niż pozostała ilość partii. Stabilne od REQ=1 do ACK=0. *)
    event_rejectsPlaced_count : UINT;
    (* r2p.event.rejectsPlaced.cycleId: Identyfikator partii odrzutów przypisany przed pobraniem. Stabilne od REQ=1 do ACK=0. *)
    event_rejectsPlaced_cycleId : UINT;
    (* r2p.event.rejectsPlaced.stackId: Kontekst stosu w chwili przypisania partii; odrzut nie zapełnia tacki. Stabilne od REQ=1 do ACK=0. *)
    event_rejectsPlaced_stackId : UINT;
END_STRUCT
END_TYPE
