/PROG RT_BOOT
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  CALL RB_BIND ;
   2:  F[14]=(ON) ;
   3:  F[756]=(ON) ;
   4:  F[15]=(OFF) ;
   5:  F[739]=(OFF) ;
   6:  R[190]=(R[78]) ;
   7:  F[38]=(ON) ;
   8:  IF (R[179]<>710),F[16]=(ON) ;
   9:  IF (F[16]),R[179]=(900) ;
/POS
/END
