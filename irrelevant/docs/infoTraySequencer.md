# FB_TraySequencer - sekwencer produkcji tacek

## Rola funkcjonalna

`FB_TraySequencer` jest głównym sekwencerem trybu AUTO dla produkcji do tacek. Koordynuje cały cykl od momentu, gdy górny bufor przygotuje stos na P3, aż do rozładunku gotowego pojemnika z windy na dolny transporter.

Blok nie steruje bezpośrednio stoperami M2-M4, bramką M5 ani górnym transporterem. Te elementy należą do `FB_TopFlowManager`. `FB_TraySequencer` mówi tylko, że TopFlow ma być aktywny i kiedy stos na P3 został zużyty przez robota.

Główne zadania `FB_TraySequencer`:

- uruchomić tryb tacek,
- poczekać na stos gotowy na P3,
- wysłać robotowi sygnały `tray production`, `stack ready` i `elevator ready`,
- liczyć ułożone tacki,
- po każdej tacy wykonać cykl M6,
- zadać windzie zjazd do krawędzi pojemnika,
- po skończeniu stosu zwolnić P3 przez TopFlow,
- zjechać windą na dół,
- uruchomić rozładunek przez transporter windy i dolny transporter,
- wrócić windą na górę i zacząć kolejny cykl.

## Gdzie jest używany

W `PRG_Main` istnieje jedna instancja:

- `fbTraySeq : FB_TraySequencer`.

`PRG_Main` aktywuje ją tylko wtedy, gdy:

- wybrany jest tryb tacek,
- nie ma trybu ręcznego,
- nie trwa opróżnianie stacji.

Wyjścia `fbTraySeq` są później mapowane na:

- `FB_TopFlowManager`,
- `FB_Elevator`,
- `FB_BottomAccumulator_567`,
- `FB_Conveyor` windy i dolnego transportera,
- `FB_StopperPair` M6,
- `GVL_Robot.robotOut`.

## Interfejs wejściowy

### `Cfg : ST_TraySeqCfg`

Parametry:

- `uiTraysInStack` - liczba tacek w stosie, domyślnie `8`,
- `tPositionerTimeout` - timeout M6,
- `tRobotAckTimeout` - timeout oczekiwania na robota,
- `tP4ConfirmTimeout` - timeout potwierdzenia P4 po sygnale odlozenia tacki przez robota,
- `tDischargeTimeout` - timeout rozładunku windy,
- `tElevReturnTimeout` - timeout powrotu windy na górę.

W `PRG_Main` `uiTraysInStack` jest pobierane z HMI. Jeśli HMI poda `0`, program ustawia domyślnie `8`.

### `Cmd : ST_TraySeqCmd`

Komendy:

- `StartAuto` - start trybu AUTO,
- `ResumeAuto` - wznowienie po przerwaniu/fault,
- `PauseAuto` - pauza AUTO bez kasowania stanu procesu,
- `AbortAuto` - abort AUTO do `DISABLED`,
- `SafetyOK` - globalne zezwolenie,
- `ResetFault` - reset błędu.

`StartAuto` jest obsługiwany zboczem `R_TRIG`, a `ResumeAuto` działa jako poziom wznowienia w `PAUSED`.

### `Inp : ST_TraySeqIn`

Wejścia z TopFlow:

- `TopFlow_OccP3`,
- `TopFlow_StackReadyAtP3`,
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

Czujniki P4/windy:

- `ind_container_in_pos_4`,
- `ind_elevator_emptied`.

Feedback M6:

- `M6_IsUp`,
- `M6_IsDown`.

Robot:

- `Robot_SystemReady`,
- `Robot_PrgRunning`,
- `Robot_InHome`,
- `Robot_AutoMode`,
- `Robot_Fault`,
- `Robot_PalletFinished`,
- `Robot_StackFinished`,
- `Robot_CmdAck`.

Uwaga: w aktualnym kodzie `Robot_InHome` i `Robot_CmdAck` są mapowane do wejść, ale nie są używane w warunkach przejść stanów.

