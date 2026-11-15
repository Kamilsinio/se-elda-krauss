/PROG BG_BIND
/ATTR
OWNER = MNEDITOR;
COMMENT = "Zrodla native";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  ! Komplet zrodel native ;
   2:  ! Robot zada - PLC wykonuje ;
   3:  ! Festo i EUROMAP ;
   4:  ! F[401] - BG_BIND ma ;
   5:  ! zdefiniowane wszystkie 14 ;
   6:  ! natywnych zrodel, nie dowod ;
   7:  ! odbioru. ON tak/zadanie, OFF ;
   8:  ! nie. ;
   9:  F[401:NativeKompl]=(OFF) ;
/POS
/END
