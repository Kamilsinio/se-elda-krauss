# Plan implementacji i odbioru SE-ELDA-Krauss

Data bazowa: 2026-10-04. Dokument wykonawczy dla kolejnych etapów adaptacji.

## 1. Stan realizacji i zasady prowadzenia prac

Etap E0 przygotowuje instrukcję agenta, [założenia](project-assumptions.md), [interfejsy](interfaces.md), macierz wymagań, testy i rejestr braków. Stan załączników podaje [rejestr źródeł](sources/README.md).

**Źródła sterowania ST/LS/VA/DG nie zostały zmienione w etapie E0. Etapy E1–E5 nie są zrealizowane.** Repozytorium przechowuje eksporty, a zewnętrzne źródła są zarejestrowane w [analizie workspace](workspace-analysis.md): fizyczny backup FANUC V9.40P/80, przykład EDS, wzorce W716/W590 oraz projekty PLC/HMI. Dostępność tych materiałów nie oznacza ich integracji ani odbioru.

Aktualizacja 2026-11-14: przygotowano [kontrakt PLC–robot](robot-plc-contract.md), katalog sygnałów, migrację symboliczną LS/GVL/IOSTATE oraz [analizę modernizacji](robot-modernization.md). To dokumentacyjna część przygotowania E1/E4; fizyczne mapowanie i przepisanie kodu nie zostały wykonane. [Raport](robot-communication-verification.md) zawiera wynik audytu statycznego, scenariusze i konkretne bramki danych.

Status każdego testu AT poniżej: **NIEWYKONANY**. Przegląd dokumentacji nie zmienia tego statusu. Przyszły raport testu ma podawać ID, wersję kodu, konfigurację sprzętu, rodzaj weryfikacji, warunki początkowe, przebieg, wynik i dowód. Oddzielać przegląd statyczny, kompilację, import FANUC, symulację i FAT/SAT.

Każdy zakres zmian przypisać do REQ, zależnych GAP i AT. Brak danych blokuje tylko zależny fragment; można kontynuować niezależną pracę. Zamknięcie GAP wymaga konkretnego dowodu i aktualizacji dokumentacji, a nie domyślnego przyjęcia wartości.

Wszystkie zapisy pozostają w se-elda-krauss. Istniejące zmiany użytkownika, stare repozytorium i oryginały materiałów zewnętrznych pozostają zachowane.

## 2. Etapy i zależności

| Etap | Zakres | Warunek odbioru |
|---|---|---|
| E0 — dokumentacja | Aktualne AGENTS/README, trzy dokumenty projektu i interfejsy, materiały źródłowe, REQ/AT/GAP | Spójne odsyłacze i identyfikatory; jawny stan załączników i braków; potwierdzenie braku zmian w źródłach sterowania |
| E1 — sprzęt i komunikacja | Mapa I/O, EtherNet/IP robot/Festo, EUROMAP, ważność danych i diagnostyka | Zamknięte odpowiednie GAP; potwierdzone kierunki, polaryzacje, assembly, reakcje na zanik danych i granice obwodów bezpieczeństwa |
| E2 — urządzenia i stacje | Bariera ST.1, V201/V202, dolne stopery, V401/V402, BAT4 | Zweryfikowane urządzenia i ręczne ruchy z blokadami; osobna diagnostyka; brak zgadywanych kanałów |
| E3 — zlecenia i proces | Koordynacja Start/Stop/Koniec zlecenia, rozliczenie operacji, pojedyncze wydanie, pełne opróżnianie | AT-01–AT-07 w odpowiednich wariantach i obu produkcjach; brak utraconych/podwójnych zdarzeń |
| E4 — integracja robota i HMI | Oba LS, diagnostyka kroku, alarmy, interfejs HMI i ekrany według W716/C30 | Kompilacja/import w docelowych środowiskach oraz odpowiednie AT-08–AT-15 |
| E5 — odbiór stanowiska | Parametry, trajektorie, testy rzeczywistych czujników i urządzeń | Zamknięte braki wpływające na uruchomienie; raporty prób, zapisane nastawy i backupy urządzeń |

