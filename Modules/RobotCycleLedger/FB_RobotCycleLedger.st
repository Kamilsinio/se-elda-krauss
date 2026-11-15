(* Jedyny wlasciciel rozliczenia partii; skutki materialowe sa trwale do odbioru. *)
FUNCTION_BLOCK FB_RobotCycleLedger
VAR_INPUT
    Session : BOOL;
    Reset : BOOL;
    StartConfirmed : BOOL;
    StartValid : BOOL;
    CyclesKnown : BOOL;
    Quantity : UINT;
    RejectBatch : BOOL;
    StackId : UINT;
    Program : UINT;
    Pending : ARRAY[1..10] OF BOOL;
    Events : ARRAY[1..10] OF ST_RobotEvent;
    TaskDone : ARRAY[1..10] OF BOOL;
END_VAR
VAR_IN_OUT
    Context : ST_RobotContext;
END_VAR
VAR_OUTPUT
    Commit : ARRAY[1..10] OF BOOL;
    Fault : BOOL;
    Unsettled : UINT;
    FreeSlot : BOOL;
    PickupPending : BOOL;
    CycleId : UINT;
    BatchCount : UINT;
    BatchReject : BOOL;
END_VAR
VAR
    startEdge : R_TRIG;
    i : INT;
    j : INT;
    slot : INT;
    pickSlot : INT;
    newId : UINT;
    allValid : BOOL;
    total : UDINT;
    delta : ARRAY[1..2] OF UDINT;
    accounted : ARRAY[1..2] OF UDINT;
END_VAR
startEdge(CLK := StartConfirmed);
IF Reset THEN Fault := FALSE; END_IF;
FOR i := 1 TO 10 DO
    Commit[i] := FALSE;
    IF TaskDone[i] THEN Context.tasks[i].pending := FALSE; END_IF;
END_FOR;
IF NOT Context.valid OR Context.schema <> 4 THEN Fault := TRUE; END_IF;
IF Context.assigned AND ((Context.assignedSlot < 1) OR (Context.assignedSlot > 2)) THEN Fault := TRUE; END_IF;
FOR i := 1 TO 2 DO
    delta[i] := 0;
    accounted[i] := Context.cycles[i].good + Context.cycles[i].samples + Context.cycles[i].rejects;
    IF Context.cycles[i].occupied AND
       ((Context.cycles[i].quantity = 0) OR (accounted[i] > TO_UDINT(Context.cycles[i].quantity))) THEN Fault := TRUE; END_IF;
END_FOR;
IF Context.cycles[1].occupied AND Context.cycles[2].occupied AND
   Context.cycles[1].id = Context.cycles[2].id THEN Fault := TRUE; END_IF;
(* Fizyczny start zawsze rejestrujemy lub zatrzaskujemy niepewnosc, takze po utracie sesji. *)
IF startEdge.Q THEN
    slot := 0;
    FOR i := 1 TO 2 DO
        IF NOT Context.cycles[i].occupied AND slot = 0 THEN slot := i; END_IF;
    END_FOR;
    IF NOT StartValid OR NOT CyclesKnown OR NOT Session OR Quantity = 0 OR slot = 0 THEN
        Fault := TRUE;
    ELSE
        newId := Context.nextCycleId;
        FOR i := 1 TO 2 DO
            IF Context.cycles[i].occupied AND Context.cycles[i].id = newId THEN
                newId := TO_UINT((TO_UDINT(newId) + 1) MOD 65536);
            END_IF;
        END_FOR;
        Context.cycles[slot].occupied := TRUE;
        Context.cycles[slot].picked := FALSE;
        Context.cycles[slot].id := newId;
        Context.cycles[slot].stackId := StackId;
        Context.cycles[slot].quantity := Quantity;
        Context.cycles[slot].reject := RejectBatch;
        Context.cycles[slot].good := 0;
        Context.cycles[slot].samples := 0;
        Context.cycles[slot].rejects := 0;
        accounted[slot] := 0;
        Context.nextCycleId := TO_UINT((TO_UDINT(newId) + 1) MOD 65536);
    END_IF;
