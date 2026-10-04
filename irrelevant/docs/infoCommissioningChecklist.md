# Checklista uruchomieniowa PLC i stacji

## Cel dokumentu

Ten plik jest praktyczna checklista do uruchomienia stacji na realnej maszynie.

Nie zastepuje oceny safety ani procedur zakladowych. Safety jest zalozone jako realizowane przez dedykowany sterownik. Ta checklista skupia sie na:

- I/O,
- pneumatyce,
- transporterach,
- windzie,
- buforach P1-P7,
- komunikacji z robotem FANUC,
- trybie tray,
- trybie box,
- oproznianiu stacji,
- diagnozie typowych objawow.

## Zasada pracy przy diagnozie

Gdy cos nie dziala, idz zawsze ta sama sciezka:

```text
fizyczny sygnal
  -> GVL_IO_RAW
    -> PRG_IO_Read / PRG_IO_Write
      -> GVL_IO
        -> PRG_Main
          -> FB
            -> wyjscie FB
              -> GVL_IO.dout
                -> fizyczne wyjscie
```

Dla komunikacji robota:

```text
GVL_Robot.robotOut
  -> FB_ModbusComm
    -> GVL_ModbusTCP.mbBuf.aRobotTxRegs
      -> Robot DI

Robot DO
  -> GVL_ModbusTCP.mbBuf.aRobotRxRegs
    -> FB_ModbusComm
      -> GVL_Robot.robotIn
```

## 1. Przygotowanie przed ruchem

- [ ] Potwierdz, ze projekt kompiluje sie w Machine Expert.
- [ ] Potwierdz, ze task `MAST` wywoluje `PRG_Main`.
- [ ] Potwierdz, ze `PRG_Main` wykonuje `PRG_IO_Read()` na poczatku i `PRG_IO_Write()` na koncu.
- [ ] Potwierdz, ze adresacja w `GVL_IO_RAW` odpowiada aktualnemu schematowi elektrycznemu.
- [ ] Potwierdz, ze fizyczne wejscia `%IX` zmieniaja sie w watchu Machine Expert.
- [ ] Potwierdz, ze fizyczne wyjscia `%QX` sa odlaczone lub bezpieczne przed pierwszym wymuszeniem.
- [ ] Potwierdz, ze niskie cisnienie `ind_low_pressure` nie blokuje `xGlobalEnable`.
- [ ] Potwierdz, ze HMI nie ustawia jednoczesnie trybu tray i box.
- [ ] Potwierdz, ze aktywny manual pauzuje sekwencery AUTO.
- [ ] Potwierdz, ze zadne faulty FB nie sa aktywne przed startem testow.

Obserwuj:

- `GVL_IO.di.ind_low_pressure`,
- `GVL_HMI.hmiStatus.xGlobalEnable`,
- `GVL_HMI.hmiStatus.xModeTray`,
- `GVL_HMI.hmiStatus.xModeBox`,
- `GVL_HMI.hmiStatus.xManualMode`,
- `GVL_HMI.hmiAlarmCount`.

## 2. Test wejsc I/O

### Pojemniki P1-P7

- [ ] Zaslon czujnik P1 i sprawdz `GVL_IO.di.ind_container_in_pos_1`.
- [ ] Zaslon czujnik P2 i sprawdz `GVL_IO.di.ind_container_in_pos_2`.
- [ ] Zaslon czujnik P3 i sprawdz `GVL_IO.di.ind_container_in_pos_3`.
- [ ] Zaslon czujnik P4 i sprawdz `GVL_IO.di.ind_container_in_pos_4`.
- [ ] Zaslon czujnik P5 i sprawdz `GVL_IO.di.ind_container_in_pos_5`.
- [ ] Zaslon czujnik P6 i sprawdz `GVL_IO.di.ind_container_in_pos_6`.
- [ ] Zaslon czujnik P7 i sprawdz `GVL_IO.di.ind_container_in_pos_7`.
- [ ] Sprawdz `GVL_IO.di.ind_elevator_emptied`.

Oczekiwane:

- `GVL_IO_RAW.di.*` zmienia sie fizycznie,
- `GVL_IO.di.*` zmienia sie po `PRG_IO_Read`,
- HMI pokazuje zgodny status P1-P7.

