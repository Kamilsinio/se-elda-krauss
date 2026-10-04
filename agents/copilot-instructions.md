# Copilot Instructions — Palletizing Station PLC Project

## Project Overview
Automated palletizing station with **Schneider Electric M241 PLC** (Machine Expert / IEC 61131-3 Structured Text), **FANUC M20iA robot** (KAREL/LS programs) mapped through IOScanner, and **ATV320 VFD** elevator controlled through Schneider Electric GIATV.Control_ATV. Two production modes: trays (tray stacks) and boxes (kuwety).

## Physical Layout & Positions
- **Positions 1–3**: Top conveyor (load/buffer). P1=loading, P2=buffer, P3=pre-elevator.
- **Position 4**: Elevator conveyor (robot palletizes here).
- **Positions 5–7**: Bottom conveyor (unloading/discharge).
- Transfers between zones require running **two conveyors simultaneously** (e.g., top+elevator for P3→P4, elevator+bottom for P4→P5).

## Actuator Naming Convention
- **M1**: Load positioner (pos 1). **M2**: Stopper pos 1. **M3**: Stopper pos 2. **M4**: Stopper pos 3.
- **M5**: Tray positioner (pos 3). **M6**: Tray positioner (elevator). **M7**: Box positioner (elevator). **M8**: Spacer storage.
- Each stopper/actuator has dual sensors: `ind_Mx_1_fwd/bwd`, `ind_Mx_2_fwd/bwd`.
- `fwd` = raised/extended (blocks container on conveyor). Conveyor must be **stopped** before raising/lowering stoppers.

## Code Architecture

### PLC (Structured Text — `.st` files)
- **GVLs/GVL_IO_RAW.st**: Hardware I/O with `AT %IX/%QX` direct addresses. Do NOT add logic here.
- **GVLs/GVL_IO.st**: Abstracted I/O structs (`ST_IO_DI`, `ST_IO_DO`) without direct addresses — used by all FBs.
- **GVLs/GVL_Robot.st**: IOScanner PLC↔Robot structs (`ST_RobotFromPLC` = PLC→Robot DI, `ST_RobotToPLC` = Robot DO→PLC) and raw `AT %IX/%QX` mappings. Globals: `robotOut`, `robotIn`, `xRobotCommOk`.
- **POUs/FB_Cyl2Pos.st**: Reusable 2-position cylinder FB with timeout/fault diagnostics. Pattern: define `ST_*Cfg`, `ST_*In`, `ST_*Out`, `ST_*Status`, `ST_*Diag` structs, then the FB.
- **POUs/FB_StopperPair.st**: Dual-cylinder stopper (paired M*.1 + M*.2). Same struct pattern as FB_Cyl2Pos.
- **POUs/FB_Conveyor.st**: Bidirectional conveyor with **software interlock** (prevents simultaneous FWD+BWD) and configurable `tReversalDelay` for direction change. States: IDLE, RUN_FWD, RUN_BWD, DELAY_FWD, DELAY_BWD, FAULT.
- **POUs/FB_Elevator.st**: VFD-driven elevator as a `FUNCTION_BLOCK`. Uses `GIATV.Control_ATV` and ATV diagnostics. Targets: `posTop`, `posBottom`, `posContainerEdge` (drives down until `ind_container_in_pos_4` clears).
- **POUs/FB_TopFlowManager.st**: State machine managing P1–P3 buffer flow with priority: **feed robot/elevator first**, then buffer. Uses `E_TopPos`, `E_TopTarget` enums.
- **POUs/FB_BottomAccumulator_567.st**: State machine for discharge positions 5–7.
- **POUs/FB_TraySequencer.st**: Main orchestrator for tray AUTO mode. Coordinates TopFlowManager, Elevator, BottomAccumulator, positioners M5/M6/M4, and robot handshake. Configurable `uiTraysInStack`.
- **POUs/FB_BoxSequencer.st**: Orchestrator for box (kuweta) AUTO mode. Similar flow but: kuweta goes directly to elevator, positioned by M7 (not M5/M6), single container per cycle.
- **POUs/PRG_Main.st**: Main PROGRAM POU (MAST task). Instantiates all FBs, maps GVL_IO ↔ FB structs, selects tray/box mode, implements "empty station" state machine, "continue" button logic, HMI manual override, robot IOScanner commands, alarm manager, and HMI status mapping.
- **POUs/FB_AlarmManager.st**: Collects fault flags from all FBs into unified `ST_HmiAlarm` array for HMI display. 16 alarm sources mapped to `E_AlarmId` with Polish text descriptions.
- **GVLs/GVL_HMI.st**: HMI data exchange — `ST_HmiStationStatus` (all visual feedback), `ST_HmiCommands` (operator inputs), `ST_HmiAlarm` array, `E_AlarmId` enum.

### Robot (FANUC LS — `.LS` files)
- **AA_MAIN_TRAY_PRG.LS**: Main tray production program. Uses `DI/DO` for PLC handshake, `R[]` registers for counters, `PR[]` for offsets. Palletization grid defined by `R[15:x-quantity]`, `R[16:y-quantity]`, `R[17:z-quantity]`.

