(* Zlecenie, Stop po operacjach i trwale zadanie oprozniania. *)
FUNCTION_BLOCK FB_OrderManager
VAR_INPUT
 Cmd : ST_RobotCommands;
 PhysicalStart : BOOL;
 PhysicalStop : BOOL;
 Session : BOOL;
 ProgramOK : BOOL;
 HomeValid : BOOL;
 ProcessOK : BOOL;
 RecoveryRequired : BOOL;
 Critical : BOOL;
 OperationsSettled : BOOL;
 TransferBusy : BOOL;
 AreasClear : BOOL;
 StationIdle : BOOL;
 RecoveryResumeAllowed : BOOL;
 NewOrderReady : BOOL;
END_VAR
VAR_IN_OUT
 Context : ST_RobotContext;
 Drain : ST_RobotDrain;
END_VAR
VAR_OUTPUT
 Sts : ST_RobotOrderStatus;
 AwaitingNew : BOOL;
END_VAR
VAR
 startEdge : R_TRIG;
 stopLatched : BOOL;
 running : BOOL;
 manualMode : BOOL;
 drainInFlight : BOOL;
 drainAccepted : BOOL;
 drainAuthorized : BOOL;
 autoDrainAfterFinish : BOOL;
 initialized : BOOL;
 ready : BOOL;
 initializeSequence : BOOL;
END_VAR
startEdge(CLK := PhysicalStart);
initializeSequence := FALSE;
Sts.startAccepted := FALSE; Sts.reason := 0;
Sts.settled := OperationsSettled AND NOT TransferBusy AND AreasClear;
ready := Session AND ProgramOK AND ProcessOK AND NOT Critical AND NOT RecoveryRequired;
IF NOT initialized THEN
 initialized := TRUE; drainAuthorized := FALSE; autoDrainAfterFinish := FALSE;
 IF Context.ending THEN Context.drainResumeRequired := TRUE; END_IF;
END_IF;
IF Cmd.applyQuantity THEN
 IF NOT Context.orderActive AND StationIdle AND Sts.settled AND Cmd.quantity > 0 AND NOT RecoveryRequired THEN Context.batchCount := Cmd.quantity;
 ELSE Sts.reason := 30; END_IF;
END_IF;
IF NewOrderReady THEN AwaitingNew := FALSE; END_IF;
IF Cmd.openOrder THEN
 IF NOT AwaitingNew AND NOT Context.orderActive AND NOT RecoveryRequired AND Context.valid AND Context.batchCount > 0 AND
  (Cmd.program_ = 1 OR Cmd.program_ = 2) AND NOT manualMode AND Sts.settled THEN
  initializeSequence := TRUE;
  Context.orderActive := TRUE; Context.ending := FALSE; Context.program_ := Cmd.program_;
  Context.drainRequested := FALSE; Context.drainResumeRequired := FALSE;
 ELSE Sts.reason := 30; END_IF;
END_IF;
IF Cmd.manual THEN
 IF NOT running AND NOT drainAuthorized AND Sts.settled THEN manualMode := TRUE;
 ELSE Sts.reason := 30; END_IF;
END_IF;
IF Cmd.automatic THEN
 IF NOT running AND Sts.settled THEN manualMode := FALSE; ELSE Sts.reason := 30; END_IF;
END_IF;
IF Cmd.robotEnable THEN
 IF NOT running AND NOT drainAuthorized AND HomeValid AND Sts.settled THEN Context.withRobot := TRUE; ELSE Sts.reason := 30; END_IF;
END_IF;
IF Cmd.robotDisable THEN
 IF NOT running AND NOT drainAuthorized AND HomeValid AND Sts.settled THEN Context.withRobot := FALSE; ELSE Sts.reason := 30; END_IF;
END_IF;
IF Cmd.endOrder AND Context.orderActive AND NOT Context.ending THEN
 Context.ending := TRUE;
 autoDrainAfterFinish := running AND NOT stopLatched AND NOT manualMode;
 Context.drainResumeRequired := NOT autoDrainAfterFinish;
