# Poprawki po review PLC — 2026-11-15

Status: **implementacja źródeł i testy offline**. Bez pobierania programu na urządzenia. Bazą był commit `1782ea7`. Dokument nie zamyka sprzętowych GAP ani odbioru bezpieczeństwa.

## Wykonane poprawki

| Review | Implementacja | Weryfikacja |
|---|---|---|
| R1 — sprzeczna polityka cewek | FB_StationOutputPolicy waliduje oba kierunki; błędny wpis nie nadpisuje ostatniej poprawnej polityki danego urządzenia | Zły wpis podczas pracy i blokady krytycznej; brak obu cewek jednocześnie |
| R2 — alarm ze starego skanu | Storage i Elevator wykonują się przed agregacją alarmów; StationCoils dostaje bieżącą blokadę; bez ponawiania FB/timerów | Błąd konfiguracji zatrzymuje transporter i TX w bieżącym skanie |
| R3 — utrata kierunku | Chwytak sprawdza również zatrzaśnięty cel po puszczeniu przycisku; Storage odbiera komendę otwierania po utracie pozwolenia | Komenda przechodzi na zatwierdzoną politykę, rezerwacja obszaru pozostaje |
| R4 — konflikty Manual | Bieżące żądania są rozstrzygane razem, przed wykonaniem ruchu | Równoczesna i przesunięta o skan komenda osi i taśmy windy |
| R5 — automatyczny powrót jogu | Utrata dopuszczenia trzymanego kierunku kasuje autoryzację | Powrót dopuszczenia wymaga zwolnienia i nowego naciśnięcia |
| R6 — timeout a końcowa cewka | Osobna LocalFaultPolicy; RestartRequired utrzymuje zależną blokadę po Reset | Końcowa cewka, brak globalnego Stop od ostrzeżenia, ponowny ruch dopiero po nowej autoryzacji |
| R7 — luka zdarzeń materiału | Zatwierdzone recovery ustala lastMaterialEventId na dotychczasowe nextMaterialEventId; licznik nie jest cofany | Następne zdarzenie działa bez powtórnego recovery i bez ponownego użycia ID |
| R8 — Apply podczas ruchu | Wspólny potwierdzony postój stacji i chwytaka oraz brak bieżących żądań Manual | Odrzucenie zmiany ilości i nastaw ST.1 podczas ruchu chwytaka |
| R9 — odmowa jako alarm | fault/faultCode są zatrzaskiwane osobno od reason; kanały 31–40 pokazują usterki | Postój nie daje dziesięciu alarmów; timeout zachowuje przyczynę |
| R10 — niespójne applied | TX oraz diagnostyka wyjść korzystają z końcowej komendy | Próżnia wcześniej OFF pozostaje OFF; wcześniej ON pozostaje ON; holdApplied zgodne |
| R11 — unsigned RFR | WORD → INT16 → REAL przed skalowaniem 0,1 Hz, również w ścieżce zgodności Elevator | 0, +5, −0,1 i −5 Hz przez rzeczywisty PRG_Main |
| R12 — stare kontrakty | Nieużywane pola Box/Tray oznaczono LEGACY; poprawiono źródła statusu V201/V202, Storage i P4 | Tabela migracji poniżej; deklaracje zachowane dla importu projektu natywnego |
| R13 — luki testów | check_plc_review.py dodano do check_plc_release.py i CI; rozszerzono granice typów w interpreterze | Testy źródeł ST oraz wspólnego kontrolera ST–LS |

Nowe testy sprawdzają także brak ruchu od samego Reset, odrzucenie nieprawidłowych składowych ilości przed przepełnieniem sumy i zachowanie próżni bez automatycznego zrzutu.

## Nowe interfejsy i odpowiedzialność

| Port | Kierunek i znaczenie | Brak zatwierdzenia / ważności |
|---|---|---|
| GVL_Station.LocalFaultPolicyVerified | Konfiguracja serwisowa → PLC. Potwierdza całą macierz lokalnych reakcji cewek | Domyślnie FALSE; blokuje dopuszczenie stacji. Nie ustawiać na TRUE bez GAP-08 |
| GVL_Station.LocalFaultPolicy[1..10] | Konfiguracja → StationCoils. Końcowe HOME/WORK po lokalnym błędzie, odrębne od zaniku komunikacji i puszczenia Manual | Obie cewki TRUE są błędem konfiguracji. Nie przyjęto domyślnej reakcji fizycznej |
| GVL_Station.LocalRestartRequired[1..10] | PLC → diagnostyka/HMI, tylko odczyt. Zależny ruch oczekuje nowej autoryzacji po usterce | Reset nie usuwa tej blokady. Auto: świeży fizyczny Start po usunięciu błędu; Manual: zwolnienie i nowe naciśnięcie |
| ST_RobotPlant.stationIdleConfirmed | StationController → RobotController. Potwierdzony postój stacji oraz brak żądań Manual | FALSE blokuje Apply. RobotController dodatkowo sprawdza chwytak i bieżące żądania ST.5 |
| ST_RobotStatus.allMotionIdle | PLC → diagnostyka. Wspólny warunek postoju używany przez Apply | FALSE nie jest potwierdzeniem zakończenia operacji |
| cylinders/vacuum.fault, faultCode | Gripper → alarmy i diagnostyka. Zatrzaśnięta usterka i jej pierwotna przyczyna | reason=10/30/40 bez usterki pozostaje odmową, nie alarmem urządzenia |

