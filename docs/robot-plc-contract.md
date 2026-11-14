# Kontrakt komunikacji FANUC–PLC v2

Data: 2026-11-14. Status: **SPECYFIKACJA LOGICZNA, NIEURUCHOMIONA**. Dotyczy REQ-03/04/11–19/22; AT-02/03/08–15. Modele urządzeń: [tabliczki](robot-hardware.md). Decyzje użytkownika: niezależne polecenia urządzeń, dwa programy produkcyjne ze wspólnymi procedurami. Przypisania pozostają NIEODEBRANE; propozycję transportu v2 zawiera ROBOT/COMM. Fizyczny backup V9.40P/80, przykład EDS i projekty są już dostępne poza repozytorium; stan ich weryfikacji opisuje [analiza źródeł](workspace-analysis.md).

## 1. Granice i źródło prawdy

PLC M241 jest skanerem, FANUC R-30iB Mate Plus adapterem EtherNet/IP. Robot porozumiewa się procesowo wyłącznie z PLC. PLC ma osobne połączenie z Festo AP i elektryczne I/O EUROMAP 67. Czujniki KEC3 mogą pozostać lokalnymi wejściami PLC. Nie tworzyć dodatkowego sterowania tym samym zaworem przez RI/RO.

Jedynym katalogiem nazw jest [robot-plc-signals.json](robot-plc-signals.json); każdy rekord zawiera kierunek, typ, semantykę, właściciela, ważność i reakcję na utratę danych. `p2r` = PLC → robot, `r2p` = robot → PLC. Prefiksy nie są nazwami gotowych zmiennych ST. `hardware_address: null` oznacza brak zatwierdzonego przypisania. JSON nie jest EDS, layoutem assembly ani deklaracją pamięci PLC.

Katalog zawiera rozwinięte funkcje V501–V505 oraz pięć fizycznych obwodów próżni. Znaczenie technologiczne zależy od narzędzia F-2844/F-2680: w F-2680 Y502/Y503 sterują grupami siłowników, a próżnia 3 służy blistrom. Nie utożsamiać numeru obwodu z numerem detalu; loadMask opisuje zajęcie obwodów według profilu narzędzia, nie liczbę sztuk. Szczegóły i sprzeczne porty: [analiza pneumatyki](workspace-analysis.md). `UINT` to liczba bez znaku 0..65535, a nie BOOL ani dowolny rejestr float. Docelowo kody przenosić przez GI/GO; liczbę słów i kolejność bajtów ustalić dopiero w mapie fizycznej. `BOOL`: 1 oznacza opisaną funkcję, 0 jej brak, nigdy automatyczne przeciwne polecenie. Nowe rdzenie wymagają rozszerzenia katalogu po GAP-05, bez fikcyjnych sygnałów rezerwowych.

Właściciele PLC/RobotInterface, OrderManager, RobotEvents, Gripper i ImmInterface oraz FANUC/LinkMonitor i Production opisują **docelowe odpowiedzialności**, nie już istniejące FB/programy. Rozdzielić transport/RAW, normalizację, urządzenia, proces i końcową arbitrażową komendę.

## 2. Ważność i uruchomienie sesji

`BOOT`: tylko nagłówek link, odczytywany po potwierdzeniu zdrowego połączenia. `SESSION`: dane dopuszczone po zgodnej wersji, gotowości obu stron, zakończonej synchronizacji, aktualnym heartbeat i ważności konkretnej grupy. Żaden status procesowy nie jest safety. Nieaktualny HOME/clear/granted ma wartość logicznie nieprzyznającą pozwolenia, niezależnie od zastanego bitu.

Stany lokalnej warstwy: DISARMED → SYNCHRONIZING → RECOVERY → READY; każda utrata zdrowia → DISARMED. READY oznacza gotową wymianę danych, nie uruchomioną produkcję. W RECOVERY wolno wymieniać statusy diagnostyczne i uzgadniać stan; nie wolno realizować nowych żądań. Komendy starych sesji nie są automatycznie wykonywane.

