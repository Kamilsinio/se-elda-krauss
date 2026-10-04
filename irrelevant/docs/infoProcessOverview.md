# Opis procesu stacji - tray, box, emptying i manual

## Cel dokumentu

Ten dokument opisuje calosciowy przebieg pracy stacji paletyzacji.

Nie opisuje szczegolowo kodu kazdego FB, bo to jest w osobnych plikach. Tutaj chodzi o odpowiedz na pytania:

- co operator robi na stacji,
- jak pojemniki przechodza przez pozycje P1-P7,
- co dzieje sie w trybie tacek,
- co dzieje sie w trybie kuwet,
- jak dziala oproznianie stacji,
- jak dziala manual,
- gdzie w procesie uczestniczy robot,
- na co patrzec przy uruchomieniu.

Najwazniejsze pliki powiazane:

- `infoMainProgram.md` - jak `PRG_Main` spina calosc,
- `infoProgramDependencies.md` - zaleznosci FB,
- `infoTopFlowManager.md` - gorny bufor P1-P3,
- `infoTraySequencer.md` - tryb tacek,
- `infoBoxSequencer.md` - tryb kuwet,
- `infoBottomAccumulator567.md` - dolny bufor P5-P7,
- `infoRobotData.md` - sygnaly PLC-FANUC,
- `infoHMI.md` - komendy i statusy HMI.

## Uklad maszyny

Stacja ma trzy glowne transportery:

| Transporter | Pozycje | Rola |
|---|---|---|
| gorny transporter | P1, P2, P3 | zaladunek i bufor pustych pojemnikow/stosow |
| transporter windy | P4 | miejsce pracy robota i przejscie miedzy gora/dolem |
| dolny transporter | P5, P6, P7 | rozladunek gotowych pojemnikow |

Uproszczony przeplyw:

```text
Operator
  -> P1
    -> P2
      -> P3
        -> P4 / winda / robot
          -> P5
            -> P6
              -> P7
                -> wyjscie
```

## Elementy wykonawcze

| Element | Miejsce | Funkcja |
|---|---|---|
| M1 | P1 | pozycjonowanie pojemnika po zaladunku |
| M2 | P1 | stoper/blokada pozycji P1 |
| M3 | P2 | stoper/blokada pozycji P2 |
| M4 | P3 | stoper/blokada pozycji P3 |
| M5 | P3 | pozycjoner/bramka tacek, uzywany w tray |
| M6 | P4 | pozycjoner tacki na windzie |
| M7 | P4 | pozycjoner kuwety na windzie |
| M8 | magazyn | oslona/przeslona magazynu przekladek |

Dla M2/M3/M4 `Fwd` oznacza podniesienie/blokade pojemnika nad transporterem.

Wazna zasada mechaniczna procesu:

```text
Pojemnik najpierw dojezdza do czujnika pozycji.
Transporter zatrzymuje sie.
Dopiero wtedy stoper moze podniesc pojemnik nad transporter.
```

To pozwala transporterowi poruszac innym pojemnikiem pod zatrzymanym pojemnikiem.

## Warunki ogolne startu AUTO

Zeby AUTO mialo sens, musza byc spelnione warunki:

- wybrany jest dokladnie jeden tryb: tray albo box,
- nie jest aktywny manual,
- nie trwa oproznianie stacji,
- `xGlobalEnable = TRUE`,
- robot jest gotowy wedlug sygnalow Modbus,
- brak aktywnych faultow blokujacych sekwencje,
- operator naciska fizyczny start albo `hmiCmd.xStartAuto`.

`xGlobalEnable` zalezy od:

```text
xSafetyOK AND NOT ind_low_pressure
```

Safety jest zalozone jako zewnetrzne, ale niskie cisnienie jest realnie uzywane w PLC.

## Zaladunek P1 - wspolny poczatek tray i box

Zaladunek jest wspolny dla obu trybow.

Sekwencja:

1. Operator wklada pojemnik albo stos na P1.
2. Czujnik `ind_container_in_pos_1` musi potwierdzic obecnosc.
3. Operator naciska `Pojemnik gotowy`.
4. `PRG_Main` ustawia `xLoadAcceptedPending`.
5. W AUTO wysuwa sie M1.
6. Gdy `fbPosM1.Sts.AtExt = TRUE`, program generuje `xTopFlowAcceptPulse`.
7. TopFlow przyjmuje nowy pojemnik do swojego modelu logicznego P1-P3.
8. `xLoadAcceptedPending` jest kasowane.

Sciezka sygnalowa:

```text
ind_button_container_ready
  -> xLoadAcceptedPending
    -> M1 CmdExtend
      -> M1 AtExt
        -> xTopFlowAcceptPulse
          -> fbTopFlow.Cmd.Pos1AcceptedPulse
```

## Gorny bufor P1-P3

Gorny bufor jest zarzadzany przez `FB_TopFlowManager`.

TopFlow:

- pamieta zajetosc P1-P3,
- steruje M2/M3/M4,
- steruje M5 w trybie tacek,
- uruchamia gorny transporter,
- w trybie kuwet lub emptying moze podac pojemnik na P4,
- priorytetyzuje podawanie do pozycji robota przed zwyklym buforowaniem.

W praktyce `PRG_Main` przekazuje TopFlow:

- czujniki P1-P4,
- feedback M2-M5,
- tryb tray/box,
- sygnal emptying,
- zlecenia z sekwencerow,
- timer transferu P4.

## Tryb tacek - opis funkcjonalny

Tryb tacek jest przeznaczony dla stosu tacek, z ktorego robot pobiera pojedyncze tacki i uklada detale na windzie.

Glowne FB:

- `FB_TopFlowManager` - dostarcza stos na P3,
- `FB_TraySequencer` - koordynuje robot, M6, winde i rozladunek,
- `FB_Elevator` - ruch pionowy windy,
- `FB_BottomAccumulator_567` - przyjecie gotowego pojemnika na dole,
- `FB_ModbusComm` - komunikacja z robotem.

### Przebieg tray krok po kroku

1. Operator wybiera tryb tacek na HMI.
2. Operator laduje stos na P1 i potwierdza `Pojemnik gotowy`.
3. M1 pozycjonuje stos.
4. TopFlow przyjmuje stos do bufora.
5. TopFlow przesuwa stos w strone P3.
6. Przed podaniem stosu na P3 w trybie tray wysuwany jest M5.
7. Po dojechaniu stosu do P3 TopFlow cofa M5 i podnosi M4.
8. Gdy stos jest gotowy na P3, TraySeq wystawia sygnaly do robota.
9. Robot pobiera tacke ze stosu P3 i kladzie ja na P4.
10. Po sygnale robota `sts_pallet_finished` TraySeq sprawdza czujnik P4.
11. Po potwierdzeniu P4 TraySeq wykonuje cykl M6.
12. Winda jedzie do krawedzi pojemnika, czyli do targetu `posContainerEdge`.
13. Po zakonczeniu ruchu windy TraySeq ponownie wystawia `Robot_ElevatorReady`.
14. Proces powtarza sie dla kolejnych tacek ze stosu.
15. Po sygnale `sts_stack_finished` TraySeq informuje TopFlow, ze stos na P3 zostal zuzyty.
16. M4/M5 sa zwalniane przez TopFlow.
17. Winda jedzie na dol.
18. Transporter windy OUT i dolny transporter FWD rozladowuja gotowy pojemnik.
19. Winda wraca na gore.
20. TopFlow moze juz przygotowywac nastepny stos na P3.

Uproszczony diagram:

```text
P1 zaladunek
  -> TopFlow P1-P3
    -> stos gotowy na P3
      -> Robot pobiera tacki
        -> M6 po kazdej tacy
          -> winda do krawedzi
            -> koniec stosu
              -> rozladunek P4 na P5-P7
```

### Priorytet w tray

Opis procesu wymaga minimalizacji postoju robota. Kod realizuje to architektonicznie tak:

- TopFlow odpowiada za buforowanie i przygotowanie P3,
- TraySeq czeka na `StackReadyAtP3`,
- gdy stos jest gotowy, robot dostaje `cmd_stack_ready`,
- kolejne stosy moga byc ladowane w tle na P1/P2.

Najwazniejsze przy uruchomieniu tray:

- P3 musi byc przygotowane przed oczekiwaniem robota,
- M5 ma dzialac tylko w tray jako bramka/pozycjoner P3,
- M4 musi byc podniesiony, zanim robot dostanie informacje o gotowym stosie,
- M6 musi wykonac cykl po kazdej tacy,
- czujnik P4 musi gasnac przy zjezdzie do krawedzi pojemnika.

## Tryb kuwet - opis funkcjonalny

Tryb kuwet jest przeznaczony dla pojedynczej kuwety, ktora wjezdza na winde i tam jest paletyzowana przez robota.

Glowne FB:

- `FB_TopFlowManager` - buforuje i podaje kuwete na P4,
- `FB_BoxSequencer` - koordynuje M7, robot, winde i rozladunek,
- `FB_Elevator` - ruch pionowy windy,
- `FB_BottomAccumulator_567` - przyjecie gotowej kuwety na dole,
- `FB_ModbusComm` - komunikacja z robotem.

