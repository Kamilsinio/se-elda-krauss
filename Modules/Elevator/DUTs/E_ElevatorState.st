{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_ElevatorState :
(
  DISABLED    := 0,
  IDLE        := 10,

  MANUAL_UP   := 20,
  MANUAL_DOWN := 21,

  AUTO_UP     := 30,
  AUTO_DOWN   := 31,

  STOPPING    := 40,
  FAULT       := 900
);
END_TYPE
