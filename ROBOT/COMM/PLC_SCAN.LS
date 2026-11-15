/PROG PLC_SCAN
/ATTR
OWNER = MNEDITOR;
COMMENT = "Cykl komunikacji";
PROTECT = READ_WRITE;
DEFAULT_GROUP = *,*,*,*,*;
CONTROL_CODE = 00000000 00000000;
/MN
   1:  ! Jeden cykl komunikacji ;
   2:  ! Robot zada - PLC wykonuje ;
   3:  ! Festo i EUROMAP ;
   4:  CALL PLC_RX ;
   5:  CALL PLC_LINK ;
   6:  CALL PLC_CMD ;
   7:  ! F[751] - Zatrzasniety blad ;
   8:  ! protokolu, OFF brak takiego ;
   9:  ! bledu. ON opisany ;
  10:  ! warunek/zadanie, OFF brak. ;
  11:  ! R[126] - Stan: 0 rozbrojone, ;
  12:  ! 10 zadanie SYNC, 20 wygaszanie ;
  13:  ! ACK, 30 ;
  14:  ! recovery, 40 po jawnym ;
  15:  ! recovery, gotowosc sesji. ;
  16:  IF (F[751:BladProto] AND (R[126:StanLacza]=40)),CALL PLC_LOST ;
  17:  IF (F[751:BladProto]),CALL PLC_CMD ;
  18:  CALL PLC_TX ;
  19:  ! R[127] - Licznik cykli ;
  20:  ! PLC_SCAN do wykrycia ;
  21:  ! zatrzymania PLC_SVC. ;
  22:  R[127:CyklSerwisu]=((R[127:CyklSerwisu]+1) MOD 65536) ;
/POS
/END
