# GVL_HMI - dane wizualizacji HMI

## Rola funkcjonalna

`GVL_HMI` jest warstwa wymiany danych miedzy programem PLC a wizualizacja HMI.

Komentarz w kodzie zaklada uzycie Schneider Vijeo Designer albo Web Visualization. Wszystkie zmienne z prefiksem `hmi*` sa przeznaczone do bindowania na panelu.

Globalne zmienne:

```iecst
hmiStatus     : ST_HmiStationStatus;
hmiCmd        : ST_HmiCommands;
hmiAlarms     : ST_HmiAlarm;
hmiAlarmCount : UINT;
```

Kierunki danych:

```text
HMI -> PLC:
  GVL_HMI.hmiCmd

PLC -> HMI:
  GVL_HMI.hmiStatus
  GVL_HMI.hmiAlarms
  GVL_HMI.hmiAlarmCount
```

## Gdzie GVL_HMI jest uzywane

`PRG_Main` jest glownym miejscem obslugi HMI.

Na poczatku skanu program czyta `GVL_HMI.hmiCmd` i kopiuje najwazniejsze komendy do zmiennych lokalnych:

- wybor trybu tacek/kuwet,
- tryb reczny,
- reczne sterowanie winda,
- reczne sterowanie transporterami,
- reczne sterowanie M1-M8.

Pod koniec skanu `PRG_Main` wpisuje do HMI:

- alarmy,
- liczbe aktywnych alarmow,
- status trybow,
- zajetosc pozycji P1-P7,
- stan windy,
- stan transporterow,
- stan silownikow,
- status robota,
- stany sekwencerow,
- liczniki produkcji.

## hmiCmd - komendy z HMI

`hmiCmd` ma typ `ST_HmiCommands`.

To sa sygnaly pisane przez panel HMI i czytane przez PLC.

### Tryb pracy

| Pole | Znaczenie | Uzycie w PRG_Main |
|---|---|---|
| `xSelectModeTray` | wybor produkcji tacek | tworzy `xModeTray` |
| `xSelectModeBox` | wybor produkcji kuwet | tworzy `xModeBox` |
| `xManualMode` | tryb reczny | tworzy `xHmiManualMode` |

`PRG_Main` robi mutex trybow:

```iecst
xModeTray := xSelectModeTray AND NOT xSelectModeBox;
xModeBox  := xSelectModeBox AND NOT xSelectModeTray;
```

Jesli HMI ustawi oba tryby naraz, PLC lokalnie ustawi oba tryby na `FALSE`.

### Komendy procesu

| Pole | Znaczenie | Uzycie w PRG_Main |
|---|---|---|
| `xStartAuto` | start AUTO | OR z fizycznym przyciskiem start |
| `xStopAuto` | abort / stop AUTO | abortuje aktywny sekwencer |
| `xContiniue` | kontynuuj AUTO | OR z fizycznym przyciskiem Kontynuuj |
| `xPauseAuto` | pauza AUTO | pauzuje aktywny Tray/Box bez kasowania stanu |
| `xEmptyStation` | oproznij stacje | OR z fizycznym przyciskiem emptying |
| `xResetFaults` | reset faultow | tworzy `xResetAll` |
| `xAckAlarms` | potwierdzenie alarmow | zadeklarowane, aktualnie nieuzywane |

`xResetFaults` jest realnie uzyte:

```iecst
xResetAll := GVL_HMI.hmiCmd.xResetFaults;
```

`xAckAlarms` jest polem przygotowanym pod HMI, ale w aktualnym `PRG_Main` nie ma logiki kasowania/potwierdzania alarmow przez to pole.

### Reczne sterowanie winda

| Pole | Znaczenie |
|---|---|
| `xElevUp` | jazda windy w gore |
| `xElevDown` | jazda windy w dol |
| `xElevFast` | predkosc szybka w manualu |

Te pola dzialaja tylko wtedy, gdy `xManualMode = TRUE` i nie trwa oproznianie stacji.

W manualu `PRG_Main` ustawia:

```iecst
elevCmd.eMode := E_ElevatorMode.MANUAL;
elevCmd.xManUp := xElevUp;
elevCmd.xManDown := xElevDown;
elevCmd.xManFast := xElevFast;
```

### Reczne sterowanie transporterami

