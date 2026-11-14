# Analiza materiałów SkyLogic x SE-ELDA

Data: 2026-11-14. Status: przegląd dokumentacji i plików offline; bez zmian urządzeń i bez prób ruchowych. Dotyczy REQ-03/04/11–19/22, nowej decyzji DEC-18 oraz GAP-02/03/04/05/06/07/08/09/11/12.

## 1. Źródła, wersje i granice analizy

Folder źródłowy: `SkyLogic x SE-ELDA - Dokumenty/P0001-Krauss`. W zinwentaryzowanej strukturze znaleziono 882 pliki, w tym pliki techniczne ROBOGUIDE, backupy i archiwa; liczba nie oznacza audytu treści każdego pliku binarnego. Pominięto katalogi irrelevant i .git przed rekursją. Analiza obejmuje oba schematy (63 + 3 strony), arkusz I/O, porównanie treści Wytycznych, dokumenty uzgodnień, metadane backupów, istotne manuale i lokalizację projektów PLC/HMI. Połączenia i symbole zaworów sprawdzono również na renderach PDF. Programów TP nie zdekompilowano; nie otwierano projektów w edytorach zapisujących konfigurację.

[Manifest analizy](sources/workspace-analysis-manifest.json) rejestruje pochodzenie, rozmiary i SHA-256. Wszystkie pliki źródłowe pozostały zewnętrzne i tylko do odczytu. Manifest obejmuje wszystkie 122 pliki katalogu fizycznego backupu oraz wybrane dowody z pozostałych projektów; nie jest kopią wszystkich 882 plików.

| Źródło | Wynik porównania | Znaczenie |
|---|---|---|
| SRC-09: elektryka 2026-09-29, P0001, 63 strony | SHA-256 identyczne z kopią SRC-03 w repozytorium | Inna nazwa pliku nie oznacza nowej rewizji; utrzymują się znane braki połączeń |
| SRC-09: pneumatyka 2026-10-28, rew. 00.0, arkusze 010/020/021 | Nowe źródło, SHA-256 bbf075e658778cdeda7e967bbf3415ac809f030d25ffe7b33ba7143c0aea6c38 | Opisuje obwody i dwa narzędzia, ale zawiera rozbieżność przyłączy |
| SRC-09: współdzielony IO Map.xlsx | Inny układ, nazwy i zawartość niż SRC-02; osiem arkuszy | Nie nadpisywać kopii w repozytorium. Są kody wykonania VTUX, brak pełnych offsetów Festo i pomiarów próżni |
| SRC-09: Wytyczne.docx | Inny hash pliku, identyczna sekwencja tekstu dokumentu przy porównaniu XML | Nie wykryto nowych wymagań tekstowych tylko z powodu zmiany pliku |
| SRC-10: 20261020-FROM_ROBOT | Wszystkie 122 pliki zgodne SHA-256 z lokalnym `Robot M20iD/backup/...` | Fizyczna baza przekazana przez użytkownika, odrębna od symulacji |
| SRC-11: wzorce W716 i W590 | W716 jest również rozpakowany; W590 sprawdzono przez listing archiwum i odczyt SUMMARY bez wypakowania | Dane do analizy starej technologii i odzyskania podprogramów |
| SRC-12: krausv6.frw i zapis ROBOGUIDE | Zapis wirtualnego kontrolera ma V9.10P/19 | Nie utożsamiać z fizycznym V9.40P/80 |
| SRC-13: projekty PLC/HMI | Znaleziono pliki projektów poza repozytorium | Dostępność pliku nie potwierdza docelowej wersji ani kompilacji |
| SRC-14: fanucrobot_eip_v900.eds | Przykładowy adapter R30iB Plus, Vendor 356, Device Type 12, Product Code 4, revision 3.1 | Punkt wyjścia; potrzebna zgodność z urządzeniem i konfiguracją skanera |

## 2. Pneumatyka — ustalenia z rysunków

