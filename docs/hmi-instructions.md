# HMI instructions — ekrany i elementy do przygotowania

Aktualizacja: 2026-10-05. Lista wykonawcza do przygotowania projektu Vijeo Designer. Zawiera ekrany, elementy i ich konfigurację bez nazw zmiennych oraz adresów.

Najpierw przygotuj wygląd, nawigację, typy obiektów, formaty, stany i warunki dostępności opisane poniżej. Powiązania danych wykonuje się w kolejnym kroku według [mapy powiązań](hmi-vijeo-map.md). Wersję narzędzia, pełny model panelu i materiały wzorcowe opisuje [instrukcja prowadzenia projektu](../human-instructions.md).

## 1. Lista paneli do utworzenia

Przygotuj **20 ekranów podstawowych**. Numery są zgodne z dotychczasowym planem HMI. Zakładki wewnętrzne i lokalne okna potwierdzeń nie są dodatkowymi ekranami procesu.

| Numer panelu | Nazwa | Przeznaczenie |
|---:|---|---|
| 1 | HOME | Przegląd stanowiska i wybór obsługi |
| 2 | ZLECENIE | Wybór produkcji i obsługa zlecenia |
| 3 | ALARMY | Alarmy aktywne, potwierdzenia i historia |
| 101 | ST.1 — STATUS | Załadunek |
| 111 | ST.1 — MANUAL | Ręczna obsługa załadunku |
| 121 | ST.1 — PARAMETRY | Nastawy załadunku |
| 102 | ST.2 — STATUS | Winda |
| 112 | ST.2 — MANUAL | Ręczna obsługa windy |
| 122 | ST.2 — PARAMETRY | Nastawy windy i procesu na windzie |
| 103 | ST.3 — STATUS | Rozładunek |
| 113 | ST.3 — MANUAL | Ręczna obsługa rozładunku |
| 123 | ST.3 — PARAMETRY | Nastawy rozładunku |
| 104 | ST.4 — STATUS | Magazyn przekładek |
| 114 | ST.4 — MANUAL | Ręczna obsługa osłon |
| 124 | ST.4 — PARAMETRY | Nastawy magazynu przekładek |
| 105 | ST.5 — STATUS | Robot i chwytak |
| 115 | ST.5 — MANUAL | Ręczna obsługa pneumatyki chwytaka |
| 125 | ST.5 — PARAMETRY | Nastawy chwytaka i nadzoru robota |
| 201 | WTRYSKARKA / EUROMAP | Podgląd i dozwolone ręczne sygnały procesowe |
| 301 | DIAGNOSTYKA | Komunikacja i podgląd sygnałów |

Na HOME ikony stacji prowadzą do Statusu: 101–105. Na Statusie każdej stacji dodaj zakładki **Status / Manual / Parametry** prowadzące do jej trzech ekranów. Przykład ST.2: 102 / 112 / 122. Robot ma dodatkowy przycisk przejścia do EUROMAP 201.

## 2. Wspólny szablon ekranów

Te elementy przygotuj dla każdego z 20 paneli. Tabele w rozdziale 4 podają zawartość specyficzną dla danego ekranu.

| Element | Typ w Vijeo | Konfiguracja do przygotowania |
|---|---|---|
| Nagłówek | Tekst statyczny | Nazwa ekranu i stacji; spójne położenie i styl. Rozmiar oraz układ dostosuj do rzeczywistej rozdzielczości panelu |
| HOME / Zlecenie / Alarmy / Diagnostyka | 4 przyciski nawigacji, Switch | Jedna akcja zmiany panelu po naciśnięciu; cele 1 / 2 / 3 / 301. Nawigacja nie wysyła polecenia procesu |
| Wstecz | Przycisk nawigacji | Ustalony powrót: ekran stacji → HOME; Manual/Parametry → Status tej stacji; EUROMAP/Diagnostyka/Alarmy/Zlecenie → HOME |
| Pasek alarmów | Alarm Banner lub pasek tekstowy ze wskaźnikiem | Kategoria obejmująca krytyczne i ostrzeżenia; kliknięcie prowadzi do Alarmów. Zwykły stan oczekiwania pokazuj oddzielnie |
| Tryb i ważność danych | Pole tekstowe + wskaźnik wielostanowy | Widoczne Auto/Manual oraz brak danych. Krytyczny czerwony, ostrzeżenie pomarańczowe, brak danych szary. Uzgodnij pozostałą paletę ze wzorcem W716/C30 |
| Miejsce na przyczynę blokady | Pole tekstowe, String Display | Tekst zawijany, czytelny przy nieaktywnych przyciskach; bez ucinania opisu |
| Informacja o wykonywanym poleceniu | Pole tekstowe / wskaźnik | Przyjęto, odrzucono, trwa oczekiwanie na odpowiedź. Kolor stanu urządzenia wynika z jego potwierdzonego statusu |

**Szablon trzech ekranów stacji:** nagłówek i przyciski Status/Manual/Parametry w tym samym miejscu. Aktywna zakładka wyróżniona; zmiana zakładki nie inicjuje ruchu.

## 3. Wzorce konfiguracji elementów

### 3.1. Przyciski nawigacji

Typ: Switch/przycisk. Działanie: jedno przejście do wskazanego panelu po naciśnięciu. Podpis przycisku jednoznacznie określa cel. Przy wyjściu z Manual zakończ żądania ruchów przytrzymywanych i ich nadzór.

