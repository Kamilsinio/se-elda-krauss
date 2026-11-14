# Komunikacja FANUC–PLC v2

Stan: **PRZYGOTOWANE OFFLINE, NIEURUCHOMIONE**. Kontroler docelowy: R-30iB Mate Plus, HandlingTool V9.40P/80. Pakiet LIVE zawiera 17 źródeł LS bez ruchów. Program tacek i trzy BG opisują [instrukcja produkcji](../TRAY/README.md) oraz [instrukcja BG](../BG/README.md).

[Kontrakt](../../docs/robot-plc-contract.md) i [katalog 227 sygnałów](../../docs/robot-plc-signals.json) definiują znaczenie. [mapping.csv](mapping.csv) / [mapping.json](mapping.json) określają proponowany transport, a [resources.json](resources.json) lokalne R/F. Źródła generuje tools/build_fanuc_comm.py. Układy 220 pól v1 i pełny układ v2 mają kontrolowane skróty; zmiana wymaga przeglądu i wersjonowania obu stron.

## Transport do skonfigurowania

PLC M241: scanner; FANUC: adapter rack 89, slot 1. Profil: configuration assembly 100, PLC→robot 151, robot→PLC 101, po **80 bajtów / 40 UINT16** na kierunek. Potwierdzić zgodność identyfikacji EDS, instancji i rozmiarów na fizycznym urządzeniu. RPI pozostaje nastawą do pomiaru.

| Kierunek | Słowa od 0 | FANUC | Port adaptera od 1 |
|---|---|---|---|
| PLC→robot BOOL | 0–7 | DI121–248; używane DI121–227 | 1–128 |
| PLC→robot UINT | 8–35 | GI1–28 po 16 bitów | 129, 145, …, 561 |
| PLC→robot rezerwa | 36–39 | bez odbiorców | 577–640 |
| Robot→PLC BOOL | 0–3 | DO121–184 | 1–64 |
| Robot→PLC UINT | 4–31 | GO1–28 po 16 bitów | 65, 81, …, 497 |
| Robot→PLC rezerwa | 32–39 | bez nadawców | 513–640 |

Little endian, bit 0 = LSB. Pierwsze dwa UINT każdego kierunku to version=2 i heartbeat. Sprawdzić fizycznie wartości 1, 32768, 65535 oraz zera w rezerwach. Nie nakładać DI/DO na porty GI/GO; nie mapować dodatkowych nadawców do rezerw.

## Zmiana v1 → v2

Dotychczasowe 220 pól zachowuje offsety. Dodano wyłącznie:

| Pole | Miejsce |
|---|---|
| p2r.imm.batchCount | słowo 34, GI27 |
| p2r.production.startToken | słowo 35, GI28 |
| p2r.event.rejectsPlaced.ack | DI227, słowo 6 bit 10 |
| r2p.event.rejectsPlaced.req | DO184, słowo 3 bit 15 |
| rejectsPlaced.count/cycleId/stackId | słowa 29/30/31, GO26/27/28 |

DO184 pełni teraz funkcję REQ odrzutów i nie jest wymuszany na OFF. Różna wersja blokuje sesję. Liczba bajtów pozostaje taka sama; lokalne R/F zostały przydzielone ponownie i wymagają wspólnego importu wszystkich nowych źródeł.

batchCount, cycleId i reject dotyczą tej samej przydzielonej partii i pozostają stabilne do końca immPickupCompleted. startToken zwiększa się modulo 65536 wyłącznie po przyjętym fizycznym Start. Nie jest UOP START i nie uruchamia zadania robota.

PLC musi wdrożyć nowe dane i niezależne rozliczenie odrzutów. Suma productsPlaced/samplesPlaced/rejectsPlaced nie przekracza ilości partii. Nowy stackId jest przekazywany po zamknięciu wymian poprzedniego stosu. Przewóz pełnego stosu i udostępnienie następnego muszą działać również przy finishPermit podczas Stop, gdy trzeba obsłużyć rozpoczęty N+1; nie uzależniać tego wyłącznie od globalnego operationsSettled.

## Wykonanie i właściciele

RC_RX tworzy snapshot. RC_LINK/RC_DROP/RC_RECOV obsługują synchronizację i jawne odzyskanie. RC_CMD oraz helpery tworzą żądania. RC_EVENTS utrzymuje dziesięć niezależnych zdarzeń i pięć przedmuchów; payload jest zamrożony do ACK=0. RC_SMPL utrzymuje odpowiedź na próbki. RC_TX jest jedynym writerem DO/GO poza heartbeat, zapisywanym przez RC_MON.

RC_SVC jest jednym zwykłym zadaniem TP z WAIT 0.02 s. RC_MON pracuje jako BG niezależnie od WAIT programu produkcyjnego, ale zatrzymuje heartbeat po wykryciu zatrzymania serwisu. Przy productionRequired sprawdza też skany pozostałych BG. Sam żywy interfejs nie oznacza pracującego RT_MAIN.

