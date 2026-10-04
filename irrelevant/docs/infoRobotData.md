# GVL_Robot / GVL_ModbusTCP - dane robota FANUC i Modbus TCP

## Rola funkcjonalna

Ten dokument opisuje dane wymieniane miedzy PLC a robotem FANUC M20iA.

W projekcie sa dwie warstwy danych:

- `GVL_Robot` - logiczne sygnaly procesu PLC <-> robot,
- `GVL_ModbusTCP` - konfiguracja komunikacji i surowe bufory rejestrow Modbus.

`FB_ModbusComm` jest opisany osobno w `infoModbusComm.md`. Ten plik skupia sie na tym, jakie bity sa wymieniane i jak je czytac jako kontrakt z robotem.

## Kierunki sygnalow

Komentarz w kodzie definiuje kierunki tak:

```text
Robot DI = PLC pisze komendy do robota
Robot DO = PLC czyta statusy z robota
```

W projekcie odpowiada to:

```text
PLC -> Robot:
  GVL_Robot.robotOut
    -> FB_ModbusComm
      -> GVL_ModbusTCP.mbBuf.aRobotTxRegs
        -> Robot DI

Robot -> PLC:
  Robot DO
    -> GVL_ModbusTCP.mbBuf.aRobotRxRegs
      -> FB_ModbusComm
        -> GVL_Robot.robotIn
```

## GVL_Robot

`GVL_Robot` zawiera dwie struktury:

- `ST_RobotFromPLC` - komendy PLC wysylane do robota,
- `ST_RobotToPLC` - statusy robota odczytywane przez PLC.

Globalne zmienne:

```iecst
robotOut : ST_RobotFromPLC; // PLC -> Robot
robotIn  : ST_RobotToPLC;   // Robot -> PLC
```

## PLC -> Robot: ST_RobotFromPLC

Te sygnaly sa mapowane na Robot DI.

| Pole PLC | Robot DI | Bit Modbus | Znaczenie |
|---|---:|---:|---|
| `cmd_box_production` | DI[1] | `16#0001` | tryb produkcji kuwet |
| `cmd_tray_production` | DI[2] | `16#0002` | tryb produkcji tacek |
| `cmd_continue_job` | DI[3] | `16#0004` | kontynuuj prace |
| `cmd_stack_ready` | DI[4] | `16#0008` | stos/pojemnik gotowy dla robota |
| `cmd_elevator_ready` | DI[5] | `16#0010` | winda gotowa do pracy robota |
| `cmd_samples` | DI[6] | `16#0020` | podaj probki |
| `spare_di_7` | DI[7] | `16#0040` | rezerwa |
| `spare_di_8` | DI[8] | `16#0080` | rezerwa |

Wszystkie te bity sa pakowane do:

```iecst
GVL_ModbusTCP.mbBuf.aRobotTxRegs[0]
```

Drugi rejestr:

```iecst
GVL_ModbusTCP.mbBuf.aRobotTxRegs[1]
```

jest aktualnie zerowany i traktowany jako rezerwa.

## Robot -> PLC: ST_RobotToPLC

Te sygnaly sa mapowane z Robot DO.

| Pole PLC | Robot DO | Bit Modbus | Znaczenie |
|---|---:|---:|---|
| `sts_auto_mode` | DO[1] | `16#0001` | robot w AUTO |
| `sts_t1_mode` | DO[2] | `16#0002` | robot w T1 |
| `sts_t2_mode` | DO[3] | `16#0004` | robot w T2 |
| `sts_estop` | DO[4] | `16#0008` | E-STOP robota aktywny |
| `sts_input_simulated` | DO[5] | `16#0010` | wejscia robota symulowane |
| `sts_output_simulated` | DO[6] | `16#0020` | wyjscia robota symulowane |
| `sts_in_home_pos` | DO[7] | `16#0040` | robot w HOME |
| `sts_system_ready` | DO[8] | `16#0080` | system gotowy |
| `sts_prg_running` | DO[9] | `16#0100` | program robota pracuje |
| `sts_fault` | DO[10] | `16#0200` | blad robota |
| `sts_tp_enabled` | DO[11] | `16#0400` | Teach Pendant enabled |
| `sts_current_prg_box` | DO[12] | `16#0800` | aktualny program kuwet |
| `sts_current_prg_tray` | DO[13] | `16#1000` | aktualny program tacek |
| `sts_cmd_ack` | DO[14] | `16#2000` | potwierdzenie komendy |
| `sts_pallet_finished` | DO[15] | `16#4000` | tacka/paleta ulozona, impuls |
| `sts_samples_placed` | DO[16] | `16#8000` | probki ulozone, impuls |
| `sts_pallet_full` | DO[17] | rejestr 1, bit `16#0001` | paleta pelna, impuls |
| `sts_stack_finished` | DO[18] | rejestr 1, bit `16#0002` | stos/kuweta zakonczona, impuls |

DO[1..16] sa czytane z:

```iecst
GVL_ModbusTCP.mbBuf.aRobotRxRegs[0]
```

DO[17..32] sa czytane z:

```iecst
GVL_ModbusTCP.mbBuf.aRobotRxRegs[1]
```

Aktualnie uzywane sa tylko DO[17] i DO[18] z drugiego rejestru.

## GVL_ModbusTCP

`GVL_ModbusTCP` zawiera konfiguracje Modbus TCP i surowe bufory.

### Konfiguracja robota

Typ:

```iecst
ST_ModbusTCP_Robot_Cfg
```

Domyslne ustawienia:

| Pole | Wartosc | Znaczenie |
|---|---:|---|
| `sIpAddress` | `192.168.1.20` | adres IP robota |
| `uiPort` | `502` | port Modbus TCP |
| `uiUnitId` | `1` | Unit ID |
| `uiRxStartReg` | `0` | poczatkowy adres odczytu Robot DO |
| `uiRxRegCount` | `2` | 2 rejestry = 32 bity DO |
| `uiTxStartReg` | `0` | poczatkowy adres zapisu Robot DI |
| `uiTxRegCount` | `2` | 2 rejestry = 32 bity DI |
| `tCommTimeout` | `T#2s` | timeout komunikacji |
| `tPollInterval` | `T#50ms` | interwal odpytywania |

Komentarz w kodzie dopuszcza dwa style implementacji zalezne od konfiguracji robota:

- Robot DI jako coils zapisywane przez PLC,
- Robot DO jako discrete inputs czytane przez PLC,
- albo reprezentacje przez holding registers.

Aktualna implementacja `FB_ModbusComm` pracuje na buforach rejestrowych `aRobotRxRegs` i `aRobotTxRegs`.

### Surowe bufory

Typ:

```iecst
ST_ModbusRawBuffers
```

Pola robota:

```iecst
aRobotRxRegs : ARRAY[0..1] OF UINT; // Robot DO -> PLC
aRobotTxRegs : ARRAY[0..1] OF UINT; // PLC -> Robot DI
```

Znaczenie:

- `aRobotRxRegs[0]` - DO[1..16],
- `aRobotRxRegs[1]` - DO[17..32],
- `aRobotTxRegs[0]` - DI[1..16],
- `aRobotTxRegs[1]` - DI[17..32].

W obecnym kodzie komendy PLC uzywaja tylko DI[1..8].

## Jak PRG_Main sklada robotOut

`PRG_Main` nie pozwala sekwencerom pisac do Modbus bezposrednio.

Najpierw sklada logiczne komendy:

```iecst
GVL_Robot.robotOut.cmd_tray_production :=
    xModeTray AND fbTraySeq.Outp.AutoRunning AND fbTraySeq.Outp.Robot_TrayProduction;

GVL_Robot.robotOut.cmd_box_production :=
    xModeBox AND fbBoxSeq.Outp.AutoRunning AND fbBoxSeq.Outp.Robot_BoxProduction;

GVL_Robot.robotOut.cmd_continue_job := tpRobotContinue.Q;
GVL_Robot.robotOut.cmd_samples := GVL_IO.di.ind_button_samples;
```

Sygnały gotowosci sa laczone z aktywnego sekwencera:

```iecst
cmd_stack_ready =
  TraySeq.StackReady OR BoxSeq.StackReady

cmd_elevator_ready =
  TraySeq.ElevatorReady OR BoxSeq.ElevatorReady
```

W praktyce tylko jeden sekwencer powinien byc aktywny, bo tryby tray/box sa wzajemnie wykluczane w `PRG_Main`.

## Jak sekwencery czytaja robotIn

`FB_TraySequencer` czyta m.in.:

- `sts_system_ready`,
- `sts_prg_running`,
- `sts_in_home_pos`,
- `sts_auto_mode`,
- `sts_fault`,
- `sts_pallet_finished`,
- `sts_stack_finished`,
- `sts_cmd_ack`.

`FB_BoxSequencer` czyta m.in.:

- `sts_system_ready`,
- `sts_prg_running`,
- `sts_auto_mode`,
- `sts_fault`,
- `sts_stack_finished`,
- `sts_cmd_ack`.

W trybie tacek `sts_pallet_finished` sluzy do reakcji po pojedynczym odlozeniu tacki. `sts_stack_finished` oznacza koniec calego stosu.

W trybie kuwet `sts_stack_finished` jest interpretowany jako zakonczenie paletyzacji kuwety.

## Handshake procesu

### Start trybu tacek

Typowy zestaw sygnalow:

```text
PLC -> Robot:
  cmd_tray_production = TRUE
  cmd_stack_ready = TRUE, gdy stos na P3 gotowy
  cmd_elevator_ready = TRUE, gdy winda gotowa na odkladanie

Robot -> PLC:
  sts_auto_mode = TRUE
  sts_system_ready = TRUE
  sts_cmd_ack = TRUE
  sts_pallet_finished = impuls po odlozeniu tacki
  sts_stack_finished = impuls po zakonczeniu stosu
```

### Start trybu kuwet

Typowy zestaw sygnalow:

