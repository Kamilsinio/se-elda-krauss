(* 1..11: uzgodnione ostrzeżenia siłowników ST.1–ST.4.
   12..52: źródła wymagające macierzy GAP-12; 53..64: jawne rozszerzenia. *)
FUNCTION_BLOCK FB_AlarmManager
VAR_INPUT
 Cfg : ST_StationAlarmCfg;
 Inp : ST_StationAlarmIn;
END_VAR
VAR_OUTPUT
 Sts : ST_StationAlarmStatus;
END_VAR
VAR
 i : INT;
 wasActive : ARRAY[1..64] OF BOOL;
 activeOrder : ARRAY[1..64] OF INT;
 activeOrderSize : INT;
 activeCode : INT;
END_VAR

(* Zachowaj aktywne kody w kolejności ich wystąpienia, od najstarszego. *)
activeOrderSize := 0;
FOR i := 1 TO TO_INT(Sts.activeCount) DO
 activeCode := activeOrder[i];
 IF Inp.active[activeCode] THEN
  activeOrderSize := activeOrderSize + 1;
  activeOrder[activeOrderSize] := activeCode;
 END_IF;
END_FOR;

Sts.critical := FALSE; Sts.warning := FALSE; Sts.count := 0;
Sts.policyReady := Cfg.policyVerified;
FOR i := 1 TO 64 DO
 Sts.entries[i].code := TO_UINT(i);
 Sts.entries[i].station := Cfg.station[i];
 IF i <= 5 THEN Sts.entries[i].station := 1;
 ELSIF i <= 8 THEN Sts.entries[i].station := 2;
 ELSIF i <= 10 THEN Sts.entries[i].station := 3;
 ELSIF i = 11 THEN Sts.entries[i].station := 4; END_IF;
 Sts.entries[i].configured := Cfg.configured[i] OR i <= 11;
 Sts.entries[i].critical := Cfg.critical[i] AND i > 11;
 IF i > 11 AND i <= 52 AND NOT Cfg.configured[i] THEN Sts.policyReady := FALSE; END_IF;
 IF i > 11 AND Inp.active[i] AND NOT Cfg.configured[i] THEN Sts.policyReady := FALSE; END_IF;
 IF Inp.active[i] AND NOT wasActive[i] THEN
  Sts.entries[i].acknowledged := FALSE;
  activeOrderSize := activeOrderSize + 1;
  activeOrder[activeOrderSize] := i;
 END_IF;
 IF Inp.active[i] THEN Sts.entries[i].latched := TRUE; END_IF;
 Sts.entries[i].active := Inp.active[i];
 Sts.entries[i].returned := NOT Inp.active[i] AND Sts.entries[i].latched;
 Sts.entries[i].canReset := NOT Inp.active[i];
 IF Inp.acknowledge THEN Sts.entries[i].acknowledged := TRUE; END_IF;
 IF NOT Inp.active[i] AND (NOT Cfg.latched[i] OR Inp.reset) THEN Sts.entries[i].latched := FALSE; END_IF;
 IF Sts.entries[i].latched THEN
  Sts.count := Sts.count + 1;
  IF Sts.entries[i].critical THEN Sts.critical := TRUE;
  ELSIF Sts.entries[i].configured THEN Sts.warning := TRUE; END_IF;
 END_IF;
 wasActive[i] := Inp.active[i];
END_FOR;

(* Najnowszy na górze. W tym samym skanie pierwszy jest większy kod. *)
Sts.activeCount := TO_UINT(activeOrderSize);
FOR i := 1 TO 12 DO
 IF i <= activeOrderSize THEN
  Sts.activeCodes[i] := activeOrder[activeOrderSize - i + 1];
 ELSE
  Sts.activeCodes[i] := 0;
 END_IF;
END_FOR;

