# Vijeo Designer — docelowa mapa ekranów i zmiennych

Stan: 2026-10-04. **Specyfikacja do implementacji, nie gotowy eksport symboli ani projekt Vijeo.** Wszystkie pola `GVL_HMI.hmiV2.…` oraz `GVL_HMI.hmiIo.…` w tej dokumentacji są **NOWE / PLANOWANE**. Nie dodano ich jeszcze do ST. Pełna lista obecnych 208 pól jest w [inwentaryzacji](hmi-existing-variables.md). Kolejność pracy i konfigurację narzędzia podaje [human-instructions](../human-instructions.md).

## 1. Konwencje i zakres

- **R** = HMI odczytuje PLC; **W** = HMI zapisuje żądanie/bufor PLC; **L** = lokalna zmienna panelu. Kierunek sieciowy nie jest kierunkiem fizycznego I/O.
- W tabelach podano symbole logiczne PLC. W Vijeo wybierz zaimportowany symbol wraz z rzeczywistym prefiksem aplikacji/equipment. Nie zamieniaj nazw na zgadywane %MW.
- Komendy są żądaniami; PLC może je odrzucić. Lampka stanu pokazuje potwierdzenie PLC, nie zapisany bit komendy.
- Poniższe numery paneli, kody, nazwy i protokół są propozycją projektową. Zatwierdzić i zamrozić je w kroku 1 planu. Nie udawać ich istnienia w projekcie bazowym.
- Dotychczasowe pola statusowe wolno wykorzystać po naprawieniu ich producenta i nadaniu wiarygodnej ważności. Żadnego starego hmiCmd nie podłączać równolegle jako obejścia nowego kontraktu.
- Nie ma tu przycisku startującego FANUC przez UOP ani nowego HMI Start automatu. Fizyczny Start/Stop pozostaje wejściem PLC. Otwarte przejścia z GAP-10 nie otrzymują domyślnej implementacji przez panel.

## 2. Wzorce obiektów Vijeo

### R — odczyt

Lampka BOOL lub animacja wielostanowa; numery jako Numeric Display, tekst jako String Display. Dla nieważnych danych nakładka „BRAK DANYCH”, wyłączona animacja gotowości i brak możliwości sterowania. Wyjście komendowe pokazuj jako „komenda aktywna”, nigdy jako „ruch potwierdzony”, jeśli nie ma rzeczywistego sprzężenia.

### T — jednorazowa transakcja z czterofazowym potwierdzeniem

Każdy klucz `K` wymieniony w tabelach komend rozwija się do poniższych **dokładnych pól**. Przykład: K=orderOpen oznacza `GVL_HMI.hmiV2.cmd.orderOpen.xReq`, nie zmienną o literalnej nazwie K.

| Symbol dla każdego K | Typ | Kierunek | Obiekt / sposób użycia |
|---|---|---|---|
| `GVL_HMI.hmiV2.cmd.K.udiSessionId` | UDINT | W | ID bieżącej sesji skopiowany z link.udiSessionId przed publikacją żądania |
| `GVL_HMI.hmiV2.cmd.K.udiRequestId` | UDINT | W | Numer nowej transakcji w danej sesji; nie powtarzać numeru dla kolejnego skutku |
| `GVL_HMI.hmiV2.rsp.K.udiSessionId` | UDINT | R | ID sesji, której dotyczy odpowiedź |
| `GVL_HMI.hmiV2.rsp.K.udiRequestId` | UDINT | R | Numer żądania, którego dotyczy odpowiedź |
| `GVL_HMI.hmiV2.cmd.K.xReq` | BOOL | W | Touch/naciśnięcie: uruchom procedurę T; ustawia TRUE raz dopiero po przygotowaniu ID. Bez krótkiego impulsu i Toggle. Release nie kasuje transakcji |
| `GVL_HMI.hmiV2.rsp.K.xAck` | BOOL | R | PLC ustawia po przyjęciu albo odrzuceniu; globalna obsługa panelu kasuje xReq dopiero po spójnym odczycie wyniku dla właściwego ID sesji i żądania |
| `GVL_HMI.hmiV2.rsp.K.uiResult` | UINT | R | 0=brak wyniku, 1=przyjęto, 2=odrzucono; dalsze przyczyny przez uiReason/sReason |
| `GVL_HMI.hmiV2.rsp.K.uiReason` | UINT | R | Kod przyczyny ostatniej odpowiedzi |
| `GVL_HMI.hmiV2.rsp.K.sReason` | STRING[120] | R | Komunikat po naciśnięciu; np. „Zakończ zatrzymanie” |
| `GVL_HMI.hmiV2.permit.K.xAllowed` | BOOL | R | Enable przycisku; PLC sprawdza warunki ponownie w chwili przyjęcia |
| `GVL_HMI.hmiV2.permit.K.sReason` | STRING[120] | R | Tekst obok nieaktywnego przycisku |

Przed ustawieniem xReq panel publikuje ID sesji i żądania, czeka na potwierdzony świeży odczyt tych pól z PLC i nie zmienia ich podczas wymiany. PLC akceptuje tylko bieżącą sesję i nowy numer; duplikat nie wywołuje ponownie skutku.

Kolejność: spoczynek xReq=0/xAck=0 → HMI xReq=1 → PLC jeden raz rozpatruje i utrzymuje ACK/wynik → HMI xReq=0 → PLC xAck=0. PLC utrzymuje nieruchomy snapshot odpowiedzi (ID sesji, ID żądania, wynik i przyczyna) aż do skasowania xReq. Po zobaczeniu ACK panel wykonuje świeży, spójny odczyt całego snapshotu i dopiero po zgodności obu ID pokazuje wynik oraz kasuje xReq. Sam odczyt ACK razem z cache'owanym uiResult nie wystarcza; odczyt dwóch kopii tego samego cache także nie jest weryfikacją. Sposób zagwarantowania takiego odczytu przez konkretny driver Vijeo (blok danych, mechanizm snapshotu/rewizji i sterowanie odświeżaniem) trzeba potwierdzić w GAP-07 przed aktywacją przycisków. Jeżeli driver nie zapewnia tej własności, adapter wymiany wymaga dostosowania i próby HMI-03. Wynik historyczny można zachować z jego ID, ale nie przedstawiać go jako wynik nowej transakcji. Ponowny przycisk jest nieaktywny, dopóki poprzednia wymiana nie wróciła do 0/0. **ACK=przyjęto nie oznacza zakończenia ruchu**; to pokazuje osobny status urządzenia.

Globalna obsługa ACK działa niezależnie od aktualnie otwartej strony. Nie resetuj xReq jednorazowej komendy w zdarzeniu zamknięcia strony przed poznaniem wyniku. Rozłączenie unieważnia sesję i wymaga uzgodnienia; utrzymane żądanie po restarcie nie może stać się nową komendą. Podwójne i wzajemnie sprzeczne żądania z tej samej grupy PLC odrzuca z powodem, nie kolejkuje do automatycznego wykonania. Dotyczy to również zapisu spoza panelu.

