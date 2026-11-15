(* ST.3: osobne operacje P4->P5, P5->P6 i pojedyncze wydanie do B304.
   HoldStop5/6 oznacza blokade ladunku; polaryzacja cewek wymaga mapowania. *)
FUNCTION_BLOCK FB_BottomAccumulator_567
VAR_INPUT
 Cfg : ST_Bottom567Cfg;
 Cmd : ST_Bottom567Cmd;
 Inp : ST_Bottom567In;
END_VAR
VAR_OUTPUT
 Outp : ST_Bottom567Out;
 Sts : ST_Bottom567Status;
 Diag : ST_Bottom567Diag;
END_VAR
VAR
 requestEdge : R_TRIG;
 unloadEdge : R_TRIG;
 advanceEdge : R_TRIG;
 source : UINT;
 target : UINT;
 unload : BOOL;
 seenSource : BOOL;
 sourceGone : BOOL;
 allowed : BOOL;
 targetSensor : BOOL;
 sourceSensor : BOOL;
 stopsReady : BOOL;
 moveTimer : TON;
 stopTimer : TON;
 arriveTimer : TON;
 receiptOn : TON;
 receiptOff : TON;
END_VAR
requestEdge(CLK := Cmd.DischargeReq);
unloadEdge(CLK := Cmd.SingleUnloadReq);
advanceEdge(CLK := Cmd.AdvanceReq);
Outp.StepDonePulse := FALSE; Outp.DischargeDonePulse := FALSE;
Outp.SingleUnloadDonePulse := FALSE; Outp.AcceptedPulse := FALSE;
Outp.ConvRun := FALSE; Outp.ElevConv_RunBwd := FALSE;
Outp.HoldStop5 := TRUE; Outp.HoldStop6 := TRUE;
Sts.CanAcceptFromElev := FALSE; Sts.SingleUnloadReady := FALSE; Sts.CanAdvance := FALSE;
Sts.EmptyBottomActive := FALSE;
IF NOT Inp.Valid THEN Sts.Known := FALSE; END_IF;
IF Inp.Reconcile AND Inp.Valid AND Inp.BeltsStopped THEN
 Sts.Occ5 := Inp.Restored[1]; Sts.Occ6 := Inp.Restored[2]; Sts.Occ7 := Inp.Restored[3];
 Sts.Known := TRUE; Sts.State := E_Bottom567State.IDLE; Sts.PickupSeen := FALSE; Sts.WaitingPickup := FALSE;
END_IF;
IF Cmd.ResetFault AND NOT Inp.StopWarning AND Inp.Valid THEN
 Diag.Fault := FALSE; Diag.Code := E_Bottom567Fault.NONE; Diag.Text := '';
 (* Po bledzie ruchu wymagane uzgodnienie, Reset nie zmienia kroku. *)
END_IF;
allowed := Cmd.SafetyOK AND Inp.Valid AND Sts.Known AND Cfg.stopsConfigured AND NOT Diag.Fault AND
 (Cmd.EnableAuto OR Cmd.FinishPermit);
Sts.Busy := Sts.State <> E_Bottom567State.IDLE AND Sts.State <> E_Bottom567State.INIT;
IF Cmd.SafetyOK AND Inp.Valid AND Sts.Known AND Cfg.stopsConfigured AND NOT Diag.Fault AND Sts.State = E_Bottom567State.IDLE THEN
 Sts.CanAcceptFromElev := NOT Sts.Occ5 AND NOT Sts.WaitingPickup;
 Sts.CanAdvance := Sts.Occ5 AND NOT Sts.Occ6 AND NOT Sts.WaitingPickup;
 Sts.SingleUnloadReady := (Sts.Occ5 OR Sts.Occ6 OR Sts.Occ7) AND NOT Sts.WaitingPickup;
END_IF;
IF NOT allowed THEN
 moveTimer(IN := FALSE); arriveTimer(IN := FALSE); stopTimer(IN := FALSE);
 RETURN;
