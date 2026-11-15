(* ============================================================
   GVL_Robot - Sygnaly IOScanner PLC <-> Robot FANUC M20iA
   Robot DIN = PLC pisze (komendy do robota)
   Robot DOUT = PLC czyta (statusy z robota)
   ============================================================ *)

TYPE ST_RobotFromPLC :
STRUCT
    (* Sygnaly sterujace do robota - mapowane na Robot DIN via IOScanner *)
    cmd_box_production       : BOOL;  // DIN[1]  - tryb produkcji kuwet
    cmd_tray_production      : BOOL;  // DIN[2]  - tryb produkcji tacek
    cmd_continue_job         : BOOL;  // DIN[3]  - kontynuuj prace
    cmd_stack_ready          : BOOL;  // DIN[4]  - stos gotowy na windzie
    cmd_elevator_ready       : BOOL;  // DIN[5]  - winda gotowa
    cmd_samples              : BOOL;  // DIN[6]  - podaj probki
    ack_pallet_placed        : BOOL;  // DIN[7]  - potwierdzenie ulozenia palety/tacki
    ack_stack_finished       : BOOL;  // DIN[8]  - potwierdzenie zakonczenia stosu
    plc_fault                : BOOL;  // DIN[9]  - blad PLC/stacji
    storage_ready            : BOOL;  // DIN[10] - magazyn przekladek gotowy
    spare_di_11              : BOOL;  // DIN[11]
    spare_di_12              : BOOL;  // DIN[12]
    spare_di_13              : BOOL;  // DIN[13]
    spare_di_14              : BOOL;  // DIN[14]
    spare_di_15              : BOOL;  // DIN[15]
    spare_di_16              : BOOL;  // DIN[16]
    spare_di_17              : BOOL;  // DIN[17]
    spare_di_18              : BOOL;  // DIN[18]
    spare_di_19              : BOOL;  // DIN[19]
    spare_di_20              : BOOL;  // DIN[20]
    spare_di_21              : BOOL;  // DIN[21]
    spare_di_22              : BOOL;  // DIN[22]
    spare_di_23              : BOOL;  // DIN[23]
    spare_di_24              : BOOL;  // DIN[24]
    spare_di_25              : BOOL;  // DIN[25]
    spare_di_26              : BOOL;  // DIN[26]
    spare_di_27              : BOOL;  // DIN[27]
    spare_di_28              : BOOL;  // DIN[28]
    spare_di_29              : BOOL;  // DIN[29]
    spare_di_30              : BOOL;  // DIN[30]
    spare_di_31              : BOOL;  // DIN[31]
    vacuum_5_ok              : BOOL;  // DIN[32] - proznia 5 OK
END_STRUCT
END_TYPE

TYPE ST_RobotToPLC :
STRUCT
    (* Statusy z robota - mapowane z Robot DOUT via IOScanner *)
    sts_auto_mode            : BOOL;  // DOUT[1]  - robot w trybie AUTO
    sts_t1_mode              : BOOL;  // DOUT[2]
    sts_t2_mode              : BOOL;  // DOUT[3]
    sts_estop                : BOOL;  // DOUT[4]  - E-STOP aktywny
    sts_input_simulated      : BOOL;  // DOUT[5]
    sts_output_simulated     : BOOL;  // DOUT[6]
    sts_in_home_pos          : BOOL;  // DOUT[7]  - robot w pozycji HOME
    sts_system_ready         : BOOL;  // DOUT[8]  - system gotowy
    sts_prg_running          : BOOL;  // DOUT[9]  - program w trakcie
    sts_fault                : BOOL;  // DOUT[10] - blad robota
    sts_tp_enabled           : BOOL;  // DOUT[11] - TP wlaczony
    sts_current_prg_box      : BOOL;  // DOUT[12] - aktualny program: kuwety
    sts_current_prg_tray     : BOOL;  // DOUT[13] - aktualny program: tacki
    sts_cmd_ack              : BOOL;  // DOUT[14] - potwierdzenie komendy
    sts_pallet_finished      : BOOL;  // DOUT[15] - tacka/paleta ulozona
    sts_samples_placed       : BOOL;  // DOUT[16] - probki ulozone
    sts_pallet_full          : BOOL;  // DOUT[17] - paleta pelna
    sts_stack_finished       : BOOL;  // DOUT[18] - caly stos zakonczony
    perm_elevator_clear      : BOOL;  // DOUT[19] - zezwolenie czyszczenia windy
    perm_storage_clear       : BOOL;  // DOUT[20] - zezwolenie czyszczenia magazynu
    ack_cmd_continue         : BOOL;  // DOUT[21] - potwierdzenie kontynuacji
    req_storage_access       : BOOL;  // DOUT[22] - zadanie dostepu do magazynu przekladek
    box_progress             : BOOL;  // DOUT[23] - impuls postepu paletyzacji kuwety
    spare_do_24              : BOOL;  // DOUT[24]
    spare_do_25              : BOOL;  // DOUT[25]
    spare_do_26              : BOOL;  // DOUT[26]
    spare_do_27              : BOOL;  // DOUT[27]
    spare_do_28              : BOOL;  // DOUT[28]
    spare_do_29              : BOOL;  // DOUT[29]
    spare_do_30              : BOOL;  // DOUT[30]
    cmd_vacuum_5             : BOOL;  // DOUT[31] - zalacz proznie 5
    cmd_blow_off_5           : BOOL;  // DOUT[32] - przedmuch 5
