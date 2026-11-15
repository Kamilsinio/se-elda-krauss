(* Jeden właściciel 10 grup cewek. 1..5=M1..M5, 6=V201, 7=V203,
   8=V202, 9=V301/V302, 10=V303/V304. HOME/WORK wymagają GAP-08.
   Postój zachowuje komendy; krytyczny stan stosuje wyłącznie zatwierdzoną politykę. *)
FUNCTION_BLOCK FB_StationCoils
VAR_INPUT
    NewPermit : BOOL;
    UseCommandValid : BOOL;
    CommandValid : ARRAY[1..10] OF BOOL;
    GateChanges : BOOL;
    ChangeAllowed : ARRAY[1..10] OF BOOL;
    Manual : BOOL;
    ManualActive : ARRAY[1..10] OF BOOL;
    ReleaseVerified : BOOL;
    ReleasePolicy : ARRAY[1..10] OF ST_StationCoil;
    Critical : BOOL;
    PolicyVerified : BOOL;
    Cmd : ARRAY[1..10] OF ST_StationCoil;
    LossPolicy : ARRAY[1..10] OF ST_StationCoil;
END_VAR
VAR_OUTPUT
    Applied : ARRAY[1..10] OF ST_StationCoil;
    Fault : BOOL;
END_VAR
VAR
    i : INT;
    wasManual : BOOL;
    wasActive : ARRAY[1..10] OF BOOL;
    releasePending : ARRAY[1..10] OF BOOL;
    validPolicy : BOOL;
    validCommands : BOOL;
END_VAR
validPolicy := PolicyVerified;
validCommands := TRUE;
FOR i := 1 TO 10 DO
    IF LossPolicy[i].home AND LossPolicy[i].work THEN validPolicy := FALSE; END_IF;
    IF Cmd[i].home AND Cmd[i].work THEN validCommands := FALSE; END_IF;
    IF Manual AND (NOT ReleaseVerified OR (ReleasePolicy[i].home AND ReleasePolicy[i].work)) THEN validPolicy := FALSE; END_IF;
END_FOR;
FOR i := 1 TO 10 DO
    IF wasActive[i] AND (NOT ManualActive[i] OR (wasManual AND NOT Manual)) THEN releasePending[i] := TRUE; END_IF;
END_FOR;
Fault := NOT validPolicy OR NOT validCommands;
IF Critical AND validPolicy THEN
    Applied := LossPolicy;
    FOR i := 1 TO 10 DO releasePending[i] := FALSE; END_FOR;
ELSIF NOT Critical AND NOT Fault THEN
    FOR i := 1 TO 10 DO
        IF NOT GateChanges OR ChangeAllowed[i] THEN
            IF releasePending[i] AND ReleaseVerified THEN
                Applied[i] := ReleasePolicy[i]; releasePending[i] := FALSE;
            ELSIF Manual THEN
                IF NewPermit AND ManualActive[i] AND (NOT UseCommandValid OR CommandValid[i]) THEN Applied[i] := Cmd[i]; END_IF;
            ELSIF NewPermit AND (NOT UseCommandValid OR CommandValid[i]) THEN Applied[i] := Cmd[i]; END_IF;
        END_IF;
    END_FOR;
END_IF;

wasManual := Manual;
wasActive := ManualActive;
