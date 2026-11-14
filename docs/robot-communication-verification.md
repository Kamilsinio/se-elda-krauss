# Weryfikacja kontraktu komunikacji robot–PLC

Data: 2026-11-14. Zakres: specyfikacja logiczna v1, migracja historycznych I/O i analiza modernizacji. **Nie jest to raport uruchomienia komunikacji ani przepisania programów sterowania.**

## Wykonane sprawdzenia

- Przegląd AGENTS, założeń, interfejsów, planu/GAP, obu main LS, GVL_Robot, powiązań PRG_IO_Read/Write i PRG_Main, IOSTATE/NUMREG/POSREG oraz odpowiednich fragmentów dostarczonych manuali.
- Katalog: 220 jawnych pól z kierunkiem, typem, właścicielem, semantyką, ważnością i reakcją na utratę danych; brak przypisanych adresów sprzętowych.
- Migracja: 268 unikalnych wierszy — 49 dla Blistrów i 65 dla Pojemników (łącznie z trzema CALL wymagającymi eksportu odnalezionych TP w każdym programie), 64 deklaracje logiczne PLC i 90 opisanych historycznych I/O. Puste opisy IOSTATE nie są sygnałami przypisanymi do wykorzystania.
- Walidator wykrywa niepokryte/stare wiersze źródeł, brakujące cele, duplikaty, brakujące kanały urządzeń/ACK/payload, utratę rozdziału DO17 i błędne przeniesienie mould-area-free do zwykłego I/O. Nie ustawia urządzeń i nie zapisuje plików.
- Osiem negatywnych prób w pamięci: usunięte użycie LS, nieistniejący cel, duplikat ID, brak ACK przedmuchu, zrównane znaczenia DO17, przeniesienie DO101 do zwykłego statusu, niepotwierdzony adres i brak osobnego payload próbek. Wszystkie zostały odrzucone przez kontrolę statyczną. To sprawdzenie narzędzia audytu, nie symulacja protokołu.
- Rejestr sześciu zewnętrznych manuali oraz manifest analizy workspace obejmują SHA-256 i rozmiary; oryginałów nie zmieniono. Odczyt treści dotyczył zakresu kontrolerów oraz instrukcji wskazanych w macierzy modernizacji; nie wykonano pełnego audytu tysięcy stron.

Powtórzenie audytu z katalogu se-elda-krauss:

```powershell
python -B tools/check_robot_contract.py
```

