# Zasoby tekstowe Vijeo Designer

Wykaz wartości dla dynamicznych obiektów **Text Display** z [instrukcji HMI](hmi-instructions.md). Dodaj zasób o podanej nazwie i wpisz do niego wszystkie jego wiersze. Nazwy `TR_…` są proponowanymi nazwami w Vijeo. Opisy i czynności alarmowe, teksty diagnostyczne i powody blokad są już dostarczane jako `STRING` z PLC i wyświetla je **String Display**.

## Przypisanie zasobów

| Resource | Kod wejściowy | Liczba stanów |
|---|---|---:|
| `TR_Tryb` | `_SoM.MyController.Application.GVL_HMI.hmiV2.state.uiMode` | 2 |
| `TR_StanZlecenia` | `_SoM.MyController.Application.GVL_HMI.hmiV2.state.uiOrderState` | 5 |
| `TR_Produkcja` | `_SoM.MyController.Application.GVL_HMI.hmiV2.state.uiProduction` | 3 |
| `TR_Program` | `_SoM.MyController.Application.GVL_HMI.hmiV2.actual.uiProgram` lub `_SoM.MyController.Application.GVL_Robot.Rx.production_program` | 3 |
| `TR_StanWykonania` | `_SoM.MyController.Application.GVL_HMI.hmiV2.state.uiExecutionState` | 7 |
| `TR_KrokOprozniania` | `_SoM.MyController.Application.GVL_HMI.hmiV2.station.drainStep` | 6 |
| `TR_WlascicielTransportu` | `_SoM.MyController.Application.GVL_HMI.hmiV2.station.owner` | 5 |
| `TR_OperacjaTransportu` | `_SoM.MyController.Application.GVL_HMI.hmiV2.station.action_` | 7 |
| `TR_KierunekTasmy` | `_SoM.MyController.Application.GVL_HMI.hmiStatus.iConvTopDirection` albo `_SoM.MyController.Application.GVL_HMI.hmiStatus.iConvBottomDirection` | 4 |
| `TR_KierunekTasmyWindy` | `_SoM.MyController.Application.GVL_HMI.hmiStatus.iConvElevDirection` | 4 |
| `TR_BarieraZaladunku` | Lokalny kod z `_SoM.MyController.Application.GVL_HMI.hmiIo.barrierValid` i `_SoM.MyController.Application.GVL_HMI.hmiIo.barrierBlocked` | 3 |
| `TR_LadunekP4` | Lokalny kod z `_SoM.MyController.Application.GVL_HMI.vijeo.stationOccupied[3]`, `_SoM.MyController.Application.GVL_HMI.hmiV2.station.materialKnown` i `_SoM.MyController.Application.GVL_HMI.hmiV2.station.dataValid` | 3 |
| `TR_StanWindy` | `_SoM.MyController.Application.GVL_HMI.hmiStatus.uiElevState` | 8 |
| `TR_StanRozladunku` | `_SoM.MyController.Application.GVL_HMI.hmiStatus.uiBottomState` | 11 |
| `TR_StanMagazynu` | `_SoM.MyController.Application.GVL_HMI.hmiStatus.uiStorageState` | 11 |
| `TR_OczekiwanieRobota` | `_SoM.MyController.Application.GVL_HMI.hmiV2.state.uiRobotWaitCode` | 8 |
| `TR_StanPrzeplywuGornego` | `_SoM.MyController.Application.GVL_HMI.hmiStatus.uiTopFlowState`, jeśli ma być pokazany jako etykieta ze słownika. Instrukcja panelu przewiduje liczbę i opis PLC. | 14 |

