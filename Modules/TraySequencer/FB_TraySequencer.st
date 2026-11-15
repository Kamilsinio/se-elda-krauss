(* PLC v2: zadania zarejestrowane sa oddzielone od ruchu; bez starego ACK. *)
FUNCTION_BLOCK FB_TraySequencer
VAR_INPUT
    Cfg : ST_TraySeqCfg;
    Cmd : ST_TraySeqCmd;
    Inp : ST_TraySeqIn;
END_VAR
VAR_IN_OUT
    Context : ST_RobotContext;
END_VAR
VAR_OUTPUT
    Outp : ST_TraySeqOut;
    Sts : ST_TraySeqStatus;
    Diag : ST_TraySeqDiag;
END_VAR
VAR
    emptyOut : ST_TraySeqOut;
    moving : BOOL;
    p4Timer : TON;
END_VAR
Outp := emptyOut;
Sts.State := Context.trayStep;
p4Timer(IN := Cmd.Enable AND Cmd.SafetyOK AND Inp.Session AND NOT Cmd.RecoveryRequired AND
    Sts.State = E_TraySeqState.CHECK_P4_OCCUPIED AND NOT Inp.ind_container_in_pos_4 AND NOT Inp.Warning AND
    NOT Inp.RobotReserved AND Inp.RobotClear, PT := Cfg.tP4ConfirmTimeout);
Sts.TrayCount := TO_UINT(Context.blisterCount MOD 65536);
Sts.StackCount := TO_UINT(Context.stackCount MOD 65536);
IF Cmd.ResetFault AND NOT Inp.Elev_Fault AND NOT Inp.Bottom_Fault THEN
    Diag.Fault := FALSE; Diag.FaultCode := E_TraySeqFault.NONE; Diag.FaultText := '';
END_IF;
IF Inp.Elev_Fault OR Inp.Bottom_Fault THEN
    Diag.Fault := TRUE; Diag.FaultCode := E_TraySeqFault.ELEVATOR_FAULT;
    Diag.FaultText := 'Blad windy lub transferu.';
END_IF;
IF p4Timer.Q THEN
    Diag.Fault := TRUE;
    Diag.FaultCode := E_TraySeqFault.P4_NOT_DETECTED;
    Diag.FaultText := 'Brak P4 po zarejestrowanym odlozeniu blistra.';
END_IF;
IF NOT Cmd.Enable OR NOT Cmd.SafetyOK OR NOT Inp.Session OR Cmd.RecoveryRequired OR Diag.Fault THEN
    Outp.Elev_Stop := TRUE; Sts.Busy := FALSE; RETURN;
END_IF;
IF NOT Cmd.NewOperations AND NOT Cmd.FinishOperations THEN RETURN; END_IF;
Outp.AutoRunning := TRUE;
Outp.TopFlow_Enable := TRUE;
Outp.Bottom_Enable := TRUE;
moving := NOT Inp.RobotReserved AND Inp.RobotClear AND NOT Inp.Warning;
Outp.SourceReady := Inp.TopFlow_StackReadyAtP3;
IF Inp.TaskPicked THEN
    Outp.ConsumePicked := TRUE;
    IF Inp.SourceEmptyConfirmed AND moving THEN Outp.TopFlow_StackConsumed := TRUE; END_IF;