### 3.2. Przyciski polecenia i pozycji

Typ: Switch/przycisk z jednorazową obsługą żądania. Jedno naciśnięcie uruchamia jedną operację; trzymanie nie powtarza i nie przełącza polecenia jak Toggle. Na czas obsługi zablokuj ponowne naciśnięcie. Przygotuj stan nieaktywny, oczekiwanie, wynik i przyczynę odmowy.

Dla HOME/WORK siłownika naciśnięcie wybiera cel. **Puszczenie przycisku nie jest poleceniem zatrzymania siłownika.** Obok przygotuj lampki rzeczywistych potwierdzeń HOME/WORK i diagnostykę. Wspólny przycisk pary równoległej ma wspólną komendę, ale osobne lampki krańcówek.

### 3.3. Przyciski ruchu przytrzymywanego

Typ: Switch z działaniem **Momentary ON**. Naciśnięcie żąda ruchu, zwolnienie kończy żądanie. Przygotuj odrębny nadzór każdego przycisku oraz reakcję na opuszczenie strony, utratę połączenia i restart panelu. W Auto przyciski szare i niedostępne. PLC ponownie sprawdza pozwolenia.

Po powrocie łączności ruch wymaga świeżego naciśnięcia. Odświeżanie jednego przycisku nie może podtrzymywać innego. Polityka zatrzymania napędu i utrzymania ładunku pozostaje odpowiedzialnością sterowania.

### 3.4. Lampki, grafika i statusy

Typ: wskaźnik, Indicator/Lamp albo grafika z animacją koloru, widoczności lub pozycji. Dla każdego stanu zaplanuj etykietę. Odróżnij komendę napędu od rzeczywistego potwierdzenia ruchu. Nieaktualny odczyt pokazuj jako „Brak danych”, a nie jako potwierdzoną pozycję lub pustą stację.

### 3.5. Pola tekstowe i odczyty liczbowe

Typ: String Display/tekst wielostanowy lub Numeric Display z wyłączoną edycją. Krok, kod i licznik: liczba całkowita. Częstotliwość: Hz, jedno miejsce po przecinku. Kierunek: etykiety Stop/Naprzód/Wstecz. Dla liczników podaj, czego dotyczą. Teksty diagnostyczne zawijaj; sprawdź polskie znaki.

### 3.6. Edytory parametrów — wspólny układ każdej karty

Dla każdej nastawy utwórz **pole edycji + osobne pole aktualnie zatwierdzonej wartości + jednostkę + zakres**.

| Element | Typ | Konfiguracja do przygotowania |
|---|---|---|
| Edycja czasu | Numeric Input lub Numeric Display z włączoną edycją | Klawiatura numeryczna; liczba całkowita, jednostka ms. Zakres min/max i wartości początkowe z zatwierdzonej listy nastaw |
| Edycja częstotliwości | Pole liczbowe z edycją | Liczba rzeczywista, Hz, jedno miejsce po przecinku; zakres i zależności między prędkościami |
| Edycja liczby sztuk | Pole liczbowe z edycją | Liczba całkowita bez części ułamkowej; jednostka szt.; zatwierdzony zakres |
| Przyjęta wartość | Numeric Display tylko do odczytu | Ten sam format i jednostka co edytor. Nie wyświetlaj edytowanego bufora jako już zastosowanej nastawy |
| Zapisz | Przycisk polecenia | Zatwierdza komplet nastaw tej stacji po walidacji PLC. Podczas odpowiedzi edycja i kolejny zapis nieaktywne |
| Anuluj | Przycisk polecenia | Wczytuje ponownie rzeczywiście przyjęte nastawy i usuwa niezapisane zmiany edycji |
| Wynik walidacji / niezapisane zmiany | Pole tekstowe + lampka | Czytelna przyczyna odrzucenia i informacja o zmienionych polach |
| Reset stanu ST.n | Przycisk polecenia + lokalne okno potwierdzenia | Tylko Manual, postój i uzgodnione warunki stacji. Okno opisuje zakres resetu, ma Potwierdź/Anuluj; samo otwarcie okna niczego nie zeruje |

Edycja parametrów w Manual/postoju jest proponowaną zasadą do zatwierdzenia; liczba blistrów w stosie dodatkowo przy zamkniętym zleceniu. Gdy nie ma zatwierdzonych parametrów stacji, pozostaw pustą kartę; nie uzupełniaj jej sztucznymi nastawami. Zapisz/Anuluj są wtedy ukryte lub niedostępne. Reset stanu jest osobną funkcją, aktywowaną dopiero po ustaleniu jego zakresu.

## 4. Elementy na poszczególnych panelach

### Panel 1 — HOME

