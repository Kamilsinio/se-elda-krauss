(* Interfejs panelu Vijeo. Dane robocze sterownika sa obslugiwane w PRG_Main. *)
{attribute 'qualified_only'}
VAR_GLOBAL
    vijeo     : ST_VijeoExchange;
    hmiIo     : ST_VijeoIoStatus;
    hmiV2     : ST_VijeoHmiV2;
    hmiStatus : ST_HmiStationStatus;
END_VAR
