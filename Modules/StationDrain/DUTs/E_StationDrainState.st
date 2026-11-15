{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_StationDrainState :
(
    IDLE := 0,
    SELECT_ACTION := 10,
    WAIT_ACTION := 20,
    PAUSED := 40,
    COMPLETE := 100,
    FAULT := 900
);
END_TYPE