Przegląd stanowiska i wybór obsługi. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Ikony ST.1–ST.5 | 5 przycisków graficznych + animacja koloru | Kliknięcie otwiera Status odpowiedniej stacji. Kolor zgodny ze stanem: krytyczny czerwony, ostrzeżenie pomarańczowe, brak danych szary. Dodaj podpis stacji i tekst statusu. |
| Auto / Manual | 2 przyciski polecenia + 2 lampki | Każde naciśnięcie wysyła jedno żądanie zmiany trybu. Lampka wskazuje tryb przyjęty przez PLC. Podczas oczekiwania na odpowiedź zablokuj ponowne naciśnięcie. |
| Praca z robotem | 2 przyciski Włącz/Wyłącz + lampka | Włącz dostępny przy aktualnym HOME i spełnionych blokadach. Wyłącz dostępny po zakończonym Stop. Lampka pokazuje przyjętą opcję. |
| Reset alarmów | Przycisk polecenia | Jednorazowe żądanie resetu; brak powtarzania przy trzymaniu. Pokaż odmowę lub wynik. Reset nie uruchamia ruchu. |
| Stan zlecenia | Pole tekstowe wielostanowe | Teksty: zamknięte, otwarte, kończenie, opróżnianie, odzyskiwanie. Obok wyświetl wybrany rodzaj produkcji. |
| Stan wykonania i oczekiwanie | 2 pola tekstowe | Stan: postój, gotowy, praca, zatrzymywanie, zatrzymany, opróżnianie, oczekiwanie na odbiór, odzyskiwanie. Powód oczekiwania wyświetl z zawijaniem tekstu. |
| Gotowość na fizyczny START | Lampka + pole tekstowe | Lampka potwierdzonej gotowości i tekst blokady. Element służy do odczytu. |
| Komunikacja PLC/HMI, robot, Festo, napęd | 4 wskaźniki stanu | Rozróżnij OK, błąd i brak aktualnych danych. Sam ostatni odczyt nie może utrzymywać zielonego statusu. |
| Liczba krytycznych i ostrzeżeń | 2 pola liczbowe tylko do odczytu | Liczby całkowite bez znaku; czerwone/pomarańczowe etykiety. Kliknięcie obszaru może prowadzić do Alarmów. |

### Panel 2 — ZLECENIE

Wybór produkcji i obsługa zlecenia. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Pojemniki / Blistry | 2 przyciski wyboru + wskazanie aktywnego wyboru | Wybory wzajemnie wykluczające się. Zmiana dostępna przy zamkniętym zleceniu, poza opróżnianiem. Podświetlenie zgodne z wyborem przyjętym przez PLC. |
| Start zlecenia | Przycisk polecenia | Otwiera zlecenie i zatwierdza produkcję. Jedno żądanie na naciśnięcie. Po otwarciu nieaktywny; otwarcie nie wywołuje ruchu. |
| Koniec zlecenia | Przycisk polecenia | Jedno żądanie zakończenia i opróżnienia. Podczas realizacji pokaż oczekiwanie; zablokuj wielokrotne wysłanie. |
| Stan zlecenia i wykonania | 2 pola tekstowe wielostanowe | Oddzielne opisy zlecenia i pracy. Pokaż zatrzymywanie i opróżnianie. |
| Wybrana produkcja i blokada wyboru | Pole tekstowe + lampka | Czytelny podpis aktywnej produkcji; informacja, że zmiana jest zablokowana do zamknięcia zlecenia. |
| Przebieg zakończenia | Lista 4 wskaźników etapów | Rozliczanie rozpoczętych operacji, opróżnianie, oczekiwanie na odbiór, zakończenie. Wskaźniki wynikają z przebiegu procesu. |
| Stacja pusta / transfer w toku / oczekiwanie na odbiór | 3 wskaźniki + pole tekstowe | Rozróżnij brak danych od potwierdzenia pustej stacji. Przy odbiorze podpis „Odbierz stos/pojemnik z wyjścia”. |
| Wynik polecenia / powód blokady | Pole tekstowe | Zawijanie tekstu; widoczne po odmowie oraz podczas niedostępności przycisku. |

### Panel 3 — ALARMY

Alarmy aktywne, potwierdzenia i historia. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Aktywne / Historia | 2 przyciski zakładek | Zmieniają lokalny widok listy. Nie zmieniają alarmów w PLC. |
| Krytyczne / Ostrzeżenia / Wszystkie | 3 przyciski filtrów | Filtr widoku; kolory klas czerwony i pomarańczowy. Przygotuj grupy alarmowe i wspólną kategorię dla widoku Wszystkie. |
| Lista aktywnych | Alarm Summary lub tabela rekordów | Kolumny: czas, klasa, ID, stacja, źródło, opis, aktywny, potwierdzony. Wiersze z czytelnymi kolorami, przewijanie. Ustal źródło potwierdzenia zgodnie z obsługą PLC. |
| Historia | Alarm Summary w widoku historii | Kolumny: wystąpienie, zanik, potwierdzenie, ID, stacja, opis. Sortowanie od najnowszych; format daty i czasu oraz archiwizacja do ustalenia z projektem. |
| Szczegóły wybranego alarmu | Panel tekstowy | Opis przyczyny, urządzenie/krok, zalecana czynność i możliwość resetu. Długi tekst zawijany. |
| Potwierdź alarmy | Przycisk polecenia | Potwierdza przyjęcie informacji. Pokaż stan potwierdzenia z PLC. Lokalny ACK listy musi mieć uzgodnioną integrację. |
| Reset alarmów | Przycisk polecenia | Oddzielny od potwierdzenia. Dostępny według warunków resetu. Reset nie usuwa aktywnej przyczyny ani nie uruchamia ruchu. |
| Liczniki alarmów | 2 pola liczbowe tylko do odczytu | Liczba krytycznych i ostrzeżeń. Informację o zwykłym oczekiwaniu pokazuj jako status procesu. |

### Panel 101 — ST.1 — STATUS

