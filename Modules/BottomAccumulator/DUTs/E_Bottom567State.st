{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_Bottom567State :
(
    INIT := 0,
    IDLE := 10,
    PRECHECK := 20,
    RUN_STEP := 30,
    WAIT_STOP := 40,
    COMPLETE := 50,
    EMPTY_HOLD := 60,
    EMPTY_RESYNC := 70,
    WAIT_RECEIPT := 80,
    LOCK_STOPS := 90,
    FAULT := 900
);
END_TYPE
