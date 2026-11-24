TYPE ST_IO_DI :
STRUCT
    (* --- Załadunek / pozycja 1 --- *)
    ind_M1_1_fwd : BOOL;
    ind_M1_2_fwd : BOOL;
    ind_M1_1_bwd : BOOL;
    ind_M1_2_bwd : BOOL;

    ind_M2_1_fwd : BOOL;
    ind_M2_2_fwd : BOOL;
    ind_M2_1_bwd : BOOL;
    ind_M2_2_bwd : BOOL;

    ind_container_in_pos_1 : BOOL;

    (* --- Bufor / pozycja 2 --- *)
    ind_container_in_pos_2 : BOOL;

    ind_M3_1_fwd : BOOL;
    ind_M3_2_fwd : BOOL;
    ind_M3_1_bwd : BOOL;
    ind_M3_2_bwd : BOOL;

    (* --- Bufor / pozycja 3 --- *)
    ind_M4_1_fwd : BOOL;
    ind_M4_2_fwd : BOOL;
    ind_M4_1_bwd : BOOL;
    ind_M4_2_bwd : BOOL;

    ind_container_in_pos_3 : BOOL;

    ind_M5_1_fwd : BOOL;
    ind_M5_2_fwd : BOOL;
    ind_M5_1_bwd : BOOL;
    ind_M5_2_bwd : BOOL;

    (* --- Winda / pozycja 4 --- *)
    ind_M6_1_fwd : BOOL;
    ind_M6_2_fwd : BOOL;
    ind_M6_1_bwd : BOOL;
    ind_M6_2_bwd : BOOL;

    ind_M7_fwd : BOOL;
    ind_M7_bwd : BOOL;

    ind_elevator_in_top_pos : BOOL;
    ind_elevator_in_intermediate_top_pos : BOOL;
    ind_elevator_in_intermediate_bottom_pos : BOOL;
    ind_elevator_in_bottom_pos : BOOL;

    ind_B301_raw : BOOL;
    ind_elevator_emptied : BOOL; // Znormalizowany sygnał dla akumulatora: 1 = zajęty.

    (* --- Rozładunek / pozycje 5-7 --- *)
    lowerStop : ARRAY[1..2] OF ST_StopperPairIn;
    ind_container_in_pos_5 : BOOL;
    ind_container_in_pos_6 : BOOL;
    ind_container_in_pos_7 : BOOL;

    (* --- Magazyn przekładek --- *)

    ind_V401_home : BOOL;
    ind_V401_work : BOOL;
    ind_V402_home : BOOL;
    ind_V402_work : BOOL;
    ind_low_level_of_spacers : BOOL;
    ind_spacer_storage_empty : BOOL;

    (* --- Przyciski / utils --- *)
    ind_button_open_close_spacer_storage : BOOL;
    ind_button_open_close_robot_cell_doors : BOOL;
    ind_button_samples : BOOL;
    ind_button_continue_process : BOOL;
    ind_button_start_process : BOOL;
    ind_button_container_ready : BOOL;
    ind_button_start_emptying_process : BOOL;

    pressureValid : BOOL;
    ind_low_pressure : BOOL;
    doorDeviceStatusValid : BOOL;
    doorDeviceOk : BOOL;
    ind_robot_cell_doors_closed : BOOL;
    ind_robot_cell_doors_locked : BOOL;

    (* --- Zezwolenia / robot --- *)
    ind_spacer_storage_robot_side_doors_opening_permission : BOOL;
    ind_spacer_storage_operator_side_doors_opening_permission : BOOL;

    // --- Chwytak i oś pneumatyczna robota ---
    ind_axis_7_home : BOOL;
    ind_axis_7_work : BOOL;
    gripperHome : ARRAY[2..5] OF BOOL;
    gripperWork : ARRAY[2..5] OF BOOL;

    // --- Wejścia przewodowe EUROMAP 67 ---
    ind_e67_imm_reject : BOOL;
    ind_e67_imm_mould_closed : BOOL;
    ind_e67_imm_mould_open : BOOL;
    ind_e67_imm_mould_in_intermediate_position : BOOL;
    ind_e67_imm_operation_with_robot_enabled : BOOL;
    ind_e67_imm_ejector_in_back_position : BOOL;
    ind_e67_imm_ejector_in_forward_position : BOOL;
    ind_e67_imm_core_1_in_position_1 : BOOL;
    ind_e67_imm_core_1_in_position_2 : BOOL;
    ind_e67_imm_core_2_in_position_1 : BOOL;
    ind_e67_imm_core_2_in_position_2 : BOOL;

	// --- Diagnostyka ATV320 (Control_ATV / Axis_Ref) ---
	ATV320_stsWord : WORD;
	ATV320_currentFreq : WORD;
	ATV320_axisExcess : WORD;

END_STRUCT
END_TYPE
