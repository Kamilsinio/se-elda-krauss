{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_ElevatorMode :
(
  MANUAL := 0,
  AUTO   := 1
);
END_TYPE
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_ElevatorPos :
(
  UNKNOWN                := 0,
  posTop                 := 1, // skrajnie górna
  posIntermediateTop     := 2, // górna pośrednia
  posIntermediateBottom  := 3, // dolna pośrednia
  posBottom              := 4  // skrajnie dolna 
);
END_TYPE
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_ElevatorState :
(
  DISABLED    := 0,
  IDLE        := 10,

  MANUAL_UP   := 20,
  MANUAL_DOWN := 21,

  AUTO_UP     := 30,
  AUTO_DOWN   := 31,

  STOPPING    := 40,
  FAULT       := 900
);
END_TYPE
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_ElevatorTarget :
(
  NONE     := 0,

  posTop     				:= 1,
  posIntermediateTop     	:= 2,
  posIntermediateBottom     := 3,
  posBottom     			:= 4,

  posContainerEdge := 10 // jedź w dół aż xInPos4 = FALSE
);
END_TYPE
TYPE ST_ATV320_Rx :
STRUCT
  uiOutFreq_0p1Hz_3202 : UINT; // Output freq [0.1 Hz] z rejestru 3202 (RFRD)
END_STRUCT
END_TYPE
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
END_STRUCT
END_TYPE
TYPE ST_ElevatorIn :
STRUCT
  // Czujniki pozycji procesu (Twoje: ind_elevator_in_posX)
  xInPos1        : BOOL; // skrajnie górna
  xInPos2        : BOOL; // górna pośrednia
  xInPos3        : BOOL; // dolna pośrednia
  xInPos4        : BOOL; // skrajnie dolna = ind_elevator_in_pos4
  xContainerInPos4 : BOOL; // czujnik pojemnika na windzie P4

  // Krańcówki / limity bezpieczeństwa (jeśli nie używasz - podaj TRUE/ FALSE zgodnie z logiką)
  xLS_Top        : BOOL := FALSE; // limit górny (blokuje jazdę w górę)
  xLS_Bottom     : BOOL := FALSE; // limit dolny (blokuje jazdę w dół)

  // Permisywy
  xSafetyOk      : BOOL;
  xDoorClosed    : BOOL;

  // Komunikacja i feedback z falownika
  xCommOk        : BOOL;
  stVfdRx        : ST_ATV320_Rx;
END_STRUCT
END_TYPE
TYPE ST_ElevatorOut :
STRUCT
  xRunUp             : BOOL;
  xRunDown           : BOOL;
END_STRUCT
END_TYPE
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
END_STRUCT
END_TYPE


FUNCTION_BLOCK FB_Elevator
VAR_IN_OUT

END_VAR

VAR_INPUT
  xEnable  : BOOL;
  stCmd    : ST_ElevatorCmd;
  stIn     : ST_ElevatorIn;
  stPar    : ST_ElevatorPar;
END_VAR

VAR_OUTPUT
  stOut    : ST_ElevatorOut;
  stStat   : ST_ElevatorStat;
  uiState  : UINT;  // aktualny stan windy jako UINT (do HMI)
END_VAR

VAR
  // sterowanie falownikiem przez bibliotekę Schneider Electric
  fbAtv        : GIATV.Control_ATV;
  wAtvStatus   : WORD;
  xAtvEnable   : BOOL;
  xAtvFwd      : BOOL;
  xAtvRev      : BOOL;
  xDriveStopped : BOOL;

  // edge/impuls
  rtAutoGo     : R_TRIG;
  rtReset      : R_TRIG;
  tpVfdReset   : TP;

  // timery
  tonMove      : TON;   // timeout ruchu (ruch trwa za długo)
  tonStop      : TON;   // timeout STOPPING (safety net dla wyhamowania)
  tTimeoutActive : TIME;

  // pozycje
  uiPosCount       : UINT;
  xPosConflict     : BOOL;
  ePosDecision     : E_ElevatorPos;

  // permissive
  xPermCommon      : BOOL;
  xPermUp          : BOOL;
  xPermDown        : BOOL;

  // target / porównanie
  iCurIdx          : INT;
  iTgtIdx          : INT;
  xAtTargetInt     : BOOL;

  // ruch + wyjścia
  xMoveUpReq       : BOOL;
  xMoveDownReq     : BOOL;

  xCmdFast         : BOOL;
  rCmdHz           : REAL;

  uiRef_0p1Hz       : UINT;
END_VAR


// -------------------------
// 1) Status falownika
// -------------------------
// Status pobierany z Control_ATV; aktualna prędkość zostaje z wejścia diagnostycznego.
wAtvStatus := fbAtv.q_wStatusword;
stStat.wVfdStatus  := wAtvStatus;
stStat.xVfdFault   := fbAtv.q_xAlrm OR ((wAtvStatus AND stPar.wStsMask_Fault)   <> 0);
stStat.xVfdReady   := (wAtvStatus AND stPar.wStsMask_Ready)   <> 0;
stStat.xVfdRunning := (wAtvStatus AND stPar.wStsMask_Running) <> 0;
stStat.xVfdRemote  := (wAtvStatus AND stPar.wStsMask_Remote)  <> 0;
stStat.xVfdCommOk  := fbAtv.q_xEn AND NOT fbAtv.q_xAlrm;
stStat.rVfdOutHz   := UINT_TO_REAL(stIn.stVfdRx.uiOutFreq_0p1Hz_3202) / 10.0;


// -------------------------
// 2) Detekcja pozycji (4 czujniki) + konflikt
// -------------------------
uiPosCount := TO_UINT(
  BOOL_TO_INT(stIn.xInPos1) +
  BOOL_TO_INT(stIn.xInPos2) +
  BOOL_TO_INT(stIn.xInPos3) +
  BOOL_TO_INT(stIn.xInPos4)
);

// Pozycje skrajne mogą mieć aktywny czujnik skrajny i pośredni jednocześnie.
xPosConflict := FALSE;

IF stIn.xInPos1 AND (NOT stIn.xInPos3) AND (NOT stIn.xInPos4) THEN
  stStat.ePos := E_ElevatorPos.posTop;

ELSIF (NOT stIn.xInPos1) AND (NOT stIn.xInPos2) AND stIn.xInPos4 THEN
  stStat.ePos := E_ElevatorPos.posBottom;

ELSIF (NOT stIn.xInPos1) AND stIn.xInPos2 AND (NOT stIn.xInPos3) AND (NOT stIn.xInPos4) THEN
  stStat.ePos := E_ElevatorPos.posIntermediateTop;

ELSIF (NOT stIn.xInPos1) AND (NOT stIn.xInPos2) AND stIn.xInPos3 AND (NOT stIn.xInPos4) THEN
  stStat.ePos := E_ElevatorPos.posIntermediateBottom;

ELSIF uiPosCount = 0 THEN
  stStat.ePos := E_ElevatorPos.UNKNOWN;

ELSE
  xPosConflict := TRUE;
  stStat.ePos := E_ElevatorPos.UNKNOWN;
END_IF;

// last known pos (latch)
IF NOT xEnable THEN
  stStat.eLastPos := E_ElevatorPos.UNKNOWN;
ELSIF stStat.ePos <> E_ElevatorPos.UNKNOWN THEN
  stStat.eLastPos := stStat.ePos;
END_IF;


// -------------------------
// 3) Permisywy
// -------------------------
xPermCommon :=
  xEnable AND
  stIn.xSafetyOk AND
  stIn.xDoorClosed AND
  stIn.xCommOk AND
  NOT stStat.xVfdFault;

xPermUp   := xPermCommon AND (NOT stIn.xLS_Top);
xPermDown := xPermCommon AND (NOT stIn.xLS_Bottom);


// -------------------------
// 4) Zbocza / reset falownika
// -------------------------
rtAutoGo(CLK := stCmd.xAutoGo);
rtReset(CLK := stCmd.xReset);

tpVfdReset(IN := rtReset.Q, PT := stPar.tVfdResetPulse);


// -------------------------
// 5) "At target" dla targetu latched
// -------------------------
CASE stStat.eTargetLatched OF
  E_ElevatorTarget.NONE:
    xAtTargetInt := TRUE;

  E_ElevatorTarget.posTop:
    xAtTargetInt := (stStat.ePos = E_ElevatorPos.posTop);

  E_ElevatorTarget.posIntermediateTop:
    xAtTargetInt := (stStat.ePos = E_ElevatorPos.posIntermediateTop);

  E_ElevatorTarget.posIntermediateBottom:
    xAtTargetInt := (stStat.ePos = E_ElevatorPos.posIntermediateBottom);

  E_ElevatorTarget.posBottom:
    xAtTargetInt := (stStat.ePos = E_ElevatorPos.posBottom);

  E_ElevatorTarget.posContainerEdge:
    // jedź w dół aż pojemnik opuści czujnik P4
    xAtTargetInt := NOT stIn.xContainerInPos4;

ELSE
  xAtTargetInt := TRUE;
END_CASE;

stStat.xAtTarget := xAtTargetInt;


// -------------------------
// 6) Timeout ruchu
// -------------------------
tTimeoutActive := stPar.tMoveTimeout;
IF stStat.eTargetLatched = E_ElevatorTarget.posContainerEdge THEN
  tTimeoutActive := stPar.tClearPos4Timeout;
END_IF;

tonMove(
  IN := (stStat.eState = E_ElevatorState.MANUAL_UP) OR
        (stStat.eState = E_ElevatorState.MANUAL_DOWN) OR
        (stStat.eState = E_ElevatorState.AUTO_UP) OR
        (stStat.eState = E_ElevatorState.AUTO_DOWN),
  PT := tTimeoutActive
);

// Timer bezpieczny dla STOPPING — startuje po wejściu w STOPPING
tonStop(
  IN := (stStat.eState = E_ElevatorState.STOPPING),
  PT := stPar.tStopTimeout
);

xDriveStopped := stStat.rVfdOutHz < stPar.rStopSpeedThreshold_Hz;


// -------------------------
// 7) Faulty modułu (latching)
// -------------------------
IF (NOT stStat.xFault) THEN

  IF xEnable AND xPosConflict THEN
    stStat.xFault := TRUE;
    stStat.uiFaultId := 10; // konflikt czujników pozycji
    stStat.sDiagText := 'Winda: konflikt czujników pozycji.';

  ELSIF xEnable AND tonMove.Q THEN
    stStat.xFault := TRUE;
    stStat.uiFaultId := 20; // timeout ruchu
    stStat.sDiagText := 'Winda: timeout ruchu.';

  ELSIF xEnable AND ( (stStat.eState = E_ElevatorState.AUTO_UP) OR
                      (stStat.eState = E_ElevatorState.AUTO_DOWN) OR
                      (stStat.eState = E_ElevatorState.MANUAL_UP) OR
                      (stStat.eState = E_ElevatorState.MANUAL_DOWN) ) AND (NOT stIn.xCommOk) THEN
    stStat.xFault := TRUE;
    stStat.uiFaultId := 30; // utrata komunikacji w ruchu
    stStat.sDiagText := 'Winda: utrata komunikacji podczas ruchu.';

  ELSIF xEnable AND ( (stStat.eState = E_ElevatorState.AUTO_UP) OR
                      (stStat.eState = E_ElevatorState.AUTO_DOWN) OR
                      (stStat.eState = E_ElevatorState.MANUAL_UP) OR
                      (stStat.eState = E_ElevatorState.MANUAL_DOWN) ) AND (NOT stIn.xSafetyOk) THEN
    stStat.xFault := TRUE;
    stStat.uiFaultId := 40; // safety drop w ruchu
    stStat.sDiagText := 'Winda: utrata zezwolenia safety podczas ruchu.';

  ELSIF xEnable AND ( (stStat.eState = E_ElevatorState.AUTO_UP) OR
                      (stStat.eState = E_ElevatorState.AUTO_DOWN) OR
                      (stStat.eState = E_ElevatorState.MANUAL_UP) OR
                      (stStat.eState = E_ElevatorState.MANUAL_DOWN) ) AND (NOT stIn.xDoorClosed) THEN
    stStat.xFault := TRUE;
    stStat.uiFaultId := 41; // drzwi otwarte w ruchu
    stStat.sDiagText := 'Winda: otwarcie drzwi podczas ruchu.';

  ELSIF xEnable AND stStat.xVfdFault THEN
    stStat.xFault := TRUE;
    stStat.uiFaultId := 60; // fault falownika (ETA bit Fault w rejestrze 3201)
    stStat.sDiagText := 'Winda: błąd falownika ATV320.';
  END_IF;

END_IF;

// reset faultów modułu + targetu
IF rtReset.Q THEN
  stStat.xFault := FALSE;
  stStat.uiFaultId := 0;
  stStat.sDiagText := '';
  stStat.eTargetLatched := E_ElevatorTarget.NONE;
END_IF;


// -------------------------
// 8) Maszyna stanów
// -------------------------
IF NOT xEnable THEN
  stStat.eState := E_ElevatorState.DISABLED;

ELSE
  IF stStat.xFault THEN
    stStat.eState := E_ElevatorState.FAULT;
  END_IF;

  CASE stStat.eState OF

    E_ElevatorState.DISABLED:
      stStat.eTargetLatched := E_ElevatorTarget.NONE;
      stStat.eState := E_ElevatorState.IDLE;

    E_ElevatorState.IDLE:

      // manual: czyścimy target, żeby nie było "niespodzianek" po powrocie na AUTO
      IF stCmd.eMode = E_ElevatorMode.MANUAL THEN
        stStat.eTargetLatched := E_ElevatorTarget.NONE;
      END_IF;

      // latch target w AUTO na zboczu
      IF (stCmd.eMode = E_ElevatorMode.AUTO) AND rtAutoGo.Q THEN
        stStat.eTargetLatched := stCmd.eAutoTarget;

        // Przelicz warunek celu po zlapaniu nowego targetu.
        CASE stStat.eTargetLatched OF
          E_ElevatorTarget.NONE:
            xAtTargetInt := TRUE;

          E_ElevatorTarget.posTop:
            xAtTargetInt := (stStat.ePos = E_ElevatorPos.posTop);

          E_ElevatorTarget.posIntermediateTop:
            xAtTargetInt := (stStat.ePos = E_ElevatorPos.posIntermediateTop);

          E_ElevatorTarget.posIntermediateBottom:
            xAtTargetInt := (stStat.ePos = E_ElevatorPos.posIntermediateBottom);

          E_ElevatorTarget.posBottom:
            xAtTargetInt := (stStat.ePos = E_ElevatorPos.posBottom);

          E_ElevatorTarget.posContainerEdge:
            xAtTargetInt := NOT stIn.xContainerInPos4;

        ELSE
          xAtTargetInt := TRUE;
        END_CASE;
        stStat.xAtTarget := xAtTargetInt;
      END_IF;

      // stop w IDLE
      IF stCmd.xStop OR ( (stCmd.eMode = E_ElevatorMode.AUTO) AND stCmd.xAutoStop ) THEN
        stStat.eTargetLatched := E_ElevatorTarget.NONE;
      END_IF;

      // priorytet: MANUAL (tylko gdy eMode=MANUAL)
      IF stCmd.eMode = E_ElevatorMode.MANUAL THEN

        IF stCmd.xManUp AND (NOT stCmd.xManDown) AND xPermUp THEN
          stStat.eState := E_ElevatorState.MANUAL_UP;

        ELSIF stCmd.xManDown AND (NOT stCmd.xManUp) AND xPermDown THEN
          stStat.eState := E_ElevatorState.MANUAL_DOWN;

        END_IF;

      ELSE
        // AUTO
        IF stStat.eTargetLatched <> E_ElevatorTarget.NONE THEN

          // jeśli już spełniony warunek celu -> skasuj target
          IF xAtTargetInt THEN
            stStat.eTargetLatched := E_ElevatorTarget.NONE;

          ELSE
            // specjalny cel: jedź w dół aż POS4 zgaśnie
            IF stStat.eTargetLatched = E_ElevatorTarget.posContainerEdge THEN
              IF xPermDown THEN
                stStat.eState := E_ElevatorState.AUTO_DOWN;
              END_IF;

            ELSE
              // wybór pozycji do decyzji (aktualna jeśli znana, inaczej ostatnia znana)
              ePosDecision := stStat.ePos;
              IF ePosDecision = E_ElevatorPos.UNKNOWN THEN
                ePosDecision := stStat.eLastPos;
              END_IF;

              // jeżeli nadal nie wiemy gdzie jesteśmy -> fault (bezpieczniej niż "zgaduj")
              IF ePosDecision = E_ElevatorPos.UNKNOWN THEN
                stStat.xFault := TRUE;
                stStat.uiFaultId := 50; // nieznana pozycja przy starcie AUTO
                stStat.sDiagText := 'Winda: nieznana pozycja przy starcie AUTO.';
                stStat.eState := E_ElevatorState.FAULT;

              ELSE
                // mapowanie POS -> index (1=góra, 4=dół)
                CASE ePosDecision OF
                  E_ElevatorPos.posTop:                iCurIdx := 1;
                  E_ElevatorPos.posIntermediateTop:    iCurIdx := 2;
                  E_ElevatorPos.posIntermediateBottom: iCurIdx := 3;
                  E_ElevatorPos.posBottom:             iCurIdx := 4;
                ELSE
                  iCurIdx := 0;
                END_CASE;

                CASE stStat.eTargetLatched OF
                  E_ElevatorTarget.posTop:                iTgtIdx := 1;
                  E_ElevatorTarget.posIntermediateTop:    iTgtIdx := 2;
                  E_ElevatorTarget.posIntermediateBottom: iTgtIdx := 3;
                  E_ElevatorTarget.posBottom:             iTgtIdx := 4;
                ELSE
                  iTgtIdx := 0;
                END_CASE;

                IF (iCurIdx = 0) OR (iTgtIdx = 0) THEN
                  stStat.xFault := TRUE;
                  stStat.uiFaultId := 51; // błąd mapowania target/pos
                  stStat.sDiagText := 'Winda: błędne mapowanie pozycji lub celu.';
                  stStat.eState := E_ElevatorState.FAULT;

                ELSIF iTgtIdx < iCurIdx THEN
                  // jedź w górę (mniejszy index = wyżej)
                  IF xPermUp THEN
                    stStat.eState := E_ElevatorState.AUTO_UP;
                  END_IF;

                ELSIF iTgtIdx > iCurIdx THEN
                  // jedź w dół
                  IF xPermDown THEN
                    stStat.eState := E_ElevatorState.AUTO_DOWN;
                  END_IF;

                ELSE
                  // teoretycznie równy (powinno wejść w xAtTargetInt)
                  stStat.eTargetLatched := E_ElevatorTarget.NONE;
                END_IF;

              END_IF;

            END_IF;

          END_IF;

        END_IF;

      END_IF;

    E_ElevatorState.MANUAL_UP:
      IF (stCmd.eMode <> E_ElevatorMode.MANUAL) OR
         (NOT xPermUp) OR stCmd.xStop OR (NOT stCmd.xManUp) OR stCmd.xManDown THEN
        stStat.eState := E_ElevatorState.STOPPING;
      END_IF;

    E_ElevatorState.MANUAL_DOWN:
      IF (stCmd.eMode <> E_ElevatorMode.MANUAL) OR
         (NOT xPermDown) OR stCmd.xStop OR (NOT stCmd.xManDown) OR stCmd.xManUp THEN
        stStat.eState := E_ElevatorState.STOPPING;
      END_IF;

    E_ElevatorState.AUTO_UP:
      // awaryjne warunki
      IF (stCmd.eMode <> E_ElevatorMode.AUTO) OR
         (NOT xPermCommon) OR (NOT xPermUp) OR stCmd.xStop OR stCmd.xAutoStop THEN
        stStat.eTargetLatched := E_ElevatorTarget.NONE;
        stStat.eState := E_ElevatorState.STOPPING;

      // osiągnięto cel
      ELSIF xAtTargetInt THEN
        stStat.eTargetLatched := E_ElevatorTarget.NONE;
        stStat.eState := E_ElevatorState.STOPPING;
      END_IF;

    E_ElevatorState.AUTO_DOWN:
      IF (stCmd.eMode <> E_ElevatorMode.AUTO) OR
         (NOT xPermCommon) OR (NOT xPermDown) OR stCmd.xStop OR stCmd.xAutoStop THEN
        stStat.eTargetLatched := E_ElevatorTarget.NONE;
        stStat.eState := E_ElevatorState.STOPPING;

      ELSIF xAtTargetInt THEN
        stStat.eTargetLatched := E_ElevatorTarget.NONE;
        stStat.eState := E_ElevatorState.STOPPING;
      END_IF;

    E_ElevatorState.STOPPING:
      // Pozostań w STOPPING aż falownik faktycznie wyhamuje (rVfdOutHz < próg)
      // lub upłynie bezpieczny timeout tonStop (watchdog na wypadek utraty feedbacku VFD)
      IF xDriveStopped OR tonStop.Q THEN
        stStat.eState := E_ElevatorState.IDLE;
      END_IF;

    E_ElevatorState.FAULT:
      IF NOT stStat.xFault THEN
        stStat.eState := E_ElevatorState.IDLE;
      END_IF;

  ELSE
    stStat.eState := E_ElevatorState.FAULT;
    stStat.xFault := TRUE;
    stStat.uiFaultId := 999;
    stStat.sDiagText := 'Winda: nieprawidłowy stan automatu.';
  END_CASE;

END_IF;


// -------------------------
// 9) Ruch (wyjścia logiczne) + profil prędkości
// -------------------------
xMoveUpReq   := (stStat.eState = E_ElevatorState.MANUAL_UP) OR (stStat.eState = E_ElevatorState.AUTO_UP);
xMoveDownReq := (stStat.eState = E_ElevatorState.MANUAL_DOWN) OR (stStat.eState = E_ElevatorState.AUTO_DOWN);

// wybór fast/slow
IF xMoveUpReq OR xMoveDownReq THEN

  IF stCmd.eMode = E_ElevatorMode.MANUAL THEN
    // manual: operator decyduje
    xCmdFast := stCmd.xManFast;

  ELSE
    // AUTO: profil segmentów slow-fast-slow
    // FAST aktywowany tylko w segmencie środkowym (między pozycjami pośrednimi)
    IF stStat.eTargetLatched = E_ElevatorTarget.posContainerEdge THEN
      xCmdFast := FALSE;
    ELSIF xMoveUpReq THEN
      // FAST tylko w segmencie środkowym: posIntermediateBottom -> posIntermediateTop
      xCmdFast := (stStat.eLastPos = E_ElevatorPos.posIntermediateBottom);
    ELSIF xMoveDownReq THEN
      // FAST tylko w segmencie środkowym: posIntermediateTop -> posIntermediateBottom
      xCmdFast := (stStat.eLastPos = E_ElevatorPos.posIntermediateTop);
    ELSE
      xCmdFast := FALSE;
    END_IF;

  END_IF;

ELSE
  xCmdFast := FALSE;
END_IF;

// Hz zadane
IF xMoveUpReq OR xMoveDownReq THEN
  IF (stCmd.eMode = E_ElevatorMode.AUTO) AND
     (stStat.eTargetLatched = E_ElevatorTarget.posContainerEdge) THEN
    // Zjazd o wysokość tacki zawsze z prędkością 5 Hz.
    rCmdHz := 5.0;
  ELSIF xCmdFast THEN
    rCmdHz := stCmd.rSpeedFast_Hz;
  ELSE
    rCmdHz := stCmd.rSpeedSlow_Hz;
  END_IF;
ELSE
  rCmdHz := 0.0;
END_IF;

stStat.xCmdFast := xCmdFast;
stStat.rCmdHz   := rCmdHz;

// Przelicz Hz → jednostki 0.1 Hz, z ograniczeniem do rMaxSpeed_Hz
IF rCmdHz > stPar.rMaxSpeed_Hz THEN
  rCmdHz := stPar.rMaxSpeed_Hz;
ELSIF rCmdHz < 0.0 THEN
  rCmdHz := 0.0;
END_IF;
uiRef_0p1Hz := REAL_TO_UINT(rCmdHz * 10.0);


// -------------------------
// 10) Sterowanie falownikiem przez Control_ATV
// -------------------------
xAtvFwd := FALSE;
xAtvRev := FALSE;

IF xMoveUpReq AND NOT xMoveDownReq THEN
  IF stPar.xFwdIsUp THEN
    xAtvFwd := TRUE;
  ELSE
    xAtvRev := TRUE;
  END_IF;

ELSIF xMoveDownReq AND NOT xMoveUpReq THEN
  IF stPar.xFwdIsUp THEN
    xAtvRev := TRUE;
  ELSE
    xAtvFwd := TRUE;
  END_IF;
END_IF;

xAtvEnable := xEnable AND stIn.xSafetyOk AND stIn.xDoorClosed AND stIn.xCommOk;

fbAtv(
  Axis := Altivar_320,
  i_xEn := xAtvEnable,
  i_xKeepOpEn := TRUE,
  i_xFwd := xAtvFwd,
  i_xRev := xAtvRev,
  i_xQckStop := TRUE,
  i_xFreeWhl := TRUE,
  i_xFltRst := tpVfdReset.Q,
  i_wSpdRef := UINT_TO_WORD(uiRef_0p1Hz)
);

wAtvStatus := fbAtv.q_wStatusword;
stStat.wVfdStatus  := wAtvStatus;
stStat.xVfdFault   := fbAtv.q_xAlrm OR ((wAtvStatus AND stPar.wStsMask_Fault)   <> 0);
stStat.xVfdReady   := (wAtvStatus AND stPar.wStsMask_Ready)   <> 0;
stStat.xVfdRunning := (wAtvStatus AND stPar.wStsMask_Running) <> 0;
stStat.xVfdRemote  := (wAtvStatus AND stPar.wStsMask_Remote)  <> 0;
stStat.xVfdCommOk  := fbAtv.q_xEn AND NOT fbAtv.q_xAlrm;

stOut.xRunUp   := xMoveUpReq;
stOut.xRunDown := xMoveDownReq;

stStat.xBusy := xMoveUpReq OR xMoveDownReq;


// Stan windy jako UINT - do odczytu z PRG_Main / HMI
uiState := TO_UINT(stStat.eState);

