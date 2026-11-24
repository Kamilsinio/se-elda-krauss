PROGRAM PRG_IO_Read
VAR
    decoder : FB_RobotCodec;
    iEip : INT; // Indeks slowa obrazu EtherNet/IP: 0..39.
END_VAR
(**************************)	
(********* INPUTS *********)	
(**************************)

(* Assembly 100: bajty wejsc CPX-AP-A-8DI-M8-3P wedlug numeru modulu AP.
   Waznosc danych jest oceniana w PRG_Main i FB_StationIo. *)
GVL_Festo.RawDiByModule[2] := GVL_Festo.EipInBytes[0];
GVL_Festo.RawDiByModule[5] := GVL_Festo.EipInBytes[2];
GVL_Festo.RawDiByModule[6] := GVL_Festo.EipInBytes[3];
GVL_Festo.RawDiByModule[7] := GVL_Festo.EipInBytes[4];
GVL_Festo.RawDiByModule[8] := GVL_Festo.EipInBytes[5];
GVL_Festo.RawDiByModule[9] := GVL_Festo.EipInBytes[6];
GVL_Festo.RawDiByModule[13] := GVL_Festo.EipInBytes[9];

(* DI: RAW -> di *)

(* M1 *)
GVL_IO.di.ind_M1_1_fwd := (GVL_Festo.RawDiByModule[6] AND 32) <> 0;
GVL_IO.di.ind_M1_2_fwd := (GVL_Festo.RawDiByModule[6] AND 128) <> 0;
GVL_IO.di.ind_M1_1_bwd := (GVL_Festo.RawDiByModule[6] AND 16) <> 0;
GVL_IO.di.ind_M1_2_bwd := (GVL_Festo.RawDiByModule[6] AND 64) <> 0;

(* M2 *)
GVL_IO.di.ind_M2_1_fwd := (GVL_Festo.RawDiByModule[5] AND 2) <> 0;
GVL_IO.di.ind_M2_2_fwd := (GVL_Festo.RawDiByModule[5] AND 8) <> 0;
GVL_IO.di.ind_M2_1_bwd := (GVL_Festo.RawDiByModule[5] AND 1) <> 0;
GVL_IO.di.ind_M2_2_bwd := (GVL_Festo.RawDiByModule[5] AND 4) <> 0;

(* Containers Pos 1 & 2 *)
GVL_IO.di.ind_container_in_pos_1 := (GVL_Festo.RawDiByModule[7] AND 16) <> 0;
GVL_IO.di.ind_container_in_pos_2 := (GVL_Festo.RawDiByModule[7] AND 32) <> 0;

(* M3 *)
GVL_IO.di.ind_M3_1_fwd := (GVL_Festo.RawDiByModule[5] AND 32) <> 0;
GVL_IO.di.ind_M3_2_fwd := (GVL_Festo.RawDiByModule[5] AND 128) <> 0;
GVL_IO.di.ind_M3_1_bwd := (GVL_Festo.RawDiByModule[5] AND 16) <> 0;
GVL_IO.di.ind_M3_2_bwd := (GVL_Festo.RawDiByModule[5] AND 64) <> 0;

(* M4 & Container Pos 3 *)
GVL_IO.di.ind_M4_1_fwd := (GVL_Festo.RawDiByModule[6] AND 2) <> 0;
GVL_IO.di.ind_M4_2_fwd := (GVL_Festo.RawDiByModule[6] AND 8) <> 0;
GVL_IO.di.ind_M4_1_bwd := (GVL_Festo.RawDiByModule[6] AND 1) <> 0;
GVL_IO.di.ind_M4_2_bwd := (GVL_Festo.RawDiByModule[6] AND 4) <> 0;
GVL_IO.di.ind_container_in_pos_3 := (GVL_Festo.RawDiByModule[7] AND 64) <> 0;

(* M5 *)
GVL_IO.di.ind_M5_1_fwd := (GVL_Festo.RawDiByModule[7] AND 2) <> 0;
GVL_IO.di.ind_M5_2_fwd := (GVL_Festo.RawDiByModule[7] AND 8) <> 0;
GVL_IO.di.ind_M5_1_bwd := (GVL_Festo.RawDiByModule[7] AND 1) <> 0;
GVL_IO.di.ind_M5_2_bwd := (GVL_Festo.RawDiByModule[7] AND 4) <> 0;

(* M6 *)
GVL_IO.di.ind_M6_1_fwd := (GVL_Festo.RawDiByModule[13] AND 2) <> 0;
GVL_IO.di.ind_M6_2_fwd := (GVL_Festo.RawDiByModule[13] AND 8) <> 0;
GVL_IO.di.ind_M6_1_bwd := (GVL_Festo.RawDiByModule[13] AND 1) <> 0;
GVL_IO.di.ind_M6_2_bwd := (GVL_Festo.RawDiByModule[13] AND 4) <> 0;