END_IF;
IF PhysicalStop THEN
 stopLatched := TRUE; autoDrainAfterFinish := FALSE; drainAuthorized := FALSE;
END_IF;
IF Context.ending THEN stopLatched := TRUE; END_IF;
IF NOT ready THEN
 running := FALSE; stopLatched := TRUE; drainAuthorized := FALSE; autoDrainAfterFinish := FALSE;
END_IF;
IF stopLatched AND Sts.settled THEN running := FALSE; END_IF;
IF Context.orderActive AND Context.ending AND Sts.settled THEN
 Context.drainRequested := TRUE;
 IF autoDrainAfterFinish AND ready AND NOT manualMode THEN
  drainAuthorized := TRUE; autoDrainAfterFinish := FALSE;
 END_IF;
END_IF;
Sts.canStart := Context.valid AND Context.orderActive AND Context.withRobot AND NOT manualMode AND ready AND HomeValid AND
 (Sts.settled OR (NOT Context.ending AND RecoveryResumeAllowed AND NOT TransferBusy AND AreasClear));
IF startEdge.Q AND Sts.canStart AND NOT PhysicalStop THEN
 IF Context.ending THEN drainAuthorized := TRUE; ELSE running := TRUE; stopLatched := FALSE; END_IF;
 Sts.startToken := TO_UINT((TO_UDINT(Sts.startToken) + 1) MOD 65536);
 Sts.startAccepted := TRUE;
END_IF;
Drain.request := Context.orderActive AND Context.ending AND Context.drainRequested;
Drain.runPermit := Drain.request AND drainAuthorized AND ready AND NOT manualMode AND Context.withRobot;
Drain.paused := Drain.request AND NOT Drain.runPermit;
Context.drainResumeRequired := Context.ending AND NOT drainAuthorized;
IF NOT Drain.request OR NOT Drain.connected THEN drainInFlight := FALSE; drainAccepted := FALSE; END_IF;
IF Drain.request AND Drain.connected AND NOT Drain.accepted AND NOT Drain.busy AND NOT Drain.done AND NOT Drain.fault THEN drainInFlight := TRUE; END_IF;
IF drainInFlight AND Drain.request AND Drain.accepted THEN drainAccepted := TRUE; END_IF;
IF Drain.request AND drainInFlight AND drainAccepted AND Drain.connected AND Drain.accepted AND Drain.done AND
 NOT Drain.busy AND NOT Drain.fault AND Drain.emptyConfirmed AND Sts.settled AND ready THEN
 initializeSequence := TRUE; AwaitingNew := TRUE;
 Context.stackId := TO_UINT((TO_UDINT(Context.stackId) + 1) MOD 65536);
 Context.orderActive := FALSE; Context.ending := FALSE; Context.drainRequested := FALSE;
 Context.drainResumeRequired := FALSE; running := FALSE; drainAuthorized := FALSE;
 Drain.request := FALSE; Drain.runPermit := FALSE; Drain.paused := FALSE;
 drainInFlight := FALSE; drainAccepted := FALSE;
END_IF;
IF initializeSequence THEN
 (* Nowe zlecenie inicjalizuje takze zamkniety kontekst starszej wersji. *)
 Context.boxStep := E_BoxSeqState.DISABLED; Context.trayStep := E_TraySeqState.DISABLED;
 Context.trayAction := FALSE; Context.stackFull := FALSE;
 Context.blisterCount := 0; Context.layerCount := 0;
END_IF;
Sts.manual := manualMode;
Sts.running := running;
Sts.stopping := stopLatched AND NOT Sts.settled;
Sts.stopped := NOT running AND NOT drainAuthorized AND Sts.settled;
Sts.newPermit := running AND NOT stopLatched AND NOT Context.ending AND ready AND Context.withRobot AND NOT manualMode;
Sts.finishPermit := Context.orderActive AND Context.withRobot AND NOT manualMode AND ready AND running;
