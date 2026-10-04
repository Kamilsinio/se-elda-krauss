# FB_Elevator - winda osi pionowej z ATV320

## Rola funkcjonalna

`FB_Elevator` steruje pionowym ruchem windy przez falownik Schneider ATV320 używany z blokiem bibliotecznym `GIATV.Control_ATV`.

Blok odpowiada za:

- tryb ręczny `MANUAL`,
- tryb automatyczny `AUTO`,
- wybór kierunku góra/dół,
- wybór prędkości wolnej albo szybkiej,
- obsługę targetów pozycji,
- specjalny target `posContainerEdge`,
- diagnostykę pozycji, timeoutów, safety, drzwi i falownika,
- wygenerowanie komend do `Control_ATV`.

Ważne: `FB_Elevator` steruje tylko ruchem pionowym windy. Transporter zamontowany na windzie P4 jest sterowany osobno przez `fbConvElev : FB_Conveyor`.

## Gdzie jest używany

W `PRG_Main` jest jedna instancja:

- `fbElevator : FB_Elevator`.

Struktury pomocnicze w `PRG_Main`:

- `elevCmd : ST_ElevatorCmd` - komendy do windy,
- `elevIn : ST_ElevatorIn` - wejścia/czujniki,
- `elevPar : ST_ElevatorPar` - parametry,
- `elevOut : ST_ElevatorOut` - wyjścia logiczne,
- `elevStat : ST_ElevatorStat` - status i diagnostyka.

Z windy korzystają głównie:

- `FB_TraySequencer` - cykl tacek,
- `FB_BoxSequencer` - cykl kuwet,
- logika opróżniania stacji w `PRG_Main`.

`FB_TopFlowManager` nie steruje ruchem pionowym windy bezpośrednio. TopFlow koordynuje podanie pojemnika na P4 i transfer transporterami, a ruch pionowy jest wywoływany przez sekwencery albo emptying.

## Pozycje i targety

### Pozycje fizyczne `E_ElevatorPos`

Winda ma cztery czujniki pozycji:

- `posTop` - skrajnie górna,
- `posIntermediateTop` - górna pośrednia,
- `posIntermediateBottom` - dolna pośrednia,
- `posBottom` - skrajnie dolna.

W `PRG_Main` są mapowane z:

- `ind_elevator_in_top_pos`,
- `ind_elevator_in_intermediate_top_pos`,
- `ind_elevator_in_intermediate_bottom_pos`,
- `ind_elevator_in_bottom_pos`.

### Targety `E_ElevatorTarget`

W trybie AUTO można zadać:

- `posTop`,
- `posIntermediateTop`,
- `posIntermediateBottom`,
- `posBottom`,
- `posContainerEdge`.

`posContainerEdge` jest targetem specjalnym. Nie oznacza konkretnego czujnika pozycji windy. Oznacza: jedź w dół aż zgaśnie czujnik pojemnika na P4:

```iecst
xAtTargetInt := NOT stIn.xContainerInPos4;
```

Ten target realizuje wymaganie procesu: po każdej tacy albo po pozycjonowaniu kuwety winda zjeżdża tak, aby górna krawędź pojemnika była na stałej wysokości dla robota.

## Interfejs wejściowy

### `xEnable : BOOL`

Główne zezwolenie pracy FB. Gdy `xEnable = FALSE`, stan przechodzi do `DISABLED`, a ostatnia znana pozycja jest kasowana do `UNKNOWN`.

### `stCmd : ST_ElevatorCmd`

Komendy:

- `eMode` - tryb `MANUAL` albo `AUTO`,
- `xStop` - zatrzymanie soft,
- `xReset` - reset błędów FB i impuls resetu falownika,
- `rSpeedFast_Hz` - prędkość szybka,
- `rSpeedSlow_Hz` - prędkość wolna,
- `xAutoGo` - impuls startu targetu AUTO,
- `xAutoStop` - zatrzymanie AUTO,
- `eAutoTarget` - zadany target AUTO,
- `xManUp` - jazda ręczna w górę,
- `xManDown` - jazda ręczna w dół,
- `xManFast` - prędkość szybka w ręcznym.

W trybie AUTO target jest latchowany na zboczu `xAutoGo`, nie na poziomie ciągłym.

### `stIn : ST_ElevatorIn`

Wejścia:

- `xInPos1..xInPos4` - czujniki pozycji windy,
- `xContainerInPos4` - pojemnik na windzie P4,
- `xLS_Top` - limit górny,
- `xLS_Bottom` - limit dolny,
- `xSafetyOk` - safety,
- `xDoorClosed` - drzwi celi robota zamknięte,
- `xCommOk` - komunikacja/permisyw komunikacji,
- `stVfdRx.uiOutFreq_0p1Hz_3202` - aktualna częstotliwość falownika w 0.1 Hz.

W aktualnym `PRG_Main` `xCommOk` jest podane jako `TRUE`, a realny status ATV jest czytany przez `GIATV.Control_ATV`.

### `stPar : ST_ElevatorPar`

Parametry:

- `rMaxSpeed_Hz` - ograniczenie prędkości,
- `tMoveTimeout` - timeout standardowego ruchu,
- `tClearPos4Timeout` - timeout ruchu do `posContainerEdge`,
- `tVfdResetPulse` - długość impulsu resetu falownika,
- `xFwdIsUp` - mapowanie kierunku FWD/REV względem góra/dół,
- `wStsMask_*` - maski bitów statusu ATV320,
- `rStopSpeedThreshold_Hz` - próg uznania napędu za zatrzymany,
- `tStopTimeout` - maksymalny czas oczekiwania w `STOPPING`.

## Interfejs wyjściowy

### `stOut : ST_ElevatorOut`

Wyjścia logiczne:

- `xRunUp` - FB żąda ruchu w górę,
- `xRunDown` - FB żąda ruchu w dół.

To są statusy logiczne. Fizyczne sterowanie falownikiem odbywa się przez wewnętrzne wywołanie `GIATV.Control_ATV`.

### `stStat : ST_ElevatorStat`

Status zawiera:

- aktualny stan automatu `eState`,
- aktualną pozycję `ePos`,
- ostatnią znaną pozycję `eLastPos`,
- zapamiętany target `eTargetLatched`,
- `xBusy`,
- `xAtTarget`,
- aktualnie wybraną prędkość,
- statusy falownika,
- fault FB i numer błędu.

### `uiState : UINT`

Stan automatu jako liczba, przeznaczony do HMI/diagnostyki.

## Automat stanów

`FB_Elevator` używa stanów:

- `DISABLED` - FB bez zezwolenia,
- `IDLE` - gotowy, brak ruchu,
- `MANUAL_UP` - jazda ręczna w górę,
- `MANUAL_DOWN` - jazda ręczna w dół,
- `AUTO_UP` - jazda automatyczna w górę,
- `AUTO_DOWN` - jazda automatyczna w dół,
- `STOPPING` - oczekiwanie na wyhamowanie napędu,
- `FAULT` - błąd zatrzaskiwany.

## Jak działa kod krok po kroku

1. Na początku FB czyta status `Control_ATV`:

   - `q_wStatusword`,
   - `q_xAlrm`,
   - `q_xEn`.

   Na tej podstawie aktualizuje diagnostykę VFD: fault, ready, running, remote i comm ok. Aktualna częstotliwość jest brana z wejścia `stVfdRx`.

2. FB zlicza aktywne czujniki pozycji `xInPos1..xInPos4`.

3. Jeśli aktywnych jest więcej niż dwa czujniki, ustawia pozycję `UNKNOWN` i traktuje to jako konflikt.

4. Jeśli nie ma konfliktu, wybiera pozycję według priorytetu:

   - `xInPos1` -> `posTop`,
   - `xInPos2` -> `posIntermediateTop`,
   - `xInPos3` -> `posIntermediateBottom`,
   - `xInPos4` -> `posBottom`,
   - brak czujnika -> `UNKNOWN`.

5. Ostatnia znana pozycja `eLastPos` jest aktualizowana, gdy aktualna pozycja nie jest `UNKNOWN`.

6. FB buduje permisywy:

   - `xPermCommon` - enable, safety, drzwi, komunikacja i brak faultu VFD,
   - `xPermUp` - `xPermCommon` oraz brak limitu górnego,
   - `xPermDown` - `xPermCommon` oraz brak limitu dolnego.

7. `xAutoGo` i `xReset` są obsługiwane zboczami `R_TRIG`.

8. FB wyznacza `xAtTarget` dla aktualnie zapamiętanego targetu.

