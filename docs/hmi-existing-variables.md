# Istniejące zmienne HMI — inwentaryzacja do migracji

Data: 2026-10-04. Źródło: [GVL_HMI.st](../GVLs/GVL_HMI.st); odczyty i przypisania: [PRG_Main.st](../POUs/PRG_Main.st). Wykaz opisuje odziedziczony kod, nie ukończoną adaptację Krauss.

**To baza migracji. Nie potwierdza eksportu symboli, komunikacji z panelem ani gotowości komend do wdrożenia na nowej maszynie.** Brakuje natywnego projektu PLC/HMI i konfiguracji Symbol Configuration. Docelowy kontrakt i ekrany opisuje [mapa Vijeo](hmi-vijeo-map.md), a kolejność prac [human-instructions.md](../human-instructions.md).

R = panel odczytuje wartość PLC; W = panel zapisuje żądanie/nastawę. To kierunek funkcjonalny, nie potwierdzenie uprawnień drivera. „Brak obsługi” oznacza deklarację bez czynnego odbiorcy lub producenta. Typy są dokładnymi typami IEC; import do konkretnego drivera wymaga potwierdzenia, zwłaszcza INT ze znakiem, REAL i długości STRING.

Zakres: **144 statusy + 37 komend/nastaw + 26 pól alarmowych + 1 licznik = 208 liści runtime**; ponadto osobno stała MAX_ALARMS. Każdy symbol ma własny wiersz.

## 1. Komendy i nastawy — 37 pól

PLC nie kasuje żadnego pola hmiCmd. Nie zakładać automatycznego resetu przycisku przez sterownik. Jog wymaga poprawnego zwolnienia oraz reakcji PLC na utratę łączności; samo zerowanie przy opuszczaniu ekranu nie pokrywa zaniku komunikacji. Obecna GVL nie deklaruje retencji tych nastaw.

| Dokładna ścieżka | Typ | Kierunek | Ekran / kontrolka | Bieżące działanie i ograniczenie |
|---|---|---|---|---|
| `GVL_HMI.hmiCmd.xSelectModeTray` | `BOOL` | W | Zlecenie / Blistry | Poziom: wybór tacek AND NOT wybór pojemników; bez blokady zlecenia. Zmiana może abortować sekwencer. PRG_Main:188. |
| `GVL_HMI.hmiCmd.xSelectModeBox` | `BOOL` | W | Zlecenie / Pojemniki | Poziom: wybór pojemników AND NOT wybór tacek. Oba wybory TRUE lub FALSE wyłączają oba tryby. PRG_Main:188. |
| `GVL_HMI.hmiCmd.xManualMode` | `BOOL` | W | HOME / Auto–Manual | TRUE = Manual, FALSE = Auto; stara pauza sekwencerów. Nie nowy potwierdzany wniosek zmiany trybu. PRG_Main:190. |
| `GVL_HMI.hmiCmd.xStartAuto` | `BOOL` | W | Stary Start automatu | OR z fizycznym Start do StartAuto sekwencerów. Nie jest Startem zlecenia. PRG_Main:625. |
| `GVL_HMI.hmiCmd.xStopAuto` | `BOOL` | W | Stary Stop — do migracji | AbortAuto obu sekwencerów, przerwanie opróżniania i odzyskanie transferu. Nie nowy Stop po cyklu. PRG_Main:322. |
| `GVL_HMI.hmiCmd.xContiniue` | `BOOL` | W | Stare Kontynuuj | Dokładna pisownia zawiera literówkę. Zbocze: ResumeAuto i żądanie robota do ACK; nie nowy Start. PRG_Main:293. |
| `GVL_HMI.hmiCmd.xPauseAuto` | `BOOL` | W | Stara Pauza | Poziom PauseAuto; nie uzgodniony Stop po rozpoczętych operacjach. PRG_Main:634. |
| `GVL_HMI.hmiCmd.xEmptyStation` | `BOOL` | W | Stare Opróżnij stację | Zbocze uruchamia pełne opróżnianie i abortuje sekwencje; nie nowy Koniec zlecenia. PRG_Main:290. |
| `GVL_HMI.hmiCmd.xResetFaults` | `BOOL` | W | HOME / Reset błędów | Do xResetAll. Utrzymane inne żądania mogą zadziałać po resecie; wymagane docelowe oddzielenie wznowienia. PRG_Main:167. |
| `GVL_HMI.hmiCmd.xAckAlarms` | `BOOL` | W / brak obsługi | Alarmy / ACK — nie działa | Brak odczytu w aktywnych źródłach; samo podłączenie przycisku nie daje ACK. |
| `GVL_HMI.hmiCmd.xElevUp` | `BOOL` | W | ST.2 / jog Góra | Poziom xManUp w Manual poza opróżnianiem; zwolnienie wyłącza żądanie. Brak watchdogu HMI. PRG_Main:191. |
| `GVL_HMI.hmiCmd.xElevDown` | `BOOL` | W | ST.2 / jog Dół | Poziom xManDown w Manual poza opróżnianiem; zwolnienie wyłącza żądanie. PRG_Main:192. |
| `GVL_HMI.hmiCmd.xElevFast` | `BOOL` | W | ST.2 / szybki jog | Wybór szybkiej prędkości w Manual; sam nie inicjuje ruchu. PRG_Main:193. |
| `GVL_HMI.hmiCmd.xConvTopFwd` | `BOOL` | W | ST.1 / jog do windy | RunFwd górnej taśmy w Manual. Brak osobnego pola jog wstecz górnej taśmy. PRG_Main:194. |
| `GVL_HMI.hmiCmd.xConvElevFwd` | `BOOL` | W | ST.2 / jog taśmy do robota | RunFwd taśmy windy; koordynacja rozładunku może przejąć sterowanie. PRG_Main:195. |
| `GVL_HMI.hmiCmd.xConvElevBwd` | `BOOL` | W | ST.2 / jog do rozładunku | RunBwd; oba kierunki TRUE powodują błąd transportera. PRG_Main:196. |
| `GVL_HMI.hmiCmd.xConvBottomFwd` | `BOOL` | W | ST.3 / jog do operatora | RunFwd; BottomAccumulator ma możliwy priorytet także w Manual. PRG_Main:197. |
| `GVL_HMI.hmiCmd.xConvBottomBwd` | `BOOL` | W | ST.3 / jog do windy | RunBwd; nie funkcja pojedynczego wydania stosu. PRG_Main:198. |
| `GVL_HMI.hmiCmd.xM1Fwd` | `BOOL` | W | ST.1 / pozycjoner załadunku / Fwd | Zatrzask celu: ustawia fbPosM1.HoldUp := TRUE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:199. |
| `GVL_HMI.hmiCmd.xM1Bwd` | `BOOL` | W | ST.1 / pozycjoner załadunku / Bwd | Zatrzask celu: ustawia fbPosM1.HoldUp := FALSE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:200. |
| `GVL_HMI.hmiCmd.xM2Fwd` | `BOOL` | W | ST.1 / podnoszenie P1 / Fwd | Zatrzask celu: ustawia fbStopM2.HoldUp := TRUE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:201. |
| `GVL_HMI.hmiCmd.xM2Bwd` | `BOOL` | W | ST.1 / podnoszenie P1 / Bwd | Zatrzask celu: ustawia fbStopM2.HoldUp := FALSE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:202. |
| `GVL_HMI.hmiCmd.xM3Fwd` | `BOOL` | W | ST.1 / podnoszenie P2 / Fwd | Zatrzask celu: ustawia fbStopM3.HoldUp := TRUE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:203. |
| `GVL_HMI.hmiCmd.xM3Bwd` | `BOOL` | W | ST.1 / podnoszenie P2 / Bwd | Zatrzask celu: ustawia fbStopM3.HoldUp := FALSE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:204. |
| `GVL_HMI.hmiCmd.xM4Fwd` | `BOOL` | W | ST.1 / podnoszenie P3 / Fwd | Zatrzask celu: ustawia fbStopM4.HoldUp := TRUE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:205. |
| `GVL_HMI.hmiCmd.xM4Bwd` | `BOOL` | W | ST.1 / podnoszenie P3 / Bwd | Zatrzask celu: ustawia fbStopM4.HoldUp := FALSE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:206. |
| `GVL_HMI.hmiCmd.xM5Fwd` | `BOOL` | W | ST.1 / pozycjoner P3 / Fwd | Zatrzask celu: ustawia fbPosM5.HoldUp := TRUE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:207. |
| `GVL_HMI.hmiCmd.xM5Bwd` | `BOOL` | W | ST.1 / pozycjoner P3 / Bwd | Zatrzask celu: ustawia fbPosM5.HoldUp := FALSE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:208. |
| `GVL_HMI.hmiCmd.xM6Fwd` | `BOOL` | W | ST.2 / para pozycjonerów blistrów / Fwd | Zatrzask celu: ustawia fbPosM6.HoldUp := TRUE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:209. |
| `GVL_HMI.hmiCmd.xM6Bwd` | `BOOL` | W | ST.2 / para pozycjonerów blistrów / Bwd | Zatrzask celu: ustawia fbPosM6.HoldUp := FALSE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:210. |
| `GVL_HMI.hmiCmd.xM7Fwd` | `BOOL` | W | ST.2 / pozycjoner pojemnika / Fwd | Zatrzask celu: ustawia fbPosM7.HoldUp := TRUE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:211. |
| `GVL_HMI.hmiCmd.xM7Bwd` | `BOOL` | W | ST.2 / pozycjoner pojemnika / Bwd | Zatrzask celu: ustawia fbPosM7.HoldUp := FALSE. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:212. |
| `GVL_HMI.hmiCmd.xM8Fwd` | `BOOL` | W | ST.4 / stara osłona magazynu / Fwd | Zatrzask celu: otwiera osłonę przez xStorageManRobotOpen. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:213. |
| `GVL_HMI.hmiCmd.xM8Bwd` | `BOOL` | W | ST.4 / stara osłona magazynu / Bwd | Zatrzask celu: zamyka osłonę przez xStorageManRobotOpen. Puszczenie nie zatrzymuje ruchu; oba kierunki TRUE zachowują cel. Potrzebne nowe blokady PLC. PRG_Main:214. |
| `GVL_HMI.hmiCmd.uiTraysInStack` | `UINT` | W | Zlecenie / liczba blistrów | >0 kopiowane co skan do Cfg; 0 daje 8. Brak blokady edycji podczas zlecenia. PRG_Main:636. |
| `GVL_HMI.hmiCmd.rElevSpeedFast_Hz` | `REAL` | W | ST.2 / szybka prędkość [Hz] | >0 stosowane, <=0 daje 15 Hz. Komentarz GVL o 40 Hz jest nieaktualny. Limit zadania w FB: 50 Hz. PRG_Main:537. |
| `GVL_HMI.hmiCmd.rElevSpeedSlow_Hz` | `REAL` | W | ST.2 / wolna prędkość [Hz] | >0 stosowane, <=0 daje 5 Hz. Komentarz GVL o 15 Hz jest nieaktualny; brak walidacji relacji szybka/wolna. PRG_Main:543. |