(* M7 *)
GVL_IO.di.ind_M7_fwd := (GVL_Festo.RawDiByModule[13] AND 32) <> 0;
GVL_IO.di.ind_M7_bwd := (GVL_Festo.RawDiByModule[13] AND 16) <> 0;

(* Elevator *)
GVL_IO.di.ind_elevator_in_top_pos := GVL_IO_RAW.di.ind_elevator_in_top_pos;
GVL_IO.di.ind_elevator_in_intermediate_top_pos := GVL_IO_RAW.di.ind_elevator_in_intermediate_top_pos;
GVL_IO.di.ind_elevator_in_intermediate_bottom_pos := GVL_IO_RAW.di.ind_elevator_in_intermediate_bottom_pos;
GVL_IO.di.ind_elevator_in_bottom_pos := GVL_IO_RAW.di.ind_elevator_in_bottom_pos;

(* B301: stan elektryczny przed sprawdzeniem polaryzacji. *)
GVL_IO.di.ind_B301_raw := (GVL_Festo.RawDiByModule[9] AND 1) <> 0;

(* Containers Pos 5, 6, 7 *)
GVL_IO.di.ind_container_in_pos_5 := (GVL_Festo.RawDiByModule[9] AND 2) <> 0;
GVL_IO.di.ind_container_in_pos_6 := (GVL_Festo.RawDiByModule[9] AND 4) <> 0;
GVL_IO.di.ind_container_in_pos_7 := (GVL_Festo.RawDiByModule[9] AND 8) <> 0;

(* V301–V304: dwie pary dolnych stoperów. *)
GVL_IO.di.lowerStop[1].ind_1_bwd := (GVL_Festo.RawDiByModule[8] AND 1) <> 0;
GVL_IO.di.lowerStop[1].ind_1_fwd := (GVL_Festo.RawDiByModule[8] AND 2) <> 0;
GVL_IO.di.lowerStop[1].ind_2_bwd := (GVL_Festo.RawDiByModule[8] AND 4) <> 0;
GVL_IO.di.lowerStop[1].ind_2_fwd := (GVL_Festo.RawDiByModule[8] AND 8) <> 0;
GVL_IO.di.lowerStop[2].ind_1_bwd := (GVL_Festo.RawDiByModule[8] AND 16) <> 0;
GVL_IO.di.lowerStop[2].ind_1_fwd := (GVL_Festo.RawDiByModule[8] AND 32) <> 0;
GVL_IO.di.lowerStop[2].ind_2_bwd := (GVL_Festo.RawDiByModule[8] AND 64) <> 0;
GVL_IO.di.lowerStop[2].ind_2_fwd := (GVL_Festo.RawDiByModule[8] AND 128) <> 0;

(* V401/V402 i poziomy magazynu przekładek. *)
GVL_IO.di.ind_V401_home := (GVL_Festo.RawDiByModule[2] AND 1) <> 0;
GVL_IO.di.ind_V401_work := (GVL_Festo.RawDiByModule[2] AND 2) <> 0;
GVL_IO.di.ind_V402_home := (GVL_Festo.RawDiByModule[2] AND 4) <> 0;
GVL_IO.di.ind_V402_work := (GVL_Festo.RawDiByModule[2] AND 8) <> 0;
GVL_IO.di.ind_low_level_of_spacers := (GVL_Festo.RawDiByModule[2] AND 16) <> 0;
GVL_IO.di.ind_spacer_storage_empty := (GVL_Festo.RawDiByModule[2] AND 32) <> 0;

(* Buttons *)
GVL_IO.di.ind_button_open_close_spacer_storage := GVL_IO_RAW.di.ind_button_open_close_spacer_storage;
GVL_IO.di.ind_button_open_close_robot_cell_doors := GVL_IO_RAW.di.ind_button_open_close_robot_cell_doors;
GVL_IO.di.ind_button_samples := GVL_IO_RAW.di.ind_button_samples;
GVL_IO.di.ind_button_continue_process := GVL_IO_RAW.di.ind_button_continue_process;
GVL_IO.di.ind_button_start_process := GVL_IO_RAW.di.ind_button_start_process;
GVL_IO.di.ind_button_container_ready := GVL_IO_RAW.di.ind_button_container_ready;

GVL_IO.di.ind_button_start_emptying_process := GVL_IO_RAW.di.ind_button_start_emptying_process;

(* KEB1: stany klamki i zezwolenia magazynu. *)
GVL_IO.di.ind_robot_cell_doors_closed := GVL_IO_RAW.di.ind_robot_cell_doors_closed;
GVL_IO.di.ind_robot_cell_doors_locked := GVL_IO_RAW.di.ind_robot_cell_doors_locked;
GVL_IO.di.ind_spacer_storage_robot_side_doors_opening_permission := GVL_IO_RAW.di.ind_spacer_storage_robot_side_doors_opening_permission;
GVL_IO.di.ind_spacer_storage_operator_side_doors_opening_permission := GVL_IO_RAW.di.ind_spacer_storage_operator_side_doors_opening_permission;

