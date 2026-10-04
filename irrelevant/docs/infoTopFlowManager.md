# FB_TopFlowManager - górny bufor P1-P3

## Rola funkcjonalna

`FB_TopFlowManager` zarządza przepływem pojemników/stosów na górnym transporterze, czyli pozycjami:

- `P1` - pozycja załadunku operatora,
- `P2` - pozycja buforowa,
- `P3` - pozycja przy robocie / koniec górnego bufora.

Blok odpowiada za:

- pamięć logicznej zajętości `OccP1..OccP3`,
- przyjmowanie pojemnika z P1 dopiero po potwierdzeniu operatora i M1,
- planowanie ruchów między P1, P2, P3 i P4,
- sterowanie górnym transporterem,
- sterowanie stoperami M2, M3, M4,
- sterowanie bramką/pozycjonerem M5 w trybie tacek,
- handshake transferu na windę P4 w trybie kuwet i opróżniania,
- informację `StackReadyAtP3` dla `FB_TraySequencer`.

To jest główny blok logiki górnego przepływu. Nie steruje fizycznie cewkami i napędami bezpośrednio. Wystawia komendy, które `PRG_Main` przekazuje do `FB_StopperPair` i `FB_Conveyor`.

## Gdzie jest używany

W `PRG_Main` istnieje jedna instancja:

- `fbTopFlow : FB_TopFlowManager`.

Z TopFlow korzystają:

- `FB_TraySequencer` - tryb tacek,
- `FB_BoxSequencer` - tryb kuwet,
- logika `Opróżnij stację`,
- HMI status/alarmy.

## Interfejs wejściowy

### `Cfg : ST_TopFlowCfg`

Parametry czasowe:

- `tMotorStopDelay` - zwłoka po zatrzymaniu górnego transportera przed ruchem stoperów,
- `tStopperTimeout` - timeout dojazdu stoperów M2-M4 i M5,
- `tMoveTimeout` - timeout ruchu pojemnika po transporterze,
- `tSensorStable` - filtr stabilizacji czujników przy postoju.

### `Cmd : ST_TopFlowCmd`

Komendy:

- `EnableAuto` - zezwolenie pracy bloku,
- `SafetyOK` - zbiorczy warunek bezpieczeństwa,
- `EmptyingMode` - tryb opróżniania stacji,
- `Pos1AcceptedPulse` - impuls zatwierdzenia pojemnika na P1,
- `TrayMode` - `TRUE` dla tacek, `FALSE` dla kuwet,
- `ResetFault` - reset błędu.

`Pos1AcceptedPulse` pochodzi z logiki M1 w `PRG_Main`. Operator naciska przycisk gotowości pojemnika, M1 pozycjonuje pojemnik, a po potwierdzeniu wysunięcia M1 program generuje impuls dla TopFlow.

### `Inp : ST_TopFlowIn`

Wejścia z czujników i bloków niższej warstwy:

- `sPos1_raw`, `sPos2_raw`, `sPos3_raw`, `sPos4_raw` - surowe czujniki P1-P4,
- `StopP1_IsUp/IsDown` - status M2,
- `StopP2_IsUp/IsDown` - status M3,
- `StopP3_IsUp/IsDown` - status M4,
- `Elev_CanAccept` - winda na górze i P4 puste,
- `Elev_RequestFeed` - sekwencer prosi o pojemnik na windę,
- `Elev_TransferDone` - P4 aktywne stabilnie przez 2 s,
- `M5_IsUp/M5_IsDown` - status bramki M5,
- `StackConsumedAtP3` - TraySeq informuje, że robot zużył stos z P3.

W aktualnym `PRG_Main` `Elev_TransferDone` jest filtrowane timerem `TON` na czujniku P4.

## Interfejs wyjściowy

### `Outp : ST_TopFlowOut`

Wyjścia do niższych warstw:

- `TopConveyor_Run` - uruchom górny transporter FWD,
- `HoldPos1_Up` - M2 ma trzymać P1,
- `HoldPos2_Up` - M3 ma trzymać P2,
- `HoldPos3_Up` - M4 ma trzymać P3,
- `M5_Extend` - wysuń bramkę/pozycjoner M5,
- `Elev_TransferReq` - żądanie transferu na windę,
- `Elev_TransferActive` - aktywny transfer poziomy na P4,
- `Elev_SourcePos` - informacja, z której pozycji idzie transfer na windę.