## Interfejs wyjściowy

### Do TopFlow

- `TopFlow_Enable` - włącz logikę górnego bufora,
- `TopFlow_Elev_RequestFeed` - nieużywane w praktyce trybu tacek,
- `TopFlow_Elev_CanAccept` - nieużywane w praktyce trybu tacek,
- `TopFlow_StackConsumed` - impuls informujący, że robot zużył stos z P3.

### Do windy

- `Elev_AutoGo`,
- `Elev_AutoTarget`,
- `Elev_Stop`.

TraySeq zadaje windzie targety:

- `posContainerEdge` - po każdej tacy,
- `posBottom` - przed rozładunkiem gotowego pojemnika,
- `posTop` - po rozładunku.

### Do dolnego akumulatora

- `Bottom_Enable`,
- `Bottom_DischargeReq`.

### Do transporterów

- `ElevConv_RunFwd`,
- `ElevConv_RunBwd`,
- `BottomConv_RunFwd`.

W trybie tacek używane jest głównie:

- `ElevConv_RunBwd` - transporter windy w kierunku rozładunku,
- `BottomConv_RunFwd` - dolny transporter do wyjścia.

Górny transporter jest sterowany przez TopFlow, nie przez TraySeq.

### Do M6

- `M6_Extend` - wysuń/cofnij pozycjoner tacki na windzie.

### Do robota

- `Robot_TrayProduction`,
- `Robot_StackReady`,
- `Robot_ElevatorReady`.

W `PRG_Main` te sygnały są maskowane trybem i `AutoRunning`, a potem mapowane do `GVL_Robot.robotOut`.

## Status i diagnostyka

### `Sts : ST_TraySeqStatus`

- `State` - aktualny stan sekwencji,
- `TrayCount` - liczba ułożonych tacek w bieżącym stosie,
- `StackCount` - liczba zakończonych stosów od startu,
- `Busy` - sekwencer wykonuje aktywną część cyklu.

### `Diag : ST_TraySeqDiag`

Możliwe błędy:

- `ROBOT_NOT_READY`,
- `ELEVATOR_FAULT`,
- `TOP_FLOW_FAULT`,
- `BOTTOM_FAULT`,
- `POSITIONER_TIMEOUT`,
- `ROBOT_TIMEOUT`,
- `P4_NOT_DETECTED`,
- `DISCHARGE_TIMEOUT`.

Błędy z TopFlow, windy i BottomAccumulator są propagowane do TraySeq jako fault sekwencji.

## Automat stanów

Stany:

- `DISABLED` - sekwencer nieaktywny,
- `IDLE` - aktywny, czeka na warunki startu cyklu,
- `PAUSED` - proces zatrzymany z zapamiętanym stanem wznowienia,
- `WAIT_STACK_READY` - czeka na stos gotowy na P3,
- `SIGNAL_ROBOT` - wystawia sygnały gotowości do robota,
- `WAIT_TRAY_DONE` - czeka na odłożenie tacki lub koniec stosu,
- `CHECK_P4_OCCUPIED` - potwierdza czujnik P4 po sygnale robota, przed M6,
- `POS_M6_CYCLE` - wysuwa i cofa M6,
- `ELEV_TO_EDGE` - zadaje windzie zjazd do krawędzi pojemnika,
- `RETRACT_POS` - informuje TopFlow, że stos na P3 jest zużyty,
- `ELEV_TO_BOTTOM` - zadaje windzie zjazd na dół,
- `DISCHARGE` - rozładunek windy na dolny transporter,
- `WAIT_ELEV_EMPTY` - przejściowy stan po potwierdzeniu opróżnienia,
- `ELEV_RETURN_TOP` - powrót windy na górę,
- `FAULT` - bezpieczne zatrzymanie sekwencji.

## Jak działa kod krok po kroku

1. Na początku FB wykrywa zbocza:

   - `StartAuto`,
   - `ResumeAuto`,
   - `Robot_PalletFinished`,
   - `Robot_StackFinished`.