END_IF;
(* Walidacja wszystkich rownoczesnych dyspozycji przed jakimkolwiek zapisem. *)
allValid := Session AND NOT Fault;
FOR i := 1 TO 10 DO
    IF Pending[i] THEN
        IF Events[i].stackId <> StackId THEN allValid := FALSE; END_IF;
        IF (i <= 3) AND Program <> 2 THEN allValid := FALSE; END_IF;
        IF ((i = 4) OR (i = 7)) AND Program <> 1 THEN allValid := FALSE; END_IF;
        IF (i = 5) OR (i = 6) OR (i = 9) OR (i = 10) THEN
            slot := 0;
            FOR j := 1 TO 2 DO
                IF Context.cycles[j].occupied AND Context.cycles[j].id = Events[i].cycleId THEN slot := j; END_IF;
            END_FOR;
            IF slot = 0 THEN
                allValid := FALSE;
            ELSE
                IF i = 9 THEN
                    IF Context.cycles[slot].picked OR NOT Context.assigned OR
                       Context.assignedSlot <> TO_UINT(slot) THEN allValid := FALSE; END_IF;
                ELSE
                    IF NOT Context.cycles[slot].picked OR Events[i].count = 0 THEN allValid := FALSE; END_IF;
                    delta[slot] := delta[slot] + TO_UDINT(Events[i].count);
                    IF Context.cycles[slot].reject AND i <> 10 THEN allValid := FALSE; END_IF;
                    IF NOT Context.cycles[slot].reject AND i = 10 THEN allValid := FALSE; END_IF;
                    IF i = 6 AND (NOT Context.sampleAccepted OR Context.sampleAwaitCycle OR
                       Context.sampleCycleId <> Events[i].cycleId) THEN allValid := FALSE; END_IF;
                    IF Context.sampleAccepted AND NOT Context.sampleAwaitCycle AND
                       Context.sampleCycleId = Events[i].cycleId AND i <> 6 THEN allValid := FALSE; END_IF;
                END_IF;
            END_IF;
        END_IF;
        IF i = 3 AND TO_UDINT(Events[i].index) <> Context.blisterCount THEN allValid := FALSE; END_IF;
        IF i = 7 AND TO_UDINT(Events[i].index) <> Context.layerCount THEN allValid := FALSE; END_IF;
        IF i = 8 THEN
            FOR j := 1 TO 10 DO
                IF j <> 8 AND (Pending[j] OR Context.tasks[j].pending) THEN allValid := FALSE; END_IF;
            END_FOR;
        END_IF;
        IF i = 5 AND Context.goodCount > 16#FFFFFFFF - TO_UDINT(Events[i].count) THEN allValid := FALSE; END_IF;
        IF i = 6 AND Context.sampleCount > 16#FFFFFFFF - TO_UDINT(Events[i].count) THEN allValid := FALSE; END_IF;
        IF i = 10 AND Context.rejectCount > 16#FFFFFFFF - TO_UDINT(Events[i].count) THEN allValid := FALSE; END_IF;
        IF i = 1 AND Context.pickedCount = 16#FFFFFFFF THEN allValid := FALSE; END_IF;
        IF i = 3 AND Context.blisterCount = 16#FFFFFFFF THEN allValid := FALSE; END_IF;
        IF i = 7 AND Context.layerCount = 16#FFFFFFFF THEN allValid := FALSE; END_IF;
        IF i = 8 AND Context.stackCount = 16#FFFFFFFF THEN allValid := FALSE; END_IF;
    END_IF;
END_FOR;
FOR i := 1 TO 2 DO
    total := accounted[i] + delta[i];
    IF Context.cycles[i].occupied AND total > TO_UDINT(Context.cycles[i].quantity) THEN allValid := FALSE; END_IF;
END_FOR;
IF Session THEN
    FOR i := 1 TO 10 DO
        IF Pending[i] AND NOT allValid THEN Fault := TRUE; END_IF;
    END_FOR;
