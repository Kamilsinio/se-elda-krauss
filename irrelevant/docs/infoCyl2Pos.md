# FB_Cyl2Pos - pojedynczy siłownik dwupołożeniowy

## Rola funkcjonalna

`FB_Cyl2Pos` jest najniższą warstwą wykonawczą dla pojedynczego siłownika pneumatycznego z dwoma stanami:

- `EXT` - siłownik wysunięty,
- `RET` - siłownik cofnięty.

Blok zamienia jedną komendę logiczną `CmdExtend` na dwie cewki wyjściowe:

- `Outp.Q_Ext` - sterowanie wysuwaniem,
- `Outp.Q_Ret` - sterowanie cofaniem.

Jednocześnie filtruje krańcówki, wykrywa sprzeczne czujniki i generuje błąd timeoutu, jeżeli siłownik nie dojedzie do żądanej pozycji w zadanym czasie.

## Gdzie jest używany

W `PRG_Main` blok jest użyty dla pojedynczych pozycjonerów:

- `fbPosM1 : FB_Cyl2Pos` - pozycjoner załadunku na pozycji P1,
- `fbPosM7 : FB_Cyl2Pos` - pozycjoner kuwet na windzie,
- `fbPosM8 : FB_Cyl2Pos` - magazyn/przesłona przekładek.

Pozostałe siłowniki, które mają parę napędów lub wymagają logiki stoperów, używają `FB_StopperPair`.

## Interfejs wejściowy

### `Cfg : ST_Cyl2PosCfg`

Konfiguracja czasów:

- `tStable` - czas stabilizacji krańcówki, domyślnie `T#50ms`,
- `tTimeout` - maksymalny czas dojazdu do pozycji, domyślnie `T#2s`.

### `Enable : BOOL`

Globalne zezwolenie pracy bloku. Gdy `Enable = FALSE`, blok wyłącza obie cewki i ustawia `Busy = FALSE`.

### `CmdExtend : BOOL`

Komenda pozycji:

- `TRUE` - jedź na wysunięcie,
- `FALSE` - jedź na cofnięcie.

To nie jest impuls. Blok traktuje tę zmienną jako aktualnie żądaną pozycję.

### `ResetFault : BOOL`

Kasuje stan błędu i diagnostykę:

- `Diag.Fault := FALSE`,
- `Diag.Code := NONE`,
- `Diag.Text := ''`.

### `Inp : ST_Cyl2PosIn`

Wejścia z czujników:

- `Inp.IsExt` - krańcówka wysunięcia,
- `Inp.IsRet` - krańcówka cofnięcia.

## Interfejs wyjściowy

### `Outp : ST_Cyl2PosOut`

Wyjścia sterujące cewkami:

- `Q_Ext` - załącz cewkę wysuwania,
- `Q_Ret` - załącz cewkę cofania.

Blok zawsze steruje maksymalnie jedną cewką naraz.

### `Sts : ST_Cyl2PosStatus`

Status ruchu:

- `AtExt` - potwierdzone, stabilne wysunięcie,
- `AtRet` - potwierdzone, stabilne cofnięcie,
- `Busy` - siłownik nie jest jeszcze w żądanej pozycji.

### `Diag : ST_Cyl2PosDiag`

Diagnostyka błędów:

- `Fault` - aktywny błąd,
- `Code` - kod z `E_Cyl2PosFault`,
- `Text` - opis błędu.

Możliwe błędy:

- `SENSOR_CONTRADICTION` - jednocześnie aktywne `IsExt` i `IsRet`,
- `TIMEOUT` - siłownik nie osiągnął żądanej pozycji w czasie `Cfg.tTimeout`.

## Jak działa kod krok po kroku

1. Jeżeli `ResetFault = TRUE`, blok kasuje flagę błędu, kod i tekst diagnostyczny.

2. Blok wykrywa sprzeczność czujników:

   ```iecst
   contradiction := Inp.IsExt AND Inp.IsRet;
   ```

   Siłownik nie powinien być jednocześnie w pozycji wysuniętej i cofniętej. Taki stan oznacza błąd czujników, okablowania albo błędne mapowanie wejść.

3. Krańcówki są filtrowane timerami `TON`:

   ```iecst
   tExt(IN := Enable AND Inp.IsExt AND (NOT contradiction), PT := Cfg.tStable);
   tRet(IN := Enable AND Inp.IsRet AND (NOT contradiction), PT := Cfg.tStable);
   ```

   Dopiero po czasie `tStable` status `AtExt` albo `AtRet` staje się prawdziwy. To zabezpiecza przed drganiami styku i krótkimi zakłóceniami.

4. Jeżeli czujniki są sprzeczne i blok jest włączony, ustawiany jest błąd `SENSOR_CONTRADICTION`.

5. Jeśli blok nie ma zezwolenia albo jest w błędzie:

   - `Q_Ext := FALSE`,
   - `Q_Ret := FALSE`,
   - `Busy := FALSE`.

   W takim stanie blok nie wymusza żadnego ruchu siłownika.

6. Jeżeli blok jest aktywny i bez błędu, wybiera docelową krańcówkę na podstawie `CmdExtend`:

   - przy `CmdExtend = TRUE` celem jest `Sts.AtExt`,
   - przy `CmdExtend = FALSE` celem jest `Sts.AtRet`.

7. `Busy` jest ustawiane, gdy aktualna pozycja nie jest jeszcze pozycją żądaną:

   ```iecst
   Sts.Busy := NOT targetReached;
   ```

