TYPE ST_GVL_IO_DI_RAW :
STRUCT
    // KEB1: S1–S7, stany klamki i zezwolenia magazynu.
    ind_button_open_close_spacer_storage AT %IX0.0 : BOOL;
    ind_button_open_close_robot_cell_doors AT %IX0.1 : BOOL;
    ind_button_samples AT %IX0.2 : BOOL;
    ind_button_continue_process AT %IX0.3 : BOOL;
    ind_button_start_process AT %IX0.4 : BOOL;
    ind_button_container_ready AT %IX0.5 : BOOL;
    ind_button_start_emptying_process AT %IX0.6 : BOOL;
    ind_robot_cell_doors_closed AT %IX1.0 : BOOL;
    ind_robot_cell_doors_locked AT %IX1.1 : BOOL;
    ind_spacer_storage_robot_side_doors_opening_permission AT %IX1.2 : BOOL;
    ind_spacer_storage_operator_side_doors_opening_permission AT %IX1.3 : BOOL;

    // KEC1: KF101–KF111, wejścia EUROMAP 67.
    ind_e67_imm_reject AT %IX4.1 : BOOL;
    ind_e67_imm_mould_closed AT %IX4.2 : BOOL;
    ind_e67_imm_mould_open AT %IX4.3 : BOOL;
    ind_e67_imm_mould_in_intermediate_position AT %IX4.4 : BOOL;
    ind_e67_imm_operation_with_robot_enabled AT %IX4.5 : BOOL;
    ind_e67_imm_ejector_in_back_position AT %IX4.6 : BOOL;
    ind_e67_imm_ejector_in_forward_position AT %IX4.7 : BOOL;
    ind_e67_imm_core_1_in_position_1 AT %IX5.0 : BOOL;
    ind_e67_imm_core_1_in_position_2 AT %IX5.1 : BOOL;
    ind_e67_imm_core_2_in_position_1 AT %IX5.2 : BOOL;
    ind_e67_imm_core_2_in_position_2 AT %IX5.3 : BOOL;

    // KEC2: B201–B204, pozycje windy.
    ind_elevator_in_top_pos AT %IX7.0 : BOOL;
    ind_elevator_in_intermediate_top_pos AT %IX7.1 : BOOL;
    ind_elevator_in_intermediate_bottom_pos AT %IX7.2 : BOOL;
    ind_elevator_in_bottom_pos AT %IX7.3 : BOOL;

    // KEC3: potwierdzenia HOME/WORK chwytaka V502–V505.
    ind_gripper_1_home AT %IX8.0 : BOOL;
    ind_gripper_1_work AT %IX8.1 : BOOL;
    ind_gripper_2_home AT %IX8.2 : BOOL;
    ind_gripper_2_work AT %IX8.3 : BOOL;
    ind_gripper_3_home AT %IX8.4 : BOOL;
    ind_gripper_3_work AT %IX8.5 : BOOL;
    ind_gripper_4_home AT %IX8.6 : BOOL;
    ind_gripper_4_work AT %IX8.7 : BOOL;

    // Wejścia do powiązania symbolicznego po potwierdzeniu źródła i polaryzacji.
    pressureValid : BOOL;
    ind_low_pressure : BOOL;
    doorDeviceStatusValid : BOOL;
    doorDeviceOk : BOOL;

    // ATV320: wiązania symboliczne z natywnej konfiguracji napędu.
    ATV320_stsWord_ETA3201 : WORD;
    ATV320_currentFrequency_RFR3202 : WORD;
    ATV320_axisExcessError_L4D4004 : WORD;
END_STRUCT
END_TYPE
