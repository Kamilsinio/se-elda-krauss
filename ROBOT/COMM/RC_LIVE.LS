/PROG RC_LIVE
/ATTR
OWNER = MNEDITOR;
COMMENT = "EIP bez ruchu";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  ! Najpierw konfiguracja i zatwierdzenie zasobow ;
   2:  IF (!F[738]),JMP LBL[90] ;
   3:  F[737]=(OFF) ;
   4:  F[736]=(ON) ;
   5:  RUN RC_SVC ;
   6:  LBL[90] ;
/POS
/END
