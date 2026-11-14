# Robot i kontroler — odczyt tabliczek znamionowych

Data odczytu: 2026-11-14. Źródło: **SRC-06**, dwa zdjęcia przekazane przez użytkownika w rozmowie: pierwsze przedstawia tabliczkę ramienia, drugie tabliczkę kontrolera. Poniższe dane są **POTWIERDZONE odczytem zdjęć**, bez odczytu konfiguracji urządzeń.

## Robot

| Pole tabliczki | Odczyt |
|---|---|
| Producent | FANUC CORPORATION |
| Model | FANUC Robot M-20iD/25 |
| TYPE | A05B-1228-B202 |
| NO. | R25920836 |
| DATE | 2025.09 (wrzesień 2025) |
| WEIGHT | 250 kg |
| Kraj produkcji | Japonia — MADE IN JAPAN |

250 kg to masa robota podana na tabliczce. Nie jest to udźwig ani dopuszczalne obciążenie narzędzia. Udźwigu, momentów, bezwładności i danych obciążenia chwytaka nie ustalono na podstawie tych zdjęć.

## Kontroler

| Pole tabliczki | Odczyt |
|---|---|
| Producent | FANUC CORPORATION |
| System | FANUC SYSTEM R-30iB Mate Plus |
| TYPE | A05B-2682-B144 |
| SERIAL NO. | E25910205 |
| DATE | 2025-09 (wrzesień 2025) |
| WEIGHT | 40 kg |
| INPUT VOLTAGE / POWER SUPPLY | 200–230 V AC |
| Liczba faz | 3 PHASE — trójfazowe |
| Częstotliwość | 50/60 Hz |
| Moc pozorna | 3.0 kVA |
| Oznaczenie EMC | EN55011 GROUP 1 CLASS A |
| Widoczne oznaczenia | CE, UKCA |
| Kraj produkcji | Japonia — MADE IN JAPAN |

Napięcie 200–230 V AC dotyczy wejścia kontrolera. Zdjęcia nie określają zasilania całego stanowiska, obecności transformatora ani wykonania obwodu zasilającego. 3.0 kVA jest mocą pozorną z tabliczki, a nie mocą czynną w kW ani zmierzonym poborem energii. Widoczne oznaczenia CE/UKCA nie zastępują deklaracji zgodności i dokumentacji odbiorowej stanowiska.

## Wnioski dla adaptacji

- **POTWIERDZONE:** model ramienia i rodzina kontrolera są zgodne z dotychczasową architekturą w [założeniach](project-assumptions.md). Numery typu i numery seryjne identyfikują urządzenia ze zdjęć; oba mają datę produkcji 2025-09.
- **OTWARTE — GAP-04:** wersja oprogramowania, zainstalowane opcje (w tym EtherNet/IP), EDS/assembly i mapowanie I/O, pełny backup, brakujące podprogramy, źródło HOME i identyfikacji programu, UFRAME/UTOOL, dane obciążenia oraz punkty i trajektorie. Tabliczki nie potwierdzają tych danych ani konfiguracji współpracy robota z tym kontrolerem.
- **OTWARTE — GAP-09:** wykonanie przewodowych sygnałów procesowych względem docelowej wymiany EtherNet/IP. Zdjęcia nie rozstrzygają rozbieżności schematu i docelowej architektury.

Aktualizacja dotyczy dokumentacji sprzętu dla E1/E4 i zakresu REQ-13/15/22. Nie stanowi wykonania AT-09/10/14 ani zamknięcia GAP-04/09. Nie zmienia parametrów, kodu PLC/FANUC ani konfiguracji urządzeń.

## Pochodzenie i ograniczenia zapisu

Odczyt wykonano bezpośrednio z załączonych zdjęć; nie dekodowano kodów 2D. Oryginalne pliki zdjęć nie zostały zapisane w repozytorium, dlatego nie podano nazw plików, rozmiarów ani SHA-256. Ten dokument jest transkrypcją i analizą, a nie kopią fotograficznego źródła. Manifest kopii plikowych pozostaje bez zmian.
