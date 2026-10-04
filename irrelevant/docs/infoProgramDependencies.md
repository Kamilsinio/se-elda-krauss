# Zależności FB w programie PLC

## Cel dokumentu

Ten plik opisuje, jak wszystkie bloki funkcyjne projektu współpracują w `PRG_Main`.

Osobne pliki opisują każdy FB od środka:

- `infoCyl2Pos.md`,
- `infoStopperPair.md`,
- `infoConveyor.md`,
- `infoElevator.md`,
- `infoBottomAccumulator567.md`,
- `infoTopFlowManager.md`,
- `infoTraySequencer.md`,
- `infoBoxSequencer.md`,
- `infoModbusComm.md`.

Ten dokument odpowiada na pytania:

- który FB jest właścicielem której części maszyny,
- w jakiej kolejności dane przepływają przez program,
- które FB sterują innymi FB,
- które statusy są używane przez sekwencery,
- gdzie dane przechodzą przez `PRG_Main`,
- na co uważać przy analizie kolejności wywołań.

## Warstwy programu

Program ma czytelną strukturę warstwową:

```text
HMI / przyciski / I/O / robot
  -> PRG_Main
    -> sekwencery procesu
      -> menedżery przepływu
        -> bloki wykonawcze
          -> GVL_IO.dout / Control_ATV / Modbus
```

W praktyce:

- `PRG_Main` jest centralnym miejscem mapowania danych,
- sekwencery decydują o kolejności procesu,
- TopFlow i BottomAccumulator zarządzają lokalnym przepływem pojemników,
- bloki wykonawcze sterują mechaniką,
- `PRG_IO_Read` i `PRG_IO_Write` są granicą z fizycznym I/O,
- `FB_ModbusComm` jest granicą z robotem FANUC,
- `FB_Elevator` jest granicą z falownikiem ATV320 przez `GIATV.Control_ATV`.

## Instancje FB w PRG_Main

| Instancja       | Typ FB                      | Rola                            |
|-----------------|-----------------------------|---------------------------------|
| `fbConvTop`     | `FB_Conveyor`               | górny transporter P1-P3         |
| `fbConvElev`    | `FB_Conveyor`               | transporter na windzie P4       |
| `fbConvBottom`  | `FB_Conveyor`               | dolny transporter P5-P7         |
| `fbStopM2`      | `FB_StopperPair`            | stoper P1                       |
| `fbStopM3`      | `FB_StopperPair`            | stoper P2                       |
| `fbStopM4`      | `FB_StopperPair`            | stoper P3                       |
| `fbPosM1`       | `FB_Cyl2Pos`                | pozycjoner załadunku P1         |
| `fbPosM5`       | `FB_StopperPair`            | bramka/pozycjoner tacek P3      |
| `fbPosM6`       | `FB_StopperPair`            | pozycjoner tacki na windzie     |
| `fbPosM7`       | `FB_Cyl2Pos`                | pozycjoner kuwety na windzie    |
| `fbPosM8`       | `FB_Cyl2Pos`                | magazyn/przesłona przekładek    |
| `fbElevator`    | `FB_Elevator`               | pionowy ruch windy przez ATV320 |
| `fbTopFlow`     | `FB_TopFlowManager`         | górny bufor P1-P3 i transfer P4 |
| `fbBottom567`   | `FB_BottomAccumulator_567`  | dolny bufor P5-P7               |
| `fbTraySeq`     | `FB_TraySequencer`          | główna sekwencja trybu tacek    |
| `fbBoxSeq`      | `FB_BoxSequencer`           | główna sekwencja trybu kuwet    |
| `fbModbusComm`  | `FB_ModbusComm`             | komunikacja PLC z robotem       |

## Główna ścieżka danych I/O

Typowy przepływ wejść i wyjść wygląda tak:

```text
GVL_IO_RAW.di
  -> PRG_IO_Read()
    -> GVL_IO.di
      -> PRG_Main mapuje wejścia do struktur FB
        -> FB liczą statusy i wyjścia
          -> PRG_Main mapuje wyjścia do GVL_IO.dout
            -> PRG_IO_Write()
              -> GVL_IO_RAW.dout
```