2. Jeśli `ResetFault = TRUE`, kasuje diagnostykę i timer. Jeśli sekwencer był w `FAULT`, to:

   - przy poprawnym `eResumeState` przechodzi do `PAUSED`,
   - jeśli nie ma poprawnego stanu wznowienia, przechodzi do `DISABLED`.

3. FB zeruje domyślne wyjścia impulsowe i ruchowe:

   - komendy windy,
   - rozładunek,
   - transportery,
   - M6,
   - sygnały robota.

4. Jeśli `SafetyOK = FALSE`, sekwencer zatrzymuje transportery, wystawia `Elev_Stop` i wychodzi z FB przez `RETURN`. Stan nie jest wtedy kasowany.

5. Jeżeli któryś z podbloków zgłasza fault, TraySeq przechodzi do `FAULT` i zapamiętuje stan wznowienia.

6. `AbortAuto` przełącza sekwencer do `DISABLED` i unieważnia stan wznowienia.

7. `PauseAuto` zapisuje aktualny stan do `eResumeState`, przełącza sekwencer do `PAUSED`, gasi ruchy i nie zeruje liczników.

8. W `PAUSED` `ResumeAuto` wraca do zapamiętanego `eResumeState`.

9. W `DISABLED` tylko start zeruje liczniki i przechodzi do `IDLE`. Sam `ResumeAuto` nie uruchamia sekwencji po abort.

10. W `IDLE` sekwencer włącza TopFlow i BottomAccumulator. Czeka, aż winda będzie u góry i P4 będzie puste.

11. W `WAIT_STACK_READY` sekwencer czeka na `TopFlow_StackReadyAtP3`. TopFlow sam w tym czasie doprowadza stos na P3, obsługuje M5 i M4.

12. W `SIGNAL_ROBOT` sekwencer wystawia:

   - `Robot_StackReady`,
   - `Robot_ElevatorReady`.

   Potem czeka, aż robot będzie w trybie AUTO, system ready i program running.

13. W `WAIT_TRAY_DONE` sekwencer:

   - utrzymuje `Robot_StackReady`,
   - wystawia `Robot_ElevatorReady`, jeśli można przyjąć kolejną tackę,
   - czeka na impuls `Robot_PalletFinished` albo `Robot_StackFinished`.

14. Gdy przyjdzie `Robot_PalletFinished`, sekwencer przechodzi do `CHECK_P4_OCCUPIED`.

15. W `CHECK_P4_OCCUPIED` sekwencer wymaga aktywnego `ind_container_in_pos_4`. Dopiero po potwierdzeniu P4 zwiększa `TrayCount`, zeruje fazę M6 i przechodzi do `POS_M6_CYCLE`.

16. W `POS_M6_CYCLE` są dwie fazy:

   - faza 1: `M6_Extend = TRUE` i oczekiwanie na `M6_IsUp`,
   - faza 2: `M6_Extend = FALSE` i oczekiwanie na `M6_IsDown`.

17. Po cofnięciu M6 sekwencer przechodzi do `ELEV_TO_EDGE`.

18. W `ELEV_TO_EDGE` zadaje windzie:

   ```text
   Elev_AutoTarget := posContainerEdge
   ```

   i czeka, aż zgaśnie `ind_container_in_pos_4` oraz winda przestanie być zajęta.

19. Po zakończeniu ruchu do krawędzi sekwencer wraca do `WAIT_TRAY_DONE` i ponownie wystawia robotowi `Robot_ElevatorReady`.

20. Jeśli robot wystawi `Robot_StackFinished` albo licznik `TrayCount` osiągnie `uiTraysInStack`, sekwencer przechodzi do rozładunku stosu.

21. W `RETRACT_POS` sekwencer wystawia `TopFlow_StackConsumed`. TopFlow zwalnia P3 i może przygotowywać kolejny stos.

22. W `ELEV_TO_BOTTOM` sekwencer zadaje windzie `posBottom`.

