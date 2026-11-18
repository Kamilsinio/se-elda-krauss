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
END_VAR
