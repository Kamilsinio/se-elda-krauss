(* PLC v2: zadania zarejestrowane sa oddzielone od ruchu; bez starego ACK. *)
FUNCTION_BLOCK FB_BoxSequencer
VAR_INPUT
    Cfg : ST_BoxSeqCfg;
    Cmd : ST_BoxSeqCmd;
    Inp : ST_BoxSeqIn;
END_VAR
VAR_IN_OUT
    Context : ST_RobotContext;
END_VAR
VAR_OUTPUT
    Outp : ST_BoxSeqOut;
    Sts : ST_BoxSeqStatus;
    Diag : ST_BoxSeqDiag;
END_VAR
VAR
    emptyOut : ST_BoxSeqOut;
    moving : BOOL;
END_VAR
Outp := emptyOut;
Sts.State := Context.boxStep;
Sts.BoxCount := TO_UINT(Context.stackCount MOD 65536);
IF Cmd.ResetFault AND NOT Inp.Elev_Fault AND NOT Inp.Bottom_Fault THEN
    Diag.Fault := FALSE; Diag.FaultCode := E_BoxSeqFault.NONE; Diag.FaultText := '';
END_IF;
IF Inp.Elev_Fault OR Inp.Bottom_Fault THEN
    Diag.Fault := TRUE; Diag.FaultCode := E_BoxSeqFault.ELEVATOR_FAULT;
    Diag.FaultText := 'Blad windy lub transferu.';
END_IF;
IF NOT Cmd.Enable OR NOT Cmd.SafetyOK OR NOT Inp.Session OR Cmd.RecoveryRequired OR Diag.Fault THEN
    Outp.Elev_Stop := TRUE; Sts.Busy := FALSE; RETURN;
END_IF;
IF NOT Cmd.NewOperations AND NOT Cmd.FinishOperations THEN RETURN; END_IF;
Outp.AutoRunning := TRUE;
Outp.TopFlow_Enable := TRUE;
Outp.Bottom_Enable := TRUE;
moving := NOT Inp.RobotReserved AND Inp.RobotClear AND NOT Inp.Warning;
CASE Sts.State OF
    E_BoxSeqState.DISABLED:
        IF Inp.Elev_AtTop THEN Sts.State := E_BoxSeqState.REQUEST_ELEVATOR_FEED; ELSE Sts.State := E_BoxSeqState.ELEV_RETURN_TOP; END_IF;
    E_BoxSeqState.IDLE:
        Sts.State := E_BoxSeqState.REQUEST_ELEVATOR_FEED;
    E_BoxSeqState.REQUEST_ELEVATOR_FEED:
        Outp.TopFlow_Elev_RequestFeed := moving;
        Outp.TopFlow_Elev_CanAccept := moving AND Inp.Elev_AtTop AND NOT Inp.ind_container_in_pos_4;
        IF Inp.TopFlow_ElevDeliveredAtP4 AND NOT Inp.TopFlow_Busy THEN Sts.State := E_BoxSeqState.POS_M7_FWD; END_IF;
    E_BoxSeqState.FEED_ELEVATOR:
        Sts.State := E_BoxSeqState.REQUEST_ELEVATOR_FEED;
    E_BoxSeqState.POS_M7_FWD:
        Outp.M7_Extend := TRUE;
        IF moving AND Inp.PositionerWork THEN Sts.State := E_BoxSeqState.ELEV_TO_EDGE; END_IF;
    E_BoxSeqState.ELEV_TO_EDGE:
        Outp.M7_Extend := TRUE;
        Outp.Elev_AutoTarget := E_ElevatorTarget.posContainerEdge;
        Outp.Elev_AutoGo := moving AND Inp.Elev_CommandReady AND Inp.ind_container_in_pos_4;
        IF moving AND NOT Inp.ind_container_in_pos_4 AND NOT Inp.Elev_Busy THEN Outp.NewStackReady := TRUE; Sts.State := E_BoxSeqState.WAIT_PALLET_DONE; END_IF;
    E_BoxSeqState.SIGNAL_ROBOT:
        Sts.State := E_BoxSeqState.WAIT_PALLET_DONE;
    E_BoxSeqState.WAIT_PALLET_DONE:
        Outp.M7_Extend := TRUE;
        Outp.ElevatorReady := NOT Inp.Elev_Busy AND Inp.PositionerWork;
        IF Inp.TaskStack THEN Outp.ElevatorReady := FALSE; Sts.State := E_BoxSeqState.RETRACT_M7; END_IF;
    E_BoxSeqState.RETRACT_M7:
        IF moving AND Inp.PositionerHome THEN Sts.State := E_BoxSeqState.ELEV_TO_BOTTOM; END_IF;
    E_BoxSeqState.ELEV_TO_BOTTOM:
        Outp.Elev_AutoTarget := E_ElevatorTarget.posBottom;
        Outp.Elev_AutoGo := moving AND Inp.Elev_CommandReady AND NOT Inp.Elev_AtBottom;
        IF Inp.Elev_AtBottom AND NOT Inp.Elev_Busy THEN Sts.State := E_BoxSeqState.DISCHARGE; END_IF;
    E_BoxSeqState.DISCHARGE:
        Outp.Bottom_DischargeReq := moving AND Inp.Bottom_CanAccept;
        IF Inp.Bottom_DischargeDonePulse THEN Outp.ConsumeStack := TRUE; Sts.State := E_BoxSeqState.WAIT_ELEV_EMPTY; END_IF;
    E_BoxSeqState.WAIT_ELEV_EMPTY:
        Sts.State := E_BoxSeqState.ELEV_RETURN_TOP;
    E_BoxSeqState.ELEV_RETURN_TOP:
        Outp.Elev_AutoTarget := E_ElevatorTarget.posTop;
        Outp.Elev_AutoGo := moving AND Inp.Elev_CommandReady AND NOT Inp.Elev_AtTop;
        IF Inp.Elev_AtTop AND NOT Inp.Elev_Busy THEN Sts.State := E_BoxSeqState.REQUEST_ELEVATOR_FEED; END_IF;
    ELSE
        Diag.Fault := TRUE; Diag.FaultCode := E_BoxSeqFault.ROBOT_NOT_READY;
        Diag.FaultText := 'Nieznany stan, wymagane recovery.';
END_CASE;

IF Inp.RobotReserved OR NOT Inp.RobotClear OR Inp.Warning THEN Outp.Elev_AutoGo := FALSE; END_IF;
Sts.Busy := Inp.Elev_Busy OR Inp.Bottom_Busy OR Inp.TaskPlaced OR Inp.TaskStack;
Context.boxStep := Sts.State;