Arkusz 010 pokazuje Y501–Y505 jako zawory 5/3 z dwoma kierunkami sterowania i zamkniętym położeniem środkowym. Y509–Y513 przedstawiają pięć obwodów próżni ze sterowaniem wytwarzaniem podciśnienia i oddzielnym przedmuchem. Łącznie rysunek przewiduje 20 funkcji sterowania cewkami dla tych dziesięciu zespołów. To liczba funkcji ze schematu, nie zatwierdzone offsety wyjść terminala AP ani dowód wykonania instalacji.

| Obwód | Przyłącze z arkusza 010 |
|---|---|
| Próżnia 1 / Y509 | FIPA 1 |
| Próżnia 2 / Y510 | FIPA 2 |
| Próżnia 3 / Y511 | FIPA 3 |
| Próżnia 4 / Y512 | FIPA 4 |
| Próżnia 5 / Y513 | GRODZ. 5 |

F-2844 (arkusz 020): cztery oddzielne siłowniki V502–V505, przyłącza ruchu FIPA 5/6 i 7/8 oraz GRODZ. 1/2 i 3/4; cztery obwody ssawek pokazane przy poszczególnych chwytakach.

F-2680 (arkusz 021): cztery siłowniki V502-1…V502-4 pracują jako grupa Y502, a dwa V503-1/V503-2 jako grupa Y503. FIPA 1/Y509, 2/Y510 i 4/Y512 obsługują ssawki detali; FIPA 3/Y511 obsługuje ssawki blistrów. Funkcja piątego obwodu nie została przypisana na tym arkuszu narzędzia. Nie uznawać go automatycznie za nieużywany w całej instalacji.

To oznacza konieczność przypisania funkcji zależnego od narzędzia. Pięć obwodów nie oznacza pięciu detali, a cztery funkcje V502–V505 nie zawsze oznaczają cztery niezależne siłowniki. Liczby gniazd formy nie ustalać przez liczenie ssawek.

### Rozbieżność przyłączy F-2680 — GAP-08 pozostaje otwarty

| Przyłącze | Arkusz 010 | Arkusz 021 |
|---|---|---|
| FIPA 5 | Y502 port 4, WP | Y502 port 2 |
| FIPA 6 | Y502 port 2, HP | Y502 port 4 |
| FIPA 7 | Y503 port 4, WP | Y503 port 2 |
| FIPA 8 | Y503 port 2, HP | Y503 port 4 |

Nie wybierać milcząco jednej wersji. Rozstrzygnięcie wymaga poprawionego rysunku lub sprawdzenia instalacji. Dla V501 arkusz 010 opisuje BENDED/STRAIGHT, ale przypisanie tych stanów do sygnałów HP/WP i końcowej polaryzacji nadal wymaga spójnego potwierdzenia. Zamknięty środek zaworu nie dowodzi utrzymania ładunku przez dowolny czas po zaniku powietrza lub energii. Zachowanie cewek, podciśnienia i obciążeń pozostaje częścią GAP-08.

## 3. Elektryka — wejścia i ograniczenia mapy

| Potwierdzenie | Kanał według schematu | Lokalizacja |
|---|---|---|
| V502 HP / WP | KEC3 I0 / I1 | arkusz 050, strona PDF 21 |
| V503 HP / WP | KEC3 I2 / I3 | arkusz 050, strona PDF 21 |
| V504 HP / WP | KEC3 I4 / I5 | arkusz 050, strona PDF 21 |
| V505 HP / WP | KEC3 I6 / I7 | arkusz 050, strona PDF 21 |
| V501 HP / WP | BAT401 X0 / X1, CPX-AP-A-8DI-M8-3P | arkusz 341, strona PDF 63 |

Są to kanały/moduły z dokumentacji. Nie przeliczać ich mechanicznie na %IX, numery DI ani bity assembly. Przebieg chwytaka przez X4/FIPA pokazuje także arkusz 309 (PDF 51). Nie wymaga to fizycznego przenoszenia wejść KEC3 do Festo.

Schemat nie daje kompletnej ścieżki pięciu pomiarów podciśnienia do PLC. Rysunek pneumatyczny rozstrzyga liczbę obwodów i istnienie przedmuchów, lecz nie dostarcza pełnej konfiguracji ich pomiarów/offsetów. B205 na arkuszu 308 (PDF 50) nadal nie ma pokazanego podłączenia sygnału do wejścia PLC — GAP-02 nie jest zamknięty.