### J — ruch przytrzymywany

Touch: TRUE; Release: FALSE. Nie używać Toggle ani zatrzasku. Wyjście z Manual, zmiana strony, błąd lub utrata sesji usuwa autoryzację jogu w PLC, nawet gdy zapis Release nie dotrze. Po powrocie połączenia wymagane zwolnienie i nowe naciśnięcie.

PLC wymaga aktualnej sesji, zgodnego numeru otwartej strony Manual oraz dopuszczenia konkretnego kierunku. Runtime panelu ma odświeżać osobny licznik trzymania dla każdego klucza K, `GVL_HMI.hmiV2.holdCounter.K` UINT/W, wyłącznie podczas rzeczywistego trzymania aktywnego przycisku; nie wystarczy globalny heartbeat ani licznik wspólny dla wszystkich jogów. Świeżość holdCounter.elevBeltFwd nigdy nie przedłuża ważności elevUp. PLC wymaga osobnego nowego naciśnięcia i świeżości dla każdego K. Jeżeli dana wersja Vijeo nie pozwala wiarygodnie odróżnić trzymania od zapamiętanego bitu, ten wariant sterowania trzeba rozwiązać przed uruchomieniem, a nie zastąpić wiecznym TRUE.

### P — parametry

Numeric Input zapisuje tylko bufor edit. **Zapisz** uruchamia transakcję paramApply; PLC sprawdza kompletność, zakresy, zależności i możliwość zastosowania, następnie aktualizuje actual i wersję. **Anuluj** uruchamia paramReload: PLC kopiuje actual do edit.

Zmiana wartości w polu nie zmienia pracy urządzenia. Panel nie wysyła swoich domyślnych zer do PLC przy starcie. Przed Apply zakończ transfer wszystkich pól i porównaj odczyt bufora z lokalnie zatwierdzonym zestawem; nie zakładaj atomowego zapisu wielu tagów. W czasie transakcji zablokuj edycję i następny Apply. PLC utrwala zaakceptowany snapshot; odrzucone wartości nie częściowo zmieniają konfiguracji.

## 3. Sesja, typy i dane ogólne

Wymienione pola sesji i ich obsługa są warunkiem uruchomienia W/J, a nie dodatkową opcją ekranu.

| Pełny symbol | Typ / kierunek | Element lub działanie |
|---|---|---|
| `GVL_HMI.hmiV2.link.uiContractVersion` | UINT / R | DIAG: wersja interfejsu; panel porównuje z obsługiwaną wersją |
| `GVL_HMI.hmiV2.link.uiPlcHeartbeat` | UINT / R | Zmieniający się licznik PLC; panel nadzoruje świeżość niezależnie od ostatniego BOOL |
| `GVL_HMI.hmiV2.link.uiHmiHeartbeat` | UINT / W | Licznik cykliczny panelu; zawijanie UINT dozwolone; PLC sprawdza zmianę, nie wartość >0 |
| `GVL_HMI.hmiV2.link.uiActivePanel` | UINT / W | Numer rzeczywiście otwartej strony; nie pole edytowane przez operatora |
| `GVL_HMI.hmiV2.link.xArmReq` | BOOL / W | Żądanie ustanowienia sesji po wyzerowaniu wszystkich req/jog i sprawdzeniu wersji |
| `GVL_HMI.hmiV2.link.udiSessionId` | UDINT / R | ID sesji nadawane przez PLC; nie może powtarzać starej generacji po restarcie |
| `GVL_HMI.hmiV2.link.xArmed` | BOOL / R | PLC potwierdza sesję po aktualnym heartbeat i neutralnych żądaniach |
| `GVL_HMI.hmiV2.link.xDataValid` | BOOL / R | Dane procesu przygotowane; panel dodatkowo wymaga własnej poprawnej komunikacji/heartbeat |
| `GVL_HMI.hmiV2.link.uiSessionState` | UINT / R | 0=brak sesji, 10=uzgadnianie, 20=aktywna, 90=błąd |
| `GVL_HMI.hmiV2.link.sDiag` | STRING[120] / R | DIAG: powód odmowy lub zerwania sesji |

Wygaszenie heartbeat/reset PLC/panelu/niezgodność wersji dezaktywuje xArmed. Nie wolno uzbroić sesji, dopóki pozostało żądanie ruchu lub nierozliczona stara wymiana. PLC wymaga nowej sekwencji xArmReq=0→1 po neutralizacji, a po jej zakończeniu HMI opuszcza xArmReq. Mechanizm generowania niepowtarzanej generacji po restarcie oraz postępowanie przy wyczerpaniu numerów zatwierdzić z retencją w GAP-11; nie zerować licznika do używanego wcześniej ID. Wznowienie z opóźnionymi telegramami starej sesji musi kończyć się ich odrzuceniem.

Czasy heartbeat i timeoutów ustalić według zmierzonej komunikacji oraz wymaganej reakcji; nie dostarcza ich obecny projekt. Wygaszenie sesji blokuje nowe komendy i usuwa autoryzację jogu; polityka zatrzymania pozostałych cykli/utrzymania ładunku wynika z GAP-08/12.

Dla parametrów TIME interfejs używa UDINT w milisekundach; PLC sprawdza limit przed konwersją do TIME. W Vijeo potwierdź obsługę 32-bit unsigned przez wybrany driver. UINT wyświetlaj bez znaku, INT ze znakiem, REAL jako Float; nie konwertuj danych przez napis. Dla czasu można pokazać sekundy z przeliczeniem 1000 ms = 1 s, ale symbol i magazyn danych nadal mają jawne ms. Diagnostyka STRING[120] wymaga sprawdzenia długości, polskich znaków i zawijania.

## 4. HOME i Zlecenie

