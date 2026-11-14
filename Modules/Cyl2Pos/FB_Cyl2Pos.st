FUNCTION_BLOCK FB_Cyl2Pos
VAR_INPUT
    Cfg : ST_Cyl2PosCfg;
    Enable : BOOL;
    CmdExtend : BOOL;   // TRUE -> extend, FALSE -> retract
    ResetFault : BOOL;
    Inp : ST_Cyl2PosIn;
END_VAR
VAR_OUTPUT
    Outp : ST_Cyl2PosOut;
    Sts  : ST_Cyl2PosStatus;
    Diag : ST_Cyl2PosDiag;
END_VAR
VAR
    tExt : TON;
    tRet : TON;
    tTO  : TON;
    contradiction : BOOL;
    targetReached : BOOL;
END_VAR


IF ResetFault THEN
    Diag.Fault := FALSE;
    Diag.Code := E_Cyl2PosFault.NONE;
    Diag.Text := '';
END_IF;

contradiction := Inp.IsExt AND Inp.IsRet;

tExt(IN := Enable AND Inp.IsExt AND (NOT contradiction), PT := Cfg.tStable);
tRet(IN := Enable AND Inp.IsRet AND (NOT contradiction), PT := Cfg.tStable);

Sts.AtExt := tExt.Q;
Sts.AtRet := tRet.Q;

IF contradiction AND Enable AND (NOT Diag.Fault) THEN
    Diag.Fault := TRUE;
    Diag.Code := E_Cyl2PosFault.SENSOR_CONTRADICTION;
    Diag.Text := 'Cylinder: sprzeczne czujniki EXT/RET.';
END_IF;

IF NOT Enable OR Diag.Fault THEN
    Outp.Q_Ext := FALSE;
    Outp.Q_Ret := FALSE;
    Sts.Busy := FALSE;
ELSE
    IF CmdExtend THEN
        targetReached := Sts.AtExt;
    ELSE
        targetReached := Sts.AtRet;
    END_IF;

    Sts.Busy := NOT targetReached;

    tTO(IN := Sts.Busy, PT := Cfg.tTimeout);
    IF tTO.Q THEN
        Diag.Fault := TRUE;
        Diag.Code := E_Cyl2PosFault.TIMEOUT;
        Diag.Text := 'Cylinder: timeout dojazdu.';
    END_IF;

    // sterowanie (zawsze jedna cewka)
    Outp.Q_Ext := CmdExtend AND (NOT Diag.Fault);
    Outp.Q_Ret := (NOT CmdExtend) AND (NOT Diag.Fault);
END_IF;
