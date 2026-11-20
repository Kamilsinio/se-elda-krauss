# HMI — diagnostyka według IO map.xlsx

Aktualizacja stacyjna 2026-11-15: wszystkie 159 nazw aliasów value/valid są zadeklarowane w PLC. [Aktualny interfejs](station-plc-implementation.md) rozróżnia powiązane wejścia, końcowe komendy i nadal nieważne pola. Obecność aliasu nie potwierdza adresu ani okablowania.

Stan: 2026-10-04. Źródło: [kopia arkusza](<sources/IO map.xlsx>), SHA-256 `9e1e47058088382590e4c1f36284c01fae4e294bebdfb6eb6f3faed95cb06e64`. Kopia 50 015 B zgodna bajtowo z oryginałem.

Poniższy wykaz obejmuje **166 wierszy sygnałów (159 unikalnych nazw logicznych) i 12 urządzeń Festo**. Podaje stan arkusza, nie dowodzi wykonania instalacji ani gotowego eksportu PLC. Obie zakładki oznaczone placeholder pozostają robocze także po skopiowaniu pliku.

Rozmieszczenie podglądu I/O na ekranach procesu i diagnostyki opisuje [instrukcja wykonawcza HMI v4](hmi-instructions.md).

## 1. Jak powiązać ten podgląd

Kolumna **Alias Vijeo** podaje krótką nazwę N dla dwóch tagów BOOL do odczytu.

- `GVL_HMI.vijeo.value.N` zasila lampkę wartości.
- `GVL_HMI.vijeo.valid.N` określa ważność tego samego sygnału.
- ID, opis, źródło i kierunek są stałymi etykietami. Identyfikator obiektu panelu `io_<arkusz>_r<wiersz>` odpowiada pozycji w tabeli.

Dla V201 HP wybierz `GVL_HMI.vijeo.value.ind_V201_HP` i `GVL_HMI.vijeo.valid.ind_V201_HP`.

**IN/OUT w tabeli przepisano z arkusza** i może zależeć od punktu widzenia jego autora, szczególnie przy przewodowym interfejsie robota. Dla HMI wszystkie te pola są R. Wyświetlenie OUT oznacza końcową komendę właściciela wyjścia, nie fizyczne potwierdzenie ruchu ani pomiar stanu cewki.

valid=FALSE → szara lampka + „brak danych”; nie FALSE procesu. Dla rezerwy bez przydzielonej funkcji pokaż „nieużywane”, a nie działającą kontrolkę. Dla obwodów safety pokazuj tylko dostępny, zatwierdzony sygnał diagnostyczny; brak możliwości pozyskania statusu oznacza brak danych. Nie odtwarzaj w HMI logiki obwodu bezpieczeństwa.

Wpisy w kolumnie „Adres źródłowy” są **wyłącznie zapisami źródłowymi**. `%I2.10` nie jest instrukcją utworzenia `%IX2.10`. TBD oznacza lukę. DI/DO FANUC i KF3xx/KF4xx dokumentują starą ścieżkę przewodową; docelowe wartości procesowe mają pochodzić z zatwierdzonej wymiany EtherNet/IP. Żaden wiersz nie tworzy alternatywnego toru sterowania.

Wspólny alias w dwóch wierszach (zawory równoległe) oznacza jeden alias wartości i ważności, przy dwóch etykietach mechaniki. Nie tworzyć dodatkowego kanału wyjściowego. Wiersze zaworu „to work position” nie zawierają kompletnego sterowania cewek HOME/WORK — przyciski korzystają z logicznych żądań w głównej mapie, nigdy z poniższych OUT.

## 2. Sygnały z arkusza

### ST01_Loading Belt

