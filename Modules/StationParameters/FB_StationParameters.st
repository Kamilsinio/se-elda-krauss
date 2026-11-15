(* Brak domyslnych nastaw maszyny. Snapshot aktualizowany w calosci albo wcale. *)
FUNCTION_BLOCK FB_StationParameters
VAR_INPUT
 Cfg : ST_StationParameterCfg;
 Inp : ST_StationParametersIn;
 Snapshot : ST_StationParameterSet;
END_VAR
VAR_IN_OUT
 Edit : ARRAY[1..4] OF ST_StationParameterSet;
 Active : ARRAY[1..4] OF ST_StationParameterSet;
 Revision : ARRAY[1..4] OF UINT;
END_VAR
VAR_OUTPUT
 Sts : ST_StationParametersStatus;
END_VAR
VAR
 n : INT;
 good : BOOL;
END_VAR
Sts.reason := 0; Sts.applied := FALSE;
IF Inp.reload >= 1 AND Inp.reload <= 4 THEN
 n := TO_INT(Inp.reload); Edit[n] := Active[n];
END_IF;
IF Inp.apply <> 0 THEN
 IF Inp.apply > 4 OR NOT Inp.idle OR Inp.recovery OR NOT Cfg.limitsVerified OR
  Inp.apply = Inp.reload THEN Sts.reason := 30;
 ELSE
  n := TO_INT(Inp.apply);
  good := Snapshot.verified AND Cfg.minTimeMs > 0 AND Cfg.maxTimeMs >= Cfg.minTimeMs AND
   Cfg.maxTimeMs <= 2147483647 AND
   Snapshot.sensorStableMs >= Cfg.minTimeMs AND Snapshot.sensorStableMs <= Cfg.maxTimeMs AND
   Snapshot.stopDelayMs >= Cfg.minTimeMs AND Snapshot.stopDelayMs <= Cfg.maxTimeMs AND
   Snapshot.moveTimeoutMs >= Cfg.minTimeMs AND Snapshot.moveTimeoutMs <= Cfg.maxTimeMs AND
   Snapshot.actuatorTimeoutMs >= Cfg.minTimeMs AND Snapshot.actuatorTimeoutMs <= Cfg.maxTimeMs AND
   Snapshot.moveTimeoutMs > Snapshot.sensorStableMs AND Snapshot.actuatorTimeoutMs > Snapshot.sensorStableMs AND
   (n <> 2 OR (Snapshot.slowHz > 0.0 AND Snapshot.fastHz >= Snapshot.slowHz AND Snapshot.fastHz <= Cfg.maxHz)) AND
   Inp.expectedRevision = Revision[n] AND Revision[n] < 65535;
  IF good THEN
   Active[n] := Snapshot; Revision[n] := Revision[n] + 1; Sts.applied := TRUE;
  ELSE Sts.reason := 50; END_IF;
 END_IF;
END_IF;
Sts.actual := Active; Sts.revision := Revision;
