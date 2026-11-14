# Odizolowany test komunikacji FANUC

Pakiet COMM w tym katalogu jest alternatywą dla LIVE, przeznaczoną do osobnej kopii kontrolera. Nie ładować go razem z ROBOT/COMM, ROBOT/TRAY ani produkcyjnymi BG: nazwy programów są wspólne, a mock R1–28 koliduje z parametrami produkcji.

RC_TEST wykonuje synchronizację v2 oraz zdarzenie count=7 z zamrożonym payloadem. Oczekiwane testResult=1, configured/run OFF. RC_TX i heartbeat zapisują wyłącznie zera, RC_LIVE nie startuje serwisu. Test nie porusza robotem i nie potwierdza działania skanera PLC ani native firmware.

Model całej produkcji uruchamia się na komputerze narzędziem tools/check_fanuc_tray.py, na rzeczywistych źródłach LIVE i syntetycznych wejściach/pozycjach. Nie jest częścią programu pobieranego na urządzenie.

Lokalne zasoby testu opisuje [manifest](COMM/resources.json), a ograniczenia źródeł LIVE — [instrukcja komunikacji](../COMM/README.md).
