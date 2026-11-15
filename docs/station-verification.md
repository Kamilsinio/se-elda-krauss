# Weryfikacja modułów stacji — 2026-11-15

Wersję badanych źródeł identyfikuje [manifest SHA-256](station-source-manifest.json). Polecenie: `C:/Users/KamilPelczar/.local/bin/python3.15.exe -B tools/check_plc_release.py` z katalogu se-elda-krauss. Testy nie łączą się z urządzeniami.

| Rodzaj kontroli | Wynik / dowód |
|---|---|
| Generator PLC --check | PASS; layout v2, 227 pól/80 B bez zmian |
| Generatory FANUC --check | PASS; źródła COMM/TRAY/BOX/BG zgodne z generatorami |
| Audyt kontraktu i migracji | PASS |
| Audyt symboli, pól i wywołań PLC | PASS; obejmuje wszystkie typowane porty, Controller, adapter i PRG_Main |
| Dotychczasowe testy ST i wspólne ST–LS | PASS, 40 testów |
| Testy modułów stacji | PASS, 32 testy |
| Regresje integracji całego kontrolera | PASS, 22 testy, w tym scenariusze ST–LS obu produkcji |
| FANUC COMM/TRAY/BOX/czytelność | PASS, 16+21+24+4 = 65 testów |
| Cały zestaw | **12/12 kontroli, 159 testów zachowania/czytelności** |
| git diff --check | PASS |
| Kompilacja Machine Expert, biblioteki i konfiguracja M241 | NIE WYKONANO |
| Import/natywne wykonanie FANUC | NIE WYKONANO |
| Fizyczne EIP/Festo/ATV320/EUROMAP, ekrany i komunikacja Vijeo | NIE WYKONANO |
| FAT/SAT i funkcje bezpieczeństwa | NIE WYKONANO |

Test opróżniania sprawdza 128 kombinacji P1–P7 dla każdej produkcji, czyli 256 podprzypadków w jednym teście. Wykonuje rzeczywiste OrderManager, StationDrain, StationTransport i StationMaterial; przejazd/odbiór są syntetyczne. Osobne scenariusze wykonują ST.1 i ST.3, w tym B304 stale 0/1, pojedyncze wydanie i ostrzeżenia bez wtórnej eskalacji.

Dodatkowo sprawdzono Stop/Start/Manual i ostatni odbiór, brak wznowienia po restarcie, utratę ważności, zachowanie ładunku między czujnikami oraz commit zarejestrowany podczas ruchu. Testy Manual obejmują niezależne watchdogi, zmianę strony, konflikty i wymóg ponownego naciśnięcia. Testy HMI obejmują zamrożony payload, wynik semantyczny, duplikaty i atomowość parametrów. Wykonywany jest też PRG_Main z niepowiązanymi I/O, z jawnym fixture GIATV; nie jest to kompilacja biblioteki Schneider ani model fizyki napędu.

Regresja obejmuje HOME jako warunek Start, bez odbierania pozwolenia na dokończenie operacji, gdy robot wyjeżdża z HOME. Końcowe cewki i wywołanie napędu są rozstrzygane po aktualnej agregacji alarmów. Krytyczna reakcja na fizycznych urządzeniach nadal wymaga potwierdzonej macierzy i prób.

Otwarte GAP i warunki uruchomienia opisuje [implementacja stacji](station-plc-implementation.md). PASS offline nie zamyka sprzętowych AT ani nie zatwierdza reakcji pneumatyki przy zaniku zasilania.


Nowa symulacja `plc_station_cosim.StationCell` wykonuje rzeczywisty FB_StationController, urządzenia i MAIN_TRAY/MAIN_BOX przez kodek 80 B. Mechanika, czujniki i statusy native są jawnie syntetyczne. Nie wpisuje potwierdzeń wykonania do kontekstu PLC. Wykonano dwa pełne stosy dla każdej produkcji, w tym warstwy/przekładki BOX; po dwa wtryski N/N+1 zakończone po Stop; Drain z fizycznymi wykonawcami, pauzą, świeżym Start i końcowym odbiorem; zakończenie zlecenia przed pierwszą produkcją; Manual i lokalne uzgodnienie.

Regresje odtwarzają siedem usterek: komendę ruchu stopera po timeout, znikające HOME wyłączonego cylindra, zgubione zwolnienie Manual, zgubione żądanie dolnego transportera, błędny powrót zajętej windy, timeout STOPPING uznany za postój oraz recovery zależne od logicznego owner. Dodatkowo sprawdzono atomowe zdarzenia materiałowe i duplikaty, stary wynik operacji, zachowanie monotonicznych ID, rozdzielenie taśmy i B304, niezatwierdzony adapter, bieżącą blokadę krytyczną, powrót I/O i pomiaru napędu bez wznowienia oraz indywidualny watchdog i stronę ręcznego EUROMAP.

Nie potwierdzono czasów skanu, opóźnień sieci, bezwładności rzeczywistej osi/taśm ani reakcji sprzętu. Parametry i verified w fixture są danymi próby. [Integracja i migracja v4](station-integration.md) opisuje pozostałe kroki odbioru.
