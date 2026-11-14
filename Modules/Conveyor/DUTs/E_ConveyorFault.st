{attribute 'qualified_only'}
{attribute 'strict'} 
TYPE E_ConveyorFault :
(
    NONE := 0,
    SIMULTANEOUS_CMD := 10,   // jednoczesna komenda FWD+BWD
    REVERSAL_BLOCKED := 20    // próba zmiany kierunku przed upływem zwłoki
);
END_TYPE
