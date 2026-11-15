# Logiki BG i powiązania statusów kontrolera

Stan: źródła przygotowane offline, **powiązania native w bindings.json są nieuzupełnione i blokują pracę**. Nie zastępować ich stałymi TRUE ani ogólnym sygnałem pracy PLC_SVC.

## Programy uruchamiane jako BG Logic

| Program | Lokalizacja | Odpowiedzialność |
|---|---|---|
| BG_PLC | [komunikacja LIVE](../COMM/BG_PLC.LS) | heartbeat PLC/robot, watchdog partnera i serwisu, aktualność BG_STATUS/BG_GUARD |
| BG_STATUS | [BG_STATUS.LS](BG_STATUS.LS) | natywne statusy, arbiter NONE/BOX/TRAY, rzeczywiste HOME, program i zwolnienie obszarów |
| BG_GUARD | [BG_GUARD.LS](BG_GUARD.LS) | dopuszczenie produkcji i zatrzask krytycznego przerwania |

Rejestrować dokładnie te trzy programy. BG_BIND jest inicjalizatorem powiązań wywoływanym jawnie, a nie czwartym BG. PLC_SVC jest osobnym zwykłym zadaniem TP. BG nie uruchamiają produkcji, nie wykonują ruchów, nie mają CALL/WAIT i nie sterują cewkami.

BG_PLC jest jedynym writerem heartbeat GO. PLC_TX zapisuje pozostałe DO/GO. BG_STATUS i BG_GUARD operują lokalnym interfejsem R/F; PLC jest właścicielem rzeczywistych wyjść chwytaka i EUROMAP.

BG_STATUS oraz BG_GUARD zapisują własne znaczniki $FAST_CLOCK. W LIVE używają dwóch rejestrów, które w odizolowanym TEST służą jako mockClock/testResult; aliasy są jawne w [manifeście tacek](../TRAY/resources.json). Pakietów nie łączyć. Cofnięcie zegara lub nieaktualny skan odbiera ważność. Jednostkę zegara i timeouty należy zmierzyć na V9.40.

## Uzupełnienie bindings.json

Dla każdego pola podać udokumentowany odczyt kontrolera lub wyrażenie boolowskie, potwierdzone na fizycznej wersji. Generator dopuszcza źródła systemowe i wskazane wewnętrzne I/O; odrzuca samą stałą bez źródła. Nie zapisuje zmiennych systemowych ani przypisań I/O.

| Pole | Wymagane znaczenie |
|---|---|
| autoMode/t1Mode/t2Mode | rzeczywiste położenie selektora; sprawdzić wzajemną wyłączność |
| tpEnabled | rzeczywisty stan włączenia pendanta |
| systemReady | gotowość kontrolera, niezależna od gotowości procesu |
| estopActive | zbiorczy diagnostyczny E-STOP; nie zastępuje funkcji bezpieczeństwa |
| fault | faktyczny alarm kontrolera |
| inputSimulated/outputSimulated | stan symulowania wejść/wyjść; blokuje odbiór produkcyjny |
| home | aktualna, włączona i nauczona Reference Position grupy 1 |
| programs.tray.running/paused | osobne źródła zadania MAIN_TRAY, również podczas CALL/WAIT/PAUSE/ABORT |
| programs.box.running/paused | osobne źródła zadania MAIN_BOX; niezależne od TRAY i PLC_SVC |

Dla HOME dostępny manual zmiennych opisuje $REFPOS1 i $atperch oraz $enabled. Dokładną składnię indeksowania, aktywność funkcji, tolerancje osi i dostępność odczytu potwierdzić na V9.40. Nie ustawiać HOME z flagi ostatnio ukończonego ruchu. Nie przypisywać automatycznie wyjścia Reference Position do któregoś DO/GO kontraktu — miałoby drugiego writera.

Dla statusów zadań nie używać ogólnego „program działa”, jeżeli może oznaczać PLC_SVC. Trzeba sprawdzić oddzielnie MAIN_TRAY i MAIN_BOX podczas pracy, WAIT, PAUSE, ABORT i po zakończeniu. Jeśli natywny odczyt nie jest dostępny w potwierdzonej formie, pozostawić pole nieuzupełnione; odbiór ruchu pozostaje zablokowany.

