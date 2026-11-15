# PLC–FANUC v2 — implementacja źródeł i integracja

Aktualizacja stacyjna 2026-11-15: opisane niżej ograniczenie Drain do samego interfejsu dotyczy poprzedniego pakietu. Aktualny wykonawca, transport, alarmy i rozszerzenie HMI są w [implementacji modułów stacji](station-plc-implementation.md). Kontekst PLC ma schema=3, HMI wersję 3; wire FANUC nadal v2/80 B.

Stan: 2026-11-15. **ŹRÓDŁA I TESTY OFFLINE. NIE SKOMPILOWANO W MACHINE EXPERT, NIE URUCHOMIONO NA URZĄDZENIACH.**

Zakres: pełna integracja robota w ST, z logicznymi interfejsami Festo i Krauss. Implementuje części REQ-01–04/09–19/21/22 oraz modelowe scenariusze AT-01–03/07–15. Pełne opróżnianie, nowe ekrany Vijeo i przebudowa całego transportu pozostają poza tym pakietem. Nie zmieniono LS ani konfiguracji urządzeń.

## 1. Pliki i właściciele

Każdy nowy FB ma osobny katalog w Modules. Wspólne kontrakty są w RobotInterface/DUTs, po jednym typie na plik.

| POU | Rola |
|---|---|
| FB_RobotCodec | Jawny kodek 80 B, bez aliasowania BOOL i bez adresów fizycznych |
| FB_RobotLink | Obustronna synchronizacja, heartbeat, wersja, ważność sesji |
| FB_RobotEvents | 10 czterofazowych kanałów; ACK dopiero po zatwierdzeniu zapisu |
| FB_RobotCycleLedger | Dwa miejsca N/N+1, ilości i identyfikatory partii, trwałe zadania materiałowe |
| FB_RobotGripper | V501–V505 i próżnie 1–5; jeden arbitraż cewek/przedmuchów |
| FB_RobotAreas | Przyznanie i zachowanie rezerwacji source/elevator/storage |
| FB_ImmInterface | Jedyny właściciel logicznych wyjść procesowych EUROMAP |
| FB_OrderManager | Zlecenie, Start/Stop, dokończenie, Manual, interfejs Drain |
| FB_RobotRecovery | Jawne uzgodnienie kontekstu i nowy pusty kontekst |
| FB_RobotHmi / FB_RobotManual | Sesja i transakcje HMI; ręczny chwytak z osobnymi watchdogami |
| FB_RobotController | Kolejność wykonania powyższych modułów, próbki, status i ramka TX |
| FB_StationCoils | Końcowe komendy M1–M7: bez nowego celu przed Start, zachowanie komend przy zwykłym Stop, osobna zatwierdzona polityka krytyczna |

PRG_Main zawiera integrację z istniejącymi blokami stacji. FB_TraySequencer i FB_BoxSequencer odbierają zarejestrowane zadania zamiast historycznych impulsów. FB_Storage obsługuje oddzielnie V401/V402: HOME otwarte, WORK zamknięte; wspólny warunek gotowości wymaga obu czujników.

Generator tools/build_plc_robot.py tworzy dwa typy wire, kodek i docs/plc-robot-wire.json. Nie poprawiać ich ręcznie. Aktualny kontrakt pozostaje v2: 227 pól, 80 B/kierunek, bez zmian offsetów i skrótu layoutu.

## 2. Publiczny interfejs PLC

