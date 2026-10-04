# PRG_IO_Read / PRG_IO_Write - warstwa wejsc i wyjsc

## Rola funkcjonalna

Warstwa I/O jest granica miedzy fizycznymi adresami sterownika a reszta programu PLC.

Projekt rozdziela ja na dwie globalne przestrzenie:

- `GVL_IO_RAW` - bezposrednie mapowanie adresow `%IX`, `%QX`, `%IW`,
- `GVL_IO` - logiczna, adresowo niezalezna struktura uzywana przez program.

Dwa programy pomocnicze wykonuja kopiowanie:

- `PRG_IO_Read` - kopiuje wejscia z `GVL_IO_RAW.di` do `GVL_IO.di`,
- `PRG_IO_Write` - kopiuje wyjscia z `GVL_IO.dout` do `GVL_IO_RAW.dout`.

Schemat:

```text
Fizyczne wejscia PLC
  -> GVL_IO_RAW.di
    -> PRG_IO_Read()
      -> GVL_IO.di
        -> PRG_Main / FB
          -> GVL_IO.dout
            -> PRG_IO_Write()
              -> GVL_IO_RAW.dout
                -> fizyczne wyjscia PLC
```

`PRG_Main` wywoluje `PRG_IO_Read()` na poczatku skanu, a `PRG_IO_Write()` na samym koncu.

## GVL_IO_RAW

`GVL_IO_RAW` zawiera struktury z fizycznymi adresami.

### Wejscia RAW

Typ `ST_GVL_IO_DI_RAW` deklaruje wejscia:

```iecst
di : ST_GVL_IO_DI_RAW;
```

Kazde pole ma przypisany adres, np.:

```iecst
ind_container_in_pos_4 AT %IX6.4 : BOOL;
ATV320_currentFrequency_RFR3202 AT %IW17 : WORD;
```

To jest jedyne miejsce, gdzie logika projektu powinna zalezec od adresacji sprzetowej.

### Wyjscia RAW

Typ `ST_GVL_IO_DO_RAW` deklaruje wyjscia:

```iecst
dout : ST_GVL_IO_DO_RAW;
```

Przyklad:

```iecst
ctrl_turn_on_top_conveyor AT %QX0.6 : BOOL;
ctrl_move_M7_actuator_forward AT %QX5.4 : BOOL;
```

Zmiana fizycznego adresu powinna wymagac zmiany tylko w `GVL_IO_RAW`, o ile nazwa logiczna sygnalu sie nie zmienia.

## GVL_IO

`GVL_IO` zawiera struktury bez adresow:

```iecst
di   : ST_IO_DI;
dout : ST_IO_DO;
```

To sa sygnaly uzywane przez:

- `PRG_Main`,
- bloki wykonawcze,
- sekwencery,
- status HMI,
- alarmy.

Dzieki tej warstwie program nie musi w kazdym miejscu znac adresow `%IX` i `%QX`.

## PRG_IO_Read

`PRG_IO_Read` wykonuje proste kopiowanie:

```iecst
GVL_IO.di.ind_container_in_pos_4 := GVL_IO_RAW.di.ind_container_in_pos_4;
```

Nie ma tu:

- filtracji,
- debounce,
- obslugi zboczy,
- logiki bezpieczenstwa,
- interpretacji procesu.

To wazne: jezeli sygnal ma byc filtrowany albo obslugiwany zboczem, dzieje sie to pozniej w `PRG_Main` albo w FB.

Przyklady:

- przycisk `Kontynuuj` jest tylko kopiowany w `PRG_IO_Read`, a zbocze i impuls 1 s robi `PRG_Main`,
- czujnik P4 jest tylko kopiowany w `PRG_IO_Read`, a timer 2 s dla `Elev_TransferDone` robi `PRG_Main`,
- krancowki silownikow sa tylko kopiowane, a timeouty i diagnostyka robi `FB_Cyl2Pos` albo `FB_StopperPair`.

## PRG_IO_Write

`PRG_IO_Write` wykonuje kopiowanie w druga strone:

```iecst
GVL_IO_RAW.dout.ctrl_turn_on_top_conveyor := GVL_IO.dout.ctrl_turn_on_top_conveyor;
```