9. Timeout ruchu używa dwóch czasów:

   - standardowo `stPar.tMoveTimeout`,
   - dla `posContainerEdge` czas `stPar.tClearPos4Timeout`.

10. Faulty są zatrzaskiwane. Reset następuje dopiero na zboczu `stCmd.xReset`.

11. W `IDLE`, jeśli tryb to `MANUAL`, target AUTO jest czyszczony.

12. W `IDLE`, jeśli tryb to `AUTO` i pojawi się zbocze `xAutoGo`, target jest zapamiętywany do `eTargetLatched`.

13. Dla standardowych targetów FB porównuje indeks aktualnej pozycji z indeksem targetu:

   - mniejszy indeks to wyżej,
   - większy indeks to niżej.

14. Dla `posContainerEdge` FB nie porównuje indeksów, tylko wymusza jazdę w dół do momentu zgaśnięcia P4.

15. Po osiągnięciu targetu FB przechodzi do `STOPPING`, nie od razu do `IDLE`.

16. W `STOPPING` FB czeka, aż częstotliwość VFD spadnie poniżej progu `rStopSpeedThreshold_Hz` albo minie `tStopTimeout`.

17. Na końcu FB wyznacza żądany kierunek i prędkość, mapuje góra/dół na FWD/REV zgodnie z `xFwdIsUp`, a potem wywołuje `GIATV.Control_ATV`.

## Profile prędkości

W trybie ręcznym prędkość szybka zależy od `xManFast`.

W trybie AUTO prędkość szybka jest używana tylko w środkowym odcinku jazdy:

- przy jeździe w górę: gdy ostatnia znana pozycja to `posIntermediateBottom`,
- przy jeździe w dół: gdy ostatnia znana pozycja to `posIntermediateTop`.

W pozostałych odcinkach używana jest prędkość wolna. Dzięki temu winda może ruszać i dojeżdżać wolniej przy skrajnych pozycjach, a szybciej przejeżdżać środkowy zakres.

## Faulty i numery błędów

Aktualne fault ID:

- `10` - konflikt czujników pozycji,
- `20` - timeout ruchu,
- `30` - utrata komunikacji w ruchu,
- `40` - utrata safety w ruchu,
- `41` - otwarcie drzwi w ruchu,
- `50` - nieznana pozycja przy starcie AUTO,
- `51` - błąd mapowania pozycji/targetu,
- `60` - fault falownika,
- `999` - nieobsłużony stan automatu.

## Zależności w programie

Ogólna ścieżka:

```text
PRG_IO_Read
  -> GVL_IO.di
    -> PRG_Main mapuje wejścia do elevIn/elevPar/elevCmd
      -> FB_TraySequencer / FB_BoxSequencer / emptying ustawiają targety windy
        -> FB_Elevator steruje ruchem pionowym przez GIATV.Control_ATV
          -> elevStat wraca do sekwencerów, HMI i alarmów
```

`FB_Elevator` nie zapisuje bezpośrednio wyjść `GVL_IO.dout`. Sterowanie falownikiem odbywa się przez `Axis := Altivar_320` w `GIATV.Control_ATV`.

## Relacja z TraySequencer

`FB_TraySequencer` używa windy w trybie tacek:

1. Sprawdza, czy winda jest u góry i P4 jest puste przed rozpoczęciem cyklu.
2. Po każdym odłożeniu tacki przez robota wykonuje cykl M6.
3. Następnie zadaje windzie target `posContainerEdge`.
4. Gdy P4 zgaśnie, robot dostaje ponownie `Robot_ElevatorReady`.
5. Po zakończeniu stosu TraySeq zadaje zjazd windy na dół.
6. Po opróżnieniu P4 zadaje powrót windy na górę.

TraySeq czyta z windy:

- `Elev_AtTop`,
- `Elev_AtBottom`,
- `Elev_AtTarget`,
- `Elev_Busy`,
- `Elev_Fault`.

## Relacja z BoxSequencer

`FB_BoxSequencer` używa windy w trybie kuwet:

1. Czeka na podanie kuwety na P4.
2. Po spozycjonowaniu M7 zadaje `posContainerEdge`.
3. Po zgaśnięciu P4 daje robotowi `Robot_ElevatorReady`.
4. Po zakończeniu pracy robota zadaje `posBottom`.
5. Po opróżnieniu windy zadaje `posTop`.