## Key Patterns & Conventions
1. **All FBs follow the same struct pattern**: Define enums (`E_*Fault`, `E_*State`), then config/cmd/in/out/status/diag structs, then the FB — all in one `.st` file.
2. **Use `{attribute 'qualified_only'}` and `{attribute 'strict'}`** on all enums.
3. **State machines** use explicit `UINT`/enum states with `CASE` — states are multiples of 10 (IDLE=10, PRECHECK=20, etc.), fault=900.
4. **Timeouts and sensor debounce** are configurable via `ST_*Cfg` structs (e.g., `tStable`, `tTimeout`).
5. **Signal names** use prefixes: `ind_` = input/indicator, `ctrl_` = control/output, `spare_` = unused.
6. **Comments in Polish** — preserve existing Polish comments and naming where present.
7. **Safety is external** — handled by dedicated safety controller, not in this PLC program.

## Critical Process Rules
- Elevator "base to container edge" = drive down until `ind_container_in_pos_4` goes OFF (keeps palletizing height constant).
- **Conveyor software interlock**: FB_Conveyor enforces mutual exclusion of FWD/BWD outputs + configurable `tReversalDelay` before direction change. Hardware contactors also prevent simultaneous forward+reverse.
- Container must arrive at position sensor BEFORE stopper can be raised.
- Priority: feeding robot > buffering containers (minimize injection mold cycle downtime).

## Signal Lists
- `GVLs/GVL_Robot.st` defines the PLC↔Robot IOScanner mapping and typed structs for robot signals.

## What's Still Needed
- HMI visualization screens (Vijeo Designer / Web Visualization) — bind to `GVL_HMI.hmiStatus`, `GVL_HMI.hmiCmd`, `GVL_HMI.hmiAlarms`.
- Fine-tuning timeouts and speeds after physical commissioning.

## Machine Expert Compilation Rules — Learned from Errors

### Strict enum type conversions
- **NEVER use `UINT(expr)` as a cast** — Machine Expert parses it as `UINT` (literal 0) assignment + `(expr)` as a separate no-effect expression. Use `TO_UINT(expr)` instead.
- **Assigning to strict enum fields**: `INT_TO_UINT()` returns `UINT`, which is rejected for `{attribute 'strict'}` enum targets. Always use the exact enum type on both sides, e.g. `eField := E_MyEnum.member;`.
- **Qualified enum assignments**: when `{attribute 'strict'}` + `{attribute 'qualified_only'}` are set, ALL assignments must use `EnumType.member` DOT syntax. Integer literals (e.g. `:= 10;`) are invalid.
- **Declaring enum output fields**: declare as the enum type (e.g. `Elev_AutoTarget : E_ElevatorTarget;`), not as `UINT`. If declared as `UINT`, the caller cannot assign an enum value to it under strict mode.
- **HASH `#` notation is FORBIDDEN** — `E_Enum#member` is NOT valid Machine Expert syntax and produces "Unknown type: 'E_Xxx#member'" errors. The ONLY correct notation is `E_Enum.member` (dot). Always write `E_ElevatorState.IDLE`, never `E_ElevatorState#IDLE`.
- **Broken TYPE definition = "Unknown type" in other files** — if `END_TYPE` is concatenated on the same line as the next `{attribute}` pragma (e.g. `END_TYPE{attribute 'qualified_only'}`), Machine Expert fails to register the TYPE globally. Other POUs then report "Unknown type" errors. Fix: always put `END_TYPE` on its own line.

### `{attribute}` pragma formatting
- **`{attribute 'qualified_only'}` and `{attribute 'strict'}` must ALWAYS be on their own separate lines**, immediately before the `TYPE` declaration they apply to.
- **`END_TYPE` must be on its own line** — never concatenate `END_TYPE{attribute ...}` on one line. This confuses the Machine Expert parser and causes cascading errors (reported as "Unexpected token 'END_FUNCTION'" far from the actual bug location).
- Correct pattern:
  ```
  END_TYPE
  {attribute 'qualified_only'}
  {attribute 'strict'}
  TYPE E_NextEnum :
  ```

### FUNCTION vs FUNCTION_BLOCK — stateful vs stateless
- **A `FUNCTION` in IEC 61131-3 is STATELESS** — it has no persistent memory between scan cycles. It CANNOT declare instances of function blocks (`TON`, `R_TRIG`, `TP`, etc.) in its `VAR` section.
- Any POU that needs timers, edge detectors, or any retained local state MUST be a `FUNCTION_BLOCK`.
- If you declare FB instances inside a `FUNCTION`, Machine Expert silently promotes the POU type to `(FB)` in the project tree, then generates errors **C0032** (`must be called as a function block, not a function`) and **C0080** (`object must be instantiated`) when the caller tries to invoke it as a plain function.
- Fix: change `FUNCTION Foo : UINT` → `FUNCTION_BLOCK Foo`, move the return value to `VAR_OUTPUT` (e.g. `uiState : UINT;`), assign it inside the body (`uiState := ...;`), change `END_FUNCTION` → `END_FUNCTION_BLOCK`, and in the caller add an instance variable (`fbFoo : Foo;`) and call `fbFoo(...)` instead of `result := Foo(...)`.

### General parsing pitfalls
- **"Unexpected token 'END_FUNCTION'"** is almost always a cascading error: look upstream for a malformed TYPE block, pragma on wrong line, or unclosed IF/CASE.
- Machine Expert error line numbers refer to the POU body, not the whole `.st` file. The actual bug is often dozens of lines before the reported line.
- When editing TYPE enums inside a `.st` file that also contains a FUNCTION/FUNCTION_BLOCK, always verify that `END_TYPE` ends on its own line with no trailing text.

Ignore the folder /irrelevant completely.

Do not read files from /irrelevant unless explicitly requested.

Treat /irrelevant as non-project archival material.