Załadunek. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Schemat załadunku | Grafika + animacje | P1, P2, P3, taśma, pięć grup siłowników i kierunek transportu. Animuj potwierdzone pozycje i ruch. |
| Obecność P1–P3 | 3 lampki | Podpisy B101/B102/B103 i nazwy pozycji; osobny stan brak danych. |
| Bariera załadunku | Lampki + tekst | Wolna/przerwana, aktualność i potwierdzenie przejazdu całego stosu. Oznaczenie sprzętowe do uzupełnienia. |
| Pozycje siłowników | 5 grup wskaźników | Grupy V101/V102, V103/V104, V105/V106, V107/V108, V109/V110. W każdej HOME, WORK, ruch, ostrzeżenie oraz osobne krańcówki obu stron. |
| Transporter | Lampka ruchu + pole kierunku | Potwierdzone włączenie/komenda napędu i kierunek opisane zgodnie z dostępnym sprzężeniem. |
| Gotowość załadunku i priorytet transferu | Wskaźniki + tekst | Miejsce na kolejny stos, przejazd w toku, oczekiwanie na windę/robota. |
| Krok i diagnostyka | Pole liczbowe + 2 pola tekstowe | Krok przepływu, oczekiwany warunek i opis ostrzeżenia/błędu. |

### Panel 111 — ST.1 — MANUAL

Ręczna obsługa załadunku. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Transporter naprzód | Przycisk Momentary ON | Ruch przy trzymaniu; zwolnienie kończy żądanie. Niedostępny w Auto; nadzór utraty łączności i opuszczenia strony. |
| HOME / WORK — V101/V102 | 2 przyciski pozycji | Jednorazowe polecenia wspólnej pary; cel, a nie jog. Obok potwierdzenia lewej i prawej strony. |
| HOME / WORK — V103/V104 | 2 przyciski pozycji | Jak wyżej, dla drugiej grupy. |
| HOME / WORK — V105/V106 | 2 przyciski pozycji | Jak wyżej, dla trzeciej grupy. |
| HOME / WORK — V107/V108 | 2 przyciski pozycji | Jedna wspólna komenda pary, osobne potwierdzenia. |
| HOME / WORK — V109/V110 | 2 przyciski pozycji | Jedna wspólna komenda pary, osobne potwierdzenia. |
| Stan każdej grupy | Lampki + tekst diagnostyczny | HOME/WORK, ruch i ostrzeżenie. Znaczenie góra/dół dopiero po potwierdzeniu mechaniki. |
| Blokady sterowania | Pole tekstowe | Powód odmowy; dla siłowników wymagany postój powiązanej taśmy i brak aktywnego właściciela automatycznego transferu. |

### Panel 121 — ST.1 — PARAMETRY

Nastawy załadunku. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Czas ruchu i stabilizacja 5 grup | 10 edytorów liczbowych + 10 odczytów nastawy | Dla każdej pary V101/V102, V103/V104, V105/V106, V107/V108, V109/V110: próg ruchu i stabilizacja. Liczby całkowite w ms. |
| Opóźnienie zatrzymania taśmy | Edytor liczbowy + odczyt nastawy | Liczba całkowita, ms. |
| Timeout transferu | Edytor liczbowy + odczyt nastawy | Liczba całkowita, ms; rozróżnić nadzór ruchu od oczekiwania na operatora. |
| Próg oczekiwania na stopery | Edytor liczbowy + odczyt nastawy | Liczba całkowita, ms; nie może powodować wtórnej krytycznej eskalacji ostrzeżenia siłownika. |
| Stabilizacja obecności | Edytor liczbowy + odczyt nastawy | Liczba całkowita, ms. |
| Przerwa zmiany kierunku | Edytor liczbowy + odczyt nastawy, warunkowy | ms; dla napędu jednokierunkowego pole ukryte. |
| Zapisz / Anuluj / Reset stanu ST.1 | Elementy wspólne strony parametrów | Konfiguracja według wspólnego wzorca poniżej. |

### Panel 102 — ST.2 — STATUS

Winda. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Schemat windy | Grafika + animacje | Taśma windy, pozycje wysokości, ładunek, V201, V202 i V203. Rozdziel stan czujnika obecności i zapamiętany ładunek. |
| Pozycje wysokości B201–B204 | 4 lampki | Góra, pośrednia górna, pośrednia dolna, dół; wskazanie aktualności. |
| Czujnik B205 | Lampka + tekst | Odczyt czujnika po potwierdzeniu podłączenia. Brak czujnika/aktualności wyświetlany jawnie. |
| Ładunek windy | Wskaźnik wielostanowy | Brak ładunku, ładunek obecny, stan nieuzgodniony. Sam zgaszony B205 nie oznacza pustej windy. |
| V201 / V202 / V203 | 3 grupy wskaźników | Oddzielnie HOME, WORK, ruch, ostrzeżenie i diagnostyka dla każdego siłownika. |
| Napęd i taśma windy | Lampki + pole kierunku | Ruch windy, ruch taśmy i kierunek taśmy; opisz, czy wskazanie jest komendą czy sprzężeniem. |
| Aktualna częstotliwość | Pole liczbowe tylko do odczytu | Hz, jedno miejsce po przecinku. |
| Krok / diagnostyka napędu | Pole liczbowe + tekst | Stan windy, opis oczekiwania, komunikacja i przyczyna błędu. |
| Liczba blistrów w bieżącym stosie | Pole liczbowe tylko do odczytu | Liczba całkowita szt.; widok właściwy dla produkcji Blistrów. |

