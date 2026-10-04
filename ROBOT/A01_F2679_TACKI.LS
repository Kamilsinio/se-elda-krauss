/PROG  A01_F2679_TACKI
/ATTR
OWNER		= SHIFT;
COMMENT		= "F-2679 TACKI";
PROG_SIZE	= 7334;
CREATE		= DATE 26-07-29  TIME 11:16:38;
MODIFIED	= DATE 26-07-29  TIME 12:56:46;
FILE_NAME	= AA_MAIN_;
VERSION		= 0;
LINE_COUNT	= 370;
MEMORY_SIZE	= 7922;
PROTECT		= READ_WRITE;
TCD:  STACK_SIZE	= 0,
      TASK_PRIORITY	= 50,
      TIME_SLICE	= 0,
      BUSY_LAMP_OFF	= 0,
      ABORT_REQUEST	= 0,
      PAUSE_REQUEST	= 0;
DEFAULT_GROUP	= 1,*,*,*,*;
CONTROL_CODE	= 00000000 00000000;
/APPL
/MN
   1:  !integrated by SkyLogic ;
   2:  !please contact ;
   3:  !k.pelczar@sky-logic.com.pl ;
   4:  !-------------------------------- ;
   5:  !main prod program ;
   6:  !tray production ;
   7:  !-------------------------------- ;
   8:   ;
   9:  !check home pos ;
  10:  IF (!DO[7:in home pos]),JMP LBL[901] ;
  11:   ;
  12:  UTOOL_NUM=3 ;
  13:   ;
  14:  !reset imm permission ;
  15:  DO[104:free operation mode]=OFF ;
  16:  DO[102:enable mould closure]=OFF ;
  17:   ;
  18:  LBL[1:raw start] ;
  19:   ;
  20:  !check plc program ;
  21:  IF (DI[1:box production] OR !DI[2:tray production]),JMP LBL[900] ;
  22:  IF (DO[18:stack finished]),JMP LBL[22] ;
  23:  !reset gripper signals ;
  24:  CALL BB_GRIPPER_RESET    ;
  25:   ;
  26:  !reset imm signals ;
  27:  CALL BB_IMM_RESET    ;
  28:   ;
  29:  !init ;
  30:  UFRAME_NUM=0 ;
  31:  UTOOL_NUM=3 ;
  32:   ;
  33:  !start pos ;
  34:J P[1:home] 100% FINE    ;
  35:   ;
  36:  !check whether to continiue cycle ;
  37:  LBL[2:start] ;
  38:   ;
  39:  IF (DI[3:cmd continiue job] OR DI[101:reject]),JMP LBL[3] ;
  40:  JMP LBL[4] ;
  41:  LBL[3:continiue] ;
  42:  DO[21:ack cmd continiue]=ON ;
  43:  WAIT (!DI[3:cmd continiue job])    ;
  44:  DO[21:ack cmd continiue]=OFF ;
  45:  JMP LBL[20] ;
  46:   ;
  47:  LBL[4:new prod] ;
  48:   ;
  49:  !start new prod ;
  50:  !pallet params ;
  51:  R[8:pallet height]=40    ;
  52:  R[9:pallet num]=0    ;
  53:  R[10:product num]=0    ;
  54:  R[15:x-quantity]=2    ;
  55:  R[16:y-quantity]=2    ;
  56:  R[17:z-quantity]=9    ;
  57:  R[14:layer-quantity]=R[15:x-quantity]*R[16:y-quantity]    ;
  58:  R[18:pallets in stack]=R[17:z-quantity]    ;
  59:   ;
  60:  !permit for 1st imm cycle ;
  61:  DO[101:mould area free]=ON ;
  62:  DO[102:enable mould closure]=ON ;
  63:  DO[103:enable full mould openig]=OFF ;
  64:  DO[104:free operation mode]=OFF ;
  65:  DO[105:enable ejector back]=ON ;
  66:  DO[106:enable ejector forward]=OFF ;
  67:  !can optimize with run ;
  68:  WAIT (DI[102:mould closed] AND !DI[103:mould open])    ;
  69:   ;
  70:  LBL[10:1st pallet] ;
  71:  !pick up 1st pallet ;
  72:  R[9:pallet num]=0    ;
  73:   ;
  74:  UFRAME_NUM=0 ;
  75:  UTOOL_NUM=3 ;
  76:   ;
  77:  LBL[50:not 1st pallet] ;
  78:J P[2:elevator] 100% CNT50    ;
  79:   ;
  80:  !bend gripper arm ;
  81:  DO[119:axis-7 straight]=OFF ;
  82:  DO[120:axis-7 bend]=ON ;
  83:  WAIT (RI[5:axis-7 bend] AND !RI[6:axis-7 straight])    ;
  84:   ;
  85:  !wait for permission ;
  86:  WAIT DI[4:pallet ready]=ON TIMEOUT,LBL[901] ;
  87:  DO[14:cmd ack]=PULSE,2.0sec ;
  88:   ;
  89:J P[3:above stack] 100% CNT0    ;
  90:   ;
  91:L P[4:above 1st pallet] 1000mm/sec CNT0    ;
  92:  IF R[9:pallet num]<>0,JMP LBL[16] ;
  93:   ;
  94:  PR[1:pallet pos]=LPOS    ;
  95:   ;
  96:  !pickup from started stack ;
  97:  LBL[16:1st try] ;
  98:  R[1:attemps counter]=0    ;
  99:   ;
 100:  LBL[11:pallet pickup] ;
 101:  R[1:attemps counter]=R[1:attemps counter]+1    ;
 102:  IF R[1:attemps counter]>R[2:num of attempts],JMP LBL[902] ;
 103:   ;
 104:  !check if vac5 locked ;
 105:  IF (DI[32:vacuum 5 ok]),CALL BB_RESET_VAC5 ;
 106:  IF (DI[32:vacuum 5 ok]),JMP LBL[901] ;
 107:   ;
 108:  SKIP CONDITION DI[32:vacuum 5 ok]=ON    ;
 109:   ;
 110:  DO[31:vacuum 5]=ON ;
 111:  DO[32:blow-off 5]=OFF ;
 112:   ;
 113:  LBL[14:go for pallet] ;
 114:L PR[1:pallet pos] 150mm/sec CNT0 Skip,LBL[13]    ;
 115:   ;
 116:  JMP LBL[12] ;
 117:   ;
 118:  LBL[13:pallet not found] ;
 119:  PR[1,3:pallet pos]=PR[1,3:pallet pos]-R[8:pallet height]    ;
 120:  JMP LBL[14] ;
 121:   ;
 122:   ;
 123:  LBL[12:pallet found] ;
 124:  PR[1:pallet pos]=LPOS    ;
 125:   ;
 126:  ! pickup pallet from stack ;
 127:  SKIP CONDITION DI[32:vacuum 5 ok]=OFF    ;
 128:   ;
 129:L PR[1:pallet pos] 200mm/sec CNT100 Offset,PR[54:z 50] Skip,LBL[15]    ;
 130:  JMP LBL[11] ;
 131:   ;
 132:  LBL[15:pickup completed] ;
 133:L P[4:above 1st pallet] 500mm/sec CNT100    ;
 134:   ;
 135:J P[3:above stack] 100% CNT100    ;
 136:   ;
 137:  DO[120:axis-7 bend]=ON ;
 138:  DO[119:axis-7 straight]=OFF ;
 139:   ;
 140:J P[8:guide pal place] 100% CNT100    ;
 141:   ;
 142:  WAIT (DI[5:elevator ready]) TIMEOUT,LBL[903] ;
 143:   ;
 144:J P[10:place pallet] 100% CNT0 Offset,PR[52:z 100 y -5]    ;
 145:   ;
 146:L P[10:place pallet] 200mm/sec FINE Offset,PR[53:z 17]    ;
 147:   ;
 148:  DO[31:vacuum 5]=OFF ;
 149:  DO[32:blow-off 5]=PULSE,2.0sec ;
 150:   ;
 151:  WAIT (!DI[32:vacuum 5 ok]) TIMEOUT,LBL[901] ;
 152:  DO[15:pallet placed]=PULSE,2.0sec ;
 153:  DO[15:pallet placed]=OFF ;
 154:   ;
 155:L P[10:place pallet] 500mm/sec CNT100 Offset,PR[51:z 200]    ;
 156:   ;
 157:J P[8:guide pal place] 100% CNT100    ;
 158:   ;
 159:J P[12:elevator] 100% CNT100    ;
 160:   ;
 161:   ;
 162:  !-------------------------------- ;
 163:  !main program loop ;
 164:  LBL[20:loop] ;
 165:   ;
 166:  !move to imm ;
 167:   ;
 168:J P[13:elev to imm 1] 100% CNT100    ;
 169:  DO[119:axis-7 straight]=ON ;
 170:  DO[120:axis-7 bend]=OFF ;
 171:   ;
 172:   ;
 173:  DO[111:gripper act 1 bwd]=ON ;
 174:  DO[112:gripper act 1 fwd]=OFF ;
 175:   ;
 176:   ;
 177:L P[6] 1000mm/sec CNT100 ACC50    ;
 178:   ;
 179:   ;
 180:  WAIT (RI[6:axis-7 straight] AND !RI[5:axis-7 bend]) TIMEOUT,LBL[901] ;
 181:   ;
 182:  !open imm ;
 183:   ;
 184:  DO[102:enable mould closure]=OFF ;
 185:  DO[103:enable full mould openig]=ON ;
 186:   ;
 187:L P[15:imm wait pos] 1000mm/sec CNT15    ;
 188:   ;
 189:  WAIT (DI[103:mould open] AND !DI[102:mould closed]) TIMEOUT,LBL[901] ;
 190:   ;
 191:L P[16:mould] 2000mm/sec CNT0    ;
 192:   ;
 193:  RO[1:vacuum 1]=ON ;
 194:  RO[2:blow-off 1]=OFF ;
 195:  RO[3:vacuum 2]=ON ;
 196:  RO[4:blow-off 2]=OFF ;
 197:  RO[5:vacuum 3]=ON ;
 198:  RO[6:blow-off 3]=OFF ;
 199:  RO[7:vacuum 4]=ON ;
 200:  RO[8:blow-off 4]=OFF ;
 201:   ;
 202:L P[17:product pickup] 100mm/sec FINE    ;
 203:   ;
 204:   ;
 205:  DO[105:enable ejector back]=OFF ;
 206:  DO[106:enable ejector forward]=ON ;
 207:   ;
 208:  WAIT    .50(sec) ;
 209:   ;
 210:  //WAIT (!DI[106:ejector in back pos] AND DI[107:ejector in forward pos]) TIMEOUT,LBL[901] ;
 211:   ;
 212:  //WAIT (RI[1:vacuum 1 ok] AND RI[2:vacuum 2 ok] AND RI[3:vacuum 3 ok] AND RI[4:vacuum 4 ok]) TIMEOUT,LBL[901] ;
 213:   ;
 214:L P[16:mould] 300mm/sec FINE    ;
 215:   ;
 216:  F[1:carrying product]=(ON) ;
 217:   ;
 218:  DO[106:enable ejector forward]=OFF ;
 219:  DO[105:enable ejector back]=ON ;
 220:   ;
 221:   ;
 222:L P[19:imm wait pos] 2000mm/sec FINE ACC50    ;
 223:   ;
 224:  DO[105:enable ejector back]=ON ;
 225:  DO[106:enable ejector forward]=ON ;
 226:   ;
 227:   ;
 228:L P[6] 1000mm/sec CNT0 ACC50    ;
 229:  WAIT    .50(sec) ;
 230:   ;
 231:   ;
 232:  DO[102:enable mould closure]=ON ;
 233:  DO[103:enable full mould openig]=OFF ;
 234:  DO[105:enable ejector back]=OFF ;
 235:  DO[106:enable ejector forward]=OFF ;
 236:  IF (DI[6:cmd samples]),JMP LBL[30] ;
 237:   ;
 238:  !go to pallet ;
 239:   ;
 240:  DO[119:axis-7 straight]=OFF ;
 241:  DO[120:axis-7 bend]=ON ;
 242:   ;
 243:L P[20:elev to imm 1] 2000mm/sec CNT100    ;
 244:   ;
 245:J P[21:elevator] 100% CNT100    ;
 246:   ;
 247:   ;
 248:  DO[111:gripper act 1 bwd]=OFF ;
 249:  DO[112:gripper act 1 fwd]=ON ;
 250:   ;
 251:  WAIT (!RI[6:axis-7 straight] AND RI[5:axis-7 bend])    ;
 252:   ;
 253:  WAIT (!DI[103:mould open] AND DI[102:mould closed])    ;
 254:   ;
 255:J P[22:guide prod place] 100% CNT0    ;
 256:   ;
 257:  WAIT (DI[5:elevator ready]) TIMEOUT,LBL[901] ;
 258:   ;
 259:  !calc place position ;
 260:  R[12:column num (y)]=R[10:product num] MOD R[15:x-quantity]    ;
 261:  R[11:row num (x)]=R[10:product num] DIV R[15:x-quantity]    ;
 262:  PR[2:product offset]=LPOS-LPOS    ;
 263:  PR[2,1:product offset]=R[11:row num (x)]*R[19:distance x]    ;
 264:  PR[2,2:product offset]=R[12:column num (y)]*R[20:distance y]    ;
 265:  PR[2,3:product offset]=50    ;
 266:   ;
 267:L P[23:product place] 1000mm/sec CNT0 Offset,PR[2:product offset]    ;
 268:  PR[2,3:product offset]=0    ;
 269:   ;
 270:L P[23:product place] 1000mm/sec CNT0 Offset,PR[2:product offset]    ;
 271:   ;
 272:  RO[1:vacuum 1]=OFF ;
 273:  RO[2:blow-off 1]=PULSE,1.0sec ;
 274:  RO[3:vacuum 2]=OFF ;
 275:  RO[4:blow-off 2]=PULSE,1.0sec ;
 276:  RO[5:vacuum 3]=OFF ;
 277:  RO[6:blow-off 3]=PULSE,1.0sec ;
 278:  RO[7:vacuum 4]=OFF ;
 279:  RO[8:blow-off 4]=PULSE,1.0sec ;
 280:   ;
 281:  WAIT   1.00(sec) ;
 282:   ;
 283:  WAIT (!RI[1:vacuum 1 ok] AND !RI[2:vacuum 2 ok] AND !RI[3:vacuum 3 ok] AND !RI[4:vacuum 4 ok])    ;
 284:   ;
 285:  R[10:product num]=R[10:product num]+1    ;
 286:   ;
 287:J P[22:guide prod place] 100% CNT100    ;
 288:   ;
 289:J P[21:elevator] 100% CNT100    ;
 290:   ;
 291:  DO[112:gripper act 1 fwd]=OFF ;
 292:  DO[111:gripper act 1 bwd]=ON ;
 293:   ;
 294:  F[1:carrying product]=(OFF) ;
 295:   ;
 296:  IF (R[10:product num]=R[14:layer-quantity]),DO[17:pallet finished]=PULSE   ;
 297:  IF (R[10:product num]=R[14:layer-quantity]),JMP LBL[21] ;
 298:   ;
 299:  !go back to main loop ;
 300:  JMP LBL[20] ;
 301:   ;
 302:  LBL[21:pallet full] ;
 303:  R[10:product num]=0    ;
 304:  R[9:pallet num]=R[9:pallet num]+1    ;
 305:  IF (R[9:pallet num]=R[18:pallets in stack]),JMP LBL[22] ;
 306:  JMP LBL[50] ;
 307:  LBL[22] ;
 308:  DO[18:stack finished]=ON ;
 309:  WAIT (DI[8:ack stack finished])    ;
 310:  DO[18:stack finished]=OFF ;
 311:  WAIT (!DI[8:ack stack finished])    ;
 312:   ;
 313:  JMP LBL[10] ;
 314:  LBL[30:samples] ;
 315:  DO[14:cmd ack]=PULSE,2.0sec ;
 316:  !go from elev to sampl ;
 317:   ;
 318:L P[27:imm to samples1] 1000mm/sec CNT100    ;
 319:   ;
 320:J P[28:elev to samples2] 100% CNT100    ;
 321:   ;
 322:J P[5] 100% CNT100    ;
 323:   ;
 324:J P[29:guide place samp] 100% CNT0    ;
 325:   ;
 326:  DO[119:axis-7 straight]=OFF ;
 327:  DO[120:axis-7 bend]=ON ;
 328:   ;
 329:  WAIT (RI[5:axis-7 bend] AND !RI[6:axis-7 straight])    ;
 330:   ;
 331:J P[30:samples] 50% FINE    ;
 332:   ;
 333:  RO[1:vacuum 1]=OFF ;
 334:  RO[2:blow-off 1]=PULSE,1.0sec ;
 335:  RO[3:vacuum 2]=OFF ;
 336:  RO[4:blow-off 2]=PULSE,1.0sec ;
 337:  RO[5:vacuum 3]=OFF ;
 338:  RO[6:blow-off 3]=PULSE,1.0sec ;
 339:  RO[7:vacuum 4]=OFF ;
 340:  RO[8:blow-off 4]=PULSE,1.0sec ;
 341:   ;
 342:  WAIT (!RI[1:vacuum 1 ok] AND !RI[2:vacuum 2 ok] AND !RI[3:vacuum 3 ok] AND !RI[4:vacuum 4 ok])    ;
 343:   ;
 344:  DO[16:samples placed]=PULSE,2.0sec ;
 345:   ;
 346:J P[29:guide place samp] 100% CNT50    ;
 347:   ;
 348:  DO[120:axis-7 bend]=OFF ;
 349:  DO[119:axis-7 straight]=ON ;
 350:   ;
 351:  WAIT (RI[6:axis-7 straight] AND !RI[5:axis-7 bend])    ;
 352:   ;
 353:J P[5] 100% CNT100    ;
 354:   ;
 355:J P[28:elev to samples2] 100% CNT100    ;
 356:   ;
 357:  !go back to main loop ;
 358:  JMP LBL[20] ;
 359:  !-------------------------------- ;
 360:   ;
 361:  LBL[903:elevator not rdy] ;
 362:  UALM[3] ;
 363:   ;
 364:  LBL[902:failed to pickup] ;
 365:  UALM[2] ;
 366:   ;
 367:  LBL[901:fault] ;
 368:  UALM[1] ;
 369:   ;
 370:  LBL[900:end] ;
