# Instrukcja dla agenta — SE-ELDA-Krauss

## Cel i granice pracy

Repozytorium zawiera eksporty źródeł PLC i FANUC odziedziczone po poprzednim stanowisku oraz dokumentację adaptacji do Krauss. Dokumentacja opisuje stan docelowy; obecność wymagania w dokumentacji nie oznacza jego implementacji w kodzie.

- Twórz i modyfikuj pliki wyłącznie wewnątrz `se-elda-krauss`, również pliki tymczasowe, raporty, skrypty i artefakty weryfikacji.
- Poprzednie repozytorium `se-elda-old-project` i materiały poza katalogiem docelowym są tylko do odczytu.
- Nie czytaj, nie przeszukuj, nie edytuj ani nie używaj zawartości `irrelevant/`. Wyszukiwania wykluczają `--glob '!**/irrelevant/**'` oraz `--glob '!**/.git/**'`; przy przejściu po katalogach pomijaj je przed rekursją.
- Zachowuj zmiany użytkownika, w tym istniejące usunięcia plików. Nie przywracaj archiwów i nie porządkuj całego repozytorium przy okazji zadania.
- Wykonuj zakres bieżącego zadania. Nie pobieraj programu na PLC, HMI ani robota i nie zmieniaj urządzeń sieciowych w ramach samej edycji repozytorium.

## Kolejność czytania i źródła ustaleń

1. [README](README.md) — stan prac i mapa repozytorium.
2. [Założenia projektowe](docs/project-assumptions.md) — wymagania i decyzje użytkownika.
3. [Interfejsy i mapowanie](docs/interfaces.md) — kierunki danych, oznaczenia, odpowiedzialność i braki mapowania.
4. [Plan implementacji](docs/implementation-plan.md) — etapy, REQ, AT i GAP oraz warunki rozpoczęcia prac.
5. Dla komunikacji i LS: [kontrakt PLC–robot](docs/robot-plc-contract.md), [katalog sygnałów](docs/robot-plc-signals.json), [migracja](docs/robot-plc-migration.csv), [modernizacja](docs/robot-modernization.md) i [raport weryfikacji](docs/robot-communication-verification.md). Są specyfikacją, nie wdrożoną konfiguracją. Nowa implementacja strony FANUC i jej instrukcja znajdują się w [ROBOT/COMM](ROBOT/COMM/README.md); nie jest jeszcze zaimportowana na kontroler. Logiczną integrację PLC i jej granice opisuje docs/plc-robot-implementation.md. Nie podłączaj obecnych ST/LS do tego kontraktu przez proste przepisanie numerów.
6. [Materiały źródłowe](docs/sources/README.md) — pochodzenie, rewizje i stan kopii.
7. Dla prac HMI: [instrukcja człowieka](human-instructions.md), [instrukcja wykonawcza 20 paneli i symboli HMI v4](docs/hmi-instructions.md), [mapa Vijeo](docs/hmi-vijeo-map.md), [obecne zmienne](docs/hmi-existing-variables.md) i [diagnostyka I/O](docs/hmi-io-diagnostics.md). Aktualne hmiV2 i hmiIo opisuje [interfejs stacji](docs/station-plc-implementation.md). Odróżniaj zaimplementowane pola od propozycji pierwotnej mapy i ekranów wymagających wykonania w Vijeo.
8. Dopiero potem pliki ST/LS dotyczące zadania.

Bieżące instrukcje użytkownika mają pierwszeństwo. W dokumentacji rozróżniaj **POTWIERDZONE**, **DOMYŚLNE** i **OTWARTE**. Decyzje użytkownika z założeń zastępują sprzeczne opisy poprzedniego stanowiska. Rozbieżność źródeł sprzętowych wymaga wpisu GAP i potwierdzenia fizycznego mapowania; nie wolno traktować docelowej architektury jako dowodu wykonania okablowania.

## Docelowa architektura

