/PROG RM_SRCIN
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
   6:  IF (!F[60]),JMP LBL[9000] ;
   7:  J PR[2] R[46]% FINE ;
   8:  CALL RT_SAFE ;
   9:  IF (!F[21]),JMP LBL[999] ;
  10:  IF (!F[61]),JMP LBL[9000] ;
  11:  L PR[3] R[46]mm/sec FINE ;
  12:  CALL RT_SAFE ;
  13:  IF (!F[21]),JMP LBL[999] ;
  14:  IF (!F[62]),JMP LBL[9000] ;
  15:  L PR[4] R[46]mm/sec FINE ;
  16:  F[20]=(ON) ;
  17:  JMP LBL[999] ;
  18:  LBL[9000] ;
  19:  IF (R[179]<>900),R[200]=(R[179]) ;
  20:  R[97]=(1101) ;
  21:  F[16]=(ON) ;
  22:  F[759]=(ON) ;
  23:  R[179]=(900) ;
  24:  LBL[999] ;
/POS
/END
