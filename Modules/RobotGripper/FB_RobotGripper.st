(* Jedyny wlasciciel komend chwytaka. Polityka zaniku jest dostarczana po GAP-08. *)
FUNCTION_BLOCK FB_RobotGripper
VAR_INPUT
    Cfg : ST_RobotGripperCfg;
    Session : BOOL;
    Permit : BOOL;
    Critical : BOOL;
    Reset : BOOL;
    CylHome : ARRAY[1..5] OF BOOL;
    CylWork : ARRAY[1..5] OF BOOL;
    VacValid : ARRAY[1..5] OF BOOL;
    VacHold : ARRAY[1..5] OF BOOL;
    BlowReq : ARRAY[1..5] OF BOOL;
    CylIn : ARRAY[1..5] OF ST_RobotCylinderIn;
    VacIn : ARRAY[1..5] OF ST_RobotVacuumIn;
END_VAR
VAR_OUTPUT
    Cyl : ARRAY[1..5] OF ST_RobotCylinderOut;
    Vac : ARRAY[1..5] OF ST_RobotVacuumOut;
    Fault : BOOL;
    Neutral : BOOL;
END_VAR
VAR
    i : INT;
    target : ARRAY[1..5] OF UINT;
    previousTarget : ARRAY[1..5] OF UINT;
    directionBlocked : ARRAY[1..5] OF BOOL;
    wasVacuum : ARRAY[1..5] OF BOOL;
    blowState : ARRAY[1..5] OF UINT;
    blowNeutral : ARRAY[1..5] OF BOOL;
    homeStable : ARRAY[1..5] OF TON;
    workStable : ARRAY[1..5] OF TON;
    moveTimer : ARRAY[1..5] OF TON;
    vacTimer : ARRAY[1..5] OF TON;
    blowTimer : ARRAY[1..5] OF TON;
    releaseTimer : ARRAY[1..5] OF TON;
    healthy : BOOL;
    active : BOOL;