E3 wymaga kontraktów PLC–robot–IMM z E1 i współpracy programów robota rozwijanych w E4. Nie traktować etapów jako niezależnych wysp: przed testem Stop muszą działać obie strony wymiany. Ekrany HMI można przygotowywać po ustaleniu kontraktu danych, ale ich wygląd i środowisko zależą od GAP-07.

## 3. Zakres zmian kodu

### Koordynacja procesu

Dodać planowany `FB_OrderManager`: otwieranie i zamykanie zlecenia, zatwierdzony rodzaj produkcji, dopuszczenie Start, żądanie normalnego zatrzymania, przejście do opróżniania oraz statusy dla HMI. Oddzielić stan zlecenia, tryb Auto/Manual, stan wykonania i opcję Praca z robotem.

Dodać planowany `FB_StationDrain` i przenieść odpowiednią część opróżniania z `PRG_Main`. Zachować właściciela transferu P4→P5, stan ładunku windy i opóźnione potwierdzenia. Koniec zlecenia nie może zerować sekwencerów przed rozliczeniem rozpoczętych operacji.

W istniejących sekwencerach Blistrów/Pojemników oddzielić: żądanie zakończenia po operacjach, krytyczne przerwanie, pauzę/wznowienie i opróżnianie. Wymagany stan robota i wtryskarki musi być jawny w ich wejściach/statusach. Nie realizować nowego Stop jednym wspólnym `AbortAuto`.

### I/O i urządzenia

Przebudować `GVL_IO_RAW`, logiczne I/O i `PRG_IO_Read/Write` według zatwierdzonej mapy. Adresy wynikają z projektu urządzeń, nie z podobieństwa nazw.

Rozbudować TopFlow o barierę i niezależne zwolnienie załadunku; dolny akumulator o stopery B302/B303, właściciela wydania i potwierdzenie odbioru B304. Zachować blokady taśm i sekwencję zajętości.

Rozdzielić V201/V202 oraz V401/V402 na oddzielne sterowania i diagnostykę. Zachować wspólny warunek końca ruchu. Zmienić interpretację WORK magazynu na zamknięcie.

Dodać obsługę żądań i potwierdzeń całego BAT4. Nie tworzyć równoległego sterowania tym samym zaworem z PLC i starego RI/RO. Przejrzeć klasyfikację błędów urządzeń i ich propagację do sekwencerów.

### Robot i EUROMAP

Dodać planowany `FB_ImmInterface` jako jeden właściciel końcowych procesowych wyjść do Krauss. Wybór źródła komend i kontrola przejść między współpracą, pracą samodzielną i Manual muszą być jawne.

Rozszerzyć `GVL_Robot` i logiczną wymianę o IMM, BAT4, fazę cyklu, normalne zatrzymanie i diagnostykę. Oddzielić zmienne logiczne od fizycznego transportu danych.

Adaptować `A01_F2679_TACKI.LS` i `AAAA_MAIN_BOX_PRG.LS` po pozyskaniu brakujących podprogramów. Uwzględnić WAIT zależne od następnego wtrysku, podtrzymanie potrzebnych zezwoleń, rozróżnienie zdarzeń warstwy/stosu i potwierdzenie rozliczenia operacji. Nie wdrażać zdalnego startu UOP.

Diagnostyka robota ma wskazywać krok, oczekiwany warunek i miejsce timeoutu. Różne przyczyny nie powinny trafiać wyłącznie do wspólnego LBL[901]. Zasady czasu oczekiwania na operatora i na ruch urządzenia trzeba rozróżnić; nie dodawać arbitralnego timeoutu wszędzie.

### Alarmy, HMI i rozruch

Dodać rzeczywisty `FB_AlarmManager`; stara instrukcja błędnie podawała go jako istniejący. Oddzielić alarmy krytyczne, ostrzeżenia i informację o zwykłym oczekiwaniu. Z tego samego modelu wyprowadzić andon i HMI.

