# Program kuwet / BOX — FANUC

Stan: **źródła przygotowane offline; brak importu i uruchomienia na V9.40P/80**. Wejście: [MAIN_BOX.LS](MAIN_BOX.LS). Program komunikuje się wyłącznie z PLC; PLC/Festo wykonuje pneumatykę i elektryczny EUROMAP 67.

Źródłem LS jest [generator produkcji](../../tools/build_fanuc_tray.py) wraz z [sekwencją BOX](../../tools/fanuc_box.py) oraz [składaniem pełnych main](../../tools/fanuc_main.py). Nie edytować wygenerowanych LS. [Manifest](resources.json) zawiera dokładne R/F i stany; [punkty](points.csv) są nieuczone. Oba main pozostają na kontrolerze, z osobnymi nastawami i kontekstem. [COMMON](../COMMON/README.md) opisuje zasoby i lokalne komendy; [BG](../BG/README.md) pilnuje wyłącznego wyboru.

## Cykl i rozliczanie

1. Operator ręcznie uruchamia MAIN_BOX przy zamkniętym zleceniu. BG przyznaje właściciela BOX=1. Po jawnym przygotowaniu kontekstu i aktywnej konfiguracji otwarcie zlecenia oraz nowy fizyczny Start PLC uzbrajają cykl. Zastany startToken nie uruchamia programu.
2. PLC dostarcza pojemnik. Robot czeka na valid/ready windy i zachowuje stackId. Ruch w obszarze windy wymaga osobnego valid/granted. Winda utrzymuje pozycję pojemnika przez cały czas jego napełniania; robot dodaje offset Z warstw.
3. Przypisanie partii zachowuje cycleId, batchCount i przeznaczenie. Suma qty aktywnego profilu musi odpowiadać batchCount. Pobranie IMM używa potwierdzeń formy, wyrzutnika i próżni. immPickupCompleted następuje po wyjściu z formy.
4. Każda grupa ma maskę próżni, liczbę detali i własne cele siłowników. Po ich potwierdzeniu robot podchodzi nad punkt grupy, schodzi, zwalnia ją przez PLC i czeka na wynik przedmuchu, zanik próżni oraz pełne ACK zdarzenia. Dopiero wtedy zmienia remaining, slot i group. Następnie podnosi chwytak w tym samym XY, przywraca cele cylFold i wyjeżdża.
5. W warstwie kolejno napełnia P1, P2 i P3. Każda sekcja ma własną siatkę i skoki X/Y oraz własne nauczone bazy grup. X zmienia się najszybciej. Cała partia pozostaje w jednej sekcji.
6. Po ostatniej używanej sekcji wysyła layerFinished z indeksem warstwy od 0. To zdarzenie nie dolicza sztuk. Przy kolejnej warstwie pobiera jedną przekładkę z obszaru storage, odkłada i rozlicza spacerPlaced. Dopiero pełny ACK i wyjazd pozwalają zwiększyć indeks warstwy.
7. Nie ma przekładki na dnie ani po ostatniej warstwie. Ostatnia warstwa kończy się stackFinished. Potem wymagany jest nowy stackId oraz przygotowany pojemnik z PLC.

productsPlaced zawiera count/cycleId/stackId i zwiększa produkcję dobrych detali. Próbki obejmują cały następny przydzielony komplet; odrzuty mają pierwszeństwo. Obie dyspozycje jadą do miejsca próbek, mają osobne zdarzenia i nie zajmują slotów pojemnika.

## Nastawy BOX

Edytować wyłącznie staging R201–241. Sekcja APPLY kopiuje wszystkie 41 nastaw do R242–282 tylko przy zamkniętym zleceniu, HOME, ważnych statusach i sesji, rozliczonych wtryskach, znanym pustym chwytaku, braku przygotowanego pojemnika oraz stationIdleConfirmed. Błędny kandydat nie zmienia aktywnej kopii i blokuje cfgApplied. Zmiany staging podczas produkcji czekają na zamknięcie i opróżnienie stacji.

