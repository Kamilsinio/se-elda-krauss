Hej, jestem w trakcie pisania programu na sterownik PLC SchneiderElectric M241 w oprogramowaniu Machine Expert. 
Będzie to program obsługujący stację automatycznej paletyzacji detali z wtryskarki z robotem 6-cio osiowym FANUC M20iA, 
dwoma typami produkcji zależnymi od rodzaju pojemnika pakowanego przez operatora (kuwety lub stos tacek) oraz trzema transporterami 
(jednym wejściowym - na górze, drugim zamontowanym na windzie góra-dół, a trzecim wyjściowym - na dole). 
Winda sterowana jest falownikiem SE ATV320U07N4C, wyposażonym w moduł komunikacyjny ModbusTCP VW3A3616. 
Robot Fanuc M20iA również wyposażony jest w opcję ModbusTCP. Stacja zrobotyzowana składa się z trzech transporterów 
1. górnego - służącego do załadunku i buforowania, 
2. na windzie poruszającego się w dwóch kierunkach, na którym robot paletyzuje elementy
3. oraz dolnego służącego do rozładunku. 


## Produkcja do tacek (tray)
Opiszę teraz typ produkcji dla tacek: 
Operator najpierw podaje stos do modułu załadunku, 
później naciska przycisk o poprawnym załadowaniu pojemnika, sprawdzane są czujniki, oraz pozycjonowany jest pojemnik siłownikiem M1. 
W pierwszym cyklu pojemnik rusza od razu na pozycję nr 3, każdorazowo kiedy oczewikany jest stos na P3, przed wysterowaniem transportera górnego należy najpierw wysunąć pozycjoner tacek (siłownik M5 używany jest tylko w produkcji do tacek) 
Kiedy stos pojawi się na pozycji P3, cofany jest pozycjoner M5, a następnie wysterowywany jest M4 do góry (fwd)
Kiedy blokada tacek M4 jest w górze, wysyłana jest informacja do robota o gotowości stosu do pobierania tacek.
Robot pobiera po jednej tacek ze stosu i kładzie ją na windę. (robot musi dostać informację o gotowości windy)
Za każdym razem kiedy robot położy tackę na windzie wysuwany jest pozycjoner M6, a następnie cofany,
winda zjeżdża na dół aż nie zgaśnie czujnik 'ind-container-ind_container_in_pos_4' dzięki temu paletyzacja odbywa się zawsze na tej samej wysokości. 
W międzyczasie Operator ładuje kolejny stos. Który powinien dojechać do końca transportera buforującego 
(tj. pierwszego wolnego miejsca od strony windy na transporterze buforującym.) 
I może w ten sposób zapełnić cały bufor. Po spaletyzowaniu całego stosu, siłowniki M5 i M4 cofają się (bwd),
a winda jedzie na dół i równocześnie uruchamiają się dwa transportery: na windzie oraz dolny, rozładunku. 
Winda jest opróżniana i wraca do góry, w międzyczasie kolejny stos tacek wjeżdża na pozycję 3, a proces powtarza się. 
Aby uniknąć kosztownych przestojów (niski czas cykli wtryskarki z której robot pobiera detale) 
należy spriorytetyzować podawanie stosów do robota, a dopiero później zająć się buforowaniem. 
na każdej pozycji pojemnika na górnym transporterze znajdują się siłowniki które podnoszą pojemniki, 
tak aby transporter mógł poruszać się pod nimi przemieszczając akurat buforowany pojemnik. 
Blokowanie pojemnika na pozycji odbywa się w taki sposób, że najpierw transporter musi dojechać pojemnikiem do danej pozycji 
(do momentu aż zapali się odpowiedni czujnik) W tym momencie transporter zatrzymuje się. 
Dopiero wtedy można załączyć blokadę pozycji fizycznie podnoszącą pojemnik nad transporter. 
Dodatkowo operator ma do dyspozycji przycisk opróżnij stację, który powinien po kolei 
dostarczyć wszystkie pojemniki do wyjścia (kierunek ruchu zgodny z normalną pracą ale pomijamy proces paletyzacji) 
Do dyspozycji jest również przycisk "Kontynuuj" który powinien wznowić pracę całej maszyny po przerwie, 
błędzie albo przerwaniu obwodu safety od momentu, w kórym nastąpiła przerwa. Z panelu HMI trzeba również móc sterować ręcznie wszystkimi
siłownikami, transporterami oraz windą. 


## Produkcja do kuwet (box)
Opis produkcji do kuwet:
Operator podaje stos w identyczny sposób, kuweta wjeżdża od razu na windę i jest tam pozycjonowana siłownikiem M7.
Aby kuweta wjechała na windę należy uruchomić dwa transportery równocześnie. 
Winda w kierunku robota oraz górny w kierunku robota.
Winda zjeżdża w dół aż nie zgaśnie czujnik 'ind-container-ind_container_in_pos_4'.
W między czasie operator może ładować kuwety które są buforowane na górnym transporterze.
Po skończeniu paletyzacji przez robota winda zjeżdża na dół, uruchamiane są dwa transportery
winda w kierunku operatora oraz dolny w kierunku operatora.

Podsumowując: pozycje 1-3 są na górnym transporterze, pozycja 4 to transporter na windzie, 
pozycje 5-7 są na dolnym transporterze.
Przejście z windy na dolny transporter odbywa się przez załączenie dwóch transporterów jednocześnie. 
Dla stoperów M2/M3/M4 fwd oznacza podniesienie pojemnika nad transporter taśmowy, czyli blokadę jego ruchu. 
Podniesienie lub opuszczenie pojemnika wymaga zatrzymania transportera. 
Styczniki silników transporterów są połączone w taki sposób, że nie da się równocześnie uruchomić go w dwóch kierunkach 
(nie da się zewrzeć faz). Po ulożeniu tacki na windzie bazuje się, jest ona pozycjonowana przez siłowniki, 
a następnie bazuje się ona do krawędzi pojemnika (jest sterowana w dół dopóki nie zgaśnie czujnik). 
Nie zajmuj się safety, jest ono realizowane przez dedykowany sterownik.

Chciałbym, żebyś rozwinął projekt tak aby był on funkcjonalny - uruchomienie pracy w auto, na samym końcu zajmiemy się HMI, 
w którym należy umożliwić manualne sterowanie windą, oraz siłownikami. 
ilość tacek w stosie powinna być konfigurowalna ale zawsze taka sama. 
Czy wszystko jest zrozumiałe? 
Jakich ewentualnie informacji jeszcze potrzebujesz?
