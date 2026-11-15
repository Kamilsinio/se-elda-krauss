{attribute 'qualified_only'}
VAR_GLOBAL
 ElevatorCfg : ST_ElevatorPar;
 ElevatorCfgVerified : BOOL;
 DriveFrequencyValid : BOOL;
    DiagnosticValue : ST_StationIoValues;
    DiagnosticValid : ST_StationIoValues;
 IoCfg : ST_StationIoCfg;
 Inputs : ST_StationIoIn;
 Io : ST_StationIoStatus;
 AlarmCfg : ST_StationAlarmCfg;
 AlarmInputs : ST_StationAlarmIn;
 Alarms : ST_StationAlarmStatus;
 ParameterCfg : ST_StationParameterCfg;
 Material : ST_StationMaterialStatus;
 Transport : ST_StationTransportStatus;
 DrainStatus : ST_StationDrainStatus;
 ManualInterlocks : ST_StationManualIn;
 LocalFaultPolicyVerified : BOOL; // GAP-08: lokalna usterka ST.1-ST.3, bez globalnego Stop.
 LocalFaultPolicy : ARRAY[1..10] OF ST_StationCoil;
 ManualReleaseVerified : BOOL;
 ManualRelease : ARRAY[1..10] OF ST_StationCoil;
 Coils : ARRAY[1..10] OF ST_StationCoil;
 LocalRestartRequired : ARRAY[1..10] OF BOOL; // R: Reset nie nadaje zgody na ponowny ruch.
 V201Out : ST_StationCoil;
 V202Out : ST_StationCoil;
 LowerStopOut : ARRAY[1..2] OF ST_StationCoil;
 ReconcileRequired : BOOL;
END_VAR