| Wiersz | ID / etykieta | Nazwa z arkusza N | IN/OUT | Źródło urządzenia | Adres źródłowy, niezatwierdzony | Alias Vijeo |
|---:|---|---|---|---|---|---|
| 3 | V101 — Loading elevator 1 left | `ctrl_move_loading_elevator_1_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V101_V102` |
| 4 | V101_HP — Loading elevator 1 left home position | `ind_loading_elevator_1_left_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V101_HP` |
| 5 | V101_WP — Loading elevator 1 left work position | `ind_loading_elevator_1_left_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V101_WP` |
| 6 | V102 — Loading elevator 1 right | `ctrl_move_loading_elevator_1_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V101_V102` |
| 7 | V102_HP — Loading elevator 1 right home position | `ind_loading_elevator_1_right_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V102_HP` |
| 8 | V102_WP — Loading elevator 1 right work position | `ind_loading_elevator_1_right_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V102_WP` |
| 9 | V103 — Loading elevator 2 left | `ctrl_move_loading_elevator_2_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V103_V104` |
| 10 | V103_HP — Loading elevator 2 left home position | `ind_loading_elevator_2_left_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V103_HP` |
| 11 | V103_WP — Loading elevator 2 left work position | `ind_loading_elevator_2_left_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V103_WP` |
| 12 | V104 — Loading elevator 2 right | `ctrl_move_loading_elevator_2_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V103_V104` |
| 13 | V104_HP — Loading elevator 2 right home position | `ind_loading_elevator_2_right_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V104_HP` |
| 14 | V104_WP — Loading elevator 2 right work position | `ind_loading_elevator_2_right_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V104_WP` |
| 15 | V105 — Loading elevator 3 left | `ctrl_move_loading_elevator_3_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V105_V106` |
| 16 | V105_HP — Loading elevator 3 left home position | `ind_loading_elevator_3_left_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V105_HP` |
| 17 | V105_WP — Loading elevator 3 left work position | `ind_loading_elevator_3_left_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V105_WP` |
| 18 | V106 — Loading elevator 3 right | `ctrl_move_loading_elevator_3_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V105_V106` |
| 19 | V106_HP — Loading elevator 3 right home position | `ind_loading_elevator_3_right_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V106_HP` |
| 20 | V106_WP — Loading elevator 3 right work position | `ind_loading_elevator_3_right_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V106_WP` |
| 21 | V107 — Loading stopper 1 left | `ctrl_move_loading_stopper_1_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V107_V108` |
| 22 | V107_HP — Loading stopper 1 left home position | `ind_loading_stopper_1_left_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V107_HP` |
| 23 | V107_WP — Loading stopper 1 left work position | `ind_loading_stopper_1_left_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V107_WP` |
| 24 | V108 — Loading stopper 1 right | `ctrl_move_loading_stopper_1_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V107_V108` |
| 25 | V108_HP — Loading stopper 1 right home position | `ind_loading_stopper_1_right_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V108_HP` |
| 26 | V108_WP — Loading stopper 1 right work position | `ind_loading_stopper_1_right_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V108_WP` |
| 27 | V109 — Loading stopper 2 left | `ctrl_move_loading_stopper_2_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V109_V110` |
| 28 | V109_HP — Loading stopper 2 left home position | `ind_loading_stopper_2_left_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V109_HP` |
| 29 | V109_WP — Loading stopper 2 left work position | `ind_loading_stopper_2_left_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V109_WP` |
| 30 | V110 — Loading stopper 2 right | `ctrl_move_loading_stopper_2_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V109_V110` |
| 31 | V110_HP — Loading stopper 2 right home position | `ind_loading_stopper_2_right_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V110_HP` |
| 32 | V110_WP — Loading stopper 2 right work position | `ind_loading_stopper_2_right_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V110_WP` |
| 33 | B101 — Loading product presence 1 | `ind_container_in_loading_position_1` | IN | FESTO AP / BAT2 | `tbd` | `ind_B101` |
| 34 | B102 — Loading product presence 2 | `ind_container_in_loading_position_2` | IN | FESTO AP / BAT2 | `tbd` | `ind_B102` |
| 35 | B103 — Loading product presence 3 | `ind_container_in_loading_position_3` | IN | FESTO AP / BAT2 | `tbd` | `ind_B103` |

### ST02_Elevator

