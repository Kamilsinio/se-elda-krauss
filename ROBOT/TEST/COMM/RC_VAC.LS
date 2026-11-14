/PROG RC_VAC
/ATTR
OWNER = MNEDITOR;
COMMENT = "EIP bez ruchu";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  F[721]=(F[657] AND F[752]) ;
   2:  F[722]=(F[658] AND F[752]) ;
   3:  F[724]=(F[660] AND F[752]) ;
   4:  F[725]=(F[661] AND F[752]) ;
   5:  F[727]=(F[663] AND F[752]) ;
   6:  F[728]=(F[664] AND F[752]) ;
   7:  F[730]=(F[666] AND F[752]) ;
   8:  F[731]=(F[667] AND F[752]) ;
   9:  F[733]=(F[669] AND F[752]) ;
  10:  F[734]=(F[670] AND F[752]) ;
/POS
/END
