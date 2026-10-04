# FB_BoxSequencer - sekwencer produkcji kuwet

## Rola funkcjonalna

`FB_BoxSequencer` jest głównym sekwencerem trybu AUTO dla produkcji do kuwet. Koordynuje cykl pojedynczej kuwety od podania jej na windę P4, przez pozycjonowanie M7 i paletyzację robota, aż do rozładunku pełnej kuwety na dolny transporter.

Najważniejsze różnice względem `FB_TraySequencer`:

- kuweta jedzie bezpośrednio na windę P4,
- nie ma stosu tacek na P3 jako punktu pracy robota,
- nie ma cyklu M6 po każdym odłożeniu tacki,
- używany jest pozycjoner M7,
- jedna kuweta oznacza jeden cykl paletyzacji robota,
- koniec pracy robota jest sygnalizowany przez `Robot_StackFinished`, interpretowane jako “kuweta gotowa / zapełniona”.

## Gdzie jest używany

W `PRG_Main` istnieje jedna instancja:

- `fbBoxSeq : FB_BoxSequencer`.

`PRG_Main` aktywuje ją tylko wtedy, gdy:

- wybrany jest tryb kuwet,
- nie ma trybu ręcznego,
- nie trwa opróżnianie stacji.

Wyjścia `fbBoxSeq` są mapowane na:

- `FB_TopFlowManager`,
- `FB_Elevator`,
- `FB_BottomAccumulator_567`,
- `FB_Conveyor` windy i dolnego transportera,
- `FB_Cyl2Pos` M7,
- `GVL_Robot.robotOut`.

## Interfejs wejściowy

### `Cfg : ST_BoxSeqCfg`

Parametry:

- `tPositionerTimeout` - timeout M7,
- `tRobotAckTimeout` - timeout oczekiwania na robota, domyślnie `T#180s`,
- `tDischargeTimeout` - timeout rozładunku windy,
- `tTransferTimeout` - timeout transferu kuwety na windę razem ze stabilnym potwierdzeniem P4,
- `tElevReturnTimeout` - timeout powrotu windy na górę.

### `Cmd : ST_BoxSeqCmd`

Komendy:

- `StartAuto` - start trybu AUTO,
- `ResumeAuto` - wznowienie po przerwaniu/fault,
- `PauseAuto` - pauza AUTO bez kasowania stanu procesu,
- `AbortAuto` - abort AUTO do `DISABLED`,
- `SafetyOK` - globalne zezwolenie,
- `ResetFault` - reset błędu.

`StartAuto` jest obsługiwane zboczem. `ResumeAuto` jest poziomem używanym tylko w stanie `PAUSED`.

### `Inp : ST_BoxSeqIn`

Wejścia z TopFlow:

- `TopFlow_OccP3`,
- `TopFlow_Busy`,
- `TopFlow_Fault`.

Wejścia z windy:

- `Elev_AtTop`,
- `Elev_AtBottom`,
- `Elev_AtTarget`,
- `Elev_Busy`,
- `Elev_Fault`.

Wejścia z dolnego akumulatora:

- `Bottom_CanAccept`,
- `Bottom_Busy`,
- `Bottom_Fault`.

Czujniki:

- `ind_container_in_pos_4` - kuweta na windzie,
- `ind_elevator_emptied` - kuweta opuściła windę.

Feedback M7:

- `M7_AtExt`,
- `M7_AtRet`.

Robot:

- `Robot_SystemReady`,
- `Robot_PrgRunning`,
- `Robot_AutoMode`,
- `Robot_Fault`,
- `Robot_StackFinished`,
- `Robot_CmdAck`.

Uwaga: `Robot_CmdAck` jest mapowane do wejścia, ale aktualny kod nie używa go w warunkach przejść.

## Interfejs wyjściowy

### Do TopFlow

- `TopFlow_Enable` - włącza TopFlow,
- `TopFlow_Elev_RequestFeed` - prośba o podanie kuwety na windę,
- `TopFlow_Elev_CanAccept` - informacja, że winda jest u góry i P4 jest puste.

To jest główny kontrakt między BoxSeq i TopFlow. BoxSeq nie planuje sam ruchów P1/P2/P3. Prosi TopFlow o karmienie P4.

### Do windy

- `Elev_AutoGo`,
- `Elev_AutoTarget`,
- `Elev_Stop`.

BoxSeq zadaje targety:

- `posContainerEdge` - po spozycjonowaniu kuwety M7,
- `posBottom` - przed rozładunkiem pełnej kuwety,
- `posTop` - po rozładunku.

### Do BottomAccumulator

- `Bottom_Enable`,
- `Bottom_DischargeReq`.

### Do transporterów