- PLC Schneider Electric M241; schemat P0001 wskazuje TM241CE24T. Zewnętrzne projekty natywne znaleziono; wybór docelowej wersji, firmware i bibliotek wymaga weryfikacji (SRC-13).
- Robot FANUC M-20iD/25, kontroler R-30iB Mate Plus.
- PLC jest skanerem EtherNet/IP dla robota i bramki Festo AP; szczegóły połączeń wynikną z EDS i konfiguracji urządzeń.
- PLC pośredniczy pomiędzy robotem a wtryskarką Krauss. Interfejs wtryskarki to sygnały elektryczne EUROMAP 67.
- Cała pneumatyka chwytaka, oś pneumatyczna, podciśnienia i przedmuchy są obsługiwane przez PLC/Festo na żądania robota.
- Robot jest uruchamiany przez operatora na robocie. Nie dodawaj zdalnego startu ani wyboru programu przez UOP.
- Winda wykorzystuje ATV320. Istniejące źródła używają `GIATV.Control_ATV`; konfigurację magistrali i osi trzeba potwierdzić, nie migrować jej automatycznie na EtherNet/IP.
- Funkcje bezpieczeństwa realizuje dedykowany układ. Status HOME, procesowe I/O i zwykły PLC nie zastępują funkcji bezpieczeństwa.

## Niezmienne zasady procesu

- Start zlecenia zatwierdza Pojemniki/Blistry; fizyczny Start uruchamia lub wznawia automat.
- Produkcja automatyczna wymaga aktywnego zlecenia. Manual nie wymaga zlecenia.
- Fizyczny Stop kończy wszystkie już rozpoczęte operacje, w tym wtrysk nakładający się na odkładanie poprzednich detali, i blokuje nowe cykle.
- Koniec zlecenia kończy rozpoczęte operacje, potem opróżnia całą stację pojedynczymi pojemnikami/stosami, również niepełnymi i pustymi. Kolejny wyjazd wymaga odebrania poprzedniego przy B304.
- Lokalny przycisk rozładunku wydaje jeden gotowy stos. Nie uruchamia pełnego opróżniania.
- Zmiana Pojemniki/Blistry jest możliwa po zamknięciu zlecenia.
- Liczba detali jest parametrem niezależnym od liczby obwodów; nowa wartość obowiązuje tylko po zastosowaniu przy wyłączonym zleceniu i niepracującej stacji (DEC-18). Rozpoczęte partie zachowują przypisaną ilość.
- Ostrzeżenie siłownika w ST.1–ST.4 blokuje zależny ruch bez globalnego Stop. Nie eskaluj tego samego oczekiwania do krytycznego alarmu w nadrzędnym sekwencerze.
- Przenoszenie między transporterami wymaga współpracy obu napędów. Stopery zmieniają położenie przy zatrzymanej taśmie.
- V201/V202 poruszają się równocześnie w Auto, mają oddzielną diagnostykę i ręczne sterowanie.
- V401/V402 otwierają i zamykają się razem; WORK obu osłon oznacza zamknięcie.
- Bez opcji Praca z robotem, przy potwierdzonym HOME i spełnionych blokadach, wtryskarka ma pozwolenia niezależne od zlecenia; automatyczna paletyzacja i transport produkcyjny są wyłączone.
- Reset błędu sam nie uruchamia ruchu. Powrót komunikacji i zasilania sam nie wznawia produkcji.

Pełne warunki i rozróżnienia znajdują się w założeniach; nie opieraj zmian wyłącznie na tej skróconej liście.

## Warstwy i odpowiedzialność za wyjścia

Zachowaj przepływ: konfiguracja urządzeń i RAW → normalizacja/diagnostyka komunikacji → logiczne interfejsy → urządzenia i sekwencje → końcowa arbitrażowa logika wyjść → zapis I/O. HMI wysyła żądania i otrzymuje statusy.

- Adresy sprzętowe nie należą do sekwencerów. RAW nie zawiera logiki procesu.
- Każde fizyczne wyjście ma jednego właściciela końcowej komendy. Auto, Manual, robot, opróżnianie i reakcja na błąd nie mogą niezależnie nadpisywać wyjść.
- Opisz źródło, odbiorcę, znaczenie TRUE/FALSE, ważność, potwierdzenie i zachowanie przy utracie danych dla każdego nowego sygnału.
- Nie kopiuj historycznych %IX/%QX ani numerów DI/DO/RI/RO jako gotowej mapy nowego sprzętu.
- Nie uznawaj `xRobotCommOk := TRUE` ani `xSafetyOK := TRUE` za docelowy status urządzenia.
- Nie ustawiaj wszystkich zaworów bezwarunkowo na FALSE przy błędzie. Zachowanie podciśnienia, cewek i obciążeń musi wynikać z potwierdzonej pneumatyki oraz GAP-08.
- Ręczne komendy i blokady egzekwuj w PLC, niezależnie od wizualizacji.