| Symbol stanu — prefiks `GVL_HMI.hmiV2.state.` | Typ / kierunek | Panel / element |
|---|---|---|
| `uiMode` | UINT / R | HOME: 0=nieustalony, 10=Manual, 20=Auto; rzeczywiście przyjęty tryb |
| `uiProduction` | UINT / R | ZLECENIE: 0=brak, 10=Pojemniki, 20=Blistry |
| `uiOrderState` | UINT / R | 0=zamknięte, 10=otwarte, 20=kończenie, 30=opróżnianie, 90=odzyskiwanie |
| `uiExecutionState` | UINT / R | 0=postój, 10=gotowy, 20=praca, 30=zatrzymywanie, 40=zatrzymany, 50=opróżnianie, 60=czeka na odbiór, 90=odzyskiwanie |
| `xWorkWithRobot` | BOOL / R | HOME: potwierdzona opcja współpracy; nie bit gotowości ani robot HOME |
| `xRobotHomeValid` | BOOL / R | Aktualne HOME; nieważność = blokada odpowiednich komend |
| `xCanPhysicalStart` | BOOL / R | Lampka „Gotowy na fizyczny START”; brak przycisku zapisującego ten bit |
| `sStartBlockReason` | STRING[120] / R | Powód blokady fizycznego Start |
| `xOpsSettled` | BOOL / R | Zakończone/rozliczone rozpoczęte operacje IMM/robot/transfer |
| `xStationEmpty` | BOOL / R | Całość opróżniona według modelu ładunków; nie iloczyn chwilowo wolnych czujników |
| `xElevLoadKnown` | BOOL / R | Czy informacja o ładunku windy jest uzgodniona |
| `xElevHasLoad` | BOOL / R | Zapamiętany/uzgodniony ładunek windy; osobno od starego xOccP4 |
| `xTransferActive` | BOOL / R | Trwający transfer / ładunek między czujnikami |
| `xSingleDischargeReady` | BOOL / R | ST03: gotowość jednego wydania przez przycisk lokalny |
| `xDischargeActive` | BOOL / R | ST03: wydanie w toku |
| `xAwaitingPickup` | BOOL / R | ST03/ZLECENIE: oczekiwanie na odebranie B304 |
| `sWaitReason` | STRING[120] / R | HOME/ZLECENIE: aktualny powód oczekiwania |
| `uiCriticalCount` | UINT / R | Licznik krytycznych; z nowego managera |
| `uiWarningCount` | UINT / R | Licznik ostrzeżeń; bez wtórnego liczenia tej samej przyczyny |

Kody powyżej są proponowanym publicznym słownikiem HMI. Nie są istniejącymi enumami sekwencerów; adapter PLC mapuje je jawnie.

### Przyciski transakcyjne T

Dla każdego wiersza użyj wszystkich pól K z rozdziału 2. Enable = poprawna lokalna komunikacja + link.xArmed + permit.K.xAllowed + wymiana K w spoczynku.

| Panel / ID obiektu | Etykieta | K (cmd/rsp/permit) | Potwierdzenie na ekranie | Wymagana walidacja PLC |
|---|---|---|---|---|
| 1 HOME / btnAuto | Auto | modeAuto | state.uiMode=20 | Dozwolone przejście; kasowanie ręcznych wymuszeń IMM; brak automatycznego startu |
| 1 HOME / btnManual | Manual | modeManual | state.uiMode=10 | Zakończone wymagane operacje; zachowanie w opróżnianiu wymaga GAP-10 |
| 1 HOME / btnRobotOn | Praca z robotem — włącz | robotEnable | state.xWorkWithRobot=TRUE | Aktualne HOME, ważne dane i blokady; nie uruchamia programu FANUC |
| 1 HOME / btnRobotOff | Praca z robotem — wyłącz | robotDisable | state.xWorkWithRobot=FALSE | Zakończony Stop i rozliczone operacje |
| 1 HOME / btnReset | Reset alarmów | resetFaults | Stan aktywnych alarmów | Przyczyna usunięta, zgodność typu resetu; brak ruchu po resecie |
| 2 ZLECENIE / btnBoxes | Pojemniki | selectBoxes | state.uiProduction=10 | Zlecenie zamknięte, brak opróżniania |
| 2 ZLECENIE / btnBlisters | Blistry | selectBlisters | state.uiProduction=20 | Jak wyżej; wzajemne wykluczenie wyborów |
| 2 ZLECENIE / btnOrderOpen | Start zlecenia | orderOpen | state.uiOrderState=10 | Poprawny wybór i warunki otwarcia; wyłącznie zatwierdzenie zlecenia |
| 2 ZLECENIE / btnOrderEnd | Koniec zlecenia | orderEnd | uiOrderState=20/30, potem 0 | Jedna operacja zakończenia; rozliczenie wtrysków i opróżnienie; GAP-10 dla wywołania w postoju |
| 3 ALARMY / btnAck | Potwierdź alarmy | alarmAckAll | Pola xAcknowledged listy | Potwierdza przyjęcie informacji; nie kasuje aktywnej przyczyny |

Ikony ST01–ST05 na HOME wykonują wyłącznie lokalną zmianę panelu, bez zapisu komendy PLC. Dla każdej stacji i=1..5 planowane `GVL_HMI.hmiV2.station[i].uiSeverity` (UINT/R: 0=neutralna, 1=normalna, 2=ostrzeżenie, 3=krytyczny), `xValid` (BOOL/R), `uiStep` (UINT/R) i `sWaitReason` (STRING[120]/R). Czerwony = krytyczny, pomarańczowy = ostrzeżenie; nieaktualne dane szare z tekstem. Pozostałą paletę uzgodnić z W716/C30.

Numery stron: ST01 Status/Manual/Parametry = 101/111/121, ST02 = 102/112/122, ST03 = 103/113/123, ST04 = 104/114/124, ST05 = 105/115/125; IMM=201, DIAG=301. Zmiana strony aktualizuje link.uiActivePanel. W numerach nie ma informacji o fizycznym adresie urządzenia.

## 5. Stacje i ruchy ręczne

### 5.1. Siłowniki — komenda pozycji T, nie jog

Dla każdego wiersza powstaje status `GVL_HMI.hmiV2.act[i]`: `xHome`, `xWork`, `xBusy`, `xValid` (BOOL/R), `uiDiagCode` (UINT/R), `sDiag` (STRING[120]/R). xHome/xWork oznacza wszystkie wymagane, ważne potwierdzenia danej grupy; surowe czujniki lewe/prawe pokazuj dodatkowo osobno z [mapy I/O](hmi-io-diagnostics.md).

Każdy przycisk Home/Work stosuje protokół T. PLC przyjmuje cel raz; puszczenie przycisku nie oznacza zatrzymania ruchu. O wyniku świadczy status pozycji/błędu. Reakcja na przerwanie ruchu, błąd i utratę sesji zależy od potwierdzonej pneumatyki GAP-08.