Rozszerzyć `GVL_HMI` o stany zlecenia i zakończenia pracy, dostępność komend, przyczyny blokad, parametry stacji i diagnostykę komunikacji. Stare pola nie mogą omijać nowej nadrzędnej logiki.

Wykonać ekrany po zamknięciu GAP-07. Blokady pozostają w PLC, nie wyłącznie na HMI. Ręczne wymuszenia EUROMAP są kasowane przy przejściu do Auto; reset stanów stacji tylko w Manual.

Przywrócić rzeczywistą kontrolę pozwoleń i aktualności danych zamiast stałych testowych. Wdrożyć jawny stan wymagający odzyskania po restarcie i brak samoczynnego ruchu po resecie lub powrocie łączności.

## 4. Macierz wymagań

W = Wytyczne klienta, sekcja podana w kolumnie źródła. DEC = potwierdzona decyzja w założeniach. D = jawne założenie projektowe z planu.

| ID | Wymaganie i kryterium realizacji | Źródło | Moduł/obszar | Testy |
|---|---|---|---|---|
| REQ-01 | Start zlecenia otwiera zlecenie bez ruchu; fizyczny Start uruchamia/wznawia dopuszczony automat | W Obsługa automatu, DEC-01 | OrderManager, HMI | AT-01 |
| REQ-02 | Zmiana Pojemniki/Blistry tylko przy zamkniętym zleceniu, również zablokowana podczas opróżniania | W Obsługa automatu | OrderManager, HMI | AT-01, AT-04 |
| REQ-03 | Stop kończy rozpoczęte operacje bez uruchamiania nowych cykli; oddzielony od AbortAuto | W Panel operatora, DEC-02 | Koordynacja, robot, IMM | AT-02, AT-03 |
| REQ-04 | Zachowane nakładanie cykli; rozliczony także wtrysk rozpoczęty podczas odkładania | DEC-03 | Robot, IMM, koordynacja | AT-03 |
| REQ-05 | Koniec zlecenia kończy operacje, usuwa pełne/niepełne/puste ładunki i zamyka zlecenie po opróżnieniu | W ST.3, DEC-04/05 | StationDrain, sekwencje | AT-04 |
| REQ-06 | Lokalne naciśnięcie wydaje jeden gotowy stos; brak powtarzania przy przytrzymaniu i kolejkowania bez gotowości | W ST.3, D | Dolny akumulator | AT-05 |
| REQ-07 | Kolejny stos czeka na potwierdzony odbiór B304; stopery działają przy B302/B303 | W ST.3 | Dolny akumulator, StationDrain | AT-05 |
| REQ-08 | Osobna bariera ST.1 potwierdza pełny przejazd i umożliwia wcześniejsze przygotowanie następnego stosu | W ST.1, DEC-09 | TopFlow, I/O | AT-06 |
| REQ-09 | V201/V202 niezależne, równoczesne w Auto, oba potwierdzenia wymagane, Manual osobny | W ST.2, DEC-10 | Winda, pozycjonery | AT-07 |
| REQ-10 | V401/V402 niezależne, wspólna sekwencja; WORK oznacza zamknięcie; dostęp po właściwych potwierdzeniach | W ST.4, DEC-11 | Storage | AT-07 |
| REQ-11 | PLC pośredniczy w procesie robot–Krauss; jeden właściciel wyjść EUROMAP | Architektura użytkownika | ImmInterface, I/O, LS | AT-08, AT-10 |
| REQ-12 | Chwytak sterowany przez PLC/Festo; potwierdzenia przez PLC, także z KEC3; brak równoległego starego RI/RO | DEC-13 | BAT4, robot, I/O | AT-09, AT-15 |
| REQ-13 | Rzeczywista diagnostyka robot/Festo i aktualność danych; nieaktualne HOME nie udziela pozwoleń | D z planu | Komunikacja, HMI | AT-09 |
| REQ-14 | Praca z robotem włączana przy HOME, wyłączana po zakończonym Stop; samodzielny Krauss niezależny od zlecenia | W Obsługa robota, DEC-07/08 | Koordynacja, IMM | AT-10 |
| REQ-15 | Program uruchamiany lokalnie na FANUC; zgodność z produkcją sprawdzana; bez zdalnego startu UOP | DEC-12 | Robot, PLC–robot | AT-10 |
| REQ-16 | Ostrzeżenie siłownika blokuje zależny ruch bez globalnego Stop i wtórnej eskalacji tej samej przyczyny | W Podział błędów, DEC-06 | Urządzenia, sekwencje, alarmy | AT-11 |
| REQ-17 | Krytyczny alarm zatrzymuje natychmiast; Reset nie uruchamia; wznowienie wymaga warunków i Start | W Podział błędów, D | AlarmManager, koordynacja | AT-12 |
| REQ-18 | Manual EUROMAP tylko przy Manual/HOME i zatrzymanej współpracy; wejście w Auto kasuje wymuszenia | W Obsługa wtryskarki | IMM, HMI | AT-08 |
| REQ-19 | Restart/powrót komunikacji bez automatycznego wznowienia; stan ładunków wymaga uzgodnienia | D z planu | Inicjalizacja i odzyskiwanie | AT-09, AT-13 |
| REQ-20 | Karty HOME/zlecenie/alarmy/stacje/parametry/manual, kolory, blokady, progi; reset stanów tylko Manual; bez receptur | W HMI i Podział błędów | GVL_HMI, HMI, alarmy | AT-01, AT-11, AT-14 |
| REQ-21 | Priorytet robota, wspólne transfery, brak ruchu stoperów z taśmą, bazowanie windy do krawędzi | Zachowana funkcja bazowa | Transport, winda | AT-06, AT-14 |
| REQ-22 | Diagnostyka kroku/timeoutu robota, rozróżnione zdarzenia i potwierdzenia bez zgubienia/powtórzenia | W ST.5, D | LS, komunikacja, HMI | AT-03, AT-09, AT-14 |

