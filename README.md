# SE-ELDA-Krauss

Adaptacja stanowiska paletyzacji do wtryskarki Krauss, robota **FANUC M-20iD/25 z R-30iB Mate Plus** oraz rozproszonych I/O **Festo AP**.

PLC Schneider Electric M241 pośredniczy między robotem a wtryskarką: robot i Festo komunikują się z PLC przez EtherNet/IP, a wtryskarka przez elektryczny interfejs EUROMAP 67. Stanowisko obejmuje załadunek, windę, rozładunek, magazyn przekładek i robota. Tryby produkcji na HMI: **Pojemniki** i **Blistry**.

## Stan projektu

**Etap dokumentacyjny adaptacji: przygotowany. Implementacja zmian sterowania: przed rozpoczęciem.**

Źródła PLC i FANUC są odziedziczoną bazą poprzedniego stanowiska. Dokumentacja opisuje uzgodnione zachowanie docelowe i wskazuje braki sprzętowe; nie potwierdza gotowości obecnego programu do pracy na nowej maszynie. W etapie dokumentacyjnym nie zmieniono plików ST, LS, VA ani DG. Następnie uporządkowano źródła PLC w `Modules/` i wydzielono typy do `DUTs/`, bez zmiany logiki sterowania.

Aktualizacja 2026-11-14: przygotowano [kontrakt komunikacji PLC–robot](docs/robot-plc-contract.md), pełną migrację symboliczną dostępnych I/O oraz analizę modernizacji obu programów. Mapa fizyczna i przepisanie sterowania pozostają zależne od danych sprzętowych; [raport weryfikacji](docs/robot-communication-verification.md) rozróżnia wykonany przegląd od niewykonanych prób.

## Dokumentacja

| Dokument | Przeznaczenie |
|---|---|
| [Instrukcja dla człowieka](human-instructions.md) | Kolejność modułów, dobór modeli i poziomów rozumowania, przygotowanie projektu Vijeo |
| [Ekrany i elementy HMI](docs/hmi-instructions.md) | Lista 20 ekranów i konfiguracja ich elementów bez nazw zmiennych |
| [Docelowa mapa Vijeo](docs/hmi-vijeo-map.md) | Ekrany, nowe komendy i statusy, blokady, parametry, alarmy i próby HMI |
| [Obecne zmienne HMI](docs/hmi-existing-variables.md) | Wszystkie 208 pól istniejącej GVL_HMI, ich powiązania i ograniczenia |
| [Diagnostyka I/O dla HMI](docs/hmi-io-diagnostics.md) | Wszystkie 166 wierszy sygnałów i 12 urządzeń z kopii Excela |
| [Instrukcja dla agenta](AGENTS.md) | Zasady pracy, granice zapisów, architektura i konwencje programowania |
| [Założenia projektowe](docs/project-assumptions.md) | Uzgodniony proces, zlecenia, tryby, stacje, alarmy i HMI |
| [Interfejsy i mapowanie](docs/interfaces.md) | Podział I/O, kontrakty PLC–robot–Festo–wtryskarka oraz migracja oznaczeń |
| [Plan implementacji i odbioru](docs/implementation-plan.md) | Etapy, macierz wymagań, scenariusze testów i rejestr braków |
| [Kontrakt PLC–robot v1](docs/robot-plc-contract.md) | Żądania urządzeń, ACK zdarzeń, synchronizacja, Stop i EUROMAP; katalog JSON i migracja CSV |
| [Modernizacja FANUC](docs/robot-modernization.md) | Wspólne procedury, zgodność instrukcji, rejestry i warunki przepisania dwóch main |
| [Analiza materiałów współdzielonych](docs/workspace-analysis.md) | Pneumatyka, EUROMAP, kanały potwierdzeń, backupy, rozbieżności i parametr liczby detali |
| [Robot i kontroler — tabliczki](docs/robot-hardware.md) | Potwierdzone modele, typy, numery seryjne, daty, masy i zasilanie; odczyt 2026-11-14 |
| [Materiały źródłowe](docs/sources/README.md) | Dokumenty klienta, pochodzenie, rewizje, kopie i sumy kontrolne |

## Struktura

- `GVLs/` — obecne deklaracje I/O, robota i HMI.
- `Modules/` — każdy FB urządzenia lub sekwencer ma własny katalog z plikiem `FB_*.st` i podkatalogiem `DUTs/` (jeden typ danych na plik ST); programy `PRG_*.st` pozostają bezpośrednio w `Modules/`.
- `ROBOT/` — dwa programy główne FANUC i częściowy eksport danych.
- `agents/` — odsyłacze do aktualnych instrukcji oraz odziedziczony materiał Control_ATV.
- `docs/` — dokumentacja adaptacji.
- `irrelevant/` — materiał wyłączony z pracy agenta.

## Praca nad adaptacją

Najpierw zapoznaj się z założeniami, następnie wybierz etap z planu implementacji i sprawdź zależne wpisy GAP. Parametry sprzętowe wymagają potwierdzenia przed przypisaniem adresów lub uruchomieniem urządzeń.

Wszystkie zapisy, także tymczasowe, muszą pozostawać wewnątrz `se-elda-krauss`. Poprzednie repozytorium i zewnętrzne materiały wejściowe służą tylko do odczytu.

Zewnętrzne projekty PLC/HMI, fizyczny backup FANUC i przykład EDS są dostępne i zarejestrowane w analizie źródeł; nie zostały skopiowane do repozytorium ani zatwierdzone jako kompletne środowisko budowania. Kompilacja, weryfikacja FANUC i próby na stanowisku są oddzielnymi etapami odbioru; nie zostały wykonane podczas przygotowania dokumentacji.
