(* Trzymane sterowanie chwytaka ST05: osobny licznik dla kazdego urzadzenia. *)
FUNCTION_BLOCK FB_RobotManual
VAR_INPUT
    Cmd : ST_RobotManual;
    SessionId : UDINT;
    Armed : BOOL;
    ActivePanel : UINT;
    Permit : BOOL;
    Timeout : TIME;
    BlowAck : ARRAY[1..5] OF BOOL;
END_VAR
VAR_OUTPUT
    CylHome : ARRAY[1..5] OF BOOL;
    CylWork : ARRAY[1..5] OF BOOL;
    VacValid : ARRAY[1..5] OF BOOL;
    VacHold : ARRAY[1..5] OF BOOL;
    BlowReq : ARRAY[1..5] OF BOOL;
END_VAR
VAR
    watchdog : ARRAY[1..10] OF TON;
    lastCounter : ARRAY[1..10] OF UINT;
    neutralSeen : ARRAY[1..10] OF BOOL;
    authorized : ARRAY[1..10] OF BOOL;
    request : ARRAY[1..10] OF BOOL;
    changed : BOOL;
    previousSession : UDINT;
    sessionChanged : BOOL;
    valid : BOOL;
    i : INT;
    blowLatched : ARRAY[1..5] OF BOOL;
    blowHold : ARRAY[1..5] OF BOOL;
    blowValid : ARRAY[1..5] OF BOOL;
END_VAR
sessionChanged := SessionId <> previousSession;
previousSession := SessionId;
valid := Armed AND Permit AND ActivePanel = 115 AND Cmd.udiSessionId = SessionId AND Timeout > T#0ms;
FOR i := 1 TO 5 DO
    request[i] := Cmd.cylHome[i] OR Cmd.cylWork[i];
    request[i + 5] := Cmd.vacValid[i] OR Cmd.blowReq[i];
END_FOR;
FOR i := 1 TO 10 DO
    changed := Cmd.holdCounter[i] <> lastCounter[i];
    lastCounter[i] := Cmd.holdCounter[i];
    watchdog[i](IN := request[i] AND NOT changed, PT := Timeout);
    IF NOT valid OR watchdog[i].Q OR (sessionChanged AND request[i]) THEN
        authorized[i] := FALSE;
        neutralSeen[i] := FALSE;
    ELSIF NOT request[i] THEN
        neutralSeen[i] := TRUE;
        authorized[i] := FALSE;
    ELSIF neutralSeen[i] AND changed THEN
        authorized[i] := TRUE;
    END_IF;
END_FOR;
FOR i := 1 TO 5 DO
    IF NOT valid OR sessionChanged THEN blowLatched[i] := FALSE;
    ELSIF NOT blowLatched[i] AND Cmd.blowReq[i] AND authorized[i + 5] THEN
        blowLatched[i] := TRUE;
        blowHold[i] := Cmd.vacHold[i];
        blowValid[i] := Cmd.vacValid[i];
    ELSIF blowLatched[i] AND BlowAck[i] AND NOT Cmd.blowReq[i] THEN blowLatched[i] := FALSE;
    END_IF;
    CylHome[i] := valid AND authorized[i] AND Cmd.cylHome[i];
    CylWork[i] := valid AND authorized[i] AND Cmd.cylWork[i];
    VacValid[i] := valid AND authorized[i + 5] AND Cmd.vacValid[i];
    VacHold[i] := Cmd.vacHold[i];
    BlowReq[i] := valid AND blowLatched[i];
    IF BlowReq[i] THEN VacValid[i] := blowValid[i]; VacHold[i] := blowHold[i]; END_IF;
END_FOR;
