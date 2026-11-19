FUNCTION_BLOCK FB_TopFlowManager
VAR_INPUT
    Cfg : ST_TopFlowCfg;
    Cmd : ST_TopFlowCmd;
    Inp : ST_TopFlowIn;
END_VAR
VAR_OUTPUT
    Outp : ST_TopFlowOut;
    Sts  : ST_TopFlowStatus;
    Diag : ST_TopFlowDiag;
END_VAR
VAR
    rPos1Accept : R_TRIG;
    fPos2Fall : F_TRIG;
    xP2SeenForP1 : BOOL;
    xP2PassedForP1 : BOOL;
    xP1TransferCanRelease : BOOL;

    // Timery
    tStopDelay  : TON;
    tStopperTO  : TON;
    tMoveTO     : TON;

    // plan ruchu
    planned : BOOL;
    motionCfg : ST_TopFlowCfg;
    desiredHoldP1 : BOOL;
    desiredHoldP2 : BOOL;
    desiredHoldP3 : BOOL;
    desiredM5     : BOOL;  // żądana pozycja M5 (TrayMode+TG_P3)
    p1Ready       : BOOL;
    xStackConsumedPending : BOOL;

    // pomocnicze
    allStoppersInPos : BOOL;
    permissive : BOOL;

    // “stabilne” czujniki do INIT/IDLE (opcjonalnie)
    tPos1Stable : TON;
    tPos2Stable : TON;
    tPos3Stable : TON;
    sPos1_stable : BOOL;
    sPos2_stable : BOOL;
    sPos3_stable : BOOL;
END_VAR

Outp.TransferDonePulse := FALSE;

(* Status jest zapisywany tylko wewnatrz FB. Recovery odtwarza zajetosc,
   gdy obraz wejsc jest wazny i oba transportery potwierdzaja postoj. *)
IF Inp.Reconcile AND Inp.Valid AND Inp.BeltsStopped THEN
    Sts.OccP1 := Inp.Restored[1];
    Sts.OccP2 := Inp.Restored[2];
    Sts.OccP3 := Inp.Restored[3];
    Sts.State := E_TopFlowState.IDLE;
END_IF;

// --- 1) Permisywy ---
permissive := Cmd.EnableAuto AND Cmd.SafetyOK AND (NOT Diag.Fault);

// Przejazd P2 pamiętamy także podczas wyhamowania po pauzie.
fPos2Fall(CLK := Inp.LoadBarrierBlocked);
xP1TransferCanRelease := (Sts.State = E_TopFlowState.RUN) AND
                         (Sts.SrcPos = E_TopPos.P1) AND
                         Inp.LoadBarrierValid AND
                         (NOT Cmd.EmptyingMode);
IF xP1TransferCanRelease THEN
    IF permissive AND Inp.TopConveyorRunning AND Inp.LoadBarrierBlocked THEN
        xP2SeenForP1 := TRUE;
    END_IF;
    IF Inp.LoadBarrierValid AND xP2SeenForP1 AND fPos2Fall.Q THEN
        xP2PassedForP1 := TRUE;
    END_IF;
END_IF;

// --- 2) Stabilizacja czujników; P1 także przy podniesionym M2 podczas jazdy ---
tPos1Stable(IN := Inp.sPos1_raw AND
                 ((NOT Outp.TopConveyor_Run) OR
                  (Outp.HoldPos1_Up AND Inp.StopP1_IsUp)), PT := Cfg.tSensorStable);
tPos2Stable(IN := (NOT Outp.TopConveyor_Run) AND Inp.sPos2_raw, PT := Cfg.tSensorStable);
tPos3Stable(IN := (NOT Outp.TopConveyor_Run) AND Inp.sPos3_raw, PT := Cfg.tSensorStable);
sPos1_stable := tPos1Stable.Q;
Sts.Pos1SensorStable := sPos1_stable;
sPos2_stable := tPos2Stable.Q;
sPos3_stable := tPos3Stable.Q;

// --- 3) Token operatora: zatwierdzenie pojemnika na P1 ---
rPos1Accept(CLK := Cmd.Pos1AcceptedPulse);