| Parametr w manifeście | Staging | Znaczenie w BOX |
|---|---|---|
| mask1…5 / qty1…5 | R201–210 | Rozłączne maski obwodów 1…5 i ilości sztuk; grupa wyłączona = oba 0 |
| gridX / gridY | R211–212 | Liczba pozycji P1 w X i Y; obie dodatnie |
| pitchX / pitchY | R213–214 | Skoki P1 w mm, również ujemne |
| trayHeight | R215 | **layerPitchZ**: przyrost Z między warstwami z uwzględnieniem materiału i przekładki |
| traysPerStack | R216 | **layerCount**: liczba warstw pojemnika |
| searchStep / searchLimit / maxAttempts | R217–219 | Ograniczone krokowe szukanie przekładki; nie ciągły SKIP po sieci |
| speed / timeout | R220–221 | Limit 1…100 (% dla J, mm/s dla L); czas w tickach zweryfikowanego zegara |
| tool / frame | R222–223 | Zweryfikowane numery UTOOL i UFRAME |
| cylFold / cylStraight | R224–225 | Cele siłowników dla bezpiecznych przejazdów/przekładki i pobrania IMM |
| trayMask | R226 | **spacerMask**: obwody przekładki; rozłączne z maskami produktów |
| p2X / p2Y / p2pitchX / p2pitchY | R227–230 | Siatka i skoki P2 |
| p3X / p3Y / p3pitchX / p3pitchY | R231–234 | Siatka i skoki P3 |
| cylGroup1…5 | R235–239 | Cele siłowników dla odkładania danej grupy produktów |
| productClearance / spacerClearance | R240–241 | Dodatnie odległości podejścia i podniesienia po Z |

Nazwy trayHeight/traysPerStack/trayMask są nazwami technicznymi wspólnego szablonu. W BOX mają znaczenie podane powyżej. P2/P3 wyłącza się przez X=0 i Y=0; jedna zerowa oś jest błędem. Pojemność każdej aktywnej sekcji musi być wielokrotnością liczby aktywnych grup. Nie ma limitu czterech sztuk na grupę. Suma qty mieści się w 1…65535.

Kod celu siłowników: bity 0…4 = HOME V501…505, 5…9 = WORK. Para 11 jest błędem; 00 pomija funkcję. Dla każdej używanej grupy wymagany jest cel wszystkich siłowników wskazanych w cylFold. V501 ma przeciwne cele w cylFold i cylStraight. Faktyczne znaczenie HOME/WORK oraz profil narzędzia podlega zatwierdzeniu; nie wpisano historycznych portów jako gotowej konfiguracji.

## Punkty i geometria

PR1 jest wspólnym HOME; potwierdzić zgodny, najlepiej osiowy zapis dla obu narzędzi. BOX rezerwuje PR41–95. Nie ma współrzędnych starego robota ani punktów zastępczych.

| Punkty | Przeznaczenie |
|---|---|
| PR41–46 | Wjazd do magazynu przekładek, początek/dolna granica szukania, podniesienie, wyjazd |
| PR47, PR50, PR62 | Wjazd/wyjazd windy i podejście nad produkty; drogi ponad całym zatwierdzonym stosem warstw |
| PR49 | Baza odłożenia przekładki na górze pierwszej warstwy |
| PR51–56 | Drogi IMM, pobranie i wyjazd |
| PR57–61 | Bazy grup P1 na pierwszej warstwie |
| PR63–67 | Bazy grup próbek/odrzutów |
| PR68–70 | Roboczy offset, szukanie i wyliczona pozycja |
| PR71–73 | Wjazd/wyjazd próbek i droga HOME |
| PR80–84 / PR85–89 | Bazy grup P2 / P3 na pierwszej warstwie |
| Pozostałe | Nieużywane pozycje szablonu lub rezerwa; patrz points.csv |