| Wiersz | ID / etykieta | Nazwa z arkusza N | IN/OUT | Źródło urządzenia | Adres źródłowy, niezatwierdzony | Alias Vijeo |
|---:|---|---|---|---|---|---|
| 3 | V201 — Blister positioner left | `ctrl_move_blister_positioner_left_to_work_position` | OUT | FESTO AP / BAT3 | `tbd` | `ctrl_V201` |
| 4 | V201 HP — Blister positioner left home position | `ind_blister_positioner_left_in_home_position` | IN | FESTO AP / BAT3 | `tbd` | `ind_V201_HP` |
| 5 | V201 WP — Blister positioner left work position | `ind_blister_positioner_left_in_work_position` | IN | FESTO AP / BAT3 | `tbd` | `ind_V201_WP` |
| 6 | V202 — Blister positioner right | `ctrl_move_blister_positioner_right_to_work_position` | OUT | FESTO AP / BAT3 | `tbd` | `ctrl_V202` |
| 7 | V202 HP — Blister positioner right home position | `ind_blister_positioner_right_in_home_position` | IN | FESTO AP / BAT3 | `tbd` | `ind_V202_HP` |
| 8 | V202 WP — Blister positioner right work position | `ind_blister_positioner_right_in_work_position` | IN | FESTO AP / BAT3 | `tbd` | `ind_V202_WP` |
| 9 | V203 — Blue box positioner left | `ctrl_move_blue_box_positioner_left_to_work_position` | OUT | FESTO AP / BAT3 | `tbd` | `ctrl_V203` |
| 10 | V203 HP — Blue box positioner left home position | `ind_blue_box_positioner_left_in_home_position` | IN | FESTO AP / BAT3 | `tbd` | `ind_V203_HP` |
| 11 | V203 WP — Blue box positioner left work position | `ind_blue_box_positioner_left_in_work_position` | IN | FESTO AP / BAT3 | `tbd` | `ind_V203_WP` |
| 12 | B201 — Elevator top position | `ind_elevator_in_top_position` | IN | PLC / KEC2 | `%I2.8` | `ind_B201` |
| 13 | B202 — Elevator intermediate top position | `ind_elevator_in_intermediate_top_position` | IN | PLC / KEC2 | `%I2.9` | `ind_B202` |
| 14 | B203 — Elevator intermediate bottom position | `ind_elevator_in_intermediate_bottom_position` | IN | PLC / KEC2 | `%I2.10` | `ind_B203` |
| 15 | B204 — Elevator bottom position | `ind_elevator_in_bottom_position` | IN | PLC / KEC2 | `%I2.11` | `ind_B204` |
| 16 | B205 — Product presence on elevator | `ind_container_in_elevator_position` | IN | PLC / KEC2 | `tbd - unconnected in P0001` | `ind_B205` |

### ST03_Unloading Belt

| Wiersz | ID / etykieta | Nazwa z arkusza N | IN/OUT | Źródło urządzenia | Adres źródłowy, niezatwierdzony | Alias Vijeo |
|---:|---|---|---|---|---|---|
| 3 | V301 — Unloading stopper 1 left | `ctrl_move_unloading_stopper_1_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V301_V302` |
| 4 | V301_HP — Unloading stopper 1 left home position | `ind_unloading_stopper_1_left_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V301_HP` |
| 5 | V301_WP — Unloading stopper 1 left work position | `ind_unloading_stopper_1_left_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V301_WP` |
| 6 | V302 — Unloading stopper 1 right | `ctrl_move_unloading_stopper_1_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V301_V302` |
| 7 | V302_HP — Unloading stopper 1 right home position | `ind_unloading_stopper_1_right_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V302_HP` |
| 8 | V302_WP — Unloading stopper 1 right work position | `ind_unloading_stopper_1_right_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V302_WP` |
| 9 | V303 — Unloading stopper 2 left | `ctrl_move_unloading_stopper_2_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V303_V304` |
| 10 | V303_HP — Unloading stopper 2 left home position | `ind_unloading_stopper_2_left_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V303_HP` |
| 11 | V303_WP — Unloading stopper 2 left work position | `ind_unloading_stopper_2_left_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V303_WP` |
| 12 | V304 — Unloading stopper 2 right | `ctrl_move_unloading_stopper_2_to_work_position` | OUT | FESTO AP / BAT2 | `tbd` | `ctrl_V303_V304` |
| 13 | V304_HP — Unloading stopper 2 right home position | `ind_unloading_stopper_2_right_in_home_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V304_HP` |
| 14 | V304_WP — Unloading stopper 2 right work position | `ind_unloading_stopper_2_right_in_work_position` | IN | FESTO AP / BAT2 | `tbd` | `ind_V304_WP` |
| 15 | B301 — Elevator unloading area empty | `ind_elevator_unloading_area_empty` | IN | FESTO AP / BAT2 | `tbd` | `ind_B301` |
| 16 | B302 — Unloading product presence 1 | `ind_container_in_unloading_position_1` | IN | FESTO AP / BAT2 | `tbd` | `ind_B302` |
| 17 | B303 — Unloading product presence 2 | `ind_container_in_unloading_position_2` | IN | FESTO AP / BAT2 | `tbd` | `ind_B303` |
| 18 | B304 — Unloading product presence 3 | `ind_container_in_unloading_position_3` | IN | FESTO AP / BAT2 | `tbd` | `ind_B304` |

### ST04_Spacer depositor

