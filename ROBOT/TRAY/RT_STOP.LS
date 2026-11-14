/PROG RT_STOP
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  IF (R[180]=700),JMP LBL[700] ;
   2:  IF (R[180]=710),JMP LBL[710] ;
   3:  IF (R[180]=900),JMP LBL[900] ;
   4:  CALL RT_BADSTATE ;
   5:  JMP LBL[999] ;
   6:  LBL[700] ;
   7:  ! Dojazd do postoju ;
   8:  IF (F[56]),R[179]=(710) ;
   9:  IF (F[56]),JMP LBL[999] ;
  10:  CALL RM_HOME ;
  11:  IF (F[20]),R[179]=(710) ;
  12:  JMP LBL[999] ;
  13:  LBL[710] ;
  14:  ! Postoj po rozliczeniu ;
  15:  F[15]=(OFF) ;
  16:  F[739]=(OFF) ;
  17:  IF (F[560] OR (R[63]>0)),F[646]=(OFF) ;
  18:  IF ((F[560] OR (R[63]>0)) AND F[570]),F[15]=(ON) ;
  19:  IF (F[15]),F[739]=(ON) ;
  20:  IF (F[15]),R[179]=(10) ;
  21:  IF (F[15]),JMP LBL[999] ;
  22:  IF (F[560] OR (R[63]>0)),JMP LBL[999] ;
  23:  F[15]=(OFF) ;
  24:  F[739]=(OFF) ;
  25:  F[646]=(ON) ;
  26:  F[654]=(ON) ;
  27:  R[102]=(80) ;
  28:  JMP LBL[999] ;
  29:  LBL[900] ;
  30:  ! Wymagane uzgodnienie stanu ;
  31:  F[15]=(OFF) ;
  32:  F[739]=(OFF) ;
  33:  F[16]=(ON) ;
  34:  R[102]=(80) ;
  35:  IF (F[2]),CALL RT_NEW ;
  36:  IF (F[3] AND F[4]),CALL RT_RECOV ;
  37:  JMP LBL[999] ;
  38:  LBL[9000] ;
  39:  IF (R[97]=0),R[97]=(1900) ;
  40:  F[16]=(ON) ;
  41:  R[179]=(900) ;
  42:  LBL[999] ;
/POS
/END
