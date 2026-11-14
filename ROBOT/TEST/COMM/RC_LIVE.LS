/PROG RC_LIVE
/ATTR
OWNER = MNEDITOR;
COMMENT = "EIP bez ruchu";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  JMP LBL[90] ;
   2:  ! Najpierw konfiguracja i zatwierdzenie zasobow ;
   3:  IF (!F[738]),JMP LBL[90] ;
   4:  F[737]=(OFF) ;
   5:  F[736]=(ON) ;
   6:  RUN RC_SVC ;
   7:  LBL[90] ;
/POS
/END