## 2. Statusy — 144 pola tylko do odczytu

Wszystkie statusy są przypisywane przez PRG_Main. W kolumnie źródła podano rzeczywistą prawą stronę przypisania i numer linii. Lokalne nazwy FB/zmiennych należą do PRG_Main. Nie wiązać tych symboli z przyciskami zapisu. Running jest statusem programu/komendy, nie niezależnym pomiarem fizycznego ruchu.
| Dokładna ścieżka | Typ | Kierunek | Ekran / znaczenie | Rzeczywiste źródło | Ograniczenie |
|---|---|---|---|---|---|
| `GVL_HMI.hmiStatus.xAutoRunning` | `BOOL` | R | HOME / Zlecenie / Automat aktywny | `xAutoActive` (Main:1408) | Z wyjść AutoRunning sekwencerów; nie stan zlecenia ani potwierdzenie ruchu. |
| `GVL_HMI.hmiStatus.xManualMode` | `BOOL` | R | HOME / Zlecenie / Wybrany Manual | `xHmiManualMode` (Main:1409) | Echo żądania, nie potwierdzona procedura zmiany trybu. |
| `GVL_HMI.hmiStatus.xEmptyingStation` | `BOOL` | R | HOME / Zlecenie / Trwa stare opróżnianie | `xEmptyRunning` (Main:1410) | Nie nowy stan kończenia zlecenia. |
| `GVL_HMI.hmiStatus.xModeTray` | `BOOL` | R | HOME / Zlecenie / Wybrane Blistry | `xModeTray` (Main:1411) | Stary wybór bez blokady zlecenia. |
| `GVL_HMI.hmiStatus.xModeBox` | `BOOL` | R | HOME / Zlecenie / Wybrane Pojemniki | `xModeBox` (Main:1412) | Stary wybór bez blokady zlecenia. |
| `GVL_HMI.hmiStatus.xGlobalEnable` | `BOOL` | R | HOME / Zlecenie / Zezwolenie programu | `xGlobalEnable` (Main:1413) | xSafetyOK AND NOT niskie ciśnienie; xSafetyOK jest zastępcze. |
| `GVL_HMI.hmiStatus.xSafetyOK` | `BOOL` | R | HOME / Zlecenie / Zastępczy status pozwolenia | `xSafetyOK` (Main:1414) | Stałe TRUE. Nie dowodzi sprawności układu bezpieczeństwa. |
| `GVL_HMI.hmiStatus.xOccP1` | `BOOL` | R | ST.1 / Zajętość P1 | `fbTopFlow.Sts.OccP1` (Main:1417) | Stan managera; nie pełny model ładunków między czujnikami. |
| `GVL_HMI.hmiStatus.xOccP2` | `BOOL` | R | ST.1 / Zajętość P2 | `fbTopFlow.Sts.OccP2` (Main:1418) | Stan managera; nie pełny model ładunków między czujnikami. |
| `GVL_HMI.hmiStatus.xOccP3` | `BOOL` | R | ST.1 / Zajętość P3 | `fbTopFlow.Sts.OccP3` (Main:1419) | Stan managera; nie pełny model ładunków między czujnikami. |
| `GVL_HMI.hmiStatus.xOccP4` | `BOOL` | R | ST.2 / Zajętość P4 | `GVL_IO.di.ind_container_in_pos_4` (Main:1420) | P4 to czujnik gasnący przy bazowaniu mimo ładunku. Nie dowód pustej windy. |
| `GVL_HMI.hmiStatus.xOccP5` | `BOOL` | R | ST.3 / Zajętość P5 | `fbBottom567.Sts.Occ5` (Main:1421) | Stan managera; nie pełny model ładunków między czujnikami. |
| `GVL_HMI.hmiStatus.xOccP6` | `BOOL` | R | ST.3 / Zajętość P6 | `fbBottom567.Sts.Occ6` (Main:1422) | Stan managera; nie pełny model ładunków między czujnikami. |
| `GVL_HMI.hmiStatus.xOccP7` | `BOOL` | R | ST.3 / Zajętość P7 | `fbBottom567.Sts.Occ7` (Main:1423) | Stan managera; nie pełny model ładunków między czujnikami. |
| `GVL_HMI.hmiStatus.uiElevState` | `UINT` | R | ST.2 / Numer stanu windy | `uiElevState` (Main:1426) | Enum E_ElevatorState w sekcji 5. |
| `GVL_HMI.hmiStatus.xElevAtTop` | `BOOL` | R | ST.2 / Winda u góry | `elevStat.ePos = E_ElevatorPos.posTop` (Main:1427) | Porównanie ePos z posTop. |
| `GVL_HMI.hmiStatus.xElevAtBottom` | `BOOL` | R | ST.2 / Winda na dole | `elevStat.ePos = E_ElevatorPos.posBottom` (Main:1428) | Porównanie ePos z posBottom. |
| `GVL_HMI.hmiStatus.xElevBusy` | `BOOL` | R | ST.2 / Ruch windy | `elevStat.xBusy` (Main:1429) | xMoveUpReq OR xMoveDownReq; nie cała gotowość procesu. |
| `GVL_HMI.hmiStatus.xElevFault` | `BOOL` | R | ST.2 / Błąd windy | `elevStat.xFault` (Main:1430) | To samo źródło co alarm xElev_Fault. |
| `GVL_HMI.hmiStatus.rElevFreq_Hz` | `REAL` | R | ST.2 / Częstotliwość napędu [Hz] | `elevStat.rVfdOutHz` (Main:1431) | Diagnostyka 0,1 Hz przeliczona przez FB; nie prędkość liniowa. |
| `GVL_HMI.hmiStatus.sElevDiagText` | `STRING[120]` | R | ST.2 / Diagnostyka windy | `elevStat.sDiagText` (Main:1432) | Zachować polskie znaki i długość tekstu. |
| `GVL_HMI.hmiStatus.xConvTopRunning` | `BOOL` | R | ST.1 / Transporter pracuje | `fbConvTop.Sts.Running` (Main:1435) | Stan FB, nie czujnik ruchu. |
| `GVL_HMI.hmiStatus.xConvElevRunning` | `BOOL` | R | ST.2 / Transporter pracuje | `fbConvElev.Sts.Running` (Main:1436) | Stan FB, nie czujnik ruchu. |
| `GVL_HMI.hmiStatus.xConvBottomRunning` | `BOOL` | R | ST.3 / Transporter pracuje | `fbConvBottom.Sts.Running` (Main:1437) | Stan FB, nie czujnik ruchu. |
| `GVL_HMI.hmiStatus.uiConvTopState` | `UINT` | R | ST.1 / Numer stanu transportera | `TO_UINT(fbConvTop.Sts.State)` (Main:1438) | Enum E_ConveyorState. |
| `GVL_HMI.hmiStatus.uiConvElevState` | `UINT` | R | ST.2 / Numer stanu transportera | `TO_UINT(fbConvElev.Sts.State)` (Main:1439) | Enum E_ConveyorState. |
| `GVL_HMI.hmiStatus.uiConvBottomState` | `UINT` | R | ST.3 / Numer stanu transportera | `TO_UINT(fbConvBottom.Sts.State)` (Main:1440) | Enum E_ConveyorState. |
| `GVL_HMI.hmiStatus.iConvTopDirection` | `INT` | R | ST.1 / Kierunek transportera | `fbConvTop.Sts.Direction` (Main:1441) | INT: -1 wstecz, 0 postój, 1 do przodu. |
| `GVL_HMI.hmiStatus.iConvElevDirection` | `INT` | R | ST.2 / Kierunek transportera | `fbConvElev.Sts.Direction` (Main:1442) | INT: -1 wstecz, 0 postój, 1 do przodu. |
| `GVL_HMI.hmiStatus.iConvBottomDirection` | `INT` | R | ST.3 / Kierunek transportera | `fbConvBottom.Sts.Direction` (Main:1443) | INT: -1 wstecz, 0 postój, 1 do przodu. |
| `GVL_HMI.hmiStatus.xConvTopFault` | `BOOL` | R | ST.1 / Błąd transportera | `fbConvTop.Diag.Fault` (Main:1444) | To samo źródło co odpowiadająca flaga alarmów. |
| `GVL_HMI.hmiStatus.xConvElevFault` | `BOOL` | R | ST.2 / Błąd transportera | `fbConvElev.Diag.Fault` (Main:1445) | To samo źródło co odpowiadająca flaga alarmów. |
| `GVL_HMI.hmiStatus.xConvBottomFault` | `BOOL` | R | ST.3 / Błąd transportera | `fbConvBottom.Diag.Fault` (Main:1446) | To samo źródło co odpowiadająca flaga alarmów. |
| `GVL_HMI.hmiStatus.sConvTopDiagText` | `STRING[120]` | R | ST.1 / Diagnostyka transportera | `fbConvTop.Diag.Text` (Main:1447) | STRING[120]. |
| `GVL_HMI.hmiStatus.sConvElevDiagText` | `STRING[120]` | R | ST.2 / Diagnostyka transportera | `fbConvElev.Diag.Text` (Main:1448) | STRING[120]. |
| `GVL_HMI.hmiStatus.sConvBottomDiagText` | `STRING[120]` | R | ST.3 / Diagnostyka transportera | `fbConvBottom.Diag.Text` (Main:1449) | STRING[120]. |
| `GVL_HMI.hmiStatus.xM1_Extended` | `BOOL` | R | ST.1 / pozycjoner załadunku / Extended | `fbPosM1.Sts.IsUp` (Main:1452) | Zagregowane potwierdzenie; M6 nie rozdziela V201/V202. |
| `GVL_HMI.hmiStatus.xM2_Up` | `BOOL` | R | ST.1 / podnoszenie P1 / Up | `fbStopM2.Sts.IsUp` (Main:1453) | Zagregowane potwierdzenie; M6 nie rozdziela V201/V202. |
| `GVL_HMI.hmiStatus.xM3_Up` | `BOOL` | R | ST.1 / podnoszenie P2 / Up | `fbStopM3.Sts.IsUp` (Main:1454) | Zagregowane potwierdzenie; M6 nie rozdziela V201/V202. |
| `GVL_HMI.hmiStatus.xM4_Up` | `BOOL` | R | ST.1 / podnoszenie P3 / Up | `fbStopM4.Sts.IsUp` (Main:1455) | Zagregowane potwierdzenie; M6 nie rozdziela V201/V202. |
| `GVL_HMI.hmiStatus.xM5_Up` | `BOOL` | R | ST.1 / pozycjoner P3 / Up | `fbPosM5.Sts.IsUp` (Main:1456) | Zagregowane potwierdzenie; M6 nie rozdziela V201/V202. |
| `GVL_HMI.hmiStatus.xM6_Up` | `BOOL` | R | ST.2 / para pozycjonerów blistrów / Up | `fbPosM6.Sts.IsUp` (Main:1457) | Zagregowane potwierdzenie; M6 nie rozdziela V201/V202. |
| `GVL_HMI.hmiStatus.xM7_Extended` | `BOOL` | R | ST.2 / pozycjoner pojemnika / Extended | `fbPosM7.Sts.IsUp` (Main:1458) | Zagregowane potwierdzenie; M6 nie rozdziela V201/V202. |
| `GVL_HMI.hmiStatus.xM8_Extended` | `BOOL` | R | ST.4 / stara osłona magazynu / Extended | `fbStorage.Sts.RobotSideOpen` (Main:1459) | M8: stara osłona otwarta, nowy WORK = zamknięcie. |
| `GVL_HMI.hmiStatus.xM1_Retracted` | `BOOL` | R | ST.1 / pozycjoner załadunku / Retracted | `fbPosM1.Sts.IsDown` (Main:1460) | Zagregowane potwierdzenie starego mechanizmu; sprawdzić M→V. |
| `GVL_HMI.hmiStatus.xM2_Down` | `BOOL` | R | ST.1 / podnoszenie P1 / Down | `fbStopM2.Sts.IsDown` (Main:1461) | Zagregowane potwierdzenie starego mechanizmu; sprawdzić M→V. |
| `GVL_HMI.hmiStatus.xM3_Down` | `BOOL` | R | ST.1 / podnoszenie P2 / Down | `fbStopM3.Sts.IsDown` (Main:1462) | Zagregowane potwierdzenie starego mechanizmu; sprawdzić M→V. |
| `GVL_HMI.hmiStatus.xM4_Down` | `BOOL` | R | ST.1 / podnoszenie P3 / Down | `fbStopM4.Sts.IsDown` (Main:1463) | Zagregowane potwierdzenie starego mechanizmu; sprawdzić M→V. |
| `GVL_HMI.hmiStatus.xM5_Down` | `BOOL` | R | ST.1 / pozycjoner P3 / Down | `fbPosM5.Sts.IsDown` (Main:1464) | Zagregowane potwierdzenie starego mechanizmu; sprawdzić M→V. |
| `GVL_HMI.hmiStatus.xM6_Down` | `BOOL` | R | ST.2 / para pozycjonerów blistrów / Down | `fbPosM6.Sts.IsDown` (Main:1465) | Zagregowane potwierdzenie starego mechanizmu; sprawdzić M→V. |
| `GVL_HMI.hmiStatus.xM7_Retracted` | `BOOL` | R | ST.2 / pozycjoner pojemnika / Retracted | `fbPosM7.Sts.IsDown` (Main:1466) | Zagregowane potwierdzenie starego mechanizmu; sprawdzić M→V. |
| `GVL_HMI.hmiStatus.xM8_Retracted` | `BOOL` | R | ST.4 / stara osłona magazynu / Retracted | `fbStorage.Sts.RobotSideClosed` (Main:1467) | Zagregowane potwierdzenie starego mechanizmu; sprawdzić M→V. |
| `GVL_HMI.hmiStatus.xM1_Busy` | `BOOL` | R | ST.1 / pozycjoner załadunku / ruch | `fbPosM1.Sts.Busy` (Main:1468) | Stan starego FB, nie nowa diagnostyka osobnych osi. |
| `GVL_HMI.hmiStatus.xM2_Busy` | `BOOL` | R | ST.1 / podnoszenie P1 / ruch | `fbStopM2.Sts.Busy` (Main:1469) | Stan starego FB, nie nowa diagnostyka osobnych osi. |
| `GVL_HMI.hmiStatus.xM3_Busy` | `BOOL` | R | ST.1 / podnoszenie P2 / ruch | `fbStopM3.Sts.Busy` (Main:1470) | Stan starego FB, nie nowa diagnostyka osobnych osi. |
| `GVL_HMI.hmiStatus.xM4_Busy` | `BOOL` | R | ST.1 / podnoszenie P3 / ruch | `fbStopM4.Sts.Busy` (Main:1471) | Stan starego FB, nie nowa diagnostyka osobnych osi. |
| `GVL_HMI.hmiStatus.xM5_Busy` | `BOOL` | R | ST.1 / pozycjoner P3 / ruch | `fbPosM5.Sts.Busy` (Main:1472) | Stan starego FB, nie nowa diagnostyka osobnych osi. |
| `GVL_HMI.hmiStatus.xM6_Busy` | `BOOL` | R | ST.2 / para pozycjonerów blistrów / ruch | `fbPosM6.Sts.Busy` (Main:1473) | Stan starego FB, nie nowa diagnostyka osobnych osi. |
| `GVL_HMI.hmiStatus.xM7_Busy` | `BOOL` | R | ST.2 / pozycjoner pojemnika / ruch | `fbPosM7.Sts.Busy` (Main:1474) | Stan starego FB, nie nowa diagnostyka osobnych osi. |
| `GVL_HMI.hmiStatus.xM8_Busy` | `BOOL` | R | ST.4 / stara osłona magazynu / ruch | `fbStorage.Sts.Busy` (Main:1475) | Stan starego FB, nie nowa diagnostyka osobnych osi. |
| `GVL_HMI.hmiStatus.xM1_Fault` | `BOOL` | R | ST.1 / pozycjoner załadunku / błąd | `fbPosM1.Diag.Fault` (Main:1476) | To samo źródło co alarm M1; brak nowego severity. |
| `GVL_HMI.hmiStatus.xM2_Fault` | `BOOL` | R | ST.1 / podnoszenie P1 / błąd | `fbStopM2.Diag.Fault` (Main:1477) | To samo źródło co alarm M2; brak nowego severity. |
| `GVL_HMI.hmiStatus.xM3_Fault` | `BOOL` | R | ST.1 / podnoszenie P2 / błąd | `fbStopM3.Diag.Fault` (Main:1478) | To samo źródło co alarm M3; brak nowego severity. |
| `GVL_HMI.hmiStatus.xM4_Fault` | `BOOL` | R | ST.1 / podnoszenie P3 / błąd | `fbStopM4.Diag.Fault` (Main:1479) | To samo źródło co alarm M4; brak nowego severity. |
| `GVL_HMI.hmiStatus.xM5_Fault` | `BOOL` | R | ST.1 / pozycjoner P3 / błąd | `fbPosM5.Diag.Fault` (Main:1480) | To samo źródło co alarm M5; brak nowego severity. |
| `GVL_HMI.hmiStatus.xM6_Fault` | `BOOL` | R | ST.2 / para pozycjonerów blistrów / błąd | `fbPosM6.Diag.Fault` (Main:1481) | To samo źródło co alarm M6; brak nowego severity. |
| `GVL_HMI.hmiStatus.xM7_Fault` | `BOOL` | R | ST.2 / pozycjoner pojemnika / błąd | `fbPosM7.Diag.Fault` (Main:1482) | To samo źródło co alarm M7; brak nowego severity. |
| `GVL_HMI.hmiStatus.xM8_Fault` | `BOOL` | R | ST.4 / stara osłona magazynu / błąd | `fbStorage.Diag.Fault` (Main:1483) | To samo źródło co alarm M8; brak nowego severity. |
| `GVL_HMI.hmiStatus.sM1DiagText` | `STRING[120]` | R | ST.1 / pozycjoner załadunku / tekst | `fbPosM1.Diag.Text` (Main:1484) | M1–M7: kopia tekstu źródłowego STRING[100]; M8: tekst Storage. |
| `GVL_HMI.hmiStatus.sM2DiagText` | `STRING[120]` | R | ST.1 / podnoszenie P1 / tekst | `fbStopM2.Diag.Text` (Main:1485) | M1–M7: kopia tekstu źródłowego STRING[100]; M8: tekst Storage. |
| `GVL_HMI.hmiStatus.sM3DiagText` | `STRING[120]` | R | ST.1 / podnoszenie P2 / tekst | `fbStopM3.Diag.Text` (Main:1486) | M1–M7: kopia tekstu źródłowego STRING[100]; M8: tekst Storage. |
| `GVL_HMI.hmiStatus.sM4DiagText` | `STRING[120]` | R | ST.1 / podnoszenie P3 / tekst | `fbStopM4.Diag.Text` (Main:1487) | M1–M7: kopia tekstu źródłowego STRING[100]; M8: tekst Storage. |
| `GVL_HMI.hmiStatus.sM5DiagText` | `STRING[120]` | R | ST.1 / pozycjoner P3 / tekst | `fbPosM5.Diag.Text` (Main:1488) | M1–M7: kopia tekstu źródłowego STRING[100]; M8: tekst Storage. |
| `GVL_HMI.hmiStatus.sM6DiagText` | `STRING[120]` | R | ST.2 / para pozycjonerów blistrów / tekst | `fbPosM6.Diag.Text` (Main:1489) | M1–M7: kopia tekstu źródłowego STRING[100]; M8: tekst Storage. |
| `GVL_HMI.hmiStatus.sM7DiagText` | `STRING[120]` | R | ST.2 / pozycjoner pojemnika / tekst | `fbPosM7.Diag.Text` (Main:1490) | M1–M7: kopia tekstu źródłowego STRING[100]; M8: tekst Storage. |
| `GVL_HMI.hmiStatus.sM8DiagText` | `STRING[120]` | R | ST.4 / stara osłona magazynu / tekst | `fbStorage.Diag.Text` (Main:1491) | M1–M7: kopia tekstu źródłowego STRING[100]; M8: tekst Storage. |
| `GVL_HMI.hmiStatus.xM1_1_Fwd` | `BOOL` | R | ST.1 / Krańcówka M1.1 Fwd | `GVL_IO.di.ind_M1_1_fwd` (Main:1495) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM1_2_Fwd` | `BOOL` | R | ST.1 / Krańcówka M1.2 Fwd | `GVL_IO.di.ind_M1_2_fwd` (Main:1496) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM1_1_Bwd` | `BOOL` | R | ST.1 / Krańcówka M1.1 Bwd | `GVL_IO.di.ind_M1_1_bwd` (Main:1497) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM1_2_Bwd` | `BOOL` | R | ST.1 / Krańcówka M1.2 Bwd | `GVL_IO.di.ind_M1_2_bwd` (Main:1498) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM2_1_Fwd` | `BOOL` | R | ST.1 / Krańcówka M2.1 Fwd | `GVL_IO.di.ind_M2_1_fwd` (Main:1500) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM2_2_Fwd` | `BOOL` | R | ST.1 / Krańcówka M2.2 Fwd | `GVL_IO.di.ind_M2_2_fwd` (Main:1501) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM2_1_Bwd` | `BOOL` | R | ST.1 / Krańcówka M2.1 Bwd | `GVL_IO.di.ind_M2_1_bwd` (Main:1502) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM2_2_Bwd` | `BOOL` | R | ST.1 / Krańcówka M2.2 Bwd | `GVL_IO.di.ind_M2_2_bwd` (Main:1503) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM3_1_Fwd` | `BOOL` | R | ST.1 / Krańcówka M3.1 Fwd | `GVL_IO.di.ind_M3_1_fwd` (Main:1505) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM3_2_Fwd` | `BOOL` | R | ST.1 / Krańcówka M3.2 Fwd | `GVL_IO.di.ind_M3_2_fwd` (Main:1506) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM3_1_Bwd` | `BOOL` | R | ST.1 / Krańcówka M3.1 Bwd | `GVL_IO.di.ind_M3_1_bwd` (Main:1507) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM3_2_Bwd` | `BOOL` | R | ST.1 / Krańcówka M3.2 Bwd | `GVL_IO.di.ind_M3_2_bwd` (Main:1508) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM4_1_Fwd` | `BOOL` | R | ST.1 / Krańcówka M4.1 Fwd | `GVL_IO.di.ind_M4_1_fwd` (Main:1510) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM4_2_Fwd` | `BOOL` | R | ST.1 / Krańcówka M4.2 Fwd | `GVL_IO.di.ind_M4_2_fwd` (Main:1511) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM4_1_Bwd` | `BOOL` | R | ST.1 / Krańcówka M4.1 Bwd | `GVL_IO.di.ind_M4_1_bwd` (Main:1512) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM4_2_Bwd` | `BOOL` | R | ST.1 / Krańcówka M4.2 Bwd | `GVL_IO.di.ind_M4_2_bwd` (Main:1513) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM5_1_Fwd` | `BOOL` | R | ST.1 / Krańcówka M5.1 Fwd | `GVL_IO.di.ind_M5_1_fwd` (Main:1515) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM5_2_Fwd` | `BOOL` | R | ST.1 / Krańcówka M5.2 Fwd | `GVL_IO.di.ind_M5_2_fwd` (Main:1516) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM5_1_Bwd` | `BOOL` | R | ST.1 / Krańcówka M5.1 Bwd | `GVL_IO.di.ind_M5_1_bwd` (Main:1517) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM5_2_Bwd` | `BOOL` | R | ST.1 / Krańcówka M5.2 Bwd | `GVL_IO.di.ind_M5_2_bwd` (Main:1518) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM6_1_Fwd` | `BOOL` | R | ST.2 / Krańcówka M6.1 Fwd | `GVL_IO.di.ind_M6_1_fwd` (Main:1520) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM6_2_Fwd` | `BOOL` | R | ST.2 / Krańcówka M6.2 Fwd | `GVL_IO.di.ind_M6_2_fwd` (Main:1521) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM6_1_Bwd` | `BOOL` | R | ST.2 / Krańcówka M6.1 Bwd | `GVL_IO.di.ind_M6_1_bwd` (Main:1522) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM6_2_Bwd` | `BOOL` | R | ST.2 / Krańcówka M6.2 Bwd | `GVL_IO.di.ind_M6_2_bwd` (Main:1523) | Surowe logiczne wejście; nie filtr ani walidacja obu osi. |
| `GVL_HMI.hmiStatus.xM7_Fwd` | `BOOL` | R | ST.2 / Krańcówka M7 Fwd | `GVL_IO.di.ind_M7_fwd` (Main:1525) | Surowe wejście; M8 ma starą semantykę otwarcia/zamknięcia. |
| `GVL_HMI.hmiStatus.xM7_Bwd` | `BOOL` | R | ST.2 / Krańcówka M7 Bwd | `GVL_IO.di.ind_M7_bwd` (Main:1526) | Surowe wejście; M8 ma starą semantykę otwarcia/zamknięcia. |
| `GVL_HMI.hmiStatus.xM8_Fwd` | `BOOL` | R | ST.4 / Krańcówka M8 Fwd | `GVL_IO.di.ind_M8_fwd` (Main:1528) | Surowe wejście; M8 ma starą semantykę otwarcia/zamknięcia. |
| `GVL_HMI.hmiStatus.xM8_Bwd` | `BOOL` | R | ST.4 / Krańcówka M8 Bwd | `GVL_IO.di.ind_M8_bwd` (Main:1529) | Surowe wejście; M8 ma starą semantykę otwarcia/zamknięcia. |
| `GVL_HMI.hmiStatus.uiSafetyDoorState` | `UINT` | R | HOME / drzwi / Stan drzwi | `TO_UINT(fbSafetyDoor.Sts.State)` (Main:1532) | Enum E_SafetyDoorState. |
| `GVL_HMI.hmiStatus.xSafetyDoorClosed` | `BOOL` | R | HOME / drzwi / Drzwi zamknięte | `fbSafetyDoor.Sts.DoorClosed` (Main:1533) | Interpretacja FB; potwierdzić wejście i konfigurację zamka. |
| `GVL_HMI.hmiStatus.xSafetyDoorLocked` | `BOOL` | R | HOME / drzwi / Drzwi zaryglowane | `fbSafetyDoor.Sts.DoorLocked` (Main:1534) | Status funkcjonalny, nie samodzielna funkcja bezpieczeństwa. |
| `GVL_HMI.hmiStatus.xSafetyDoorDeviceError` | `BOOL` | R | HOME / drzwi / Błąd urządzenia drzwi | `fbSafetyDoor.Sts.DeviceError` (Main:1535) | DeviceError jest negacją ind_robot_cell_doors_error w PRG_Main. |
| `GVL_HMI.hmiStatus.xSafetyDoorUnlockRequest` | `BOOL` | R | HOME / drzwi / Żądanie odryglowania | `fbSafetyDoor.Sts.UnlockRequest` (Main:1536) | Status; nie komenda do zapisu z HMI. |
| `GVL_HMI.hmiStatus.xSafetyDoorReadyToRun` | `BOOL` | R | HOME / drzwi / Gotowość drzwi | `fbSafetyDoor.Sts.ReadyToRun` (Main:1537) | Status pomijany przez xSafetyOK := TRUE. |
| `GVL_HMI.hmiStatus.xSafetyDoorBusy` | `BOOL` | R | HOME / drzwi / Obsługa drzwi w toku | `fbSafetyDoor.Sts.Busy` (Main:1538) | Stan FB. |
| `GVL_HMI.hmiStatus.xSafetyDoorFault` | `BOOL` | R | HOME / drzwi / Błąd drzwi | `fbSafetyDoor.Diag.Fault` (Main:1539) | Brak osobnej odpowiadającej flagi w hmiAlarms. |
| `GVL_HMI.hmiStatus.sSafetyDoorDiagText` | `STRING[120]` | R | HOME / drzwi / Tekst drzwi | `fbSafetyDoor.Diag.Text` (Main:1540) | STRING[120]. |
| `GVL_HMI.hmiStatus.uiStorageState` | `UINT` | R | ST.4 / Stan magazynu | `TO_UINT(fbStorage.Sts.State)` (Main:1543) | Enum E_StorageState. |
| `GVL_HMI.hmiStatus.xStorageRobotSideOpen` | `BOOL` | R | ST.4 / Osłona robota otwarta | `fbStorage.Sts.RobotSideOpen` (Main:1544) | Duplikat xM8_Extended; nowy układ potrzebuje dwóch osłon. |
| `GVL_HMI.hmiStatus.xStorageRobotSideClosed` | `BOOL` | R | ST.4 / Osłona robota zamknięta | `fbStorage.Sts.RobotSideClosed` (Main:1545) | Duplikat xM8_Retracted; nowy WORK to zamknięcie. |
| `GVL_HMI.hmiStatus.xStorageRobotAccessActive` | `BOOL` | R | ST.4 / Aktywny dostęp robota | `fbStorage.Sts.RobotAccessActive` (Main:1546) | Status FB. |
| `GVL_HMI.hmiStatus.xStorageOperatorAccessActive` | `BOOL` | R | ST.4 / Aktywny dostęp operatora | `fbStorage.Sts.OperatorAccessActive` (Main:1547) | Status, nie żądanie odryglowania. |
| `GVL_HMI.hmiStatus.xStorageOperatorRequest` | `BOOL` | R | ST.4 / Żądanie operatora | `fbStorage.Sts.OperatorRequest` (Main:1548) | Od fizycznego przycisku; brak komendy HMI w obecnej GVL. |
| `GVL_HMI.hmiStatus.xStorageRobotPermission` | `BOOL` | R | ST.4 / Wejściowe pozwolenie otwarcia od robota | `GVL_IO.di.ind_spacer_storage_robot_side_doors_opening_permission` (Main:1549) | Nie jest pełnym storage_ready wysyłanym robotowi. |
| `GVL_HMI.hmiStatus.xStorageOperatorPermission` | `BOOL` | R | ST.4 / Wejściowe pozwolenie operatora | `GVL_IO.di.ind_spacer_storage_operator_side_doors_opening_permission` (Main:1551) | Nie zastępuje obu osłon i rygli nowej stacji. |
| `GVL_HMI.hmiStatus.xStorageLowLevel` | `BOOL` | R | ST.4 / Niski poziom przekładek | `fbStorage.Sts.LowLevel` (Main:1553) | Status czujnika/FB. |
| `GVL_HMI.hmiStatus.xStorageEmpty` | `BOOL` | R | ST.4 / Magazyn pusty | `fbStorage.Sts.Empty` (Main:1554) | Status czujnika/FB. |
| `GVL_HMI.hmiStatus.xStorageBusy` | `BOOL` | R | ST.4 / Sekwencja magazynu zajęta | `fbStorage.Sts.Busy` (Main:1555) | Ten sam FB co xM8_Busy. |
| `GVL_HMI.hmiStatus.xStorageFault` | `BOOL` | R | ST.4 / Błąd magazynu | `fbStorage.Diag.Fault` (Main:1556) | Ten sam błąd co xM8_Fault; nie dublować alarmu. |
| `GVL_HMI.hmiStatus.sStorageDiagText` | `STRING[120]` | R | ST.4 / Tekst magazynu | `fbStorage.Diag.Text` (Main:1557) | Ten sam tekst co sM8DiagText. |
| `GVL_HMI.hmiStatus.xRobotAutoMode` | `BOOL` | R | ST.5 / Robot AUTO | `GVL_Robot.robotIn.sts_auto_mode` (Main:1560) | Nie panelowe Auto/Manual automatu. |
| `GVL_HMI.hmiStatus.xRobotReady` | `BOOL` | R | ST.5 / Robot system ready | `GVL_Robot.robotIn.sts_system_ready` (Main:1561) | Nie gotowość całego procesu. |
| `GVL_HMI.hmiStatus.xRobotRunning` | `BOOL` | R | ST.5 / Program robota uruchomiony | `GVL_Robot.robotIn.sts_prg_running` (Main:1562) | Nie dowód ruchu ani zgodności programu z produkcją. |
| `GVL_HMI.hmiStatus.xRobotFault` | `BOOL` | R | ST.5 / Błąd robota | `GVL_Robot.robotIn.sts_fault` (Main:1563) | To samo źródło co alarm xRobot_Fault. |
| `GVL_HMI.hmiStatus.xRobotHome` | `BOOL` | R | ST.5 / Robot HOME | `GVL_Robot.robotIn.sts_in_home_pos` (Main:1564) | Brak kontroli aktualności; źródło HOME wymaga backupu. |
| `GVL_HMI.hmiStatus.xRobotCommOk` | `BOOL` | R | ST.5 / Komunikacja robota | `GVL_Robot.xRobotCommOk` (Main:1565) | Stałe TRUE; nie rzeczywista diagnostyka. |
| `GVL_HMI.hmiStatus.xVfdCommOk` | `BOOL` | R | ST.2 / Stan GIATV | `elevStat.xVfdCommOk` (Main:1566) | q_xEn AND NOT q_xAlrm; nie czysty status połączenia sieciowego. |
| `GVL_HMI.hmiStatus.uiTraySeqState` | `UINT` | R | Zlecenie / Blistry / Stan TraySeq | `TO_UINT(fbTraySeq.Sts.State)` (Main:1569) | Wartości z odpowiedniego enumu w sekcji 5. |
| `GVL_HMI.hmiStatus.uiBoxSeqState` | `UINT` | R | Zlecenie / Pojemniki / Stan BoxSeq | `TO_UINT(fbBoxSeq.Sts.State)` (Main:1570) | Wartości z odpowiedniego enumu w sekcji 5. |
| `GVL_HMI.hmiStatus.uiTopFlowState` | `UINT` | R | ST.1 / Stan TopFlow | `TO_UINT(fbTopFlow.Sts.State)` (Main:1571) | Wartości z odpowiedniego enumu w sekcji 5. |
| `GVL_HMI.hmiStatus.uiBottomState` | `UINT` | R | ST.3 / Stan Bottom | `TO_UINT(fbBottom567.Sts.State)` (Main:1572) | Wartości z odpowiedniego enumu w sekcji 5. |
| `GVL_HMI.hmiStatus.sTopFlowDiagText` | `STRING[120]` | R | ST.1 / Diagnostyka TopFlow | `fbTopFlow.Diag.FaultText` (Main:1573) | Tekst błędu, nie nowy powód blokady komendy. |
| `GVL_HMI.hmiStatus.sBottomDiagText` | `STRING[120]` | R | ST.3 / Diagnostyka Bottom | `fbBottom567.Diag.Text` (Main:1574) | Tekst błędu, nie nowy powód blokady komendy. |
| `GVL_HMI.hmiStatus.sTraySeqDiagText` | `STRING[120]` | R | Zlecenie / Blistry / Diagnostyka TraySeq | `fbTraySeq.Diag.FaultText` (Main:1575) | Tekst błędu, nie nowy powód blokady komendy. |
| `GVL_HMI.hmiStatus.sBoxSeqDiagText` | `STRING[120]` | R | Zlecenie / Pojemniki / Diagnostyka BoxSeq | `fbBoxSeq.Diag.FaultText` (Main:1576) | Tekst błędu, nie nowy powód blokady komendy. |
| `GVL_HMI.hmiStatus.uiTraysDone` | `UINT` | R | Zlecenie / Blistry / Tacki bieżącego stosu | `fbTraySeq.Sts.TrayCount` (Main:1578) | TrayCount; nie liczba produktów. |
| `GVL_HMI.hmiStatus.uiStacksDone` | `UINT` | R | Zlecenie / Blistry / Zakończone stosy | `fbTraySeq.Sts.StackCount` (Main:1579) | StackCount; brak odrębnej retencji zlecenia. |
| `GVL_HMI.hmiStatus.uiBoxesDone` | `UINT` | R | Zlecenie / Pojemniki / Zakończone pojemniki | `fbBoxSeq.Sts.BoxCount` (Main:1580) | BoxCount; nie liczba warstw ani produktów. |

## 3. Struktura alarmów — 26 pól

Pojedyncza struktura BOOL nie ma rekordów severity/ID/tekstu/czasu ani działającego ACK. Nazwa Fault nie rozstrzyga nowej klasy alarmu. Nie tworzyć dwóch alarmów z tej samej flagi pokazywanej również w hmiStatus.
| Dokładna ścieżka | Typ | Kierunek | Ekran / znaczenie | Bieżące źródło i ograniczenie |
|---|---|---|---|---|
| `GVL_HMI.hmiAlarms.xM1_Fault` | `BOOL` | R | ST.1 / pozycjoner załadunku | `fbPosM1.Diag.Fault` (Main:1354). Błąd bazowego FB; docelowo klasyfikacja ST.1–ST.4 i oddzielne osie. |
| `GVL_HMI.hmiAlarms.xM2_Fault` | `BOOL` | R | ST.1 / podnoszenie P1 | `fbStopM2.Diag.Fault` (Main:1355). Błąd bazowego FB; docelowo klasyfikacja ST.1–ST.4 i oddzielne osie. |
| `GVL_HMI.hmiAlarms.xM3_Fault` | `BOOL` | R | ST.1 / podnoszenie P2 | `fbStopM3.Diag.Fault` (Main:1356). Błąd bazowego FB; docelowo klasyfikacja ST.1–ST.4 i oddzielne osie. |
| `GVL_HMI.hmiAlarms.xM4_Fault` | `BOOL` | R | ST.1 / podnoszenie P3 | `fbStopM4.Diag.Fault` (Main:1357). Błąd bazowego FB; docelowo klasyfikacja ST.1–ST.4 i oddzielne osie. |
| `GVL_HMI.hmiAlarms.xM5_Fault` | `BOOL` | R | ST.1 / pozycjoner P3 | `fbPosM5.Diag.Fault` (Main:1358). Błąd bazowego FB; docelowo klasyfikacja ST.1–ST.4 i oddzielne osie. |
| `GVL_HMI.hmiAlarms.xM6_Fault` | `BOOL` | R | ST.2 / para pozycjonerów blistrów | `fbPosM6.Diag.Fault` (Main:1359). Błąd bazowego FB; docelowo klasyfikacja ST.1–ST.4 i oddzielne osie. |
| `GVL_HMI.hmiAlarms.xM7_Fault` | `BOOL` | R | ST.2 / pozycjoner pojemnika | `fbPosM7.Diag.Fault` (Main:1360). Błąd bazowego FB; docelowo klasyfikacja ST.1–ST.4 i oddzielne osie. |
| `GVL_HMI.hmiAlarms.xM8_Fault` | `BOOL` | R | ST.4 / stara osłona magazynu | `fbStorage.Diag.Fault` (Main:1361). Błąd bazowego FB; docelowo klasyfikacja ST.1–ST.4 i oddzielne osie. |
| `GVL_HMI.hmiAlarms.xConvTop_Fault` | `BOOL` | R | ST.1 / transporter | `fbConvTop.Diag.Fault` (Main:1362). FB_Conveyor, w tym jednoczesne kierunki. |
| `GVL_HMI.hmiAlarms.xConvElev_Fault` | `BOOL` | R | ST.2 / transporter | `fbConvElev.Diag.Fault` (Main:1363). FB_Conveyor, w tym jednoczesne kierunki. |
| `GVL_HMI.hmiAlarms.xConvBottom_Fault` | `BOOL` | R | ST.3 / transporter | `fbConvBottom.Diag.Fault` (Main:1364). FB_Conveyor, w tym jednoczesne kierunki. |
| `GVL_HMI.hmiAlarms.xElev_Fault` | `BOOL` | R | ST.2 / winda | `elevStat.xFault` (Main:1365). Nie utożsamiać dowolnego błędu napędu z ostrzeżeniem pozycjonera. |
| `GVL_HMI.hmiAlarms.xElev_CommLost` | `BOOL` | R / stała FALSE | ST.2 / dawny alarm komunikacji | `FALSE` (Main:1366). Jawnie FALSE; alarm nieużywany. |
| `GVL_HMI.hmiAlarms.xTopFlow_Fault` | `BOOL` | R | ST.1 / przepływ | `fbTopFlow.Diag.Fault` (Main:1367). Błąd nadrzędny; wymaga eliminacji wtórnych eskalacji. |
| `GVL_HMI.hmiAlarms.xBottom_Fault` | `BOOL` | R | ST.3 / rozładunek | `fbBottom567.Diag.Fault` (Main:1368). Błąd dolnego akumulatora. |
| `GVL_HMI.hmiAlarms.xTraySeq_Fault` | `BOOL` | R | Zlecenie / Blistry | `fbTraySeq.Diag.Fault` (Main:1369). Błąd starego sekwencera. |
| `GVL_HMI.hmiAlarms.xBoxSeq_Fault` | `BOOL` | R | Zlecenie / Pojemniki | `fbBoxSeq.Diag.Fault` (Main:1370). Błąd starego sekwencera. |
| `GVL_HMI.hmiAlarms.xRobot_Fault` | `BOOL` | R | ST.5 / robot | `GVL_Robot.robotIn.sts_fault` (Main:1371). Brak szczegółowego kodu robota. |
| `GVL_HMI.hmiAlarms.xRobot_EStop` | `BOOL` | R | ST.5 / E-STOP status | `GVL_Robot.robotIn.sts_estop` (Main:1372). Procesowy odczyt, nie funkcja bezpieczeństwa. |
| `GVL_HMI.hmiAlarms.xRobot_CommLost` | `BOOL` | R / źródło zastępcze | ST.5 / komunikacja | `NOT GVL_Robot.xRobotCommOk` (Main:1373). Obecnie FALSE przez xRobotCommOk := TRUE. |
| `GVL_HMI.hmiAlarms.xVfd_CommLost` | `BOOL` | R | ST.2 / GIATV | `xGlobalEnable AND (NOT elevStat.xVfdCommOk)` (Main:1374). Liczone przy xGlobalEnable; status GIATV nie jest samym statusem łącza. |
| `GVL_HMI.hmiAlarms.xRobot_MbLost` | `BOOL` | R / brak producenta | ST.5 / dawny Modbus | Brak przypisania. Brak producenta, mimo to składnik hmiAlarmCount. Nie sprawna diagnostyka. |
| `GVL_HMI.hmiAlarms.xLowPressure` | `BOOL` | R | HOME / ciśnienie | `GVL_IO.di.ind_low_pressure` (Main:1375). Polaryzacja wejścia nowego układu wymaga zatwierdzenia. |
| `GVL_HMI.hmiAlarms.xSafetyTrip` | `BOOL` | R / źródło zastępcze | HOME / pozwolenie | `NOT xSafetyOK` (Main:1376). Obecnie FALSE przez xSafetyOK := TRUE. |
| `GVL_HMI.hmiAlarms.xAckAll` | `BOOL` | Brak obsługi | Alarmy / historyczne ACK | Brak przypisania. Brak odczytu i zapisu; pole nie działa. |
| `GVL_HMI.hmiAlarms.xResetAll` | `BOOL` | Brak obsługi | Alarmy / historyczny Reset | Brak przypisania. Brak odczytu i zapisu; obsługiwana ścieżka resetu to hmiCmd.xResetFaults. |

## 4. Licznik i stała

| Dokładna ścieżka | Typ | Kierunek | Ekran / znaczenie | Bieżące działanie i ograniczenie |
|---|---|---|---|---|
| `GVL_HMI.hmiAlarmCount` | `UINT` | R | HOME / Alarmy | Main:1378: suma 24 flag, w tym stale FALSE xElev_CommLost i nieustawiane xRobot_MbLost. Nie liczba rekordów nowego AlarmManagera. |
| `GVL_HMI.MAX_ALARMS` | `UINT` | Stała | Brak kontrolki operatora | VAR_GLOBAL CONSTANT := 32; brak tablicy hmiAlarms[1..32] i brak aktywnego użycia stałej. |

## 5. Opisy wartości stanów

Statusy UINT wyświetlać z opisem właściwego enumu. Nie używać jednej tabeli dla wszystkich FB. Nieznana wartość ma dawać „Nieznany stan: <kod>”, nie „Gotowy”. Poniżej dokładne nazwy/wartości z aktualnych FB, przeznaczone do diagnostyki, nie do zapisu.

| Enum | Źródło | Wartości w kodzie |
|---|---|---|
| `E_ElevatorState` | [FB_Elevator.st](../POUs/FB_Elevator.st) | `DISABLED=0`, `IDLE=10`, `MANUAL_UP=20`, `MANUAL_DOWN=21`, `AUTO_UP=30`, `AUTO_DOWN=31`, `STOPPING=40`, `FAULT=900` |
| `E_ConveyorState` | [FB_Conveyor.st](../POUs/FB_Conveyor.st) | `IDLE=0`, `RUN_FWD=10`, `RUN_BWD=20`, `DELAY_FWD=30`, `DELAY_BWD=40`, `FAULT=900` |
| `E_SafetyDoorState` | [FB_SafetyDoor.st](../POUs/FB_SafetyDoor.st) | `DISABLED=0`, `UNLOCKED=10`, `LOCKED=20`, `UNLOCK_REQUEST=30`, `FAULT=900` |
| `E_StorageState` | [FB_Storage.st](../POUs/FB_Storage.st) | `DISABLED=0`, `IDLE=10`, `ROBOT_WAIT_PERMISSION=20`, `ROBOT_OPENING=30`, `ROBOT_OPEN=40`, `ROBOT_CLOSING=50`, `CLOSING_FOR_OPERATOR=60`, `OPERATOR_WAIT_PERMISSION=70`, `OPERATOR_UNLOCKED=80`, `WAIT_OPERATOR_LOCK=90`, `FAULT=900` |
| `E_TopFlowState` | [FB_TopFlowManager.st](../POUs/FB_TopFlowManager.st) | `INIT=0`, `IDLE=10`, `PREP_STOP=20`, `PREP_STOPPERS=30`, `RUN=40`, `WAIT_STOP=50`, `RETRACT_M5_GATE=55`, `WAIT_M5_RETRACT=57`, `LOCK_TARGET=60`, `WAIT_LOCK=70`, `COMPLETE=80`, `FAULT=900` |
| `E_Bottom567State` | [FB_BottomAccumulator_567.st](../POUs/FB_BottomAccumulator_567.st) | `INIT=0`, `IDLE=10`, `PRECHECK=20`, `RUN_STEP=30`, `WAIT_STOP=40`, `COMPLETE=50`, `EMPTY_HOLD=60`, `EMPTY_RESYNC=70`, `FAULT=900` |
| `E_TraySeqState` | [FB_TraySequencer.st](../POUs/FB_TraySequencer.st) | `DISABLED=0`, `IDLE=10`, `PAUSED=15`, `WAIT_STACK_READY=20`, `SIGNAL_ROBOT=70`, `WAIT_TRAY_DONE=80`, `CHECK_P4_OCCUPIED=82`, `POS_M6_CYCLE=85`, `ELEV_TO_EDGE=90`, `RETRACT_POS=110`, `ELEV_TO_BOTTOM=120`, `DISCHARGE=130`, `WAIT_ELEV_EMPTY=140`, `ELEV_RETURN_TOP=150`, `FAULT=900` |
| `E_BoxSeqState` | [FB_BoxSequencer.st](../POUs/FB_BoxSequencer.st) | `DISABLED=0`, `IDLE=10`, `PAUSED=15`, `REQUEST_ELEVATOR_FEED=20`, `FEED_ELEVATOR=30`, `POS_M7_FWD=40`, `ELEV_TO_EDGE=50`, `SIGNAL_ROBOT=60`, `WAIT_PALLET_DONE=70`, `RETRACT_M7=80`, `ELEV_TO_BOTTOM=90`, `DISCHARGE=100`, `WAIT_ELEV_EMPTY=110`, `ELEV_RETURN_TOP=120`, `FAULT=900` |

## 6. Migracja znaczenia i brakujące zabezpieczenia

| Obszar | Konsekwencja dla HMI Krauss |
|---|---|
| Start/Stop/Kontynuuj/Opróżnij | Nie zmieniać tylko podpisów na Start zlecenia/Stop/Start/Koniec zlecenia. Potrzebne nowe komendy i koordynacja procesu. |
| Manual M1–M7 | HoldUp zatrzaskuje cel. Ścieżka manual i FB_StopperPair nie sprawdzają stanu taśmy; blokada taśma–stoper wymaga implementacji PLC. |
| Manual jog | Brak watchdogu HMI. Utrata wiadomości zwolnienia może pozostawić TRUE. Wyjście z ekranu nie zastępuje kontroli aktualności. |
| Reset | Utrzymana komenda może zadziałać po resecie w tym samym skanie. Docelowy Reset bez ruchu wymaga zmian i testów. |
| M6 i M8 | M6 ma wspólny cel pary; M8 jedną starą osłonę. Nie tworzyć pozornie niezależnych przycisków V201/V202 lub V401/V402 na tych samych starych polach. |
| M1–M5 → Vxxx | Mapowanie w interfaces.md jest proponowane; zatwierdzić mechanikę przed podpisaniem kontrolek nowymi numerami. |
| xSafetyOK / xRobotCommOk | Stałe zastępcze nie uzasadniają zielonego potwierdzenia sprawności. |
| Obecność na windzie | xOccP4 gaśnie podczas bazowania. Opróżnianie i gotowość wymagają pamięci ładunku/transferów. |
| Alarmy | Brak severity i działającego ACK. Przemianowanie Fault na Warning nie implementuje nowej obsługi. |
| GVL_IO i GVL_Robot | Podgląd diagnostyczny tylko R. Panel nie ma pisać do RAW, dout, robotOut ani lokalnych FB z pominięciem koordynacji. |
| robotOut.ack_pallet_placed i plc_fault | Istnieją i są kopiowane do RAW, ale nie mają producenta w logice; nie działające potwierdzenie/alarm. |
| Nowy proces | Zlecenie, Praca z robotem, nowe Stop/opróżnianie, Festo, pełny chwytak, EUROMAP, dostępność komend i reset stanów wymagają nowych implementowanych pól według mapy Vijeo. |

Cfg/Par urządzeń zawierają timeouty i filtrację, ale poza trzema nastawami hmiCmd nie mają interfejsu w tej GVL. Nie wiązać panelu bezpośrednio z lokalnym Cfg/Par: część, szczególnie elevPar, jest nadpisywana co skan. Potrzebny walidowany interfejs nastaw z jednostką, zakresem, warunkiem edycji i wartością przyjętą. TIME wymaga jawnej jednostki/konwersji; maski statusu napędu i kierunek osi pozostają konfiguracją inżynierską.

## 7. Weryfikacja wykazu

Porównano deklaracje GVL_HMI, odczyty/przypisania PRG_Main i źródła enumów. Osobne wiersze obejmują 208 liści runtime i stałą. Wszystkie 144 statusy mają przypisania, 36 z 37 komend ma odczyt, 23 z 26 pól alarmowych ma przypisanie. Importu symboli, kompilacji PLC/HMI, symulacji Vijeo i prób komunikacji nie wykonano. Zmiana tej dokumentacji nie zmienia źródeł ST/LS.
