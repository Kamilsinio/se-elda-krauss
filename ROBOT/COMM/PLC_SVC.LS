/PROG PLC_SVC
/ATTR
OWNER = MNEDITOR;
COMMENT = "Serwis PLC";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  ! Petla serwisu lacza ;
   2:  ! Robot zada - PLC wykonuje ;
   3:  ! Festo i EUROMAP ;
   4:  ! Jedyna petla obslugi zadan ;
   5:  LBL[1] ;
   6:  CALL PLC_SCAN ;
   7:  WAIT   .02(sec) ;
   8:  ! F[736] - Serwis ma pracowac, ;
   9:  ! OFF konczy serwis i uniewaznia ;
  10:  ! sesje. ON ;
  11:  ! opisany warunek/zadanie, OFF ;
  12:  ! brak. ;
  13:  IF (F[736:SerwisON]),JMP LBL[1] ;
  14:  CALL PLC_LOST ;
  15:  CALL PLC_CMD ;
  16:  CALL PLC_TX ;
/POS
/END