| Pole | Znaczenie |
|---|---|
| `xConvTopFwd` | gorny transporter FWD |
| `xConvElevFwd` | transporter windy IN |
| `xConvElevBwd` | transporter windy OUT |
| `xConvBottomFwd` | dolny transporter FWD do wyjscia |
| `xConvBottomBwd` | dolny transporter BWD do windy |

W manualu komendy sa wpisywane do `FB_Conveyor`.

`FB_Conveyor` nadal blokuje konflikt FWD/BWD i pilnuje opoznienia zmiany kierunku.

### Reczne sterowanie silownikami

Pola:

| Element | Fwd | Bwd |
|---|---|---|
| M1 | `xM1Fwd` | `xM1Bwd` |
| M2 | `xM2Fwd` | `xM2Bwd` |
| M3 | `xM3Fwd` | `xM3Bwd` |
| M4 | `xM4Fwd` | `xM4Bwd` |
| M5 | `xM5Fwd` | `xM5Bwd` |
| M6 | `xM6Fwd` | `xM6Bwd` |
| M7 | `xM7Fwd` | `xM7Bwd` |
| M8 | `xM8Fwd` | `xM8Bwd` |

Sterowanie jest bistabilne:

- samo `Fwd = TRUE` ustawia komende wysuniecia/podniesienia,
- samo `Bwd = TRUE` ustawia komende cofniecia/opuszczenia,
- gdy oba sa `FALSE`, zostaje ostatnio zadana komenda,
- gdy oba sa `TRUE`, kod nie zmienia komendy.

Komentarz w `GVL_HMI` slusznie zaklada, ze HMI powinno wzajemnie blokowac `Fwd` i `Bwd` tego samego elementu.

Dla M2-M4 `Fwd` oznacza podniesienie stopera i zablokowanie pojemnika nad transporterem.

### Parametry

| Pole | Znaczenie | Uzycie |
|---|---|---|
| `uiTraysInStack` | liczba tacek w stosie | konfiguracja `FB_TraySequencer` |

Jesli HMI poda `0`, `PRG_Main` ustawia domyslnie:

```iecst
uiTraysInStack := 8;
```

## hmiStatus - status stacji

`hmiStatus` ma typ `ST_HmiStationStatus`.

To sa dane pisane przez PLC i czytane przez HMI.

### Tryby i zezwolenia

| Pole | Znaczenie |
|---|---|
| `xAutoRunning` | aktywny AUTO jednego z sekwencerow |
| `xManualMode` | aktywny manual |
| `xEmptyingStation` | trwa oproznianie stacji |
| `xModeTray` | lokalnie aktywny tryb tacek |
| `xModeBox` | lokalnie aktywny tryb kuwet |
| `xGlobalEnable` | globalne zezwolenie programu |
| `xSafetyOK` | lokalny status safety |

`xGlobalEnable` uwzglednia niskie cisnienie:

```iecst
xSafetyOK AND NOT ind_low_pressure
```

### Zajetosc pozycji

| Pole | Zrodlo |
|---|---|
| `xOccP1` | `fbTopFlow.Sts.OccP1` |
| `xOccP2` | `fbTopFlow.Sts.OccP2` |
| `xOccP3` | `fbTopFlow.Sts.OccP3` |
| `xOccP4` | `GVL_IO.di.ind_container_in_pos_4` |
| `xOccP5` | `fbBottom567.Sts.Occ5` |
| `xOccP6` | `fbBottom567.Sts.Occ6` |
| `xOccP7` | `fbBottom567.Sts.Occ7` |

P1-P3 i P5-P7 pochodza z modeli logicznych FB, a P4 jest surowym czujnikiem.

To ma znaczenie diagnostyczne: P1-P3 moga pamietac stan logiczny TopFlow, a nie tylko aktualny czujnik.

### Winda

| Pole | Znaczenie |
|---|---|
| `uiElevState` | stan `FB_Elevator` jako `UINT` |
| `xElevAtTop` | winda na gorze |
| `xElevAtBottom` | winda na dole |
| `xElevBusy` | winda pracuje |
| `xElevFault` | fault windy |
| `rElevFreq_Hz` | aktualna czestotliwosc falownika |

`uiElevState` jest liczba, wiec HMI powinno miec opis tekstowy stanow zgodny z enumem `E_ElevatorState`.