END_VAR
IF Reset THEN Fault := FALSE; END_IF;
Neutral := TRUE;
FOR i := 1 TO 5 DO
    IF Reset THEN
        Cyl[i].fault := FALSE; Cyl[i].faultCode := 0;
        Vac[i].fault := FALSE; Vac[i].faultCode := 0;
    END_IF;
    IF CylIn[i].configured AND NOT CylIn[i].valid THEN Cyl[i].fault := TRUE; Cyl[i].faultCode := 50; END_IF;
    IF VacIn[i].configured AND NOT VacIn[i].valid THEN Vac[i].fault := TRUE; Vac[i].faultCode := 50; END_IF;
    IF CylIn[i].lossPolicyVerified AND CylIn[i].lossHome AND CylIn[i].lossWork THEN
        Cyl[i].fault := TRUE; Cyl[i].faultCode := 50;
    END_IF;
    IF Cyl[i].fault OR Vac[i].fault THEN Fault := TRUE; END_IF;
    homeStable[i](IN := CylIn[i].valid AND CylIn[i].atHome AND NOT CylIn[i].atWork, PT := Cfg.stable);
    workStable[i](IN := CylIn[i].valid AND CylIn[i].atWork AND NOT CylIn[i].atHome, PT := Cfg.stable);
    healthy := CylIn[i].configured AND CylIn[i].valid AND CylIn[i].lossPolicyVerified AND
        (Cfg.motionTimeout > T#0ms) AND (Cfg.stable > T#0ms);
    active := healthy AND Session AND Permit AND NOT Critical AND NOT Fault;
    Cyl[i].valid := healthy;
    Cyl[i].atHome := homeStable[i].Q;
    Cyl[i].atWork := workStable[i].Q;
    Cyl[i].acceptedHome := FALSE;
    Cyl[i].acceptedWork := FALSE;
    Cyl[i].reason := 0;
    previousTarget[i] := target[i];
    IF NOT CylHome[i] AND NOT CylWork[i] THEN directionBlocked[i] := FALSE; END_IF;
    IF ((target[i] = 1 OR CylHome[i]) AND NOT CylIn[i].homeAllowed) OR
       ((target[i] = 2 OR CylWork[i]) AND NOT CylIn[i].workAllowed) THEN directionBlocked[i] := TRUE; END_IF;
    IF directionBlocked[i] THEN active := FALSE; END_IF;
    IF NOT Session THEN Cyl[i].reason := 10;
    ELSIF NOT healthy THEN Cyl[i].reason := 50;
    ELSIF NOT Permit OR Critical OR Fault THEN Cyl[i].reason := 30;
    ELSIF directionBlocked[i] THEN Cyl[i].reason := 30;
    ELSIF CylHome[i] AND CylWork[i] THEN Cyl[i].reason := 40;
    ELSIF CylHome[i] THEN
        IF CylIn[i].homeAllowed THEN
            target[i] := 1; Cyl[i].acceptedHome := TRUE;
        ELSE Cyl[i].reason := 30; END_IF;
    ELSIF CylWork[i] THEN
        IF CylIn[i].workAllowed THEN
            target[i] := 2; Cyl[i].acceptedWork := TRUE;
        ELSE Cyl[i].reason := 30; END_IF;
    END_IF;
    IF CylIn[i].atHome AND CylIn[i].atWork THEN
        Cyl[i].reason := 70; Cyl[i].fault := TRUE; Cyl[i].faultCode := 70;
        Cyl[i].valid := FALSE;
        Fault := TRUE;
        active := FALSE;
    END_IF;
    Cyl[i].busy := active AND (((target[i] = 1) AND NOT Cyl[i].atHome) OR
        ((target[i] = 2) AND NOT Cyl[i].atWork));
    moveTimer[i](IN := Cyl[i].busy AND previousTarget[i] = target[i], PT := Cfg.motionTimeout);
    IF moveTimer[i].Q THEN Fault := TRUE; Cyl[i].reason := 60; Cyl[i].fault := TRUE; Cyl[i].faultCode := 60; active := FALSE; END_IF;
    IF active AND Cyl[i].reason = 0 AND target[i] > 0 THEN
        Cyl[i].home := target[i] = 1;
        Cyl[i].work := target[i] = 2;
    ELSIF NOT active THEN
        Cyl[i].acceptedHome := FALSE; Cyl[i].acceptedWork := FALSE;
        target[i] := 0;
        IF CylIn[i].lossPolicyVerified AND NOT (CylIn[i].lossHome AND CylIn[i].lossWork) THEN
            Cyl[i].home := CylIn[i].lossHome;
            Cyl[i].work := CylIn[i].lossWork;
        END_IF;
    END_IF;

    healthy := VacIn[i].configured AND VacIn[i].valid AND VacIn[i].lossPolicyVerified AND
        (Cfg.vacuumTimeout > T#0ms);
    active := healthy AND Session AND Permit AND NOT Critical AND NOT Fault;
    Vac[i].valid := healthy;
    Vac[i].ok := VacIn[i].ok AND healthy;
    Vac[i].accepted := FALSE;
    Vac[i].reason := 0;
    IF NOT active THEN
        Vac[i].reason := 30;
        IF NOT Session THEN Vac[i].reason := 10; END_IF;
        IF NOT healthy THEN Vac[i].reason := 50; END_IF;
        IF Vac[i].hold AND VacIn[i].lossPolicyVerified AND NOT VacIn[i].holdOnLoss THEN
            Fault := TRUE; Vac[i].fault := TRUE; Vac[i].faultCode := 50;
        END_IF;
        (* Brak podtrzymania w polityce nie uprawnia do automatycznego zrzutu ladunku. *)
        Vac[i].blow := FALSE;
        IF NOT Session OR Critical OR blowState[i] <> 20 THEN
            blowState[i] := 0;
            blowNeutral[i] := FALSE;
            Vac[i].blowAck := FALSE;
            Vac[i].blowResult := 0;
        ELSIF NOT BlowReq[i] THEN
            blowState[i] := 0;
            Vac[i].blowAck := FALSE;
        END_IF;
    ELSE
        IF VacValid[i] THEN
            IF VacHold[i] AND VacIn[i].onAllowed AND blowState[i] <> 10 THEN
                Vac[i].hold := TRUE; Vac[i].accepted := TRUE;
            ELSIF NOT VacHold[i] AND VacIn[i].offAllowed THEN
                Vac[i].hold := FALSE; Vac[i].accepted := TRUE;
            ELSE Vac[i].reason := 30;
            END_IF;
        END_IF;
        IF NOT BlowReq[i] AND blowState[i] = 0 THEN blowNeutral[i] := TRUE; END_IF;
        IF blowState[i] = 20 AND NOT BlowReq[i] THEN
            blowState[i] := 0;
            Vac[i].blowAck := FALSE;
            Vac[i].blowResult := 0;
            blowNeutral[i] := TRUE;
        ELSIF BlowReq[i] AND blowState[i] = 0 AND blowNeutral[i] THEN
            blowNeutral[i] := FALSE;
            IF NOT VacIn[i].blowConfigured OR Cfg.blowTime <= T#0ms OR Cfg.releaseTimeout <= Cfg.blowTime THEN
                Vac[i].blowResult := 2; Vac[i].reason := 100; blowState[i] := 20;
            ELSIF NOT VacValid[i] OR VacHold[i] OR Vac[i].hold OR NOT VacIn[i].blowAllowed OR NOT VacIn[i].offAllowed THEN
                Vac[i].blowResult := 2; Vac[i].reason := 40; blowState[i] := 20;
            ELSE blowState[i] := 10;
            END_IF;
        END_IF;
    END_IF;
    blowTimer[i](IN := blowState[i] = 10, PT := Cfg.blowTime);
    releaseTimer[i](IN := blowState[i] = 10, PT := Cfg.releaseTimeout);
    Vac[i].blow := active AND (blowState[i] = 10) AND NOT blowTimer[i].Q;
    IF active AND blowState[i] = 10 THEN
        IF NOT BlowReq[i] THEN
            Fault := TRUE; Vac[i].fault := TRUE; Vac[i].faultCode := 60; Vac[i].blowResult := 3; blowState[i] := 20;
        ELSIF blowTimer[i].Q AND VacIn[i].releaseConfirmed AND NOT VacIn[i].ok THEN
            Vac[i].blowResult := 1; blowState[i] := 20;
        ELSIF releaseTimer[i].Q THEN
            Vac[i].blowResult := 3; Vac[i].reason := 60; Vac[i].fault := TRUE; Vac[i].faultCode := 60; Fault := TRUE; blowState[i] := 20;
        END_IF;
    END_IF;
    Vac[i].blowAck := Session AND NOT Critical AND blowState[i] = 20;
    vacTimer[i](IN := active AND Vac[i].hold AND NOT VacIn[i].ok, PT := Cfg.vacuumTimeout);
    IF active AND Vac[i].hold AND VacIn[i].ok THEN wasVacuum[i] := TRUE; END_IF;
    IF NOT Vac[i].hold THEN wasVacuum[i] := FALSE; END_IF;
    IF active AND ((wasVacuum[i] AND NOT VacIn[i].ok) OR vacTimer[i].Q) THEN
        Fault := TRUE; Vac[i].reason := 90; Vac[i].fault := TRUE; Vac[i].faultCode := 90;
    END_IF;
    Vac[i].busy := active AND ((blowState[i] = 10) OR (Vac[i].hold AND NOT VacIn[i].ok));
    IF Cyl[i].fault THEN Cyl[i].reason := Cyl[i].faultCode; END_IF;
    IF Vac[i].fault THEN Vac[i].reason := Vac[i].faultCode; END_IF;
    Neutral := Neutral AND NOT BlowReq[i] AND NOT Vac[i].blowAck AND blowState[i] = 0;
END_FOR;
(* Blad pozniejszego kanalu uniewaznia nowe komendy wszystkich kanalow w tym samym skanie. *)
IF Fault OR Critical THEN
    FOR i := 1 TO 5 DO
        Cyl[i].acceptedHome := FALSE;
        Cyl[i].acceptedWork := FALSE;
        Cyl[i].busy := FALSE;
        IF CylIn[i].lossPolicyVerified AND NOT (CylIn[i].lossHome AND CylIn[i].lossWork) THEN
            Cyl[i].home := CylIn[i].lossHome;
            Cyl[i].work := CylIn[i].lossWork;
        END_IF;
        Vac[i].accepted := FALSE;
        Vac[i].blow := FALSE;
    END_FOR;
END_IF;