```text
PLC -> Robot:
  cmd_box_production = TRUE
  cmd_stack_ready = TRUE, gdy kuweta/P4 gotowa do paletyzacji
  cmd_elevator_ready = TRUE, gdy winda jest gotowa

Robot -> PLC:
  sts_auto_mode = TRUE
  sts_system_ready = TRUE
  sts_cmd_ack = TRUE
  sts_stack_finished = impuls po zakonczeniu kuwety
```

### Kontynuuj

`cmd_continue_job` jest wysylane z impulsu `TP` w `PRG_Main`.

Obecnie impuls trwa:

```iecst
T#1s
```

Jest to wazne, bo cykl Modbus jest rzedu dziesiatek milisekund. Impuls 1 s powinien byc latwy do odczytania po stronie robota, o ile warstwa Modbus faktycznie odswieza bufory.

### Probki

`cmd_samples` jest przepisywane z fizycznego przycisku:

```iecst
GVL_IO.di.ind_button_samples
```

Robot powinien potwierdzac ulozenie probek przez:

```iecst
sts_samples_placed
```

W glownych sekwencerach ten status nie jest aktualnie glownym warunkiem procesu tray/box.

## Status komunikacji

Status komunikacji robota trafia przez:

```iecst
fbModbusComm.Outp.stStatus.xRobotCommOk
```

Do HMI trafia jako:

```iecst
GVL_HMI.hmiStatus.xRobotCommOk
```

Alarmy:

```iecst
GVL_HMI.hmiAlarms.xRobot_CommLost
GVL_HMI.hmiAlarms.xRobot_MbLost
```

Oba sa aktualnie liczone z tego samego warunku:

```iecst
NOT fbModbusComm.Outp.stStatus.xRobotCommOk
```

Przy uruchomieniu warto zdecydowac, czy operator ma widziec dwa osobne alarmy, czy jeden czytelny alarm komunikacji robota.

## Wazna uwaga o aktualnej implementacji

`FB_ModbusComm` w aktualnym kodzie nie wykonuje bezposrednio realnych wywolan sieciowych `READ_VAR` / `WRITE_VAR`.

Blok:

- czyta `GVL_ModbusTCP.mbBuf.aRobotRxRegs`,
- dekoduje bity do `GVL_Robot.robotIn`,
- koduje `GVL_Robot.robotOut`,
- zapisuje `GVL_ModbusTCP.mbBuf.aRobotTxRegs`.

Oznacza to, ze musi istniec zewnetrzna konfiguracja Machine Expert, I/O Scanner albo inna warstwa komunikacji, ktora faktycznie wymienia `mbBuf` z robotem.

Przy testach samo `xRobotCommOk = TRUE` nie gwarantuje jeszcze, ze robot realnie odpowiada po sieci, jesli bufor nie jest aktualizowany przez fizyczna warstwe komunikacji.

## Na co zwrocic uwage przy uruchomieniu

- Czy IP robota to faktycznie `192.168.1.20`.
- Czy Unit ID robota odpowiada konfiguracji FANUC.
- Czy FANUC mapuje DI[1] na bit 0 pierwszego slowa zapisu.
- Czy FANUC mapuje DO[1] na bit 0 pierwszego slowa odczytu.
- Czy kolejnosc bitow w FANUC nie jest odwrocona wzgledem PLC.
- Czy `aRobotRxRegs[0]` zmienia sie po recznym wymuszeniu DO w robocie.
- Czy `aRobotTxRegs[0]` zmienia sie po starcie trybu tray/box.
- Czy robot widzi `cmd_continue_job` przez okolo 1 s.
- Czy `sts_cmd_ack` jest poziomem czy impulsem; sekwencery oczekuja go jako potwierdzenia.
- Czy `sts_pallet_finished` i `sts_stack_finished` sa impulsami wystarczajaco dlugimi dla cyklu komunikacji PLC.
- Czy `sts_fault` oraz `sts_estop` maja prawidlowa polaryzacje.
- Czy `cmd_box_production` i `cmd_tray_production` nigdy nie sa TRUE jednoczesnie.

## Minimalny test komunikacji

1. Ustaw w robocie znany wzorzec DO, np. DO[1], DO[8], DO[14].
2. Sprawdz `GVL_ModbusTCP.mbBuf.aRobotRxRegs[0]`.
3. Sprawdz, czy `GVL_Robot.robotIn.sts_auto_mode`, `sts_system_ready`, `sts_cmd_ack` sa zgodne.
4. Wymus w PLC tryb tray albo box.
5. Sprawdz `GVL_Robot.robotOut`.
6. Sprawdz `GVL_ModbusTCP.mbBuf.aRobotTxRegs[0]`.
7. Potwierdz na teach pendancie lub w diagnostyce FANUC, ze robot widzi odpowiednie DI.

## Podsumowanie

`GVL_Robot` jest logicznym kontraktem procesu z robotem, a `GVL_ModbusTCP` jest niskopoziomowym nosnikiem bitow.

Najwazniejsze przy uruchomieniu jest potwierdzenie zgodnosci:

- numerow DI/DO w robocie,
- kolejnosci bitow w rejestrach,
- czasu trwania impulsow,
- fizycznego odswiezania `mbBuf` przez warstwe Modbus.