### Transportery

| Pole | Zrodlo |
|---|---|
| `xConvTopRunning` | `fbConvTop.Sts.Running` |
| `xConvElevRunning` | `fbConvElev.Sts.Running` |
| `xConvBottomRunning` | `fbConvBottom.Sts.Running` |

To sa statusy po FB wykonawczych, a nie same komendy z HMI.

### Silowniki - stan zagregowany

| Pole | Znaczenie |
|---|---|
| `xM1_Extended` | M1 wysuniety |
| `xM2_Up` | M2 podniesiony |
| `xM3_Up` | M3 podniesiony |
| `xM4_Up` | M4 podniesiony |
| `xM5_Up` | M5 wysuniety/podniesiony |
| `xM6_Up` | M6 wysuniety/podniesiony |
| `xM7_Extended` | M7 wysuniety |
| `xM8_Extended` | M8 wysuniety |

Te pola sa wygodne do prostych lampek stanu.

### Silowniki - surowe krancowki

`hmiStatus` ma tez osobne pola dla kazdej krancowki:

- M1: `xM1_1_Fwd`, `xM1_2_Fwd`, `xM1_1_Bwd`, `xM1_2_Bwd`,
- M2: `xM2_1_Fwd`, `xM2_2_Fwd`, `xM2_1_Bwd`, `xM2_2_Bwd`,
- M3: `xM3_1_Fwd`, `xM3_2_Fwd`, `xM3_1_Bwd`, `xM3_2_Bwd`,
- M4: `xM4_1_Fwd`, `xM4_2_Fwd`, `xM4_1_Bwd`, `xM4_2_Bwd`,
- M5: `xM5_1_Fwd`, `xM5_2_Fwd`, `xM5_1_Bwd`, `xM5_2_Bwd`,
- M6: `xM6_1_Fwd`, `xM6_2_Fwd`, `xM6_1_Bwd`, `xM6_2_Bwd`,
- M7: `xM7_Fwd`, `xM7_Bwd`,
- M8: `xM8_Fwd`, `xM8_Bwd`.

Te pola sa bardzo przydatne przy uruchomieniu pneumatyki, bo pokazuja czy problem jest w zaworze, krancowce, mapowaniu I/O czy logice FB.

### Robot

| Pole | Zrodlo |
|---|---|
| `xRobotAutoMode` | `GVL_Robot.robotIn.sts_auto_mode` |
| `xRobotReady` | `GVL_Robot.robotIn.sts_system_ready` |
| `xRobotRunning` | `GVL_Robot.robotIn.sts_prg_running` |
| `xRobotFault` | `GVL_Robot.robotIn.sts_fault` |
| `xRobotHome` | `GVL_Robot.robotIn.sts_in_home_pos` |
| `xRobotCommOk` | `fbModbusComm.Outp.stStatus.xRobotCommOk` |
| `xVfdCommOk` | `elevStat.xVfdCommOk` |

Robot status pochodzi z ostatniego odswiezenia Modbus, wiec ma naturalne opoznienie wzgledem realnego robota.

### Stany sekwencerow

| Pole | Zrodlo |
|---|---|
| `uiTraySeqState` | `fbTraySeq.Sts.State` |
| `uiBoxSeqState` | `fbBoxSeq.Sts.State` |
| `uiTopFlowState` | `fbTopFlow.Sts.State` |
| `uiBottomState` | `fbBottom567.Sts.State` |

Na HMI warto wyswietlac te pola jako tekst, nie tylko liczby. Mapowanie trzeba zrobic zgodnie z enumami w odpowiednich plikach FB.

### Liczniki produkcji

| Pole | Znaczenie |
|---|---|
| `uiTraysDone` | liczba tacek ulozonych w aktualnym stosie |
| `uiStacksDone` | liczba zakonczonych stosow |
| `uiBoxesDone` | liczba zakonczonych kuwet |

Liczniki pochodza z sekwencerow.

## hmiAlarms - alarmy

`hmiAlarms` ma typ `ST_HmiAlarm`.

Alarmy sa pisane w `PRG_Main` na podstawie diagnostyki FB i sygnalow systemowych.

### Alarmy wykonawcze

