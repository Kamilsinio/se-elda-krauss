/PROG RG_RELEASE
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  F[41]=(ON) ;
   2:  IF (((R[191] DIV 1) MOD 2)=1),F[657]=(ON) ;
   3:  IF (((R[191] DIV 1) MOD 2)=1),F[658]=(OFF) ;
   4:  IF (((R[191] DIV 1) MOD 2)=1),F[656]=(ON) ;
   5:  IF (((R[191] DIV 2) MOD 2)=1),F[660]=(ON) ;
   6:  IF (((R[191] DIV 2) MOD 2)=1),F[661]=(OFF) ;
   7:  IF (((R[191] DIV 2) MOD 2)=1),F[659]=(ON) ;
   8:  IF (((R[191] DIV 4) MOD 2)=1),F[663]=(ON) ;
   9:  IF (((R[191] DIV 4) MOD 2)=1),F[664]=(OFF) ;
  10:  IF (((R[191] DIV 4) MOD 2)=1),F[662]=(ON) ;
  11:  IF (((R[191] DIV 8) MOD 2)=1),F[666]=(ON) ;
  12:  IF (((R[191] DIV 8) MOD 2)=1),F[667]=(OFF) ;
  13:  IF (((R[191] DIV 8) MOD 2)=1),F[665]=(ON) ;
  14:  IF (((R[191] DIV 16) MOD 2)=1),F[669]=(ON) ;
  15:  IF (((R[191] DIV 16) MOD 2)=1),F[670]=(OFF) ;
  16:  IF (((R[191] DIV 16) MOD 2)=1),F[668]=(ON) ;
/POS
/END
