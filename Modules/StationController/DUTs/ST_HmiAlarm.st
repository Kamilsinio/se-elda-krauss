TYPE ST_HmiAlarm :
STRUCT
    (* Siłowniki — fault z FB_Cyl2Pos / FB_StopperPair *)
    xM1_Fault           : BOOL;
    xM2_Fault           : BOOL;
    xM3_Fault           : BOOL;
    xM4_Fault           : BOOL;
    xM5_Fault           : BOOL;
    xM6_Fault           : BOOL;
    xM7_Fault           : BOOL;
    xM8_Fault           : BOOL;

    (* Transportery *)
    xConvTop_Fault      : BOOL;
    xConvElev_Fault     : BOOL;
    xConvBottom_Fault   : BOOL;

    (* Winda *)
    xElev_Fault         : BOOL;
    xElev_CommLost      : BOOL;

    (* Przepływ *)
    xTopFlow_Fault      : BOOL;
    xBottom_Fault       : BOOL;

    (* Sekwencery *)
    xTraySeq_Fault      : BOOL;
    xBoxSeq_Fault       : BOOL;

    (* Robot *)
    xRobot_Fault        : BOOL;
    xRobot_EStop        : BOOL;
    xRobot_CommLost     : BOOL;

    (* Komunikacja *)
    xVfd_CommLost       : BOOL;
    xRobot_MbLost       : BOOL;

    (* System *)
    xLowPressure        : BOOL;
    xSafetyTrip         : BOOL;

	xAckAll : BOOL;
	xResetAll : BOOL;
END_STRUCT
END_TYPE