Na starcie, restarcie, zmianie programu i każdym zaniku sesji obie strony ustawiają ready=0 i syncRequest=1. Odbiorca, po unieważnieniu starej sesji i odłączeniu wykonania nowych żądań, odpowiada syncAck=1 na żądanie partnera. Każdy nadajnik kasuje własne syncRequest po odebraniu własnego potwierdzenia; odbiorca kasuje syncAck po syncRequest=0. Dopiero po zakończeniu **obu** wymian i stabilnym nagłówku można przejść do RECOVERY. Partner otrzymujący nowe syncRequest zawsze opuszcza READY; nie ignoruje go tylko dlatego, że jego własny proces się nie zrestartował.

Przed ustawieniem ready=1 uzgodnić nierozliczone operacje i wyzerować kanały REQ/ACK bez naliczania zdarzeń; nie kasować przy tym informacji o ładunku. Niepewna operacja pozostaje nierozliczona do odzyskania wg GAP-11. Utrata sesji w dowolnej fazie synchronizacji wymaga powtórzenia całości. Różna wersja kontraktu blokuje READY.

Heartbeat każdej strony to licznik modulo 65536; kontrola bada zmianę, nie konkretną wartość. Działa z zadania PLC i monitorowania FANUC niezależnego od WAIT programu. Osobno raportowane running/phase/step pozwalają odróżnić żywy interfejs od zatrzymanego programu. Okres heartbeat, timeout i RPI są konfigurowane; przed pomiarami nie mają zatwierdzonych wartości. Ich brak blokuje uruchomienie, nie jest zastępowany TRUE.

Zanik EtherNet/IP i awaria aplikacji wymagają również potwierdzonej reakcji zatrzymania po stronie robota. Sam bit criticalBlock ani odpytywanie między ruchami nie gwarantują przerwania bieżącego ruchu. Dobór reakcji alarmu adaptera i niezależnego monitorowania FANUC to GAP-04/12; próba musi objąć aktywny ruch, WAIT i zatrzymany monitor. Nie uruchamiać ruchów produkcyjnych przed tym sprawdzeniem. Tor bezpieczeństwa pozostaje odrębny.

## 3. Urządzenia i arbitraż wyjść

Robot wyznacza kolejność; PLC wykonuje cewki i ograniczenia. Priorytet: potwierdzona reakcja awaryjna/utrzymanie ładunku → odzyskiwanie → dokończenie dopuszczonych operacji → nowe Auto albo dozwolone Manual. Zwykłego Stop nie traktować jako awarii. Manual i Auto są wzajemnie wykluczone; wejście w Auto kasuje wymuszenia Manual. PLC/HMI nie nadpisują równolegle wyjść robota.

### Siłowniki V501–V505

- Para home/work: 00 = brak nowego ruchu, 10 = HOME, 01 = WORK, 11 = odrzuć z reason=40. Zmiana celu jest nowym zadaniem i wymaga ponownej oceny blokad. 00 nie nakazuje powrotu.
- acceptedHome/Work informuje o przyjęciu bieżącego celu, busy o ruchu. Kontynuowanie robotowej sekwencji wymaga valid, właściwego accepted i zgodnego atHome/atWork; sam accepted nie wystarcza.
- Sprzeczne krańcówki dają reason=70 i brak ukończenia. Schemat pneumatyczny potwierdza dwukierunkowe zawory 5/3 ze środkiem zamkniętym; końcowe offsety cewek, interpretacja HOME/WORK, sprzeczne porty F-2680, podtrzymanie i timeouty nadal wymagają GAP-03/08. V501 jest osią pneumatyczną, nie serwoosią interpolowaną FANUC.

### Próżnie i przedmuchy 1–5

- cmdValid=1 i hold=1: żądanie utrzymywania próżni. cmdValid=1 i hold=0: jawne żądanie wyłączenia. cmdValid=0 nie zrzuca automatycznie ładunku.
- holdApplied opisuje wyjście po arbitrażu, ok opisuje pomiar. Kontynuacja pobrania wymaga accepted, valid i ok. Stan niesionego ładunku nie wynika wyłącznie z żądania hold.
- Każdy przedmuch ma osobny blowReq/blowAck/blowResult. PLC przyjmuje raz, wykonuje skonfigurowany impuls i sprawdza potwierdzenie zwolnienia. Dopiero wynik terminalny ustawia ACK: 1 ukończono, 2 odrzucono, 3 usterka. W czasie wykonywania ACK=0, busy=1. Wynik i ACK pozostają do REQ=0.
- Konflikt hold=1 i blowReq=1 odrzuca przedmuch, nie wyłącza próżni. Nowy przedmuch wymaga ważnego polecenia wyłączenia próżni, odpowiedniego miejsca odkładania i blokad PLC; samo HOME robota tego nie potwierdza.
- Wyłączenie próżni nie generuje przedmuchu. Utrzymane REQ nie powtarza impulsu. Odrzuconego żądania nie kolejkować; ponowienie dopiero po pełnym 00 kanału i nowej decyzji programu.
- Stop, brak sesji lub criticalBlock nie oznaczają wszystkich wyjść OFF. Stany cewek, przerwanie trwającego impulsu i utrzymanie podciśnienia zatwierdza GAP-08. Brak kompletu czujników/mapy przedmuchów blokuje dany obwód, nie daje fikcyjnego blowResult=1.

