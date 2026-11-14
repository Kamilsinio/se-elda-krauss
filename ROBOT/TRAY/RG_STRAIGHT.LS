/PROG RG_STRAIGHT
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  F[24]=(ON) ;
   2:  F[614]=((((R[177] DIV 1) MOD 2)=1)) ;
   3:  F[615]=((((R[177] DIV 32) MOD 2)=1)) ;
   4:  IF (((((R[177] DIV 1) MOD 2)=1) OR (((R[177] DIV 32) MOD 2)=1)) AND !F[515]),F[24]=(OFF) ;
   5:  IF ((((R[177] DIV 1) MOD 2)=1) AND (!F[510] OR !F[512] OR F[513])),F[24]=(OFF) ;
   6:  IF ((((R[177] DIV 32) MOD 2)=1) AND (!F[511] OR !F[513] OR F[512])),F[24]=(OFF) ;
   7:  F[616]=((((R[177] DIV 2) MOD 2)=1)) ;
   8:  F[617]=((((R[177] DIV 64) MOD 2)=1)) ;
   9:  IF (((((R[177] DIV 2) MOD 2)=1) OR (((R[177] DIV 64) MOD 2)=1)) AND !F[521]),F[24]=(OFF) ;
  10:  IF ((((R[177] DIV 2) MOD 2)=1) AND (!F[516] OR !F[518] OR F[519])),F[24]=(OFF) ;
  11:  IF ((((R[177] DIV 64) MOD 2)=1) AND (!F[517] OR !F[519] OR F[518])),F[24]=(OFF) ;
  12:  F[618]=((((R[177] DIV 4) MOD 2)=1)) ;
  13:  F[619]=((((R[177] DIV 128) MOD 2)=1)) ;
  14:  IF (((((R[177] DIV 4) MOD 2)=1) OR (((R[177] DIV 128) MOD 2)=1)) AND !F[527]),F[24]=(OFF) ;
  15:  IF ((((R[177] DIV 4) MOD 2)=1) AND (!F[522] OR !F[524] OR F[525])),F[24]=(OFF) ;
  16:  IF ((((R[177] DIV 128) MOD 2)=1) AND (!F[523] OR !F[525] OR F[524])),F[24]=(OFF) ;
  17:  F[620]=((((R[177] DIV 8) MOD 2)=1)) ;
  18:  F[621]=((((R[177] DIV 256) MOD 2)=1)) ;
  19:  IF (((((R[177] DIV 8) MOD 2)=1) OR (((R[177] DIV 256) MOD 2)=1)) AND !F[533]),F[24]=(OFF) ;
  20:  IF ((((R[177] DIV 8) MOD 2)=1) AND (!F[528] OR !F[530] OR F[531])),F[24]=(OFF) ;
  21:  IF ((((R[177] DIV 256) MOD 2)=1) AND (!F[529] OR !F[531] OR F[530])),F[24]=(OFF) ;
  22:  F[622]=((((R[177] DIV 16) MOD 2)=1)) ;
  23:  F[623]=((((R[177] DIV 512) MOD 2)=1)) ;
  24:  IF (((((R[177] DIV 16) MOD 2)=1) OR (((R[177] DIV 512) MOD 2)=1)) AND !F[539]),F[24]=(OFF) ;
  25:  IF ((((R[177] DIV 16) MOD 2)=1) AND (!F[534] OR !F[536] OR F[537])),F[24]=(OFF) ;
  26:  IF ((((R[177] DIV 512) MOD 2)=1) AND (!F[535] OR !F[537] OR F[536])),F[24]=(OFF) ;
/POS
/END
