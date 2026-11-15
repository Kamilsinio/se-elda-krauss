(* Jeden właściciel 10 grup cewek. 1..5=M1..M5, 6=V201, 7=V203,
   8=V202, 9=V301/V302, 10=V303/V304. HOME/WORK wymagają GAP-08.
   Postój zachowuje komendy; krytyczny stan stosuje wyłącznie zatwierdzoną politykę. *)
FUNCTION_BLOCK FB_StationCoils
VAR_INPUT
    NewPermit : BOOL;
    UseCommandValid : BOOL;
    CommandValid : ARRAY[1..10] OF BOOL;
    LocalFault : ARRAY[1..10] OF BOOL;
    RestartPulse : BOOL; // Swiezy fizyczny Start, bez kolejkowania.
    LocalFaultPolicyVerified : BOOL;
    LocalFaultPolicy : ARRAY[1..10] OF ST_StationCoil;
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
    RestartRequired : ARRAY[1..10] OF BOOL;
END_VAR
VAR
    i : INT;
    wasManual : BOOL;
    wasActive : ARRAY[1..10] OF BOOL;
    releasePending : ARRAY[1..10] OF BOOL;
    manualReleased : ARRAY[1..10] OF BOOL;
    validPolicy : BOOL;
    validCommands : BOOL;
    validLocalPolicy : BOOL;
    validReleasePolicy : BOOL;
    anyLocalFault : BOOL;
END_VAR
validPolicy := PolicyVerified; validReleasePolicy := ReleaseVerified;
validCommands := TRUE; validLocalPolicy := LocalFaultPolicyVerified; anyLocalFault := FALSE;
FOR i := 1 TO 10 DO
    IF LossPolicy[i].home AND LossPolicy[i].work THEN validPolicy := FALSE; END_IF;
    IF Cmd[i].home AND Cmd[i].work THEN validCommands := FALSE; END_IF;
    IF LocalFaultPolicy[i].home AND LocalFaultPolicy[i].work THEN validLocalPolicy := FALSE; END_IF;
    anyLocalFault := anyLocalFault OR LocalFault[i] OR RestartRequired[i];
    IF ReleasePolicy[i].home AND ReleasePolicy[i].work THEN validReleasePolicy := FALSE; END_IF;
END_FOR;
FOR i := 1 TO 10 DO
    IF LocalFault[i] THEN RestartRequired[i] := TRUE; manualReleased[i] := FALSE; END_IF;
    IF Manual AND NOT ManualActive[i] THEN manualReleased[i] := TRUE; END_IF;
    IF RestartRequired[i] AND NOT LocalFault[i] AND NewPermit AND
       (NOT UseCommandValid OR CommandValid[i]) AND (NOT GateChanges OR ChangeAllowed[i]) AND
       ((NOT Manual AND RestartPulse) OR (Manual AND manualReleased[i] AND ManualActive[i] AND NOT wasActive[i])) THEN
        RestartRequired[i] := FALSE;
    END_IF;
    IF wasActive[i] AND (NOT ManualActive[i] OR (wasManual AND NOT Manual)) THEN releasePending[i] := TRUE; END_IF;
END_FOR;
Fault := NOT validPolicy OR NOT validCommands OR (anyLocalFault AND NOT validLocalPolicy) OR (Manual AND NOT validReleasePolicy);
IF Critical AND validPolicy THEN
    Applied := LossPolicy;
    FOR i := 1 TO 10 DO releasePending[i] := FALSE; END_FOR;
ELSIF NOT Critical AND NOT Fault THEN
    FOR i := 1 TO 10 DO
        IF (LocalFault[i] OR RestartRequired[i]) AND validLocalPolicy THEN
            (* Lokalna polityka nie zmienia ostrzezenia w globalny Stop. *)
            Applied[i] := LocalFaultPolicy[i]; releasePending[i] := FALSE;
        ELSIF NOT GateChanges OR ChangeAllowed[i] THEN
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
