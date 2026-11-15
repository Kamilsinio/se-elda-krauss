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
 ManualReleaseVerified : BOOL;
 ManualRelease : ARRAY[1..10] OF ST_StationCoil;
 Coils : ARRAY[1..10] OF ST_StationCoil;
 V201Out : ST_StationCoil;
 V202Out : ST_StationCoil;
 LowerStopOut : ARRAY[1..2] OF ST_StationCoil;
 ReconcileRequired : BOOL;
END_VAR
