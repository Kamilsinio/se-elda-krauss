# Vijeo Designer — ekrany HMI, działanie obiektów i zmienne PLC

Stan na 19.11.2026. Instrukcja do budowy projektu Krauss według interfejsu HMI v4. Zacznij od numerów paneli i jednego szablonu. Następnie dla każdego panelu utwórz obiekty z jego tabeli. Nazwa w kolumnie „Zmienna lub akcja” jest ścieżką w źródłach PLC. W Vijeo wybierz odpowiadający jej symbol z eksportu docelowej aplikacji.

Ścieżki PLC w tabelach wskazują pola potwierdzone w źródłach ST. Podłączenie sprzętu, eksport symboli i próby Vijeo wymagają osobnego sprawdzenia. **Lokalnie** oznacza nawigację, obliczenie lub pamięć panelu. **Otwarte** oznacza miejsce w projekcie bez aktywnego sterowania. Funkcje sprzętowe zależne od mapy pokazuj na szaro przy nieważnym odczycie.

## Lista ekranów

Przygotuj **20 ekranów podstawowych**. Numery są zgodne z dotychczasowym planem HMI. Zakładki wewnętrzne i lokalne okna potwierdzeń nie są dodatkowymi ekranami procesu.

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

## Wspólny szablon wszystkich 20 ekranów

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Nagłówek i zakładki stacji | Stały tytuł. Na każdej karcie stacji przejdź do Statusu, Manual lub Parametrów tej samej stacji według numerów powyżej. | Lokalnie w Vijeo |
| HOME / Zlecenie / Alarmy / Diagnostyka / Wstecz | Zmiana panelu na 1 / 2 / 3 / 301. Wstecz z Manual lub Parametrów wraca na Status stacji, z pozostałych podstron na HOME. | Lokalnie w Vijeo |
| Numer aktywnego panelu | Po każdym wejściu zapisz rzeczywisty numer ekranu (UINT). Zakładka lokalna wewnątrz ekranu zachowuje jego numer. | `GVL_HMI.hmiV2.link.uiActivePanel` |
| Tryb · pole tekstowe | 10 Manual, 20 Auto. Pokazuj tryb potwierdzony przez PLC. | `GVL_HMI.hmiV2.state.uiMode` |
| Pasek alarmów · baner z przejściem na 3 | Czerwony dla krytycznego, pomarańczowy dla ostrzeżenia. Tekst według rekordu z tabeli alarmów. Przy utracie komunikacji pokaż „Brak danych”. | `GVL_HMI.vijeo.alarms.critical`<br>`GVL_HMI.vijeo.alarms.warning` |
| Łączność i gotowość do poleceń · wskaźniki | Kontroluj jakość komunikacji drivera oraz zmiany licznika PLC w runtime panelu. Osobno pokaż dane skanera i uzbrojenie sesji. Utrata świeżości blokuje polecenia operatorskie. | `GVL_HMI.hmiV2.link.uiPlcHeartbeat`<br>`GVL_HMI.hmiV2.link.xDataValid`<br>`GVL_HMI.hmiV2.link.xArmed`<br>`GVL_HMI.hmiV2.link.sDiag` |
| Blokada / wynik · tekst zawijany | Przy transakcji pokaż powód niedostępności, następnie wynik konkretnego żądania. Dla ruchów pokaż właściwe potwierdzenia urządzenia. | Pola `permit` i `rsp` opisane poniżej |

## Jak skonfigurować powtarzalne obiekty

**Dobór obiektu Vijeo.** Do nawigacji i poleceń użyj `Switch`, do ruchów przytrzymywanych użyj `Switch` z działaniem `Momentary ON` i licznikiem danego urządzenia. Do sygnalizacji użyj `Lamp` lub grafiki z animacją koloru. Dla nastawy umieść obok siebie `Numeric Input` i `Numeric Display` z jednostką. Do komunikatu PLC użyj pola tekstowego z zawijaniem, a do kodu stanu listy opisów z widocznym numerem przy nieznanym kodzie.

**Kierunek danych.** Lampki, liczniki, teksty i potwierdzenia tylko odczytują PLC. Zapis przypisz wyłącznie do opisanego żądania, licznika podtrzymania, bufora edycji lub pól sesji zapisywanych przez HMI. Pola rewizji, flagi weryfikacji i parametry konfiguracji służą panelowi do odczytu. Zapis `[i-1]` oznacza, że dla numeru logicznego i wpisujesz w Vijeo indeks o jeden mniejszy. Dla alarmu nr 41 wybierz `entries[40]`. Dokładne indeksy stałych obiektów podano w tabelach.

**Sesja HMI.** PLC publikuje wersję w `GVL_HMI.hmiV2.link.uiContractVersion` (wymagana 4). HMI cyklicznie zmienia `GVL_HMI.hmiV2.link.uiHmiHeartbeat` (UINT). Po starcie lub powrocie łączności wyzeruj żądania HMI, poczekaj na zanik ACK i neutralne ręczne przyciski. Wyślij nowe zbocze 0→1 na `GVL_HMI.hmiV2.link.xArmReq`, wróć do 0 i odczytaj `GVL_HMI.hmiV2.link.xArmed` oraz nowe `GVL_HMI.hmiV2.link.udiSessionId` (UDINT). Ostatniego polecenia nie odtwarzaj. Okresy dobierz do skonfigurowanego `GVL_HMI.vijeo.hmiTimeoutMs` i sprawdź w runtime.

**Przycisk transakcyjny.** Rozpoznasz go po wiązaniu kończącym się na `.xReq`. Nazwa między `cmd` i `xReq` wskazuje ten sam klucz w trzech gałęziach. Przykład dla „Start zlecenia” poniżej. Zastosuj go do wszystkich przycisków transakcyjnych.

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Dostępność | Odczytaj BOOL i tekst przyczyny. Włącz przycisk przy aktualnej, uzbrojonej sesji, zgodzie PLC i braku transakcji w toku. Tekst może być pusty. | `GVL_HMI.hmiV2.permit.orderOpen.xAllowed`<br>`GVL_HMI.hmiV2.permit.orderOpen.sReason` |
| Naciśnięcie | Najpierw zapisz ID sesji i nowy rosnący niezerowy ID żądania (UDINT). Na końcu ustaw BOOL xReq na 1 i utrzymaj do odpowiedzi. Jedna transakcja naraz w całym HMI. | `GVL_HMI.hmiV2.cmd.orderOpen.udiSessionId`<br>`GVL_HMI.hmiV2.cmd.orderOpen.udiRequestId`<br>`GVL_HMI.hmiV2.cmd.orderOpen.xReq` |
| Odpowiedź | Przy xAck=1 sprawdź zgodność obu ID. Wynik 1 oznacza przyjęcie, 2 odmowę. Pokaż kod i tekst. Zdejmij xReq, poczekaj na xAck=0 i dopiero odblokuj następne polecenie. | `GVL_HMI.hmiV2.rsp.orderOpen.xAck`<br>`GVL_HMI.hmiV2.rsp.orderOpen.udiSessionId`<br>`GVL_HMI.hmiV2.rsp.orderOpen.udiRequestId`<br>`GVL_HMI.hmiV2.rsp.orderOpen.uiResult`<br>`GVL_HMI.hmiV2.rsp.orderOpen.uiReason`<br>`GVL_HMI.hmiV2.rsp.orderOpen.sReason` |

**Lampki I/O.** Każde pole `GVL_HMI.vijeo.value.N` ma osobną ważność `GVL_HMI.vijeo.valid.N` o identycznej końcówce. Oba są BOOL do odczytu. Przykładowo dla B205 wybierz `GVL_HMI.vijeo.value.ind_B205` i `GVL_HMI.vijeo.valid.ind_B205`. Przy nieważnym kanale pokaż szare „Brak danych”. Wskazanie wyjścia podpisz „Komenda PLC”. Krańcówka, czujnik lub sprzężenie napędu mają własne wskazanie.

**Manual ST.1–ST.4 i EUROMAP.** Przycisk chwilowy zgłasza kierunek podczas trzymania. Wpisz bieżące ID sesji do `GVL_HMI.vijeo.stationManual.sessionId` (na panelu 201 do `GVL_HMI.vijeo.immManual.sessionId`). Zaczynaj od zwolnionych obu kierunków. Zmieniaj licznik UINT danego urządzenia `GVL_HMI.vijeo.stationManual.holdCounter[i-1]` albo `GVL_HMI.vijeo.immManual.holdCounter[i-1]` tylko podczas aktywnego nacisku. Dla kierunku dodatniego i EUROMAP indeks licznika jest taki sam jak indeks bitu. Dla kierunku wstecznego kanału PLC `n` (2–16) zapisuj `negativeFrom2[n-2]` i odświeżaj `holdCounter[n-1]`. Zwolnienie, opuszczenie ekranu i utrata sesji kończą żądanie i odświeżanie. Po utracie zezwolenia lub konflikcie wymagane jest zwolnienie i nowe naciśnięcie. Położenie mechanizmu po zwolnieniu zależy od wykonawcy i polityki PLC. W Auto wyszarz przyciski.

Dla Manual ST.1–ST.4 PLC sprawdza m.in. numer ekranu, postój produkcji, właściciela zasobu, aktualne HOME i znany ładunek robota, zatwierdzone parametry i politykę zwolnienia. Przyczyny widoczne dla operatora buduj z dostępnych stanów. `GVL_HMI.vijeo.allowManualPositive[i-1]` i `GVL_HMI.vijeo.allowManualNegative[i-1]` to wejściowe pozwolenia kierunków do odczytu. PLC dodatkowo ocenia konflikty, stan napędów i rezerwacje. Interfejs v4 nie publikuje osobnego końcowego tekstu odmowy dla każdego jogu.

**Parametry ST.1–ST.4.** Na wejściu użyj „Wczytaj”. Po ACK pokaż osobno bufor edycji i wartość przyjętą. Zmianę zaznacz lokalnie przez porównanie pól. „Zastosuj” przesyła cały zestaw stacji z rewizją zapamiętaną przez PLC przy wczytaniu. Zamroź edycję na czas transakcji. Po udanym zapisie wykonaj „Wczytaj”, aby odświeżyć rewizję bazową. PLC wymaga potwierdzonego postoju, braku recovery oraz zgodnej rewizji. Zlecenie może pozostać otwarte.

Czasy są typu UDINT w ms, częstotliwości REAL w Hz (jedna cyfra po przecinku). Granice dla klawiatury pobierz do odczytu z `GVL_Station.ParameterCfg.minTimeMs` / `GVL_Station.ParameterCfg.maxTimeMs` / `GVL_Station.ParameterCfg.maxHz`. PLC sprawdza flagę `verified` zestawu i `GVL_Station.ParameterCfg.limitsVerified`. Zachowaj flagę zestawu z Wczytaj. Jeśli zestaw początkowy nie został zweryfikowany, pokaż „Wymagane zatwierdzenie nastaw w PLC”. Czasy ruchu i siłownika muszą być większe od stabilizacji.

**Reset stanu stacji.** Pokaż lokalne okno „Potwierdź / Anuluj”. Dopiero potwierdzenie wysyła wskazaną transakcję. PLC wymaga Manual i postoju, po przyjęciu żąda uzgodnienia stacji. Ładunki, liczniki i zobowiązania pozostają zachowane. Po lokalnym błędzie siłownika pokaż wymaganie wznowienia z `GVL_HMI.vijeo.localRestartRequired[i-1]`. Po usunięciu przyczyny i resecie potrzebny jest świeży fizyczny Start w Auto lub ponowne naciśnięcie w Manual.