| i / status act[i] | Panel | Mechanizm / etykieta | K: przycisk HOME | K: przycisk WORK | Uwagi |
|---:|---|---|---|---|---|
| 1 | ST01 Manual | V101/V102 — Podnoszenie P1 | `loadLift1Home` | `loadLift1Work` | GAP-08; wspólna para równoległa |
| 2 | ST01 Manual | V103/V104 — Podnoszenie P2 | `loadLift2Home` | `loadLift2Work` | GAP-08; wspólna para równoległa |
| 3 | ST01 Manual | V105/V106 — Podnoszenie P3 | `loadLift3Home` | `loadLift3Work` | GAP-08; wspólna para równoległa |
| 4 | ST01 Manual | V107/V108 — Pozycjoner P1 | `loadPositioner1Home` | `loadPositioner1Work` | GAP-08; wspólna para równoległa |
| 5 | ST01 Manual | V109/V110 — Pozycjoner P3 | `loadPositioner3Home` | `loadPositioner3Work` | GAP-08; wspólna para równoległa |
| 6 | ST02 Manual | V201 — Pozycjoner blistrów lewy | `elevPositionerLeftHome` | `elevPositionerLeftWork` | Manual osobno; w Auto ruch wspólny z V202 |
| 7 | ST02 Manual | V202 — Pozycjoner blistrów prawy | `elevPositionerRightHome` | `elevPositionerRightWork` | Manual osobno; w Auto ruch wspólny z V201 |
| 8 | ST02 Manual | V203 — Pozycjoner pojemnika | `elevBoxPositionerHome` | `elevBoxPositionerWork` | Blokady windy i taśmy |
| 9 | ST03 Manual | V301/V302 — Stoper rozładunku 1 | `unloadStopper1Home` | `unloadStopper1Work` | Para równoległa; B302 |
| 10 | ST03 Manual | V303/V304 — Stoper rozładunku 2 | `unloadStopper2Home` | `unloadStopper2Work` | Para równoległa; B303 |
| 11 | ST04 Manual | V401 — Osłona lewa | `storageCoversHome` | `storageCoversWork` | Wspólna komenda obu osłon: storageCoversHome/Work |
| 12 | ST04 Manual | V402 — Osłona prawa | `storageCoversHome` | `storageCoversWork` | Ta sama wspólna komenda; bez drugiego niezależnego przycisku |
| 13 | ST05 Manual | V501 — Oś pneumatyczna 7 | `robotAxis7Home` | `robotAxis7Work` | Nie jog osi serwonapędowej FANUC |
| 14 | ST05 Manual | V502 — Siłownik chwytaka 1 | `gripper1Home` | `gripper1Work` | Utrzymanie ładunku i przekazanie własności od robota |
| 15 | ST05 Manual | V503 — Siłownik chwytaka 2 | `gripper2Home` | `gripper2Work` | Jak wyżej; czujniki mogą pozostać w KEC3 |
| 16 | ST05 Manual | V504 — Siłownik chwytaka 3 | `gripper3Home` | `gripper3Work` | Jak wyżej |
| 17 | ST05 Manual | V505 — Siłownik chwytaka 4 | `gripper4Home` | `gripper4Work` | Jak wyżej |

Dla ST01/ST03 podpisuj przyciski „HOME” i „WORK” wraz z oznaczeniem V; etykiety „góra/dół”, „zablokuj/zwolnij” dopiero po potwierdzeniu mechaniki. Dla ST04: **storageCoversHome = otwórz obie osłony**, **storageCoversWork = zamknij obie osłony**. Potwierdzenie „zamknięte” wymaga act[11].xWork AND act[12].xWork i obu xValid; potwierdzenie „otwarte” analogicznie xHome. Osobną diagnostykę obu zachować.

Enable oprócz ogólnego wzorca T: przyjęty Manual, brak aktywnego właściciela Auto/robot/drain, aktualne I/O, odpowiednie pozwolenia. Dla stoperów/pozycjonerów potwierdzony postój powiązanej taśmy; dla magazynu przeciwne dostępy zablokowane; dla chwytaka uzgodniona własność sterowania i stan detalu. **Samo Manual nie wystarcza.** PLC egzekwuje wzajemne wykluczenie Home/Work oraz poprawne zachowanie cewek. W rozstrzygnięciach mechaniki nie zakładać, że wyłączenie wszystkich cewek utrzyma ładunek.

V506–V508 są rezerwami: bez przycisków. Nie wyznaczają wolnych kanałów przedmuchu.

### 5.2. Winda i transportery — J

Każdy poniższy K oznacza `GVL_HMI.hmiV2.jog.K` BOOL/W, a `GVL_HMI.hmiV2.holdCounter.K` UINT/W jest osobnym licznikiem trzymania tego klucza; powiązane `GVL_HMI.hmiV2.permit.K.xAllowed` BOOL/R i `sReason` STRING[120]/R. Obiekt: momentary Touch=1/Release=0, nadzór według J. Dla par kierunków oba TRUE oznaczają odrzucenie obu żądań przez PLC, nie wybranie kierunku priorytetem.

| Panel / obiekt | Etykieta | K | Stan do odczytu po naprawieniu producenta | Warunki szczególne |
|---|---|---|---|---|
| ST01 Manual / jogTopFwd | Transporter załadunku — naprzód | topFwd | hmiStatus.xConvTopRunning, iConvTopDirection | Zgodne położenia blokad, brak trwającego transferu Auto |
| ST02 Manual / jogElevUp | Winda — góra | elevUp | hmiStatus.xElevBusy, rElevFreq_Hz, xElevAtTop | Potwierdzone kierunki, krańcówki, napęd i pozwolenia |
| ST02 Manual / jogElevDown | Winda — dół | elevDown | hmiStatus.xElevBusy, rElevFreq_Hz, xElevAtBottom | Jak wyżej |
| ST02 Manual / jogElevFwd | Taśma windy — naprzód | elevBeltFwd | hmiStatus.xConvElevRunning, iConvElevDirection | Właściwy poziom windy, blokady pozycji i wolna droga |
| ST02 Manual / jogElevBwd | Taśma windy — wstecz | elevBeltBwd | Te same pola | Kierunek zgodny z zatwierdzoną mechaniką |
| ST03 Manual / jogBottomFwd | Rozładunek — naprzód | bottomFwd | hmiStatus.xConvBottomRunning, iConvBottomDirection | Stopery i zajętość zgodne z ruchem |
| ST03 Manual / jogBottomBwd | Rozładunek — wstecz | bottomBwd | Te same pola | Pokazywać jako dostępne wyłącznie jeżeli nowy napęd i okablowanie obsługują ten kierunek |

Przed powiązaniem „naprzód/wstecz” sprawdź znaczenie aktualnych iConv*Direction; wartości -1/0/1 nie dowodzą zgodności fizycznej z nowym transporterem. Każdy pełny historyczny symbol ma prefiks `GVL_HMI.`.

Wybór szybkiej windy: proponowane `GVL_HMI.hmiV2.jog.xElevFast` BOOL/W, przycisk chwilowy lub selektor działający tylko podczas uprawnionego jogu. Po zakończeniu sesji reset do FALSE, sam nie wywołuje ruchu. Rzeczywistą częstotliwość pokazuje rElevFreq_Hz; nie zadanie prędkości.

### 5.3. Podciśnienia i przedmuchy ST05

Dla i=1..5: `GVL_HMI.hmiV2.vac[i].xCommanded`, `xVacuumOK`, `xFeedbackValid`, `xBlowActive` (BOOL/R), `uiDiagCode` (UINT/R), `sDiag` (STRING[120]/R). VacuumOK musi pochodzić z właściwego czujnika, nie z komendy. Brak źródła = xFeedbackValid=FALSE i „brak potwierdzenia”.

| Obwód | Zawór | K przycisku Załącz próżnię (T) | K przycisku Wyłącz próżnię (T) | K przycisku Przedmuch (T) | Potwierdzenie |
|---|---|---|---|---|---|
| 1 | V509 | vacuum1On | vacuum1Off | vacuum1Blow | vac[1] |
| 2 | V510 | vacuum2On | vacuum2Off | vacuum2Blow | vac[2] |
| 3 | V511 | vacuum3On | vacuum3Off | vacuum3Blow | vac[3] |
| 4 | V512 | vacuum4On | vacuum4Off | vacuum4Blow | vac[4] |
| 5 | V513 | vacuum5On | vacuum5Off | vacuum5Blow | vac[5] |