Jesli nie:

- sprawdz adres w `GVL_IO_RAW`,
- sprawdz przewod/czujnik,
- sprawdz polaryzacje PNP/NPN,
- sprawdz, czy `PRG_IO_Read` kopiuje wlasciwe pole.

### Przyciski operatora

- [ ] Start procesu: `ind_button_start_process`.
- [ ] Pojemnik gotowy: `ind_button_container_ready`.
- [ ] Kontynuuj: `ind_button_continue_process` albo HMI `xContiniue`.
- [ ] Oproznij stacje: `ind_button_start_emptying_process`.
- [ ] Podaj probki: `ind_button_samples`.

Oczekiwane:

- przycisk fizyczny zmienia `GVL_IO.di`,
- `Kontynuuj` generuje impuls `tpRobotContinue.Q` okolo 1 s bez resetowania faultow,
- `Podaj probki` trafia do `GVL_Robot.robotOut.cmd_samples`.

## 3. Test wyjsc bez AUTO

Wykonuj tylko w trybie manualnym i z zachowaniem procedur uruchomieniowych.

### Transportery

- [ ] Gorny transporter FWD: `ctrl_turn_on_top_conveyor`.
- [ ] Transporter windy IN: `ctrl_turn_on_elevator_conveyor_in`.
- [ ] Transporter windy OUT: `ctrl_turn_on_elevator_conveyor_out`.
- [ ] Dolny transporter FWD: `ctrl_turn_on_bottom_conveyor`.
- [ ] Dolny transporter BWD/do windy: `ctrl_turn_on_bottom_conveyor_in`.

Oczekiwane:

- `FB_Conveyor.Sts.Running = TRUE`,
- tylko jeden kierunek transportera jest aktywny naraz,
- po zmianie kierunku nie ma natychmiastowego zwarcia komend,
- HMI pokazuje prace odpowiedniego transportera.

Jesli transporter nie rusza:

- sprawdz `fbConv*.Cmd.RunFwd/RunBwd`,
- sprawdz `fbConv*.Inp.Enable`,
- sprawdz `fbConv*.Inp.SafetyOK`,
- sprawdz `fbConv*.Diag.Fault`,
- sprawdz `GVL_IO.dout`,
- sprawdz fizyczne `%QX`.

### Silowniki M1-M8

- [ ] M1 wysun/cofnij.
- [ ] M2 podnies/opusc.
- [ ] M3 podnies/opusc.
- [ ] M4 podnies/opusc.
- [ ] M5 wysun/cofnij.
- [ ] M6 wysun/cofnij.
- [ ] M7 wysun/cofnij.
- [ ] M8 wysun/cofnij.

Oczekiwane:

- komenda HMI trafia do `CmdExtend` albo `HoldUp`,
- wyjscie FB aktywuje odpowiedni zawor,
- krancowka FWD/BWD potwierdza ruch,
- FB nie przechodzi w timeout.

Jesli silownik rusza odwrotnie:

- sprawdz przewody zaworu,
- sprawdz znaczenie FWD/BWD w mapie I/O,
- sprawdz, czy krancowki nie sa zamienione.

Jesli silownik nie konczy ruchu:

- sprawdz cisnienie,
- sprawdz mechanike,
- sprawdz czujniki krancowe,
- sprawdz timeout w FB.

## 4. Test windy

### Wejscia pozycji

- [ ] `ind_elevator_in_top_pos`.
- [ ] `ind_elevator_in_intermediate_top_pos`.
- [ ] `ind_elevator_in_intermediate_bottom_pos`.
- [ ] `ind_elevator_in_bottom_pos`.
- [ ] `ind_container_in_pos_4`.

Oczekiwane:

- `elevStat.ePos` odpowiada rzeczywistej pozycji,
- `GVL_HMI.hmiStatus.xElevAtTop` i `xElevAtBottom` sa zgodne z czujnikami,
- `rElevFreq_Hz` zmienia sie przy ruchu.

### Ruch manualny

- [ ] Manual UP.
- [ ] Manual DOWN.
- [ ] Manual FAST.
- [ ] Stop po osiagnieciu pozycji gornej.
- [ ] Stop po osiagnieciu pozycji dolnej.

Oczekiwane:

