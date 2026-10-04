# FB_StopperPair - para siłowników / stoper dwupołożeniowy

## Rola funkcjonalna

`FB_StopperPair` jest blokiem wykonawczym dla mechanizmu złożonego z dwóch zsynchronizowanych siłowników albo dwóch stron jednego stopera. Blok traktuje parę jako jeden element logiczny:

- `UP` / `FWD` - element wysunięty, podniesiony albo trzymający pojemnik,
- `DOWN` / `BWD` - element cofnięty, opuszczony albo przepuszczający pojemnik.

W projekcie ten sam FB obsługuje dwa typy mechaniki:

- stopery bufora górnego `M2`, `M3`, `M4`,
- pozycjonery/bramki parowe `M5`, `M6`.

Blok nie decyduje, kiedy pojemnik ma jechać. On tylko wykonuje komendę `HoldUp`, potwierdza osiągnięcie pozycji i zgłasza błędy czujników albo timeout ruchu.

## Gdzie jest używany

W `PRG_Main` istnieje pięć instancji `FB_StopperPair`:

- `fbStopM2` - stoper pozycji P1,
- `fbStopM3` - stoper pozycji P2,
- `fbStopM4` - stoper pozycji P3,
- `fbPosM5` - bramka/pozycjoner stosu tacek na P3,
- `fbPosM6` - pozycjoner tacek na windzie.

`M2`, `M3`, `M4` i `M5` są sterowane przez `FB_TopFlowManager`. `M6` jest sterowany przez `FB_TraySequencer`.

## Interfejs wejściowy

### `Cfg : ST_StopperPairCfg`

Konfiguracja czasów i sposobu sterowania cewką:

- `tStable` - czas stabilizacji czujników, domyślnie `T#50ms`,
- `tTimeout` - maksymalny czas dojazdu do pozycji, domyślnie `T#2s`,
- `HoldCoilInEndPos` - sposób pracy cewki po osiągnięciu pozycji.

Gdy `HoldCoilInEndPos = TRUE`, blok trzyma cewkę w pozycji docelowej cały czas. Gdy `FALSE`, cewka gaśnie po potwierdzeniu pozycji.

### `Enable : BOOL`

Zezwolenie pracy. Przy `Enable = FALSE` blok wyłącza obie cewki i ustawia `Busy = FALSE`.

### `HoldUp : BOOL`

Główna komenda pozycji:

- `TRUE` - żądaj pozycji `UP/FWD`,
- `FALSE` - żądaj pozycji `DOWN/BWD`.

W przypadku stoperów oznacza to zwykle:

- `TRUE` - trzymaj/zatrzymaj pojemnik,
- `FALSE` - opuść stoper i pozwól pojemnikowi jechać.

### `ResetFault : BOOL`

Kasuje błąd diagnostyczny:

- `Diag.Fault := FALSE`,
- `Diag.Code := NONE`,
- `Diag.Text := ''`.

### `Inp : ST_StopperPairIn`

Cztery wejścia czujników:

- `ind_1_fwd` - pierwszy siłownik w pozycji FWD,
- `ind_2_fwd` - drugi siłownik w pozycji FWD,
- `ind_1_bwd` - pierwszy siłownik w pozycji BWD,
- `ind_2_bwd` - drugi siłownik w pozycji BWD.

Pozycja `UP` jest uznana dopiero wtedy, gdy oba czujniki FWD są stabilnie aktywne. Pozycja `DOWN` analogicznie wymaga obu czujników BWD.

## Interfejs wyjściowy

### `Outp : ST_StopperPairOut`

Wyjścia na cewki:

- `Q_Fwd` - jazda / trzymanie w kierunku FWD,
- `Q_Bwd` - jazda / trzymanie w kierunku BWD.

Blok nie powinien wystawiać obu kierunków jednocześnie.

### `Sts : ST_StopperPairStatus`

Status mechaniki:

- `IsUp` - oba FWD stabilne przez `tStable`,
- `IsDown` - oba BWD stabilne przez `tStable`,
- `Busy` - element nie jest jeszcze w żądanej pozycji.

Te statusy są używane przez wyższe warstwy. `FB_TopFlowManager` czeka na `IsUp/IsDown` M2-M5 przed startem górnego transportera, a `FB_TraySequencer` używa statusów M6 w cyklu pozycjonowania tacki.

### `Diag : ST_StopperPairDiag`

Diagnostyka:

- `Fault` - aktywny błąd,
- `Code` - kod błędu z `E_StopperFault`,
- `Text` - opis.

Możliwe błędy:

- `SENSOR_CONTRADICTION` - jeden z dwóch siłowników ma jednocześnie aktywne FWD i BWD,
- `TIMEOUT` - para nie osiągnęła żądanej pozycji w czasie `Cfg.tTimeout`.

## Jak działa kod krok po kroku

1. Jeśli `ResetFault = TRUE`, blok kasuje błąd i opis diagnostyczny.

2. Jeśli `Enable = FALSE` albo `Diag.Fault = TRUE`, blok wyłącza wyjścia:

   ```iecst
   Outp.Q_Fwd := FALSE;
   Outp.Q_Bwd := FALSE;
   Sts.Busy := FALSE;
   ```

   Statusy czujników są jednak dalej liczone. To jest przydatne diagnostycznie, bo HMI może nadal pokazywać realną pozycję mechaniki.

3. Blok wykrywa sprzeczne czujniki osobno dla obu siłowników:

   ```iecst
   contradiction :=
       (Inp.ind_1_fwd AND Inp.ind_1_bwd) OR
       (Inp.ind_2_fwd AND Inp.ind_2_bwd);
   ```

4. Pozycje są filtrowane timerami `TON`:

   ```iecst
   tFwdStable(IN := (Inp.ind_1_fwd AND Inp.ind_2_fwd) AND (NOT contradiction), PT := Cfg.tStable);
   tBwdStable(IN := (Inp.ind_1_bwd AND Inp.ind_2_bwd) AND (NOT contradiction), PT := Cfg.tStable);
   ```

   `IsUp` jest prawdziwe tylko wtedy, gdy oba siłowniki są stabilnie w FWD. `IsDown` wymaga stabilnego BWD na obu siłownikach.

5. Jeśli wystąpi sprzeczność czujników i blok jest aktywny, ustawiany jest błąd `SENSOR_CONTRADICTION`.

6. Gdy blok jest aktywny i bez błędu, wybiera cel:

   - `HoldUp = TRUE` -> celem jest `Sts.IsUp`,
   - `HoldUp = FALSE` -> celem jest `Sts.IsDown`.

7. `Busy` jest ustawione, gdy cel nie został osiągnięty.

8. Timer `tMoveTO` liczy czas, w którym `Busy = TRUE`. Po przekroczeniu `Cfg.tTimeout` blok zgłasza `TIMEOUT`.

9. Wyjścia są ustawiane zależnie od `HoldUp` i `HoldCoilInEndPos`:

   - przy `HoldUp = TRUE` aktywowane jest `Q_Fwd`,
   - przy `HoldUp = FALSE` aktywowane jest `Q_Bwd`,
   - jeśli `HoldCoilInEndPos = FALSE`, cewka gaśnie po dojechaniu do celu.

## Zależności w programie

`FB_StopperPair` jest warstwą wykonawczą. Sam korzysta tylko ze standardowych timerów `TON`, ale jego statusy są ważne dla logiki procesu.

Ogólna ścieżka zależności:

```text
PRG_IO_Read
  -> GVL_IO.di
    -> PRG_Main mapuje czujniki do FB_StopperPair.Inp
      -> FB_TopFlowManager / FB_TraySequencer wyznaczają HoldUp
        -> FB_StopperPair wykonuje pozycję i liczy diagnostykę
          -> PRG_Main przepisuje Q_Fwd/Q_Bwd do GVL_IO.dout
            -> PRG_IO_Write
              -> fizyczne wyjścia PLC
```

Ważna cecha architektury: `FB_StopperPair` nie zna pojęć P1, P2, P3, stosu, tacki ani windy. Znaczenie `HoldUp` wynika z tego, która warstwa wyższa nim steruje.

## Konkretne instancje

### `fbStopM2` - stoper P1

`M2` zatrzymuje albo zwalnia pojemnik na pozycji P1. W trybie automatycznym komendę `HoldUp` wystawia `FB_TopFlowManager` przez `Outp.HoldPos1_Up`.

`FB_TopFlowManager` używa statusów:

- `StopP1_IsUp`,
- `StopP1_IsDown`.

Przed ruchem z P1 TopFlow wymaga, aby stoper źródłowy był opuszczony. Jeżeli pozycja jest zajęta i ma trzymać pojemnik, TopFlow wymaga pozycji `UP`.

### `fbStopM3` - stoper P2

`M3` działa analogicznie do M2, ale dla pozycji P2. Jest używany do buforowania pojemników na górnym transporterze.

TopFlow opuszcza M3, gdy P2 jest źródłem ruchu albo celem wjazdu. W pozostałych przypadkach, jeśli P2 jest logicznie zajęte, M3 powinien trzymać pojemnik.

