{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_StorageFault :
(
    NONE := 0,
    SENSOR_CONTRADICTION := 10,
    M8_TIMEOUT := 20,
    ROBOT_PERMISSION_TIMEOUT := 30,
    OPERATOR_PERMISSION_TIMEOUT := 40,
    SPACER_EMPTY := 50,
    MANUAL_CMD_CONFLICT := 60
);
END_TYPE
