PROGRAM PRG_Main
VAR
 station : FB_StationController;
 hmiRuntime : ST_RobotHmiV2;
 vijeoRead : FB_VijeoRead;
 vijeoPublish : FB_VijeoPublish;
 driveAdapter : FB_ElevatorDriveAdapter;
 cfg : ST_StationCfg;
 inp : ST_StationInputs;
 festoImageValid : BOOL;
 festoValid : ARRAY[1..12] OF BOOL;
 moduleIndex : INT;
 cylinderIndex : INT;
 startInputArmed : BOOL;
END_VAR
PRG_IO_Read();
cfg.robot_Cfg := GVL_Robot.Cfg;
cfg.robot_stationIoBound := GVL_Robot.stationIoBound AND GVL_Station.LocalIoHealthy;
cfg.robot_stationCoilPolicyVerified := GVL_Robot.stationCoilPolicyVerified;
cfg.robot_stationCoilLossPolicy := GVL_Robot.stationCoilLossPolicy;
cfg.station_IoCfg := GVL_Station.IoCfg;
cfg.station_AlarmCfg := GVL_Station.AlarmCfg;
cfg.station_ParameterCfg := GVL_Station.ParameterCfg;
cfg.station_ElevatorCfg := GVL_Station.ElevatorCfg;
cfg.station_ElevatorCfgVerified := GVL_Station.ElevatorCfgVerified;
cfg.station_LocalFaultPolicyVerified := GVL_Station.LocalFaultPolicyVerified;
cfg.station_LocalFaultPolicy := GVL_Station.LocalFaultPolicy;
cfg.station_ManualReleaseVerified := GVL_Station.ManualReleaseVerified;
cfg.station_ManualRelease := GVL_Station.ManualRelease;
inp.robot_ScannerHealthy := GVL_Robot.ScannerHealthy;
inp.robot_ImageFresh := GVL_Robot.ImageFresh;
inp.robot_Plant := GVL_Robot.Plant;
inp.robot_Plant.physicalStop := inp.robot_Plant.physicalStop OR NOT GVL_Station.PhysicalStopValid;
inp.robot_Plant.processOK := inp.robot_Plant.processOK AND GVL_Station.PhysicalStopValid;
inp.robot_Rx := GVL_Robot.Rx;
inp.robot_storageIn := GVL_Robot.storageIn;
inp.robot_vfdCommHealthy := GVL_Robot.vfdCommHealthy;
inp.station_Inputs := GVL_Station.Inputs;
inp.station_AlarmInputs := GVL_Station.AlarmInputs;
inp.station_DiagnosticValue := GVL_Station.DiagnosticValue;
inp.station_DiagnosticValid := GVL_Station.DiagnosticValid;
inp.station_ManualInterlocks := GVL_Station.ManualInterlocks;
inp.io_di := GVL_IO.di;

(* Diagnostyka modułów pochodzi z adaptera natywnego. Indeksy według tabeli BAT. *)
festoImageValid := inp.station_Inputs.mappingVerified AND inp.station_Inputs.gatewayHealthy AND
 inp.station_Inputs.imageFresh;
FOR moduleIndex := 1 TO 12 DO
 festoValid[moduleIndex] := festoImageValid AND inp.station_Inputs.moduleHealthy[moduleIndex];
END_FOR;
// BAT201–BAT205 i BAT301 zasilają automat transportu.
FOR moduleIndex := 4 TO 8 DO
 cfg.station_IoCfg.required[moduleIndex] := TRUE;
END_FOR;
cfg.station_IoCfg.required[10] := TRUE;
cfg.station_IoCfg.required[12] := FALSE; // Fizycznie brak osobnego BAT401.

(* B205/P4 nadal pochodzi z jawnego wiązania GVL_Station.Inputs. *)
inp.station_Inputs.occupied[1] := inp.io_di.ind_container_in_pos_1;
inp.station_Inputs.positionValid[1] := festoValid[6];
inp.station_Inputs.occupied[2] := inp.io_di.ind_container_in_pos_2;
inp.station_Inputs.positionValid[2] := festoValid[6];
inp.station_Inputs.occupied[3] := inp.io_di.ind_container_in_pos_3;
inp.station_Inputs.positionValid[3] := festoValid[6];
inp.station_Inputs.occupied[5] := inp.io_di.ind_container_in_pos_5;
inp.station_Inputs.positionValid[5] := festoValid[8];
inp.station_Inputs.occupied[6] := inp.io_di.ind_container_in_pos_6;
inp.station_Inputs.positionValid[6] := festoValid[8];
inp.station_Inputs.occupied[7] := inp.io_di.ind_container_in_pos_7;
inp.station_Inputs.positionValid[7] := festoValid[8];

