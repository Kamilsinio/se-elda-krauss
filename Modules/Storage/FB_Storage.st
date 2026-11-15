(* V401/V402: HOME otwarte, WORK zamkniete. Zwykly status nie zastepuje safety. *)
FUNCTION_BLOCK FB_Storage
VAR_INPUT
    Cfg : ST_StorageCfg;
    Cmd : ST_StorageCmd;
    Inp : ST_StorageIn;
END_VAR
VAR_OUTPUT
    Outp : ST_StorageOut;
    Sts : ST_StorageStatus;
    Diag : ST_StorageDiag;
END_VAR
VAR
    leftHome : TON;
    rightHome : TON;
    leftWork : TON;
    rightWork : TON;
    moveTimer : TON;
    leftMove : TON;
    rightMove : TON;
    wasManualHome : ARRAY[1..2] OF BOOL;
    wasManualWork : ARRAY[1..2] OF BOOL;
    button : R_TRIG;
    operatorRequest : BOOL;
    wantOpen : BOOL;
    valid : BOOL;
    contradiction : BOOL;
END_VAR
leftHome(IN := Inp.Left.valid AND Inp.Left.atHome AND NOT Inp.Left.atWork, PT := Cfg.tStable);
rightHome(IN := Inp.Right.valid AND Inp.Right.atHome AND NOT Inp.Right.atWork, PT := Cfg.tStable);
leftWork(IN := Inp.Left.valid AND Inp.Left.atWork AND NOT Inp.Left.atHome, PT := Cfg.tStable);
rightWork(IN := Inp.Right.valid AND Inp.Right.atWork AND NOT Inp.Right.atHome, PT := Cfg.tStable);
contradiction := (Inp.Left.atHome AND Inp.Left.atWork) OR (Inp.Right.atHome AND Inp.Right.atWork);
valid := Inp.Left.configured AND Inp.Left.valid AND Inp.Right.configured AND Inp.Right.valid AND
    Inp.Left.lossPolicyVerified AND Inp.Right.lossPolicyVerified AND Cfg.tStable > T#0ms AND Cfg.tM8Timeout > T#0ms;
Sts.RobotSideOpen := valid AND leftHome.Q AND rightHome.Q;
Sts.RobotSideClosed := valid AND leftWork.Q AND rightWork.Q;
Sts.Empty := Inp.Empty;
Sts.LowLevel := Inp.LowLevel;
button(CLK := Inp.BtnOpenClose);
IF Cmd.ResetFault AND NOT contradiction AND valid THEN
    Diag.Fault := FALSE; Diag.LeftFault := FALSE; Diag.RightFault := FALSE; Diag.Code := E_StorageFault.NONE; Diag.Text := '';
END_IF;
IF contradiction THEN
    Diag.Fault := TRUE; Diag.Code := E_StorageFault.SENSOR_CONTRADICTION;
    Diag.Text := 'V401/V402: sprzeczne krancowki.';
END_IF;
IF button.Q AND Cmd.Enable AND valid AND NOT Cmd.RobotReserved AND NOT Cmd.RobotAccessReq THEN
    operatorRequest := NOT operatorRequest;
END_IF;
wantOpen := Cmd.RobotAccessPermit AND Cmd.RobotAccessReq AND NOT operatorRequest AND NOT Inp.Empty;
Outp.Q_UnlockOperatorSide := FALSE;
Outp.Q_UnlockRobotSide := FALSE;
Sts.RobotAccessGranted := FALSE;
Sts.RobotAccessActive := Cmd.RobotReserved;
Sts.OperatorAccessActive := FALSE;
Sts.OperatorRequest := operatorRequest;
Sts.State := E_StorageState.DISABLED;
IF Cmd.Enable AND valid AND NOT Diag.Fault AND NOT Cmd.Manual THEN
    IF wantOpen AND Inp.RobotSideOpeningPermission AND Inp.Left.homeAllowed AND Inp.Right.homeAllowed THEN
        Outp.Q_V401Home := TRUE; Outp.Q_V401Work := FALSE;
        Outp.Q_V402Home := TRUE; Outp.Q_V402Work := FALSE;
        Outp.Q_UnlockRobotSide := TRUE;
        Sts.State := E_StorageState.ROBOT_OPENING;
        IF Sts.RobotSideOpen THEN Sts.State := E_StorageState.ROBOT_OPEN; END_IF;
        Sts.RobotAccessGranted := Sts.RobotSideOpen;
    ELSIF NOT Cmd.RobotReserved AND Inp.Left.workAllowed AND Inp.Right.workAllowed THEN
        Outp.Q_V401Home := FALSE; Outp.Q_V401Work := TRUE;
        Outp.Q_V402Home := FALSE; Outp.Q_V402Work := TRUE;
        Sts.State := E_StorageState.ROBOT_CLOSING;
        IF Sts.RobotSideClosed THEN
            Sts.State := E_StorageState.IDLE;
            IF operatorRequest AND Inp.OperatorSideOpeningPermission THEN
                Outp.Q_UnlockOperatorSide := TRUE;
                Sts.OperatorAccessActive := TRUE;
                Sts.State := E_StorageState.OPERATOR_UNLOCKED;
            END_IF;
        END_IF;
    END_IF;
