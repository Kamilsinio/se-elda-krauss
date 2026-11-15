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
END_VAR
IF NOT Inp.valid OR Inp.manualMoved THEN Sts.known := FALSE; END_IF;
IF Inp.reconcile AND Inp.valid AND NOT Inp.moving THEN
 Sts.occupied := Inp.restored;
 Sts.known := TRUE; dirty := FALSE;
END_IF;
IF Inp.commit THEN dirty := TRUE; END_IF;
IF Sts.known AND dirty AND NOT Inp.moving THEN Sts.occupied := Inp.observed; dirty := FALSE; END_IF;
Sts.emptyConfirmed := Sts.known AND Inp.valid AND NOT Inp.moving AND NOT Inp.pending;
FOR i := 1 TO 7 DO
 IF Sts.occupied[i] OR Inp.sensed[i] THEN Sts.emptyConfirmed := FALSE; END_IF;
END_FOR;
Sts.reason := 0;
IF NOT Sts.known THEN Sts.reason := 80; END_IF;