END_IF;
IF Inp.TaskFinished THEN Outp.ConsumeFinished := TRUE; END_IF;
CASE Sts.State OF
    E_TraySeqState.DISABLED:
        IF Inp.Elev_AtTop THEN Sts.State := E_TraySeqState.WAIT_STACK_READY; ELSE Sts.State := E_TraySeqState.ELEV_RETURN_TOP; END_IF;
    E_TraySeqState.IDLE:
        Sts.State := E_TraySeqState.WAIT_STACK_READY;
    E_TraySeqState.WAIT_STACK_READY:
        IF Inp.TopFlow_StackReadyAtP3 THEN Outp.NewStackReady := TRUE; Sts.State := E_TraySeqState.WAIT_TRAY_DONE; END_IF;
    E_TraySeqState.SIGNAL_ROBOT:
        Sts.State := E_TraySeqState.WAIT_TRAY_DONE;
    E_TraySeqState.WAIT_TRAY_DONE:
        Outp.ElevatorReady := NOT Inp.Elev_Busy AND Inp.PositionerHome AND NOT Inp.TaskPlaced;
        IF Inp.TaskPlaced THEN Sts.State := E_TraySeqState.CHECK_P4_OCCUPIED; ELSIF Inp.TaskStack THEN Sts.State := E_TraySeqState.RETRACT_POS; END_IF;
    E_TraySeqState.CHECK_P4_OCCUPIED:
        IF moving AND Inp.ind_container_in_pos_4 THEN Context.trayAction := TRUE; Sts.State := E_TraySeqState.POS_M6_CYCLE; END_IF;
    E_TraySeqState.POS_M6_CYCLE:
        IF moving THEN
            IF Context.trayAction AND Inp.PositionerWork THEN Context.trayAction := FALSE;
            ELSIF NOT Context.trayAction AND Inp.PositionerHome THEN Sts.State := E_TraySeqState.ELEV_TO_EDGE; END_IF;
        END_IF;
    E_TraySeqState.ELEV_TO_EDGE:
        Outp.Elev_AutoTarget := E_ElevatorTarget.posContainerEdge;
        Outp.Elev_AutoGo := moving AND Inp.Elev_CommandReady AND Inp.ind_container_in_pos_4;
        IF moving AND NOT Inp.ind_container_in_pos_4 AND NOT Inp.Elev_Busy THEN Outp.ConsumePlaced := TRUE; Sts.State := E_TraySeqState.WAIT_TRAY_DONE; END_IF;
    E_TraySeqState.RETRACT_POS:
        IF moving THEN Context.trayAction := FALSE; IF Inp.PositionerHome THEN Sts.State := E_TraySeqState.ELEV_TO_BOTTOM; END_IF; END_IF;
    E_TraySeqState.ELEV_TO_BOTTOM:
        Outp.Elev_AutoTarget := E_ElevatorTarget.posBottom;
        Outp.Elev_AutoGo := moving AND Inp.Elev_CommandReady AND NOT Inp.Elev_AtBottom;
        IF Inp.Elev_AtBottom AND NOT Inp.Elev_Busy THEN Sts.State := E_TraySeqState.DISCHARGE; END_IF;
    E_TraySeqState.DISCHARGE:
        Outp.Bottom_DischargeReq := moving AND Inp.Bottom_CanAccept;
        IF Inp.Bottom_DischargeDonePulse THEN Outp.ConsumeStack := TRUE; Sts.State := E_TraySeqState.WAIT_ELEV_EMPTY; END_IF;
    E_TraySeqState.WAIT_ELEV_EMPTY:
        Sts.State := E_TraySeqState.ELEV_RETURN_TOP;
    E_TraySeqState.ELEV_RETURN_TOP:
        Outp.Elev_AutoTarget := E_ElevatorTarget.posTop;
        Outp.Elev_AutoGo := moving AND Inp.Elev_CommandReady AND NOT Inp.Elev_AtTop;
        IF Inp.Elev_AtTop AND NOT Inp.Elev_Busy THEN Outp.NewStackReady := TRUE; Sts.State := E_TraySeqState.WAIT_TRAY_DONE; END_IF;
    ELSE
        Diag.Fault := TRUE; Diag.FaultCode := E_TraySeqFault.ROBOT_NOT_READY;
        Diag.FaultText := 'Nieznany stan, wymagane recovery.';
END_CASE;
Outp.M6_Extend := Context.trayAction;
IF Inp.RobotReserved OR NOT Inp.RobotClear OR Inp.Warning THEN Outp.Elev_AutoGo := FALSE; END_IF;
Sts.Busy := Inp.Elev_Busy OR Inp.Bottom_Busy OR Inp.TaskPlaced OR Inp.TaskStack;
Context.trayStep := Sts.State;