Jeśli `python` wskazuje niedostępny alias Windows Store, użyć interpretera z runtime Codex. Narzędzie korzysta wyłącznie z biblioteki standardowej. Lokalnie użyto `C:/Users/KamilPelczar/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.

## Scenariusze odbioru zachowania — wszystkie NIEWYKONANE

| Scenariusz | Oczekiwany dowód | Powiązanie |
|---|---|---|
| Jednoczesne HOME/WORK kilku urządzeń, w tym konflikt 11 jednej pary | niezależne wykonanie poprawnych żądań; konflikt odrzucony bez ruchu i bez wpływu na inne kanały | AT-09/15 |
| Próżnia, brak pomiaru, konflikt hold/przedmuch, utrzymane blowReq | accepted nie udaje vacuumOK; jeden impuls i stabilny wynik; konflikt nie zrzuca próżni | AT-15 |
| Zdarzenie opóźnione, długo utrzymany ACK, dwa różne kanały równocześnie | pojedynczy skutek w sesji, niezmienny payload, brak wspólnego licznika count | AT-03/09/14 |
| Restart w każdej fazie REQ/ACK i synchronizacji | brak automatycznego powtórzenia, rozliczenie niepewnego skutku przez recovery | AT-09/13 |
| Niezgodna wersja, heartbeat zatrzymany, ale sieć ONLINE, program w WAIT | brak fałszywego CommOK; monitor aktywny podczas prawidłowego WAIT | AT-09 |
| Zanik podczas ruchu, WAIT i zatrzymanie samego monitora | potwierdzona reakcja robota; brak polegania wyłącznie na odczycie bitu pomiędzy ruchami | AT-09/12 |
| Stop przed/po potwierdzonym rozpoczęciu N+1 | nierozpoczęty nie powoduje nieskończonego WAIT; rozpoczęty rozliczony, ładunki/transfery zachowane | AT-02/03 |
| Częściowe odkładanie kilku chwytaków i próbki z tego samego wtrysku | prawidłowe sumowanie dyspozycji bez podwójnego liczenia lub zakończenia po pierwszym detalu | AT-03/14 |
| Przekroczenie pojemności rejestru cykli i niepoprawny cycleId | zablokowany nowy wtrysk, zachowane stare wpisy, brak przypisania detali do N+1 zamiast N | AT-03/13 |
| Zanik Festo lub lokalnych wejść KEC3 przy robot–PLC ONLINE | invalid odpowiedniej grupy; brak potwierdzenia ruchu lub HOME ze starego obrazu | AT-09/15 |
| Zajęty obszar windy/magazynu; odebrane granted, gdy robot wewnątrz | brak kolizyjnego uruchomienia urządzeń PLC; rezerwacja do uzgodnienia | AT-07/14 |
| Manual/Auto, błędny program, samodzielna praca Krauss | jeden właściciel wyjścia; poprawne blokady i pozwolenia niezależne od zlecenia tylko dla trybu samodzielnego | AT-08/10 |
| Pełne cykle obu produkcji, blistry, przekładki, próbki i częściowy stos | każde zdarzenie zgodne z funkcją; pełne opróżnianie dopiero po Koniec zlecenia | AT-04/14 |
| Pomiar opóźnień przez PLC/Festo i SKIP | zapis najgorszej latencji, doboru RPI/timeoutów i bezpiecznej drogi zatrzymania w procedurze szukania | AT-14/15 |

## Stan etapów i bramki

| Część planu | Stan | Co pozostało |
|---|---|---|
| Kontrakt logiczny i pełna migracja symboliczna dostępnych źródeł | PRZYGOTOWANE, przegląd statyczny zakończony | walidacja na docelowej konfiguracji |
| Mapowanie fizyczne | NIEWYKONANE | Weryfikacja dostępnego przykładu EDS i backupu, rozmiary/offsety Festo, docelowy projekt, sprzeczne porty i EUROMAP (GAP-03/04/05/06/08/09) |
| Przepisanie ST/LS i integracja urządzeń | NIEWYKONANE | Eksport/audyt odnalezionych TP, zgodność instrukcji V9.40P/80, zatwierdzona mapa i wybór docelowego PLC, retencja i alarmy (GAP-04/06/11/12) |
| Kompilacja Machine Expert / import FANUC | NIEWYKONANE | docelowe środowiska, opcje i projekt |
| Symulacja protokołu / FAT / SAT | NIEWYKONANE | implementacja i przygotowane środowisko odbioru |

Żaden GAP nie został zamknięty samą dokumentacją. Źródła ST/LS/VA/DG i urządzenia pozostają bez zmian. Materiały odnalezione i pozostałe bramki opisuje [analiza workspace](workspace-analysis.md). Nie wymagać ponownie fizycznego backupu, przykładu EDS, wzorców W716/W590 i projektów PLC/HMI. Potrzebne są ich weryfikacja/wybór, eksport TP, rozstrzygnięcie portów F-2680, pełny obraz Festo/pomiary próżni oraz rozpoznanie początku i rozliczenia cyklu Krauss. Brak jednego elementu blokuje tylko zależny fragment, a nie pozostałe niezależne prace.

## Aktualizacja analizy materiałów i kryteriów

Zapisano ustalenia SRC-09–SRC-15, oddzielając potwierdzenie dokumentacyjne od wykonania instalacji. Przed commitem sprawdzono rozmiary i SHA-256 wszystkich 150 rekordów plikowych w trzech manifestach (6 manuali, 141 rekordów analizy, 3 kopie wejściowe), odsyłacze lokalne i tabele w 15 dokumentach Markdown. Audyt kontraktu: 220 pól i 268 wierszy migracji, wynik poprawny. Dodatkowe trzy negatywne próby w pamięci wykryły brak GAP przy EXPORT_REQUIRED, usunięty ACK próżni 5 i pominięte źródło migracji. Sprawdzono składnię narzędzia Python i brak stałego limitu 1..4 w polach count. To wyniki statyczne, nie odbiór urządzeń.

Dodatkowe scenariusze pozostają NIEWYKONANE: zastosowanie liczby detali podczas aktywnego zlecenia/ruchu musi być zablokowane; zmiana przy zamkniętym zleceniu i potwierdzonym postoju jest dopuszczona; rozpoczęte partie zachowują ilość; zdarzenie z count>4 jest dopuszczalne w granicach ilości partii; przekroczenie tej ilości odrzucane. Dodatkowo sprawdzić przypisanie próżni dla F-2680/F-2844, kierunki po korekcie rysunku oraz podtrzymanie sygnałów zależnych od KF203 podczas Stop.