Program zaklada, ze wszystkie decyzje zostaly juz policzone w `PRG_Main` i FB wykonawczych.

`PRG_IO_Write` nie rozstrzyga konfliktow, np. FWD/BWD. Konflikty sa blokowane wczesniej:

- transportery przez `FB_Conveyor`,
- silowniki przez `FB_Cyl2Pos` i `FB_StopperPair`,
- logika wyboru trybow przez `PRG_Main`.

## Wejscia - grupy funkcjonalne

### Modul zaladunku i P1

| Sygnal `GVL_IO.di` | RAW | Znaczenie |
|---|---|---|
| `ind_M1_1_fwd` | `%IX0.0` | M1.1 wysuniety |
| `ind_M1_2_fwd` | `%IX0.1` | M1.2 wysuniety |
| `ind_M1_1_bwd` | `%IX0.2` | M1.1 cofniety |
| `ind_M1_2_bwd` | `%IX0.3` | M1.2 cofniety |
| `ind_M2_1_fwd` | `%IX0.4` | M2.1 wysuniety |
| `ind_M2_2_fwd` | `%IX0.5` | M2.2 wysuniety |
| `ind_M2_1_bwd` | `%IX0.6` | M2.1 cofniety |
| `ind_M2_2_bwd` | `%IX0.7` | M2.2 cofniety |
| `ind_container_in_pos_1` | `%IX1.0` | pojemnik na P1 |

Te sygnaly sa uzywane przez `PRG_Main`, `FB_Cyl2Pos`, `FB_StopperPair` i `FB_TopFlowManager`.

### Gorny bufor P2-P3

| Sygnal `GVL_IO.di` | RAW | Znaczenie |
|---|---|---|
| `ind_container_in_pos_2` | `%IX1.1` | pojemnik na P2 |
| `ind_M3_1_fwd` | `%IX1.2` | M3.1 wysuniety |
| `ind_M3_2_fwd` | `%IX1.3` | M3.2 wysuniety |
| `ind_M3_1_bwd` | `%IX1.4` | M3.1 cofniety |
| `ind_M3_2_bwd` | `%IX1.5` | M3.2 cofniety |
| `ind_M4_1_fwd` | `%IX4.0` | M4.1 wysuniety |
| `ind_M4_2_fwd` | `%IX4.1` | M4.2 wysuniety |
| `ind_M4_1_bwd` | `%IX4.2` | M4.1 cofniety |
| `ind_M4_2_bwd` | `%IX4.3` | M4.2 cofniety |
| `ind_container_in_pos_3` | `%IX4.4` | pojemnik na P3 |
| `ind_M5_1_fwd` | `%IX4.6` | M5.1 wysuniety |
| `ind_M5_2_fwd` | `%IX4.7` | M5.2 wysuniety |
| `ind_M5_1_bwd` | `%IX5.0` | M5.1 cofniety |
| `ind_M5_2_bwd` | `%IX5.1` | M5.2 cofniety |

P2/P3, M3/M4/M5 sa kluczowe dla `FB_TopFlowManager`.

### Winda i P4

| Sygnal `GVL_IO.di` | RAW | Znaczenie |
|---|---|---|
| `ind_M6_1_fwd` | `%IX5.2` | M6.1 wysuniety |
| `ind_M6_2_fwd` | `%IX5.3` | M6.2 wysuniety |
| `ind_M6_1_bwd` | `%IX5.4` | M6.1 cofniety |
| `ind_M6_2_bwd` | `%IX5.5` | M6.2 cofniety |
| `ind_M7_fwd` | `%IX5.6` | M7 wysuniety |
| `ind_M7_bwd` | `%IX5.7` | M7 cofniety |
| `ind_elevator_in_top_pos` | `%IX6.0` | winda w gornej pozycji |
| `ind_elevator_in_intermediate_top_pos` | `%IX6.1` | winda blisko gory |
| `ind_elevator_in_intermediate_bottom_pos` | `%IX6.2` | winda blisko dolu |
| `ind_elevator_in_bottom_pos` | `%IX6.3` | winda w dolnej pozycji |
| `ind_container_in_pos_4` | `%IX6.4` | pojemnik na P4 |
| `ind_elevator_emptied` | `%IX6.6` | pojemnik opuscil winde |

P4 jest uzywane w kilku miejscach:

