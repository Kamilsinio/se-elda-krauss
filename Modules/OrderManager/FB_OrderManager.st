(* Stop dokancza, Manual jest odrzucany do postoju. Brak zdalnego Start. *)
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
END_VAR
VAR_IN_OUT
    Context : ST_RobotContext;
    Drain : ST_RobotDrain;
END_VAR
VAR_OUTPUT
    Sts : ST_RobotOrderStatus;
END_VAR
VAR
    startEdge : R_TRIG;
    stopLatched : BOOL;
    running : BOOL;
    manualMode : BOOL;
    drainInFlight : BOOL;
    drainAccepted : BOOL;
END_VAR
startEdge(CLK := PhysicalStart);
Sts.startAccepted := FALSE;
Sts.reason := 0;
Sts.settled := OperationsSettled AND NOT TransferBusy AND AreasClear;
IF Cmd.applyQuantity THEN
    IF NOT Context.orderActive AND StationIdle AND Sts.settled AND Cmd.quantity > 0 AND NOT RecoveryRequired THEN
        Context.batchCount := Cmd.quantity;
    ELSE Sts.reason := 30;
    END_IF;
END_IF;
IF Cmd.openOrder THEN
    IF NOT Context.orderActive AND NOT RecoveryRequired AND Context.valid AND Context.batchCount > 0 AND
       ((Cmd.program = 1) OR (Cmd.program = 2)) AND NOT manualMode AND Sts.settled THEN
        Context.orderActive := TRUE; Context.ending := FALSE; Context.program := Cmd.program;
    ELSE Sts.reason := 30;
    END_IF;
END_IF;
IF Cmd.manual THEN
    IF NOT running AND Sts.settled AND NOT Context.ending THEN manualMode := TRUE;
    ELSE Sts.reason := 30;
    END_IF;
END_IF;
IF Cmd.automatic THEN
    IF NOT running AND Sts.settled THEN manualMode := FALSE; ELSE Sts.reason := 30; END_IF;
END_IF;
IF Cmd.robotEnable THEN
    IF NOT running AND HomeValid AND Sts.settled THEN Context.withRobot := TRUE; ELSE Sts.reason := 30; END_IF;
END_IF;
IF Cmd.robotDisable THEN
    IF NOT running AND HomeValid AND Sts.settled THEN Context.withRobot := FALSE; ELSE Sts.reason := 30; END_IF;
END_IF;
IF Cmd.endOrder AND Context.orderActive THEN Context.ending := TRUE; END_IF;
IF PhysicalStop OR Context.ending THEN stopLatched := TRUE; END_IF;
IF Critical OR RecoveryRequired OR NOT Session OR NOT ProcessOK THEN
    running := FALSE;
    stopLatched := TRUE;
END_IF;
IF stopLatched AND Sts.settled THEN running := FALSE; END_IF;
Sts.canStart := Context.valid AND Context.orderActive AND Context.withRobot AND NOT Context.ending AND
    NOT manualMode AND Session AND ProgramOK AND HomeValid AND ProcessOK AND
    NOT Critical AND NOT RecoveryRequired AND (Sts.settled OR
    (RecoveryResumeAllowed AND NOT TransferBusy AND AreasClear));
IF startEdge.Q AND Sts.canStart AND NOT PhysicalStop THEN
    running := TRUE;
    stopLatched := FALSE;
    Sts.startToken := TO_UINT((TO_UDINT(Sts.startToken) + 1) MOD 65536);
    Sts.startAccepted := TRUE;
END_IF;
Drain.request := Context.orderActive AND Context.ending AND Sts.settled AND NOT RecoveryRequired;
IF NOT Drain.request OR NOT Drain.connected THEN drainInFlight := FALSE; drainAccepted := FALSE; END_IF;
IF Drain.request AND Drain.connected AND NOT Drain.accepted AND NOT Drain.busy AND NOT Drain.done AND NOT Drain.fault THEN
    drainInFlight := TRUE;
END_IF;
IF drainInFlight AND Drain.request AND Drain.accepted THEN drainAccepted := TRUE; END_IF;
IF Drain.request AND drainInFlight AND drainAccepted AND Drain.connected AND Drain.accepted AND Drain.done AND
   NOT Drain.busy AND NOT Drain.fault AND Drain.emptyConfirmed THEN
    Context.orderActive := FALSE; Context.ending := FALSE; running := FALSE;
    Drain.request := FALSE;
    drainInFlight := FALSE;
    drainAccepted := FALSE;
END_IF;
Sts.manual := manualMode;
Sts.running := running;
Sts.stopping := stopLatched AND NOT Sts.settled;
Sts.stopped := NOT running AND Sts.settled;
Sts.newPermit := running AND NOT stopLatched AND NOT Context.ending AND Session AND
    ProgramOK AND ProcessOK AND NOT RecoveryRequired AND NOT Critical AND Context.withRobot AND NOT manualMode;
Sts.finishPermit := Context.orderActive AND Context.withRobot AND NOT manualMode AND
    Session AND ProgramOK AND ProcessOK AND NOT RecoveryRequired AND NOT Critical AND
    running;
