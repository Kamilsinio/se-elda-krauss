(* FANUC v2: skaner i Festo wymagaja jawnego powiazania GAP-03/04/06/08/09.
   Brak AT/adresow historycznych; RawIn/RawOut to wylacznie obraz 80 bajtow.
   Plant to znormalizowane wejscia, Sts.* jedyny wlasciciel komend robot/IMM. *)
{attribute 'qualified_only'}
VAR_GLOBAL
    // Obraz skanera EtherNet/IP: mapowanie calych tablic WORD w I/O Mapping.
    EipInWords : ARRAY[0..39] OF WORD; // Robot -> PLC, 80 bajtow.
    EipOutWords : ARRAY[0..39] OF WORD; // PLC -> robot, 80 bajtow.
    // Konwersja do/z obrazu BYTE w PRG_IO_Read i PRG_IO_Write.

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
    stationCoilLossPolicy : ARRAY[1..10] OF ST_StationCoil; // 1..5 M1-M5, 6 V201, 7 V203, 8 V202, 9/10 dolne stopery; mapa GAP-08.
    vfdCommHealthy : BOOL;
    elevatorFast_Hz : REAL; // Zatwierdzone nastawy; bez edycji starym hmiCmd.
    elevatorSlow_Hz : REAL;
    sourceEmptyStable : TIME;
    elevatorTransferStable : TIME; // Stabilne P4 potwierdzajace przekazanie przez TopFlow.
    storageIn : ST_StorageIn;
    storageOut : ST_StorageOut;
    singleUnloadReady : BOOL; // Gotowość rzeczywistego wykonawcy ST.3.
    singleUnloadRequest : BOOL; // Jeden impuls; nigdy nie rozpoczyna Drain.
END_VAR
