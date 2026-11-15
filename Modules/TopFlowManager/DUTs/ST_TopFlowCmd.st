TYPE ST_TopFlowCmd :
STRUCT
    EnableAuto : BOOL;         // globalne pozwolenie na automaty (z supervisora)
    SafetyOK   : BOOL;         // zbiorcze pozwolenie safety (od safety PLC)
    EmptyingMode : BOOL;       // tryb opróżniania (opcjonalnie wpływa na priorytety)

    // “token” operatora: pojemnik na P1 zatwierdzony (przycisk “Pojemnik gotowy” po checks)
    Pos1AcceptedPulse : BOOL;  // impuls (zbocze narastające)
    // TRUE = produkcja tacek: używaj bramki M5 przy TG_P3, nie planuj TG_ELEV
    // FALSE = produkcja kuwet: TG_ELEV dostępne (dwa transportery jednocześnie)
    TrayMode : BOOL;
    ResetFault : BOOL;
    AllowNewTransfers : BOOL;
    OperationId : UDINT;
END_STRUCT
END_TYPE
