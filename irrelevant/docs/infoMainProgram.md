# PRG_Main - glowny program cykliczny

## Rola funkcjonalna

`PRG_Main` jest centralnym programem PLC uruchamianym cyklicznie w tasku `MAST`.

Nie jest klasycznym blokiem funkcyjnym jak `FB_TopFlowManager` albo `FB_TraySequencer`. Jego rola jest nadrzedna:

- instancjonuje wszystkie FB projektu,
- czyta sygnaly z `GVL_IO`, `GVL_HMI`, `GVL_Robot` i `GVL_ModbusTCP`,
- wybiera tryb pracy,
- mapuje wejscia do FB,
- laczy wyjscia sekwencerow z blokami wykonawczymi,
- wywoluje FB w ustalonej kolejnosci,
- przepisuje gotowe wyjscia na `GVL_IO.dout`,
- aktualizuje komunikacje z robotem,
- sklada alarmy i statusy HMI.

Mozna traktowac go jako "szafe rozdzielcza" logiki: decyzje procesowe sa w FB, ale `PRG_Main` decyduje, ktore FB dostaje dane i ktore wyjscie ma ostatecznie trafic na fizyczny element maszyny.

## Powiazane pliki

Opis szczegolowy blokow jest rozbity na osobne dokumenty:

- `infoCyl2Pos.md` - pojedyncze silowniki dwupozycyjne,
- `infoStopperPair.md` - pary silownikow/stoperow,
- `infoConveyor.md` - transportery,
- `infoElevator.md` - winda i falownik ATV320,
- `infoBottomAccumulator567.md` - dolny bufor P5-P7,
- `infoTopFlowManager.md` - gorny bufor P1-P3 i transfer na P4,
- `infoTraySequencer.md` - produkcja tacek,
- `infoBoxSequencer.md` - produkcja kuwet,
- `infoModbusComm.md` - komunikacja Modbus TCP z robotem,
- `infoProgramDependencies.md` - zaleznosci miedzy FB.

Ten plik opisuje glownie `PRG_Main.st`.

## Najwazniejsze instancje

`PRG_Main` tworzy po jednej instancji kazdego glownego bloku:

| Instancja | Typ | Rola |
|---|---|---|
| `fbConvTop` | `FB_Conveyor` | gorny transporter P1-P3 |
| `fbConvElev` | `FB_Conveyor` | transporter na windzie P4 |
| `fbConvBottom` | `FB_Conveyor` | dolny transporter P5-P7 |
| `fbStopM2` | `FB_StopperPair` | stoper P1 |
| `fbStopM3` | `FB_StopperPair` | stoper P2 |
| `fbStopM4` | `FB_StopperPair` | stoper P3 |
| `fbPosM1` | `FB_Cyl2Pos` | pozycjoner zaladunku P1 |
| `fbPosM5` | `FB_StopperPair` | pozycjoner/bramka tacek P3 |
| `fbPosM6` | `FB_StopperPair` | pozycjoner tacek na windzie |
| `fbPosM7` | `FB_Cyl2Pos` | pozycjoner kuwet na windzie |
| `fbPosM8` | `FB_Cyl2Pos` | magazyn/przeslona przekladek |
| `fbElevator` | `FB_Elevator` | pionowy ruch windy |
| `fbTopFlow` | `FB_TopFlowManager` | gorny przeplyw P1-P3/P4 |
| `fbBottom567` | `FB_BottomAccumulator_567` | dolny bufor P5-P7 |
| `fbTraySeq` | `FB_TraySequencer` | AUTO dla tacek |
| `fbBoxSeq` | `FB_BoxSequencer` | AUTO dla kuwet |
| `fbModbusComm` | `FB_ModbusComm` | Modbus TCP robot FANUC |

## Zmienne sterujace trybem

### Tryb produkcji

Tryb jest czytany z HMI:

```iecst
xModeTray := xSelectModeTray AND NOT xSelectModeBox;
xModeBox  := xSelectModeBox AND NOT xSelectModeTray;
```

To oznacza, ze PLC ma prosty mutex:

- wybrano tylko tacki -> `xModeTray = TRUE`,
- wybrano tylko kuwety -> `xModeBox = TRUE`,
- wybrano oba tryby naraz -> oba lokalne tryby sa `FALSE`,
- nie wybrano nic -> oba lokalne tryby sa `FALSE`.

