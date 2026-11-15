# Moduły stacji PLC — implementacja źródeł

Stan: 2026-11-15. **ŹRÓDŁA I TESTY OFFLINE. Nie wykonano kompilacji Machine Expert, importu FANUC ani FAT/SAT.**

Pakiet uzupełnia [integrację PLC–robot](plc-robot-implementation.md). Kontrakt robota pozostaje v2: 227 pól, 80 B/kierunek, niezmieniony layout. Kontekst PLC ma teraz **schema=4**, a interfejs HMI **uiContractVersion=4**. Są to niezależne wersje.

Aktualną architekturę Controller/DriveAdapter/StationRecovery, zasoby, ID operacji i migrację opisuje [integracja całej stacji](station-integration.md).

## 1. Moduły i odpowiedzialność

| Moduł | Odpowiedzialność | Wymagania / próby |
|---|---|---|
| FB_StationController | Typowane porty, kolejność skanu i końcowa finalizacja wyjść | REQ-01–22, próby integracyjne |
| FB_ElevatorDriveAdapter | Jedyny natywny GIATV i ważny feedback prędkości | GAP-06, odbiór natywny OTWARTY |
| FB_StationRecovery | Uzgodnienie materiału po Manual i przerwanym transferze | REQ-19/21, AT-13 |
| FB_StationIo | Filtracja obu stanów wejść, ważność obrazu i modułów, osobna bariera ST.1 | REQ-08/13, AT-06/09 |
| FB_StationMaterial | Model P1–P7 i windy; zachowanie ładunku między czujnikami, odroczony commit po ruchu | REQ-05/19/21, AT-04/13 |
| FB_StationTransport | Właściciel produkcja/drain/lokalny/manual, zachowanie rozpoczętej operacji | REQ-03/05/06/21, AT-02/04/05 |
| FB_StationDrain | Wykonawca pełnego opróżniania, pauza i wynik powiązany z request | REQ-05/07, AT-04/05 |
| FB_AlarmManager | 64 miejsca, katalog 52 źródeł, active/ACK/returned/reset, andon i blokada niepełnej polityki | REQ-16/17/20, AT-11/12 |
| FB_StationManual | 16 ruchów stacyjnych, sesja/strona i indywidualne watchdogi | REQ-09/10/20, AT-07/14 |
| FB_StationParameters | Apply/Reload ST.1–ST.4, pełny snapshot, rewizja i zakresy | REQ-16/20, próby HMI |
| FB_StationHmi | Wspólna prezentacja zajętości, kroku, właściciela, pauzy i blokad | REQ-20/22, AT-14 |

Każdy FB ma własny katalog i osobne DUT. Zmieniono również OrderManager, TopFlow, BottomAccumulator, Storage, arbitraż cewek, nadzór robota, recovery i PRG_Main. Nie dodano technologicznych podprogramów FANUC.

## 2. Publiczne interfejsy i ważność

`GVL_Station` jest interfejsem adaptera sprzętowego i konfiguracji. Żadne nowe pole nie ma adresu AT. Poniżej kierunki dotyczą PLC; HMI odczytuje statusy i zapisuje wyłącznie żądania/bufory.

