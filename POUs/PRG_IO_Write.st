(* DO: dout -> RAW *)

(* LED Buttons *)
GVL_IO_RAW.dout.ctrl_LED_button_open_close_spacer_storage := GVL_IO.dout.ctrl_LED_button_open_close_spacer_storage;
GVL_IO_RAW.dout.ctrl_LED_button_samples := GVL_IO.dout.ctrl_LED_button_samples;
GVL_IO_RAW.dout.ctrl_LED_button_continue_process := GVL_IO.dout.ctrl_LED_button_continue_process;
GVL_IO_RAW.dout.ctrl_LED_button_start_process := GVL_IO.dout.ctrl_LED_button_start_process;
GVL_IO_RAW.dout.ctrl_LED_button_container_ready := GVL_IO.dout.ctrl_LED_button_container_ready;
GVL_IO_RAW.dout.ctrl_LED_button_start_emptying_process := GVL_IO.dout.ctrl_LED_button_start_emptying_process;

(* Conveyors *)
GVL_IO_RAW.dout.ctrl_turn_on_top_conveyor := GVL_IO.dout.ctrl_turn_on_top_conveyor;
GVL_IO_RAW.dout.ctrl_turn_on_bottom_conveyor := GVL_IO.dout.ctrl_turn_on_bottom_conveyor;
GVL_IO_RAW.dout.ctrl_turn_on_elevator_conveyor_in := GVL_IO.dout.ctrl_turn_on_elevator_conveyor_in;
GVL_IO_RAW.dout.ctrl_turn_on_elevator_conveyor_out := GVL_IO.dout.ctrl_turn_on_elevator_conveyor_out;

(* Actuators M1 - M8 *)
GVL_IO_RAW.dout.ctrl_move_M1_actuator_forward := GVL_IO.dout.ctrl_move_M1_actuator_forward;
GVL_IO_RAW.dout.ctrl_move_M1_actuator_backward := GVL_IO.dout.ctrl_move_M1_actuator_backward;

GVL_IO_RAW.dout.ctrl_move_M2_actuator_forward := GVL_IO.dout.ctrl_move_M2_actuator_forward;
GVL_IO_RAW.dout.ctrl_move_M2_actuator_backward := GVL_IO.dout.ctrl_move_M2_actuator_backward;

GVL_IO_RAW.dout.ctrl_move_M3_actuator_forward := GVL_IO.dout.ctrl_move_M3_actuator_forward;
GVL_IO_RAW.dout.ctrl_move_M3_actuator_backward := GVL_IO.dout.ctrl_move_M3_actuator_backward;

GVL_IO_RAW.dout.ctrl_move_M4_actuator_forward := GVL_IO.dout.ctrl_move_M4_actuator_forward;
GVL_IO_RAW.dout.ctrl_move_M4_actuator_backward := GVL_IO.dout.ctrl_move_M4_actuator_backward;

GVL_IO_RAW.dout.ctrl_move_M5_actuator_forward := GVL_IO.dout.ctrl_move_M5_actuator_forward;
GVL_IO_RAW.dout.ctrl_move_M5_actuator_backward := GVL_IO.dout.ctrl_move_M5_actuator_backward;

GVL_IO_RAW.dout.ctrl_move_M6_actuator_forward := GVL_IO.dout.ctrl_move_M6_actuator_forward;
GVL_IO_RAW.dout.ctrl_move_M6_actuator_backward := GVL_IO.dout.ctrl_move_M6_actuator_backward;

GVL_IO_RAW.dout.ctrl_move_M7_actuator_forward := GVL_IO.dout.ctrl_move_M7_actuator_forward;
GVL_IO_RAW.dout.ctrl_move_M7_actuator_backward := GVL_IO.dout.ctrl_move_M7_actuator_backward;

GVL_IO_RAW.dout.ctrl_move_M8_actuator_forward := GVL_IO.dout.ctrl_move_M8_actuator_forward;
GVL_IO_RAW.dout.ctrl_move_M8_actuator_backward := GVL_IO.dout.ctrl_move_M8_actuator_backward;

(* Spares QX6 *)
GVL_IO_RAW.dout.spare_qx6_0 := GVL_IO.dout.spare_qx6_0;
GVL_IO_RAW.dout.spare_qx6_1 := GVL_IO.dout.spare_qx6_1;
GVL_IO_RAW.dout.spare_qx6_2 := GVL_IO.dout.spare_qx6_2;
GVL_IO_RAW.dout.spare_qx6_3 := GVL_IO.dout.spare_qx6_3;

(* Locks & Doors *)
GVL_IO_RAW.dout.ctrl_open_spacer_storage_robot_side_lock := GVL_IO.dout.ctrl_open_spacer_storage_robot_side_lock;
GVL_IO_RAW.dout.ctrl_open_spacer_storage_operator_side_lock := GVL_IO.dout.ctrl_open_spacer_storage_operator_side_lock;
GVL_IO_RAW.dout.ctrl_open_robot_cell_doors_lock := GVL_IO.dout.ctrl_open_robot_cell_doors_lock;

GVL_IO_RAW.dout.ctrl_reset_robot_cell_doors := GVL_IO.dout.ctrl_reset_robot_cell_doors;
GVL_IO_RAW.dout.ctrl_robot_cell_doors_LED_open_close := GVL_IO.dout.ctrl_robot_cell_doors_LED_open_close;

