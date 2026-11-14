TYPE ST_TopFlowCfg :
STRUCT
    // Po zatrzymaniu transportera odczekaj zanim ruszysz stoperami (wyhamowanie taśmy)
    tMotorStopDelay : TIME := T#300ms;

    // Timeout na dojazd stoperów do pozycji (UP/DOWN)
    tStopperTimeout : TIME := T#3s;

    // Timeout na dojazd pojemnika do czujnika docelowego (ruch taśmą)
    tMoveTimeout : TIME := T#20s;

    // Opcjonalnie: minimalny czas “stabilności” czujnika gdy taśma stoi (do inicjalizacji / diagnostyki)
    tSensorStable : TIME := T#80ms;
END_STRUCT
END_TYPE