| Pole / źródło → odbiorca | Znaczenie i potwierdzenie | Utrata ważności |
|---|---|---|
| IoCfg.configured/stable/required[1..12], konfiguracja → StationIo | Zatwierdzenie konfiguracji, czas filtracji i wymagane moduły. Nie są pomiarem health. | Brak configured, dodatniego czasu lub wymaganego modułu unieważnia obraz. |
| Inputs.mappingVerified/gatewayHealthy/imageFresh/moduleHealthy, adapter → StationIo | Mapowanie oraz rzeczywista diagnostyka skanera/bramki/AP. TRUE wymaga danych urządzenia. | Brak ważnego obrazu blokuje ruch; powrót wymaga uzgodnienia modelu materiału. |
| Inputs.occupied/positionValid[1..7], adapter → StationIo | Logiczne P1–P7. TRUE=czujnik aktywny; FALSE nie dowodzi braku całego ładunku, zwłaszcza B205. Osobna ważność każdego punktu. | Ostatnia wartość pozostaje diagnostyczna, ważność spada. Nie daje potwierdzenia pustej stacji. |
| Inputs.barrierBlocked/barrierValid, adapter → TopFlow | Osobna bariera ST.1: zasłonięcie i późniejsze zwolnienie potwierdzają pełny przejazd. | Brak ważności blokuje nowe podanie z P1 i potwierdzenie jego zwolnienia. |
| Inputs.beltsStopped[1..3], adapter → transport/arbitraż | Potwierdzone zatrzymanie taśmy górnej, windy i dolnej; nie sam brak komendy RUN. | Brak potwierdzenia nie dopuszcza zmiany stoperów ani Apply w postoju. |
| Inputs.v201/v202/lowerStop[1..2]/lowerFeedbackValid, adapter → urządzenia | Oddzielne HOME/WORK i jawne potwierdzenie mapowania dolnych grup. | Nieważne dane nie dopuszczają zależnego ruchu. |
| ElevatorCfg/ElevatorCfgVerified, konfiguracja → Elevator | Kierunki, maski i techniczne parametry napędu, potwierdzone niezależnie od nastaw operatora. | Brak zatwierdzenia blokuje ruch. GIATV/Axis_Ref nadal wymagają projektu natywnego. |
| ManualInterlocks, adapter blokad → StationManual | allowPositive/Negative[1..16] są dodatkowym dopuszczeniem danego kierunku, domyślnie FALSE. PLC dokłada stan trybu, obszarów, taśm i sesji. | Wygaśnięcie autoryzacji wymaga zwolnienia i nowego naciśnięcia. |
| ManualRelease/ManualReleaseVerified, konfiguracja → StationCoils | Potwierdzona polityka po odebraniu ręcznego żądania, osobna od utraty komunikacji. | Brak zatwierdzenia blokuje Manual; nie zakłada się uniwersalnego wyłączenia cewek. |
| V201Out/V202Out/LowerStopOut, StationCoils → adapter | Końcowe komendy HOME/WORK; TRUE oznacza komendę, nie potwierdzenie pozycji. | Stosowana jest wyłącznie zatwierdzona polityka zaniku. |
| DiagnosticValue/DiagnosticValid, adapter → hmiIo | Wartości wejść diagnostycznych według nazw z mapy 159 aliasów. To odczyt, bez wymuszania. | valid=FALSE oznacza brak danych, nie FALSE procesu. |

Indeksy required/moduleHealthy/moduleValid[1..12] zachowują kolejność mapy HMI: 1=BAT100, 2=BAT101, 3=BAT200, 4=BAT201, 5=BAT202, 6=BAT203, 7=BAT204, 8=BAT205, 9=BAT300, 10=BAT301, 11=BAT400, 12=BAT401. Są indeksami logicznymi, nie slotami ani osobnymi adresami IP.

Wszystkie ustawienia verified/configured i ważności startują od FALSE. RAW i historyczne adresy pozostają niezatwierdzoną warstwą sprzętową do powiązania przed uruchomieniem. Wejścia B301, Start/Stop, bezpieczeństwo i osłony wymagają spójnej weryfikacji z tą samą mapą. PhysicalStop nadal jest osobnym bindingiem Plant; nie przypisano go do starego Continue.

**Właściciele wyjść:** StationCoils obsługuje 10 grup: 1=M1, 2=M2, 3=M3, 4=M4, 5=M5, 6=V201, 7=V203, 8=V202, 9=V301/V302, 10=V303/V304. Powiązania M1–M5 z nową mechaniką nadal wymagają GAP-08. Stare wyjście M6 jest odłączone. Storage pozostaje właścicielem V401/V402, RobotGripper chwytaka, ImmInterface logicznych wyjść EUROMAP, a bloki napędów ruchu transporterów/windy. Adapter nie tworzy drugiego arbitrażu.

## 3. Proces, Stop i odzyskiwanie