Wyjątki:

- winda pionowa nie zapisuje zwykłych wyjść PLC dla ruchu, tylko używa `GIATV.Control_ATV` wewnątrz `FB_Elevator`,
- robot nie używa `GVL_IO.dout`, tylko `GVL_Robot.robotOut` i `FB_ModbusComm`.

## Kolejność w jednym skanie PRG_Main

Uproszczona kolejność:

1. `PRG_IO_Read()` kopiuje fizyczne wejścia do `GVL_IO.di`.
2. `PRG_Main` odczytuje tryb, HMI i przyciski.
3. Jeśli aktywny jest manual, wpisuje komendy ręczne do FB.
4. Liczone są impulsy przycisków: emptying, continue, container ready.
5. Liczony jest timer `Elev_TransferDone` dla P4 aktywnego przez 2 s.
6. Mapowane są wejścia windy, TopFlow i BottomAccumulator.
7. Ustawiane są domyślne komendy automatu i zerowane komendy transporterów.
8. Wywoływany jest `fbTraySeq()`.
9. Wyjścia TraySeq są mapowane do TopFlow, windy, M6, BottomAccumulator i transporterów.
10. Wywoływany jest `fbBoxSeq()`.
11. Wyjścia BoxSeq są mapowane do TopFlow, windy, M7, BottomAccumulator i transporterów.
12. Liczone jest `xAutoActive`.
13. Jeśli trwa `Opróżnij stację`, logika emptying nadpisuje wybrane komendy.
14. Wywoływany jest `fbTopFlow()`.
15. Wyjścia TopFlow są mapowane do M2-M5 oraz transporterów.
16. Wywoływany jest `fbBottom567()`.
17. Wyjście `ConvRun` BottomAccumulator jest dodawane do dolnego transportera.
18. Wywoływany jest `fbElevator()`.
19. Wywoływane są FB wykonawcze siłowników i transporterów.
20. Wyniki FB wykonawczych są przepisywane do `GVL_IO.dout`.
21. Składane są lampy, buzzery i LED przycisków.
22. Składane są sygnały robota i wywoływany jest `fbModbusComm()`.
23. Aktualizowane są alarmy i statusy HMI.
24. `PRG_IO_Write()` kopiuje `GVL_IO.dout` na fizyczne wyjścia.

## Ważna konsekwencja kolejności

Sekwencery czytają statusy z TopFlow, BottomAccumulator, windy, siłowników i robota z wartości dostępnych na początku tej części skanu. Część z tych wartości pochodzi z poprzedniego wywołania FB, czyli praktycznie z poprzedniego skanu.

To jest normalne dla cyklicznego programu PLC, ale trzeba o tym pamiętać:

- `fbTraySeq` i `fbBoxSeq` są wywołane przed finalnym `fbTopFlow()`,
- wyjścia sekwencerów są jednak ustawiane przed `fbTopFlow()`, więc TopFlow dostaje komendy w tym samym skanie,
- statusy fizyczne M2-M7 używane przez TopFlow pochodzą z ostatniego wywołania FB wykonawczych,
- `GVL_Robot.robotIn` używany przez sekwencery pochodzi z poprzedniego cyklu komunikacji Modbus, bo `fbModbusComm()` jest wywoływany po sekwencerach.

## Właściciele elementów maszyny

### P1-P3 i górny transporter

Właściciel logiki: `FB_TopFlowManager`.

TopFlow decyduje:

- kiedy ruszyć górny transporter,
- kiedy opuścić/podnieść M2-M4,
- kiedy wysunąć/cofnąć M5,
- jak aktualizować `OccP1..OccP3`,
- kiedy stos na P3 jest gotowy,
- kiedy transfer na P4 jest zakończony.

Fizyczne wykonanie:

- `fbStopM2`, `fbStopM3`, `fbStopM4` wykonują M2-M4,
- `fbPosM5` wykonuje M5,
- `fbConvTop` wykonuje górny transporter.