8. Timer `tTO` mierzy czas trwania ruchu. Jeśli `Busy` trwa dłużej niż `Cfg.tTimeout`, blok zgłasza `TIMEOUT`.

9. Na końcu blok wystawia wyjścia:

   ```iecst
   Outp.Q_Ext := CmdExtend AND (NOT Diag.Fault);
   Outp.Q_Ret := (NOT CmdExtend) AND (NOT Diag.Fault);
   ```

   Czyli przy braku błędu blok stale podtrzymuje cewkę odpowiadającą żądanej pozycji.

## Zależności w programie

`FB_Cyl2Pos` nie zależy od innych bloków funkcyjnych projektu. Korzysta tylko ze standardowego timera `TON`.

W większej strukturze programu zależności wyglądają tak:

```text
PRG_IO_Read
  -> GVL_IO.di
    -> PRG_Main mapuje czujniki do FB_Cyl2Pos.Inp
      -> FB_Cyl2Pos liczy status, diagnostykę i wyjścia cewek
        -> PRG_Main przepisuje Outp.Q_Ext/Q_Ret do GVL_IO.dout
          -> PRG_IO_Write
            -> fizyczne wyjścia PLC
```

Sekwencery i wyższe warstwy nie sterują bezpośrednio fizycznymi wyjściami siłowników. Zamiast tego ustawiają komendy w `PRG_Main`, a `FB_Cyl2Pos` odpowiada za bezpieczne wystawienie cewek i diagnostykę ruchu.

## Konkretne instancje

### `fbPosM1` - pozycjoner załadunku P1

`M1` pozycjonuje pojemnik/stos po naciśnięciu przycisku potwierdzenia załadunku.

Logika w `PRG_Main` ustawia `fbPosM1.CmdExtend`, gdy:

- program nie jest w trybie ręcznym,
- operator potwierdził gotowość pojemnika,
- czujnik P1 widzi pojemnik,
- nie trwa opróżnianie stacji.

Gdy `fbPosM1.Sts.AtExt = TRUE`, program generuje `xTopFlowAcceptPulse`, czyli informację dla `FB_TopFlowManager`, że pojemnik z P1 może zostać przyjęty do logiki bufora.

Dodatkowa zależność: górny transporter nie wystartuje z P1, dopóki `fbPosM1.Sts.AtRet` nie potwierdzi cofnięcia pozycjonera.

### `fbPosM7` - pozycjoner kuwet na windzie

`M7` jest używany przez `FB_BoxSequencer`. Sekwencer kuwet decyduje, kiedy pojemnik na windzie ma zostać spozycjonowany. W `PRG_Main` komenda jest maskowana warunkami:

- aktywny tryb kuwet,
- aktywny `BoxSeq`,
- wyjście `fbBoxSeq.Outp.M7_Extend`.

Poza aktywnym trybem kuwet `M7` wraca do stanu bezpiecznego, czyli `CmdExtend = FALSE`.

### `fbPosM8` - magazyn/przesłona przekładek

`M8` jest przygotowany jako ręcznie sterowany pozycjoner z HMI. W obecnej logice automatycznej nie widać sekwencji, która używa `M8` jako elementu procesu.

## Zachowanie w trybie ręcznym

W trybie ręcznym `PRG_Main` ustawia `CmdExtend` na podstawie przycisków HMI:

- `xM1Fwd` / `xM1Bwd`,
- `xM7Fwd` / `xM7Bwd`,
- `xM8Fwd` / `xM8Bwd`.

Jeżeli oba kierunki dla jednego siłownika są aktywne naraz, `PRG_Main` nie zmienia komendy. Zakłada się, że HMI blokuje przeciwstawne przyciski, ale warto to sprawdzić przy uruchomieniu.

## Na co uważać przy uruchomieniu

- Sprawdź zgodność krańcówek `EXT` i `RET`. Jeżeli są zamienione, blok będzie sterował odwrotnie albo zgłosi timeout.
- Sprawdź, czy jednoczesne `IsExt = TRUE` i `IsRet = TRUE` nie występuje przy przejściach. Po filtrze `tStable` nie powinno być takiego stanu.
- Zweryfikuj, czy `Cfg.tTimeout = T#2s` jest wystarczający dla realnych siłowników. Jeżeli ruch pneumatyki jest wolniejszy, pojawią się fałszywe timeouty.
- Po resecie błędu timer timeoutu nie jest jawnie resetowany w gałęzi `ResetFault`. W praktyce, jeśli warunek `Busy` nadal trwa, blok może szybko ponownie zgłosić timeout. To jest poprawne diagnostycznie, ale ważne przy testach.
- Dla `M1` szczególnie sprawdź, czy pozycjoner cofa się przed startem górnego transportera. `PRG_Main` blokuje ruch z P1 do czasu `fbPosM1.Sts.AtRet`.

## Miejsce w hierarchii

`FB_Cyl2Pos` jest elementem wykonawczym najniższego poziomu:

```text
Sekwencery / logika procesu
  -> PRG_Main
    -> FB_Cyl2Pos
      -> GVL_IO.dout
        -> fizyczny siłownik
```

Nie podejmuje decyzji procesowych. Jego zadaniem jest wykonać zadaną pozycję, potwierdzić położenie i zgłosić błąd, jeśli fizyczny element nie zachowuje się zgodnie z oczekiwaniem.

