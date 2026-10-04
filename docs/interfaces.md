# Interfejsy i mapowanie SE-ELDA-Krauss

Status: kontrakty docelowe do implementacji; adresy sprzętowe niezatwierdzone. Data bazowa: 2026-10-04.

Dokument uzupełnia [założenia](project-assumptions.md) i [plan implementacji](implementation-plan.md). Nie jest gotową konfiguracją EtherNet/IP ani zatwierdzonym wykazem zacisków. Dane wejściowe opisano w [rejestrze źródeł](sources/README.md).

## 1. Topologia i aktualność danych

PLC M241 pełni rolę skanera EtherNet/IP dla robota i bramki Festo AP. Wewnątrz systemu Festo poszczególne terminale/moduły są połączone magistralą AP; nie przypisywać każdemu z nich osobnego adresu IP.

Adresy wskazane w schemacie P0001, do potwierdzenia z konfiguracją:

| Urządzenie | Adres ze schematu | Stan |
|---|---|---|
| PLC | 192.168.0.1 | Źródłowy, niepotwierdzony odczytem urządzenia |
| HMI | 192.168.0.10 | Źródłowy, niepotwierdzony odczytem urządzenia |
| Bramka Festo BAT100 | 192.168.0.20 | Źródłowy, niepotwierdzony odczytem urządzenia |
| ATV320 | 192.168.0.30 | Źródłowy; nie rozstrzyga protokołu lub konfiguracji osi |
| Robot | 192.168.0.40 | Źródłowy, niepotwierdzony odczytem urządzenia |

Maska widoczna w schemacie: 255.255.255.0. Brak weryfikacji z urządzeń.

Konfiguracja wymaga EDS, identyfikatorów assembly, kierunków i rozmiarów danych, RPI, timeoutów, kolejności bajtów/bitów i diagnostyki zgodnej z rzeczywistymi urządzeniami (GAP-03/04/06). Nie określać tych parametrów na podstawie numeracji starego GVL.

Stan połączenia i aktualność obrazu danych to jawne warunki logiczne. Stały bit TRUE lub niezmieniające się dane procesu nie dowodzą poprawnej komunikacji. Źródłem ważności musi być diagnostyka skanera/urządzenia, uzupełniona uzgodnionym mechanizmem kontroli aktualności. Powrót łączności wymaga uzgodnienia stanu przed wznowieniem ruchu.

## 2. Mapowanie oznaczeń

**POTWIERDZONE FUNKCJONALNIE** oznacza zgodność funkcji ze źródłem lub decyzją użytkownika, nie potwierdzenie kanału i polaryzacji. **PROPONOWANE** oznacza wniosek wymagający potwierdzenia mechaniki w GAP-08.

Stare M2/M3/M4, mimo nazwy „stoper”, podnoszą stos nad taśmę. Porównywać rzeczywistą funkcję, a nie samą nazwę zmiennej.

| Stare oznaczenie | Funkcja | Nowe oznaczenie | Status |
|---|---|---|---|
| M1 | Pozycjonowanie załadunku P1 | ST.1, V107/V108 — loading stopper 1 | PROPONOWANE |
| M2 | Podniesienie/blokowanie stosu P1 | ST.1, V101/V102 — loading elevator 1 | PROPONOWANE |
| M3 | Podniesienie/blokowanie stosu P2 | ST.1, V103/V104 — loading elevator 2 | PROPONOWANE |
| M4 | Podniesienie/blokowanie stosu P3 | ST.1, V105/V106 — loading elevator 3 | PROPONOWANE |
| M5 | Pozycjonowanie blistrów do poboru P3 | ST.1, V109/V110 — loading stopper 2 | PROPONOWANE |
| M6 | Pozycjonery blistrów na windzie | ST.2, V201/V202 | POTWIERDZONE FUNKCJONALNIE; dwa niezależne sterowania |
| M7 | Pozycjoner pojemnika na windzie | ST.2, V203 | POTWIERDZONE FUNKCJONALNIE |
| M8 | Osłona magazynu od strony robota | ST.4, V401/V402 | POTWIERDZONE FUNKCJONALNIE; dwie osłony, WORK = zamknięcie |
| Nowe mechanizmy | Stopery dolnego transportera | ST.3, V301/V302 przy B302 i V303/V304 przy B303 | Nowa funkcja w sekwencji |
| P1/P2/P3 | Obecność na górnej taśmie | B101/B102/B103 | POTWIERDZONE FUNKCJONALNIE |
| P4 | Obecność na windzie i bazowanie wysokości | B205 | Funkcja potwierdzona; podłączenie OTWARTE |
| Czujnik obszaru wyjazdu windy | Potwierdzenie opróżnienia obszaru | B301 | Powiązanie i polaryzacja do potwierdzenia |
| P5/P6/P7 | Obecność na dolnej taśmie | B302/B303/B304 | POTWIERDZONE FUNKCJONALNIE; B304 także odbiór operatora |
| Czujniki wysokości | Góra, blisko góry, blisko dołu, dół | B201/B202/B203/B204 | Powiązanie funkcji; polaryzacje do sprawdzenia |
| Niski poziom / pusty magazyn | Stan przekładek | B401/B402 | POTWIERDZONE FUNKCJONALNIE |
| Osobna bariera ST.1 | Przejście całego stosu | Brak oznaczenia | OTWARTE, GAP-01 |

