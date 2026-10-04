(* ============================================================
   GVL_HMI — Zmienne wymiany danych z wizualizacją HMI
   Schneider Vijeo Designer / Web Visualization.
   Wszystkie zmienne z prefiksem hmi* są bindowane w panelu.
   ============================================================ *)

TYPE ST_HmiAlarm :
STRUCT
    (* Siłowniki — fault z FB_Cyl2Pos / FB_StopperPair *)
    xM1_Fault           : BOOL;
    xM2_Fault           : BOOL;
    xM3_Fault           : BOOL;
    xM4_Fault           : BOOL;
    xM5_Fault           : BOOL;
    xM6_Fault           : BOOL;
    xM7_Fault           : BOOL;
    xM8_Fault           : BOOL;

    (* Transportery *)
    xConvTop_Fault      : BOOL;
    xConvElev_Fault     : BOOL;
    xConvBottom_Fault   : BOOL;

    (* Winda *)
    xElev_Fault         : BOOL;
    xElev_CommLost      : BOOL;

    (* Przepływ *)
    xTopFlow_Fault      : BOOL;
    xBottom_Fault       : BOOL;

    (* Sekwencery *)
    xTraySeq_Fault      : BOOL;
    xBoxSeq_Fault       : BOOL;

    (* Robot *)
    xRobot_Fault        : BOOL;
    xRobot_EStop        : BOOL;
    xRobot_CommLost     : BOOL;

    (* Komunikacja *)
    xVfd_CommLost       : BOOL;
    xRobot_MbLost       : BOOL;

    (* System *)
    xLowPressure        : BOOL;
    xSafetyTrip         : BOOL;

	xAckAll : BOOL;
	xResetAll : BOOL;
END_STRUCT
END_TYPE

(* --- Konfiguracja HMI: stała ilość alarmów --- *)
{attribute 'qualified_only'}
VAR_GLOBAL CONSTANT
    MAX_ALARMS   : UINT := 32;
END_VAR