### Panel 112 — ST.2 — MANUAL

Ręczna obsługa windy. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Winda góra / dół | 2 przyciski Momentary ON | Ruch przy trzymaniu; przeciwne żądania odrzucane. Krańcówki, napęd i pozwolenia blokują kierunki. |
| Szybka prędkość | Przycisk chwilowy lub selektor wyboru | Aktywny tylko dla dopuszczonego jogu windy. Sam wybór nie uruchamia ruchu; po utracie sesji wraca do wolnej. |
| Taśma windy naprzód / wstecz | 2 przyciski Momentary ON | Ruch przy trzymaniu; wymagany właściwy poziom windy i wolna droga transferu. Etykiety kierunków potwierdzić mechanicznie. |
| V201 HOME / WORK | 2 przyciski pozycji | Osobna ręczna komenda lewego pozycjonera; jedno żądanie na naciśnięcie. |
| V202 HOME / WORK | 2 przyciski pozycji | Osobna ręczna komenda prawego pozycjonera. |
| V203 HOME / WORK | 2 przyciski pozycji | Osobna komenda pozycjonera pojemnika. |
| Potwierdzenia i częstotliwość | Lampki + pole liczbowe | Potwierdzenia wszystkich trzech siłowników, wysokości i aktualne Hz; obok pól status ważności. |
| Powód niedostępności | Pole tekstowe | Podaj blokadę konkretnego kierunku lub mechanizmu. Odświeżanie jednego jogu nie podtrzymuje drugiego. |

### Panel 122 — ST.2 — PARAMETRY

Nastawy windy i procesu na windzie. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Liczba blistrów w stosie | Edytor liczbowy + odczyt nastawy | Całkowita liczba szt.; zmiana przy zamkniętym zleceniu. Zakres do zatwierdzenia. |
| Szybka / wolna prędkość windy | 2 edytory liczbowe + 2 odczyty nastaw | Hz, jedno miejsce po przecinku; dodatnia wolna nie większa od szybkiej, obie do zatwierdzonego limitu. |
| Czasy ruchu V201 / V202 / V203 | 3 edytory liczbowe + 3 odczyty nastaw | ms; każdy siłownik ma własny próg. |
| Stabilizacja V201 / V202 / V203 | 3 edytory liczbowe + 3 odczyty nastaw | ms; oddzielnie dla każdego. |
| Timeout przejazdu / zwolnienia B205 / zatrzymania | 3 edytory liczbowe + 3 odczyty nastaw | Liczby całkowite w ms, etykieta opisuje nadzorowaną operację. |
| Próg zatrzymanej windy | Edytor liczbowy + odczyt nastawy | Hz, jedno miejsce po przecinku; dostęp serwisowy według zatwierdzonego projektu. |
| Przerwa zmiany kierunku taśmy | Edytor liczbowy + odczyt nastawy | Liczba całkowita, ms. |
| Blistry — progi procesu | 4 edytory liczbowe + odczyty nastaw | Pozycjonery, potwierdzenie B205, rozładunek, powrót windy. Wszystkie w ms. |
| Pojemniki — progi procesu | 4 edytory liczbowe + odczyty nastaw | Pozycjonery, transfer do windy, rozładunek, powrót windy. Wszystkie w ms. |
| Zapisz / Anuluj / Reset stanu ST.2 | Elementy wspólne strony parametrów | Reset dostępny tylko według procedury uzgodnienia ładunku i pozycji windy. |

### Panel 103 — ST.3 — STATUS

Rozładunek. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Schemat rozładunku | Grafika + animacje | Pozycje P5/P6/P7, strefa wyjazdu z windy, dwie grupy stoperów, kierunek taśmy i wyjście dla operatora. |
| B301 / B302 / B303 / B304 | 4 lampki | B301 = strefa wyjazdu z windy; B302/B303/B304 = pozycje. Podpis opisuje rzeczywistą polaryzację potwierdzoną przy uruchomieniu. |
| Stopery V301/V302 i V303/V304 | 2 grupy wskaźników | HOME/WORK, ruch, ostrzeżenie i osobne krańcówki lewe/prawe. |
| Transporter | Lampka + pole kierunku | Ruch i kierunek; wskaż rodzaj dostępnego potwierdzenia. |
| Jedno wydanie | 3 wskaźniki + tekst | Gotowe do wydania, wydanie w toku, oczekiwanie na odebranie. Widok powiązany z lokalnym przyciskiem. |
| Odbiór operatora | Wskaźnik + komunikat | Pokaż „Odbierz stos/pojemnik”. Następny wyjazd dopiero po potwierdzonym odbiorze B304. |
| Krok i diagnostyka | Pole liczbowe + 2 pola tekstowe | Krok akumulatora, powód oczekiwania i usterka. |
| Pełne opróżnianie | Wskaźnik + tekst | Przebieg zakończenia zlecenia; przycisk końca zlecenia znajduje się na Zleceniu. |

### Panel 113 — ST.3 — MANUAL

