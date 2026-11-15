(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotGripperCfg :
STRUCT
stable : TIME;
    motionTimeout : TIME;
    vacuumTimeout : TIME;
    blowTime : TIME;
    releaseTimeout : TIME;
END_STRUCT
END_TYPE