END_IF;
CASE Sts.State OF
 E_Bottom567State.INIT:
  (* Tylko jawny Reconcile nadaje Known. *)
 E_Bottom567State.IDLE:
  Sts.Busy := FALSE;
  Sts.CanAcceptFromElev := NOT Sts.Occ5 AND NOT Sts.WaitingPickup;
  Sts.CanAdvance := Sts.Occ5 AND NOT Sts.Occ6 AND NOT Sts.WaitingPickup;
  Sts.SingleUnloadReady := (Sts.Occ5 OR Sts.Occ6 OR Sts.Occ7) AND NOT Sts.WaitingPickup;
  source := 0; target := 0; unload := FALSE;
  IF Cmd.EnableAuto AND Inp.BeltsStopped AND NOT Inp.StopWarning THEN
   IF unloadEdge.Q AND Sts.SingleUnloadReady THEN
    unload := TRUE; target := 7;
    IF Sts.Occ7 THEN source := 7; ELSIF Sts.Occ6 THEN source := 6; ELSE source := 5; END_IF;
   ELSIF requestEdge.Q AND Sts.CanAcceptFromElev THEN source := 4; target := 5;
   ELSIF advanceEdge.Q AND Sts.CanAdvance THEN source := 5; target := 6;
   END_IF;
  END_IF;
  IF source <> 0 THEN
   Outp.AcceptedPulse := TRUE; Sts.Busy := TRUE; Sts.PickupSeen := FALSE;
   seenSource := FALSE; sourceGone := FALSE;
   IF source = 7 THEN Sts.WaitingPickup := TRUE; Sts.State := E_Bottom567State.WAIT_RECEIPT;
   ELSE Sts.State := E_Bottom567State.PRECHECK; END_IF;
  END_IF;
 E_Bottom567State.PRECHECK:
  IF Inp.BeltsStopped THEN
   Outp.HoldStop5 := source <> 5; Outp.HoldStop6 := source <> 6;
   stopsReady := ((Outp.HoldStop5 AND Inp.Stop5Holding) OR (NOT Outp.HoldStop5 AND Inp.Stop5Released)) AND
    ((Outp.HoldStop6 AND Inp.Stop6Holding) OR (NOT Outp.HoldStop6 AND Inp.Stop6Released));
   IF stopsReady AND NOT Inp.StopWarning THEN Sts.State := E_Bottom567State.RUN_STEP; END_IF;
  END_IF;
 E_Bottom567State.RUN_STEP:
  Outp.HoldStop5 := source <> 5; Outp.HoldStop6 := source <> 6;
  (* Stopery zachowuja cel podczas ruchu; nie zmieniamy ich na podstawie czujnikow ladunku. *)
  IF NOT Inp.StopWarning THEN
   Outp.ConvRun := TRUE; Outp.ElevConv_RunBwd := source = 4;
   sourceSensor := Inp.sElevatorEmptied_raw;
   IF source = 5 THEN sourceSensor := Inp.sPos5_raw; END_IF;
   IF source = 6 THEN sourceSensor := Inp.sPos6_raw; END_IF;
   IF sourceSensor THEN seenSource := TRUE; END_IF;
   IF seenSource AND NOT sourceSensor THEN sourceGone := TRUE; END_IF;
   targetSensor := Inp.sPos5_raw;
   IF target = 6 THEN targetSensor := Inp.sPos6_raw; END_IF;
   IF target = 7 THEN targetSensor := Inp.sPos7_raw; END_IF;
   arriveTimer(IN := targetSensor AND sourceGone, PT := Cfg.tSensorStable);
   moveTimer(IN := TRUE, PT := Cfg.tStepTimeout);
   IF arriveTimer.Q THEN
    Outp.ConvRun := FALSE; Outp.ElevConv_RunBwd := FALSE;
    moveTimer(IN := FALSE); arriveTimer(IN := FALSE); Sts.State := E_Bottom567State.WAIT_STOP;
   ELSIF moveTimer.Q THEN
    Diag.Fault := TRUE; Diag.Code := E_Bottom567Fault.MOVE_TIMEOUT;
    Diag.Text := 'ST.3: brak potwierdzenia przejazdu ladunku.';
    Outp.ConvRun := FALSE; Outp.ElevConv_RunBwd := FALSE; Sts.Known := FALSE; Sts.State := E_Bottom567State.FAULT;
   END_IF;
  ELSE moveTimer(IN := FALSE); arriveTimer(IN := FALSE); END_IF;
 E_Bottom567State.WAIT_STOP:
  Outp.HoldStop5 := source <> 5; Outp.HoldStop6 := source <> 6;
  stopTimer(IN := Inp.BeltsStopped, PT := Cfg.tMotorStopDelay);
  IF stopTimer.Q THEN stopTimer(IN := FALSE); Sts.State := E_Bottom567State.LOCK_STOPS; END_IF;
 E_Bottom567State.LOCK_STOPS:
  IF Inp.BeltsStopped AND Inp.Stop5Holding AND Inp.Stop6Holding AND NOT Inp.StopWarning THEN
   IF source = 5 THEN Sts.Occ5 := FALSE; END_IF;
   IF source = 6 THEN Sts.Occ6 := FALSE; END_IF;
   IF target = 5 THEN Sts.Occ5 := TRUE; END_IF;
   IF target = 6 THEN Sts.Occ6 := TRUE; END_IF;
   IF target = 7 THEN Sts.Occ7 := TRUE; END_IF;
   IF unload THEN Sts.WaitingPickup := TRUE; Sts.State := E_Bottom567State.WAIT_RECEIPT;
   ELSE Sts.State := E_Bottom567State.COMPLETE; END_IF;
  END_IF;
 E_Bottom567State.WAIT_RECEIPT:
  receiptOn(IN := Inp.sPos7_raw AND Inp.BeltsStopped, PT := Cfg.tSensorStable);
  receiptOff(IN := NOT Inp.sPos7_raw AND Sts.PickupSeen AND Inp.BeltsStopped, PT := Cfg.tSensorStable);
  IF receiptOn.Q THEN Sts.PickupSeen := TRUE; END_IF;
  IF receiptOff.Q THEN
   Sts.Occ7 := FALSE; Sts.WaitingPickup := FALSE;
   receiptOn(IN := FALSE); receiptOff(IN := FALSE); Sts.State := E_Bottom567State.COMPLETE;
  END_IF;
 E_Bottom567State.COMPLETE:
  Outp.StepDonePulse := TRUE;
  Outp.DischargeDonePulse := source = 4;
  Outp.SingleUnloadDonePulse := unload;
  Sts.Busy := FALSE; Sts.State := E_Bottom567State.IDLE;
 E_Bottom567State.FAULT:
  Sts.Known := FALSE;
END_CASE;
Outp.AlarmQueueFull := Sts.Occ5 AND Sts.Occ6;
