TYPE ST_HmiStationStatus :
STRUCT

    // Winda
    uiElevState : UINT;
    xElevBusy : BOOL;
    xElevFault : BOOL;
    rElevFreq_Hz : REAL;
    sElevDiagText : STRING[80];
    xConvTopRunning : BOOL;
    xConvElevRunning : BOOL;
    xConvBottomRunning : BOOL;
    iConvTopDirection : INT;
    iConvElevDirection : INT;
    iConvBottomDirection : INT;
    sConvTopDiagText : STRING[80];
    sConvElevDiagText : STRING[80];
    sConvBottomDiagText : STRING[80];
    xM1_Busy : BOOL;
    xM2_Busy : BOOL;
    xM3_Busy : BOOL;
    xM4_Busy : BOOL;
    xM5_Busy : BOOL;
    xM6_Busy : BOOL;
    sM1DiagText : STRING[80];
    sM2DiagText : STRING[80];
    sM3DiagText : STRING[80];
    sM4DiagText : STRING[80];
    sM5DiagText : STRING[80];

    // Magazyn przekladek
    uiStorageState : UINT;
    xStorageRobotSideOpen : BOOL;
    xStorageRobotSideClosed : BOOL;
    xStorageRobotAccessActive : BOOL;
    xStorageOperatorAccessActive : BOOL;
    xStorageOperatorRequest : BOOL;
    xStorageRobotPermission : BOOL;
    xStorageOperatorPermission : BOOL;
    xStorageBusy : BOOL;
    sStorageDiagText : STRING[80];

    // Robot
    xRobotAutoMode : BOOL;
    xRobotReady : BOOL;
    xRobotRunning : BOOL;
    xRobotFault : BOOL;
    xRobotHome : BOOL;
    xVfdCommOk : BOOL;

    // Sekwencje stacji
    uiTopFlowState : UINT;
    uiBottomState : UINT;
    sTopFlowDiagText : STRING[80];
    sBottomDiagText : STRING[80];

    // Liczniki produkcji
    uiTraysDone : UINT;
    uiStacksDone : UINT;
    uiBoxesDone : UINT;
END_STRUCT
END_TYPE
