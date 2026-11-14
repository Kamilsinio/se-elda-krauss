/PROG RE_SAMPLE
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  F[23]=(OFF) ;
   2:  IF ((R[157]<>0) OR F[630]),JMP LBL[999] ;
   3:  R[92]=(R[192]) ;
   4:  R[93]=(R[183]) ;
   5:  R[94]=(R[189]) ;
   6:  F[630]=(ON) ;
   7:  LBL[999] ;
/POS
/END
