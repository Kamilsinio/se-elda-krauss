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
   4:  ! Najpierw konfiguracja i ;
   5:  ! zatwierdzenie zasobow ;
   6:  ! F[738] - Odebrano rzeczywista ;
   7:  ! konfiguracje EIP, OFF brak ;
   8:  ! dopuszczenia lacza. ;
   9:  ! ON opisany warunek/zadanie, ;
  10:  ! OFF brak. ;
  11:  IF (!F[738:MapaOdebr]),JMP LBL[90] ;
  12:  ! F[737] - ON izolowany TEST, ;
  13:  ! OFF LIVE. Nie dopuszcza mock w ;
  14:  ! produkcji. ON ;
  15:  ! opisany warunek/zadanie, OFF ;
  16:  ! brak. ;
  17:  F[737:WariantTEST]=(OFF) ;
  18:  ! F[736] - Serwis ma pracowac, ;
  19:  ! OFF konczy serwis i uniewaznia ;
  20:  ! sesje. ON ;
  21:  ! opisany warunek/zadanie, OFF ;
  22:  ! brak. ;
  23:  F[736:SerwisON]=(ON) ;
  24:  RUN PLC_SVC ;
  25:  LBL[90] ;
/POS
/END
