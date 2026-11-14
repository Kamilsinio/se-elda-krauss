{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_ConveyorState :
(
    IDLE      := 0,
    RUN_FWD   := 10,
    RUN_BWD   := 20,
    DELAY_FWD := 30,  // czekanie na zwłokę przed startem FWD (po BWD)
    DELAY_BWD := 40,  // czekanie na zwłokę przed startem BWD (po FWD)
    FAULT     := 900
);
END_TYPE