## 5. Scenariusze odbiorcze

Wszystkie próby wymagające ruchu wykonywać dopiero w przygotowanym środowisku i z potwierdzoną konfiguracją sprzętu. Nie wykonywano ich w E0.

| ID | Warunki i próba | Oczekiwany wynik |
|---|---|---|
| AT-01 | Obie produkcje: Start przy braku zlecenia, otwarcie zlecenia, fizyczny Start, zmiana typu w każdym stanie | Otwarcie bez ruchu; produkcja wymaga zlecenia i Start. Zmiana typu dopiero po zamknięciu. Blokada komendy widoczna na HMI. |
| AT-02 | Stop podczas wtrysku, pobierania, odkładania, wymiany tacki/przekładki i transferu; następnie Start | Kończą się rozpoczęte operacje, nie rusza nowy cykl. Informacja o ładunku pozostaje spójna. Wznowienie po sprawdzeniu warunków, bez wymuszonego globalnego resetu. |
| AT-03 | Wtrysk N+1 w trakcie odkładania N; Stop/Koniec zlecenia przed i po potwierdzonym starcie N+1; opóźnione i długo utrzymane ACK | Rozpoczęty N+1 obsłużony dokładnie raz; nierozpoczęty nie powoduje nieskończonego WAIT na formę. Potwierdzenie zakończenia dopiero po rozliczeniu wszystkich operacji. |
| AT-04 | Koniec zlecenia: niepełny ładunek windy, reszta blistrów P3, pełny dolny bufor; kolejno odbierać stosy | Najpierw kończą się rozpoczęte operacje, potem opróżnianie. Pusty stos jedzie w całości po zwolnieniu windy. Zlecenie aktywne aż do odebrania ostatniego ładunku. Po zamknięciu GAP-10 objąć Stop/Start i Manual w trakcie opróżniania. |
| AT-05 | Przytrzymanie lokalnego przycisku, naciśnięcie bez gotowego stosu, zajęte B304, drgania, B304 stale 1/0, prawidłowy odbiór | Jedno zaakceptowane naciśnięcie daje jedno wydanie. Brak kolejki starego żądania. Następne wydanie wymaga wiarygodnego odbioru. Stopery utrzymują pozostałe ładunki. |
| AT-06 | Częściowy/pełny przejazd przez barierę ST.1; przygotowanie kolejnego stosu podczas dalszego transportu; pełne bufory | Brak przedwczesnego uznania przejazdu; blokada wjazdu i gotowość załadunku we właściwym momencie. Priorytet podania do robota, wspólne transfery i nieruchome stopery przy ruchu taśmy. |
| AT-07 | V201/V202 i V401/V402: obie pozycje, tylko jedna, opóźnienie, sprzeczne krańcówki, ręczny ruch każdej osi | Brak dalszego zależnego kroku z jednym potwierdzeniem. Diagnoza wskazuje oś. Dostęp do magazynu wymaga właściwych obu pozycji i pozostałych blokad. |
| AT-08 | Manual EUROMAP przy braku/nieaktualnym HOME, w Auto i podczas współpracy; dozwolone wymuszenie, następnie Auto | Niedozwolone komendy odrzucone przez PLC. Ręczne wymuszenia skasowane przed Auto. Brak konkurujących zapisów wyjść i wymuszania obwodów bezpieczeństwa. |
| AT-09 | Zanik EtherNet/IP robota, bramki Festo, pojedynczego modułu; zamrożone HOME=1; przywrócenie komunikacji | Właściwa diagnostyka, nieważne dane nie udzielają pozwoleń. Brak automatycznego wznowienia lub powtórzenia zdarzenia. Zachowanie wyjść zgodne z GAP-03/08. |
| AT-10 | Praca z robotem w HOME/poza HOME, przed/po Stop; niewłaściwy program FANUC; Krauss samodzielnie bez/z aktywnym zleceniem | Poprawne blokady opcji. Samodzielne pozwolenia niezależne od zlecenia przy HOME; brak transportu produkcyjnego i paletyzacji. Niezgodny program blokuje współpracę. |
| AT-11 | Brak krańcówki siłownika ST.1–ST.4 przez czas dłuższy od progów urządzenia i nadrzędnego oczekiwania; oddzielna usterka krytyczna | Pomarańczowy andon, dokładne źródło, zależna sekwencja czeka. Ta sama przyczyna nie eskaluje przez wtórny timer; niezależny krytyczny błąd nadal zatrzymuje. Parametry są dostępne we właściwej stacji. |
| AT-12 | Utrata rzeczywistego pozwolenia bezpieczeństwa lub alarm krytyczny; Reset przy utrzymanej/usuniętej przyczynie | Natychmiastowe zatrzymanie automatu, czerwony andon, brak obejścia TRUE. Reset nie powoduje ruchu; Start odrzucony przy niespełnionych warunkach. |
| AT-13 | Restart PLC/robota w postoju, z detalem w chwytaku, między czujnikami podczas transferu i podczas opróżniania | Brak samoczynnego ruchu i automatycznego uznania stacji za pustą. Wymagane uzgodnienie stanu zgodnie z GAP-11; stare zdarzenie nie jest wykonane ponownie. |
| AT-14 | Co najmniej dwa pełne cykle obu produkcji, pełne bufory, bazowanie windy, próbki, przekładki, wszystkie karty HMI i oczekiwania robota | Spójne liczniki i wysokość odkładania, zachowane transfery i próbki. Kody robota rozróżniają oczekiwania; HMI pokazuje blokady. Manual w Auto nieaktywny także po stronie PLC; reset stanów tylko Manual. |
| AT-15 | Chwytak: prawidłowe/brakujące podciśnienie, przedmuch, Stop z ładunkiem, alarm i zanik komunikacji/energii według uzgodnionej procedury | Sterowanie i potwierdzenia przechodzą nowym interfejsem. Zachowanie ładunku i cewek odpowiada potwierdzonej pneumatyce; brak domyślnego „wszystkie OFF”. |

