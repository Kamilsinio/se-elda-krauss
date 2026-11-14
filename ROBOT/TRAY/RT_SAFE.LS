/PROG RT_SAFE
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  F[21]=(F[757]) ;
   2:  F[21]=(F[21] AND F[752]) ;
   3:  F[21]=(F[21] AND F[739]) ;
   4:  F[21]=(F[21] AND F[15]) ;
   5:  F[21]=(F[21] AND !F[759]) ;
   6:  F[21]=(F[21] AND !F[16]) ;
   7:  IF ((((R[27] DIV 1) MOD 2)=1) AND !F[582]),F[21]=(OFF) ;
   8:  IF ((((R[27] DIV 2) MOD 2)=1) AND !F[588]),F[21]=(OFF) ;
   9:  IF ((((R[27] DIV 4) MOD 2)=1) AND !F[594]),F[21]=(OFF) ;
  10:  IF ((((R[27] DIV 8) MOD 2)=1) AND !F[600]),F[21]=(OFF) ;
  11:  IF ((((R[27] DIV 16) MOD 2)=1) AND !F[606]),F[21]=(OFF) ;
  12:  IF ((((R[28] DIV 1) MOD 2)=1) AND !F[582]),F[21]=(OFF) ;
  13:  IF ((((R[28] DIV 2) MOD 2)=1) AND !F[588]),F[21]=(OFF) ;
  14:  IF ((((R[28] DIV 4) MOD 2)=1) AND !F[594]),F[21]=(OFF) ;
  15:  IF ((((R[28] DIV 8) MOD 2)=1) AND !F[600]),F[21]=(OFF) ;
  16:  IF ((((R[28] DIV 16) MOD 2)=1) AND !F[606]),F[21]=(OFF) ;
  17:  IF ((((R[29] DIV 1) MOD 2)=1) AND !F[582]),F[21]=(OFF) ;
  18:  IF ((((R[29] DIV 2) MOD 2)=1) AND !F[588]),F[21]=(OFF) ;
  19:  IF ((((R[29] DIV 4) MOD 2)=1) AND !F[594]),F[21]=(OFF) ;
  20:  IF ((((R[29] DIV 8) MOD 2)=1) AND !F[600]),F[21]=(OFF) ;
  21:  IF ((((R[29] DIV 16) MOD 2)=1) AND !F[606]),F[21]=(OFF) ;
  22:  IF ((((R[30] DIV 1) MOD 2)=1) AND !F[582]),F[21]=(OFF) ;
  23:  IF ((((R[30] DIV 2) MOD 2)=1) AND !F[588]),F[21]=(OFF) ;
  24:  IF ((((R[30] DIV 4) MOD 2)=1) AND !F[594]),F[21]=(OFF) ;
  25:  IF ((((R[30] DIV 8) MOD 2)=1) AND !F[600]),F[21]=(OFF) ;
  26:  IF ((((R[30] DIV 16) MOD 2)=1) AND !F[606]),F[21]=(OFF) ;
  27:  IF ((((R[31] DIV 1) MOD 2)=1) AND !F[582]),F[21]=(OFF) ;
  28:  IF ((((R[31] DIV 2) MOD 2)=1) AND !F[588]),F[21]=(OFF) ;
  29:  IF ((((R[31] DIV 4) MOD 2)=1) AND !F[594]),F[21]=(OFF) ;
  30:  IF ((((R[31] DIV 8) MOD 2)=1) AND !F[600]),F[21]=(OFF) ;
  31:  IF ((((R[31] DIV 16) MOD 2)=1) AND !F[606]),F[21]=(OFF) ;
  32:  IF ((((R[178] DIV 1) MOD 2)=1) AND !F[582]),F[21]=(OFF) ;
  33:  IF ((((R[178] DIV 2) MOD 2)=1) AND !F[588]),F[21]=(OFF) ;
  34:  IF ((((R[178] DIV 4) MOD 2)=1) AND !F[594]),F[21]=(OFF) ;
  35:  IF ((((R[178] DIV 8) MOD 2)=1) AND !F[600]),F[21]=(OFF) ;
  36:  IF ((((R[178] DIV 16) MOD 2)=1) AND !F[606]),F[21]=(OFF) ;
  37:  IF (F[21]),JMP LBL[999] ;
  38:  IF (R[179]<>900),R[200]=(R[179]) ;
  39:  R[97]=(1100) ;
  40:  F[16]=(ON) ;
  41:  F[759]=(ON) ;
  42:  R[179]=(900) ;
  43:  LBL[999] ;
/POS
/END