END_STRUCT
END_TYPE

{attribute 'qualified_only'}
VAR_GLOBAL
    robotOut : ST_RobotFromPLC;  // PLC -> Robot DIN
    robotIn  : ST_RobotToPLC;    // Robot DOUT -> PLC
    xRobotCommOk : BOOL := TRUE; // Mapowac z health IOScannera, jesli dostepny.

    (* Robot DOUT -> PLC, IOScanner inputs *)
    raw_do_1_auto_mode          AT %IX28.0 : BOOL;
    raw_do_2_t1_mode            AT %IX28.1 : BOOL;
    raw_do_3_t2_mode            AT %IX28.2 : BOOL;
    raw_do_4_estop              AT %IX28.3 : BOOL;
    raw_do_5_input_simulated    AT %IX28.4 : BOOL;
    raw_do_6_output_simulated   AT %IX28.5 : BOOL;
    raw_do_7_in_home_pos        AT %IX28.6 : BOOL;
    raw_do_8_system_ready       AT %IX28.7 : BOOL;
    raw_do_9_prg_running        AT %IX29.0 : BOOL;
    raw_do_10_fault             AT %IX29.1 : BOOL;
    raw_do_11_tp_enabled        AT %IX29.2 : BOOL;
    raw_do_12_current_prg_box   AT %IX29.3 : BOOL;
    raw_do_13_current_prg_tray  AT %IX29.4 : BOOL;
    raw_do_14_cmd_ack           AT %IX29.5 : BOOL;
    raw_do_15_pallet_finished   AT %IX29.6 : BOOL;
    raw_do_16_samples_placed    AT %IX29.7 : BOOL;
    raw_do_17_pallet_full       AT %IX30.0 : BOOL;
    raw_do_18_stack_finished    AT %IX30.1 : BOOL;
    raw_do_19_elevator_clear    AT %IX30.2 : BOOL;
    raw_do_20_storage_clear     AT %IX30.3 : BOOL;
    raw_do_21_ack_continue      AT %IX30.4 : BOOL;
    raw_do_22_req_storage_access AT %IX30.5 : BOOL;
    raw_do_23_box_progress       AT %IX30.6 : BOOL;
    raw_do_24_spare            AT %IX30.7 : BOOL;
    raw_do_25_spare            AT %IX31.0 : BOOL;
    raw_do_26_spare            AT %IX31.1 : BOOL;
    raw_do_27_spare            AT %IX31.2 : BOOL;
    raw_do_28_spare            AT %IX31.3 : BOOL;
    raw_do_29_spare            AT %IX31.4 : BOOL;
    raw_do_30_spare            AT %IX31.5 : BOOL;
    raw_do_31_vacuum_5         AT %IX31.6 : BOOL;
    raw_do_32_blow_off_5       AT %IX31.7 : BOOL;

    (* PLC -> Robot DIN, IOScanner outputs *)
    raw_di_1_box_production     AT %QX10.0 : BOOL;
    raw_di_2_tray_production    AT %QX10.1 : BOOL;
    raw_di_3_continue_job       AT %QX10.2 : BOOL;
    raw_di_4_stack_ready        AT %QX10.3 : BOOL;
    raw_di_5_elevator_ready     AT %QX10.4 : BOOL;
    raw_di_6_samples            AT %QX10.5 : BOOL;
    raw_di_7_ack_pallet_placed  AT %QX10.6 : BOOL;
    raw_di_8_ack_stack_finished AT %QX10.7 : BOOL;
    raw_di_9_plc_fault          AT %QX11.0 : BOOL;
    raw_di_10_storage_ready     AT %QX11.1 : BOOL;
    raw_di_11_spare             AT %QX11.2 : BOOL;
    raw_di_12_spare             AT %QX11.3 : BOOL;
    raw_di_13_spare             AT %QX11.4 : BOOL;
    raw_di_14_spare             AT %QX11.5 : BOOL;
    raw_di_15_spare             AT %QX11.6 : BOOL;
    raw_di_16_spare             AT %QX11.7 : BOOL;
    raw_di_17_spare             AT %QX12.0 : BOOL;
    raw_di_18_spare             AT %QX12.1 : BOOL;
    raw_di_19_spare             AT %QX12.2 : BOOL;
    raw_di_20_spare             AT %QX12.3 : BOOL;
    raw_di_21_spare             AT %QX12.4 : BOOL;
    raw_di_22_spare             AT %QX12.5 : BOOL;
    raw_di_23_spare             AT %QX12.6 : BOOL;
    raw_di_24_spare             AT %QX12.7 : BOOL;
    raw_di_25_spare             AT %QX13.0 : BOOL;
    raw_di_26_spare             AT %QX13.1 : BOOL;
    raw_di_27_spare             AT %QX13.2 : BOOL;
    raw_di_28_spare             AT %QX13.3 : BOOL;
    raw_di_29_spare             AT %QX13.4 : BOOL;
    raw_di_30_spare             AT %QX13.5 : BOOL;
    raw_di_31_spare             AT %QX13.6 : BOOL;
    raw_di_32_vacuum_5_ok       AT %QX13.7 : BOOL;
END_VAR