### Przebieg box krok po kroku

1. Operator wybiera tryb kuwet na HMI.
2. Operator laduje kuwete na P1 i potwierdza `Pojemnik gotowy`.
3. M1 pozycjonuje kuwete.
4. TopFlow przyjmuje kuwete do bufora P1-P3.
5. BoxSeq prosi TopFlow o podanie kuwety na winde.
6. TopFlow planuje transfer na P4.
7. Gorny transporter i transporter windy IN pracuja razem.
8. Kuweta dojezdza na P4.
9. Czujnik P4 musi byc aktywny stabilnie przez 2 s.
10. TopFlow uznaje transfer za zakonczony przez `Elev_TransferDone`.
11. BoxSeq wysuwa M7 i pozycjonuje kuwete.
12. Winda zjezdza do krawedzi pojemnika.
13. PLC wystawia robotowi tryb box i gotowosc windy.
14. Robot paletyzuje detale do kuwety.
15. Robot wystawia `sts_stack_finished`, interpretowane jako koniec kuwety.
16. BoxSeq cofa M7.
17. Winda jedzie na dol.
18. Transporter windy OUT i dolny transporter FWD rozladowuja kuwete.
19. Winda wraca na gore i cykl moze ruszyc ponownie.

Uproszczony diagram:

```text
P1 zaladunek kuwety
  -> TopFlow P1-P3
    -> transfer P4
      -> P4 aktywne 2 s
        -> M7
          -> winda do krawedzi
            -> robot paletyzuje
              -> rozladunek P4 na P5-P7
```

Najwazniejsze przy uruchomieniu box:

- gorny transporter i transporter windy IN musza ruszac razem przy transferze,
- P4 musi byc puste, zanim TopFlow dostanie `Elev_CanAccept`,
- `Elev_TransferDone` jest filtrowane 2 s,
- M7 powinien byc aktywny tylko w trybie box,
- `sts_stack_finished` robota oznacza w box zakonczenie kuwety.

## Winda i pozycja P4

P4 jest centralnym miejscem procesu.

W trybie tray:

- robot odklada tacki na P4,
- M6 pozycjonuje tacke,
- winda zjezdza do krawedzi pojemnika po kazdej tacy,
- po calym stosie P4 jest rozladowywane na dol.

W trybie box:

- kuweta wjezdza na P4 z gornego transportera,
- M7 pozycjonuje kuwete,
- winda zjezdza do krawedzi pojemnika,
- robot paletyzuje do kuwety,
- po koncu kuweta zjezdza na dol.

Najwazniejsze sygnaly P4:

| Sygnal | Znaczenie |
|---|---|
| `ind_container_in_pos_4` | surowy czujnik pojemnika na windzie |
| `xElevTransferDone` | P4 aktywne stabilnie 2 s |
| `ind_elevator_emptied` | pojemnik opuscil winde |
| `elevStat.xAtTarget` | winda osiagnela zadany target |

## Rozladunek na dol

Rozladunek z P4 na dolny transporter jest podobny w tray i box.

Sekwencja:

1. Winda jedzie na dol.
2. Transporter windy pracuje w kierunku OUT.
3. Dolny transporter pracuje w kierunku FWD do wyjscia.
4. `FB_BottomAccumulator_567` moze przyjac pojemnik na P5.
5. Po sygnale `ind_elevator_emptied` transporter windy zatrzymuje sie.
6. Winda wraca na gore.
7. Dolny bufor przesuwa pojemniki P5-P7 w kierunku wyjscia.

Dolny bufor jest zarzadzany jako model logiczny `Occ5..Occ7`.

## Oproznianie stacji

Oproznianie stacji jest trybem specjalnym w `PRG_Main`, a nie osobnym FB.

Cel:

```text
Dostarczyc wszystkie pojemniki do wyjscia,
jadac zgodnie z normalnym kierunkiem pracy,
ale pomijajac paletyzacje robota.
```

Stany emptying:

| Stan | Nazwa | Funkcja |
|---:|---|---|
| `10` | `TOP_FLUSH` | podaj pojemniki z P1-P3 na P4 |
| `20` | `ELEV_DOWN` | zjedz winda na dol |
| `30` | `DISCHARGE` | rozladuj P4 na dolny transporter |
| `40` | `ELEV_UP` | wroc winda na gore |
| `60` | `BOTTOM_FLUSH` | oproznij P5-P7 do wyjscia |
| `50` | `DONE` | zakoncz oproznianie |

