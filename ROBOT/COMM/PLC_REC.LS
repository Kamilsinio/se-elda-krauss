/PROG PLC_REC
/ATTR
OWNER = MNEDITOR;
COMMENT = "Recovery lacza";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  ! Jawne recovery lacza ;
   2:  ! Robot zada - PLC wykonuje ;
   3:  ! Festo i EUROMAP ;
   4:  ! R[126] - Stan: 0 rozbrojone, ;
   5:  ! 10 zadanie SYNC, 20 wygaszanie ;
   6:  ! ACK, 30 ;
   7:  ! recovery, 40 po jawnym ;
   8:  ! recovery, gotowosc sesji. ;
   9:  IF (R[126:StanLacza]<>30),JMP LBL[90] ;
  10:  ! F[751] - Zatrzasniety blad ;
  11:  ! protokolu, OFF brak takiego ;
  12:  ! bledu. ON opisany ;
  13:  ! warunek/zadanie, OFF brak. ;
  14:  F[751:BladProto]=(OFF) ;
  15:  ! F[740] - Jednorazowe zadanie ;
  16:  ! jawnego recovery lacza, ;
  17:  ! konsumowane przez ;
  18:  ! PLC_LINK. ON opisany ;
  19:  ! warunek/zadanie, OFF brak. ;
  20:  F[740:ZadRecLacza]=(ON) ;
  21:  LBL[90] ;
/POS
/END