- `FB_Elevator` wystawia ruch przez `GIATV.Control_ATV`,
- `elevStat.xBusy = TRUE` podczas ruchu,
- po zatrzymaniu `elevStat.xBusy = FALSE`,
- nie ma faultu VFD ani faultu windy.

### Targety AUTO

- [ ] `posTop`.
- [ ] `posBottom`.
- [ ] `posContainerEdge`.

Oczekiwane:

- `posTop` konczy na czujniku gornej pozycji,
- `posBottom` konczy na czujniku dolnej pozycji,
- `posContainerEdge` jedzie do momentu zmiany czujnika P4 zgodnie z logika `FB_Elevator`,
- `elevStat.xAtTarget = TRUE` po osiagnieciu celu.

Jesli winda nie rusza:

- sprawdz `elevCmd.eMode`,
- sprawdz `elevCmd.xAutoGo` albo `xManUp/xManDown`,
- sprawdz `elevIn.xSafetyOk`,
- sprawdz `elevIn.xDoorClosed`,
- sprawdz komunikacje ATV320,
- sprawdz `elevStat.xFault`.

## 5. Test HMI

- [ ] `xSelectModeTray` ustawia tylko `hmiStatus.xModeTray`.
- [ ] `xSelectModeBox` ustawia tylko `hmiStatus.xModeBox`.
- [ ] Oba tryby naraz daja oba statusy `FALSE`.
- [ ] `xManualMode` pauzuje aktywny sekwencer.
- [ ] `xStartAuto` dziala jak przycisk chwilowy.
- [ ] `xPauseAuto` pauzuje TraySeq/BoxSeq bez zerowania licznikow.
- [ ] `xContiniue` dziala jak fizyczny przycisk Kontynuuj.
- [ ] `xStopAuto` abortuje aktywny TraySeq/BoxSeq do `DISABLED`.
- [ ] `xEmptyStation` startuje emptying zboczem.
- [ ] `xResetFaults` kasuje fault po usunieciu przyczyny.
- [ ] `uiTraysInStack = 0` daje domyslne 8 w TraySeq.
- [ ] HMI blokuje jednoczesne FWD/BWD dla jednego elementu.

Wazne: `Kontynuuj` pochodzi z fizycznego wejscia `ind_button_continue_process` albo HMI `xContiniue`.

## 6. Test komunikacji robota

### Konfiguracja

- [ ] IP robota jest zgodne z `GVL_ModbusTCP.cfgRobot.sIpAddress`.
- [ ] Port robota to `502`.
- [ ] Unit ID jest zgodny z konfiguracja FANUC.
- [ ] Adres startowy DI/DO robota odpowiada konfiguracji Modbus.
- [ ] Machine Expert/I/O Scanner realnie odswieza `mbBuf`.

### Odczyt Robot DO

- [ ] Wymus DO[1] w robocie i sprawdz `sts_auto_mode`.
- [ ] Wymus DO[8] i sprawdz `sts_system_ready`.
- [ ] Wymus DO[10] i sprawdz `sts_fault`.
- [ ] Wymus DO[14] i sprawdz `sts_cmd_ack`.
- [ ] Wymus DO[15] i sprawdz `sts_pallet_finished`.
- [ ] Wymus DO[18] i sprawdz `sts_stack_finished`.

Obserwuj:

- `GVL_ModbusTCP.mbBuf.aRobotRxRegs[0]`,
- `GVL_ModbusTCP.mbBuf.aRobotRxRegs[1]`,
- `GVL_Robot.robotIn.*`,
- `GVL_HMI.hmiStatus.xRobotCommOk`.

### Zapis Robot DI

- [ ] W trybie tray sprawdz DI[2] = `cmd_tray_production`.
- [ ] W trybie box sprawdz DI[1] = `cmd_box_production`.
- [ ] Sprawdz DI[3] = `cmd_continue_job` po przycisku Kontynuuj.
- [ ] Sprawdz DI[4] = `cmd_stack_ready`.
- [ ] Sprawdz DI[5] = `cmd_elevator_ready`.
- [ ] Sprawdz DI[6] = `cmd_samples`.

Obserwuj:

- `GVL_Robot.robotOut.*`,
- `GVL_ModbusTCP.mbBuf.aRobotTxRegs[0]`,
- diagnostyke DI na teach pendancie FANUC.