(* Tower Light & Buzzer *)
GVL_IO_RAW.dout.ctrl_turn_on_buzzer := GVL_IO.dout.ctrl_turn_on_buzzer;
GVL_IO_RAW.dout.ctrl_turn_on_light_green := GVL_IO.dout.ctrl_turn_on_light_green;
GVL_IO_RAW.dout.ctrl_turn_on_light_yellow := GVL_IO.dout.ctrl_turn_on_light_yellow;
GVL_IO_RAW.dout.ctrl_turn_on_light_red := GVL_IO.dout.ctrl_turn_on_light_red;

(* Robot Gripper *)
GVL_IO_RAW.dout.ctrl_turn_on_robot_gripper_vacuum := GVL_IO.dout.ctrl_turn_on_robot_gripper_vacuum;
GVL_IO_RAW.dout.ctrl_turn_on_robot_gripper_blow_off := GVL_IO.dout.ctrl_turn_on_robot_gripper_blow_off;

(* Conveyor In *)
GVL_IO_RAW.dout.ctrl_turn_on_bottom_conveyor_in := GVL_IO.dout.ctrl_turn_on_bottom_conveyor_in;

(* Spares QX8 *)
GVL_IO_RAW.dout.spare_qx8_0 := GVL_IO.dout.spare_qx8_0;
GVL_IO_RAW.dout.spare_qx8_1 := GVL_IO.dout.spare_qx8_1;
GVL_IO_RAW.dout.spare_qx8_2 := GVL_IO.dout.spare_qx8_2;
GVL_IO_RAW.dout.spare_qx8_3 := GVL_IO.dout.spare_qx8_3;
GVL_IO_RAW.dout.spare_qx8_4 := GVL_IO.dout.spare_qx8_4;
GVL_IO_RAW.dout.spare_qx8_5 := GVL_IO.dout.spare_qx8_5;
GVL_IO_RAW.dout.spare_qx8_6 := GVL_IO.dout.spare_qx8_6;
GVL_IO_RAW.dout.spare_qx8_7 := GVL_IO.dout.spare_qx8_7;

(* Robot FANUC - PLC -> DIN *)
GVL_Robot.raw_di_1_box_production := GVL_Robot.robotOut.cmd_box_production;
GVL_Robot.raw_di_2_tray_production := GVL_Robot.robotOut.cmd_tray_production;
GVL_Robot.raw_di_3_continue_job := GVL_Robot.robotOut.cmd_continue_job;
GVL_Robot.raw_di_4_stack_ready := GVL_Robot.robotOut.cmd_stack_ready;
GVL_Robot.raw_di_5_elevator_ready := GVL_Robot.robotOut.cmd_elevator_ready;
GVL_Robot.raw_di_6_samples := GVL_Robot.robotOut.cmd_samples;
GVL_Robot.raw_di_7_ack_pallet_placed := GVL_Robot.robotOut.ack_pallet_placed;
GVL_Robot.raw_di_8_ack_stack_finished := GVL_Robot.robotOut.ack_stack_finished;
GVL_Robot.raw_di_9_plc_fault := GVL_Robot.robotOut.plc_fault;
GVL_Robot.raw_di_10_storage_ready := GVL_Robot.robotOut.storage_ready;
GVL_Robot.raw_di_11_spare := GVL_Robot.robotOut.spare_di_11;
GVL_Robot.raw_di_12_spare := GVL_Robot.robotOut.spare_di_12;
GVL_Robot.raw_di_13_spare := GVL_Robot.robotOut.spare_di_13;
GVL_Robot.raw_di_14_spare := GVL_Robot.robotOut.spare_di_14;
GVL_Robot.raw_di_15_spare := GVL_Robot.robotOut.spare_di_15;
GVL_Robot.raw_di_16_spare := GVL_Robot.robotOut.spare_di_16;
GVL_Robot.raw_di_17_spare := GVL_Robot.robotOut.spare_di_17;
GVL_Robot.raw_di_18_spare := GVL_Robot.robotOut.spare_di_18;
GVL_Robot.raw_di_19_spare := GVL_Robot.robotOut.spare_di_19;
GVL_Robot.raw_di_20_spare := GVL_Robot.robotOut.spare_di_20;
GVL_Robot.raw_di_21_spare := GVL_Robot.robotOut.spare_di_21;
GVL_Robot.raw_di_22_spare := GVL_Robot.robotOut.spare_di_22;
GVL_Robot.raw_di_23_spare := GVL_Robot.robotOut.spare_di_23;
GVL_Robot.raw_di_24_spare := GVL_Robot.robotOut.spare_di_24;
GVL_Robot.raw_di_25_spare := GVL_Robot.robotOut.spare_di_25;
GVL_Robot.raw_di_26_spare := GVL_Robot.robotOut.spare_di_26;
GVL_Robot.raw_di_27_spare := GVL_Robot.robotOut.spare_di_27;
GVL_Robot.raw_di_28_spare := GVL_Robot.robotOut.spare_di_28;
GVL_Robot.raw_di_29_spare := GVL_Robot.robotOut.spare_di_29;
GVL_Robot.raw_di_30_spare := GVL_Robot.robotOut.spare_di_30;
GVL_Robot.raw_di_31_spare := GVL_Robot.robotOut.spare_di_31;
GVL_Robot.raw_di_32_vacuum_5_ok := GVL_Robot.robotOut.vacuum_5_ok;

// --- ATV320 ---
// Falownik jest sterowany przez GIATV.Control_ATV w FB_Elevator.