(* --- Status stacji do wyświetlania --- *)
TYPE ST_HmiStationStatus :
STRUCT
    (* Tryby *)
    xAutoRunning        : BOOL;
    xManualMode         : BOOL;
    xEmptyingStation    : BOOL;
    xModeTray           : BOOL;
    xModeBox            : BOOL;
    xGlobalEnable       : BOOL;
    xSafetyOK           : BOOL;

    (* Pozycje zajęte *)
    xOccP1              : BOOL;
    xOccP2              : BOOL;
    xOccP3              : BOOL;
    xOccP4              : BOOL;  // pojemnik na windzie
    xOccP5              : BOOL;
    xOccP6              : BOOL;
    xOccP7              : BOOL;

    (* Winda *)
    uiElevState         : UINT;
    xElevAtTop          : BOOL;
    xElevAtBottom       : BOOL;
    xElevBusy           : BOOL;
    xElevFault          : BOOL;
    rElevFreq_Hz        : REAL;  // aktualna częstotliwość VFD
    sElevDiagText       : STRING[120];

    (* Transportery *)
    xConvTopRunning     : BOOL;
    xConvElevRunning    : BOOL;
    xConvBottomRunning  : BOOL;
    uiConvTopState      : UINT;
    uiConvElevState     : UINT;
    uiConvBottomState   : UINT;
    iConvTopDirection   : INT;   // 0=stop, 1=FWD, -1=BWD
    iConvElevDirection  : INT;
    iConvBottomDirection : INT;
    xConvTopFault       : BOOL;
    xConvElevFault      : BOOL;
    xConvBottomFault    : BOOL;
    sConvTopDiagText    : STRING[120];
    sConvElevDiagText   : STRING[120];
    sConvBottomDiagText : STRING[120];

    (* Stopery / pozycjonery — stan zagregowany (kompatybilność wstecz) *)
    xM1_Extended        : BOOL;
    xM2_Up              : BOOL;
    xM3_Up              : BOOL;
    xM4_Up              : BOOL;
    xM5_Up              : BOOL;
    xM6_Up              : BOOL;
    xM7_Extended        : BOOL;
    xM8_Extended        : BOOL;
    xM1_Retracted       : BOOL;
    xM2_Down            : BOOL;
    xM3_Down            : BOOL;
    xM4_Down            : BOOL;
    xM5_Down            : BOOL;
    xM6_Down            : BOOL;
    xM7_Retracted       : BOOL;
    xM8_Retracted       : BOOL;
    xM1_Busy            : BOOL;
    xM2_Busy            : BOOL;
    xM3_Busy            : BOOL;
    xM4_Busy            : BOOL;
    xM5_Busy            : BOOL;
    xM6_Busy            : BOOL;
    xM7_Busy            : BOOL;
    xM8_Busy            : BOOL;
    xM1_Fault           : BOOL;
    xM2_Fault           : BOOL;
    xM3_Fault           : BOOL;
    xM4_Fault           : BOOL;
    xM5_Fault           : BOOL;
    xM6_Fault           : BOOL;
    xM7_Fault           : BOOL;
    xM8_Fault           : BOOL;
    sM1DiagText         : STRING[120];
    sM2DiagText         : STRING[120];
    sM3DiagText         : STRING[120];
    sM4DiagText         : STRING[120];
    sM5DiagText         : STRING[120];
    sM6DiagText         : STRING[120];
    sM7DiagText         : STRING[120];
    sM8DiagText         : STRING[120];

    (* Krańcówki siłowników — każdy czujnik osobno *)
    (* M1 — pozycjoner załadunku *)
    xM1_1_Fwd           : BOOL;   // M1.1 wysunięty
    xM1_2_Fwd           : BOOL;   // M1.2 wysunięty
    xM1_1_Bwd           : BOOL;   // M1.1 cofnięty
    xM1_2_Bwd           : BOOL;   // M1.2 cofnięty
    (* M2 — stoper P1 *)
    xM2_1_Fwd           : BOOL;
    xM2_2_Fwd           : BOOL;
    xM2_1_Bwd           : BOOL;
    xM2_2_Bwd           : BOOL;
    (* M3 — stoper P2 *)
    xM3_1_Fwd           : BOOL;
    xM3_2_Fwd           : BOOL;
    xM3_1_Bwd           : BOOL;
    xM3_2_Bwd           : BOOL;
    (* M4 — stoper P3 *)
    xM4_1_Fwd           : BOOL;
    xM4_2_Fwd           : BOOL;
    xM4_1_Bwd           : BOOL;
    xM4_2_Bwd           : BOOL;
    (* M5 — pozycjoner tacek P3 *)
    xM5_1_Fwd           : BOOL;
    xM5_2_Fwd           : BOOL;
    xM5_1_Bwd           : BOOL;
    xM5_2_Bwd           : BOOL;
    (* M6 — pozycjoner tacek winda *)
    xM6_1_Fwd           : BOOL;
    xM6_2_Fwd           : BOOL;
    xM6_1_Bwd           : BOOL;
    xM6_2_Bwd           : BOOL;
    (* M7 — pozycjoner kuwet winda *)
    xM7_Fwd             : BOOL;
    xM7_Bwd             : BOOL;
    (* M8 — osłona magazynu przekładek *)
    xM8_Fwd             : BOOL;
    xM8_Bwd             : BOOL;

    (* Drzwi celi robota *)
    uiSafetyDoorState        : UINT;
    xSafetyDoorClosed        : BOOL;
    xSafetyDoorLocked        : BOOL;
    xSafetyDoorDeviceError   : BOOL;
    xSafetyDoorUnlockRequest : BOOL;
    xSafetyDoorReadyToRun    : BOOL;
    xSafetyDoorBusy          : BOOL;
    xSafetyDoorFault         : BOOL;
    sSafetyDoorDiagText      : STRING[120];

    (* Magazyn przekładek *)
    uiStorageState              : UINT;
    xStorageRobotSideOpen       : BOOL;
    xStorageRobotSideClosed     : BOOL;
    xStorageRobotAccessActive   : BOOL;
    xStorageOperatorAccessActive : BOOL;
    xStorageOperatorRequest     : BOOL;
    xStorageRobotPermission     : BOOL;
    xStorageOperatorPermission  : BOOL;
    xStorageLowLevel            : BOOL;
    xStorageEmpty               : BOOL;
    xStorageBusy                : BOOL;
    xStorageFault               : BOOL;
    sStorageDiagText            : STRING[120];

    (* Robot *)
    xRobotAutoMode      : BOOL;
    xRobotReady         : BOOL;
    xRobotRunning       : BOOL;
    xRobotFault         : BOOL;
    xRobotHome          : BOOL;
    xRobotCommOk        : BOOL;
    xVfdCommOk          : BOOL;

    (* Sekwencer *)
    uiTraySeqState      : UINT;
    uiBoxSeqState       : UINT;
    uiTopFlowState      : UINT;
    uiBottomState       : UINT;
    sTopFlowDiagText    : STRING[120];
    sBottomDiagText     : STRING[120];
    sTraySeqDiagText    : STRING[120];
    sBoxSeqDiagText     : STRING[120];

    (* Liczniki produkcji *)
    uiTraysDone         : UINT;   // tacki ułożone w bieżącym stosie
    uiStacksDone        : UINT;   // stosy gotowe
    uiBoxesDone         : UINT;   // kuwety gotowe
END_STRUCT
END_TYPE

(* --- Komendy z HMI --- *)
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


{attribute 'qualified_only'}
VAR_GLOBAL
    hmiStatus     : ST_HmiStationStatus;
    hmiCmd        : ST_HmiCommands;
    hmiAlarms     : ST_HmiAlarm;
    hmiAlarmCount : UINT;  // ilość aktywnych alarmów
END_VAR