(* ST.2: BAT301, V201/V202. *)
inp.station_Inputs.v201.IsRet := inp.io_di.ind_M6_1_bwd;
inp.station_Inputs.v201.IsExt := inp.io_di.ind_M6_1_fwd;
inp.station_Inputs.v201.valid := festoValid[10];
inp.station_Inputs.v202.IsRet := inp.io_di.ind_M6_2_bwd;
inp.station_Inputs.v202.IsExt := inp.io_di.ind_M6_2_fwd;
inp.station_Inputs.v202.valid := festoValid[10];

(* ST.3: BAT204 (stopery), BAT205 (czujniki). B301 = zajętość dla sekwencji. *)
inp.station_Inputs.lowerStop := inp.io_di.lowerStop;
inp.station_Inputs.lowerFeedbackValid := festoValid[7];
inp.station_Inputs.b301Valid := festoValid[8] AND GVL_Station.B301PolarityVerified;
inp.io_di.ind_elevator_emptied := inp.station_Inputs.b301Valid AND
 (inp.io_di.ind_B301_raw = GVL_Station.B301HighWhenOccupied);

(* ST.4: BAT101 i zezwolenia z KEB1. Parametry i polityki pochodzą z GVL_Robot.storageIn. *)
inp.robot_storageIn.Left.valid := inp.robot_storageIn.Left.configured AND festoValid[2];
inp.robot_storageIn.Left.atHome := festoValid[2] AND inp.io_di.ind_V401_home;
inp.robot_storageIn.Left.atWork := festoValid[2] AND inp.io_di.ind_V401_work;
inp.robot_storageIn.Right.valid := inp.robot_storageIn.Right.configured AND festoValid[2];
inp.robot_storageIn.Right.atHome := festoValid[2] AND inp.io_di.ind_V402_home;
inp.robot_storageIn.Right.atWork := festoValid[2] AND inp.io_di.ind_V402_work;
inp.robot_storageIn.LowLevel := festoValid[2] AND inp.io_di.ind_low_level_of_spacers;
inp.robot_storageIn.Empty := festoValid[2] AND inp.io_di.ind_spacer_storage_empty;
inp.robot_storageIn.BtnOpenClose := cfg.robot_stationIoBound AND inp.io_di.ind_button_open_close_spacer_storage;
inp.robot_storageIn.RobotSideOpeningPermission := cfg.robot_stationIoBound AND
 inp.io_di.ind_spacer_storage_robot_side_doors_opening_permission;
inp.robot_storageIn.OperatorSideOpeningPermission := cfg.robot_stationIoBound AND
 inp.io_di.ind_spacer_storage_operator_side_doors_opening_permission;

(* ST.5: AP16 w BAT400 oraz KEC3. Polityki i dopuszczenia zachowują dotychczasowe źródło. *)
inp.robot_Plant.cylinders[1].valid := festoValid[11];
inp.robot_Plant.cylinders[1].atHome := festoValid[11] AND inp.io_di.ind_axis_7_home;
inp.robot_Plant.cylinders[1].atWork := festoValid[11] AND inp.io_di.ind_axis_7_work;
FOR cylinderIndex := 2 TO 5 DO
 inp.robot_Plant.cylinders[cylinderIndex].valid := cfg.robot_stationIoBound;
 inp.robot_Plant.cylinders[cylinderIndex].atHome := cfg.robot_stationIoBound AND inp.io_di.gripperHome[cylinderIndex];
 inp.robot_Plant.cylinders[cylinderIndex].atWork := cfg.robot_stationIoBound AND inp.io_di.gripperWork[cylinderIndex];
END_FOR;