| Symbol | Kierunek / znaczenie |
|---|---|
| GVL_Robot.RawIn / RawOut | Skaner ↔ PLC; ARRAY[0..79] OF BYTE, robot→PLC / PLC→robot |
| GVL_Robot.Rx / Tx | Odczytany snapshot i złożona odpowiedź v2; nazwy płaskie odpowiadają identyfikatorom katalogu |
| GVL_Robot.Cfg | Konfiguracja czasów i linku; domyślnie nieuzbrojona, brak zatwierdzonych czasów |
| GVL_Robot.ScannerHealthy / ImageFresh | Rzeczywisty health i aktualność obrazu skanera, bez zastępowania TRUE |
| GVL_Robot.Plant | Znormalizowane wejścia Festo, IMM, bezpieczeństwa, potwierdzenia i dane recovery |
| GVL_Robot.Sts | Status nadzoru oraz końcowe logiczne komendy chwytaka i IMM |
| GVL_Robot.storageIn / storageOut | Osobne czujniki i wyjścia V401/V402 oraz blokady magazynu |
| GVL_RobotRetain.Context | Kontekst do retencji; żadne pozwolenia ruchu nie są odtwarzane |
| GVL_Robot.Proposal | Edytowalny, jawnie uzgodniony kandydat kontekstu recovery |
| GVL_Robot.Drain | Interfejs do osobnego wykonawcy pełnego opróżniania |
| GVL_HMI.hmiV2 | Zaimplementowany podzbiór kontraktu HMI, niezależny od starego hmiCmd |

W strukturach Plant.cylinders[i] indeksy 1–5 oznaczają V501–V505. Plant.vacuum[i] oznacza fizyczny obwód 1–5, nie numer detalu. Obszary 1/2/3 to source/elevator/storage.

M1–M7 mają dodatkowy końcowy arbitraż FB_StationCoils. stationCoilPolicyVerified i stationCoilLossPolicy[1..7] wymagają osobnego potwierdzenia GAP-08; home/work oznacza tu zatwierdzone bwd/fwd historycznych grup. Przed Start nowe cele nie trafiają do wyjść. Zwykły postój zachowuje poprzednie komendy; blokada krytyczna stosuje wyłącznie zweryfikowaną politykę. Sprzeczna polityka blokuje wykonanie. Osobne sterowania Manual całej stacji pozostają poza tym podzbiorem HMI.

Każde valid/configured/potwierdzenie ma domyślnie FALSE. Potwierdzenie musi pochodzić z rzeczywistego urządzenia lub jawnej próby modelowej. Parametry materiałowe na FANUC pozostają ustawiane na robocie; PLC dostarcza ilość przypisaną do wtrysku.

### Sygnały do powiązania przed uruchomieniem

1. **Robot:** dwa obrazy 80 B, health i aktualność. Proponowane assembly 100/151/101 i RPI potwierdzić na urządzeniach; nie są wdrożoną konfiguracją.
2. **Chwytak:** aktualne czujniki, dopuszczenia kierunków, rzeczywiste pomiary próżni i potwierdzenia zwolnienia. Wyjścia do Festo biorą komendy wyłącznie ze Sts.cylinders[i].home/work i Sts.vacuum[i].hold/blow.
3. **Magazyn:** storageIn.Left/Right oraz storageOut.Q_V401Home/Work i Q_V402Home/Work. Nie podłączać równolegle starego M8.
4. **Krauss:** Plant.imm, potwierdzone zbocze startConfirmed wraz ze startSignalValid, cycleKnown, zakończenie i zestaw pozwoleń completion* zależny od fazy. Wyjścia po arbitrażu pochodzą wyłącznie ze Sts.imm.
5. **Stacja:** stationIoBound, rzeczywisty physicalStop (nie dawny Continue), zewnętrzne potwierdzenia bezpieczeństwa, health ATV320, zatwierdzone prędkości windy, elevatorTransferStable dla potwierdzenia dostarczenia P4 i sourceEmptyStable dla pustego źródła. Brak czasu potwierdzenia P4 lub dodatnich prędkości blokuje automat.

PRG_Main mapuje fizyczny Start i przycisk próbek dopiero po stationIoBound. Istniejąca mapa stacyjnego RAW pochodzi ze starej maszyny i wymaga sprawdzenia przed ustawieniem tego dopuszczenia. Stare wyjścia robota 32-bitowego, bezpośrednia próżnia 5 i zapis starego M8 są odłączone. Nowe porty Festo nie otrzymały fikcyjnych adresów.

Adapter sprzętowy może odwzorowywać polaryzację, lecz nie może tworzyć drugiego arbitrażu wyjść. Jeśli dodaje warunek zmieniający wyjście, również status applied musi przedstawiać wynik tego warunku. Szczególnie sprawdzić wspólne zasilanie KF204–KF210 przez KF203.

