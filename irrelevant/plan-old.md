## Plan: HMI sterowanie siłownikami

Rozszerzyć interfejs HMI tak, aby każdy siłownik M1-M8 miał dwa niezależne sygnały komend ręcznych przód/tył w logice bistabilnej oraz pełny podgląd wszystkich krańcówek jako osobnych bitów statusowych. Najmniejsza i najbezpieczniejsza zmiana powinna zachować istniejące FB wykonawcze FB_Cyl2Pos i FB_StopperPair bez przebudowy ich interfejsów, a nową semantykę rozstrzygać w PRG_Main przez translację komend HMI przód/tył do obecnych wejść CmdExtend/HoldUp i przez jawne mapowanie wszystkich czujników z GVL_IO.di do GVL_HMI.hmiStatus.

**Steps**
1. Faza 1 - rozszerzenie modelu danych HMI. Zmodyfikować ST_HmiCommands w GVLs/GVL_HMI.st tak, aby zastąpić obecne pola jednokierunkowe xM1Extend, xM2HoldUp, xM3HoldUp, xM4HoldUp, xM5HoldUp, xM6HoldUp, xM7Extend, xM8Extend parą pól kierunkowych dla każdego siłownika, np. xM1Fwd/xM1Bwd lub xM1Forward/xM1Backward.
2. W tej samej fazie rozszerzyć ST_HmiStationStatus w GVLs/GVL_HMI.st o osobne bity dla wszystkich krańcówek fizycznych. Dla M1, M2, M3, M4, M5, M6 wystawić po cztery sygnały na siłownik; dla M7 i M8 po dwa sygnały.
3. Faza 2 - translacja nowych komend HMI w POUs/PRG_Main.st. Zmodyfikować sekcję lokalnych zmiennych i kopiowania komend z GVL_HMI.hmiCmd tak, aby wprowadzić lokalne zmienne xHmiM*Fwd i xHmiM*Bwd.
4. Zaktualizować blok HMI MANUAL OVERRIDE w POUs/PRG_Main.st, zachowując warunek xHmiManualMode AND NOT xAutoActive AND NOT xEmptyRunning. Dla FB_Cyl2Pos: Fwd/Bwd mapować na CmdExtend. Dla FB_StopperPair: Fwd/Bwd mapować na HoldUp.
5. Dodać arbitraż konfliktu dla jednoczesnego aktywnego Fwd i Bwd. Rekomendacja: przy konflikcie nie zmieniać komendy wyjściowej i wymusić wzajemną blokadę kierunków na HMI.
6. Faza 3 - mapowanie pełnych krańcówek do statusu HMI. W sekcji HMI STATUS w POUs/PRG_Main.st dopisać bezpośrednie przypisania z GVL_IO.di.ind_M*_... do nowych pól ST_HmiStationStatus.
7. Zachować istniejące zagregowane pola statusowe siłowników (xM1_Extended, xM2_Up, xM3_Up, xM4_Up, xM5_Up, xM6_Up, xM7_Extended, xM8_Extended) dla kompatybilności wstecz.
8. Faza 4 - aktualizacja warstwy HMI poza kodem PLC. Przepiąć bindingi ręcznego sterowania i dodać kontrolki/lamki dla każdej krańcówki.
9. Faza 5 - weryfikacja. Sprawdzić referencje starych nazw, kompletność mapowania krańcówek i logikę konfliktu Fwd/Bwd.

**Relevant files**
- GVLs/GVL_HMI.st
- POUs/PRG_Main.st
- GVLs/GVL_IO.st
- signals/signal_list_plc.csv
- POUs/FB_Cyl2Pos.st
- POUs/FB_StopperPair.st

**Verification**
1. Wyszukać wszystkie odwołania do starych pól HMI komend siłowników i potwierdzić, że zostały zastąpione nowymi nazwami.
2. Wyszukać nowe pola statusowe krańcówek i porównać je z listą sygnałów w GVLs/GVL_IO.st oraz signals/signal_list_plc.csv.
3. Sprawdzić w logice PRG_Main, że dla każdego siłownika istnieje jednoznaczna translacja Fwd/Bwd -> CmdExtend lub HoldUp oraz zdefiniowane zachowanie przy konflikcie.
4. Jeśli dostępna jest diagnostyka środowiska, uruchomić kontrolę błędów dla GVLs/GVL_HMI.st i POUs/PRG_Main.st.
5. Po stronie HMI wykonać test funkcjonalny: przełączenie każdego siłownika w oba kierunki oraz obserwacja lampek wszystkich krańcówek.

**Decisions**
- Zakres wyświetlania obejmuje każdą krańcówkę osobno.
- Komendy HMI dla siłowników są bistabilne i rozdzielone na przód/tył.
- Zakres PLC obejmuje struktury, translację i statusy; wykonanie ekranów HMI pozostaje poza repozytorium ST.
- Rekomendowane jest zachowanie istniejących zagregowanych bitów statusowych dla kompatybilności wstecz.
