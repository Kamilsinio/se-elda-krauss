(* Festo CPX-AP-A-EP: profil Exact I/O size, 33 B wejsc i 16 B wyjsc.
   Tablice odpowiadaja typom widocznym w EtherNet/IP I/O Mapping Machine Expert.
   Waznosc wejsc wymaga diagnostyki polaczenia i modulow AP (GAP-03).
   Przypisania czujnikow/cewek i reakcje na utrate danych wymagaja potwierdzenia GAP-03/08. *)
{attribute 'qualified_only'}
VAR_GLOBAL
    // Festo -> PLC: kolejne bajty obrazu wejsciowego.
    EipInBytes : ARRAY[0..32] OF BYTE;

    // PLC -> Festo: 8 slow = 16 bajtow; komendy z koncowej logiki wyjsc.
    EipOutWords : ARRAY[0..7] OF WORD;

    // Podglad RAW wedlug numerow modulow AP. Znaczenie maja tylko przypisane indeksy.
    RawDiByModule : ARRAY[2..13] OF BYTE; // Moduly 2, 5, 6, 7, 8, 9 i 13.
    RawCoilCommandByModule : ARRAY[3..17] OF BYTE; // Moduly 3, 10, 11, 14, 16 i 17.
END_VAR
