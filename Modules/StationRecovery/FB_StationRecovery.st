FUNCTION_BLOCK FB_StationRecovery
VAR_INPUT
 Invalidate : BOOL; (* Przyczyna wymogu uzgodnienia, także zatrzaśnięta. *)
 Blocked : BOOL; (* Bieżący brak ważnych danych, ruch ręczny lub blokada procesu. *)
 PhysicalIdle : BOOL;
 Confirm : BOOL;
 RobotApproved : BOOL;
 RobotReady : BOOL;
 Proposal : ST_RobotContext;
END_VAR
VAR_IN_OUT
 Context : ST_RobotContext;
END_VAR
VAR_OUTPUT
 Required : BOOL := TRUE;
 Approved : BOOL;
 Reason : UINT;
END_VAR
VAR
 validProposal : BOOL;
 i : INT;
END_VAR
Approved := FALSE; Reason := 80;
IF Invalidate THEN Required := TRUE; END_IF;
validProposal := Proposal.valid AND Proposal.schema = 4 AND Proposal.occupancyKnown AND
 Proposal.occupied[4] = Proposal.elevatorLoadPresent;
IF Required AND NOT Blocked AND PhysicalIdle AND RobotReady THEN
 IF RobotApproved THEN
  Required := FALSE; Approved := TRUE; Reason := 0;
 ELSIF Confirm AND validProposal THEN
  Context.occupied := Proposal.occupied;
  Context.elevatorLoadPresent := Proposal.elevatorLoadPresent;
  Context.occupancyKnown := TRUE;
  Context.bottomDonePendingTray := Proposal.bottomDonePendingTray;
  Context.bottomDonePendingBox := Proposal.bottomDonePendingBox;
  Required := FALSE; Approved := TRUE; Reason := 0;
 END_IF;
 IF Approved THEN
  (* Uzgodniony snapshot zamyka takze przydzielone, odrzucone zdarzenia. *)
  Context.station.lastMaterialEventId := Context.station.nextMaterialEventId;
  FOR i := 1 TO 6 DO Context.station.operations[i].done := TRUE; Context.station.operations[i].accepted := FALSE; END_FOR;
 END_IF;
END_IF;