23. W `DISCHARGE`, jeśli `Bottom_CanAccept = TRUE`, sekwencer uruchamia:

   - transporter windy OUT,
   - dolny transporter FWD,
   - `Bottom_DischargeReq`.

   Czeka na `ind_elevator_emptied`.

24. Po potwierdzeniu opróżnienia przechodzi przez `WAIT_ELEV_EMPTY` do `ELEV_RETURN_TOP`.

25. W `ELEV_RETURN_TOP` zadaje windzie `posTop`. Po osiągnięciu góry wraca do `IDLE`.

26. W `FAULT` zatrzymuje transportery, daje `Elev_Stop` i kasuje sygnały gotowości do robota.

## Logika liczników

`TrayCount` zwiększa się na zboczu `Robot_PalletFinished`.

`StackCount` zwiększa się:

- na zboczu `Robot_StackFinished`,
- albo fallbackowo, gdy `TrayCount >= uiTraysInStack`.

Jeśli `uiTraysInStack = 0` w konfiguracji FB, kod traktuje to jako brak limitu i nie wyłącza `Robot_ElevatorReady` na podstawie licznika. W aktualnym `PRG_Main` wartość `0` z HMI jest zastępowana przez `8`.

## Relacja z TopFlowManager

TraySeq nie steruje górnym transporterem ani M2-M5. Wysyła tylko:

- `TopFlow_Enable`,
- `TopFlow_StackConsumed`.

Odbiera:

- `TopFlow_StackReadyAtP3`,
- `TopFlow_Fault`.

W trybie tacek TopFlow przygotowuje stos na P3:

```text
P3 zajęte + M4 up + M5 down -> StackReadyAtP3
```

Dopiero wtedy TraySeq sygnalizuje robotowi gotowość stosu.

## Relacja z windą

TraySeq zadaje trzy rodzaje ruchów windy:

- `posContainerEdge` po każdej tacy,
- `posBottom` do rozładunku,
- `posTop` po rozładunku.

Sama winda jest obsługiwana przez `FB_Elevator`. TraySeq widzi tylko jej statusy i wystawia targety.

## Relacja z M6

M6 jest jedynym pozycjonerem procesu tacek sterowanym bezpośrednio przez TraySeq.

Po każdym impulsie `Robot_PalletFinished`:

```text
sprawdz P4 -> M6 extend -> czekaj M6_IsUp -> M6 retract -> czekaj M6_IsDown -> winda do krawedzi -> Robot_ElevatorReady
```

Fizycznie `M6_Extend` idzie w `PRG_Main` do `fbPosM6.HoldUp`, a `fbPosM6` jest instancją `FB_StopperPair`.

## Relacja z BottomAccumulator

Przy rozładunku TraySeq wymaga `Bottom_CanAccept = TRUE`.

Gdy dolny bufor może przyjąć pojemnik:

- uruchamia transporter windy OUT,
- uruchamia dolny transporter FWD,
- wysyła `Bottom_DischargeReq`.

`Bottom_DischargeReq` powoduje wykonanie kroku w `FB_BottomAccumulator_567`.

## Relacja z robotem

Do robota idą trzy główne sygnały:

- `cmd_tray_production` - produkcja tacek aktywna,
- `cmd_stack_ready` - stos gotowy na P3,
- `cmd_elevator_ready` - robot może odkładać tackę na windę.

Z robota TraySeq oczekuje:

- `sts_prg_running`,
- `sts_auto_mode`,
- `sts_system_ready`,
- `sts_fault`,
- `sts_pallet_finished`,
- `sts_stack_finished`.

Najważniejsze impulsy procesu:

- `Robot_PalletFinished` - tacka została odłożona,
- `Robot_StackFinished` - cały stos został zakończony.

Przy uruchomieniu koniecznie trzeba potwierdzić, czy mapowanie DO robota odpowiada znaczeniom używanym w PLC.

## Wznowienie i fault

