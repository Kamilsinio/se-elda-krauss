TYPE ST_SafetyDoorOut :
STRUCT
    Q_Unlock       : BOOL; // cewka odryglowania
    Q_LEDOpenClose : BOOL; // LED przycisku otworz/zamknij
    Q_DeviceReset  : BOOL; // impuls RST klamki Euchner
END_STRUCT
END_TYPE