Przedmuch jest ograniczoną czasowo operacją w PLC, z osobnym zezwoleniem, nie zatrzaśniętym wyjściem HMI. Jego rzeczywiste kanały, czas i relacja do próżni są otwarte w GAP-03/08. Do ich zamknięcia obiekty przedmuchu pozostają nieaktywne. Wyłączenie próżni ma osobne permit — nie wynika automatycznie z zezwolenia na jej włączenie. Wymagane Manual, ważne dane, przekazanie sterowania przez robota i warunki utrzymania/zwolnienia detalu.

### 5.4. Robot i komunikacja — diagnostyka R

| Symbol — prefiks `GVL_HMI.hmiV2.` | Typ | Element |
|---|---|---|
| `robot.uiProgram` | UINT | ST05: faktycznie wybrany/uruchomiony program z nowego kontraktu |
| `robot.xProgramMatches` | BOOL | Zgodność z zatwierdzonym rodzajem produkcji |
| `robot.uiStep` | UINT | Numer bieżącego kroku LS |
| `robot.uiWaitCode` | UINT | Kod oczekiwanego warunku |
| `robot.sWaitText` | STRING[120] | Tekst: czego robot oczekuje |
| `robot.uiAlarmCode` | UINT | Rozróżniony kod alarmu/timeoutu |
| `robot.xCycleActive` | BOOL | Rozpoczęta operacja robota |
| `robot.xStopSettled` | BOOL | Rozliczone wszystkie rozpoczęte operacje, nie tylko HOME |
| `comm.xRobotValid` | BOOL | Aktualność wymiany FANUC |
| `comm.xFestoValid` | BOOL | Aktualność bramki Festo |
| `comm.xVfdValid` | BOOL | Rzeczywista aktualność napędu; spójna z GIATV |
| `comm.sRobotDiag`, `comm.sFestoDiag`, `comm.sVfdDiag` | STRING[120] | Przyczyna problemu komunikacji |

Pozostałe lampki robot Auto/Ready/Running/Fault/Home można wyprowadzić ze zaktualizowanych istniejących hmiStatus, ale zawsze z comm.xRobotValid. „HOME” nie oznacza „forma wolna” ani zakończenia wtrysku. Testowe xRobotCommOk=TRUE nie jest producentem nowego comm.xRobotValid.

### 5.5. Reset stanu stacji

Pięć osobnych kluczy T: **station1ResetState, station2ResetState, station3ResetState, station4ResetState, station5ResetState**. Przyciski na odpowiednich Parametrach, etykieta „Reset stanu ST.n”, z lokalnym oknem potwierdzenia opisującym rzeczywisty zakres resetu.

Warunki: przyjęty Manual, postój, brak nierozliczonego transferu, uzgodniony stan ładunku i warunki specyficzne stacji. PLC sprawdza je ponownie. Przed implementacją ustalić, co resetuje każda stacja w GAP-11; przy braku decyzji permit=FALSE. Nie zerować na ślepo zajętości windy albo informacji o trzymanym detalu. To nie jest reset alarmów ani bezpieczeństwa. Panel ST05 nie resetuje programu/pozycji robota przez UOP.

## 6. EUROMAP — podgląd i ręczne żądania

Na panelu 201 utwórz trzy kolumny: **wejście od Krauss**, **żądanie bieżącego źródła**, **końcowe wyjście po arbitrażu PLC**. Wartość wyjścia PLC nie dowodzi, że Krauss wykonał ruch; pokaż osobno potwierdzenia pozycji.

Wejścia KF101–KF111, wyjścia KF201–KF211 i źródłowe KF3xx/KF4xx są rozpisane w [mapie I/O](hmi-io-diagnostics.md). Ich adresy z Excela są materiałem wejściowym, nie gotową konfiguracją. Dane FANUC docelowo pochodzą z EtherNet/IP, nie z równoległego starego okablowania. KF211/KF403 pozostają nierozstrzygnięte.

| Pole — prefiks `GVL_HMI.hmiV2.imm.` | Typ / kierunek | Element |
|---|---|---|
| `uiOwner` | UINT / R | Źródło: 0=brak, 10=robot, 20=praca samodzielna, 30=Manual |
| `xDataValid` | BOOL / R | Ważność wejść i konfiguracji |
| `xCycleActive` | BOOL / R | Rzeczywiście rozpoczęty cykl; źródło do zatwierdzenia GAP-05 |
| `xManualActive` | BOOL / R | Przyjęty tryb ręcznych żądań procesowych |
| `sBlockReason` | STRING[120] / R | Przyczyna blokady |
| `requestKF202…requestKF210` | BOOL / R, każde osobno | Żądanie przed arbitrażem, odpowiadające sygnałowi; nie fizyczne wyjście |
| `manualKF202…manualKF210` | BOOL / R, każde osobno | Aktualnie przyjęte żądanie Manual; status przełącznika |
| `allowedKF202…allowedKF210` | BOOL / R, każde osobno | Czy sygnał został zatwierdzony jako ręcznie obsługiwany procesowy sygnał |

Zapisy KF202…KF210 oznaczają dokładnie dziewięć osobnych pól z końcówkami 202, 203, 204, 205, 206, 207, 208, 209, 210. Dla KF204 właścicielem pozostaje koordynacja opcji współpracy; pole diagnostyczne istnieje, ale **bez przycisku wymuszenia**.

| Sygnał / etykieta | K ustawienia (T) | K kasowania (T) | Warunek dodatkowy |
|---|---|---|---|
| KF202 — zezwolenie zamknięcia formy | immKF202Set | immKF202Clear | Zweryfikowane funkcje i granica obwodów GAP-05; samo HOME nie wystarcza |
| KF203 — zezwolenie pełnego otwarcia | immKF203Set | immKF203Clear | Zatwierdzona funkcja i warunki ruchu |
| KF205 — wyrzutnik tył | immKF205Set | immKF205Clear | Dopuszczalne kombinacje i przejścia według zatwierdzonego interfejsu Krauss, GAP-05 |
| KF206 — wyrzutnik przód | immKF206Set | immKF206Clear | Dopuszczalne kombinacje i przejścia według zatwierdzonego interfejsu Krauss, GAP-05 |
| KF207 — rdzeń 1, pozycja 1 | immKF207Set | immKF207Clear | Dopuszczalne kombinacje i przejścia według zatwierdzonego interfejsu Krauss, GAP-05 |
| KF208 — rdzeń 1, pozycja 2 | immKF208Set | immKF208Clear | Dopuszczalne kombinacje i przejścia według zatwierdzonego interfejsu Krauss, GAP-05 |
| KF209 — rdzeń 2, pozycja 1 | immKF209Set | immKF209Clear | Dopuszczalne kombinacje i przejścia według zatwierdzonego interfejsu Krauss, GAP-05 |
| KF210 — rdzeń 2, pozycja 2 | immKF210Set | immKF210Clear | Dopuszczalne kombinacje i przejścia według zatwierdzonego interfejsu Krauss, GAP-05 |

