# Human instructions — SE-ELDA-Krauss

Aktualizacja 2026-11-15: bieżący stan źródeł obejmuje [nowe moduły stacji](docs/station-plc-implementation.md). Historyczna tabela kolejności poniżej nie oznacza, że OrderManager, Drain i AlarmManager nadal nie istnieją. Kolejnym odbiorem jest konfiguracja i kompilacja projektu natywnego.

Stan: 2026-10-04. Instrukcja prowadzenia projektu przez człowieka. Dotyczy przygotowania i wykonania adaptacji; kod PLC/FANUC oraz projekt HMI nie zostały w tym zadaniu przebudowane.

Zacznij od [założeń](docs/project-assumptions.md). Szczegółowe wymagania REQ, testy AT i braki GAP są w [planie implementacji](docs/implementation-plan.md), a reguły pracy agenta w [AGENTS.md](AGENTS.md).

## 1. Jak korzystać z tej instrukcji

1. Zbierz dane z kroku 0 poniżej i zamykaj tylko te GAP, dla których masz dowód.
2. Realizuj po jednym pakiecie funkcjonalnym. W zadaniu podaj moduły, REQ, AT oraz otwarte GAP.
3. Po każdej zmianie wykonaj przegląd kodu i odpowiednią próbę w docelowym środowisku. Zapisuj wynik; samo przeczytanie kodu nie oznacza kompilacji ani FAT.
4. Równolegle przygotuj szkielet Vijeo według rozdziału 4. Komendy podłączaj dopiero po implementacji i weryfikacji kontraktu PLC.
5. Wszystkie projekty, eksporty, backupy i raporty zapisuj **wewnątrz se-elda-krauss**. Stare repozytorium i oryginały dokumentów są tylko do odczytu.

Dokumentację budowy paneli, importu symboli i prób odbiorczych zawiera [instrukcja HMI Krauss](docs/hmi-instructions.md).

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
| 9 / E4 | GVL_HMI, obsługa żądań, watchdog, symbole, finalne powiązania Vijeo | Importujesz symbole po kompilacji; wiążesz obiekty; sprawdzasz dostępność i potwierdzenia komend | Każdy przycisk ma właściciela w PLC i test. Zanik połączenia lub zamknięcie strony Manual nie pozostawia jogu. AT-01/08/09/14 i [próby odbiorcze HMI](docs/hmi-instructions.md#proby-odbiorcze) |
| 10 / E5 | FAT/SAT, nastawy, trajektorie, backupy końcowe | Przeprowadzasz próby na stanowisku dla Pojemników i Blistrów; zapisujesz wersje i wyniki | Zamknięte braki wpływające na uruchomienie; wymagane AT mają dowody, a nie tylko etykietę PASS |

W kroku 1 ustal także minimalny szkielet OrderManager i reakcje alarmowe, aby urządzenia w krokach 3–6 korzystały z docelowych pozwoleń. Finalizacja w krokach 7–8 nie oznacza odkładania projektu tych zachowań na koniec.

**Ważne podczas integracji Machine Expert:** PRG_Main już wywołuje PRG_IO_Read na początku oraz PRG_IO_Write na końcu. Nie dopisuj drugiego cyklicznego wywołania tych programów w konfiguracji zadania. Deklaracje TYPE są wydzielone do plików ST w `Modules/<moduł>/DUTs/`, a pliki FB zawierają deklaracje zmiennych i logikę bloku; trzeba utworzyć właściwe obiekty DUT/GVL/POU w projekcie natywnym, a nie zakładać, że cały katalog importuje się jednym poleceniem.

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

## 4. Wykonanie HMI

Przygotowanie projektu, import symboli, wspólne akcje, rozmieszczenie kontrolek na wszystkich 20 panelach oraz scenariusze odbiorcze opisuje [instrukcja HMI Krauss](docs/hmi-instructions.md).