`PRG_Main` po wywołaniu `fbTopFlow()` przepisuje te wyjścia:

- `HoldPos1_Up..HoldPos3_Up` do `fbStopM2..M4.HoldUp`,
- `M5_Extend` do `fbPosM5.HoldUp`,
- `TopConveyor_Run` do `fbConvTop.Cmd.RunFwd`,
- `Elev_TransferActive` dodaje do `fbConvElev.Cmd.RunFwd`.

### `Sts : ST_TopFlowStatus`

Status:

- `OccP1`, `OccP2`, `OccP3` - logiczna zajętość górnego bufora,
- `Pos1Accepted` - token operatora dla pojemnika z P1,
- `Busy` - TopFlow jest w trakcie ruchu,
- `State` - stan automatu,
- `SrcPos` - pozycja źródłowa aktualnego ruchu,
- `Target` - cel aktualnego ruchu,
- `BufferFull` - P1-P3 zajęte,
- `Starved` - sekwencer prosi o podanie na windę, ale TopFlow nie ma gotowego pojemnika,
- `StackReadyAtP3` - stos na P3 jest gotowy dla robota,
- `ElevDeliveredAtP4` - transfer `TG_ELEV` został zakończony i P4 jest potwierdzone stabilnie.

### `Diag : ST_TopFlowDiag`

Diagnostyka:

- `Fault`,
- `FaultCode`,
- `FaultText`.

Kody błędów:

- `STOPPER_TIMEOUT` - M2/M3/M4/M5 nie osiągnęły wymaganej pozycji,
- `MOVE_TIMEOUT` - transporter nie doprowadził pojemnika do celu w czasie,
- `ILLEGAL_COMMAND` - zdefiniowane w enumie, obecnie nieużywane,
- `TRANSFER_HANDSHAKE_TIMEOUT` - zdefiniowane w enumie, obecnie nieużywane.

## Model logiczny zajętości

TopFlow nie opiera całej logiki bezpośrednio o migające czujniki podczas ruchu. Utrzymuje własny model:

- `OccP1`,
- `OccP2`,
- `OccP3`.

Czujniki P1-P3 są stabilizowane tylko wtedy, gdy górny transporter stoi:

```iecst
tPos1Stable(IN := (NOT Outp.TopConveyor_Run) AND Inp.sPos1_raw, PT := Cfg.tSensorStable);
```

Model jest inicjalizowany z czujników w `INIT`, odświeżany częściowo w `IDLE` i aktualizowany modelowo po zakończonym ruchu w `COMPLETE`.

To podejście chroni przed fałszywą zmianą zajętości, gdy pojemnik przejeżdża przez czujnik podczas ruchu.

## Token P1

Pojemnik na P1 nie jest automatycznie uznany za gotowy do transportu tylko dlatego, że czujnik P1 jest aktywny.

W normalnej pracy potrzebny jest token:

```text
operator potwierdza załadunek
  -> M1 pozycjonuje pojemnik
    -> PRG_Main generuje xTopFlowAcceptPulse
      -> TopFlow ustawia Pos1Accepted
```

Dopiero wtedy `p1Ready = TRUE`.

Wyjątek: w `EmptyingMode` TopFlow może traktować P1 jako gotowe bez tokena operatora, żeby opróżnić stację.

## Tryb tacek

Gdy `Cmd.TrayMode = TRUE`, TopFlow nie planuje transferu `TG_ELEV` w normalnej produkcji. Dla tacek robot sam pobiera tacki ze stosu na P3 i odkłada je na windę.

Zadaniem TopFlow w tym trybie jest:

1. przyjąć zatwierdzony stos z P1,
2. buforować stosy na P2/P3,
3. priorytetowo doprowadzać stos do P3,
4. przed dojazdem do P3 wysunąć M5,
5. po dojechaniu do P3 cofnąć M5,
6. podnieść M4,
7. wystawić `StackReadyAtP3`.

