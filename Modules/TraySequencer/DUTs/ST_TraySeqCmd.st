TYPE ST_TraySeqCmd :
STRUCT
    StartAuto      : BOOL;  // impuls startu trybu AUTO
    ResumeAuto     : BOOL;  // poziom: wznowienie po przerwie/fault bez zerowania licznikow
    PauseAuto      : BOOL;  // pauza AUTO z mozliwoscia wznowienia
    AbortAuto      : BOOL;  // abort AUTO do DISABLED
    SafetyOK       : BOOL;
    ResetFault     : BOOL;
END_STRUCT
END_TYPE