Jesli PLC widzi `xRobotCommOk`, ale robot nie reaguje:

- sprawdz, czy `mbBuf` jest realnie powiazany z fizyczna komunikacja,
- sprawdz kolejnosc bitow w FANUC,
- sprawdz, czy DI robota sa mapowane od bitu 0 czy 1,
- sprawdz, czy uzywasz coils/discrete inputs/holding registers zgodnie z konfiguracja.

## 7. Test TopFlow P1-P3

Testuj najpierw bez robota i bez pelnego AUTO.

- [ ] Zaladuj pojemnik na P1.
- [ ] Nacisnij `Pojemnik gotowy`.
- [ ] Sprawdz wysuniecie M1.
- [ ] Sprawdz `xTopFlowAcceptPulse`.
- [ ] Sprawdz `fbTopFlow.Sts.OccP1`.
- [ ] Sprawdz przejazd P1 -> P2.
- [ ] Sprawdz przejazd P2 -> P3.
- [ ] Sprawdz, ze transporter zatrzymuje sie przed podniesieniem M2/M3/M4.
- [ ] Sprawdz `fbTopFlow.Sts.BufferFull`.
- [ ] Sprawdz zachowanie przy pelnym P1/P2/P3.

W trybie tray:

- [ ] M5 wysuwa sie przed podaniem stosu na P3.
- [ ] M5 cofa sie po dojechaniu stosu do P3.
- [ ] M4 podnosi stos po zatrzymaniu transportera.
- [ ] `StackReadyAtP3 = TRUE` dopiero po gotowej pozycji.

W trybie box:

- [ ] TopFlow moze planowac transfer `TG_ELEV`.
- [ ] `Elev_RequestFeed` z BoxSeq uruchamia karmienie P4.
- [ ] `Elev_CanAccept` jest TRUE tylko gdy winda jest u gory i P4 puste.

## 8. Test P4 i transferu na winde

- [ ] Ustaw winde na gorze.
- [ ] Upewnij sie, ze P4 jest puste.
- [ ] W trybie box zadaj transfer na P4.
- [ ] Sprawdz, ze rusza gorny transporter.
- [ ] Sprawdz, ze rusza transporter windy IN.
- [ ] Zaslon P4.
- [ ] Sprawdz, ze `xElevTransferDone` robi sie TRUE dopiero po 2 s.
- [ ] Sprawdz, ze TopFlow konczy transfer dopiero po `Elev_TransferDone`.

Obserwuj:

- `GVL_IO.di.ind_container_in_pos_4`,
- `xElevTransferDone`,
- `fbTopFlow.Inp.Elev_TransferDone`,
- `fbTopFlow.Outp.Elev_TransferActive`,
- `fbConvElev.Cmd.RunFwd`,
- `GVL_IO.dout.ctrl_turn_on_elevator_conveyor_in`.

Jesli transfer konczy sie za szybko:

- sprawdz timer `tElevTransferDone`,
- sprawdz, czy TopFlow nie uzywa surowego P4 jako konca transferu,
- sprawdz drgania czujnika P4.

Jesli transfer nigdy sie nie konczy:

- sprawdz, czy P4 jest aktywne stabilnie 2 s,
- sprawdz mapowanie `fbTopFlow.Inp.Elev_TransferDone`,
- sprawdz, czy transporter nie zatrzymuje pojemnika przed czujnikiem.

## 9. Test dolnego bufora P5-P7

- [ ] Sprawdz czujniki P5/P6/P7.
- [ ] Sprawdz `fbBottom567.Sts.Occ5`.
- [ ] Sprawdz `fbBottom567.Sts.Occ6`.
- [ ] Sprawdz `fbBottom567.Sts.Occ7`.
- [ ] Sprawdz `fbBottom567.Sts.CanAcceptFromElev`.
- [ ] Zadaj `DischargeReq`.
- [ ] Sprawdz jeden krok transportera.
- [ ] Sprawdz aktualizacje modelu `Occ5..Occ7`.
- [ ] Sprawdz zachowanie przy pelnym P5-P7.

Oczekiwane:

- `CanAcceptFromElev = TRUE`, gdy P5 moze przyjac pojemnik,
- dolny transporter FWD rusza przez `fbBottom567.Outp.ConvRun`,
- `PRG_Main` dodaje `ConvRun` do `fbConvBottom.Cmd.RunFwd`.

## 10. Test trybu tray z robotem

Warunki przed testem:

- [ ] Tryb tray wybrany jako jedyny.
- [ ] Manual wylaczony.
- [ ] Emptying wylaczony.
- [ ] Robot w AUTO.
- [ ] Robot system ready.
- [ ] Brak faultow.
- [ ] `uiTraysInStack` ustawione na znana wartosc.

Przebieg:

- [ ] Start AUTO.
- [ ] Zaladuj stos na P1.
- [ ] Potwierdz `Pojemnik gotowy`.
- [ ] Sprawdz przygotowanie P3 przez TopFlow.
- [ ] Sprawdz `cmd_tray_production`.
- [ ] Sprawdz `cmd_stack_ready`.
- [ ] Sprawdz `cmd_elevator_ready`.
- [ ] Robot potwierdza gotowosc/ack zgodnie z ustalonym handshake.
- [ ] Robot generuje `sts_pallet_finished` po jednej tacy.
- [ ] M6 wykonuje cykl.
- [ ] Winda jedzie do `posContainerEdge`.
- [ ] Licznik `uiTraysDone` rosnie.
- [ ] Robot generuje `sts_stack_finished` po calym stosie.
- [ ] P3 zostaje zwolnione przez TopFlow.
- [ ] Winda jedzie na dol.
- [ ] Transporter windy OUT i dolny FWD rozladowuja P4.
- [ ] Winda wraca na gore.
- [ ] `uiStacksDone` rosnie.

Jesli robot nie startuje:

- sprawdz `cmd_tray_production`,
- sprawdz `cmd_stack_ready`,
- sprawdz `cmd_elevator_ready`,
- sprawdz `sts_system_ready`,
- sprawdz `sts_auto_mode`,
- sprawdz mapowanie DI/DO.

Jesli M6 nie dziala:

- sprawdz `fbTraySeq.Outp.M6_Extend`,
- sprawdz `fbPosM6.HoldUp`,
- sprawdz krancowki M6,
- sprawdz `fbPosM6.Diag.Fault`.

## 11. Test trybu box z robotem

Warunki przed testem:

- [ ] Tryb box wybrany jako jedyny.
- [ ] Manual wylaczony.
- [ ] Emptying wylaczony.
- [ ] Winda u gory.
- [ ] P4 puste.
- [ ] Robot w AUTO i ready.
- [ ] Brak faultow.

Przebieg:

- [ ] Start AUTO.
- [ ] Zaladuj kuwete na P1.
- [ ] Potwierdz `Pojemnik gotowy`.
- [ ] TopFlow przyjmuje kuwete.
- [ ] BoxSeq zada `Elev_RequestFeed`.
- [ ] Gorny transporter i transporter windy IN ruszaja razem.
- [ ] P4 zaslania sie stabilnie.
- [ ] Po 2 s `xElevTransferDone = TRUE`.
- [ ] M7 wysuwa sie.
- [ ] Winda jedzie do `posContainerEdge`.
- [ ] PLC wysyla `cmd_box_production`.
- [ ] PLC wysyla `cmd_stack_ready` i `cmd_elevator_ready`.
- [ ] Robot paletyzuje kuwete.
- [ ] Robot generuje `sts_stack_finished`.
- [ ] M7 cofa sie.
- [ ] Winda jedzie na dol.
- [ ] Transporter windy OUT i dolny FWD rozladowuja kuwete.
- [ ] Winda wraca na gore.
- [ ] `uiBoxesDone` rosnie.

Jesli box zatrzymuje sie przy transferze:

- sprawdz `fbBoxSeq.Sts.State`,
- sprawdz `fbTopFlow.Inp.Elev_RequestFeed`,
- sprawdz `fbTopFlow.Inp.Elev_CanAccept`,
- sprawdz P4,
- sprawdz `xElevTransferDone`,
- sprawdz timeout transferu.

Jesli M7 zostaje wysuniety poza cyklem:

- sprawdz `xModeBox`,
- sprawdz `fbBoxSeq.Outp.AutoRunning`,
- sprawdz `fbBoxSeq.Outp.M7_Extend`,
- sprawdz manual.