Współdzielony Excel opisuje zawory 5/3 pojedynczymi symbolami Q_05_01…Q_05_05 i obwody próżni Q_V509…Q_V513. Nie jest to pełna lista niezależnych komend cewek/przedmuchów. Zakładka Festo Islands zawiera kody wykonania terminali VTUX, ale nie konfigurację obrazu procesowego. Zachować źródło obok SRC-02, bez automatycznego zastępowania nazw i adresów istniejącej kopii.

## 4. EUROMAP — zależności do uwzględnienia w programie

Arkusze 030/031 i 151 pokazują sygnały IMM przez KF101–KF111: odrzut, formę zamkniętą/otwartą/pośrednią, współpracę, wyrzutnik i dwa rdzenie. Arkusze 060/061 i 152/153 pokazują KF201–KF210 dla procesowych wyjść do IMM.

**KF204–KF210 mają wspólne zasilanie styków przez KF203:14** (arkusz 153, PDF 41). Wyłączenie KF203, czyli pozwolenia pełnego otwarcia formy, odbiera również sygnały trybu współpracy, wyrzutnika i rdzeni, nawet gdy ich własne cewki pozostają wysterowane. Stop musi uwzględniać tę zależność i podtrzymanie sygnałów potrzebnych do zakończenia rozpoczętej operacji.

Brak jednoznacznego sygnału rzeczywistego rozpoczęcia wtrysku. Nie zastępować go formą zamkniętą ani wysłanym pozwoleniem. KF211 ma cewkę i niepełne powiązanie; KF403 ma rozbieżne opisy. Nie przypisywać im funkcji tylko z podobnej nazwy w placeholderze. Mould area free/KF201 należy ocenić razem z obwodami bezpieczeństwa; obecność wyjścia zwykłego PLC na rysunku nie jest odbiorem funkcji safety.

Schemat nadal zawiera przewodowe procesowe I/O CRMA15 (arkusze 171–173). Docelowo proces ma przechodzić po EtherNet/IP, zgodnie z decyzją użytkownika. Pozostaje wyznaczenie zachowanych funkcji przewodowych i usunięcie konkurujących torów sterowania (GAP-09). EUROMAP 73 i CRMA90 dotyczą odrębnej analizy bezpieczeństwa.

## 5. Backupy, EDS, projekty i manuale

Fizyczny backup SRC-10: LR HandlingTool V9.40P/80, build V9.40509. SUMMARY.DG wymienia adapter EtherNet/IP R538, funkcje skanera, Mixed Logic, Condition Monitor, High-Speed Skip, Multi-Tasking i OPT TP Ins. Lista opcji nie zastępuje sprawdzenia dokładnej składni blokowego IF/ELSE ani argumentów CALL. Obecne mapowanie DI121–184 i DO121–184 wskazuje rack 89, slot 1, port 1; to po 64 zmapowane punkty, nie zatwierdzony rozmiar docelowego kontraktu ani limit możliwości robota.

Raport używa osobowości ARC Mate 120iD, a MD25.DT podaje payload 25. Manual B-84074EN/04 obejmuje również M-20iD/25, typ A05B-1228-B202 (PDF 11). Nazwa osobowości nie wystarcza do uznania backupu za niewłaściwy; przed pracą na geometrii trzeba sprawdzić zgodność konfiguracji mechaniki.

Przykładowy EDS SRC-14 ma revision urządzenia 3.1 (nie wersję oprogramowania 3.1). Dla adaptera slotu 1 ścieżka podaje configuration assembly 100, PLC → robot 151 i robot → PLC 101. Parametry rozmiaru EDS są w bajtach, a konfiguracja FANUC może przedstawiać słowa 16-bitowe; jawnie uzgodnić jednostki. EDS ma wartości domyślne, nie odczyt konfiguracji tej maszyny. Nie zatwierdza jeszcze liczby bajtów, RPI, timeoutów i zgodności identyfikacji z urządzeniem.

