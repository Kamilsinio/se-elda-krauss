(* Zrzut zadan panelu przed wykonaniem sterownika stacji. *)
FUNCTION_BLOCK FB_VijeoRead
VAR_IN_OUT
    Hmi : ST_RobotHmiV2;
END_VAR
VAR
    i : INT;
END_VAR
Hmi.link.uiHmiHeartbeat := GVL_HMI.hmiV2.link.uiHmiHeartbeat;
Hmi.link.uiActivePanel := GVL_HMI.hmiV2.link.uiActivePanel;
Hmi.link.xArmReq := GVL_HMI.hmiV2.link.xArmReq;
Hmi.cmd := GVL_HMI.hmiV2.cmd;
Hmi.edit := GVL_HMI.hmiV2.edit;

Hmi.stationManual.sessionId := GVL_HMI.vijeo.stationManual.sessionId;
Hmi.immManual.sessionId := GVL_HMI.vijeo.immManual.sessionId;
Hmi.manual.udiSessionId := GVL_HMI.vijeo.manual.udiSessionId;

FOR i := 1 TO 16 DO
    Hmi.stationManual.positive[i] := GVL_HMI.vijeo.stationManual.positive[i - 1];
    Hmi.stationManual.holdCounter[i] := GVL_HMI.vijeo.stationManual.holdCounter[i - 1];
    Hmi.immManual.negative[i] := FALSE;
END_FOR;
(* Kanal 1 nie ma kierunku wstecznego. *)
Hmi.stationManual.negative[1] := FALSE;
FOR i := 2 TO 16 DO
    Hmi.stationManual.negative[i] := GVL_HMI.vijeo.stationManual.negativeFrom2[i - 2];
END_FOR;

FOR i := 1 TO 4 DO
    Hmi.immManual.positive[i] := GVL_HMI.vijeo.immManual.positive[i - 1];
    Hmi.immManual.holdCounter[i] := GVL_HMI.vijeo.immManual.holdCounter[i - 1];
END_FOR;
FOR i := 5 TO 16 DO
    Hmi.immManual.positive[i] := FALSE;
    Hmi.immManual.holdCounter[i] := 0;
END_FOR;

FOR i := 1 TO 5 DO
    Hmi.manual.cylHome[i] := GVL_HMI.vijeo.manual.cylHome[i - 1];
    Hmi.manual.cylWork[i] := GVL_HMI.vijeo.manual.cylWork[i - 1];
    Hmi.manual.vacValid[i] := GVL_HMI.vijeo.manual.vacValid[i - 1];
    Hmi.manual.vacHold[i] := GVL_HMI.vijeo.manual.vacHold[i - 1];
    Hmi.manual.blowReq[i] := GVL_HMI.vijeo.manual.blowReq[i - 1];
END_FOR;
FOR i := 1 TO 10 DO
    Hmi.manual.holdCounter[i] := GVL_HMI.vijeo.manual.holdCounter[i - 1];
END_FOR;

(* Wczytaj ustala flage verified i rewizje. Pozostale nastawy ST.4
   pozostaja w buforze PLC, z ktorego korzysta walidacja Zastosuj. *)
FOR i := 1 TO 3 DO
    Hmi.stationEdit[i].sensorStableMs := GVL_HMI.vijeo.stationEdit[i - 1].sensorStableMs;
    Hmi.stationEdit[i].stopDelayMs := GVL_HMI.vijeo.stationEdit[i - 1].stopDelayMs;
    Hmi.stationEdit[i].moveTimeoutMs := GVL_HMI.vijeo.stationEdit[i - 1].moveTimeoutMs;
    Hmi.stationEdit[i].actuatorTimeoutMs := GVL_HMI.vijeo.stationEdit[i - 1].actuatorTimeoutMs;
END_FOR;
Hmi.stationEdit[4].sensorStableMs := GVL_HMI.vijeo.storageEdit.sensorStableMs;
Hmi.stationEdit[4].actuatorTimeoutMs := GVL_HMI.vijeo.storageEdit.actuatorTimeoutMs;
Hmi.stationEdit[2].slowHz := GVL_HMI.vijeo.elevatorSpeedEdit.slowHz;
Hmi.stationEdit[2].fastHz := GVL_HMI.vijeo.elevatorSpeedEdit.fastHz;