- `FB_Elevator` dostaje `xContainerInPos4`,
- `FB_TopFlowManager` dostaje `sPos4_raw`,
- `PRG_Main` filtruje P4 timerem 2 s do `Elev_TransferDone`,
- `FB_TraySequencer` i `FB_BoxSequencer` dostaja surowy stan P4.

### Dolny bufor P5-P7

| Sygnal `GVL_IO.di` | RAW | Znaczenie |
|---|---|---|
| `ind_container_in_pos_5` | `%IX6.7` | pojemnik na P5 |
| `ind_container_in_pos_6` | `%IX7.0` | pojemnik na P6 |
| `ind_container_in_pos_7` | `%IX7.1` | pojemnik na P7 |

Te sygnaly sa podstawowym feedbackiem dla `FB_BottomAccumulator_567`.

### Magazyn przekladek

| Sygnal `GVL_IO.di` | RAW | Znaczenie |
|---|---|---|
| `ind_M8_fwd` | `%IX7.4` | M8 wysuniety |
| `ind_M8_bwd` | `%IX7.5` | M8 cofniety |
| `ind_low_level_of_spacers` | `%IX7.6` | niski poziom przekladek |
| `ind_spacer_storage_empty` | `%IX7.7` | magazyn przekladek pusty |

M8 jest aktualnie obslugiwany jako zwykly `FB_Cyl2Pos`. Sygnały poziomu przekladek sa dostepne w `GVL_IO.di`, ale ich dalsza logika procesowa nie jest rozbudowana w glownych sekwencerach.

### Przyciski operatora

| Sygnal `GVL_IO.di` | RAW | Znaczenie |
|---|---|---|
| `ind_button_open_close_spacer_storage` | `%IX8.2` | przycisk magazynu przekladek |
| `ind_button_open_close_robot_cell_doors` | `%IX8.3` | przycisk drzwi celi |
| `ind_button_samples` | `%IX8.4` | podaj probki |
| `ind_button_continue_process` | `%IX8.5` | kontynuuj proces |
| `ind_button_start_process` | `%IX8.6` | start procesu |
| `ind_button_container_ready` | `%IX8.7` | pojemnik gotowy |
| `ind_button_start_emptying_process` | `%IX9.0` | oproznij stacje |

Wazne zachowania:

- `Start` trafia do `StartAuto` aktywnego sekwencera,
- `Pojemnik gotowy` tworzy impuls akceptacji P1 po dojsciu M1,
- `Kontynuuj` tworzy impuls 1 s do wznowienia AUTO i robota; reset faultow jest osobny,
- `Podaj probki` jest wysylane do robota jako `cmd_samples`,
- `Oproznij stacje` startuje lokalna maszyne stanow emptying w `PRG_Main`.

### Safety, status i robot

| Sygnal `GVL_IO.di` | RAW | Znaczenie |
|---|---|---|
| `ind_low_pressure` | `%IX9.1` | niskie cisnienie pneumatyki |
| `ind_robot_cell_doors_closed` | `%IX9.2` | drzwi celi zamkniete |
| `ind_robot_cell_doors_locked` | `%IX9.3` | drzwi celi zaryglowane |
| `ind_spacer_storage_robot_side_doors_opening_permission` | `%IX9.4` | pozwolenie otwarcia od strony robota |
| `ind_spacer_storage_operator_side_doors_opening_permission` | `%IX9.5` | pozwolenie otwarcia od strony operatora |
| `ind_robot_gripper_vacuum_ok` | `%IX9.6` | proznia chwytaka OK |

`ind_low_pressure` jest uzywane do blokowania `xGlobalEnable`. Pozostale sygnaly sa dostepne dla statusow/HMI lub przyszlej logiki.

### Diagnostyka ATV320

| Sygnal `GVL_IO.di` | RAW | Znaczenie |
|---|---|---|
| `ATV320_stsWord` | `%IW16` | slowo statusowe falownika |
| `ATV320_currentFreq` | `%IW17` | aktualna czestotliwosc w 0.1 Hz |
| `ATV320_axisExcess` | `%IW18` | diagnostyka osi/krańcowek |

Komentarz w kodzie zaznacza, ze glowne sterowanie ATV320 jest wykonywane przez `GIATV.Control_ATV` w `FB_Elevator`. `PRG_IO_Write` nie zapisuje starych slow procesowych CMD/LFR/FST.