Lokalny interfejs aplikacji znajduje się w resources.json. Aplikacja nie zapisuje fizycznych DO/GO ani snapshotu rx. Dla submit ustawia najpierw payload, a flagę żądania jako ostatnią; nie powtarza jej w każdej iteracji. state=10 czeka na ACK, 20 na ACK=0, 0 zwalnia kanał. Wynik 20 nie zwalnia kanału przed ACK=0. Nie ma automatycznego retry ani trwałego exactly-once po restarcie.

Clear i accessReq obszarów są utrzymywane przy ważnej sesji niezależnie od pozwolenia na nową operację. Sekwencja rozstrzyga nowe wejście, a potwierdzenie opuszczenia publikuje BG. Po zerwaniu sesji PLC zachowuje potrzebne rezerwacje do uzgodnienia.

## LIVE i TEST — nie łączyć

| Pakiet | Pamięć | Przeznaczenie |
|---|---|---|
| ROBOT/COMM LIVE | R51–176, F501–759 | transport używany przez produkcję |
| ROBOT/TRAY + BG | R1–50, R177–200, F1–98, PR1–40 | konfiguracja, kontekst i statusy |
| [ROBOT/TEST/COMM](../TEST/COMM/RC_TEST.LS) | wspólny transport oraz mock R1–28 i dodatkowe F | izolowany test komunikacji, bez produkcji |

W LIVE nie ma obrazu mock ani RC_TEST. W TEST wszystkie obsługiwane DO/GO są zapisywane zerami niezależnie od flagi test, a RC_LIVE nie uruchamia serwisu. Nazwy programów są wspólne z LIVE; testować na osobnej kopii i nigdy nie wgrywać obu pakietów razem. RC_TEST oczekuje testResult=1 i pozostawia configured/run OFF.

Backup nie dowodzi wolności zasobów. Sprawdzić wszystkie R/F/PR, makra, BG i pojemność przed importem. Nie odtwarzać NUMREG, FLAG ani binarnych konfiguracji z innego robota. Nie przywracać starych programów ruchowych do tych samych zasobów.

## Konfiguracja i ograniczenia uruchomienia

Backup ma DI121–184 i DO121–184 w rack 89/slot 1. Propozycja rozszerza DI i dodaje GI/GO. Zachować pozostałe przypisania rack 48 i UOP. Nie używać globalnego CLR_ASG. Sprawdzić IO_AUTO_CFG/IO_AUTO_UOP i brak konkurujących writerów. Nie dodawać zdalnego startu lub wyboru programu przez UOP.

RC_INIT zeruje tylko lokalną pamięć komunikacji, w LIVE pozostawia configured/run OFF. Wykonywać wyłącznie przy zatrzymanych zadaniach i uzgodnionym stanie. Nie używać INIT do recovery. RC_DROP zachowuje maskę ładunku i zamrożone dane, lecz unieważnia żądania i uzbrojenie; odbiorca nie może traktować ostatniego snapshotu jako aktualnego.

Po potwierdzeniu konfiguracji uruchomić RC_MON jako BG, ustawić configured i jawnie wywołać RC_LIVE. Zakończyć obie wymiany synchronizacji, uzgodnić stan i wywołać RC_RECOV. appArm jest kasowane przy zaniku sesji, criticalBlock, recoveryRequired lub guardRequest. Powrót warunków sam go nie ustawia.

Zegar $FAST_CLOCK wymaga pomiaru na V9.40: jednostki, zawijanie i dokładność w R przy długim uptime. W INIT ustawiono testowe heartbeatPeriod=64, peerTimeout=512, serviceTimeout=256, syncTimeout=2048 surowych ticków. Starszy manual podaje krok 4 ms; nie zakładać kroku 1 ms. Zatwierdzić parametry względem zmierzonego RPI i cyklu.

Potwierdzić KEEP_IO_ADP=FALSE oraz reakcję alarmu adaptera. Watchdog procesowy i UALM w BG nie są samodzielnym dowodem zatrzymania bieżącego ruchu. Import LS/kompilacja TP musi dotyczyć V9.40P/80; dostępny ROBOGUIDE V9.10 nie jest tym potwierdzeniem.

Normalne zatrzymanie serwisu: run=OFF; ostatni cykl unieważnia sesję i zapisuje żądania bez dopuszczenia wykonania. ABORT serwisu wymaga wykrycia przez watchdog, ponieważ nie wykona sekcji końcowej. Fizyczne podtrzymanie próżni i zaworów zawsze rozstrzyga PLC.

~~~powershell
python -B tools/build_fanuc_comm.py --check
python -B tools/check_robot_contract.py
python -B tools/check_fanuc_comm.py
~~~

Wynik: 16 testów komunikacji offline. Kompilacja/import, EtherNet/IP z PLC, reakcje alarmowe oraz FAT/SAT są NIEWYKONANE. Szczegóły: [raport](../../docs/robot-communication-verification.md).