## 12. Test oprozniania stacji

Warunki:

- [ ] AUTO zatrzymane albo gotowe do przerwania.
- [ ] Manual wylaczony.
- [ ] Na stacji sa testowe pojemniki na znanych pozycjach.

Przebieg:

- [ ] Nacisnij `Oproznij stacje`.
- [ ] `xEmptyRunning = TRUE`.
- [ ] TraySeq i BoxSeq dostaja `AbortAuto`.
- [ ] Stan `10 TOP_FLUSH` podaje P1-P3 na P4.
- [ ] Stan `20 ELEV_DOWN` zjezdza winda na dol.
- [ ] Stan `30 DISCHARGE` wlacza transporter windy OUT i dolny FWD.
- [ ] `ind_elevator_emptied` konczy rozladunek P4.
- [ ] Stan `40 ELEV_UP` wraca winda na gore.
- [ ] Logika wraca do `TOP_FLUSH`, jesli na gorze sa kolejne pojemniki.
- [ ] Stan `60 BOTTOM_FLUSH` oproznia P5-P7.
- [ ] Stan `50 DONE` kasuje `xEmptyRunning`.

Obserwuj:

- `uiEmptyState`,
- `xEmptyRunning`,
- `fbTopFlow.Cmd.EmptyingMode`,
- `fbTopFlow.Sts.OccP1..OccP3`,
- `GVL_IO.di.ind_container_in_pos_4`,
- `GVL_IO.di.ind_elevator_emptied`,
- `fbBottom567.Sts.Occ5..Occ7`.

Jesli emptying konczy sie za szybko:

- sprawdz model `OccP1..OccP3`,
- sprawdz czujniki P5-P7,
- sprawdz timeouty `tEmptyTO` i `tEmptyTransfer`.

## 13. Test Kontynuuj

- [ ] Wywolaj kontrolowany fault sekwencera.
- [ ] Sprawdz, ze sekwencer zapamietuje stan wznowienia.
- [ ] Usun przyczyne faultu.
- [ ] Nacisnij `xResetFaults`.
- [ ] Sprawdz `xResetAll = TRUE` tylko podczas resetu.
- [ ] Nacisnij fizyczny `Kontynuuj` albo HMI `xContiniue`.
- [ ] Sprawdz `xContinueReq` przez okolo 1 s.
- [ ] Sprawdz `ResumeAuto` aktywnego sekwencera.
- [ ] Sprawdz `GVL_Robot.robotOut.cmd_continue_job`.
- [ ] Sprawdz Robot DI[3].
- [ ] Potwierdz, ze sekwencer wraca do zapamietanego stanu po `ResumeAuto`, a nie zeruje licznikow bez potrzeby.

Jesli kontynuacja nie dziala:

- sprawdz fizyczny przycisk `ind_button_continue_process`,
- sprawdz `rtContinue.Q`,
- sprawdz `tpRobotContinue.Q`,
- sprawdz, czy sekwencer jest w stanie, ktory obsluguje Resume,
- sprawdz, czy fault zostal realnie usuniety.

## 14. Alarmy i status HMI

- [ ] Wymus fault M1 i sprawdz `xM1_Fault`.
- [ ] Wymus fault transportera i sprawdz `xConv*_Fault`.
- [ ] Wymus fault windy i sprawdz `xElev_Fault`.
- [ ] Wymus fault robota i sprawdz `xRobot_Fault`.
- [ ] Odłącz/zasymuluj brak komunikacji robota i sprawdz `xRobot_CommLost`.
- [ ] Sprawdz, czy `hmiAlarmCount` rosnie o oczekiwana liczbe.
- [ ] Sprawdz lampy: zielona, zolta, czerwona.
- [ ] Sprawdz buzzer.
- [ ] Sprawdz reset faultow po usunieciu przyczyny.

Uwaga:

- `xRobot_CommLost` i `xRobot_MbLost` sa obecnie liczone z tego samego warunku,
- `xElev_CommLost` jest stale `FALSE`,
- `xAckAlarms` jest zadeklarowane, ale nieuzywane w `PRG_Main`.

## 15. Typowe objawy i szybka diagnoza