## 3. Zasady wykonania

- Kodek RX tworzy snapshot. Nadzór jest wykonywany raz na skan; PLC nie ma WAIT zależnego od programu robota. Kodeki RX i TX są osobnymi bezstanowymi instancjami.
- Zdarzenia mają osobne zamrożone payloady. Najpierw walidowane są wszystkie równoczesne dyspozycje, potem zapisywane skutki, następnie ACK. Zapisane zadania materiałowe pozostają w Context.tasks do odbioru przez sekwencer.
- cycleId powstaje na potwierdzonym fizycznym starcie, a batchCount/reject pozostają przypisane do partii. pickupPending nie jest ponownie ustawiany dla pobranego cyklu. Brak miejsca lub nadmiarowe ilości blokują następne operacje.
- Ilości produktów, próbek i odrzutów są oddzielne. Warstwy i stosy nie doliczają produktów. Liczba detali nie wynika z maski podciśnień. Przepełnienie liczników powoduje błąd zamiast zawijania statystyki.
- Zwykły Stop utrzymuje kontekst i prawo dokończenia N/N+1. Nie zeruje właściciela zaakceptowanego transferu. Nowy fizyczny Start jest wymagany po postoju; odrzucone zbocze nie jest kolejkowane.
- Rezerwacja obszaru powstaje po przyznaniu dostępu. Samo clear=0 przy nowym żądaniu nie nadaje granted. Spadek gotowości przygotowania po odłożeniu nie odbiera już przyznanego dostępu przed wyjściem. Utrata sesji zachowuje rezerwację do uzgodnienia.
- Winda BOX nie zmienia wysokości pomiędzy warstwami; Z dodaje robot. Blistry mają osobne przygotowanie po odłożeniu pustej tacki. Pojedyncze blisterPicked nie zwalnia całego P3; wymagane jest potwierdzenie pustego źródła.
- Ostrzeżenia siłowników ST.1–ST.4 blokują zależne działanie. Sekwencery nie dodają nadrzędnego timeoutu eskalującego to samo oczekiwanie.
- Fault w fazie 900 robota obejmuje również potrzebę recovery. Nie tworzymy pętli „PLC criticalBlock blokuje robot recovery, bo robot zgłasza recovery”. Nowe operacje nadal wymagają braku fault, rzeczywistej gotowości i lokalnego zakończenia recovery FANUC.
- Po uzgodnieniu pustego postoju istnieje jawny lokalny stan reconciledIdle, pozwalający otworzyć pierwsze zlecenie i przyjąć Start. Nie jest wyprowadzany z samego HOME i jest kasowany przy Start/utracie warunków.

## 4. Recovery i retencja

Lista do zachowania: zlecenie, program, aktywna ilość, identyfikatory, dwa wpisy wtrysków, liczniki i dyspozycje, zadania materiałowe, próbki, rezerwacje obszarów oraz model zajętości/ładunku i diagnostyczne stany transferów. Generacja HMI nigdy nie jest cofana przez wczytanie Proposal.

Przy wejściu w recovery PLC kopiuje kontekst do Proposal. Operator porównuje go z robotem, maszyną, ładunkami i trwałymi skutkami zdarzeń. Proposal nie jest zapisywany automatycznie po zmianie czujnika ani traktowany jako zatwierdzenie.

Potwierdzenie wymaga: zakończonej synchronizacji, neutralnych kanałów zdarzeń/przedmuchów/próbek, HOME i loadKnown robota, aktualnego modelu IMM, potwierdzenia kontekstu robota, ładunków i cykli oraz sprawdzonej retencji.

Transfer przerwany w połowie wymaga fizycznego uzgodnienia do postoju i transfersConfirmedIdle. Kod odtwarza uzgodnioną zajętość i oczekujące potwierdzenia, **nie wznawia taśmy od niezweryfikowanego kroku w połowie przejazdu**. Stany zapisane przed przerwaniem służą diagnozie. Na niepewny trwały skutek należy podjąć jawną decyzję przed zatwierdzeniem Proposal.

