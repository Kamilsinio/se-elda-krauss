TYPE ST_ElevatorStat :
STRUCT
  eState             : E_ElevatorState;

  ePos               : E_ElevatorPos;   // aktualnie aktywny czujnik pozycji (lub UNKNOWN)
  eLastPos           : E_ElevatorPos;   // ostatnia znana pozycja (latch)

  eTargetLatched     : E_ElevatorTarget;

  xBusy              : BOOL;
  xAtTarget          : BOOL;

  // prędkość zadana (diagnostyka)
  xCmdFast           : BOOL;
  rCmdHz             : REAL;

  // VFD status — zdekodowane z ETA (rejestr 3201)
  wVfdStatus         : WORD;
  xVfdFault          : BOOL;   // bit Fault
  xVfdReady          : BOOL;   // bit Ready to Switch On
  xVfdRunning        : BOOL;   // bit Operation Enabled (napęd jedzie)
  xVfdRemote         : BOOL;   // bit Remote (sterowanie z sieci)
  xVfdCommOk         : BOOL;   // Control_ATV aktywny bez alarmu
  rVfdOutHz          : REAL;   // aktualna prędkość [Hz] z rejestru 3202

  // Faulty modułu
  xFault             : BOOL;
  uiFaultId          : UINT;
  sDiagText          : STRING[120];
    xStandstillValid : BOOL;
    xStandstill : BOOL;
    AcceptedId : UDINT;
    CompletedId : UDINT;
    xContainerEdgeReached : BOOL; // B205 zgasl podczas zjazdu do krawedzi
END_STRUCT
END_TYPE
