# SE-ELDA-Krauss

Adaptacja stanowiska paletyzacji do wtryskarki Krauss, robota **FANUC M-20iD/25 z R-30iB Mate Plus** oraz rozproszonych I/O **Festo AP**.

PLC Schneider Electric M241 pośredniczy między robotem a wtryskarką: robot i Festo komunikują się z PLC przez EtherNet/IP, a wtryskarka przez elektryczny interfejs EUROMAP 67. Stanowisko obejmuje załadunek, windę, rozładunek, magazyn przekładek i robota. Tryby produkcji na HMI: **Pojemniki** i **Blistry**.

## Stan projektu

**Dokumentacja adaptacji przygotowana. Komunikacja FANUC v2, programy tacek i BOX oraz logiki BG są przygotowane w źródłach i sprawdzone offline. Import i uruchomienie pozostają do wykonania.**

Źródła PLC i archiwalne programy FANUC są odziedziczoną bazą poprzedniego stanowiska. Dokumentacja opisuje uzgodnione zachowanie docelowe i wskazuje braki sprzętowe; nie potwierdza gotowości obecnego programu do pracy na nowej maszynie. W etapie dokumentacyjnym nie zmieniono plików ST, LS, VA ani DG. Następnie uporządkowano źródła PLC w `Modules/` i wydzielono typy do `DUTs/`, bez zmiany logiki sterowania.

Aktualizacja 2026-11-15: przygotowano [kontrakt komunikacji PLC–robot](docs/robot-plc-contract.md), pełną migrację symboliczną dostępnych I/O oraz analizę modernizacji obu programów. Dodano [pakiet komunikacji FANUC](ROBOT/COMM/README.md): 17 źródeł komunikacji LIVE, propozycję mapy 80 bajtów na kierunek oraz odizolowany pakiet TEST. [Program tacek i BG](ROBOT/TRAY/README.md) obejmuje częściowe odkładanie, próbki, odrzuty i Stop N+1. Punkty nie są nauczone, powiązania natywne BG są nieuzupełnione; ruch jest zablokowany. [Program BOX](ROBOT/BOX/README.md) obsługuje trzy sekcje, warstwy i przekładki. [COMMON](ROBOT/COMMON/README.md) zawiera opisy zasobów; BG pilnuje jednego aktywnego main. Konfiguracja urządzeń i PLC v2 pozostają do wykonania; [raport weryfikacji](docs/robot-communication-verification.md) rozróżnia wykonany przegląd od niewykonanych prób.

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
| [Kontrakt PLC–robot v2](docs/robot-plc-contract.md) | Żądania urządzeń, ACK zdarzeń, synchronizacja, Stop i EUROMAP; katalog JSON i migracja CSV |
| [Pakiet komunikacji FANUC](ROBOT/COMM/README.md) | Źródła LS, mapa 80 B/kierunek, API R/F, konfiguracja i granice testów |
| [Program BOX](ROBOT/BOX/README.md) | Kuwety/box, trzy sekcje, warstwy, przekładki i recovery |
| [COMMON](ROBOT/COMMON/README.md) | Opisy zmiennych, właściciel, komendy operatora i inicjalizacja |
| [Program tacek i BG](ROBOT/TRAY/README.md) | Źródła, parametry, punkty do nauczenia, recovery i warunki uruchomienia |
| [Modernizacja FANUC](docs/robot-modernization.md) | Dwa pełne main, komentarze, zgodność instrukcji i zasoby |
| [Analiza materiałów współdzielonych](docs/workspace-analysis.md) | Pneumatyka, EUROMAP, kanały potwierdzeń, backupy, rozbieżności i parametr liczby detali |
| [Robot i kontroler — tabliczki](docs/robot-hardware.md) | Potwierdzone modele, typy, numery seryjne, daty, masy i zasilanie; odczyt 2026-11-14 |
| [Materiały źródłowe](docs/sources/README.md) | Dokumenty klienta, pochodzenie, rewizje, kopie i sumy kontrolne |

## Struktura

- `GVLs/` — obecne deklaracje I/O, robota i HMI.
- `Modules/` — każdy FB urządzenia lub sekwencer ma własny katalog z plikiem `FB_*.st` i podkatalogiem `DUTs/` (jeden typ danych na plik ST); programy `PRG_*.st` pozostają bezpośrednio w `Modules/`.
- `ROBOT/COMM/` — nowe źródła komunikacji FANUC, mapa i interfejs aplikacji. Archiwalne dwa main i eksporty danych użytkownik przeniósł do `../Robot M20iD/old/ROBOT` (tylko odczyt).
- `ROBOT/TRAY/`, `ROBOT/BOX/`, `ROBOT/COMMON/`, `ROBOT/BG/` — dwa pełne main, słownik zasobów i monitorowanie; punkty i native bindings wymagają zatwierdzenia.
- `ROBOT/TEST/` — izolowany test komunikacji, niedopuszczony do wspólnego importu z LIVE/produkcją.
- `tools/` — generatory komunikacji/produkcji, audyt kontraktu i testy offline rzeczywistych instrukcji LS.
- `agents/` — odsyłacze do aktualnych instrukcji oraz odziedziczony materiał Control_ATV.
- `docs/` — dokumentacja adaptacji.
- `irrelevant/` — materiał wyłączony z pracy agenta.

## Praca nad adaptacją

Najpierw zapoznaj się z założeniami, następnie wybierz etap z planu implementacji i sprawdź zależne wpisy GAP. Parametry sprzętowe wymagają potwierdzenia przed przypisaniem adresów lub uruchomieniem urządzeń.

Wszystkie zapisy, także tymczasowe, muszą pozostawać wewnątrz `se-elda-krauss`. Poprzednie repozytorium i zewnętrzne materiały wejściowe służą tylko do odczytu.

Zewnętrzne projekty PLC/HMI, fizyczny backup FANUC i przykład EDS są dostępne i zarejestrowane w analizie źródeł; nie zostały skopiowane do repozytorium ani zatwierdzone jako kompletne środowisko budowania. Kompilacja, weryfikacja FANUC i próby na stanowisku są oddzielnymi etapami odbioru; nie zostały wykonane podczas przygotowania dokumentacji.
