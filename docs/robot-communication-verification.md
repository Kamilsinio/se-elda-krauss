# Weryfikacja komunikacji v2, programu tacek i BG

Data: 2026-11-14. Wynik dotyczy **źródeł i testów offline**. Import FANUC, konfiguracja urządzeń i odbiór stanowiska pozostają niewykonane.

## Dostarczona implementacja

- Kontrakt v2: 227 pól; zachowano adresy 220 pól v1. Dodano batchCount, startToken i osobny kanał rejectsPlaced z payloadem. Rozmiar pozostaje 80 bajtów na kierunek.
- LIVE: 17 źródeł komunikacji, 58 programu tacek/procedur i 3 w katalogu BG. Rejestrowane jako BG są RC_MON, RB_STATUS i RB_GUARD; RB_BIND jest inicjalizatorem.
- Wariant TEST: osobny obraz mock i RC_TEST, bez możliwości zapisu niezerowych wyjść sieciowych. Nie jest ładowany razem z produkcją.
- R1–200 są zarezerwowane łącznie przez LIVE, sekwencję i BG. Manifesty kontrolują kolizje. Wolność i pojemność zasobów na fizycznym kontrolerze wymagają potwierdzenia.
- Chwytak ma profil grup maska/ilość, aktywną kopię parametrów i punkty do nauki. Nie skopiowano współrzędnych starego robota ani nie użyto nieodczytanych BB_* jako zależności.
- Źródła native BG pozostają UNBOUND; wszystkie flagi dopuszczenia i punkty są niezatwierdzone. W tym stanie ruch nie jest dopuszczony.

Szczegóły i instrukcje: [tacki](../ROBOT/TRAY/README.md), [BG](../ROBOT/BG/README.md), [komunikacja](../ROBOT/COMM/README.md).

## Wyniki wykonanych kontroli

| Kontrola | Wynik |
|---|---|
| Generatory w trybie --check | zgodne: 41 artefaktów komunikacji LIVE/TEST i 63 tacek/BG |
| Audyt kontraktu i migracji | 227 pól, 268 wierszy; brak utraty rozróżnienia DO17 i granicy DO101/safety |
| Testy komunikacji na rzeczywistych instrukcjach LS | 16/16 poprawnych |
| Testy sekwencji i BG na rzeczywistych instrukcjach LS | 21/21 poprawnych |
| Zasoby, referencje CALL, pisarze DO/GO i ograniczony zestaw instrukcji BG | sprawdzone statycznie |
| Budżet wyrażeń Mixed Logic | kontrola konserwatywna do 20 elementów; nie zastępuje importu FANUC |
| Spójność dokumentacji, lokalnych odsyłaczy i składni Python | sprawdzana przy zakończeniu zmiany |

Łącznie **37 testów offline**. Interpreter czyta /MN z wygenerowanych plików LS, wykonuje przypisania, IF, SELECT/CALL i skoki, a operacje PR/J/L rejestruje w kontrolowanym modelu. Natywne statusy i współrzędne są jawnymi syntetycznymi danymi testowymi. Nie emuluje firmware, servo, kinematyki ani rzeczywistego harmonogramu BG.

Testy komunikacji obejmują mapę i skrajne UINT, kolejność bajtów, REQ/ACK, stałość payloadu, niezależność kanałów, błędną wersję, heartbeat i watchdog serwisu, synchronizację, jawne recovery, reakcje na błędne dane oraz izolację TEST od wyjść sieciowych.

Testy produkcji obejmują:

- pełny stos z częściowymi odłożeniami, ilość grupy większą niż cztery, brak podwójnego liczenia;
- cały komplet próbek i osobne odrzuty w tym samym miejscu fizycznym;
- Stop z rozpoczętym N+1 oraz Stop bez N+1, z zachowaniem niepełnej tacki;
- niekolejkowany Start, zamknięcie zlecenia i wymóg nowego kontekstu;
- aktywną kopię parametrów, błędne maski, ilości i niepodzielną pojemność tacki;
- utratę ACK i sesji, zachowanie maski, unieważnienie pewności ładunku i brak replay;
- ograniczone szukanie tacki, odrzucony przedmuch i brak fałszywego odłożenia;
- oczekiwanie na obszar bez eskalowania ostrzeżenia do globalnego błędu;
- brak bindingów, nienauczone punkty, native ABORT, ręczny jog i zatrzymany monitor;
- recovery spójnej partii, nowy Start po uzgodnieniu, brak ponownego pobrania rozliczonego kompletu;
- blokadę recovery pełnej tacki przed uzgodnieniem zdarzeń końcowych z PLC;
- nieznany stan sekwencji, właścicieli wyjść i matematyczne offsety X/Y.

## Powtórzenie

Z katalogu repozytorium, Python 3 i biblioteka standardowa:

~~~powershell
python -B tools/build_fanuc_comm.py --check
python -B tools/build_fanuc_tray.py --check
python -B tools/check_robot_contract.py
python -B tools/check_fanuc_comm.py
python -B tools/check_fanuc_tray.py
~~~

Lokalnie użyto interpretera runtime Codex. Opcja -B zapobiega zapisywaniu cache modułów. Narzędzia nie łączą się z urządzeniami.

## Niewykonane próby i bramki

| Etap | Stan / wymagany dowód |
|---|---|
| Native źródła statusów i mechanika kontrolera | NIEWYKONANE: zweryfikować powiązania na fizycznym V9.40, zgodność osobowości/kinematyki, mastering, narzędzie i obciążenia |
| Import/kompilacja LS do TP | NIEWYKONANE: docelowe V9.40P/80 i właściwe opcje/importer; ROBOGUIDE V9.10 nie jest tym dowodem |
| BG i alarmy podczas ruchu/WAIT | NIEWYKONANE: wykazać zatrzymanie RT_MAIN przez ustaloną reakcję; sam UALM wykonany w BG nie dowodzi zatrzymania grupy ruchowej |
| Native HOME i status właściwego zadania | NIEWYKONANE: Reference Position, tryby, symulacje, WAIT, PAUSE, ABORT; nie używać pracy RC_SVC jako pracy produkcji |
| Ethernet/IP i PLC v2 | NIEWYKONANE: zgodność assembly/EDS, 80 bajtów na kierunek, rezerwy, RPI, KEEP_IO_ADP, watchdog i alarm adaptera |
| PLC/Festo/EUROMAP | NIEWYKONANE: końcowe mapowanie, porty F-2680, próżnia, podtrzymanie, początek wtrysku i zależność KF203 |
| Ruchy i geometria | NIEWYKONANE: nauka punktów, poprawne UF/UT, próby dróg, granic szukania i kolizji |
| Recovery trwałych skutków | NIEWYKONANE na stanowisku: ręczne uzgodnienie nierozliczonych zdarzeń i danych PLC; brak deklaracji exactly-once po restarcie |
| Pełne cykle i FAT/SAT | NIEWYKONANE |

Otwarte GAP nie są zamknięte wynikami interpretera. PLC i program Pojemników nie zostały przepisane. Domyślne UNBOUND i niezatwierdzone punkty blokują przejście do ruchu; brakujące dane nie są zastępowane fikcyjnym potwierdzeniem.

## Pochodzenie i wcześniejsze kontrole

Podstawą są decyzje DEC-01–26, dawny program A01_F2679_TACKI, dokumentacja instalacji i dostarczone manuale. Archiwalne źródła użytkownik przeniósł do ../Robot M20iD/old/ROBOT; audyt i CSV migracji odczytują tę lokalizację bez przywracania plików.

Wcześniejszy etap v1 obejmował 220 pól, 268 wierszy migracji oraz negatywne próby walidatora. W analizie materiałów zweryfikowano 150 rekordów plikowych w trzech manifestach, pochodzenie manuali i schematów; nie oznaczało to audytu treści każdego binarnego TP ani odbioru urządzeń. [Analiza workspace](workspace-analysis.md) i [rejestr źródeł](sources/README.md) pozostają opisem pochodzenia materiałów.
