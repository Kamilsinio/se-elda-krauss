# Integracja stacji — stan źródeł 2026-11-15

**Wykonano integrację i weryfikację offline. Kompilacja natywna oraz próby na urządzeniach pozostają do wykonania.** Poprzedni pakiet modułów zapisano osobno w commicie `de67d17`. Niniejszy zakres rozwija ten pakiet; wymagania i otwarte dane sprzętowe nadal określa [plan odbioru](implementation-plan.md).

## Architektura i kolejność skanu

`PRG_Main` odczytuje I/O raz, tworzy snapshot `ST_StationCfg` i `ST_StationInputs`, wywołuje jeden `FB_StationController`, publikuje `ST_StationOutputs`, wywołuje jeden `FB_ElevatorDriveAdapter` i zapisuje I/O raz. Nie należy dodawać PRG_IO_Read/Write do zadania osobno. Sterownik stacji nie odwołuje się do GVL ani do adresów fizycznych. Typy dotychczas osadzone w GVL_IO/GVL_HMI przeniesiono do osobnych DUT w StationController.

Controller zachowuje osobne instancje urządzeń i sekwencji. Kolejność obejmuje normalizację wejść, nadzór robota i zlecenia, uzgodnienie stacji, arbitraż zasobów, wykonawców, aktualizację modelu materiału, aktualne alarmy oraz końcową komendę wyjść. Finalizacja blokady krytycznej nie wywołuje ponownie timerów, rejestru cykli ani kanałów zdarzeń. Odbiera pozwolenia TX, dostęp do obszarów, wyjścia EUROMAP i ruch napędów w tym samym skanie. Chwytak i cewki przechodzą wyłącznie na zweryfikowaną politykę utraty; nie założono uniwersalnego odpuszczenia ładunku.

`FB_Elevator` jest logiką ruchu. Jedyny `GIATV.Control_ATV` znajduje się w adapterze natywnym, z istniejącym `Altivar_320`; Axis_Ref, biblioteka i magistrala wymagają GAP-06. Pomiar `drive.actualHz` i jego ważność są oddzielne od komendy. `GVL_Station.DriveFrequencyValid` ma pochodzić ze zweryfikowanego pomiaru, nie ze stałej TRUE. Adapter zwraca snapshot z poprzedniego wykonania do kolejnego skanu logiki; opóźnienie jednego zadania trzeba uwzględnić podczas odbioru.

## Zasoby, operacje i materiał

| Indeks zasobu | Znaczenie |
|---|---|
| 1 | Górna taśma |
| 2 | Oś windy |
| 3 | Taśma windy |
| 4 | Dolna taśma |
| 5 | Wydanie i odbiór B304 |
| 6 | Magazyn przekładek |

StationTransport rezerwuje zasoby potrzebne konkretnej operacji. Po wydaniu ładunku na P7 zachowuje rezerwację B304, a zwalnia dolną taśmę. Oczekiwanie na odbiór nie blokuje niezależnej produkcji do wolnych buforów. Nowe wydanie wymaga zakończenia poprzedniego odbioru. Aktywność produkcyjna ma oddzielne rezerwacje zasobów; pole zbiorcze owner służy także do prezentacji i nie jest globalną blokadą całej stacji.

Identyfikatory operacji i zdarzeń materiałowych pochodzą z retencji `Context.station`. TopFlow, BottomAccumulator i Elevator publikują przyjęty identyfikator oraz identyfikator zakończenia. Scheduler przyjmuje wyłącznie wynik zgodny z aktywną operacją. Powtórzony stary wynik nie kończy następnego podania. Wyczerpanie UDINT wymaga kontrolowanej migracji; nie ma zawijania ani zerowania liczników przy recovery.

`StationMaterial` jest właścicielem zajętości P1–P7. W integracji korzysta ze zdarzeń przybycia, zakończonego przejazdu i potwierdzonego odbioru; aktualizacja całej partii zdarzeń jest atomowa. Powtórzenia są ignorowane, luka w numeracji lub sprzeczne źródło/cel odbierają known i wymagają uzgodnienia. Zgaśnięcie B205 podczas obniżania windy nie kasuje ładunku P4. Snapshoty wewnętrzne sekwencerów nie zastępują całego modelu materiału po dowolnym ruchu.

