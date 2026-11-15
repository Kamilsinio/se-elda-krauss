(* Procesowe wyjscia; zwykly PLC nie realizuje funkcji safety EUROMAP. *)
FUNCTION_BLOCK FB_ImmInterface
VAR_INPUT
    Inp : ST_RobotImmIn;
    Session : BOOL;
    HomeValid : BOOL;
    WithRobot : BOOL;
    Manual : BOOL;
    NewPermit : BOOL;
    FinishPermit : BOOL;
    Critical : BOOL;
    FreeSlot : BOOL;
    Unsettled : UINT;
    ReqClose : BOOL;
    ReqOpen : BOOL;
    ReqBack : BOOL;
    ReqForward : BOOL;
END_VAR
VAR_OUTPUT
    Outp : ST_RobotImmOut;
END_VAR
VAR
    allowed : BOOL;
    manualArmed : BOOL;
END_VAR
Outp.valid := Inp.configured AND Inp.valid AND Inp.sharedSupplyVerified AND Inp.processInterlocks;
Outp.mouldClose := FALSE;
Outp.mouldFullOpen := FALSE;
Outp.ejectorBack := FALSE;
Outp.ejectorForward := FALSE;
Outp.withRobot := WithRobot;
Outp.newCyclePermit := FALSE;
Outp.reason := 0;
allowed := Outp.valid AND NOT Critical;
IF NOT Manual OR NOT HomeValid OR WithRobot OR Critical THEN manualArmed := FALSE; END_IF;
IF Manual AND NOT Inp.manualMouldClose AND NOT Inp.manualFullOpen AND
   NOT Inp.manualEjectorBack AND NOT Inp.manualEjectorForward THEN manualArmed := TRUE; END_IF;
IF allowed THEN
    IF Manual THEN
        IF HomeValid AND NOT WithRobot AND Unsettled = 0 AND manualArmed THEN
            Outp.mouldClose := Inp.manualMouldClose;
            Outp.mouldFullOpen := Inp.manualFullOpen;
            Outp.ejectorBack := Inp.manualEjectorBack AND NOT Inp.manualEjectorForward;
            Outp.ejectorForward := Inp.manualEjectorForward AND NOT Inp.manualEjectorBack;
        ELSE Outp.reason := 20;
        END_IF;
    ELSIF NOT WithRobot THEN
        Outp.mouldClose := HomeValid;
        Outp.mouldFullOpen := HomeValid;
        Outp.ejectorBack := HomeValid;
        Outp.ejectorForward := HomeValid;
    ELSIF Session THEN
        Outp.newCyclePermit := NewPermit AND FreeSlot AND Inp.startSignalValid AND Inp.cycleKnown;
        Outp.mouldClose := (ReqClose AND Outp.newCyclePermit) OR
            (FinishPermit AND Unsettled > 0 AND Inp.completionMouldClose);
        Outp.mouldFullOpen := (ReqOpen AND (NewPermit OR FinishPermit)) OR
            (FinishPermit AND Unsettled > 0 AND Inp.completionFullOpen);
        Outp.ejectorBack := (ReqBack AND (NewPermit OR FinishPermit)) OR
            (FinishPermit AND Unsettled > 0 AND Inp.completionEjectorBack);
        Outp.ejectorForward := (ReqForward AND (NewPermit OR FinishPermit)) OR
            (FinishPermit AND Unsettled > 0 AND Inp.completionEjectorForward);
        IF Outp.ejectorBack AND Outp.ejectorForward THEN
            Outp.ejectorBack := FALSE; Outp.ejectorForward := FALSE; Outp.reason := 40;
        END_IF;
    ELSE Outp.reason := 10;
    END_IF;
ELSE Outp.reason := 50;
END_IF;
(* applied uwzglednia wspolne zasilanie KF204-210 przez KF203. *)
IF NOT Outp.mouldFullOpen THEN Outp.ejectorBack := FALSE; Outp.ejectorForward := FALSE; END_IF;