Każdy scenariusz wykonać w obu trybach produkcji tam, gdzie ma zastosowanie. Brak fizycznego czujnika, konfiguracji lub narzędzia oznacza BLOCKED z podaniem GAP, nie wynik pozytywny.

## 6. Rejestr braków i rozbieżności

Wszystkie wpisy nadal mają status **OTWARTE w pozostałym zakresie**. Część danych wejściowych już odnaleziono; poniższe wpisy i [analiza workspace](workspace-analysis.md) określają konkretne nierozstrzygnięte części, bez ponownego żądania dostępnych materiałów. Uzupełniający zapis zamknięcia powinien zawierać źródło, datę, ustaloną wartość/zachowanie i zależne dokumenty. Użytkownik zaakceptował prowadzenie tego rejestru zamiast zgadywania danych.

| ID | Brak/rozbieżność | Dowód potrzebny do zamknięcia | Zależny zakres |
|---|---|---|---|
| GAP-01 | Osobna bariera pełnego przejścia ST.1 | Oznaczenie, położenie, polaryzacja, wejście, mechanizm blokowania wjazdu i warunek pełnego przejazdu | ST.1, REQ-08, AT-06 |
| GAP-02 | B205 nie ma pokazanego podłączenia sygnału do PLC w P0001 | Uzupełniony schemat i potwierdzony kanał/polaryzacja sygnału | Winda, obecność/poziom ładunku |
| GAP-03 | Festo AP: kody VTUX i typy zaworów dostępne w SRC-09; nadal brak zatwierdzonego obrazu procesowego i pełnych pomiarów próżni | Konfiguracja, kanały/assembly, długości/offsety, RPI, diagnostyka, sygnały próżni/przedmuchu i reakcje wyjść | E1/E2, BAT4, AT-09/15 |
| GAP-04 | Dostępne: fizyczny backup V9.40P/80, opcje EIP, wzorce W716/W590 i trzy podprogramy TP (SRC-10/11); eksport LS i audyt pozostają OTWARTE | Odczyt/eksport TP, źródło HOME/identyfikacji programu, potwierdzenie instrukcji i konfiguracji EIP, ramki/narzędzie/obciążenia i punkty | Adaptacja LS, zgodność programów, AT-10/14 |
| GAP-05 | EUROMAP: brak rozpoznania początku wtrysku i niepełne KF211/KF403; odkryte wspólne zasilanie KF204–KF210 przez KF203:14 | Lista używanych sygnałów, zaciski/polaryzacje, początek/koniec wtrysku, podtrzymanie pozwoleń z uwzględnieniem wspólnego zasilania, granica safety | ImmInterface, Stop przy nakładaniu cykli |
| GAP-06 | Znaleziono zewnętrzne projekty PLC i eksport symboli (SRC-13); wersja docelowa i środowisko niezatwierdzone | Wybór projektu, biblioteki/firmware, zadania, skaner i obraz I/O, ATV320/Axis_Ref oraz potwierdzenia układu bezpieczeństwa | Kompilacja, rzeczywista mapa i diagnostyka |
| GAP-07 | Znaleziono dwa wzorce HMI Vijeo .vdz (SRC-13); zgodność z W716/C30 nadal do weryfikacji | Wskazanie projektu bazowego i wzorca, kompletny model panelu i wersja narzędzia | Wykonanie ekranów, integracja HMI |
| GAP-08 | Pneumatyka SRC-09 potwierdza pięć obwodów i warianty F-2844/F-2680; porty Y502/Y503 sprzeczne między arkuszami 010/021 | Rozstrzygnięcie portów i HP/WP, przypisanie narzędzi, grup siłowników i ilości detali, utrzymanie ładunku/cewek przy Stop i awarii | E2, reakcje na awarie, AT-07/15 |
| GAP-09 | Przewodowe procesowe sygnały robota w schemacie/arkuszu vs docelowy EtherNet/IP | Aktualizacja lub jednoznaczne oznaczenie rewizji, wykaz pozostających przewodowych funkcji i usunięcie konkurujących kanałów sterowania | Docelowa mapa robot–PLC–IMM |
| GAP-10 | Szczegóły obsługi postoju/Manual/opróżniania i starego HMI Start | Uzgodnione Stop/Start podczas opróżniania, przejście do Manual, Koniec zlecenia z postoju, dostępność starego HMI Start i wydania lokalnego podczas pauzy | Odpowiednie przejścia OrderManager/StationDrain/HMI |
| GAP-11 | Retencja i odzyskiwanie po restarcie | Lista zachowywanych danych oraz procedura uzgodnienia ładunków, robota i wtryskarki przed Start; bez automatycznego wznowienia | Inicjalizacja, AT-13 |
| GAP-12 | Pełna macierz alarmów poza uzgodnionymi ostrzeżeniami siłowników | Klasyfikacja, warunki kasowania/wznowienia i reakcje m.in. dla falownika, chwytaka, próżni i komunikacji; bez wtórnej eskalacji tej samej przyczyny | AlarmManager, reakcje krytyczne, AT-11/12/15 |

