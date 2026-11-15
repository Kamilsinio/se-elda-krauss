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
