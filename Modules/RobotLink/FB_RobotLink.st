(* Lacze zyje niezaleznie od WAIT main. READY nie oznacza Start. *)
FUNCTION_BLOCK FB_RobotLink
VAR_INPUT
    Cfg : ST_RobotLinkCfg;
    ScannerHealthy : BOOL;
    ImageFresh : BOOL;
    Rx : ST_RobotRxV2;
    Recover : BOOL;
    Neutral : BOOL;
    Invalidate : BOOL;
END_VAR
VAR_OUTPUT
    State : E_RobotLinkState;
    Session : BOOL;
    LocalReady : BOOL;
    SyncRequest : BOOL;
    SyncAck : BOOL;
    Heartbeat : UINT;
    HeaderValid : BOOL;
    Diag : ST_RobotDiag;
END_VAR
VAR
    peerSeen : BOOL;
    lastPeer : UINT;
    changed : BOOL;
    healthy : BOOL;
    peerSyncSeen : BOOL;
    wasSession : BOOL;
    heartbeatPulse : BOOL;
    heartbeatTimer : TON;
    peerTimer : TON;
    syncTimer : TON;
END_VAR
changed := Rx.link_heartbeat <> lastPeer;
lastPeer := Rx.link_heartbeat;
IF changed AND ScannerHealthy AND ImageFresh THEN peerSeen := TRUE; END_IF;
peerTimer(IN := NOT changed, PT := Cfg.peerTimeout);
heartbeatTimer(IN := NOT heartbeatPulse, PT := Cfg.heartbeatPeriod);
heartbeatPulse := heartbeatTimer.Q;
IF heartbeatPulse THEN Heartbeat := TO_UINT((TO_UDINT(Heartbeat) + 1) MOD 65536); END_IF;
healthy := Cfg.configured AND ScannerHealthy AND ImageFresh AND peerSeen AND
    (Rx.link_version = 2) AND (Cfg.heartbeatPeriod > T#0ms) AND
    (Cfg.peerTimeout > Cfg.heartbeatPeriod) AND (Cfg.syncTimeout > Cfg.peerTimeout) AND NOT peerTimer.Q;
HeaderValid := healthy;
syncTimer(IN := (State = E_RobotLinkState.SYNC_REQUEST) OR (State = E_RobotLinkState.SYNC_RELEASE),
    PT := Cfg.syncTimeout);
Diag.fault := FALSE;
Diag.code := 0;
Diag.text := '';
IF NOT healthy OR Invalidate OR syncTimer.Q OR
   ((State = E_RobotLinkState.READY) AND (Rx.link_syncRequest OR (wasSession AND NOT Rx.link_ready))) THEN
    State := E_RobotLinkState.DISARMED;
    peerSyncSeen := FALSE;
    wasSession := FALSE;
END_IF;
IF NOT healthy THEN
    Diag.code := 10;
    Diag.text := 'Brak aktualnego naglowka lub konfiguracji lacza.';
END_IF;
IF syncTimer.Q THEN
    Diag.fault := TRUE;
    Diag.code := 110;
    Diag.text := 'Timeout obustronnej synchronizacji.';
END_IF;
SyncAck := healthy AND Rx.link_syncRequest;
IF SyncAck THEN peerSyncSeen := TRUE; END_IF;
IF healthy AND NOT Invalidate AND NOT syncTimer.Q THEN
    CASE State OF
        E_RobotLinkState.DISARMED:
            IF NOT Rx.link_syncAck THEN State := E_RobotLinkState.SYNC_REQUEST; END_IF;
        E_RobotLinkState.SYNC_REQUEST:
            IF Rx.link_syncAck THEN State := E_RobotLinkState.SYNC_RELEASE; END_IF;
        E_RobotLinkState.SYNC_RELEASE:
            IF peerSyncSeen AND NOT Rx.link_syncRequest AND NOT Rx.link_syncAck THEN
                State := E_RobotLinkState.RECOVERY;
            END_IF;
        E_RobotLinkState.RECOVERY:
            IF Rx.link_syncRequest THEN
                State := E_RobotLinkState.DISARMED;
                peerSyncSeen := FALSE;
            ELSIF Recover AND Neutral THEN State := E_RobotLinkState.READY;
            END_IF;
        E_RobotLinkState.READY:
            IF Rx.link_ready THEN wasSession := TRUE; END_IF;
    END_CASE;
END_IF;
LocalReady := healthy AND (State = E_RobotLinkState.READY);
SyncRequest := healthy AND (State = E_RobotLinkState.SYNC_REQUEST);
Session := LocalReady AND Rx.link_ready AND NOT Rx.link_syncRequest AND NOT Rx.link_syncAck;
