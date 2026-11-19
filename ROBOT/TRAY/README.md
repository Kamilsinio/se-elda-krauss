# Program tacek / Blistrów — FANUC

Stan: **źródła przygotowane i sprawdzone offline; brak importu V9.40 i odbioru stanowiska**. Program dotyczy M-20iD/25 z R-30iB Mate Plus. Źródła BOX są w [osobnym pakiecie](../BOX/README.md); PLC i fizyczny robot nie zostały przeprogramowane.

Punktem wejścia jest [MAIN_TRAY.LS](MAIN_TRAY.LS). Pełna technologia, ruchy, chwytak i zdarzenia są w tym pliku, w opisanych sekcjach. Kroki pozostają jawne dla diagnostyki i recovery. [resources.json](resources.json) opisuje stan, parametry, flagi i właścicieli pamięci, a [points.csv](points.csv) punkty wymagające nauczenia. Źródła generuje tools/build_fanuc_tray.py; zmieniać generator, następnie odtwarzać i sprawdzać LS.

## Zachowanie cyklu

1. Operator wybiera i uruchamia program na FANUC. Po sprawdzeniu konfiguracji program czeka na nowy startToken PLC, pochodzący z przyjętego fizycznego Startu. Zastany token nie uruchamia ani nie wznawia pracy.
2. Robot pobiera pustą tackę po przyznaniu dostępu do źródła. Szukanie odbywa się krokami z ograniczeniem zejścia i liczby prób. Nie używa ciągłego SKIP po opóźnionym sygnale PLC.
3. Po przyznaniu dostępu do windy odkłada tackę i rozlicza blisterPicked/blisterPlaced. Przedmuch wykonuje PLC; robot czeka na wynik, pełne ACK=0 i zanik potwierdzonej próżni.
4. Dla przydzielonego wtrysku zapamiętuje cycleId, batchCount i przeznaczenie: 0 dobre, 1 próbki, 2 odrzuty. Pozwolenia formy i wyrzutnika są żądaniami do PLC. Pobranie wymaga aktualnych potwierdzeń; po wyjściu z formy wysyłane jest immPickupCompleted.
5. Detale odkładane są kolejno grupami. Każda grupa ma maskę obwodów i ilość sztuk. Jedno odłożenie grupy zajmuje jedną pozycję X/Y. Fizyczne zwolnienie poprzedza zdarzenie; licznik pozycji i pozostałej ilości zmienia się dopiero po pełnym REQ/ACK.
6. Pełna tacka daje blisterFinished, pełny stos stackFinished. Te zdarzenia nie doliczają ponownie sztuk. Po stosie robot czeka na nowy stackId PLC.
7. Próbki obejmują cały następny przypisany komplet; odrzuty mają pierwszeństwo i jadą tą samą drogą do miejsca próbek. Są rozliczane osobno, bez zapełniania pozycji tacki. Nie ma drugiego równocześnie przyjętego żądania próbek.

Zwykły Stop kończy rozpoczęte operacje, również rzeczywiście rozpoczęty N+1. Nie czeka na formę cyklu, który nie ruszył. Nie wysyła fałszywego blisterFinished dla niepełnej tacki. W stanie 710 zachowuje częściową tackę i wymaga nowego Startu do normalnego wznowienia. Późno zgłoszona rozpoczęta operacja nadal jest kończona przy finishPermit.

Koniec zlecenia kończy operacje robota; opróżnianie całej stacji realizuje PLC. Zamknięcie zlecenia unieważnia możliwość ponownego użycia starego kontekstu. Sekcja NEW wymaga zamkniętego zlecenia i jawnego potwierdzenia pustego stanowiska. Otwartych zleceń nie zeruje się tą procedurą.

## Parametry operatora i profil chwytaka

R1–26 to nastawy do zastosowania. Program pracuje z kopią aktywną R27–50 oraz R177–178. Bez zatwierdzonej kopii ruch jest zablokowany. Dokładne powiązania znajdują się w resources.json.

