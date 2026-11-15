TYPE ST_TopFlowOut :
STRUCT
    // komendy dla sprzętu
    TopConveyor_Run : BOOL;
    ElevConv_RunFwd : BOOL; // transporter windy IN podczas TG_ELEV

    // TRUE = podnieś (blokada), FALSE = opuść (zwolnij)
    HoldPos1_Up : BOOL; // stoper M2
    HoldPos2_Up : BOOL; // stoper M3
    HoldPos3_Up : BOOL; // stoper M4

    // bramka tacek P3 (tylko TrayMode=TRUE): TRUE = wysuń M5 (blokada), FALSE = cofnij
    M5_Extend : BOOL;

    // handshake/telemetria do sekwencji windy (tryb kuwet TG_ELEV)
    Elev_TransferReq : BOOL;
    Elev_TransferActive : BOOL;
    Elev_SourcePos : E_TopPos;
    TransferDonePulse : BOOL;
    AcceptedId : UDINT;
    CompletedId : UDINT;
END_STRUCT
END_TYPE
