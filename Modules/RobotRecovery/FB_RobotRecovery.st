(* Potwierdzenie dotyczy uzgodnionego snapshotu, nie domyslnego pustego stanu. *)
FUNCTION_BLOCK FB_RobotRecovery
VAR_INPUT
    Invalidate : BOOL;
    AtRecovery : BOOL;
    Neutral : BOOL;
    Cmd : ST_RobotCommands;
    Plant : ST_RobotPlant;
    Rx : ST_RobotRxV2;
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
    empty : ST_RobotContext;
    generation : UDINT;
    stationBefore : ST_StationContext;
    i : INT;
    validProposal : BOOL;
END_VAR
Approved := FALSE;
Reason := 80;
IF Invalidate THEN Required := TRUE; END_IF;
validProposal := Proposal.valid AND Proposal.schema = 4 AND Proposal.occupancyKnown AND
    Plant.contextRestored AND Plant.retentionVerified AND Proposal.occupied[4] = Proposal.elevatorLoadPresent;
IF Proposal.orderActive AND ((Proposal.program <> 1 AND Proposal.program <> 2) OR Proposal.batchCount = 0) THEN
    validProposal := FALSE;
END_IF;
FOR i := 1 TO 2 DO
    IF Proposal.cycles[i].occupied AND (Proposal.cycles[i].quantity = 0 OR
       Proposal.cycles[i].good + Proposal.cycles[i].samples + Proposal.cycles[i].rejects >
       TO_UDINT(Proposal.cycles[i].quantity)) THEN validProposal := FALSE; END_IF;
END_FOR;
IF Proposal.cycles[1].occupied AND Proposal.cycles[2].occupied AND
   Proposal.cycles[1].id = Proposal.cycles[2].id THEN validProposal := FALSE; END_IF;
IF Proposal.assigned AND ((Proposal.assignedSlot < 1) OR (Proposal.assignedSlot > 2)) THEN validProposal := FALSE; END_IF;
IF Required AND NOT Invalidate AND AtRecovery AND Neutral AND Plant.robotContextConfirmed AND Plant.loadsConfirmed AND
   Plant.cyclesConfirmed AND Rx.production_home AND Rx.production_loadKnown AND
   Plant.imm.valid AND Plant.imm.cycleKnown AND NOT Plant.critical AND Plant.safetyValid AND Plant.safetyOK AND
   Plant.transfersConfirmedIdle AND Plant.physicalIdle AND Plant.retentionVerified THEN
    IF Cmd.newEmptyContext AND Plant.stationEmptyConfirmed AND Rx.production_loadMask = 0 AND Plant.imm.settled THEN
        generation := Context.hmiGeneration;
        empty.schema := 4; empty.valid := TRUE;
        empty.occupancyKnown := TRUE;
        empty.batchCount := Context.batchCount;
        empty.station := Context.station;
        FOR i := 1 TO 6 DO empty.station.operations[i].accepted := FALSE; empty.station.operations[i].done := TRUE; END_FOR;
        empty.stationParameters := Context.stationParameters;
        empty.stationParamRevision := Context.stationParamRevision;
        empty.hmiGeneration := generation;
        Context := empty;
        Context.drainResumeRequired := Context.ending;
        Required := FALSE; Approved := TRUE; Reason := 0;
    ELSIF Cmd.recover AND validProposal THEN
        generation := Context.hmiGeneration;
        stationBefore := Context.station;
        Context := Proposal;
        Context.station := stationBefore;
        Context.hmiGeneration := generation;
        FOR i := 1 TO 3 DO
            IF Plant.areas[i].recoveryClearConfirmed THEN Context.areaReserved[i] := FALSE; END_IF;
        END_FOR;
        Context.drainResumeRequired := Context.ending;
        Required := FALSE; Approved := TRUE; Reason := 0;
    END_IF;
END_IF;
