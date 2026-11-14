/PROG RC_SVC
/ATTR
OWNER = MNEDITOR;
COMMENT = "EIP bez ruchu";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  ! Jedyna petla obslugi zadan ;
   2:  LBL[1] ;
   3:  CALL RC_TICK ;
   4:  WAIT   .02(sec) ;
   5:  IF (F[736]),JMP LBL[1] ;
   6:  CALL RC_DROP ;
   7:  CALL RC_CMD ;
   8:  CALL RC_TX ;
/POS
/END
