# Human instructions — SE-ELDA-Krauss

Stan: 2026-10-04. Instrukcja prowadzenia projektu przez człowieka. Dotyczy przygotowania i wykonania adaptacji; kod PLC/FANUC oraz projekt HMI nie zostały w tym zadaniu przebudowane.

Zacznij od [założeń](docs/project-assumptions.md). Szczegółowe wymagania REQ, testy AT i braki GAP są w [planie implementacji](docs/implementation-plan.md), a reguły pracy agenta w [AGENTS.md](AGENTS.md).

## 1. Jak korzystać z tej instrukcji

1. Zbierz dane z kroku 0 poniżej i zamykaj tylko te GAP, dla których masz dowód.
2. Realizuj po jednym pakiecie funkcjonalnym. W zadaniu podaj moduły, REQ, AT oraz otwarte GAP.
3. Po każdej zmianie wykonaj przegląd kodu i odpowiednią próbę w docelowym środowisku. Zapisuj wynik; samo przeczytanie kodu nie oznacza kompilacji ani FAT.
4. Równolegle przygotuj szkielet Vijeo według rozdziału 4. Komendy podłączaj dopiero po implementacji i weryfikacji kontraktu PLC.
5. Wszystkie projekty, eksporty, backupy i raporty zapisuj **wewnątrz se-elda-krauss**. Stare repozytorium i oryginały dokumentów są tylko do odczytu.

Dokumentację HMI rozdzielono na trzy uzupełniające się mapy:

- [Docelowe ekrany, przyciski, parametry i protokół komend](docs/hmi-vijeo-map.md) — projekt interfejsu do zaimplementowania.
- [Wszystkie 208 obecnych pól GVL_HMI](docs/hmi-existing-variables.md) — rzeczywista baza migracji z ograniczeniami.
- [166 wierszy sygnałów oraz 12 urządzeń z Excela](docs/hmi-io-diagnostics.md) — podgląd I/O, nazwy i pochodzenie; żaden wiersz nie daje prawa do bezpośredniego wymuszania wyjścia.

## 2. Kolejność prac nad modułami

Kroki są praktycznym rozwinięciem E1–E5. Kontrakty robota, wtryskarki, alarmów i HMI projektuj razem na początku; ich implementację dziel na mniejsze, testowalne części.