| Nastawa | Rejestry edytowane | Znaczenie |
|---|---|---|
| mask1…mask5 | R1–5 | Bity 0…4 odpowiadają obwodom próżni 1…5 |
| qty1…qty5 | R6–10 | Ilość sztuk odłożonych daną grupą; nie liczba ssawek |
| gridX/gridY | R11/R12 | Liczba pozycji w osiach X/Y, iloczyn do 65535 |
| pitchX/pitchY | R13/R14 | Skok w mm; X zmienia się najszybciej |
| trayHeight/traysPerStack | R15/R16 | Wysokość tacki i liczba tacek w stosie; krok szukania nie przekracza wysokości tacki |
| searchStep/searchLimit/maxAttempts | R17–19 | Krok, maksymalne zejście i liczba kroków szukania |
| speed/timeout | R20/R21 | Wspólny limit 1…100: procent dla J, mm/s dla L; timeout w surowych tickach zegara |
| tool/frame | R22/R23 | Zatwierdzone numery UTOOL/UFRAME istniejące na kontrolerze |
| cylFold/cylStraight | R24/R25 | Zakodowane cele siłowników w drogach tacki/odkładania i IMM |
| trayMask | R26 | Obwody pobierania pustej tacki; niezależne od grup detali |

Cele siłowników: bity 0…4 oznaczają HOME V501…V505, a 5…9 WORK V501…V505. Para 00 pomija nieużywaną funkcję, 11 jest błędem. V501 musi mieć wskazany przeciwny cel dla obu faz; nie wybieramy z góry polaryzacji HOME/WORK. Profile F-2680 i F-2844 nie są automatycznie utożsamiane; polaryzację V501 i sprzeczne przyłącza F-2680 trzeba potwierdzić przed zatwierdzeniem profilu.

Maski grup są rozłączne i nie nakładają się na trayMask. Grupa nieaktywna ma mask=0 oraz qty=0. Aktywna ma dodatnią ilość i maskę. Suma qty ma zakres 1…65535 i musi odpowiadać batchCount danego wtrysku. Pojemność X×Y jest wielokrotnością liczby aktywnych grup: nie ma wymiany tacki z pozostałymi detalami w chwytaku. Nie ma stałego limitu czterech sztuk.

Sekcja APPLY wymaga zamkniętego zlecenia, ważnej sesji i statusów, HOME, znanego pustego chwytaka, rozliczonych wtrysków, braku przygotowanej tacki i jawnego stationIdleConfirmed. Edycja nastaw podczas pracy nie zmienia kopii aktywnej. Nie edytować aktywnych rejestrów ani kontekstu przez HMI lub pendant poza opisaną procedurą recovery.

Wszystkie nastawy inicjalizują się zerami i blokują uruchomienie. Wartości z testów są syntetyczne. Czasów, prędkości i geometrii nie traktować jako zatwierdzonych nastaw maszyny.

## Punkty do nauczenia i blokada ruchów

PR1–40 są zarezerwowane. Nie zawierają współrzędnych starego robota ani sztucznych punktów zerowych.

- PR1: HOME zgodne z zatwierdzoną Reference Position.
- PR2–7: dojazd do źródła, początek i dolna granica szukania, podniesienie oraz wyjazd.
- PR8–11 i PR35: wjazd, podejście, odłożenie tacki, podniesienie i wyjazd z windy.
- PR12–17: dojazd, oczekiwanie, wejście, pobranie, wycofanie i opuszczenie formy.
- PR18–22: pozycja bazowa odkładania każdej aktywnej grupy. Uwzględnia rzeczywisty układ chwytaka.
- PR23: podejście nad produkty. PR24–28: odłożenie poszczególnych grup do miejsca próbek/odrzutów.
- PR29–31: pamięć robocza offsetu, szukania i pozycji. PR32–34: drogi próbek oraz dojścia do HOME.
- PR36–40: rezerwa, bez wymagania uczenia w obecnej wersji.