Podczas opróżniania ST.1 podejmuje stabilny ładunek z P1 także bez wcześniejszego zatwierdzenia załadunku. Zakończenie przejazdu z P1 wymaga obserwacji zajęcia i zwolnienia bariery P2. Wydanie z P5 przebiega przez potwierdzony postój na P6. Oba odcinki zachowują ten sam identyfikator wydania. Rozpoczęcie innego ruchu dolnej taśmy zachowuje informację o obecności wydanego ładunku na B304 aż do potwierdzenia odbioru.

Gotowość BOX wymaga znanego pojemnika na P4, potwierdzonego zejścia z B205 podczas ruchu do krawędzi i postoju osi. Dojazd na dół lub następne pozycjonowanie unieważnia potwierdzenie krawędzi. Po zamknięciu opróżnionego zlecenia PLC nadaje następny identyfikator stosu i zeruje indeksy stosu. Liczniki całkowite i identyfikatory zdarzeń transportu zachowują ciągłość. Po utracie potwierdzenia krawędzi przy częściowo napełnionym pojemniku potrzebne jest uzgodnienie postoju przy aktywnym B205. Wtedy kolejny fizyczny Start pozwala ponownie wypozycjonować ten sam pojemnik i zmierzyć krawędź. PLC udostępnia otwarcie następnego zlecenia po potwierdzeniu nowego kontekstu przez FANUC.

## Stop, Manual i recovery

Normalny Stop odbiera nowe cykle, a rozpoczęte operacje kończą się na dotychczasowym właścicielu. Drain zatrzymuje wybór następnego działania i czeka na świeży fizyczny Start. Końcowe zamknięcie zlecenia wymaga pustego, znanego modelu, rozliczonych operacji i ostatniego potwierdzenia odbioru B304. Lokalny przycisk wydaje jeden gotowy ładunek bez kolejki i bez uruchomienia całego Drain.

Nowy `FB_StationRecovery` oddziela uzgodnienie materiału po Manual/resetowaniu kroku od odtwarzania sesji robota. Ocenia rzeczywisty postój taśm i ważny pomiar zatrzymanej osi; zatrzaśnięty owner lub sam wymóg recovery nie blokuje jego własnego rozliczenia. Bieżący brak ważnych danych, ruch ręczny i blokada procesu nadal uniemożliwiają zatwierdzenie. Proposal wymaga znanej zajętości i zgodności occupied[4] z elevatorLoadPresent. Uzgodnienie kończy rezerwacje i odtwarza model w postoju, bez automatycznego odtwarzania ruchu w połowie kroku. Nie nadaje Start.

Ręczny EUROMAP na panelu 201 korzysta z `GVL_HMI.vijeo.immManual`. Publiczne pola positive[0..3] i holdCounter[0..3] odpowiadają kolejno zamknięciu formy, pełnemu otwarciu, wyrzutnikowi w tył i wyrzutnikowi w przód. PLC wymaga tej samej sesji HMI i zwolnienia przycisku przed ponownym naciśnięciem. Przeciwstawne żądania są odrzucane. Wymagane są Manual, HOME, brak pracy z robotem, postój i blokady IMM. Polecenia manualne przekazane bezpośrednio w Plant nie obchodzą tego nadzoru. Dotychczasowe ręczne sterowanie chwytakiem i stationManual pozostaje oddzielne.

## Poprawki istniejących modułów