GAP-10–GAP-12 uszczegóławiają punkty konieczne dla implementacji produkcyjnej. Nie zmieniają potwierdzonych decyzji: normalny Stop kończy rozpoczęte operacje, Reset nie uruchamia, a ostrzeżenie siłownika nie zatrzymuje globalnie.

Arkusz I/O zawiera nazwy i adresy robocze oraz zakładki oznaczone placeholder. Zamknięcie GAP wymaga potwierdzenia, nie usunięcia samego słowa TBD.

## 7. Wyniki przeglądu bazy kodu

Poniższe pozycje są faktami z przeglądu, nie wykonanymi poprawkami. Numery w kolumnie odnoszą się do linii plików odczytanych w E0, nie do numerów kroków LS.

| Miejsce | Obserwacja | Zadanie |
|---|---|---|
| POUs/PRG_Main.st:180 | xSafetyOK := TRUE | Zastąpić rzeczywistym uzgodnionym pozwoleniem; nie utożsamiać logiki PLC z funkcją bezpieczeństwa |
| GVLs/GVL_Robot.st:87 | xRobotCommOk inicjalizowane TRUE bez aktualizacji w aktywnych źródłach | Wprowadzić diagnostykę rzeczywistego połączenia i ważności |
| POUs/FB_TraySequencer.st:367 | Zakomentowany blok „do testów” obsługi błędu/timeoutu gotowości robota | Przywrócić właściwą kontrolę zgodną z nowym kontraktem |
| ../Robot M20iD/old/ROBOT/A01_F2679_TACKI.LS:232 i :234 | Zapis //WAIT dla potwierdzenia wyrzutnika i próżni RI1–RI4 | Zweryfikować eksport i czynną kontrolę nowych potwierdzeń |
| ../Robot M20iD/old/ROBOT/A01_F2679_TACKI.LS:105; ../Robot M20iD/old/ROBOT/AAAA_MAIN_BOX_PRG.LS:703 | Przykładowe WAIT bez timeoutu; występują kolejne | Zdiagnozować warunek/krok i określić właściwą reakcję; odróżnić oczekiwanie procesowe od awarii |
| ../Robot M20iD/old/ROBOT/A01_F2679_TACKI.LS:275 | Oczekiwanie na zamknięcie kolejnego wtrysku przed odłożeniem | Uwzględnić zatrzymanie bez oczekiwania na cykl, który nie wystartuje |
| POUs/PRG_Main.st:509 | elevIn.xCommOk := TRUE; równocześnie winda ma xVfdCommOk z GIATV | Zweryfikować spójność diagnostyki wejścia i GIATV; nie twierdzić, że diagnostyki falownika nie ma |
| POUs/PRG_Main.st:635 i :735 | HMI Stop używany jako AbortAuto obu sekwencji | Oddzielić Stop, krytyczne przerwanie i Koniec zlecenia |
| POUs/PRG_Main.st:849 | Stop natychmiast przerywa opróżnianie | Zastąpić po rozstrzygnięciu GAP-10, zachowując stan transferu |
| POUs/PRG_Main.st:1351 | Alarmy zbierane w programie głównym; brak FB_AlarmManager | Wprowadzić rzeczywisty moduł i podział klas alarmów |
| ROBOT — oba programy | Wywołują BB_GRIPPER_RESET, BB_IMM_RESET, BB_RESET_VAC5; od 2026-11-14 znalezione jako TP we wzorcu W716 | Wyeksportować/odczytać LS i sprawdzić skutki; nie tworzyć pustych zastępników |
| Dawne instrukcje | Nieistniejąca nazwa AA_MAIN_TRAY_PRG.LS i nieaktualny model robota | W E0 zastąpione aktualnymi instrukcjami i odsyłaczami |