Produkty: baza grupy + (kolumna × pitchX, wiersz × pitchY, indeksWarstwy × layerPitchZ). Przekładka: PR49 + indeksWarstwy × layerPitchZ. Nie przesuwać równocześnie windy o ten sam przyrost. productClearance i spacerClearance są kierowane w dodatnie Z zatwierdzonego UFRAME. Należy zweryfikować orientacje, konfiguracje osi, TCP, ładunki, granice ruchu i obwiednie całego wypełnionego pojemnika. PR44 jest dolną granicą szukania przekładki.

Każdy J/L poprzedza sprawdzenie SAFE, a nauczone bazy mają osobne flagi taught. Zatwierdzenia profilu, ruchu, alarmów i natywnych statusów są domyślnie wyłączone.

## Stop i recovery

Zwykły Stop zachowuje niepełny pojemnik. Kończy przypisaną partię oraz faktycznie rozpoczęty N+1. Jeśli do jego zakończenia potrzebna jest przekładka lub wymiana pojemnika, wykonuje te czynności. Nie zaczyna nowego wtrysku.

Przed pierwszym ruchem do magazynu przekładki Stop bez nierozliczonego wtrysku anuluje oczekiwanie i prowadzi do HOME. spacerNeeded pozostaje zachowane. Od ustawienia spacerStarted, tuż przed pierwszym ruchem wejścia po przyznaniu dostępu, rozpoczęte pobranie/odłożenie i pełny ACK muszą się zakończyć. Brak przekładki przed rozpoczęciem to oczekiwanie stacji, a ograniczone szukanie już rozpoczętego pobrania ma kontrolowaną granicę.

R283–307 zawierają kontekst: m.in. cycleId/batchCount/remaining, group, slot, indeks warstwy trayIndex, stackId, sectionIndex i loadKind (0 brak przypisanego ładunku, 1 produkty, 2 przekładka). Fizyczny ładunek opisują osobno loadKnown/loadMask kontraktu. Flagi spacerNeeded/spacerStarted/terminalPending zachowują stan czynności. Nie edytować ich podczas automatu.

Po błędzie stan 900 blokuje ruch. Wymagane są aktualne HOME, jawne sprawdzenie ładunku i danych PLC, wygaszone kanały, synchronizacja, recoveryApproved i contextChecked. Sekcja RECOVERY może odzyskać spójną pozostałą część partii, bez ponownego pobrania rozliczonych detali. Potem wymaga świeżego Startu.

terminalPending, spacerStarted lub loadKind=2 blokują automatyczną rekonstrukcję. Niepewny wynik layerFinished/spacerPlaced/stackFinished, zwolnienia grupy czy ACK wymaga ręcznego uzgodnienia trwałych skutków z PLC i fizycznego sprawdzenia stanowiska. Dopiero zapisany wynik tej procedury pozwala poprawić kontekst. Nie kasować flag, aby obejść blokadę, i nie odtwarzać zdarzenia na podstawie domysłu.

Sekcja NEW to jawne rozpoczęcie nowego, pustego kontekstu przy zamkniętym zleceniu, po fizycznym opróżnieniu/uzgodnieniu stacji. Sekcja INIT zeruje wyłącznie lokalny bank i jest dopuszczalna tylko w wybranym nieuzbrojonym main, przy pustym postoju i zamkniętym zleceniu. Zwykły Stop nie wymaga żadnej z tych procedur.

## Przygotowanie i odbiór

Obowiązuje wspólna [procedura inicjalizacji i zmiany trybu](../COMMON/README.md). Nie importować pakietu TEST z produkcją. **Przed importem sprawdzić dostępność R1–400, F do 759 i PR do 95** oraz kolizje z istniejącymi makrami/BG. Nie zmieniono pojemności fizycznego kontrolera.

Testy: python -B tools/check_fanuc_box.py. Wykonują wygenerowane instrukcje LS z syntetycznym modelem PLC/Festo, punktów i statusów. Import FANUC, harmonogram BG, fizyczna reakcja UALM, PLC v2, nauka punktów i FAT/SAT pozostają niewykonane.