**POTWIERDZONE w tym zadaniu:**

- Koniec zlecenia w pracy kończy rozpoczęte operacje, po czym uruchamia opróżnianie. Koniec z postoju wymaga fizycznego Start; w Manual także powrotu do Auto.
- Stop podczas opróżniania kończy przyjętą operację i pauzuje następne. Manual jest dostępny w postoju; powrót do Auto sam nie wznawia.
- Lokalny przycisk może wydać jeden gotowy ładunek w Auto przy aktywnym zleceniu również podczas postoju/pauzy. Nie wznawia pełnego opróżniania. Brak gotowości oznacza odrzucenie bez kolejki.
- Drain.request jest podtrzymywany od rozpoczęcia transakcji do odebrania wyniku. runPermit osobno dopuszcza nowy ruch. Spadek runPermit nie odbiera właściciela rozpoczętej operacji.
- connected pochodzi od rzeczywiście wywoływanego FB_StationDrain. accepted/busy/done/fault/emptyConfirmed są jego odpowiedzią. Wynik wraca do zera po request=0; OrderManager wymaga neutralnego podłączenia i świeżego przyjęcia.
- ST.3 oddziela P4→P5, przesunięcie P5→P6 i wydanie jednego ładunku do P7/B304. Wydanie kończy powiązane z nim filtrowane B304=1, potem B304=0. Oczekiwanie na operatora nie ma timeoutu ruchu.
- Najpierw zwalniane jest potrzebne miejsce na dole i ładunek windy; następnie reszta górnych buforów. Pozostały pusty stos blistrów jedzie w całości. Ostatni odbiór jest warunkiem zamknięcia zlecenia.
- Timeout siłownika ST.1–ST.4 blokuje zależną czynność. TopFlow nie dodaje wtórnego krytycznego timeoutu tego samego oczekiwania.

Retencja schema=4 obejmuje dodatkowo fazę i właściciela opróżniania, odbiór B304, aktywne nastawy i rewizje. Schema=2/3 jest odrzucane przez walidację. Zachować kopię dotychczasowych danych; nie nadpisywać ich pustym kontekstem w celu obejścia migracji. Proposal wymaga jawnego uzgodnienia ładunków, cykli i transferów do postoju. Stan kroku jest diagnostyczny, bez automatycznego odtwarzania ruchu w połowie transferu.

Ruch Manual unieważnia model materiału. Dopuszczone ruchy ręczne można zakończyć w Manual; po powrocie do Auto nadzór wymusza recovery. ResetState nie usuwa ładunków, liczników ani zobowiązań i również wymaga uzgodnienia. Reset i powrót łączności nie udzielają Start.

## 4. HMI, parametry i alarmy

Sesję, monotoniczne ID, neutralizację i czterofazową transakcję nadal prowadzi jeden FB_RobotHmi. Dodano station1–4ParamApply, station1–5ParamReload, station1–5ResetState i alarmAckAll. Dalszy wynik semantyczny wraca z głównej integracji; samo przyjęcie transportu HMI nie oznacza zakończenia ruchu. Snapshot parametrów jest zamrożony przy przyjęciu żądania.

Publiczne pola: hmiV2.station, stationManual, immManual, stationEdit[1..4], stationActual, stationRevision, stationEditRevision oraz dotychczasowe edit/actual dla ilości ST.5. Apply wymaga postoju, zgodnej rewizji i zweryfikowanych zakresów ParameterCfg; zlecenie może pozostać otwarte. Ilość detali nadal wymaga zamkniętego zlecenia. Reload kopiuje aktywne dane i rewizję. Nie zerować rewizji po wyczerpaniu UINT bez kontrolowanej migracji.

Zestaw ST.1–ST.4 zawiera sensorStableMs, stopDelayMs, moveTimeoutMs, actuatorTimeoutMs, a ST.2 także slowHz/fastHz. Czasy interfejsu są UDINT w ms; walidacja ogranicza je przed TO_TIME. Parametry techniczne napędu i polityki cewek nie są edytowane przez ten interfejs. Winda do krawędzi korzysta z aktywnej prędkości wolnej.

