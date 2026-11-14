{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_SafetyDoorState :
(
    DISABLED := 0,
    UNLOCKED := 10,
    LOCKED := 20,
    UNLOCK_REQUEST := 30,
    FAULT := 900
);
END_TYPE