/POS
P[1:"home"]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=   -35.000 deg,	J3=     -.000 deg,
	J4=      .000 deg,	J5=   -90.000 deg,	J6=   -20.000 deg
};
P[2:"elevator"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   749.074  mm,	Y =   -16.800  mm,	Z =   978.329  mm,
	W =   180.000 deg,	P =     -.000 deg,	R =     -.000 deg
};
P[3:"above stack"]{
   GP1:
	UF : 0, UT : 3,	
	J1=     1.832 deg,	J2=    49.642 deg,	J3=     1.187 deg,
	J4=   107.315 deg,	J5=    -5.651 deg,	J6=    52.227 deg
};
P[4:"above 1st pallet"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =  1680.502  mm,	Y =    44.350  mm,	Z =   652.539  mm,
	W =    12.760 deg,	P =    87.066 deg,	R =     9.208 deg
};
P[5]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   -16.765  mm,	Y =  -476.579  mm,	Z =   903.971  mm,
	W =  -179.845 deg,	P =     2.225 deg,	R =   -90.450 deg
};
P[6]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, -1',
	X =   317.196  mm,	Y =   422.339  mm,	Z =   582.798  mm,
	W =   139.294 deg,	P =     -.682 deg,	R =   179.263 deg
};
P[8:"guide pal place"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   910.752  mm,	Y =    24.470  mm,	Z =   796.363  mm,
	W =    12.702 deg,	P =    87.074 deg,	R =     9.151 deg
};
P[10:"place pallet"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   898.140  mm,	Y =    25.210  mm,	Z =   329.010  mm,
	W =   -38.410 deg,	P =    87.725 deg,	R =   -42.724 deg
};
P[12:"elevator"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   820.445  mm,	Y =   141.000  mm,	Z =  1067.487  mm,
	W =  -180.000 deg,	P =      .000 deg,	R =     -.000 deg
};
P[13:"elev to imm 1"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, -1',
	X =   324.513  mm,	Y =   434.658  mm,	Z =  1053.546  mm,
	W =  -179.867 deg,	P =     -.480 deg,	R =   179.669 deg
};
P[15:"imm wait pos"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   308.313  mm,	Y =   407.382  mm,	Z =    11.278  mm,
	W =    89.706 deg,	P =    -1.369 deg,	R =   179.502 deg
};
P[16:"mould"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   308.313  mm,	Y =   894.700  mm,	Z =    11.278  mm,
	W =    89.706 deg,	P =    -1.368 deg,	R =   179.502 deg
};
P[17:"product pickup"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   343.024  mm,	Y =   895.817  mm,	Z =    21.258  mm,
	W =    90.273 deg,	P =    -1.127 deg,	R =   179.095 deg
};
P[19:"imm wait pos"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   308.313  mm,	Y =   407.382  mm,	Z =    11.278  mm,
	W =    89.706 deg,	P =    -1.369 deg,	R =   179.502 deg
};
P[20:"elev to imm 1"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, -1',
	X =   324.513  mm,	Y =   434.658  mm,	Z =  1053.546  mm,
	W =  -179.867 deg,	P =     -.480 deg,	R =   179.669 deg
};
P[21:"elevator"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   633.111  mm,	Y =    99.040  mm,	Z =   846.897  mm,
	W =  -179.970 deg,	P =      .290 deg,	R =   -89.656 deg
};
P[22:"guide prod place"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =  1269.109  mm,	Y =    99.040  mm,	Z =   884.097  mm,
	W =  -179.970 deg,	P =      .290 deg,	R =   -89.656 deg
};
P[23:"product place"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =  1249.881  mm,	Y =    56.181  mm,	Z =   423.459  mm,
	W =   179.364 deg,	P =     1.256 deg,	R =   -89.311 deg
};
P[27:"imm to samples1"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, -1',
	X =   342.495  mm,	Y =   496.659  mm,	Z =   806.832  mm,
	W =  -178.168 deg,	P =    -1.096 deg,	R =  -179.678 deg
};
P[28:"elev to samples2"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   589.656  mm,	Y =  -212.519  mm,	Z =   903.971  mm,
	W =  -179.845 deg,	P =     2.225 deg,	R =   -90.450 deg
};
P[29:"guide place samp"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =  -448.513  mm,	Y =  -276.479  mm,	Z =   677.966  mm,
	W =   179.899 deg,	P =     1.723 deg,	R =   -89.821 deg
};
P[30:"samples"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =  -473.713  mm,	Y =  -747.120  mm,	Z =   543.327  mm,
	W =   179.994 deg,	P =    29.201 deg,	R =   -89.795 deg
};
/END