IF rPos1Accept.Q AND sPos1_stable THEN
    Sts.OccP1 := TRUE;
    Sts.Pos1Accepted := TRUE;
END_IF;

// Jeżeli fizycznie nie ma pojemnika na P1 -> token kasujemy
IF NOT sPos1_stable THEN
    Sts.Pos1Accepted := FALSE;
END_IF;

// Po zwolnieniu P1 jego zajętość dotyczy już nowego pojemnika.
IF Sts.P1ReleasedForLoad THEN
    IF NOT Inp.sPos1_raw THEN
        Sts.OccP1 := FALSE;
    ELSIF sPos1_stable AND Outp.HoldPos1_Up AND Inp.StopP1_IsUp THEN
        Sts.OccP1 := TRUE;
    END_IF;
END_IF;

// --- 4) Reset błędu ---
IF Cmd.ResetFault THEN
    Diag.Fault := FALSE;
    Diag.FaultCode := E_TopFault.NONE;
    Diag.FaultText := '';
    Sts.Pos1Accepted := FALSE;
    xStackConsumedPending := FALSE;
    tStopDelay(IN := FALSE);
    tStopperTO(IN := FALSE);
    tMoveTO(IN := FALSE);

END_IF;

// --- 5) Domyślne wyjścia (nadpisywane w stanach) ---
Outp.Elev_TransferReq := FALSE;
Outp.Elev_TransferActive := FALSE;
Outp.ElevConv_RunFwd := FALSE;
Outp.M5_Extend := FALSE;

// Zapamiętaj impuls z TraySeq nawet jeśli TopFlow jest akurat zajęty ruchem/buforowaniem.
IF Inp.StackConsumedAtP3 THEN
    xStackConsumedPending := TRUE;
END_IF;

IF Inp.DeviceWarning THEN
    Outp.TopConveyor_Run := FALSE; Outp.ElevConv_RunFwd := FALSE;
    tMoveTO(IN := FALSE); tStopperTO(IN := FALSE);
    RETURN;
END_IF;
IF (NOT Cmd.EnableAuto) OR (NOT Cmd.SafetyOK) THEN
    Outp.TopConveyor_Run := FALSE;
    Outp.HoldPos1_Up := TRUE;
    Outp.HoldPos2_Up := Sts.OccP2;
    Outp.HoldPos3_Up := Sts.OccP3;
    tStopDelay(IN := FALSE);
    tStopperTO(IN := FALSE);
    tMoveTO(IN := FALSE);
    Sts.Busy := FALSE;
    RETURN;
END_IF;