| Wiersz | ID / etykieta | Nazwa z arkusza N | IN/OUT | Źródło urządzenia | Adres źródłowy, niezatwierdzony | Alias Vijeo |
|---:|---|---|---|---|---|---|
| 3 | V401 — Spacer barrier left | `ctrl_move_spacer_barrier_left_to_work_position` | OUT | FESTO AP / BAT1 | `tbd` | `ctrl_V401` |
| 4 | V401_HP — Spacer barrier left home position | `ind_spacer_barrier_left_in_home_position` | IN | FESTO AP / BAT1 | `tbd` | `ind_V401_HP` |
| 5 | V401_WP — Spacer barrier left work position | `ind_spacer_barrier_left_in_work_position` | IN | FESTO AP / BAT1 | `tbd` | `ind_V401_WP` |
| 6 | V402 — Spacer barrier right | `ctrl_move_spacer_barrier_right_to_work_position` | OUT | FESTO AP / BAT1 | `tbd` | `ctrl_V402` |
| 7 | V402_HP — Spacer barrier right home position | `ind_spacer_barrier_right_in_home_position` | IN | FESTO AP / BAT1 | `tbd` | `ind_V402_HP` |
| 8 | V402_WP — Spacer barrier right work position | `ind_spacer_barrier_right_in_work_position` | IN | FESTO AP / BAT1 | `tbd` | `ind_V402_WP` |
| 9 | B401 — Spacer depositor low level | `ind_low_level_of_spacers` | IN | FESTO AP / BAT1 | `tbd` | `ind_B401` |
| 10 | B402 — Spacer depositor empty | `ind_spacer_storage_empty` | IN | FESTO AP / BAT1 | `tbd` | `ind_B402` |

### ST05_Robot

| Wiersz | ID / etykieta | Nazwa z arkusza N | IN/OUT | Źródło urządzenia | Adres źródłowy, niezatwierdzony | Alias Vijeo |
|---:|---|---|---|---|---|---|
| 3 | V501 — Robot axis 7 | `ctrl_move_robot_axis_7_to_work_position` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V501` |
| 4 | V501_HP — Robot axis 7 home position | `ind_robot_axis_7_in_home_position` | IN | FESTO AP / BAT4 | `tbd` | `ind_V501_HP` |
| 5 | V501_WP — Robot axis 7 work position | `ind_robot_axis_7_in_work_position` | IN | FESTO AP / BAT4 | `tbd` | `ind_V501_WP` |
| 6 | V502 — Robot gripper actuator 1 | `ctrl_move_robot_gripper_1_to_work_position` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V502` |
| 7 | V502_HP — Robot gripper actuator 1 home position | `ind_robot_gripper_1_in_home_position` | IN | PLC / KEC3 | `tbd` | `ind_V502_HP` |
| 8 | V502_WP — Robot gripper actuator 1 work position | `ind_robot_gripper_1_in_work_position` | IN | PLC / KEC3 | `tbd` | `ind_V502_WP` |
| 9 | V503 — Robot gripper actuator 2 | `ctrl_move_robot_gripper_2_to_work_position` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V503` |
| 10 | V503_HP — Robot gripper actuator 2 home position | `ind_robot_gripper_2_in_home_position` | IN | PLC / KEC3 | `tbd` | `ind_V503_HP` |
| 11 | V503_WP — Robot gripper actuator 2 work position | `ind_robot_gripper_2_in_work_position` | IN | PLC / KEC3 | `tbd` | `ind_V503_WP` |
| 12 | V504 — Robot gripper actuator 3 | `ctrl_move_robot_gripper_3_to_work_position` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V504` |
| 13 | V504_HP — Robot gripper actuator 3 home position | `ind_robot_gripper_3_in_home_position` | IN | PLC / KEC3 | `tbd` | `ind_V504_HP` |
| 14 | V504_WP — Robot gripper actuator 3 work position | `ind_robot_gripper_3_in_work_position` | IN | PLC / KEC3 | `tbd` | `ind_V504_WP` |
| 15 | V505 — Robot gripper actuator 4 | `ctrl_move_robot_gripper_4_to_work_position` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V505` |
| 16 | V505_HP — Robot gripper actuator 4 home position | `ind_robot_gripper_4_in_home_position` | IN | PLC / KEC3 | `tbd` | `ind_V505_HP` |
| 17 | V505_WP — Robot gripper actuator 4 work position | `ind_robot_gripper_4_in_work_position` | IN | PLC / KEC3 | `tbd` | `ind_V505_WP` |
| 18 | V506 — Reservation 1 | `ctrl_spare_v506` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V506` |
| 19 | V507 — Reservation 2 | `ctrl_spare_v507` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V507` |
| 20 | V508 — Reservation 3 | `ctrl_spare_v508` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V508` |
| 21 | V509 — Vacuum 1 | `ctrl_turn_on_robot_gripper_vacuum_1` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V509` |
| 22 | V510 — Vacuum 2 | `ctrl_turn_on_robot_gripper_vacuum_2` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V510` |
| 23 | V511 — Vacuum 3 | `ctrl_turn_on_robot_gripper_vacuum_3` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V511` |
| 24 | V512 — Vacuum 4 | `ctrl_turn_on_robot_gripper_vacuum_4` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V512` |
| 25 | V513 — Vacuum 5 | `ctrl_turn_on_robot_gripper_vacuum_5` | OUT | FESTO AP / BAT4 | `tbd` | `ctrl_V513` |