`StackReadyAtP3` jest prawdziwe, gdy:

```text
OccP3 AND TrayMode AND StopP3_IsUp AND M5_IsDown
```

`FB_TraySequencer` czeka na ten sygnał, zanim powie robotowi, że stos jest gotowy.

Po zakończeniu stosu TraySeq wystawia `StackConsumedAtP3`. TopFlow zapamiętuje ten impuls i w `IDLE` zwalnia `OccP3`.

## Tryb kuwet

Gdy `Cmd.TrayMode = FALSE`, TopFlow może planować transfer na windę `TG_ELEV`.

Priorytet w IDLE jest taki:

1. Jeśli `Elev_RequestFeed = TRUE` i `Elev_CanAccept = TRUE`, najpierw próbuj karmić windę.
2. Jeśli na P3 jest pojemnik, transferuj P3 -> P4.
3. Jeśli na P2 jest pojemnik, przesuń P2 -> P3.
4. Jeśli P1 jest gotowe, a P2/P3 są puste, transferuj P1 -> P4.
5. Jeśli nie da się nakarmić windy, ustaw `Starved`.
6. Jeśli nie ma aktywnego planu karmienia windy, wykonuj buforowanie P2/P1 w stronę P3.

Transfer na P4 kończy się dopiero, gdy `Elev_TransferDone = TRUE`, czyli gdy P4 jest aktywne stabilnie przez 2 s.

## Tryb opróżniania

W `EmptyingMode` TopFlow może przenosić pojemniki z górnego bufora na windę bez wymagania tokena operatora dla P1.

`PRG_Main` ustawia wtedy:

- `fbTopFlow.Cmd.EnableAuto := TRUE`,
- `fbTopFlow.Cmd.EmptyingMode := TRUE`,
- `fbTopFlow.Inp.Elev_RequestFeed := TRUE`,
- `fbTopFlow.Inp.Elev_CanAccept := winda u góry AND P4 puste`.

To powoduje, że TopFlow działa podobnie jak w trybie kuwet i podaje pojemniki z P1-P3 na P4, aby stacja mogła zostać opróżniona.

## Automat stanów

`FB_TopFlowManager` używa stanów:

- `INIT` - inicjalizacja modelu `OccP1..OccP3` z czujników,
- `IDLE` - planowanie ruchu i obsługa gotowości P3,
- `PREP_STOP` - zatrzymaj transporter i odczekaj,
- `PREP_STOPPERS` - ustaw stopery i M5 przed ruchem,
- `RUN` - uruchom górny transporter,
- `WAIT_STOP` - odczekaj po zatrzymaniu transportera,
- `RETRACT_M5_GATE` - cofnij M5 po dojechaniu stosu tacek na P3,
- `LOCK_TARGET` - podnieś stoper docelowy P2/P3,
- `WAIT_LOCK` - czekaj na potwierdzenie stopera,
- `COMPLETE` - zaktualizuj model zajętości,
- `FAULT` - zatrzymaj ruch i trzymaj zajęte pozycje.

W enumie jest też `WAIT_M5_RETRACT`, ale aktualny kod go nie używa. Czekanie na cofnięcie M5 odbywa się bezpośrednio w stanie `RETRACT_M5_GATE`.

## Jak działa kod krok po kroku

1. Blok wylicza `permissive` jako `EnableAuto AND SafetyOK AND NOT Fault`.

2. Stabilizuje czujniki P1-P3 tylko przy zatrzymanym transporterze.

3. Obsługuje impuls `Pos1AcceptedPulse`. Jeśli P1 jest stabilnie zajęte, ustawia `Pos1Accepted`.

4. Jeśli P1 nie jest stabilnie zajęte, kasuje `Pos1Accepted`.

5. Reset błędu kasuje diagnostykę, timery i pending `StackConsumed`.

6. Domyślnie zerowane są wyjścia transferu na windę i `M5_Extend`.

7. Impuls `StackConsumedAtP3` jest zapamiętywany w `xStackConsumedPending`, nawet jeśli TopFlow jest akurat zajęty ruchem.