END_IF;
IF allValid THEN
    FOR i := 1 TO 10 DO
        IF Pending[i] AND NOT Context.tasks[i].pending THEN
            Commit[i] := TRUE;
            IF (i = 1) OR (i = 2) OR (i = 3) OR (i = 4) OR (i = 7) OR (i = 8) THEN
                Context.tasks[i].pending := TRUE;
                Context.tasks[i].data := Events[i];
            END_IF;
            slot := 0;
            FOR j := 1 TO 2 DO
                IF Context.cycles[j].occupied AND Context.cycles[j].id = Events[i].cycleId THEN slot := j; END_IF;
            END_FOR;
            IF i = 1 THEN Context.pickedCount := Context.pickedCount + 1; END_IF;
            IF i = 3 THEN Context.blisterCount := Context.blisterCount + 1; END_IF;
            IF i = 7 THEN Context.layerCount := Context.layerCount + 1; END_IF;
            IF i = 8 THEN Context.stackCount := Context.stackCount + 1; Context.stackFull := TRUE; END_IF;
            IF slot > 0 THEN
                IF i = 9 THEN
                    Context.cycles[slot].picked := TRUE;
                    IF Context.sampleAccepted AND Context.sampleAwaitCycle THEN
                        Context.sampleAwaitCycle := FALSE;
                        Context.sampleCycleId := Events[i].cycleId;
                    END_IF;
                END_IF;
                IF i = 5 THEN
                    Context.cycles[slot].good := Context.cycles[slot].good + TO_UDINT(Events[i].count);
                    Context.goodCount := Context.goodCount + TO_UDINT(Events[i].count);
                END_IF;
                IF i = 6 THEN
                    Context.cycles[slot].samples := Context.cycles[slot].samples + TO_UDINT(Events[i].count);
                    Context.sampleCount := Context.sampleCount + TO_UDINT(Events[i].count);
                END_IF;
                IF i = 10 THEN
                    Context.cycles[slot].rejects := Context.cycles[slot].rejects + TO_UDINT(Events[i].count);
                    Context.rejectCount := Context.rejectCount + TO_UDINT(Events[i].count);
                END_IF;
            END_IF;
        END_IF;
    END_FOR;
END_IF;
(* Przydzial pozostaje zamrozony przez caly handshake pickup. *)
IF Context.assigned AND Context.assignedSlot >= 1 AND Context.assignedSlot <= 2 AND NOT Pending[9] AND NOT Events[9].req THEN
    IF Context.cycles[Context.assignedSlot].picked THEN Context.assigned := FALSE; END_IF;
END_IF;
FOR i := 1 TO 2 DO
    total := Context.cycles[i].good + Context.cycles[i].samples + Context.cycles[i].rejects;
    IF Context.cycles[i].occupied AND Context.cycles[i].picked AND
       total = TO_UDINT(Context.cycles[i].quantity) AND NOT Pending[5] AND NOT Pending[6] AND NOT Pending[10] AND
       NOT Events[5].req AND NOT Events[6].req AND NOT Events[10].req AND
       (NOT Context.assigned OR Context.assignedSlot <> TO_UINT(i)) THEN
        IF Context.sampleAccepted AND NOT Context.sampleAwaitCycle AND
           Context.sampleCycleId = Context.cycles[i].id THEN Context.sampleAccepted := FALSE; END_IF;
        Context.cycles[i].occupied := FALSE;
    END_IF;
END_FOR;
IF NOT Context.assigned AND NOT Fault THEN
    pickSlot := 0;
    FOR i := 1 TO 2 DO
        IF Context.cycles[i].occupied AND NOT Context.cycles[i].picked AND pickSlot = 0 THEN pickSlot := i; END_IF;
    END_FOR;
    IF pickSlot > 0 THEN Context.assigned := TRUE; Context.assignedSlot := TO_UINT(pickSlot); END_IF;
END_IF;
Unsettled := 0;
FreeSlot := FALSE;
FOR i := 1 TO 2 DO
    IF Context.cycles[i].occupied THEN Unsettled := Unsettled + 1; ELSE FreeSlot := TRUE; END_IF;
END_FOR;
PickupPending := FALSE;
CycleId := 0;
BatchCount := 0;
BatchReject := FALSE;
IF Context.assigned AND Context.assignedSlot >= 1 AND Context.assignedSlot <= 2 THEN
    slot := TO_INT(Context.assignedSlot);
    CycleId := Context.cycles[slot].id;
    BatchCount := Context.cycles[slot].quantity;
    BatchReject := Context.cycles[slot].reject;
    PickupPending := Context.cycles[slot].occupied AND NOT Context.cycles[slot].picked AND NOT Fault;
END_IF;