## Elementy na poszczególnych ekranach

<a id="panel-1"></a>

### Panel 1 — HOME

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| ST.1 Załadunek / ST.2 Winda / ST.3 Rozładunek / ST.4 Magazyn przekładek / ST.5 Robot · 5 kafli | Przejdź odpowiednio na 101, 102, 103, 104, 105. Kolor lokalny według rekordów zatrzaśniętych i skonfigurowanych dla numeru stacji. Szary przy nieaktualnych danych, czerwony dla krytycznych, pomarańczowy dla ostrzeżeń. | `GVL_HMI.vijeo.alarms.entries[i-1].station`<br>`GVL_HMI.vijeo.alarms.entries[i-1].configured`<br>`GVL_HMI.vijeo.alarms.entries[i-1].latched`<br>`GVL_HMI.vijeo.alarms.entries[i-1].critical`<br>`GVL_HMI.hmiIo.dataValid`<br>`GVL_HMI.hmiV2.state.xRobotDataValid` |
| Auto · przycisk | Poproś o tryb automatyczny po rozliczeniu operacji. | `GVL_HMI.hmiV2.cmd.modeAuto.xReq` |
| Manual · przycisk | Poproś o tryb ręczny po zatrzymaniu. | `GVL_HMI.hmiV2.cmd.modeManual.xReq` |
| Praca z robotem — Włącz · przycisk | Włącz współpracę przy potwierdzonym HOME i rozliczonych operacjach. | `GVL_HMI.hmiV2.cmd.robotEnable.xReq` |
| Praca z robotem — Wyłącz · przycisk | Wyłącz współpracę po zatrzymaniu, przy potwierdzonym HOME. | `GVL_HMI.hmiV2.cmd.robotDisable.xReq` |
| Praca z robotem / HOME · lampki | Pokaż przyjętą opcję oraz HOME potwierdzone w sesji z rozpoznanym ładunkiem. | `GVL_HMI.hmiV2.state.xWorkWithRobot`<br>`GVL_HMI.hmiV2.state.xRobotHomeValid` |
| Reset alarmów · przycisk | Zażądaj skasowania po usunięciu przyczyny. Wznowienie wymaga odrębnej czynności. | `GVL_HMI.hmiV2.cmd.resetFaults.xReq` |
| Zlecenie / produkcja / wykonanie · trzy pola tekstowe | Opisy kodów jak na panelu 2. | `GVL_HMI.hmiV2.state.uiOrderState`<br>`GVL_HMI.hmiV2.state.uiProduction`<br>`GVL_HMI.hmiV2.state.uiExecutionState` |
| Gotowość na fizyczny START · lampka i tekst | Wyświetl pozwolenie na Start oraz powód blokady. | `GVL_HMI.hmiV2.state.xCanPhysicalStart`<br>`GVL_HMI.hmiV2.state.sStartBlockReason` |
| PLC/HMI / FANUC / Festo / ATV320 · cztery wskaźniki | HMI według jakości drivera i zmiany heartbeat. FANUC według sesji, bramka Festo według świeżości i diagnostyki BAT100, napęd według komunikacji. | `GVL_HMI.hmiV2.link.uiPlcHeartbeat`<br>`GVL_HMI.hmiV2.state.xRobotDataValid`<br>`GVL_HMI.vijeo.modules[0]`<br>`GVL_HMI.hmiStatus.xVfdCommOk` |
| Krytyczne / ostrzeżenia · dwa liczniki | Oblicz lokalnie liczbę skonfigurowanych zatrzaśniętych rekordów odpowiedniej klasy. Dotknięcie otwiera panel 3. | `GVL_HMI.vijeo.alarms.entries[i-1].configured`<br>`GVL_HMI.vijeo.alarms.entries[i-1].latched`<br>`GVL_HMI.vijeo.alarms.entries[i-1].critical` |
| Komunikat procesu | Gdy PLC czeka na odbiór, pokaż „Odbierz stos lub pojemnik”. Przy wymaganym uzgodnieniu wskaż Diagnostykę (301). | `GVL_HMI.hmiV2.station.waitingPickup`<br>`GVL_HMI.hmiV2.state.xRecoveryRequired` |

<a id="panel-2"></a>

### Panel 2 — ZLECENIE

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Pojemniki / Blistry · dwa przyciski wyboru | Zapisz 1 dla Pojemników lub 2 dla Blistrów (UINT). Wybór w buforze przy zamkniętym zleceniu, przed otwarciem nowego. Nie uzależniaj samego wyboru od pozwolenia orderOpen, które już sprawdza wybrany kod. | `GVL_HMI.hmiV2.edit.uiProgram` |
| Start zlecenia · przycisk | Zatwierdź wybraną produkcję i otwórz zlecenie. Ruch rozpoczyna fizyczny Start, FANUC uruchamia operator na robocie. | `GVL_HMI.hmiV2.cmd.orderOpen.xReq` |
| Koniec zlecenia · przycisk | PLC rozlicza rozpoczęte operacje, opróżnia stację i czeka na odbiór przy B304. Przy żądaniu z postoju opróżnianie wymaga fizycznego Start. | `GVL_HMI.hmiV2.cmd.orderEnd.xReq` |
| Zatwierdzona produkcja · pole tekstowe | 0 brak, 10 Pojemniki, 20 Blistry. Oddziel ją od kandydata w edycji. Kod programu w actual ma wartości 1/2. | `GVL_HMI.hmiV2.state.uiProduction`<br>`GVL_HMI.hmiV2.actual.uiProgram` |
| Stan zlecenia · tekst | 0 zamknięte, 10 otwarte, 20 kończenie, 30 opróżnianie, 90 wymagane uzgodnienie. | `GVL_HMI.hmiV2.state.uiOrderState` |
| Stan wykonania · tekst | 0 postój, 10 gotowy, 20 praca, 30 zatrzymywanie, 40 zatrzymany, 50 opróżnianie, 90 wymagane uzgodnienie. Osobna lampka pauzy. | `GVL_HMI.hmiV2.state.uiExecutionState`<br>`GVL_HMI.hmiV2.station.paused` |
| Rozliczanie / transfer / odbiór / zakończenie · wskaźniki | Pokaż operacje rozliczone, liczbę nierozliczonych wtrysków, transfer w toku, etap opróżniania i oczekiwanie na odbiór. Stop pauzuje po bieżącej operacji. Zakończenie zlecenia potwierdza powrót stanu zlecenia do 0. | `GVL_HMI.hmiV2.state.xOpsSettled`<br>`GVL_HMI.hmiV2.state.uiUnsettled`<br>`GVL_Station.Transport.busy`<br>`GVL_HMI.hmiV2.station.drainStep`<br>`GVL_HMI.hmiV2.station.waitingPickup` |
| Stacja pusta · lampka trójstanowa | Wymagaj aktualnych danych i uzgodnionego modelu. Pokaż „Pusta”, „Zajęta” lub „Stan nieznany”. | `GVL_HMI.hmiV2.station.emptyConfirmed`<br>`GVL_HMI.hmiV2.station.materialKnown`<br>`GVL_HMI.hmiV2.station.dataValid` |
| Detale na wtrysk · odczyt i przejście do nastawy | Pokaż aktualną ilość w sztukach. Przycisk „Zmień ilość” otwiera 125. | `GVL_HMI.hmiV2.actual.uiBatchCount` |

Dla kroku opróżniania stosuj 0 bezczynny, 10 wybór operacji, 20 oczekiwanie na wykonanie, 40 pauza, 100 ukończone, 900 błąd. Wartość spoza słownika pokaż wraz z numerem.

<a id="panel-3"></a>

### Panel 3 — ALARMY

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Aktywne / Historia i Wszystkie / Krytyczne / Ostrzeżenia · zakładki i filtry | Wybierz lokalny widok i klasę. Sortuj historię od najnowszego zdarzenia. | Lokalnie w Vijeo |
| Lista alarmów · przewijana tabela | Powiel wiersz dla i=1…64. Kolumny ID, stacja, opis, klasa, przyczyna aktywna, zatrzaśnięty, ustąpił, potwierdzony. W widoku bieżącym uwzględnij także zatrzaśnięte wpisy po ustąpieniu przyczyny. | `GVL_HMI.vijeo.alarms.entries[i-1].code`<br>`GVL_HMI.vijeo.alarms.entries[i-1].station`<br>`GVL_HMI.vijeo.alarms.entries[i-1].text`<br>`GVL_HMI.vijeo.alarms.entries[i-1].critical`<br>`GVL_HMI.vijeo.alarms.entries[i-1].active`<br>`GVL_HMI.vijeo.alarms.entries[i-1].latched`<br>`GVL_HMI.vijeo.alarms.entries[i-1].returned`<br>`GVL_HMI.vijeo.alarms.entries[i-1].acknowledged` |
| Szczegóły · pola tekstowe i lampka | Pokaż opis, czynność operatora i możliwość skasowania wybranego rekordu. | `GVL_HMI.vijeo.alarms.entries[i-1].text`<br>`GVL_HMI.vijeo.alarms.entries[i-1].actionText`<br>`GVL_HMI.vijeo.alarms.entries[i-1].canReset` |
| Konfiguracja / liczba zatrzaśniętych · lampka i odczyt | Pokaż gotowość konfiguracji alarmów i licznik PLC. Oddziel rekordy niesklasyfikowane. Dwa liczniki klas oblicz jak na HOME. | `GVL_HMI.vijeo.alarms.policyReady`<br>`GVL_HMI.vijeo.alarms.count`<br>`GVL_HMI.vijeo.alarms.entries[i-1].configured` |
| Historia · Alarm Summary / dziennik lokalny | Rejestruj czas pojawienia się i zaniku przyczyny oraz zmiany ACK w runtime Vijeo. Wpisy mają czas panelu. Historia za okres wyłączenia panelu wymaga odrębnego archiwum. | `GVL_HMI.vijeo.alarms.entries[i-1].active`<br>`GVL_HMI.vijeo.alarms.entries[i-1].acknowledged` |
| Potwierdź alarmy · przycisk | Potwierdź w PLC. Lista odczytuje acknowledged. Lokalny ACK obiektu Alarm Summary nie zastępuje tej transakcji. | `GVL_HMI.hmiV2.cmd.alarmAckAll.xReq` |
| Reset alarmów · przycisk | Kasuj zatrzaśnięcia zgodnie z polityką PLC po ustąpieniu przyczyny. | `GVL_HMI.hmiV2.cmd.resetFaults.xReq` |

ID 1–11 obejmują ostrzeżenia siłowników ST.1–ST.4, ID 12–52 wymagają zatwierdzonej klasy GAP-12, 53–64 to rezerwa. Oczekiwanie na odbiór pozostaje statusem procesu. [Katalog ID alarmów](station-alarm-catalog.csv).

<a id="panel-101"></a>

