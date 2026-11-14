(**************************)	
(********* INPUTS *********)	
(**************************)

(* DI: RAW -> di *)

(* M1 *)
GVL_IO.di.ind_M1_1_fwd := GVL_IO_RAW.di.ind_M1_1_fwd;
GVL_IO.di.ind_M1_2_fwd := GVL_IO_RAW.di.ind_M1_2_fwd;
GVL_IO.di.ind_M1_1_bwd := GVL_IO_RAW.di.ind_M1_1_bwd;
GVL_IO.di.ind_M1_2_bwd := GVL_IO_RAW.di.ind_M1_2_bwd;

(* M2 *)
GVL_IO.di.ind_M2_1_fwd := GVL_IO_RAW.di.ind_M2_1_fwd;
GVL_IO.di.ind_M2_2_fwd := GVL_IO_RAW.di.ind_M2_2_fwd;
GVL_IO.di.ind_M2_1_bwd := GVL_IO_RAW.di.ind_M2_1_bwd;
GVL_IO.di.ind_M2_2_bwd := GVL_IO_RAW.di.ind_M2_2_bwd;

(* Containers Pos 1 & 2 *)
GVL_IO.di.ind_container_in_pos_1 := GVL_IO_RAW.di.ind_container_in_pos_1;
GVL_IO.di.ind_container_in_pos_2 := GVL_IO_RAW.di.ind_container_in_pos_2;

(* M3 *)
GVL_IO.di.ind_M3_1_fwd := GVL_IO_RAW.di.ind_M3_1_fwd;
GVL_IO.di.ind_M3_2_fwd := GVL_IO_RAW.di.ind_M3_2_fwd;
GVL_IO.di.ind_M3_1_bwd := GVL_IO_RAW.di.ind_M3_1_bwd;
GVL_IO.di.ind_M3_2_bwd := GVL_IO_RAW.di.ind_M3_2_bwd;

(* M4 & Container Pos 3 *)
GVL_IO.di.ind_M4_1_fwd := GVL_IO_RAW.di.ind_M4_1_fwd;
GVL_IO.di.ind_M4_2_fwd := GVL_IO_RAW.di.ind_M4_2_fwd;
GVL_IO.di.ind_M4_1_bwd := GVL_IO_RAW.di.ind_M4_1_bwd;
GVL_IO.di.ind_M4_2_bwd := GVL_IO_RAW.di.ind_M4_2_bwd;
GVL_IO.di.ind_container_in_pos_3 := GVL_IO_RAW.di.ind_container_in_pos_3;
GVL_IO.di.spare_ix4_5 := GVL_IO_RAW.di.spare_ix4_5;

(* M5 *)
GVL_IO.di.ind_M5_1_fwd := GVL_IO_RAW.di.ind_M5_1_fwd;
GVL_IO.di.ind_M5_2_fwd := GVL_IO_RAW.di.ind_M5_2_fwd;
GVL_IO.di.ind_M5_1_bwd := GVL_IO_RAW.di.ind_M5_1_bwd;
GVL_IO.di.ind_M5_2_bwd := GVL_IO_RAW.di.ind_M5_2_bwd;

(* M6 *)
GVL_IO.di.ind_M6_1_fwd := GVL_IO_RAW.di.ind_M6_1_fwd;
GVL_IO.di.ind_M6_2_fwd := GVL_IO_RAW.di.ind_M6_2_fwd;
GVL_IO.di.ind_M6_1_bwd := GVL_IO_RAW.di.ind_M6_1_bwd;
GVL_IO.di.ind_M6_2_bwd := GVL_IO_RAW.di.ind_M6_2_bwd;

(* M7 *)
GVL_IO.di.ind_M7_fwd := GVL_IO_RAW.di.ind_M7_fwd;
GVL_IO.di.ind_M7_bwd := GVL_IO_RAW.di.ind_M7_bwd;

