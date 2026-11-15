# Weryfikacja źródeł FANUC

Data: 2026-11-15. Wynik dotyczy **źródeł i testów offline**. Import, konfiguracja urządzeń i odbiór stanowiska pozostają niewykonane.

## Dostarczona zmiana

Cała technologia znajduje się w [MAIN_TRAY](../ROBOT/TRAY/MAIN_TRAY.LS) i [MAIN_BOX](../ROBOT/BOX/MAIN_BOX.LS). Oba zawierają ruchy, chwytak, IMM, odkładanie, próbki, zdarzenia, Stop i recovery. Nie ma osobnych wykonywalnych RT/RX/RM/XM/RF/RG/RE ani runtime mailboxu. Wspólne definicje Python rozwijane są przy generowaniu.

Oddzielne pozostają komunikacja PLC_* i trzy BG: BG_PLC, BG_STATUS oraz BG_GUARD. BG_BIND jest inicjalizatorem powiązań. LIVE zawiera 22 LS: 2 main, 17 komunikacji (w tym BG_PLC) i 3 w katalogu BG. COMMON zawiera tylko manifest i opisy. [Migracja](../ROBOT/program-migration.csv) wskazuje stare programy i ich docelowe role.

Każdy LS ma indywidualny opis. Każdy używany zasób ma krótką etykietę i pełne objaśnienie przed pierwszym użyciem w danym programie. Opisy obejmują ON/OFF, kierunki, jednostki, maski i kody. Te same definicje są eksportowane do descriptions.csv/json oraz alokacji resources.json. Brak znaczenia przerywa generowanie.

Dostarczony HandlingTool 8.30 Rev.C wskazuje: standardowy remark 1–32 znaki (§8.19.6, PDF 961), opis programu 1–16 (§8.2.8, PDF 729), komentarz I/O do 24 (§6.2.3, PDF 554). Generator stosuje konserwatywnie do 32 znaków łącznie z prefiksem komentarza, do 16 opisu programu i do 14 etykiety operandu. Test kontroluje limity. To odniesienie składniowe; import i wyświetlanie na fizycznym V9.40 nadal są otwarte.

Kontrakt v2 nie zmienił się: 227 pól, 80 bajtów/kierunek, zachowane adresy. Numery COMM/TRAY R1–200, BOX R201–330 oraz właściciel R331 pozostają bez zmian. R332–349 i dawne flagi mailboxu są nieużywane. Lokalne APPLY/EXIT używają F47/F48 w TRAY i F151/F152 w BOX, bez nowych pól wire.

Zachowano parametry, profile grup, P1–P3, warstwy, przekładki tylko między warstwami, próbki/odrzuty, Stop N+1, pełny REQ/ACK i jawne recovery. Zatrzask błędu ma pierwszeństwo przed zwykłym przejściem kroku. Nie skopiowano współrzędnych starego robota ani fikcyjnych native.

## Kontrole

| Kontrola | Wynik |
|---|---|
| Generator komunikacji --check | 45 artefaktów LIVE/TEST |
| Generator produkcji --check | 13 artefaktów, w tym migracja i słownik |
| Audyt kontraktu/migracji sygnałów | 227 pól i 268 wierszy |
| Komunikacja | 16 scenariuszy |
| MAIN_TRAY i regresja BG | 21 scenariuszy |
| MAIN_BOX i wybór programów | 24 scenariusze |
| Czytelność, komentarze i struktura | 4 kontrole |
| Zasoby, CALL, lokalne etykiety, pisarze I/O, Mixed Logic | audyt statyczny w powyższych testach |

Łącznie **65 testów offline**. Zachowano 61 wcześniejszych scenariuszy odbioru; testy wykonują teraz pełne main i zachowują ich PC przy WAIT, bez pomocniczych programów TICK. Test offsetów BOX obserwuje rzeczywiste odkładanie w kolejnych sekcjach i warstwach.

Cztery kontrole czytelności sprawdzają opisy wszystkich operandów przed pierwszym użyciem, zgodność i jednoznaczność etykiet, limity komentarzy, kompletność lokalnych skoków, brak technologicznych CALL/mailboxu oraz odmowę generowania po usunięciu znaczenia ze słownika.

Interpreter wykonuje rzeczywiste instrukcje /MN. PR/J/L rejestruje w modelu. Native, współrzędne i PLC/Festo są jawnie syntetyczne. Nie jest kompilatorem FANUC i nie odtwarza serwonapędów, kinematyki ani harmonogramu firmware/BG.

## Powtórzenie

~~~powershell
python -B tools/build_fanuc_comm.py --check
python -B tools/build_fanuc_tray.py --check
python -B tools/check_robot_contract.py
python -B tools/check_fanuc_comm.py
python -B tools/check_fanuc_tray.py
python -B tools/check_fanuc_box.py
python -B tools/check_fanuc_readability.py
~~~

Python 3 i biblioteka standardowa. Narzędzia nie łączą się z urządzeniami. TEST ma osobny obraz mock, nazwy wspólne z LIVE oraz kolizje pamięci; nie importować razem z produkcją.

## Niewykonane próby

| Bramka | Wymagany dowód |
|---|---|
| Zasoby | Pojemność R400, wymagane F/PR, retencja, kolizje oraz pamięć i czas wykonywania rozwiniętych main |
| Native / mechanika | 14 rzeczywistych źródeł, oba main w ruchu/WAIT/PAUSE/ABORT, Reference Position, osobowość/kinematyka, mastering i payload |
| Import LS / komentarzy | V9.40P/80, właściwy importer/opcje, etykiety R/F/PR/I/O oraz faktyczne tabele komentarzy i ekran pendanta |
| BG / alarmy | Czas skanu, obciążenie, watchdog i rzeczywiste zatrzymanie obu main podczas ruchu/WAIT; UALM sam nie stanowi takiego dowodu |
| EtherNet/IP / PLC v2 | EDS/assembly, 80 B/kierunek, RPI, rezerwy, KEEP_IO_ADP i reakcje na utratę |
| Pneumatyka / EUROMAP | Mapowanie, porty F-2680, profil grup, pomiary próżni, podtrzymanie ładunku, początek wtrysku i KF203 |
| Geometria | Nauka PR, UF/UT, kierunki Z, maksymalna wysokość BOX i drogi z ładunkami |
| Recovery | Uzgadnianie trwałych skutków i liczników z rzeczywistym PLC; bez deklaracji exactly-once po restarcie |
| FAT/SAT | Pełne cykle ze stanowiskiem |

GAP-03/04/05/06/08/09/11/12 pozostają otwarte w zakresie zależnych danych i prób. Wszystkie native bindings są UNBOUND, zatwierdzenia ruchu nieaktywne. Nie zmieniono plików ST, projektów natywnych ani fizycznego robota.

## Pochodzenie

Podstawa: DEC-01–32, archiwalne programy tacek/BOX, dokumentacja instalacji i dostarczone manuale. Archiwum ../Robot M20iD/old/ROBOT jest tylko do odczytu. [Rejestr źródeł](sources/README.md) oraz [analiza workspace](workspace-analysis.md) opisują pochodzenie; wcześniejsza weryfikacja manifestów nie jest odbiorem każdego binarnego TP.
