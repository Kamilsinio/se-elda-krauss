# Modernizacja programów FANUC po ustaleniu kontraktu

Data: 2026-11-15. Status: **źródła MAIN_BOX/MAIN_TRAY oraz komunikacji/BG przygotowane offline; import i uruchomienie pozostają otwarte**. Kontrakt v2: [robot-plc-contract.md](robot-plc-contract.md). DEC-31/32: użytkownik wybrał całą technologię w dwóch main oraz opisy wszystkich zmiennych; robot wydaje niezależne polecenia urządzeń, PLC wykonuje pneumatykę.

## 1. Ustalenia z rzeczywistych źródeł

Oba programy main wywołują BB_GRIPPER_RESET, BB_IMM_RESET i BB_RESET_VAC5. Znaleziono je jako binarne TP we wzorcu W716 (SRC-11); wymagany jest odczyt/eksport LS i przegląd skutków przed zmianą startu/resetu. Fizyczny backup nowego robota V9.40P/80 oraz archiwum W590 są dostępne. [Analiza materiałów](workspace-analysis.md) rozróżnia fizyczny kontroler, starsze wzorce i ROBOGUIDE V9.10P/19.

| Obszar | Blistry | Pojemniki | Zmiana docelowa |
|---|---|---|---|
| DO15 | odłożenie pustego blistra | odłożenie przekładki | osobne kanały blisterPlaced/spacerPlaced |
| DO17 | napełniony pojedynczy blister | ukończona warstwa | osobne blisterFinished/layerFinished; stackFinished oddzielnie |
| DO23 | nieużywane | impuls postępu po detalach lub przekładce | zdarzenia z konkretnym znaczeniem, bez podwójnego liczenia |
| Próżnia 1–4 | RO1–8, RI1–4 | RO1–8, RI1–4 | żądania i rzeczywiste potwierdzenia przez PLC |
| Próżnia 5 | DI32/DO31/DO32 | DI32/DO31/DO32 | ten sam model co pozostałe próżnie |
| Oś pneumatyczna | DO119/120, RI5/6 | DO119/120, RI5/6 | V501 przez PLC; straight=HOME wymaga GAP-08 |
| Siłowniki | użycia 1 | użycia 1–4 | V502–V505; funkcję odczytywać z etykiet, nie parzystości numeru DO |

W `IOSTATE.DG` zapisano HandlingTool V7.70125. To nagłówek historycznego eksportu, nie dowód wersji nowego Mate Plus. Snapshot jest zapisem stanów ON/OFF, nie konfiguracją rack/slot/assembly ani listą opcji. DO30 ma w snapshotcie opis „rob movement”, choć GVL nazywa go rezerwą; migracja pozostawia REVIEW_BACKUP zamiast automatycznego uznania kanału za wolny. Schemat/arkusz i LS mają rozbieżną numerację IMM: LS DI101=reject, DI102=mould closed, DI103=mould open; arkusz opisuje przewodowe kanały robota inaczej. Nie przenosić numerów mechanicznie (GAP-05/09).

[CSV migracji](robot-plc-migration.csv) zawiera każde użycie I/O w obu main, także zakomentowane WAIT, wszystkie 64 pola logiczne GVL_Robot, CALL wymagające eksportu odnalezionych TP oraz opisane historyczne I/O. Kolumna usage wskazuje numery instrukcji LS (nie linie pliku). CSV nie jest konfiguracją nowego kontrolera. RESERVED, REMOVE, SAFETY_REVIEW, EXPORT_REQUIRED, EXTENSION_REQUIRED i REVIEW_BACKUP są jawnymi decyzjami, a nie zmapowanymi kanałami sprzętu.

## 2. Macierz instrukcji i zgodność