(* EUROMAP 67: potwierdzenia fizyczne. GAP-05 nadal ocenia ważność cyklu i zezwoleń. *)
inp.robot_Plant.imm.valid := inp.robot_Plant.imm.valid AND cfg.robot_stationIoBound;
inp.robot_Plant.imm.reject := cfg.robot_stationIoBound AND inp.io_di.ind_e67_imm_reject;
inp.robot_Plant.imm.mouldClosed := cfg.robot_stationIoBound AND inp.io_di.ind_e67_imm_mould_closed;
inp.robot_Plant.imm.mouldOpen := cfg.robot_stationIoBound AND inp.io_di.ind_e67_imm_mould_open;
inp.robot_Plant.imm.mouldIntermediate := cfg.robot_stationIoBound AND inp.io_di.ind_e67_imm_mould_in_intermediate_position;
inp.robot_Plant.imm.withRobot := cfg.robot_stationIoBound AND inp.io_di.ind_e67_imm_operation_with_robot_enabled;
inp.robot_Plant.imm.ejectorBack := cfg.robot_stationIoBound AND inp.io_di.ind_e67_imm_ejector_in_back_position;
inp.robot_Plant.imm.ejectorForward := cfg.robot_stationIoBound AND inp.io_di.ind_e67_imm_ejector_in_forward_position;