- `TopConv_RunFwd`,
- `ElevConv_RunFwd`,
- `ElevConv_RunBwd`,
- `BottomConv_RunFwd`.

W aktualnym kodzie górny transporter w praktyce jest uruchamiany przez `FB_TopFlowManager`, nie przez `TopConv_RunFwd` z BoxSeq. BoxSeq steruje żądaniem karmienia windy, a TopFlow wystawia `TopConveyor_Run` i `Elev_TransferActive`.

### Do M7

- `M7_Extend` - wysuń/cofnij pozycjoner kuwety.

W `PRG_Main` sygnał jest dodatkowo maskowany:

```text
xModeBox AND fbBoxSeq.Outp.AutoRunning AND fbBoxSeq.Outp.M7_Extend
```

Poza aktywnym trybem kuwet M7 wraca do cofnięcia.

### Do robota

- `Robot_BoxProduction`,
- `Robot_StackReady`,
- `Robot_ElevatorReady`.

Nazwy `StackReady` i `StackFinished` są wspólne z trybem tacek. W trybie kuwet oznaczają odpowiednio gotowość kuwety oraz zakończenie paletyzacji kuwety.

## Status i diagnostyka

### `Sts : ST_BoxSeqStatus`

- `State` - aktualny stan sekwencji,
- `BoxCount` - liczba gotowych kuwet od startu,
- `Busy` - sekwencer wykonuje aktywną część cyklu.

### `Diag : ST_BoxSeqDiag`

Możliwe błędy:

- `ROBOT_NOT_READY`,
- `ELEVATOR_FAULT`,
- `TOP_FLOW_FAULT`,
- `BOTTOM_FAULT`,
- `POSITIONER_TIMEOUT`,
- `ROBOT_TIMEOUT`,
- `DISCHARGE_TIMEOUT`,
- `TRANSFER_TIMEOUT`.

Faulty z TopFlow, windy i BottomAccumulator są propagowane do BoxSeq.

## Automat stanów

Stany:

- `DISABLED` - sekwencer nieaktywny,
- `IDLE` - aktywny, prosi TopFlow o kuwetę,
- `PAUSED` - pauza AUTO z zapamiętanym stanem wznowienia,
- `FEED_ELEVATOR` - oczekiwanie na transfer kuwety na P4,
- `POS_M7_FWD` - wysunięcie M7,
- `ELEV_TO_EDGE` - zjazd windy do krawędzi kuwety,
- `SIGNAL_ROBOT` - sygnały gotowości do robota,
- `WAIT_PALLET_DONE` - oczekiwanie na koniec paletyzacji kuwety,
- `RETRACT_M7` - cofnięcie M7,
- `ELEV_TO_BOTTOM` - zjazd windy na dół,
- `DISCHARGE` - rozładunek windy na dolny transporter,
- `WAIT_ELEV_EMPTY` - przejście po potwierdzeniu opróżnienia,
- `ELEV_RETURN_TOP` - powrót windy na górę,
- `FAULT` - bezpieczne zatrzymanie.

## Jak działa kod krok po kroku

1. FB wykrywa zbocza:

   - `StartAuto`,
   - `Robot_StackFinished`.

2. Przy `ResetFault = TRUE` kasuje diagnostykę i timer. Jeśli był w `FAULT`, to:

   - przy poprawnym `eResumeState` przechodzi do `PAUSED`,
   - bez poprawnego stanu wznowienia przechodzi do `DISABLED`.

3. Na początku skanu zerowane są domyślne wyjścia:

   - komendy windy,
   - żądania TopFlow,
   - transportery,
   - M7,
   - sygnały robota.

4. Jeśli `SafetyOK = FALSE`, sekwencer wystawia `Elev_Stop`, zeruje ruchy transporterów i kończy wykonanie przez `RETURN`. Stan nie jest kasowany.

5. Jeśli winda, TopFlow albo BottomAccumulator zgłoszą fault, BoxSeq przechodzi do `FAULT` i zapamiętuje stan wznowienia.

6. `AbortAuto` przełącza sekwencer do `DISABLED` i unieważnia stan wznowienia.

7. `PauseAuto` zapisuje aktualny stan do `eResumeState`, przełącza sekwencer do `PAUSED`, gasi ruchy i nie zeruje `BoxCount`.

8. `ResumeAuto` z `PAUSED` wraca do zapamiętanego stanu.

9. W `DISABLED` tylko start zeruje `BoxCount` i przechodzi do `IDLE`.

10. W `IDLE` sekwencer:

   - włącza TopFlow,
   - włącza BottomAccumulator,
   - wystawia `TopFlow_Elev_RequestFeed`,
   - wystawia `TopFlow_Elev_CanAccept`, jeśli winda jest u góry i P4 puste.