(* Elevator *)
GVL_IO.di.ind_elevator_in_top_pos := GVL_IO_RAW.di.ind_elevator_in_top_pos;
GVL_IO.di.ind_elevator_in_intermediate_top_pos := GVL_IO_RAW.di.ind_elevator_in_intermediate_top_pos;
GVL_IO.di.ind_elevator_in_intermediate_bottom_pos := GVL_IO_RAW.di.ind_elevator_in_intermediate_bottom_pos;
GVL_IO.di.ind_elevator_in_bottom_pos := GVL_IO_RAW.di.ind_elevator_in_bottom_pos;

(* Container Pos 4 & Elevator Empty *)
GVL_IO.di.ind_container_in_pos_4 := GVL_IO_RAW.di.ind_container_in_pos_4;
GVL_IO.di.spare_ix6_5 := GVL_IO_RAW.di.spare_ix6_5;
GVL_IO.di.ind_elevator_emptied := GVL_IO_RAW.di.ind_elevator_emptied;

(* Containers Pos 5, 6, 7 *)
GVL_IO.di.ind_container_in_pos_5 := GVL_IO_RAW.di.ind_container_in_pos_5;
GVL_IO.di.ind_container_in_pos_6 := GVL_IO_RAW.di.ind_container_in_pos_6;
GVL_IO.di.ind_container_in_pos_7 := GVL_IO_RAW.di.ind_container_in_pos_7;
GVL_IO.di.spare_ix7_2 := GVL_IO_RAW.di.spare_ix7_2;
GVL_IO.di.spare_ix7_3 := GVL_IO_RAW.di.spare_ix7_3;

(* M8 & Spacers *)
GVL_IO.di.ind_M8_fwd := GVL_IO_RAW.di.ind_M8_fwd;
GVL_IO.di.ind_M8_bwd := GVL_IO_RAW.di.ind_M8_bwd;
GVL_IO.di.ind_low_level_of_spacers := GVL_IO_RAW.di.ind_low_level_of_spacers;
GVL_IO.di.ind_spacer_storage_empty := GVL_IO_RAW.di.ind_spacer_storage_empty;

GVL_IO.di.spare_ix8_0 := GVL_IO_RAW.di.spare_ix8_0;
GVL_IO.di.spare_ix8_1 := GVL_IO_RAW.di.spare_ix8_1;

(* Buttons *)
GVL_IO.di.ind_button_open_close_spacer_storage := GVL_IO_RAW.di.ind_button_open_close_spacer_storage;
GVL_IO.di.ind_button_open_close_robot_cell_doors := GVL_IO_RAW.di.ind_button_open_close_robot_cell_doors;
GVL_IO.di.ind_button_samples := GVL_IO_RAW.di.ind_button_samples;
GVL_IO.di.ind_button_continue_process := GVL_IO_RAW.di.ind_button_continue_process;
GVL_IO.di.ind_button_start_process := GVL_IO_RAW.di.ind_button_start_process;
GVL_IO.di.ind_button_container_ready := GVL_IO_RAW.di.ind_button_container_ready;

GVL_IO.di.ind_button_start_emptying_process := GVL_IO_RAW.di.ind_button_start_emptying_process;

(* Safety & Status *)
GVL_IO.di.ind_low_pressure := GVL_IO_RAW.di.ind_low_pressure;
GVL_IO.di.ind_robot_cell_doors_locked := GVL_IO_RAW.di.ind_robot_cell_doors_locked;
GVL_IO.di.ind_robot_cell_doors_error := GVL_IO_RAW.di.ind_robot_cell_doors_error;

GVL_IO.di.ind_spacer_storage_robot_side_doors_opening_permission := GVL_IO_RAW.di.ind_spacer_storage_robot_side_doors_opening_permission;
GVL_IO.di.ind_spacer_storage_operator_side_doors_opening_permission := GVL_IO_RAW.di.ind_spacer_storage_operator_side_doors_opening_permission;

GVL_IO.di.ind_robot_gripper_vacuum_ok := GVL_IO_RAW.di.ind_robot_gripper_vacuum_ok;
GVL_IO.di.spare_ix9_7 := GVL_IO_RAW.di.spare_ix9_7;

