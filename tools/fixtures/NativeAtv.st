(* TYLKO TEST: syntetyczny interfejs GIATV, nie model napedu ani biblioteka Schneider. *)
FUNCTION_BLOCK NativeAtv
VAR_INPUT
 Axis : BOOL;
 i_xEn : BOOL;
 i_xKeepOpEn : BOOL;
 i_xFwd : BOOL;
 i_xRev : BOOL;
 i_xQckStop : BOOL;
 i_xFreeWhl : BOOL;
 i_xFltRst : BOOL;
 i_wSpdRef : WORD;
END_VAR
VAR_OUTPUT
 q_xEn : BOOL;
 q_xAlrm : BOOL;
 q_wStatusword : WORD;
END_VAR
q_xEn := i_xEn;
q_xAlrm := FALSE;
q_wStatusword := 16#0201;
IF i_xEn AND (i_xFwd OR i_xRev) THEN q_wStatusword := 16#0205; END_IF;