Dla ATV320 dodatkowo sprawdzić `FB_Elevator`: xVfdCommOk jest wyprowadzane z GIATV, a niektóre warunki korzystają również z wejścia xCommOk ustawianego na TRUE. To konkretna niespójność do oceny, nie dowód braku wszystkich mechanizmów diagnostycznych.

## 8. Zamknięcie etapu i przekazanie

E0 przekazuje specyfikację i otwarte dane. Kolejny wykonawca rozpoczyna od właściwego zakresu E1 i zamyka zależne GAP. Nie oznacza E1–E5 jako ukończonych na podstawie tego dokumentu.

Przed odbiorem każdej zmiany:
1. sprawdzić powiązanie z REQ i bieżący stan zależnych GAP;
2. sprawdzić stronę PLC, LS i HMI wspólnego interfejsu;
3. przeprowadzić odpowiednie testy i zapisać dowody;
4. zaktualizować dokumentację stanu faktycznego, mapę i statusy etapów;
5. zachować wersje źródeł, konfiguracji urządzeń i backupy użyte do prób.

Wgranie i uruchomienie na urządzeniach jest osobnym działaniem poza etapem dokumentacyjnym. E0 nie zmienia układu bezpieczeństwa ani ustawień urządzeń.

## 9. Aktualny zakres źródeł FANUC — 2026-11-14