| Miejsce | Zachowanie po zmianie |
|---|---|
| StopperPair | Timeout odbiera ruch w tym samym skanie; ważność komendy zapobiega uznaniu zer za nakaz odpuszczenia |
| Cyl2Pos / StopperPair | HOME/WORK są pomiarem także przy wyłączonym Enable; timeout ruchu wymaga faktycznie zastosowanej komendy |
| StationCoils | Pamięta zwolnienie Manual aż blokada zmiany zaworu pozwoli zastosować politykę |
| Conveyor | Zmiana kierunku może wymagać fizycznego postoju; Running odpowiada opublikowanej komendzie |
| TopFlow | Oddzielny wynik transferu i ID; ostrzeżenie zależnego urządzenia blokuje ruch bez wtórnego krytycznego timeoutu |
| BottomAccumulator | Żądanie trwa do przyjęcia; odbiór B304 jest niezależny od przejazdów bufora, z własnym ID i zamrożoną filtracją |
| Elevator | STOPPING wymaga ważnej stabilnej prędkości poniżej progu; timeout oznacza błąd, a nie IDLE |
| Storage | Oddzielne timeouty lewej/prawej osłony, także w Manual |
| StationDrain | Zajęta winda z zablokowanym dołem nie jedzie na górę po kolejny ładunek |
| RobotRecovery | Fizyczny postój niezależny od logicznego owner; zachowana generacja HMI i liczniki operacji |
| MAIN_TRAY / MAIN_BOX | Koniec zlecenia przed pierwszym Start produkcji może potwierdzić już obserwowany HOME i pusty chwytak bez uruchamiania ruchu |

Zmiana LS powstała w generatorze, bez ręcznej korekty wygenerowanych programów. Wire pozostaje v2, 227 pól i 80 B w każdym kierunku. Nie dodano zdalnego Start ani wyboru programu UOP.

## Migracja i kolejność uruchomienia

1. Zachować backup projektu natywnego i retencji. Nie reinterpretować binarnie starego kontekstu po zmianie układu DUT.
2. Importować wszystkie DUT przed FB, następnie GVL i programy; nowe kontrakty to **schema=4 oraz HMI uiContractVersion=4**. Nazwa hmiV2 pozostaje historycznym symbolem. Schema 2/3 nie jest akceptowanym Proposal.
3. Przenieść potwierdzone ładunki, cykle, parametry i liczniki do jawnego Proposal wersji 4. Zachować niepowtarzalność nowych ID oraz bieżącą generację HMI. Uruchomić kontrolowaną procedurę uzgodnienia w fizycznym postoju.
4. Potwierdzić docelowy projekt Machine Expert, bibliotekę GIATV, Axis_Ref, zadanie, okres i retencję. Skompilować z rzeczywistymi bibliotekami. Fixture z tools nie jest częścią projektu PLC.
5. Zamknąć zależne GAP mapowania Festo, polaryzacji, B205/B301/B304, bariery, początku/końca wtrysku, zatrzymania taśm i pneumatycznych polityk utrzymania. Uzupełnić macierz alarmów GAP-12; nieznane klasy pozostają niezatwierdzone.
6. Zaimportować rzeczywiste symbole PLC do Vijeo i wykonać ekrany. Przeprowadzić osobny import/odbiór FANUC V9.40, dostępności zasobów, native statusów, punktów i narzędzia.
7. Wykonać testy pojedynczych urządzeń, wspólne cykle obu produkcji, utraty danych/zasilania, Stop N+1, wszystkie warianty Drain i FAT/SAT.

## Dowody offline

[Raport weryfikacji](station-verification.md) rozdziela przegląd statyczny, wykonanie ST/LS w interpreterach i niewykonane próby natywne. `tools/plc_station_cosim.py` wykonuje rzeczywisty StationController i oba wygenerowane main przez kodek 80 B. Syntetyczne są wyłącznie źródła native, czujniki i mechanika urządzeń. Model nie wpisuje ACK zakończenia do kontekstu PLC. Parametry i zweryfikowane flagi fixture nie stanowią zatwierdzenia nastaw maszyny.

Oddzielny test 256 wariantów początkowej zajętości używa modelu koordynacji z syntetycznym wykonawcą przejazdu. Nie należy przedstawiać go jako 256 prób całego fizycznego kontrolera. Pełna symulacja obejmuje dwa stosy obu produkcji, Stop N+1, opróżnianie z pauzą i końcowym odbiorem, Manual/recovery, zanik I/O oraz blokadę krytyczną bieżącego skanu.

## Poprawki po review