Nowy pusty kontekst wymaga dodatkowo potwierdzonej pustej stacji, pustego chwytaka i rozliczonego IMM. Po zatwierdzeniu obu stron konieczny jest świeży fizyczny Start. Dokończenie częściowej partii przed tym Start jest zablokowane.

VAR_GLOBAL PERSISTENT RETAIN wymaga konfiguracji listy persistent i sprawdzenia spójnego odtwarzania w Machine Expert/M241. Nie deklarujemy atomowości zapisu ani trwałego exactly-once po zaniku zasilania. Nie uzbrajać HMI ani produkcji bez retentionVerified. Wyzerowanie generacji sesji nie jest sposobem naprawy retencji; przy jej wyczerpaniu HMI pozostaje nieuzbrojone.

## 5. HMI i ręczne sterowanie

Zaimplementowane klucze transakcji: orderOpen, orderEnd, modeManual, modeAuto, robotEnable, robotDisable, resetFaults, recoveryConfirm, newEmptyContext, station5ParamApply i samples. Zachowano układ cmd/rsp/permit, ID sesji i żądania, stabilny wynik oraz pełne 0/0. W jednej chwili dopuszczona jest jedna nowa transakcja; równoczesne żądania są odrzucane. ID rośnie w danym kanale i sesji; jego ponowienie nie powtarza skutku.

Bufor edit.uiProgram używa kodów 1=BOX, 2=TRAY. Status state.uiProduction zachowuje kody HMI 10/20. edit.uiBatchCount nie zmienia active; station5ParamApply stosuje ilość tylko po zamknięciu zlecenia, w uzgodnionym postoju. Program zatwierdza orderOpen.

Sesja HMI wymaga świeżego heartbeat, retencji generacji, neutralnych komend i nowego zbocza ARM. ACK=przyjęto oznacza przyjęcie komendy; zakończenie pokazuje status procesu. W przypadku próbek nie oznacza przyjęcia przez robot ani odłożenia; wynik robota i samplesPlaced są osobnymi etapami.

Nowy podzbiór ręcznego chwytaka: hmiV2.manual, panel ST05 Manual 115, poprawne udiSessionId, Manual, wyłączona współpraca, HOME, wolne obszary i jawne manualGripperHandover. holdCounter[1..5] dotyczy V501–V505, [6..10] próżni 1–5. Licznik innego urządzenia nie przedłuża pozwolenia; po wygaśnięciu/zmianie strony wymagane są zwolnienie i nowe naciśnięcie. Przedmuch po przyjęciu jest skończoną operacją PLC, utrzymywaną do terminalnego wyniku, bez powtórzeń. Przełączenie na Auto kasuje autoryzację; stare ręczne EUROMAP wymaga neutralizacji przed ponownym dopuszczeniem.

Stare hmiCmd pozostają deklaracjami do migracji i nie uruchamiają produkcji ani ruchów z pominięciem nowego nadzoru. Nie dostarczono nowych ekranów ani eksportu symboli. Ręczne ekrany całej stacji i dalsze hmiV2/hmiIo nadal należą do oddzielnej adaptacji HMI; nie należy podłączać ich na podstawie podobnej nazwy.

## 6. Granica pełnego opróżniania

Drain.request jest żądaniem z PLC. Wykonawca dostarcza connected/accepted/busy/done/fault/emptyConfirmed. PLC wymaga neutralnych accepted/busy/done/fault po podłączeniu wykonawcy, a następnie świeżego accepted i done dla bieżącego request. Stare utrzymane DONE nie zamyka zlecenia. Wykonawca musi wyzerować wynik po request=0 i rozpocząć nową wymianę.

Bez connected i potwierdzenia opróżnienia zlecenie pozostaje otwarte. Nie wykorzystujemy starego algorytmu opróżniania jako pozornego potwierdzenia. Wymaganie odbioru ostatniego ładunku B304 należy do tego wykonawcy. Lokalny przycisk rozładunku nie generuje Drain.request. Tworzy tylko pojedynczy impuls singleUnloadRequest przy singleUnloadReady; wykonawca pojedynczego wydania i B304 należą do osobnego pakietu ST.3. Nie utożsamiamy wydania operatorowi z transferem P4→P5.

