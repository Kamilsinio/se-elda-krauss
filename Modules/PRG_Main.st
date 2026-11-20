PROGRAM PRG_Main
VAR
 station : FB_StationController;
 hmiRuntime : ST_RobotHmiV2;
 vijeoRead : FB_VijeoRead;
 vijeoPublish : FB_VijeoPublish;
 driveAdapter : FB_ElevatorDriveAdapter;
 cfg : ST_StationCfg;
 inp : ST_StationInputs;
END_VAR
PRG_IO_Read();
cfg.robot_Cfg := GVL_Robot.Cfg;
cfg.robot_stationIoBound := GVL_Robot.stationIoBound;
cfg.robot_stationCoilPolicyVerified := GVL_Robot.stationCoilPolicyVerified;
cfg.robot_stationCoilLossPolicy := GVL_Robot.stationCoilLossPolicy;
cfg.station_IoCfg := GVL_Station.IoCfg;
cfg.station_AlarmCfg := GVL_Station.AlarmCfg;
cfg.station_ParameterCfg := GVL_Station.ParameterCfg;
cfg.station_ElevatorCfg := GVL_Station.ElevatorCfg;
cfg.station_ElevatorCfgVerified := GVL_Station.ElevatorCfgVerified;
cfg.station_LocalFaultPolicyVerified := GVL_Station.LocalFaultPolicyVerified;
cfg.station_LocalFaultPolicy := GVL_Station.LocalFaultPolicy;
cfg.station_ManualReleaseVerified := GVL_Station.ManualReleaseVerified;
cfg.station_ManualRelease := GVL_Station.ManualRelease;
inp.robot_ScannerHealthy := GVL_Robot.ScannerHealthy;
inp.robot_ImageFresh := GVL_Robot.ImageFresh;
inp.robot_Plant := GVL_Robot.Plant;
inp.robot_Rx := GVL_Robot.Rx;
inp.robot_storageIn := GVL_Robot.storageIn;
inp.robot_vfdCommHealthy := GVL_Robot.vfdCommHealthy;
inp.station_Inputs := GVL_Station.Inputs;
inp.station_AlarmInputs := GVL_Station.AlarmInputs;
inp.station_DiagnosticValue := GVL_Station.DiagnosticValue;
inp.station_DiagnosticValid := GVL_Station.DiagnosticValid;
inp.station_ManualInterlocks := GVL_Station.ManualInterlocks;
inp.io_di := GVL_IO.di;
inp.drive := driveAdapter.Feedback;
vijeoRead(Hmi := hmiRuntime);
station(Cfg := cfg, Inp := inp, Context := GVL_RobotRetain.Context,
 Proposal := GVL_Robot.Proposal, Hmi := hmiRuntime);
GVL_Robot.Sts := station.Outp.robot_Sts;
GVL_Robot.Tx := station.Outp.robot_Tx;
GVL_Robot.storageOut := station.Outp.robot_storageOut;
GVL_Robot.singleUnloadReady := station.Outp.robot_singleUnloadReady;
GVL_Robot.singleUnloadRequest := station.Outp.robot_singleUnloadRequest;
GVL_Station.Io := station.Outp.station_Io;
GVL_Station.Alarms := station.Outp.station_Alarms;
GVL_Station.Coils := station.Outp.station_Coils;
GVL_Station.LocalRestartRequired := station.Outp.station_LocalRestartRequired;
GVL_Station.Transport := station.Outp.station_Transport;
GVL_Station.DrainStatus := station.Outp.station_DrainStatus;
GVL_Station.Material := station.Outp.station_Material;
GVL_Station.V201Out := station.Outp.station_V201Out;
GVL_Station.V202Out := station.Outp.station_V202Out;
GVL_Station.LowerStopOut := station.Outp.station_LowerStopOut;
GVL_IO.dout := station.Outp.io_dout;
GVL_HMI.hmiStatus := station.Outp.hmi_hmiStatus;
GVL_Robot.Drain := station.Outp.drain;
GVL_Station.ReconcileRequired := station.Outp.reconcileRequired;
driveAdapter(Cmd := station.Outp.drive, MappingVerified := GVL_Station.ElevatorCfgVerified,
 CommHealthy := GVL_Robot.vfdCommHealthy, FrequencyValid := GVL_Station.DriveFrequencyValid,
 ActualHz := INT_TO_REAL(WORD_TO_INT(GVL_IO.di.ATV320_currentFreq)) / 10.0);
vijeoPublish(
    Hmi := hmiRuntime,
    Io := station.Outp.hmi_hmiIo,
    ReloadedStation := station.Outp.hmi_reloadedStation);
PRG_IO_Write();