Ręczna obsługa rozładunku. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Transporter naprzód / wstecz | 2 przyciski Momentary ON | Ruch przy trzymaniu. Wstecz dostępny tylko po potwierdzeniu obsługi przez napęd i okablowanie. |
| V301/V302 HOME / WORK | 2 przyciski pozycji | Wspólny cel pierwszej pary; wymagany postój taśmy. |
| V303/V304 HOME / WORK | 2 przyciski pozycji | Wspólny cel drugiej pary; wymagany postój taśmy. |
| Pozycje i krańcówki | Lampki | Obecności B301–B304 oraz osobne potwierdzenia siłowników. |
| Stan ruchu i blokady | Pole kierunku + pole tekstowe | Pokaż powód niedostępności i właściciela transferu. Jedno wydanie pozostaje funkcją lokalnego przycisku. |

### Panel 123 — ST.3 — PARAMETRY

Nastawy rozładunku. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Czas ruchu i stabilizacja dwóch grup | 4 edytory liczbowe + 4 odczyty nastaw | Dla V301/V302 i V303/V304: próg ruchu oraz stabilizacja, ms. |
| Opóźnienie po zatrzymaniu silnika | Edytor liczbowy + odczyt nastawy | Liczba całkowita, ms. |
| Timeout kroku | Edytor liczbowy + odczyt nastawy | ms; oczekiwanie na zabranie stosu nie jest zwykłym timeoutem ruchu. |
| Stabilizacja czujników / odbioru | Edytor liczbowy + odczyt nastawy | Liczba całkowita, ms. |
| Przerwa zmiany kierunku | Edytor liczbowy + odczyt nastawy, warunkowy | ms; widoczność zależna od obsługi kierunku wstecz. |
| Zapisz / Anuluj / Reset stanu ST.3 | Elementy wspólne strony parametrów | Reset nie zeruje nierozliczonego wydania ani ładunku między czujnikami. |

### Panel 104 — ST.4 — STATUS

Magazyn przekładek. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Schemat magazynu | Grafika + animacje | Osłona lewa/prawa, strona operatora i robota, poziom przekładek. |
| V401 / V402 | 2 oddzielne grupy wskaźników | Otwarte = HOME, zamknięte = WORK. Dla każdej pozycji, ruch, krańcówki i diagnostyka. |
| Obie osłony otwarte / zamknięte | 2 lampki zbiorcze | Potwierdzenie dopiero po właściwych, aktualnych krańcówkach obu osłon. |
| Dostęp robota / operatora | 2 lampki + pola tekstowe | Rozróżnij pozwolenie i faktycznie aktywny dostęp; pokaż blokadę przeciwnego dostępu. |
| Niski poziom / pusty magazyn | 2 lampki | Podpisy B401/B402; właściwe klasy informacji/ostrzeżeń zgodne z katalogiem alarmów. |
| Krok i diagnostyka | Pole liczbowe + 2 pola tekstowe | Krok magazynu, oczekiwany warunek i usterka. |

### Panel 114 — ST.4 — MANUAL

Ręczna obsługa osłon. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Otwórz obie osłony | Przycisk pozycji | Jedno żądanie przejścia do HOME obu osłon. Wymagane właściwe pozwolenia i brak przeciwnego dostępu. |
| Zamknij obie osłony | Przycisk pozycji | Jedno żądanie przejścia do WORK obu osłon. |
| Potwierdzenia V401 / V402 | 2 grupy lampek | Oddzielne HOME, WORK, ruch i ostrzeżenie; zbiorcze zakończenie wymaga obu potwierdzeń. |
| Pozwolenia dostępu i blokada | Lampki + pole tekstowe | Pokaż warunki dla strony robota/operatora. Polecenia osłon nie są surowym sterowaniem ryglami. |

### Panel 124 — ST.4 — PARAMETRY

Nastawy magazynu przekładek. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Czas ruchu V401 / V402 | 2 edytory liczbowe + 2 odczyty nastaw | Oddzielne progi w ms. |
| Stabilizacja pozycji V401 / V402 | 2 edytory liczbowe + 2 odczyty nastaw | Oddzielne czasy w ms. |
| Stabilizacja sygnałów magazynu | Edytor liczbowy + odczyt nastawy | Liczba całkowita, ms. |
| Timeout pozwolenia procesowego | Edytor liczbowy + odczyt nastawy | ms; nadzór procesu, nie nastawa funkcji bezpieczeństwa. |
| Zapisz / Anuluj / Reset stanu ST.4 | Elementy wspólne strony parametrów | Postój, Manual i uzgodnione dostępy wymagane do zastosowania/resetu. |

### Panel 105 — ST.5 — STATUS

Robot i chwytak. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Robot — tryb i stan | Grupa lampek | Auto, gotowy, uruchomiony, błąd, HOME i ważność wymiany. Program uruchamiany na FANUC. |
| Program i zgodność produkcji | Pole tekstowe + lampka | Faktyczny program oraz zgodność z Pojemniki/Blistry. Informacja o rozbieżności. |
| Krok, oczekiwany warunek i alarm | 2 pola liczbowe + 2 pola tekstowe | Numer kroku, kod alarmu, opis oczekiwania i przyczyny timeoutu. |
| Rozliczenie operacji | Lampki + tekst | Cykl aktywny, kończenie po Stop, wszystkie rozpoczęte operacje rozliczone. |
| Pneumatyka V501–V505 | 5 grup wskaźników | Oś pneumatyczna i cztery siłowniki: HOME, WORK, ruch, ważność, ostrzeżenie/błąd. |
| Próżnie 1–5 | Tabela 5 wierszy ze wskaźnikami | Komenda próżni, rzeczywiste osiągnięcie próżni, ważność potwierdzenia, aktywny przedmuch, diagnostyka. |
| Liczniki produkcji | Pola liczbowe tylko do odczytu | Blistry w bieżącym stosie, gotowe stosy, gotowe pojemniki. Opisz zakres licznika, nie dodawaj nieuzgodnionego zerowania. |
| EUROMAP | Przycisk nawigacji | Otwiera panel 201. |

