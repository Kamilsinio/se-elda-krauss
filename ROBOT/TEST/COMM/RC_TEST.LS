/PROG RC_TEST
/ATTR
OWNER = MNEDITOR;
COMMENT = "EIP bez ruchu";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  ! Zatrzymac SVC i BG przed testem ;
   2:  CALL RC_INIT ;
   3:  F[738]=(ON) ;
   4:  F[736]=(ON) ;
   5:  R[146]=(0) ;
   6:  R[1]=(2) ;
   7:  F[826]=(ON) ;
   8:  R[2]=(1) ;
   9:  R[142]=(1) ;
  10:  CALL RC_RX ;
  11:  CALL RC_MON ;
  12:  CALL RC_TICK ;
  13:  R[2]=(2) ;
  14:  R[142]=(2) ;
  15:  CALL RC_RX ;
  16:  CALL RC_MON ;
  17:  CALL RC_TICK ;
  18:  F[825]=(ON) ;
  19:  CALL RC_TICK ;
  20:  F[826]=(OFF) ;
  21:  F[825]=(OFF) ;
  22:  CALL RC_TICK ;
  23:  CALL RC_RECOV ;
  24:  CALL RC_TICK ;
  25:  F[824]=(ON) ;
  26:  F[830]=(ON) ;
  27:  F[739]=(ON) ;
  28:  R[89]=(7) ;
  29:  R[90]=(32768) ;
  30:  R[91]=(65535) ;
  31:  F[629]=(ON) ;
  32:  CALL RC_TICK ;
  33:  IF (R[155]<>10),F[753]=(ON) ;
  34:  R[89]=(99) ;
  35:  CALL RC_TICK ;
  36:  IF (R[115]<>7),F[753]=(ON) ;
  37:  F[804]=(ON) ;
  38:  CALL RC_TICK ;
  39:  IF (R[156]<>20),F[753]=(ON) ;
  40:  F[804]=(OFF) ;
  41:  CALL RC_TICK ;
  42:  IF (R[155]<>0),F[753]=(ON) ;
  43:  R[146]=(1) ;
  44:  IF (F[753]),R[146]=(900) ;
  45:  F[736]=(OFF) ;
  46:  F[738]=(OFF) ;
/POS
/END