| Pole | Zrodlo |
|---|---|
| `xM1_Fault` | `fbPosM1.Diag.Fault` |
| `xM2_Fault` | `fbStopM2.Diag.Fault` |
| `xM3_Fault` | `fbStopM3.Diag.Fault` |
| `xM4_Fault` | `fbStopM4.Diag.Fault` |
| `xM5_Fault` | `fbPosM5.Diag.Fault` |
| `xM6_Fault` | `fbPosM6.Diag.Fault` |
| `xM7_Fault` | `fbPosM7.Diag.Fault` |
| `xM8_Fault` | `fbPosM8.Diag.Fault` |
| `xConvTop_Fault` | `fbConvTop.Diag.Fault` |
| `xConvElev_Fault` | `fbConvElev.Diag.Fault` |
| `xConvBottom_Fault` | `fbConvBottom.Diag.Fault` |

### Alarmy procesu

| Pole | Zrodlo |
|---|---|
| `xElev_Fault` | `elevStat.xFault` |
| `xElev_CommLost` | stale `FALSE` w aktualnym kodzie |
| `xTopFlow_Fault` | `fbTopFlow.Diag.Fault` |
| `xBottom_Fault` | `fbBottom567.Diag.Fault` |
| `xTraySeq_Fault` | `fbTraySeq.Diag.Fault` |
| `xBoxSeq_Fault` | `fbBoxSeq.Diag.Fault` |

`xElev_CommLost` jest zadeklarowany, ale aktualnie osobny alarm komunikacji windy nie jest uzywany.

### Alarmy robota i systemu

| Pole | Zrodlo |
|---|---|
| `xRobot_Fault` | `GVL_Robot.robotIn.sts_fault` |
| `xRobot_EStop` | `GVL_Robot.robotIn.sts_estop` |
| `xRobot_CommLost` | `NOT fbModbusComm.Outp.stStatus.xRobotCommOk` |
| `xVfd_CommLost` | `xGlobalEnable AND NOT elevStat.xVfdCommOk` |
| `xRobot_MbLost` | `NOT fbModbusComm.Outp.stStatus.xRobotCommOk` |
| `xLowPressure` | `GVL_IO.di.ind_low_pressure` |
| `xSafetyTrip` | `NOT xSafetyOK` |

`xRobot_CommLost` i `xRobot_MbLost` sa obecnie liczone z tego samego warunku. Na HMI moze to wygladac jak dwa alarmy tej samej przyczyny.

### Pola Ack/Reset w ST_HmiAlarm

W strukturze `ST_HmiAlarm` istnieja:

```iecst
xAckAll
xResetAll
```

W aktualnym `PRG_Main` nie sa one ustawiane ani wykorzystywane. Realny reset faultow jest przez:

```iecst
GVL_HMI.hmiCmd.xResetFaults
```

Dlatego przy budowie HMI lepiej traktowac `hmiAlarms.xAckAll` i `hmiAlarms.xResetAll` jako pola rezerwowe albo uporzadkowac ich role w kolejnej poprawce.

## hmiAlarmCount

`hmiAlarmCount` jest liczony w `PRG_Main` jako suma aktywnych alarmow BOOL.

Do licznika wchodza alarmy:

- M1-M8,
- transportery,
- winda,
- TopFlow,
- BottomAccumulator,
- sekwencery,
- robot,
- Modbus,
- niskie cisnienie,
- safety.

Do licznika nie wchodza pola `xAckAll` i `xResetAll`.

## Wazne zachowania HMI w PRG_Main

### Start AUTO

Start moze przyjsc z:

```iecst
GVL_IO.di.ind_button_start_process
OR
GVL_HMI.hmiCmd.xStartAuto
```

Aktywny zostanie tylko sekwencer zgodny z wybranym trybem.

### Stop / abort AUTO

`xStopAuto` oznacza abort AUTO. Dla TraySequencer i BoxSequencer trafia do `AbortAuto`.

Oba sekwencery maja osobna pauze:

```iecst
GVL_HMI.hmiCmd.xPauseAuto -> fbTraySeq.Cmd.PauseAuto
GVL_HMI.hmiCmd.xPauseAuto -> fbBoxSeq.Cmd.PauseAuto
```

Pauza zachowuje stan procesu, a abort przechodzi do `DISABLED`.

Abort aktywnego sekwencera jest aktywny razem z:

- emptying,
- niezgodnym trybem pracy.

