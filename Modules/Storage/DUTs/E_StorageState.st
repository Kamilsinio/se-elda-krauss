{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_StorageState :
(
    DISABLED := 0,
    IDLE := 10,
    ROBOT_WAIT_PERMISSION := 20,
    ROBOT_OPENING := 30,
    ROBOT_OPEN := 40,
    ROBOT_CLOSING := 50,
    CLOSING_FOR_OPERATOR := 60,
    OPERATOR_WAIT_PERMISSION := 70,
    OPERATOR_UNLOCKED := 80,
    WAIT_OPERATOR_LOCK := 90,
    FAULT := 900
);
END_TYPE