## 7. Weryfikacja i import

Uruchomienie kontroli z katalogu repozytorium:

Pełny zestaw jednym poleceniem: `python -B tools/check_plc_release.py`.

~~~powershell
python -B tools/build_plc_robot.py --check
python -B tools/check_plc_structure.py
python -B tools/check_plc_robot.py
python -B tools/build_fanuc_comm.py --check
python -B tools/build_fanuc_tray.py --check
python -B tools/check_robot_contract.py
python -B tools/check_fanuc_comm.py
python -B tools/check_fanuc_tray.py
python -B tools/check_fanuc_box.py
python -B tools/check_fanuc_readability.py
~~~

Na tym komputerze działający interpreter to C:/Users/KamilPelczar/.local/bin/python3.15.exe; alias python z WindowsApps nie uruchamia Pythona.

Testy PLC wykonują AST rzeczywistych źródeł ST. Nieobsługiwana składnia przerywa test. TON/R_TRIG i czas są wirtualne. Audyt statyczny sprawdza symbole, pola i argumenty wywołań również w PRG_Main; GIATV/Axis_Ref pozostają zewnętrznym interfejsem, bez pozornej kompilacji biblioteki.

Wspólna symulacja łączy rzeczywisty ST i LIVE LS przez obrazy 80 B. Native, geometria, czujniki i fizyka urządzeń są jawnie syntetyczne. Obejmuje dwa stosy Blistrów, dwa BOX z warstwami/przekładkami, Stop N+1, próbki/odrzuty i utratę połączenia. Nie dowodzi zachowania firmware, czasów magistrali ani mechaniki.

Do projektu natywnego importować wyłącznie DUT z Modules, aktualne FB, GVL i PRG. Nie importować docs/sources/legacy-robot-gvl.st: to zamrożona baza audytu 64 starych pól, nie aktywny kod. Historyczne wiersze migracji nadal wskazują oryginalne GVLs/GVL_Robot.st; audyt czyta kopię z kontrolą SHA-256.

Kolejność odbioru: DUT/FB/GVL/PRG i biblioteki → kompilacja Machine Expert → konfiguracja skanera i rzeczywiste bindingi → pomiar timingów → potwierdzenie reakcji zaniku/utrzymania ładunku → wspólne próby z FANUC → FAT/SAT. Ruch produkcyjny pozostaje zablokowany do zamknięcia zależnych GAP.

Otwarte: GAP-01/02 dla zależnych funkcji stacji; GAP-03/04/05/06/08/09 dla sprzętu/transportu; GAP-07 dla wykonania HMI; GAP-11/12 dla retencji i fizycznych reakcji. Uzgodnienia tego pakietu rozstrzygają Manual podczas kończenia i granicę Drain, ale nie wszystkie warianty GAP-10.

## 8. Wynik weryfikacji źródeł — 2026-11-15

| Kontrola | Wynik |
|---|---|
| Generator PLC --check | PASS, 4 artefakty, 227 pól i niezmieniony layout |
| Audyt symboli, pól i wywołań PLC | PASS; obejmuje PRG_Main i producentów lokalnych sygnałów |
| Testy ST i wspólne ST–LS | PASS, 40 testów, w tym 4 testy wspólnej symulacji oraz testy końcowego arbitrażu cewek |
| Generatory FANUC --check | PASS, 45 artefaktów komunikacji i 13 produkcji/BG |
| Audyt kontraktu i migracji | PASS, 227 pól i 268 wierszy, zachowane 64 historyczne deklaracje GVL |
| Regresja FANUC | PASS, 65 testów |
| Zestaw kontroli | 10/10, łącznie 105 testów zachowania/czytelności |
| Kompilacja Machine Expert / import FANUC | NIE WYKONANO |
| Konfiguracja i pomiary EIP/Festo/IMM, FAT/SAT | NIE WYKONANO |

Wyniki odnoszą się do źródeł i modelu offline. Nie stanowią odbioru funkcji bezpieczeństwa ani gotowości fizycznej stacji.
