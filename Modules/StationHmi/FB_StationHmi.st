(* Prezentacja wspolnych stanow; sesje i transakcje prowadzi wylacznie FB_RobotHmi. *)
FUNCTION_BLOCK FB_StationHmi
VAR_INPUT
 Inp : ST_StationHmiIn;
END_VAR
VAR_OUTPUT
 Sts : ST_StationHmiStatus;
END_VAR
Sts.occupied := Inp.material.occupied;
Sts.dataValid := Inp.io.valid;
Sts.materialKnown := Inp.material.known;
Sts.emptyConfirmed := Inp.material.emptyConfirmed;
Sts.draining := Inp.drain.state <> E_StationDrainState.IDLE AND Inp.drain.state <> E_StationDrainState.COMPLETE;
Sts.paused := Inp.drain.paused;
Sts.waitingPickup := Inp.waitingPickup;
Sts.localReady := Inp.localReady;
Sts.drainStep := Inp.drain.state;
Sts.owner := Inp.transport.owner; Sts.action_ := Inp.transport.action_;
Sts.canApply := Inp.idle AND NOT Inp.recovery;
Sts.canResetState := Inp.idle AND Inp.manual;
Sts.reason := Inp.drain.reason;
IF NOT Inp.material.known THEN Sts.reason := 80; END_IF;
IF NOT Inp.io.valid THEN Sts.reason := 10; END_IF;
