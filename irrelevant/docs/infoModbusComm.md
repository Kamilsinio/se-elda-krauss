# FB_ModbusComm - komunikacja Modbus TCP z robotem FANUC

## Rola funkcjonalna

`FB_ModbusComm` jest blokiem komunikacyjnym odpowiedzialnym za wymianę sygnałów PLC <-> robot FANUC M20iA.

Blok obsługuje:

- odczyt statusów robota, czyli Robot DO -> PLC,
- zapis komend PLC, czyli PLC -> Robot DI,
- mapowanie bitów z rejestrów Modbus na struktury `GVL_Robot`,
- prosty status komunikacji robota,
- licznik błędów odczytu/zapisu.

W aktualnej architekturze `FB_ModbusComm` dotyczy tylko robota. Falownik ATV320 windy jest sterowany osobno w `FB_Elevator` przez `GIATV.Control_ATV`.

## Ważna uwaga o obecnej implementacji

Kod `FB_ModbusComm` jest obecnie warstwą mapowania na surowe bufory:

```text
GVL_ModbusTCP.mbBuf.aRobotRxRegs
GVL_ModbusTCP.mbBuf.aRobotTxRegs
```

Oznacza to, że blok sam nie wykonuje realnego odpytywania sieci przez `READ_VAR` / `WRITE_VAR` w pokazanym kodzie. Zakłada, że fizyczna warstwa Modbus, I/O Scanner albo inna konfiguracja Machine Expert będzie aktualizować `mbBuf`.

To jest kluczowe przy uruchomieniu: jeśli `mbBuf.aRobotRxRegs` nie będzie odświeżany z robota, PLC może czytać stare dane, mimo że `FB_ModbusComm` ustawi `xRobotCommOk`.

## Gdzie jest używany

W `PRG_Main` istnieje jedna instancja:

- `fbModbusComm : FB_ModbusComm`.

Sekcja komunikacji w `PRG_Main`:

1. Składa `GVL_Robot.robotOut` z wyjść sekwencerów i przycisków.
2. Przepisuje konfigurację robota do `fbModbusComm.Cfg.cfgRobot`.
3. Włącza komunikację przez `fbModbusComm.Cmd.xEnable`.
4. Przekazuje dane do wysłania przez `fbModbusComm.Inp.stRobotOut`.
5. Wywołuje `fbModbusComm()`.
6. Przepisuje `fbModbusComm.Outp.stRobotIn` do `GVL_Robot.robotIn`.

`GVL_Robot.robotIn` jest potem używany przez `FB_TraySequencer`, `FB_BoxSequencer`, HMI i alarmy.

## Powiązane GVL

### `GVL_Robot`

Zawiera struktury logiczne:

- `ST_RobotFromPLC` - komendy PLC do robota,
- `ST_RobotToPLC` - statusy robota do PLC,
- `robotOut`,
- `robotIn`.

### `GVL_ModbusTCP`

Zawiera:

- konfigurację IP/port/unit id robota,
- liczbę rejestrów,
- surowe bufory `mbBuf`,
- legacy konfigurację ATV320.

Dla robota domyślnie:

- IP: `192.168.1.20`,
- port: `502`,
- Unit ID: `1`,
- odczyt: 2 rejestry = 32 bity Robot DO,
- zapis: 2 rejestry = 32 bity Robot DI,
- polling: `T#50ms`.

## Interfejs wejściowy

### `Cfg : ST_MbCommCfg`

Konfiguracja:

- `cfgVfd` - legacy, nieużywane do realnego sterowania ATV320,
- `cfgRobot` - konfiguracja Modbus TCP robota,
- `tWatchdogTime` - czas watchdog, domyślnie `T#3s`.

### `Cmd : ST_MbCommCmd`

Komendy:

- `xEnable` - włącza pracę komunikacji,
- `xResetFault` - reset faultu komunikacji.

### `Inp : ST_MbCommIn`

Dane do wysłania do robota:

- `stRobotOut : ST_RobotFromPLC`.

W `PRG_Main` ta struktura jest składana z trybu pracy, sekwencerów i przycisków operatora.

## Interfejs wyjściowy

### `Outp : ST_MbCommOut`

Zawiera:

- `stVfdRx` - legacy/diagnostyka ATV, realnie ATV obsługuje `FB_Elevator`,
- `stRobotIn` - zdekodowane statusy robota,
- `stStatus` - status komunikacji.

### `ST_MbCommStatus`

Status zawiera:

- `xVfdCommOk` - legacy,
- `xRobotCommOk` - komunikacja robota OK według bloku,
- `eState` - stan automatu komunikacji,
- `eFault` - fault komunikacji,
- liczniki błędów odczytu/zapisu.

## Automat stanów

`E_MbCommState` definiuje stany:

- `IDLE`,
- `VFD_READ`,
- `VFD_READ_WAIT`,
- `VFD_WRITE`,
- `VFD_WRITE_WAIT`,
- `ROB_READ`,
- `ROB_READ_WAIT`,
- `ROB_WRITE`,
- `ROB_WRITE_WAIT`,
- `FAULT`.

W aktualnym kodzie używana jest ścieżka robota:

```text
IDLE -> ROB_READ -> ROB_READ_WAIT -> ROB_WRITE -> ROB_WRITE_WAIT -> IDLE
```

Stany VFD są legacy i nie są używane do sterowania windy.

## Jak działa kod krok po kroku

1. Jeśli `xResetFault = TRUE` i blok jest w `FAULT`, stan wraca do `IDLE`, fault jest kasowany, a liczniki błędów robota są zerowane.

2. Jeśli `xEnable = FALSE`, blok przechodzi do `IDLE` i ustawia `xRobotCommOk := FALSE`.

3. Watchdog robota jest uruchamiany, gdy komunikacja jest włączona i ostatnia komunikacja nie była OK.

4. W `IDLE` blok czeka na timer `tonPollDelay` zgodny z `Cfg.cfgRobot.tPollInterval`.

5. Po czasie pollingu przechodzi do `ROB_READ`.

6. W `ROB_READ` ustawia flagi odczytu i przechodzi do `ROB_READ_WAIT`.

7. W `ROB_READ_WAIT` kopiuje:

   ```iecst
   GVL_ModbusTCP.mbBuf.aRobotRxRegs[0]
   GVL_ModbusTCP.mbBuf.aRobotRxRegs[1]
   ```

   do lokalnego bufora `aRobRxBuf`.

8. Następnie dekoduje bity Robot DO na strukturę `Outp.stRobotIn`.

9. Po udanym odczycie ustawia:

   - `xRobLastCommOk := TRUE`,
   - `xRobotCommOk := TRUE`,
   - stan `ROB_WRITE`.

10. W `ROB_WRITE` blok buduje rejestr wyjściowy `aRobTxBuf[0]` z bitów `Inp.stRobotOut`.

11. W `ROB_WRITE_WAIT` kopiuje:

   ```iecst
   aRobTxBuf[0] -> GVL_ModbusTCP.mbBuf.aRobotTxRegs[0]
   aRobTxBuf[1] -> GVL_ModbusTCP.mbBuf.aRobotTxRegs[1]
   ```

12. Po zapisie wraca do `IDLE`.

13. Na końcu każdego skanu aktualizuje `Outp.stStatus.eState` i `Outp.stStatus.eFault`.

## Mapowanie PLC -> Robot DI

PLC buduje Robot DI w `aRobotTxRegs[0]`.

