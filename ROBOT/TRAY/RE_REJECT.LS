/PROG RE_REJECT
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  F[23]=(OFF) ;
   2:  IF ((R[165]<>0) OR F[671]),JMP LBL[999] ;
   3:  R[104]=(R[192]) ;
   4:  R[105]=(R[183]) ;
   5:  R[106]=(R[189]) ;
   6:  F[671]=(ON) ;
   7:  LBL[999] ;
/POS
/END