### Panel 101 — ST.1 — STATUS · Załadunek

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Schemat P1 / P2 / P3 · trzy wskaźniki | Pokaż zajętość po filtracji i ważność danej pozycji. B101=P1, B102=P2, B103=P3. | `GVL_HMI.vijeo.occupied[0]`<br>`GVL_HMI.vijeo.occupied[1]`<br>`GVL_HMI.vijeo.occupied[2]`<br>`GVL_HMI.vijeo.positionsValid[0]`<br>`GVL_HMI.vijeo.positionsValid[1]`<br>`GVL_HMI.vijeo.positionsValid[2]` |
| Bariera załadunku · lampka i tekst | Przerwana / wolna przy ważnym odczycie. Osobna bariera wymaga potwierdzenia mapy GAP-01. Dla zatwierdzenia przejazdu całego stosu brak osobnego publicznego bitu. | `GVL_HMI.hmiIo.barrierBlocked`<br>`GVL_HMI.hmiIo.barrierValid` |
| V101/V102 lewy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V101_HP`<br>`GVL_HMI.vijeo.value.ind_V101_WP` |
| V101/V102 prawy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V102_HP`<br>`GVL_HMI.vijeo.value.ind_V102_WP` |
| V101/V102 · ruch, ostrzeżenie i tekst | Grupa M2, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM2_Busy`<br>`GVL_HMI.vijeo.alarms.entries[1].active`<br>`GVL_HMI.hmiStatus.sM2DiagText` |
| V103/V104 lewy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V103_HP`<br>`GVL_HMI.vijeo.value.ind_V103_WP` |
| V103/V104 prawy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V104_HP`<br>`GVL_HMI.vijeo.value.ind_V104_WP` |
| V103/V104 · ruch, ostrzeżenie i tekst | Grupa M3, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM3_Busy`<br>`GVL_HMI.vijeo.alarms.entries[2].active`<br>`GVL_HMI.hmiStatus.sM3DiagText` |
| V105/V106 lewy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V105_HP`<br>`GVL_HMI.vijeo.value.ind_V105_WP` |
| V105/V106 prawy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V106_HP`<br>`GVL_HMI.vijeo.value.ind_V106_WP` |
| V105/V106 · ruch, ostrzeżenie i tekst | Grupa M4, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM4_Busy`<br>`GVL_HMI.vijeo.alarms.entries[3].active`<br>`GVL_HMI.hmiStatus.sM4DiagText` |
| V107/V108 lewy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V107_HP`<br>`GVL_HMI.vijeo.value.ind_V107_WP` |
| V107/V108 prawy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V108_HP`<br>`GVL_HMI.vijeo.value.ind_V108_WP` |
| V107/V108 · ruch, ostrzeżenie i tekst | Grupa M1, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM1_Busy`<br>`GVL_HMI.vijeo.alarms.entries[0].active`<br>`GVL_HMI.hmiStatus.sM1DiagText` |
| V109/V110 lewy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V109_HP`<br>`GVL_HMI.vijeo.value.ind_V109_WP` |
| V109/V110 prawy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V110_HP`<br>`GVL_HMI.vijeo.value.ind_V110_WP` |
| V109/V110 · ruch, ostrzeżenie i tekst | Grupa M5, obie strony mają wspólny napęd. | `GVL_HMI.hmiStatus.xM5_Busy`<br>`GVL_HMI.vijeo.alarms.entries[4].active`<br>`GVL_HMI.hmiStatus.sM5DiagText` |
| Taśma · lampka komendy, kierunek, diagnostyka | Lampka wskazuje końcową komendę PLC. Kierunek (INT) wyświetl jako 1 naprzód, −1 wstecz, 0 postój. Przy wyłączonej komendzie pokaż brak komendy ruchu. Tekst obok grafiki. | `GVL_HMI.hmiStatus.xConvTopRunning`<br>`GVL_HMI.hmiStatus.iConvTopDirection`<br>`GVL_HMI.hmiStatus.sConvTopDiagText` |
| Krok przepływu / opis · liczba i tekst | Pokaż kod kroku z E_TopFlowState oraz diagnostykę. Zajętość P1 i stan sekwencji służą do oceny miejsca na nowy stos. | `GVL_HMI.hmiStatus.uiTopFlowState`<br>`GVL_HMI.hmiStatus.sTopFlowDiagText` |
| Przekazanie P3 / aktualny transfer · lampki i tekst | Gotowość i rezerwacja obszaru pobrania przez robota, właściciel i bieżąca operacja transportu. Ważność obszaru sprawdź oddzielnie. | `GVL_HMI.vijeo.sourceArea.valid`<br>`GVL_HMI.vijeo.sourceArea.ready`<br>`GVL_HMI.vijeo.sourceArea.reserved`<br>`GVL_HMI.hmiV2.station.owner`<br>`GVL_HMI.hmiV2.station.action_` |

<a id="panel-111"></a>

