TYPE ST_GVL_IO_DI_RAW :
STRUCT 
	// --- Moduł Załadunku ---
    ind_M1_1_fwd AT %IX0.0 : BOOL; // siłownik M1.1 w pozycji wysuniętej - pozycjoner stosu, załadunek
    ind_M1_2_fwd AT %IX0.1 : BOOL; // siłownik M1.2 w pozycji wysuniętej - pozycjoner stosu, załadunek
    ind_M1_1_bwd AT %IX0.2 : BOOL; // siłownik M1.1 w pozycji cofniętej - pozycjoner stosu, załadunek
    ind_M1_2_bwd AT %IX0.3 : BOOL; // siłownik M1.2 w pozycji cofniętej - pozycjoner stosu, załadunek
    ind_M2_1_fwd AT %IX0.4 : BOOL; // siłownik M2.1 w pozycji wysuniętej - blokada ruchu stosu na pozycji 1, załadunek
    ind_M2_2_fwd AT %IX0.5 : BOOL; // siłownik M2.2 w pozycji wysuniętej - blokada ruchu stosu na pozycji 1, załadunek
    ind_M2_1_bwd AT %IX0.6 : BOOL; // siłownik M2.1 w pozycji cofniętej - blokada ruchu stosu na pozycji 1, załadunek
    ind_M2_2_bwd AT %IX0.7 : BOOL; // siłownik M2.2 w pozycji cofniętej - blokada ruchu stosu na pozycji 1, załadunek
    ind_container_in_pos_1 AT %IX1.0 : BOOL; // Pojemnik w pozycji 1 - potwierdzenie obecności, załadunek

    // --- Moduł Bufora ---
    ind_container_in_pos_2 AT %IX1.1 : BOOL; // Pojemnik w pozycji 2 - potwierdzenie obecności, bufor
    ind_M3_1_fwd AT %IX1.2 : BOOL; // siłownik M3.1 w pozycji wysuniętej - blokada ruchu stosu na pozycji 2, bufor
    ind_M3_2_fwd AT %IX1.3 : BOOL; // siłownik M3.2 w pozycji wysuniętej - blokada ruchu stosu na pozycji 2, bufor
    ind_M3_1_bwd AT %IX1.4 : BOOL; // siłownik M3.1 w pozycji cofniętej - blokada ruchu stosu na pozycji 2, bufor
    ind_M3_2_bwd AT %IX1.5 : BOOL; // siłownik M3.2 w pozycji cofniętej - blokada ruchu stosu na pozycji 2, bufor
    
    ind_M4_1_fwd AT %IX4.0 : BOOL; // siłownik M4.1 w pozycji wysuniętej - blokada ruchu stosu na pozycji 3, bufor
    ind_M4_2_fwd AT %IX4.1 : BOOL; // siłownik M4.2 w pozycji wysuniętej - blokada ruchu stosu na pozycji 3, bufor
    ind_M4_1_bwd AT %IX4.2 : BOOL; // siłownik M4.1 w pozycji cofniętej - blokada ruchu stosu na pozycji 3, bufor
    ind_M4_2_bwd AT %IX4.3 : BOOL; // siłownik M4.2 w pozycji cofniętej - blokada ruchu stosu na pozycji 3, bufor
    ind_container_in_pos_3 AT %IX4.4 : BOOL; // Pojemnik w pozycji 3 - potwierdzenie obecności, bufor
    
    spare_IX4_5 AT %IX4.5 : BOOL; // spare
    
    ind_M5_1_fwd AT %IX4.6 : BOOL; // siłownik M5.1 w pozycji wysuniętej - pozycjoner tacek na pozycji 3, bufor
    ind_M5_2_fwd AT %IX4.7 : BOOL; // siłownik M5.2 w pozycji wysuniętej - pozycjoner tacek na pozycji 3, bufor
    ind_M5_1_bwd AT %IX5.0 : BOOL; // siłownik M5.1 w pozycji cofniętej - pozycjoner tacek na pozycji 3, bufor
    ind_M5_2_bwd AT %IX5.1 : BOOL; // siłownik M5.2 w pozycji cofniętej - pozycjoner tacek na pozycji 3, bufor

    // --- Moduł Windy ---
    ind_M6_1_fwd AT %IX5.2 : BOOL; // siłownik M6.1 w pozycji wysuniętej - pozycjoner tacek na pozycji 4, winda
    ind_M6_2_fwd AT %IX5.3 : BOOL; // siłownik M6.2 w pozycji wysuniętej - pozycjoner tacek na pozycji 4, winda
    ind_M6_1_bwd AT %IX5.4 : BOOL; // siłownik M6.1 w pozycji cofniętej - pozycjoner tacek na pozycji 4, winda
    ind_M6_2_bwd AT %IX5.5 : BOOL; // siłownik M6.2 w pozycji cofniętej - pozycjoner tacek na pozycji 4, winda
    ind_M7_fwd AT %IX5.6 : BOOL; // siłownik M7 w pozycji wysuniętej - pozycjoner kuwet na pozycji 4, winda
    ind_M7_bwd AT %IX5.7 : BOOL; // siłownik M7 w pozycji cofniętej - pozycjoner kuwet na pozycji 4, winda
    ind_elevator_in_top_pos AT %IX6.0 : BOOL; // winda w górnej pozycji - zatrzymaj/uruchom falownik, winda
    ind_elevator_in_intermediate_top_pos AT %IX6.1 : BOOL; // winda blisko górnej pozycji - zmień prędkość falownika, winda
    ind_elevator_in_intermediate_bottom_pos AT %IX6.2 : BOOL; // winda blisko dolnej pozycji - zmień prędkość falownika, winda
    ind_elevator_in_bottom_pos AT %IX6.3 : BOOL; // winda w dolnej pozycji - zatrzymaj/uruchom falownik, winda
    ind_container_in_pos_4 AT %IX6.4 : BOOL; // Pojemnik w pozycji 4 - potwierdzenie obecności, winda
    
    spare_IX6_5 AT %IX6.5 : BOOL; // spare
    
    ind_elevator_emptied AT %IX6.6 : BOOL; // Pojemnik opuścił windę - pozwolenie na ruch do góry, winda

    // --- Moduł Rozładunku ---
    ind_container_in_pos_5 AT %IX6.7 : BOOL; // Pojemnik w pozycji 5, rozładunek
    ind_container_in_pos_6 AT %IX7.0 : BOOL; // Pojemnik w pozycji 6, rozładunek
    ind_container_in_pos_7 AT %IX7.1 : BOOL; // Pojemnik w pozycji 7, rozładunek
    
    spare_IX7_2 AT %IX7.2 : BOOL; // spare
    spare_IX7_3 AT %IX7.3 : BOOL; // spare

    // --- Moduł Magazynu ---
    ind_M8_fwd AT %IX7.4 : BOOL; // siłownik M8 w pozycji wysuniętej - osłona magazynu od strony robota otwarta, magazyn
    ind_M8_bwd AT %IX7.5 : BOOL; // siłownik M8 w pozycji cofniętej - osłona magazynu od strony robota zamknięta, magazyn
    ind_low_level_of_spacers AT %IX7.6 : BOOL; // niski poziom przekładek w magazynie, magazyn
    ind_spacer_storage_empty AT %IX7.7 : BOOL; // magazyn przekładek pusty, magazyn
    
    spare_IX8_0 AT %IX8.0 : BOOL; // spare
    spare_IX8_1 AT %IX8.1 : BOOL; // spare
    
    ind_button_open_close_spacer_storage AT %IX8.2 : BOOL; // przycisk "Otwórz/Zamknij magazyn" wciśnięty przez operatora, magazyn
    ind_spacer_storage_robot_side_doors_opening_permission AT %IX9.4 : BOOL; // zezwolenie otwarcia magazynu od strony robota
    ind_spacer_storage_operator_side_doors_opening_permission AT %IX9.5 : BOOL; // zezwolenie otwarcia magazynu przez operatora

    // --- Utils / Robot / Inne ---
    ind_button_open_close_robot_cell_doors AT %IX8.3 : BOOL; // przycisk "Otwórz/Zamknij drzwi" wciśnięty przez operatora, utils
    ind_button_samples AT %IX8.4 : BOOL; // przycisk "Podaj Próbki" wciśnięty przez operatora, utils
    ind_button_continue_process AT %IX8.5 : BOOL; // przycisk "Kontynuuj proces" wciśnięty przez operatora, utils
    ind_button_start_process AT %IX8.6 : BOOL; // przycisk "Rozpocznij pracę/START" wciśnięty przez operatora, utils
    ind_button_container_ready AT %IX8.7 : BOOL; // przycisk "Pojemnik gotowy" wciśnięty przez operatora, moduł załadunku
    ind_button_start_emptying_process AT %IX9.0 : BOOL; // przycisk "Opróżnij stację" wciśnięty przez operatora, utils
    ind_low_pressure AT %IX9.1 : BOOL; // niskie ciśnienie w obwodach pneumatyki, utils
    ind_robot_cell_doors_locked AT %IX9.2 : BOOL; // OD Euchner: drzwi celi robota zaryglowane, utils
    ind_robot_cell_doors_error AT %IX9.3 : BOOL; // OI Euchner: blad klamki drzwi celi robota, utils
    ind_robot_gripper_vacuum_ok AT %IX9.6 : BOOL; // sygnał osiągnięcia próżni eżektora na narzędziu robota, moduł robota
    
    spare_IX9_7 AT %IX9.7 : BOOL; // spare
	
	// --- Falownik ATV320 ---
	ATV320_stsWord_ETA3201 AT %IW16 : WORD; // status word falownika 
	ATV320_currentFrequency_RFR3202 AT %IW17 : WORD; // aktualna czestotliwość w 0.1Hz
	ATV320_axisExcessError_L4D4004 AT %IW18 : WORD; // fizyczne krańcówki podpięte pod DI4 -> wtedy w manualu tryb serwisowy i sterowanie ręczne do wyjazdu
	
END_STRUCT
END_TYPE

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

{attribute 'qualified_only'}
// HW IO mapping 
// direct adresses in structures:
VAR_GLOBAL
	di : ST_GVL_IO_DI_RAW ;
	dout : ST_GVL_IO_DO_RAW ;
END_VAR