8. Jeśli `EnableAuto` albo `SafetyOK` są fałszywe, blok zatrzymuje transporter, ustawia stopery według zajętości i wychodzi z FB.

9. W `INIT` zajętość P1-P3 jest inicjalizowana ze stabilnych czujników.

10. W `IDLE` blok:

   - zatrzymuje transporter,
   - obsługuje zwolnienie P3 po zużyciu stosu,
   - liczy `BufferFull`,
   - liczy `StackReadyAtP3`,
   - ustawia domyślne holdy zajętych pozycji,
   - planuje następny ruch.

11. Jeśli zaplanowano ruch, `SrcPos` i `Target` są zapisane, a stan przechodzi do `PREP_STOP`.

12. W `PREP_STOP` TopFlow czeka `tMotorStopDelay`, żeby transporter był bezpiecznie zatrzymany przed ruchem stoperów.

13. W `PREP_STOPPERS` blok:

   - opuszcza stoper źródła,
   - opuszcza stoper celu P2/P3, jeśli pojemnik ma tam wjechać,
   - trzyma pozostałe zajęte pozycje,
   - w trybie tacek przy target P3 wysuwa M5,
   - czeka na potwierdzenia wszystkich wymaganych pozycji.

14. W `RUN` blok uruchamia górny transporter. Jeśli target to `TG_ELEV`, wystawia `Elev_TransferActive`, przez co `PRG_Main` uruchamia też transporter windy w kierunku przyjęcia.

15. Zatrzymanie w `RUN` zależy od celu:

   - `TG_P2` - stop po aktywacji P2,
   - `TG_P3` - stop po aktywacji P3,
   - `TG_ELEV` - stop po `Elev_TransferDone`.

16. W `WAIT_STOP` blok czeka po zatrzymaniu transportera.

17. Dla `TrayMode + TG_P3` blok przechodzi do `RETRACT_M5_GATE`, cofa M5 i dopiero potem blokuje P3 przez M4.

18. Dla targetów P2/P3 blok przechodzi do `LOCK_TARGET` i `WAIT_LOCK`, czyli podnosi docelowy stoper.

19. Dla `TG_ELEV` nie ma docelowego stopera na górze, więc blok przechodzi bezpośrednio do `COMPLETE`.

20. W `COMPLETE` blok modelowo aktualizuje zajętość:

   - target P2/P3 staje się zajęty,
   - source staje się pusty,
   - P1 jest ponownie odświeżane ze stabilnego czujnika.

21. W `FAULT` transporter jest zatrzymany, a stopery trzymają zajęte pozycje według pamięci `OccP1..OccP3`.

## Planowanie ruchów

### Buforowanie

Jeśli nie ma pilniejszego żądania karmienia windy, TopFlow buforuje w stronę P3:

```text
P2 -> P3, jeśli P3 wolne
P1 -> P3, jeśli P2 i P3 wolne
P1 -> P2, jeśli P2 wolne
```

Dzięki temu pierwszy stos w trybie tacek może pojechać od razu na P3, zgodnie z opisem procesu.

### Karmienie windy

W trybie kuwet albo emptying, jeśli winda może przyjąć pojemnik:

```text
P3 -> P4, jeśli P3 zajęte
P2 -> P3, jeśli P2 zajęte
P1 -> P4, jeśli P1 gotowe i P2/P3 wolne
```

Ten priorytet powoduje, że TopFlow najpierw próbuje obsłużyć robot/windę, a dopiero później zajmuje się samym buforowaniem.

## Zależności z PRG_Main

`PRG_Main` dostarcza do TopFlow:

- czujniki P1-P4,
- statusy M2-M4 z `FB_StopperPair`,
- statusy M5 z `FB_StopperPair`,
- `Elev_TransferDone`,
- `TrayMode`,
- `EmptyingMode`,
- `Pos1AcceptedPulse`.

Po wywołaniu `fbTopFlow()` `PRG_Main` przekazuje wyjścia TopFlow do:

- `fbStopM2`, `fbStopM3`, `fbStopM4`,
- `fbPosM5`,
- `fbConvTop`,
- `fbConvElev`.

Dodatkowo `PRG_Main` blokuje start górnego transportera przy ruchu z P1, dopóki M1 nie jest cofnięty.