### Panel 115 — ST.5 — MANUAL

Ręczna obsługa pneumatyki chwytaka. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| V501 HOME / WORK | 2 przyciski pozycji | Pneumatyczna oś 7; jedno żądanie celu. Wymagana uzgodniona własność sterowania. |
| V502–V505 HOME / WORK | 8 przycisków pozycji | Po dwa dla każdego z czterech siłowników; obok osobne potwierdzenia i diagnostyka. |
| Próżnia 1–5 — Załącz / Wyłącz | 10 przycisków polecenia | Po dwa na obwód V509–V513. Zezwolenie na wyłączenie sprawdzane osobno ze względu na trzymany detal. |
| Przedmuch 1–5 | 5 przycisków polecenia | Jednorazowa, czasowo ograniczona operacja. Pozostają nieaktywne do potwierdzenia kanałów i pneumatyki. |
| Potwierdzenia chwytaka i próżni | Lampki + tabela | Komenda i potwierdzenie pokazane osobno. Brak czujnika próżni ma czytelny opis. |
| Własność sterowania / blokada | Pole tekstowe | Manual i przekazanie sterowania przez robota wymagane do poleceń. Bez funkcji zdalnego startu lub jogu osi serwonapędowych FANUC. |

### Panel 125 — ST.5 — PARAMETRY

Nastawy chwytaka i nadzoru robota. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Czas ruchu V501–V505 | 5 edytorów liczbowych + 5 odczytów nastaw | Oddzielny próg ruchu każdego mechanizmu, ms. |
| Stabilizacja V501–V505 | 5 edytorów liczbowych + 5 odczytów nastaw | Oddzielny czas potwierdzenia, ms. |
| Osiągnięcie próżni 1–5 | 5 edytorów liczbowych + 5 odczytów nastaw | Timeout w ms; pola dostępne po zatwierdzeniu potwierdzeń podciśnienia. |
| Czas przedmuchu 1–5 | 5 edytorów liczbowych + 5 odczytów nastaw | Długość impulsu ms; przed potwierdzeniem pneumatyki nieaktywne. |
| Oczekiwanie na robota — Blistry / Pojemniki | 2 edytory liczbowe + 2 odczyty nastaw | Timeout w ms; różnicuj nadzór aktywnej operacji i zwykłe oczekiwanie na operatora. |
| Zapisz / Anuluj / Reset stanu ST.5 | Elementy wspólne strony parametrów | Reset nie kasuje informacji o trzymanym detalu i nie startuje programu FANUC. |

### Panel 201 — WTRYSKARKA / EUROMAP

Podgląd i dozwolone ręczne sygnały procesowe. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| Manual / Podgląd | Zakładki lub rozdzielone obszary | Podgląd zawsze dostępny; elementy ręczne w Auto nieaktywne. |
| Sygnały od Krauss | Tabela lampek | Odrzut, forma zamknięta/otwarta/pośrednia, współpraca, wyrzutnik tył/przód, rdzeń 1 i 2 w pozycjach. Każdy z opisem i aktualnością. |
| Żądania i końcowe pozwolenia | Tabela 2 kolumn wskaźników | Rozdziel żądanie sterującego źródła i końcowy wynik PLC. Wyjście nie jest potwierdzeniem wykonania ruchu Krauss. |
| Zamknięcie / pełne otwarcie formy | 4 przyciski Ustaw/Skasuj | Po dwa dla każdego zatwierdzonego sygnału procesowego. Aktywacja dopiero po uzgodnieniu interfejsu i blokad. |
| Wyrzutnik — tył / przód | 4 przyciski Ustaw/Skasuj | Po dwa na zezwolenie. Dopuszczalne kombinacje według interfejsu Krauss; nie traktować automatycznie jako przeciwnych cewek. |
| Rdzeń 1 / rdzeń 2 — pozycja 1 / 2 | 8 przycisków Ustaw/Skasuj | Po dwa na każde zezwolenie; kombinacje według zatwierdzonego protokołu. |
| Źródło sterowania i rozpoczęty cykl | Pole wielostanowe + lampka | Robot, praca samodzielna, Manual lub brak; osobno potwierdzony cykl aktywny. |
| Warunki Manual | Lampki + pole blokady | Manual, aktualne HOME, zatrzymana współpraca, aktualne dane i zatwierdzona funkcja. Wejście w Auto usuwa wymuszenia. |
| Obszar formy wolny / tryb współpracy | 2 wskaźniki tylko do odczytu | Bez surowych przycisków wymuszania. Sygnały safety, bypass STO oraz funkcje o niepotwierdzonym znaczeniu pozostają podglądem, jeśli dostępny jest zatwierdzony status. |

### Panel 301 — DIAGNOSTYKA

Komunikacja i podgląd sygnałów. Dodaj wspólne elementy z rozdziału 2.

