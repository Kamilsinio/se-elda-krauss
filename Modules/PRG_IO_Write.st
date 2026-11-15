PROGRAM PRG_IO_Write
VAR
    encoder : FB_RobotCodec;
END_VAR
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

(* V401/V402: tylko GVL_Robot.storageOut, nowe bindingi Festo zamiast starego M8. *)

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
(* BAT4: tylko Sts.vacuum[1..5], bez rownoleglego starego toru prozni 5. *)

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


encoder(Tx := GVL_Robot.Tx);
GVL_Robot.RawOut := encoder.RawOut;
