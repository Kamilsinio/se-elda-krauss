{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_TraySeqFault :
(
    NONE := 0,
    ROBOT_NOT_READY := 10,
    ELEVATOR_FAULT := 20,
    TOP_FLOW_FAULT := 30,
    BOTTOM_FAULT := 40,
    POSITIONER_TIMEOUT := 50,
    ROBOT_TIMEOUT := 60,
    P4_NOT_DETECTED := 65,
    DISCHARGE_TIMEOUT := 70,
    STARTUP_P4_OCCUPIED := 75
);
END_TYPE