(* V501: AP16, oś prosta = HOME. V502–V505: wejścia KEC3. *)
GVL_IO.di.ind_axis_7_home := (GVL_Festo.EipInBytes[11] AND 1) <> 0;
GVL_IO.di.ind_axis_7_work := (GVL_Festo.EipInBytes[11] AND 2) <> 0;
GVL_IO.di.gripperHome[2] := GVL_IO_RAW.di.ind_gripper_1_home;
GVL_IO.di.gripperWork[2] := GVL_IO_RAW.di.ind_gripper_1_work;
GVL_IO.di.gripperHome[3] := GVL_IO_RAW.di.ind_gripper_2_home;
GVL_IO.di.gripperWork[3] := GVL_IO_RAW.di.ind_gripper_2_work;
GVL_IO.di.gripperHome[4] := GVL_IO_RAW.di.ind_gripper_3_home;
GVL_IO.di.gripperWork[4] := GVL_IO_RAW.di.ind_gripper_3_work;
GVL_IO.di.gripperHome[5] := GVL_IO_RAW.di.ind_gripper_4_home;
GVL_IO.di.gripperWork[5] := GVL_IO_RAW.di.ind_gripper_4_work;

(* KF101–KF111: EUROMAP 67. *)
GVL_IO.di.ind_e67_imm_reject := GVL_IO_RAW.di.ind_e67_imm_reject;
GVL_IO.di.ind_e67_imm_mould_closed := GVL_IO_RAW.di.ind_e67_imm_mould_closed;
GVL_IO.di.ind_e67_imm_mould_open := GVL_IO_RAW.di.ind_e67_imm_mould_open;
GVL_IO.di.ind_e67_imm_mould_in_intermediate_position := GVL_IO_RAW.di.ind_e67_imm_mould_in_intermediate_position;
GVL_IO.di.ind_e67_imm_operation_with_robot_enabled := GVL_IO_RAW.di.ind_e67_imm_operation_with_robot_enabled;
GVL_IO.di.ind_e67_imm_ejector_in_back_position := GVL_IO_RAW.di.ind_e67_imm_ejector_in_back_position;
GVL_IO.di.ind_e67_imm_ejector_in_forward_position := GVL_IO_RAW.di.ind_e67_imm_ejector_in_forward_position;
GVL_IO.di.ind_e67_imm_core_1_in_position_1 := GVL_IO_RAW.di.ind_e67_imm_core_1_in_position_1;
GVL_IO.di.ind_e67_imm_core_1_in_position_2 := GVL_IO_RAW.di.ind_e67_imm_core_1_in_position_2;
GVL_IO.di.ind_e67_imm_core_2_in_position_1 := GVL_IO_RAW.di.ind_e67_imm_core_2_in_position_1;
GVL_IO.di.ind_e67_imm_core_2_in_position_2 := GVL_IO_RAW.di.ind_e67_imm_core_2_in_position_2;

(* Zweryfikowane wiązania symboliczne projektu natywnego. *)
GVL_IO.di.pressureValid := GVL_IO_RAW.di.pressureValid;
GVL_IO.di.ind_low_pressure := GVL_IO_RAW.di.ind_low_pressure;
GVL_IO.di.doorDeviceStatusValid := GVL_IO_RAW.di.doorDeviceStatusValid;
GVL_IO.di.doorDeviceOk := GVL_IO_RAW.di.doorDeviceOk;

// --- ATV320 ---
// Status główny pobiera FB_Elevator z Control_ATV; częstotliwość zostaje diagnostyczna.
GVL_IO.di.ATV320_stsWord := GVL_IO_RAW.di.ATV320_stsWord_ETA3201;
GVL_IO.di.ATV320_currentFreq := GVL_IO_RAW.di.ATV320_currentFrequency_RFR3202;
GVL_IO.di.ATV320_axisExcess := GVL_IO_RAW.di.ATV320_axisExcessError_L4D4004;

(* FANUC -> PLC: 40 WORD ze skanera -> 80 BYTE kodeka v2.
   Little endian: mlodszy bajt slowa pod indeksem parzystym.
   Przepisujemy cala ramke, lacznie z rezerwami; waznosc ocenia diagnostyka linku. *)
FOR iEip := 0 TO 39 DO
    GVL_Robot.RawIn[2 * iEip] :=
        TO_BYTE(WORD_TO_UINT(GVL_Robot.EipInWords[iEip]) AND 255);
    GVL_Robot.RawIn[2 * iEip + 1] :=
        TO_BYTE(SHR(GVL_Robot.EipInWords[iEip], 8));
END_FOR;

decoder(RawIn := GVL_Robot.RawIn);
GVL_Robot.Rx := decoder.Rx;