Przy faultach z podbloków albo timeoutach sekwencer zapisuje `eResumeState`, czyli stan, w którym wystąpił problem.

Po `ResetFault`:

- jeśli ma zapamiętany poprawny `eResumeState`, przechodzi do `PAUSED`,
- dalszy powrót do procesu wymaga `ResumeAuto`,
- jeśli nie ma poprawnego stanu wznowienia, przechodzi do `DISABLED`.

Przy samym zaniku `SafetyOK` sekwencer nie zmienia stanu, tylko wyłącza ruchy i robi `RETURN`. To ma umożliwić powrót z tego samego miejsca po przywróceniu safety.

## Zależności z PRG_Main

`PRG_Main`:

1. Ustawia komendy start/stop/resume.
2. Wpisuje konfigurację `uiTraysInStack`.
3. Mapuje wejścia z TopFlow, windy, BottomAccumulator, M6 i robota.
4. Wywołuje `fbTraySeq()`.
5. Mapuje wyjścia TraySeq do innych bloków.
6. Mapuje sygnały robota z `fbTraySeq.Outp` do `GVL_Robot.robotOut`.
7. Wysyła statusy i liczniki do HMI.

Ścieżka zależności:

```text
FB_TraySequencer
  -> FB_TopFlowManager
  -> FB_Elevator
  -> FB_StopperPair M6
  -> FB_BottomAccumulator_567
  -> FB_Conveyor windy/dolny
  -> GVL_Robot.robotOut
```

## Na co uważać przy uruchomieniu

- Sprawdź, czy w trybie tacek TopFlow najpierw przygotowuje P3, a TraySeq nie sygnalizuje robota przed `StackReadyAtP3`.
- Sprawdź mapowanie impulsów robota `pallet finished` i `stack finished`. TraySeq liczy tacki na `Robot_PalletFinished`.
- `Robot_CmdAck` jest wejściem, ale nie steruje przejściami. Start robota jest uznany po `Robot_PrgRunning AND Robot_AutoMode AND Robot_SystemReady`.
- `Robot_InHome` też jest wejściem, ale aktualny kod go nie używa.
- Po każdej tacy sprawdź kolejność: `Robot_PalletFinished`, P4 aktywne, cykl M6, zjazd windy do krawędzi, dopiero potem `Robot_ElevatorReady`.
- Dla `posContainerEdge` koniec stanu `ELEV_TO_EDGE` zależy od zgaśnięcia `ind_container_in_pos_4` oraz `Elev_Busy = FALSE`.
- Sprawdź, czy po osiągnięciu `uiTraysInStack` robot nie dostaje dalej `ElevatorReady`.
- Przy rozładunku sprawdź, że `Bottom_CanAccept` blokuje ruch, gdy P7 jest zajęte.
- W `DISCHARGE` `Bottom_DischargeReq` jest trzymany poziomem, ale BottomAccumulator reaguje na zbocze. To jest OK dla jednego kroku, ale kolejny krok wymaga zejścia i ponownego narastania sygnału.
- Timeout robota `tRobotAckTimeout` ma domyślnie `T#120s`. Przy długim cyklu robota może wymagać korekty.
- Po fault/reset z `ResumeAuto` sprawdź zachowanie na każdym krytycznym stanie: `WAIT_TRAY_DONE`, `POS_M6_CYCLE`, `ELEV_TO_EDGE`, `DISCHARGE`.

## Miejsce w hierarchii

`FB_TraySequencer` jest wysokopoziomowym sekwencerem trybu tacek.

```text
PRG_Main
  -> FB_TraySequencer
    -> TopFlowManager przygotowuje stos
    -> Robot układa tacki
    -> M6 pozycjonuje tackę
    -> Elevator bazuje do krawędzi i zjeżdża na dół
    -> BottomAccumulator przyjmuje gotowy pojemnik
```

Ten blok opisuje “kolejność procesu”, a niższe FB wykonują poszczególne ruchy i diagnostykę sprzętu.