Arkusz zawiera wspólne nazwy komend dla par oznaczonych jako równoległe. Dwa wiersze opisujące siłowniki nie dowodzą istnienia dwóch niezależnych kanałów wyjściowych. Z kolei opis zaworu 5/3 z pojedynczym wierszem „do WORK” nie jest kompletną mapą cewek HOME/WORK.

Nie przeliczać mechanicznie zapisów kanałów takich jak `%I2.10` z arkusza na adresy `%IX` starego kodu. Adresy i symboliczne powiązania mają wynikać z konfiguracji urządzeń w Machine Expert.

### Festo AP

| Element | Funkcja według mapy |
|---|---|
| BAT100 / BAT101 | Bramka Ethernet/IP oraz wejścia ST.4 |
| BAT200–BAT205 | Terminal i wejścia ST.1/ST.3 |
| BAT300 / BAT301 | Terminal i wejścia ST.2 |
| BAT400 / BAT401 | Terminal i wejścia ST.5 |

ST.5: V501 to oś pneumatyczna „axis 7”, V502–V505 to siłowniki chwytaka 1–4, V506–V508 to rezerwy, V509–V513 to obwody próżni 1–5. Czujniki V502–V505 są w arkuszu przypisane do KEC3, czujniki V501 do BAT401. Nadal przechodzą przez PLC; nie utożsamiać każdego potwierdzenia chwytaka z fizycznym wejściem Festo.

Brakuje pełnego przypisania potwierdzeń podciśnienia i komend przedmuchu. Rezerwy nie są wolnymi kanałami do dowolnego zagospodarowania bez sprawdzenia konfiguracji.

### Minimalny rekord zatwierdzonej mapy I/O

Dla każdego sygnału zapisać: stacja, mechanizm/sygnał, źródło i odbiorca, kierunek z perspektywy PLC, nazwa logiczna, urządzenie/moduł/kanał lub bit assembly, adres z projektu, znaczenie 0/1, filtracja, właściciel wyjścia, zachowanie przy utracie danych oraz źródło potwierdzenia.

Dla zaworu dodatkowo: liczba i funkcja cewek, stan bez energii, sposób utrzymania pozycji/ładunku. Dla sygnału EUROMAP dodatkowo: zacisk i rozdzielenie sygnału procesowego od obwodu bezpieczeństwa. Puste pola pozostają oznaczone OTWARTE; nie dostają fikcyjnych adresów.

## 3. Stan odziedziczonych interfejsów

- `GVL_Robot` ma historyczne 32 bity w każdym kierunku: wejścia PLC %IX28.0–%IX31.7 i wyjścia %QX10.0–%QX13.7.
- Ten kontrakt zawiera przez PLC tylko obwód próżni 5. Nie zawiera pełnej nowej wymiany EUROMAP ani BAT4.
- `xRobotCommOk := TRUE` jest zastępczym statusem, nie docelową diagnostyką.
- `PRG_IO_Read/Write` mapują stary układ; nie stanowią nowej konfiguracji Festo/EUROMAP.
- LS używają IMM DI101/102/103/106/107 i DO101–106; chwytaka DO111–120, DI112–119, RI1–6, RO1–8 oraz DI32/DO31/DO32 dla próżni 5. Numery są historyczne.
- DO17 ma zależne od programu znaczenie: zakończenie palety w blistrach i warstwy w pojemnikach. Nie utożsamiać go z zakończeniem całego stosu.
- HOME DO7 i identyfikacja programu DO12/13 nie są generowane w dostarczonych dwóch programach głównych. Potrzebny jest pełny backup i konfiguracja sygnałów.
- W programie blistrów kroki LS 210/212 zawierają zapis `//WAIT` dotyczący wyrzutnika i próżni 1–4. Wymagają rozstrzygnięcia przy adaptacji.
- Brakuje podprogramów `BB_GRIPPER_RESET`, `BB_IMM_RESET`, `BB_RESET_VAC5`.

