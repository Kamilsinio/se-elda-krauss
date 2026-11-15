(* FANUC v2: skaner i Festo wymagaja jawnego powiazania GAP-03/04/06/08/09.
   Brak AT/adresow historycznych; RawIn/RawOut to wylacznie obraz 80 bajtow.
   Plant to znormalizowane wejscia, Sts.* jedyny wlasciciel komend robot/IMM. *)
{attribute 'qualified_only'}
VAR_GLOBAL
    RawIn : ARRAY[0..79] OF BYTE;
    RawOut : ARRAY[0..79] OF BYTE;
    Rx : ST_RobotRxV2;
    Tx : ST_RobotTxV2;
    Cfg : ST_RobotCfg;
    Plant : ST_RobotPlant;
    Sts : ST_RobotStatus;
    Proposal : ST_RobotContext;
    Drain : ST_RobotDrain;
    ScannerHealthy : BOOL;
    ImageFresh : BOOL;
    stationIoBound : BOOL;
    stationCoilPolicyVerified : BOOL; // GAP-08, niezalezne od samego adresowania.
    stationCoilLossPolicy : ARRAY[1..7] OF ST_StationCoil; // M1-M7, home=bwd, work=fwd.
    vfdCommHealthy : BOOL;
    elevatorFast_Hz : REAL; // Zatwierdzone nastawy; bez edycji starym hmiCmd.
    elevatorSlow_Hz : REAL;
    sourceEmptyStable : TIME;
    elevatorTransferStable : TIME; // Stabilne P4 potwierdzajace przekazanie przez TopFlow.
    storageIn : ST_StorageIn;
    storageOut : ST_StorageOut;
    singleUnloadReady : BOOL; // Potwierdzenie przyszlego wykonawcy pojedynczego wydania.
    singleUnloadRequest : BOOL; // Jeden impuls; nigdy nie rozpoczyna Drain.
END_VAR
