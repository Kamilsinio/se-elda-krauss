(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotPlant :
STRUCT
(* Wszystkie TRUE wymagaja rzeczywistego zrodla lub jawnej proby offline. *)
    safetyValid : BOOL;
    safetyOK : BOOL;
    processOK : BOOL;
    mappingVerified : BOOL;
    retentionVerified : BOOL;
    contextRestored : BOOL;
    physicalStart : BOOL;
    physicalStop : BOOL;
    sampleButton : BOOL;
    transferBusy : BOOL;
    transfersConfirmedIdle : BOOL;
    manualGripperHandover : BOOL;
    stationEmptyConfirmed : BOOL;
    robotContextConfirmed : BOOL;
    loadsConfirmed : BOOL;
    cyclesConfirmed : BOOL;
    sourceEmptyConfirmed : BOOL;
    critical : BOOL;
    warning : BOOL;
    taskDone : ARRAY[1..10] OF BOOL;
    areas : ARRAY[1..3] OF ST_RobotAreaIn;
    cylinders : ARRAY[1..5] OF ST_RobotCylinderIn;
    vacuum : ARRAY[1..5] OF ST_RobotVacuumIn;
    imm : ST_RobotImmIn;
END_STRUCT
END_TYPE
