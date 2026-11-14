/PROG RM_TRAYOUT
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
   6:  IF (!F[93]),JMP LBL[9000] ;
   7:  L PR[35] R[46]mm/sec FINE ;
   8:  CALL RT_SAFE ;
   9:  IF (!F[21]),JMP LBL[999] ;
  10:  IF (!F[69]),JMP LBL[9000] ;
  11:  J PR[11] R[46]% FINE ;
  12:  F[20]=(ON) ;
  13:  JMP LBL[999] ;
  14:  LBL[9000] ;
  15:  IF (R[179]<>900),R[200]=(R[179]) ;
  16:  R[97]=(1101) ;
  17:  F[16]=(ON) ;
  18:  F[759]=(ON) ;
  19:  R[179]=(900) ;
  20:  LBL[999] ;
/POS
/END