| Element do przygotowania | Typ elementu | Konfiguracja |
|---|---|---|
| PLC/HMI, FANUC, Festo i ATV320 | Tabela stanu | Urządzenie, połączenie, ważność danych, kod/tekst przyczyny. Status brak danych odrębny od OK/błąd. |
| Moduły Festo | Tabela 12 wierszy | BAT100, BAT101, BAT200–BAT205, BAT300, BAT301, BAT400, BAT401. Pokaż obecność, ważność wejść/wyjść, kod i opis diagnostyczny. Nie dotyczy dla modułu bez odpowiedniego kierunku. |
| Grupy podglądu I/O | Zakładki lub selektor lokalny | ST.1, ST.2, ST.3, ST.4, ST.5, EUROMAP, przyciski fizyczne. Zmieniaj widok bez wysyłania komend. |
| Lista sygnałów | Tabela przewijana tylko do odczytu | Oznaczenie urządzenia/sygnału, opis, wartość, ważność, pochodzenie oraz komenda/potwierdzenie. Przygotuj miejsce na 166 pozycji źródłowych; nie dodawaj przycisków wymuszania. |
| Wersje i stan interfejsu HMI | Pola liczbowe/tekstowe | Wersja projektu PLC/HMI i interfejsu, sesja aktywna/uzgadnianie/błąd. Informacje serwisowe, bez operatorskiej edycji parametrów sieci. |
| Szczegóły wybranego problemu | Pole tekstowe | Czytelny opis urządzenia/modułu i brakującego warunku. Zawijanie tekstu. |

## 5. Kolejność przygotowania projektu w Vijeo

1. Wybierz rzeczywisty target i rozdzielczość, ustaw język polski oraz styl zgodny z W716/C30.
2. Utwórz szablon nagłówka, nawigacji, paska alarmów i statusu danych.
3. Utwórz 20 paneli według listy i sprawdź wszystkie przejścia.
4. Przygotuj HOME, Zlecenie i trzy widoki każdej stacji.
5. Dodaj Alarmy z widokiem aktywnym/historią i grupami klas.
6. Przygotuj EUROMAP i Diagnostykę jako tabele; ręczne funkcje EUROMAP pozostaw nieaktywne do zatwierdzenia interfejsu.
7. Ustaw typy przycisków, formaty liczb, jednostki, kolory, widoczność i warunki dostępności według list.
8. Dodaj edytory parametrów, obsługę Zapisz/Anuluj i lokalne potwierdzenia resetu.
9. Sprawdź wygląd w rozdzielczości docelowego panelu: długie komunikaty, polskie znaki, przewijanie tabel, nieaktywne elementy i scenariusz braku danych.
10. Następnie wykonaj powiązania danych i próby zachowania według [mapy powiązań](hmi-vijeo-map.md).

Nie dodawaj receptur ani nieuzgodnionego przycisku HMI Start automatu. Start/Stop ruchu pozostają zgodne z uzgodnioną obsługą przycisków fizycznych; FANUC uruchamiany jest lokalnie na robocie.

## 6. Kontrola przygotowanych ekranów

- Każdy panel z listy istnieje i ma właściwe przejścia nawigacji.
- Każdy element z jego tabeli został przygotowany albo jawnie oznaczony jako oczekujący na brakujące dane.
- Przyciski poleceń, pozycji i ruchów przytrzymywanych mają właściwe, odrębne zachowanie.
- V201/V202 mają osobną obsługę Manual; obie osłony V401/V402 otwierane i zamykane są wspólnie, z oddzielnymi potwierdzeniami.
- Ekrany Manual są nieaktywne w Auto; powód blokady jest czytelny.
- Parametry mają jednostki, właściwy format i oddzielny odczyt przyjętej nastawy.
- Potwierdzenie alarmu, reset alarmów i reset stacji są odrębnymi czynnościami.
- Utrata aktualności nie wygląda jak prawidłowe HOME/WORK albo pusta stacja.
- Przygotowano wszystkie pięć obwodów próżni i miejsce na przedmuchy; brakujące funkcje pozostają nieaktywne do potwierdzenia.
- Sprawdzono nawigację i wygląd; próby poleceń i ruchu odnotowuje się oddzielnie po integracji.

## 7. Dokumentacja typów obiektów

Nazwy dostępnych ustawień i obiektów sprawdź w używanej wersji Vijeo. Opisane zachowania pozostają wymaganiem projektu.

- [Schneider — Momentary ON dla przycisku działającego do zwolnienia](https://www.se.com/us/en/faqs/FA232961/).
- [Schneider — kategoria łącząca grupy w Alarm Banner / Alarm Summary](https://www.se.com/uk/en/faqs/FA193128/).

## Aktualizacja po review PLC — 2026-11-15

W wykonanym PLC GVL_Station.LocalRestartRequired[1..10] jest statusem tylko do odczytu. Po lokalnym timeout komunikat ma wskazywać usunięcie przyczyny i Reset, następnie świeży fizyczny Start w Auto lub zwolnienie i ponowne naciśnięcie w Manual. Sam Reset nie jest wznowieniem. Konflikt osi/taśmy/pozycjonera odbiera obie autoryzacje; nowe naciśnięcie jest wymagane po usunięciu konfliktu. Zmiana ilości i Apply ST.1–ST.4 wymagają także postoju chwytaka i braku aktualnych ręcznych żądań. Pola DUT oznaczone LEGACY nie są aktywnymi nastawami. [Tabela migracji, źródła statusów i granice odbioru](plc-review-fixes.md).