### Euromap67+73 (placeholder)

| Wiersz | ID / etykieta | Nazwa z arkusza N | IN/OUT | Źródło urządzenia | Adres źródłowy, niezatwierdzony | Alias Vijeo |
|---:|---|---|---|---|---|---|
| 3 | KF101 — IMM reject | `ind_e67_imm_reject` | IN | PLC / KEC1 | `%I1.1` | `ind_KF101` |
| 4 | KF102 — IMM mould closed | `ind_e67_imm_mould_closed` | IN | PLC / KEC1 | `%I1.2` | `ind_KF102` |
| 5 | KF103 — IMM mould open | `ind_e67_imm_mould_open` | IN | PLC / KEC1 | `%I1.3` | `ind_KF103` |
| 6 | KF104 — IMM mould intermediate position | `ind_e67_imm_mould_in_intermediate_position` | IN | PLC / KEC1 | `%I1.4` | `ind_KF104` |
| 7 | KF105 — IMM operation with robot enabled | `ind_e67_imm_operation_with_robot_enabled` | IN | PLC / KEC1 | `%I1.5` | `ind_KF105` |
| 8 | KF106 — IMM ejector back position | `ind_e67_imm_ejector_in_back_position` | IN | PLC / KEC1 | `%I1.6` | `ind_KF106` |
| 9 | KF107 — IMM ejector forward position | `ind_e67_imm_ejector_in_forward_position` | IN | PLC / KEC1 | `%I1.7` | `ind_KF107` |
| 10 | KF108 — IMM core 1 in position 1 | `ind_e67_imm_core_1_in_position_1` | IN | PLC / KEC1 | `%I1.8` | `ind_KF108` |
| 11 | KF109 — IMM core 1 in position 2 | `ind_e67_imm_core_1_in_position_2` | IN | PLC / KEC1 | `%I1.9` | `ind_KF109` |
| 12 | KF110 — IMM core 2 in position 1 | `ind_e67_imm_core_2_in_position_1` | IN | PLC / KEC1 | `%I1.10` | `ind_KF110` |
| 13 | KF111 — IMM core 2 in position 2 | `ind_e67_imm_core_2_in_position_2` | IN | PLC / KEC1 | `%I1.11` | `ind_KF111` |
| 14 | KF201 — IMM mould area free | `ctrl_e67_imm_mould_area_free` | OUT | PLC / KEC11 | `%Q1.0` | `ctrl_KF201` |
| 15 | KF202 — IMM enable mould closure | `ctrl_e67_imm_enable_mould_closure` | OUT | PLC / KEC11 | `%Q1.1` | `ctrl_KF202` |
| 16 | KF203 — IMM enable full mould opening | `ctrl_e67_imm_enable_full_mould_opening` | OUT | PLC / KEC11 | `%Q1.2` | `ctrl_KF203` |
| 17 | KF204 — IMM robot operation mode | `ctrl_e67_imm_robot_operation_mode` | OUT | PLC / KEC11 | `%Q1.3` | `ctrl_KF204` |
| 18 | KF205 — IMM enable ejector back | `ctrl_e67_imm_enable_ejector_back` | OUT | PLC / KEC11 | `%Q1.4` | `ctrl_KF205` |
| 19 | KF206 — IMM enable ejector forward | `ctrl_e67_imm_enable_ejector_forward` | OUT | PLC / KEC11 | `%Q1.5` | `ctrl_KF206` |
| 20 | KF207 — IMM enable core 1 position 1 | `ctrl_e67_imm_enable_core_1_position_1` | OUT | PLC / KEC11 | `%Q1.6` | `ctrl_KF207` |
| 21 | KF208 — IMM enable core 1 position 2 | `ctrl_e67_imm_enable_core_1_position_2` | OUT | PLC / KEC11 | `%Q1.7` | `ctrl_KF208` |
| 22 | KF209 — IMM enable core 2 position 1 | `ctrl_e67_imm_enable_core_2_position_1` | OUT | PLC / KEC11 | `%Q1.8` | `ctrl_KF209` |
| 23 | KF210 — IMM enable core 2 position 2 | `ctrl_e67_imm_enable_core_2_position_2` | OUT | PLC / KEC11 | `%Q1.9` | `ctrl_KF210` |
| 24 | KF211 — IMM function to confirm | `ctrl_e67_imm_kf211_tbd` | OUT | PLC / KEC11 | `%Q1.10` | `ctrl_KF211` |
| 25 | KF501 — IMM safety acknowledgement | `ctrl_e73_imm_safety_acknowledgement` | OUT | Safety module / KFA4 | `tbd` | `ctrl_KF501` |
| 26 | KF301 — Robot mould closed | `ind_robot_mould_closed` | IN | Robot controller / CRMA15 | `DI101` | `ind_KF301` |
| 27 | KF302 — Robot mould open | `ind_robot_mould_open` | IN | Robot controller / CRMA15 | `DI102` | `ind_KF302` |
| 28 | KF303 — Robot operation with IMM enabled | `ind_robot_operation_with_imm_enabled` | IN | Robot controller / CRMA15 | `DI103` | `ind_KF303` |
| 29 | KF304 — Robot reserved input 1 | `ctrl_robot_reserved_input_1` | OUT | PLC / KEC11 | `tbd` | `ctrl_KF304` |
| 30 | KF305 — Robot reserved input 2 | `ctrl_robot_reserved_input_2` | OUT | PLC / KEC11 | `tbd` | `ctrl_KF305` |
| 31 | KF306 — Robot reserved input 3 | `ctrl_robot_reserved_input_3` | OUT | PLC / KEC11 | `tbd` | `ctrl_KF306` |
| 32 | KF307 — Robot reserved input 4 | `ctrl_robot_reserved_input_4` | OUT | PLC / KEC11 | `tbd` | `ctrl_KF307` |
| 33 | KF308 — Robot reserved input 5 | `ctrl_robot_reserved_input_5` | OUT | PLC / KEC11 | `tbd` | `ctrl_KF308` |
| 34 | KF401 — Robot mould area free | `ind_robot_mould_area_free` | IN | PLC / KEC2 | `%I2.0` | `ind_KF401` |
| 35 | KF402 — Robot enable mould closure | `ind_robot_enable_mould_closure` | IN | PLC / KEC2 | `%I2.1` | `ind_KF402` |
| 36 | KF403 — Robot function to confirm | `ind_robot_kf403_tbd` | IN | PLC / KEC2 | `%I2.2` | `ind_KF403` |
| 37 | KF404 — Robot reserved output 1 | `ind_robot_reserved_output_1` | IN | PLC / KEC2 | `%I2.3` | `ind_KF404` |
| 38 | KF405 — Robot reserved output 2 | `ind_robot_reserved_output_2` | IN | PLC / KEC2 | `%I2.4` | `ind_KF405` |
| 39 | KF406 — Robot reserved output 3 | `ind_robot_reserved_output_3` | IN | PLC / KEC2 | `%I2.5` | `ind_KF406` |
| 40 | KF407 — Robot reserved output 4 | `ind_robot_reserved_output_4` | IN | PLC / KEC2 | `%I2.6` | `ind_KF407` |
| 41 | KF408 — Robot reserved output 5 | `ind_robot_reserved_output_5` | IN | PLC / KEC2 | `%I2.7` | `ind_KF408` |

