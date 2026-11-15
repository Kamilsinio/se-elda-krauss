(* Rezerwacja pozostaje po utracie sesji i po odebraniu granted. *)
FUNCTION_BLOCK FB_RobotAreas
VAR_INPUT
    Session : BOOL;
    Permit : BOOL;
    Recover : BOOL;
    AccessReq : ARRAY[1..3] OF BOOL;
    Clear : ARRAY[1..3] OF BOOL;
    Inp : ARRAY[1..3] OF ST_RobotAreaIn;
END_VAR
VAR_IN_OUT
    Context : ST_RobotContext;
END_VAR
VAR_OUTPUT
    Outp : ARRAY[1..3] OF ST_RobotAreaOut;
    AllClear : BOOL;
END_VAR
VAR
    i : INT;
END_VAR
AllClear := TRUE;
FOR i := 1 TO 3 DO
    IF Recover AND Inp[i].recoveryClearConfirmed THEN Context.areaReserved[i] := FALSE; END_IF;
    IF Session AND AccessReq[i] AND Inp[i].valid AND Inp[i].ready AND NOT Inp[i].blocked AND Permit THEN
        (* Rezerwacja po przyznaniu; clear=0 przed wejsciem nie jest dowodem przyznania. *)
        Context.areaReserved[i] := TRUE;
    END_IF;
    IF Session AND Inp[i].valid AND Clear[i] AND NOT AccessReq[i] THEN Context.areaReserved[i] := FALSE; END_IF;
    Outp[i].valid := Session AND Inp[i].valid;
    Outp[i].ready := Outp[i].valid AND Inp[i].ready AND NOT Inp[i].blocked;
    Outp[i].granted := Outp[i].valid AND NOT Inp[i].blocked AND AccessReq[i] AND Permit AND
        (Outp[i].ready OR Context.areaReserved[i]);
    Outp[i].reserved := Context.areaReserved[i];
    Outp[i].reason := 0;
    IF NOT Session THEN Outp[i].reason := 10;
    ELSIF NOT Inp[i].valid THEN Outp[i].reason := 50;
    ELSIF NOT Outp[i].ready OR NOT Permit THEN Outp[i].reason := 30;
    END_IF;
    AllClear := AllClear AND NOT Context.areaReserved[i];
END_FOR;