## Zasady ST i FANUC

- Nie używaj zarezerwowanych słów `action`, `program` i `reference` jako identyfikatorów zmiennych ani pól struktur; stosuj `action_`, `program_` i `reference_` oraz aktualizuj odwołania. Słowo kluczowe `PROGRAM` w deklaracji POU pozostaje bez zmiany. Nazwy złożone, np. `actionText`, `actionDone`, `production_program` i `uiProgram`, są odrębnymi identyfikatorami.
- Zachowaj zgodność z docelowym Machine Expert; stosuj `TO_UINT(expr)`, `TO_INT(expr)` i inne jawne konwersje.
- Enumy kwalifikuj przez kropkę: `E_State.IDLE`. Nie stosuj `E_State#IDLE` ani liczb zamiast wartości ścisłego enumu.
- `{attribute 'qualified_only'}`, `{attribute 'strict'}`, `TYPE` i `END_TYPE` zapisuj w osobnych właściwych liniach.
- Timery, detektory zboczy i pamięć sekwencji umieszczaj w `FUNCTION_BLOCK`, nie w bezstanowej `FUNCTION`.
- Nowe FB organizuj jako enumy oraz struktury `ST_*Cfg/Cmd/In/Out/Status/Diag`, następnie FB. Stany numeruj jawnie, zwykle co 10, stan błędu 900; nie zmieniaj numerów istniejących stanów bez potrzeby.
- Parametry czasowe i stabilizację czujników wydzielaj do konfiguracji. Nie wymyślaj wartości jako potwierdzonych nastaw maszyny.
- Zachowaj prefiksy `ind_`, `ctrl_`, `spare_`; nowe oznaczenia powiąż z ST.x/Vxxx/Bxxx. Nie wykonuj masowej zmiany nazw starego kodu bez tabeli migracji.
- Komentarze i komunikaty operatora pisz po polsku. Zachowuj istniejące identyfikatory techniczne, jeśli zmiana nie jest potrzebna.
- Przed zmianą LS sprawdź używane podprogramy, rejestry, sygnały i powiązania obu trybów. DO17 ma obecnie inne opisy w programach tacek i pojemników.
- Pozycje, UFRAME/UTOOL, obciążenia i trajektorie poprzedniego robota są materiałem odniesienia, a nie potwierdzonymi danymi M-20iD/25.

## Rzeczywisty stan źródeł

Istnieją `GVLs/`, `Modules/` i `ROBOT/`. Każdy FB ma własny katalog w `Modules/` oraz `DUTs/` z osobnym plikiem ST dla każdego typu; programy `PRG_*.st` pozostają bezpośrednio w `Modules/`. Historyczne programy `A01_F2679_TACKI.LS`, `AAAA_MAIN_BOX_PRG.LS` i eksporty VA/DG użytkownik przeniósł do `../Robot M20iD/old/ROBOT` (tylko odczyt); nie przywracać ich usunięć w repozytorium. Nowe `ROBOT/COMM` zawiera wyłącznie komunikację bez ruchów. Mapa i zasoby są generowane przez `tools/build_fanuc_comm.py`; zmieniać generator i ponawiać testy, nie poprawiać ręcznie wygenerowanych LS. `ROBOT/TRAY`, `ROBOT/BOX`, `ROBOT/COMMON` i `ROBOT/BG` zawierają dwa pełne main, słownik zasobów i statusy. Generuje je razem `tools/build_fanuc_tray.py` z definicjami technologii w Pythonie i fanuc_main.py; nie edytować wygenerowanych LS. Obowiązuje kontrakt v2 (227 pól, 80 bajtów/kierunek); zachowano offsety 220 pól v1. COMM/TRAY zachowują numery R1–200; BOX rezerwuje R201–330, COMMON R331–360, R361–400 to rezerwa. Dostępność co najmniej 400 R musi być zweryfikowana przed importem; capacityVerified pozostaje OFF. Jedyny właściciel produkcji R331 jest zapisywany w BG. Zmiany wymagają wspólnego audytu banków R/F/PR. `ROBOT/TEST/COMM` jest alternatywnym pakietem z kolizją R1–28 i nie może być importowany z produkcją. Nie ustawiać native/sourceBound/taught/approval jako stałych potwierdzających brakujące dane; bindings.json pozostaje UNBOUND do weryfikacji. Uruchamiać oba generatory z --check i cztery testy check_fanuc_comm.py, check_fanuc_tray.py i check_fanuc_box.py oraz check_fanuc_readability.py po odpowiednich zmianach. Poza repozytorium znaleziono fizyczny backup FANUC V9.40P/80, przykład EDS, wzorce W716/W590 z brakującymi wcześniej podprogramami TP oraz projekty PLC/HMI. [Analiza workspace](docs/workspace-analysis.md) i manifesty są źródłem aktualnego stanu dostępności. Podprogramy wymagają eksportu/odczytu LS, a konfiguracje i docelowa wersja projektów nadal wymagają weryfikacji. Nie traktować wirtualnego ROBOGUIDE V9.10P/19 jako fizycznego kontrolera.