### P4, winda i transporter windy

Właściciel ruchu pionowego: `FB_Elevator`.

Właściciel procesu P4:

- `FB_TraySequencer` w trybie tacek,
- `FB_BoxSequencer` w trybie kuwet,
- logika emptying przy opróżnianiu.

Transporter na windzie:

- fizycznie wykonuje go `fbConvElev`,
- w kierunku IN może być uruchomiony przez TopFlow przy transferze na P4,
- w kierunku OUT jest uruchamiany przez sekwencery lub emptying przy rozładunku.

### P5-P7 i dolny transporter

Właściciel logiki bufora: `FB_BottomAccumulator_567`.

Blok decyduje:

- czy dolny bufor może przyjąć pojemnik z windy,
- kiedy wykonać jeden krok,
- jak zaktualizować `Occ5..Occ7`.

Fizyczne wykonanie:

- `fbConvBottom` wykonuje dolny transporter,
- `PRG_Main` dodaje `fbBottom567.Outp.ConvRun` do `fbConvBottom.Cmd.RunFwd`.

### Robot FANUC

Właściciel procesu:

- `FB_TraySequencer` w trybie tacek,
- `FB_BoxSequencer` w trybie kuwet.

Komunikacja:

- `PRG_Main` składa `GVL_Robot.robotOut`,
- `FB_ModbusComm` mapuje bity na bufory Modbus,
- status wraca przez `GVL_Robot.robotIn`.

## Tryb ręczny

W trybie ręcznym `PRG_Main` bezpośrednio wpisuje komendy:

- do windy: `elevCmd.eMode := MANUAL`, `xManUp`, `xManDown`, `xManFast`,
- do transporterów: `fbConv*.Cmd.RunFwd/RunBwd`,
- do siłowników: `CmdExtend` albo `HoldUp`.

W trybie ręcznym aktywny TraySequencer albo BoxSequencer dostaje `PauseAuto`, a `xStopAuto` oznacza abort do `DISABLED`.

Ważne:

- nawet w manualu fizyczne wyjścia nadal przechodzą przez FB wykonawcze,
- `FB_Conveyor` nadal blokuje jednoczesne FWD+BWD,
- `FB_Cyl2Pos` i `FB_StopperPair` nadal diagnozują krańcówki i timeouty.

## Tryb tacek

Główna ścieżka zależności:

```text
Operator potwierdza P1
  -> M1 pozycjonuje pojemnik
    -> TopFlow przyjmuje token P1
      -> TopFlow transportuje stos na P3
        -> TraySeq czeka na StackReadyAtP3
          -> robot układa tacki na windzie
            -> TraySeq steruje M6 i windą do krawędzi
              -> po stosie TraySeq rozładowuje P4 na dół
```

W trybie tacek:

- TopFlow obsługuje P1-P3, M2-M5 i górny transporter,
- TraySeq obsługuje robot handshake, M6, windę, rozładunek i BottomAccumulator,
- TopFlow nie planuje normalnego transferu `TG_ELEV`, bo robot sam odkłada tacki na P4.

## Tryb kuwet

Główna ścieżka zależności:

```text
Operator potwierdza P1
  -> M1 pozycjonuje kuwetę
    -> TopFlow buforuje/podaje kuwetę
      -> BoxSeq prosi TopFlow o karmienie windy
        -> TopFlow + transporter windy przenoszą kuwetę na P4
          -> BoxSeq steruje M7
            -> BoxSeq steruje windą do krawędzi
              -> robot paletyzuje kuwetę
                -> BoxSeq rozładowuje P4 na dół
```

W trybie kuwet:

- BoxSeq prosi TopFlow o podanie pojemnika na P4,
- TopFlow wykonuje transfer P1/P2/P3 -> P4,
- `PRG_Main` dodaje `TopFlow.Elev_TransferActive` do `fbConvElev.Cmd.RunFwd`,
- BoxSeq steruje M7, windą i rozładunkiem.