(* Diagnostyka HMI z tej samej próbki wejść. *)
inp.station_DiagnosticValue.ind_loading_elevator_1_left_in_home_position := inp.io_di.ind_M2_1_bwd;
inp.station_DiagnosticValid.ind_loading_elevator_1_left_in_home_position := festoValid[4];
inp.station_DiagnosticValue.ind_loading_elevator_1_left_in_work_position := inp.io_di.ind_M2_1_fwd;
inp.station_DiagnosticValid.ind_loading_elevator_1_left_in_work_position := festoValid[4];
inp.station_DiagnosticValue.ind_loading_elevator_1_right_in_home_position := inp.io_di.ind_M2_2_bwd;
inp.station_DiagnosticValid.ind_loading_elevator_1_right_in_home_position := festoValid[4];
inp.station_DiagnosticValue.ind_loading_elevator_1_right_in_work_position := inp.io_di.ind_M2_2_fwd;
inp.station_DiagnosticValid.ind_loading_elevator_1_right_in_work_position := festoValid[4];
inp.station_DiagnosticValue.ind_loading_elevator_2_left_in_home_position := inp.io_di.ind_M3_1_bwd;
inp.station_DiagnosticValid.ind_loading_elevator_2_left_in_home_position := festoValid[4];
inp.station_DiagnosticValue.ind_loading_elevator_2_left_in_work_position := inp.io_di.ind_M3_1_fwd;
inp.station_DiagnosticValid.ind_loading_elevator_2_left_in_work_position := festoValid[4];
inp.station_DiagnosticValue.ind_loading_elevator_2_right_in_home_position := inp.io_di.ind_M3_2_bwd;
inp.station_DiagnosticValid.ind_loading_elevator_2_right_in_home_position := festoValid[4];
inp.station_DiagnosticValue.ind_loading_elevator_2_right_in_work_position := inp.io_di.ind_M3_2_fwd;
inp.station_DiagnosticValid.ind_loading_elevator_2_right_in_work_position := festoValid[4];
inp.station_DiagnosticValue.ind_loading_elevator_3_left_in_home_position := inp.io_di.ind_M4_1_bwd;
inp.station_DiagnosticValid.ind_loading_elevator_3_left_in_home_position := festoValid[5];
inp.station_DiagnosticValue.ind_loading_elevator_3_left_in_work_position := inp.io_di.ind_M4_1_fwd;
inp.station_DiagnosticValid.ind_loading_elevator_3_left_in_work_position := festoValid[5];
inp.station_DiagnosticValue.ind_loading_elevator_3_right_in_home_position := inp.io_di.ind_M4_2_bwd;
inp.station_DiagnosticValid.ind_loading_elevator_3_right_in_home_position := festoValid[5];
inp.station_DiagnosticValue.ind_loading_elevator_3_right_in_work_position := inp.io_di.ind_M4_2_fwd;
inp.station_DiagnosticValid.ind_loading_elevator_3_right_in_work_position := festoValid[5];
inp.station_DiagnosticValue.ind_loading_stopper_1_left_in_home_position := inp.io_di.ind_M1_1_bwd;
inp.station_DiagnosticValid.ind_loading_stopper_1_left_in_home_position := festoValid[5];
inp.station_DiagnosticValue.ind_loading_stopper_1_left_in_work_position := inp.io_di.ind_M1_1_fwd;
inp.station_DiagnosticValid.ind_loading_stopper_1_left_in_work_position := festoValid[5];
inp.station_DiagnosticValue.ind_loading_stopper_1_right_in_home_position := inp.io_di.ind_M1_2_bwd;
inp.station_DiagnosticValid.ind_loading_stopper_1_right_in_home_position := festoValid[5];
inp.station_DiagnosticValue.ind_loading_stopper_1_right_in_work_position := inp.io_di.ind_M1_2_fwd;
inp.station_DiagnosticValid.ind_loading_stopper_1_right_in_work_position := festoValid[5];
inp.station_DiagnosticValue.ind_loading_stopper_2_left_in_home_position := inp.io_di.ind_M5_1_bwd;
inp.station_DiagnosticValid.ind_loading_stopper_2_left_in_home_position := festoValid[6];
inp.station_DiagnosticValue.ind_loading_stopper_2_left_in_work_position := inp.io_di.ind_M5_1_fwd;
inp.station_DiagnosticValid.ind_loading_stopper_2_left_in_work_position := festoValid[6];
inp.station_DiagnosticValue.ind_loading_stopper_2_right_in_home_position := inp.io_di.ind_M5_2_bwd;
inp.station_DiagnosticValid.ind_loading_stopper_2_right_in_home_position := festoValid[6];
inp.station_DiagnosticValue.ind_loading_stopper_2_right_in_work_position := inp.io_di.ind_M5_2_fwd;
inp.station_DiagnosticValid.ind_loading_stopper_2_right_in_work_position := festoValid[6];
inp.station_DiagnosticValue.ind_container_in_loading_position_1 := inp.station_Inputs.occupied[1];
inp.station_DiagnosticValid.ind_container_in_loading_position_1 := festoValid[6];
inp.station_DiagnosticValue.ind_container_in_loading_position_2 := inp.station_Inputs.occupied[2];
inp.station_DiagnosticValid.ind_container_in_loading_position_2 := festoValid[6];
inp.station_DiagnosticValue.ind_container_in_loading_position_3 := inp.station_Inputs.occupied[3];
inp.station_DiagnosticValid.ind_container_in_loading_position_3 := festoValid[6];
inp.station_DiagnosticValue.ind_container_in_unloading_position_1 := inp.station_Inputs.occupied[5];
inp.station_DiagnosticValid.ind_container_in_unloading_position_1 := festoValid[8];
inp.station_DiagnosticValue.ind_container_in_unloading_position_2 := inp.station_Inputs.occupied[6];
inp.station_DiagnosticValid.ind_container_in_unloading_position_2 := festoValid[8];
inp.station_DiagnosticValue.ind_container_in_unloading_position_3 := inp.station_Inputs.occupied[7];
inp.station_DiagnosticValid.ind_container_in_unloading_position_3 := festoValid[8];
inp.station_DiagnosticValue.ind_blister_positioner_left_in_home_position := inp.io_di.ind_M6_1_bwd;
inp.station_DiagnosticValid.ind_blister_positioner_left_in_home_position := festoValid[10];
inp.station_DiagnosticValue.ind_blister_positioner_left_in_work_position := inp.io_di.ind_M6_1_fwd;
inp.station_DiagnosticValid.ind_blister_positioner_left_in_work_position := festoValid[10];
inp.station_DiagnosticValue.ind_blister_positioner_right_in_home_position := inp.io_di.ind_M6_2_bwd;
inp.station_DiagnosticValid.ind_blister_positioner_right_in_home_position := festoValid[10];
inp.station_DiagnosticValue.ind_blister_positioner_right_in_work_position := inp.io_di.ind_M6_2_fwd;
inp.station_DiagnosticValid.ind_blister_positioner_right_in_work_position := festoValid[10];
inp.station_DiagnosticValue.ind_blue_box_positioner_left_in_home_position := inp.io_di.ind_M7_bwd;
inp.station_DiagnosticValid.ind_blue_box_positioner_left_in_home_position := festoValid[10];
inp.station_DiagnosticValue.ind_blue_box_positioner_left_in_work_position := inp.io_di.ind_M7_fwd;
inp.station_DiagnosticValid.ind_blue_box_positioner_left_in_work_position := festoValid[10];
inp.station_DiagnosticValue.ind_elevator_in_top_position := inp.io_di.ind_elevator_in_top_pos;
inp.station_DiagnosticValid.ind_elevator_in_top_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_elevator_in_intermediate_top_position := inp.io_di.ind_elevator_in_intermediate_top_pos;
inp.station_DiagnosticValid.ind_elevator_in_intermediate_top_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_elevator_in_intermediate_bottom_position := inp.io_di.ind_elevator_in_intermediate_bottom_pos;
inp.station_DiagnosticValid.ind_elevator_in_intermediate_bottom_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_elevator_in_bottom_position := inp.io_di.ind_elevator_in_bottom_pos;
inp.station_DiagnosticValid.ind_elevator_in_bottom_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_container_in_elevator_position := inp.station_Inputs.occupied[4];
inp.station_DiagnosticValid.ind_container_in_elevator_position := inp.station_Inputs.positionValid[4];
inp.station_DiagnosticValue.ind_unloading_stopper_1_left_in_home_position := inp.io_di.lowerStop[1].ind_1_bwd;
inp.station_DiagnosticValid.ind_unloading_stopper_1_left_in_home_position := festoValid[7];
inp.station_DiagnosticValue.ind_unloading_stopper_1_left_in_work_position := inp.io_di.lowerStop[1].ind_1_fwd;
inp.station_DiagnosticValid.ind_unloading_stopper_1_left_in_work_position := festoValid[7];
inp.station_DiagnosticValue.ind_unloading_stopper_1_right_in_home_position := inp.io_di.lowerStop[1].ind_2_bwd;
inp.station_DiagnosticValid.ind_unloading_stopper_1_right_in_home_position := festoValid[7];
inp.station_DiagnosticValue.ind_unloading_stopper_1_right_in_work_position := inp.io_di.lowerStop[1].ind_2_fwd;
inp.station_DiagnosticValid.ind_unloading_stopper_1_right_in_work_position := festoValid[7];
inp.station_DiagnosticValue.ind_unloading_stopper_2_left_in_home_position := inp.io_di.lowerStop[2].ind_1_bwd;
inp.station_DiagnosticValid.ind_unloading_stopper_2_left_in_home_position := festoValid[7];
inp.station_DiagnosticValue.ind_unloading_stopper_2_left_in_work_position := inp.io_di.lowerStop[2].ind_1_fwd;
inp.station_DiagnosticValid.ind_unloading_stopper_2_left_in_work_position := festoValid[7];
inp.station_DiagnosticValue.ind_unloading_stopper_2_right_in_home_position := inp.io_di.lowerStop[2].ind_2_bwd;
inp.station_DiagnosticValid.ind_unloading_stopper_2_right_in_home_position := festoValid[7];
inp.station_DiagnosticValue.ind_unloading_stopper_2_right_in_work_position := inp.io_di.lowerStop[2].ind_2_fwd;
inp.station_DiagnosticValid.ind_unloading_stopper_2_right_in_work_position := festoValid[7];
inp.station_DiagnosticValue.ind_elevator_unloading_area_empty := inp.station_Inputs.b301Valid AND
 NOT inp.io_di.ind_elevator_emptied;