Dzieki temu sekwencery nie powinny pracowac rownoczesnie.

### Globalne zezwolenie

`xGlobalEnable` jest liczone z:

```iecst
xSafetyOK AND NOT ind_low_pressure
```

`xSafetyOK` w tym projekcie jest lokalnie ustawione na `TRUE`, bo safety ma byc realizowane przez osobny sterownik. Niskie cisnienie blokuje jednak globalne zezwolenie dla FB.

### Tryb reczny

`xHmiManualMode` pochodzi z HMI. Gdy jest aktywny:

- aktywny sekwencer dostaje `PauseAuto`, a `xStopAuto` pozostaje abortem do `DISABLED`,
- ruch windy jest zadawany przez `xElevUp`, `xElevDown`, `xElevFast`,
- transportery dostaja komendy reczne,
- silowniki sa przelaczane bistabilnie z HMI,
- logika AUTO nie powinna nadpisywac recznych komend poza miejscami, gdzie kod jawnie sprawdza `NOT xHmiManualMode`.

## Przebieg jednego skanu

Ponizej jest uproszczona kolejnosc wykonania `PRG_Main`.

### 0. Odczyt wejsc

Na poczatku wykonywane jest:

```iecst
PRG_IO_Read();
```

Program pracuje potem na abstrakcyjnej strukturze `GVL_IO.di`, a nie bezposrednio na `GVL_IO_RAW.di`.

### 1. Odczyt HMI

Komendy HMI sa kopiowane do lokalnych zmiennych:

- wybor trybu,
- manual mode,
- reczne komendy windy,
- reczne komendy transporterow,
- reczne komendy M1-M8.

To jest zrobione na poczatku skanu, aby reszta programu uzywala spojnego zestawu komend.

### 2. Manual override

Jesli aktywny jest manual i nie trwa oproznianie stacji, `PRG_Main` wpisuje komendy reczne do:

- `elevCmd`,
- `fbConvTop.Cmd`,
- `fbConvElev.Cmd`,
- `fbConvBottom.Cmd`,
- `fbPosM1.CmdExtend`,
- `fbStopM2.HoldUp`,
- `fbStopM3.HoldUp`,
- `fbStopM4.HoldUp`,
- `fbPosM5.HoldUp`,
- `fbPosM6.HoldUp`,
- `fbPosM7.CmdExtend`,
- `fbPosM8.CmdExtend`.

Rzeczywiste wyjscia fizyczne nadal przechodza przez FB wykonawcze, wiec dzialaja ich blokady, timeouty i diagnostyka.

### 3. Przyciski i zbocza

`PRG_Main` obsluguje trzy wazne zdarzenia:

- `Oproznij stacje` przez `rtEmptyStation`,
- `Kontynuuj` przez `rtContinue` i impuls `TP` 1 s,
- `Pojemnik gotowy` przez `rtContainerReady`.

`Kontynuuj` tworzy:

```iecst
xContinueReq := tpRobotContinue.Q;
xResetAll := xResetFaults;
```

Impuls `Kontynuuj`:

- trafia jako `ResumeAuto` do aktywnego sekwencera,
- jest wysylany do robota jako `cmd_continue_job`.

Zrodlem `Kontynuuj` jest fizyczne wejscie `ind_button_continue_process` albo `GVL_HMI.hmiCmd.xContiniue`.
Reset faultow jest osobny i pochodzi tylko z `GVL_HMI.hmiCmd.xResetFaults`.

### 4. Timer transferu na P4

`PRG_Main` filtruje czujnik P4:

```iecst
tElevTransferDone(IN := ind_container_in_pos_4, PT := T#2s);
xElevTransferDone := tElevTransferDone.Q;
```

`xElevTransferDone` trafia potem do:

```iecst
fbTopFlow.Inp.Elev_TransferDone
```

Dzieki temu TopFlow uznaje transfer na winde za zakonczony dopiero wtedy, gdy czujnik pojemnika na P4 jest aktywny stabilnie przez 2 s.

### 5. Zaladunek P1 i M1

Po nacisnieciu `Pojemnik gotowy` ustawiane jest `xLoadAcceptedPending`, o ile:

- nie ma manuala,
- nie trwa oproznianie,
- nie ma resetu,
- czujnik P1 widzi pojemnik.