## Wyjscia - grupy funkcjonalne

### LED przyciskow

| Sygnal `GVL_IO.dout` | RAW | Znaczenie |
|---|---|---|
| `ctrl_LED_button_open_close_spacer_storage` | `%QX0.0` | LED przycisku magazynu |
| `ctrl_LED_button_samples` | `%QX0.1` | LED przycisku probek |
| `ctrl_LED_button_continue_process` | `%QX0.2` | LED kontynuacji |
| `ctrl_LED_button_start_process` | `%QX0.3` | LED startu |
| `ctrl_LED_button_container_ready` | `%QX0.4` | LED pojemnik gotowy |
| `ctrl_LED_button_start_emptying_process` | `%QX0.5` | LED oprozniania |

W `PRG_Main` aktywnie ustawiane sa m.in. LED startu, pojemnika gotowego, kontynuacji i oprozniania.

### Transportery

| Sygnal `GVL_IO.dout` | RAW | Znaczenie |
|---|---|---|
| `ctrl_turn_on_top_conveyor` | `%QX0.6` | gorny transporter FWD |
| `ctrl_turn_on_bottom_conveyor` | `%QX0.7` | dolny transporter FWD do wyjscia |
| `ctrl_turn_on_elevator_conveyor_in` | `%QX1.0` | transporter windy IN do robota |
| `ctrl_turn_on_elevator_conveyor_out` | `%QX1.1` | transporter windy OUT do rozladunku |
| `ctrl_turn_on_bottom_conveyor_in` | `%QX7.7` | dolny transporter BWD do windy |

Komendy tych wyjsc pochodza z `FB_Conveyor`, a nie bezposrednio z sekwencerow.

### Silowniki M1-M8

| Sygnal `GVL_IO.dout` | RAW | Znaczenie |
|---|---|---|
| `ctrl_move_M1_actuator_forward` | `%QX4.0` | M1 wysun |
| `ctrl_move_M1_actuator_backward` | `%QX4.1` | M1 cofnij |
| `ctrl_move_M2_actuator_forward` | `%QX4.2` | M2 wysun/podnies |
| `ctrl_move_M2_actuator_backward` | `%QX4.3` | M2 cofnij/opusc |
| `ctrl_move_M3_actuator_forward` | `%QX4.4` | M3 wysun/podnies |
| `ctrl_move_M3_actuator_backward` | `%QX4.5` | M3 cofnij/opusc |
| `ctrl_move_M4_actuator_forward` | `%QX4.6` | M4 wysun/podnies |
| `ctrl_move_M4_actuator_backward` | `%QX4.7` | M4 cofnij/opusc |
| `ctrl_move_M5_actuator_forward` | `%QX5.0` | M5 wysun |
| `ctrl_move_M5_actuator_backward` | `%QX5.1` | M5 cofnij |
| `ctrl_move_M6_actuator_forward` | `%QX5.2` | M6 wysun |
| `ctrl_move_M6_actuator_backward` | `%QX5.3` | M6 cofnij |
| `ctrl_move_M7_actuator_forward` | `%QX5.4` | M7 wysun |
| `ctrl_move_M7_actuator_backward` | `%QX5.5` | M7 cofnij |
| `ctrl_move_M8_actuator_forward` | `%QX5.6` | M8 wysun |
| `ctrl_move_M8_actuator_backward` | `%QX5.7` | M8 cofnij |

Wyjscia sa ustawiane po wywolaniu odpowiednich FB:

- `FB_Cyl2Pos` dla M1, M7, M8,
- `FB_StopperPair` dla M2, M3, M4, M5, M6.

### Zamki, sygnalizacja i robot gripper