## 4. Zdarzenia, obszary i próbki

Kanały zdarzeń: rejectsPlaced, blisterPicked, blisterPlaced, blisterFinished, spacerPlaced, productsPlaced, samplesPlaced, layerFinished, stackFinished, immPickupCompleted. Każdy ma osobne REQ/ACK i własny payload. Payload stabilny przed ustawieniem REQ i aż do ACK=0; nie współdzielić zmiennej count między równoległymi kanałami.

```mermaid
sequenceDiagram
    participant R as Robot
    participant P as PLC
    R->>P: stabilny payload + REQ=1
    P->>P: sprawdź sesję, program i kontekst; zapisz skutek raz
    P-->>R: ACK=1
    R->>P: REQ=0
    P-->>R: ACK=0
    Note over R,P: dopiero teraz kolejne zdarzenie tego typu
```

ACK zdarzenia oznacza jego zarejestrowanie, nie stan urządzenia. Niepoprawny payload lub typ niezgodny z programem: brak ACK, diagnostyka błędu protokołu i RECOVERY; nie pomijać po cichu. Czterofazowa wymiana daje pojedynczą obsługę **w bieżącej sesji**, nie trwałe exactly-once po restarcie. Po utracie ACK w trakcie zaniku nie ponawiać zdarzenia automatycznie; uzgodnić rzeczywisty skutek.

Po jednym nierozliczonym zdarzeniu danego typu; następne czeka w sekwencji robota, bez nadpisywania payload i bez gubienia impulsu. Przy równoczesnych kanałach PLC rejestruje dane w jednym cyklu przed oceną końca stosu. stackFinished można wysłać dopiero po zamknięciu poprzednich wymian odkładania i warstwy.

productsPlaced oznacza potwierdzone odłożenie ilości detali przypisanej do zdarzenia, nie ukończenie warstwy. count jest UINT (technicznie 1..65535) i nie może przekraczać nierozliczonej ilości danej partii. Nie ma stałego limitu czterech detali ani zależności od liczby obwodów próżni. samplesPlaced rozlicza próbki, nie zwiększa automatycznie ilości dobrych detali w pojemniku. rejectsPlaced rozlicza odrzuty osobno, choć fizycznie trafiają do miejsca próbek. Wszystkie trzy dyspozycje mają oddzielne kanały i payloady; ich suma nie przekracza ilości przypisanej do wtrysku. layerFinished nie zwiększa ponownie liczby detali. blisterFinished oznacza napełnienie pojedynczego blistra (stary DO17 w Blistrach), a nie odłożenie pustego blistra ani ukończenie stosu. blisterPicked, blisterPlaced i spacerPlaced mają odrębne skutki dla źródła, windy i magazynu. stackFinished to ukończenie stosu/pojemnika; zwykły Stop nie generuje fałszywego zakończenia niepełnego stosu.

Dostęp do source (źródło blistrów P3), elevator i storage: robot wystawia accessReq, PLC rozstrzyga ready/granted. ready nie jest granted. Robot blokuje ruchy zależne bez granted, valid i aktualnej sesji. accessReq utrzymać przez cały pobyt; clear=1 dopiero po faktycznym opuszczeniu obszaru i przed skasowaniem accessReq. Zezwolenia na zwolnienie magazynu/windy są procesowe, nie safety. Przejście granted=0 przy robocie wewnątrz nie uprawnia PLC do ruchu kolizyjnego — obowiązuje rezerwacja obszaru do uzgodnienia stanu.

