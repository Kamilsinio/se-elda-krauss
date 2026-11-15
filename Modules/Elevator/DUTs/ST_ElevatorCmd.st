TYPE ST_ElevatorCmd :
STRUCT
  eMode          : E_ElevatorMode;

  // wspólne
  xStop          : BOOL;  // soft stop
  xReset         : BOOL;  // reset faultów modułu + impuls resetu falownika

  // Prędkości z HMI (w Hz)
  rSpeedFast_Hz  : REAL;  // szybka (segment posIntermediateTop<->posIntermediateBottom)
  rSpeedSlow_Hz  : REAL;  // wolna  (segmenty posTop<->posIntermediateTop i posIntermediateBottom<->posBottom)

  // AUTO
  xAutoGo        : BOOL;             // impuls start (zbocze)
  xAutoStop      : BOOL;             // stop auto (poziom)
  eAutoTarget    : E_ElevatorTarget; // posTop..posBottom lub posContainerEdge

  // MANUAL (jog)
  xManUp         : BOOL;
  xManDown       : BOOL;
  xManFast       : BOOL;             // TRUE => jedź na rSpeedFast_Hz, FALSE => rSpeedSlow_Hz
    OperationId : UDINT;
END_STRUCT
END_TYPE
