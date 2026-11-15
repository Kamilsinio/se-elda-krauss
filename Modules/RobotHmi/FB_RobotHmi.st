(* Sesja i transakcje HMI v2; bez komendy Start i bez starych obejsc. *)
FUNCTION_BLOCK FB_RobotHmi
VAR_INPUT
    DataValid : BOOL;
    GenerationValid : BOOL;
    Timeout : TIME;
    Complete : BOOL;
    CompleteReason : UINT;
END_VAR
VAR_IN_OUT
    Hmi : ST_RobotHmiV2;
    Context : ST_RobotContext;
END_VAR
VAR_OUTPUT
    Cmd : ST_RobotCommands;
    Pending : BOOL;
    Key : INT;
    StationKey : INT;
    StationSnapshot : ST_StationParameterSet;
    StationRevision : UINT;
END_VAR
VAR
    emptyCmd : ST_RobotCommands;
    req : ARRAY[1..26] OF ST_RobotHmiRequest;
    rsp : ARRAY[1..26] OF ST_RobotHmiResponse;
    lastId : ARRAY[1..26] OF UDINT;
    active : BOOL;
    initialized : BOOL;
    lastHeartbeat : UINT;
    changed : BOOL;
    seen : BOOL;
    armEdge : R_TRIG;
    watchdog : TON;
    neutral : BOOL;
    i : INT;
    newCount : INT;
    selected : INT;
END_VAR
Cmd := emptyCmd;
StationKey := 0;
Hmi.link.uiContractVersion := 4;
Hmi.link.uiPlcHeartbeat := TO_UINT((TO_UDINT(Hmi.link.uiPlcHeartbeat) + 1) MOD 65536);
req[1] := Hmi.cmd.orderOpen;
rsp[1] := Hmi.rsp.orderOpen;
req[2] := Hmi.cmd.orderEnd;
rsp[2] := Hmi.rsp.orderEnd;
req[3] := Hmi.cmd.modeManual;
rsp[3] := Hmi.rsp.modeManual;
req[4] := Hmi.cmd.modeAuto;
rsp[4] := Hmi.rsp.modeAuto;
req[5] := Hmi.cmd.robotEnable;
rsp[5] := Hmi.rsp.robotEnable;
req[6] := Hmi.cmd.robotDisable;
rsp[6] := Hmi.rsp.robotDisable;
req[7] := Hmi.cmd.resetFaults;
rsp[7] := Hmi.rsp.resetFaults;
req[8] := Hmi.cmd.recoveryConfirm;
rsp[8] := Hmi.rsp.recoveryConfirm;
req[9] := Hmi.cmd.newEmptyContext;
rsp[9] := Hmi.rsp.newEmptyContext;
req[10] := Hmi.cmd.station5ParamApply;
rsp[10] := Hmi.rsp.station5ParamApply;
req[11] := Hmi.cmd.samples;
rsp[11] := Hmi.rsp.samples;
req[12] := Hmi.cmd.station1ParamApply;
rsp[12] := Hmi.rsp.station1ParamApply;
req[13] := Hmi.cmd.station2ParamApply;
rsp[13] := Hmi.rsp.station2ParamApply;
req[14] := Hmi.cmd.station3ParamApply;
rsp[14] := Hmi.rsp.station3ParamApply;
req[15] := Hmi.cmd.station4ParamApply;
rsp[15] := Hmi.rsp.station4ParamApply;
req[16] := Hmi.cmd.station1ParamReload;
rsp[16] := Hmi.rsp.station1ParamReload;
req[17] := Hmi.cmd.station2ParamReload;
rsp[17] := Hmi.rsp.station2ParamReload;
req[18] := Hmi.cmd.station3ParamReload;
rsp[18] := Hmi.rsp.station3ParamReload;
req[19] := Hmi.cmd.station4ParamReload;
rsp[19] := Hmi.rsp.station4ParamReload;
req[20] := Hmi.cmd.station5ParamReload;
rsp[20] := Hmi.rsp.station5ParamReload;
req[21] := Hmi.cmd.station1ResetState;
rsp[21] := Hmi.rsp.station1ResetState;
req[22] := Hmi.cmd.station2ResetState;
rsp[22] := Hmi.rsp.station2ResetState;
req[23] := Hmi.cmd.station3ResetState;
rsp[23] := Hmi.rsp.station3ResetState;
req[24] := Hmi.cmd.station4ResetState;
rsp[24] := Hmi.rsp.station4ResetState;
req[25] := Hmi.cmd.station5ResetState;
rsp[25] := Hmi.rsp.station5ResetState;
req[26] := Hmi.cmd.alarmAckAll;
rsp[26] := Hmi.rsp.alarmAckAll;
changed := Hmi.link.uiHmiHeartbeat <> lastHeartbeat;
lastHeartbeat := Hmi.link.uiHmiHeartbeat;
IF changed THEN seen := TRUE; END_IF;
watchdog(IN := NOT changed, PT := Timeout);
armEdge(CLK := Hmi.link.xArmReq);
neutral := TRUE;
FOR i := 1 TO 26 DO
    neutral := neutral AND NOT req[i].xReq AND NOT rsp[i].xAck;