Ruchy stationManual: 1=górna taśma, 2=taśma windy, 3=dolna taśma, 4=oś windy, 5=M1, 6=M2, 7=M3, 8=M4, 9=M5, 10=V201, 11=V202, 12=V203, 13/14=dolne stopery, 15/16=V401/V402. Positive oznacza FWD/WORK/górę, Negative BWD/HOME/dół, zgodnie z zatwierdzonym mapowaniem. Strony to 111/112/113/114 według stacji. Górna taśma nie ma kierunku wstecznego w obecnej mapie. Wciśnięcie obu kierunków jest odrzucane. Osobne holdCounter nie mogą przedłużać autoryzacji innego urządzenia.

hmiIo.value/valid zawiera komplet **159 nazw z 166 wierszy** mapy źródłowej i statusy 12 modułów. Wejścia są powiązane przez DiagnosticValue/Valid. Obsługiwane OUT prezentują końcową komendę właściciela. Niepowiązane EUROMAP, safety i rezerwy pozostają nieważne; nie tworzono pozornych wartości ani dodatkowych kanałów sterowania.

[Katalog alarmów](station-alarm-catalog.csv): 1–11 to uzgodnione ostrzeżenia siłowników, 12–52 wymagają GAP-12. 53–64 pozostają na jawne dodatkowe źródła. AlarmCfg.policyVerified i configured dla 12–52 są warunkiem policyReady; niekompletna macierz blokuje produkcję. Dotychczasowe ochronne blokady urządzeń pozostają aktywne. Nie nadano nieuzgodnionym alarmom domyślnie łagodniejszej klasy. alarmAckAll, ustąpienie przyczyny i reset zatrzaśnięcia są osobnymi zdarzeniami. Żadne nie wywołuje ruchu.

## 5. Weryfikacja i przekazanie

`python -B tools/check_plc_release.py` uruchamia 12 kontroli. W pakiecie stacyjnym wykonywane są rzeczywiste źródła ST, w tym PRG_Main. Jego GIATV oraz I/O są jawnymi fixture testowymi w tools, a nie zaimportowaną biblioteką ani modelem mechaniki. Nie importować tools/fixtures do PLC.

Zakres prób: wszystkie 128 kombinacji początkowej zajętości obu produkcji w modelu koordynacji, Stop/Start/Manual, ostatni odbiór, B304 stale 0/1, brak kolejkowania lokalnego żądania, utrata ważności, retencja ładunku podczas ruchu, osobne watchdogi, konflikty, rewizje i atomowe Apply, alarm ACK/Reset, zamrożony payload HMI oraz brak ruchu niepowiązanego PRG_Main. Mechanika przejazdów w modelu opróżniania jest syntetyczna; osobne testy wykonują ST.1 i ST.3.

Pozostają otwarte fizyczne GAP-01–09 oraz zależny zakres GAP-11/12. GAP-10 rozstrzygnięto funkcjonalnie powyżej; stary HMI Start nadal nie uruchamia automatu. Przed uruchomieniem potwierdzić: mapę/polaryzacje, barierę, B205/B301/B304, grupy dolnych stoperów, warunki zatrzymania taśm, konfigurację AP, pneumatyczne polityki utrzymania ładunku, sygnały początku/końca wtrysku, konfigurację osi i retencję.

Kolejność przekazania: DUT/FB/GVL/PRG → kompilacja Machine Expert z właściwymi bibliotekami → fizyczne bindingi i diagnostyka → import rzeczywistych symboli do Vijeo → próby pojedynczych urządzeń → wspólne próby robot–IMM–transport → FAT/SAT. PRG_IO_Read/Write są wywoływane raz wewnątrz PRG_Main; nie dodawać ich ponownie do zadania.

Wynik końcowy: **12/12 kontroli, 159 testów offline**, w tym 32 testy modułów stacji i 22 regresje integracyjne. [Raport i granice weryfikacji](station-verification.md).