### Oproznij stacje

Oproznianie moze wystartowac z:

```iecst
GVL_IO.di.ind_button_start_emptying_process
OR
GVL_HMI.hmiCmd.xEmptyStation
```

`PRG_Main` wykrywa zbocze i uruchamia lokalna maszyne stanow emptying.

### Reset faultow

Reset faultow z HMI:

```iecst
GVL_HMI.hmiCmd.xResetFaults
```

jest jedynym zrodlem `xResetAll`:

```iecst
xResetAll := xResetFaults;
```

### Kontynuuj

`Kontynuuj` w `PRG_Main` pochodzi z fizycznego wejscia albo HMI:

```iecst
GVL_IO.di.ind_button_continue_process OR GVL_HMI.hmiCmd.xContiniue
```

i tworzy impuls 1 s do:

- `ResumeAuto`,
- `GVL_Robot.robotOut.cmd_continue_job`.

Kontynuuj nie resetuje faultow. Reset bledow robi tylko `xResetFaults`.

## Zalecenia dla ekranow HMI

Praktyczny podzial ekranow:

- ekran glowny: tryb, P1-P7, winda, robot, start/stop/emptying/reset,
- ekran manualny: M1-M8, transportery, winda, surowe krancowki,
- ekran alarmow: `hmiAlarms` z tekstami i `hmiAlarmCount`,
- ekran diagnostyki robota: statusy `robotIn`, komunikacja, tryb tray/box,
- ekran parametrow: `uiTraysInStack`,
- ekran serwisowy: stany sekwencerow jako liczby i tekst.

Na ekranie manualnym HMI powinno blokowac jednoczesne FWD/BWD dla tego samego elementu. PLC nie nadpisuje komendy, gdy oba przyciski sa aktywne, ale dobra wizualizacja powinna nie dopuszczac takiej sytuacji.

## Na co zwrocic uwage przy uruchomieniu

- Czy HMI nie ustawia jednoczesnie `xSelectModeTray` i `xSelectModeBox`.
- Czy `xManualMode` rzeczywiscie pauzuje aktywny sekwencer.
- Czy `xStartAuto` nie jest przyciskiem podtrzymanym na stale, jesli oczekiwane jest dzialanie impulsowe.
- Czy `xStopAuto`, `xPauseAuto` i `xContiniue` sa kasowane po puszczeniu przycisku.
- Czy `xEmptyStation` jest obslugiwane jako przycisk chwilowy.
- Czy `xResetFaults` jest impulsem, a nie stale ustawionym bitem.
- Czy HMI blokuje FWD/BWD dla jednego silownika lub transportera.
- Czy `uiTraysInStack = 0` nie jest mylaco wyswietlane operatorowi, bo PLC zastepuje je wartoscia `8`.
- Czy teksty stanow sekwencerow odpowiadaja aktualnym enumom w kodzie.
- Czy `xRobot_CommLost` i `xRobot_MbLost` nie dubluja operatorowi tego samego alarmu.

## Minimalny test HMI

1. Zmien `xSelectModeTray` i sprawdz `hmiStatus.xModeTray`.
2. Zmien `xSelectModeBox` i sprawdz `hmiStatus.xModeBox`.
3. Ustaw oba tryby naraz i potwierdz, ze oba statusy sa `FALSE`.
4. Wlacz manual i sprawdz `hmiStatus.xManualMode`.
5. W manualu rusz M1, M2 i transporter windy, obserwuj wyjscia oraz krancowki.
6. Zmien `uiTraysInStack` i sprawdz konfiguracje TraySeq.
7. Wymus jeden fault FB i sprawdz alarm oraz `hmiAlarmCount`.
8. Sprawdz, czy reset z `xResetFaults` kasuje fault po usunieciu przyczyny.

## Podsumowanie

`GVL_HMI` jest kontraktem miedzy wizualizacja a PLC.

Najwazniejsze zasady:

- HMI pisze tylko do `hmiCmd`,
- PLC pisze do `hmiStatus`, `hmiAlarms` i `hmiAlarmCount`,
- reczne sterowanie dziala przez `PRG_Main`, ale wykonanie nadal przechodzi przez FB wykonawcze,
- czesc pol jest juz zadeklarowana na przyszlosc, ale nie wszystko jest aktualnie uzyte w logice.
