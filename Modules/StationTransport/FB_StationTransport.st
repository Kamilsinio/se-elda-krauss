(* Zasoby: 1=górna taśma, 2=oś windy, 3=taśma windy, 4=dolna,
   5=wydanie B304, 6=magazyn. Właściciel nie znika od samego Stop. *)
FUNCTION_BLOCK FB_StationTransport
VAR_INPUT
 Inp : ST_StationTransportIn;
END_VAR
VAR_IN_OUT
 Context : ST_StationContext;
END_VAR
VAR_OUTPUT
 Sts : ST_StationTransportStatus;
END_VAR
VAR
 candidate : E_StationAction;
 candidateOwner : E_StationOwner;
 needed : ARRAY[1..6] OF BOOL;
 available : BOOL;
 i : INT;
 item : ST_StationOperation;
 empty : ST_StationOperation;
END_VAR
Sts.start := FALSE; Sts.done := FALSE; Sts.completedOwner := E_StationOwner.NONE; Sts.reason := 0;
IF (Inp.critical OR NOT Inp.permit OR Inp.actionFault) AND Sts.owner <> E_StationOwner.NONE THEN Sts.fault := TRUE; END_IF;
IF Inp.reconcile THEN
 Sts.fault := FALSE; Sts.owner := E_StationOwner.NONE; Sts.action := E_StationAction.NONE;
 FOR i := 1 TO 6 DO Context.operations[i].done := TRUE; Context.operations[i].accepted := FALSE; END_FOR;
END_IF;
IF Inp.resourcesUsed THEN
 FOR i := 1 TO 6 DO
  needed[i] := FALSE;
 END_FOR;
 needed[1] := Inp.productionTopBusy; needed[2] := Inp.productionAxisBusy;
 needed[3] := Inp.productionElevatorBusy; needed[4] := Inp.productionBottomBusy; needed[6] := Inp.storageBusy;
 FOR i := 1 TO 6 DO
  IF Context.operations[i].owner = E_StationOwner.PRODUCTION AND NOT needed[i] THEN
   Context.operations[i].accepted := FALSE; Context.operations[i].done := TRUE;
  END_IF;
  IF needed[i] AND NOT Context.operations[i].accepted THEN
   IF Context.nextOperationId < 16#FFFFFFFF THEN
    Context.nextOperationId := Context.nextOperationId + 1; item := empty;
    item.id := Context.nextOperationId; item.owner := E_StationOwner.PRODUCTION;
    item.accepted := TRUE; item.started := TRUE; Context.operations[i] := item;
   ELSE Sts.fault := TRUE; END_IF;
  END_IF;
 END_FOR;
END_IF;
IF Sts.owner = E_StationOwner.PRODUCTION AND (Inp.resourcesUsed OR NOT Inp.productionBusy) THEN Sts.owner := E_StationOwner.NONE; END_IF;
IF Sts.owner = E_StationOwner.MANUAL AND NOT Inp.manualActive THEN Sts.owner := E_StationOwner.NONE; END_IF;
IF Sts.owner = E_StationOwner.DRAIN OR Sts.owner = E_StationOwner.LOCAL THEN
 FOR i := 1 TO 6 DO
  IF Context.operations[i].id = Sts.operationId THEN
   IF Inp.executorAccepted AND (NOT Inp.requireIds OR Inp.acceptedId = Sts.operationId) THEN Context.operations[i].accepted := TRUE; END_IF;
   IF Inp.executorStarted AND (NOT Inp.requireIds OR Inp.startedId = Sts.operationId) THEN Context.operations[i].started := TRUE; END_IF;
   IF Inp.unloadIssued AND i = 4 THEN Context.operations[i].accepted := FALSE; END_IF;
   IF Sts.fault THEN Context.operations[i].fault := TRUE; END_IF;
  END_IF;
 END_FOR;
 IF Inp.actionDone AND NOT Sts.fault AND (NOT Inp.requireIds OR Inp.doneId = Sts.operationId) THEN
  Sts.completedOwner := Sts.owner; Sts.done := TRUE;
  FOR i := 1 TO 6 DO
   IF Context.operations[i].id = Sts.operationId THEN Context.operations[i].accepted := FALSE; Context.operations[i].done := TRUE; END_IF;
  END_FOR;
  Sts.owner := E_StationOwner.NONE; Sts.action := E_StationAction.NONE;
 END_IF;
