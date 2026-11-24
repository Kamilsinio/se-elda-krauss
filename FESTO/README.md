# Uruchomienie FESTO CPX-AP-A-EP

## Połączenie potwierdzone 2026-11-23

W `plc_soft.project` w Machine Expert V2.3, pod `Industrial_Ethernet_Manager → CPX_AP_A_EP`, adres urządzenia to `10.0.1.41`, a zakładka **Status** pokazała `Running`. Połączenie `260`, `Exact I/O size`, ma RPI 10 ms w obu kierunkach. Zakładka **EtherNet/IP I/O Mapping** pokazała oba przypisania i wartości online. [Instrukcja Schneider dotycząca wymiany cyklicznej](https://product-help.schneider-electric.com/Machine%20Expert/V2.0/en/ESMEEtherNetIP/ESMEEtherNetIP/D-SE-0056942.html).

| Kierunek | Assembly | Rozmiar | Zmienna projektu |
|---|---:|---:|---|
| FESTO → PLC (T→O) | 100 | 33 B | `GVL_Festo.EipInBytes[0..32]` |
| PLC → FESTO (O→T) | 101 | 16 B | `GVL_Festo.EipOutWords[0..7]` |

Numer 260 jest identyfikatorem połączenia w tym projekcie. Do monitorowania aktualności połączenia w PLC służy `EipGetHealth` z identyfikatorem odczytanym z **Connections**. Stan modułów i zasilania PL trzeba sprawdzić osobno. Diagnostykę modułów udostępnia m.in. Assembly 129, a Assembly 130 zawiera stan zbiorczy. Assembly 100 przenosi dane procesowe. [Diagnostyka skanera Schneider](https://product-help.schneider-electric.com/Machine%20Expert/V1.1/de/ESMEEtherNetIP/ESMEEtherNetIP/SoM_Industrial_Ethernet_-_Operating/SoM_Industrial_Ethernet_-_Operating-2.htm) · [Dokumentacja FESTO](https://ftp.festo.com/Public/PNEUMATIC/SOFTWARE_SERVICE/Documentation/8129244.html).

## Topologia potwierdzona na maszynie 2026-11-23

Zespół potwierdził powiązania z fizyczną maszyną i przekazał oznaczony widok **Terminal** z webserwera. Kolejność elementów w obrębie wysp zgadza się z eksportami Assembly 100/101.

| Wyspa | Funkcja | Sloty AP | Moduły z danymi procesowymi |
|---|---|---|---|
| BAT1 / BAT100 | Magazyn przekładek | 1–3 | 2: 8DI BAT101, 3: zawory |
| BAT2 / BAT200 | Załadunek i rozładunek | 4–11 | 5–9: 8DI BAT201–BAT205, 10–11: zawory |
| BAT3 / BAT300 | Winda | 12–14 | 13: 8DI BAT301, 14: zawory |
| BAT4 / BAT400 | Robot i chwytak | 15–22 | 16–17: zawory, 18–22: moduły próżni |

## Wejścia cyfrowe

Indeks bajtu i numer modułu AP pochodzą z [eksportu 100](<Assembly View - AP-A-EP inputs.csv>). Indeks bitu `0..7` odpowiada numerowi `Input 0..7`. Rozkład złączy X0–X7 oparto na [schemacie elektrycznym](<../docs/sources/Schemat elektryczny.PDF>), a przypisanie modułu 13 do BAT301 i krańcówek V201 na X0/X1 potwierdził zespół przy maszynie.

| Moduł AP | `EipInBytes` | BAT | X0/X1, X2/X3, X4/X5, X6/X7 według schematu | Strona PDF |
|---:|---:|---|---|---:|
| 2 | 0 | BAT101 | V401 HP/WP, V402 HP/WP, B401/B402, wolne | 53 |
| 5 | 2 | BAT201 | V101 HP/WP, V102 HP/WP, V103 HP/WP, V104 HP/WP | 55 |
| 6 | 3 | BAT202 | V105 HP/WP, V106 HP/WP, V107 HP/WP, V108 HP/WP | 56 |
| 7 | 4 | BAT203 | V109 HP/WP, V110 HP/WP, B101/B102, B103/wolne | 57 |
| 8 | 5 | BAT204 | V301 HP/WP, V302 HP/WP, V303 HP/WP, V304 HP/WP | 58 |
| 9 | 6 | BAT205 | B301/B302, B303/B304, wolne, wolne | 59 |
| 13 | 9 | BAT301 | V201 HP/WP, V202 HP/WP, V203 HP/WP, wolne | 61 |
| 16 | 11 | BAT400 | IN0 = V501 HOME (oś prosta), IN1 = V501 WORK (oś złamana) | — |

W BAT4 nie ma osobnego BAT401. Dwa wejścia V501 są potwierdzone w eksporcie Assembly 100 na AP16 oraz w aktualnym arkuszu. B201–B204 korzystają z KEC2, B205 pozostaje w GAP-02. Nieużywane bity podbudów pozostają poza mapą procesową.

`PRG_IO_Read` odczytuje 47 sygnałów z modułów 8DI i dwa potwierdzenia V501. `PRG_Main` przekazuje zajętość P1–P3/P5–P7, krańcówki windy i dolnych stoperów, wejścia magazynu i osi V501 do odbiorców w PLC oraz do HMI. BAT201–BAT205 i BAT301 są wymagane przez `FB_StationIo`. Ważność wejść zależy od statusów mapy, bramki, świeżości i właściwego modułu. Polaryzacja B301 i interpretacja wejść próżni pozostają do odbioru. [Mapa I/O](../docs/io-mapping-krauss.csv)

## Wyjścia zaworów

Offsety pochodzą z [opisanego eksportu 101](<Assembly View - AP-A-EP outputs.csv>). Użytkownik potwierdził korektę opisu modułu AP 10. Bity 8/9 sterują V101/V102, a bity 10/11 sterują V103/V104. Kolumna komentarza w pliku eksportu nadal zawiera pierwotny zapis dla bitów 10/11.

`PRG_IO_Write` zapisuje komendy po arbitrażu do `GVL_Festo.EipOutWords[0..7]`, tablicy przypisanej do skanera w projekcie natywnym. Pierwszy bajt pary zajmuje bity 0–7 słowa. `RawCoilCommandByModule` pokazuje bity z tego samego skanu. Program przestał równolegle zapisywać historyczne wyjścia `%QX` zaworów M1–M7.

| Moduł AP | Bajt wyjść | `EipOutWords`, bity | Wyspa |
|---:|---:|---|---|
| 3 | 0 | `[0]`, 0–7 | BAT100 · ST.4 |
| 10 | 1 | `[0]`, 8–15 | BAT200 · ST.1/ST.3 |
| 11 | 2 | `[1]`, 0–7 | BAT200 · ST.1/ST.3 |
| 14 | 3 | `[1]`, 8–15 | BAT300 · ST.2 |
| 16 | 4 | `[2]`, 0–7 | BAT400 · ST.5 |
| 17 | 5 | `[2]`, 8–15 | BAT400 · ST.5 |

| Moduł AP | Zawór lub grupa | Offsety 101 WP/HP | Źródło w PLC |
|---:|---|---|---|
| 3 | V401, V402 | 0/1, 2/3 | `GVL_Robot.storageOut` |
| 10 | V101/V102, V103/V104, V105/V106, V107/V108 | 8/9, 10/11, 12/13, 14/15 | `GVL_Station.Coils[2]`, `[3]`, `[4]`, `[1]` |
| 11 | V109/V110, V301/V302, V303/V304 | 16/17, 18/19, 20/21 | `GVL_Station.Coils[5]`, `[9]`, `[10]` |
| 14 | V201, V202, V203 | 24/25, 26/27, 28/29 | `GVL_Station.Coils[6]`, `[8]`, `[7]` |
| 16 | V501, V502, V503, V504 | 32/33, 34/35, 36/37, 38/39 | `GVL_Robot.Sts.cylinders[1..4]` |
| 17 | V505 | 40/41 | `GVL_Robot.Sts.cylinders[5]` |
| 17 | V506–V508 | 42–47 | Rezerwa, bity zerowe |

V509–V513 odpowiadają kolejno modułom 18–22 i słowom wyjściowym `[3]`–`[7]`. `GVL_Robot.Sts.vacuum[1..5]` dostarcza `hold` na bit 0 i `blow` na bit 1 młodszego bajtu. Pozostałe bity ramki, w tym bajt teach-in, są zerowe. Bloki wejściowe zaczynają się od bajtów `13, 17, 21, 25, 29`. Każdy zawiera `INT` pomiaru, bajt statusu i bajt jakości procesu. Jednostki, kolejność bajtów pomiaru i konfiguracja potwierdzeń zależą od firmware i nastaw modułu. FESTO VABX-A-S-VE, instrukcja 8239830, dane procesowe.

## Pierwsza próba ST.2

Do odczytu pierwszej krańcówki wystarczy podgląd istniejącego `GVL_Festo.EipInBytes` online. Podgląd według numerów modułów jest w źródłach `GVL_Festo`, `PRG_IO_Read` i `PRG_IO_Write` i wymaga synchronizacji z projektem oraz kompilacji w Machine Expert.

1. Na postoju porównać krańcówki V201 z `EipInBytes[9]`, bity 0/1 oraz lampkami HOME/WORK na HMI. Podgląd `RawDiByModule[13]` pokazuje ten sam bajt.
2. V201 na AP 14 używa cewki 0 dla WP i 1 dla HP. Odpowiadają im bity 8 i 9 słowa `[1]`. Porównać komendę z fizycznym potwierdzeniem położenia oraz sprawdzić zachowanie po zwolnieniu przycisku i zaniku PL/komunikacji.
3. Sprawdzić dopuszczenia istniejącego ekranu **112 – ST.2 MANUAL**. Aktualna logika stacji wymaga m.in. ważnego I/O stacji, sprawnego napędu, potwierdzonego safety i polityki zaworów, sesji FANUC, HOME i znanego stanu ładunku oraz poprawnej sesji HMI. W odczycie online ikona FANUC sygnalizowała problem komunikacji. Sprawdzić w PLC `GVL_Robot.Sts.session`, `GVL_Station.Io.valid` i `GVL_HMI.vijeo.stationManual` przed próbą. [Więcej o ekranie 112](../docs/hmi-instructions.md#panel-112).
4. Próbę ruchu wykonać z osobą przy maszynie i pustą strefą ruchu. Polecenie przechodzi z HMI przez istniejące blokady PLC, a odbiór porównuje komendę, stan odpowiedniego bitu i potwierdzenie położenia. Sprawdzić zwolnienie przycisku, zanik łączności i zachowanie po jej powrocie przed kolejnymi zaworami.

Weryfikacja offline przełącza osobno każdy bit w ośmiu używanych bajtach wejściowych i każdą z 44 aktywnych komend Assembly 101. Sprawdza rozdzielenie kanałów, wyzerowanie rezerw oraz unieważnianie sygnałów po utracie danych. Odbiór natywnego mapowania i testy na maszynie są osobnymi próbami.

Zakres REQ-13 i GAP-03: cykliczną komunikację potwierdzono w odczycie online. Kompilacja nowych zmian w Machine Expert, sprawdzenie reakcji GAP-08, AT-09 (zanik i powrót połączenia) i próby ruchowe pozostają do wykonania.