KF205/206 i pary rdzeni są zezwoleniami procesowymi, nie bezpośrednimi przeciwnymi cewkami. Nie narzucać im wykluczenia bez potwierdzenia protokołu; niektóre fazy mogą wymagać równoczesnego zezwolenia.

Cała ta grupa wymaga Manual, aktualnego HOME, zatrzymanej współpracy i zatwierdzonej listy procesowych sygnałów. **Domyślnie niedostępna do zamknięcia GAP-05.** Wejście w Auto kasuje wymuszenia w PLC. Polityka kasowania przy utracie sesji musi uwzględniać zakończenie operacji i GAP-08/12 — nie kopiować bezmyślnie reguły dla jogu.

KF201 „obszar formy wolny” wyłącznie podgląd, bez przycisku wymuszenia. KF204 podgląd wyniku koordynacji, nie surowy przełącznik B2. KF211, KF403, KF501/Euromap73, rygle, reset obwodów bezpieczeństwa i obejście STO: **brak przycisków surowego wymuszania w tym projekcie HMI**. Ich obecność w arkuszu nie czyni ich zmiennymi operatorskimi. Ewentualne funkcje obsługi dedykowanego układu wynikają z odrębnego zatwierdzonego projektu.

## 7. Parametry stacji

### 7.1. Kontrakt edycji P

Dla każdego klucza P z tabeli obowiązują `GVL_HMI.hmiV2.param.edit.P` (W), `actual.P` (R), `min.P` (R), `max.P` (R) o typie z wiersza. Element: Numeric Input dla edit oraz Numeric Display dla actual, z jednostką przy polu. Min/max pochodzą z zatwierdzonej konfiguracji PLC, nie z deklarowanego zakresu typu danych.

Dla każdej stacji n=1..5 przyciski T: **station1ParamApply…station5ParamApply** oraz **station1ParamReload…station5ParamReload**. Stacja zatwierdza atomowo swój zestaw; panel nie łączy dwóch Apply jednocześnie. Przed zmianą produkcji liczba blistrów w stosie musi być zatwierdzona zgodnie z cyklem zlecenia.

| Pole wspólne — prefiks `GVL_HMI.hmiV2.param.` | Typ / kierunek | Element / działanie |
|---|---|---|
| `uiActualRevision[1..5]` | UINT / R | Wersja przyjętych nastaw stacji, zwiększana po skutecznym Apply |
| `xLoaded[1..5]` | BOOL / R | Aktualny bufor został wczytany z PLC; bez tego nie aktywować edycji |
| `xDirty[1..5]` | BOOL / R | PLC porównuje edit i actual |
| `sValidation[1..5]` | STRING[120] / R | Błąd walidacji / wynik zapisu, obok przycisków |
| `uiEditBaseRevision[1..5]` | UINT / R | Wersja actual, z której PLC utworzył bufor edit; zmiana actual podczas edycji wymaga Reload |

Przyjęta strategia projektowa: edycja tylko w Manual/postoju, a nastawa liczby blistrów dodatkowo przy zamkniętym zleceniu. To **DOMYŚLNE**, do zatwierdzenia dla procedury uruchomienia. Retencja parametrów, wartości startowe, dopuszczalne min/max i role edycji wymagają zatwierdzenia; nie kopiować ich automatycznie ze starego projektu.

### 7.2. Lista parametrów do wystawienia

| Panel | Klucz P / typ | Jednostka / znaczenie | Powiązanie w PLC |
|---|---|---|---|
| ST02 | `uiTraysInStack` / UINT | szt.; całkowita liczba blistrów >0 i do zatwierdzonego maksimum | FB_TraySequencer.Cfg.uiTraysInStack; zmiana przy zamkniętym zleceniu |
| ST02 | `rElevSpeedFast_Hz` / REAL | Hz; wolna ≤ szybka ≤ zatwierdzony limit napędu | ST_ElevatorCmd.rSpeedFast_Hz |
| ST02 | `rElevSpeedSlow_Hz` / REAL | Hz; dodatnia do zatwierdzonego limitu | ST_ElevatorCmd.rSpeedSlow_Hz |
| ST01–ST05 wg act[i] | `udiActTimeout_ms[1..17]` / UDINT | ms; osobny próg diagnostyki każdego mechanizmu z tabeli act | Cfg.tTimeout/nowe odpowiedniki; V201/V202 i V401/V402 osobno |
| ST01–ST05 wg act[i] | `udiActStable_ms[1..17]` / UDINT | ms; stabilizacja pozycji, osobno dla każdego mechanizmu | Cfg.tStable/nowe odpowiedniki |
| ST01 | `udiTopMotorStop_ms` / UDINT | ms; oczekiwanie po wyłączeniu taśmy | ST_TopFlowCfg.tMotorStopDelay |
| ST01 | `udiTopMoveTimeout_ms` / UDINT | ms; nadzór transferu | ST_TopFlowCfg.tMoveTimeout |
| ST01 | `udiTopStopperTimeout_ms` / UDINT | ms; koordynacja oczekiwania na stopery | ST_TopFlowCfg.tStopperTimeout; nie eskalować ostrzeżenia tego samego ruchu |
| ST01 | `udiTopSensorStable_ms` / UDINT | ms; stabilizacja czujników | ST_TopFlowCfg.tSensorStable |
| ST03 | `udiBottomMotorStop_ms` / UDINT | ms; oczekiwanie po wyłączeniu taśmy | ST_Bottom567Cfg.tMotorStopDelay |
| ST03 | `udiBottomStepTimeout_ms` / UDINT | ms; nadzór aktywnego kroku | ST_Bottom567Cfg.tStepTimeout; oczekiwanie na odbiór operatora nie jest tym błędem |
| ST03 | `udiBottomSensorStable_ms` / UDINT | ms; stabilizacja obecności/odbioru | ST_Bottom567Cfg.tSensorStable |
| ST01/ST02/ST03 | `udiConveyorReversal_ms[1..3]` / UDINT | ms; przerwa przed zmianą kierunku: top/elev/bottom | ST_ConveyorCfg.tReversalDelay; dla jednokierunkowego napędu parametr ukryty |
| ST02 | `udiElevMoveTimeout_ms` / UDINT | ms; nadzór przejazdu windy | ST_ElevatorPar.tMoveTimeout |
| ST02 | `udiElevClearP4Timeout_ms` / UDINT | ms; bazowanie do zwolnienia czujnika | ST_ElevatorPar.tClearPos4Timeout |
| ST02 | `udiElevStopTimeout_ms` / UDINT | ms; nadzór wyhamowania | ST_ElevatorPar.tStopTimeout |
| ST02 | `rElevStopThreshold_Hz` / REAL | Hz; rozpoznanie zatrzymania według napędu | ST_ElevatorPar.rStopSpeedThreshold_Hz; parametr serwisowy, zakres do zatwierdzenia |
| ST04 | `udiStorageStable_ms` / UDINT | ms; filtracja sygnałów magazynu | ST_StorageCfg.tStable |
| ST04 | `udiStoragePermissionTimeout_ms` / UDINT | ms; nadzór zmiany pozwolenia procesowego | ST_StorageCfg.tPermissionTimeout; nie traktować jak czas funkcji bezpieczeństwa |
| ST02 | `udiTrayPositionerTimeout_ms` / UDINT | ms | ST_TraySeqCfg.tPositionerTimeout; bez wtórnej eskalacji siłownika |
| ST05 | `udiTrayRobotAckTimeout_ms` / UDINT | ms | ST_TraySeqCfg.tRobotAckTimeout; rozróżnić oczekiwanie operatora od operacji robota |
| ST02 | `udiTrayP4ConfirmTimeout_ms` / UDINT | ms | ST_TraySeqCfg.tP4ConfirmTimeout |
| ST02 | `udiTrayDischargeTimeout_ms` / UDINT | ms | ST_TraySeqCfg.tDischargeTimeout |
| ST02 | `udiTrayElevReturnTimeout_ms` / UDINT | ms | ST_TraySeqCfg.tElevReturnTimeout |
| ST02 | `udiBoxPositionerTimeout_ms` / UDINT | ms | ST_BoxSeqCfg.tPositionerTimeout; bez wtórnej eskalacji siłownika |
| ST05 | `udiBoxRobotAckTimeout_ms` / UDINT | ms | ST_BoxSeqCfg.tRobotAckTimeout |
| ST02 | `udiBoxDischargeTimeout_ms` / UDINT | ms | ST_BoxSeqCfg.tDischargeTimeout |
| ST02 | `udiBoxTransferTimeout_ms` / UDINT | ms | ST_BoxSeqCfg.tTransferTimeout |
| ST02 | `udiBoxElevReturnTimeout_ms` / UDINT | ms | ST_BoxSeqCfg.tElevReturnTimeout |
| ST05 | `udiVacuumConfirmTimeout_ms[1..5]` / UDINT | ms; osiągnięcie podciśnienia | Nowa obsługa BAT4; kanały potwierdzeń GAP-03/08 |
| ST05 | `udiBlowPulse_ms[1..5]` / UDINT | ms; ograniczony przedmuch | Nowa obsługa BAT4; niedostępne do potwierdzenia pneumatyki |

