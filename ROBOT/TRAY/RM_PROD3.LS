/PROG RM_PROD3
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = 1,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  F[20]=(OFF) ;
   2:  UTOOL_NUM=R[48] ;
   3:  UFRAME_NUM=R[49] ;
   4:  CALL RT_SAFE ;
   5:  IF (!F[21]),JMP LBL[999] ;
   6:  IF (!F[78]),JMP LBL[9000] ;
   7:  L PR[20] R[46]mm/sec FINE Offset,PR[29] ;
   8:  F[20]=(ON) ;
   9:  JMP LBL[999] ;
  10:  LBL[9000] ;
  11:  IF (R[179]<>900),R[200]=(R[179]) ;
  12:  R[97]=(1101) ;
  13:  F[16]=(ON) ;
  14:  F[759]=(ON) ;
  15:  R[179]=(900) ;
  16:  LBL[999] ;
/POS
/END