### Physical buttons (placeholder)

| Wiersz | ID / etykieta | Nazwa z arkusza N | IN/OUT | Źródło urządzenia | Adres źródłowy, niezatwierdzony | Alias Vijeo |
|---:|---|---|---|---|---|---|
| 3 | S1 — Open or close spacer storage button | `ind_button_open_close_spacer_storage` | IN | PLC / KEB1 | `%I3.2` | `ind_S1` |
| 4 | S3 — Give samples button | `ind_button_samples` | IN | PLC / KEB1 | `%I3.4` | `ind_S3` |
| 5 | S4 — Continue process button | `ind_button_continue_process` | IN | PLC / KEB1 | `%I3.5` | `ind_S4` |
| 6 | S5 — Start process button | `ind_button_start_process` | IN | PLC / KEB1 | `%I3.6` | `ind_S5` |
| 7 | S6 — Container ready button | `ind_button_container_ready` | IN | PLC / KEB1 | `%I3.7` | `ind_S6` |
| 8 | S7 — Empty station button | `ind_button_start_emptying_process` | IN | PLC / KEB1 | `%I3.8` | `ind_S7` |
| 9 | LCK1-X2:7 — Robot cell doors button | `ind_button_open_close_robot_cell_doors` | IN | PLC / KEB1 | `%I3.3` | `ind_LCK1_X2_7` |
| 10 | LCK1-X5:1 — Robot cell doors closed | `ind_robot_cell_doors_closed` | IN | PLC / KEB1 | `%I3.10` | `ind_LCK1_X5_1` |
| 11 | LCK1-X5:4 — Robot cell doors locked | `ind_robot_cell_doors_locked` | IN | PLC / KEB1 | `%I3.11` | `ind_LCK1_X5_4` |
| 12 | KF9.KF10 — Spacer storage robot-side opening permission | `ind_spacer_storage_robot_side_doors_opening_permission` | IN | PLC / KEB1 | `%I3.12` | `ind_KF9_KF10` |
| 13 | KF11.KF12 — Spacer storage operator-side opening permission | `ind_spacer_storage_operator_side_doors_opening_permission` | IN | PLC / KEB1 | `%I3.13` | `ind_KF11_KF12` |
| 14 | H1 — Spacer storage button LED | `ctrl_led_button_open_close_spacer_storage` | OUT | PLC / KEB1 | `%Q0.0` | `ctrl_H1` |
| 15 | H3 — Give samples button LED | `ctrl_led_button_samples` | OUT | PLC / KEB1 | `%Q0.1` | `ctrl_H3` |
| 16 | H4 — Continue process button LED | `ctrl_led_button_continue_process` | OUT | PLC / KEB1 | `%Q0.2` | `ctrl_H4` |
| 17 | H5 — Start process button LED | `ctrl_led_button_start_process` | OUT | PLC / KEB1 | `%Q0.3` | `ctrl_H5` |
| 18 | P6 — Container ready button LED | `ctrl_led_button_container_ready` | OUT | PLC / KEB1 | `%Q0.4` | `ctrl_P6` |
| 19 | P7 — Empty station button LED | `ctrl_led_button_start_emptying_process` | OUT | PLC / KEB1 | `%Q0.5` | `ctrl_P7` |
| 20 | KF30 — Loading conveyor | `ctrl_turn_on_loading_conveyor` | OUT | PLC / KEB1 | `%Q0.6` | `ctrl_KF30` |
| 21 | KF31 — Unloading conveyor out | `ctrl_turn_on_unloading_conveyor_out` | OUT | PLC / KEB1 | `%Q0.7` | `ctrl_KF31` |
| 22 | KF33 — Elevator conveyor out | `ctrl_turn_on_elevator_conveyor_out` | OUT | PLC / KEB1 | `%Q0.8` | `ctrl_KF33` |
| 23 | KF34 — Elevator conveyor in | `ctrl_turn_on_elevator_conveyor_in` | OUT | PLC / KEB1 | `%Q0.9` | `ctrl_KF34` |
| 24 | KF35 — Elevator drive | `ctrl_run_elevator` | OUT | PLC / KEB1 | `tbd` | `ctrl_KF35` |
| 25 | KEC12-Q0 — Spacer storage robot-side lock | `ctrl_open_spacer_storage_robot_side_lock` | OUT | PLC / KEC12 | `tbd` | `ctrl_KEC12_Q0` |
| 26 | KEC12-Q1 — Spacer storage operator-side lock | `ctrl_open_spacer_storage_operator_side_lock` | OUT | PLC / KEC12 | `tbd` | `ctrl_KEC12_Q1` |
| 27 | KEC12-Q2 — Robot cell doors lock | `ctrl_open_robot_cell_doors_lock` | OUT | PLC / KEC12 | `%Q2.6` | `ctrl_KEC12_Q2` |
| 28 | KEC12-Q3 — Robot cell doors safety reset | `ctrl_reset_robot_cell_doors_safety` | OUT | PLC / KEC12 | `%Q2.7` | `ctrl_KEC12_Q3` |
| 29 | KEC12-Q8 — Robot cell doors LED | `ctrl_robot_cell_doors_led` | OUT | PLC / KEC12 | `%Q2.8` | `ctrl_KEC12_Q8` |
| 30 | KEC12-Q5 — Elevator STO bypass | `ctrl_bypass_elevator_sto` | OUT | PLC / KEC12 | `tbd` | `ctrl_KEC12_Q5` |
| 31 | PFA10-G — Signal tower green | `ctrl_turn_on_light_green` | OUT | PLC / KEC12 | `%Q2.10` | `ctrl_PFA10_G` |
| 32 | PFA10-O — Signal tower orange | `ctrl_turn_on_light_yellow` | OUT | PLC / KEC12 | `%Q2.11` | `ctrl_PFA10_O` |
| 33 | PFA10-R — Signal tower red | `ctrl_turn_on_light_red` | OUT | PLC / KEC12 | `%Q2.12` | `ctrl_PFA10_R` |
| 34 | PFA10-4 — Signal tower level 4 | `ctrl_turn_on_signal_tower_level_4` | OUT | PLC / KEC12 | `tbd` | `ctrl_PFA10_4` |
| 35 | PFA10-5 — Signal tower buzzer | `ctrl_turn_on_buzzer` | OUT | PLC / KEC12 | `tbd (%Q2.13 in draft note)` | `ctrl_PFA10_5` |