### `fbStopM4` - stoper P3

`M4` jest krytyczny dla pozycji P3, czyli pozycji odbioru stosu przez robota w trybie tacek.

W trybie tacek `FB_TopFlowManager` uznaje stos za gotowy na P3 dopiero wtedy, gdy:

- `OccP3 = TRUE`,
- `M4` jest w pozycji `UP`,
- `M5` jest cofnięty.

Po zakończeniu pracy robota ze stosem `FB_TraySequencer` wysyła do TopFlow sygnał `TopFlow_StackConsumed`, a TopFlow zwalnia P3.

### `fbPosM5` - bramka/pozycjoner tacek na P3

`M5` jest używany przez `FB_TopFlowManager` jako bramka przy dojeździe stosu tacek na P3.

W stanie przygotowania ruchu TopFlow wysuwa M5, gdy:

- aktywny jest tryb tacek,
- celem ruchu jest P3.

TopFlow czeka wtedy na `M5_IsUp` przed startem transportera. W stanie jazdy do P3 TopFlow dalej podtrzymuje `M5_Extend`, aby bramka była aktywna podczas wjazdu stosu.

### `fbPosM6` - pozycjoner tacki na windzie

`M6` jest sterowany przez `FB_TraySequencer`, nie przez TopFlow.

Po każdym impulsie robota `Robot_PalletFinished`, czyli po odłożeniu tacki, TraySequencer wykonuje cykl:

1. wysuń M6,
2. poczekaj na `M6_IsUp`,
3. cofnij M6,
4. poczekaj na `M6_IsDown`,
5. zjedź windą do krawędzi pojemnika.

Timeout tego cyklu jest nadzorowany w `FB_TraySequencer`, a samo sterowanie cewkami i diagnostyka pary czujników pozostaje w `FB_StopperPair`.

## Zachowanie w trybie ręcznym

W trybie ręcznym `PRG_Main` ustawia `HoldUp` bezpośrednio z komend HMI:

- `xM2Fwd/xM2Bwd`,
- `xM3Fwd/xM3Bwd`,
- `xM4Fwd/xM4Bwd`,
- `xM5Fwd/xM5Bwd`,
- `xM6Fwd/xM6Bwd`.

Jeżeli oba kierunki jednego elementu są aktywne naraz, `PRG_Main` nie zmienia aktualnej komendy. HMI powinno blokować przeciwstawne przyciski.

## Na co uważać przy uruchomieniu

- Sprawdź znaczenie FWD/BWD dla każdego elementu. W tym projekcie FWD dla M2-M6 oznacza stan `UP`.
- Zweryfikuj każdą parę krańcówek osobno. Do `IsUp` potrzebne są oba FWD, a do `IsDown` oba BWD.
- Jeżeli jeden siłownik z pary dojedzie, a drugi nie, blok pozostanie w `Busy` i po czasie zgłosi `TIMEOUT`.
- Jeżeli czujnik FWD i BWD jednej osi są aktywne jednocześnie, blok zgłosi `SENSOR_CONTRADICTION`.
- Domyślny timeout `T#2s` może być zbyt krótki dla wolnej pneumatyki albo ograniczonego ciśnienia.
- Reset błędu nie resetuje jawnie `tMoveTO`. Jeśli po resecie mechanika nadal nie jest w żądanej pozycji, błąd timeout może szybko wrócić.
- W skanie, w którym `tMoveTO.Q` ustawi fault, logika wyjść jest jeszcze w tej samej gałęzi wykonania. Przy `HoldCoilInEndPos = TRUE` warto sprawdzić na sterowniku, czy nie pojawia się jednoskanowe podtrzymanie cewki po momencie wykrycia timeoutu.
- Dla M2-M4 ważne jest, aby transporter górny nie ruszał, dopóki stopery nie są w pozycjach wymaganych przez TopFlow. Ta zależność jest realizowana przez `FB_TopFlowManager`, który czeka na `IsUp/IsDown`.

## Miejsce w hierarchii

`FB_StopperPair` jest drugim podstawowym blokiem wykonawczym pneumatyki, obok `FB_Cyl2Pos`.

```text
TopFlowManager / TraySequencer
  -> PRG_Main
    -> FB_StopperPair
      -> GVL_IO.dout
        -> fizyczne cewki M2-M6
```

Blok odpowiada za wykonanie komendy i diagnostykę mechaniki. Decyzje procesowe, takie jak “który pojemnik ma jechać”, “czy P3 jest gotowe” albo “kiedy cykl M6 ma się rozpocząć”, są w wyższych warstwach.