Dla obu zasobów kierunku podaj lokalnie kod 2, gdy odpowiednie `_SoM.MyController.Application.GVL_HMI.hmiStatus.xConvTopRunning`, `_SoM.MyController.Application.GVL_HMI.hmiStatus.xConvBottomRunning` lub `_SoM.MyController.Application.GVL_HMI.hmiStatus.xConvElevRunning` jest fałszywe. W pozostałych przypadkach podaj kierunek z PLC. Dla bariery podaj 2 przy nieważnym odczycie, w pozostałych przypadkach 0 lub 1 według `_SoM.MyController.Application.GVL_HMI.hmiIo.barrierBlocked`. Dla P4 podaj 2, jeśli stan materiału jest nieuzgodniony lub dane są nieważne. W pozostałych przypadkach podaj 0 lub 1 według `_SoM.MyController.Application.GVL_HMI.vijeo.stationOccupied[3]`. Kod 2 w tych czterech zasobach jest lokalnym kodem HMI. Dla każdego kodu spoza tabeli pokaż „Kod” i otrzymaną liczbę. Dla kierunku zachowaj wejście ze znakiem, żeby odróżnić −1 od 1.

## Wartości do wprowadzenia

| Resource | Integer | Tekst do wyświetlenia |
|---|---:|---|
| `TR_Tryb` | 10 | Manual |
| `TR_Tryb` | 20 | Auto |
| `TR_StanZlecenia` | 0 | Zamknięte |
| `TR_StanZlecenia` | 10 | Otwarte |
| `TR_StanZlecenia` | 20 | Kończenie |
| `TR_StanZlecenia` | 30 | Opróżnianie |
| `TR_StanZlecenia` | 90 | Wymagane uzgodnienie |
| `TR_Produkcja` | 0 | Brak |
| `TR_Produkcja` | 10 | Pojemniki |
| `TR_Produkcja` | 20 | Blistry |
| `TR_Program` | 0 | Brak / nieznany |
| `TR_Program` | 1 | Pojemniki |
| `TR_Program` | 2 | Blistry |
| `TR_StanWykonania` | 0 | Postój |
| `TR_StanWykonania` | 10 | Gotowy |
| `TR_StanWykonania` | 20 | Praca |
| `TR_StanWykonania` | 30 | Zatrzymywanie |
| `TR_StanWykonania` | 40 | Zatrzymany |
| `TR_StanWykonania` | 50 | Opróżnianie |
| `TR_StanWykonania` | 90 | Wymagane uzgodnienie |
| `TR_KrokOprozniania` | 0 | Bezczynny |
| `TR_KrokOprozniania` | 10 | Wybór operacji |
| `TR_KrokOprozniania` | 20 | Oczekiwanie na wykonanie |
| `TR_KrokOprozniania` | 40 | Pauza |
| `TR_KrokOprozniania` | 100 | Ukończone |
| `TR_KrokOprozniania` | 900 | Błąd |
| `TR_WlascicielTransportu` | 0 | Brak |
| `TR_WlascicielTransportu` | 10 | Produkcja |
| `TR_WlascicielTransportu` | 20 | Opróżnianie |
| `TR_WlascicielTransportu` | 30 | Lokalne wydanie |
| `TR_WlascicielTransportu` | 40 | Manual |
| `TR_OperacjaTransportu` | 0 | Brak |
| `TR_OperacjaTransportu` | 10 | Winda w górę |
| `TR_OperacjaTransportu` | 20 | Winda w dół |
| `TR_OperacjaTransportu` | 30 | Podanie |
| `TR_OperacjaTransportu` | 40 | Rozładunek |
| `TR_OperacjaTransportu` | 50 | Przesunięcie |
| `TR_OperacjaTransportu` | 60 | Wydanie |
| `TR_KierunekTasmy` | -1 | Wstecz |
| `TR_KierunekTasmy` | 0 | Postój |
| `TR_KierunekTasmy` | 1 | Naprzód |
| `TR_KierunekTasmy` | 2 | Brak komendy ruchu |
| `TR_KierunekTasmyWindy` | -1 | OUT |
| `TR_KierunekTasmyWindy` | 0 | Postój |
| `TR_KierunekTasmyWindy` | 1 | IN |
| `TR_KierunekTasmyWindy` | 2 | Brak komendy ruchu |
| `TR_BarieraZaladunku` | 0 | Wolna |
| `TR_BarieraZaladunku` | 1 | Przerwana |
| `TR_BarieraZaladunku` | 2 | Stan nieznany |
| `TR_LadunekP4` | 0 | Brak ładunku |
| `TR_LadunekP4` | 1 | Ładunek obecny |
| `TR_LadunekP4` | 2 | Stan nieznany |
| `TR_StanWindy` | 0 | Wyłączona |
| `TR_StanWindy` | 10 | Postój |
| `TR_StanWindy` | 20 | Ręcznie w górę |
| `TR_StanWindy` | 21 | Ręcznie w dół |
| `TR_StanWindy` | 30 | Automatycznie w górę |
| `TR_StanWindy` | 31 | Automatycznie w dół |
| `TR_StanWindy` | 40 | Zatrzymywanie |
| `TR_StanWindy` | 900 | Błąd |
| `TR_StanRozladunku` | 0 | Inicjalizacja |
| `TR_StanRozladunku` | 10 | Postój |
| `TR_StanRozladunku` | 20 | Sprawdzanie warunków |
| `TR_StanRozladunku` | 30 | Przejazd |
| `TR_StanRozladunku` | 40 | Oczekiwanie na zatrzymanie |
| `TR_StanRozladunku` | 50 | Zakończono |
| `TR_StanRozladunku` | 60 | Pauza opróżniania |
| `TR_StanRozladunku` | 70 | Uzgadnianie rozładunku |
| `TR_StanRozladunku` | 80 | Oczekiwanie na odbiór |
| `TR_StanRozladunku` | 90 | Ustawianie stoperów |
| `TR_StanRozladunku` | 900 | Błąd |
| `TR_StanMagazynu` | 0 | Wyłączony |
| `TR_StanMagazynu` | 10 | Postój |
| `TR_StanMagazynu` | 20 | Oczekiwanie na zgodę dla robota |
| `TR_StanMagazynu` | 30 | Otwieranie dla robota |
| `TR_StanMagazynu` | 40 | Otwarty dla robota |
| `TR_StanMagazynu` | 50 | Zamykanie po dostępie robota |
| `TR_StanMagazynu` | 60 | Zamykanie przed dostępem operatora |
| `TR_StanMagazynu` | 70 | Oczekiwanie na zgodę dla operatora |
| `TR_StanMagazynu` | 80 | Odryglowany dla operatora |
| `TR_StanMagazynu` | 90 | Oczekiwanie na zaryglowanie po dostępie operatora |
| `TR_StanMagazynu` | 900 | Błąd |
| `TR_OczekiwanieRobota` | 0 | Brak |
| `TR_OczekiwanieRobota` | 20 | Oczekiwanie na partię |
| `TR_OczekiwanieRobota` | 30 | Oczekiwanie na formę |
| `TR_OczekiwanieRobota` | 40 | Oczekiwanie na chwytak |
| `TR_OczekiwanieRobota` | 50 | Próżnia lub przedmuch |
| `TR_OczekiwanieRobota` | 60 | Obszar lub nośnik |
| `TR_OczekiwanieRobota` | 70 | Oczekiwanie na ACK |
| `TR_OczekiwanieRobota` | 80 | Operator lub Start |
| `TR_StanPrzeplywuGornego` | 0 | Inicjalizacja |
| `TR_StanPrzeplywuGornego` | 10 | Postój |
| `TR_StanPrzeplywuGornego` | 20 | Zatrzymywanie taśmy |
| `TR_StanPrzeplywuGornego` | 30 | Ustawianie stoperów |
| `TR_StanPrzeplywuGornego` | 40 | Przejazd |
| `TR_StanPrzeplywuGornego` | 50 | Zwłoka po zatrzymaniu |
| `TR_StanPrzeplywuGornego` | 55 | Cofanie M5 |
| `TR_StanPrzeplywuGornego` | 57 | Oczekiwanie na M5 |
| `TR_StanPrzeplywuGornego` | 60 | Blokowanie pozycji docelowej |
| `TR_StanPrzeplywuGornego` | 70 | Oczekiwanie na blokadę |
| `TR_StanPrzeplywuGornego` | 80 | Zakończono |
| `TR_StanPrzeplywuGornego` | 90 | Zwalnianie P1 |
| `TR_StanPrzeplywuGornego` | 100 | Oczekiwanie na blokadę P1 |
| `TR_StanPrzeplywuGornego` | 900 | Błąd |