## 3. Urządzenia i diagnostyka Festo

W v4 odczytaj `GVL_HMI.vijeo.modules[i-1]` (BOOL) dla każdego indeksu z tabeli. Sterownik sprawdza stan modułu, bramki i świeżość obrazu. Opis powiązanego alarmu pochodzi z `GVL_HMI.vijeo.alarms.entries[j-1].text`, gdzie `j=40+i`. Osobne pola kodu producenta i ważności wejść/wyjść dla modułu pozostają otwarte w GAP-03.

| i | ID | Funkcja z arkusza | Źródło |
|---:|---|---|---|
| 1 | BAT100 | Festo AP system gateway | Festo Islands, wiersz 3 |
| 2 | BAT101 | ST04 digital input module | Festo Islands, wiersz 4 |
| 3 | BAT200 | ST01 and ST03 valve terminal | Festo Islands, wiersz 5 |
| 4 | BAT201 | ST01 digital input module 1 | Festo Islands, wiersz 6 |
| 5 | BAT202 | ST01 digital input module 2 | Festo Islands, wiersz 7 |
| 6 | BAT203 | ST01 digital input module 3 | Festo Islands, wiersz 8 |
| 7 | BAT204 | ST03 digital input module 1 | Festo Islands, wiersz 9 |
| 8 | BAT205 | ST03 digital input module 2 | Festo Islands, wiersz 10 |
| 9 | BAT300 | ST02 valve terminal | Festo Islands, wiersz 11 |
| 10 | BAT301 | ST02 digital input module | Festo Islands, wiersz 12 |
| 11 | BAT400 | ST05 valve terminal | Festo Islands, wiersz 13 |
| 12 | BAT401 | ST05 digital input module | Festo Islands, wiersz 14 |