Indeksy lokalnej polityki: 1=M1, 2=M2, 3=M3, 4=M4, 5=M5, 6=V201, 7=V203, 8=V202, 9=V301/V302, 10=V303/V304. Polaryzację M1–M5 nadal potwierdza GAP-08.

FB_StationOutputPolicy ma pamięć ostatniej poprawnej reakcji każdego urządzenia wyłącznie w bieżącym uruchomieniu. Nie potwierdza nowej błędnej konfiguracji; odbiera Ready i dopuszczenia ruchu. Po restarcie wymagane jest ponowne dostarczenie zatwierdzonej konfiguracji. Brak polityki nie jest zastępowany fikcyjną wartością verified. Na krytycznej blokadzie próżnia zachowuje poprzednio zastosowany hold, a przedmuch jest wyłączony. Nie rozpoczynamy ssania na wcześniej wyłączonych obwodach.

Macierz konfliktów Manual: taśma górna ↔ M1–M5; taśma windy ↔ oś windy/V201/V202/V203; oś windy ↔ V201/V202/V203; taśma dolna ↔ dolne stopery. Odrzucane są obie sprzeczne autoryzacje. Dopuszczenia mechaniczne adaptera pozostają dodatkowo wymagane.

## Zgodność i migracja

- Wire FANUC pozostaje **v2, 227 pól, 80 B/kierunek**; bez zmiany layoutu lub LS.
- Retencja Context pozostaje **schema=4**, bez zmiany jej układu. HMI pozostaje **uiContractVersion=4**. Nowe statusy i konfiguracja są poza zachowywanym kontekstem.
- Importować nowy FB_StationOutputPolicy przed StationController; ponownie zaimportować zmienione DUT, GVL oraz symbole HMI. Dodać dwa nowe wejścia konfiguracji lokalnej polityki. Nie kopiować verified z fixture.
- Puszczenie HOME/WORK chwytaka nadal nie przerywa już przyjętego celu pneumatycznego. Odebranie dopuszczenia kierunku jest osobnym zdarzeniem.
- Recovery potwierdza fizycznie uzgodniony snapshot i zamyka odrzucone zdarzenia do bieżącego numeru. Nie odtwarza ich skutków i nie nadaje Start.

| Zachowany interfejs LEGACY | Rzeczywiste źródło funkcji w v4 |
|---|---|
| Wszystkie pola ST_BoxSeqCfg | Czasy urządzeń/transportu: Context.stationParameters; sesja/diagnostyka robota: robot Cfg |
| ST_TraySeqCfg poza tP4ConfirmTimeout | Parametry stacji i kontrakt FANUC; uiTraysInStack nie steruje technologią robota |
| Box/Tray Cmd.StopRequested | OrderManager NewOperations/FinishOperations i zarejestrowane zadania |
| Nieużywane wejścia i wyjścia oznaczone LEGACY w DUT | Nie podłączać ich jako nowej funkcji; aktywne porty wynikają z FB i aktualnego kontraktu |
| Dawne krańcówki M6 na HMI | Oddzielne wejścia v201/v202 |
| P4 na legacy HMI | Zapamiętana zajętość materiałowa; B205 nadal jest oddzielnym czujnikiem krawędzi |
| uiOutFreq_0p1Hz_3202 typu UINT w ścieżce zgodności | Zachowany symbol/przenoszony wzorzec bitów; dekodowany ze znakiem INT16 |

Deklaracji LEGACY nie usunięto, ponieważ zależności projektu natywnego i Vijeo wymagają weryfikacji. Ich edycja nie zmienia procesu.

## Weryfikacja i dalszy odbiór

Polecenie: `python -B tools/check_plc_release.py`. CI uruchamia je na Windows z Pythonem 3.15, bez połączeń z urządzeniami. Wykonanie CI na GitHub nastąpi dopiero po przekazaniu zmian do repozytorium.

Interpreter ogranicza przypisania deklarowanych BYTE/WORD/DWORD/UINT/UDINT/INT/DINT i modeluje jawne konwersje REAL_TO_UINT z zaokrągleniem do najbliższej, przy remisie parzystej. Wartość poza zakresem jest odrzucana. Nie odwzorowuje w pełni pośrednich wyników arytmetyki, precyzji REAL32, zegara firmware ani biblioteki GIATV. Natywne granice nadal wymagają prób Machine Expert.

Otwarte pozostają GAP-01/02/03/04/05/06/07/08/09/11/12. GAP-10 jest rozstrzygnięty funkcjonalnie. Nie wykonano wyboru projektu natywnego, konfiguracji sieci/retencji/napędów, budowy ekranów Vijeo, importu FANUC, nauki punktów, prób utraty energii ani FAT/SAT. Kolejność: zatwierdzenie map i polityk → kompilacja natywna → pojedyncze urządzenia → wspólne cykle obu produkcji → Stop N/N+1 i Drain/B304 → utrata danych i zasilania → FAT/SAT.

Wynik końcowy po poprawkach: **13/13 kontroli, 179 testów zachowania/czytelności — PASS**. Sprawdzono także składnię zmienionych modułów testowych, manifest 284 plików i git diff --check. Zestaw uruchomiono lokalnie; workflow GitHub Actions przygotowano, ale nie wykonano go na GitHub w tym zadaniu.
