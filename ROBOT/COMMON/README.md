# Zasoby wspólne i obsługa dwóch main

Stan 2026-11-15: źródła offline, bez importu i prób na kontrolerze. Cała technologia znajduje się w [MAIN_TRAY](../TRAY/MAIN_TRAY.LS) i [MAIN_BOX](../BOX/MAIN_BOX.LS). Katalog COMMON zawiera wyłącznie manifest oraz słownik opisów, bez programów LS.

## Co otrzymuje robot

- MAIN_TRAY: przygotowanie pustej tacki, IMM, chwytak, odkładanie, próbki, stos, Stop i recovery.
- MAIN_BOX: pojemnik, IMM, chwytak, P1–P3, warstwy, przekładki, próbki, Stop i recovery.
- PLC_*: komunikacja i walidacja logicznych żądań do PLC.
- BG_PLC, BG_STATUS, BG_GUARD: niezależne monitorowanie. BG_BIND sprawdza komplet powiązań natywnych.

Usunięto osobne RT/RX/RM/XM/RF/RG/RE oraz runtime RF_READ/RF_WRITE. Generator korzysta z definicji czynności w Pythonie, ale rozwija je bezpośrednio do main: nie trzeba ich wgrywać jako podprogramów. Main wywołuje jedynie techniczne BG_BIND i PLC_REC; ruchy, próżnia, cele siłowników oraz zgłoszenia zdarzeń są widoczne w jego własnej treści.

## Komentarze i zmienne

Każdy LS ma indywidualny opis. Każdy używany R/F/PR/DI/DO/GI/GO otrzymuje krótką etykietę przy operandzie i pełny komentarz przed pierwszym użyciem w danym programie. Składowe PR oraz zmienne systemowe mają komentarze przy użyciu; zachowują właściwą składnię numeryczną.

Słownik obejmuje znaczenie ON/OFF, kierunek sygnałów, jednostki, maski i wartości kodów. Przykładowo S w nazwie nastawy oznacza staging do edycji, A aktywną kopię po APPLY; T/B oznacza odpowiednio TRAY/BOX. Rx to snapshot z PLC, Cmd lokalne żądanie/status, Tx zwalidowany bufor wyjścia, ACK zamrożone dane zdarzenia. M występuje wyłącznie w izolowanym TEST i oznacza wejście modelowe.

[descriptions.csv](descriptions.csv) i [descriptions.json](descriptions.json) są eksportem opisów produkcji/BG. Komunikacja i TEST mają własne eksporty. Ich źródłem jest tools/fanuc_meanings.csv, katalog sygnałów v2 oraz semantyka punktów w tools/fanuc_descriptions.py. Brak definicji przerywa generowanie; test sprawdza również brak mylących powtórzeń etykiet. Komentarze LS są po polsku bez znaków diakrytycznych. Standardowe linie komentarza mieszczą się w 32 znakach, a opis ATTR w 16, zgodnie z dostarczonym HandlingTool 8.30 (§8.19.6 i §8.2.8); odbiór V9.40 pozostaje osobny.

Etykieta w LS nie jest dowodem zapisania komentarza w natywnej tabeli FANUC. Import opisów, dopuszczalne długości i poprawne wyświetlanie na V9.40 trzeba sprawdzić na kontrolerze. Eksport CSV pozwala porównać każdą pozycję z jego tabelami bez wymyślania binarnego formatu konfiguracji.

## Jeden właściciel

R331 zapisuje wyłącznie BG_STATUS: 0 brak, 1 MAIN_BOX, 2 MAIN_TRAY. Lokalnie uruchomiony main zgłasza żądanie; przed przyznaniem wyboru nie wydaje komend procesu.

Przyznanie wymaga zamkniętego zlecenia, zweryfikowanych native i zasobów, HOME, znanego pustego chwytaka, rozliczonych wtrysków i bezczynnych REQ/ACK. Tylko jeden natywny main może być aktywny/paused i zgłaszać wybór. Oba aktywne zadania lub oba żądania zatrzaskują konflikt. PLC expectedProgram i praca PLC_SVC nie zastępują identyfikacji main.

Po rozliczonym zakończeniu zlecenia w HOME oba programy przechodzą do kroku 720 z zachowaną sesją PLC. Operator potwierdza pusty postój przez stationIdleConfirmed i wybiera NEW. Po przyjęciu NEW panel udostępnia otwarcie kolejnego zlecenia, a wznowienie produkcji wymaga nowego fizycznego Startu.

