/PROG PLC_LIVE
/ATTR
OWNER = MNEDITOR;
COMMENT = "Start serwisu";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  ! Lokalny start serwisu ;
   2:  ! Robot zada - PLC wykonuje ;
   3:  ! Festo i EUROMAP ;
   4:  JMP LBL[90] ;
   5:  ! Najpierw konfiguracja i ;
   6:  ! zatwierdzenie zasobow ;
   7:  ! F[738] - Odebrano rzeczywista ;
   8:  ! konfiguracje EIP, OFF brak ;
   9:  ! dopuszczenia lacza. ;
  10:  ! ON opisany warunek/zadanie, ;
  11:  ! OFF brak. ;
  12:  IF (!F[738:MapaOdebr]),JMP LBL[90] ;
  13:  ! F[737] - ON izolowany TEST, ;
  14:  ! OFF LIVE. Nie dopuszcza mock w ;
  15:  ! produkcji. ON ;
  16:  ! opisany warunek/zadanie, OFF ;
  17:  ! brak. ;
  18:  F[737:WariantTEST]=(OFF) ;
  19:  ! F[736] - Serwis ma pracowac, ;
  20:  ! OFF konczy serwis i uniewaznia ;
  21:  ! sesje. ON ;
  22:  ! opisany warunek/zadanie, OFF ;
  23:  ! brak. ;
  24:  F[736:SerwisON]=(ON) ;
  25:  RUN PLC_SVC ;
  26:  LBL[90] ;
/POS
/END
