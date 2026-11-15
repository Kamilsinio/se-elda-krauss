(* Jedyny wlasciciel modelu stacyjnego; zgasniecie czujnika nie kasuje ladunku. *)
FUNCTION_BLOCK FB_StationMaterial
VAR_INPUT
 Inp : ST_StationMaterialIn;
END_VAR
VAR_OUTPUT
 Sts : ST_StationMaterialStatus;
END_VAR
VAR
 i : INT;
 dirty : BOOL;
 j : INT;
 candidate : ARRAY[1..7] OF BOOL;
 eventId : UDINT;
 good : BOOL;
 anyEvent : BOOL;
END_VAR
IF NOT Inp.valid OR Inp.manualMoved THEN Sts.known := FALSE; END_IF;
IF Inp.reconcile AND Inp.valid AND NOT Inp.moving THEN
 Sts.occupied := Inp.restored;
 Sts.known := TRUE; Sts.fault := FALSE; dirty := FALSE;
 Sts.lastEventId := Inp.restoredEventId;
END_IF;
IF Inp.commit AND NOT Inp.useEvents THEN dirty := TRUE; END_IF;
IF Sts.known AND dirty AND NOT Inp.moving THEN Sts.occupied := Inp.observed; dirty := FALSE; END_IF;
IF Inp.useEvents AND Sts.known THEN
 candidate := Sts.occupied; eventId := Sts.lastEventId; good := TRUE; anyEvent := FALSE;
 FOR j := 1 TO 8 DO
  IF Inp.events[j].id > eventId THEN
   anyEvent := TRUE;
   IF eventId = 16#FFFFFFFF OR Inp.events[j].id <> eventId + 1 OR
      Inp.events[j].source > 7 OR Inp.events[j].target > 7 OR
      Inp.events[j].source = Inp.events[j].target THEN good := FALSE;
   ELSE
    IF Inp.events[j].source > 0 THEN
     IF NOT candidate[Inp.events[j].source] THEN good := FALSE;
     ELSE candidate[Inp.events[j].source] := FALSE; END_IF;
    END_IF;
    IF Inp.events[j].target > 0 THEN
     IF candidate[Inp.events[j].target] THEN good := FALSE;
     ELSE candidate[Inp.events[j].target] := TRUE; END_IF;
    END_IF;
   END_IF;
   eventId := Inp.events[j].id;
  END_IF;
 END_FOR;
 IF good THEN Sts.occupied := candidate; Sts.lastEventId := eventId;
 ELSE Sts.fault := TRUE; Sts.known := FALSE; END_IF;
END_IF;
Sts.emptyConfirmed := Sts.known AND Inp.valid AND NOT Inp.moving AND NOT Inp.pending;
FOR i := 1 TO 7 DO
 IF Sts.occupied[i] OR Inp.sensed[i] THEN Sts.emptyConfirmed := FALSE; END_IF;
END_FOR;
Sts.reason := 0;
IF NOT Sts.known THEN Sts.reason := 80; END_IF;