| Konstrukcja | Dowód w dostępnej dokumentacji | Decyzja |
|---|---|---|
| CALL i END | HandlingTool 8.30 §8.12.3, PDF 904–905 | techniczne wywołania komunikacji; technologia bezpośrednio w main; import do potwierdzenia |
| IF z CALL / logika mieszana | HandlingTool 8.30 §8.12.4, PDF 905–908 | dostępne odniesienie składni; nie wydzielać drobnych czynności technologii do plików |
| SELECT z CALL i ELSE | HandlingTool 8.30 §8.12.4, PDF 908–909 | wybór wariantu chwytaka/palety bez łańcucha wielu JMP |
| FOR/ENDFOR | HandlingTool 8.30 §8.15, PDF 924–926 | ograniczone powtórzenia; nie stosować do odtwarzania nieznanego miejsca po awarii |
| Argumenty CALL / AR | HandlingTool 8.30 §8.24; §8.12.3 opisuje opcję Parameters for CALL Program | dostępność opcji OTWARTA; nie zakładać jej na podstawie daty robota |
| IF/THEN/ELSE/ENDIF, WHILE | brak potwierdzenia dla docelowego systemu w dostarczonym zestawie | nie generować takiej składni przed potwierdzeniem wersji/opcji i próbą importu |
| Background Logic | HandlingTool 8.30 §8.20.6, PDF 973–976 | kandydat na heartbeat i statusy; bez ruchu, odrębny właściciel wyjść; potwierdzić dopuszczalne instrukcje, alarm i start monitora |
| SKIP, WAIT TIMEOUT, UALM | istniejące LS; dokładne zachowanie sprawdzić w manualu docelowym | zachować wymagane etykiety; oddzielić przyczynę i krok, sprawdzić zatrzymanie w ruchu |

Źródła PDF znajdują się poza repozytorium w `../Robot M20iD/manuals` oraz we współdzielonym katalogu projektu zamawiającego. Identyfikatory, rewizje i SHA-256: [manifest manuali](sources/robot-manuals-manifest.json). Dodatkowy MAROU91EN02171E Rev C obejmuje wersje 9.10 i nowsze, a B-84074EN/04 wprost wymienia M-20iD/25 A05B-1228-B202. B-82854EN/03 obejmuje Mate Plus i adapter EtherNet/IP; B-83525EN/09 obejmuje serwis Mate/Mate Plus. Basic Operation B-83284EN/04 i HandlingTool 8.30 dotyczą wcześniejszej rodziny; stanowią odniesienie, nie potwierdzają dostępności wszystkich instrukcji na dostarczonym urządzeniu.

Brak potwierdzenia blokowego IF nie blokuje implementacji. Oba main używają opisanych faz, zwykłego IF i lokalnych etykiet; nie wymagają opcji argumentów CALL/AR ani runtime mailboxu. Etykiety potrzebne do oczekiwania/recovery pozostają jawne. Kompilację/import należy potwierdzić na docelowym kontrolerze.

## 3. Bieżący podział programów — decyzja 2026-11-15

| Program / pakiet | Odpowiedzialność |
|---|---|
| [MAIN_TRAY](../ROBOT/TRAY/MAIN_TRAY.LS) | Pełna technologia tacek: ruchy, chwytak, IMM, produkty, próbki, zdarzenia, Stop i recovery |
| [MAIN_BOX](../ROBOT/BOX/MAIN_BOX.LS) | Pełna technologia BOX: ruchy, chwytak, IMM, P1–P3, warstwy, przekładki, zdarzenia, Stop i recovery |
| PLC_* | Oddzielna komunikacja, REQ/ACK i walidacja logicznego interfejsu |
| BG_PLC / BG_STATUS / BG_GUARD | Monitorowanie niezależne od oczekiwania/ruchu main; wybór jednego właściciela |
| BG_BIND | Sprawdzenie kompletu źródeł native, bez ich fikcyjnego uzupełniania |
| COMMON | Wyłącznie manifest i słownik opisów, bez programów LS |

Usunięto wykonywalne mikroprogramy RT/RX/RM/XM/RG/RE/RF i runtime kopiowanie RF_READ/RF_WRITE. Ich definicje w generatorze są rozwijane do dwóch main przed eksportem; nie są osobnymi plikami do załadowania. [Migracja nazw](../ROBOT/program-migration.csv) wskazuje każdy stary plik i jego docelową rolę.

Każdy używany zasób ma etykietę i pełne objaśnienie w LS. Słownik podaje kierunek, jednostki, maski, ON/OFF i znaczenie wartości. Opisy są również eksportowane do CSV/JSON; nie zastępują komentarzy w programie. Nie należy zakładać, że import LS automatycznie ustawi wszystkie natywne tabele komentarzy — wymaga to sprawdzenia.