Sekcja EXIT zgłasza zwolnienie. BG przyjmuje je w stanie 710, 720 lub 900, przy zamkniętym zleceniu, HOME, stationIdleConfirmed, znanym pustym chwytaku, braku partii, remaining=0 oraz rozliczonych kanałach/wtryskach. Main kończy pętlę po zwolnieniu. Przed drugim main trzeba zakończyć stare zadanie, także PAUSE. Konflikt wymaga jawnej wspólnej inicjalizacji przy obu zakończonych zadaniach i pustej uzgodnionej stacji.

Nie ma mailboxu ani kopiowania danych między bankami produkcyjnymi. Każdy main używa bezpośrednio własnych nastaw i kontekstu oraz interfejsu COMM.

## Komendy operatora wewnątrz main

| Komenda / potwierdzenie | TRAY | BOX |
|---|---|---|
| INIT: jawne wyzerowanie prywatnych danych | F1 | F101 |
| NEW: nowy pusty kontekst | F2 | F102 |
| RECOVERY: zgoda na uzgodnienie | F3 | F103 |
| Sprawdzono kontekst z PLC | F4 | F104 |
| Potwierdzony pusty postój stacji | F5 | F105 |
| APPLY: jednorazowe zastosowanie staging | F47 | F151 |
| EXIT: jednorazowe zwolnienie wyboru | F48 | F152 |

To lokalne komendy, bez nowych pól w protokole PLC. INIT działa w wybranym, nieuzbrojonym main przy pustym postoju potwierdzonym przez operatora i BG; nie zeruje native, drugiego banku ani właściciela. Zatwierdzenia profilu, trajektorii i punktów po INIT są wyłączone. INIT nie zostanie przyjęty przy zachowanej przypisanej partii lub remaining większym od zera; najpierw trzeba uzgodnić jej rozliczenie. NEW i RECOVERY obsługuje sekcja stanu 900. APPLY/EXIT są konsumowane po próbie wykonania. Nie ustawiać potwierdzeń z wyprzedzeniem ani zbiorczo.

## Zasoby i pierwsze przygotowanie

| Bank | Rezerwacja |
|---|---|
| R1–200 | Dotychczasowe COMM/TRAY, numery bez zmian |
| R201–330 | BOX: staging R201–241, aktywne R242–282, kontekst R283–307 |
| R331–360 | Wspólny wybór main; R332–349 po usunięciu mailboxu nieużywane |
| R361–400 | Rezerwa |
| F1–98 / F101–300 | Prywatne TRAY / BOX; nowe APPLY/EXIT w F47/F48 i F151/F152 |
| F401–480 | Native i wspólne blokady; F410/F411 oraz F432–443 nieużywane |
| F501–759 | COMM |
| PR1 / PR2–40 / PR41–95 | Wspólne HOME / TRAY / BOX |

1. Zachować backup. Sprawdzić pojemność co najmniej R400, wymagane F/PR, pamięć programów po rozwinięciu technologii i kolizje. Nie zmieniono konfiguracji kontrolera.
2. Przy zakończonych main, zatrzymanym serwisie i BG zaimportować spójny pakiet. Z poprzedniego pakietu usunąć wyłącznie programy wskazane w [migracji nazw](../program-migration.csv). TEST jest oddzielną alternatywą, nigdy dodatkiem do LIVE.
3. Wykonać PLC_INIT LIVE przy pustej stacji. Uzupełnić 14 źródeł native, odtworzyć LS i zweryfikować BG_BIND, bindingsVerified oraz capacityVerified.
4. Uruchomić trzy BG, skonfigurować komunikację i lokalnie PLC_LIVE. Przy obu zakończonych main, zamkniętym zleceniu, HOME i wygaszonych kanałach potwierdzić wspólne emptyConfirmed/initApproved. BG ustala NONE i znany pusty chwytak.
5. Ręcznie uruchomić wybrany main. Po przyznaniu wyboru wykonać ewentualny prywatny INIT z potwierdzeniem pustego postoju. Wejście BOOT wymaga uzgodnienia; zakończyć świeżą obustronną synchronizację do recovery.
6. Przy rzeczywiście pustej stacji potwierdzić NEW w main, następnie APPLY po edycji staging i stationIdleConfirmed. Oddzielnie odebrać profil, punkty, trajektorie i reakcję alarmu. Wyjaśnienia wszystkich flag znajdują się w LS i manifestach.
7. Dopiero po gotowej sesji otworzyć właściwe zlecenie i przyjąć nowy fizyczny Start PLC. Nie używać UOP do wyboru/startu main.

Zwykły Stop zachowuje kontekst i nie wymaga INIT/NEW. Po krytycznym przerwaniu obowiązuje uzgodnienie ładunku oraz trwałych skutków z PLC, HOME, synchronizacja, jawne recovery i świeży Start. Import, wykonanie BG, alarmy, geometria i FAT/SAT pozostają NIEWYKONANE.
