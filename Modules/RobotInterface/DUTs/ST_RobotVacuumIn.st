(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotVacuumIn :
STRUCT
configured : BOOL;
    valid : BOOL;
    ok : BOOL;
    onAllowed : BOOL;
    offAllowed : BOOL;
    blowAllowed : BOOL;
    releaseConfirmed : BOOL;
    blowConfigured : BOOL;
    lossPolicyVerified : BOOL;
    holdOnLoss : BOOL;
END_STRUCT
END_TYPE
