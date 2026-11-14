/PROG RT_NEW
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  IF (!F[2]),JMP LBL[999] ;
   2:  IF (F[572] OR F[15]),JMP LBL[999] ;
   3:  IF (!F[11]),JMP LBL[999] ;
   4:  IF (!F[56]),JMP LBL[999] ;
   5:  IF (!F[47] OR F[50]),JMP LBL[999] ;
   6:  IF (F[568] OR F[573]),JMP LBL[999] ;
   7:  IF ((R[126]<>30) AND (R[126]<>40)),JMP LBL[999] ;
   8:  IF ((R[147]<>0) OR F[541]),JMP LBL[999] ;
   9:  IF ((R[149]<>0) OR F[542]),JMP LBL[999] ;
  10:  IF ((R[151]<>0) OR F[540]),JMP LBL[999] ;
  11:  IF ((R[153]<>0) OR F[547]),JMP LBL[999] ;
  12:  IF ((R[155]<>0) OR F[545]),JMP LBL[999] ;
  13:  IF ((R[157]<>0) OR F[546]),JMP LBL[999] ;
  14:  IF ((R[159]<>0) OR F[544]),JMP LBL[999] ;
  15:  IF ((R[161]<>0) OR F[548]),JMP LBL[999] ;
  16:  IF ((R[163]<>0) OR F[543]),JMP LBL[999] ;
  17:  IF ((R[165]<>0) OR F[607]),JMP LBL[999] ;
  18:  IF ((R[167]<>0) OR F[578]),JMP LBL[999] ;
  19:  IF ((R[169]<>0) OR F[584]),JMP LBL[999] ;
  20:  IF ((R[171]<>0) OR F[590]),JMP LBL[999] ;
  21:  IF ((R[173]<>0) OR F[596]),JMP LBL[999] ;
  22:  IF ((R[175]<>0) OR F[602]),JMP LBL[999] ;
  23:  IF (F[17]),JMP LBL[999] ;
  24:  IF (R[98]<>0),JMP LBL[999] ;
  25:  R[187]=(0) ;
  26:  R[188]=(0) ;
  27:  R[185]=(0) ;
  28:  R[186]=(1) ;
  29:  F[19]=(OFF) ;
  30:  F[42]=(OFF) ;
  31:  F[41]=(OFF) ;
  32:  F[39]=(OFF) ;
  33:  F[40]=(OFF) ;
  34:  R[189]=(R[66]) ;
  35:  F[645]=(ON) ;
  36:  F[16]=(OFF) ;
  37:  F[759]=(OFF) ;
  38:  F[739]=(OFF) ;
  39:  F[15]=(OFF) ;
  40:  R[97]=(0) ;
  41:  R[190]=(R[78]) ;
  42:  R[179]=(10) ;
  43:  F[27]=(ON) ;
  44:  F[28]=(ON) ;
  45:  F[29]=(ON) ;
  46:  F[30]=(ON) ;
  47:  F[2]=(OFF) ;
  48:  CALL RC_RECOV ;
  49:  LBL[999] ;
/POS
/END