samples.req/ack/result: PLC żąda, robot przyjmuje albo odrzuca; ACK nie oznacza odłożenia. Przyjęte żądanie odłożenia kończy się osobnym event.samplesPlaced. Jedno przyjęte żądanie próbek naraz, nowe dopiero po zakończeniu poprzedniego. Nie dodawać nowego fizycznego przycisku ani receptur.

### Parametr liczby detali — DEC-18

Operator może wpisać liczbę detali; PLC stosuje nową wartość tylko przy wyłączonym zleceniu i niepracującej stacji, bez nierozliczonych operacji. Wpisanie wartości w trakcie pracy nie zmienia aktywnej konfiguracji. Każdy rozpoczęty wtrysk/partia zachowuje przypisaną ilość aż do rozliczenia, również podczas Stop i recovery. Dla częściowego odkładania ilość wynika z potwierdzonego kontekstu partii i narzędzia; nie z samego zgaszenia vacuumOK. Brak potwierdzonej nastawy lub stanu blokuje rozpoczęcie nowej produkcji. To wymaganie dla przyszłej implementacji, nie gotowa zmienna HMI/ST. W v2 PLC przekazuje snapshot ilości w p2r.imm.batchCount, związany z cycleId i reject do końca immPickupCompleted.

## 5. EUROMAP i rozliczenie Stop

PLC/ImmInterface jest jedynym właścicielem końcowych wyjść procesowych. r2p.imm.req to żądania, p2r.imm.applied to faktycznie wystawione pozwolenia po arbitrażu; potwierdzenie ruchu pochodzi z oddzielnych wejść maszyny. Sygnał „obszar formy wolny” i historyczny DO101 pozostają poza zwykłym kontraktem do wyjaśnienia granicy safety w GAP-05/09. Tryb samodzielny ustala PLC, nie stare DO104 robota. Arkusz 153 pokazuje wspólne zasilanie styków KF204–KF210 przez KF203:14: odebranie pozwolenia pełnego otwarcia formy odbiera również sygnały trybu współpracy, wyrzutnika i rdzeni. Uwzględnić ten tor w podtrzymaniu pozwoleń podczas Stop; same osobne BOOL nie zapewniają ich niezależności elektrycznej. Rdzenie i nieznane KF211/KF403 pozostają rozszerzeniami OTWARTE.

PLC prowadzi rejestr rozpoczętych wtrysków: cycleId przydziela na potwierdzonym rozpoczęciu, nigdy na wysłanym pozwoleniu ani samej formie zamkniętej. Snapshot unsettledCount nie zastępuje wewnętrznej listy cykli i ich dyspozycji. immPickupCompleted(cycleId) rejestruje pobranie; dopiero productsPlaced/samplesPlaced(cycleId,count) rozlicza odłożenie odpowiedniej partii. Odrzut musi zostać powiązany z konkretnym cyklem i jego rzeczywistą dyspozycją; brak rozpoznanego sposobu odłożenia odrzutu blokuje rozliczenie i wymaga GAP-05/11, nie automatycznego naliczenia jako dobry detal. Dopuszczalne są kolejne częściowe productsPlaced dla różnych detali tego samego cyklu (np. count=1 po każdym chwytaku), każde z pełnym REQ/ACK. PLC sumuje dyspozycje i odrzuca przekroczenie potwierdzonej liczby detali wtrysku. Oczekiwaną liczbę ustalić z zatwierdzonymi parametrami narzędzia przed produkcją; nie wyprowadzać jej z samej liczby zaworów próżni. Nie wysyłać drugiego immPickupCompleted ani drugiego końcowego rozliczenia tego samego cyklu. Rejestr PLC musi obsłużyć co najmniej N i N+1; przed kolejnym pozwoleniem sprawdza wolne miejsce. Przepełnienie nie usuwa starych wpisów, lecz blokuje nowy wtrysk i zgłasza błąd.

Robot rozpoczyna nowe pobranie wyłącznie przy pickupPending=1, cycleKnown=1 i właściwych stanach maszyny. PLC kasuje pickupPending po zarejestrowaniu immPickupCompleted, aby nie przydzielić ponownie tego samego cyklu. Robot musi znać identyfikator pobieranego cyklu. PLC utrzymuje p2r.imm.cycleId do zakończenia handshake immPickupCompleted dla tego pobrania; kolejny fizyczny start zapisuje w swoim rejestrze jako oczekujący. Nie podmieniać identyfikatora bieżącego pobrania na N+1 podczas odkładania N. Przed nowym pobraniem robot kopiuje identyfikator do kontekstu partii; zdarzenia odkładania korzystają z tej kopii. Semantyka pola to identyfikator cyklu przydzielonego do obsługi, nie ruchomy licznik ostatniego startu.

