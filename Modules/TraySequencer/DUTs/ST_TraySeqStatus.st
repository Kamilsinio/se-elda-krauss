TYPE ST_TraySeqStatus :
STRUCT
    State         : E_TraySeqState;
    TrayCount     : UINT;   // ile tacek ułożono w bieżącym stosie
    StackCount    : UINT;   // ile stosów ukończono od startu
    Busy          : BOOL;
END_STRUCT
END_TYPE