### Panel 111 — ST.1 — MANUAL · Załadunek

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Transporter naprzód · przycisk chwilowy | Trzymaj, aby żądać ruchu taśmy. Dostępny kierunek naprzód. Licznik `GVL_HMI.vijeo.stationManual.holdCounter[0]`. | `GVL_HMI.vijeo.stationManual.positive[0]` |
| V101/V102 WORK / HOME · dwa przyciski chwilowe | Wspólny kierunek dla pary M2. Postój górnej taśmy i wolny obszar wymagane. Licznik 6. | `GVL_HMI.vijeo.stationManual.positive[5]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[4]` |
| V103/V104 WORK / HOME · dwa przyciski chwilowe | Wspólny kierunek dla pary M3. Postój górnej taśmy i wolny obszar wymagane. Licznik 7. | `GVL_HMI.vijeo.stationManual.positive[6]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[5]` |
| V105/V106 WORK / HOME · dwa przyciski chwilowe | Wspólny kierunek dla pary M4. Postój górnej taśmy i wolny obszar wymagane. Licznik 8. | `GVL_HMI.vijeo.stationManual.positive[7]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[6]` |
| V107/V108 WORK / HOME · dwa przyciski chwilowe | Wspólny kierunek dla pary M1. Postój górnej taśmy i wolny obszar wymagane. Licznik 5. | `GVL_HMI.vijeo.stationManual.positive[4]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[3]` |
| V109/V110 WORK / HOME · dwa przyciski chwilowe | Wspólny kierunek dla pary M5. Postój górnej taśmy i wolny obszar wymagane. Licznik 9. | `GVL_HMI.vijeo.stationManual.positive[8]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[7]` |
| Pozycje i potwierdzenia · lampki | Skopiuj z panelu 101 lampki lewej i prawej strony dla tych samych zaworów, ruch grupy i ostrzeżenie. | [Krańcówki i diagnostyka V101–V110 na 101](#panel-101) |
| Wymagane wznowienie · lampki | Po lokalnej usterce wskaż mechanizm wymagający usunięcia przyczyny, resetu i świeżego polecenia. | `GVL_HMI.vijeo.localRestartRequired[1]`<br>`GVL_HMI.vijeo.localRestartRequired[2]`<br>`GVL_HMI.vijeo.localRestartRequired[3]`<br>`GVL_HMI.vijeo.localRestartRequired[0]`<br>`GVL_HMI.vijeo.localRestartRequired[4]` |
| Postój / rezerwacja / właściciel · lampki | Pokaż warunki blokujące żądanie. | `GVL_HMI.vijeo.beltsStopped[0]`<br>`GVL_HMI.vijeo.sourceArea.reserved`<br>`GVL_HMI.hmiV2.station.owner` |

<a id="panel-121"></a>

### Panel 121 — ST.1 — PARAMETRY · Załadunek

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Stabilizacja · edytor i odczyt | ms, filtr przepływu i potwierdzeń grup. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.stationEdit[0].sensorStableMs`<br>`GVL_HMI.vijeo.stationActual[0].sensorStableMs` |
| Zwłoka zatrzymania taśmy · edytor i odczyt | ms, oczekiwanie po wyłączeniu. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.stationEdit[0].stopDelayMs`<br>`GVL_HMI.vijeo.stationActual[0].stopDelayMs` |
| Timeout transferu · edytor i odczyt | ms, nadzór ruchu. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.stationEdit[0].moveTimeoutMs`<br>`GVL_HMI.vijeo.stationActual[0].moveTimeoutMs` |
| Timeout siłowników · edytor i odczyt | ms, wspólny próg pięciu grup. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.stationEdit[0].actuatorTimeoutMs`<br>`GVL_HMI.vijeo.stationActual[0].actuatorTimeoutMs` |
| Rewizja edycji / aktywna · odczyty | Gdy wartości się różnią, wczytaj zestaw ponownie. Oba pola zapisuje PLC. | `GVL_HMI.vijeo.stationEditRevision[0]`<br>`GVL_HMI.vijeo.stationRevision[0]` |
| Zestaw zatwierdzony · lampka | Potwierdzenie konfiguracji zestawu. Bufor zachowuje flagę po Wczytaj. | `GVL_HMI.vijeo.stationActual[0].verified`<br>`GVL_HMI.vijeo.stationEdit[0].verified` |
| Wczytaj / Anuluj · przycisk | Wczytaj aktualne dane i rewizję, porzuć niezapisane zmiany. | `GVL_HMI.hmiV2.cmd.station1ParamReload.xReq` |
| Zastosuj · przycisk | PLC sprawdza komplet parametrów. Pokaż wynik i odśwież zestaw po przyjęciu. | `GVL_HMI.hmiV2.cmd.station1ParamApply.xReq` |
| Reset stanu ST.1 · przycisk | Po potwierdzeniu zażądaj uzgodnienia stanu. | `GVL_HMI.hmiV2.cmd.station1ResetState.xReq` |

PLC stosuje jeden zestaw czasów ST.1. Indywidualne progi 5 par i osobny timeout oczekiwania na stopery pozostają poza edycją v4.

<a id="panel-102"></a>

### Panel 102 — ST.2 — STATUS · Winda

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| B201 · lampka | Górny poziom. | `GVL_HMI.vijeo.value.ind_B201` |
| B202 · lampka | Pośredni górny. | `GVL_HMI.vijeo.value.ind_B202` |
| B203 · lampka | Pośredni dolny. | `GVL_HMI.vijeo.value.ind_B203` |
| B204 · lampka | Dolny poziom. | `GVL_HMI.vijeo.value.ind_B204` |
| B205 · obecność na wysokości czujnika · lampka | Pokaż jako osobny sygnał po potwierdzeniu podłączenia (GAP-02). | `GVL_HMI.vijeo.value.ind_B205` |
| P4 · ładunek na windzie | Stan zapamiętany przez model materiału. Przy braku uzgodnienia pokaż „Stan nieznany”. Odsłonięcie B205 podczas pozycjonowania nie oznacza utraty ładunku. | `GVL_HMI.vijeo.stationOccupied[3]`<br>`GVL_HMI.hmiV2.station.materialKnown`<br>`GVL_HMI.hmiV2.station.dataValid` |
| V201 · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V201_HP`<br>`GVL_HMI.vijeo.value.ind_V201_WP` |
| V201 · komenda i ostrzeżenie | Komenda końcowa WORK i ostrzeżenie danego pozycjonera. Potwierdzenie pochodzi z osobnych krańcówek. | `GVL_HMI.vijeo.value.ctrl_V201`<br>`GVL_HMI.vijeo.alarms.entries[5].active` |
| V202 · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V202_HP`<br>`GVL_HMI.vijeo.value.ind_V202_WP` |
| V202 · komenda i ostrzeżenie | Komenda końcowa WORK i ostrzeżenie danego pozycjonera. Potwierdzenie pochodzi z osobnych krańcówek. | `GVL_HMI.vijeo.value.ctrl_V202`<br>`GVL_HMI.vijeo.alarms.entries[6].active` |
| V203 · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V203_HP`<br>`GVL_HMI.vijeo.value.ind_V203_WP` |
| V203 · komenda i ostrzeżenie | Komenda końcowa WORK i ostrzeżenie danego pozycjonera. Potwierdzenie pochodzi z osobnych krańcówek. | `GVL_HMI.vijeo.value.ctrl_V203`<br>`GVL_HMI.vijeo.alarms.entries[7].active` |
| Taśma · lampka komendy, kierunek, diagnostyka | Lampka wskazuje końcową komendę PLC. Kierunek (INT) wyświetl jako 1 naprzód, −1 wstecz, 0 postój. Przy wyłączonej komendzie pokaż brak komendy ruchu. Tekst obok grafiki. | `GVL_HMI.hmiStatus.xConvElevRunning`<br>`GVL_HMI.hmiStatus.iConvElevDirection`<br>`GVL_HMI.hmiStatus.sConvElevDiagText` |
| Oś windy · pole Hz, stan i diagnostyka | Częstotliwość rzeczywista, REAL w Hz (0,0). Wymagaj komunikacji ATV i ważnego pomiaru. Kod stanu według E_ElevatorState. | `GVL_HMI.hmiStatus.rElevFreq_Hz`<br>`GVL_HMI.hmiStatus.xVfdCommOk`<br>`GVL_Station.DriveFrequencyValid`<br>`GVL_HMI.hmiStatus.uiElevState`<br>`GVL_HMI.hmiStatus.xElevBusy`<br>`GVL_HMI.hmiStatus.xElevFault`<br>`GVL_HMI.hmiStatus.sElevDiagText` |
| Bieżący stos · licznik sztuk | Liczba blistrów w bieżącym kontekście. Pokaż w trybie Blistry. | `GVL_HMI.hmiStatus.uiTraysDone`<br>`GVL_HMI.hmiV2.state.uiProduction` |

V201 i V202 mają odrębne krańcówki i alarmy. `GVL_HMI.hmiStatus.xM6_Busy` oznacza ruch co najmniej jednego z nich. Osobny bit ruchu dla każdej z tych dwóch osi pozostaje otwarty.

<a id="panel-112"></a>

### Panel 112 — ST.2 — MANUAL · Winda

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Oś windy — góra / dół · dwa przyciski chwilowe | Żądaj ruchu osi tylko przy trzymaniu. Kod ustawia ręczną prędkość wolną. Licznik 4. | `GVL_HMI.vijeo.stationManual.positive[3]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[2]` |
| Taśma windy — do robota / do rozładunku · dwa przyciski chwilowe | Dodatni kierunek załącza IN, ujemny załącza OUT. Potwierdź etykiety kierunków na maszynie. Licznik 2. | `GVL_HMI.vijeo.stationManual.positive[1]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[0]` |
| V201 lewy pozycjoner blistrów — WORK / HOME · dwa przyciski chwilowe | Żądaj osobno wybranego położenia. Licznik 10. | `GVL_HMI.vijeo.stationManual.positive[9]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[8]` |
| V202 prawy pozycjoner blistrów — WORK / HOME · dwa przyciski chwilowe | Żądaj osobno wybranego położenia. Licznik 11. | `GVL_HMI.vijeo.stationManual.positive[10]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[9]` |
| V203 pozycjoner pojemnika — WORK / HOME · dwa przyciski chwilowe | Żądaj osobno wybranego położenia. Licznik 12. | `GVL_HMI.vijeo.stationManual.positive[11]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[10]` |
| Pozycje, częstotliwość i potwierdzenia | Skopiuj z 102 lampki B201–B205, krańcówki V201–V203 i odczyt Hz z jego ważnością. | [B201–B205, V201–V203 i częstotliwość na 102](#panel-102) |
| Blokady · lampki | Postój taśmy, zajętość osi, rezerwacja obszaru windy. | `GVL_HMI.vijeo.beltsStopped[1]`<br>`GVL_HMI.hmiStatus.xElevBusy`<br>`GVL_HMI.vijeo.elevatorAreaReserved` |
| Wymagane wznowienie · lampki | Po lokalnej usterce wskaż mechanizm wymagający usunięcia przyczyny, resetu i świeżego polecenia. | `GVL_HMI.vijeo.localRestartRequired[5]`<br>`GVL_HMI.vijeo.localRestartRequired[7]`<br>`GVL_HMI.vijeo.localRestartRequired[6]` |
| Szybki jog | Ukryj przełącznik. Sterownik ustawia ręczny szybki bieg na FALSE. | Otwarte · brak powiązania operatorskiego |

<a id="panel-122"></a>

### Panel 122 — ST.2 — PARAMETRY · Winda

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Stabilizacja · edytor i odczyt | ms, stabilizacja pozycji siłowników, postoju i przekazania. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.stationEdit[1].sensorStableMs`<br>`GVL_HMI.vijeo.stationActual[1].sensorStableMs` |
| Nadzór zatrzymania · edytor i odczyt | ms, zatrzymanie windy i zwłoka odwrócenia taśmy. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.stationEdit[1].stopDelayMs`<br>`GVL_HMI.vijeo.stationActual[1].stopDelayMs` |
| Nadzór przejazdu · edytor i odczyt | ms, przejazd, zwolnienie P4 i nadzór potwierdzenia P4. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.stationEdit[1].moveTimeoutMs`<br>`GVL_HMI.vijeo.stationActual[1].moveTimeoutMs` |
| Timeout pozycjonerów · edytor i odczyt | ms, wspólny próg V201/V202/V203. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.stationEdit[1].actuatorTimeoutMs`<br>`GVL_HMI.vijeo.stationActual[1].actuatorTimeoutMs` |
| Wolna prędkość · edytor i odczyt | Hz, wartość dodatnia. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.elevatorSpeedEdit.slowHz`<br>`GVL_HMI.vijeo.elevatorSpeedActual.slowHz` |
| Szybka prędkość · edytor i odczyt | Hz, od wolnej do zweryfikowanego maksimum napędu. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.elevatorSpeedEdit.fastHz`<br>`GVL_HMI.vijeo.elevatorSpeedActual.fastHz` |
| Rewizja edycji / aktywna · odczyty | Gdy wartości się różnią, wczytaj zestaw ponownie. Oba pola zapisuje PLC. | `GVL_HMI.vijeo.stationEditRevision[1]`<br>`GVL_HMI.vijeo.stationRevision[1]` |
| Zestaw zatwierdzony · lampka | Potwierdzenie konfiguracji zestawu. Bufor zachowuje flagę po Wczytaj. | `GVL_HMI.vijeo.stationActual[1].verified`<br>`GVL_HMI.vijeo.stationEdit[1].verified` |
| Wczytaj / Anuluj · przycisk | Wczytaj aktualne dane i rewizję, porzuć niezapisane zmiany. | `GVL_HMI.hmiV2.cmd.station2ParamReload.xReq` |
| Zastosuj · przycisk | PLC sprawdza komplet parametrów. Pokaż wynik i odśwież zestaw po przyjęciu. | `GVL_HMI.hmiV2.cmd.station2ParamApply.xReq` |
| Reset stanu ST.2 · przycisk | Po potwierdzeniu zażądaj uzgodnienia stanu. | `GVL_HMI.hmiV2.cmd.station2ResetState.xReq` |

Liczba blistrów w stosie oraz osobne progi Blistry/Pojemniki, próg zatrzymania w Hz i czasy dla każdego siłownika nie mają operatorskiego Apply w tym zestawie. W programie Blistry liczbę tacek w stosie ustala nastawa FANUC traysPerStack. Liczbę detali na wtrysk ustawia się na 125.

<a id="panel-103"></a>

### Panel 103 — ST.3 — STATUS · Rozładunek

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| B301 · lampka | Strefa wyjazdu z windy wolna. | `GVL_HMI.vijeo.value.ind_B301` |
| B302 / P5 · lampka | Obecność ładunku na pozycji P5. | `GVL_HMI.vijeo.value.ind_B302` |
| B303 / P6 · lampka | Obecność ładunku na pozycji P6. | `GVL_HMI.vijeo.value.ind_B303` |
| B304 / P7 · lampka | Obecność ładunku na pozycji P7. | `GVL_HMI.vijeo.value.ind_B304` |
| V301/V302 lewy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V301_HP`<br>`GVL_HMI.vijeo.value.ind_V301_WP` |
| V301/V302 prawy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V302_HP`<br>`GVL_HMI.vijeo.value.ind_V302_WP` |
| V301/V302 · komenda i ostrzeżenie | Oddziel końcową komendę pary od krańcówek. Osobny publiczny bit ruchu pary pozostaje otwarty. | `GVL_HMI.vijeo.unloadCoils[0].home`<br>`GVL_HMI.vijeo.unloadCoils[0].work`<br>`GVL_HMI.vijeo.alarms.entries[8].active` |
| V303/V304 lewy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V303_HP`<br>`GVL_HMI.vijeo.value.ind_V303_WP` |
| V303/V304 prawy · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V304_HP`<br>`GVL_HMI.vijeo.value.ind_V304_WP` |
| V303/V304 · komenda i ostrzeżenie | Oddziel końcową komendę pary od krańcówek. Osobny publiczny bit ruchu pary pozostaje otwarty. | `GVL_HMI.vijeo.unloadCoils[1].home`<br>`GVL_HMI.vijeo.unloadCoils[1].work`<br>`GVL_HMI.vijeo.alarms.entries[9].active` |
| Taśma · lampka komendy, kierunek, diagnostyka | Lampka wskazuje końcową komendę PLC. Kierunek (INT) wyświetl jako 1 naprzód, −1 wstecz, 0 postój. Przy wyłączonej komendzie pokaż brak komendy ruchu. Tekst obok grafiki. | `GVL_HMI.hmiStatus.xConvBottomRunning`<br>`GVL_HMI.hmiStatus.iConvBottomDirection`<br>`GVL_HMI.hmiStatus.sConvBottomDiagText` |
| Wydanie pojedyncze · trzy lampki | Gotowość do naciśnięcia przycisku lokalnego, wydawanie przez właściciela LOCAL (30), następnie „Odbierz stos lub pojemnik”. Kolejne wydanie po odbiorze przy B304. | `GVL_HMI.hmiV2.station.localReady`<br>`GVL_HMI.hmiV2.station.owner`<br>`GVL_Station.Transport.busy`<br>`GVL_HMI.hmiV2.station.waitingPickup` |
| Krok rozładunku / przyczyna / opróżnianie | Wyświetl stan E_Bottom567State, opis i oddzielny krok pełnego opróżniania. Koniec zlecenia obsługuje ekran 2. | `GVL_HMI.hmiStatus.uiBottomState`<br>`GVL_HMI.hmiStatus.sBottomDiagText`<br>`GVL_HMI.hmiV2.station.draining`<br>`GVL_HMI.hmiV2.station.drainStep` |

<a id="panel-113"></a>

### Panel 113 — ST.3 — MANUAL · Rozładunek

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Taśma rozładunku — na zewnątrz / do środka · dwa przyciski chwilowe | Kierunek wstecz udostępnij po potwierdzeniu napędu i okablowania. Licznik 3. | `GVL_HMI.vijeo.stationManual.positive[2]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[1]` |
| V301/V302 — WORK / HOME · dwa przyciski chwilowe | Wspólne żądanie pierwszej pary przy zatrzymanej taśmie. Licznik 13. | `GVL_HMI.vijeo.stationManual.positive[12]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[11]` |
| V303/V304 — WORK / HOME · dwa przyciski chwilowe | Wspólne żądanie drugiej pary przy zatrzymanej taśmie. Licznik 14. | `GVL_HMI.vijeo.stationManual.positive[13]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[12]` |
| Potwierdzenia i kierunek · lampki | Skopiuj z 103 krańcówki, B301–B304 i wskazania taśmy. | [B301–B304, stopery i taśma na 103](#panel-103) |
| Wymagane wznowienie · lampki | Po lokalnej usterce wskaż mechanizm wymagający usunięcia przyczyny, resetu i świeżego polecenia. | `GVL_HMI.vijeo.localRestartRequired[8]`<br>`GVL_HMI.vijeo.localRestartRequired[9]` |
| Blokada i właściciel transferu | Pokaż zatrzymanie taśmy, właściciela i operację. Pojedyncze wydanie inicjuje przycisk fizyczny. | `GVL_HMI.vijeo.beltsStopped[2]`<br>`GVL_HMI.hmiV2.station.owner`<br>`GVL_HMI.hmiV2.station.action_` |

<a id="panel-123"></a>

### Panel 123 — ST.3 — PARAMETRY · Rozładunek

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Stabilizacja czujników i stoperów · edytor i odczyt | ms, także przy odbiorze. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.stationEdit[2].sensorStableMs`<br>`GVL_HMI.vijeo.stationActual[2].sensorStableMs` |
| Zwłoka zatrzymania / zmiany kierunku · edytor i odczyt | ms, wspólna nastawa. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.stationEdit[2].stopDelayMs`<br>`GVL_HMI.vijeo.stationActual[2].stopDelayMs` |
| Timeout kroku transportu · edytor i odczyt | ms, nadzór aktywnego kroku. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.stationEdit[2].moveTimeoutMs`<br>`GVL_HMI.vijeo.stationActual[2].moveTimeoutMs` |
| Timeout stoperów · edytor i odczyt | ms, wspólny dla obu par. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.stationEdit[2].actuatorTimeoutMs`<br>`GVL_HMI.vijeo.stationActual[2].actuatorTimeoutMs` |
| Rewizja edycji / aktywna · odczyty | Gdy wartości się różnią, wczytaj zestaw ponownie. Oba pola zapisuje PLC. | `GVL_HMI.vijeo.stationEditRevision[2]`<br>`GVL_HMI.vijeo.stationRevision[2]` |
| Zestaw zatwierdzony · lampka | Potwierdzenie konfiguracji zestawu. Bufor zachowuje flagę po Wczytaj. | `GVL_HMI.vijeo.stationActual[2].verified`<br>`GVL_HMI.vijeo.stationEdit[2].verified` |
| Wczytaj / Anuluj · przycisk | Wczytaj aktualne dane i rewizję, porzuć niezapisane zmiany. | `GVL_HMI.hmiV2.cmd.station3ParamReload.xReq` |
| Zastosuj · przycisk | PLC sprawdza komplet parametrów. Pokaż wynik i odśwież zestaw po przyjęciu. | `GVL_HMI.hmiV2.cmd.station3ParamApply.xReq` |
| Reset stanu ST.3 · przycisk | Po potwierdzeniu zażądaj uzgodnienia stanu. | `GVL_HMI.hmiV2.cmd.station3ResetState.xReq` |

Oczekiwanie na zabranie stosu pokazuj jako komunikat procesu. Reset nie rozlicza wydania ani ładunku między czujnikami.

<a id="panel-104"></a>

### Panel 104 — ST.4 — STATUS · Magazyn przekładek

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| V401 · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V401_HP`<br>`GVL_HMI.vijeo.value.ind_V401_WP` |
| V402 · dwie lampki | Krańcówki HOME / WORK. Dla każdej lampki zastosuj jej własny bit valid. | `GVL_HMI.vijeo.value.ind_V402_HP`<br>`GVL_HMI.vijeo.value.ind_V402_WP` |
| Obie osłony otwarte / zamknięte · dwie lampki | HOME obu oznacza otwarte, WORK obu zamknięte. Obok schematu pokaż wynik potwierdzony po stabilizacji. | `GVL_HMI.hmiStatus.xStorageRobotSideOpen`<br>`GVL_HMI.hmiStatus.xStorageRobotSideClosed` |
| Strona robota / strona operatora · pozwolenia i dostęp | Po dwie lampki na stronę. Osobno pokaż żądanie operatora. | `GVL_HMI.hmiStatus.xStorageRobotPermission`<br>`GVL_HMI.hmiStatus.xStorageRobotAccessActive`<br>`GVL_HMI.hmiStatus.xStorageOperatorPermission`<br>`GVL_HMI.hmiStatus.xStorageOperatorAccessActive`<br>`GVL_HMI.hmiStatus.xStorageOperatorRequest` |
| B401 · lampka | Niski poziom przekładek. | `GVL_HMI.vijeo.value.ind_B401` |
| B402 · lampka | Magazyn pusty. | `GVL_HMI.vijeo.value.ind_B402` |
| Stan, ruch automatyczny i usterka · tekst i lampki | Kod E_StorageState, wspólny ruch, ostrzeżenie osłon i tekst diagnostyczny PLC. Brak osobnych publicznych bitów timeoutu lewej i prawej osłony. | `GVL_HMI.hmiStatus.uiStorageState`<br>`GVL_HMI.hmiStatus.xStorageBusy`<br>`GVL_HMI.vijeo.alarms.entries[10].active`<br>`GVL_HMI.hmiStatus.sStorageDiagText` |

<a id="panel-114"></a>

### Panel 114 — ST.4 — MANUAL · Osłony magazynu

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Otwórz obie osłony · przycisk chwilowy | Wymagane wspólne otwarcie do HOME. Kanały lewej i prawej mają oddzielne zezwolenia i liczniki 15/16. Pozostaw przycisk nieaktywny do zapewnienia przez PLC wspólnego dopuszczenia obu stron. | `GVL_HMI.vijeo.stationManual.negativeFrom2[13]`<br>`GVL_HMI.vijeo.stationManual.negativeFrom2[14]` |
| Zamknij obie osłony · przycisk chwilowy | Wymagane wspólne zamknięcie do WORK. Ten sam warunek dla obu stron. Dwa oddzielne zapisy panelu nie zapewniają wspólnego wykonania. | `GVL_HMI.vijeo.stationManual.positive[14]`<br>`GVL_HMI.vijeo.stationManual.positive[15]` |
| V401 / V402 · potwierdzenia i diagnostyka | Skopiuj z 104 osobne krańcówki, potwierdzenia obu osłon, pozwolenia, rezerwację i tekst usterki. | [V401/V402 i pozwolenia na 104](#panel-104) |
| Wyjścia osłon · cztery lampki | Końcowe komendy HOME/WORK obu osłon, wyłącznie podgląd. | `GVL_Robot.storageOut.Q_V401Home`<br>`GVL_Robot.storageOut.Q_V401Work`<br>`GVL_Robot.storageOut.Q_V402Home`<br>`GVL_Robot.storageOut.Q_V402Work` |

Projekt wymaga dwóch przycisków dla pary. PLC v4 obsługuje V401 i V402 niezależnie w Manual. Wspólna blokada i reakcja po odmowie jednej strony pozostają do uzgodnienia. Rygle pozostają poza sterowaniem z tej karty.

<a id="panel-124"></a>

### Panel 124 — ST.4 — PARAMETRY · Magazyn przekładek

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Stabilizacja obu osłon · edytor i odczyt | ms, czas potwierdzenia położenia. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.storageEdit.sensorStableMs`<br>`GVL_HMI.vijeo.storageActual.sensorStableMs` |
| Timeout ruchu obu osłon · edytor i odczyt | ms, jeden próg, osobny nadzór ruchu każdej osłony. Po lewej edycja, po prawej wartość przyjęta. | `GVL_HMI.vijeo.storageEdit.actuatorTimeoutMs`<br>`GVL_HMI.vijeo.storageActual.actuatorTimeoutMs` |
| Rewizja edycji / aktywna · odczyty | Gdy wartości się różnią, wczytaj zestaw ponownie. Oba pola zapisuje PLC. | `GVL_HMI.vijeo.stationEditRevision[3]`<br>`GVL_HMI.vijeo.stationRevision[3]` |
| Zestaw zatwierdzony · lampka | Potwierdzenie konfiguracji zestawu. Bufor zachowuje flagę po Wczytaj. | `GVL_HMI.vijeo.storageActual.verified`<br>`GVL_HMI.vijeo.storageEdit.verified` |
| Wczytaj / Anuluj · przycisk | Wczytaj aktualne dane i rewizję, porzuć niezapisane zmiany. | `GVL_HMI.hmiV2.cmd.station4ParamReload.xReq` |
| Zastosuj · przycisk | PLC sprawdza komplet parametrów. Pokaż wynik i odśwież zestaw po przyjęciu. | `GVL_HMI.hmiV2.cmd.station4ParamApply.xReq` |
| Reset stanu ST.4 · przycisk | Po potwierdzeniu zażądaj uzgodnienia stanu. | `GVL_HMI.hmiV2.cmd.station4ResetState.xReq` |

Wczytaj pobiera pełny zestaw ST.4 do bufora PLC. Przy Zastosuj sterownik zachowuje wczytane `stopDelayMs` i `moveTimeoutMs`. Te dwie wartości mają mieścić się w limitach i są konfigurowane przy uruchomieniu PLC. Wykonawca magazynu używa dwóch nastaw z tabeli.

<a id="panel-105"></a>

### Panel 105 — ST.5 — STATUS · Robot i chwytak

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Robot · lampki Auto / gotowy / pracuje / błąd / HOME | Stan zgłaszany przez FANUC. Ważność sesji i diagnostyki pokaż oddzielnie. Program uruchamia operator z robota. | `GVL_HMI.hmiStatus.xRobotAutoMode`<br>`GVL_HMI.hmiStatus.xRobotReady`<br>`GVL_HMI.hmiStatus.xRobotRunning`<br>`GVL_HMI.hmiStatus.xRobotFault`<br>`GVL_HMI.hmiStatus.xRobotHome`<br>`GVL_HMI.hmiV2.state.xRobotDataValid`<br>`GVL_Robot.Sts.diagnosticValid` |
| Program rzeczywisty / zgodność · tekst i lampka | Odczytaj kod z FANUC i porównaj lokalnie z programem zlecenia przy ważnych danych. 0 brak/nieznany, 1 Pojemniki, 2 Blistry. | `GVL_Robot.Rx.production_program`<br>`GVL_HMI.hmiV2.actual.uiProgram` |
| Krok / faza / oczekiwanie / kod błędu · pola tekstowe | Wyświetl numer kroku w kontekście wykonanego programu. WaitCode 0 brak, 10 synchronizacja, 20 pozwolenie, 30 IMM, 40 siłownik, 50 próżnia, 60 obszar, 70 ACK, 80 operator. Dla pozostałych wyświetl kod. | `GVL_HMI.hmiV2.state.uiRobotStep`<br>`GVL_HMI.hmiV2.state.uiRobotPhase`<br>`GVL_HMI.hmiV2.state.uiRobotWaitCode`<br>`GVL_HMI.hmiV2.state.uiRobotFaultCode` |
| Kończenie operacji · lampki i licznik | Pokaż zatrzymywanie, liczbę nierozliczonych wtrysków i potwierdzenie rozliczenia operacji. | `GVL_Robot.Sts.order.stopping`<br>`GVL_HMI.hmiV2.state.uiUnsettled`<br>`GVL_HMI.hmiV2.state.xOpsSettled` |
| V501–V505 · pięć wierszy | i=1 pneumatyczna oś 7 (V501), i=2…5 siłowniki V502…V505. Kolumny HOME, WORK, ruch, ważność, usterka i kod. | `GVL_HMI.vijeo.cylinders[i-1].atHome`<br>`GVL_HMI.vijeo.cylinders[i-1].atWork`<br>`GVL_HMI.vijeo.cylinders[i-1].busy`<br>`GVL_HMI.vijeo.cylinders[i-1].valid`<br>`GVL_HMI.vijeo.cylinders[i-1].fault`<br>`GVL_HMI.vijeo.cylinders[i-1].faultCode` |
| Próżnia V509–V513 · pięć wierszy | i=1…5 w kolejności V509…V513. Kolumny komenda ssania, osiągnięta próżnia, ważność, komenda przedmuchu, alarm i kod. Przy braku zatwierdzonego sprzężenia pokaż „Brak danych”. | `GVL_HMI.vijeo.vacuum[i-1].hold`<br>`GVL_HMI.vijeo.vacuum[i-1].ok`<br>`GVL_HMI.vijeo.vacuum[i-1].valid`<br>`GVL_HMI.vijeo.vacuum[i-1].blow`<br>`GVL_HMI.vijeo.vacuum[i-1].fault`<br>`GVL_HMI.vijeo.vacuum[i-1].faultCode` |
| Dobre / próbki / odrzuty · liczniki detali | Trzy odczyty UDINT w sztukach. Pokaż osobno dobre detale, próbki i odrzuty według rozliczonych zdarzeń. | `GVL_HMI.hmiV2.state.udiGood`<br>`GVL_HMI.hmiV2.state.udiSamples`<br>`GVL_HMI.hmiV2.state.udiRejects` |
| Blistry / ukończone jednostki · liczniki | Blistry w kontekście stosu. Licznik ukończonych jednostek podpisz według produkcji. Stosy i pojemniki korzystają z tego samego licznika kontekstu modulo 65536. Nie sumuj tych dwóch wskazań. | `GVL_HMI.hmiStatus.uiTraysDone`<br>`GVL_HMI.hmiStatus.uiStacksDone`<br>`GVL_HMI.hmiStatus.uiBoxesDone`<br>`GVL_HMI.hmiV2.state.uiProduction` |
| Zażądaj próbek · przycisk | Zgłoś pobranie próbek. ACK dotyczy żądania w PLC, zakończenie rozlicza zdarzenie robota. | `GVL_HMI.hmiV2.cmd.samples.xReq` |
| Wtryskarka / EUROMAP · przycisk | Otwórz panel 201. | Lokalnie w Vijeo |

Opisy kroków i kodów według programu. [Blistry](../ROBOT/TRAY/README.md) · [Pojemniki](../ROBOT/BOX/README.md).

<a id="panel-115"></a>

### Panel 115 — ST.5 — MANUAL · Chwytak

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Zezwolenie ręczne · lampki | Wymagane Manual, wyłączona praca z robotem, ważne HOME, przekazany chwytak i wolne obszary, bez trwającego transferu. Skopiuj aktualne ID sesji do pola udiSessionId gałęzi manual. | `GVL_HMI.hmiV2.state.uiMode`<br>`GVL_HMI.hmiV2.state.xWorkWithRobot`<br>`GVL_HMI.hmiV2.state.xRobotHomeValid`<br>`GVL_Robot.Plant.manualGripperHandover`<br>`GVL_HMI.vijeo.manual.udiSessionId` |
| V501 oś 7 — HOME / WORK | Dwa przyciski, kanał 1. Na nacisk zgłoś jeden kierunek, odświeżaj licznik podczas trzymania, na zwolnienie wycofaj żądanie. PLC może zachować przyjęty cel. | `GVL_HMI.vijeo.manual.cylHome[0]`<br>`GVL_HMI.vijeo.manual.cylWork[0]`<br>`GVL_HMI.vijeo.manual.holdCounter[0]` |
| V502 siłownik 1 — HOME / WORK | Dwa przyciski, wiersz 2. Na nacisk zgłoś jeden kierunek, odświeżaj licznik podczas trzymania, na zwolnienie wycofaj żądanie. PLC może zachować przyjęty cel. | `GVL_HMI.vijeo.manual.cylHome[1]`<br>`GVL_HMI.vijeo.manual.cylWork[1]`<br>`GVL_HMI.vijeo.manual.holdCounter[1]` |
| V503 siłownik 2 — HOME / WORK | Dwa przyciski, wiersz 3. Na nacisk zgłoś jeden kierunek, odświeżaj licznik podczas trzymania, na zwolnienie wycofaj żądanie. PLC może zachować przyjęty cel. | `GVL_HMI.vijeo.manual.cylHome[2]`<br>`GVL_HMI.vijeo.manual.cylWork[2]`<br>`GVL_HMI.vijeo.manual.holdCounter[2]` |
| V504 siłownik 3 — HOME / WORK | Dwa przyciski, wiersz 4. Na nacisk zgłoś jeden kierunek, odświeżaj licznik podczas trzymania, na zwolnienie wycofaj żądanie. PLC może zachować przyjęty cel. | `GVL_HMI.vijeo.manual.cylHome[3]`<br>`GVL_HMI.vijeo.manual.cylWork[3]`<br>`GVL_HMI.vijeo.manual.holdCounter[3]` |
| V505 siłownik 4 — HOME / WORK | Dwa przyciski, wiersz 5. Na nacisk zgłoś jeden kierunek, odświeżaj licznik podczas trzymania, na zwolnienie wycofaj żądanie. PLC może zachować przyjęty cel. | `GVL_HMI.vijeo.manual.cylHome[4]`<br>`GVL_HMI.vijeo.manual.cylWork[4]`<br>`GVL_HMI.vijeo.manual.holdCounter[4]` |
| V509 obwód 1 — Załącz / Wyłącz / Przedmuch | Trzy przyciski. Załącz ustawia vacHold=1, Wyłącz vacHold=0. Oba zgłaszają vacValid. Przedmuch zgłasza jawne wyłączenie ssania i blowReq. Licznik 6 obsługuje ten obwód. | `GVL_HMI.vijeo.manual.vacHold[0]`<br>`GVL_HMI.vijeo.manual.vacValid[0]`<br>`GVL_HMI.vijeo.manual.blowReq[0]`<br>`GVL_HMI.vijeo.manual.holdCounter[5]` |
| V510 obwód 2 — Załącz / Wyłącz / Przedmuch | Trzy przyciski. Załącz ustawia vacHold=1, Wyłącz vacHold=0. Oba zgłaszają vacValid. Przedmuch zgłasza jawne wyłączenie ssania i blowReq. Licznik 7 obsługuje ten obwód. | `GVL_HMI.vijeo.manual.vacHold[1]`<br>`GVL_HMI.vijeo.manual.vacValid[1]`<br>`GVL_HMI.vijeo.manual.blowReq[1]`<br>`GVL_HMI.vijeo.manual.holdCounter[6]` |
| V511 obwód 3 — Załącz / Wyłącz / Przedmuch | Trzy przyciski. Załącz ustawia vacHold=1, Wyłącz vacHold=0. Oba zgłaszają vacValid. Przedmuch zgłasza jawne wyłączenie ssania i blowReq. Licznik 8 obsługuje ten obwód. | `GVL_HMI.vijeo.manual.vacHold[2]`<br>`GVL_HMI.vijeo.manual.vacValid[2]`<br>`GVL_HMI.vijeo.manual.blowReq[2]`<br>`GVL_HMI.vijeo.manual.holdCounter[7]` |
| V512 obwód 4 — Załącz / Wyłącz / Przedmuch | Trzy przyciski. Załącz ustawia vacHold=1, Wyłącz vacHold=0. Oba zgłaszają vacValid. Przedmuch zgłasza jawne wyłączenie ssania i blowReq. Licznik 9 obsługuje ten obwód. | `GVL_HMI.vijeo.manual.vacHold[3]`<br>`GVL_HMI.vijeo.manual.vacValid[3]`<br>`GVL_HMI.vijeo.manual.blowReq[3]`<br>`GVL_HMI.vijeo.manual.holdCounter[8]` |
| V513 obwód 5 — Załącz / Wyłącz / Przedmuch | Trzy przyciski. Załącz ustawia vacHold=1, Wyłącz vacHold=0. Oba zgłaszają vacValid. Przedmuch zgłasza jawne wyłączenie ssania i blowReq. Licznik 10 obsługuje ten obwód. | `GVL_HMI.vijeo.manual.vacHold[4]`<br>`GVL_HMI.vijeo.manual.vacValid[4]`<br>`GVL_HMI.vijeo.manual.blowReq[4]`<br>`GVL_HMI.vijeo.manual.holdCounter[9]` |
| Przyjęcie pozycji / potwierdzenia · lampki | Dla i=1…5 pokaż przyjęcie celu, następnie krańcówkę i ważność jak na 105. Kod reason opisuje odmowę. | `GVL_HMI.vijeo.cylinders[i-1].acceptedHome`<br>`GVL_HMI.vijeo.cylinders[i-1].acceptedWork`<br>`GVL_HMI.vijeo.cylinders[i-1].reason` |
| Przyjęcie próżni / wynik przedmuchu · lampki i kod | Użyj potwierdzeń z 105. Jedno żądanie przedmuchu na nacisk. PLC kończy przyjęty impuls. Po blowAck odczytaj blowResult (1 wykonano, 2 odmowa, 3 błąd) i powróć do neutralnego żądania przed następnym. | `GVL_HMI.vijeo.vacuum[i-1].accepted`<br>`GVL_HMI.vijeo.vacuum[i-1].reason`<br>`GVL_HMI.vijeo.vacuum[i-1].blowAck`<br>`GVL_HMI.vijeo.vacuum[i-1].blowResult` |
| Pozwolenia · wskaźniki dla obwodu | Pokaż zezwolenie na ssanie, zwolnienie i przedmuch. Wstrzymaj aktywację przy braku potwierdzenia pneumatyki GAP-03/08. | `GVL_HMI.vijeo.vacuumInput[i-1].onAllowed`<br>`GVL_HMI.vijeo.vacuumInput[i-1].offAllowed`<br>`GVL_HMI.vijeo.vacuumInput[i-1].blowAllowed`<br>`GVL_HMI.vijeo.vacuumInput[i-1].blowConfigured` |

Cylindry i próżnia mają osobny protokół od ST.1–ST.4. PLC wymaga neutralnego wejścia i zmiany licznika danego urządzenia przy żądaniu. Na zwolnienie wycofaj bity cylHome/cylWork, vacValid i blowReq przypisane do gestu. Wyjście z karty lub zanik łącza kończy nadawanie. Przedmuch wymaga zgody na zwolnienie i przedmuch oraz zweryfikowanego kanału. Dla przedmuchu wyślij spójny zestaw vacHold=0, vacValid=1 i blowReq=1. Zanik nacisku na „Załącz” sam nie wydaje polecenia zwolnienia detalu.

<a id="panel-125"></a>

### Panel 125 — ST.5 — PARAMETRY · Detale na wtrysk

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Detale na wtrysk · edytor i odczyt | UINT w sztukach, wartość dodatnia. Kandydat i przyjęta wartość obok siebie. Ilość jest niezależna od liczby obwodów próżni. | `GVL_HMI.hmiV2.edit.uiBatchCount`<br>`GVL_HMI.hmiV2.actual.uiBatchCount` |
| Zastosuj ilość · przycisk | Wymaga zamkniętego zlecenia, potwierdzonego postoju stacji i chwytaka, rozliczonych operacji oraz braku recovery. Rozpoczęte partie zachowują przypisaną ilość. | `GVL_HMI.hmiV2.cmd.station5ParamApply.xReq` |
| Wczytaj / Anuluj · przycisk | Wczytaj aktywną ilość. PLC przywraca także aktywny program w buforze wyboru na ekranie 2. | `GVL_HMI.hmiV2.cmd.station5ParamReload.xReq` |
| Reset stanu ST.5 · przycisk | Użyj lokalnego potwierdzenia i procedury uzgodnienia. | `GVL_HMI.hmiV2.cmd.station5ResetState.xReq` |
| Czasy chwytaka · podgląd serwisowy | Odczyty UDINT w ms kolejno stabilizacja, ruch, osiągnięcie próżni, czas przedmuchu i potwierdzenie zwolnienia. Wyłącznie odczyt. | `GVL_HMI.vijeo.gripperStableMs`<br>`GVL_HMI.vijeo.gripperMotionTimeoutMs`<br>`GVL_HMI.vijeo.gripperVacuumTimeoutMs`<br>`GVL_HMI.vijeo.gripperBlowMs`<br>`GVL_HMI.vijeo.gripperReleaseTimeoutMs` |
| Indywidualne progi V501–V505, próżni i oczekiwania programu | Brak bufora edycji i zatwierdzania tych czasów z panelu. Geometria i stos blistrów należą do nastaw programu FANUC. | Otwarte · brak powiązania operatorskiego |

<a id="panel-201"></a>

### Panel 201 — WTRYSKARKA / EUROMAP

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| Podgląd / Manual · zakładki lokalne | Zachowaj uiActivePanel=201. Przy przejściu z Manual na Podgląd zwolnij wszystkie żądania i zatrzymaj ich liczniki. | Lokalnie w Vijeo |
| KF101 · lampka | Odrzut. | `GVL_HMI.vijeo.value.ind_KF101` |
| KF102 · lampka | Forma zamknięta. | `GVL_HMI.vijeo.value.ind_KF102` |
| KF103 · lampka | Forma otwarta. | `GVL_HMI.vijeo.value.ind_KF103` |
| KF104 · lampka | Forma w pozycji pośredniej. | `GVL_HMI.vijeo.value.ind_KF104` |
| KF105 · lampka | Współpraca z robotem. | `GVL_HMI.vijeo.value.ind_KF105` |
| KF106 · lampka | Wyrzutnik z tyłu. | `GVL_HMI.vijeo.value.ind_KF106` |
| KF107 · lampka | Wyrzutnik z przodu. | `GVL_HMI.vijeo.value.ind_KF107` |
| KF108 · lampka | Rdzeń 1 w pozycji 1. | `GVL_HMI.vijeo.value.ind_KF108` |
| KF109 · lampka | Rdzeń 1 w pozycji 2. | `GVL_HMI.vijeo.value.ind_KF109` |
| KF110 · lampka | Rdzeń 2 w pozycji 1. | `GVL_HMI.vijeo.value.ind_KF110` |
| KF111 · lampka | Rdzeń 2 w pozycji 2. | `GVL_HMI.vijeo.value.ind_KF111` |
| KF202 · Zezwól na zamknięcie formy | Jeden przycisk chwilowy i dwie lampki. Kolejno żądanie HMI podczas trzymania (licznik 1), żądanie FANUC i końcowe pozwolenie procesowe PLC. Zwolnienie wycofuje żądanie HMI. | `GVL_HMI.vijeo.immManual.positive[0]`<br>`GVL_Robot.Rx.imm_req_mouldClose`<br>`GVL_Robot.Sts.imm.mouldClose` |
| KF203 · Zezwól na pełne otwarcie formy | Jeden przycisk chwilowy i dwie lampki. Kolejno żądanie HMI podczas trzymania (licznik 2), żądanie FANUC i końcowe pozwolenie procesowe PLC. Zwolnienie wycofuje żądanie HMI. | `GVL_HMI.vijeo.immManual.positive[1]`<br>`GVL_Robot.Rx.imm_req_mouldFullOpen`<br>`GVL_Robot.Sts.imm.mouldFullOpen` |
| KF205 · Zezwól na wyrzutnik w tył | Jeden przycisk chwilowy i dwie lampki. Kolejno żądanie HMI podczas trzymania (licznik 3), żądanie FANUC i końcowe pozwolenie procesowe PLC. Zwolnienie wycofuje żądanie HMI. | `GVL_HMI.vijeo.immManual.positive[2]`<br>`GVL_Robot.Rx.imm_req_ejectorBack`<br>`GVL_Robot.Sts.imm.ejectorBack` |
| KF206 · Zezwól na wyrzutnik w przód | Jeden przycisk chwilowy i dwie lampki. Kolejno żądanie HMI podczas trzymania (licznik 4), żądanie FANUC i końcowe pozwolenie procesowe PLC. Zwolnienie wycofuje żądanie HMI. | `GVL_HMI.vijeo.immManual.positive[3]`<br>`GVL_Robot.Rx.imm_req_ejectorForward`<br>`GVL_Robot.Sts.imm.ejectorForward` |
| Warunki trybu ręcznego · lampki | Manual, aktualne HOME, współpraca wyłączona, postój i brak nierozliczonych wtrysków. Zezwolenia i ich blokady ocenia PLC. Pokaż ważność oraz kod przyczyny. | `GVL_HMI.hmiV2.state.uiMode`<br>`GVL_HMI.hmiV2.state.xRobotHomeValid`<br>`GVL_HMI.hmiV2.state.xWorkWithRobot`<br>`GVL_HMI.hmiV2.state.uiUnsettled`<br>`GVL_Robot.Sts.imm.valid`<br>`GVL_Robot.Sts.imm.reason` |
| Współpraca / cykl · wskaźniki | Wskaż opcję współpracy (KF204 logicznie), pozwolenie nowego cyklu, znany stan wtrysku, ostatni identyfikator i rozliczenie. Żądanie i końcowe zezwolenie są odrębne od wejść potwierdzenia Krauss. | `GVL_Robot.Sts.imm.withRobot`<br>`GVL_Robot.Sts.imm.newCyclePermit`<br>`GVL_Robot.Tx.imm_cycleKnown`<br>`GVL_Robot.Tx.imm_cycleId`<br>`GVL_Robot.Tx.imm_settled` |
| KF201 · obszar formy wolny · lampka | Tylko podgląd. W obecnym adapterze wartość i ważność tego wyjścia pozostają FALSE, pokaż „Brak danych”. | `GVL_HMI.vijeo.value.ctrl_KF201` |
| KF207–KF210 · pozwolenia rdzeni | Cztery wyjścia diagnostyczne, obecnie nieważne. PLC v4 nie obsługuje dla nich żądań ręcznych. | `GVL_HMI.vijeo.value.ctrl_KF207`<br>`GVL_HMI.vijeo.value.ctrl_KF208`<br>`GVL_HMI.vijeo.value.ctrl_KF209`<br>`GVL_HMI.vijeo.value.ctrl_KF210` |

Cztery żądania ręczne korzystają tylko z dodatnich kanałów 1–4. Wyłącz je do potwierdzenia interfejsu Krauss i blokad (GAP-05). PLC wymaga pełnego otwarcia dla zezwoleń wyrzutnika i odrzuca jednoczesne kierunki pary. Surowe wyjścia KF201–KF211 w `GVL_HMI.vijeo.value` mają niepotwierdzone mapowanie. Sygnalizacja safety, KF403, KF501 i obejście STO należą wyłącznie do diagnostyki.

<a id="panel-301"></a>

### Panel 301 — DIAGNOSTYKA

| Obiekt w Vijeo | Działanie i wskazanie | Zmienna lub akcja |
| --- | --- | --- |
| PLC/HMI · pola liczbowe i opis | Wersja kontraktu (4), stan sesji (0 nieuzbrojona, 20 uzbrojona), ID sesji i tekst PLC. Pokaż również oba liczniki heartbeat i aktywny panel ze wspólnego szablonu. | `GVL_HMI.hmiV2.link.uiContractVersion`<br>`GVL_HMI.hmiV2.link.uiSessionState`<br>`GVL_HMI.hmiV2.link.udiSessionId`<br>`GVL_HMI.hmiV2.link.sDiag` |
| FANUC · łącze, obraz, sesja i diagnostyka | Pokaż stan skanera, świeżość obrazu, aktywną sesję, ważność diagnostyki i tekst/kod. Wire FANUC v2 ma odrębną wersję od HMI v4. | `GVL_Robot.ScannerHealthy`<br>`GVL_Robot.ImageFresh`<br>`GVL_Robot.Sts.session`<br>`GVL_Robot.Sts.diagnosticValid`<br>`GVL_Robot.Sts.diag.code`<br>`GVL_Robot.Sts.diag.text`<br>`GVL_Robot.Rx.link_version` |
| Festo AP i ATV320 · wskaźniki | Bramka, świeżość danych, ważność całej stacji i przyczyna. Dla napędu komunikacja i ważność pomiaru Hz osobno. | `GVL_Station.Inputs.gatewayHealthy`<br>`GVL_Station.Inputs.imageFresh`<br>`GVL_HMI.hmiIo.dataValid`<br>`GVL_Station.Io.reason`<br>`GVL_HMI.hmiStatus.xVfdCommOk`<br>`GVL_Station.DriveFrequencyValid` |
| Moduły Festo · 12 wierszy | i=1…12 kolejno BAT100, BAT101, BAT200, BAT201, BAT202, BAT203, BAT204, BAT205, BAT300, BAT301, BAT400, BAT401. Lampka ważności każdego modułu. Do opisu użyj j=40+i (41…52), np. BAT100 odpowiada rekordowi 41. Natywny kod producenta i osobna ważność IN/OUT nie mają pól w tym interfejsie. | `GVL_HMI.vijeo.modules[i-1]`<br>`GVL_HMI.vijeo.alarms.entries[j-1].text` |
| I/O · przewijana tabela i lokalny wybór grupy | ST.1–ST.5, EUROMAP i przyciski fizyczne. Utwórz wiersz dla każdej z 166 pozycji arkusza. ID, opis, IN/OUT i źródło są statyczne. Każdy z 159 krótkich aliasów N daje dwa odczyty BOOL. Powtórzony sygnał używa tej samej pary tagów. | `GVL_HMI.vijeo.value.N`<br>`GVL_HMI.vijeo.valid.N`. [Pełna lista N, urządzeń i etykiet](hmi-io-diagnostics.md) |
| Uzgodnienie stacji · model i pola statusu | Pokaż wymagane recovery, nieuzgodniony materiał, potwierdzenie pustej stacji oraz nierozliczone wtryski. Rozwiń podgląd P1–P7 z modelu i pozycji czujników. | `GVL_HMI.hmiV2.state.xRecoveryRequired`<br>`GVL_HMI.hmiV2.station.materialKnown`<br>`GVL_HMI.hmiV2.station.emptyConfirmed`<br>`GVL_HMI.hmiV2.state.uiUnsettled`<br>`GVL_HMI.vijeo.stationOccupied[i-1]`<br>`GVL_HMI.vijeo.occupied[i-1]`<br>`GVL_HMI.vijeo.positionsValid[i-1]` |
| Transport · operacja i przyczyna | Właściciel 0 brak, 10 produkcja, 20 opróżnianie, 30 lokalne wydanie, 40 Manual. Operacja 0 brak, 10 winda góra, 20 winda dół, 30 podanie, 40 rozładunek, 50 przesunięcie, 60 wydanie. Pokaż ID i kod blokady. | `GVL_HMI.hmiV2.station.owner`<br>`GVL_HMI.hmiV2.station.action_`<br>`GVL_Station.Transport.operationId`<br>`GVL_Station.Transport.reason`<br>`GVL_HMI.hmiV2.station.reason` |
| Potwierdź uzgodniony stan · przycisk | Po uzgodnieniu rzeczywistych ładunków, robota i wtrysków potwierdź proponowany kontekst. Pokaż wynik i aktualny stan recovery. | `GVL_HMI.hmiV2.cmd.recoveryConfirm.xReq` |
| Nowy pusty kontekst · serwis · przycisk | Oddziel od zwykłego resetu. Własne okno potwierdzenia objaśnia inicjalizację pustego kontekstu. Użycie wyłącznie po potwierdzeniu pustej stacji, pustego chwytaka i rozliczenia wtrysków. | `GVL_HMI.hmiV2.cmd.newEmptyContext.xReq` |

Numer wersji samego projektu Vijeo umieść jako lokalny tekst wydania. W tabeli diagnostycznej użyj etykiet „Komenda PLC”, „Wejście” oraz „Brak danych”. Rezerwy, obwody bezpieczeństwa i nieważne kanały mają wyłącznie podgląd.

### Symbole do importu w Vijeo

1. Przed zastosowaniem zmian w natywnym projekcie sprawdź stare wiązania ekranów, skryptów i alarmów. Użyj tabeli migracji poniżej oraz przypisań z kart stacji.
2. W Machine Expert zaktualizuj DUT i FB z `Modules/Vijeo` oraz `GVL_HMI`, `PRG_Main`, `ST_StationOutputs`, `ST_HmiStationStatus`, `ST_RobotHmiState`, `FB_StationController` i `FB_RobotController`. Usuń zbędne DUT `ST_HmiCommands` i `ST_HmiAlarm` po podmianie źródeł.
3. W **Symbol Configuration** zaznacz całą gałąź `GVL_HMI`. W `GVL_Robot` i `GVL_Station` wybierz 40 odczytów z [listy zmiennych](hmi-vijeo-symbols.txt). Pod `GVL_HMI` znajdują się wyłącznie cztery struktury z polami potrzebnymi wizualizacji.
4. W Vijeo zapis przypisz do pól `RW` z listy, w tym do `manual`, `stationManual`, `immManual` i edytowalnych nastaw. `verified` i rewizje służą do odczytu. Apply i Reload nadal korzystają z odpowiednich transakcji `hmiV2.cmd`.
5. Wykonaj **Generate Code**, wyeksportuj symbole i ponów import w Vijeo. Zresetuj lokalne żądania panelu i uzbrój nową sesję po przepięciu symboli.

Jeśli kompilator wymienia `hmiCmd`, `hmiAlarms` lub `hmiAlarmCount` jako symbole wciąż skonfigurowane do eksportu, usuń stare wpisy z **Symbol Configuration** i ponownie zaznacz cztery aktualne struktury `GVL_HMI`.

### Migracja wiązań po przycięciu GVL_HMI

Poniższa tabela dotyczy zmienionych ścieżek interfejsu zgodnego z Vijeo. Pozostałe ścieżki z listy eksportowej zachowują swoje nazwy.

| Poprzedni symbol | Nowy symbol |
|---|---|
| `GVL_HMI.vijeo.stationManual.negative[1]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[0]` |
| `GVL_HMI.vijeo.stationManual.negative[2]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[1]` |
| `GVL_HMI.vijeo.stationManual.negative[3]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[2]` |
| `GVL_HMI.vijeo.stationManual.negative[4]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[3]` |
| `GVL_HMI.vijeo.stationManual.negative[5]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[4]` |
| `GVL_HMI.vijeo.stationManual.negative[6]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[5]` |
| `GVL_HMI.vijeo.stationManual.negative[7]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[6]` |
| `GVL_HMI.vijeo.stationManual.negative[8]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[7]` |
| `GVL_HMI.vijeo.stationManual.negative[9]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[8]` |
| `GVL_HMI.vijeo.stationManual.negative[10]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[9]` |
| `GVL_HMI.vijeo.stationManual.negative[11]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[10]` |
| `GVL_HMI.vijeo.stationManual.negative[12]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[11]` |
| `GVL_HMI.vijeo.stationManual.negative[13]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[12]` |
| `GVL_HMI.vijeo.stationManual.negative[14]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[13]` |
| `GVL_HMI.vijeo.stationManual.negative[15]` | `GVL_HMI.vijeo.stationManual.negativeFrom2[14]` |
| `GVL_HMI.vijeo.stationEdit[1].slowHz` | `GVL_HMI.vijeo.elevatorSpeedEdit.slowHz` |
| `GVL_HMI.vijeo.stationEdit[1].fastHz` | `GVL_HMI.vijeo.elevatorSpeedEdit.fastHz` |
| `GVL_HMI.vijeo.stationEdit[3].verified` | `GVL_HMI.vijeo.storageEdit.verified` |
| `GVL_HMI.vijeo.stationEdit[3].sensorStableMs` | `GVL_HMI.vijeo.storageEdit.sensorStableMs` |
| `GVL_HMI.vijeo.stationEdit[3].actuatorTimeoutMs` | `GVL_HMI.vijeo.storageEdit.actuatorTimeoutMs` |
| `GVL_HMI.vijeo.stationActual[1].slowHz` | `GVL_HMI.vijeo.elevatorSpeedActual.slowHz` |
| `GVL_HMI.vijeo.stationActual[1].fastHz` | `GVL_HMI.vijeo.elevatorSpeedActual.fastHz` |
| `GVL_HMI.vijeo.stationActual[3].verified` | `GVL_HMI.vijeo.storageActual.verified` |
| `GVL_HMI.vijeo.stationActual[3].sensorStableMs` | `GVL_HMI.vijeo.storageActual.sensorStableMs` |
| `GVL_HMI.vijeo.stationActual[3].actuatorTimeoutMs` | `GVL_HMI.vijeo.storageActual.actuatorTimeoutMs` |
| `GVL_HMI.vijeo.appliedCoils[8].home` | `GVL_HMI.vijeo.unloadCoils[0].home` |
| `GVL_HMI.vijeo.appliedCoils[8].work` | `GVL_HMI.vijeo.unloadCoils[0].work` |
| `GVL_HMI.vijeo.appliedCoils[9].home` | `GVL_HMI.vijeo.unloadCoils[1].home` |
| `GVL_HMI.vijeo.appliedCoils[9].work` | `GVL_HMI.vijeo.unloadCoils[1].work` |
| `GVL_HMI.vijeo.areas[0].valid` | `GVL_HMI.vijeo.sourceArea.valid` |
| `GVL_HMI.vijeo.areas[0].ready` | `GVL_HMI.vijeo.sourceArea.ready` |
| `GVL_HMI.vijeo.areas[0].reserved` | `GVL_HMI.vijeo.sourceArea.reserved` |
| `GVL_HMI.vijeo.areas[1].reserved` | `GVL_HMI.vijeo.elevatorAreaReserved` |

Zapisany `plc_soft.project` zawiera nazwy 32 starych tagów `hmiCmd` oraz `hmiAlarmCount` w tablicy tekstów. Sprawdzenie nazw w archiwum nie rozstrzyga, czy aktualne obiekty Vijeo nadal ich używają. Jeśli stare wiązania są aktywne, dostosuj je przed uruchomieniem nowego projektu HMI.

| Stare wiązanie | Co zastosować w bieżącym projekcie |
|---|---|
| `hmiAlarmCount` oraz `hmiAlarms` | Licznik `GVL_HMI.vijeo.alarms.count` i rekordy z panelu 3. |
| `hmiCmd.xResetFaults`, `xManualMode` | Transakcje resetu i przełączania trybu z panelu 1. |
| `hmiCmd.xSelectModeTray`, `xSelectModeBox` | Wybór programu oraz transakcja otwarcia zlecenia z panelu 2. |
| `hmiCmd.xStartAuto`, `xStopAuto`, `xContiniue`, `xPauseAuto` | Użyj sekwencji otwarcia zlecenia, fizycznego START i STOP oraz wznowienia opisanych na panelach 1 i 2. Usuń stare przyciski zawierające bezpośredni bit. |
| `hmiCmd.xM*Fwd/Bwd`, `xConv*Fwd/Bwd`, `xElevUp/Down`, `xElevFast` | Skonfiguruj odpowiednie przyciski na ekranach 111–114 wg tabel, uwzględniając sesję i licznik danego kanału. Użyj wyłącznie kierunków udostępnionych dla tego urządzenia. |
| Stare pola `hmiStatus` poza listą eksportową | Stan i tryb bierz z `hmiV2.state`, zajętość z `vijeo.occupied` lub `vijeo.stationOccupied`, a potwierdzenia i usterki z odpowiednich kart stacji i mapy I/O. Usuń stare wskazania bez odpowiednika w bieżącym projekcie. |

### Import tekstów diagnostycznych

Pola tekstowe publikowane do Vijeo w statusie stacji, sesji HMI, odpowiedziach, pozwoleniach oraz diagnostyce alarmów i robota mają typ `STRING[80]`. Pierwotne `STRING[120]` przekraczały limit 100 znaków lub bajtów Vijeo. Po aktualizacji DUT przebuduj aplikację w Machine Expert, wykonaj **Export Symbols to Vijeo-Designer** i ponów import w panelu. Do pierwszej próby tekstu wybierz `GVL_HMI.hmiStatus.sElevDiagText`. [Limit zmiennej tekstowej Vijeo](https://www.se.com/ar/es/faqs/FA283025/).

## Sprawdzenie projektu w Vijeo

1. Zaimportuj symbole z właściwej aplikacji Machine Expert. Sprawdź typy BOOL, UINT, UDINT, INT ze znakiem, REAL, STRING i obsługę tablic. Czasy publikowane w `vijeo` mają jednostkę ms. Indeks w nawiasie zastąp liczbą podaną w wierszu. Do statusów nadaj dostęp tylko do odczytu. [Konfiguracja projektu i import symboli](../human-instructions.md).
2. Otwórz kolejno 20 ekranów. Potwierdź odczyt numeru aktywnego panelu, przejścia Wstecz, kolory braku danych i podpisy. Sprawdź zawijanie tekstów, polskie znaki, historię i rozdzielczość docelowego panelu.
3. Sprawdź żądanie przyjęte, odmowę, podwójne naciśnięcie i zerwanie łączności w trakcie ACK. Sprawdź każdy Manual po puszczeniu, zmianie strony, utracie łącza i wygaśnięciu licznika jednego urządzenia. Wznowienie wymaga nowego żądania.
4. Dla każdej stacji wykonaj Wczytaj, edycję, Anuluj i próbę zapisu z błędną rewizją lub wartością poza zakresem. Zweryfikuj warunki DEC-18 osobno dla ilości na wtrysk. Dla alarmu sprawdź wystąpienie, ACK, ustąpienie i Reset jako osobne zdarzenia. [Scenariusze prób HMI-01–HMI-12](hmi-vijeo-map.md#10-sprawdzenie-gotowego-projektu-hmi).

Wiązania sprawdzono na poziomie źródeł ST. Gotowość do uruchomienia wymaga eksportu z docelowego projektu, weryfikacji sprzętowej mapy I/O i prób runtime. [Integracja stacji](station-integration.md) · [Kontrakt HMI i parametry](station-plc-implementation.md) · [Pola historyczne do migracji](hmi-existing-variables.md).
