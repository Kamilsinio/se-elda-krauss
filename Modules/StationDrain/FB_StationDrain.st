(* Wykonawca jednego stalego request; done trzymane do request=0. *)
FUNCTION_BLOCK FB_StationDrain
VAR_INPUT
 Inp : ST_StationDrainIn;
END_VAR
VAR_IN_OUT
 Drain : ST_RobotDrain;
END_VAR
VAR_OUTPUT
 Sts : ST_StationDrainStatus;
END_VAR
Drain.connected := TRUE;
Sts.action_ := E_StationAction.NONE;
Sts.reason := 0;
IF NOT Drain.request THEN
 Drain.accepted := FALSE; Drain.busy := FALSE; Drain.done := FALSE; Drain.fault := FALSE;
 Drain.emptyConfirmed := FALSE; Sts.state := E_StationDrainState.IDLE;
 RETURN;
END_IF;
IF Inp.reconcile THEN
 Drain.fault := FALSE; Sts.state := E_StationDrainState.SELECT_ACTION;
END_IF;
IF Inp.actionFault OR NOT Inp.known THEN
 Drain.fault := TRUE; Sts.state := E_StationDrainState.FAULT;
END_IF;
CASE Sts.state OF
 E_StationDrainState.IDLE:
  Drain.accepted := TRUE; Sts.state := E_StationDrainState.SELECT_ACTION;
 E_StationDrainState.SELECT_ACTION:
  IF Inp.actionAccepted THEN Sts.state := E_StationDrainState.WAIT_ACTION;
  ELSIF NOT Drain.runPermit THEN Sts.state := E_StationDrainState.PAUSED;
  ELSIF Inp.enable THEN
   IF Inp.emptyConfirmed THEN
    Drain.done := TRUE; Drain.emptyConfirmed := TRUE; Sts.state := E_StationDrainState.COMPLETE;
   ELSIF Inp.occupied[4] AND Inp.lowerCanAccept THEN
    IF Inp.atBottom THEN Sts.action_ := E_StationAction.DISCHARGE; ELSE Sts.action_ := E_StationAction.ELEV_BOTTOM; END_IF;
   ELSIF Inp.occupied[5] OR Inp.occupied[6] OR Inp.occupied[7] THEN Sts.action_ := E_StationAction.UNLOAD;
   ELSIF NOT Inp.occupied[4] AND (Inp.occupied[1] OR Inp.occupied[2] OR Inp.occupied[3]) THEN
    IF NOT Inp.atTop THEN Sts.action_ := E_StationAction.ELEV_TOP; ELSE Sts.action_ := E_StationAction.FEED; END_IF;
   END_IF;

  END_IF;
 E_StationDrainState.WAIT_ACTION:
  IF Inp.actionDone THEN
   IF Drain.runPermit THEN Sts.state := E_StationDrainState.SELECT_ACTION;
   ELSE Sts.state := E_StationDrainState.PAUSED; END_IF;
  END_IF;
 E_StationDrainState.PAUSED:
  IF Drain.runPermit AND Inp.enable THEN Sts.state := E_StationDrainState.SELECT_ACTION; END_IF;
 E_StationDrainState.COMPLETE:
  Drain.done := TRUE; Drain.emptyConfirmed := Inp.emptyConfirmed;
 E_StationDrainState.FAULT:
  Sts.reason := 80;
END_CASE;
Drain.busy := Sts.state <> E_StationDrainState.COMPLETE AND Sts.state <> E_StationDrainState.FAULT;
Sts.paused := Sts.state = E_StationDrainState.PAUSED;
IF Sts.paused THEN Sts.reason := 30; END_IF;
