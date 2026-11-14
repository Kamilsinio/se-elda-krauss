TYPE ST_Bottom567Cfg :
STRUCT
    tMotorStopDelay : TIME := T#300ms; // do korekty po testach
    tStepTimeout    : TIME := T#8s;    // timeout pojedynczego kroku
    tSensorStable   : TIME := T#80ms;  // stabilizacja przy STOP
END_STRUCT
END_TYPE
