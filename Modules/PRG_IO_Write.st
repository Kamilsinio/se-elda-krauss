PROGRAM PRG_IO_Write
VAR
    encoder : FB_RobotCodec;
    iEip : INT; // Indeks slowa obrazu EtherNet/IP: 0..39.
    iVac : INT; // Obwod prozni FESTO: 1..5.
END_VAR
(* DO: dout -> RAW *)

(* LED Buttons *)
GVL_IO_RAW.dout.ctrl_LED_button_open_close_spacer_storage := GVL_IO.dout.ctrl_LED_button_open_close_spacer_storage;
GVL_IO_RAW.dout.ctrl_LED_button_samples := GVL_IO.dout.ctrl_LED_button_samples;
GVL_IO_RAW.dout.ctrl_LED_button_continue_process := GVL_IO.dout.ctrl_LED_button_continue_process;
GVL_IO_RAW.dout.ctrl_LED_button_start_process := GVL_IO.dout.ctrl_LED_button_start_process;
GVL_IO_RAW.dout.ctrl_LED_button_container_ready := GVL_IO.dout.ctrl_LED_button_container_ready;
GVL_IO_RAW.dout.ctrl_LED_button_start_emptying_process := GVL_IO.dout.ctrl_LED_button_start_emptying_process;

(* Conveyors *)
GVL_IO_RAW.dout.ctrl_turn_on_top_conveyor := GVL_IO.dout.ctrl_turn_on_top_conveyor;
GVL_IO_RAW.dout.ctrl_turn_on_bottom_conveyor := GVL_IO.dout.ctrl_turn_on_bottom_conveyor;
GVL_IO_RAW.dout.ctrl_turn_on_elevator_conveyor_in := GVL_IO.dout.ctrl_turn_on_elevator_conveyor_in;
GVL_IO_RAW.dout.ctrl_turn_on_elevator_conveyor_out := GVL_IO.dout.ctrl_turn_on_elevator_conveyor_out;

(* Zawory M1-M7 sa obslugiwane przez Assembly 101. *)

(* Locks & Doors *)
GVL_IO_RAW.dout.ctrl_open_spacer_storage_robot_side_lock := GVL_IO.dout.ctrl_open_spacer_storage_robot_side_lock;
GVL_IO_RAW.dout.ctrl_open_spacer_storage_operator_side_lock := GVL_IO.dout.ctrl_open_spacer_storage_operator_side_lock;
GVL_IO_RAW.dout.ctrl_open_robot_cell_doors_lock := GVL_IO.dout.ctrl_open_robot_cell_doors_lock;

GVL_IO_RAW.dout.ctrl_reset_robot_cell_doors := GVL_IO.dout.ctrl_reset_robot_cell_doors;
GVL_IO_RAW.dout.ctrl_robot_cell_doors_LED_open_close := GVL_IO.dout.ctrl_robot_cell_doors_LED_open_close;

(* Tower Light & Buzzer *)
GVL_IO_RAW.dout.ctrl_turn_on_buzzer := GVL_IO.dout.ctrl_turn_on_buzzer;
GVL_IO_RAW.dout.ctrl_turn_on_light_green := GVL_IO.dout.ctrl_turn_on_light_green;
GVL_IO_RAW.dout.ctrl_turn_on_light_yellow := GVL_IO.dout.ctrl_turn_on_light_yellow;
GVL_IO_RAW.dout.ctrl_turn_on_light_red := GVL_IO.dout.ctrl_turn_on_light_red;

(* Robot Gripper *)
(* BAT4: tylko Sts.vacuum[1..5], bez rownoleglego starego toru prozni 5. *)

encoder(Tx := GVL_Robot.Tx);
GVL_Robot.RawOut := encoder.RawOut;

(* PLC -> FANUC: po kodowaniu biezacego Tx przepisujemy 80 BYTE do 40 WORD.
   Little endian: pierwszy bajt pary zajmuje bity 0..7, drugi bity 8..15.
   Zapis calej ramki obejmuje rowniez rezerwy wyzerowane przez kodek. *)
FOR iEip := 0 TO 39 DO
    GVL_Robot.EipOutWords[iEip] := UINT_TO_WORD(
        TO_UINT(GVL_Robot.RawOut[2 * iEip])
        OR SHL(TO_UINT(GVL_Robot.RawOut[2 * iEip + 1]), 8));
END_FOR;

(* Assembly 101: mapa wyjsc potwierdzona na maszynie 2026-11-23.
   Zapis tylko komend koncowych, po arbitrazu i politykach zaniku.
   Pierwszy bajt pary to mlodszy bajt slowa. WP/HP = WORK/HOME. *)
