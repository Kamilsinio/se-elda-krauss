TYPE ST_Bottom567Out :
STRUCT
    ConvRun : BOOL;
    ElevConv_RunBwd : BOOL;

    AlarmQueueFull : BOOL;   // do logiki lamp/buzzer
    StepDonePulse  : BOOL;   // 1 scan
    DischargeDonePulse : BOOL; // 1 scan, rozladunek P4->P5 zakonczony
    HoldStop5 : BOOL;
    HoldStop6 : BOOL;
    SingleUnloadDonePulse : BOOL;
    AcceptedPulse : BOOL;
END_STRUCT
END_TYPE