11. Jeśli TopFlow potwierdził zakończony transfer na P4 i czujnik P4 jest aktywny, przechodzi od razu do `POS_M7_FWD`.

12. Jeśli TopFlow ma kuwetę na P3, winda jest u góry i P4 jest puste, przechodzi do `FEED_ELEVATOR`.

13. W `FEED_ELEVATOR` BoxSeq dalej prosi TopFlow o karmienie windy. Czeka na potwierdzenie `TopFlow_ElevDeliveredAtP4` i aktywne P4 albo timeout `tTransferTimeout`.

14. Dopiero po potwierdzeniu transferu przez TopFlow przechodzi do `POS_M7_FWD`.

15. W `POS_M7_FWD` wysuwa M7 i czeka na `M7_AtExt`.

16. Po wysunięciu M7 przechodzi do `ELEV_TO_EDGE`.

17. W `ELEV_TO_EDGE` utrzymuje M7 wysunięte i zadaje windzie `posContainerEdge`. Stan kończy się, gdy zgaśnie `ind_container_in_pos_4`.

18. W `SIGNAL_ROBOT` utrzymuje M7, wystawia `Robot_StackReady` i `Robot_ElevatorReady`, a potem czeka, aż robot będzie:

   - `Robot_PrgRunning`,
   - `Robot_AutoMode`,
   - `Robot_SystemReady`.

19. W `WAIT_PALLET_DONE` sekwencer czeka na zbocze `Robot_StackFinished`. W trybie kuwet jest to sygnał zakończenia kuwety.

20. Po `Robot_StackFinished` zwiększa `BoxCount` i przechodzi do `RETRACT_M7`.

21. W `RETRACT_M7` cofa M7 i czeka na `M7_AtRet`.

22. W `ELEV_TO_BOTTOM` zadaje windzie `posBottom`.

23. W `DISCHARGE`, jeśli `Bottom_CanAccept = TRUE`, uruchamia:

   - transporter windy OUT,
   - dolny transporter FWD,
   - `Bottom_DischargeReq`.

   Czeka na `ind_elevator_emptied`.

24. Po potwierdzeniu opróżnienia przechodzi przez `WAIT_ELEV_EMPTY` do `ELEV_RETURN_TOP`.

25. W `ELEV_RETURN_TOP` zadaje windzie `posTop`. Po osiągnięciu góry wraca do `IDLE`.

26. W `FAULT` zatrzymuje transportery, zadaje stop windy i kasuje sygnały gotowości do robota.

## Transfer kuwety na P4

BoxSeq sam nie podaje kuwety transporterem. Robi to przez TopFlow:

```text
BoxSeq: TopFlow_Elev_RequestFeed = TRUE
BoxSeq: TopFlow_Elev_CanAccept = Elev_AtTop AND NOT P4
TopFlow: planuje ruch do TG_ELEV
PRG_Main: uruchamia górny transporter oraz transporter windy IN
```

BoxSeq przechodzi z `FEED_ELEVATOR` do `POS_M7_FWD` dopiero wtedy, gdy TopFlow wystawi `TopFlow_ElevDeliveredAtP4` i czujnik `ind_container_in_pos_4` nadal potwierdza pojemnik na windzie. Dzięki temu M7 nie zaczyna pozycjonowania przed zakończeniem transferu przez TopFlow.

## Relacja z TopFlowManager

BoxSeq:

- włącza TopFlow,
- prosi o kuwetę na windę,
- informuje, kiedy winda może przyjąć pojemnik,
- obserwuje `TopFlow_OccP3`, `TopFlow_Busy`, `TopFlow_Fault` i `TopFlow_ElevDeliveredAtP4`.

TopFlow:

- wybiera źródło P3/P2/P1,
- steruje M2-M4 i górnym transporterem,
- uruchamia transfer na P4 przez `Elev_TransferActive`,
- zatrzymuje transfer po `Elev_TransferDone`.

## Relacja z windą

BoxSeq zadaje windzie:

- `posContainerEdge` po wysunięciu M7,
- `posBottom` po zakończeniu paletyzacji,
- `posTop` po rozładunku.

Ruch pionowy wykonuje `FB_Elevator`.

## Relacja z M7

M7 jest pozycjonerem kuwety na windzie.

Sekwencja:

```text
P4 aktywne
  -> M7 extend
    -> winda do posContainerEdge
      -> robot paletyzuje
        -> M7 retract
```

Fizycznie `M7_Extend` jest mapowane w `PRG_Main` do `fbPosM7.CmdExtend`, a `fbPosM7` jest instancją `FB_Cyl2Pos`.

## Relacja z BottomAccumulator