## Opróżnianie stacji

Logika emptying jest w `PRG_Main`, nie w osobnym FB.

W uproszczeniu:

```text
TOP_FLUSH
  -> TopFlow podaje pojemniki z P1-P3 na P4
ELEV_DOWN
  -> winda jedzie na dół
DISCHARGE
  -> transporter windy OUT + dolny FWD
ELEV_UP
  -> winda wraca na górę
BOTTOM_FLUSH
  -> dolny transporter opróżnia P5-P7 do wyjścia
DONE
```

Emptying korzysta z tych samych bloków:

- `FB_TopFlowManager`,
- `FB_Elevator`,
- `FB_BottomAccumulator_567`,
- `FB_Conveyor`.

Sekwencery TraySeq i BoxSeq dostaja `AbortAuto` przez `xEmptyRunning`.

## Komendy i feedback między FB

### TraySeq -> TopFlow

```text
TopFlow_Enable
TopFlow_StackConsumed
```

TraySeq czyta:

```text
TopFlow_StackReadyAtP3
TopFlow_OccP3
TopFlow_Busy
TopFlow_Fault
```

### BoxSeq -> TopFlow

```text
TopFlow_Enable
TopFlow_Elev_RequestFeed
TopFlow_Elev_CanAccept
```

BoxSeq czyta:

```text
TopFlow_OccP3
TopFlow_Busy
TopFlow_Fault
TopFlow_ElevDeliveredAtP4
```

### Sekwencery -> Elevator

```text
Elev_AutoGo
Elev_AutoTarget
Elev_Stop
```

Sekwencery czytają:

```text
Elev_AtTop
Elev_AtBottom
Elev_AtTarget
Elev_Busy
Elev_Fault
```

### Sekwencery -> BottomAccumulator

```text
Bottom_Enable
Bottom_DischargeReq
```

Sekwencery czytają:

```text
Bottom_CanAccept
Bottom_Busy
Bottom_Fault
```

### TopFlow -> wykonawka

```text
HoldPos1_Up -> M2
HoldPos2_Up -> M3
HoldPos3_Up -> M4
M5_Extend   -> M5
TopConveyor_Run -> górny transporter
Elev_TransferActive -> transporter windy IN
```

### Sekwencery -> wykonawka

TraySeq:

```text
M6_Extend
ElevConv_RunBwd
BottomConv_RunFwd
```

BoxSeq:

```text
M7_Extend
ElevConv_RunBwd
BottomConv_RunFwd
```

## Komunikacja z robotem

Robot jest obsługiwany przez `GVL_Robot` i `FB_ModbusComm`.

Sekwencery nie piszą bezpośrednio do Modbus. Wystawiają tylko swoje wyjścia:

```text
Robot_TrayProduction
Robot_BoxProduction
Robot_StackReady
Robot_ElevatorReady
```

`PRG_Main` składa z nich:

```text
cmd_tray_production
cmd_box_production
cmd_stack_ready
cmd_elevator_ready
cmd_continue_job
cmd_samples
```

Następnie `FB_ModbusComm` mapuje je na rejestry `GVL_ModbusTCP.mbBuf.aRobotTxRegs`.

Status robota wraca przez:

```text
mbBuf.aRobotRxRegs
  -> FB_ModbusComm
    -> GVL_Robot.robotIn
      -> TraySeq / BoxSeq / HMI
```

## Diagnostyka i alarmy

Alarmy HMI w `PRG_Main` są zbudowane z diagnostyki:

- siłowników `FB_Cyl2Pos` i `FB_StopperPair`,
- transporterów `FB_Conveyor`,
- windy `FB_Elevator`,
- TopFlow,
- BottomAccumulator,
- TraySeq,
- BoxSeq,
- robota,
- komunikacji,
- niskiego ciśnienia,
- safety.

Hierarchia błędów wygląda tak:

```text
FB wykonawczy fault
  -> menedżer/sekwencer widzi fault wejściowy
    -> sekwencer przechodzi do FAULT
      -> PRG_Main zapala alarm/lampę/buzzer
```