BoxSeq korzysta z tych samych statusów windy co TraySeq.

## Relacja z TopFlowManager

TopFlow nie rusza windą w pionie. TopFlow potrzebuje tylko informacji, że winda może przyjąć pojemnik na P4:

```text
Elev_CanAccept = winda u góry AND P4 puste
```

Gdy TopFlow realizuje transfer na windę, `PRG_Main` załącza transporter windy `fbConvElev.Cmd.RunFwd`. To jest ruch poziomy pojemnika na P4, nie ruch pionowy windy.

## Relacja z opróżnianiem stacji

Logika emptying w `PRG_Main` używa windy bezpośrednio:

- zadaje `posBottom`, gdy P4 ma zostać opróżnione,
- po rozładunku zadaje `posTop`,
- używa `ind_elevator_emptied` do potwierdzenia, że pojemnik opuścił windę.

## Tryb ręczny

W trybie ręcznym `PRG_Main` ustawia:

- `elevCmd.eMode := MANUAL`,
- `xManUp`,
- `xManDown`,
- `xManFast`.

`FB_Elevator` dopuszcza ruch ręczny tylko wtedy, gdy aktywny jest odpowiedni permissive:

- w górę: `xPermUp`,
- w dół: `xPermDown`.

Jeżeli operator poda jednocześnie górę i dół, FB nie wystartuje nowego ruchu z `IDLE`, a jeśli jest już w ruchu, przejdzie do `STOPPING`.

## Tryb automatyczny

Poza trybem ręcznym `PRG_Main` ustawia tryb `AUTO` i czyści domyślne komendy. Następnie aktywny sekwencer albo logika emptying wpisuje:

- `xAutoGo`,
- `eAutoTarget`,
- opcjonalnie `xAutoStop`.

`FB_Elevator` łapie target na zboczu `xAutoGo`. Dlatego sekwencery mogą wystawiać `xAutoGo` przez wiele skanów, ale faktyczne zapamiętanie targetu dzieje się na zboczu.

## Na co uważać przy uruchomieniu

- Sprawdź `xFwdIsUp`. Jeśli kierunki FWD/REV są odwrócone względem mechaniki, winda pojedzie przeciwnie do oczekiwań.
- Sprawdź po kolei wszystkie czujniki pozycji: góra, pośrednia góra, pośrednia dół, dół.
- Aktualna diagnostyka konfliktu pozycji zgłasza błąd dopiero, gdy aktywne są więcej niż dwa czujniki pozycji. Dwa jednoczesne czujniki są tolerowane, nawet jeśli fizycznie taka kombinacja jest podejrzana.
- Dla `posContainerEdge` warunkiem końca jest zgaśnięcie `ind_container_in_pos_4`. Jeżeli ten czujnik jest źle ustawiony, winda może zatrzymać się za wcześnie albo wejść w timeout.
- `tClearPos4Timeout` w `PRG_Main` ma `T#5s`. Przy wolnym ruchu lub dużej wysokości zejścia może być zbyt krótki.
- `xCommOk` w `PRG_Main` jest obecnie ustawione na `TRUE`; realną diagnostykę ATV trzeba obserwować przez `Control_ATV` i `elevStat.xVfdCommOk`.
- `STOPPING` zależy od aktualnej częstotliwości VFD. Jeżeli odczyt częstotliwości nie działa, wyjście ze `STOPPING` nastąpi dopiero po `tStopTimeout`.
- Przed AUTO winda musi znać pozycję. Jeśli `ePos` i `eLastPos` są `UNKNOWN`, start AUTO kończy się faultem `50`.
- Drzwi celi robota są permissivem windy. Otwarcie drzwi w ruchu powinno zatrzymać windę i wygenerować fault `41`.

## Miejsce w hierarchii

`FB_Elevator` jest najwyższym z bloków wykonawczych niskiej warstwy. W odróżnieniu od prostych siłowników i transporterów zawiera własny automat pozycjonowania oraz integrację z falownikiem.

```text
TraySequencer / BoxSequencer / Emptying
  -> PRG_Main
    -> FB_Elevator
      -> GIATV.Control_ATV
        -> ATV320
          -> ruch pionowy windy
```

Nad windą pracują sekwencery procesu, a pod windą jest biblioteczny blok napędowy `Control_ATV`.