// --- ATV320 ---
// Status główny pobiera FB_Elevator z Control_ATV; częstotliwość zostaje diagnostyczna.
GVL_IO.di.ATV320_stsWord := GVL_IO_RAW.di.ATV320_stsWord_ETA3201;
GVL_IO.di.ATV320_currentFreq := GVL_IO_RAW.di.ATV320_currentFrequency_RFR3202;
GVL_IO.di.ATV320_axisExcess := GVL_IO_RAW.di.ATV320_axisExcessError_L4D4004;

(* Robot FANUC - DOUT -> PLC *)
GVL_Robot.robotIn.sts_auto_mode := GVL_Robot.raw_do_1_auto_mode;
GVL_Robot.robotIn.sts_t1_mode := GVL_Robot.raw_do_2_t1_mode;
GVL_Robot.robotIn.sts_t2_mode := GVL_Robot.raw_do_3_t2_mode;
GVL_Robot.robotIn.sts_estop := GVL_Robot.raw_do_4_estop;
GVL_Robot.robotIn.sts_input_simulated := GVL_Robot.raw_do_5_input_simulated;
GVL_Robot.robotIn.sts_output_simulated := GVL_Robot.raw_do_6_output_simulated;
GVL_Robot.robotIn.sts_in_home_pos := GVL_Robot.raw_do_7_in_home_pos;
GVL_Robot.robotIn.sts_system_ready := GVL_Robot.raw_do_8_system_ready;
GVL_Robot.robotIn.sts_prg_running := GVL_Robot.raw_do_9_prg_running;
GVL_Robot.robotIn.sts_fault := GVL_Robot.raw_do_10_fault;
GVL_Robot.robotIn.sts_tp_enabled := GVL_Robot.raw_do_11_tp_enabled;
GVL_Robot.robotIn.sts_current_prg_box := GVL_Robot.raw_do_12_current_prg_box;
GVL_Robot.robotIn.sts_current_prg_tray := GVL_Robot.raw_do_13_current_prg_tray;
GVL_Robot.robotIn.sts_cmd_ack := GVL_Robot.raw_do_14_cmd_ack;
GVL_Robot.robotIn.sts_pallet_finished := GVL_Robot.raw_do_15_pallet_finished;
GVL_Robot.robotIn.sts_samples_placed := GVL_Robot.raw_do_16_samples_placed;
GVL_Robot.robotIn.sts_pallet_full := GVL_Robot.raw_do_17_pallet_full;
GVL_Robot.robotIn.sts_stack_finished := GVL_Robot.raw_do_18_stack_finished;
GVL_Robot.robotIn.perm_elevator_clear := GVL_Robot.raw_do_19_elevator_clear;
GVL_Robot.robotIn.perm_storage_clear := GVL_Robot.raw_do_20_storage_clear;
GVL_Robot.robotIn.ack_cmd_continue := GVL_Robot.raw_do_21_ack_continue;
GVL_Robot.robotIn.req_storage_access := GVL_Robot.raw_do_22_req_storage_access;
GVL_Robot.robotIn.box_progress := GVL_Robot.raw_do_23_box_progress;
GVL_Robot.robotIn.spare_do_24 := GVL_Robot.raw_do_24_spare;
GVL_Robot.robotIn.spare_do_25 := GVL_Robot.raw_do_25_spare;
GVL_Robot.robotIn.spare_do_26 := GVL_Robot.raw_do_26_spare;
GVL_Robot.robotIn.spare_do_27 := GVL_Robot.raw_do_27_spare;
GVL_Robot.robotIn.spare_do_28 := GVL_Robot.raw_do_28_spare;
GVL_Robot.robotIn.spare_do_29 := GVL_Robot.raw_do_29_spare;
GVL_Robot.robotIn.spare_do_30 := GVL_Robot.raw_do_30_spare;
GVL_Robot.robotIn.cmd_vacuum_5 := GVL_Robot.raw_do_31_vacuum_5;
GVL_Robot.robotIn.cmd_blow_off_5 := GVL_Robot.raw_do_32_blow_off_5;