Schemat P0001 i arkusz nadal przedstawiają przewodowe sygnały procesowe robota. Zgodnie z decyzją docelowo proces jest wymieniany po EtherNet/IP, ale rzeczywiste wykonanie sprzętu trzeba uzgodnić w GAP-09. Nie pozostawiać dwóch równoległych źródeł sterowania.

## 4. PLC ↔ FANUC

| Kierunek | Docelowe grupy danych |
|---|---|
| PLC → robot | Oczekiwany rodzaj produkcji, pozwolenie pracy, żądanie zakończenia rozpoczętych operacji, gotowość stosu/windy/magazynu, próbki, potwierdzenia zdarzeń, stan blokad, sygnały IMM, potwierdzenia chwytaka i ważność danych |
| Robot → PLC | Tryb/gotowość, HOME, uruchomiony program, faza pracy, potwierdzenie zakończenia operacji, zdarzenia odkładania i zakończenia stosu/pojemnika, żądanie magazynu, żądania IMM, żądania pneumatyki, kod kroku/alarmu i ważność danych |

Oczekiwany rodzaj produkcji nie jest poleceniem zdalnego wyboru programu. Operator uruchamia właściwy program na FANUC, PLC sprawdza jego zgodność przed pozwoleniem pracy.

Zezwolenia i stany przekazywać poziomowo. Dla zdarzeń wymagających jednokrotnej obsługi przyjąć wymianę żądanie/ACK: nadawca trzyma żądanie do potwierdzenia, kasuje żądanie, odbiorca kasuje ACK; następne zdarzenie dopiero po zakończeniu wymiany. Odbiorca wykonuje skutek raz, a nie w każdym skanie utrzymanego żądania. Utrata komunikacji i restart wymagają uzgodnienia stanu; nie odtwarzać starego bitu jako nowego zdarzenia.

Rozróżnić odłożenie tacki/przekładki, odłożenie partii produktów, zakończenie warstwy i zakończenie stosu/pojemnika. Liczniki i potwierdzenia muszą odpowiadać konkretnej operacji.

Potwierdzenie zatrzymania oznacza rozliczenie wszystkich rozpoczętych wtrysków i związanych operacji robota, nie samo osiągnięcie HOME. PLC łączy to z potwierdzeniem zakończenia transferów stacji.

Numery bitów/rejestrów i szerokość danych zostaną ustalone po inwentaryzacji backupu oraz assembly. Nie upychać nowych sygnałów w historycznych 32 bitach bez zatwierdzonej mapy.

## 5. PLC ↔ Festo oraz pneumatyka

PLC rozstrzyga końcowe wyjścia Festo. Robot wysyła logiczne żądania chwytaka, a PLC odsyła rzeczywiste potwierdzenia i diagnostykę. Komenda nie jest potwierdzeniem ruchu.

Dla V201/V202 oraz V401/V402 zachować osobne komendy i diagnostykę oraz wspólny warunek ukończenia kroku. W Manual sterowanie poszczególnymi osiami nadal podlega blokadom mechanicznym.

Diagnozować bramkę i poszczególne moduły. Brak aktualnego wejścia nie może dawać potwierdzenia HOME/WORK. Zachowanie fizycznych wyjść po zaniku danych wynika z konfiguracji Festo oraz pneumatyki (GAP-03/08), nie z uniwersalnego wyzerowania.

Utrata podciśnienia chwytaka wymaga osobnej klasyfikacji alarmowej; ustalenie o ostrzeżeniach siłowników ST.1–ST.4 nie stanowi zgody na ignorowanie utraty trzymanego detalu.

## 6. PLC ↔ EUROMAP 67

Planowany `FB_ImmInterface` jest jednym miejscem kontroli procesowych wyjść do wtryskarki. Przyjmuje żądania robota, stan pracy samodzielnej i dopuszczone ręczne komendy. Nie łączyć komend prostym OR z pominięciem trybu i blokad.

