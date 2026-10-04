# FB_Conveyor - transporter z blokadą kierunków

## Rola funkcjonalna

`FB_Conveyor` jest blokiem wykonawczym dla transportera sterowanego komendami:

- `RunFwd` - jazda w kierunku do przodu,
- `RunBwd` - jazda w kierunku do tyłu.

Blok pilnuje, aby nie załączyć obu kierunków jednocześnie, obsługuje stan błędu oraz wymusza zwłokę przy zmianie kierunku. Nie analizuje czujników pojemników i nie decyduje, kiedy transporter ma ruszyć. Decyzje procesowe są w wyższych warstwach, a `FB_Conveyor` zamienia gotowe komendy na wyjścia cewek/styczników.

## Gdzie jest używany

W `PRG_Main` są trzy instancje:

- `fbConvTop` - górny transporter bufora P1-P3,
- `fbConvElev` - transporter windy P4,
- `fbConvBottom` - dolny transporter rozładunku P5-P7.

Każda instancja używa tego samego FB, ale ma inne znaczenie kierunków:

- `fbConvTop.Q_Fwd` - ruch pustych pojemników/stosów w kierunku robota,
- `fbConvElev.Q_Fwd` - transporter windy w kierunku przyjęcia pojemnika z góry,
- `fbConvElev.Q_Bwd` - transporter windy w kierunku rozładunku,
- `fbConvBottom.Q_Fwd` - dolny transporter w kierunku wyjścia,
- `fbConvBottom.Q_Bwd` - dolny transporter w kierunku windy.

Górny transporter jest w programie traktowany jako jednokierunkowy. `FB_Conveyor` potrafi obsłużyć `BWD`, ale `PRG_Main` nie mapuje `fbConvTop.Outp.Q_Bwd` na fizyczne wyjście.

## Interfejs wejściowy

### `Cfg : ST_ConveyorCfg`

Konfiguracja:

- `tReversalDelay` - czas zwłoki po zatrzymaniu przed zmianą kierunku, domyślnie `T#500ms`.

### `Cmd : ST_ConveyorCmd`

Komendy:

- `RunFwd` - żądanie jazdy FWD,
- `RunBwd` - żądanie jazdy BWD,
- `ResetFault` - kasowanie błędu.

`RunFwd` i `RunBwd` są sygnałami poziomowymi. Transporter jedzie tak długo, jak dana komenda jest aktywna.

### `Inp : ST_ConveyorIn`

Warunki ogólne:

- `Enable` - zezwolenie pracy,
- `SafetyOK` - warunek bezpieczeństwa.

Gdy którykolwiek z nich jest fałszywy, blok natychmiast wyłącza wyjścia i wraca do `IDLE`, o ile nie jest w błędzie.

## Interfejs wyjściowy

### `Outp : ST_ConveyorOut`

Wyjścia sterujące:

- `Q_Fwd` - załącz kierunek FWD,
- `Q_Bwd` - załącz kierunek BWD.

Blok programowo zabezpiecza przed jednoczesnym załączeniem obu kierunków.

### `Sts : ST_ConveyorStatus`

Status:

- `State` - aktualny stan automatu `E_ConveyorState`,
- `Running` - transporter logicznie pracuje,
- `Direction` - `0` stop, `1` FWD, `-1` BWD.

### `Diag : ST_ConveyorDiag`

Diagnostyka:

- `Fault` - aktywny błąd,
- `Code` - kod z `E_ConveyorFault`,
- `Text` - opis.

Zaimplementowany błąd:

- `SIMULTANEOUS_CMD` - jednoczesna komenda `RunFwd` i `RunBwd`.

W enumie istnieje też `REVERSAL_BLOCKED`, ale aktualny kod go nie ustawia. Zmiana kierunku jest obsługiwana stanami opóźnienia `DELAY_FWD` i `DELAY_BWD`, bez zgłaszania błędu.

## Automat stanów

`FB_Conveyor` używa stanów:

- `IDLE` - transporter zatrzymany,
- `RUN_FWD` - jazda do przodu,
- `RUN_BWD` - jazda do tyłu,
- `DELAY_FWD` - oczekiwanie przed startem FWD po wcześniejszym BWD,
- `DELAY_BWD` - oczekiwanie przed startem BWD po wcześniejszym FWD,
- `FAULT` - błąd, wyjścia wyłączone.