END_FOR;
FOR i := 1 TO 5 DO
    neutral := neutral AND NOT Hmi.manual.cylHome[i] AND NOT Hmi.manual.cylWork[i] AND
        NOT Hmi.manual.vacValid[i] AND NOT Hmi.manual.blowReq[i];
END_FOR;
FOR i := 1 TO 16 DO
 neutral := neutral AND NOT Hmi.stationManual.positive[i] AND NOT Hmi.stationManual.negative[i] AND NOT Hmi.immManual.positive[i] AND NOT Hmi.immManual.negative[i];
END_FOR;
IF NOT initialized THEN
    active := FALSE; Pending := FALSE; initialized := TRUE;
END_IF;
IF NOT DataValid OR NOT GenerationValid OR Timeout <= T#0ms OR watchdog.Q THEN
    active := FALSE; Pending := FALSE;
END_IF;
IF armEdge.Q AND neutral AND seen AND DataValid AND GenerationValid AND NOT watchdog.Q AND Timeout > T#0ms THEN
    IF Context.hmiGeneration < 16#FFFFFFFF THEN
        Context.hmiGeneration := Context.hmiGeneration + 1;
        Hmi.link.udiSessionId := Context.hmiGeneration;
        active := TRUE;
        FOR i := 1 TO 26 DO lastId[i] := 0; END_FOR;
    ELSE active := FALSE;
    END_IF;
END_IF;
IF Pending AND Complete THEN
    rsp[Key].xAck := TRUE;
    rsp[Key].uiResult := 1;
    rsp[Key].uiReason := CompleteReason;
    IF CompleteReason <> 0 THEN rsp[Key].uiResult := 2; END_IF;
    rsp[Key].sReason := '';
    IF CompleteReason <> 0 THEN rsp[Key].sReason := 'Komenda odrzucona: sprawdz blokady lub recovery.'; END_IF;
    Pending := FALSE;
END_IF;
newCount := 0; selected := 0;
FOR i := 1 TO 26 DO
    IF NOT req[i].xReq THEN rsp[i].xAck := FALSE; END_IF;
    IF req[i].xReq AND NOT rsp[i].xAck AND NOT Pending THEN
        newCount := newCount + 1; selected := i;
    END_IF;
