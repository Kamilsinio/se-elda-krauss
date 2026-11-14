{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_TopFlowState :
(
    INIT := 0,
    IDLE := 10,

    PREP_STOP := 20,        // zatrzymaj transporter + zwłoka
    PREP_STOPPERS := 30,    // ustaw stopery na żądane pozycje (UP/DOWN)

    RUN := 40,              // jedź transporterem do celu
    WAIT_STOP := 50,        // po stopie odczekaj zwłokę przed stoperami

    RETRACT_M5_GATE := 55,  // (tylko TrayMode+TG_P3) cofnij bramkę M5 po przybyciu stosu
    WAIT_M5_RETRACT := 57,  // czekaj na potwierdzenie cofnięcia M5

    LOCK_TARGET := 60,      // podnieś stoper docelowy (tylko P2/P3)
    WAIT_LOCK := 70,

    COMPLETE := 80,

    FAULT := 900
);
END_TYPE