## Jak działa kod krok po kroku

1. Jeżeli `Cmd.ResetFault = TRUE`, blok kasuje diagnostykę. Jeśli był w stanie `FAULT`, wraca do `IDLE`.

2. Blok sprawdza jednoczesne komendy:

   ```iecst
   IF Cmd.RunFwd AND Cmd.RunBwd AND (NOT Diag.Fault) THEN
   ```

   Taki stan ustawia błąd `SIMULTANEOUS_CMD` i przełącza automat do `FAULT`.

3. Jeżeli brakuje `Enable`, `SafetyOK` albo aktywny jest błąd, blok natychmiast wyłącza oba wyjścia, zeruje `Running` i `Direction`, a następnie kończy wykonanie przez `RETURN`.

4. W stanie `IDLE` blok czeka na pojedynczą komendę kierunku:

   - `RunFwd = TRUE` i `RunBwd = FALSE`,
   - albo `RunBwd = TRUE` i `RunFwd = FALSE`.

5. Blok pamięta ostatni kierunek w `lastDir`. Jeśli poprzedni kierunek był przeciwny, nie uruchamia od razu drugiego kierunku, tylko przechodzi do stanu opóźnienia:

   - po BWD przed FWD: `DELAY_FWD`,
   - po FWD przed BWD: `DELAY_BWD`.

6. W stanach `DELAY_FWD` i `DELAY_BWD` oba wyjścia są wyłączone. Timer `tReversal` odmierza `Cfg.tReversalDelay`.

7. Jeśli komenda kierunku zostanie zdjęta w czasie opóźnienia, blok wraca do `IDLE`.

8. Po upływie zwłoki blok przechodzi do odpowiedniego stanu ruchu.

9. W `RUN_FWD` załączane jest tylko `Q_Fwd`, a w `RUN_BWD` tylko `Q_Bwd`. Po zdjęciu komendy blok wyłącza wyjście i wraca do `IDLE`.

## Zależności w programie

`FB_Conveyor` sam nie korzysta z innych FB. Korzysta tylko z timera `TON`.

W projekcie komendy do transporterów powstają z kilku warstw:

```text
TopFlowManager / TraySequencer / BoxSequencer / BottomAccumulator / Emptying
  -> PRG_Main składa komendy RunFwd/RunBwd
    -> FB_Conveyor pilnuje kierunku, safety, enable i reversal delay
      -> GVL_IO.dout
        -> PRG_IO_Write
          -> fizyczne wyjścia PLC
```

To oznacza, że `FB_Conveyor` jest ostatnim programowym filtrem przed fizycznym wyjściem transportera.

## Konkretne instancje

### `fbConvTop` - górny transporter P1-P3

Górny transporter jest głównie sterowany przez `FB_TopFlowManager`.

TopFlow wystawia `Outp.TopConveyor_Run`, a `PRG_Main` przepisuje to na `fbConvTop.Cmd.RunFwd`. Dodatkowo przy ruchu ze źródła P1 jest blokada na pozycjoner M1:

```text
TopConveyor_Run AND (źródło nie jest P1 OR M1 jest cofnięty)
```

Dzięki temu transporter nie powinien ruszyć z P1, dopóki pozycjoner załadunku M1 nie potwierdzi cofnięcia.

W trybie kuwet i podczas opróżniania górny transporter może współpracować z transporterem windy, aby przenieść pojemnik na P4. W trybie tacek górny transporter buforuje stosy do P3.

### `fbConvElev` - transporter windy P4

Transporter windy ma dwa kierunki:

- `FWD` / `IN` - przyjmowanie pojemnika z górnego transportera,
- `BWD` / `OUT` - oddanie pojemnika na dolny transporter.

Komendy do `fbConvElev` mogą pochodzić z:

- `FB_TraySequencer` - rozładunek po zakończeniu stosu tacek,
- `FB_BoxSequencer` - rozładunek po zakończeniu kuwety,
- `FB_TopFlowManager` - transfer kuwety lub opróżnianie z góry na windę,
- logika opróżniania stacji w `PRG_Main`,
- HMI w trybie ręcznym.

`PRG_Main` sumuje część komend operacją `OR`, np. dołożenie jazdy `FWD` podczas aktywnego transferu TopFlow na windę.

### `fbConvBottom` - dolny transporter P5-P7