## Relacja z FB_TraySequencer

W trybie tacek TraySeq:

- włącza TopFlow przez `TopFlow_Enable`,
- czeka na `TopFlow_StackReadyAtP3`,
- po skończeniu stosu wysyła `TopFlow_StackConsumed`,
- reaguje na `TopFlow_Fault`.

TopFlow jest odpowiedzialny za przygotowanie stosu na P3. TraySeq nie steruje bezpośrednio M2-M5 ani górnym transporterem.

## Relacja z FB_BoxSequencer

W trybie kuwet BoxSeq:

- włącza TopFlow,
- wystawia `TopFlow_Elev_RequestFeed`,
- wystawia `TopFlow_Elev_CanAccept`,
- obserwuje `TopFlow_OccP3`, `TopFlow_Busy` i `TopFlow_Fault`.

TopFlow odpowiada za doprowadzenie kuwety na P4, ale BoxSeq odpowiada za dalszą pracę windy, M7 i robota.

## Relacja z FB_StopperPair i FB_Conveyor

TopFlow nie wykonuje ruchu mechaniki sam. Wystawia tylko komendy:

```text
TopFlow.Outp.HoldPos1_Up -> fbStopM2.HoldUp
TopFlow.Outp.HoldPos2_Up -> fbStopM3.HoldUp
TopFlow.Outp.HoldPos3_Up -> fbStopM4.HoldUp
TopFlow.Outp.M5_Extend   -> fbPosM5.HoldUp
TopFlow.Outp.TopConveyor_Run -> fbConvTop.Cmd.RunFwd
```

`FB_StopperPair` odpowiada za fizyczne dojazdy i diagnostykę M2-M5, a `FB_Conveyor` za blokadę kierunków i wyjście górnego transportera.

## Na co uważać przy uruchomieniu

- Sprawdź czujniki P1-P3 przy zatrzymanym transporterze. To z nich TopFlow inicjalizuje `OccP1..OccP3`.
- Sprawdź token P1: po naciśnięciu `Pojemnik gotowy` M1 musi dojechać do wysunięcia, a dopiero potem TopFlow dostaje `Pos1AcceptedPulse`.
- Dla trybu tacek sprawdź sekwencję P3: M5 wysuwa się przed ruchem do P3, po dojechaniu stosu M5 cofa się, a dopiero potem M4 idzie w górę.
- Dla trybu kuwet sprawdź transfer P3/P1 na P4: górny transporter i transporter windy muszą pracować razem, a koniec transferu następuje po 2 s aktywnego P4.
- Sprawdź, czy `Elev_CanAccept` jest prawdziwe tylko wtedy, gdy winda jest u góry i P4 jest puste.
- `sPos4_raw` jest wejściem TopFlow, ale zakończenie transferu `TG_ELEV` używa `Elev_TransferDone`, czyli przefiltrowanego P4.
- W czasie przerwania `EnableAuto/SafetyOK` blok ustawia stopery według `OccP1..OccP3`. Po wznowieniu w środku ruchu warto testowo sprawdzić, czy stopery wracają do pozycji wymaganych przez aktualny stan.
- Timeout ruchu górnego transportera to domyślnie `T#10s`. Przy długim dojeździe P1 -> P3 albo wolnym transporterze może wymagać korekty.
- Tekst i logika emptying zależą od aktualnego modelu `OccP1..OccP3`; po ręcznych ruchach warto pozwolić TopFlow przejść przez postój/INIT, aby model był zgodny z czujnikami.

## Miejsce w hierarchii

`FB_TopFlowManager` jest warstwą logiki przepływu, położoną nad blokami wykonawczymi, ale pod sekwencerami produkcji.

```text
TraySequencer / BoxSequencer / Emptying
  -> FB_TopFlowManager
    -> FB_StopperPair M2-M5
    -> FB_Conveyor górny
    -> FB_Conveyor windy przy transferze na P4
```

TopFlow podejmuje decyzje o ruchach P1-P3/P4. Sekwencery decydują, kiedy potrzebują stosu albo kuwety, a bloki wykonawcze realizują mechanikę.