Podczas oprozniania:

- TraySeq i BoxSeq sa zatrzymane,
- TopFlow pracuje w `EmptyingMode`,
- robot nie wykonuje paletyzacji,
- winda i transportery sa sterowane lokalna logika `PRG_Main`,
- dolny transporter oproznia P5-P7.

Najwazniejsze testy emptying:

- pojemnik z P1/P2/P3 ma trafic na P4,
- po P4 winda ma zjechac na dol,
- `ind_elevator_emptied` ma zakonczyc rozladunek,
- po powrocie windy logika ma sprawdzic, czy na gorze zostal kolejny pojemnik,
- po oproznieniu gory ma przejsc do P5-P7.

## Tryb reczny

Tryb reczny jest aktywowany przez:

```text
GVL_HMI.hmiCmd.xManualMode
```

W manualu operator moze sterowac:

- winda gora/dol/szybko,
- gornym transporterem,
- transporterem windy w obu kierunkach,
- dolnym transporterem w obu kierunkach,
- M1-M8.

TraySequencer i BoxSequencer dostaja `PauseAuto`, zeby zachowac stan procesu, a `xStopAuto` jest traktowane jako abort AUTO do `DISABLED`.

Wazne:

- reczne komendy nadal przechodza przez FB wykonawcze,
- `FB_Conveyor` nadal blokuje konflikt FWD/BWD,
- silowniki nadal maja diagnostyke krancowek,
- manual nie powinien byc aktywny rownoczesnie z emptying.

## Kontynuuj i wznowienie

Fizyczny przycisk `Kontynuuj` jest obslugiwany w `PRG_Main`.

Aktualnie:

```text
ind_button_continue_process OR hmiCmd.xContiniue
  -> R_TRIG
    -> TP 1 s
      -> xContinueReq
```

Ten impuls:

- trafia do `ResumeAuto` aktywnego sekwencera,
- jest wysylany do robota jako `cmd_continue_job`.

Reset faultow jest oddzielony od kontynuacji i pochodzi tylko z `hmiCmd.xResetFaults`.

## Robot w procesie

Robot komunikuje sie przez `GVL_Robot` i `FB_ModbusComm`.

PLC wysyla:

- tryb produkcji tray/box,
- kontynuuj,
- stos/pojemnik gotowy,
- winda gotowa,
- probki.

Robot odsyla:

- tryb AUTO,
- gotowosc systemu,
- program w ruchu,
- fault/E-STOP,
- aktualny program,
- potwierdzenie komendy,
- koniec tacki/palety,
- koniec stosu/kuwety,
- probki ulozone.

W trybie tray:

- `sts_pallet_finished` oznacza pojedyncza tacke,
- `sts_stack_finished` oznacza koniec stosu.

W trybie box:

- `sts_stack_finished` oznacza zakonczenie kuwety.

## Sygnaly najwazniejsze do obserwacji

### Zaladunek

- `GVL_IO.di.ind_container_in_pos_1`,
- `GVL_IO.di.ind_button_container_ready`,
- `fbPosM1.Sts.AtExt`,
- `xTopFlowAcceptPulse`,
- `fbTopFlow.Sts.OccP1`.

### Gorny bufor

- `fbTopFlow.Sts.OccP1`,
- `fbTopFlow.Sts.OccP2`,
- `fbTopFlow.Sts.OccP3`,
- `fbTopFlow.Sts.StackReadyAtP3`,
- `fbTopFlow.Sts.Busy`,
- `fbTopFlow.Outp.TopConveyor_Run`,
- `fbTopFlow.Outp.HoldPos1_Up`,
- `fbTopFlow.Outp.HoldPos2_Up`,
- `fbTopFlow.Outp.HoldPos3_Up`,
- `fbTopFlow.Outp.M5_Extend`.

### P4 i winda

- `GVL_IO.di.ind_container_in_pos_4`,
- `xElevTransferDone`,
- `elevStat.ePos`,
- `elevStat.xAtTarget`,
- `elevStat.xBusy`,
- `elevStat.xFault`,
- `GVL_IO.di.ind_elevator_emptied`.

### Dolny bufor

- `fbBottom567.Sts.Occ5`,
- `fbBottom567.Sts.Occ6`,
- `fbBottom567.Sts.Occ7`,
- `fbBottom567.Sts.CanAcceptFromElev`,
- `fbBottom567.Sts.Busy`,
- `fbBottom567.Outp.ConvRun`.

### Robot

