TYPE ST_GVL_IO_DO_RAW :
STRUCT
    // KEB1: lampki S1, S3–S7 i styczniki taśm.
    ctrl_LED_button_open_close_spacer_storage AT %QX0.0 : BOOL; // podświetlenie przycisku "Otwórz/Zamknij magazyn" - załącz, magazyn
    ctrl_LED_button_samples AT %QX0.1 : BOOL; // podświetlenie przycisku "Podaj próbki" - załącz, robot
    ctrl_LED_button_continue_process AT %QX0.2 : BOOL; // podświetlenie przycisku "Kontynuuj proces" - załącz, robot
    ctrl_LED_button_start_process AT %QX0.3 : BOOL; // podświetlenie przycisku "Rozpocznij pracę/START" - załącz, utils
    ctrl_LED_button_container_ready AT %QX0.4 : BOOL; // podświetlenie przycisku "Pojemnik gotowy" - załącz, załadunek
    ctrl_LED_button_start_emptying_process AT %QX0.5 : BOOL; // podświetlenie przycisku "Opróżnij stację" - załącz, utils
    ctrl_turn_on_top_conveyor AT %QX0.6 : BOOL; // górny transporter - kierunek podawania pustych pojemników do robota - załącz, moduł bufora
    ctrl_turn_on_bottom_conveyor AT %QX0.7 : BOOL; // dolny transporter - kierunek podawanie pełnych pojemników do wyjścia - załącz, moduł rozładunku
    ctrl_turn_on_elevator_conveyor_out AT %QX1.0 : BOOL; // KF33: transporter windy w kierunku rozładunku
    ctrl_turn_on_elevator_conveyor_in AT %QX1.1 : BOOL; // KF34: transporter windy w kierunku robota

    // KEC12: zamki, lampka drzwi i wieża.
    ctrl_open_spacer_storage_robot_side_lock AT %QX6.4 : BOOL; // odrygluj zamek osłony magazynu przekładek od strony robota
    ctrl_open_spacer_storage_operator_side_lock AT %QX6.5 : BOOL; // odrygluj zamek osłony magazynu przekładek od strony operatora, magazyn
    ctrl_open_robot_cell_doors_lock AT %QX6.6 : BOOL; // odrygluj zamek drzwi celi robota
    ctrl_reset_robot_cell_doors AT %QX6.7 : BOOL; // RST klamki Euchner drzwi celi robota, utils
    ctrl_robot_cell_doors_LED_open_close AT %QX7.0 : BOOL; // LED przycisku "Otwórz/Zamknij" drzwi celi robota - załącz, utils
    ctrl_turn_on_light_green AT %QX7.2 : BOOL; // Załącz zielone światło na wieży sygnalizacyjnej, utils
    ctrl_turn_on_light_yellow AT %QX7.3 : BOOL; // Załącz żółte światło na wieży sygnalizacyjnej, utils
    ctrl_turn_on_light_red AT %QX7.4 : BOOL; // Załącz czerwone światło na wieży sygnalizacyjnej, utils
    ctrl_turn_on_buzzer AT %QX7.6 : BOOL; // PFA10-5 według potwierdzonej mapy I/O

    // %QX7.1: obwód STO. %QX7.5: czwarty poziom wieży, funkcja do uzgodnienia.
    // KEC11: KF201–KF210 na %QX4.0–%QX5.1, odbiór i dopuszczenie zapisu w GAP-05.
END_STRUCT
END_TYPE
