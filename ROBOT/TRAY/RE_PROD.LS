/PROG RE_PROD
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  F[23]=(OFF) ;
   2:  IF ((R[155]<>0) OR F[629]),JMP LBL[999] ;
   3:  R[89]=(R[192]) ;
   4:  R[90]=(R[183]) ;
   5:  R[91]=(R[189]) ;
   6:  F[629]=(ON) ;
   7:  LBL[999] ;
/POS
/END