// --- 6) Automat stanów ---
CASE Sts.State OF

    E_TopFlowState.INIT:
        xP2SeenForP1 := FALSE;
        xP2PassedForP1 := FALSE;
        Sts.P1ReleasedForLoad := FALSE;

        // Inicjalizacja logicznej zajętości na podstawie stabilnych czujników (taśma stoi)
        Sts.OccP1 := sPos1_stable;
        Sts.OccP2 := sPos2_stable;
        Sts.OccP3 := sPos3_stable;
        Sts.BufferFull := Sts.OccP1 AND Sts.OccP2 AND Sts.OccP3;
        Sts.StackReadyAtP3 := Sts.OccP3 AND Cmd.TrayMode AND Inp.StopP3_IsUp AND Inp.M5_IsDown;
        Sts.Busy := FALSE;
        Sts.Starved := FALSE;
        Sts.ElevDeliveredAtP4 := FALSE;

        Outp.TopConveyor_Run := FALSE;
        Outp.HoldPos1_Up := TRUE;
        Outp.HoldPos2_Up := Sts.OccP2;
        Outp.HoldPos3_Up := Sts.OccP3;

        // W IDLE domyślnie trzymaj zajęte pozycje UP
        Sts.SrcPos := E_TopPos.P1;
        Sts.Target := E_TopTarget.TG_P2;

        Sts.State := E_TopFlowState.IDLE;

    E_TopFlowState.IDLE:
        Outp.TopConveyor_Run := FALSE;

        Sts.Busy := FALSE;
        Sts.Starved := FALSE;

        // Zwolnienie P3 przez TraySeq po skończeniu stosu przez robota.
        IF xStackConsumedPending AND Cmd.TrayMode THEN
            IF Sts.OccP3 THEN
                Sts.OccP3 := FALSE;
            END_IF;
            Sts.StackReadyAtP3 := FALSE;
            xStackConsumedPending := FALSE;
        END_IF;

        IF Sts.Pos1Accepted AND sPos1_stable THEN
            Sts.OccP1 := TRUE;
        END_IF;

        Sts.BufferFull := Sts.OccP1 AND Sts.OccP2 AND Sts.OccP3;

        IF NOT Inp.sPos4_raw THEN
            Sts.ElevDeliveredAtP4 := FALSE;
        END_IF;

        // TrayMode: stos gotowy gdy P3 zajęte, M4 potwierdzony góra, M5 cofnięty
        Sts.StackReadyAtP3 := Sts.OccP3 AND Cmd.TrayMode AND Inp.StopP3_IsUp AND Inp.M5_IsDown;

        // M2 domyślnie podniesiony; opuszczany tylko dla kontrolowanego transferu z P1
        Outp.HoldPos1_Up := TRUE;
        Outp.HoldPos2_Up := Sts.OccP2;
        Outp.HoldPos3_Up := Sts.OccP3;

        planned := FALSE;
        p1Ready := Sts.OccP1 AND (Sts.Pos1Accepted OR Cmd.EmptyingMode) AND Inp.LoadBarrierValid;

        IF permissive AND Cmd.AllowNewTransfers THEN
            // --- W trybie tacek (TrayMode) nie planuj TG_ELEV ---
            // Robot sam układa tacki na windię; górny transporter tylko buforuje do P3
            IF (NOT Cmd.TrayMode) OR Cmd.EmptyingMode THEN
                // --- Priorytet: karmienie windy/robota (tryb kuwet) ---
                IF Inp.Elev_RequestFeed AND Inp.Elev_CanAccept THEN

                    IF Sts.OccP3 THEN
                        Sts.SrcPos := E_TopPos.P3;
                        Sts.Target := E_TopTarget.TG_ELEV;
                        planned := TRUE;

                    ELSIF Sts.OccP2 THEN
                        Sts.SrcPos := E_TopPos.P2;
                        Sts.Target := E_TopTarget.TG_P3;
                        planned := TRUE;

                    ELSIF p1Ready AND (NOT Sts.OccP2) AND (NOT Sts.OccP3) THEN
                        Sts.SrcPos := E_TopPos.P1;
                        Sts.Target := E_TopTarget.TG_ELEV;
                        planned := TRUE;

                    ELSE
                        Sts.Starved := TRUE;
                    END_IF;

                END_IF;
            END_IF;

            // --- Buforowanie (wspólne dla obu trybów; w trybie kuwet także gdy brak żądania windy) ---
            IF NOT planned THEN
                IF (NOT Sts.OccP3) AND Sts.OccP2 THEN
                    Sts.SrcPos := E_TopPos.P2;
                    Sts.Target := E_TopTarget.TG_P3;
                    planned := TRUE;

                ELSIF (NOT Sts.OccP3) AND (NOT Sts.OccP2) AND p1Ready THEN
                    Sts.SrcPos := E_TopPos.P1;
                    Sts.Target := E_TopTarget.TG_P3;
                    planned := TRUE;

                ELSIF (NOT Sts.OccP2) AND p1Ready THEN
                    Sts.SrcPos := E_TopPos.P1;
                    Sts.Target := E_TopTarget.TG_P2;
                    planned := TRUE;
                END_IF;
            END_IF;
        END_IF;

        IF planned THEN
            motionCfg := Cfg;
            Outp.AcceptedId := Cmd.OperationId;
            xP2SeenForP1 := FALSE;
            xP2PassedForP1 := FALSE;
            Sts.P1ReleasedForLoad := FALSE;
            IF Sts.Target = E_TopTarget.TG_ELEV THEN
                Sts.ElevDeliveredAtP4 := FALSE;
            END_IF;
            Sts.Busy := TRUE;
            Sts.State := E_TopFlowState.PREP_STOP;
        END_IF;

    E_TopFlowState.PREP_STOP:
        // Zatrzymaj taśmę i odczekaj przed ruchem stoperów
        Outp.TopConveyor_Run := FALSE;

        tStopDelay(IN := TRUE, PT := motionCfg.tMotorStopDelay);

        IF tStopDelay.Q THEN
            tStopDelay(IN := FALSE);
            Sts.State := E_TopFlowState.PREP_STOPPERS;
        END_IF;

    E_TopFlowState.PREP_STOPPERS:
        // Ustaw stopery: source DOWN, target (P2/P3) DOWN, reszta zajęta UP
        // 1) wyznacz żądane hold-y
        desiredHoldP1 := TRUE;
        desiredHoldP2 := Sts.OccP2;
        desiredHoldP3 := Sts.OccP3;

        // source ma być DOWN (zwolnij)
        CASE Sts.SrcPos OF
            E_TopPos.P1: desiredHoldP1 := FALSE;
            E_TopPos.P2: desiredHoldP2 := FALSE;
            E_TopPos.P3: desiredHoldP3 := FALSE;
        END_CASE;

        // target P2/P3 musi być DOWN na czas wjazdu
        CASE Sts.Target OF
            E_TopTarget.TG_P2: desiredHoldP2 := FALSE;
            E_TopTarget.TG_P3: desiredHoldP3 := FALSE;
        ELSE
            // TG_ELEV: nic dodatkowego
        END_CASE;

        // TrayMode+TG_P3: przed ruszeniem taśmy wysuń bramkę M5
        desiredM5 := Cmd.TrayMode AND (Sts.Target = E_TopTarget.TG_P3);
        Outp.M5_Extend := desiredM5;

        // 2) wystaw komendy
        Outp.HoldPos1_Up := desiredHoldP1;
        Outp.HoldPos2_Up := desiredHoldP2;
        Outp.HoldPos3_Up := desiredHoldP3;

        // 3) sprawdź czy stopery dojechały (i opcjonalnie M5)
        allStoppersInPos :=
            ((Outp.HoldPos1_Up AND Inp.StopP1_IsUp) OR ((NOT Outp.HoldPos1_Up) AND Inp.StopP1_IsDown)) AND
            ((Outp.HoldPos2_Up AND Inp.StopP2_IsUp) OR ((NOT Outp.HoldPos2_Up) AND Inp.StopP2_IsDown)) AND
            ((Outp.HoldPos3_Up AND Inp.StopP3_IsUp) OR ((NOT Outp.HoldPos3_Up) AND Inp.StopP3_IsDown)) AND
            (NOT desiredM5 OR Inp.M5_IsUp);  // jeśli TrayMode+TG_P3: poczekaj na M5 w górze

        tStopperTO(IN := NOT allStoppersInPos, PT := motionCfg.tStopperTimeout);

        IF allStoppersInPos THEN
            tStopperTO(IN := FALSE);
            Sts.State := E_TopFlowState.RUN;
        END_IF;

    E_TopFlowState.RUN:
        // Ruch taśmą do celu (P2/P3) lub transfer na windę (TG_ELEV)
        Sts.Busy := TRUE;

        IF Sts.P1ReleasedForLoad THEN Outp.HoldPos1_Up := TRUE; END_IF;
        // Podtrzymaj M5 w górze (bramka) podczas jazdy do P3 w trybie tacek
        IF Cmd.TrayMode AND (Sts.Target = E_TopTarget.TG_P3) THEN
            Outp.M5_Extend := TRUE;
        END_IF;

        // handshake do windy, jeśli cel = ELEV
        IF Sts.Target = E_TopTarget.TG_ELEV THEN
            Outp.Elev_TransferReq := TRUE;
            Outp.Elev_TransferActive := TRUE;
            Outp.ElevConv_RunFwd := TRUE;
            Outp.Elev_SourcePos := Sts.SrcPos;
        END_IF;

        Outp.TopConveyor_Run := TRUE;

        tMoveTO(IN := TRUE, PT := motionCfg.tMoveTimeout);

        // warunek stopu zależnie od celu
        IF (Sts.Target = E_TopTarget.TG_P2) AND Inp.sPos2_raw AND (Sts.SrcPos <> E_TopPos.P1 OR xP2PassedForP1) THEN
            Outp.TopConveyor_Run := FALSE;
            tMoveTO(IN := FALSE);
            Sts.State := E_TopFlowState.WAIT_STOP;

        ELSIF (Sts.Target = E_TopTarget.TG_P3) AND Inp.sPos3_raw AND (Sts.SrcPos <> E_TopPos.P1 OR xP2PassedForP1) THEN
            Outp.TopConveyor_Run := FALSE;
            tMoveTO(IN := FALSE);
            Sts.State := E_TopFlowState.WAIT_STOP;

        ELSIF (Sts.Target = E_TopTarget.TG_ELEV) AND Inp.Elev_TransferDone AND (Sts.SrcPos <> E_TopPos.P1 OR xP2PassedForP1) THEN
            // Transfer na windę kończy dopiero przefiltrowany sygnał P4 (2 s).
            Outp.TopConveyor_Run := FALSE;
            Outp.Elev_TransferReq := FALSE;
            Outp.Elev_TransferActive := FALSE;
            Outp.ElevConv_RunFwd := FALSE;
            tMoveTO(IN := FALSE);
            Sts.State := E_TopFlowState.WAIT_STOP;

        ELSIF tMoveTO.Q THEN
            Outp.TopConveyor_Run := FALSE;
            Outp.Elev_TransferReq := FALSE;
            Outp.Elev_TransferActive := FALSE;
            Outp.ElevConv_RunFwd := FALSE;
            Diag.Fault := TRUE;
            Diag.FaultCode := E_TopFault.MOVE_TIMEOUT;
            Diag.FaultText := 'TopFlow: timeout ruchu transportera (brak osiągnięcia celu).';
            Sts.State := E_TopFlowState.FAULT;
        END_IF;

        IF xP1TransferCanRelease AND xP2PassedForP1 AND NOT Sts.P1ReleasedForLoad AND
           NOT Inp.sPos1_raw AND Sts.State = E_TopFlowState.RUN THEN
            Outp.TopConveyor_Run := FALSE; Outp.ElevConv_RunFwd := FALSE;
            tMoveTO(IN := FALSE); Sts.State := E_TopFlowState.RELEASE_P1;
        END_IF;

    E_TopFlowState.RELEASE_P1:
        Outp.TopConveyor_Run := FALSE; Outp.ElevConv_RunFwd := FALSE;
        tStopDelay(IN := NOT Inp.TopConveyorRunning, PT := motionCfg.tMotorStopDelay);
        IF tStopDelay.Q THEN
            tStopDelay(IN := FALSE); Outp.HoldPos1_Up := TRUE;
            Sts.State := E_TopFlowState.WAIT_P1_LOCK;
        END_IF;
    E_TopFlowState.WAIT_P1_LOCK:
        Outp.TopConveyor_Run := FALSE; Outp.ElevConv_RunFwd := FALSE; Outp.HoldPos1_Up := TRUE;
        IF Inp.StopP1_IsUp AND NOT Inp.DeviceWarning THEN
            Sts.P1ReleasedForLoad := TRUE; Sts.OccP1 := FALSE; Sts.Pos1Accepted := FALSE;
            Sts.State := E_TopFlowState.RUN;
        END_IF;

    E_TopFlowState.WAIT_STOP:
        // Odczekaj przed komendami stoperów po zatrzymaniu
        // Podtrzymaj M5 jeśli TrayMode+TG_P3 (będzie cofnięty w RETRACT_M5_GATE)
        IF Cmd.TrayMode AND (Sts.Target = E_TopTarget.TG_P3) THEN
            Outp.M5_Extend := TRUE;
        END_IF;

        tStopDelay(IN := TRUE, PT := motionCfg.tMotorStopDelay);

        IF tStopDelay.Q THEN
            tStopDelay(IN := FALSE);

            IF Cmd.TrayMode AND (Sts.Target = E_TopTarget.TG_P3) THEN
                // Tryb tacek: cofnij M5, potem podnieś M4
                Sts.State := E_TopFlowState.RETRACT_M5_GATE;
            ELSIF (Sts.Target = E_TopTarget.TG_P2) OR (Sts.Target = E_TopTarget.TG_P3) THEN
                Sts.State := E_TopFlowState.LOCK_TARGET;
            ELSE
                // TG_ELEV – nie ma co blokować na górze
                Sts.State := E_TopFlowState.COMPLETE;
            END_IF;
        END_IF;

    E_TopFlowState.RETRACT_M5_GATE:
        // (TrayMode+TG_P3) Cofnij M5 po przybyciu stosu, zanim podniesiemy M4
        Outp.M5_Extend := FALSE;
        tStopperTO(IN := NOT Inp.M5_IsDown, PT := motionCfg.tStopperTimeout);

        IF Inp.M5_IsDown THEN
            tStopperTO(IN := FALSE);
            Sts.State := E_TopFlowState.LOCK_TARGET;
        END_IF;

    E_TopFlowState.LOCK_TARGET:
        // Podnieś stoper docelowy (P2 lub P3), żeby utrzymać pojemnik
        Outp.TopConveyor_Run := FALSE;

        // domyślne hold-y
        Outp.HoldPos1_Up := TRUE;
        Outp.HoldPos2_Up := Sts.OccP2;
        Outp.HoldPos3_Up := Sts.OccP3;

        // target -> UP
        IF Sts.Target = E_TopTarget.TG_P2 THEN
            Outp.HoldPos2_Up := TRUE;
        ELSIF Sts.Target = E_TopTarget.TG_P3 THEN
            Outp.HoldPos3_Up := TRUE;
        END_IF;

        Sts.State := E_TopFlowState.WAIT_LOCK;

    E_TopFlowState.WAIT_LOCK:
        // czekaj aż target stoper potwierdzi UP
        tStopperTO(IN := TRUE, PT := motionCfg.tStopperTimeout);

        IF (Sts.Target = E_TopTarget.TG_P2) AND Inp.StopP2_IsUp THEN
            tStopperTO(IN := FALSE);
            Sts.State := E_TopFlowState.COMPLETE;

        ELSIF (Sts.Target = E_TopTarget.TG_P3) AND Inp.StopP3_IsUp THEN
            tStopperTO(IN := FALSE);
            Sts.State := E_TopFlowState.COMPLETE;

        END_IF;

    E_TopFlowState.COMPLETE:
        Outp.TransferDonePulse := TRUE;
        Outp.CompletedId := Outp.AcceptedId;
        // Aktualizacja zajętości logicznej po zakończonym ruchu
        // (celowo nie opieramy się tu o migające czujniki w trakcie ruchu)

        CASE Sts.Target OF
            E_TopTarget.TG_P2:
                Sts.OccP2 := TRUE;
            E_TopTarget.TG_P3:
                Sts.OccP3 := TRUE;
            E_TopTarget.TG_ELEV:
                // na górze nic nie zajmujemy; pojemnik oddany na windę
                Sts.ElevDeliveredAtP4 := TRUE;
        END_CASE;

        // source -> puste
        CASE Sts.SrcPos OF
            E_TopPos.P1:
                IF NOT Sts.P1ReleasedForLoad THEN
                    Sts.OccP1 := FALSE;
                    Sts.Pos1Accepted := FALSE; // token dotyczył tego pojemnika
                END_IF;
            E_TopPos.P2:
                Sts.OccP2 := FALSE;
            E_TopPos.P3:
                Sts.OccP3 := FALSE;
        END_CASE;

        // P1 fizycznie może już mieć nowy pojemnik – odśwież P1 z czujnika stabilnego
        Sts.OccP1 := sPos1_stable;

        Sts.State := E_TopFlowState.IDLE;

    E_TopFlowState.FAULT:
        Outp.TopConveyor_Run := FALSE;
        Outp.ElevConv_RunFwd := FALSE;

        // Bezpieczny stan: M2 zawsze UP, pozostałe stopery według pamięci zajętości
        Outp.HoldPos1_Up := TRUE;
        Outp.HoldPos2_Up := Sts.OccP2;
        Outp.HoldPos3_Up := Sts.OccP3;

        Sts.Busy := FALSE;

END_CASE;

IF Sts.P1ReleasedForLoad THEN
    Sts.BufferFull := Sts.OccP1 AND Sts.OccP2 AND Sts.OccP3;
END_IF;