END_FOR;
IF newCount > 0 AND NOT Pending THEN
    FOR i := 1 TO 26 DO
        IF req[i].xReq AND NOT rsp[i].xAck THEN
            rsp[i].udiSessionId := req[i].udiSessionId;
            rsp[i].udiRequestId := req[i].udiRequestId;
            rsp[i].uiReason := 0;
            IF NOT active OR req[i].udiSessionId <> Hmi.link.udiSessionId THEN rsp[i].uiReason := 10;
            ELSIF req[i].udiRequestId = 0 OR req[i].udiRequestId <= lastId[i] THEN rsp[i].uiReason := 120;
            ELSIF newCount <> 1 THEN rsp[i].uiReason := 40;
            END_IF;
            IF rsp[i].uiReason <> 0 THEN
                IF active AND req[i].udiSessionId = Hmi.link.udiSessionId AND req[i].udiRequestId > lastId[i] THEN
                    lastId[i] := req[i].udiRequestId;
                END_IF;
                rsp[i].xAck := TRUE; rsp[i].uiResult := 2;
                rsp[i].sReason := 'Nieaktualna, powtorzona lub sprzeczna transakcja.';
            ELSE
                lastId[i] := req[i].udiRequestId;
                Key := i; Pending := TRUE;
                Cmd.program_ := Hmi.edit.uiProgram;
                Cmd.quantity := Hmi.edit.uiBatchCount;
            END_IF;
        END_IF;
    END_FOR;
    IF Pending THEN
        CASE Key OF
            1: Cmd.openOrder := TRUE;
            2: Cmd.endOrder := TRUE;
            3: Cmd.manual := TRUE;
            4: Cmd.automatic := TRUE;
            5: Cmd.robotEnable := TRUE;
            6: Cmd.robotDisable := TRUE;
            7: Cmd.reset := TRUE;
            8: Cmd.recover := TRUE;
            9: Cmd.newEmptyContext := TRUE;
            10: Cmd.applyQuantity := TRUE;
            11: Cmd.samples := TRUE;
            ELSE
                StationKey := Key;
                IF Key >= 12 AND Key <= 15 THEN
                    StationSnapshot := Hmi.stationEdit[Key - 11];
                    StationRevision := Hmi.stationEditRevision[Key - 11];
                END_IF;
        END_CASE;
    END_IF;
END_IF;
Hmi.link.xArmed := active;
Hmi.link.xDataValid := DataValid;
Hmi.link.uiSessionState := 0;
IF active THEN Hmi.link.uiSessionState := 20; END_IF;
Hmi.link.sDiag := '';
IF NOT active THEN Hmi.link.sDiag := 'HMI nieuzbrojone: sprawdz heartbeat, retencje i neutralna nowa sekwencje ARM.'; END_IF;
IF Context.hmiGeneration = 16#FFFFFFFF THEN Hmi.link.sDiag := 'Wyczerpana generacja sesji HMI; wymagane uzgodnienie retencji.'; END_IF;
Hmi.rsp.orderOpen := rsp[1];
Hmi.rsp.orderEnd := rsp[2];
Hmi.rsp.modeManual := rsp[3];
Hmi.rsp.modeAuto := rsp[4];
Hmi.rsp.robotEnable := rsp[5];
Hmi.rsp.robotDisable := rsp[6];
Hmi.rsp.resetFaults := rsp[7];
Hmi.rsp.recoveryConfirm := rsp[8];
Hmi.rsp.newEmptyContext := rsp[9];
Hmi.rsp.station5ParamApply := rsp[10];
Hmi.rsp.samples := rsp[11];

Hmi.rsp.station1ParamApply := rsp[12];
Hmi.rsp.station2ParamApply := rsp[13];
Hmi.rsp.station3ParamApply := rsp[14];
Hmi.rsp.station4ParamApply := rsp[15];
Hmi.rsp.station1ParamReload := rsp[16];
Hmi.rsp.station2ParamReload := rsp[17];
Hmi.rsp.station3ParamReload := rsp[18];
Hmi.rsp.station4ParamReload := rsp[19];
Hmi.rsp.station5ParamReload := rsp[20];
Hmi.rsp.station1ResetState := rsp[21];
Hmi.rsp.station2ResetState := rsp[22];
Hmi.rsp.station3ResetState := rsp[23];
Hmi.rsp.station4ResetState := rsp[24];
Hmi.rsp.station5ResetState := rsp[25];

Hmi.rsp.alarmAckAll := rsp[26];
