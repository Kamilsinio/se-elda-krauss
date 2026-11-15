(* Dane z adaptera sprzetowego; brak adresow i domyslnych potwierdzen. *)
FUNCTION_BLOCK FB_StationIo
VAR_INPUT
 Cfg : ST_StationIoCfg;
 Inp : ST_StationIoIn;
END_VAR
VAR_OUTPUT
 Sts : ST_StationIoStatus;
END_VAR
VAR
 onTimer : ARRAY[1..7] OF TON;
 offTimer : ARRAY[1..7] OF TON;
 barrierOn : TON;
 barrierOff : TON;
 i : INT;
END_VAR
Sts.valid := Cfg.configured AND Inp.mappingVerified AND Inp.gatewayHealthy AND Inp.imageFresh AND Cfg.stable > T#0ms;
FOR i := 1 TO 12 DO
 Sts.moduleValid[i] := Inp.gatewayHealthy AND Inp.imageFresh AND Inp.moduleHealthy[i];
 IF Cfg.required[i] AND NOT Sts.moduleValid[i] THEN Sts.valid := FALSE; END_IF;
END_FOR;
FOR i := 1 TO 7 DO
 IF NOT Inp.positionValid[i] THEN Sts.valid := FALSE; END_IF;
END_FOR;
FOR i := 1 TO 7 DO
 Sts.positionValid[i] := Sts.valid AND Inp.positionValid[i];
 onTimer[i](IN := Sts.positionValid[i] AND Inp.occupied[i], PT := Cfg.stable);
 offTimer[i](IN := Sts.positionValid[i] AND NOT Inp.occupied[i], PT := Cfg.stable);
 IF onTimer[i].Q THEN Sts.occupied[i] := TRUE; END_IF;
 IF offTimer[i].Q THEN Sts.occupied[i] := FALSE; END_IF;
END_FOR;
Sts.barrierValid := Sts.valid AND Inp.barrierValid;
barrierOn(IN := Sts.barrierValid AND Inp.barrierBlocked, PT := Cfg.stable);
barrierOff(IN := Sts.barrierValid AND NOT Inp.barrierBlocked, PT := Cfg.stable);
IF barrierOn.Q THEN Sts.barrierBlocked := TRUE; END_IF;
IF barrierOff.Q THEN Sts.barrierBlocked := FALSE; END_IF;
Sts.reason := 0;
IF NOT Sts.valid THEN Sts.reason := 10; END_IF;