END_IF;
IF Cmd.Manual AND Cmd.Enable AND valid AND NOT Diag.Fault THEN
    IF wasManualHome[1] OR wasManualWork[1] THEN Outp.Q_V401Home := Inp.Left.lossHome; Outp.Q_V401Work := Inp.Left.lossWork; END_IF;
    IF wasManualHome[2] OR wasManualWork[2] THEN Outp.Q_V402Home := Inp.Right.lossHome; Outp.Q_V402Work := Inp.Right.lossWork; END_IF;
    IF NOT Cmd.RobotReserved AND NOT operatorRequest THEN
        IF Cmd.ManualHome[1] AND NOT Cmd.ManualWork[1] AND Inp.Left.homeAllowed AND Inp.RobotSideOpeningPermission THEN
            Outp.Q_V401Home := TRUE; Outp.Q_V401Work := FALSE;
        ELSIF Cmd.ManualWork[1] AND NOT Cmd.ManualHome[1] AND Inp.Left.workAllowed THEN
            Outp.Q_V401Home := FALSE; Outp.Q_V401Work := TRUE;
        END_IF;
        IF Cmd.ManualHome[2] AND NOT Cmd.ManualWork[2] AND Inp.Right.homeAllowed AND Inp.RobotSideOpeningPermission THEN
            Outp.Q_V402Home := TRUE; Outp.Q_V402Work := FALSE;
        ELSIF Cmd.ManualWork[2] AND NOT Cmd.ManualHome[2] AND Inp.Right.workAllowed THEN
            Outp.Q_V402Home := FALSE; Outp.Q_V402Work := TRUE;
        END_IF;
    END_IF;
END_IF;
Sts.Busy := valid AND Cmd.Enable AND NOT Cmd.Manual AND ((wantOpen AND NOT Sts.RobotSideOpen) OR
    (NOT Cmd.RobotReserved AND NOT wantOpen AND NOT Sts.RobotSideClosed));
leftMove(IN := Cmd.Enable AND valid AND ((Outp.Q_V401Home AND NOT leftHome.Q) OR (Outp.Q_V401Work AND NOT leftWork.Q)), PT := Cfg.tM8Timeout);
rightMove(IN := Cmd.Enable AND valid AND ((Outp.Q_V402Home AND NOT rightHome.Q) OR (Outp.Q_V402Work AND NOT rightWork.Q)), PT := Cfg.tM8Timeout);
IF leftMove.Q THEN Diag.LeftFault := TRUE; END_IF;
IF rightMove.Q THEN Diag.RightFault := TRUE; END_IF;
IF Diag.LeftFault OR Diag.RightFault THEN
 Diag.Fault := TRUE; Diag.Code := E_StorageFault.M8_TIMEOUT;
 Diag.Text := 'V401: timeout lewej osłony.';
 IF Diag.RightFault THEN Diag.Text := 'V402: timeout prawej osłony.'; END_IF;
END_IF;
wasManualHome := Cmd.ManualHome; wasManualWork := Cmd.ManualWork;
IF NOT Cmd.Enable OR NOT valid OR Diag.Fault THEN
    Outp.Q_UnlockOperatorSide := FALSE; Outp.Q_UnlockRobotSide := FALSE;
    Sts.RobotAccessGranted := FALSE;
    IF Inp.Left.lossPolicyVerified THEN Outp.Q_V401Home := Inp.Left.lossHome; Outp.Q_V401Work := Inp.Left.lossWork; END_IF;
    IF Inp.Right.lossPolicyVerified THEN Outp.Q_V402Home := Inp.Right.lossHome; Outp.Q_V402Work := Inp.Right.lossWork; END_IF;
END_IF;
Outp.Q_LEDOpenClose := operatorRequest OR Sts.Busy OR Diag.Fault;
