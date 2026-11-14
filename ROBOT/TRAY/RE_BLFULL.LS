/PROG RE_BLFULL
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  F[23]=(OFF) ;
   2:  IF ((R[151]<>0) OR F[624]),JMP LBL[999] ;
   3:  R[81]=(R[188]) ;
   4:  R[82]=(R[189]) ;
   5:  F[624]=(ON) ;
   6:  LBL[999] ;
/POS
/END
