TYPE ST_HmiCommands :
STRUCT
    (* Tryb *)
    xSelectModeTray     : BOOL;   // wybór tacek
    xSelectModeBox      : BOOL;   // wybór kuwet
    xManualMode         : BOOL;   // tryb ręczny

    (* Sterowanie *)
    xStartAuto          : BOOL;   // start AUTO
    xStopAuto           : BOOL;   // abort / stop AUTO
    xContiniue          : BOOL;   // kontynuuj AUTO
    xPauseAuto          : BOOL;   // pauza AUTO
    xEmptyStation       : BOOL;   // opróżnij stację
    xResetFaults        : BOOL;   // kasuj alarmy
    xAckAlarms          : BOOL;   // potwierdź alarmy

    (* Manualne sterowanie — przekierowane do xHmi* w PRG_Main *)
    xElevUp             : BOOL;
    xElevDown           : BOOL;
    xElevFast           : BOOL;
    xConvTopFwd         : BOOL;
    xConvElevFwd        : BOOL;
    xConvElevBwd        : BOOL;
    xConvBottomFwd      : BOOL;
    xConvBottomBwd      : BOOL;
    (* Siłowniki — sterowanie bistabilne, przód/tył *)
    (* HMI powinno wzajemnie blokować Fwd i Bwd tego samego siłownika *)
    xM1Fwd              : BOOL;   // wysuń M1 (pozycjoner załadunku)
    xM1Bwd              : BOOL;   // cofnij M1
    xM2Fwd              : BOOL;   // wysuń M2 (stoper P1)
    xM2Bwd              : BOOL;   // cofnij M2
    xM3Fwd              : BOOL;   // wysuń M3 (stoper P2)
    xM3Bwd              : BOOL;   // cofnij M3
    xM4Fwd              : BOOL;   // wysuń M4 (stoper P3)
    xM4Bwd              : BOOL;   // cofnij M4
    xM5Fwd              : BOOL;   // wysuń M5 (pozycjoner tacek P3)
    xM5Bwd              : BOOL;   // cofnij M5
    xM6Fwd              : BOOL;   // wysuń M6 (pozycjoner tacek winda)
    xM6Bwd              : BOOL;   // cofnij M6
    xM7Fwd              : BOOL;   // wysuń M7 (pozycjoner kuwet winda)
    xM7Bwd              : BOOL;   // cofnij M7
    xM8Fwd              : BOOL;   // wysuń M8 (osłona magazynu)
    xM8Bwd              : BOOL;   // cofnij M8

    (* Parametry *)
    uiTraysInStack      : UINT;   // ilość tacek w stosie (domyślnie 8)
    rElevSpeedFast_Hz   : REAL;   // szybka prędkość windy [Hz], 0 = domyślne 40 Hz
    rElevSpeedSlow_Hz   : REAL;   // wolna prędkość windy [Hz], 0 = domyślne 15 Hz
END_STRUCT
END_TYPE
