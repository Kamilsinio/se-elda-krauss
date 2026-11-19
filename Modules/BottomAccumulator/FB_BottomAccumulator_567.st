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
 dischargeAccepted : BOOL;
 unloadAccepted : BOOL;
 advanceAccepted : BOOL;
 motionCfg : ST_Bottom567Cfg;
 receiptStable : TIME;
 lastDischargeId : UDINT;
 lastUnloadId : UDINT;
 lastAdvanceId : UDINT;
 motionId : UDINT;
 receiptId : UDINT;
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
IF NOT Cmd.DischargeReq THEN dischargeAccepted := FALSE; END_IF;
IF NOT Cmd.SingleUnloadReq THEN unloadAccepted := FALSE; END_IF;
IF NOT Cmd.AdvanceReq THEN advanceAccepted := FALSE; END_IF;
requestEdge(CLK := Cmd.DischargeReq);
unloadEdge(CLK := Cmd.SingleUnloadReq);
advanceEdge(CLK := Cmd.AdvanceReq);
Outp.SingleUnloadIssuedPulse := FALSE; Outp.MaterialMovedPulse := FALSE;
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
 Sts.CanAcceptFromElev := NOT Sts.Occ5;
 Sts.CanAdvance := Sts.Occ5 AND NOT Sts.Occ6;
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
  Sts.CanAcceptFromElev := NOT Sts.Occ5;
  Sts.CanAdvance := Sts.Occ5 AND NOT Sts.Occ6;
  Sts.SingleUnloadReady := (Sts.Occ5 OR Sts.Occ6 OR Sts.Occ7) AND NOT Sts.WaitingPickup;
  source := 0; target := 0; unload := FALSE;
  IF Cmd.EnableAuto AND Inp.BeltsStopped AND NOT Inp.StopWarning THEN
   IF Cmd.SingleUnloadReq AND (NOT unloadAccepted OR (Cmd.UnloadId <> 0 AND Cmd.UnloadId <> lastUnloadId)) AND Sts.SingleUnloadReady THEN
    unload := TRUE; target := 7;
    IF Sts.Occ7 THEN source := 7; ELSIF Sts.Occ6 THEN source := 6;
    ELSE source := 5; target := 6; END_IF;
   ELSIF Cmd.DischargeReq AND (NOT dischargeAccepted OR (Cmd.DischargeId <> 0 AND Cmd.DischargeId <> lastDischargeId)) AND Sts.CanAcceptFromElev THEN source := 4; target := 5;
   ELSIF Cmd.AdvanceReq AND (NOT advanceAccepted OR (Cmd.AdvanceId <> 0 AND Cmd.AdvanceId <> lastAdvanceId)) AND Sts.CanAdvance THEN source := 5; target := 6;
   END_IF;
  END_IF;
  IF source <> 0 THEN
   IF unload THEN motionId := Cmd.UnloadId; lastUnloadId := Cmd.UnloadId; receiptId := motionId;
   ELSIF source = 4 THEN motionId := Cmd.DischargeId; lastDischargeId := Cmd.DischargeId;
   ELSE motionId := Cmd.AdvanceId; lastAdvanceId := Cmd.AdvanceId; END_IF;
   Outp.AcceptedId := motionId;
   motionCfg := Cfg;
   IF unload THEN receiptStable := Cfg.tSensorStable; unloadAccepted := TRUE; Sts.PickupSeen := FALSE;
   ELSIF source = 4 THEN dischargeAccepted := TRUE; ELSE advanceAccepted := TRUE; END_IF;
   Outp.AcceptedPulse := TRUE; Sts.Busy := TRUE;
   seenSource := FALSE; sourceGone := FALSE;
   IF source = 7 THEN Sts.WaitingPickup := TRUE; Outp.SingleUnloadIssuedPulse := TRUE; Sts.State := E_Bottom567State.IDLE;
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
   arriveTimer(IN := targetSensor AND sourceGone, PT := motionCfg.tSensorStable);
   moveTimer(IN := TRUE, PT := motionCfg.tStepTimeout);
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
  stopTimer(IN := Inp.BeltsStopped, PT := motionCfg.tMotorStopDelay);
  IF stopTimer.Q THEN stopTimer(IN := FALSE); Sts.State := E_Bottom567State.LOCK_STOPS; END_IF;
 E_Bottom567State.LOCK_STOPS:
  IF Inp.BeltsStopped AND Inp.Stop5Holding AND Inp.Stop6Holding AND NOT Inp.StopWarning THEN
   IF source = 5 THEN Sts.Occ5 := FALSE; END_IF;
   IF source = 6 THEN Sts.Occ6 := FALSE; END_IF;
   IF target = 5 THEN Sts.Occ5 := TRUE; END_IF;
   IF target = 6 THEN Sts.Occ6 := TRUE; END_IF;
   IF target = 7 THEN Sts.Occ7 := TRUE; END_IF;
   Outp.MaterialMovedPulse := TRUE; Outp.MaterialSource := source; Outp.MaterialTarget := target;
   IF unload AND target = 6 THEN
    (* Ten sam identyfikator wydania. Po postoju na P6 odblokuj drugi stoper. *)
    source := 6; target := 7; seenSource := FALSE; sourceGone := FALSE;
    Sts.State := E_Bottom567State.PRECHECK;
   ELSIF unload THEN Sts.WaitingPickup := TRUE; Outp.SingleUnloadIssuedPulse := TRUE; Sts.State := E_Bottom567State.IDLE;
   ELSE Sts.State := E_Bottom567State.COMPLETE; END_IF;
  END_IF;
 E_Bottom567State.WAIT_RECEIPT:
  Sts.State := E_Bottom567State.IDLE;
 E_Bottom567State.COMPLETE:
  Outp.StepDonePulse := TRUE;
  Outp.DischargeDonePulse := source = 4;
  IF source = 4 THEN Outp.DischargeDoneId := motionId; ELSE Outp.AdvanceDoneId := motionId; END_IF;
  Outp.SingleUnloadDonePulse := unload;
  Sts.Busy := FALSE; Sts.State := E_Bottom567State.IDLE;
 E_Bottom567State.FAULT:
  Sts.Known := FALSE;
END_CASE;
Outp.AlarmQueueFull := Sts.Occ5 AND Sts.Occ6;

(* Potwierdzenie odbioru jest rozliczane także podczas innych operacji bufora. *)
receiptOn(IN := Sts.WaitingPickup AND Inp.sPos7_raw AND Inp.Valid, PT := receiptStable);
receiptOff(IN := Sts.WaitingPickup AND NOT Inp.sPos7_raw AND Sts.PickupSeen AND Inp.Valid, PT := receiptStable);
IF receiptOn.Q THEN Sts.PickupSeen := TRUE; END_IF;
IF receiptOff.Q THEN
 Sts.Occ7 := FALSE; Sts.WaitingPickup := FALSE; Sts.PickupSeen := FALSE;
 Outp.SingleUnloadDonePulse := TRUE; Outp.UnloadDoneId := receiptId;
 receiptOn(IN := FALSE); receiptOff(IN := FALSE);
END_IF;
