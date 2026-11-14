{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_ElevatorTarget :
(
  NONE     := 0,

  posTop     				:= 1,
  posIntermediateTop     	:= 2,
  posIntermediateBottom     := 3,
  posBottom     			:= 4,

  posContainerEdge := 10 // jedź w dół aż xInPos4 = FALSE
);
END_TYPE
