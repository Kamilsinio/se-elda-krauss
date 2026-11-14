TYPE ST_BoxSeqCmd :
STRUCT
    StartAuto      : BOOL;
    ResumeAuto     : BOOL;  // poziom: wznowienie po przerwie/fault bez zerowania licznika
    PauseAuto      : BOOL;  // pauza AUTO z mozliwoscia wznowienia
    AbortAuto      : BOOL;  // abort AUTO do DISABLED
    SafetyOK       : BOOL;
    ResetFault     : BOOL;
END_STRUCT
END_TYPE