[COMMON](../ROBOT/COMMON/README.md) opisuje komendy INIT/APPLY/NEW/RECOVERY/EXIT wykonywane wewnątrz wybranego main. R331 nadal zapisuje wyłącznie BG_STATUS. Każdy main ma własne nastawy i kontekst, bez wpływu na indeksy drugiego programu.

## 4. Dane, błędy i optymalizacja

Przed kodowaniem sporządzić inwentarz całego backupu R/PR/F/TIMER/P/UFRAME/UTOOL, z właścicielami i miejscami retencji. Same NUMREG.VA i POSREG.VA nie dowodzą, że pozostałe rejestry są wolne. Historyczne R1/2 i R8–20 (Blistry), R31–59 (Pojemniki), PR1/2, PR31–34 i PR51–53 wymagają audytu wszystkich podprogramów przed zmianą.

Rozdzielić parametry technologiczne od stanu sekwencji i danych protokołu. Stan odtwarzania obejmuje program, fazę, stos, warstwę, indeks detalu, następny chwytak, cycleId partii, przypisaną jej liczbę detali i rzeczywistą maskę zajętych obwodów według narzędzia. Pięć obwodów nie oznacza pięciu sztuk. DEC-18 dopuszcza zastosowanie nowej liczby detali wyłącznie przy zamkniętym zleceniu i niepracującej stacji. Błąd walidacji przy wznowieniu nie może po cichu uruchamiać ścieżki „nowa produkcja” i zerować liczników.

W programie tacek r2p.production.step jest bieżącym stanem sekwencji 10–900 opisanym w resources.json, a faultCode i resumeState są osobne. BOX używa analogicznych rodzin 10–900: gotowość, pojemnik, IMM, odkładanie, warstwy/przekładki/koniec pojemnika, Stop i recovery. Szczegóły zawiera jego resources.json. W ramach modułu numeracja co 10; kod błędu jest odrębny. Nie kierować wszystkich timeoutów do nierozróżnialnego UALM[1].

BOX ma opisane fazy oraz osobne bazy grup dla każdej sekcji. Podejście, praca i wycofanie oraz obliczenie offsetu są bezpośrednio w MAIN_BOX, bez zmiany konfiguracji kinematycznej bazy. Zmniejszenie liczby etykiet poprawia utrzymanie; nie jest dowodem skrócenia cyklu.

Najpierw zachować poprawność nakładania wtrysku i odkładania, potem mierzyć postoje i opóźnienia. Nie usuwać WAIT potwierdzeń ani nie zmieniać CNT/FINE, prędkości, przyspieszeń i kolizyjnych odcinków w ramach refaktoryzacji. SKIP po próżni przez PLC wymaga zmierzenia najgorszej latencji i drogi zatrzymania. Nie kopiować starego UTOOL=3, UFRAME=0 i obciążeń jako potwierdzonych ustawień nowego robota.

## 5. Warunki utworzenia docelowych LS/ST

Kolejność: kontrakt logiczny → fizyczna mapa i dowody I/O → inwentarz backupu i macierz instrukcji → warstwa komunikacji PLC/FANUC → urządzenia/IMM → definicje generatora → dwa pełne main → import/kompilacja → próby bez i z ruchem.

Przykład EDS, projekty PLC, fizyczny backup i schemat pneumatyczny są już znalezione. Do mapy potrzebna jest weryfikacja identyfikacji/obrazu urządzeń i wybór docelowego projektu. Nowe programy BOX/TRAY nie wywołują historycznych BB_* ani nie kopiują dawnych współrzędnych. Do porównania technologii i dalszej modernizacji pozostają eksport TP, audyt zależności oraz potwierdzenie importu na V9.40P/80. Rozbieżne porty F-2680, niepełne pomiary podciśnienia i brak rozpoznania początku wtrysku blokują zależne ruchy i Stop N+1. Nie tworzyć pozornie działających main z nieobecnymi helperami, fikcyjnymi DI/DO ani składnią niepotwierdzoną przez kontroler. [Raport weryfikacji](robot-communication-verification.md) rozróżnia zakończony przegląd statyczny i niewykonane próby urządzeń.
