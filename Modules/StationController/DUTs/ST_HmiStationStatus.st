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
