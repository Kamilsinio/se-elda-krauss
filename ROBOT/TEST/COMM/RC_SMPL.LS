/PROG RC_SMPL
/ATTR
OWNER = MNEDITOR;
COMMENT = "EIP bez ruchu";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  IF (!F[745]),R[143]=(0) ;
   2:  IF ((R[143]=0) AND F[745] AND F[576]),R[144]=(10) ;
   3:  IF ((R[143]=0) AND F[745] AND F[576]),R[143]=(10) ;
   4:  IF ((R[143]=10) AND !F[576]),R[143]=(0) ;
   5:  IF ((R[143]=10) AND F[655] AND (R[103]<>1) AND (R[103]<>2)),R[144]=(904) ;
   6:  IF ((R[143]=10) AND F[655] AND (R[103]=1)),R[145]=(1) ;
   7:  IF ((R[143]=10) AND F[655] AND (R[103]=1)),R[144]=(20) ;
   8:  IF ((R[143]=10) AND F[655] AND (R[103]=1)),R[143]=(20) ;
   9:  IF ((R[143]=10) AND F[655] AND (R[103]=2)),R[145]=(2) ;
  10:  IF ((R[143]=10) AND F[655] AND (R[103]=2)),R[144]=(30) ;
  11:  IF ((R[143]=10) AND F[655] AND (R[103]=2)),R[143]=(20) ;
  12:  F[655]=(OFF) ;
  13:  IF ((R[143]=20) AND !F[576]),R[143]=(0) ;
  14:  F[719]=((R[143]=20) AND F[745]) ;
/POS
/END