| Krok / etap | Moduły i wynik | Co przygotowujesz lub wykonujesz | Warunek przejścia dalej |
|---|---|---|---|
| 0 / E1 | Natywny projekt, wersje narzędzi, lista braków | Projekt Machine Expert z zadaniami, bibliotekami i konfiguracją urządzeń; firmware M241; GIATV i konfiguracja ATV320; pełny backup FANUC; EDS i konfiguracja Festo; pełny model HMI, Vijeo i projekt wzorcowy W716/C30 | Można otworzyć i skompilować bazę albo każdy błąd bazowy jest opisany. GAP-03/04/06/07 mają przypisane brakujące materiały |
| 1 / E1 | Typy danych i kontrakty robot–PLC–IMM–HMI; stany zlecenia; klasy alarmów | Rozstrzygnięcia GAP-10–12; potwierdzenie mechaniki, polaryzacji, danych wejściowych i odpowiedzialności za wyjścia | Zatwierdzona lista sygnałów i przejść; żadnych fikcyjnych adresów. Nowe pola HMI z tej instrukcji otrzymują wersję kontraktu |
| 2 / E1 | GVL_IO_RAW, GVL_IO, GVL_Robot, PRG_IO_Read, PRG_IO_Write; diagnostyka EtherNet/IP | Konfigurujesz skaner M241, urządzenia, assembly, rozmiary danych, RPI i reakcje na utratę komunikacji. Potwierdzasz barierę, B205 i mapę cewek | Wiarygodne ważność danych i kierunki; podgląd I/O zgodny z fizycznymi sygnałami. AT-09; GAP-01/02/03/04/05/06/08/09 dla użytego zakresu |
| 3 / E2 | FB_Cyl2Pos, FB_StopperPair, FB_Conveyor; pojedynczy właściciel każdej komendy | Testujesz czujniki, cele HOME/WORK, sprzeczności, ruchy ręczne, zatrzymanie taśmy przed stoperem | Każde urządzenie działa osobno; timeout ostrzega i blokuje zależny ruch zgodnie z klasą. AT-07/11/14 |
| 4 / E2 | FB_Elevator, FB_Storage, przegląd FB_SafetyDoor; V201/V202, V401/V402, obsługa BAT4 | Potwierdzasz krańcówki i zatrzymanie windy, reakcję zaworów, utrzymanie detalu, podciśnienia i przedmuchy | Oddzielne sterowania i diagnostyka, wspólne potwierdzenia w Auto; WORK osłon = zamknięcie. AT-07/09/15 |
| 5 / E2–E3 | FB_TopFlowManager i FB_BottomAccumulator_567 | Testujesz barierę, wcześniejszy załadunek, P1–P7, współpracę transporterów oraz jedno wydanie i odbiór B304 | Brak dwóch właścicieli transferu; jeden impuls lokalny daje jedno wydanie; potwierdzenie odbioru obejmuje pojawienie się i zabranie ładunku. AT-05/06 |
| 6 / E3–E4 | Nowy FB_ImmInterface, oba LS FANUC oraz FB_TraySequencer/FB_BoxSequencer | Dostarczasz brakujące podprogramy i potwierdzasz sygnały rzeczywiście rozpoczętego wtrysku. Program wybierasz/uruchamiasz na FANUC | Pełna wymiana IMM i chwytaka przez PLC; zdarzenia z ACK; Stop nie tworzy oczekiwania na kolejny zabroniony wtrysk. AT-03/08/09/10/15 |
| 7 / E3 | Nowe FB_OrderManager i FB_StationDrain, integracja PRG_Main | Próbujesz otwarcia zlecenia, fizycznego Start/Stop, obu produkcji, częściowych ładunków i pełnego opróżnienia | Start zlecenia bez ruchu; rozliczenie wszystkich rozpoczętych operacji; zamknięcie zlecenia dopiero po odebraniu ostatniego ładunku. AT-01–05 |
| 8 / E3–E4 | Odzyskiwanie stanu, finalny FB_AlarmManager, parametry i adapter HMI | Zatwierdzasz retencję, macierz alarmów, zakresy nastaw i warunki ponownego startu | Reset/powrót zasilania/łączności nie wywołuje ruchu. Ostrzeżenie siłownika nie eskaluje drugi raz w sekwencerze. AT-11–13 |
| 9 / E4 | GVL_HMI, obsługa żądań, watchdog, symbole, finalne powiązania Vijeo | Importujesz symbole po kompilacji; wiążesz obiekty; sprawdzasz dostępność i potwierdzenia komend | Każdy przycisk ma właściciela w PLC i test. Zanik połączenia lub zamknięcie strony Manual nie pozostawia jogu. AT-01/08/09/14 i próby HMI z mapy |
| 10 / E5 | FAT/SAT, nastawy, trajektorie, backupy końcowe | Przeprowadzasz próby na stanowisku dla Pojemników i Blistrów; zapisujesz wersje i wyniki | Zamknięte braki wpływające na uruchomienie; wymagane AT mają dowody, a nie tylko etykietę PASS |

W kroku 1 ustal także minimalny szkielet OrderManager i reakcje alarmowe, aby urządzenia w krokach 3–6 korzystały z docelowych pozwoleń. Finalizacja w krokach 7–8 nie oznacza odkładania projektu tych zachowań na koniec.

**Ważne podczas integracji Machine Expert:** PRG_Main już wywołuje PRG_IO_Read na początku oraz PRG_IO_Write na końcu. Nie dopisuj drugiego cyklicznego wywołania tych programów w konfiguracji zadania. Pliki ST są eksportami zawierającymi także TYPE; trzeba utworzyć właściwe obiekty DUT/GVL/POU w projekcie natywnym, a nie zakładać, że cały katalog importuje się jednym poleceniem.

