(* Wlasciciel nie zmienia sie po Stop; nowe zadania nie sa kolejkowane. *)
FUNCTION_BLOCK FB_StationTransport
VAR_INPUT
 Inp : ST_StationTransportIn;
END_VAR
VAR_OUTPUT
 Sts : ST_StationTransportStatus;
END_VAR
Sts.start := FALSE;
Sts.completedOwner := E_StationOwner.NONE;
Sts.done := FALSE;
Sts.reason := 0;
IF Inp.critical OR NOT Inp.permit OR Inp.actionFault THEN
 IF Sts.owner <> E_StationOwner.NONE THEN Sts.fault := TRUE; END_IF;
END_IF;
IF Inp.reconcile THEN
 Sts.owner := E_StationOwner.NONE; Sts.action := E_StationAction.NONE; Sts.fault := FALSE;
END_IF;
IF Sts.owner = E_StationOwner.PRODUCTION AND NOT Inp.productionBusy AND NOT Inp.productionPermit THEN
 Sts.owner := E_StationOwner.NONE;
END_IF;
IF Sts.owner = E_StationOwner.MANUAL AND NOT Inp.manualActive THEN Sts.owner := E_StationOwner.NONE; END_IF;
IF (Sts.owner = E_StationOwner.DRAIN OR Sts.owner = E_StationOwner.LOCAL) AND Inp.actionDone AND NOT Sts.fault THEN
 Sts.completedOwner := Sts.owner;
 Sts.done := TRUE; Sts.owner := E_StationOwner.NONE; Sts.action := E_StationAction.NONE;
ELSIF Sts.owner = E_StationOwner.NONE AND Inp.permit AND NOT Inp.critical AND NOT Sts.fault THEN
 IF Inp.productionBusy THEN Sts.owner := E_StationOwner.PRODUCTION;
 ELSIF Inp.localRequest AND Inp.localReady AND Inp.localAllowed AND NOT Inp.manual THEN
  Sts.owner := E_StationOwner.LOCAL; Sts.action := E_StationAction.UNLOAD; Sts.start := TRUE;
 ELSIF Inp.drainPermit AND Inp.drainAction <> E_StationAction.NONE AND NOT Inp.manual THEN
  Sts.owner := E_StationOwner.DRAIN; Sts.action := Inp.drainAction; Sts.start := TRUE;
 ELSIF Inp.manual AND Inp.manualActive THEN Sts.owner := E_StationOwner.MANUAL;
 ELSIF Inp.productionPermit AND NOT Inp.manual THEN Sts.owner := E_StationOwner.PRODUCTION;
 END_IF;
END_IF;
(* Lokalny rozladunek moze przejac dolna tasme w bezczynnej produkcji. *)
IF Sts.owner = E_StationOwner.PRODUCTION AND NOT Inp.productionBusy AND NOT Inp.productionNeedsLower AND
 Inp.localRequest AND Inp.localReady AND Inp.localAllowed AND Inp.permit AND NOT Inp.critical AND NOT Sts.fault THEN
 Sts.owner := E_StationOwner.LOCAL; Sts.action := E_StationAction.UNLOAD; Sts.start := TRUE;
END_IF;
Sts.busy := Sts.owner <> E_StationOwner.NONE;
IF Sts.fault THEN Sts.reason := 80; END_IF;
