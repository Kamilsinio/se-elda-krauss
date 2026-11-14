/PROG RG_VACON
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  F[25]=(ON) ;
   2:  IF (((R[191] DIV 1) MOD 2)=1),F[657]=(ON) ;
   3:  IF (((R[191] DIV 1) MOD 2)=1),F[658]=(ON) ;
   4:  IF ((((R[191] DIV 1) MOD 2)=1) AND (!F[582] OR !F[577] OR !F[580] OR !F[581])),F[25]=(OFF) ;
   5:  IF (((R[191] DIV 2) MOD 2)=1),F[660]=(ON) ;
   6:  IF (((R[191] DIV 2) MOD 2)=1),F[661]=(ON) ;
   7:  IF ((((R[191] DIV 2) MOD 2)=1) AND (!F[588] OR !F[583] OR !F[586] OR !F[587])),F[25]=(OFF) ;
   8:  IF (((R[191] DIV 4) MOD 2)=1),F[663]=(ON) ;
   9:  IF (((R[191] DIV 4) MOD 2)=1),F[664]=(ON) ;
  10:  IF ((((R[191] DIV 4) MOD 2)=1) AND (!F[594] OR !F[589] OR !F[592] OR !F[593])),F[25]=(OFF) ;
  11:  IF (((R[191] DIV 8) MOD 2)=1),F[666]=(ON) ;
  12:  IF (((R[191] DIV 8) MOD 2)=1),F[667]=(ON) ;
  13:  IF ((((R[191] DIV 8) MOD 2)=1) AND (!F[600] OR !F[595] OR !F[598] OR !F[599])),F[25]=(OFF) ;
  14:  IF (((R[191] DIV 16) MOD 2)=1),F[669]=(ON) ;
  15:  IF (((R[191] DIV 16) MOD 2)=1),F[670]=(ON) ;
  16:  IF ((((R[191] DIV 16) MOD 2)=1) AND (!F[606] OR !F[601] OR !F[604] OR !F[605])),F[25]=(OFF) ;
/POS
/END
