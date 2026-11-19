TYPE ST_GVL_IO_DO_RAW :
STRUCT
	// --- Moduł Magazynu ---
    ctrl_LED_button_open_close_spacer_storage AT %QX0.0 : BOOL; // podświetlenie przycisku "Otwórz/Zamknij magazyn" - załącz, magazyn
    ctrl_move_M8_actuator_forward AT %QX5.6 : BOOL; // wysuń siłownik M8 - otwórz osłonę magazynu przekładek od strony robota, magazyn
    ctrl_move_M8_actuator_backward AT %QX5.7 : BOOL; // cofnij siłownik M8 - zamknij osłonę magazynu przekładek od strony robota, magazyn
    ctrl_open_spacer_storage_operator_side_lock AT %QX6.5 : BOOL; // odrygluj zamek osłony magazynu przekładek od strony operatora, magazyn

    // --- Moduł Robota ---
    ctrl_LED_button_samples AT %QX0.1 : BOOL; // podświetlenie przycisku "Podaj próbki" - załącz, robot
    ctrl_LED_button_continue_process AT %QX0.2 : BOOL; // podświetlenie przycisku "Kontynuuj proces" - załącz, robot
    ctrl_turn_on_robot_gripper_vacuum AT %QX7.5 : BOOL; // Załącz próżnię na narzędziu robota, moduł robota
    ctrl_turn_on_robot_gripper_blow_off AT %QX7.6 : BOOL; // Załącz przedmuch na narzędziu robota, moduł robota

    // --- Utils / Sygnalizacja ---
    ctrl_LED_button_start_process AT %QX0.3 : BOOL; // podświetlenie przycisku "Rozpocznij pracę/START" - załącz, utils
    ctrl_LED_button_start_emptying_process AT %QX0.5 : BOOL; // podświetlenie przycisku "Opróżnij stację" - załącz, utils
    ctrl_reset_robot_cell_doors AT %QX6.7 : BOOL; // RST klamki Euchner drzwi celi robota, utils
    ctrl_robot_cell_doors_LED_open_close AT %QX7.0 : BOOL; // LED przycisku "Otwórz/Zamknij" drzwi celi robota - załącz, utils
    ctrl_turn_on_buzzer AT %QX7.1 : BOOL; // Załącz sygnał dźwiękowy dla operatora, utils
    ctrl_turn_on_light_green AT %QX7.2 : BOOL; // Załącz zielone światło na wieży sygnalizacyjnej, utils
    ctrl_turn_on_light_yellow AT %QX7.3 : BOOL; // Załącz żółte światło na wieży sygnalizacyjnej, utils
    ctrl_turn_on_light_red AT %QX7.4 : BOOL; // Załącz czerwone światło na wieży sygnalizacyjnej, utils

    // --- Moduł Załadunku ---
    ctrl_LED_button_container_ready AT %QX0.4 : BOOL; // podświetlenie przycisku "Pojemnik gotowy" - załącz, załadunek
    ctrl_move_M1_actuator_forward AT %QX4.0 : BOOL; // wysuń siłownik M1 - spozycjonuj pojemnik w pozycji 1 (załadunku), moduł załadunku
    ctrl_move_M1_actuator_backward AT %QX4.1 : BOOL; // cofnij siłownik M1 - cofnij pozycjoner pozycji 1 (załadunku), moduł załadunku

    // --- Moduł Bufora ---
    ctrl_turn_on_top_conveyor AT %QX0.6 : BOOL; // górny transporter - kierunek podawania pustych pojemników do robota - załącz, moduł bufora
    ctrl_move_M2_actuator_forward AT %QX4.2 : BOOL; // wysuń siłownik M2 - zablokuj ruch pojemnika w pozycji 1 (załadunku), moduł bufora
    ctrl_move_M2_actuator_backward AT %QX4.3 : BOOL; // cofnij siłownik M2 - odblokuj ruch pojemnika w pozycji 1 (załadunku), moduł bufora
    ctrl_move_M3_actuator_forward AT %QX4.4 : BOOL; // wysuń siłownik M3 - zablokuj ruch pojemnika w pozycji 2, moduł bufora
    ctrl_move_M3_actuator_backward AT %QX4.5 : BOOL; // cofnij siłownik M3 - odblokuj ruch pojemnika w pozycji 2, moduł bufora
    ctrl_move_M4_actuator_forward AT %QX4.6 : BOOL; // wysuń siłownik M4 - zablokuj ruch pojemnika w pozycji 3, moduł bufora
    ctrl_move_M4_actuator_backward AT %QX4.7 : BOOL; // cofnij siłownik M4 - odblokuj ruch pojemnika w pozycji 3, moduł bufora
    ctrl_move_M5_actuator_forward AT %QX5.0 : BOOL; // wysuń siłownik M5 - spozycjonuj tacki w pozycji 3 (odbioru przez robota), moduł bufora
    ctrl_move_M5_actuator_backward AT %QX5.1 : BOOL; // cofnij siłownik M5 - cofnij pozycjoner w pozycji 3 (odbioru przez robota), moduł bufora

    // --- Moduł Rozładunku ---
    ctrl_turn_on_bottom_conveyor AT %QX0.7 : BOOL; // dolny transporter - kierunek podawanie pełnych pojemników do wyjścia - załącz, moduł rozładunku
    ctrl_turn_on_bottom_conveyor_in AT %QX7.7 : BOOL; // Załącz dolny transporter (rozładunku) w kierunku windy, moduł rozładunku

    // --- Moduł Windy ---
    ctrl_turn_on_elevator_conveyor_in AT %QX1.0 : BOOL; // transporter windy - kierunek podawania pustych pojemników do robota - załącz, winda
    ctrl_turn_on_elevator_conveyor_out AT %QX1.1 : BOOL; // transporter windy - kierunek podawania pełnych pojemników do rozładunku - załącz, winda
    ctrl_move_M6_actuator_forward AT %QX5.2 : BOOL; // wysuń siłownik M6 - spozycjonuj tacki w pozycji 4 (na windzie), moduł windy
    ctrl_move_M6_actuator_backward AT %QX5.3 : BOOL; // cofnij siłownik M6 - cofnij pozycjoner tacek w pozycji 4 (na windzie), moduł windy
    ctrl_move_M7_actuator_forward AT %QX5.4 : BOOL; // wysuń siłownik M7 - spozycjonuj kuwetę w pozycji 4 (na windzie), moduł windy
    ctrl_move_M7_actuator_backward AT %QX5.5 : BOOL; // cofnij siłownik M7 - cofnij pozycjoner kuwet w pozycji 4 (na windzie), moduł windy

    // --- Spares / Inne ---
    spare_QX6_0 AT %QX6.0 : BOOL; // spare
    spare_QX6_1 AT %QX6.1 : BOOL; // spare
    spare_QX6_2 AT %QX6.2 : BOOL; // spare
    spare_QX6_3 AT %QX6.3 : BOOL; // spare
    ctrl_open_spacer_storage_robot_side_lock AT %QX6.4 : BOOL; // odrygluj zamek osłony magazynu przekładek od strony robota, spare (zgodnie z listą)
    ctrl_open_robot_cell_doors_lock AT %QX6.6 : BOOL; // odrygluj zamek drzwi celi robota, moduł magazynu (zgodnie z listą)

    spare_QX8_0 AT %QX8.0 : BOOL; // spare
    spare_QX8_1 AT %QX8.1 : BOOL; // spare
    spare_QX8_2 AT %QX8.2 : BOOL; // spare
    spare_QX8_3 AT %QX8.3 : BOOL; // spare
    spare_QX8_4 AT %QX8.4 : BOOL; // spare
    spare_QX8_5 AT %QX8.5 : BOOL; // spare
    spare_QX8_6 AT %QX8.6 : BOOL; // spare
    spare_QX8_7 AT %QX8.7 : BOOL; // spare

END_STRUCT
END_TYPE