| Objaw | Najpierw sprawdz |
|---|---|
| AUTO nie startuje | tryb tray/box, manual, emptying, `xGlobalEnable`, alarmy |
| Oba tryby nieaktywne | czy HMI nie wybralo tray i box jednoczesnie |
| M1 nie wysuwa po zaladunku | P1, przycisk gotowosci, `xLoadAcceptedPending`, `fbPosM1.Diag` |
| TopFlow nie przyjmuje P1 | `xTopFlowAcceptPulse`, `fbTopFlow.Cmd.Pos1AcceptedPulse` |
| Gorny transporter nie rusza | `fbTopFlow.Outp.TopConveyor_Run`, M1 AtRet, `fbConvTop.Diag` |
| Stoper podnosi za wczesnie | stan TopFlow, czujnik pozycji, stop transportera |
| Stos nie jest gotowy na P3 | P3, M4, M5, `StackReadyAtP3` |
| Transfer box nie konczy sie | P4 stabilne 2 s, `xElevTransferDone`, TopFlow TG_ELEV |
| Winda nie jedzie do krawedzi | `elevIn.xContainerInPos4`, target `posContainerEdge`, `elevStat.xFault` |
| Robot nie zaczyna pracy | DI robota, `cmd_stack_ready`, `cmd_elevator_ready`, `sts_system_ready` |
| Tray nie liczy tacki | impuls `sts_pallet_finished`, cykl Modbus, `fbTraySeq.Sts.State` |
| Box nie konczy cyklu | impuls `sts_stack_finished`, `fbBoxSeq.Sts.State` |
| Rozladunek nie konczy sie | `ind_elevator_emptied`, P5, BottomAccumulator |
| Dolny bufor nie przyjmuje | `CanAcceptFromElev`, `Occ5`, czujnik P5 |
| Kontynuuj nie wznawia | `xContinueReq`, `ResumeAuto`, stan faultu, czy fault byl osobno zresetowany |
| Alarm komunikacji robota mylacy | dublowanie `xRobot_CommLost` i `xRobot_MbLost` |

## 16. Minimalny zapis z uruchomienia

Dla kazdego testu warto zapisac:

- data i wersja programu,
- tryb testu: manual/tray/box/emptying,
- pozycje pojemnikow przed startem,
- aktywne alarmy przed startem,
- obserwowane stany sekwencerow,
- sygnaly robota DI/DO,
- wynik testu,
- opis problemu, jesli wystapil,
- decyzja: poprawka kodu, poprawka elektryki, poprawka mechaniki, poprawka robota.

## 17. Kolejnosc rekomendowana

Najbezpieczniejsza kolejnosc uruchamiania:

1. I/O wejsc bez ruchu.
2. Wyjscia i manual bez pojemnikow.
3. Silowniki M1-M8.
4. Transportery bez pojemnikow.
5. Winda bez pojemnikow.
6. Czujniki P1-P7 z pojemnikiem recznie.
7. TopFlow P1-P3 bez robota.
8. Transfer box na P4 bez paletyzacji.
9. Dolny bufor P5-P7.
10. Komunikacja Modbus robota.
11. Tray z robotem na wolnym, kontrolowanym cyklu.
12. Box z robotem na wolnym, kontrolowanym cyklu.
13. Oproznianie stacji.
14. Kontynuuj po kontrolowanej przerwie/fault.
15. Test dluzej pracy AUTO.

## Podsumowanie

Najwazniejsze sygnaly do stalego watcha podczas pierwszych testow:

```text
GVL_HMI.hmiStatus.xModeTray
GVL_HMI.hmiStatus.xModeBox
GVL_HMI.hmiStatus.xManualMode
GVL_HMI.hmiStatus.xGlobalEnable
GVL_HMI.hmiAlarmCount
fbTopFlow.Sts.State
fbTraySeq.Sts.State
fbBoxSeq.Sts.State
fbBottom567.Sts.State
elevStat.eState
GVL_Robot.robotOut
GVL_Robot.robotIn
GVL_IO.di.ind_container_in_pos_1..7
GVL_IO.di.ind_container_in_pos_4
GVL_IO.di.ind_elevator_emptied
```

Taka obserwacja daje szybki obraz, czy problem jest po stronie I/O, procesu, windy, robota czy dolnego bufora.