inp.station_DiagnosticValid.ind_elevator_unloading_area_empty := inp.station_Inputs.b301Valid;
inp.station_DiagnosticValue.ind_spacer_barrier_left_in_home_position := inp.io_di.ind_V401_home;
inp.station_DiagnosticValid.ind_spacer_barrier_left_in_home_position := festoValid[2];
inp.station_DiagnosticValue.ind_spacer_barrier_left_in_work_position := inp.io_di.ind_V401_work;
inp.station_DiagnosticValid.ind_spacer_barrier_left_in_work_position := festoValid[2];
inp.station_DiagnosticValue.ind_spacer_barrier_right_in_home_position := inp.io_di.ind_V402_home;
inp.station_DiagnosticValid.ind_spacer_barrier_right_in_home_position := festoValid[2];
inp.station_DiagnosticValue.ind_spacer_barrier_right_in_work_position := inp.io_di.ind_V402_work;
inp.station_DiagnosticValid.ind_spacer_barrier_right_in_work_position := festoValid[2];
inp.station_DiagnosticValue.ind_low_level_of_spacers := inp.io_di.ind_low_level_of_spacers;
inp.station_DiagnosticValid.ind_low_level_of_spacers := festoValid[2];
inp.station_DiagnosticValue.ind_spacer_storage_empty := inp.io_di.ind_spacer_storage_empty;
inp.station_DiagnosticValid.ind_spacer_storage_empty := festoValid[2];
inp.station_DiagnosticValue.ind_robot_axis_7_in_home_position := inp.io_di.ind_axis_7_home;
inp.station_DiagnosticValid.ind_robot_axis_7_in_home_position := festoValid[11];
inp.station_DiagnosticValue.ind_robot_axis_7_in_work_position := inp.io_di.ind_axis_7_work;
inp.station_DiagnosticValid.ind_robot_axis_7_in_work_position := festoValid[11];
inp.station_DiagnosticValue.ind_robot_gripper_1_in_home_position := inp.io_di.gripperHome[2];
inp.station_DiagnosticValid.ind_robot_gripper_1_in_home_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_robot_gripper_1_in_work_position := inp.io_di.gripperWork[2];
inp.station_DiagnosticValid.ind_robot_gripper_1_in_work_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_robot_gripper_2_in_home_position := inp.io_di.gripperHome[3];
inp.station_DiagnosticValid.ind_robot_gripper_2_in_home_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_robot_gripper_2_in_work_position := inp.io_di.gripperWork[3];
inp.station_DiagnosticValid.ind_robot_gripper_2_in_work_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_robot_gripper_3_in_home_position := inp.io_di.gripperHome[4];
inp.station_DiagnosticValid.ind_robot_gripper_3_in_home_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_robot_gripper_3_in_work_position := inp.io_di.gripperWork[4];
inp.station_DiagnosticValid.ind_robot_gripper_3_in_work_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_robot_gripper_4_in_home_position := inp.io_di.gripperHome[5];
inp.station_DiagnosticValid.ind_robot_gripper_4_in_home_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_robot_gripper_4_in_work_position := inp.io_di.gripperWork[5];
inp.station_DiagnosticValid.ind_robot_gripper_4_in_work_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_e67_imm_reject := inp.io_di.ind_e67_imm_reject;
inp.station_DiagnosticValid.ind_e67_imm_reject := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_e67_imm_mould_closed := inp.io_di.ind_e67_imm_mould_closed;
inp.station_DiagnosticValid.ind_e67_imm_mould_closed := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_e67_imm_mould_open := inp.io_di.ind_e67_imm_mould_open;
inp.station_DiagnosticValid.ind_e67_imm_mould_open := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_e67_imm_mould_in_intermediate_position := inp.io_di.ind_e67_imm_mould_in_intermediate_position;
inp.station_DiagnosticValid.ind_e67_imm_mould_in_intermediate_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_e67_imm_operation_with_robot_enabled := inp.io_di.ind_e67_imm_operation_with_robot_enabled;
inp.station_DiagnosticValid.ind_e67_imm_operation_with_robot_enabled := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_e67_imm_ejector_in_back_position := inp.io_di.ind_e67_imm_ejector_in_back_position;
inp.station_DiagnosticValid.ind_e67_imm_ejector_in_back_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_e67_imm_ejector_in_forward_position := inp.io_di.ind_e67_imm_ejector_in_forward_position;
inp.station_DiagnosticValid.ind_e67_imm_ejector_in_forward_position := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_e67_imm_core_1_in_position_1 := inp.io_di.ind_e67_imm_core_1_in_position_1;
inp.station_DiagnosticValid.ind_e67_imm_core_1_in_position_1 := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_e67_imm_core_1_in_position_2 := inp.io_di.ind_e67_imm_core_1_in_position_2;
inp.station_DiagnosticValid.ind_e67_imm_core_1_in_position_2 := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_e67_imm_core_2_in_position_1 := inp.io_di.ind_e67_imm_core_2_in_position_1;
inp.station_DiagnosticValid.ind_e67_imm_core_2_in_position_1 := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_e67_imm_core_2_in_position_2 := inp.io_di.ind_e67_imm_core_2_in_position_2;
inp.station_DiagnosticValid.ind_e67_imm_core_2_in_position_2 := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_button_open_close_spacer_storage := inp.io_di.ind_button_open_close_spacer_storage;
inp.station_DiagnosticValid.ind_button_open_close_spacer_storage := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_button_open_close_robot_cell_doors := inp.io_di.ind_button_open_close_robot_cell_doors;
inp.station_DiagnosticValid.ind_button_open_close_robot_cell_doors := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_button_samples := inp.io_di.ind_button_samples;
inp.station_DiagnosticValid.ind_button_samples := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_button_continue_process := inp.io_di.ind_button_continue_process;
inp.station_DiagnosticValid.ind_button_continue_process := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_button_start_process := inp.io_di.ind_button_start_process;
inp.station_DiagnosticValid.ind_button_start_process := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_button_container_ready := inp.io_di.ind_button_container_ready;
inp.station_DiagnosticValid.ind_button_container_ready := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_button_start_emptying_process := inp.io_di.ind_button_start_emptying_process;
inp.station_DiagnosticValid.ind_button_start_emptying_process := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_robot_cell_doors_closed := inp.io_di.ind_robot_cell_doors_closed;
inp.station_DiagnosticValid.ind_robot_cell_doors_closed := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_robot_cell_doors_locked := inp.io_di.ind_robot_cell_doors_locked;
inp.station_DiagnosticValid.ind_robot_cell_doors_locked := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_spacer_storage_robot_side_doors_opening_permission := inp.io_di.ind_spacer_storage_robot_side_doors_opening_permission;
inp.station_DiagnosticValid.ind_spacer_storage_robot_side_doors_opening_permission := cfg.robot_stationIoBound;
inp.station_DiagnosticValue.ind_spacer_storage_operator_side_doors_opening_permission := inp.io_di.ind_spacer_storage_operator_side_doors_opening_permission;
inp.station_DiagnosticValid.ind_spacer_storage_operator_side_doors_opening_permission := cfg.robot_stationIoBound;

