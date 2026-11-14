TYPE ST_ElevatorPar :
STRUCT
  rMaxSpeed_Hz       : REAL; // clamp (np. 50.0)
  tMoveTimeout       : TIME; // timeout standard (np. T#25s)
  tClearPos4Timeout  : TIME; // timeout dla POS4_OFF (np. T#5s)
  tVfdResetPulse     : TIME; // impuls resetu falownika (np. T#200ms)

  // Mapowanie kierunku:
  // TRUE  -> FWD = GÓRA, REV = DÓŁ
  // FALSE -> FWD = DÓŁ, REV = GÓRA
  xFwdIsUp           : BOOL;

  // Maski ETA (rejestr 3201) — ATV320 standardowe bity:
  // bit 0 = Ready to Switch On, bit 1 = Switched On, bit 2 = Operation Enabled
  // bit 3 = Fault,  bit 9 = Remote (sterowanie z sieci),  bit 13 = FWD
  wStsMask_Fault     : WORD;   // np. 16#0008 (bit 3)
  wStsMask_Ready     : WORD;   // np. 16#0001 (bit 0)
  wStsMask_Running   : WORD;   // np. 16#0004 (bit 2 = Operation Enabled)
  wStsMask_Remote    : WORD;   // np. 16#0200 (bit 9)

  // Wyhamowanie: próg prędkości i timeout bezpieczny STOPPING
  rStopSpeedThreshold_Hz : REAL;  // [Hz] próg "zatrzymany" np. 1.5
  tStopTimeout           : TIME;  // bezpieczny timeout STOPPING np. T#5s
END_STRUCT
END_TYPE
