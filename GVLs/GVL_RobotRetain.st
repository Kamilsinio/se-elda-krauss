(* W projekcie natywnym skonfigurowac liste persistent, spojnosc zapisu i odtworzenie.
   Sam RETAIN nie jest dowodem atomowosci po zaniku energii. GAP-06/11. *)
{attribute 'qualified_only'}
VAR_GLOBAL PERSISTENT RETAIN
    Context : ST_RobotContext;
END_VAR
