/PROG  AAAA_MAIN_BOX_PRG
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "main box prod";
PROG_SIZE	= 10087;
CREATE		= DATE 26-07-19  TIME 12:00:00;
MODIFIED	= DATE 26-07-27  TIME 20:38:42;
FILE_NAME	= AAAA_BOX;
VERSION		= 0;
LINE_COUNT	= 811;
MEMORY_SIZE	= 10779;
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
   6:  !box production ;
   7:  !-------------------------------- ;
   8:   ;
   9:  !check home pos ;
  10:  IF (!DO[7:in home pos]),JMP LBL[901] ;
  11:   ;
  12:  UTOOL_NUM=3 ;
  13:   ;
  14:  !imm init - free operation ;
  15:   ;
  16:J P[1:home] 5% FINE    ;
  17:   ;
  18:  CALL BB_IMM_RESET    ;
  19:  DO[104:free operation mode]=ON ;
  20:  DO[102:enable mould closure]=ON ;
  21:   ;
  22:  PAUSE ;
  23:   ;
  24:  !reset imm permission ;
  25:  DO[104:free operation mode]=OFF ;
  26:  DO[102:enable mould closure]=OFF ;
  27:  DO[22:storage access req]=OFF ;
  28:  DO[17:layer finished]=OFF ;
  29:  DO[18:stack finished]=OFF ;
  30:  DO[23:box progress]=OFF ;
  31:   ;
  32:  LBL[1:raw start] ;
  33:   ;
  34:  !check plc program ;
  35:  IF (!DI[1:box production] OR DI[2:tray production]),JMP LBL[900] ;
  36:   ;
  37:  !reset imm signals ;
  38:  CALL BB_IMM_RESET    ;
  39:   ;
  40:  !init ;
  41:  UFRAME_NUM=0 ;
  42:  UTOOL_NUM=3 ;
  43:   ;
  44:  !start pos ;
  45:J P[1:home] 100% FINE    ;
  46:   ;
  47:  !check whether to continiue cycle ;
  48:  LBL[2:start] ;
  49:   ;
  50:  IF (DI[3:cmd continiue job] OR DI[101:reject]),JMP LBL[3] ;
  51:  JMP LBL[4] ;
  52:  LBL[3:continiue] ;
  53:  DO[21:ack cmd continiue]=ON ;
  54:  WAIT (!DI[3:cmd continiue job])    ;
  55:  DO[21:ack cmd continiue]=OFF ;
  56:  IF R[43:box z qty]<=0,JMP LBL[4] ;
  57:  IF (R[43:box z qty]>1 AND R[44:box dist z]<=0),JMP LBL[4] ;
  58:  IF (R[43:box z qty]>1 AND R[45:spacer search st]<=0),JMP LBL[4] ;
  59:  IF (R[43:box z qty]>1 AND R[46:spacer max attem]<=0),JMP LBL[4] ;
  60:  IF R[47:box layer index]<0,JMP LBL[4] ;
  61:  IF R[47:box layer index]>=R[43:box z qty],JMP LBL[4] ;
  62:  IF R[48:box active palle]<1,JMP LBL[4] ;
  63:  IF R[48:box active palle]>3,JMP LBL[4] ;
  64:  IF R[52:box active x qty]<=0,JMP LBL[4] ;
  65:  IF R[53:box active y qty]<=0,JMP LBL[4] ;
  66:  IF R[56:box product limi]<=0,JMP LBL[4] ;
  67:  IF R[49:box product inde]<0,JMP LBL[4] ;
  68:  IF R[49:box product inde]>R[56:box product limi],JMP LBL[4] ;
  69:  IF R[59:box resume phase]=1,JMP LBL[5] ;
  70:  IF R[59:box resume phase]=2,JMP LBL[6] ;
  71:  IF R[59:box resume phase]<>0,JMP LBL[4] ;
  72:  IF R[49:box product inde]>=R[56:box product limi],JMP LBL[4] ;
  73:  R[58:box next gripper]=1    ;
  74:  CALL BB_GRIPPER_RESET    ;
  75:  F[1:carrying product]=(OFF) ;
  76:  JMP LBL[20] ;
  77:   ;
  78:  LBL[5:resume box place] ;
  79:  IF R[58:box next gripper]<1,JMP LBL[4] ;
  80:  IF R[58:box next gripper]>5,JMP LBL[4] ;
  81:  IF R[58:box next gripper]=1,JMP LBL[7] ;
  82:  IF R[58:box next gripper]=2,JMP LBL[8] ;
  83:  IF R[58:box next gripper]=3,JMP LBL[9] ;
  84:  IF R[58:box next gripper]=4,JMP LBL[10] ;
  85:  IF R[58:box next gripper]=5,JMP LBL[11] ;
  86:  JMP LBL[901] ;
  87:  LBL[7:check gripper 1] ;
  88:  IF (!RI[1:vacuum 1 ok]),JMP LBL[901] ;
  89:  IF (!RI[2:vacuum 2 ok]),JMP LBL[901] ;
  90:  IF (!RI[3:vacuum 3 ok]),JMP LBL[901] ;
  91:  IF (!RI[4:vacuum 4 ok]),JMP LBL[901] ;
  92:  JMP LBL[12] ;
  93:  LBL[8:check gripper 2] ;
  94:  IF (RI[1:vacuum 1 ok]),JMP LBL[901] ;
  95:  IF (!RI[2:vacuum 2 ok]),JMP LBL[901] ;
  96:  IF (!RI[3:vacuum 3 ok]),JMP LBL[901] ;
  97:  IF (!RI[4:vacuum 4 ok]),JMP LBL[901] ;
  98:  JMP LBL[12] ;
  99:  LBL[9:check gripper 3] ;
 100:  IF (RI[1:vacuum 1 ok]),JMP LBL[901] ;
 101:  IF (RI[2:vacuum 2 ok]),JMP LBL[901] ;
 102:  IF (!RI[3:vacuum 3 ok]),JMP LBL[901] ;
 103:  IF (!RI[4:vacuum 4 ok]),JMP LBL[901] ;
 104:  JMP LBL[12] ;
 105:  LBL[10:check grip 4] ;
 106:  IF (RI[1:vacuum 1 ok]),JMP LBL[901] ;
 107:  IF (RI[2:vacuum 2 ok]),JMP LBL[901] ;
 108:  IF (RI[3:vacuum 3 ok]),JMP LBL[901] ;
 109:  IF (!RI[4:vacuum 4 ok]),JMP LBL[901] ;
 110:  JMP LBL[12] ;
 111:  LBL[11:check clear] ;
 112:  IF (RI[1:vacuum 1 ok]),JMP LBL[901] ;
 113:  IF (RI[2:vacuum 2 ok]),JMP LBL[901] ;
 114:  IF (RI[3:vacuum 3 ok]),JMP LBL[901] ;
 115:  IF (RI[4:vacuum 4 ok]),JMP LBL[901] ;
 116:  LBL[12:resume valid] ;
 117:  DO[112:gripper act 1 fwd]=OFF ;
 118:  DO[111:gripper act 1 bwd]=ON ;
 119:  DO[114:gripper act 2 fwd]=OFF ;
 120:  DO[113:gripper act 2 bwd]=ON ;
 121:  DO[115:gripper act 3 fwd]=OFF ;
 122:  DO[116:gripper act 3 bwd]=ON ;
 123:  DO[117:gripper act 4 fwd]=OFF ;
 124:  DO[118:gripper act 4 bwd]=ON ;
 125:  WAIT (!DI[112:act 1 in fwd pos] AND DI[113:act 1 in bwd pos]) TIMEOUT,LBL[901] ;
 126:  WAIT (!DI[114:act 2 in fwd pos] AND DI[115:act 2 in bwd pos]) TIMEOUT,LBL[901] ;
 127:  WAIT (!DI[116:act 3 in fwd pos] AND DI[117:act 3 in bwd pos]) TIMEOUT,LBL[901] ;
 128:  WAIT (!DI[118:act 4 in fwd pos] AND DI[119:act 4 in bwd pos]) TIMEOUT,LBL[901] ;
 129:  DO[119:axis-7 straight]=OFF ;
 130:  DO[120:axis-7 bend]=ON ;
 131:  WAIT (RI[5:axis-7 bend] AND !RI[6:axis-7 straight]) TIMEOUT,LBL[901] ;
 132:J P[2:elevator] 100% CNT100    ;
 133:J P[21:elevator] 100% CNT100    ;
 134:  WAIT (DI[5:elevator ready]) TIMEOUT,LBL[903] ;
 135:  DO[14:cmd ack]=PULSE,2.0sec ;
 136:J P[22:guide prod place] 100% CNT0    ;
 137:  JMP LBL[80] ;
 138:   ;
 139:  LBL[6:resume samples] ;
 140:  IF (!RI[1:vacuum 1 ok]),JMP LBL[901] ;
 141:  IF (!RI[2:vacuum 2 ok]),JMP LBL[901] ;
 142:  IF (!RI[3:vacuum 3 ok]),JMP LBL[901] ;
 143:  IF (!RI[4:vacuum 4 ok]),JMP LBL[901] ;
 144:  DO[112:gripper act 1 fwd]=OFF ;
 145:  DO[111:gripper act 1 bwd]=ON ;
 146:  DO[114:gripper act 2 fwd]=OFF ;
 147:  DO[113:gripper act 2 bwd]=ON ;
 148:  DO[115:gripper act 3 fwd]=OFF ;
 149:  DO[116:gripper act 3 bwd]=ON ;
 150:  DO[117:gripper act 4 fwd]=OFF ;
 151:  DO[118:gripper act 4 bwd]=ON ;
 152:  WAIT (!DI[112:act 1 in fwd pos] AND DI[113:act 1 in bwd pos]) TIMEOUT,LBL[901] ;
 153:  WAIT (!DI[114:act 2 in fwd pos] AND DI[115:act 2 in bwd pos]) TIMEOUT,LBL[901] ;
 154:  WAIT (!DI[116:act 3 in fwd pos] AND DI[117:act 3 in bwd pos]) TIMEOUT,LBL[901] ;
 155:  WAIT (!DI[118:act 4 in fwd pos] AND DI[119:act 4 in bwd pos]) TIMEOUT,LBL[901] ;
 156:  JMP LBL[30] ;
 157:   ;
 158:  LBL[4:new prod] ;
 159:  CALL BB_GRIPPER_RESET    ;
 160:  F[1:carrying product]=(OFF) ;
 161:  R[58:box next gripper]=1    ;
 162:  R[59:box resume phase]=0    ;
 163:  DO[112:gripper act 1 fwd]=OFF ;
 164:  DO[111:gripper act 1 bwd]=ON ;
 165:  DO[114:gripper act 2 fwd]=OFF ;
 166:  DO[113:gripper act 2 bwd]=ON ;
 167:  DO[115:gripper act 3 fwd]=OFF ;
 168:  DO[116:gripper act 3 bwd]=ON ;
 169:  DO[117:gripper act 4 fwd]=OFF ;
 170:  DO[118:gripper act 4 bwd]=ON ;
 171:  WAIT (!DI[112:act 1 in fwd pos] AND DI[113:act 1 in bwd pos]) TIMEOUT,LBL[901] ;
 172:  WAIT (!DI[114:act 2 in fwd pos] AND DI[115:act 2 in bwd pos]) TIMEOUT,LBL[901] ;
 173:  WAIT (!DI[116:act 3 in fwd pos] AND DI[117:act 3 in bwd pos]) TIMEOUT,LBL[901] ;
 174:  WAIT (!DI[118:act 4 in fwd pos] AND DI[119:act 4 in bwd pos]) TIMEOUT,LBL[901] ;
 175:   ;
 176:  !pallet params in NUMREG ;
 177:  !P1 R31 xqty R32 yqty ;
 178:  !P1 R33 distx R34 disty ;
 179:  !P2 R35 xqty R36 yqty ;
 180:  !P2 R37 distx R38 disty ;
 181:  !P3 R39 xqty R40 yqty ;
 182:  !P3 R41 distx R42 disty ;
 183:  !Z R43 qty R44 distz ;
 184:  !spacer R45 step R46 max ;
 185:  !runtime R47-R59 PR31-PR34 ;
 186:  !EDIT VALUES FOR REF ;
 187:  R[31:box p1 x qty]=0    ;
 188:  R[32:box p1 y qty]=0    ;
 189:  R[33:box p1 dist x]=0    ;
 190:  R[34:box p1 dist y]=0    ;
 191:  R[35:box p2 x qty]=0    ;
 192:  R[36:box p2 y qty]=0    ;
 193:  R[37:box p2 dist x]=0    ;
 194:  R[38:box p2 dist y]=0    ;
 195:  R[39:box p3 x qty]=0    ;
 196:  R[40:box p3 y qty]=0    ;
 197:  R[41:box p3 dist x]=0    ;
 198:  R[42:box p3 dist y]=0    ;
 199:  R[43:box z qty]=0    ;
 200:  R[44:box dist z]=0    ;
 201:  R[45:spacer search st]=40    ;
 202:  R[46:spacer max attem]=3    ;
 203:   ;
 204:  !permit for 1st imm cycle ;
 205:  DO[101:mould area free]=ON ;
 206:  DO[102:enable mould closure]=ON ;
 207:  DO[103:enable full mould openig]=OFF ;
 208:  DO[104:free operation mode]=OFF ;
 209:  DO[105:enable ejector back]=ON ;
 210:  DO[106:enable ejector forward]=OFF ;
 211:  WAIT (DI[102:mould closed] AND !DI[103:mould open])    ;
 212:   ;
 213:  LBL[40:new box] ;
 214:  !validate pallet params ;
 215:  IF R[43:box z qty]<=0,JMP LBL[904] ;
 216:  IF (R[43:box z qty]>1 AND R[44:box dist z]<=0),JMP LBL[904] ;
 217:  IF (R[43:box z qty]>1 AND R[45:spacer search st]<=0),JMP LBL[904] ;
 218:  IF (R[43:box z qty]>1 AND R[46:spacer max attem]<=0),JMP LBL[904] ;
 219:  IF (R[31:box p1 x qty]>0 AND R[32:box p1 y qty]>0),JMP LBL[42] ;
 220:  JMP LBL[43] ;
 221:  LBL[42:validate P1] ;
 222:  R[56:box product limi]=R[31:box p1 x qty]*R[32:box p1 y qty]    ;
 223:  R[50:box x index]=R[56:box product limi] MOD 4    ;
 224:  IF R[50:box x index]<>0,JMP LBL[904] ;
 225:  LBL[43:validate P2] ;
 226:  IF (R[35:box p2 x qty]>0 AND R[36:box p2 y qty]>0),JMP LBL[44] ;
 227:  JMP LBL[45] ;
 228:  LBL[44:check P2 count] ;
 229:  R[56:box product limi]=R[35:box p2 x qty]*R[36:box p2 y qty]    ;
 230:  R[50:box x index]=R[56:box product limi] MOD 4    ;
 231:  IF R[50:box x index]<>0,JMP LBL[904] ;
 232:  LBL[45:validate P3] ;
 233:  IF (R[39:box p3 x qty]>0 AND R[40:box p3 y qty]>0),JMP LBL[46] ;
 234:  JMP LBL[47] ;
 235:  LBL[46:check P3 count] ;
 236:  R[56:box product limi]=R[39:box p3 x qty]*R[40:box p3 y qty]    ;
 237:  R[50:box x index]=R[56:box product limi] MOD 4    ;
 238:  IF R[50:box x index]<>0,JMP LBL[904] ;
 239:  LBL[47:at least one] ;
 240:  IF (R[31:box p1 x qty]>0 AND R[32:box p1 y qty]>0),JMP LBL[41] ;
 241:  IF (R[35:box p2 x qty]>0 AND R[36:box p2 y qty]>0),JMP LBL[41] ;
 242:  IF (R[39:box p3 x qty]>0 AND R[40:box p3 y qty]>0),JMP LBL[41] ;
 243:  JMP LBL[904] ;
 244:  LBL[41:params valid] ;
 245:  R[47:box layer index]=0    ;
 246:  R[48:box active palle]=1    ;
 247:  R[49:box product inde]=0    ;
 248:  R[58:box next gripper]=1    ;
 249:  R[59:box resume phase]=0    ;
 250:  JMP LBL[60] ;
 251:   ;
 252:  !select active pallet ;
 253:  LBL[60:select pallet] ;
 254:  IF R[48:box active palle]=1,JMP LBL[65] ;
 255:  IF R[48:box active palle]=2,JMP LBL[66] ;
 256:  IF R[48:box active palle]=3,JMP LBL[67] ;
 257:  IF R[48:box active palle]>3,JMP LBL[70] ;
 258:  JMP LBL[901] ;
 259:  LBL[65:check P1] ;
 260:  IF (R[31:box p1 x qty]>0 AND R[32:box p1 y qty]>0),JMP LBL[61] ;
 261:  R[48:box active palle]=2    ;
 262:  JMP LBL[60] ;
 263:  LBL[66:check P2] ;
 264:  IF (R[35:box p2 x qty]>0 AND R[36:box p2 y qty]>0),JMP LBL[62] ;
 265:  R[48:box active palle]=3    ;
 266:  JMP LBL[60] ;
 267:  LBL[67:check P3] ;
 268:  IF (R[39:box p3 x qty]>0 AND R[40:box p3 y qty]>0),JMP LBL[63] ;
 269:  R[48:box active palle]=4    ;
 270:  JMP LBL[60] ;
 271:   ;
 272:  LBL[61:load P1] ;
 273:  R[52:box active x qty]=R[31:box p1 x qty]    ;
 274:  R[53:box active y qty]=R[32:box p1 y qty]    ;
 275:  R[54:box active dist ]=R[33:box p1 dist x]    ;
 276:  R[55:box active dist ]=R[34:box p1 dist y]    ;
 277:  JMP LBL[64] ;
 278:  LBL[62:load P2] ;
 279:  R[52:box active x qty]=R[35:box p2 x qty]    ;
 280:  R[53:box active y qty]=R[36:box p2 y qty]    ;
 281:  R[54:box active dist ]=R[37:box p2 dist x]    ;
 282:  R[55:box active dist ]=R[38:box p2 dist y]    ;
 283:  JMP LBL[64] ;
 284:  LBL[63:load P3] ;
 285:  R[52:box active x qty]=R[39:box p3 x qty]    ;
 286:  R[53:box active y qty]=R[40:box p3 y qty]    ;
 287:  R[54:box active dist ]=R[41:box p3 dist x]    ;
 288:  R[55:box active dist ]=R[42:box p3 dist y]    ;
 289:  LBL[64:active loaded] ;
 290:  R[56:box product limi]=R[52:box active x qty]*R[53:box active y qty]    ;
 291:  R[49:box product inde]=0    ;
 292:  R[58:box next gripper]=1    ;
 293:  R[59:box resume phase]=0    ;
 294:  JMP LBL[20] ;
 295:   ;
 296:  !-------------------------------- ;
 297:  !main program loop ;
 298:  LBL[20:loop] ;
 299:   ;
 300:  IF (DI[3:cmd continiue job]),JMP LBL[3] ;
 301:  R[50:box x index]=R[56:box product limi]-R[49:box product inde]    ;
 302:  IF R[50:box x index]<4,JMP LBL[904] ;
 303:  R[58:box next gripper]=1    ;
 304:  R[59:box resume phase]=0    ;
 305:  DO[112:gripper act 1 fwd]=OFF ;
 306:  DO[111:gripper act 1 bwd]=ON ;
 307:  DO[114:gripper act 2 fwd]=OFF ;
 308:  DO[113:gripper act 2 bwd]=ON ;
 309:  DO[115:gripper act 3 fwd]=OFF ;
 310:  DO[116:gripper act 3 bwd]=ON ;
 311:  DO[117:gripper act 4 fwd]=OFF ;
 312:  DO[118:gripper act 4 bwd]=ON ;
 313:  WAIT (!DI[112:act 1 in fwd pos] AND DI[113:act 1 in bwd pos]) TIMEOUT,LBL[901] ;
 314:  WAIT (!DI[114:act 2 in fwd pos] AND DI[115:act 2 in bwd pos]) TIMEOUT,LBL[901] ;
 315:  WAIT (!DI[116:act 3 in fwd pos] AND DI[117:act 3 in bwd pos]) TIMEOUT,LBL[901] ;
 316:  WAIT (!DI[118:act 4 in fwd pos] AND DI[119:act 4 in bwd pos]) TIMEOUT,LBL[901] ;
 317:  !move to imm ;
 318:J P[13:elev to imm 1] 100% CNT100    ;
 319:  DO[119:axis-7 straight]=ON ;
 320:  DO[120:axis-7 bend]=OFF ;
 321:L P[6] 1000mm/sec CNT100 ACC50    ;
 322:  WAIT (RI[6:axis-7 straight] AND !RI[5:axis-7 bend]) TIMEOUT,LBL[901] ;
 323:   ;
 324:  !open imm ;
 325:  DO[102:enable mould closure]=OFF ;
 326:  DO[103:enable full mould openig]=ON ;
 327:L P[15:imm wait pos] 1000mm/sec CNT15    ;
 328:  WAIT (DI[103:mould open] AND !DI[102:mould closed]) TIMEOUT,LBL[901] ;
 329:L P[16:mould] 2000mm/sec CNT0    ;
 330:  RO[1:vacuum 1]=ON ;
 331:  RO[2:blow-off 1]=OFF ;
 332:  RO[3:vacuum 2]=ON ;
 333:  RO[4:blow-off 2]=OFF ;
 334:  RO[5:vacuum 3]=ON ;
 335:  RO[6:blow-off 3]=OFF ;
 336:  RO[7:vacuum 4]=ON ;
 337:  RO[8:blow-off 4]=OFF ;
 338:L P[17:product pickup] 100mm/sec FINE    ;
 339:  DO[105:enable ejector back]=OFF ;
 340:  DO[106:enable ejector forward]=ON ;
 341:  WAIT (!DI[106:ejector in back pos] AND DI[107:ejector in forward pos]) TIMEOUT,LBL[901] ;
 342:  WAIT (RI[1:vacuum 1 ok]) TIMEOUT,LBL[901] ;
 343:  WAIT (RI[2:vacuum 2 ok]) TIMEOUT,LBL[901] ;
 344:  WAIT (RI[3:vacuum 3 ok]) TIMEOUT,LBL[901] ;
 345:  WAIT (RI[4:vacuum 4 ok]) TIMEOUT,LBL[901] ;
 346:  F[1:carrying product]=(ON) ;
 347:  R[58:box next gripper]=1    ;
 348:  IF DI[6:cmd samples]=ON,JMP LBL[21] ;
 349:  R[59:box resume phase]=1    ;
 350:  JMP LBL[22] ;
 351:  LBL[21:set sample phase] ;
 352:  R[59:box resume phase]=2    ;
 353:  LBL[22:phase selected] ;
 354:  DO[106:enable ejector forward]=OFF ;
 355:  DO[105:enable ejector back]=ON ;
 356:  WAIT (DI[106:ejector in back pos] AND !DI[107:ejector in forward pos]) TIMEOUT,LBL[901] ;
 357:L P[16:mould] 300mm/sec FINE    ;
 358:L P[19:imm wait pos] 2000mm/sec FINE ACC50    ;
 359:  DO[105:enable ejector back]=ON ;
 360:  DO[106:enable ejector forward]=ON ;
 361:L P[6] 1000mm/sec CNT0 ACC50    ;
 362:  IF R[59:box resume phase]=2,JMP LBL[30] ;
 363:   ;
 364:  DO[102:enable mould closure]=ON ;
 365:  DO[103:enable full mould openig]=OFF ;
 366:  DO[105:enable ejector back]=OFF ;
 367:  DO[106:enable ejector forward]=OFF ;
 368:   ;
 369:  !go to box ;
 370:  DO[119:axis-7 straight]=OFF ;
 371:  DO[120:axis-7 bend]=ON ;
 372:L P[20:elev to imm 1] 2000mm/sec CNT100    ;
 373:J P[21:elevator] 100% CNT100    ;
 374:  WAIT (!RI[6:axis-7 straight] AND RI[5:axis-7 bend]) TIMEOUT,LBL[901] ;
 375:  WAIT (!DI[103:mould open] AND DI[102:mould closed]) TIMEOUT,LBL[901] ;
 376:  !wait outside elevator ;
 377:  WAIT (DI[5:elevator ready]) TIMEOUT,LBL[903] ;
 378:  DO[14:cmd ack]=PULSE,2.0sec ;
 379:J P[22:guide prod place] 100% CNT0    ;
 380:   ;
 381:  LBL[80:place dispatcher] ;
 382:  IF R[58:box next gripper]=1,JMP LBL[100] ;
 383:  IF R[58:box next gripper]=2,JMP LBL[130] ;
 384:  IF R[58:box next gripper]=3,JMP LBL[160] ;
 385:  IF R[58:box next gripper]=4,JMP LBL[190] ;
 386:  IF R[58:box next gripper]=5,JMP LBL[220] ;
 387:  JMP LBL[901] ;
 388:   ;
 389:  LBL[100:place gripper 1] ;
 390:  IF R[49:box product inde]>=R[56:box product limi],JMP LBL[904] ;
 391:  R[50:box x index]=R[49:box product inde] MOD R[52:box active x qty]    ;
 392:  R[51:box y index]=R[49:box product inde] DIV R[52:box active x qty]    ;
 393:  PR[31:box product offs]=LPOS-LPOS    ;
 394:  PR[31,1:box product offs]=R[50:box x index]*R[54:box active dist ]    ;
 395:  PR[31,2:box product offs]=R[51:box y index]*R[55:box active dist ]    ;
 396:  PR[31,3:box product offs]=R[47:box layer index]*R[44:box dist z]    ;
 397:  PR[31,3:box product offs]=PR[31,3:box product offs]+50    ;
 398:  IF R[48:box active palle]=1,JMP LBL[101] ;
 399:  IF R[48:box active palle]=2,JMP LBL[102] ;
 400:  IF R[48:box active palle]=3,JMP LBL[103] ;
 401:  JMP LBL[901] ;
 402:  LBL[101:G1 approach P1] ;
 403:L P[101] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 404:  JMP LBL[104] ;
 405:  LBL[102:G1 approach P2] ;
 406:L P[201] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 407:  JMP LBL[104] ;
 408:  LBL[103:G1 approach P3] ;
 409:L P[301] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 410:  LBL[104:G1 work] ;
 411:  DO[111:gripper act 1 bwd]=OFF ;
 412:  DO[112:gripper act 1 fwd]=ON ;
 413:  WAIT (DI[112:act 1 in fwd pos] AND !DI[113:act 1 in bwd pos]) TIMEOUT,LBL[901] ;
 414:  PR[31,3:box product offs]=R[47:box layer index]*R[44:box dist z]    ;
 415:  IF R[48:box active palle]=1,JMP LBL[105] ;
 416:  IF R[48:box active palle]=2,JMP LBL[106] ;
 417:  IF R[48:box active palle]=3,JMP LBL[107] ;
 418:  JMP LBL[901] ;
 419:  LBL[105:G1 place P1] ;
 420:L P[101] 500mm/sec FINE Offset,PR[31:box product offs]    ;
 421:  JMP LBL[108] ;
 422:  LBL[106:G1 place P2] ;
 423:L P[201] 500mm/sec FINE Offset,PR[31:box product offs]    ;
 424:  JMP LBL[108] ;
 425:  LBL[107:G1 place P3] ;
 426:L P[301] 500mm/sec FINE Offset,PR[31:box product offs]    ;
 427:  LBL[108:release grip 1] ;
 428:  RO[1:vacuum 1]=OFF ;
 429:  RO[2:blow-off 1]=PULSE,1.0sec ;
 430:  WAIT (!RI[1:vacuum 1 ok]) TIMEOUT,LBL[901] ;
 431:  R[49:box product inde]=R[49:box product inde]+1    ;
 432:  R[58:box next gripper]=2    ;
 433:  PR[31,3:box product offs]=R[47:box layer index]*R[44:box dist z]    ;
 434:  PR[31,3:box product offs]=PR[31,3:box product offs]+50    ;
 435:  IF R[48:box active palle]=1,JMP LBL[109] ;
 436:  IF R[48:box active palle]=2,JMP LBL[110] ;
 437:  IF R[48:box active palle]=3,JMP LBL[111] ;
 438:  JMP LBL[901] ;
 439:  LBL[109:G1 retreat P1] ;
 440:L P[101] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 441:  JMP LBL[112] ;
 442:  LBL[110:G1 retreat P2] ;
 443:L P[201] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 444:  JMP LBL[112] ;
 445:  LBL[111:G1 retreat P3] ;
 446:L P[301] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 447:  LBL[112:G1 home] ;
 448:  DO[112:gripper act 1 fwd]=OFF ;
 449:  DO[111:gripper act 1 bwd]=ON ;
 450:  WAIT (!DI[112:act 1 in fwd pos] AND DI[113:act 1 in bwd pos]) TIMEOUT,LBL[901] ;
 451:  JMP LBL[130] ;
 452:   ;
 453:  LBL[130:place gripper 2] ;
 454:  IF R[49:box product inde]>=R[56:box product limi],JMP LBL[904] ;
 455:  R[50:box x index]=R[49:box product inde] MOD R[52:box active x qty]    ;
 456:  R[51:box y index]=R[49:box product inde] DIV R[52:box active x qty]    ;
 457:  PR[31:box product offs]=LPOS-LPOS    ;
 458:  PR[31,1:box product offs]=R[50:box x index]*R[54:box active dist ]    ;
 459:  PR[31,2:box product offs]=R[51:box y index]*R[55:box active dist ]    ;
 460:  PR[31,3:box product offs]=R[47:box layer index]*R[44:box dist z]    ;
 461:  PR[31,3:box product offs]=PR[31,3:box product offs]+50    ;
 462:  IF R[48:box active palle]=1,JMP LBL[131] ;
 463:  IF R[48:box active palle]=2,JMP LBL[132] ;
 464:  IF R[48:box active palle]=3,JMP LBL[133] ;
 465:  JMP LBL[901] ;
 466:  LBL[131:G2 approach P1] ;
 467:L P[102] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 468:  JMP LBL[134] ;
 469:  LBL[132:G2 approach P2] ;
 470:L P[202] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 471:  JMP LBL[134] ;
 472:  LBL[133:G2 approach P3] ;
 473:L P[302] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 474:  LBL[134:G2 work] ;
 475:  DO[113:gripper act 2 bwd]=OFF ;
 476:  DO[114:gripper act 2 fwd]=ON ;
 477:  WAIT (DI[114:act 2 in fwd pos] AND !DI[115:act 2 in bwd pos]) TIMEOUT,LBL[901] ;
 478:  PR[31,3:box product offs]=R[47:box layer index]*R[44:box dist z]    ;
 479:  IF R[48:box active palle]=1,JMP LBL[135] ;
 480:  IF R[48:box active palle]=2,JMP LBL[136] ;
 481:  IF R[48:box active palle]=3,JMP LBL[137] ;
 482:  JMP LBL[901] ;
 483:  LBL[135:G2 place P1] ;
 484:L P[102] 500mm/sec FINE Offset,PR[31:box product offs]    ;
 485:  JMP LBL[138] ;
 486:  LBL[136:G2 place P2] ;
 487:L P[202] 500mm/sec FINE Offset,PR[31:box product offs]    ;
 488:  JMP LBL[138] ;
 489:  LBL[137:G2 place P3] ;
 490:L P[302] 500mm/sec FINE Offset,PR[31:box product offs]    ;
 491:  LBL[138:release grip 2] ;
 492:  RO[3:vacuum 2]=OFF ;
 493:  RO[4:blow-off 2]=PULSE,1.0sec ;
 494:  WAIT (!RI[2:vacuum 2 ok]) TIMEOUT,LBL[901] ;
 495:  R[49:box product inde]=R[49:box product inde]+1    ;
 496:  R[58:box next gripper]=3    ;
 497:  PR[31,3:box product offs]=R[47:box layer index]*R[44:box dist z]    ;
 498:  PR[31,3:box product offs]=PR[31,3:box product offs]+50    ;
 499:  IF R[48:box active palle]=1,JMP LBL[139] ;
 500:  IF R[48:box active palle]=2,JMP LBL[140] ;
 501:  IF R[48:box active palle]=3,JMP LBL[141] ;
 502:  JMP LBL[901] ;
 503:  LBL[139:G2 retreat P1] ;
 504:L P[102] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 505:  JMP LBL[142] ;
 506:  LBL[140:G2 retreat P2] ;
 507:L P[202] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 508:  JMP LBL[142] ;
 509:  LBL[141:G2 retreat P3] ;
 510:L P[302] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 511:  LBL[142:G2 home] ;
 512:  DO[114:gripper act 2 fwd]=OFF ;
 513:  DO[113:gripper act 2 bwd]=ON ;
 514:  WAIT (!DI[114:act 2 in fwd pos] AND DI[115:act 2 in bwd pos]) TIMEOUT,LBL[901] ;
 515:  JMP LBL[160] ;
 516:   ;
 517:  LBL[160:place gripper 3] ;
 518:  IF R[49:box product inde]>=R[56:box product limi],JMP LBL[904] ;
 519:  R[50:box x index]=R[49:box product inde] MOD R[52:box active x qty]    ;
 520:  R[51:box y index]=R[49:box product inde] DIV R[52:box active x qty]    ;
 521:  PR[31:box product offs]=LPOS-LPOS    ;
 522:  PR[31,1:box product offs]=R[50:box x index]*R[54:box active dist ]    ;
 523:  PR[31,2:box product offs]=R[51:box y index]*R[55:box active dist ]    ;
 524:  PR[31,3:box product offs]=R[47:box layer index]*R[44:box dist z]    ;
 525:  PR[31,3:box product offs]=PR[31,3:box product offs]+50    ;
 526:  IF R[48:box active palle]=1,JMP LBL[161] ;
 527:  IF R[48:box active palle]=2,JMP LBL[162] ;
 528:  IF R[48:box active palle]=3,JMP LBL[163] ;
 529:  JMP LBL[901] ;
 530:  LBL[161:G3 approach P1] ;
 531:L P[103] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 532:  JMP LBL[164] ;
 533:  LBL[162:G3 approach P2] ;
 534:L P[203] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 535:  JMP LBL[164] ;
 536:  LBL[163:G3 approach P3] ;
 537:L P[303] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 538:  LBL[164:G3 work] ;
 539:  DO[116:gripper act 3 bwd]=OFF ;
 540:  DO[115:gripper act 3 fwd]=ON ;
 541:  WAIT (DI[116:act 3 in fwd pos] AND !DI[117:act 3 in bwd pos]) TIMEOUT,LBL[901] ;
 542:  PR[31,3:box product offs]=R[47:box layer index]*R[44:box dist z]    ;
 543:  IF R[48:box active palle]=1,JMP LBL[165] ;
 544:  IF R[48:box active palle]=2,JMP LBL[166] ;
 545:  IF R[48:box active palle]=3,JMP LBL[167] ;
 546:  JMP LBL[901] ;
 547:  LBL[165:G3 place P1] ;
 548:L P[103] 500mm/sec FINE Offset,PR[31:box product offs]    ;
 549:  JMP LBL[168] ;
 550:  LBL[166:G3 place P2] ;
 551:L P[203] 500mm/sec FINE Offset,PR[31:box product offs]    ;
 552:  JMP LBL[168] ;
 553:  LBL[167:G3 place P3] ;
 554:L P[303] 500mm/sec FINE Offset,PR[31:box product offs]    ;
 555:  LBL[168:release grip 3] ;
 556:  RO[5:vacuum 3]=OFF ;
 557:  RO[6:blow-off 3]=PULSE,1.0sec ;
 558:  WAIT (!RI[3:vacuum 3 ok]) TIMEOUT,LBL[901] ;
 559:  R[49:box product inde]=R[49:box product inde]+1    ;
 560:  R[58:box next gripper]=4    ;
 561:  PR[31,3:box product offs]=R[47:box layer index]*R[44:box dist z]    ;
 562:  PR[31,3:box product offs]=PR[31,3:box product offs]+50    ;
 563:  IF R[48:box active palle]=1,JMP LBL[169] ;
 564:  IF R[48:box active palle]=2,JMP LBL[170] ;
 565:  IF R[48:box active palle]=3,JMP LBL[171] ;
 566:  JMP LBL[901] ;
 567:  LBL[169:G3 retreat P1] ;
 568:L P[103] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 569:  JMP LBL[172] ;
 570:  LBL[170:G3 retreat P2] ;
 571:L P[203] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 572:  JMP LBL[172] ;
 573:  LBL[171:G3 retreat P3] ;
 574:L P[303] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 575:  LBL[172:G3 home] ;
 576:  DO[115:gripper act 3 fwd]=OFF ;
 577:  DO[116:gripper act 3 bwd]=ON ;
 578:  WAIT (!DI[116:act 3 in fwd pos] AND DI[117:act 3 in bwd pos]) TIMEOUT,LBL[901] ;
 579:  JMP LBL[190] ;
 580:   ;
 581:  LBL[190:place gripper 4] ;
 582:  IF R[49:box product inde]>=R[56:box product limi],JMP LBL[904] ;
 583:  R[50:box x index]=R[49:box product inde] MOD R[52:box active x qty]    ;
 584:  R[51:box y index]=R[49:box product inde] DIV R[52:box active x qty]    ;
 585:  PR[31:box product offs]=LPOS-LPOS    ;
 586:  PR[31,1:box product offs]=R[50:box x index]*R[54:box active dist ]    ;
 587:  PR[31,2:box product offs]=R[51:box y index]*R[55:box active dist ]    ;
 588:  PR[31,3:box product offs]=R[47:box layer index]*R[44:box dist z]    ;
 589:  PR[31,3:box product offs]=PR[31,3:box product offs]+50    ;
 590:  IF R[48:box active palle]=1,JMP LBL[191] ;
 591:  IF R[48:box active palle]=2,JMP LBL[192] ;
 592:  IF R[48:box active palle]=3,JMP LBL[193] ;
 593:  JMP LBL[901] ;
 594:  LBL[191:G4 approach P1] ;
 595:L P[104] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 596:  JMP LBL[194] ;
 597:  LBL[192:G4 approach P2] ;
 598:L P[204] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 599:  JMP LBL[194] ;
 600:  LBL[193:G4 approach P3] ;
 601:L P[304] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 602:  LBL[194:G4 work] ;
 603:  DO[118:gripper act 4 bwd]=OFF ;
 604:  DO[117:gripper act 4 fwd]=ON ;
 605:  WAIT (DI[118:act 4 in fwd pos] AND !DI[119:act 4 in bwd pos]) TIMEOUT,LBL[901] ;
 606:  PR[31,3:box product offs]=R[47:box layer index]*R[44:box dist z]    ;
 607:  IF R[48:box active palle]=1,JMP LBL[195] ;
 608:  IF R[48:box active palle]=2,JMP LBL[196] ;
 609:  IF R[48:box active palle]=3,JMP LBL[197] ;
 610:  JMP LBL[901] ;
 611:  LBL[195:G4 place P1] ;
 612:L P[104] 500mm/sec FINE Offset,PR[31:box product offs]    ;
 613:  JMP LBL[198] ;
 614:  LBL[196:G4 place P2] ;
 615:L P[204] 500mm/sec FINE Offset,PR[31:box product offs]    ;
 616:  JMP LBL[198] ;
 617:  LBL[197:G4 place P3] ;
 618:L P[304] 500mm/sec FINE Offset,PR[31:box product offs]    ;
 619:  LBL[198:release grip 4] ;
 620:  RO[7:vacuum 4]=OFF ;
 621:  RO[8:blow-off 4]=PULSE,1.0sec ;
 622:  WAIT (!RI[4:vacuum 4 ok]) TIMEOUT,LBL[901] ;
 623:  R[49:box product inde]=R[49:box product inde]+1    ;
 624:  R[58:box next gripper]=5    ;
 625:  F[1:carrying product]=(OFF) ;
 626:  PR[31,3:box product offs]=R[47:box layer index]*R[44:box dist z]    ;
 627:  PR[31,3:box product offs]=PR[31,3:box product offs]+50    ;
 628:  IF R[48:box active palle]=1,JMP LBL[199] ;
 629:  IF R[48:box active palle]=2,JMP LBL[200] ;
 630:  IF R[48:box active palle]=3,JMP LBL[201] ;
 631:  JMP LBL[901] ;
 632:  LBL[199:G4 retreat P1] ;
 633:L P[104] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 634:  JMP LBL[202] ;
 635:  LBL[200:G4 retreat P2] ;
 636:L P[204] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 637:  JMP LBL[202] ;
 638:  LBL[201:G4 retreat P3] ;
 639:L P[304] 1000mm/sec CNT0 Offset,PR[31:box product offs]    ;
 640:  LBL[202:G4 home] ;
 641:  DO[117:gripper act 4 fwd]=OFF ;
 642:  DO[118:gripper act 4 bwd]=ON ;
 643:  WAIT (!DI[118:act 4 in fwd pos] AND DI[119:act 4 in bwd pos]) TIMEOUT,LBL[901] ;
 644:   ;
 645:  LBL[220:product clear] ;
 646:  DO[112:gripper act 1 fwd]=OFF ;
 647:  DO[111:gripper act 1 bwd]=ON ;
 648:  DO[114:gripper act 2 fwd]=OFF ;
 649:  DO[113:gripper act 2 bwd]=ON ;
 650:  DO[115:gripper act 3 fwd]=OFF ;
 651:  DO[116:gripper act 3 bwd]=ON ;
 652:  DO[117:gripper act 4 fwd]=OFF ;
 653:  DO[118:gripper act 4 bwd]=ON ;
 654:  WAIT (!DI[112:act 1 in fwd pos] AND DI[113:act 1 in bwd pos]) TIMEOUT,LBL[901] ;
 655:  WAIT (!DI[114:act 2 in fwd pos] AND DI[115:act 2 in bwd pos]) TIMEOUT,LBL[901] ;
 656:  WAIT (!DI[116:act 3 in fwd pos] AND DI[117:act 3 in bwd pos]) TIMEOUT,LBL[901] ;
 657:  WAIT (!DI[118:act 4 in fwd pos] AND DI[119:act 4 in bwd pos]) TIMEOUT,LBL[901] ;
 658:J P[22:guide prod place] 100% CNT100    ;
 659:J P[21:elevator] 100% CNT100    ;
 660:  R[58:box next gripper]=1    ;
 661:  R[59:box resume phase]=0    ;
 662:  F[1:carrying product]=(OFF) ;
 663:  DO[23:box progress]=PULSE,2.0sec ;
 664:  IF R[49:box product inde]<R[56:box product limi],JMP LBL[20] ;
 665:  R[48:box active palle]=R[48:box active palle]+1    ;
 666:  R[49:box product inde]=0    ;
 667:  JMP LBL[60] ;
 668:   ;
 669:  LBL[70:layer complete] ;
 670:  DO[17:layer finished]=PULSE,2.0sec ;
 671:  R[48:box active palle]=R[47:box layer index]+1    ;
 672:  IF R[48:box active palle]>=R[43:box z qty],JMP LBL[75] ;
 673:   ;
 674:  !go outside storage ;
 675:J P[2:elevator] 100% CNT50    ;
 676:   ;
 677:J P[7] 100% FINE    ;
 678:   ;
 679:  DO[119:axis-7 straight]=OFF ;
 680:  DO[120:axis-7 bend]=ON ;
 681:  WAIT (RI[5:axis-7 bend] AND !RI[6:axis-7 straight])    ;
 682:   ;
 683:  !wait for storage door open ;
 684:  DO[22:storage access req]=ON ;
 685:  WAIT DI[10:storage ready]=ON TIMEOUT,LBL[905] ;
 686:   ;
 687:L P[3:above 1st spacer] 2000mm/sec CNT0    ;
 688:L P[4:1st spacer] 1000mm/sec CNT0    ;
 689:  IF R[47:box layer index]<>0,JMP LBL[71] ;
 690:  PR[32:spacer search po]=LPOS    ;
 691:  LBL[71:search init] ;
 692:  R[57:spacer try count]=0    ;
 693:   ;
 694:  LBL[72:spacer pickup] ;
 695:  R[57:spacer try count]=R[57:spacer try count]+1    ;
 696:  IF R[57:spacer try count]>R[46:spacer max attem],JMP LBL[902] ;
 697:  IF (DI[32:vacuum 5 ok]),CALL BB_RESET_VAC5 ;
 698:  IF (DI[32:vacuum 5 ok]),JMP LBL[901] ;
 699:  SKIP CONDITION DI[32:vacuum 5 ok]=ON    ;
 700:  DO[31:vacuum 5]=ON ;
 701:  DO[32:blow-off 5]=OFF ;
 702:   ;
 703:  LBL[73:go for spacer] ;
 704:L PR[32:spacer search po] 100mm/sec CNT0 Skip,LBL[74]    ;
 705:  JMP LBL[77] ;
 706:  LBL[74:spacer not found] ;
 707:  R[57:spacer try count]=R[57:spacer try count]+1    ;
 708:  IF R[57:spacer try count]>R[46:spacer max attem],JMP LBL[902] ;
 709:  PR[32,3:spacer search po]=PR[32,3:spacer search po]-R[45:spacer search st]    ;
 710:  JMP LBL[73] ;
 711:   ;
 712:  LBL[77:spacer found] ;
 713:  PR[32:spacer search po]=LPOS    ;
 714:  SKIP CONDITION DI[32:vacuum 5 ok]=OFF    ;
 715:L PR[32:spacer search po] 200mm/sec CNT100 Offset,PR[34:spacer retreat] Skip,LBL[78]    ;
 716:  JMP LBL[72] ;
 717:  LBL[78:pickup completed] ;
 718:L P[4:1st spacer] 500mm/sec CNT100    ;
 719:J P[3:above 1st spacer] 100% CNT100    ;
 720:J P[7] 100% CNT50    ;
 721:J P[2:elevator] 100% CNT100    ;
 722:  DO[22:storage access req]=OFF ;
 723:  WAIT DI[10:storage ready]=OFF TIMEOUT,LBL[905] ;
 724:   ;
 725:  !place spacer on box ;
 726:J P[8:guide pal place] 100% CNT100    ;
 727:  WAIT (DI[5:elevator ready]) TIMEOUT,LBL[903] ;
 728:  PR[33:box spacer offse]=LPOS-LPOS    ;
 729:  PR[33,3:box spacer offse]=R[47:box layer index]*R[44:box dist z]    ;
 730:  PR[33,3:box spacer offse]=PR[33,3:box spacer offse]+100    ;
 731:L P[100] 500mm/sec CNT0 Offset,PR[33:box spacer offse]    ;
 732:  PR[33,3:box spacer offse]=R[47:box layer index]*R[44:box dist z]    ;
 733:L P[100] 200mm/sec FINE Offset,PR[33:box spacer offse]    ;
 734:  DO[31:vacuum 5]=OFF ;
 735:  DO[32:blow-off 5]=PULSE,2.0sec ;
 736:  WAIT (!DI[32:vacuum 5 ok]) TIMEOUT,LBL[901] ;
 737:  DO[15:pallet placed]=PULSE,2.0sec ;
 738:   ;
 739:  PR[33,3:box spacer offse]=R[47:box layer index]*R[44:box dist z]    ;
 740:  PR[33,3:box spacer offse]=PR[33,3:box spacer offse]+200    ;
 741:L P[100] 500mm/sec CNT100 Offset,PR[33:box spacer offse]    ;
 742:J P[8:guide pal place] 100% CNT100    ;
 743:J P[12:elevator] 100% CNT100    ;
 744:   ;
 745:  R[47:box layer index]=R[47:box layer index]+1    ;
 746:  R[48:box active palle]=1    ;
 747:  R[49:box product inde]=0    ;
 748:  DO[23:box progress]=PULSE,2.0sec ;
 749:  JMP LBL[60] ;
 750:   ;
 751:  LBL[75:box complete] ;
 752:  DO[18:stack finished]=ON ;
 753:  WAIT DI[8:ack stack finished]=ON    ;
 754:  DO[18:stack finished]=OFF ;
 755:  WAIT DI[8:ack stack finished]=OFF    ;
 756:  WAIT DI[5:elevator ready]=OFF    ;
 757:  JMP LBL[40] ;
 758:  !-------------------------------- ;
 759:   ;
 760:  LBL[30:samples] ;
 761:  DO[14:cmd ack]=PULSE,2.0sec ;
 762:  !go from elev to sampl ;
 763:   ;
 764:L P[27:imm to samples1] 1000mm/sec CNT100    ;
 765:J P[28:elev to samples2] 100% CNT100    ;
 766:J P[5] 100% CNT100    ;
 767:J P[29:guide place samp] 100% CNT0    ;
 768:   ;
 769:  DO[119:axis-7 straight]=OFF ;
 770:  DO[120:axis-7 bend]=ON ;
 771:  WAIT (RI[5:axis-7 bend] AND !RI[6:axis-7 straight])    ;
 772:J P[30:samples] 50% FINE    ;
 773:   ;
 774:  RO[1:vacuum 1]=OFF ;
 775:  RO[2:blow-off 1]=PULSE,1.0sec ;
 776:  RO[3:vacuum 2]=OFF ;
 777:  RO[4:blow-off 2]=PULSE,1.0sec ;
 778:  RO[5:vacuum 3]=OFF ;
 779:  RO[6:blow-off 3]=PULSE,1.0sec ;
 780:  RO[7:vacuum 4]=OFF ;
 781:  RO[8:blow-off 4]=PULSE,1.0sec ;
 782:  WAIT (!RI[1:vacuum 1 ok]) TIMEOUT,LBL[901] ;
 783:  WAIT (!RI[2:vacuum 2 ok]) TIMEOUT,LBL[901] ;
 784:  WAIT (!RI[3:vacuum 3 ok]) TIMEOUT,LBL[901] ;
 785:  WAIT (!RI[4:vacuum 4 ok]) TIMEOUT,LBL[901] ;
 786:  F[1:carrying product]=(OFF) ;
 787:  R[58:box next gripper]=1    ;
 788:  R[59:box resume phase]=0    ;
 789:  DO[16:samples placed]=PULSE,2.0sec ;
 790:  DO[23:box progress]=PULSE,2.0sec ;
 791:J P[29:guide place samp] 100% CNT50    ;
 792:  DO[120:axis-7 bend]=OFF ;
 793:  DO[119:axis-7 straight]=ON ;
 794:  WAIT (RI[6:axis-7 straight] AND !RI[5:axis-7 bend])    ;
 795:J P[5] 100% CNT100    ;
 796:J P[28:elev to samples2] 100% CNT100    ;
 797:  JMP LBL[20] ;
 798:  !-------------------------------- ;
 799:   ;
 800:  LBL[905:storage timeout] ;
 801:  DO[22:storage access req]=OFF ;
 802:  UALM[1] ;
 803:  LBL[904:invalid params] ;
 804:  UALM[1] ;
 805:  LBL[903:elevator not rdy] ;
 806:  UALM[3] ;
 807:  LBL[902:failed to pickup] ;
 808:  UALM[2] ;
 809:  LBL[901:fault] ;
 810:  UALM[1] ;
 811:  LBL[900:end] ;