| Robot DI | Bit | Zmienna PLC | Znaczenie |
|---|---:|---|---|
| DI[1] | `16#0001` | `cmd_box_production` | tryb produkcji kuwet |
| DI[2] | `16#0002` | `cmd_tray_production` | tryb produkcji tacek |
| DI[3] | `16#0004` | `cmd_continue_job` | kontynuuj pracę |
| DI[4] | `16#0008` | `cmd_stack_ready` | stos/kuweta gotowa |
| DI[5] | `16#0010` | `cmd_elevator_ready` | winda gotowa |
| DI[6] | `16#0020` | `cmd_samples` | podaj próbki |
| DI[7] | `16#0040` | `spare_di_7` | rezerwa |
| DI[8] | `16#0080` | `spare_di_8` | rezerwa |

`aRobotTxRegs[1]` jest obecnie zerowane i pozostaje rezerwą.

## Mapowanie Robot DO -> PLC

Robot DO są dekodowane z `aRobotRxRegs[0]` i `aRobotRxRegs[1]`.

| Robot DO | Bit | Zmienna PLC | Znaczenie |
|---|---:|---|---|
| DO[1] | `16#0001` | `sts_auto_mode` | robot AUTO |
| DO[2] | `16#0002` | `sts_t1_mode` | tryb T1 |
| DO[3] | `16#0004` | `sts_t2_mode` | tryb T2 |
| DO[4] | `16#0008` | `sts_estop` | E-STOP robota |
| DO[5] | `16#0010` | `sts_input_simulated` | wejścia symulowane |
| DO[6] | `16#0020` | `sts_output_simulated` | wyjścia symulowane |
| DO[7] | `16#0040` | `sts_in_home_pos` | robot w HOME |
| DO[8] | `16#0080` | `sts_system_ready` | system ready |
| DO[9] | `16#0100` | `sts_prg_running` | program running |
| DO[10] | `16#0200` | `sts_fault` | fault robota |
| DO[11] | `16#0400` | `sts_tp_enabled` | TP enabled |
| DO[12] | `16#0800` | `sts_current_prg_box` | aktualny program kuwet |
| DO[13] | `16#1000` | `sts_current_prg_tray` | aktualny program tacek |
| DO[14] | `16#2000` | `sts_cmd_ack` | potwierdzenie komendy |
| DO[15] | `16#4000` | `sts_pallet_finished` | tacka/paleta odłożona |
| DO[16] | `16#8000` | `sts_samples_placed` | próbki odłożone |
| DO[17] | `16#0001` w reg 1 | `sts_pallet_full` | paleta pełna |
| DO[18] | `16#0002` w reg 1 | `sts_stack_finished` | stos/kuweta zakończona |

## Relacja z sekwencerami

### TraySequencer

`FB_TraySequencer` używa:

- `sts_system_ready`,
- `sts_prg_running`,
- `sts_auto_mode`,
- `sts_fault`,
- `sts_pallet_finished`,
- `sts_stack_finished`.

Wysyła do robota przez `PRG_Main`:

- `cmd_tray_production`,
- `cmd_stack_ready`,
- `cmd_elevator_ready`.

`sts_pallet_finished` jest impulsem zliczającym tacki. `sts_stack_finished` kończy stos.

### BoxSequencer

`FB_BoxSequencer` używa:

- `sts_system_ready`,
- `sts_prg_running`,
- `sts_auto_mode`,
- `sts_fault`,
- `sts_stack_finished`.

Wysyła:

- `cmd_box_production`,
- `cmd_stack_ready`,
- `cmd_elevator_ready`.

W trybie kuwet `sts_stack_finished` oznacza zakończenie jednej kuwety.

## Relacja z PRG_Main

`PRG_Main` składa komendy robota tak:

- `cmd_tray_production` - aktywny tryb tacek i TraySeq running,
- `cmd_box_production` - aktywny tryb kuwet i BoxSeq running,
- `cmd_continue_job` - impuls TP `Kontynuuj`,
- `cmd_samples` - przycisk `Podaj próbki`,
- `cmd_stack_ready` - sygnał gotowości z aktywnego sekwencera,
- `cmd_elevator_ready` - gotowość windy z aktywnego sekwencera.

