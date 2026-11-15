(* M1-M7: jeden punkt koncowej komendy. Postoj nie zmienia poprzedniego celu.
   Kolejnosc M1-M7; home=bwd, work=fwd po zatwierdzeniu mapy. *)
FUNCTION_BLOCK FB_StationCoils
VAR_INPUT
    NewPermit : BOOL;
    Critical : BOOL;
    PolicyVerified : BOOL;
    Cmd : ARRAY[1..7] OF ST_StationCoil;
    LossPolicy : ARRAY[1..7] OF ST_StationCoil;
END_VAR
VAR_OUTPUT
    Applied : ARRAY[1..7] OF ST_StationCoil;
    Fault : BOOL;
END_VAR
VAR
    i : INT;
    validPolicy : BOOL;
    validCommands : BOOL;
END_VAR
validPolicy := PolicyVerified;
validCommands := TRUE;
FOR i := 1 TO 7 DO
    IF LossPolicy[i].home AND LossPolicy[i].work THEN validPolicy := FALSE; END_IF;
    IF Cmd[i].home AND Cmd[i].work THEN validCommands := FALSE; END_IF;
END_FOR;
Fault := NOT validPolicy OR NOT validCommands;
IF Critical AND validPolicy THEN
    Applied := LossPolicy;
ELSIF NewPermit AND NOT Critical AND NOT Fault THEN
    Applied := Cmd;
END_IF;
