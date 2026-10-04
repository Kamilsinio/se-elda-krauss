# FB_BottomAccumulator_567 - akumulator dolny P5-P7

## Rola funkcjonalna

`FB_BottomAccumulator_567` zarządza dolnym buforem rozładunku obejmującym pozycje:

- `P5` - pierwsza pozycja po zjeździe z windy,
- `P6` - pozycja pośrednia rozładunku,
- `P7` - ostatnia pozycja / wyjście.

Blok nie steruje bezpośrednio fizycznym wyjściem silnika. Wystawia tylko logiczne żądanie:

- `Outp.ConvRun` - uruchom dolny transporter w kierunku wyjścia.

`PRG_Main` dodaje to żądanie do `fbConvBottom.Cmd.RunFwd`, a dopiero `FB_Conveyor` wystawia fizyczne wyjście PLC.

Główne zadanie bloku: po żądaniu `DischargeReq` wykonać jeden krok dolnego transportera tak, aby pojemnik z windy mógł wejść na `P5`, a istniejące pojemniki na dole przesunęły się dalej:

```text
P5 -> P6
P6 -> P7
P4 -> P5
```

## Gdzie jest używany

W `PRG_Main` istnieje jedna instancja:

- `fbBottom567 : FB_BottomAccumulator_567`.

Korzystają z niej:

- `FB_TraySequencer` - rozładunek po zakończeniu stosu tacek,
- `FB_BoxSequencer` - rozładunek po zakończeniu kuwety,
- logika `Opróżnij stację` w `PRG_Main`,
- HMI status/alarmy.

## Interfejs wejściowy

### `Cfg : ST_Bottom567Cfg`

Parametry czasowe:

- `tMotorStopDelay` - zwłoka po zatrzymaniu transportera, domyślnie `T#300ms`,
- `tStepTimeout` - maksymalny czas jednego kroku, domyślnie `T#8s`,
- `tSensorStable` - filtr czujników przy postoju, domyślnie `T#80ms`.

### `Cmd : ST_Bottom567Cmd`

Komendy:

- `EnableAuto` - zezwolenie pracy automatycznej bloku,
- `SafetyOK` - warunek safety/global enable,
- `DischargeReq` - żądanie wykonania kroku, gdy winda chce oddać pojemnik,
- `ResetFault` - reset błędu.

`DischargeReq` jest obsługiwane przez `R_TRIG`, czyli blok reaguje na zbocze narastające, a nie na sam poziom ciągły.

### `Inp : ST_Bottom567In`

Wejścia z czujników dolnego bufora:

- `sPos5_raw` - pojemnik na P5,
- `sPos6_raw` - pojemnik na P6,
- `sPos7_raw` - pojemnik na P7.

W `PRG_Main` są mapowane z:

- `ind_container_in_pos_5`,
- `ind_container_in_pos_6`,
- `ind_container_in_pos_7`.

## Interfejs wyjściowy

### `Outp : ST_Bottom567Out`

Wyjścia:

- `ConvRun` - logiczne żądanie pracy dolnego transportera FWD,
- `AlarmQueueFull` - informacja, że kolejka jest pełna / P7 zajęta,
- `StepDonePulse` - impuls jednoskanowy po zakończeniu kroku.

### `Sts : ST_Bottom567Status`

Status:

- `State` - stan automatu,
- `Busy` - blok wykonuje krok,
- `Occ5` - logiczna zajętość P5,
- `Occ6` - logiczna zajętość P6,
- `Occ7` - logiczna zajętość P7,
- `CanAcceptFromElev` - dolny bufor może przyjąć pojemnik z windy.

`CanAcceptFromElev` jest liczone jako:

```text
NOT Occ7 AND NOT Fault
```

czyli jeśli P7 jest zajęte, blok nie pozwala na kolejny krok z windy.

### `Diag : ST_Bottom567Diag`

Diagnostyka:

- `Fault` - aktywny błąd,
- `Code` - kod błędu,
- `Text` - opis.

Możliwe błędy:

- `FULL_QUEUE` - P7 zajęte, nie ma miejsca na kolejny krok,
- `MOVE_TIMEOUT` - krok transportera nie zakończył się w czasie.

## Automat stanów

`FB_BottomAccumulator_567` używa stanów:

- `INIT` - inicjalizacja zajętości z czujników,
- `IDLE` - postój i oczekiwanie na żądanie kroku,
- `PRECHECK` - sprawdzenie, czy można wykonać krok,
- `RUN_STEP` - jazda dolnego transportera,
- `WAIT_STOP` - zwłoka po zatrzymaniu,
- `COMPLETE` - impuls zakończenia kroku,
- `FAULT` - błąd.

## Jak działa kod krok po kroku

1. Blok wylicza `permissive`:

   ```iecst
   permissive := Cmd.EnableAuto AND Cmd.SafetyOK AND (NOT Diag.Fault);
   ```

2. Jeśli `ResetFault = TRUE`, blok kasuje diagnostykę i timery. Jeśli był w stanie `FAULT`, wraca do `INIT`.

3. `StepDonePulse` jest domyślnie zerowany w każdym skanie.

4. Czujniki P5-P7 są filtrowane tylko wtedy, gdy transporter nie pracuje:

   ```iecst
   t5(IN := (NOT Outp.ConvRun) AND Inp.sPos5_raw, PT := Cfg.tSensorStable);
   ```

   To jest ważne, bo podczas jazdy czujniki mogą migać i nie powinny bezpośrednio nadpisywać modelu zajętości.

5. Jeśli `EnableAuto = FALSE` albo `SafetyOK = FALSE`, blok zatrzymuje transporter, kasuje timery i kończy wykonanie przez `RETURN`.

6. `DischargeReq` jest podawane na `R_TRIG`. Nowy krok zaczyna się tylko na zboczu narastającym.

7. W `INIT` blok przepisuje stabilne czujniki do modelu logicznego:

   - `Occ5 := s5_stable`,
   - `Occ6 := s6_stable`,
   - `Occ7 := s7_stable`.

8. W `IDLE` blok:

   - zatrzymuje transporter,
   - odświeża `Occ5..Occ7` ze stabilnych czujników,
   - wylicza `CanAcceptFromElev`,
   - ustawia `AlarmQueueFull`, jeśli P7 jest zajęte,
   - przy zboczu `DischargeReq` przechodzi do `PRECHECK`.

9. W `PRECHECK` blok sprawdza P7:

   - jeśli `Occ7 = TRUE`, ustawia `FULL_QUEUE`,
   - jeśli `Occ7 = FALSE`, zapamiętuje czy P5 było zajęte i przechodzi do `RUN_STEP`.

10. W `RUN_STEP` blok włącza `ConvRun`.

11. Sposób zatrzymania zależy od tego, czy P5 było zajęte przed ruchem:

   - jeśli P5 było zajęte, blok czeka aż P5 zgaśnie, a potem zapali się ponownie,
   - jeśli P5 było puste, blok zatrzymuje transporter, gdy P5 zapali się pierwszy raz.

   Dzięki temu nowy pojemnik z P4 powinien zatrzymać się na P5.

12. Jeśli krok trwa dłużej niż `tStepTimeout`, blok ustawia `MOVE_TIMEOUT`.

13. W `WAIT_STOP` blok czeka `tMotorStopDelay`.

14. Po zwłoce model logiczny zajętości jest przesuwany o jeden krok:

   ```iecst
   Occ7 := Occ6;
   Occ6 := Occ5;
   Occ5 := TRUE;
   ```

   `Occ5 := TRUE` oznacza, że po kroku na P5 pojawił się nowy pojemnik z windy.

15. W `COMPLETE` blok wystawia `StepDonePulse` na jeden skan i wraca do `IDLE`.

16. W `FAULT` transporter jest wyłączony, `Busy = FALSE`, a `AlarmQueueFull = TRUE`.

## Model logiczny a czujniki

Blok pracuje na modelu `Occ5..Occ7`. Czujniki są używane do:

- inicjalizacji,
- odświeżenia modelu w postoju,
- wykrycia właściwego momentu zatrzymania kroku po P5.

Podczas ruchu blok nie próbuje stale przeliczać zajętości z P6 i P7. Po zakończeniu kroku wykonuje przesunięcie modelowe. To jest prostsze i odporne na miganie czujników podczas przejazdu.

## Relacja z transporterem dolnym

`FB_BottomAccumulator_567` nie jest napędem. Wystawia `Outp.ConvRun`, a `PRG_Main` robi:

```text
fbConvBottom.Cmd.RunFwd := fbConvBottom.Cmd.RunFwd OR fbBottom567.Outp.ConvRun
```

Dopiero `fbConvBottom : FB_Conveyor` obsługuje blokadę kierunków i fizyczne wyjście:

- `ctrl_turn_on_bottom_conveyor` - FWD do wyjścia,
- `ctrl_turn_on_bottom_conveyor_in` - BWD w kierunku windy.

## Relacja z TraySequencer

W trybie tacek `FB_TraySequencer` po zakończeniu stosu:

1. zadaje windzie zjazd na dół,
2. przechodzi do rozładunku,
3. sprawdza `Bottom_CanAccept`,
4. uruchamia transporter windy OUT i dolny FWD,
5. wystawia `Bottom_DischargeReq`,
6. czeka na `ind_elevator_emptied`.

W `PRG_Main` sygnały są połączone tak:

- `fbTraySeq.Inp.Bottom_CanAccept := fbBottom567.Sts.CanAcceptFromElev`,
- `fbBottom567.Cmd.EnableAuto := fbTraySeq.Outp.Bottom_Enable`,
- `fbBottom567.Cmd.DischargeReq := fbTraySeq.Outp.Bottom_DischargeReq`.

## Relacja z BoxSequencer

W trybie kuwet `FB_BoxSequencer` używa dolnego akumulatora analogicznie:

1. po zakończeniu paletyzacji zadaje windzie `posBottom`,
2. jeśli `Bottom_CanAccept = TRUE`, uruchamia rozładunek,
3. wystawia `Bottom_DischargeReq`,
4. czeka na `ind_elevator_emptied`,
5. potem zadaje powrót windy na górę.

## Relacja z opróżnianiem stacji

Logika `Opróżnij stację` w `PRG_Main` używa `fbBottom567` dwojako:

- przy rozładunku z windy na dół ustawia `EnableAuto` i `DischargeReq`,
- przy stanie `BOTTOM_FLUSH` uruchamia dolny transporter bezpośrednio, aby opróżnić P5-P7 do wyjścia.

Warto pamiętać, że bezpośrednie flushowanie P5-P7 przez `fbConvBottom.Cmd.RunFwd` omija model kroku `FB_BottomAccumulator_567`. Po takim opróżnianiu model powinien zostać ponownie odświeżony w stanie postoju.

## Na co uważać przy uruchomieniu

- Sprawdź kierunek FWD dolnego transportera. Dla tego bloku FWD musi oznaczać ruch P5 -> P6 -> P7 -> wyjście.
- Sprawdź pozycję czujnika P5. Logika zatrzymania kroku opiera się głównie o zgaszenie i ponowne zapalenie P5.
- Jeżeli P5 było zajęte przed krokiem, blok oczekuje sekwencji: P5 OFF, potem P5 ON. Jeśli czujnik P5 nie gaśnie podczas przejazdu, krok może wejść w timeout.
- Jeżeli P5 było puste, blok zatrzyma się na pierwszym pojawieniu się P5.
- P7 zajęte blokuje przyjęcie kolejnego pojemnika z windy. To jest normalne zabezpieczenie przed przepełnieniem.
- `AlarmQueueFull` w FAULT jest ustawiane także dla błędu timeout, nie tylko dla pełnego P7. Przy HMI warto rozróżniać właściwy `Diag.Code`.
- W tekście błędu w kodzie pojawia się nazwa `Bottom457`, choć blok dotyczy P5-P7. To tylko komentarz/tekst diagnostyczny, ale może mylić operatora.
- `CanAcceptFromElev` jest aktualizowane w `IDLE`. W trakcie ruchu lub po wyłączeniu bloku może być wartością z poprzedniego stanu.
- `DischargeReq` jest zboczowe. Jeśli sekwencer trzyma `DischargeReq = TRUE` przez dłuższy czas, blok wykona jeden krok na pierwszym zboczu, a kolejny dopiero po zejściu i ponownym narastaniu sygnału.
- Po ręcznym przesunięciu pojemników na dolnym transporterze trzeba pozwolić blokowi wrócić do postoju, żeby model `Occ5..Occ7` odświeżył się z czujników.

## Miejsce w hierarchii

`FB_BottomAccumulator_567` jest warstwą logiki transportowej, wyżej niż pojedynczy transporter, ale niżej niż sekwencery produkcji.

```text
TraySequencer / BoxSequencer / Emptying
  -> FB_BottomAccumulator_567
    -> PRG_Main dodaje ConvRun do fbConvBottom.Cmd.RunFwd
      -> FB_Conveyor
        -> fizyczny dolny transporter
```

Blok odpowiada za jeden obszar procesu: akumulację i przyjmowanie pojemników z windy na dolny transporter P5-P7.

