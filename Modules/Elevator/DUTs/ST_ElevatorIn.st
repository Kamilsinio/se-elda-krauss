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
    drive : ST_ElevatorDriveIn;
END_STRUCT
END_TYPE