- `GVL_Robot.robotOut.cmd_tray_production`,
- `GVL_Robot.robotOut.cmd_box_production`,
- `GVL_Robot.robotOut.cmd_stack_ready`,
- `GVL_Robot.robotOut.cmd_elevator_ready`,
- `GVL_Robot.robotOut.cmd_continue_job`,
- `GVL_Robot.robotIn.sts_system_ready`,
- `GVL_Robot.robotIn.sts_auto_mode`,
- `GVL_Robot.robotIn.sts_cmd_ack`,
- `GVL_Robot.robotIn.sts_pallet_finished`,
- `GVL_Robot.robotIn.sts_stack_finished`.

## Typowy scenariusz uruchomienia

### 1. Manual bez pojemnikow

Sprawdz:

- M1-M8 w obu kierunkach,
- krancowki kazdego silownika,
- transportery FWD/BWD tam, gdzie wystepuja,
- winde gora/dol wolno i szybko,
- brak jednoczesnego FWD/BWD na transporterach.

### 2. Wejscia pojemnikow

Sprawdz po kolei:

- czujnik P1,
- czujnik P2,
- czujnik P3,
- czujnik P4,
- czujniki P5-P7,
- `ind_elevator_emptied`.

### 3. TopFlow bez robota

Sprawdz:

- akceptacje P1 przez M1,
- przesuniecie do P2/P3,
- zatrzymanie transportera przed podniesieniem stopera,
- logiczne `OccP1..OccP3`,
- zachowanie M5 w tray.

### 4. Winda i P4

Sprawdz:

- zjazd do `posContainerEdge`,
- zjazd na `posBottom`,
- powrot na `posTop`,
- reakcje na P4,
- timer `Elev_TransferDone` 2 s.

### 5. Tryb tray z robotem

Sprawdz:

- `cmd_tray_production`,
- `cmd_stack_ready`,
- `cmd_elevator_ready`,
- reakcje na `sts_pallet_finished`,
- cykl M6,
- liczenie tacek,
- reakcje na `sts_stack_finished`,
- rozladunek P4.

### 6. Tryb box z robotem

Sprawdz:

- `cmd_box_production`,
- transfer P1/P2/P3 -> P4,
- jednoczesna prace gornego transportera i transportera windy IN,
- M7,
- zjazd do krawedzi,
- reakcje na `sts_stack_finished`,
- rozladunek P4.

### 7. Emptying

Sprawdz:

- oproznianie P1-P3,
- transfer na P4,
- rozladunek na dol,
- oproznianie P5-P7,
- zakonczenie `xEmptyRunning`.

## Najwazniejsze miejsca ryzyka

Przy uruchomieniu szczegolnie pilnuj:

- zgodnosci czujnikow P1-P7 z rzeczywista pozycja pojemnika,
- polaryzacji krancowek FWD/BWD,
- czy M2-M4 podnosza pojemnik dopiero po zatrzymaniu transportera,
- czy M5 dziala tylko wtedy, gdy tryb tray tego wymaga,
- czy M6 nie blokuje paletyzacji po pojedynczej tacy,
- czy M7 wraca do cofniecia poza aktywnym box,
- czy P4 jest stabilne przez 2 s przy transferze box,
- czy `ind_elevator_emptied` nie pojawia sie za wczesnie,
- czy robotowe impulsy sa dluzsze niz cykl Modbus/PLC,
- czy `Kontynuuj` faktycznie wznawia z poprzedniego stanu sekwencera,
- czy HMI nie wybiera obu trybow naraz,
- czy alarmy komunikacji robota nie dubluja operatorowi tej samej przyczyny.

## Podsumowanie

Caly proces jest podzielony na czytelne warstwy:

```text
Operator / HMI / przyciski
  -> PRG_Main
    -> TraySeq albo BoxSeq
      -> TopFlow / Elevator / BottomAccumulator / Robot
        -> FB wykonawcze
          -> fizyczne I/O
```

Najwazniejsza zasada czytania projektu:

- `FB_TopFlowManager` odpowiada za P1-P3,
- `FB_TraySequencer` odpowiada za proces tacek po przygotowaniu P3,
- `FB_BoxSequencer` odpowiada za proces kuwety po zleceniu transferu na P4,
- `FB_Elevator` odpowiada za pionowy ruch windy,
- `FB_BottomAccumulator_567` odpowiada za P5-P7,
- `PRG_Main` laczy wszystkie te decyzje z rzeczywistymi wyjsciami.

Jesli maszyna zachowuje sie inaczej niz oczekiwany proces, najlepiej isc po sciezce: czujnik -> `GVL_IO` -> `PRG_Main` -> FB -> wyjscie FB -> `GVL_IO.dout` -> fizyczne wyjscie.