Punkty ruchowe wymagają poprawnego typu, konfiguracji robota i zgodności UF/UT. Szukanie zakłada zejście po Z zatwierdzonego UFRAME; PR5 wyznacza dolną granicę Z. Nauczyć też drogi dojścia przy niesieniu tacki i wszystkich używanych grup produktów. Native mastering, payload, TCP, kinematyka i kolizje wymagają sprawdzenia na fizycznej konfiguracji.

Każdy ruch poprzedza sekcja SAFE i sprawdzenie flagi taught danego punktu. motionApproved, profileApproved, alarmApproved i bindingsVerified są domyślnie OFF. Nie ustawiać ich zbiorczo do testu na rzeczywistym robocie. Nauka przez ręczne pozycjonowanie nie jest odbiorem sekwencji AUTO; wykonywanie programu produkcyjnego wymaga aktualnego AUTO, wyłączonego TP i właściwych pozwoleń.

## Inicjalizacja, zwykłe wznowienie i recovery

Nie wykonywać żadnego INIT przy niesionym ładunku lub nierozliczonych zdarzeniach. INIT zeruje pamięć; recovery zachowuje kontekst.

Przy pierwszym przygotowaniu pustego stanowiska obowiązuje [procedura COMMON](../COMMON/README.md): weryfikacja R1–400/F/PR i pamięci programów, 14 natywnych powiązań, trzy BG oraz jawna wspólna inicjalizacja pustej stacji przy obu zakończonych main. Potem ręcznie uruchomić MAIN_TRAY przy zamkniętym zleceniu; BG przyznaje TRAY=2. Ewentualny prywatny INIT działa już wewnątrz wybranego nieuzbrojonego main. NEW/APPLY/RECOVERY również wymagają jego właściciela. Po wejściu zakończyć świeżą obustronną synchronizację do recovery przed NEW i APPLY.

Po przyznaniu wykonać jawne sekcja NEW (newApproved), zastosować nastawy przez sekcja APPLY przy stationIdleConfirmed i zatwierdzić profil, punkty oraz reakcję alarmu. Otworzyć zlecenie dopiero po gotowości sesji. Wymagany jest nowy fizyczny Start PLC. BOOT nie uzbraja i nie przyjmuje zastanego startToken. Nie konfigurować automatycznego startu main ani UOP START.

INIT zeruje tylko prywatny bank tacek, przy zamkniętym zleceniu i potwierdzonym pustym postoju wybranego, nieuzbrojonego main. Bindingi, natywne statusy i właściciel należą teraz do COMMON; stare F9–11/F47–58 nie są źródłami statusów; F47/F48 służą teraz do APPLY/EXIT. Zmiana wymaga spójnego importu wszystkich aktualnych pakietów.

Zwykły Stop pozostawia main w stanie 710. Nie wykonywać INIT ani sekcji NEW; kolejny fizyczny Start wznawia zachowany kontekst.

Po ABORT, utracie sesji, krytycznej blokadzie lub ręcznym przemieszczeniu:

- Sprawdzić rzeczywisty ładunek, maskę obwodów, pozostałą ilość, grupę, tackę, stos i rejestr wtrysków PLC. Maska jest zachowana; przy utracie pewności loadKnown jest unieważniane.
- Stan 900 sam nie ponawia ruchów ani zdarzeń. Pole resumeState i step wskazują miejsce przerwania.
- Niepewne odłożenie/ACK uzgodnić z PLC. Dopiero na tej podstawie operator koryguje kontekst i potwierdza contextChecked (F4). Nie uznawać utraty podciśnienia za dowód policzonego odłożenia.
- Powrócić ręcznie uzgodnioną drogą do rzeczywistego HOME. Wygasić stare REQ/ACK po obu stronach i zakończyć synchronizację do RECOVERY.
- Ustawić recoveryApproved (F3), usunąć przyczynę i skasować alarm. Ta flaga pozwala przeprowadzić uzgodnienie bez ciągłego ponawiania UALM; nadal nie daje pozwolenia ruchu.
- sekcja RECOVERY sprawdza HOME/AUTO, stan kanałów, pozostałą ilość i maskę. Po całkowicie rozliczonej partii usuwa jej przypisanie, aby nie pobrać jej drugi raz. Nie generuje zaległych zdarzeń. MAIN obsługuje ją w stanie 900 po obu potwierdzeniach operatora.
- Po przyjętym recovery ruch nadal jest zablokowany do nowego fizycznego Startu. Nie wznawiać starej instrukcji ruchowej z nieuzgodnionej pozycji.

