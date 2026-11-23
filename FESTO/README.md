# Uruchomienie FESTO CPX-AP-A-EP

## Połączenie potwierdzone 2026-11-23

W `plc_soft.project` w Machine Expert V2.3, pod `Industrial_Ethernet_Manager → CPX_AP_A_EP`, adres urządzenia to `10.0.1.41`, a zakładka **Status** pokazała `Running`. Połączenie `260`, `Exact I/O size`, ma RPI 10 ms w obu kierunkach. Zakładka **EtherNet/IP I/O Mapping** pokazała oba przypisania i wartości online. [Instrukcja Schneider dotycząca wymiany cyklicznej](https://product-help.schneider-electric.com/Machine%20Expert/V2.0/en/ESMEEtherNetIP/ESMEEtherNetIP/D-SE-0056942.html).

| Kierunek | Assembly | Rozmiar | Zmienna projektu |
|---|---:|---:|---|
| FESTO → PLC (T→O) | 100 | 33 B | `GVL_Festo.EipInBytes[0..32]` |
| PLC → FESTO (O→T) | 101 | 16 B | `GVL_Festo.EipOutWords[0..7]` |

Numer 260 jest identyfikatorem połączenia w tym projekcie. Do monitorowania aktualności połączenia w PLC służy `EipGetHealth` z identyfikatorem odczytanym z **Connections**. Stan modułów i zasilania PL trzeba sprawdzić osobno. Diagnostykę modułów udostępnia m.in. Assembly 129, a Assembly 130 zawiera stan zbiorczy. Assembly 100 przenosi dane procesowe. [Diagnostyka skanera Schneider](https://product-help.schneider-electric.com/Machine%20Expert/V1.1/de/ESMEEtherNetIP/ESMEEtherNetIP/SoM_Industrial_Ethernet_-_Operating/SoM_Industrial_Ethernet_-_Operating-2.htm) · [Dokumentacja FESTO](https://ftp.festo.com/Public/PNEUMATIC/SOFTWARE_SERVICE/Documentation/8129244.html).

## Wejścia cyfrowe

Indeks bajtu i numer modułu AP pochodzą z [eksportu 100](<Assembly View - AP-A-EP.csv>). Indeks bitu `0..7` odpowiada numerowi `Input 0..7`. Kolumny BAT i sygnałów zestawiają kolejność modułów 8DI z arkuszami P0001. Są hipotezą do weryfikacji po identyfikacji modułu w widoku AP i porównaniu stanu konkretnego czujnika. Oznaczenia X0–X7 pochodzą ze [schematu elektrycznego](<../docs/sources/Schemat elektryczny.PDF>).

| Moduł AP | `EipInBytes` | BAT do potwierdzenia | X0/X1, X2/X3, X4/X5, X6/X7 według schematu | Strona PDF |
|---:|---:|---|---|---:|
| 2 | 0 | BAT101 | V401 HP/WP, V402 HP/WP, B401/B402, wolne | 53 |
| 5 | 2 | BAT201 | V101 HP/WP, V102 HP/WP, V103 HP/WP, V104 HP/WP | 55 |
| 6 | 3 | BAT202 | V105 HP/WP, V106 HP/WP, V107 HP/WP, V108 HP/WP | 56 |
| 7 | 4 | BAT203 | V109 HP/WP, V110 HP/WP, B101/B102, B103/wolne | 57 |
| 8 | 5 | BAT204 | V301 HP/WP, V302 HP/WP, V303 HP/WP, V304 HP/WP | 58 |
| 9 | 6 | BAT205 | B301/B302, B303/B304, wolne, wolne | 59 |
| 13 | 9 | BAT301 | V201 HP/WP, V202 HP/WP, V203 HP/WP, wolne | 61 |
| do ustalenia | — | BAT401 | V501 HP/WP na X0/X1 | 63 |

Schemat pokazuje osiem modułów 8DI, a eksport siedem. Trzeba zidentyfikować wszystkie w topologii rzeczywistej, szczególnie BAT301 i BAT401. B201–B204 wymagają osobnego powiązania ze schematem windy, a B205 pozostaje otwarty w GAP-02. Bajty wejściowe podbudów zaworowych V4A (`1, 7, 8, 10, 11, 12`) są przewidziane w obrazie AP. Według instrukcji VTUX-A-S z 2024-07 pełnią funkcję rezerwy. FESTO VTUX-A-S, instrukcja 8214916, rozdział 9.

## Wyjścia zaworów

Offsety pochodzą z [eksportu 101](<Assembly View - AP-A-EP (1).csv>). Projekt udostępnia obraz w słowach. W podglądzie ST przyjęto młodszy bajt jako pierwszy bajt słowa. Potwierdzić kolejność na zatwierdzonej próbie oraz sprawdzić położenie zaworu na podbudowie i kierunek ruchu dla każdej cewki. Według instrukcji VTUX pozycje 0–3 zajmują pary `0/1`, `2/3`, `4/5`, `6/7`, z cewką 14 na niższym bicie i 12 na wyższym. Typ zaworu i węże rozstrzygają powiązanie HP/WP. FESTO VTUX-A-S, instrukcja 8214916, rozdziały 4.4 i 9.

| Moduł AP | Bajt wyjść | `EipOutWords`, bity | Wyspa wg kolejności, do potwierdzenia |
|---:|---:|---|---|
| 3 | 0 | `[0]`, 0–7 | BAT100 · ST.4 |
| 10 | 1 | `[0]`, 8–15 | BAT200 · ST.1/ST.3 |
| 11 | 2 | `[1]`, 0–7 | BAT200 · ST.1/ST.3 |
| 14 | 3 | `[1]`, 8–15 | BAT300 · ST.2 |
| 16 | 4 | `[2]`, 0–7 | BAT400 · ST.5 |
| 17 | 5 | `[2]`, 8–15 | BAT400 · ST.5 |

Dla modułów próżni 18–22 kolejne bloki wejść zaczynają się od bajtów `13, 17, 21, 25, 29`. Blok to `INT` pomiaru, bajt statusu i bajt jakości procesu. Każdy moduł ma dwa bajty wyjść, w słowach `[3]`–`[7]`. Przed podłączeniem próżni trzeba potwierdzić przypisanie V509–V513, nastawy, jednostki i format pomiaru dla zainstalowanego firmware. FESTO VABX-A-S-VE, instrukcja 8239830, dane procesowe.

## Pierwsza próba ST.2

Do odczytu pierwszej krańcówki wystarczy podgląd istniejącego `GVL_Festo.EipInBytes` online. Podgląd według numerów modułów jest w źródłach `GVL_Festo`, `PRG_IO_Read` i `PRG_IO_Write` i wymaga synchronizacji z projektem oraz kompilacji w Machine Expert.

1. Porównać fizyczną etykietę BAT301 i urządzenie w widoku AP. Na postoju porównać stan krańcówki V201 z `EipInBytes[9]`, bity 0/1, jeśli widok AP potwierdzi moduł 13. Podgląd w źródłach `RawDiByModule[13]` pokazuje ten sam bajt. Zapisać polaryzację i stan rzeczywisty.
2. Zidentyfikować pozycję zaworu V201 na BAT300, typ zaworu i funkcję cewki 12/14. Zapisać zachowanie przy zwolnieniu przycisku i zaniku PL/komunikacji. Następnie powiązać `GVL_Station.Inputs.v201` z potwierdzonymi wejściami i `GVL_Station.Coils[6]` z wyjściem w `PRG_IO_Write`. Dla V202 i V203 końcowymi komendami są odpowiednio `Coils[8]` i `Coils[7]`. `RawCoilCommandByModule` wyświetla wysyłane bity; pozycję potwierdzają krańcówki.
3. Sprawdzić dopuszczenia istniejącego ekranu **112 – ST.2 MANUAL**. Aktualna logika stacji wymaga m.in. ważnego I/O stacji, sprawnego napędu, potwierdzonego safety i polityki zaworów, sesji FANUC, HOME i znanego stanu ładunku oraz poprawnej sesji HMI. W odczycie online ikona FANUC sygnalizowała problem komunikacji. Sprawdzić w PLC `GVL_Robot.Sts.session`, `GVL_Station.Io.valid` i `GVL_HMI.vijeo.stationManual` przed próbą. [Więcej o ekranie 112](../docs/hmi-instructions.md#panel-112).
4. Próbę ruchu wykonać z osobą przy maszynie i pustą strefą ruchu. Polecenie przechodzi z HMI przez istniejące blokady PLC, a odbiór porównuje komendę, stan odpowiedniego bitu i potwierdzenie położenia. Sprawdzić zwolnienie przycisku, zanik łączności i zachowanie po jej powrocie przed kolejnymi zaworami.

Zakres REQ-13 i GAP-03: potwierdzono cykliczną komunikację, długości oraz offsety procesowe. Powiązanie urządzeń, diagnostyka modułów w logice PLC i reakcje GAP-08 pozostają otwarte. Test AT-09 (zanik i powrót połączenia) oraz próby ruchowe pozostają do wykonania.