| Zdarzenie | Nowe operacje | Już rozpoczęte | Warunek zakończenia |
|---|---|---|---|
| Stop | newOperationPermit=0 i blokada nowego wtrysku | finishPermit i wymagane procesowe pozwolenia pozostają według fazy | operationsSettled robota + imm.settled + rozliczone transfery PLC |
| Koniec zlecenia | jak Stop | jak Stop, następnie opróżnianie przez PLC | opróżnienie i odbiór ostatniego ładunku B304 |
| Krytyczny błąd/zanik | zablokowane | potwierdzona reakcja awaryjna, osobna od zwykłego Stop | odzyskanie stanu, Reset przy usuniętej przyczynie i fizyczny Start |

N+1 rozpoczęty podczas odkładania N musi zostać pobrany i odłożony także po Stop. Nierozpoczęty N+1 nie może powodować WAIT na formę, która już nie wystartuje. Stop nie odbiera sygnałów potrzebnych do zakończenia rozpoczętego wtrysku; ich zestaw i granice podtrzymania wymagają GAP-05. operationsSettled nie zastępuje HOME ani odwrotnie. Zmiana Pojemniki/Blistry dopiero po zamknięciu zlecenia. Praca Krauss bez robota jest niezależna od zlecenia przy aktualnym HOME i wymaganych blokadach, bez automatycznej paletyzacji.

## 6. Następne bramki i walidacja

[Mapa migracji](robot-plc-migration.csv) obejmuje użycia LS i deklaracje starego GVL; nie jest zatwierdzoną mapą zacisków. [Modernizacja](robot-modernization.md) określa moduły, instrukcje i dane potrzebne do przepisywania. Weryfikację i statusy opisuje [raport](robot-communication-verification.md).

Przed mapowaniem fizycznym zamknąć właściwe części GAP-03/04/05/06/08/09: EDS/assembly, opcje FANUC, natywny PLC, pneumatyka, potwierdzenia i EUROMAP. Następnie zmierzyć pełną latencję robot → PLC → Festo → czujnik → PLC → robot i wpływ na SKIP. Osobno zatwierdzić retencję/recovery (GAP-11) i alarmy (GAP-12). Nie oznaczać E1–E5 jako zakończonych samym przygotowaniem kontraktu.

## 7. Implementacja źródeł v2 — 2026-11-14

[Komunikacja LIVE](../ROBOT/COMM/README.md) i [program tacek](../ROBOT/TRAY/README.md) zawierają źródła LS oraz testy offline. Wszystkie offsety 220 pól v1 pozostały bez zmian; v2 dodaje 7 pól w rezerwach: batchCount, startToken, REQ/ACK rejectsPlaced oraz jego count/cycleId/stackId. Razem 227 pól, 40 słów w każdym kierunku. Version obu nagłówków wynosi 2; v1 nie uzbraja sesji. DO184 jest teraz REQ odrzutów.

startToken zmienia się modulo 65536 po przyjętym fizycznym Start. Robot pobiera wartość bazową przy inicjalizacji/recovery i wymaga kolejnej zmiany po gotowości; odrzucony Start nie jest kolejkowany. Nie uruchamia zadania przez UOP. Geometryczne parametry tacek ustawia się na robocie i kopiuje do konfiguracji aktywnej przy potwierdzonym postoju oraz zamkniętym zleceniu. Partia zachowuje dane do rozliczenia.

Clear i utrzymane accessReq nie są kasowane przez samo odebranie pozwolenia na nowe operacje. Pozostają ważne przy aktualnej sesji i rzeczywistym potwierdzeniu obszaru. Utrata sesji nadal wymaga uzgodnienia rezerwacji przez PLC.

Implementacja PLC v2, import FANUC, powiązania natywne BG, nauka punktów i FAT/SAT są NIEWYKONANE. Żaden status procesu nie zastępuje safety. Archiwalne źródła migracji znajdują się w `../Robot M20iD/old/ROBOT` względem katalogu repozytorium.