W AUTO `fbPosM1.CmdExtend` jest ustawiane, gdy zaakceptowano zaladunek i czujnik P1 jest aktywny.

Gdy M1 dojdzie do pozycji wysunietej:

```iecst
xTopFlowAcceptPulse := TRUE;
xLoadAcceptedPending := FALSE;
```

Ten impuls informuje `FB_TopFlowManager`, ze nowy pojemnik na P1 zostal zaakceptowany do modelu logicznego bufora.

### 6. Mapowanie FB wykonawczych

Nastepnie program mapuje wejscia i parametry:

- M2-M4 do `FB_StopperPair`,
- M1, M7, M8 do `FB_Cyl2Pos`,
- M5, M6 do `FB_StopperPair`,
- transportery do `FB_Conveyor`,
- winde do `FB_Elevator`.

W tym miejscu jeszcze nie sa wywolywane bloki wykonawcze. Program tylko przygotowuje ich wejscia.

### 7. Mapowanie windy

Do `elevIn` trafia:

- pozycja gorna,
- pozycje posrednie,
- pozycja dolna,
- czujnik pojemnika P4,
- drzwi celi robota,
- status komunikacji,
- aktualna czestotliwosc ATV320.

W AUTO komendy windy sa zerowane do bezpiecznego stanu bazowego:

```iecst
eMode := AUTO;
xAutoGo := FALSE;
xAutoStop := FALSE;
eAutoTarget := NONE;
```

Dopiero sekwencery lub oproznianie stacji wpisuja w ten sam skan docelowa komende ruchu.

### 8. Przygotowanie TopFlow i BottomAccumulator

Do `fbTopFlow` trafia:

- `SafetyOK`,
- `ResetFault`,
- impuls zaakceptowania P1,
- tryb oprozniania,
- `TrayMode`,
- surowe czujniki P1-P4,
- feedback M2-M5,
- `Elev_TransferDone` filtrowane 2 s.

Do `fbBottom567` trafia:

- `SafetyOK`,
- `ResetFault`,
- surowe czujniki P5-P7.

Przed wywolaniem sekwencerow `PRG_Main` zeruje bazowe komendy TopFlow, BottomAccumulator i transporterow. Dzieki temu stare komendy z poprzedniego skanu nie powinny zostac przypadkowo utrzymane w AUTO.

### 9. TraySequencer

`fbTraySeq` jest uruchamiany tylko logicznie, gdy:

- wybrany jest tryb tacek,
- nie ma manuala,
- nie trwa oproznianie.

Do wejsc sekwencera trafiaja:

- komendy `StartAuto`, `ResumeAuto`, `PauseAuto`, `AbortAuto`,
- status TopFlow,
- status windy,
- status BottomAccumulator,
- czujniki P4 i oproznienia windy,
- feedback M6,
- status robota z `GVL_Robot.robotIn`.

Po wywolaniu `fbTraySeq()` jego wyjscia sa mapowane na:

- TopFlow,
- transporter windy,
- dolny transporter,
- winde,
- M6,
- BottomAccumulator.

W trybie tacek TopFlow jest odpowiedzialny za przygotowanie stosu na P3, a TraySeq przejmuje proces robot/winda/rozladunek.

`xPauseAuto` pauzuje TraySeq bez kasowania stanu procesu. `xStopAuto` jest traktowane jako abort i przeprowadza TraySeq do `DISABLED`.

### 10. BoxSequencer

`fbBoxSeq` jest uruchamiany analogicznie, ale tylko dla trybu kuwet.

Do komend BoxSeq trafiaja `StartAuto`, `ResumeAuto`, `PauseAuto`, `AbortAuto`, `SafetyOK` i `ResetFault`.

`xPauseAuto` pauzuje BoxSeq bez kasowania `BoxCount`, a `xStopAuto` abortuje BoxSeq do `DISABLED`.

Do wejsc trafiaja:

- status TopFlow,
- status windy,
- status BottomAccumulator,
- P4 i oproznienie windy,
- feedback M7,
- status robota.

Po wywolaniu `fbBoxSeq()` program wylicza:

```iecst
xAutoActive := (xModeTray AND fbTraySeq.Outp.AutoRunning) OR
               (xModeBox AND fbBoxSeq.Outp.AutoRunning);
```

Dopiero potem, jesli BoxSeq jest aktywny, jego wyjscia sa mapowane na:

- TopFlow,
- gorny transporter,
- transporter windy,
- dolny transporter,
- winde,
- BottomAccumulator.

M7 jest dodatkowo wymuszany do stanu bezpiecznego poza aktywnym trybem kuwet:

```iecst
fbPosM7.CmdExtend := xModeBox AND AutoRunning AND M7_Extend;
```

### 11. Oproznianie stacji

Oproznianie stacji nie jest osobnym FB. To lokalna maszyna stanow w `PRG_Main`, aktywowana przez `xEmptyRunning`.

Stany:

| Stan | Nazwa | Rola |
|---|---|---|
| `10` | `TOP_FLUSH` | podawanie pojemnikow z P1-P3 na P4 |
| `20` | `ELEV_DOWN` | jazda windy na dol |
| `30` | `DISCHARGE` | rozladunek z windy na dolny transporter |
| `40` | `ELEV_UP` | powrot windy na gore |
| `60` | `BOTTOM_FLUSH` | oproznianie P5-P7 do wyjscia |
| `50` | `DONE` | zakonczenie oprozniania |

W tym trybie sekwencery sa zatrzymywane, a `PRG_Main` bezposrednio steruje:

- TopFlow w trybie `EmptyingMode`,
- winda,
- transporter windy,
- dolny transporter,
- BottomAccumulator.

Celem jest dostarczenie wszystkich pojemnikow do wyjscia bez paletyzacji.

### 12. Wywolanie FB nadrzednych

Po przygotowaniu wszystkich komend wykonywane sa:

```iecst
fbTopFlow();
fbBottom567();
fbElevator(...);
```

Po `fbTopFlow()` jego wyjscia sa przepisywane na komendy M2-M5.

Po `fbBottom567()` jego `Outp.ConvRun` jest dodawane do komendy dolnego transportera.

TopFlow moze tez dolozyc ruch transportera windy IN, gdy wykonywany jest transfer na P4 w trybie kuwet lub oprozniania.

### 13. Wywolanie FB wykonawczych

Dopiero teraz wywolywane sa fizyczne bloki wykonawcze:

1. `fbStopM2()`,
2. `fbStopM3()`,
3. `fbStopM4()`,
4. `fbPosM1()`,
5. `fbPosM5()`,
6. `fbPosM6()`,
7. `fbPosM7()`,
8. `fbPosM8()`,
9. `fbConvTop()`,
10. `fbConvElev()`,
11. `fbConvBottom()`.

Po kazdym wywolaniu wyjscia FB sa przepisywane do `GVL_IO.dout`.

Przyklad:

```iecst
fbStopM2();
GVL_IO.dout.ctrl_move_M2_actuator_forward := fbStopM2.Outp.Q_Fwd;
GVL_IO.dout.ctrl_move_M2_actuator_backward := fbStopM2.Outp.Q_Bwd;
```

To jest wazne: fizyczne wyjscia sa wynikiem ostatniego wywolania FB wykonawczego w danym skanie, a nie bezposredniego ustawienia komendy w sekwencerze.

### 14. Sygnalizacja

Po wykonaniu FB program sklada:

- zielona lampa - AUTO aktywne bez faultow sekwencerow,
- zolta lampa - AUTO aktywne i sekwencer zajety,
- czerwona lampa - fault sekwencerow, TopFlow, BottomAccumulator albo windy,
- buzzer - powiazany z czerwona lampa,
- LED startu,
- LED gotowosci zaladunku,
- LED kontynuacji,
- LED oprozniania.

### 15. Robot i Modbus TCP

`PRG_Main` sklada `GVL_Robot.robotOut` na podstawie wyjsc sekwencerow:

- `cmd_tray_production`,
- `cmd_box_production`,
- `cmd_continue_job`,
- `cmd_samples`,
- `cmd_stack_ready`,
- `cmd_elevator_ready`.

Nastepnie wywolywany jest:

```iecst
fbModbusComm();
GVL_Robot.robotIn := fbModbusComm.Outp.stRobotIn;
```

Status robota bedzie wiec widoczny dla sekwencerow w kolejnym skanie programu PLC, a dodatkowo z opoznieniem wynikajacym z cyklu komunikacji Modbus.

### 16. Alarmy i status HMI

`PRG_Main` zbiera alarmy z:

- M1-M8,
- transporterow,
- windy,
- TopFlow,
- BottomAccumulator,
- TraySeq,
- BoxSeq,
- robota,
- Modbus,
- niskiego cisnienia,
- safety.

Nastepnie liczy `hmiAlarmCount` i aktualizuje `GVL_HMI.hmiStatus`, m.in.:

- tryb AUTO/manual/emptying,
- aktywny tryb tray/box,
- zajetosc P1-P7,
- stan windy,
- prace transporterow,
- pozycje silownikow,
- surowe krancowki,
- status robota,
- stany sekwencerow,
- liczniki tacek/stosow/kuwet.

Na koncu wykonywane jest:

```iecst
PRG_IO_Write();
```

To przepisuje `GVL_IO.dout` na fizyczne wyjscia.

## Priorytety komend

W `PRG_Main` kilka miejsc moze chciec sterowac tym samym elementem. Aktualna logika priorytetow wyglada tak:

| Element | Zrodla komend | Priorytet praktyczny |
|---|---|---|
| M2-M4 | TopFlow, manual | manual gdy aktywny, inaczej TopFlow |
| M5 | TopFlow, manual | manual gdy aktywny, inaczej TopFlow |
| M6 | TraySeq, manual | manual gdy aktywny, inaczej TraySeq |
| M7 | BoxSeq, manual | manual gdy aktywny, inaczej BoxSeq |
| M1 | logika zaladunku, manual | manual gdy aktywny, inaczej zaladunek P1 |
| Gorny transporter | TopFlow, BoxSeq, manual | finalnie TopFlow w AUTO, manual w manualu |
| Transporter windy IN | TraySeq/BoxSeq/TopFlow/manual | komendy sa sumowane przez OR w AUTO |
| Transporter windy OUT | TraySeq/BoxSeq/emptying/manual | zalezy od trybu, manual tylko gdy manual |
| Dolny transporter | TraySeq/BoxSeq/BottomAccumulator/emptying/manual | komendy FWD sa sumowane przez OR w AUTO |
| Winda | TraySeq/BoxSeq/emptying/manual | manual ustawia `MANUAL`, inaczej AUTO |

Najwazniejsza zasada: w AUTO komendy sa zwykle zerowane na poczatku czesci sekwencerow, a potem skladane ponownie z aktywnego trybu.

## Tryb tacek w PRG_Main

W trybie tacek `PRG_Main` realizuje taki lancuch:

```text
Pojemnik gotowy
  -> M1
    -> TopFlow dostaje Pos1AcceptedPulse
      -> TopFlow przygotowuje stos na P3
        -> TraySeq widzi StackReadyAtP3
          -> robot dostaje StackReady / ElevatorReady
            -> M6 + winda do krawedzi
              -> rozladunek P4 na dol
```

`PRG_Main` nie implementuje krokow robotycznych samodzielnie. On tylko laczy:

- TopFlow jako zrodlo gotowego stosu,
- TraySeq jako sekwencer procesu,
- Elevator jako wykonawce pionowego ruchu,
- BottomAccumulator jako odbior pojemnika,
- Modbus jako interfejs robota.

## Tryb kuwet w PRG_Main

W trybie kuwet lancuch jest inny:

```text
Pojemnik gotowy
  -> M1
    -> TopFlow przyjmuje kuwete do bufora
      -> BoxSeq zada transferu na P4
        -> TopFlow uruchamia gorny transporter i transporter windy IN
          -> P4 aktywne stabilnie przez 2 s
            -> BoxSeq steruje M7, winda i robotem
              -> rozladunek P4 na dol
```

Kluczowe jest to, ze `Elev_TransferDone` do TopFlow jest filtrowane timerem 2 s, a BoxSeq przechodzi do pozycjonowania M7 dopiero po potwierdzeniu `TopFlow_ElevDeliveredAtP4` i aktywnym P4.

## Uwagi o kolejnosci skanu

Warto pamietac o kilku konsekwencjach cyklicznego wykonania:

- `fbTraySeq()` i `fbBoxSeq()` sa wywolane przed `fbTopFlow()`.
- Sekwencery czytaja status TopFlow z poprzedniego wywolania, czyli praktycznie z poprzedniego skanu.
- Wyjscia sekwencerow trafiaja do TopFlow jeszcze przed jego wywolaniem w aktualnym skanie.
- `GVL_Robot.robotIn` jest aktualizowany po sekwencerach, wiec robot feedback dla sekwencerow ma opoznienie co najmniej jednego skanu PLC plus cykl Modbus.
- Statusy silownikow uzywane przez TopFlow pochodza z ostatniego wywolania FB wykonawczych.