| Sygnal `GVL_IO.dout` | RAW | Znaczenie |
|---|---|---|
| `ctrl_open_spacer_storage_robot_side_lock` | `%QX6.4` | odryglowanie magazynu od strony robota |
| `ctrl_open_spacer_storage_operator_side_lock` | `%QX6.5` | odryglowanie magazynu od strony operatora |
| `ctrl_open_robot_cell_doors_lock` | `%QX6.6` | odryglowanie drzwi celi |
| `ctrl_reset_robot_cell_doors` | `%QX6.7` | RST klamki Euchner drzwi celi |
| `ctrl_robot_cell_doors_LED_open_close` | `%QX7.0` | LED otworz/zamknij drzwi |
| `ctrl_turn_on_buzzer` | `%QX7.1` | buzzer |
| `ctrl_turn_on_light_green` | `%QX7.2` | lampa zielona |
| `ctrl_turn_on_light_yellow` | `%QX7.3` | lampa zolta |
| `ctrl_turn_on_light_red` | `%QX7.4` | lampa czerwona |
| `ctrl_turn_on_robot_gripper_vacuum` | `%QX7.5` | proznia chwytaka |
| `ctrl_turn_on_robot_gripper_blow_off` | `%QX7.6` | przedmuch chwytaka |

Lampy i buzzer sa skladane w `PRG_Main`. Czesci zwiazane z drzwiami, magazynem i chwytakiem sa dostepne w mapie I/O, ale nie sa glownym elementem aktualnej automatyki tray/box.

## Zaleznosc z PRG_Main

`PRG_Main` korzysta z warstwy I/O w taki sposob:

```text
PRG_IO_Read()
  -> odczyt HMI i wejsc fizycznych
  -> mapowanie GVL_IO.di do FB
  -> wywolanie sekwencerow i FB wykonawczych
  -> zapis wynikow do GVL_IO.dout
  -> PRG_IO_Write()
```

Przykladowa sciezka wejscia:

```text
%IX6.4
  -> GVL_IO_RAW.di.ind_container_in_pos_4
    -> PRG_IO_Read
      -> GVL_IO.di.ind_container_in_pos_4
        -> PRG_Main
          -> FB_TopFlowManager / FB_Elevator / FB_TraySequencer / FB_BoxSequencer
```

Przykladowa sciezka wyjscia:

```text
FB_BoxSequencer.Outp.M7_Extend
  -> PRG_Main
    -> fbPosM7.CmdExtend
      -> fbPosM7()
        -> GVL_IO.dout.ctrl_move_M7_actuator_forward
          -> PRG_IO_Write
            -> GVL_IO_RAW.dout.ctrl_move_M7_actuator_forward
              -> %QX5.4
```

## Na co zwrocic uwage przy uruchomieniu

- `PRG_IO_Read` nie filtruje wejsc - drgania przyciskow i czujnikow trzeba diagnozowac w logice wyzszej warstwy albo sprzetowo.
- `PRG_IO_Write` nie blokuje konfliktow - jezeli na wyjsciu pojawia sie cos dziwnego, sprawdz najpierw FB wykonawczy.
- P4 jest uzywane rownoczesnie jako surowy czujnik procesu i jako filtrowane `Elev_TransferDone`.
- `ind_low_pressure = TRUE` blokuje `xGlobalEnable`.
- Nazwy `fwd/bwd` dla M2-M4 oznaczaja fizycznie podniesienie/opuszczenie stopera, a nie kierunek transportera.
- Top transporter ma tylko jedno wyjscie fizyczne FWD.
- Transporter windy i dolny transporter maja dwa kierunki.
- Sterowanie pionowym ruchem windy nie wychodzi z `PRG_IO_Write`, tylko z `FB_Elevator` przez `GIATV.Control_ATV`.
- Sygnaly drzwi, magazynu przekladek i chwytaka sa zmapowane, ale czesc z nich moze nie miec jeszcze rozbudowanej logiki procesowej.

## Jak diagnozowac I/O

Najprostsza metoda:

1. Sprawdz fizyczny adres w `GVL_IO_RAW`.
2. Sprawdz, czy `PRG_IO_Read` albo `PRG_IO_Write` kopiuje go do odpowiedniego pola.
3. Sprawdz pole logiczne w `GVL_IO`.
4. Sprawdz, ktory FB lub fragment `PRG_Main` uzywa tego pola.
5. Dla wyjsc sprawdz, czy FB wykonawczy faktycznie wystawia `Outp`.
6. Dopiero potem sprawdz fizyczne wyjscie `%QX`.

Taka kolejnosc zwykle szybko pokazuje, czy problem jest w okablowaniu/adresacji, mapowaniu, logice FB, czy w samym wyjsciu wykonawczym.
