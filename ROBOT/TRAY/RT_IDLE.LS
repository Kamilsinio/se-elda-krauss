/PROG RT_IDLE
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  IF (R[180]=10),JMP LBL[10] ;
   2:  CALL RT_BADSTATE ;
   3:  JMP LBL[999] ;
   4:  LBL[10] ;
   5:  ! Oczekiwanie i przypisanie partii ;
   6:  R[102]=(20) ;
   7:  IF (!F[15]),JMP LBL[999] ;
   8:  IF (F[42]),R[179]=(620) ;
   9:  IF (F[42]),JMP LBL[999] ;
  10:  IF (F[17] AND (R[185]>0)),R[179]=(300) ;
  11:  IF (F[17] AND (R[185]>0)),JMP LBL[999] ;
  12:  IF (F[560]),CALL RT_ASSIGN ;
  13:  IF (F[16]),JMP LBL[9000] ;
  14:  IF (F[17]),R[179]=(300) ;
  15:  IF (F[17] AND (R[195]=0) AND !F[19]),R[179]=(200) ;
  16:  IF (F[17]),JMP LBL[999] ;
  17:  IF ((F[574] OR F[569]) AND F[562] AND (R[63]=0)),R[179]=(700) ;
  18:  IF (R[179]=700),JMP LBL[999] ;
  19:  IF (!F[19] AND F[571]),R[179]=(200) ;
  20:  JMP LBL[999] ;
  21:  LBL[9000] ;
  22:  IF (R[97]=0),R[97]=(1900) ;
  23:  F[16]=(ON) ;
  24:  R[179]=(900) ;
  25:  LBL[999] ;
/POS
/END