Tablice rozwija się w Vijeo na osobne pola z jawnym indeksem, np. `GVL_HMI.hmiV2.param.edit.udiActTimeout_ms[6]` odpowiada V201. Jeśli importer nie obsłuży danego zagnieżdżenia, przygotuj płaskie aliasy po stronie PLC i tabelę 1:1; nie zmieniaj znaczenia ani typów.

Fizyczne czasy ze starego kodu nie są zatwierdzonymi nastawami Krauss. Obecny fallback prędkości to **15/5 Hz**, mimo komentarza GVL 40/15; liczba blistrów 0 daje 8. W nowym interfejsie 0 poza zatwierdzonym zakresem ma zostać odrzucone z komunikatem, a nie potajemnie włączyć dawną wartość. Zjazd o wysokość tacki ma obecnie osobną stałą 5 Hz w FB_Elevator; decyzję o jego parametryzacji podjąć w kroku windy, nie sugerować, że pole prędkości wolnej już nim steruje.

**Nie wystawiać do zwykłej edycji operatorskiej:** HoldCoilInEndPos, maski słowa napędu, xFwdIsUp, dane safety, czasy resetów safety/napędu, IP/assembly/RPI i polityka zaniku cewek/podciśnienia. Parametry tBlink są wyglądem/konfiguracją, nie progami błędu. Stare tM8Timeout zastępuje diagnoza dwóch osobnych osłon; nie pozostawić dwóch sprzecznych źródeł nastawy.

## 8. Alarmy

Obecne hmiAlarms jest strukturą flag, a nie gotową listą alarmów. Zaprojektuj stabilny katalog ID w FB_AlarmManager, zatwierdź go w GAP-12, a potem z niego wygeneruj listę Vijeo. `MAX_ALARMS=32` nie wyznacza liczby wymaganych rekordów nowego projektu.

Dla każdego zatwierdzonego rekordu i=1..N:

| Symbol — prefiks `GVL_HMI.hmiV2.alarm[i].` | Typ / kierunek | Obiekt |
|---|---|---|
| `uiId`, `uiStation`, `uiSource`, `uiCode` | UINT / R | Stały ID, ST.1–ST.5/system, urządzenie i przyczyna; nie przesuwać znaczeń po zmianie kolejności listy |
| `uiSeverity` | UINT / R | 1=informacja, 2=ostrzeżenie, 3=krytyczny |
| `xActive` | BOOL / R | Czy przyczyna aktualnie występuje |
| `xAcknowledged` | BOOL / R | Potwierdzenie przez operatora |
| `xReturned` | BOOL / R | Przyczyna ustąpiła; osobno od ACK i usunięcia zatrzaśnięcia |
| `xCriticalActive` | BOOL / R | Trigger zdarzenia krytycznego w grupie Vijeo |
| `xWarningActive` | BOOL / R | Trigger ostrzeżenia w grupie Vijeo |
| `xCanReset` | BOOL / R | Można skasować zatrzaśnięcie zgodnie z klasą |
| `sText` | STRING[120] / R | Opis przyczyny, stacja i mechanizm |
| `sAction` | STRING[120] / R | Konkretna czynność operatora / czego oczekuje PLC |

Tabela rekordów musi pokrywać co najmniej: urządzenia act[1..17], napędy i transportery, przepływ, oba sekwencery, komunikację robot/Festo/moduły/ATV/HMI, ciśnienie, blokady/stan układu bezpieczeństwa, IMM, podciśnienia i odzyskiwanie. Kody oraz klasy poza potwierdzonymi ostrzeżeniami siłowników ST.1–ST.4 zatwierdzić w GAP-12. Nie nadawać im wszystkim klasy czerwonej z powodu dawnego słowa Fault.

W Vijeo utwórz grupy Krytyczne i Ostrzeżenia, stałe teksty/ID z katalogu, listę aktywnych i historię z czasem wystąpienia, zaniku oraz potwierdzenia. Zwykłe oczekiwanie na operatora pokazuj jako status, nie alarm timeout. Do historii użyj czasu runtime panelu po zatwierdzeniu strefy/synchronizacji; przy archiwum PLC ustal osobny format znaczników. Nie obiecuj historii z czasu wyłączonego panelu bez archiwizacji po stronie PLC.