Jeżeli przerwano pobieranie pustej tacki, najpierw ręcznie uzgodnić jej odłożenie i stan zdarzeń PLC; program nie podejmuje od nowa szukania z tacką w chwytaku. Przy pełnej tacce (slot równy pojemności) recovery jest blokowane kodem 1408 do ręcznego uzgodnienia końcowych zdarzeń i korekty kontekstu z PLC. Nie przesuwać indeksów na podstawie domysłu.

Sekcja EXIT zgłasza zwolnienie właściciela. BG przyjmuje je ze stanu 710, 720 lub 900 przy zamkniętym zleceniu, HOME, rozliczonych wtryskach/kanałach, remaining=0, braku partii, znanym pustym chwytaku oraz stationIdleConfirmed. Main kończy się po przyjęciu zwolnienia. Przed BOX trzeba zakończyć również natywne zadanie TRAY, w tym PAUSE. Pełna procedura i konflikt obu main: [COMMON](../COMMON/README.md).

## Diagnostyka i sprawdzenia

| Stan | Znaczenie |
|---|---|
| 10 | oczekiwanie / przypisanie partii |
| 200–295 | pobranie i odłożenie pustej tacki |
| 300–380 | pobranie z formy i ACK |
| 400–490 | częściowe odkładanie oraz rozliczenie grup |
| 500–620 | pełna tacka / stos / oczekiwanie na nowy stos |
| 700/710 | dojście do HOME / postój |
| 720 | zlecenie zamknięte w HOME, oczekiwanie na lokalne NEW i stationIdleConfirmed |
| 900 | uzgodnienie stanu |

FaultCode: 1001 parametry; 1100 brak dopuszczenia ruchu; 1101 punkt/granica szukania; 1102 nieznany stan; 1201 przedmuch; 1301–1303 przypisanie partii; 1401–1408 niespójność recovery; 1501 granice szukania; 1502 zastana próżnia tacki; 1601 brak miejsca; 1700+stan timeout; 1800 BG; 1900 niespójność sekwencji. Przyczyna jest odrębna od step/resumeState.

Czekanie na dostęp do źródła/windy i nowy stos nie jest automatycznie eskalowane do krytycznego timeoutu ostrzeżeń stacji PLC. Czynności chwytaka, formy i ACK mają osobne kody miejsca oraz konfigurowany limit. Fizyczną klasyfikację i reakcje zatwierdza odbiór alarmów.

~~~powershell
python -B tools/build_fanuc_comm.py --check
python -B tools/build_fanuc_tray.py --check
python -B tools/check_robot_contract.py
python -B tools/check_fanuc_comm.py
python -B tools/check_fanuc_tray.py
python -B tools/check_fanuc_box.py
python -B tools/check_fanuc_readability.py
~~~

21 testów tacek, 24 testy BOX i 16 testów komunikacji oraz 4 kontrole czytelności wykonuje rzeczywiste instrukcje LS z modelem wejść, PLC/Festo i ruchów. Modelowe PR oraz źródła statusów nie pochodzą z fizycznego robota. Wynik nie potwierdza poprawności kinematyki, harmonogramu BG, działania alarmu ani importu LS. Import/kompilacja V9.40, pomiary, uruchomienie PLC v2 i FAT/SAT pozostają NIEWYKONANE.