// AP 3: V401, V402. AP 10: V101/V102, V103/V104, V105/V106, V107/V108.
GVL_Festo.EipOutWords[0] := UINT_TO_WORD(
    TO_UINT(GVL_Robot.storageOut.Q_V401Work)
    OR SHL(TO_UINT(GVL_Robot.storageOut.Q_V401Home), 1)
    OR SHL(TO_UINT(GVL_Robot.storageOut.Q_V402Work), 2)
    OR SHL(TO_UINT(GVL_Robot.storageOut.Q_V402Home), 3)
    OR SHL(TO_UINT(GVL_Station.Coils[2].work), 8)
    OR SHL(TO_UINT(GVL_Station.Coils[2].home), 9)
    OR SHL(TO_UINT(GVL_Station.Coils[3].work), 10)
    OR SHL(TO_UINT(GVL_Station.Coils[3].home), 11)
    OR SHL(TO_UINT(GVL_Station.Coils[4].work), 12)
    OR SHL(TO_UINT(GVL_Station.Coils[4].home), 13)
    OR SHL(TO_UINT(GVL_Station.Coils[1].work), 14)
    OR SHL(TO_UINT(GVL_Station.Coils[1].home), 15));

// AP 11: V109/V110, V301/V302, V303/V304. AP 14: V201, V202, V203.
GVL_Festo.EipOutWords[1] := UINT_TO_WORD(
    TO_UINT(GVL_Station.Coils[5].work)
    OR SHL(TO_UINT(GVL_Station.Coils[5].home), 1)
    OR SHL(TO_UINT(GVL_Station.Coils[9].work), 2)
    OR SHL(TO_UINT(GVL_Station.Coils[9].home), 3)
    OR SHL(TO_UINT(GVL_Station.Coils[10].work), 4)
    OR SHL(TO_UINT(GVL_Station.Coils[10].home), 5)
    OR SHL(TO_UINT(GVL_Station.Coils[6].work), 8)
    OR SHL(TO_UINT(GVL_Station.Coils[6].home), 9)
    OR SHL(TO_UINT(GVL_Station.Coils[8].work), 10)
    OR SHL(TO_UINT(GVL_Station.Coils[8].home), 11)
    OR SHL(TO_UINT(GVL_Station.Coils[7].work), 12)
    OR SHL(TO_UINT(GVL_Station.Coils[7].home), 13));

// AP 16/17: V501-V505. V506-V508 pozostaja rezerwa.
GVL_Festo.EipOutWords[2] := UINT_TO_WORD(
    TO_UINT(GVL_Robot.Sts.cylinders[1].work)
    OR SHL(TO_UINT(GVL_Robot.Sts.cylinders[1].home), 1)
    OR SHL(TO_UINT(GVL_Robot.Sts.cylinders[2].work), 2)
    OR SHL(TO_UINT(GVL_Robot.Sts.cylinders[2].home), 3)
    OR SHL(TO_UINT(GVL_Robot.Sts.cylinders[3].work), 4)
    OR SHL(TO_UINT(GVL_Robot.Sts.cylinders[3].home), 5)
    OR SHL(TO_UINT(GVL_Robot.Sts.cylinders[4].work), 6)
    OR SHL(TO_UINT(GVL_Robot.Sts.cylinders[4].home), 7)
    OR SHL(TO_UINT(GVL_Robot.Sts.cylinders[5].work), 8)
    OR SHL(TO_UINT(GVL_Robot.Sts.cylinders[5].home), 9));

// AP 18-22: V509-V513. Bajt 0: ssanie na bicie 0, przedmuch na bicie 1.
// Bajt 1 i bit zapisu parametrow pozostaja zerowe.
FOR iVac := 1 TO 5 DO
    GVL_Festo.EipOutWords[iVac + 2] := UINT_TO_WORD(
        TO_UINT(GVL_Robot.Sts.vacuum[iVac].hold)
        OR SHL(TO_UINT(GVL_Robot.Sts.vacuum[iVac].blow), 1));
END_FOR;

(* Podglad bajtow cewek zapisanych w tym skanie. *)
GVL_Festo.RawCoilCommandByModule[3] := TO_BYTE(WORD_TO_UINT(GVL_Festo.EipOutWords[0]) AND 255);
GVL_Festo.RawCoilCommandByModule[10] := TO_BYTE(SHR(GVL_Festo.EipOutWords[0], 8));
GVL_Festo.RawCoilCommandByModule[11] := TO_BYTE(WORD_TO_UINT(GVL_Festo.EipOutWords[1]) AND 255);
GVL_Festo.RawCoilCommandByModule[14] := TO_BYTE(SHR(GVL_Festo.EipOutWords[1], 8));
GVL_Festo.RawCoilCommandByModule[16] := TO_BYTE(WORD_TO_UINT(GVL_Festo.EipOutWords[2]) AND 255);
GVL_Festo.RawCoilCommandByModule[17] := TO_BYTE(SHR(GVL_Festo.EipOutWords[2], 8));