**ACK natywnego Alarm Summary Vijeo nie zapisuje automatycznie xAcknowledged w PLC.** Przyjętym źródłem potwierdzenia jest transakcja alarmAckAll. Wyłącz/nie udostępniaj sprzecznego lokalnego ACK albo zaimplementuj i przetestuj jego świadome powiązanie. Jeśli obiekt Alarm Summary nie umie pokazać zewnętrznego statusu ACK, obok umieść tabelę aktualnych rekordów PLC. Nie pokazuj lokalnego ACK jako potwierdzenia PLC.

Reset alarmów używa resetFaults; reset stacji używa stationNResetState. Żaden z nich nie udziela automatycznie zgody na nowy ruch. Ostrzeżenie siłownika nadal blokuje zależny ruch. Usunięcie jego przyczyny i zasada kontynuacji muszą odpowiadać zatwierdzonej procedurze, nie przypadkowemu ponownemu naciśnięciu Reset.

## 9. Podgląd I/O i kompletność mapy

[Mapa diagnostyczna](hmi-io-diagnostics.md) obejmuje każdy wiersz sygnału z aktualnej kopii Excela: 166 wierszy, 159 unikalnych nazw logicznych, oraz 12 urządzeń Festo. Powtórzone nazwy dotyczą wspólnych komend par; nie tworzą dwóch różnych kanałów wyjściowych.

Na każdej stronie diagnostycznej pokaż: ID sprzętu, opis, logiczny stan, ważność, źródło oraz informację „komenda”/„potwierdzenie”. Dostęp tylko do odczytu. Szczególnie:
- oddzielna bariera ST.1 nie ma jeszcze wiersza ani adresu — planowane `GVL_HMI.hmiV2.loading.xBarrierClear` i `xBarrierValid` BOOL/R oraz `xStackPassed` BOOL/R, po GAP-01;
- B205 ma niepotwierdzone podłączenie — jego lampka nie może symulować działającego czujnika;
- brakujące potwierdzenia podciśnień/przedmuchy pozostają nieaktywne do uzupełnienia mapy;
- numery urządzeń nie są adresami sieciowymi, a nazwy Excel nie są dowodem deklaracji w PLC;
- sygnały KF3xx/KF4xx zachowują ślad źródła, lecz produkcyjne źródło musi wynikać z migracji na EtherNet/IP.

Pola brakujące w dostarczonych źródłach nie otrzymały fikcyjnych zacisków ani numerów rejestrów. Gotowy eksport powstanie dopiero z zatwierdzonego natywnego projektu.

## 10. Sprawdzenie gotowego projektu HMI

Wszystkie poniższe próby mają status **NIEWYKONANE**. Uzupełnij datę, wersję PLC/HMI, konfigurację, kroki i dowód. Próby ruchu wykonywać w przygotowanym środowisku; przegląd dokumentów nie zastępuje ich.

| Test | Próba | Wynik wymagany |
|---|---|---|
| HMI-01 / AT-01 | Zablokowane żądanie Auto/produkcji/zlecenia; następnie poprawne | Potwierdzony tryb nie zmienia się od samego kliknięcia; widoczny powód odmowy; Start zlecenia bez ruchu |
| HMI-02 / AT-09/14 | Trzymany jog: puść, zmień stronę, wyłącz sieć, zrestartuj panel, zatrzymaj skrypt hold; zgub Release elevUp i przytrzymaj elevBeltFwd na tej samej stronie | PLC unieważnia jog w zatwierdzonym czasie; brak wznowienia ze starego TRUE. Nie następuje przypadkowe zwolnienie detalu/podciśnienia |
| HMI-03 | Podwójny klik, opóźniony ACK, utrata połączenia w każdej fazie T, restart PLC | Jeden skutek; odpowiedź dotyczy właściwych ID klucza/żądania/sesji; cache starego wyniku i opóźniony telegram poprzedniej sesji nie są przyjmowane; brak odtworzenia komendy po reconnect |
| HMI-04 | Edycja bez Apply, Apply poza zakresem, przepełnienie, wolna>szybka, TIME w złej jednostce | Brak częściowego zastosowania; walidacja w PLC; czytelny wynik i odczyt actual |
| HMI-05 / AT-13 | Restart panelu/PLC podczas edycji i po Apply | Brak nadpisania zerami; retencja według ustaleń; wymagany Reload przy nieaktualnej rewizji |
| HMI-06 / AT-11/12 | Alarm krytyczny, ostrzeżenie siłownika, oczekiwanie na odbiór, ACK, Reset | Poprawne kolory/andon, odrębne active/ack/returned; ostrzeżenie bez globalnego Stop; Reset bez ruchu |
| HMI-07 / AT-09 | Utrata danych przy HOME/WORK=TRUE i przy FALSE | Wyraźny brak danych, zablokowane komendy; brak traktowania ostatniej wartości jak aktualnej |
| HMI-08 | Uprawnienia operator/serwis, jeżeli wymagane przez uzgodniony projekt | Dostęp zgodny z zatwierdzonym katalogiem; PLC nadal egzekwuje blokady procesu niezależnie od widoczności ekranu |
| HMI-09 / AT-14 | Przeciwne jogi/cele; zapis zakazanej komendy spoza HMI; stoper przy aktywnej taśmie | Odrzucenie przez PLC z przyczyną, brak ukrytego kolejkowania |
| HMI-10 / AT-08/10 | Manual EUROMAP bez HOME, w ruchu, potem przy poprawnych warunkach i przejściu Auto | Zgodne permit, rozdział request/output/feedback; wejście Auto usuwa ręczne wymuszenia; bez surowych wymuszeń safety |
| HMI-11 / AT-01/14 | Przegląd każdego przycisku, ekranów, polskich znaków i opisu celu | Zgodny typ T/J/P/R, Enable, powód blokady, status rzeczywisty, czytelne jednostki; bez nieuzgodnionego Start HMI |
| HMI-12 | Porównanie eksportów PLC i Vijeo oraz próby typów | Każdy wymagany symbol istnieje, właściwy typ/zakres/kierunek; -1 nie staje się 65535; REAL/TIME poprawne; statusy tylko R; brak pozostałych tagów demonstracyjnych |

## 11. Dane do zamknięcia przed finalnym wiązaniem

GAP-07: pełny panel, wersja Vijeo, projekt W716/C30, driver, rzeczywisty eksport symboli, formaty typów, heartbeat i możliwości runtime przycisków. GAP-03/08: cewek/podciśnień/potwierdzeń nie zastępuje tabela ekranów. GAP-05/09: sygnały IMM i migracja robota. GAP-10: zachowanie Stop/Manual podczas drain i koniec zlecenia z postoju. GAP-11: reset stacji, retencja i uzgadnianie ładunków. GAP-12: pełny katalog alarmów i reakcje po utracie sesji.

Dla każdego parametru należy wpisać zatwierdzone min/max, wartość początkową, retencję i moment zastosowania. Do tego czasu można przygotować obiekty, ale nie uznawać nastaw za gotowe do uruchomienia. Role użytkowników i logowanie uzgodnić z bazowym projektem/klientem — nie wprowadza się tu arbitralnego katalogu ról.