Przygotowano kontrakt v2 (227 pól, 80 bajtów/kierunek), komunikację LIVE/TEST, dwa pełne main BOX/TRAY, słownik COMMON i trzy programy rejestrowane jako BG. [BOX](../ROBOT/BOX/README.md), [TRAY](../ROBOT/TRAY/README.md), [COMMON](../ROBOT/COMMON/README.md) i [raport](robot-communication-verification.md) opisują źródła, 65 testów offline i bramki uruchomienia.

To częściowa realizacja źródłowa E1/E3/E4: implementacja PLC, fizyczna mapa/konfiguracja, dostępność R400, import V9.40, nauka punktów i FAT/SAT nadal pozostają niewykonane. Powiązania native BG mają status UNBOUND; dopuszczenia ruchu są niezatwierdzone. Nie zamykać GAP-03/04/05/06/08/09/11/12 wynikiem interpretera.

Zrealizowany zakres BOX odpowiada REQ-02/03/04/11/12/13/15/17/19/22 oraz modelowym częściom AT-01/02/03/09/10/13/14/15. Obejmuje P1–P3, grupy i ilości, warstwy, przekładki, Stop N+1, ACK i recovery. Próby w środowisku robota i z rzeczywistym PLC są osobnymi kryteriami odbioru. Źródła ST i projekty natywne nie zostały zmienione.

Aktualizacja DEC-31/32 (2026-11-15): cała technologia jest bezpośrednio w MAIN_TRAY i MAIN_BOX. Usunięto wykonawcze mikroprogramy i runtime mailbox. Pozostały PLC_* oraz BG_*; dodano pełne opisy operandów, słowniki CSV/JSON i cztery kontrole czytelności. Import opisów i pamięć rozwiniętych main wymagają potwierdzenia na V9.40.
