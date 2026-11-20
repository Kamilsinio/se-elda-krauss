# HMI Krauss — instrukcja wykonania ekranów w Vijeo Designer

Zbuduj 20 paneli według kolejności z tabeli. Każdy panel korzysta ze wspólnego szablonu i ma własną listę obiektów. Ścieżki w kolumnie „Zmienna lub akcja” wskazują symbole PLC. Prefiks urządzenia i aplikacji wybierz z importu Vijeo. Kontrakt `uiContractVersion=4` potwierdzono w źródłach ST. Import i próby na docelowym panelu są otwarte.

## Lista ekranów

Zakładki lokalne i okna potwierdzeń dzielą numer panelu, do którego należą.

| Numer panelu | Nazwa | Przeznaczenie |
|---:|---|---|
| [1](#panel-1) | HOME | Przegląd stanowiska i wybór obsługi |
| [2](#panel-2) | ZLECENIE | Wybór produkcji i obsługa zlecenia |
| [3](#panel-3) | ALARMY | Alarmy aktywne, potwierdzenia i historia |
| [101](#panel-101) | ST.1 — STATUS | Załadunek |
| [111](#panel-111) | ST.1 — MANUAL | Ręczna obsługa załadunku |
| [121](#panel-121) | ST.1 — PARAMETRY | Nastawy załadunku |
| [102](#panel-102) | ST.2 — STATUS | Winda |
| [112](#panel-112) | ST.2 — MANUAL | Ręczna obsługa windy |
| [122](#panel-122) | ST.2 — PARAMETRY | Nastawy windy i procesu na windzie |
| [103](#panel-103) | ST.3 — STATUS | Rozładunek |
| [113](#panel-113) | ST.3 — MANUAL | Ręczna obsługa rozładunku |
| [123](#panel-123) | ST.3 — PARAMETRY | Nastawy rozładunku |
| [104](#panel-104) | ST.4 — STATUS | Magazyn przekładek |
| [114](#panel-114) | ST.4 — MANUAL | Ręczna obsługa osłon |
| [124](#panel-124) | ST.4 — PARAMETRY | Nastawy magazynu przekładek |
| [105](#panel-105) | ST.5 — STATUS | Robot i chwytak |
| [115](#panel-115) | ST.5 — MANUAL | Ręczna obsługa pneumatyki chwytaka |
| [125](#panel-125) | ST.5 — PARAMETRY | Liczba detali na wtrysk i podgląd czasów chwytaka |
| [201](#panel-201) | WTRYSKARKA / EUROMAP | Podgląd i dozwolone ręczne sygnały procesowe |
| [301](#panel-301) | DIAGNOSTYKA | Komunikacja i podgląd sygnałów |

Z HOME każda ikona otwiera Status swojej stacji (101–105). Na trzech kartach stacji umieść zakładki **Status / Manual / Parametry** w tym samym miejscu. Dla ST.2 prowadzą do 102, 112 i 122. Z karty robota można też przejść na EUROMAP 201.

## Typy i tryby obiektów

| Typ i tryb | Ustawienie |
|---|---|
| Text / Text Display | Stała etykieta lub tekst ze słownika kodów. Do tekstu dynamicznego użyj zasobu tekstowego sterowanego kodem albo lokalnego STRING z mapowania. Nieznany kod wyświetl z jego numerem. |
| String Display | Odczyt STRING z PLC albo tekstu wyliczonego lokalnie. Dla bieżących tekstów diagnostycznych PLC ustaw wyświetlanie `STRING[80]`. Przy długich opisach użyj pola wielowierszowego. |
| Lamp | Odczyt BOOL lub warunku logicznego. Dla sygnałów I/O ustaw ON/OFF na podstawie wartości i trzeci stan „Brak danych” przy nieważnym odczycie. |
| Numeric Display / odczyt | `Enable Input Mode` wyłączone. Ustaw typ zgodny z symbolem i jednostkę z tabeli. Kierunki to INT ze znakiem. |
| Numeric Display / Input Mode | `Enable Input Mode` włączone i klawiatura numeryczna. Zapisuj do bufora edycji. Wartość aktywną pokaż obok jako osobny odczyt. |
| Switch / Change Panel | `When Touch → Panel → Change Panel`. Ustaw konkretny numer docelowy. |
| Switch / akcja lokalna | Jedna akcja przy `When Touch`. Wybierz lokalną zakładkę lub filtr, otwórz okno lub zapisz wartość wskazaną w tabeli. Dla filtrów wielowartościowych użyj wyboru wartości. |
| Switch / transakcja | Jedno wywołanie skryptu na `When Touch`. Skrypt steruje bitem żądania według ACK. Właściwość `Toggle` pozostaw niewybraną dla komend i nastaw PLC. |
| Switch / Momentary ON | Naciśnięcie ustawia żądanie, zwolnienie je zeruje. Dla pojedynczego bitu użyj `Bit → Momentary ON` z akcją licznika. Dla zestawu bitów zastosuj opisane w tabeli akcje nacisku, trzymania i zwolnienia. |

Nazwy ustawień zależą od wersji edytora. [Instrukcja Vijeo Designer 6.2](https://download.se.com/doc/VD-userguide-V6.2/Vijeo-Designer-Starting-guide-English.pdf) · [Schneider Electric — Momentary ON](https://www.se.com/us/en/faqs/FA232961/).

<a id="szablon"></a>

## Wspólny szablon

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Tytuł ekranu | Text | Wyświetl nazwę z wykazu. | Stała lokalna |
| HOME / Zlecenie / Alarmy / Diagnostyka | 4 × Switch / Change Panel | Otwórz odpowiednio 1 / 2 / 3 / 301. | Lokalnie |
| Wstecz | Switch / Change Panel | Z Manual i Parametrów wróć do Statusu tej samej stacji. Z panelu 201 wróć do 105, z paneli 2, 3, 101–105 i 301 do 1. | Lokalnie |
| Status / Manual / Parametry | 3 × Switch / Change Panel | Na panelach każdej stacji otwórz kartę tej samej stacji według wykazu. | Lokalnie |
| Aktywny numer panelu | Akcja wejścia na panel | Zapisz numer otwartego panelu. Wybór zakładki lokalnej go nie zmienia. | `GVL_HMI.hmiV2.link.uiActivePanel` |
| Tryb potwierdzony | Text Display | 10 Manual, 20 Auto. | `GVL_HMI.hmiV2.state.uiMode` |
| Baner alarmu | String Display + Switch / Change Panel | Krytyczny czerwony, ostrzeżenie pomarańczowe. Użyj pierwszego zatrzaśniętego rekordu właściwej klasy z panelu 3 i otwórz 3 po dotknięciu. Przy utracie komunikacji pokaż „Brak danych”. | `GVL_HMI.vijeo.alarms.critical`<br>`GVL_HMI.vijeo.alarms.warning`<br>`GVL_HMI.vijeo.alarms.entries[i-1].latched`<br>`GVL_HMI.vijeo.alarms.entries[i-1].critical`<br>`GVL_HMI.vijeo.alarms.entries[i-1].text` |
| Łącze PLC / dane / sesja | 3 × Lamp + String Display | Sprawdź jakość w driverze i świeżość licznika PLC. Osobno pokaż ważność danych i uzbrojenie sesji z opisem PLC. | `GVL_HMI.hmiV2.link.uiPlcHeartbeat`<br>`GVL_HMI.hmiV2.link.xDataValid`<br>`GVL_HMI.hmiV2.link.xArmed`<br>`GVL_HMI.hmiV2.link.sDiag` |
| Blokada / wynik polecenia | 2 × String Display + Numeric Display | Wyświetl przyczynę blokady z pozwolenia, a po próbie tekst i kod odpowiedzi skojarzonej z żądaniem. | Pola `permit` i `rsp` opisane niżej |
| Potwierdź / Anuluj | 2 × Switch / akcja lokalna | Dla resetów stanów i komend uzgodnienia otwórz okno z nazwą czynności. Potwierdzenie uruchamia transakcję z tabeli, anulowanie zamyka okno. | Lokalnie |

Jeżeli wiersz wymienia kilka obiektów, utwórz je w podanej kolejności. Dla wierszy powtarzalnych wstaw osobne obiekty dla każdego wskazanego indeksu. Indeks `[i-1]` jest o jeden mniejszy od numeru logicznego, np. rekord alarmu nr 41 to `entries[40]`.

## Wspólne wiązania i akcje

### Sesja HMI

Przy dobrej jakości łącza i zgodnej wersji cyklicznie zwiększaj `GVL_HMI.hmiV2.link.uiHmiHeartbeat` (UINT z obrotem 65535 → 0). Po uruchomieniu lub utracie sesji wyzeruj `GVL_HMI.hmiV2.link.xArmReq`, wszystkie `cmd.*.xReq` oraz bity żądań ręcznych w `GVL_HMI.vijeo.manual`, `stationManual` i `immManual`. Poczekaj na neutralne przyciski, zanik wszystkich `rsp.*.xAck` i świeży heartbeat. Wyślij zbocze 0 → 1 w `GVL_HMI.hmiV2.link.xArmReq`, odczytaj `GVL_HMI.hmiV2.link.xArmed` i nowy `GVL_HMI.hmiV2.link.udiSessionId`, po czym przywróć ARM do 0. Blokuj polecenia przy nieaktualnym łączu, nieuzbrojonej sesji lub nieważnych danych sesji. Po powrocie łączności wymagaj świeżego gestu operatora. Okres heartbeat oraz skryptu podtrzymania dobierz poniżej `GVL_HMI.vijeo.hmiTimeoutMs` z zapasem na cykl komunikacji.

### Transakcja Switch dla klucza K

W tabeli panelu podano ścieżkę kończącą się na `.xReq`. Z tej ścieżki weź klucz K, np. `orderOpen`, i podstaw go w poniższych wiązaniach. W całym HMI obsługuj jedną transakcję naraz.

| Etap | Operacja | Symbole PLC |
|---|---|---|
| Dostępność | Odczytaj pozwolenie PLC oraz tekst blokady. Włącz przycisk przy aktualnej, uzbrojonej sesji, zgodzie PLC i braku innej transakcji. | `GVL_HMI.hmiV2.permit.K.xAllowed`<br>`GVL_HMI.hmiV2.permit.K.sReason` |
| When Touch | Zapisz aktualne ID sesji i nowy, rosnący niezerowy ID żądania (UDINT). Poczekaj, aż payload i ID zostaną zapisane, po czym ustaw `xReq=1`. Przytrzymaj je także po puszczeniu przycisku. | `GVL_HMI.hmiV2.cmd.K.udiSessionId`<br>`GVL_HMI.hmiV2.cmd.K.udiRequestId`<br>`GVL_HMI.hmiV2.cmd.K.xReq` |
| ACK | Przy `xAck=1` sprawdź zgodność sesji i ID żądania. Pokaż wynik 1 „Przyjęto” lub 2 „Odmowa”, kod i opis. Zakończenie czynności potwierdza właściwy status procesu. | `GVL_HMI.hmiV2.rsp.K.xAck`<br>`GVL_HMI.hmiV2.rsp.K.udiSessionId`<br>`GVL_HMI.hmiV2.rsp.K.udiRequestId`<br>`GVL_HMI.hmiV2.rsp.K.uiResult`<br>`GVL_HMI.hmiV2.rsp.K.uiReason`<br>`GVL_HMI.hmiV2.rsp.K.sReason` |
| Zamknięcie | Po odebraniu odpowiedzi ustaw `xReq=0` i poczekaj na `xAck=0`. Po zerwaniu połączenia pokaż brak potwierdzenia i sprawdź aktualny status procesu po uzbrojeniu nowej sesji. | `GVL_HMI.hmiV2.cmd.K.xReq`<br>`GVL_HMI.hmiV2.rsp.K.xAck` |

### Lampki I/O i ruch przytrzymywany

Dla każdej lampki z `GVL_HMI.vijeo.value.N` odczytaj `GVL_HMI.vijeo.valid.N` z tą samą końcówką. Oba pola są BOOL. Podpis „Komenda PLC” opisuje wynik sterowania. Do wskazania wykonanego ruchu użyj oddzielnych czujników i sprzężeń.

Dla paneli 111–113 przed naciśnięciem zapisz bieżącą sesję w `GVL_HMI.vijeo.stationManual.sessionId`. Na panelu 201 użyj `GVL_HMI.vijeo.immManual.sessionId`, a na 115 `GVL_HMI.vijeo.manual.udiSessionId`. Zacznij od stanu neutralnego. Podczas trzymania zwiększaj wskazany licznik `holdCounter` (UINT), odrębnie dla każdego urządzenia. Przy zwolnieniu, opuszczeniu ekranu lub utracie sesji zakończ żądanie i odświeżanie licznika. Po utracie zgody lub konflikcie wymagaj zwolnienia i nowego naciśnięcia. W Auto wyszarz te przyciski. Położenie po zwolnieniu wynika z wykonawcy PLC.

Na panelach 111–113 warunek dostępności dla kanału PLC n podłącz do `GVL_HMI.vijeo.allowManualPositive[n-1]` lub `GVL_HMI.vijeo.allowManualNegative[n-1]`. Liczniki dodatniego i ujemnego kierunku mają ten sam indeks `[n-1]`. Zapis ujemnego kierunku ma indeks `negativeFrom2[n-2]`. PLC ocenia również numer panelu, postój, stan urządzenia, rezerwację, HOME oraz blokady ruchu. Panel pokazuje dostępne bity diagnostyczne i potwierdzenia urządzenia.

### Edycja i reset stacji

Na panelach parametrów „Wczytaj / Anuluj” jest jednym przyciskiem, który pobiera aktywną nastawę i porzuca zmiany. Po wczytaniu porównuj edycję z aktywnymi nastawami. „Zastosuj” wysyła cały zestaw bieżącej stacji i jego rewizję bazową zapamiętaną przez PLC przy wczytaniu. Zablokuj edycję podczas transakcji. Po jej przyjęciu odśwież zestaw. ST.1–ST.4 wymagają postoju, braku recovery i zgodnej rewizji. Ilość ST.5 dodatkowo wymaga zamknięcia zlecenia.

Czasy wprowadzaj jako UDINT w ms, częstotliwości jako REAL w Hz z jedną cyfrą po przecinku. Do limitów użyj odczytów `GVL_Station.ParameterCfg.minTimeMs`, `GVL_Station.ParameterCfg.maxTimeMs`, `GVL_Station.ParameterCfg.maxHz` i `GVL_Station.ParameterCfg.limitsVerified`. Czasy ruchu i siłownika muszą przekraczać stabilizację. Rewizje oraz `verified` zapisuje PLC. Przy braku zatwierdzenia zestawu w PLC pokaż „Wymagane zatwierdzenie nastaw w PLC”.

Reset stanu ST.1–ST.5 wymaga lokalnego potwierdzenia, trybu Manual i postoju. PLC zgłasza potrzebę uzgodnienia stanu, zachowując model ładunków, liczniki i zobowiązania. Po usunięciu przyczyny i resecie wznowienie wymaga świeżego fizycznego Startu lub nowego naciśnięcia w Manual.

## Elementy na poszczególnych ekranach

<a id="panel-1"></a>

### Panel 1 — HOME

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| ST.1 Załadunek / ST.2 Winda / ST.3 Rozładunek / ST.4 Magazyn przekładek / ST.5 Robot | 5 × Switch / Change Panel | Otwórz odpowiednio 101 / 102 / 103 / 104 / 105. Kolor według skonfigurowanych, zatrzaśniętych alarmów tej stacji. Krytyczny czerwony, ostrzeżenie pomarańczowe, nieważne dane szare. | `GVL_HMI.vijeo.alarms.entries[i-1].station`<br>`GVL_HMI.vijeo.alarms.entries[i-1].configured`<br>`GVL_HMI.vijeo.alarms.entries[i-1].latched`<br>`GVL_HMI.vijeo.alarms.entries[i-1].critical`<br>`GVL_HMI.hmiIo.dataValid`<br>`GVL_HMI.hmiV2.state.xRobotDataValid` |
| Auto | Switch / transakcja | Poproś o tryb automatyczny po rozliczeniu operacji. | `GVL_HMI.hmiV2.cmd.modeAuto.xReq` |
| Manual | Switch / transakcja | Poproś o tryb ręczny po zatrzymaniu. | `GVL_HMI.hmiV2.cmd.modeManual.xReq` |
| Praca z robotem — Włącz | Switch / transakcja | Włącz współpracę przy potwierdzonym HOME i rozliczonych operacjach. | `GVL_HMI.hmiV2.cmd.robotEnable.xReq` |
| Praca z robotem — Wyłącz | Switch / transakcja | Wyłącz współpracę po zatrzymaniu, przy potwierdzonym HOME. | `GVL_HMI.hmiV2.cmd.robotDisable.xReq` |
| Praca z robotem / HOME | 2 × Lamp | Pokaż przyjętą opcję oraz HOME potwierdzone w sesji z rozpoznanym ładunkiem. | `GVL_HMI.hmiV2.state.xWorkWithRobot`<br>`GVL_HMI.hmiV2.state.xRobotHomeValid` |
| Reset alarmów | Switch / transakcja | Zażądaj skasowania po usunięciu przyczyny. Wznowienie wymaga odrębnej czynności. | `GVL_HMI.hmiV2.cmd.resetFaults.xReq` |
| Zlecenie / produkcja / wykonanie | 3 × Text Display | Opisy kodów jak na panelu 2. | `GVL_HMI.hmiV2.state.uiOrderState`<br>`GVL_HMI.hmiV2.state.uiProduction`<br>`GVL_HMI.hmiV2.state.uiExecutionState` |
| Gotowość na fizyczny START · lampka i tekst | Lamp + String Display | Wyświetl pozwolenie na Start oraz powód blokady. | `GVL_HMI.hmiV2.state.xCanPhysicalStart`<br>`GVL_HMI.hmiV2.state.sStartBlockReason` |
| PLC/HMI / FANUC / Festo / ATV320 | 4 × Lamp | HMI według jakości drivera i zmiany heartbeat. FANUC według sesji, bramka Festo według świeżości i diagnostyki BAT100, napęd według komunikacji. | `GVL_HMI.hmiV2.link.uiPlcHeartbeat`<br>`GVL_HMI.hmiV2.state.xRobotDataValid`<br>`GVL_Station.Inputs.gatewayHealthy`<br>`GVL_Station.Inputs.imageFresh`<br>`GVL_HMI.vijeo.modules[0]`<br>`GVL_HMI.hmiStatus.xVfdCommOk` |
| Krytyczne / ostrzeżenia | 2 × Numeric Display + Switch / Change Panel | Oblicz lokalnie liczbę skonfigurowanych zatrzaśniętych rekordów odpowiedniej klasy. Dotknięcie otwiera panel 3. | `GVL_HMI.vijeo.alarms.entries[i-1].configured`<br>`GVL_HMI.vijeo.alarms.entries[i-1].latched`<br>`GVL_HMI.vijeo.alarms.entries[i-1].critical` |
| Komunikat procesu | String Display (lokalny) | Gdy PLC oczekuje na odbiór, pokaż „Odbierz stos lub pojemnik”. Przy wymaganym uzgodnieniu pokaż komunikat i numer ekranu 301. | `GVL_HMI.hmiV2.station.waitingPickup`<br>`GVL_HMI.hmiV2.state.xRecoveryRequired` |

<a id="panel-2"></a>

### Panel 2 — ZLECENIE

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Pojemniki / Blistry | 2 × Switch / akcja zapisu wartości | Przy zamkniętym zleceniu i uzbrojonej sesji zapisz 1 dla Pojemników albo 2 dla Blistrów. Podświetl wybór z odczytu bufora. Zezwolenie orderOpen steruje przyciskiem Start zlecenia. | RW `GVL_HMI.hmiV2.edit.uiProgram` |
| Start zlecenia | Switch / transakcja | Zatwierdź wybraną produkcję i otwórz zlecenie. Ruch rozpoczyna fizyczny Start, FANUC uruchamia operator na robocie. | `GVL_HMI.hmiV2.cmd.orderOpen.xReq` |
| Koniec zlecenia | Switch / transakcja | PLC rozlicza rozpoczęte operacje, opróżnia stację i czeka na odbiór przy B304. Przy żądaniu z postoju opróżnianie wymaga fizycznego Start. | `GVL_HMI.hmiV2.cmd.orderEnd.xReq` |
| Zatwierdzona produkcja | 2 × Text Display | 0 brak, 10 Pojemniki, 20 Blistry. Oddziel ją od kandydata w edycji. Kod programu w actual ma wartości 1/2. | `GVL_HMI.hmiV2.state.uiProduction`<br>`GVL_HMI.hmiV2.actual.uiProgram` |
| Stan zlecenia | Text Display | 0 zamknięte, 10 otwarte, 20 kończenie, 30 opróżnianie, 90 wymagane uzgodnienie. | `GVL_HMI.hmiV2.state.uiOrderState` |
| Stan wykonania | Text Display + Lamp | 0 postój, 10 gotowy, 20 praca, 30 zatrzymywanie, 40 zatrzymany, 50 opróżnianie, 90 wymagane uzgodnienie. Osobna lampka pauzy. | `GVL_HMI.hmiV2.state.uiExecutionState`<br>`GVL_HMI.hmiV2.station.paused` |
| Operacje rozliczone / nierozliczone wtryski / transfer / krok opróżniania / odbiór | Lamp + Numeric Display + Lamp + Text Display + Lamp | Pokaż operacje rozliczone, liczbę nierozliczonych wtrysków, transfer w toku, etap opróżniania i oczekiwanie na odbiór. Stop pauzuje po bieżącej operacji. Zakończenie zlecenia potwierdza powrót stanu zlecenia do 0. | `GVL_HMI.hmiV2.state.xOpsSettled`<br>`GVL_HMI.hmiV2.state.uiUnsettled`<br>`GVL_Station.Transport.busy`<br>`GVL_HMI.hmiV2.station.drainStep`<br>`GVL_HMI.hmiV2.station.waitingPickup` |
| Stacja pusta | Lamp trójstanowa | Wymagaj aktualnych danych i uzgodnionego modelu. Pokaż „Pusta”, „Zajęta” lub „Stan nieznany”. | `GVL_HMI.hmiV2.station.emptyConfirmed`<br>`GVL_HMI.hmiV2.station.materialKnown`<br>`GVL_HMI.hmiV2.station.dataValid` |
| Detale na wtrysk | Numeric Display + Switch / Change Panel | Pokaż aktualną ilość w sztukach. Przycisk „Zmień ilość” otwiera 125. | `GVL_HMI.hmiV2.actual.uiBatchCount`<br>Przycisk → 125 |
| Fizyczny START / gotowość | Lamp + String Display | Pokaż zgodę i powód blokady. Uruchomienie i wznowienie automatu wykonuje operator przyciskiem fizycznym. | `GVL_HMI.hmiV2.state.xCanPhysicalStart`<br>`GVL_HMI.hmiV2.state.sStartBlockReason` |

Dla kroku opróżniania stosuj 0 bezczynny, 10 wybór operacji, 20 oczekiwanie na wykonanie, 40 pauza, 100 ukończone, 900 błąd. Wartość spoza słownika pokaż wraz z numerem.

<a id="panel-3"></a>

### Panel 3 — ALARMY

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Aktywne / Historia i Wszystkie / Krytyczne / Ostrzeżenia | 5 × Switch / akcja lokalna | Dwa przyciski wybierają widok Aktywne lub Historia. Trzy wybierają filtr Wszystkie, Krytyczne lub Ostrzeżenia. Historię sortuj od najnowszego zdarzenia. | Lokalnie w Vijeo |
| Lista alarmów | Tabela / 2 × Numeric Display + String Display + Lamp / rekord | Powiel wiersz dla i=1…64. Pokaż kod i stację jako liczby, opis jako STRING oraz lampki klasy, przyczyny, zatrzaśnięcia, ustąpienia i potwierdzenia. Uwzględnij zatrzaśnięte wpisy po ustąpieniu przyczyny. configured określa, czy klasa jest zatwierdzona. | `GVL_HMI.vijeo.alarms.entries[i-1].code`<br>`GVL_HMI.vijeo.alarms.entries[i-1].station`<br>`GVL_HMI.vijeo.alarms.entries[i-1].text`<br>`GVL_HMI.vijeo.alarms.entries[i-1].critical`<br>`GVL_HMI.vijeo.alarms.entries[i-1].active`<br>`GVL_HMI.vijeo.alarms.entries[i-1].latched`<br>`GVL_HMI.vijeo.alarms.entries[i-1].returned`<br>`GVL_HMI.vijeo.alarms.entries[i-1].acknowledged`<br>`GVL_HMI.vijeo.alarms.entries[i-1].configured` |
| Szczegóły · pola tekstowe i lampka | 2 × String Display + Lamp | Pokaż opis, czynność operatora i możliwość skasowania wybranego rekordu. | `GVL_HMI.vijeo.alarms.entries[i-1].text`<br>`GVL_HMI.vijeo.alarms.entries[i-1].actionText`<br>`GVL_HMI.vijeo.alarms.entries[i-1].canReset` |
| Konfiguracja / liczba zatrzaśniętych · lampka i odczyt | Lamp + 3 × Numeric Display | Pokaż gotowość konfiguracji i łączną liczbę zatrzaśniętych rekordów PLC. Dwa liczniki klas oblicz jak na HOME. Rekordy z configured=0 oznacz „Klasa niezatwierdzona”. | `GVL_HMI.vijeo.alarms.policyReady`<br>`GVL_HMI.vijeo.alarms.count`<br>`GVL_HMI.vijeo.alarms.entries[i-1].configured` |
| Historia alarmów | Dziennik lokalny / tabela | Rejestruj zmianę przyczyny i potwierdzenia, gdy dane są aktualne. Wyświetl czas panelu, ID, opis i rodzaj zdarzenia. Po powrocie danych odczytaj stan początkowy przed rejestracją kolejnych zmian. | `GVL_HMI.vijeo.alarms.entries[i-1].code`<br>`GVL_HMI.vijeo.alarms.entries[i-1].text`<br>`GVL_HMI.vijeo.alarms.entries[i-1].active`<br>`GVL_HMI.vijeo.alarms.entries[i-1].acknowledged` |
| Potwierdź alarmy | Switch / transakcja | Potwierdź w PLC. Lista odczytuje acknowledged. Lokalny ACK obiektu Alarm Summary nie zastępuje tej transakcji. | `GVL_HMI.hmiV2.cmd.alarmAckAll.xReq` |
| Reset alarmów | Switch / transakcja | Kasuj zatrzaśnięcia zgodnie z polityką PLC po ustąpieniu przyczyny. | `GVL_HMI.hmiV2.cmd.resetFaults.xReq` |

ID 1–11 obejmują ostrzeżenia siłowników ST.1–ST.4, ID 12–52 wymagają zatwierdzonej klasy GAP-12, 53–64 to rezerwa. Oczekiwanie na odbiór pozostaje statusem procesu. [Katalog ID alarmów](station-alarm-catalog.csv).

<a id="panel-101"></a>

### Panel 101 — ST.1 — STATUS · Załadunek

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Schemat P1 / P2 / P3 | 3 × Lamp | Pokaż zajętość po filtracji i ważność danej pozycji. B101=P1, B102=P2, B103=P3. | P1 `GVL_HMI.vijeo.occupied[0]`<br>`GVL_HMI.vijeo.positionsValid[0]`<br>P2 `GVL_HMI.vijeo.occupied[1]`<br>`GVL_HMI.vijeo.positionsValid[1]`<br>P3 `GVL_HMI.vijeo.occupied[2]`<br>`GVL_HMI.vijeo.positionsValid[2]` |
| Bariera załadunku · lampka i tekst | Lamp + Text Display | Przerwana / wolna przy ważnym odczycie. Osobna bariera wymaga potwierdzenia mapy GAP-01. Dla zatwierdzenia przejazdu całego stosu brak osobnego publicznego bitu. | `GVL_HMI.hmiIo.barrierBlocked`<br>`GVL_HMI.hmiIo.barrierValid` |
| V101/V102 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V101_HP`<br>`GVL_HMI.vijeo.value.ind_V101_WP` |
| V101/V102 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V102_HP`<br>`GVL_HMI.vijeo.value.ind_V102_WP` |
| V101/V102 · ruch, ostrzeżenie i tekst | 2 × Lamp + String Display | Grupa M2, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM2_Busy`<br>`GVL_HMI.vijeo.alarms.entries[1].active`<br>`GVL_HMI.hmiStatus.sM2DiagText` |
| V103/V104 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V103_HP`<br>`GVL_HMI.vijeo.value.ind_V103_WP` |
| V103/V104 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V104_HP`<br>`GVL_HMI.vijeo.value.ind_V104_WP` |
| V103/V104 · ruch, ostrzeżenie i tekst | 2 × Lamp + String Display | Grupa M3, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM3_Busy`<br>`GVL_HMI.vijeo.alarms.entries[2].active`<br>`GVL_HMI.hmiStatus.sM3DiagText` |
| V105/V106 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V105_HP`<br>`GVL_HMI.vijeo.value.ind_V105_WP` |
| V105/V106 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V106_HP`<br>`GVL_HMI.vijeo.value.ind_V106_WP` |
| V105/V106 · ruch, ostrzeżenie i tekst | 2 × Lamp + String Display | Grupa M4, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM4_Busy`<br>`GVL_HMI.vijeo.alarms.entries[3].active`<br>`GVL_HMI.hmiStatus.sM4DiagText` |
| V107/V108 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V107_HP`<br>`GVL_HMI.vijeo.value.ind_V107_WP` |
| V107/V108 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V108_HP`<br>`GVL_HMI.vijeo.value.ind_V108_WP` |
| V107/V108 · ruch, ostrzeżenie i tekst | 2 × Lamp + String Display | Grupa M1, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM1_Busy`<br>`GVL_HMI.vijeo.alarms.entries[0].active`<br>`GVL_HMI.hmiStatus.sM1DiagText` |
| V109/V110 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V109_HP`<br>`GVL_HMI.vijeo.value.ind_V109_WP` |
| V109/V110 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V110_HP`<br>`GVL_HMI.vijeo.value.ind_V110_WP` |
| V109/V110 · ruch, ostrzeżenie i tekst | 2 × Lamp + String Display | Grupa M5, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM5_Busy`<br>`GVL_HMI.vijeo.alarms.entries[4].active`<br>`GVL_HMI.hmiStatus.sM5DiagText` |
| Taśma · lampka komendy, kierunek, diagnostyka | Lamp + Text Display + String Display | Lampka wskazuje końcową komendę PLC. Kierunek (INT) wyświetl jako 1 naprzód, −1 wstecz, 0 postój. Przy wyłączonej komendzie pokaż brak komendy ruchu. Tekst obok grafiki. | `GVL_HMI.hmiStatus.xConvTopRunning`<br>`GVL_HMI.hmiStatus.iConvTopDirection`<br>`GVL_HMI.hmiStatus.sConvTopDiagText` |
| Krok przepływu / opis · liczba i tekst | Numeric Display + String Display | Pokaż kod kroku i opis diagnostyczny PLC. Zajętość P1 i stan sekwencji służą do oceny miejsca na nowy stos. | `GVL_HMI.hmiStatus.uiTopFlowState`<br>`GVL_HMI.hmiStatus.sTopFlowDiagText` |
| Przekazanie P3 / aktualny transfer · lampki i tekst | 2 × Lamp + 2 × Text Display | Pokaż gotowość i rezerwację pobrania P3 przy ważnym obszarze. Wyświetl właściciela i operację transportu według słownika panelu 301. | `GVL_HMI.vijeo.sourceArea.valid`<br>`GVL_HMI.vijeo.sourceArea.ready`<br>`GVL_HMI.vijeo.sourceArea.reserved`<br>`GVL_HMI.hmiV2.station.owner`<br>`GVL_HMI.hmiV2.station.action_` |

<a id="panel-111"></a>

### Panel 111 — ST.1 — MANUAL · Załadunek

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Transporter naprzód | Switch / Momentary ON | Trzymaj, aby żądać ruchu taśmy w dostępnym kierunku naprzód. | `GVL_HMI.vijeo.stationManual.positive[0]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[0]` |
| V101/V102 WORK / HOME | 2 × Switch / Momentary ON | Wspólny kierunek dla pary M2. Postój górnej taśmy i wolny obszar wymagane. | `GVL_HMI.vijeo.stationManual.positive[5]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[4]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[5]` |
| V103/V104 WORK / HOME | 2 × Switch / Momentary ON | Wspólny kierunek dla pary M3. Postój górnej taśmy i wolny obszar wymagane. | `GVL_HMI.vijeo.stationManual.positive[6]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[5]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[6]` |
| V105/V106 WORK / HOME | 2 × Switch / Momentary ON | Wspólny kierunek dla pary M4. Postój górnej taśmy i wolny obszar wymagane. | `GVL_HMI.vijeo.stationManual.positive[7]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[6]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[7]` |
| V107/V108 WORK / HOME | 2 × Switch / Momentary ON | Wspólny kierunek dla pary M1. Postój górnej taśmy i wolny obszar wymagane. | `GVL_HMI.vijeo.stationManual.positive[4]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[3]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[4]` |
| V109/V110 WORK / HOME | 2 × Switch / Momentary ON | Wspólny kierunek dla pary M5. Postój górnej taśmy i wolny obszar wymagane. | `GVL_HMI.vijeo.stationManual.positive[8]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[7]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[8]` |
| V101/V102 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V101_HP`<br>`GVL_HMI.vijeo.value.ind_V101_WP` |
| V101/V102 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V102_HP`<br>`GVL_HMI.vijeo.value.ind_V102_WP` |
| V101/V102 · ruch, ostrzeżenie i tekst | 2 × Lamp + String Display | Grupa M2, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM2_Busy`<br>`GVL_HMI.vijeo.alarms.entries[1].active`<br>`GVL_HMI.hmiStatus.sM2DiagText` |
| V103/V104 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V103_HP`<br>`GVL_HMI.vijeo.value.ind_V103_WP` |
| V103/V104 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V104_HP`<br>`GVL_HMI.vijeo.value.ind_V104_WP` |
| V103/V104 · ruch, ostrzeżenie i tekst | 2 × Lamp + String Display | Grupa M3, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM3_Busy`<br>`GVL_HMI.vijeo.alarms.entries[2].active`<br>`GVL_HMI.hmiStatus.sM3DiagText` |
| V105/V106 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V105_HP`<br>`GVL_HMI.vijeo.value.ind_V105_WP` |
| V105/V106 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V106_HP`<br>`GVL_HMI.vijeo.value.ind_V106_WP` |
| V105/V106 · ruch, ostrzeżenie i tekst | 2 × Lamp + String Display | Grupa M4, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM4_Busy`<br>`GVL_HMI.vijeo.alarms.entries[3].active`<br>`GVL_HMI.hmiStatus.sM4DiagText` |
| V107/V108 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V107_HP`<br>`GVL_HMI.vijeo.value.ind_V107_WP` |
| V107/V108 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V108_HP`<br>`GVL_HMI.vijeo.value.ind_V108_WP` |
| V107/V108 · ruch, ostrzeżenie i tekst | 2 × Lamp + String Display | Grupa M1, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM1_Busy`<br>`GVL_HMI.vijeo.alarms.entries[0].active`<br>`GVL_HMI.hmiStatus.sM1DiagText` |
| V109/V110 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V109_HP`<br>`GVL_HMI.vijeo.value.ind_V109_WP` |
| V109/V110 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V110_HP`<br>`GVL_HMI.vijeo.value.ind_V110_WP` |
| V109/V110 · ruch, ostrzeżenie i tekst | 2 × Lamp + String Display | Grupa M5, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM5_Busy`<br>`GVL_HMI.vijeo.alarms.entries[4].active`<br>`GVL_HMI.hmiStatus.sM5DiagText` |
| Taśma · lampka komendy, kierunek, diagnostyka | Lamp + Text Display + String Display | Lampka wskazuje końcową komendę PLC. Kierunek (INT) wyświetl jako 1 naprzód, −1 wstecz, 0 postój. Przy wyłączonej komendzie pokaż brak komendy ruchu. Tekst obok grafiki. | `GVL_HMI.hmiStatus.xConvTopRunning`<br>`GVL_HMI.hmiStatus.iConvTopDirection`<br>`GVL_HMI.hmiStatus.sConvTopDiagText` |
| Wymagane wznowienie | 5 × Lamp | W kolejności par V101/V102, V103/V104, V105/V106, V107/V108 i V109/V110 pokaż wymóg usunięcia przyczyny, resetu i świeżego polecenia. | `GVL_HMI.vijeo.localRestartRequired[1]`<br>`GVL_HMI.vijeo.localRestartRequired[2]`<br>`GVL_HMI.vijeo.localRestartRequired[3]`<br>`GVL_HMI.vijeo.localRestartRequired[0]`<br>`GVL_HMI.vijeo.localRestartRequired[4]` |
| Postój / rezerwacja / właściciel | 2 × Lamp + Text Display | Pokaż warunki blokujące żądanie. | `GVL_HMI.vijeo.beltsStopped[0]`<br>`GVL_HMI.vijeo.sourceArea.reserved`<br>`GVL_HMI.hmiV2.station.owner` |

<a id="panel-121"></a>

### Panel 121 — ST.1 — PARAMETRY · Załadunek

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Stabilizacja | Numeric Display / Input Mode + Numeric Display / odczyt | ms, filtr przepływu i potwierdzeń grup. | Edycja `GVL_HMI.vijeo.stationEdit[0].sensorStableMs`<br>Aktywna `GVL_HMI.vijeo.stationActual[0].sensorStableMs` |
| Zwłoka zatrzymania taśmy | Numeric Display / Input Mode + Numeric Display / odczyt | ms, oczekiwanie po wyłączeniu. | Edycja `GVL_HMI.vijeo.stationEdit[0].stopDelayMs`<br>Aktywna `GVL_HMI.vijeo.stationActual[0].stopDelayMs` |
| Timeout transferu | Numeric Display / Input Mode + Numeric Display / odczyt | ms, nadzór ruchu. | Edycja `GVL_HMI.vijeo.stationEdit[0].moveTimeoutMs`<br>Aktywna `GVL_HMI.vijeo.stationActual[0].moveTimeoutMs` |
| Timeout siłowników | Numeric Display / Input Mode + Numeric Display / odczyt | ms, wspólny próg pięciu grup. | Edycja `GVL_HMI.vijeo.stationEdit[0].actuatorTimeoutMs`<br>Aktywna `GVL_HMI.vijeo.stationActual[0].actuatorTimeoutMs` |
| Rewizja edycji / aktywna | 2 × Numeric Display | Gdy wartości się różnią, wczytaj zestaw ponownie. Oba pola zapisuje PLC. | `GVL_HMI.vijeo.stationEditRevision[0]`<br>`GVL_HMI.vijeo.stationRevision[0]` |
| Zestaw zatwierdzony | 2 × Lamp | Pokaż flagę zestawu aktywnego i zestawu wczytanego do edycji. | `GVL_HMI.vijeo.stationActual[0].verified`<br>`GVL_HMI.vijeo.stationEdit[0].verified` |
| Wczytaj / Anuluj | Switch / transakcja | Wczytaj aktualne dane i rewizję, porzuć niezapisane zmiany. | `GVL_HMI.hmiV2.cmd.station1ParamReload.xReq` |
| Zastosuj | Switch / transakcja | PLC sprawdza komplet parametrów. Pokaż wynik i odśwież zestaw po przyjęciu. | `GVL_HMI.hmiV2.cmd.station1ParamApply.xReq` |
| Reset stanu ST.1 | Switch / transakcja | Po potwierdzeniu zażądaj uzgodnienia stanu. | `GVL_HMI.hmiV2.cmd.station1ResetState.xReq` |

PLC stosuje jeden zestaw czasów ST.1. Indywidualne progi 5 par i osobny timeout oczekiwania na stopery pozostają poza edycją v4.

<a id="panel-102"></a>

### Panel 102 — ST.2 — STATUS · Winda

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| B201 | Lamp | Górny poziom. | `GVL_HMI.vijeo.value.ind_B201` |
| B202 | Lamp | Pośredni górny. | `GVL_HMI.vijeo.value.ind_B202` |
| B203 | Lamp | Pośredni dolny. | `GVL_HMI.vijeo.value.ind_B203` |
| B204 | Lamp | Dolny poziom. | `GVL_HMI.vijeo.value.ind_B204` |
| B205 · obecność na wysokości czujnika | Lamp | Pokaż jako osobny sygnał po potwierdzeniu podłączenia (GAP-02). | `GVL_HMI.vijeo.value.ind_B205` |
| P4 — ładunek na windzie | Lamp + Text Display | Stan zapamiętany przez model materiału. Przy braku uzgodnienia pokaż „Stan nieznany”. Odsłonięcie B205 podczas pozycjonowania nie oznacza utraty ładunku. | `GVL_HMI.vijeo.stationOccupied[3]`<br>`GVL_HMI.hmiV2.station.materialKnown`<br>`GVL_HMI.hmiV2.station.dataValid` |
| V201 | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V201_HP`<br>`GVL_HMI.vijeo.value.ind_V201_WP` |
| V201 · komenda i ostrzeżenie | 2 × Lamp | Komenda końcowa WORK i ostrzeżenie danego pozycjonera. Potwierdzenie pochodzi z osobnych krańcówek. | `GVL_HMI.vijeo.value.ctrl_V201`<br>`GVL_HMI.vijeo.alarms.entries[5].active` |
| V202 | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V202_HP`<br>`GVL_HMI.vijeo.value.ind_V202_WP` |
| V202 · komenda i ostrzeżenie | 2 × Lamp | Komenda końcowa WORK i ostrzeżenie danego pozycjonera. Potwierdzenie pochodzi z osobnych krańcówek. | `GVL_HMI.vijeo.value.ctrl_V202`<br>`GVL_HMI.vijeo.alarms.entries[6].active` |
| V203 | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V203_HP`<br>`GVL_HMI.vijeo.value.ind_V203_WP` |
| V203 · komenda i ostrzeżenie | 2 × Lamp | Komenda końcowa WORK i ostrzeżenie danego pozycjonera. Potwierdzenie pochodzi z osobnych krańcówek. | `GVL_HMI.vijeo.value.ctrl_V203`<br>`GVL_HMI.vijeo.alarms.entries[7].active` |
| Taśma · lampka komendy, kierunek, diagnostyka | Lamp + Text Display + String Display | Lampka wskazuje końcową komendę PLC. Kierunek INT 1 „IN”, −1 „OUT”, 0 „Postój”. Przy wyłączonej komendzie pokaż „Brak komendy ruchu”. Tekst PLC obok grafiki. | `GVL_HMI.hmiStatus.xConvElevRunning`<br>`GVL_HMI.hmiStatus.iConvElevDirection`<br>`GVL_HMI.hmiStatus.sConvElevDiagText` |
| Oś windy · pole Hz, stan i diagnostyka | Numeric Display + Text Display + 2 × Lamp + String Display | Częstotliwość rzeczywista, REAL w Hz (0,0). Wymagaj komunikacji ATV i ważnego pomiaru. Tekst stanu według słownika windy. | `GVL_HMI.hmiStatus.rElevFreq_Hz`<br>`GVL_HMI.hmiStatus.xVfdCommOk`<br>`GVL_Station.DriveFrequencyValid`<br>`GVL_HMI.hmiStatus.uiElevState`<br>`GVL_HMI.hmiStatus.xElevBusy`<br>`GVL_HMI.hmiStatus.xElevFault`<br>`GVL_HMI.hmiStatus.sElevDiagText` |
| V201/V202 — ruch grupy | Lamp | Ruch co najmniej jednego z dwóch pozycjonerów. | `GVL_HMI.hmiStatus.xM6_Busy` |
| Bieżący stos | Numeric Display / odczyt | Liczba blistrów w bieżącym kontekście. Pokaż w trybie Blistry. | `GVL_HMI.hmiStatus.uiTraysDone`<br>`GVL_HMI.hmiV2.state.uiProduction` |

V201 i V202 mają odrębne krańcówki i alarmy.

<a id="panel-112"></a>

### Panel 112 — ST.2 — MANUAL · Winda

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Oś windy — góra / dół | 2 × Switch / Momentary ON | Żądaj ruchu osi tylko przy trzymaniu. Kod ustawia ręczną prędkość wolną. | `GVL_HMI.vijeo.stationManual.positive[3]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[2]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[3]` |
| Taśma windy — IN / OUT | 2 × Switch / Momentary ON | Dodatni kierunek załącza IN, ujemny załącza OUT. Potwierdź etykiety kierunków na maszynie. | `GVL_HMI.vijeo.stationManual.positive[1]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[0]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[1]` |
| V201 lewy pozycjoner blistrów — WORK / HOME | 2 × Switch / Momentary ON | Żądaj osobno wybranego położenia. | `GVL_HMI.vijeo.stationManual.positive[9]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[8]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[9]` |
| V202 prawy pozycjoner blistrów — WORK / HOME | 2 × Switch / Momentary ON | Żądaj osobno wybranego położenia. | `GVL_HMI.vijeo.stationManual.positive[10]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[9]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[10]` |
| V203 pozycjoner pojemnika — WORK / HOME | 2 × Switch / Momentary ON | Żądaj osobno wybranego położenia. | `GVL_HMI.vijeo.stationManual.positive[11]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[10]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[11]` |
| B201 | Lamp | Górny poziom. | `GVL_HMI.vijeo.value.ind_B201` |
| B202 | Lamp | Pośredni górny. | `GVL_HMI.vijeo.value.ind_B202` |
| B203 | Lamp | Pośredni dolny. | `GVL_HMI.vijeo.value.ind_B203` |
| B204 | Lamp | Dolny poziom. | `GVL_HMI.vijeo.value.ind_B204` |
| B205 · obecność na wysokości czujnika | Lamp | Pokaż jako osobny sygnał po potwierdzeniu podłączenia (GAP-02). | `GVL_HMI.vijeo.value.ind_B205` |
| V201 | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V201_HP`<br>`GVL_HMI.vijeo.value.ind_V201_WP` |
| V202 | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V202_HP`<br>`GVL_HMI.vijeo.value.ind_V202_WP` |
| V203 | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V203_HP`<br>`GVL_HMI.vijeo.value.ind_V203_WP` |
| Oś windy · pole Hz, stan i diagnostyka | Numeric Display + Text Display + 2 × Lamp + String Display | Częstotliwość rzeczywista, REAL w Hz (0,0). Wymagaj komunikacji ATV i ważnego pomiaru. Tekst stanu według słownika windy. | `GVL_HMI.hmiStatus.rElevFreq_Hz`<br>`GVL_HMI.hmiStatus.xVfdCommOk`<br>`GVL_Station.DriveFrequencyValid`<br>`GVL_HMI.hmiStatus.uiElevState`<br>`GVL_HMI.hmiStatus.xElevBusy`<br>`GVL_HMI.hmiStatus.xElevFault`<br>`GVL_HMI.hmiStatus.sElevDiagText` |
| Blokady | Lamp | Postój taśmy, zajętość osi, rezerwacja obszaru windy. | `GVL_HMI.vijeo.beltsStopped[1]`<br>`GVL_HMI.hmiStatus.xElevBusy`<br>`GVL_HMI.vijeo.elevatorAreaReserved` |
| Wymagane wznowienie | 3 × Lamp | W kolejności V201, V202, V203 pokaż wymóg resetu i nowego naciśnięcia po usunięciu przyczyny. | `GVL_HMI.vijeo.localRestartRequired[5]`<br>`GVL_HMI.vijeo.localRestartRequired[7]`<br>`GVL_HMI.vijeo.localRestartRequired[6]` |

<a id="panel-122"></a>

### Panel 122 — ST.2 — PARAMETRY · Winda

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Stabilizacja | Numeric Display / Input Mode + Numeric Display / odczyt | ms, stabilizacja pozycji siłowników, postoju i przekazania. | Edycja `GVL_HMI.vijeo.stationEdit[1].sensorStableMs`<br>Aktywna `GVL_HMI.vijeo.stationActual[1].sensorStableMs` |
| Nadzór zatrzymania | Numeric Display / Input Mode + Numeric Display / odczyt | ms, zatrzymanie windy i zwłoka odwrócenia taśmy. | Edycja `GVL_HMI.vijeo.stationEdit[1].stopDelayMs`<br>Aktywna `GVL_HMI.vijeo.stationActual[1].stopDelayMs` |
| Nadzór przejazdu | Numeric Display / Input Mode + Numeric Display / odczyt | ms, przejazd, zwolnienie P4 i nadzór potwierdzenia P4. | Edycja `GVL_HMI.vijeo.stationEdit[1].moveTimeoutMs`<br>Aktywna `GVL_HMI.vijeo.stationActual[1].moveTimeoutMs` |
| Timeout pozycjonerów | Numeric Display / Input Mode + Numeric Display / odczyt | ms, wspólny próg V201/V202/V203. | Edycja `GVL_HMI.vijeo.stationEdit[1].actuatorTimeoutMs`<br>Aktywna `GVL_HMI.vijeo.stationActual[1].actuatorTimeoutMs` |
| Wolna prędkość | Numeric Display / Input Mode + Numeric Display / odczyt | Hz, wartość dodatnia. | Edycja `GVL_HMI.vijeo.elevatorSpeedEdit.slowHz`<br>Aktywna `GVL_HMI.vijeo.elevatorSpeedActual.slowHz` |
| Szybka prędkość | Numeric Display / Input Mode + Numeric Display / odczyt | Hz, od wolnej do zweryfikowanego maksimum napędu. | Edycja `GVL_HMI.vijeo.elevatorSpeedEdit.fastHz`<br>Aktywna `GVL_HMI.vijeo.elevatorSpeedActual.fastHz` |
| Rewizja edycji / aktywna | 2 × Numeric Display | Gdy wartości się różnią, wczytaj zestaw ponownie. Oba pola zapisuje PLC. | `GVL_HMI.vijeo.stationEditRevision[1]`<br>`GVL_HMI.vijeo.stationRevision[1]` |
| Zestaw zatwierdzony | 2 × Lamp | Pokaż flagę zestawu aktywnego i zestawu wczytanego do edycji. | `GVL_HMI.vijeo.stationActual[1].verified`<br>`GVL_HMI.vijeo.stationEdit[1].verified` |
| Wczytaj / Anuluj | Switch / transakcja | Wczytaj aktualne dane i rewizję, porzuć niezapisane zmiany. | `GVL_HMI.hmiV2.cmd.station2ParamReload.xReq` |
| Zastosuj | Switch / transakcja | PLC sprawdza komplet parametrów. Pokaż wynik i odśwież zestaw po przyjęciu. | `GVL_HMI.hmiV2.cmd.station2ParamApply.xReq` |
| Reset stanu ST.2 | Switch / transakcja | Po potwierdzeniu zażądaj uzgodnienia stanu. | `GVL_HMI.hmiV2.cmd.station2ResetState.xReq` |

Liczba blistrów w stosie oraz osobne progi Blistry/Pojemniki, próg zatrzymania w Hz i czasy dla każdego siłownika nie mają operatorskiego Apply w tym zestawie. W programie Blistry liczbę tacek w stosie ustala nastawa FANUC traysPerStack. Liczbę detali na wtrysk ustawia się na 125.

<a id="panel-103"></a>

### Panel 103 — ST.3 — STATUS · Rozładunek

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| B301 | Lamp | Strefa wyjazdu z windy wolna. | `GVL_HMI.vijeo.value.ind_B301` |
| B302 / P5 | Lamp | Obecność ładunku na pozycji P5. | `GVL_HMI.vijeo.value.ind_B302` |
| B303 / P6 | Lamp | Obecność ładunku na pozycji P6. | `GVL_HMI.vijeo.value.ind_B303` |
| B304 / P7 | Lamp | Obecność ładunku na pozycji P7. | `GVL_HMI.vijeo.value.ind_B304` |
| V301/V302 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V301_HP`<br>`GVL_HMI.vijeo.value.ind_V301_WP` |
| V301/V302 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V302_HP`<br>`GVL_HMI.vijeo.value.ind_V302_WP` |
| V301/V302 · komenda i ostrzeżenie | 3 × Lamp | Oddziel końcową komendę pary od krańcówek. Osobny publiczny bit ruchu pary pozostaje otwarty. | `GVL_HMI.vijeo.unloadCoils[0].home`<br>`GVL_HMI.vijeo.unloadCoils[0].work`<br>`GVL_HMI.vijeo.alarms.entries[8].active` |
| V303/V304 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V303_HP`<br>`GVL_HMI.vijeo.value.ind_V303_WP` |
| V303/V304 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V304_HP`<br>`GVL_HMI.vijeo.value.ind_V304_WP` |
| V303/V304 · komenda i ostrzeżenie | 3 × Lamp | Oddziel końcową komendę pary od krańcówek. Osobny publiczny bit ruchu pary pozostaje otwarty. | `GVL_HMI.vijeo.unloadCoils[1].home`<br>`GVL_HMI.vijeo.unloadCoils[1].work`<br>`GVL_HMI.vijeo.alarms.entries[9].active` |
| Taśma · lampka komendy, kierunek, diagnostyka | Lamp + Text Display + String Display | Lampka wskazuje końcową komendę PLC. Kierunek (INT) wyświetl jako 1 naprzód, −1 wstecz, 0 postój. Przy wyłączonej komendzie pokaż brak komendy ruchu. Tekst obok grafiki. | `GVL_HMI.hmiStatus.xConvBottomRunning`<br>`GVL_HMI.hmiStatus.iConvBottomDirection`<br>`GVL_HMI.hmiStatus.sConvBottomDiagText` |
| Wydanie pojedyncze | 3 × Lamp | Gotowość do naciśnięcia przycisku lokalnego, wydawanie przez właściciela LOCAL (30), następnie „Odbierz stos lub pojemnik”. Kolejne wydanie po odbiorze przy B304. | Gotowość `GVL_HMI.hmiV2.station.localReady`<br>Wydawanie `GVL_HMI.hmiV2.station.owner`<br>`GVL_Station.Transport.busy`<br>Odbiór `GVL_HMI.hmiV2.station.waitingPickup` |
| Krok rozładunku / przyczyna / opróżnianie | Text Display + String Display + Lamp + Text Display | Wyświetl stan rozładunku według słownika, opis PLC i oddzielny krok pełnego opróżniania z panelu 2. Koniec zlecenia obsługuje ekran 2. | `GVL_HMI.hmiStatus.uiBottomState`<br>`GVL_HMI.hmiStatus.sBottomDiagText`<br>`GVL_HMI.hmiV2.station.draining`<br>`GVL_HMI.hmiV2.station.drainStep` |

<a id="panel-113"></a>

### Panel 113 — ST.3 — MANUAL · Rozładunek

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Taśma rozładunku — na zewnątrz / do środka | 2 × Switch / Momentary ON | Kierunek wstecz udostępnij po potwierdzeniu napędu i okablowania. | `GVL_HMI.vijeo.stationManual.positive[2]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[1]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[2]` |
| V301/V302 — WORK / HOME | 2 × Switch / Momentary ON | Wspólne żądanie pierwszej pary przy zatrzymanej taśmie. | `GVL_HMI.vijeo.stationManual.positive[12]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[11]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[12]` |
| V303/V304 — WORK / HOME | 2 × Switch / Momentary ON | Wspólne żądanie drugiej pary przy zatrzymanej taśmie. | `GVL_HMI.vijeo.stationManual.positive[13]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[12]`<br>`GVL_HMI.vijeo.stationManual.holdCounter[13]` |
| B301 | Lamp | Strefa wyjazdu z windy wolna. | `GVL_HMI.vijeo.value.ind_B301` |
| B302 / P5 | Lamp | Obecność ładunku na pozycji P5. | `GVL_HMI.vijeo.value.ind_B302` |
| B303 / P6 | Lamp | Obecność ładunku na pozycji P6. | `GVL_HMI.vijeo.value.ind_B303` |
| B304 / P7 | Lamp | Obecność ładunku na pozycji P7. | `GVL_HMI.vijeo.value.ind_B304` |
| V301/V302 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V301_HP`<br>`GVL_HMI.vijeo.value.ind_V301_WP` |
| V301/V302 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V302_HP`<br>`GVL_HMI.vijeo.value.ind_V302_WP` |
| V303/V304 lewy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V303_HP`<br>`GVL_HMI.vijeo.value.ind_V303_WP` |
| V303/V304 prawy | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V304_HP`<br>`GVL_HMI.vijeo.value.ind_V304_WP` |
| Taśma · lampka komendy, kierunek, diagnostyka | Lamp + Text Display + String Display | Lampka wskazuje końcową komendę PLC. Kierunek (INT) wyświetl jako 1 naprzód, −1 wstecz, 0 postój. Przy wyłączonej komendzie pokaż brak komendy ruchu. Tekst obok grafiki. | `GVL_HMI.hmiStatus.xConvBottomRunning`<br>`GVL_HMI.hmiStatus.iConvBottomDirection`<br>`GVL_HMI.hmiStatus.sConvBottomDiagText` |
| Wymagane wznowienie | 2 × Lamp | W kolejności V301/V302 i V303/V304 pokaż wymóg resetu i nowego naciśnięcia po usunięciu przyczyny. | `GVL_HMI.vijeo.localRestartRequired[8]`<br>`GVL_HMI.vijeo.localRestartRequired[9]` |
| Blokada i właściciel transferu | Lamp + 2 × Text Display | Pokaż zatrzymanie taśmy, właściciela i operację. Pojedyncze wydanie inicjuje przycisk fizyczny. | `GVL_HMI.vijeo.beltsStopped[2]`<br>`GVL_HMI.hmiV2.station.owner`<br>`GVL_HMI.hmiV2.station.action_` |

<a id="panel-123"></a>

### Panel 123 — ST.3 — PARAMETRY · Rozładunek

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Stabilizacja czujników i stoperów | Numeric Display / Input Mode + Numeric Display / odczyt | ms, także przy odbiorze. | Edycja `GVL_HMI.vijeo.stationEdit[2].sensorStableMs`<br>Aktywna `GVL_HMI.vijeo.stationActual[2].sensorStableMs` |
| Zwłoka zatrzymania / zmiany kierunku | Numeric Display / Input Mode + Numeric Display / odczyt | ms, wspólna nastawa. | Edycja `GVL_HMI.vijeo.stationEdit[2].stopDelayMs`<br>Aktywna `GVL_HMI.vijeo.stationActual[2].stopDelayMs` |
| Timeout kroku transportu | Numeric Display / Input Mode + Numeric Display / odczyt | ms, nadzór aktywnego kroku. | Edycja `GVL_HMI.vijeo.stationEdit[2].moveTimeoutMs`<br>Aktywna `GVL_HMI.vijeo.stationActual[2].moveTimeoutMs` |
| Timeout stoperów | Numeric Display / Input Mode + Numeric Display / odczyt | ms, wspólny dla obu par. | Edycja `GVL_HMI.vijeo.stationEdit[2].actuatorTimeoutMs`<br>Aktywna `GVL_HMI.vijeo.stationActual[2].actuatorTimeoutMs` |
| Rewizja edycji / aktywna | 2 × Numeric Display | Gdy wartości się różnią, wczytaj zestaw ponownie. Oba pola zapisuje PLC. | `GVL_HMI.vijeo.stationEditRevision[2]`<br>`GVL_HMI.vijeo.stationRevision[2]` |
| Zestaw zatwierdzony | 2 × Lamp | Pokaż flagę zestawu aktywnego i zestawu wczytanego do edycji. | `GVL_HMI.vijeo.stationActual[2].verified`<br>`GVL_HMI.vijeo.stationEdit[2].verified` |
| Wczytaj / Anuluj | Switch / transakcja | Wczytaj aktualne dane i rewizję, porzuć niezapisane zmiany. | `GVL_HMI.hmiV2.cmd.station3ParamReload.xReq` |
| Zastosuj | Switch / transakcja | PLC sprawdza komplet parametrów. Pokaż wynik i odśwież zestaw po przyjęciu. | `GVL_HMI.hmiV2.cmd.station3ParamApply.xReq` |
| Reset stanu ST.3 | Switch / transakcja | Po potwierdzeniu zażądaj uzgodnienia stanu. | `GVL_HMI.hmiV2.cmd.station3ResetState.xReq` |

Oczekiwanie na zabranie stosu pokazuj jako komunikat procesu. Reset nie rozlicza wydania ani ładunku między czujnikami.

<a id="panel-104"></a>

### Panel 104 — ST.4 — STATUS · Magazyn przekładek

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| V401 | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V401_HP`<br>`GVL_HMI.vijeo.value.ind_V401_WP` |
| V402 | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V402_HP`<br>`GVL_HMI.vijeo.value.ind_V402_WP` |
| Obie osłony otwarte / zamknięte | 2 × Lamp | HOME obu oznacza otwarte, WORK obu zamknięte. Obok schematu pokaż wynik potwierdzony po stabilizacji. | `GVL_HMI.hmiStatus.xStorageRobotSideOpen`<br>`GVL_HMI.hmiStatus.xStorageRobotSideClosed` |
| Strona robota / strona operatora · pozwolenia i dostęp | 5 × Lamp | Po dwie lampki na stronę. Osobno pokaż żądanie operatora. | `GVL_HMI.hmiStatus.xStorageRobotPermission`<br>`GVL_HMI.hmiStatus.xStorageRobotAccessActive`<br>`GVL_HMI.hmiStatus.xStorageOperatorPermission`<br>`GVL_HMI.hmiStatus.xStorageOperatorAccessActive`<br>`GVL_HMI.hmiStatus.xStorageOperatorRequest` |
| B401 | Lamp | Niski poziom przekładek. | `GVL_HMI.vijeo.value.ind_B401` |
| B402 | Lamp | Magazyn pusty. | `GVL_HMI.vijeo.value.ind_B402` |
| Stan, ruch automatyczny i usterka · tekst i lampki | Text Display + 2 × Lamp + String Display | Stan magazynu według słownika, ruch, ostrzeżenie osłon i tekst diagnostyczny PLC. | `GVL_HMI.hmiStatus.uiStorageState`<br>`GVL_HMI.hmiStatus.xStorageBusy`<br>`GVL_HMI.vijeo.alarms.entries[10].active`<br>`GVL_HMI.hmiStatus.sStorageDiagText` |

<a id="panel-114"></a>

### Panel 114 — ST.4 — MANUAL · Osłony magazynu

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| V401 | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V401_HP`<br>`GVL_HMI.vijeo.value.ind_V401_WP` |
| V402 | 2 × Lamp | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V402_HP`<br>`GVL_HMI.vijeo.value.ind_V402_WP` |
| Obie osłony otwarte / zamknięte | 2 × Lamp | HOME obu oznacza otwarte, WORK obu zamknięte. Obok schematu pokaż wynik potwierdzony po stabilizacji. | `GVL_HMI.hmiStatus.xStorageRobotSideOpen`<br>`GVL_HMI.hmiStatus.xStorageRobotSideClosed` |
| Strona robota / strona operatora · pozwolenia i dostęp | 5 × Lamp | Po dwie lampki na stronę. Osobno pokaż żądanie operatora. | `GVL_HMI.hmiStatus.xStorageRobotPermission`<br>`GVL_HMI.hmiStatus.xStorageRobotAccessActive`<br>`GVL_HMI.hmiStatus.xStorageOperatorPermission`<br>`GVL_HMI.hmiStatus.xStorageOperatorAccessActive`<br>`GVL_HMI.hmiStatus.xStorageOperatorRequest` |
| Stan, ruch automatyczny i usterka · tekst i lampki | Text Display + 2 × Lamp + String Display | Stan magazynu według słownika, ruch, ostrzeżenie osłon i tekst diagnostyczny PLC. | `GVL_HMI.hmiStatus.uiStorageState`<br>`GVL_HMI.hmiStatus.xStorageBusy`<br>`GVL_HMI.vijeo.alarms.entries[10].active`<br>`GVL_HMI.hmiStatus.sStorageDiagText` |
| Wyjścia osłon | 4 × Lamp | Końcowe komendy HOME/WORK obu osłon, wyłącznie podgląd. | `GVL_Robot.storageOut.Q_V401Home`<br>`GVL_Robot.storageOut.Q_V401Work`<br>`GVL_Robot.storageOut.Q_V402Home`<br>`GVL_Robot.storageOut.Q_V402Work` |

Wspólne otwieranie i zamykanie V401/V402 wymaga wspólnej komendy rozstrzyganej po stronie PLC. Panel 114 ma obecnie podgląd krańcówek, pozwoleń i wyjść. Wymóg wspólnego ruchu pozostaje otwarty.

<a id="panel-124"></a>

### Panel 124 — ST.4 — PARAMETRY · Magazyn przekładek

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Stabilizacja obu osłon | Numeric Display / Input Mode + Numeric Display / odczyt | ms, czas potwierdzenia położenia. | Edycja `GVL_HMI.vijeo.storageEdit.sensorStableMs`<br>Aktywna `GVL_HMI.vijeo.storageActual.sensorStableMs` |
| Timeout ruchu obu osłon | Numeric Display / Input Mode + Numeric Display / odczyt | ms, jeden próg, osobny nadzór ruchu każdej osłony. | Edycja `GVL_HMI.vijeo.storageEdit.actuatorTimeoutMs`<br>Aktywna `GVL_HMI.vijeo.storageActual.actuatorTimeoutMs` |
| Rewizja edycji / aktywna | 2 × Numeric Display | Gdy wartości się różnią, wczytaj zestaw ponownie. Oba pola zapisuje PLC. | `GVL_HMI.vijeo.stationEditRevision[3]`<br>`GVL_HMI.vijeo.stationRevision[3]` |
| Zestaw zatwierdzony | 2 × Lamp | Pokaż flagę zestawu aktywnego i zestawu wczytanego do edycji. | `GVL_HMI.vijeo.storageActual.verified`<br>`GVL_HMI.vijeo.storageEdit.verified` |
| Wczytaj / Anuluj | Switch / transakcja | Wczytaj aktualne dane i rewizję, porzuć niezapisane zmiany. | `GVL_HMI.hmiV2.cmd.station4ParamReload.xReq` |
| Zastosuj | Switch / transakcja | PLC sprawdza komplet parametrów. Pokaż wynik i odśwież zestaw po przyjęciu. | `GVL_HMI.hmiV2.cmd.station4ParamApply.xReq` |
| Reset stanu ST.4 | Switch / transakcja | Po potwierdzeniu zażądaj uzgodnienia stanu. | `GVL_HMI.hmiV2.cmd.station4ResetState.xReq` |

Wczytaj pobiera pełny zestaw ST.4 do bufora PLC. Przy Zastosuj sterownik zachowuje wczytane `stopDelayMs` i `moveTimeoutMs`. Te dwie wartości mają mieścić się w limitach i są konfigurowane przy uruchomieniu PLC. Wykonawca magazynu używa dwóch nastaw z tabeli.

<a id="panel-105"></a>

### Panel 105 — ST.5 — STATUS · Robot i chwytak

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Robot · lampki Auto / gotowy / pracuje / błąd / HOME | 7 × Lamp | Stan zgłaszany przez FANUC. Ważność sesji i diagnostyki pokaż oddzielnie. Program uruchamia operator z robota. | `GVL_HMI.hmiStatus.xRobotAutoMode`<br>`GVL_HMI.hmiStatus.xRobotReady`<br>`GVL_HMI.hmiStatus.xRobotRunning`<br>`GVL_HMI.hmiStatus.xRobotFault`<br>`GVL_HMI.hmiStatus.xRobotHome`<br>`GVL_HMI.hmiV2.state.xRobotDataValid`<br>`GVL_Robot.Sts.diagnosticValid` |
| Program rzeczywisty / zgodność · tekst i lampka | Text Display + Lamp | Odczytaj kod z FANUC i porównaj lokalnie z programem zlecenia przy ważnych danych. 0 brak/nieznany, 1 Pojemniki, 2 Blistry. | `GVL_Robot.Rx.production_program`<br>`GVL_HMI.hmiV2.actual.uiProgram` |
| Krok / faza / oczekiwanie / kod błędu | 3 × Numeric Display + Text Display | Pokaż krok, fazę i błąd jako liczby. Kod oczekiwania przypisz do tekstu: 0 brak, 20 partia, 30 forma, 40 chwytak, 50 próżnia lub przedmuch, 60 obszar lub nośnik, 70 ACK, 80 operator lub Start. | Krok `GVL_HMI.hmiV2.state.uiRobotStep`<br>Faza `GVL_HMI.hmiV2.state.uiRobotPhase`<br>Oczekiwanie `GVL_HMI.hmiV2.state.uiRobotWaitCode`<br>Błąd `GVL_HMI.hmiV2.state.uiRobotFaultCode` |
| Kończenie operacji · lampki i licznik | Lamp + Numeric Display | Pokaż zatrzymywanie, liczbę nierozliczonych wtrysków i potwierdzenie rozliczenia operacji. | `GVL_Robot.Sts.order.stopping`<br>`GVL_HMI.hmiV2.state.uiUnsettled`<br>`GVL_HMI.hmiV2.state.xOpsSettled` |
| V501–V505 | 5 × Lamp + Numeric Display / wiersz | i=1 pneumatyczna oś 7 (V501), i=2…5 siłowniki V502…V505. Kolumny HOME, WORK, ruch, ważność, usterka i kod. | `GVL_HMI.vijeo.cylinders[i-1].atHome`<br>`GVL_HMI.vijeo.cylinders[i-1].atWork`<br>`GVL_HMI.vijeo.cylinders[i-1].busy`<br>`GVL_HMI.vijeo.cylinders[i-1].valid`<br>`GVL_HMI.vijeo.cylinders[i-1].fault`<br>`GVL_HMI.vijeo.cylinders[i-1].faultCode` |
| Próżnia V509–V513 | 5 × Lamp + Numeric Display / wiersz | i=1…5 w kolejności V509…V513. Kolumny komenda ssania, osiągnięta próżnia, ważność, komenda przedmuchu, alarm i kod. Przy braku zatwierdzonego sprzężenia pokaż „Brak danych”. | `GVL_HMI.vijeo.vacuum[i-1].hold`<br>`GVL_HMI.vijeo.vacuum[i-1].ok`<br>`GVL_HMI.vijeo.vacuum[i-1].valid`<br>`GVL_HMI.vijeo.vacuum[i-1].blow`<br>`GVL_HMI.vijeo.vacuum[i-1].fault`<br>`GVL_HMI.vijeo.vacuum[i-1].faultCode` |
| Dobre / próbki / odrzuty · liczniki detali | 3 × Numeric Display | Trzy odczyty UDINT w sztukach. Pokaż osobno dobre detale, próbki i odrzuty według rozliczonych zdarzeń. | `GVL_HMI.hmiV2.state.udiGood`<br>`GVL_HMI.hmiV2.state.udiSamples`<br>`GVL_HMI.hmiV2.state.udiRejects` |
| Blistry / ukończone jednostki · liczniki | 3 × Numeric Display | W Blistrach pokaż blistry bieżącego stosu i ukończone stosy, w Pojemnikach ukończone pojemniki. Widoczność zależy od potwierdzonego rodzaju produkcji. | `GVL_HMI.hmiStatus.uiTraysDone`<br>`GVL_HMI.hmiStatus.uiStacksDone`<br>`GVL_HMI.hmiStatus.uiBoxesDone`<br>`GVL_HMI.hmiV2.state.uiProduction` |
| Zażądaj próbek | Switch / transakcja | Zgłoś pobranie próbek. ACK dotyczy żądania w PLC, zakończenie rozlicza zdarzenie robota. | `GVL_HMI.hmiV2.cmd.samples.xReq` |
| Wtryskarka / EUROMAP | Switch / Change Panel | Otwórz panel 201. | Lokalnie w Vijeo |

Opisy kroków i kodów według programu. [Blistry](../ROBOT/TRAY/README.md) · [Pojemniki](../ROBOT/BOX/README.md).

<a id="panel-115"></a>

### Panel 115 — ST.5 — MANUAL · Chwytak

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Zezwolenie ręczne | Text Display + 3 × Lamp + akcja zapisu sesji | Pokaż Manual, wyłączoną współpracę, potwierdzone HOME i przekazanie chwytaka. Zapisz aktualne ID sesji gałęzi ręcznej przed wydaniem żądania. Pozwolenia i potwierdzenia poszczególnych obwodów są poniżej. | `GVL_HMI.hmiV2.state.uiMode`<br>`GVL_HMI.hmiV2.state.xWorkWithRobot`<br>`GVL_HMI.hmiV2.state.xRobotHomeValid`<br>`GVL_Robot.Plant.manualGripperHandover`<br>`GVL_HMI.vijeo.manual.udiSessionId` |
| V501 oś 7 — HOME / WORK | 2 × Switch / Momentary ON | Dwa przyciski, kanał 1. Na nacisk zgłoś jeden kierunek, odświeżaj licznik podczas trzymania, na zwolnienie wycofaj żądanie. PLC może zachować przyjęty cel. | `GVL_HMI.vijeo.manual.cylHome[0]`<br>`GVL_HMI.vijeo.manual.cylWork[0]`<br>`GVL_HMI.vijeo.manual.holdCounter[0]` |
| V502 siłownik 1 — HOME / WORK | 2 × Switch / Momentary ON | Dwa przyciski, wiersz 2. Na nacisk zgłoś jeden kierunek, odświeżaj licznik podczas trzymania, na zwolnienie wycofaj żądanie. PLC może zachować przyjęty cel. | `GVL_HMI.vijeo.manual.cylHome[1]`<br>`GVL_HMI.vijeo.manual.cylWork[1]`<br>`GVL_HMI.vijeo.manual.holdCounter[1]` |
| V503 siłownik 2 — HOME / WORK | 2 × Switch / Momentary ON | Dwa przyciski, wiersz 3. Na nacisk zgłoś jeden kierunek, odświeżaj licznik podczas trzymania, na zwolnienie wycofaj żądanie. PLC może zachować przyjęty cel. | `GVL_HMI.vijeo.manual.cylHome[2]`<br>`GVL_HMI.vijeo.manual.cylWork[2]`<br>`GVL_HMI.vijeo.manual.holdCounter[2]` |
| V504 siłownik 3 — HOME / WORK | 2 × Switch / Momentary ON | Dwa przyciski, wiersz 4. Na nacisk zgłoś jeden kierunek, odświeżaj licznik podczas trzymania, na zwolnienie wycofaj żądanie. PLC może zachować przyjęty cel. | `GVL_HMI.vijeo.manual.cylHome[3]`<br>`GVL_HMI.vijeo.manual.cylWork[3]`<br>`GVL_HMI.vijeo.manual.holdCounter[3]` |
| V505 siłownik 4 — HOME / WORK | 2 × Switch / Momentary ON | Dwa przyciski, wiersz 5. Na nacisk zgłoś jeden kierunek, odświeżaj licznik podczas trzymania, na zwolnienie wycofaj żądanie. PLC może zachować przyjęty cel. | `GVL_HMI.vijeo.manual.cylHome[4]`<br>`GVL_HMI.vijeo.manual.cylWork[4]`<br>`GVL_HMI.vijeo.manual.holdCounter[4]` |
| V509 obwód 1 — Załącz / Wyłącz / Przedmuch | 3 × Switch / Momentary ON (skrypt) | Załącz: vacHold=1, vacValid=1. Wyłącz: vacHold=0, vacValid=1. Przedmuch: vacHold=0, vacValid=1, blowReq=1. Podczas trzymania zwiększaj licznik. | Cel `GVL_HMI.vijeo.manual.vacHold[0]`<br>Żądanie `GVL_HMI.vijeo.manual.vacValid[0]`<br>Przedmuch `GVL_HMI.vijeo.manual.blowReq[0]`<br>Licznik `GVL_HMI.vijeo.manual.holdCounter[5]` |
| V510 obwód 2 — Załącz / Wyłącz / Przedmuch | 3 × Switch / Momentary ON (skrypt) | Załącz: vacHold=1, vacValid=1. Wyłącz: vacHold=0, vacValid=1. Przedmuch: vacHold=0, vacValid=1, blowReq=1. Podczas trzymania zwiększaj licznik. | Cel `GVL_HMI.vijeo.manual.vacHold[1]`<br>Żądanie `GVL_HMI.vijeo.manual.vacValid[1]`<br>Przedmuch `GVL_HMI.vijeo.manual.blowReq[1]`<br>Licznik `GVL_HMI.vijeo.manual.holdCounter[6]` |
| V511 obwód 3 — Załącz / Wyłącz / Przedmuch | 3 × Switch / Momentary ON (skrypt) | Załącz: vacHold=1, vacValid=1. Wyłącz: vacHold=0, vacValid=1. Przedmuch: vacHold=0, vacValid=1, blowReq=1. Podczas trzymania zwiększaj licznik. | Cel `GVL_HMI.vijeo.manual.vacHold[2]`<br>Żądanie `GVL_HMI.vijeo.manual.vacValid[2]`<br>Przedmuch `GVL_HMI.vijeo.manual.blowReq[2]`<br>Licznik `GVL_HMI.vijeo.manual.holdCounter[7]` |
| V512 obwód 4 — Załącz / Wyłącz / Przedmuch | 3 × Switch / Momentary ON (skrypt) | Załącz: vacHold=1, vacValid=1. Wyłącz: vacHold=0, vacValid=1. Przedmuch: vacHold=0, vacValid=1, blowReq=1. Podczas trzymania zwiększaj licznik. | Cel `GVL_HMI.vijeo.manual.vacHold[3]`<br>Żądanie `GVL_HMI.vijeo.manual.vacValid[3]`<br>Przedmuch `GVL_HMI.vijeo.manual.blowReq[3]`<br>Licznik `GVL_HMI.vijeo.manual.holdCounter[8]` |
| V513 obwód 5 — Załącz / Wyłącz / Przedmuch | 3 × Switch / Momentary ON (skrypt) | Załącz: vacHold=1, vacValid=1. Wyłącz: vacHold=0, vacValid=1. Przedmuch: vacHold=0, vacValid=1, blowReq=1. Podczas trzymania zwiększaj licznik. | Cel `GVL_HMI.vijeo.manual.vacHold[4]`<br>Żądanie `GVL_HMI.vijeo.manual.vacValid[4]`<br>Przedmuch `GVL_HMI.vijeo.manual.blowReq[4]`<br>Licznik `GVL_HMI.vijeo.manual.holdCounter[9]` |
| V501–V505 | 5 × Lamp + Numeric Display / wiersz | i=1 pneumatyczna oś 7 (V501), i=2…5 siłowniki V502…V505. Kolumny HOME, WORK, ruch, ważność, usterka i kod. | `GVL_HMI.vijeo.cylinders[i-1].atHome`<br>`GVL_HMI.vijeo.cylinders[i-1].atWork`<br>`GVL_HMI.vijeo.cylinders[i-1].busy`<br>`GVL_HMI.vijeo.cylinders[i-1].valid`<br>`GVL_HMI.vijeo.cylinders[i-1].fault`<br>`GVL_HMI.vijeo.cylinders[i-1].faultCode` |
| Próżnia V509–V513 | 5 × Lamp + Numeric Display / wiersz | i=1…5 w kolejności V509…V513. Kolumny komenda ssania, osiągnięta próżnia, ważność, komenda przedmuchu, alarm i kod. Przy braku zatwierdzonego sprzężenia pokaż „Brak danych”. | `GVL_HMI.vijeo.vacuum[i-1].hold`<br>`GVL_HMI.vijeo.vacuum[i-1].ok`<br>`GVL_HMI.vijeo.vacuum[i-1].valid`<br>`GVL_HMI.vijeo.vacuum[i-1].blow`<br>`GVL_HMI.vijeo.vacuum[i-1].fault`<br>`GVL_HMI.vijeo.vacuum[i-1].faultCode` |
| Przyjęcie pozycji / potwierdzenia | 2 × Lamp + Numeric Display / siłownik | Dla i=1…5 pokaż przyjęcie celu obok potwierdzeń urządzenia. Kod reason opisuje odmowę. | `GVL_HMI.vijeo.cylinders[i-1].acceptedHome`<br>`GVL_HMI.vijeo.cylinders[i-1].acceptedWork`<br>`GVL_HMI.vijeo.cylinders[i-1].reason` |
| Przyjęcie próżni / wynik przedmuchu · lampki i kod | 2 × Lamp + 2 × Numeric Display / obwód | Wyświetl wynik obok potwierdzeń obwodu. Jedno żądanie przedmuchu na nacisk. PLC kończy przyjęty impuls. Po blowAck odczytaj blowResult (1 wykonano, 2 odmowa, 3 błąd) i powróć do neutralnego żądania przed następnym. | `GVL_HMI.vijeo.vacuum[i-1].accepted`<br>`GVL_HMI.vijeo.vacuum[i-1].reason`<br>`GVL_HMI.vijeo.vacuum[i-1].blowAck`<br>`GVL_HMI.vijeo.vacuum[i-1].blowResult` |
| Pozwolenia · wskaźniki dla obwodu | 4 × Lamp / obwód | Pokaż zezwolenie na ssanie, zwolnienie i przedmuch. Wstrzymaj aktywację przy braku potwierdzenia pneumatyki GAP-03/08. | `GVL_HMI.vijeo.vacuumInput[i-1].onAllowed`<br>`GVL_HMI.vijeo.vacuumInput[i-1].offAllowed`<br>`GVL_HMI.vijeo.vacuumInput[i-1].blowAllowed`<br>`GVL_HMI.vijeo.vacuumInput[i-1].blowConfigured` |

Cylindry i próżnia mają osobny protokół od ST.1–ST.4. PLC wymaga neutralnego wejścia i zmiany licznika danego urządzenia przy żądaniu. Przy Załącz lub Wyłącz wymagaj blowReq=0. Przy zwolnieniu wycofaj bity cylHome/cylWork, vacValid i blowReq przypisane do gestu. Wyjście z karty lub zanik łącza kończy nadawanie. Przedmuch wymaga zgody na zwolnienie i przedmuch oraz zweryfikowanego kanału. Najpierw zapisz cel vacHold=0, następnie vacValid=1. Ustaw blowReq=1 jako ostatni bit, po zapisaniu celu i ważności, ponieważ PLC zapamiętuje oba pola przy przyjęciu przedmuchu. Do następnego gestu wymagaj zaniku blowAck. Zanik nacisku na „Załącz” sam nie wydaje polecenia zwolnienia detalu.

<a id="panel-125"></a>

### Panel 125 — ST.5 — PARAMETRY · Detale na wtrysk

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Detale na wtrysk | Numeric Display / Input Mode + Numeric Display / odczyt | UINT w sztukach, wartość dodatnia. Kandydat i przyjęta wartość obok siebie. Ilość jest niezależna od liczby obwodów próżni. | Edycja `GVL_HMI.hmiV2.edit.uiBatchCount`<br>Aktywna `GVL_HMI.hmiV2.actual.uiBatchCount` |
| Zastosuj ilość | Switch / transakcja | Wymaga zamkniętego zlecenia, potwierdzonego postoju stacji i chwytaka, rozliczonych operacji oraz braku recovery. Rozpoczęte partie zachowują przypisaną ilość. | `GVL_HMI.hmiV2.cmd.station5ParamApply.xReq` |
| Wczytaj / Anuluj | Switch / transakcja | Wczytaj aktywną ilość. PLC przywraca także aktywny program w buforze wyboru na ekranie 2. | `GVL_HMI.hmiV2.cmd.station5ParamReload.xReq` |
| Reset stanu ST.5 | Switch / transakcja | Użyj lokalnego potwierdzenia i procedury uzgodnienia. | `GVL_HMI.hmiV2.cmd.station5ResetState.xReq` |
| Czasy chwytaka | 5 × Numeric Display | Odczyty UDINT w ms kolejno stabilizacja, ruch, osiągnięcie próżni, czas przedmuchu i potwierdzenie zwolnienia. Wyłącznie odczyt. | `GVL_HMI.vijeo.gripperStableMs`<br>`GVL_HMI.vijeo.gripperMotionTimeoutMs`<br>`GVL_HMI.vijeo.gripperVacuumTimeoutMs`<br>`GVL_HMI.vijeo.gripperBlowMs`<br>`GVL_HMI.vijeo.gripperReleaseTimeoutMs` |

<a id="panel-201"></a>

### Panel 201 — WTRYSKARKA / EUROMAP

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| Podgląd / Manual | 2 × Switch / akcja lokalna | Zachowaj uiActivePanel=201. Przy przejściu z Manual na Podgląd zwolnij wszystkie żądania i zatrzymaj ich liczniki. | Lokalnie w Vijeo |
| KF101 | Lamp | Odrzut. | `GVL_HMI.vijeo.value.ind_KF101` |
| KF102 | Lamp | Forma zamknięta. | `GVL_HMI.vijeo.value.ind_KF102` |
| KF103 | Lamp | Forma otwarta. | `GVL_HMI.vijeo.value.ind_KF103` |
| KF104 | Lamp | Forma w pozycji pośredniej. | `GVL_HMI.vijeo.value.ind_KF104` |
| KF105 | Lamp | Współpraca z robotem. | `GVL_HMI.vijeo.value.ind_KF105` |
| KF106 | Lamp | Wyrzutnik z tyłu. | `GVL_HMI.vijeo.value.ind_KF106` |
| KF107 | Lamp | Wyrzutnik z przodu. | `GVL_HMI.vijeo.value.ind_KF107` |
| KF108 | Lamp | Rdzeń 1 w pozycji 1. | `GVL_HMI.vijeo.value.ind_KF108` |
| KF109 | Lamp | Rdzeń 1 w pozycji 2. | `GVL_HMI.vijeo.value.ind_KF109` |
| KF110 | Lamp | Rdzeń 2 w pozycji 1. | `GVL_HMI.vijeo.value.ind_KF110` |
| KF111 | Lamp | Rdzeń 2 w pozycji 2. | `GVL_HMI.vijeo.value.ind_KF111` |
| KF202 · Zezwól na zamknięcie formy | Switch / Momentary ON + 2 × Lamp | Przytrzymaj, aby zgłosić zezwolenie w Manual. Dwie lampki odczytują niezależnie żądanie FANUC oraz logiczne pozwolenie PLC. | Żądanie `GVL_HMI.vijeo.immManual.positive[0]`<br>Licznik `GVL_HMI.vijeo.immManual.holdCounter[0]`<br>FANUC `GVL_Robot.Rx.imm_req_mouldClose`<br>PLC `GVL_Robot.Sts.imm.mouldClose` |
| KF203 · Zezwól na pełne otwarcie formy | Switch / Momentary ON + 2 × Lamp | Przytrzymaj, aby zgłosić zezwolenie w Manual. Dwie lampki odczytują niezależnie żądanie FANUC oraz logiczne pozwolenie PLC. | Żądanie `GVL_HMI.vijeo.immManual.positive[1]`<br>Licznik `GVL_HMI.vijeo.immManual.holdCounter[1]`<br>FANUC `GVL_Robot.Rx.imm_req_mouldFullOpen`<br>PLC `GVL_Robot.Sts.imm.mouldFullOpen` |
| KF205 · Zezwól na wyrzutnik w tył | Switch / Momentary ON + 2 × Lamp | Przytrzymaj, aby zgłosić zezwolenie w Manual. Dwie lampki odczytują niezależnie żądanie FANUC oraz logiczne pozwolenie PLC. | Żądanie `GVL_HMI.vijeo.immManual.positive[2]`<br>Licznik `GVL_HMI.vijeo.immManual.holdCounter[2]`<br>FANUC `GVL_Robot.Rx.imm_req_ejectorBack`<br>PLC `GVL_Robot.Sts.imm.ejectorBack` |
| KF206 · Zezwól na wyrzutnik w przód | Switch / Momentary ON + 2 × Lamp | Przytrzymaj, aby zgłosić zezwolenie w Manual. Dwie lampki odczytują niezależnie żądanie FANUC oraz logiczne pozwolenie PLC. | Żądanie `GVL_HMI.vijeo.immManual.positive[3]`<br>Licznik `GVL_HMI.vijeo.immManual.holdCounter[3]`<br>FANUC `GVL_Robot.Rx.imm_req_ejectorForward`<br>PLC `GVL_Robot.Sts.imm.ejectorForward` |
| Warunki trybu ręcznego | Text Display + 3 × Lamp + 2 × Numeric Display | Manual, aktualne HOME, współpraca wyłączona, postój i brak nierozliczonych wtrysków. Zezwolenia i ich blokady ocenia PLC. Pokaż ważność oraz kod przyczyny. | `GVL_HMI.hmiV2.state.uiMode`<br>`GVL_HMI.hmiV2.state.xRobotHomeValid`<br>`GVL_HMI.hmiV2.state.xWorkWithRobot`<br>`GVL_HMI.hmiV2.state.uiUnsettled`<br>`GVL_Robot.Sts.imm.valid`<br>`GVL_Robot.Sts.imm.reason` |
| Współpraca / cykl · wskaźniki | 4 × Lamp + Numeric Display | Wskaż opcję współpracy (KF204 logicznie), pozwolenie nowego cyklu, znany stan wtrysku, ostatni identyfikator i rozliczenie. Żądanie i końcowe zezwolenie są odrębne od wejść potwierdzenia Krauss. | `GVL_Robot.Sts.imm.withRobot`<br>`GVL_Robot.Sts.imm.newCyclePermit`<br>`GVL_Robot.Tx.imm_cycleKnown`<br>`GVL_Robot.Tx.imm_cycleId`<br>`GVL_Robot.Tx.imm_settled` |

Cztery przyciski Manual udostępnij po potwierdzeniu konfiguracji elektrycznej i blokad Krauss (GAP-05). PLC odrzuca przeciwstawne żądania i wymaga pełnego otwarcia formy dla zezwoleń wyrzutnika. Wskaźniki logiczne pokazują decyzję PLC, a lampki KF101–KF111 pokazują wejścia Krauss. Status urządzeń bezpieczeństwa można pokazać tylko z zatwierdzonych danych diagnostycznych.

<a id="panel-301"></a>

### Panel 301 — DIAGNOSTYKA

| Element | Typ i tryb | Działanie | Zmienna lub akcja |
|---|---|---|---|
| PLC/HMI | 6 × Numeric Display + String Display | Wersja kontraktu (4), stan sesji (0 nieuzbrojona, 20 uzbrojona), ID sesji i tekst PLC. Pokaż również oba liczniki heartbeat i aktywny panel ze wspólnego szablonu. | `GVL_HMI.hmiV2.link.uiContractVersion`<br>`GVL_HMI.hmiV2.link.uiSessionState`<br>`GVL_HMI.hmiV2.link.udiSessionId`<br>`GVL_HMI.hmiV2.link.sDiag`<br>`GVL_HMI.hmiV2.link.uiPlcHeartbeat`<br>`GVL_HMI.hmiV2.link.uiHmiHeartbeat`<br>`GVL_HMI.hmiV2.link.uiActivePanel` |
| FANUC · łącze, obraz, sesja i diagnostyka | 4 × Lamp + 2 × Numeric Display + String Display | Pokaż stan skanera, świeżość obrazu, aktywną sesję, ważność diagnostyki i tekst/kod. Wire FANUC v2 ma odrębną wersję od HMI v4. | `GVL_Robot.ScannerHealthy`<br>`GVL_Robot.ImageFresh`<br>`GVL_Robot.Sts.session`<br>`GVL_Robot.Sts.diagnosticValid`<br>`GVL_Robot.Sts.diag.code`<br>`GVL_Robot.Sts.diag.text`<br>`GVL_Robot.Rx.link_version` |
| Festo AP i ATV320 · wskaźniki | 5 × Lamp + Numeric Display | Bramka, świeżość danych, ważność całej stacji i przyczyna. Dla napędu komunikacja i ważność pomiaru Hz osobno. | `GVL_Station.Inputs.gatewayHealthy`<br>`GVL_Station.Inputs.imageFresh`<br>`GVL_HMI.hmiIo.dataValid`<br>`GVL_Station.Io.reason`<br>`GVL_HMI.hmiStatus.xVfdCommOk`<br>`GVL_Station.DriveFrequencyValid` |
| Moduły Festo | Lamp + String Display | Utwórz 12 wierszy według tabeli „Moduły Festo” poniżej. Lampka wskazuje ważność kanału, String Display odczytuje opis powiązanego rekordu. | [Indeksy modułów i rekordów](#moduly-festo) |
| I/O · przewijana tabela i lokalny wybór grupy | Tabela / Text + Lamp i Switch / akcja lokalna | Utwórz wiersze z wykazu I/O poniżej. Każdy zawiera stałą etykietę sygnału, kierunek i lampkę z ważnością. Przycisk wyboru grupy przełącza widok lokalny. | `GVL_HMI.vijeo.value.N`<br>`GVL_HMI.vijeo.valid.N`<br>[Wykaz aliasów](#wykaz-io) |
| Uzgodnienie stacji · model i pola statusu | 3 × Lamp + Numeric Display oraz po 2 × Lamp / pozycję | Pokaż wymagane recovery, nieuzgodniony materiał, potwierdzenie pustej stacji oraz nierozliczone wtryski. Rozwiń podgląd P1–P7 z modelu i pozycji czujników. | `GVL_HMI.hmiV2.state.xRecoveryRequired`<br>`GVL_HMI.hmiV2.station.materialKnown`<br>`GVL_HMI.hmiV2.station.emptyConfirmed`<br>`GVL_HMI.hmiV2.state.uiUnsettled`<br>`GVL_HMI.vijeo.stationOccupied[i-1]`<br>`GVL_HMI.vijeo.occupied[i-1]`<br>`GVL_HMI.vijeo.positionsValid[i-1]`<br>`GVL_HMI.hmiV2.station.dataValid` |
| Transport · operacja i przyczyna | 2 × Text Display + 3 × Numeric Display | Właściciel 0 brak, 10 produkcja, 20 opróżnianie, 30 lokalne wydanie, 40 Manual. Operacja 0 brak, 10 winda góra, 20 winda dół, 30 podanie, 40 rozładunek, 50 przesunięcie, 60 wydanie. Pokaż ID i kod blokady. | `GVL_HMI.hmiV2.station.owner`<br>`GVL_HMI.hmiV2.station.action_`<br>`GVL_Station.Transport.operationId`<br>`GVL_Station.Transport.reason`<br>`GVL_HMI.hmiV2.station.reason` |
| Potwierdź uzgodniony stan | Switch / transakcja | Po uzgodnieniu rzeczywistych ładunków, robota i wtrysków potwierdź proponowany kontekst. Pokaż wynik i aktualny stan recovery. | `GVL_HMI.hmiV2.cmd.recoveryConfirm.xReq` |
| Nowy pusty kontekst · serwis | Switch / transakcja | Użyj osobnego okna potwierdzenia. Transakcję inicjalizacji stosuj po potwierdzeniu pustej stacji, pustego chwytaka i rozliczenia wtrysków. | `GVL_HMI.hmiV2.cmd.newEmptyContext.xReq` |

Dla statusu modelu wymagaj `GVL_HMI.hmiV2.station.dataValid` i `materialKnown`. Pozycje z czujników mają swoją ważność `positionsValid[i-1]`. Dla i=1…7 utwórz lampkę pozycji modelu i lampkę czujnika. Statusy recovery, znanego materiału i pustej stacji pokaż jako osobne lampki. Liczbę nierozliczonych wtrysków pokaż jako Numeric Display.

<a id="moduly-festo"></a>

#### Moduły Festo

| Etykieta | Lamp (ważność) | String Display (opis alarmu) |
|---|---|---|
| BAT100 — Bramka Festo AP | `GVL_HMI.vijeo.modules[0]` | `GVL_HMI.vijeo.alarms.entries[40].text` |
| BAT101 — Wejścia ST.4 | `GVL_HMI.vijeo.modules[1]` | `GVL_HMI.vijeo.alarms.entries[41].text` |
| BAT200 — Wyspa zaworowa ST.1 i ST.3 | `GVL_HMI.vijeo.modules[2]` | `GVL_HMI.vijeo.alarms.entries[42].text` |
| BAT201 — Wejścia ST.1 nr 1 | `GVL_HMI.vijeo.modules[3]` | `GVL_HMI.vijeo.alarms.entries[43].text` |
| BAT202 — Wejścia ST.1 nr 2 | `GVL_HMI.vijeo.modules[4]` | `GVL_HMI.vijeo.alarms.entries[44].text` |
| BAT203 — Wejścia ST.1 nr 3 | `GVL_HMI.vijeo.modules[5]` | `GVL_HMI.vijeo.alarms.entries[45].text` |
| BAT204 — Wejścia ST.3 nr 1 | `GVL_HMI.vijeo.modules[6]` | `GVL_HMI.vijeo.alarms.entries[46].text` |
| BAT205 — Wejścia ST.3 nr 2 | `GVL_HMI.vijeo.modules[7]` | `GVL_HMI.vijeo.alarms.entries[47].text` |
| BAT300 — Wyspa zaworowa ST.2 | `GVL_HMI.vijeo.modules[8]` | `GVL_HMI.vijeo.alarms.entries[48].text` |
| BAT301 — Wejścia ST.2 | `GVL_HMI.vijeo.modules[9]` | `GVL_HMI.vijeo.alarms.entries[49].text` |
| BAT400 — Wyspa zaworowa ST.5 | `GVL_HMI.vijeo.modules[10]` | `GVL_HMI.vijeo.alarms.entries[50].text` |
| BAT401 — Wejścia ST.5 | `GVL_HMI.vijeo.modules[11]` | `GVL_HMI.vijeo.alarms.entries[51].text` |

<a id="wykaz-io"></a>

#### Wykaz I/O panelu 301

Dla każdego wiersza utwórz etykietę Text oraz trójstanową Lamp. W pole wartości wstaw `GVL_HMI.vijeo.value.N`, a w pole ważności `GVL_HMI.vijeo.valid.N`. Zastąp N dokładną wartością z trzeciej kolumny. Wspólna komenda pary ma jeden wiersz. Użyj 118 wierszy z poniższych tabel. Rygiel i drzwi są podglądem diagnostycznym. Właściwe działanie funkcji bezpieczeństwa ocenia dedykowany układ.

##### ST.1 — załadunek

| Etykieta | Wskazanie | Alias N |
|---|---|---|
| V101/V102 — komenda WORK | Komenda PLC | `ctrl_V101_V102` |
| V101 — krańcówka HOME | Wejście | `ind_V101_HP` |
| V101 — krańcówka WORK | Wejście | `ind_V101_WP` |
| V102 — krańcówka HOME | Wejście | `ind_V102_HP` |
| V102 — krańcówka WORK | Wejście | `ind_V102_WP` |
| V103/V104 — komenda WORK | Komenda PLC | `ctrl_V103_V104` |
| V103 — krańcówka HOME | Wejście | `ind_V103_HP` |
| V103 — krańcówka WORK | Wejście | `ind_V103_WP` |
| V104 — krańcówka HOME | Wejście | `ind_V104_HP` |
| V104 — krańcówka WORK | Wejście | `ind_V104_WP` |
| V105/V106 — komenda WORK | Komenda PLC | `ctrl_V105_V106` |
| V105 — krańcówka HOME | Wejście | `ind_V105_HP` |
| V105 — krańcówka WORK | Wejście | `ind_V105_WP` |
| V106 — krańcówka HOME | Wejście | `ind_V106_HP` |
| V106 — krańcówka WORK | Wejście | `ind_V106_WP` |
| V107/V108 — komenda WORK | Komenda PLC | `ctrl_V107_V108` |
| V107 — krańcówka HOME | Wejście | `ind_V107_HP` |
| V107 — krańcówka WORK | Wejście | `ind_V107_WP` |
| V108 — krańcówka HOME | Wejście | `ind_V108_HP` |
| V108 — krańcówka WORK | Wejście | `ind_V108_WP` |
| V109/V110 — komenda WORK | Komenda PLC | `ctrl_V109_V110` |
| V109 — krańcówka HOME | Wejście | `ind_V109_HP` |
| V109 — krańcówka WORK | Wejście | `ind_V109_WP` |
| V110 — krańcówka HOME | Wejście | `ind_V110_HP` |
| V110 — krańcówka WORK | Wejście | `ind_V110_WP` |
| B101 — obecność P1 | Wejście | `ind_B101` |
| B102 — obecność P2 | Wejście | `ind_B102` |
| B103 — obecność P3 | Wejście | `ind_B103` |

##### ST.2 — winda

| Etykieta | Wskazanie | Alias N |
|---|---|---|
| V201 — komenda WORK | Komenda PLC | `ctrl_V201` |
| V201 — krańcówka HOME | Wejście | `ind_V201_HP` |
| V201 — krańcówka WORK | Wejście | `ind_V201_WP` |
| V202 — komenda WORK | Komenda PLC | `ctrl_V202` |
| V202 — krańcówka HOME | Wejście | `ind_V202_HP` |
| V202 — krańcówka WORK | Wejście | `ind_V202_WP` |
| V203 — komenda WORK | Komenda PLC | `ctrl_V203` |
| V203 — krańcówka HOME | Wejście | `ind_V203_HP` |
| V203 — krańcówka WORK | Wejście | `ind_V203_WP` |
| B201 — winda na poziomie górnym | Wejście | `ind_B201` |
| B202 — winda na poziomie pośrednim górnym | Wejście | `ind_B202` |
| B203 — winda na poziomie pośrednim dolnym | Wejście | `ind_B203` |
| B204 — winda na poziomie dolnym | Wejście | `ind_B204` |
| B205 — obecność na wysokości czujnika | Wejście | `ind_B205` |

##### ST.3 — rozładunek

| Etykieta | Wskazanie | Alias N |
|---|---|---|
| V301/V302 — komenda WORK | Komenda PLC | `ctrl_V301_V302` |
| V301 — krańcówka HOME | Wejście | `ind_V301_HP` |
| V301 — krańcówka WORK | Wejście | `ind_V301_WP` |
| V302 — krańcówka HOME | Wejście | `ind_V302_HP` |
| V302 — krańcówka WORK | Wejście | `ind_V302_WP` |
| V303/V304 — komenda WORK | Komenda PLC | `ctrl_V303_V304` |
| V303 — krańcówka HOME | Wejście | `ind_V303_HP` |
| V303 — krańcówka WORK | Wejście | `ind_V303_WP` |
| V304 — krańcówka HOME | Wejście | `ind_V304_HP` |
| V304 — krańcówka WORK | Wejście | `ind_V304_WP` |
| B301 — wolny wyjazd z windy | Wejście | `ind_B301` |
| B302 — obecność P5 | Wejście | `ind_B302` |
| B303 — obecność P6 | Wejście | `ind_B303` |
| B304 — obecność P7 | Wejście | `ind_B304` |

##### ST.4 — magazyn przekładek

| Etykieta | Wskazanie | Alias N |
|---|---|---|
| V401 — komenda WORK | Komenda PLC | `ctrl_V401` |
| V401 — krańcówka HOME | Wejście | `ind_V401_HP` |
| V401 — krańcówka WORK | Wejście | `ind_V401_WP` |
| V402 — komenda WORK | Komenda PLC | `ctrl_V402` |
| V402 — krańcówka HOME | Wejście | `ind_V402_HP` |
| V402 — krańcówka WORK | Wejście | `ind_V402_WP` |
| B401 — niski poziom przekładek | Wejście | `ind_B401` |
| B402 — brak przekładek | Wejście | `ind_B402` |

##### ST.5 — robot i chwytak

| Etykieta | Wskazanie | Alias N |
|---|---|---|
| V501 — komenda WORK | Komenda PLC | `ctrl_V501` |
| V501 — krańcówka HOME | Wejście | `ind_V501_HP` |
| V501 — krańcówka WORK | Wejście | `ind_V501_WP` |
| V502 — komenda WORK | Komenda PLC | `ctrl_V502` |
| V502 — krańcówka HOME | Wejście | `ind_V502_HP` |
| V502 — krańcówka WORK | Wejście | `ind_V502_WP` |
| V503 — komenda WORK | Komenda PLC | `ctrl_V503` |
| V503 — krańcówka HOME | Wejście | `ind_V503_HP` |
| V503 — krańcówka WORK | Wejście | `ind_V503_WP` |
| V504 — komenda WORK | Komenda PLC | `ctrl_V504` |
| V504 — krańcówka HOME | Wejście | `ind_V504_HP` |
| V504 — krańcówka WORK | Wejście | `ind_V504_WP` |
| V505 — komenda WORK | Komenda PLC | `ctrl_V505` |
| V505 — krańcówka HOME | Wejście | `ind_V505_HP` |
| V505 — krańcówka WORK | Wejście | `ind_V505_WP` |
| V509 — komenda ssania | Komenda PLC | `ctrl_V509` |
| V510 — komenda ssania | Komenda PLC | `ctrl_V510` |
| V511 — komenda ssania | Komenda PLC | `ctrl_V511` |
| V512 — komenda ssania | Komenda PLC | `ctrl_V512` |
| V513 — komenda ssania | Komenda PLC | `ctrl_V513` |

##### EUROMAP — wejścia Krauss

| Etykieta | Wskazanie | Alias N |
|---|---|---|
| KF101 — Odrzut | Wejście | `ind_KF101` |
| KF102 — Forma zamknięta | Wejście | `ind_KF102` |
| KF103 — Forma otwarta | Wejście | `ind_KF103` |
| KF104 — Forma w pozycji pośredniej | Wejście | `ind_KF104` |
| KF105 — Współpraca z robotem | Wejście | `ind_KF105` |
| KF106 — Wyrzutnik z tyłu | Wejście | `ind_KF106` |
| KF107 — Wyrzutnik z przodu | Wejście | `ind_KF107` |
| KF108 — Rdzeń 1 w pozycji 1 | Wejście | `ind_KF108` |
| KF109 — Rdzeń 1 w pozycji 2 | Wejście | `ind_KF109` |
| KF110 — Rdzeń 2 w pozycji 1 | Wejście | `ind_KF110` |
| KF111 — Rdzeń 2 w pozycji 2 | Wejście | `ind_KF111` |

##### Przyciski, transportery i andon

| Etykieta | Wskazanie | Alias N |
|---|---|---|
| S1 — przycisk osłon magazynu | Wejście | `ind_S1` |
| S5 — fizyczny Start / wznowienie | Wejście | `ind_S5` |
| S6 — potwierdzenie załadunku | Wejście | `ind_S6` |
| S7 — żądanie pojedynczego wydania ST.3 | Wejście | `ind_S7` |
| LCK1-X2:7 — przycisk drzwi celi | Wejście | `ind_LCK1_X2_7` |
| LCK1-X5:1 — drzwi celi zamknięte | Wejście | `ind_LCK1_X5_1` |
| LCK1-X5:4 — drzwi celi zaryglowane | Wejście | `ind_LCK1_X5_4` |
| KF9/KF10 — pozwolenie otwarcia magazynu od strony robota | Wejście | `ind_KF9_KF10` |
| KF11/KF12 — pozwolenie otwarcia magazynu od strony operatora | Wejście | `ind_KF11_KF12` |
| H1 — podświetlenie przycisku osłon magazynu | Komenda PLC | `ctrl_H1` |
| H5 — gotowość na fizyczny Start | Komenda PLC | `ctrl_H5` |
| P7 — gotowość pojedynczego wydania ST.3 | Komenda PLC | `ctrl_P7` |
| KF30 — taśma załadunku | Komenda PLC | `ctrl_KF30` |
| KF31 — taśma rozładunku, wyjazd | Komenda PLC | `ctrl_KF31` |
| KF33 — taśma windy OUT | Komenda PLC | `ctrl_KF33` |
| KF34 — taśma windy IN | Komenda PLC | `ctrl_KF34` |
| KF35 — żądanie biegu napędu windy | Komenda PLC | `ctrl_KF35` |
| KEC12-Q0 — rygiel magazynu od strony robota | Komenda PLC | `ctrl_KEC12_Q0` |
| KEC12-Q1 — rygiel magazynu od strony operatora | Komenda PLC | `ctrl_KEC12_Q1` |
| PFA10-G — andon zielony | Komenda PLC | `ctrl_PFA10_G` |
| PFA10-O — andon pomarańczowy | Komenda PLC | `ctrl_PFA10_O` |
| PFA10-R — andon czerwony | Komenda PLC | `ctrl_PFA10_R` |
| PFA10-5 — sygnał dźwiękowy andon | Komenda PLC | `ctrl_PFA10_5` |

Przy niezatwierdzonym module, czujniku lub mapie pokazuj „Brak danych”. Dotyczy to m.in. bariery ST.1 (GAP-01), B205 (GAP-02), dystrybucji I/O (GAP-03) i wejść IMM (GAP-05). Przypisanie fizycznego Stop pozostaje otwarte. Oznaczenia urządzeń pochodzą z arkusza. [Arkusz I/O](<sources/IO map.xlsx>).

## Słowniki stanów urządzeń

Użyj numerów z PLC do wyświetlania poniższych etykiet. Dla nieznanej wartości pokaż „Kod” i numer.

| Pole stanu | Etykiety według kodu |
|---|---|
| `GVL_HMI.hmiStatus.uiTopFlowState` | 0 inicjalizacja, 10 postój, 20 zatrzymywanie taśmy, 30 ustawianie stoperów, 40 przejazd, 50 zwłoka po zatrzymaniu, 55 cofanie M5, 57 oczekiwanie na M5, 60 blokowanie pozycji docelowej, 70 oczekiwanie na blokadę, 80 zakończono, 90 zwalnianie P1, 100 oczekiwanie na blokadę P1, 900 błąd |
| `GVL_HMI.hmiStatus.uiElevState` | 0 wyłączona, 10 postój, 20 ręcznie w górę, 21 ręcznie w dół, 30 automatycznie w górę, 31 automatycznie w dół, 40 zatrzymywanie, 900 błąd |
| `GVL_HMI.hmiStatus.uiBottomState` | 0 inicjalizacja, 10 postój, 20 sprawdzanie warunków, 30 przejazd, 40 oczekiwanie na zatrzymanie, 50 zakończono, 60 pauza opróżniania, 70 uzgadnianie rozładunku, 80 oczekiwanie na odbiór, 90 ustawianie stoperów, 900 błąd |
| `GVL_HMI.hmiStatus.uiStorageState` | 0 wyłączony, 10 postój, 20 oczekiwanie na zgodę dla robota, 30 otwieranie dla robota, 40 otwarty dla robota, 50 zamykanie po dostępie robota, 60 zamykanie przed dostępem operatora, 70 oczekiwanie na zgodę dla operatora, 80 odryglowany dla operatora, 90 oczekiwanie na zaryglowanie po dostępie operatora, 900 błąd |

## Przygotowanie projektu i import symboli

1. Ustal pełny model jednostki bazowej HMI, firmware, wersję Vijeo Designer z Service Packiem i rozdzielczość. Schemat podaje wyświetlacz HMIDT351. W projekcie Krauss wybierz zgodny driver do symbolicznej komunikacji z Machine Expert (GAP-07). Nazwę węzła i adresy ustaw po potwierdzeniu konfiguracji urządzeń. [Topologia PLC i HMI](interfaces.md).
2. W Machine Expert włącz **Symbol Configuration**. Zaznacz `GVL_HMI` oraz wymagane 40 odczytów z `GVL_Robot` i `GVL_Station`. Ustaw dostęp R i RW według listy. [Wykaz symboli i uprawnień](hmi-vijeo-symbols.txt).
3. Wykonaj **Generate Code**, wyeksportuj symbole i zaimportuj je w Vijeo. W istniejącym projekcie odśwież wiązania obiektów, skryptów oraz alarmów według tabel ekranów. Usuń osierocone tagi z konfiguracji eksportu i Vijeo. [Schneider Electric — eksport i import symboli dla Machine Expert V1.2 / Vijeo 6.2 SP9.1](https://www.se.com/us/en/faqs/FA411965/).
4. Sprawdź typy BOOL, UINT, UDINT, INT, REAL, STRING oraz indeksy tablic. Do próby STRING wybierz `GVL_HMI.hmiStatus.sElevDiagText`. Sprawdź polskie znaki, zawijanie, układ klawiatury i czytelność na docelowej rozdzielczości. [Schneider Electric — długość zmiennej tekstowej Vijeo](https://www.se.com/ar/es/faqs/FA283025/).

<a id="proby-odbiorcze"></a>

## Próby odbiorcze HMI

Zapisz wynik osobno dla symulacji, połączenia z PLC i stanowiska. Poniższe próby czekają na wykonanie w Vijeo.

| Test | Próba | Wynik wymagany |
|---|---|---|
| HMI-01 / AT-01 | Zablokowane żądanie Auto/produkcji/zlecenia; następnie poprawne | Potwierdzony tryb nie zmienia się od samego kliknięcia; widoczny powód odmowy; Start zlecenia bez ruchu |
| HMI-02 / AT-09/14 | Trzymany jog: puść, zmień stronę, wyłącz sieć, zrestartuj panel, zatrzymaj skrypt hold; zasymuluj utratę zdarzenia zwolnienia osi windy przy odświeżaniu innego licznika | PLC unieważnia jog w zatwierdzonym czasie; brak wznowienia ze starego TRUE. Nie następuje przypadkowe zwolnienie detalu/podciśnienia |
| HMI-03 | Podwójny klik, opóźniony ACK, utrata połączenia w każdej fazie T, restart PLC | Jeden skutek; odpowiedź dotyczy właściwych ID klucza/żądania/sesji; cache starego wyniku i opóźniony telegram poprzedniej sesji nie są przyjmowane; brak odtworzenia komendy po reconnect |
| HMI-04 | Edycja bez Apply, Apply poza zakresem, przepełnienie, wolna>szybka, czas wpisany w niewłaściwej jednostce | Brak częściowego zastosowania; walidacja w PLC; czytelny wynik i odczyt actual |
| HMI-05 / AT-13 | Restart panelu/PLC podczas edycji i po Apply | Brak nadpisania zerami; retencja według ustaleń; wymagany Reload przy nieaktualnej rewizji |
| HMI-06 / AT-11/12 | Alarm krytyczny, ostrzeżenie siłownika, oczekiwanie na odbiór, ACK, Reset | Poprawne kolory/andon, odrębne active/ack/returned; ostrzeżenie bez globalnego Stop; Reset bez ruchu |
| HMI-07 / AT-09 | Utrata danych przy HOME/WORK=TRUE i przy FALSE | Wyraźny brak danych, zablokowane komendy; brak traktowania ostatniej wartości jak aktualnej |
| HMI-08 | Uprawnienia operator/serwis, jeżeli wymagane przez uzgodniony projekt | Dostęp zgodny z zatwierdzonym katalogiem; PLC nadal egzekwuje blokady procesu niezależnie od widoczności ekranu |
| HMI-09 / AT-14 | Przeciwne jogi/cele; zapis zakazanej komendy spoza HMI; stoper przy aktywnej taśmie | Odrzucenie przez PLC z przyczyną, brak ukrytego kolejkowania |
| HMI-10 / AT-08/10 | Manual EUROMAP bez HOME, w ruchu, potem przy poprawnych warunkach i przejściu Auto | Zgodne pozwolenia PLC, osobne wskazania żądania, decyzji i wejścia Krauss. Wejście w Auto kasuje żądania ręczne. |
| HMI-11 / AT-01/14 | Przegląd każdego przycisku, ekranów, polskich znaków i opisu celu | Typ i tryb zgodne z tabelą panelu, odpowiednia dostępność, powód blokady, stan rzeczywisty i czytelne jednostki |
| HMI-12 | Porównanie eksportów PLC i Vijeo oraz próby typów | Każdy wymagany symbol istnieje, właściwy typ/zakres/kierunek; -1 nie staje się 65535; częstotliwość REAL i czasy w ms poprawne, statusy mają dostęp R |

Przejdź po wszystkich 20 panelach i sprawdź powroty, zapisy numeru ekranu oraz zerowanie żądań przy zmianie widoku. Do kompletu odbioru dołącz edytowalny projekt, wersję narzędzia i targetu, eksport symboli, kopię zapasową, raport kompilacji oraz wyniki testów. [Integracja PLC stacji](station-plc-implementation.md).
