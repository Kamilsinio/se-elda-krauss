/PROG RB_STATUS
/ATTR
OWNER = MNEDITOR;
COMMENT = "Krauss tacki";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  R[142]=($FAST_CLOCK) ;
   2:  F[11]=(F[10] AND F[9]) ;
   3:  F[640]=(F[47] AND F[11]) ;
   4:  F[651]=(F[48] AND F[11]) ;
   5:  F[652]=(F[49] AND F[11]) ;
   6:  F[653]=(F[50] AND F[11]) ;
   7:  F[650]=(F[51] AND F[11]) ;
   8:  F[641]=(F[52] AND F[11]) ;
   9:  F[642]=(F[53] AND F[11]) ;
  10:  F[644]=(F[54] AND F[11]) ;
  11:  F[647]=(F[55] AND F[11]) ;
  12:  F[643]=(F[56] AND F[11]) ;
  13:  R[100]=(0) ;
  14:  IF (F[14] AND F[11] AND (F[57] OR F[58])),R[100]=(2) ;
  15:  F[648]=(F[14] AND F[57] AND !F[58] AND F[11]) ;
  16:  F[642]=(F[642] OR F[16]) ;
  17:  F[46]=(F[14] AND F[47] AND !F[50] AND F[57] AND !F[58]) ;
  18:  F[611]=(F[11] AND (F[56] OR (F[27] AND F[46])) AND !F[16] AND !F[610]) ;
  19:  F[609]=(F[11] AND (F[56] OR (F[28] AND F[46])) AND !F[16] AND !F[608]) ;
  20:  F[613]=(F[11] AND (F[56] OR (F[29] AND F[46])) AND !F[16] AND !F[612]) ;
  21:  IF (F[15] AND F[8] AND !F[3] AND ($FAST_CLOCK-R[146]>R[138])),UALM[1] ;
  22:  IF (F[15] AND F[8] AND !F[3] AND ($FAST_CLOCK-R[129]>R[138])),UALM[1] ;
/POS
/END