[Pakiet poprawek](plc-review-fixes.md) zmienia kolejność końca skanu: wykonawcy Storage/Elevator → bieżące alarmy → StationCoils i końcowa finalizacja. FB_StationOutputPolicy waliduje polityki przed nadzorem. LocalFaultPolicy jest obowiązkową, odrębną macierzą serwisową; brak zatwierdzenia nie jest zastępowany TRUE. Po lokalnej usterce sam Reset nie wznawia ruchu. Recovery zamyka odrzucone zdarzenia do bieżącego nextMaterialEventId bez cofania licznika. Wire v2, Context schema=4 i HMI v4 pozostają bez zmian; nowe porty wymagają ponownego importu symboli.

## Nazwa zarezerwowana ACTION — zmiana symboli

Zgodnie z wymaganiem użytkownika deklaracje PLC o dokładnej nazwie `action` mają nazwę `action_`. Dotyczy to pól w ST_StationOperation, ST_StationTransportStatus, ST_StationDrainStatus i ST_StationHmiStatus oraz wszystkich odwołań w FB i modelach testowych. Kontrola struktury wykrywa nazwę ACTION niezależnie od wielkości liter w deklaracjach zmiennych i polach DUT.

Aktualne ścieżki obejmują `GVL_Station.Transport.action_`, `GVL_Station.Transport.resources[i].action_`, `GVL_Station.DrainStatus.action_` oraz `GVL_HMI.hmiV2.station.action_`. Po imporcie odświeżyć symbole i powiązania HMI. Istniejące `actionText`, `actionDone`, `actionFault`, `drainAction` i `stationAction` zachowują nazwy. Kolumna `action` w pliku migracji CSV i słowo kluczowe `action` biblioteki Python argparse nie są deklaracjami PLC.

Zmiana nazw nie zmienia typów, kolejności pól, numerów enum ani wire FANUC v2/80 B. Schema kontekstu pozostaje 4. Ze względu na pole operacji wewnątrz Context przed importem zachować backup i ponownie zweryfikować listę persistent oraz odtworzenie danych w projekcie natywnym.

## Nazwa zarezerwowana PROGRAM — zmiana symboli

Dokładna nazwa identyfikatora `program` otrzymuje końcowy podkreślnik: `program_`. Zmieniono pola `ST_RobotContext.program_`, `ST_RobotCommands.program_`, wejście `FB_RobotCycleLedger.Program_`, wszystkie odwołania ST oraz odpowiadające im klucze i argumenty testów offline. Słowo kluczowe `PROGRAM` deklarujące PRG_Main/PRG_IO_Read/PRG_IO_Write, komentarze, teksty operatora i identyfikatory kontraktu komunikacyjnego zachowują dotychczasową postać.

Aktualna ścieżka zachowywanego pola to `GVL_RobotRetain.Context.program_`, a kandydata recovery `GVL_Robot.Proposal.program_`. Audyt odrzuca deklaracje o nazwach ACTION i PROGRAM niezależnie od wielkości liter. Nazwy `production_program`, `production_expectedProgram` i `uiProgram` pozostają poprawnymi, odrębnymi symbolami.

Układ wire v2/80 B, typy, kolejność pól i schema=4 pozostają bez zmian. Przed importem zachować backup i zweryfikować listę persistent oraz mapowanie odtwarzanego kontekstu po zmianie nazwy pola. Odświeżyć eksport symboli i wszystkie zewnętrzne powiązania korzystające z dawnej nazwy.

## Nazwa zarezerwowana REFERENCE — zmiana symboli

Pole `ST_ElevatorDriveCmd.reference` otrzymuje nazwę `reference_`. Zaktualizowano producenta komendy w FB_Elevator, oba zerowania przy blokadzie krytycznej w FB_StationController, odczyt w FB_ElevatorDriveAdapter oraz test adaptera. Przed kompilacją w Machine Expert ponownie zaimportować DUT i deklaracje oraz implementacje zależnych FB. Audyt odrzuca nazwę REFERENCE niezależnie od wielkości liter. Typ WORD, skala prędkości i port biblioteki GIATV `i_wSpdRef` pozostają bez zmian.
