# Materiały źródłowe SE-ELDA-Krauss

Stan rejestru: 2026-10-04. Materiały są wejściem do adaptacji, a nie potwierdzeniem gotowej konfiguracji urządzeń.

## Kopie i pochodzenie

Oryginały znajdowały się w katalogu nadrzędnym względem repozytorium. Pozostają tylko do odczytu. Dostępne kopie wykonano bajt w bajt do tego katalogu, bez edycji zawartości. [Manifest](manifest.json) zapisuje pochodzenie, rozmiar i SHA-256 każdej wykonanej kopii.

| ID | Materiał | Stan i zastosowanie |
|---|---|---|
| SRC-01 | [Wytyczne.docx](Wytyczne.docx) | Kopia zgodna z oryginałem. Wymagania zmian względem poprzedniego stanowiska; ustalenia użytkownika doprecyzowują zachowanie. |
| SRC-02 | [IO map.xlsx](<IO map.xlsx>) | Kopia zgodna z oryginałem, uzupełniona 2026-10-04 po zwolnieniu blokady. Ponownie odczytano 166 wierszy sygnałów i 12 urządzeń; mapa nadal zawiera TBD i zakładki placeholder. |
| SRC-03 | [Schemat elektryczny.PDF](<Schemat elektryczny.PDF>) | Kopia zgodna z oryginałem. P0001, 63 strony PDF; karta tytułowa: rewizja 01, data 2026-09-29. Poszczególne arkusze mają własne rewizje i daty. |
| SRC-04 | Odpowiedzi użytkownika podczas planowania | Potwierdzone decyzje DEC-01–DEC-15 zapisano w [założeniach](../project-assumptions.md). Nie są częścią oryginalnego Worda. |
| SRC-05 | Kod PLC/FANUC odziedziczony w repozytorium | Baza do adaptacji, nie nadrzędny opis nowego procesu. Konkretne rozbieżności zestawiono w [planie](../implementation-plan.md). |

SHA-256 wykonanych kopii:

- IO map.xlsx: `9e1e47058088382590e4c1f36284c01fae4e294bebdfb6eb6f3faed95cb06e64`
- Wytyczne.docx: `9368fd7d90d1aa23f35983e61f74dc6dfbe97ee35a77bd52c225179ae983cfa9`
- Schemat elektryczny.PDF: `81f6c50ad3cdec51a13930bfea6311f13f2754f5ef89630fb13928928be226a9`

Kopię SRC-02 zweryfikowano SHA-256 względem oryginału. Ponowny odczyt potwierdził istotne dla dokumentacji funkcje i otwarte punkty: brak osobnej bariery, B205 bez podłączenia, adresy TBD, rozdzielone V201/V202 i V401/V402 oraz roboczą mapę EUROMAP/robota. Pełny podgląd HMI opisuje [mapa diagnostyczna](../hmi-io-diagnostics.md). Brak sumy kontrolnej z wcześniejszego planowania nie pozwala twierdzić, że arkusz od tamtej chwili nie zmienił się; obecna kopia jest nowym utrwalonym punktem odniesienia.

## Nawigacja po dokumentach

Wytyczne obejmują ST.1–ST.5, HMI, fizyczne Start/Stop, opcję Praca z robotem, ręczny EUROMAP, zlecenia oraz podział alarmów. Ich pokrycie jest w macierzy REQ → moduł → AT.

Istotne arkusze schematu (numer strony PDF / oznaczenie arkusza):

| Strona / arkusz | Zawartość |
|---|---|
| 8 / 015 | Napęd windy ATV320 |
| 9 / 016 | Panel HMI; oznaczenie HMIDT351 nie określa tu pełnej konfiguracji środowiska |
| 10 / 017 | Sieć urządzeń i źródłowe adresy IP |
| 11 / 020 | PLC TM241CE24T i moduły TM3 |
| 39–41 / 151–153 | EUROMAP 67 |
| 42–43 / 161–162 | EUROMAP 73 i obwody wymagające odrębnej weryfikacji bezpieczeństwa |
| 44–46 / 171–173 | Przewodowe I/O robota, rozbieżne z docelową komunikacją procesową EtherNet/IP |
| 50 / 308 | Czujniki windy; B205 bez pokazanego podłączenia sygnału do wejścia PLC |
| 52–63 / 310–341 | Bramka, terminale i wejścia Festo AP |

Mapa I/O odczytana podczas planowania zawiera arkusze ST01_Loading Belt, ST02_Elevator, ST03_Unloading Belt, ST04_Spacer depositor, ST05_Robot, Festo Islands oraz zakładki EUROMAP i przycisków oznaczone jako placeholder. Zawiera pola TBD i robocze nazwy/adresy; nie jest zatwierdzoną mapą uruchomieniową.

## Dokumentacja producentów użyta podczas analizy

- [Schneider Electric — M241 jako skaner EtherNet/IP](https://www.se.com/us/en/faqs/FA305861/): rodzina TM241CE24x/TM241CE40x obsługuje tę funkcję w wymaganym środowisku. Nie zastępuje to projektu i konfiguracji konkretnego urządzenia.
- [EUROMAP 67, wersja 1.11, maj 2015](https://www.euromap.org/media/recommendations/67/2015/EU%2067_Ver_1.11_May2015.pdf): znaczenie interfejsu elektrycznego i sygnałów, w tym B2. Użycie poszczególnych sygnałów w Krauss i przebieg obwodów potwierdza GAP-05.

Odwołania sprawdzono podczas planowania 2026-10-04. Dokumenty producentów nie potwierdzają fizycznego wykonania dostarczonego stanowiska.

## Reguły aktualizacji

Kopie źródeł zachowywać bez edycji. Nową rewizję odnotować razem z jej pochodzeniem i sumą kontrolną, a następnie przejrzeć powiązane wymagania oraz mapę I/O. Nie zastępować niezgodnych informacji milczącym wyborem jednej wersji.

Przy implementacji pierwszeństwo mają aktualne ustalenia użytkownika, a fizyczne mapowanie i zachowanie urządzeń muszą mieć dowód w potwierdzonej konfiguracji. Lista nierozstrzygniętych punktów jest w [GAP](../implementation-plan.md).