Sts.entries[1].text := 'ST.1 pozycjoner V107/V108';
Sts.entries[1].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[2].text := 'ST.1 podnosnik V101/V102';
Sts.entries[2].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[3].text := 'ST.1 podnosnik V103/V104';
Sts.entries[3].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[4].text := 'ST.1 podnosnik V105/V106';
Sts.entries[4].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[5].text := 'ST.1 pozycjoner V109/V110';
Sts.entries[5].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[6].text := 'ST.2 V201';
Sts.entries[6].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[7].text := 'ST.2 V202';
Sts.entries[7].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[8].text := 'ST.2 V203';
Sts.entries[8].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[9].text := 'ST.3 stopery V301/V302';
Sts.entries[9].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[10].text := 'ST.3 stopery V303/V304';
Sts.entries[10].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[11].text := 'ST.4 oslony V401/V402';
Sts.entries[11].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[12].text := 'Brak pozwolenia ukladu bezpieczenstwa';
Sts.entries[12].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[13].text := 'Niskie cisnienie';
Sts.entries[13].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[14].text := 'Komunikacja ATV320';
Sts.entries[14].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[15].text := 'Blad windy';
Sts.entries[15].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[16].text := 'Transporter gorny';
Sts.entries[16].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[17].text := 'Transporter windy';
Sts.entries[17].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[18].text := 'Transporter dolny';
Sts.entries[18].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[19].text := 'Przeplyw ST.1';
Sts.entries[19].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[20].text := 'Przeplyw ST.3';
Sts.entries[20].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[21].text := 'Sekwencer blistrow';
Sts.entries[21].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[22].text := 'Sekwencer pojemnikow';
Sts.entries[22].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[23].text := 'Blad FANUC';
Sts.entries[23].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[24].text := 'Protokol PLC-robot';
Sts.entries[24].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[25].text := 'Niewazny obraz stacji';
Sts.entries[25].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[26].text := 'Nieuzgodnione ladunki';
Sts.entries[26].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[27].text := 'Koordynator transportu';
Sts.entries[27].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[28].text := 'Arbitraz cewek';
Sts.entries[28].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[29].text := 'Sesja HMI';
Sts.entries[29].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[30].text := 'Dane EUROMAP';
Sts.entries[30].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[31].text := 'Chwytak V501';
Sts.entries[31].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[32].text := 'Chwytak V502';
Sts.entries[32].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[33].text := 'Chwytak V503';
Sts.entries[33].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[34].text := 'Chwytak V504';
Sts.entries[34].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[35].text := 'Chwytak V505';
Sts.entries[35].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[36].text := 'Proznia obwod 1';
Sts.entries[36].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[37].text := 'Proznia obwod 2';
Sts.entries[37].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[38].text := 'Proznia obwod 3';
Sts.entries[38].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[39].text := 'Proznia obwod 4';
Sts.entries[39].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[40].text := 'Proznia obwod 5';
Sts.entries[40].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[41].text := 'Diagnostyka modulu AP BAT100';
Sts.entries[41].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[42].text := 'Diagnostyka modulu AP BAT101';
Sts.entries[42].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[43].text := 'Diagnostyka modulu AP BAT200';
Sts.entries[43].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[44].text := 'Diagnostyka modulu AP BAT201';
Sts.entries[44].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[45].text := 'Diagnostyka modulu AP BAT202';
Sts.entries[45].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[46].text := 'Diagnostyka modulu AP BAT203';
Sts.entries[46].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[47].text := 'Diagnostyka modulu AP BAT204';
Sts.entries[47].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[48].text := 'Diagnostyka modulu AP BAT205';
Sts.entries[48].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[49].text := 'Diagnostyka modulu AP BAT300';
Sts.entries[49].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[50].text := 'Diagnostyka modulu AP BAT301';
Sts.entries[50].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[51].text := 'Diagnostyka modulu AP BAT400';
Sts.entries[51].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
Sts.entries[52].text := 'Diagnostyka modulu AP BAT401';
Sts.entries[52].actionText := 'Sprawdz przyczyne i rzeczywiste potwierdzenia; Reset nie uruchamia ruchu.';