/POS
P[1:"home"]{
   GP1:
	UF : 0, UT : 3,	
	J1=     0.000 deg,	J2=   -35.000 deg,	J3=     0.000 deg,
	J4=     0.000 deg,	J5=   -90.000 deg,	J6=   -20.000 deg
};
P[2:"elevator"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   749.074  mm,	Y =   -16.800  mm,	Z =   978.329  mm,
	W =   180.000 deg,	P =     0.000 deg,	R =     0.000 deg
};
P[3:"above 1st spacer"]{
   GP1:
	UF : 0, UT : 3,	
	J1=   -46.838 deg,	J2=   -36.828 deg,	J3=   -19.510 deg,
	J4=   109.600 deg,	J5=   -46.564 deg,	J6=    62.619 deg
};
P[4:"1st spacer"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   374.190  mm,	Y =  -499.000  mm,	Z =   457.130  mm,
	W =   -90.000 deg,	P =    70.000 deg,	R =   180.000 deg
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
P[7]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   374.190  mm,	Y =   224.000  mm,	Z =   589.130  mm,
	W =   -90.000 deg,	P =    70.000 deg,	R =   180.000 deg
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
	X =   900.631  mm,	Y =    32.678  mm,	Z =   347.367  mm,
	W =   -62.167 deg,	P =    88.715 deg,	R =   -65.450 deg
};
P[12:"elevator"]{
   GP1:
	UF : 0, UT : 3,		CONFIG : 'N U T, 0, 0, 0',
	X =   820.445  mm,	Y =   141.000  mm,	Z =  1067.487  mm,
	W =  -180.000 deg,	P =     0.000 deg,	R =     0.000 deg
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
	X =   348.317  mm,	Y =   896.718  mm,	Z =    19.377  mm,
	W =    90.811 deg,	P =    -1.103 deg,	R =   179.087 deg
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
	X =  1240.693  mm,	Y =    58.716  mm,	Z =   434.224  mm,
	W =  -179.466 deg,	P =     1.293 deg,	R =   -90.264 deg
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