(* Start przytrzymany podczas utraty ważności wymaga zwolnienia po jej powrocie. *)
IF NOT cfg.robot_stationIoBound OR inp.robot_Plant.physicalStop THEN
 startInputArmed := FALSE;
ELSIF NOT inp.io_di.ind_button_start_process THEN
 startInputArmed := TRUE;
END_IF;
inp.io_di.ind_button_start_process := startInputArmed AND inp.io_di.ind_button_start_process;

inp.drive := driveAdapter.Feedback;
vijeoRead(Hmi := hmiRuntime);
station(Cfg := cfg, Inp := inp, Context := GVL_RobotRetain.Context,
 Proposal := GVL_Robot.Proposal, Hmi := hmiRuntime);
GVL_Robot.Sts := station.Outp.robot_Sts;
GVL_Robot.Tx := station.Outp.robot_Tx;
GVL_Robot.storageOut := station.Outp.robot_storageOut;
GVL_Robot.singleUnloadReady := station.Outp.robot_singleUnloadReady;
GVL_Robot.singleUnloadRequest := station.Outp.robot_singleUnloadRequest;
GVL_Station.Io := station.Outp.station_Io;
GVL_Station.Alarms := station.Outp.station_Alarms;
GVL_Station.Coils := station.Outp.station_Coils;
GVL_Station.LocalRestartRequired := station.Outp.station_LocalRestartRequired;
GVL_Station.Transport := station.Outp.station_Transport;
GVL_Station.DrainStatus := station.Outp.station_DrainStatus;
GVL_Station.Material := station.Outp.station_Material;
GVL_Station.V201Out := station.Outp.station_V201Out;
GVL_Station.V202Out := station.Outp.station_V202Out;
GVL_Station.LowerStopOut := station.Outp.station_LowerStopOut;
GVL_IO.dout := station.Outp.io_dout;
GVL_HMI.hmiStatus := station.Outp.hmi_hmiStatus;
GVL_Robot.Drain := station.Outp.drain;
GVL_Station.ReconcileRequired := station.Outp.reconcileRequired;
driveAdapter(Cmd := station.Outp.drive, MappingVerified := GVL_Station.ElevatorCfgVerified,
 CommHealthy := GVL_Robot.vfdCommHealthy, FrequencyValid := GVL_Station.DriveFrequencyValid,
 ActualHz := INT_TO_REAL(WORD_TO_INT(GVL_IO.di.ATV320_currentFreq)) / 10.0);
vijeoPublish(
    Hmi := hmiRuntime,
    Io := station.Outp.hmi_hmiIo,
    ReloadedStation := station.Outp.hmi_reloadedStation);
PRG_IO_Write();