`FB_OrderManager`, `FB_ImmInterface`, `FB_StationDrain` i `FB_AlarmManager` istnieją w źródłach. Pakiet stacyjny dodaje również StationIo, StationMaterial, StationTransport, StationManual, StationParameters i StationHmi. Aktualne kontrakty, schema=4 kontekstu i HMI v4 opisuje [implementacja stacji](docs/station-plc-implementation.md); wire FANUC pozostaje v2/80 B. Mechanizm alarmów nie zamyka GAP-12. Weryfikacja: tools/check_plc_release.py obejmuje także tools/check_station.py oraz check_station_integration.py. Integrację bez GVL prowadzi FB_StationController; PRG_Main wywołuje go raz wraz z osobnym adapterem GIATV. [Integracja i migracja](docs/station-integration.md) określa zasoby, monotoniczne ID, recovery i granice testów. Fixture GIATV w tools/fixtures jest wyłącznie modelem testowym, nie importować go do PLC. Nie raportować kompilacji Machine Expert ani zamknięcia sprzętowych GAP na podstawie testów offline.

## Weryfikacja i raportowanie

Przed edycją sprawdź stan Git i przeczytaj właściwe źródła. Dla zadania ustal REQ, zależne GAP i scenariusze AT. Otwarte dane sprzętowe blokują tylko zależne prace; można rozwijać niezależną dokumentację lub logikę z jawnym interfejsem, bez fikcyjnych adresów.

Po zmianie sprawdź właścicieli wyjść, reakcję na Stop/błąd/utracone dane, zachowanie potwierdzeń i wznowienia oraz zgodność dokumentacji. Uruchamiaj testy odpowiednie do zmiany.

Oddzielnie raportuj: przegląd statyczny, kompilację w Machine Expert, sprawdzenie FANUC, symulację i FAT/SAT. Brak środowiska lub danych oznacza „nie wykonano”, nie PASS. Nie twórz testów odtwarzających implementację; sprawdzaj zachowanie i warunki odbioru.

Program BOX: P1–P3 kolejno w warstwie, przekładki wyłącznie między warstwami, cała partia w jednej sekcji, robot dodaje Z przy nieruchomej windzie. Oba main pozostają na kontrolerze, mają osobne konteksty i staging/active. Zmiana właściciela wymaga zamkniętego zlecenia, HOME, znanego pustego chwytaka/stacji i rozliczenia kanałów/wtrysków. Dwa main to konflikt, nie wybór według PLC. Native bindings zawierają 10 statusów i dwie niezależne pary running/paused. Cała technologia, chwytak i ruchy są bezpośrednio w MAIN_TRAY/MAIN_BOX. COMMON nie zawiera LS ani runtime mailboxu. Osobno wyłącznie PLC_* i BG_*; nie odtwarzać mikroprogramów RF/RG/RE/RT/RX/RM/XM. [COMMON](ROBOT/COMMON/README.md) i [BOX](ROBOT/BOX/README.md) opisują inicjalizację, recovery i otwarte bramki uruchomienia.

Każdy LS i każdy używany zasób muszą mieć opis widoczny w samym programie. Etykiety operandów oraz komentarze generuje fanuc_descriptions.py ze słownika fanuc_meanings.csv i katalogu sygnałów. Brak znaczenia blokuje generowanie. Nie usuwać testów kompletności opisów. Lokalne INIT/APPLY/NEW/RECOVERY/EXIT obsługuje wybrany main; APPLY/EXIT mają jawne jednorazowe flagi, bez nowych pól wire. Interpreter testuje rzeczywiste main, zachowując PC przy WAIT. Import i pamięć rozwiniętych programów oraz native komentarze wymagają odbioru V9.40.
