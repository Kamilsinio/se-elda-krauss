(* ============================================================
   GVL_HMI — Zmienne wymiany danych z wizualizacją HMI
   Schneider Vijeo Designer / Web Visualization.
   Wszystkie zmienne z prefiksem hmi* są bindowane w panelu.
   ============================================================ *)



(* --- Konfiguracja HMI: stała ilość alarmów --- *)
{attribute 'qualified_only'}
VAR_GLOBAL CONSTANT
    MAX_ALARMS   : UINT := 32;
END_VAR

(* --- Status stacji do wyświetlania --- *)


(* --- Komendy z HMI --- *)



{attribute 'qualified_only'}
VAR_GLOBAL
    hmiIo         : ST_StationHmiIo;
    hmiV2         : ST_RobotHmiV2; // Nowy kontrakt; stare hmiCmd nie steruja robotem.
    hmiStatus     : ST_HmiStationStatus;
    hmiCmd        : ST_HmiCommands;
    hmiAlarms     : ST_HmiAlarm;
    hmiAlarmCount : UINT;  // ilość aktywnych alarmów
END_VAR