END_IF;
candidate := E_StationAction.NONE; candidateOwner := E_StationOwner.NONE;
IF Sts.owner = E_StationOwner.NONE AND NOT Sts.done AND Inp.permit AND NOT Inp.critical AND NOT Inp.actionFault AND NOT Sts.fault THEN
 IF Inp.localRequest AND Inp.localReady AND Inp.localAllowed AND NOT Inp.manual AND NOT Inp.drainPermit THEN
  candidate := E_StationAction.UNLOAD; candidateOwner := E_StationOwner.LOCAL;
 ELSIF Inp.drainPermit AND Inp.drainAction <> E_StationAction.NONE AND NOT Inp.manual THEN
  candidate := Inp.drainAction; candidateOwner := E_StationOwner.DRAIN;
 ELSIF Inp.manual AND Inp.manualActive THEN Sts.owner := E_StationOwner.MANUAL;
 ELSIF Inp.productionPermit THEN Sts.owner := E_StationOwner.PRODUCTION;
 END_IF;
END_IF;
FOR i := 1 TO 6 DO needed[i] := FALSE; END_FOR;
CASE candidate OF
 E_StationAction.ELEV_TOP: needed[2] := TRUE; needed[3] := TRUE;
 E_StationAction.ELEV_BOTTOM: needed[2] := TRUE; needed[3] := TRUE;
 E_StationAction.FEED: needed[1] := TRUE; needed[2] := TRUE; needed[3] := TRUE;
 E_StationAction.DISCHARGE: needed[2] := TRUE; needed[3] := TRUE; needed[4] := TRUE;
 E_StationAction.ADVANCE: needed[4] := TRUE;
 E_StationAction.UNLOAD: needed[4] := TRUE; needed[5] := TRUE;
END_CASE;
available := TRUE;
FOR i := 1 TO 6 DO
 IF needed[i] AND Context.operations[i].accepted THEN available := FALSE; END_IF;
END_FOR;
IF needed[1] AND Inp.robotReserved[1] THEN available := FALSE; END_IF;
IF (needed[2] OR needed[3]) AND Inp.robotReserved[2] THEN available := FALSE; END_IF;
IF needed[5] AND Inp.outputPending THEN available := FALSE; END_IF;
IF NOT Inp.resourcesUsed AND Inp.productionBusy THEN available := FALSE; END_IF;
IF candidate <> E_StationAction.NONE AND available THEN
 IF Context.nextOperationId < 16#FFFFFFFF THEN
  Context.nextOperationId := Context.nextOperationId + 1; Sts.operationId := Context.nextOperationId;
  item := empty; item.id := Sts.operationId; item.owner := candidateOwner; item.action := candidate; item.accepted := TRUE;
  FOR i := 1 TO 6 DO IF needed[i] THEN Context.operations[i] := item; END_IF; END_FOR;
  Sts.owner := candidateOwner; Sts.action := candidate; Sts.start := TRUE;
 ELSE Sts.fault := TRUE; END_IF;
END_IF;
Sts.resources := Context.operations;
Sts.productionTopAllowed := NOT Context.operations[1].accepted OR Context.operations[1].owner = E_StationOwner.PRODUCTION;
Sts.productionAxisAllowed := NOT Context.operations[2].accepted OR Context.operations[2].owner = E_StationOwner.PRODUCTION;
Sts.productionElevatorAllowed := NOT Context.operations[3].accepted OR Context.operations[3].owner = E_StationOwner.PRODUCTION;
Sts.productionBottomAllowed := NOT Context.operations[4].accepted OR Context.operations[4].owner = E_StationOwner.PRODUCTION;
Sts.busy := Sts.owner = E_StationOwner.DRAIN OR Sts.owner = E_StationOwner.LOCAL OR Sts.owner = E_StationOwner.MANUAL OR Inp.productionBusy;
IF Sts.fault THEN Sts.reason := 80; END_IF;
