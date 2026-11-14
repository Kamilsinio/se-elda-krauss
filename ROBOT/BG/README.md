# Logiki BG i powiązania statusów kontrolera

Stan: źródła przygotowane offline, **powiązania native w bindings.json są nieuzupełnione i blokują pracę**. Nie zastępować ich stałymi TRUE ani ogólnym sygnałem pracy RC_SVC.

## Programy uruchamiane jako BG Logic

| Program | Lokalizacja | Odpowiedzialność |
|---|---|---|
| RC_MON | [komunikacja LIVE](../COMM/RC_MON.LS) | heartbeat PLC/robot, watchdog partnera i serwisu, aktualność RB_STATUS/RB_GUARD |
| RB_STATUS | [RB_STATUS.LS](RB_STATUS.LS) | natywne statusy, rzeczywiste HOME, właściwy program, ważność zwolnienia obszarów |
| RB_GUARD | [RB_GUARD.LS](RB_GUARD.LS) | dopuszczenie produkcji i zatrzask krytycznego przerwania |

Rejestrować dokładnie te trzy programy. RB_BIND jest inicjalizatorem powiązań wywoływanym jawnie, a nie czwartym BG. RC_SVC jest osobnym zwykłym zadaniem TP. BG nie uruchamiają produkcji, nie wykonują ruchów, nie mają CALL/WAIT i nie sterują cewkami.

RC_MON jest jedynym writerem heartbeat GO. RC_TX zapisuje pozostałe DO/GO. RB_STATUS i RB_GUARD operują lokalnym interfejsem R/F; PLC jest właścicielem rzeczywistych wyjść chwytaka i EUROMAP.

RB_STATUS oraz RB_GUARD zapisują własne znaczniki $FAST_CLOCK. W LIVE używają dwóch rejestrów, które w odizolowanym TEST służą jako mockClock/testResult; aliasy są jawne w [manifeście tacek](../TRAY/resources.json). Pakietów nie łączyć. Cofnięcie zegara lub nieaktualny skan odbiera ważność. Jednostkę zegara i timeouty należy zmierzyć na V9.40.

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
| taskRunning/taskPaused | stan zadania RT_MAIN, również podczas CALL i WAIT; nie dowolnego zadania TP |

Dla HOME dostępny manual zmiennych opisuje $REFPOS1 i $atperch oraz $enabled. Dokładną składnię indeksowania, aktywność funkcji, tolerancje osi i dostępność odczytu potwierdzić na V9.40. Nie ustawiać HOME z flagi ostatnio ukończonego ruchu. Nie przypisywać automatycznie wyjścia Reference Position do któregoś DO/GO kontraktu — miałoby drugiego writera.

Dla taskRunning nie używać ogólnego „program działa”, jeżeli może oznaczać RC_SVC. Trzeba sprawdzić RT_MAIN podczas pracy, WAIT, PAUSE, ABORT i po zakończeniu. Jeśli natywny odczyt nie jest dostępny w potwierdzonej formie, pozostawić pole nieuzupełnione; odbiór ruchu pozostaje zablokowany.

Po zmianie bindings.json odtworzyć źródła i przeprowadzić import właściwy dla V9.40. RB_BIND ustawi sourceBound dopiero przy komplecie źródeł. bindingsVerified jest osobnym potwierdzeniem wykonanych prób. Nie ustawiać ręcznie sourceBound ani nie wymuszać flag native jako sposobu uruchomienia.

## Reakcje i ograniczenia

RB_GUARD sprawdza sesję, aktualność BG, tryb i status kontrolera, wybrany program, zlecenie, ważność używanych obwodów, ładunek i potwierdzenia siłowników oraz dostęp do zajętych obszarów. Celowe zwalnianie grupy jest odróżnione od utraty pozostałych niesionych detali.

Przy przerwaniu blokuje appArm/productionPermit, zatrzaskuje recovery i unieważnia aktualną pewność ładunku. Zachowuje maskę i kontekst do uzgodnienia. Nie zrzuca próżni przez reset rejestrów ani nie wystawia bezpośrednich poleceń cewek.

Warunkowy UALM[1] jest przygotowany jako zgłoszenie procesu. **Samo wykonanie UALM w BG nie jest dowodem zatrzymania zadania ruchowego**. Przed alarmApproved trzeba potwierdzić na kontrolerze konfigurację i reakcję obejmującą RT_MAIN podczas ruchu i WAIT oraz sposób ponownego dopuszczenia. Potwierdzić także alarm zaniku adaptera, zachowanie zatrzymanego RC_SVC, RC_MON i każdego BG. Do tego czasu alarmApproved/motionApproved pozostają OFF.

recoveryApproved umożliwia operatorowi skasowanie alarmu i przeprowadzenie uzgodnienia bez ponawiania zgłoszenia w każdej próbie resetu; nie kasuje blokady procesu ani nie daje komendy ruchu. Do wznowienia potrzebne są spójny kontekst, gotowa sesja oraz nowy fizyczny Start.

Zwolnienie obszaru jest ważne także po zwykłym Stop, nawet bez newOperationPermit/finishPermit. Potwierdzenie z drogi programu jest unieważniane przy zmianie trybu, nieznanej pozycji lub przerwaniu; po zakończeniu programu nie dowodzi miejsca robota po ręcznym jogu. HOME, clear i granted są sygnałami procesowymi, nie safety.

## Odbiór przed ruchem

Sprawdzić zasoby R/F/PR i kolizje z makrami/BG, wykonać import LS oraz zatwierdzić dopuszczalną składnię na V9.40P/80. Domyślny tryb skanowania BG: Normal; czasy skanu i obciążenie wymagają pomiaru. Nie konfigurować samoczynnego startu RC_LIVE lub programu ruchowego. BG mogą wracać po zasileniu zgodnie z ustawieniem kontrolera, ale produkcja nadal wymaga jawnej inicjalizacji/uzgodnienia.

Źródła odniesienia: dostarczony HandlingTool 8.30, PDF 908–909 i 973–976, oraz manual zmiennych Rev.G, PDF 690–694. Są starszym odniesieniem; nie potwierdzają działania wszystkich źródeł na V9.40. Lokalizacje i rewizje zawiera [rejestr materiałów](../../docs/sources/README.md). Import oraz fizyczne próby opisane powyżej pozostają NIEWYKONANE.