| Grupa | Funkcje wymagające mapowania |
|---|---|
| Krauss → PLC → robot | Forma otwarta/zamknięta, pozycja pośrednia, zezwolenie współpracy, odrzut, pozycje wyrzutnika i używanych rdzeni |
| Robot → PLC → Krauss | Procesowe pozwolenia ruchów formy, wyrzutnika i rdzeni oraz wybór współpracy; każdą funkcję zweryfikować pod kątem granicy obwodów bezpieczeństwa |
| Krauss ↔ PLC | Rzeczywiste warunki rozpoznania rozpoczętego cyklu i zakończenia operacji potrzebne do Stop/Koniec zlecenia |
| Układ bezpieczeństwa ↔ urządzenia | Obwody bezpieczeństwa pozostają odrębnym zagadnieniem sprzętowym; brak ręcznych wymuszeń z HMI |

EUROMAP 67 B2 jest LOW dla współpracy z robotem i HIGH dla braku współpracy. To znaczenie na interfejsie, nie gotowa polaryzacja cewki PLC: uwzględnić przekaźniki i okablowanie. Sygnalizacja „Mould area free” ma określoną funkcję i nie może być utożsamiona z dowolnym programowym HOME.

Źródło normatywnego opisu sygnałów: [EUROMAP 67, wersja 1.11, tabela 2](https://www.euromap.org/media/recommendations/67/2015/EU%2067_Ver_1.11_May2015.pdf). Wykorzystanie w Krauss i zaciski zatwierdza GAP-05.

Tryb współpracy: aktywne zlecenie, poprawny program, aktualne dane i spełnione pozwolenia. Tryb samodzielny: wyłączona współpraca i aktualne HOME, bez uzależnienia od zlecenia automatu. Ręczny: Manual, HOME i zatrzymana współpraca automatyczna; wejście w Auto kasuje ręczne wymuszenia.

Przy zwykłym Stop nie odcinać mechanicznie wszystkich zezwoleń: sygnały wymagane do zakończenia rozpoczętej operacji muszą być utrzymane zgodnie z jej protokołem. Nowe cykle nie mogą się rozpocząć. Dokładny zestaw i momenty przejść wymagają GAP-05.

## 7. HMI ↔ PLC

Szczegółową specyfikację elementów, proponowanych tagów i protokołu komend zawiera [mapa Vijeo](hmi-vijeo-map.md); [inwentaryzacja](hmi-existing-variables.md) opisuje wszystkie istniejące pola. Nowe hmiV2/hmiIo są propozycją do zatwierdzenia przed implementacją, nie deklaracjami już obecnymi w ST.

| Grupa | Minimalny zakres |
|---|---|
| Komendy | Start/Koniec zlecenia, Pojemniki/Blistry, Auto/Manual, Praca z robotem, Reset, ruchy ręczne, dopuszczone ręczne sygnały IMM |
| Stan procesu | Zlecenie otwarte/kończone, gotowość, praca, zatrzymywanie, zatrzymanie, opróżnianie, odzyskiwanie stanu |
| Stan rozładunku | Gotowość pojedynczego wydania, wydanie w toku, oczekiwanie na odbiór B304 |
| Dostępność | Dopuszczalność każdej komendy i czytelny powód blokady, obliczane przez PLC |
| Alarm | Identyfikator, stacja, źródło, krytyczny/ostrzeżenie, aktywność, potwierdzenie i opis warunku |
| Parametry | Progi czasowe stacji, diagnostyka komunikacji i kroku robota, wymagane parametry procesu |

Zachować rozdział żądań od potwierdzonych stanów. Odrzucenie komendy nie zmienia potajemnie stanu urządzenia lub zlecenia. Reset stanów stacji jest odrębną czynnością od resetu alarmów i wymaga Manual.

Fizyczny Start i Stop trafiają do tej samej nadrzędnej koordynacji zlecenia. Dotychczasową komendę HMI Start rozstrzyga GAP-10; nie dodawać nowego przycisku uruchomienia poza uzgodnionym zakresem.

## 8. Zasady migracji i weryfikacji

Przed uruchomieniem przejść pełną ścieżkę: czujnik/zawór → moduł → kanał/assembly → RAW → nazwa logiczna → użytkownik sygnału → status HMI/robota. Zweryfikować obie polaryzacje i rzeczywiste potwierdzenia.

Kontrolować aliasy dla par równoległych, brak konfliktu adresów, pojedynczego właściciela wyjścia, zgodność nazw w PLC/LS/HMI oraz jednoznaczną obsługę potwierdzeń. Rejestr adresów z projektu powinien powstać jako jeden wykaz, a nie niezależne ręcznie utrzymywane listy.

Tabela funkcji jest gotowa do dalszej pracy dokumentacyjnej. Zamknięcie właściwych GAP i testy AT są wymagane dla zatwierdzenia fizycznej mapy i pracy urządzeń.
