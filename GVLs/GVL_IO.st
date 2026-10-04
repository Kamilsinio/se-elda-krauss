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
    spare_ix4_5 : BOOL;

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

    ind_container_in_pos_4 : BOOL;
    spare_ix6_5 : BOOL;

    ind_elevator_emptied : BOOL;

    (* --- Rozładunek / pozycje 5-7 --- *)
    ind_container_in_pos_5 : BOOL;
    ind_container_in_pos_6 : BOOL;
    ind_container_in_pos_7 : BOOL;

    spare_ix7_2 : BOOL;
    spare_ix7_3 : BOOL;

    (* --- Magazyn przekładek --- *)
    ind_M8_fwd : BOOL;
    ind_M8_bwd : BOOL;

    ind_low_level_of_spacers : BOOL;
    ind_spacer_storage_empty : BOOL;

    spare_ix8_0 : BOOL;
    spare_ix8_1 : BOOL;

    (* --- Przyciski / utils --- *)
    ind_button_open_close_spacer_storage : BOOL;
    ind_button_open_close_robot_cell_doors : BOOL;
    ind_button_samples : BOOL;
    ind_button_continue_process : BOOL;
    ind_button_start_process : BOOL;
    ind_button_container_ready : BOOL;
    ind_button_start_emptying_process : BOOL;

    ind_low_pressure : BOOL;
    ind_robot_cell_doors_locked : BOOL;
    ind_robot_cell_doors_error : BOOL;

    (* --- Zezwolenia / robot --- *)
    ind_spacer_storage_robot_side_doors_opening_permission : BOOL;
    ind_spacer_storage_operator_side_doors_opening_permission : BOOL;
    ind_robot_gripper_vacuum_ok : BOOL;

    spare_ix9_7 : BOOL;
	
	// --- Diagnostyka ATV320 (Control_ATV / Axis_Ref) ---
	ATV320_stsWord : WORD;
	ATV320_currentFreq : WORD;
	ATV320_axisExcess : WORD;
	
END_STRUCT
END_TYPE

TYPE ST_IO_DO :
STRUCT
    (* --- LED przycisków --- *)
    ctrl_LED_button_open_close_spacer_storage : BOOL;
    ctrl_LED_button_samples : BOOL;
    ctrl_LED_button_continue_process : BOOL;
    ctrl_LED_button_start_process : BOOL;
    ctrl_LED_button_container_ready : BOOL;
    ctrl_LED_button_start_emptying_process : BOOL;

    (* --- Transportery --- *)
    ctrl_turn_on_top_conveyor : BOOL;
    ctrl_turn_on_bottom_conveyor : BOOL;
    ctrl_turn_on_elevator_conveyor_in : BOOL;
    ctrl_turn_on_elevator_conveyor_out : BOOL;

    (* --- Siłowniki --- *)
    ctrl_move_M1_actuator_forward : BOOL;
    ctrl_move_M1_actuator_backward : BOOL;

    ctrl_move_M2_actuator_forward : BOOL;
    ctrl_move_M2_actuator_backward : BOOL;

    ctrl_move_M3_actuator_forward : BOOL;
    ctrl_move_M3_actuator_backward : BOOL;

    ctrl_move_M4_actuator_forward : BOOL;
    ctrl_move_M4_actuator_backward : BOOL;

    ctrl_move_M5_actuator_forward : BOOL;
    ctrl_move_M5_actuator_backward : BOOL;

    ctrl_move_M6_actuator_forward : BOOL;
    ctrl_move_M6_actuator_backward : BOOL;

    ctrl_move_M7_actuator_forward : BOOL;
    ctrl_move_M7_actuator_backward : BOOL;

    ctrl_move_M8_actuator_forward : BOOL;
    ctrl_move_M8_actuator_backward : BOOL;

    (* --- Spares --- *)
    spare_qx6_0 : BOOL;
    spare_qx6_1 : BOOL;
    spare_qx6_2 : BOOL;
    spare_qx6_3 : BOOL;

    (* --- Zamki / drzwi --- *)
    ctrl_open_spacer_storage_robot_side_lock : BOOL;
    ctrl_open_spacer_storage_operator_side_lock : BOOL;
    ctrl_open_robot_cell_doors_lock : BOOL;

    ctrl_reset_robot_cell_doors : BOOL;
    ctrl_robot_cell_doors_LED_open_close : BOOL;

    (* --- Sygnalizacja --- *)
    ctrl_turn_on_buzzer : BOOL;
    ctrl_turn_on_light_green : BOOL;
    ctrl_turn_on_light_yellow : BOOL;
    ctrl_turn_on_light_red : BOOL;

    (* --- Robot chwytak --- *)
    ctrl_turn_on_robot_gripper_vacuum : BOOL;
    ctrl_turn_on_robot_gripper_blow_off : BOOL;

    (* --- Dolny transporter (kierunek do windy) --- *)
    ctrl_turn_on_bottom_conveyor_in : BOOL;

    (* --- Spares --- *)
    spare_qx8_0 : BOOL;
    spare_qx8_1 : BOOL;
    spare_qx8_2 : BOOL;
    spare_qx8_3 : BOOL;
    spare_qx8_4 : BOOL;
    spare_qx8_5 : BOOL;
    spare_qx8_6 : BOOL;
    spare_qx8_7 : BOOL;
	
END_STRUCT
END_TYPE

{attribute 'qualified_only'}
// variable mapping 
// used directly in FBS

VAR_GLOBAL
di : ST_IO_DI ;
dout : ST_IO_DO ;
END_VAR