Po zakończeniu paletyzacji BoxSeq zjeżdża windą na dół. Następnie, jeśli `Bottom_CanAccept = TRUE`, wystawia:

- `ElevConv_RunBwd`,
- `BottomConv_RunFwd`,
- `Bottom_DischargeReq`.

`Bottom_DischargeReq` uruchamia jeden krok `FB_BottomAccumulator_567`, a transporter dolny jest fizycznie obsługiwany przez `FB_Conveyor`.

## Relacja z robotem

Do robota idą:

- `cmd_box_production`,
- `cmd_stack_ready`,
- `cmd_elevator_ready`.

Z robota BoxSeq oczekuje:

- `sts_prg_running`,
- `sts_auto_mode`,
- `sts_system_ready`,
- `sts_fault`,
- `sts_stack_finished`.

W trybie kuwet `sts_stack_finished` oznacza praktycznie zakończenie paletyzacji jednej kuwety.

`Robot_CmdAck` jest wejściem, ale aktualny kod nie używa go do potwierdzania startu albo zakończenia komendy.

## Wznowienie i fault

Mechanizm wznowienia jest analogiczny do TraySeq:

- przy fault sekwencer zapisuje `eResumeState`,
- `ResetFault` kasuje fault,
- jeśli `eResumeState` jest poprawny, sekwencer przechodzi do `PAUSED`,
- `ResumeAuto` z `PAUSED` wraca do zapamiętanego stanu,
- `AbortAuto` przechodzi do `DISABLED` i kasuje możliwość wznowienia.

Przy samym zaniku `SafetyOK` sekwencer nie zmienia stanu, tylko wyłącza ruchy i wykonuje `RETURN`.

## Zależności z PRG_Main

`PRG_Main`:

1. Ustawia start/pause/abort/resume/reset.
2. Mapuje wejścia z TopFlow, windy, BottomAccumulator, P4, M7 i robota.
3. Wywołuje `fbBoxSeq()`.
4. Oblicza `xAutoActive`.
5. Jeśli BoxSeq jest aktywny, mapuje jego wyjścia do TopFlow, transporterów, windy i BottomAccumulator.
6. Osobno mapuje `M7_Extend` do `fbPosM7.CmdExtend`.
7. Mapuje sygnały robota i status HMI.

Ścieżka zależności:

```text
FB_BoxSequencer
  -> FB_TopFlowManager
  -> FB_Elevator
  -> FB_Cyl2Pos M7
  -> FB_BottomAccumulator_567
  -> FB_Conveyor windy/dolny
  -> GVL_Robot.robotOut
```

## Na co uważać przy uruchomieniu

- Sprawdź, czy w trybie kuwet TopFlow i transporter windy faktycznie ruszają razem przy transferze na P4.
- Sprawdź czas `tTransferTimeout = T#12s`; obejmuje dojazd kuwety i stabilizację P4 po stronie TopFlow.
- Sprawdź moment startu M7: BoxSeq powinien ruszyć dalej dopiero po `TopFlow_ElevDeliveredAtP4` i aktywnym P4.
- Sprawdź wysunięcie i cofnięcie M7 oraz kierunek działania `fbPosM7.CmdExtend`.
- Sprawdź `posContainerEdge`: po M7 winda musi zjechać aż P4 zgaśnie.
- Sprawdź znaczenie robota `Robot_StackFinished`; w trybie kuwet to sygnał “kuweta zakończona”.
- `Robot_CmdAck` jest nieużywany, więc start robota jest uznany po `Robot_PrgRunning AND Robot_AutoMode AND Robot_SystemReady`.
- Przy rozładunku `Bottom_CanAccept` musi blokować cykl, gdy P7 jest zajęte.
- `Bottom_DischargeReq` jest poziomem z BoxSeq, ale BottomAccumulator reaguje na zbocze.
- Po fault/reset sprawdź przejście do `PAUSED`, a potem wznowienie przez `ResumeAuto` w stanach `FEED_ELEVATOR`, `POS_M7_FWD`, `ELEV_TO_EDGE`, `WAIT_PALLET_DONE` i `DISCHARGE`.

## Miejsce w hierarchii

`FB_BoxSequencer` jest wysokopoziomowym sekwencerem trybu kuwet.

```text
PRG_Main
  -> FB_BoxSequencer
    -> TopFlowManager podaje kuwetę na P4
    -> M7 pozycjonuje kuwetę
    -> Elevator bazuje do krawędzi i zjeżdża na dół
    -> Robot paletyzuje kuwetę
    -> BottomAccumulator przyjmuje gotową kuwetę
```

Ten blok opisuje kolejność procesu kuwety, a niższe FB wykonują konkretne ruchy i diagnostykę sprzętu.
