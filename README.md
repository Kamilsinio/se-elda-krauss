# SE-ELDA-Krauss

Adaptacja stanowiska paletyzacji do wtryskarki Krauss, robota **FANUC M-20iD/25 z R-30iB Mate Plus** oraz rozproszonych I/O **Festo AP**.

PLC Schneider Electric M241 pośredniczy między robotem a wtryskarką: robot i Festo komunikują się z PLC przez EtherNet/IP, a wtryskarka przez elektryczny interfejs EUROMAP 67. Stanowisko obejmuje załadunek, windę, rozładunek, magazyn przekładek i robota. Tryby produkcji na HMI: **Pojemniki** i **Blistry**.

## Stan projektu

**Etap dokumentacyjny adaptacji: przygotowany. Implementacja zmian sterowania: przed rozpoczęciem.**

Źródła PLC i FANUC są odziedziczoną bazą poprzedniego stanowiska. Dokumentacja opisuje uzgodnione zachowanie docelowe i wskazuje braki sprzętowe; nie potwierdza gotowości obecnego programu do pracy na nowej maszynie. W tym etapie nie zmieniono plików ST, LS, VA ani DG.

## Dokumentacja

| Dokument | Przeznaczenie |
|---|---|
| [Instrukcja dla człowieka](human-instructions.md) | Kolejność modułów, dobór modeli i poziomów rozumowania, przygotowanie projektu Vijeo |
| [Docelowa mapa Vijeo](docs/hmi-vijeo-map.md) | Ekrany, nowe komendy i statusy, blokady, parametry, alarmy i próby HMI |
| [Obecne zmienne HMI](docs/hmi-existing-variables.md) | Wszystkie 208 pól istniejącej GVL_HMI, ich powiązania i ograniczenia |
| [Diagnostyka I/O dla HMI](docs/hmi-io-diagnostics.md) | Wszystkie 166 wierszy sygnałów i 12 urządzeń z kopii Excela |
| [Instrukcja dla agenta](AGENTS.md) | Zasady pracy, granice zapisów, architektura i konwencje programowania |
| [Założenia projektowe](docs/project-assumptions.md) | Uzgodniony proces, zlecenia, tryby, stacje, alarmy i HMI |
| [Interfejsy i mapowanie](docs/interfaces.md) | Podział I/O, kontrakty PLC–robot–Festo–wtryskarka oraz migracja oznaczeń |
| [Plan implementacji i odbioru](docs/implementation-plan.md) | Etapy, macierz wymagań, scenariusze testów i rejestr braków |
| [Materiały źródłowe](docs/sources/README.md) | Dokumenty klienta, pochodzenie, rewizje, kopie i sumy kontrolne |

## Struktura

- `GVLs/` — obecne deklaracje I/O, robota i HMI.
- `POUs/` — obecne FB urządzeń, sekwencery i programy PLC.
- `ROBOT/` — dwa programy główne FANUC i częściowy eksport danych.
- `agents/` — odsyłacze do aktualnych instrukcji oraz odziedziczony materiał Control_ATV.
- `docs/` — dokumentacja adaptacji.
- `irrelevant/` — materiał wyłączony z pracy agenta.

## Praca nad adaptacją

Najpierw zapoznaj się z założeniami, następnie wybierz etap z planu implementacji i sprawdź zależne wpisy GAP. Parametry sprzętowe wymagają potwierdzenia przed przypisaniem adresów lub uruchomieniem urządzeń.

Wszystkie zapisy, także tymczasowe, muszą pozostawać wewnątrz `se-elda-krauss`. Poprzednie repozytorium i zewnętrzne materiały wejściowe służą tylko do odczytu.

W repozytorium nie ma obecnie natywnego projektu Machine Expert/HMI ani kompletnego środowiska budowania. Kompilacja, weryfikacja FANUC i próby na stanowisku są oddzielnymi etapami odbioru; nie zostały wykonane podczas przygotowania dokumentacji.
