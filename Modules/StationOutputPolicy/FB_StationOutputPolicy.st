(* Walidacja raz na skan. Bledne dane nie nadpisuja ostatniej poprawnej polityki.
   Pamiec nie jest RETAIN: po restarcie brak zatwierdzenia blokuje uruchomienie. *)
FUNCTION_BLOCK FB_StationOutputPolicy
VAR_INPUT
 Cfg : ST_StationCfg;
 Plant : ST_RobotPlant;
 Storage : ST_StorageIn;
END_VAR
VAR_OUTPUT
 Ready : BOOL;
 Fault : BOOL;
 StationLossReady : BOOL;
 StationLoss : ARRAY[1..10] OF ST_StationCoil;
 CylinderLoss : ARRAY[1..5] OF ST_StationCoil;
 StorageLoss : ARRAY[1..2] OF ST_StationCoil;
END_VAR
VAR
 i : INT;
 stationKnown : ARRAY[1..10] OF BOOL;
END_VAR
Ready := Cfg.robot_stationCoilPolicyVerified AND Cfg.station_LocalFaultPolicyVerified;
FOR i := 1 TO 10 DO
 IF Cfg.robot_stationCoilPolicyVerified AND NOT (Cfg.robot_stationCoilLossPolicy[i].home AND Cfg.robot_stationCoilLossPolicy[i].work) THEN
  StationLoss[i] := Cfg.robot_stationCoilLossPolicy[i]; stationKnown[i] := TRUE;
 ELSE Ready := FALSE; END_IF;
 IF Cfg.station_LocalFaultPolicy[i].home AND Cfg.station_LocalFaultPolicy[i].work THEN Ready := FALSE; END_IF;
 IF Cfg.station_ManualReleaseVerified AND Cfg.station_ManualRelease[i].home AND Cfg.station_ManualRelease[i].work THEN Ready := FALSE; END_IF;
END_FOR;
FOR i := 1 TO 5 DO
 IF Plant.cylinders[i].lossPolicyVerified AND NOT (Plant.cylinders[i].lossHome AND Plant.cylinders[i].lossWork) THEN
  CylinderLoss[i].home := Plant.cylinders[i].lossHome; CylinderLoss[i].work := Plant.cylinders[i].lossWork;
 ELSE Ready := FALSE; END_IF;
 IF NOT Plant.vacuum[i].lossPolicyVerified THEN Ready := FALSE; END_IF;
END_FOR;
IF Storage.Left.lossPolicyVerified AND NOT (Storage.Left.lossHome AND Storage.Left.lossWork) THEN
 StorageLoss[1].home := Storage.Left.lossHome; StorageLoss[1].work := Storage.Left.lossWork;
ELSE Ready := FALSE; END_IF;
IF Storage.Right.lossPolicyVerified AND NOT (Storage.Right.lossHome AND Storage.Right.lossWork) THEN
 StorageLoss[2].home := Storage.Right.lossHome; StorageLoss[2].work := Storage.Right.lossWork;
ELSE Ready := FALSE; END_IF;
StationLossReady := TRUE;
FOR i := 1 TO 10 DO StationLossReady := StationLossReady AND stationKnown[i]; END_FOR;
Fault := NOT Ready;
