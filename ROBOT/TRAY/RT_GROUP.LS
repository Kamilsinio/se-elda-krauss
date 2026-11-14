/PROG RT_GROUP
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  R[191]=(0) ;
   2:  R[192]=(0) ;
   3:  IF (R[186]=1),R[191]=(R[27]) ;
   4:  IF (R[186]=1),R[192]=(R[32]) ;
   5:  IF (R[186]=2),R[191]=(R[28]) ;
   6:  IF (R[186]=2),R[192]=(R[33]) ;
   7:  IF (R[186]=3),R[191]=(R[29]) ;
   8:  IF (R[186]=3),R[192]=(R[34]) ;
   9:  IF (R[186]=4),R[191]=(R[30]) ;
  10:  IF (R[186]=4),R[192]=(R[35]) ;
  11:  IF (R[186]=5),R[191]=(R[31]) ;
  12:  IF (R[186]=5),R[192]=(R[36]) ;
/POS
/END