W716: SUMMARY V7.70P/61; znaleziono BB_GRIPPER_RESET.TP, BB_IMM_RESET.TP i BB_RESET_VAC5.TP. To podprogramy dostępne binarnie, wymagające odczytu/eksportu LS i przeglądu skutków; nie są już „nieznalezionymi plikami”. W590: archiwum zawiera 157 wpisów, SUMMARY wskazuje V9.40P/66, m.in. programy F2680BOX, F2680TACKI i F2844. Same nazwy nie rozstrzygają przypisania narzędzi do przyszłych zleceń.

ROBOGUIDE krausv6: zapis kontrolera z 2026-10-20 ma V9.10P/19, inny niż fizyczny V9.40P/80. Nie traktować pomyślnej próby w tej komórce jako weryfikacji fizycznego runtime. Projekt zawiera modele sceny, a nie potwierdzone punkty rzeczywistego M-20iD/25.

Poza repozytorium, w `../../plc_project` względem jego katalogu głównego, znaleziono Krauss_PLC-lukasz.project, plc_soft.project i eksport symboli plc_soft.MyController.Application.xml. Folder współdzielony zawiera dwa wzorce HMI Vijeo .vdz. Nie wykonano otwarcia/kompilacji projektów i nie wskazano jeszcze autorytatywnej wersji PLC/HMI. Katalogi współdzielone 01_imm, 02_plc, 05_safety, 06_inverter i 07_remote_io w 04_software były puste podczas inwentaryzacji; lokalne projekty PLC znajdują się gdzie indziej.

## 6. Decyzja użytkownika — liczenie produkcji (SRC-15 / DEC-18)

Liczba detali jest parametrem wpisywanym przez operatora, niezależnym od liczby zaworów, ssawek i grup siłowników. Nowa wartość może być zastosowana **tylko przy wyłączonym zleceniu i niepracującej stacji**. Sama edycja pola nie zmienia aktywnej nastawy podczas pracy. Warunek zastosowania egzekwuje PLC; brak aktualnego potwierdzenia postoju lub nierozliczone operacje nie pozwalają zastosować zmiany.

Każda rozpoczęta partia/wtrysk zachowuje przypisaną ilość do zakończenia lub jawnego odzyskania. Liczenie następuje z potwierdzonych zdarzeń odłożenia, z oddzielnym rozliczeniem próbek i odrzutów; przyjęcie komendy lub załączenie próżni nie nalicza produkcji. Nie mnożyć automatycznie liczby zwolnionych obwodów przez liczbę detali. Częściowe odłożenie wymaga potwierdzonej ilości dla części partii — samo vacuumOK=0 nie określa sztuk.

Usunięto ze specyfikacji ograniczenie count do 1–4 oraz stałą interpretację loadMask jako czterech pojedynczych detali i piątej przekładki. Typ count pozostaje UINT, więc technicznie mieści 1..65535, ale ilość zdarzenia musi dodatkowo mieścić się w nierozliczonej ilości przypisanej partii. Nie dodano nowych adresów ani gotowej implementacji HMI/PLC; to aktualizacja wymagań i semantyki istniejących pól.

## 7. Stan braków po analizie

POTWIERDZONE DOKUMENTACYJNIE: wersja i wykaz opcji fizycznego FANUC, dostępność EDS jako przykładu, obecność wzorców W716/W590 i podprogramów TP, typy zaworów z rysunku, pięć obwodów próżni, wskazane kanały potwierdzeń oraz zależność KF203. Ustalenia te zastępują wcześniejsze ogólne stwierdzenia o braku materiałów.

OTWARTE: korekta portów F-2680, przypisanie narzędzi do zleceń, pomiary podciśnienia i pełny obraz Festo, B205, sygnał rozpoczęcia wtrysku, KF211/KF403, granice safety, właściwa wersja natywnego projektu, eksport i audyt TP, zgodność instrukcji i próby recovery. GAP pozostają otwarte w tych konkretnych częściach; nie wymagać ponownie materiałów, których obecność już potwierdzono.

Nie wykonano kompilacji Machine Expert, importu FANUC, symulacji protokołu ani FAT/SAT. [Raport weryfikacji](robot-communication-verification.md) rozdziela przegląd statyczny od odbioru urządzeń.