Po wywołaniu `fbModbusComm()` status robota jest przepisywany do `GVL_Robot.robotIn`. Dopiero z tej globalnej struktury korzystają sekwencery i HMI.

## Relacja z HMI i alarmami

HMI dostaje między innymi:

- `xRobotAutoMode`,
- `xRobotReady`,
- `xRobotRunning`,
- `xRobotFault`,
- `xRobotHome`,
- `xRobotCommOk`.

Alarmy komunikacji robota:

- `xRobot_CommLost`,
- `xRobot_MbLost`.

Oba są obecnie oparte na tym samym statusie `NOT fbModbusComm.Outp.stStatus.xRobotCommOk`.

## Ograniczenia aktualnej implementacji

- Blok nie wykonuje realnego `READ_VAR` / `WRITE_VAR` w pokazanym kodzie.
- `xRobotCommOk` jest ustawiane na `TRUE` po skopiowaniu lokalnego bufora, nawet jeśli bufor nie został realnie odświeżony z sieci.
- Watchdog nie potwierdza świeżości danych z robota przez heartbeat ani licznik zmian.
- Zmienne błędów `xRobReadError` i `xRobWriteError` są ustawiane lokalnie na `FALSE`, więc ścieżki błędów odczytu/zapisu nie będą aktywne bez dopięcia realnej warstwy komunikacyjnej.
- Stany VFD w enumie są legacy. ATV320 jest obsługiwany przez `FB_Elevator`.
- `cmd_continue_job` jest impulsem 1 s z `PRG_Main`; trzeba sprawdzić, czy robot na pewno go próbuje odczytać w tym oknie.
- `cmd_samples` jest poziomem przycisku, bez latcha do `sts_samples_placed`.
- `sts_cmd_ack` jest dekodowane, ale aktualne sekwencery nie używają go do przejść.

## Na co uważać przy uruchomieniu

- Potwierdź w Machine Expert, jaka warstwa realnie aktualizuje `GVL_ModbusTCP.mbBuf.aRobotRxRegs` i wysyła `aRobotTxRegs` do robota.
- Sprawdź adresację bitów FANUC: czy DI[1] odpowiada bitowi `16#0001`, czy nie ma przesunięcia offsetu.
- Sprawdź kolejność słów i bitów dla DO[17]/DO[18], bo są w drugim rejestrze.
- Potwierdź semantykę DO[15], DO[17] i DO[18]. W liście sygnałów DO[15] to `pallet placed`, DO[17] to `pallet finished`, DO[18] to `stack finished`; PLC używa DO[15] jako `sts_pallet_finished` dla liczenia tacek.
- Sprawdź, czy robot widzi `cmd_continue_job` przez pełny wymagany czas. PLC trzyma go przez około 1 s.
- Sprawdź, czy `cmd_stack_ready` i `cmd_elevator_ready` są zgodne z oczekiwaniami programu robota w obu trybach.
- Sprawdź, czy robot kasuje swoje impulsy `pallet_finished` i `stack_finished` tak, aby PLC widziało zbocze narastające.
- Przy testach komunikacji nie ufaj tylko `xRobotCommOk`; obserwuj też rzeczywistą zmianę bitów w `mbBuf`.
- Rozważ dodanie heartbeat/licznika transakcji albo realnej obsługi błędów `READ_VAR/WRITE_VAR`, jeśli komunikacja ma być diagnozowana przez PLC.

## Miejsce w hierarchii

`FB_ModbusComm` jest warstwą komunikacyjną, nie sekwencerem procesu.

```text
TraySequencer / BoxSequencer / przyciski
  -> PRG_Main składa GVL_Robot.robotOut
    -> FB_ModbusComm mapuje robotOut do aRobotTxRegs
      -> warstwa Modbus / I/O Scanner / robot FANUC
      -> aRobotRxRegs
    -> FB_ModbusComm mapuje rejestry na GVL_Robot.robotIn
  -> sekwencery czytają status robota
```

Blok jest pomostem między logiką PLC a mapą bitów robota.