Dolny transporter ma dwa kierunki:

- `FWD` - do wyjścia rozładunku,
- `BWD` - w kierunku windy.

W normalnej sekwencji rozładunku używany jest głównie `FWD`. Komenda może pochodzić z:

- `FB_TraySequencer`,
- `FB_BoxSequencer`,
- `FB_BottomAccumulator_567`,
- logiki opróżniania stacji,
- HMI w trybie ręcznym.

`FB_BottomAccumulator_567` wystawia `Outp.ConvRun`, a `PRG_Main` dodaje tę komendę do `fbConvBottom.Cmd.RunFwd`.

## Tryb ręczny

W trybie ręcznym `PRG_Main` przypisuje komendy bezpośrednio z HMI:

- `xConvTopFwd` -> `fbConvTop.Cmd.RunFwd`,
- `xConvElevFwd` -> `fbConvElev.Cmd.RunFwd`,
- `xConvElevBwd` -> `fbConvElev.Cmd.RunBwd`,
- `xConvBottomFwd` -> `fbConvBottom.Cmd.RunFwd`,
- `xConvBottomBwd` -> `fbConvBottom.Cmd.RunBwd`.

Nadal działa blokada `FB_Conveyor`: jeśli HMI poda jednocześnie FWD i BWD dla transportera dwukierunkowego, FB zgłosi błąd `SIMULTANEOUS_CMD`.

## Tryb automatyczny

Poza trybem ręcznym `PRG_Main` najpierw zeruje wszystkie komendy transporterów. Następnie wyższe warstwy wpisują swoje żądania:

- TraySeq steruje transporterem windy i dolnym przy rozładunku tacek,
- BoxSeq steruje transporterami przy cyklu kuwet,
- TopFlow steruje górnym transporterem i dodaje ruch transportera windy przy transferze na P4,
- BottomAccumulator dodaje ruch dolnego transportera przy akumulacji/rozładunku P5-P7,
- Emptying nadpisuje lub ustawia komendy potrzebne do opróżniania stacji.

Na końcu skanu `PRG_Main` wywołuje `fbConvTop()`, `fbConvElev()` i `fbConvBottom()`, a ich wyjścia przepisuje do `GVL_IO.dout`.

## Na co uważać przy uruchomieniu

- Sprawdź rzeczywiste kierunki FWD/BWD dla windy i dolnego transportera. Nazwy w programie zakładają konkretne kierunki procesu.
- Górny transporter ma używane tylko `Q_Fwd`. Jeżeli sprzętowo istnieje kierunek wsteczny, nie jest obecnie mapowany do wyjścia PLC.
- Jeżeli na HMI albo w automacie pojawi się jednocześnie `RunFwd` i `RunBwd`, blok wejdzie w `FAULT`.
- `FB_Conveyor` nie ma feedbacku ruchu z napędu ani czujnika pracy. `Sts.Running` oznacza, że PLC wystawia komendę, nie że transporter faktycznie się obraca.
- `tReversalDelay` chroni przed natychmiastową zmianą kierunku. Przy testach ręcznych operator może widzieć krótką pauzę po zmianie kierunku.
- `lastDir` pamięta ostatni kierunek także po zatrzymaniu. To jest potrzebne do zwłoki przy rewersie.
- Przy utracie `SafetyOK` lub `Enable` blok wraca do `IDLE`, ale `lastDir` zostaje zapamiętany. Po powrocie zezwolenia rewers nadal może wejść przez `DELAY_FWD/DELAY_BWD`.
- Dla `fbConvElev` i `fbConvBottom` warto sprawdzić, czy komendy z emptying nie kolidują z aktywnymi sekwencjami. `PRG_Main` abortuje sekwencery przez `AbortAuto` przy emptying, ale uruchomieniowo trzeba to potwierdzić.

## Miejsce w hierarchii

`FB_Conveyor` jest blokiem wykonawczym tej samej warstwy co `FB_Cyl2Pos` i `FB_StopperPair`, ale dla napędów transporterów.

```text
Logika procesu
  -> PRG_Main składa komendy ruchu
    -> FB_Conveyor
      -> fizyczne wyjścia transportera
```

Blok odpowiada za bezpieczne wystawienie kierunku i podstawową diagnostykę komend. Nie odpowiada za planowanie transportu pojemników między pozycjami.