To nie jest blad samo w sobie. Tak dziala typowy program PLC. Przy diagnostyce trzeba jednak patrzec, czy dany sygnal jest wartoscia "z tego skanu", czy z poprzedniego cyklu.

## Na co patrzec przy uruchomieniu

Najbardziej praktyczne punkty kontrolne:

- Czy HMI nie ustawia jednoczesnie `xSelectModeTray` i `xSelectModeBox`.
- Czy `ind_low_pressure` nie blokuje `xGlobalEnable`.
- Czy po nacisnieciu `Pojemnik gotowy` M1 wysuwa sie i potem generuje impuls do TopFlow.
- Czy `xTopFlowAcceptPulse` wystepuje tylko po dojsciu M1 do pozycji wysunietej.
- Czy TopFlow widzi poprawne feedbacki M2-M5.
- Czy `ind_container_in_pos_4` po transferze na winde jest stabilny przez 2 s, zanim TopFlow uzna transfer za zakonczony.
- Czy `xContinueReq` trwa okolo 1 s po nacisnieciu fizycznego przycisku `Kontynuuj`.
- Czy `xContiniue` z HMI dziala tak samo jak fizyczny przycisk `Kontynuuj`.
- Czy `xPauseAuto` pauzuje TraySeq i BoxSeq bez zerowania licznikow.
- Czy `cmd_continue_job` dociera do robota przez Modbus.
- Czy `cmd_samples` odpowiada fizycznemu przyciskowi `ind_button_samples`.
- Czy w trybie manualnym sekwencery przechodza w pauze, ale wykonawcze FB nadal reaguja na HMI.
- Czy przy oproznianiu stacji stany `10 -> 20 -> 30 -> 40 -> 60/50` przechodza zgodnie z realnym ruchem pojemnikow.
- Czy `GVL_HMI.hmiStatus.xOccP1..xOccP7` zgadza sie z rzeczywistymi pozycjami pojemnikow.
- Czy alarm `xRobot_CommLost` i `xRobot_MbLost` nie dubluja sie w sposob mylacy dla operatora.

## Jak diagnozowac problem

Dobra kolejnosc sprawdzania:

1. Sprawdz fizyczne wejscie w `GVL_IO.di`.
2. Sprawdz, czy `PRG_Main` mapuje je do odpowiedniego FB.
3. Sprawdz stan FB/sekwencera.
4. Sprawdz wyjscie FB.
5. Sprawdz, czy `PRG_Main` przepisuje je do `GVL_IO.dout`.
6. Sprawdz fizyczne wyjscie po `PRG_IO_Write()`.

Przyklad dla M7:

```text
GVL_IO.di.ind_M7_fwd / ind_M7_bwd
  -> fbPosM7.Inp.IsExt / IsRet
    -> fbBoxSeq.Outp.M7_Extend
      -> fbPosM7.CmdExtend
        -> fbPosM7()
          -> GVL_IO.dout.ctrl_move_M7_actuator_forward/backward
```

Przyklad dla transferu kuwety na P4:

```text
BoxSeq zada Elev_RequestFeed
  -> TopFlow planuje TG_ELEV
    -> TopFlow.Outp.TopConveyor_Run
    -> TopFlow.Outp.Elev_TransferActive
      -> fbConvTop / fbConvElev IN
        -> ind_container_in_pos_4 aktywne przez 2 s
          -> fbTopFlow.Inp.Elev_TransferDone
```

## Podsumowanie

`PRG_Main` jest miejscem integracji calego projektu. Najwazniejsze dla jego zrozumienia sa trzy rzeczy:

- tryby pracy sa wybierane i blokowane tutaj,
- sekwencery nie steruja fizyka bezposrednio, tylko przez mapowania w `PRG_Main`,
- koncowa kolejnosc wywolan decyduje, ktora komenda faktycznie trafi na wyjscie.

Jesli cos w maszynie "nie robi tego, co sekwencer kazal", najpierw trzeba sprawdzic mapowanie w `PRG_Main`, bo to on laczy decyzje procesu z wykonawka.