Na stronie DIAG pokazuj bramkę oraz zależne węzły i ich konkretne przyczyny błędów. BAT100 ma źródłowy adres 192.168.0.20; pozostałe elementy AP nie otrzymują na tej podstawie osobnych adresów Ethernet.

## 4. Braki i rozbieżności wykazane przez arkusz

- Osobna bariera ST.1: brak oznaczenia/wiersza, GAP-01. Jej stan i ważność udostępniają `GVL_HMI.hmiIo.barrierBlocked` oraz `GVL_HMI.hmiIo.barrierValid`. B101 mierzy obecność na P1.
- B205: „tbd - unconnected in P0001”, GAP-02; konieczne fizyczne podłączenie i zatwierdzona mapa.
- Sterowania i potwierdzenia Festo w większości mają TBD; potwierdzić EDS, konfigurację modułów, bity, cewki, polaryzacje oraz zachowanie po zaniku, GAP-03/08.
- V201/V202 mają odrębne nazwy poleceń; V401/V402 także. Równoczesność w Auto wynika z procesu PLC, nie ze wspólnego aliasu wyjścia.
- V502–V505 mają w arkuszu czujniki w KEC3; nowe aliasy nie wymagają ich fizycznego przepięcia do Festo.
- V509–V513 mają komendy próżni, ale brak pełnych potwierdzeń i mapy przedmuchów. Nie wykorzystać automatycznie V506–V508 jako przedmuchów.
- KF211 i KF403: funkcja do potwierdzenia. KF3xx/KF4xx: rozbieżność przewodowy robot ↔ docelowe EtherNet/IP, GAP-05/09.
- „Continue process”, „Empty station” i „Container ready” w arkuszu opisują stare nazwy. Źródłowy opis przycisku nie zastępuje nowej semantyki fizycznego Start/Stop, jednego wydania i końca zlecenia; zatwierdzić połączenia przed normalizacją. „Give samples” pozostaje diagnostyką istniejącego wejścia; nie dodaje się samowolnie nowego przycisku HMI.
- KF501, rygle, reset safety i bypass STO są widoczne w rejestrze źródeł. To nie zgoda na ich ręczne wymuszanie. Główna mapa określa, które zatwierdzone sygnały procesowe mają komendy Manual.

Weryfikacja tej listy potwierdza pokrycie pliku źródłowego, nie poprawność jego adresów ani próbę komunikacji. Fizyczna walidacja, kompilacja aliasów i import Vijeo pozostają do wykonania.
