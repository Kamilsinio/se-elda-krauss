(* Kanaly 1 picked,2 placed,3 finished,4 spacer,5 products,6 samples,
   7 layer,8 stack,9 pickup,10 rejects. ACK dopiero po Commit. *)
FUNCTION_BLOCK FB_RobotEvents
VAR_INPUT
    Session : BOOL;
    Reset : BOOL;
    Rx : ARRAY[1..10] OF ST_RobotEvent;
    Commit : ARRAY[1..10] OF BOOL;
    Reject : BOOL;
END_VAR
VAR_OUTPUT
    Pending : ARRAY[1..10] OF BOOL;
    Frozen : ARRAY[1..10] OF ST_RobotEvent;
    Ack : ARRAY[1..10] OF BOOL;
    Idle : BOOL;
    Diag : ST_RobotDiag;
END_VAR
VAR
    i : INT;
    neutralSeen : ARRAY[1..10] OF BOOL;
END_VAR
IF Reset THEN Diag.fault := FALSE; Diag.code := 0; END_IF;
IF Reject THEN
    Diag.fault := TRUE;
    Diag.code := 120;
    Diag.text := 'Niespojny kontekst zdarzenia.';
END_IF;
Idle := TRUE;
FOR i := 1 TO 10 DO
    IF NOT Session THEN
        Ack[i] := FALSE;
        Pending[i] := FALSE;
        neutralSeen[i] := FALSE;
    ELSE
        IF NOT Rx[i].req AND NOT Ack[i] AND NOT Pending[i] THEN neutralSeen[i] := TRUE; END_IF;
        IF (Pending[i] OR Ack[i]) AND
           ((Rx[i].stackId <> Frozen[i].stackId) OR (Rx[i].cycleId <> Frozen[i].cycleId) OR
            (Rx[i].count <> Frozen[i].count) OR (Rx[i].index <> Frozen[i].index)) THEN
            Diag.fault := TRUE;
            Diag.code := 121;
            Diag.text := 'Payload zmieniony przed zakonczeniem REQ/ACK.';
        END_IF;
        IF Pending[i] AND NOT Rx[i].req THEN
            Diag.fault := TRUE;
            Diag.code := 122;
            Diag.text := 'REQ zniknal przed zapisaniem skutku.';
        END_IF;
        IF Pending[i] AND Commit[i] AND NOT Diag.fault THEN
            Pending[i] := FALSE;
            Ack[i] := TRUE;
        END_IF;
        IF Ack[i] AND NOT Rx[i].req THEN
            Ack[i] := FALSE;
            neutralSeen[i] := TRUE;
        ELSIF Rx[i].req AND NOT Ack[i] AND NOT Pending[i] AND neutralSeen[i] AND NOT Diag.fault THEN
            Frozen[i] := Rx[i];
            Pending[i] := TRUE;
            neutralSeen[i] := FALSE;
        END_IF;
    END_IF;
    Idle := Idle AND NOT Rx[i].req AND NOT Pending[i] AND NOT Ack[i];
    Frozen[i].req := Rx[i].req;
END_FOR;
