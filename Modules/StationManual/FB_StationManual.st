(* 1..4 tasmy/os windy; 5..14 pneumatyka; 15/16 oslony. Oddzielny watchdog kazdego ruchu. *)
FUNCTION_BLOCK FB_StationManual
VAR_INPUT
 Cmd : ST_StationManualCmd;
 Inp : ST_StationManualIn;
END_VAR
VAR_OUTPUT
 Sts : ST_StationManualStatus;
END_VAR
VAR
 watchdog : ARRAY[1..16] OF TON;
 lastCounter : ARRAY[1..16] OF UINT;
 released : ARRAY[1..16] OF BOOL;
 lastSession : UDINT;
 lastPanel : UINT;
 expectedPanel : UINT;
 i : INT;
 valid : BOOL;
 held : BOOL;
END_VAR
Sts.active := FALSE; Sts.reason := 0;
valid := Inp.armed AND Inp.manual AND Inp.safe AND Inp.idle AND Inp.timeout > T#0ms AND
 Cmd.sessionId = Inp.sessionId AND Inp.sessionId <> 0;
FOR i := 1 TO 16 DO
 expectedPanel := 111;
 IF i = 2 OR i = 4 OR (i >= 10 AND i <= 12) THEN expectedPanel := 112; END_IF;
 IF i = 3 OR i = 13 OR i = 14 THEN expectedPanel := 113; END_IF;
 IF i >= 15 THEN expectedPanel := 114; END_IF;
 IF Inp.panelOverride > 0 THEN expectedPanel := Inp.panelOverride; END_IF;
 held := Cmd.positive[i] OR Cmd.negative[i];
 IF lastSession <> Inp.sessionId OR lastPanel <> Inp.panel OR NOT valid OR Inp.panel <> expectedPanel THEN released[i] := FALSE; END_IF;
 IF valid AND Inp.panel = expectedPanel AND NOT held THEN released[i] := TRUE; END_IF;
 watchdog[i](IN := held AND Cmd.holdCounter[i] = lastCounter[i], PT := Inp.timeout);
 lastCounter[i] := Cmd.holdCounter[i];
 IF watchdog[i].Q OR (Cmd.positive[i] AND Cmd.negative[i]) THEN released[i] := FALSE; END_IF;
 Sts.positive[i] := valid AND Inp.panel = expectedPanel AND released[i] AND NOT watchdog[i].Q AND
  Cmd.positive[i] AND NOT Cmd.negative[i] AND Inp.allowPositive[i];
 Sts.negative[i] := valid AND Inp.panel = expectedPanel AND released[i] AND NOT watchdog[i].Q AND
  Cmd.negative[i] AND NOT Cmd.positive[i] AND Inp.allowNegative[i];
 Sts.active := Sts.active OR Sts.positive[i] OR Sts.negative[i];
END_FOR;
lastSession := Inp.sessionId; lastPanel := Inp.panel;
IF NOT valid THEN Sts.reason := 30; END_IF;