Przykład:

```text
fbBottom567.Diag.Fault
  -> fbTraySeq.Inp.Bottom_Fault
    -> fbTraySeq.Diag.Fault
      -> GVL_HMI.hmiAlarms.xTraySeq_Fault
```

## Kolejność wyjść fizycznych

Po obliczeniu TopFlow, BottomAccumulator i Elevator wywoływane są bloki wykonawcze:

1. M2,
2. M3,
3. M4,
4. M1,
5. M5,
6. M6,
7. M7,
8. M8,
9. górny transporter,
10. transporter windy,
11. dolny transporter.

Każdy z nich dopiero po wywołaniu przepisuje swoje `Outp` do `GVL_IO.dout`.

Na końcu `PRG_IO_Write()` przepisuje `GVL_IO.dout` na `GVL_IO_RAW.dout`.

## Miejsca szczególnie ważne przy uruchomieniu

- Robot status z Modbus trafia do sekwencerów z opóźnieniem cyklu komunikacji.
- `Elev_TransferDone` dla TopFlow jest filtrowane 2 s z P4.
- BoxSeq przechodzi do M7 dopiero po `TopFlow_ElevDeliveredAtP4` oraz aktywnym `ind_container_in_pos_4`.
- W trybie manualnym sekwencery są zatrzymane, ale FB wykonawcze nadal diagnozują sprzęt.
- `xModeTray` i `xModeBox` mają mutex w PLC: jeśli HMI wybierze oba, oba tryby lokalne są `FALSE`.
- `xAutoActive` jest liczone po wywołaniu obu sekwencerów.
- Winda pionowa i transporter windy to dwa różne FB: `FB_Elevator` i `fbConvElev`.
- TopFlow zarządza M2-M5, TraySeq zarządza M6, BoxSeq zarządza M7.
- M1 jest osobną logiką załadunku w `PRG_Main`, nie częścią TopFlow.
- Emptying nie jest osobnym FB, tylko stanem w `PRG_Main`, który używa tych samych bloków.

## Schemat całości

```text
                 +------------------+
                 |     PRG_Main     |
                 +------------------+
                         |
       +-----------------+-----------------+
       |                                   |
  Tryb tacek                           Tryb kuwet
       |                                   |
 FB_TraySequencer                  FB_BoxSequencer
       |                                   |
       +---------------+-------------------+
                       |
              FB_TopFlowManager
                       |
        +--------------+--------------+
        |              |              |
    M2/M3/M4          M5       górny transporter
        |              |              |
 FB_StopperPair  FB_StopperPair   FB_Conveyor

 FB_TraySequencer -> M6 -> FB_StopperPair
 FB_BoxSequencer  -> M7 -> FB_Cyl2Pos

 FB_TraySequencer / FB_BoxSequencer
        -> FB_Elevator -> GIATV.Control_ATV -> ATV320

 FB_TraySequencer / FB_BoxSequencer
        -> FB_BottomAccumulator_567
             -> FB_Conveyor dolny

 FB_TraySequencer / FB_BoxSequencer
        -> GVL_Robot.robotOut
             -> FB_ModbusComm
                -> Robot FANUC
```

## Jak czytać projekt

Najłatwiejsza kolejność analizy:

1. Zacznij od `PRG_Main`, żeby zobaczyć mapowania.
2. Dla fizycznych elementów czytaj `FB_Cyl2Pos`, `FB_StopperPair`, `FB_Conveyor`, `FB_Elevator`.
3. Dla lokalnych buforów czytaj `FB_TopFlowManager` i `FB_BottomAccumulator_567`.
4. Dla procesu czytaj `FB_TraySequencer` albo `FB_BoxSequencer`.
5. Dla robota czytaj `GVL_Robot`, `GVL_ModbusTCP` i `FB_ModbusComm`.

Taka kolejność odpowiada temu, jak sygnały przechodzą przez program: od sprzętu i wykonawki do decyzji procesowych, a potem z powrotem do wyjść.
