(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotContext :
STRUCT
(* Zachowywac kontekst, nigdy pozwolenia ruchu; wersja 4. *)
    schema : UINT;
    drainRequested : BOOL;
    drainResumeRequired : BOOL;
    stationDrainStep : E_StationDrainState;
    stationOwner : E_StationOwner;
    stationAction : E_StationAction;
    pickupPending : BOOL;
    pickupSeen : BOOL;
    stationParameters : ARRAY[1..4] OF ST_StationParameterSet;
    stationParamRevision : ARRAY[1..4] OF UINT;
    valid : BOOL;
    orderActive : BOOL;
    ending : BOOL;
    program_ : UINT;
    withRobot : BOOL;
    batchCount : UINT;
    nextCycleId : UINT;
    stackId : UINT;
    assigned : BOOL;
    assignedSlot : UINT;
    cycles : ARRAY[1..2] OF ST_RobotCycle;
    tasks : ARRAY[1..10] OF ST_RobotTask;
    goodCount : UDINT;
    sampleCount : UDINT;
    rejectCount : UDINT;
    blisterCount : UDINT;
    pickedCount : UDINT;
    layerCount : UDINT;
    stackCount : UDINT;
    sampleAccepted : BOOL;
    sampleAwaitCycle : BOOL;
    sampleCycleId : UINT;
    areaReserved : ARRAY[1..3] OF BOOL;
    trayStep : E_TraySeqState;
    boxStep : E_BoxSeqState;
    trayAction : BOOL;
    stackFull : BOOL;
    hmiGeneration : UDINT;
    occupancyKnown : BOOL;
    occupied : ARRAY[1..7] OF BOOL;
    elevatorLoadPresent : BOOL;
    topTransferState : E_TopFlowState;
    bottomTransferState : E_Bottom567State;
    bottomTransferOwner : UINT;
    bottomDonePendingTray : BOOL;
    bottomDonePendingBox : BOOL;
    station : ST_StationContext;
END_STRUCT
END_TYPE