Po zmianie bindings.json odtworzyć źródła i przeprowadzić import właściwy dla V9.40. BG_BIND ustawi sourceBound dopiero przy komplecie 14 źródeł: 10 wspólnych oraz dwie pary stanów main. bindingsVerified jest osobnym potwierdzeniem wykonanych prób. Nie ustawiać ręcznie sourceBound ani nie wymuszać flag native jako sposobu uruchomienia.

## Reakcje i ograniczenia

[COMMON](../COMMON/README.md) opisuje właściciela R331 i procedurę inicjalizacji/zmiany trybu. Właściciela zapisuje wyłącznie BG_STATUS. Żaden main nie publikuje komend przed przyznaniem. Oba natywnie aktywne/paused main lub oba żądania powodują konflikt, blokadę appArm/productionPermit i konieczność jawnego uzgodnienia. Każdy main korzysta bezpośrednio z własnego banku, bez runtime mailboxu i wspólnych podprogramów technologicznych.

BG_GUARD sprawdza sesję, aktualność BG, tryb i status kontrolera, wybrany program, zlecenie, ważność używanych obwodów, ładunek i potwierdzenia siłowników oraz dostęp do zajętych obszarów. Celowe zwalnianie grupy jest odróżnione od utraty pozostałych niesionych detali.

Przy przerwaniu blokuje appArm/productionPermit, zatrzaskuje recovery i unieważnia aktualną pewność ładunku. Zachowuje maskę i kontekst do uzgodnienia. Nie zrzuca próżni przez reset rejestrów ani nie wystawia bezpośrednich poleceń cewek.

Warunkowy UALM[1] jest przygotowany jako zgłoszenie procesu. **Samo wykonanie UALM w BG nie jest dowodem zatrzymania zadania ruchowego**. Przed alarmApproved trzeba potwierdzić na kontrolerze konfigurację i reakcję obejmującą MAIN_TRAY i MAIN_BOX podczas ruchu i WAIT oraz sposób ponownego dopuszczenia. Potwierdzić także alarm zaniku adaptera, zachowanie zatrzymanego PLC_SVC, BG_PLC i każdego BG. Do tego czasu alarmApproved/motionApproved pozostają OFF.

recoveryApproved umożliwia operatorowi skasowanie alarmu i przeprowadzenie uzgodnienia bez ponawiania zgłoszenia w każdej próbie resetu; nie kasuje blokady procesu ani nie daje komendy ruchu. Do wznowienia potrzebne są spójny kontekst, gotowa sesja oraz nowy fizyczny Start.

Zwolnienie obszaru jest ważne także po zwykłym Stop, nawet bez newOperationPermit/finishPermit. Potwierdzenie z drogi programu jest unieważniane przy zmianie trybu, nieznanej pozycji lub przerwaniu; po zakończeniu programu nie dowodzi miejsca robota po ręcznym jogu. HOME, clear i granted są sygnałami procesowymi, nie safety.

## Odbiór przed ruchem

Sprawdzić dostępność R1–400, F do 759 i PR do 95 oraz zatwierdzić capacityVerified; nie zmieniono pojemności kontrolera. Sprawdzić zasoby R/F/PR i kolizje z makrami/BG, wykonać import LS oraz zatwierdzić dopuszczalną składnię na V9.40P/80. Domyślny tryb skanowania BG: Normal; czasy skanu i obciążenie wymagają pomiaru. Nie konfigurować samoczynnego startu PLC_LIVE lub programu ruchowego. BG mogą wracać po zasileniu zgodnie z ustawieniem kontrolera, ale produkcja nadal wymaga jawnej inicjalizacji/uzgodnienia.

Źródła odniesienia: dostarczony HandlingTool 8.30, PDF 908–909 i 973–976, oraz manual zmiennych Rev.G, PDF 690–694. Są starszym odniesieniem; nie potwierdzają działania wszystkich źródeł na V9.40. Lokalizacje i rewizje zawiera [rejestr materiałów](../../docs/sources/README.md). Import oraz fizyczne próby opisane powyżej pozostają NIEWYKONANE.
