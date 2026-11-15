(* Jedyny natywny zapis GIATV. Brak domyślnego health; Axis_Ref wymaga GAP-06. *)
FUNCTION_BLOCK FB_ElevatorDriveAdapter
VAR_INPUT
 Cmd : ST_ElevatorDriveCmd;
 MappingVerified : BOOL;
 CommHealthy : BOOL;
 FrequencyValid : BOOL;
 ActualHz : REAL;
END_VAR
VAR_OUTPUT
 Feedback : ST_ElevatorDriveIn;
END_VAR
VAR
 fbAtv : GIATV.Control_ATV;
END_VAR
fbAtv(Axis := Altivar_320, i_xEn := Cmd.enable AND MappingVerified AND CommHealthy,
 i_xKeepOpEn := TRUE, i_xFwd := Cmd.enable AND MappingVerified AND CommHealthy AND FrequencyValid AND Cmd.forward AND NOT Cmd.reverse,
 i_xRev := Cmd.enable AND MappingVerified AND CommHealthy AND FrequencyValid AND Cmd.reverse AND NOT Cmd.forward, i_xQckStop := TRUE,
 i_xFreeWhl := TRUE, i_xFltRst := Cmd.reset, i_wSpdRef := Cmd.reference);
Feedback.valid := MappingVerified AND CommHealthy AND FrequencyValid;
Feedback.commHealthy := MappingVerified AND CommHealthy;
Feedback.statusword := fbAtv.q_wStatusword;
Feedback.actualHz := ActualHz;