Można równolegle: projektować ekrany, przygotować teksty alarmów i dokumentować I/O. Zmiany dwóch agentów w PRG_Main albo tym samym GVL prowadź kolejno; równoległe przeglądy mogą być tylko do odczytu.

## 3. Modele i poziomy rozumowania — jakość oraz koszt

Rekomendacja projektowa na 2026-10-04: **GPT-6.1 Sol / medium** jako ustawienie codzienne; **Sol / high** do logiki procesu; **Astra / high** do wybranych przeglądów integracji; **Luna / low lub medium** do zadań powtarzalnych z jednoznacznym wynikiem.

Dokumentacja OpenAI rozróżnia Astra jako model do najbardziej wymagających zadań, Sol jako kompromis jakości i kosztu oraz Luna jako wariant ekonomiczny. Dobór do konkretnych modułów poniżej jest rekomendacją dla tego projektu, a nie opublikowanym testem poprawności kodu PLC. [OpenAI — modele](https://developers.openai.com/api/docs/models)

| Zadanie | Model / reasoning effort | Zakres i warunek odbioru |
|---|---|---|
| Inwentaryzacja symboli, uzupełnienie tabel z zatwierdzonej listy, linki, format Markdown | GPT-6 Luna / low | Źródła i schemat wyniku podane wprost; porównanie automatyczne listy wejściowej i wyjściowej |
| Powtarzalne opisy tagów HMI, warianty kontrolek, proste testy z gotowych scenariuszy | GPT-6 Luna / medium | Bez samodzielnego ustalania blokad, klas alarmów lub mapowania sprzętu; przegląd przez Sol |
| Ograniczona zmiana jednego FB, adapter danych HMI, diagnoza kompilatora z pełnym komunikatem | GPT-6.1 Sol / medium | Mały zakres, jawne wejścia/wyjścia, odpowiednie testy i kompilacja |
| Stop przy nakładaniu wtrysków, OrderManager, StationDrain, EUROMAP, handshaki, utrata danych i arbitraż wyjść | GPT-6.1 Sol / high | Analiza stanów i ścieżek błędów; przegląd niezależny dla zmiany przekrojowej |
| Pierwszy przegląd architektury; finalny przegląd robot–IMM–PLC; niewyjaśniony deadlock lub sprzeczne wymagania | GPT-6 Astra / high | Jedno precyzyjne zadanie z aktualnym kontraktem, zmianą kodu i wynikami testów |
| Trudny błąd nadal nierozwiązany po jednej rzeczowej iteracji z logami i reprodukcją | GPT-6.1 Sol / xhigh albo Astra / xhigh | Najpierw popraw kontekst i reprodukcję. Użyj wyższego poziomu tylko do pozostałego problemu |
| Zatwierdzanie trajektorii, polaryzacji, bezpieczeństwa i odbioru fizycznej maszyny | Inżynier + środowisko docelowe | Model pomaga przygotować analizę i scenariusze; nie zastępuje pomiaru, prób i odbioru |

Nie ustawiaj domyślnie max/ultra. Większy wysiłek może pomóc w trudnym problemie, ale nie uzupełnia brakującego backupu, schematu ani pomiaru. Dobieraj poziom jawnie; dostępne wartości zależą od modelu i interfejsu. [OpenAI — reasoning](https://developers.openai.com/api/docs/guides/reasoning)

### Jak rozumieć koszt

Poniżej orientacyjne **stawki standardowego API za milion tokenów**, dla żądań do 272 tys. tokenów wejścia, bez cache, narzędzi, dopłat regionalnych i dodatkowych trybów; nie są taryfą punktów ani limitów Twojej subskrypcji Codex.

| Model | Wejście USD / 1M | Wyjście USD / 1M | Dokumentacja |
|---|---:|---:|---|
| GPT-6 Luna | 0,10 | 0,50 | [Karta modelu](https://developers.openai.com/api/docs/models/gpt-6-luna) |
| GPT-6.1 Sol | 2,00 | 10,00 | [Karta modelu](https://developers.openai.com/api/docs/models/gpt-6.1-sol) |
| GPT-6 Astra | 10,00 | 50,00 | [Karta modelu](https://developers.openai.com/api/docs/models/gpt-6-astra) |

Przy identycznej liczbie tokenów wejścia/wyjścia Astra kosztuje tu 5 razy tyle co Sol, a Sol 20 razy tyle co Luna. Rzeczywisty koszt zadania zależy także od liczby iteracji i rozumowania; tani model powtarzający błędną próbę może nie być najtańszym wykonawcą. Tokeny rozumowania w API są rozliczane jako wyjście. [OpenAI — reasoning i koszty](https://developers.openai.com/api/docs/guides/reasoning)

W aplikacji wybierz dostępny model oraz poziom rozumowania z selektora. Tryb pracy **Plan** służy ustaleniu zakresu, a **Default/implementacja** wykonaniu zmian; nie jest to poziom rozumowania. Tryb API standard/pro to jeszcze osobne ustawienie. Nazw z API nie dopisuj do ustawień aplikacji, jeśli interfejs ich nie udostępnia. Nie potwierdzono Twojego planu taryfowego ani uprawnień do każdego modelu; w razie braku Luna użyj dostępnego Sol / low, a w razie braku Astra — Sol / high i niezależnego przeglądu inżynierskiego. Aktualne ceny i dostępność sprawdź przed długą serią zadań.

### Ekonomiczny cykl pracy z agentem

1. **Jedno zadanie = jeden pakiet z tabeli kolejności.** Dołącz REQ/AT i wskaż konkretne pliki. Nie wysyłaj za każdym razem wszystkich PDF oraz całego starego projektu.
2. **Plan dla niejasnego zakresu, implementacja dla rozstrzygniętego.** Nie każ modelowi ponownie projektować zatwierdzonej architektury przy każdej poprawce.
3. **Najpierw dowód problemu.** Błąd kompilatora, log czasu/stanów, oczekiwany i rzeczywisty przebieg. Podnoszenie reasoning bez nowych danych zwykle nie usuwa przyczyny.
4. **Przegląd niezależny na granicach ryzyka.** Po zmianie Stop/IMM/robot/odzyskiwania daj drugiemu agentowi diff, kontrakt i testy; zleć szukanie kontrprzykładów, nie ponowne pisanie wszystkiego.
5. **Astra w punktach kontrolnych.** Po kontraktach, po integracji kończenia cyklu i przed FAT; nie przy każdej etykiecie przycisku.
6. **Zamykaj zadanie dowodem.** Kompilacja i raport prób są cenniejsze od kolejnego ogólnego przeglądu. Poprawki ponownie sprawdzaj w zakresie, na który wpłynęły.
7. Po zadaniu aktualizuj stan GAP/AT i krótki opis zmian. Następny agent dostaje stan repozytorium, a nie długą historię rozmowy.

### Gotowe polecenia

**Ograniczona implementacja (Sol / medium lub high według tabeli):**

> Przeczytaj AGENTS.md oraz wskazane REQ i AT. Zaimplementuj krok [numer], tylko moduły [lista], w se-elda-krauss. Otwarte GAP: [lista]. Nie zgaduj adresów ani nastaw. Zachowaj pojedynczego właściciela wyjść. Sprawdź kompilację, jeśli dostępne jest środowisko, oraz zachowanie [scenariusze]. Zaktualizuj dokumentację i podaj osobno wykonane i niewykonane sprawdzenia.

**Przegląd integracji (Astra / high):**

> Wykonaj przegląd tylko do odczytu zmian [zakres]. Szukaj kontrprzykładów dla Stop podczas wtrysku N+1, utraty ACK, zaniku komunikacji, restartu i częściowego opróżnienia. Dla każdego problemu podaj sekwencję zdarzeń, skutek, miejsce w kodzie i brakujący test. Nie zmieniaj zatwierdzonych decyzji DEC bez wskazania konkretnej sprzeczności.

**Powtarzalna dokumentacja (Luna / low):**

> Na podstawie [zatwierdzonego pliku] zaktualizuj wyłącznie tabelę [nazwa]. Zachowaj dokładne symbole, typy, kierunki i jednostki. Nie twórz brakujących danych. Porównaj kompletność list przed i po zmianie.

## 4. Co przygotować w projekcie Vijeo Designer

### 4.1. Materiały i projekt bazowy

Przygotuj pełny numer wyświetlacza i jednostki bazowej HMIG…, wersję Vijeo z Service Packiem, firmware/runtime, rozdzielczość, kopię projektu źródłowego HMI poprzedniej maszyny oraz wzorzec W716/C30. Schemat podaje HMIDT351; nie rozstrzyga pełnej konfiguracji jednostki. Schneider rozróżnia część ekranową HMIDT i współpracujący moduł bazowy. [Schneider — zgodność części panelu](https://www.se.com/uk/en/faqs/FAQ000239173/)

Zapisz projekt jako osobny projekt Krauss w podkatalogu repozytorium, np. HMI/Vijeo. Zachowaj edytowalny projekt i eksport/backup właściwy dla użytej wersji, wykaz wersji narzędzi, listę symboli oraz raport kompilacji. Nie dostarczaj wyłącznie pliku runtime.

### 4.2. Komunikacja i symbole

Preferowany wariant projektowy to komunikacja symboliczna obsługiwana przez konkretny zestaw Machine Expert/Vijeo. Wybór potwierdź po otrzymaniu projektu i wersji; Ethernet HMI–PLC nie oznacza automatycznie EtherNet/IP używanego do robota i Festo.

1. W Machine Expert skompiluj rzeczywiste DUT/GVL/POU.
2. Dodaj/uzupełnij Symbol Configuration i wybierz wyłącznie potrzebne pola interfejsu. Statusy udostępnij do odczytu, komendy i bufor parametrów do zapisu zgodnie z możliwościami sterownika.
3. Wyeksportuj symbole do Vijeo; w panelu zaimportuj zmienne z SoMachine/Machine Expert. Schneider opisuje polecenia „Export Symbols to Vijeo-Designer” i „Import Variables From SoMachine…” dla Machine Expert 1.2 oraz Vijeo 6.2 SP9.1; w innej wersji sprawdź jej odpowiednik. [Schneider — import symboli](https://www.se.com/us/en/faqs/FA411965/)
4. Skonfiguruj właściwy sterownik/equipment, nazwę węzła i adres PLC. Adresy 192.168.0.1 / .10 i maska 255.255.255.0 pochodzą ze schematu, wymagają sprawdzenia konfliktów i rzeczywistej konfiguracji.
5. Wybieraj zmienne z listy zaimportowanych symboli. Pełny prefiks urządzenia/aplikacji oraz alias Vijeo może różnić się od zapisu GVL_HMI.… w dokumentacji. Nie zgaduj go ręcznie.
6. Jeśli wybrany zestaw wymaga Modbus TCP zamiast symboli, najpierw zaprojektuj osobny blok wymiany PLC z zatwierdzonymi adresami, typami, kolejnością słów i bitów. Obecne struktury nie mają gotowych adresów %MW. Ten wariant wymaga uzupełnienia mapy przed wiązaniem panelu.

Sprawdź BOOL, 16-bitowe UINT/INT, REAL 32-bit oraz długość i kodowanie STRING. Enumy wyświetlaj poprzez jawny słownik liczb, bo Vijeo może otrzymać wartość liczbową bez etykiety. Nie zakładaj obsługi 64-bitowych typów. [Schneider — ograniczenia typów i enumów](https://www.se.com/uk/en/faqs/FA315437/)

### 4.3. Szkielet ekranów do wykonania teraz

| Panel | Co przygotować |
|---|---|
| HOME | Pięć ikon stacji, Auto/Manual, Praca z robotem, Reset alarmów; stan zlecenia i wykonania; komunikacja; pasek alarmów |
| ZLECENIE | Pojemniki/Blistry, Start zlecenia, Koniec zlecenia, potwierdzone stany, przyczyna blokady; bez nowego przycisku startującego ruch |
| ALARMY | Osobne klasy krytyczne/ostrzeżenia, aktywne i historia, stacja/źródło/krok, potwierdzenie i oddzielny Reset |
| ST01–ST05 STATUS | Animacja procesu, czujniki, diagnostyka, numer kroku i tekst oczekiwania; nawigacja do Manual/Parametrów |
| ST01–ST05 MANUAL | Obiekty według docelowej mapy; w Auto szare; informacja, dlaczego żądanie jest zablokowane |
| ST01–ST05 PARAMETRY | Edytor i odczyt zatwierdzonej wartości; Zapisz/Anuluj; reset stanu stacji tylko Manual. Przy braku parametrów karta pozostaje pusta |
| IMM / EUROMAP | Oddzielne kolumny wejść, żądań i końcowych pozwoleń; ręczne przyciski wyłącznie dla zatwierdzonych procesowych sygnałów |
| DIAGNOSTYKA | PLC/HMI, robot, Festo z modułami, ATV320, ważność danych, wersja kontraktu oraz podgląd sygnałów z Excela |

Możesz utworzyć lokalne zmienne demonstracyjne do budowy ekranów, jednoznacznie oznaczając projekt jako demonstracyjny. Nie mogą pozostać podpięte zamiast rzeczywistych statusów w finalnym runtime. Nie twórz strony receptur.

### 4.4. Zasady powiązania elementów

Pełne nazwy i procedury są w [mapie Vijeo](docs/hmi-vijeo-map.md). Stosuj cztery różne zachowania: odczyt, transakcja jednorazowa z odpowiedzią PLC, ruch przytrzymywany z nadzorem oraz edycja parametru z zatwierdzeniem.

Kolor przycisku wynika z potwierdzonego stanu PLC, a nie z ostatnio naciśniętego żądania. Brak ważnych danych pokazuj jako „brak danych”, a nie jako FALSE, HOME albo pustą stację. Dostępność w HMI poprawia obsługę, natomiast właściwe blokady musi ponownie sprawdzić PLC.

Nie wiąż Start zlecenia do starego xStartAuto ani Koniec zlecenia do xEmptyStation. Nie używaj surowego xOccP4 jako jedynego dowodu braku ładunku windy. Stare xM6Fwd/Bwd nie sterują oddzielnie V201/V202; stare M8 nie ma docelowej interpretacji obu osłon.

### 4.5. Co oddać po przygotowaniu HMI

- Edytowalny projekt Vijeo z wersją docelowego panelu i narzędzia.
- Eksport rzeczywiście użytych symboli i zgodną wersję kontraktu PLC.
- Mapę obiekt → symbol → zachowanie → blokada → potwierdzenie, zgodną z dokumentami w tym repozytorium.
- Słowniki stanów i alarmów oraz zatwierdzone jednostki/zakresy parametrów.
- Raport walidacji/kompilacji i prób HMI z [mapy](docs/hmi-vijeo-map.md); osobno symulacja, komunikacja z PLC i próby na maszynie.
- Backup przed uruchomieniem i backup końcowy z numerem wersji.

Na dziś można wykonać szkielet i przygotować powiązania projektowe. Brak natywnego projektu PLC/HMI, pełnej konfiguracji panelu oraz niezaimplementowane nowe tagi blokują uznanie mapy za gotowy import i potwierdzenie działania przycisków.
