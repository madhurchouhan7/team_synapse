// src/websocket/wsServer.js
// ═══════════════════════════════════════════════════════════════════════════════
// WebSocket server for real-time smart plug telemetry streaming.
//
// Protocol:
//   Client → Server: { type: 'subscribe', userId: '<uid>' }
//                    { type: 'ping' }
//   Server → Client: { type: 'reading', data: ReadingPayload }
//                    { type: 'anomaly', data: AnomalyPayload }
//                    { type: 'state_change', data: { plugId, oldState, newState } }
//                    { type: 'pong' }
//                    { type: 'error', message: '...' }
//
// Authentication: Firebase ID token passed as ?token=<idToken> query param
//                 OR as the first message after connect.
// ═══════════════════════════════════════════════════════════════════════════════

const { WebSocketServer, OPEN } = require('ws');
const url = require('url');

// Map<userId, Set<WebSocket>>
const _clients = new Map();

let _wss = null;

/**
 * Attach the WebSocket server to an existing Node HTTP server.
 * @param {import('http').Server} httpServer
 */
function attachWsServer(httpServer) {
  _wss = new WebSocketServer({ server: httpServer, path: '/ws' });

  _wss.on('connection', (ws, req) => {
    const query   = url.parse(req.url, true).query;
    const userId  = query.userId || null;  // Client passes their userId as query param

    ws._userId = userId;
    ws._isAlive = true;

    // Subscribe client to their user channel
    if (userId) {
      _subscribeClient(userId, ws);
    }

    ws.on('message', (rawMessage) => {
      try {
        const msg = JSON.parse(rawMessage.toString());

        if (msg.type === 'ping') {
          ws.send(JSON.stringify({ type: 'pong', ts: Date.now() }));
          ws._isAlive = true;
          return;
        }

        if (msg.type === 'subscribe' && msg.userId) {
          // Late subscription
          if (ws._userId && ws._userId !== msg.userId) {
            _unsubscribeClient(ws._userId, ws);
          }
          ws._userId = msg.userId;
          _subscribeClient(msg.userId, ws);
          ws.send(JSON.stringify({ type: 'subscribed', userId: msg.userId }));
        }

      } catch (_err) {
        // Ignore malformed messages
      }
    });

    ws.on('close', () => {
      if (ws._userId) _unsubscribeClient(ws._userId, ws);
    });

    ws.on('error', () => {
      if (ws._userId) _unsubscribeClient(ws._userId, ws);
    });

    // Initial handshake
    ws.send(JSON.stringify({
      type:    'connected',
      message: 'WattSense Real-Time Telemetry Stream',
      ts:      Date.now(),
    }));
  });

  // Heartbeat: close dead connections every 30s
  const heartbeat = setInterval(() => {
    if (!_wss) return;
    _wss.clients.forEach((ws) => {
      if (ws._isAlive === false) {
        if (ws._userId) _unsubscribeClient(ws._userId, ws);
        return ws.terminate();
      }
      ws._isAlive = false;
      if (ws.readyState === OPEN) {
        ws.send(JSON.stringify({ type: 'ping', ts: Date.now() }));
      }
    });
  }, 30_000);

  _wss.on('close', () => clearInterval(heartbeat));

  console.log('[WsServer] 🔌 WebSocket server attached at path /ws');
  return _wss;
}

// ── Client registry ───────────────────────────────────────────────────────────

function _subscribeClient(userId, ws) {
  if (!_clients.has(userId)) {
    _clients.set(userId, new Set());
  }
  _clients.get(userId).add(ws);
}

function _unsubscribeClient(userId, ws) {
  const set = _clients.get(userId);
  if (set) {
    set.delete(ws);
    if (set.size === 0) _clients.delete(userId);
  }
}

// ── Broadcast helpers ─────────────────────────────────────────────────────────

/**
 * Send a message to all WebSocket connections for a given userId.
 * @param {string} userId
 * @param {object} payload
 */
function broadcastToUser(userId, payload) {
  const set = _clients.get(userId.toString());
  if (!set || set.size === 0) return;
  const json = JSON.stringify(payload);
  for (const ws of set) {
    if (ws.readyState === OPEN) {
      ws.send(json);
    }
  }
}

/**
 * Broadcast a telemetry reading to the owning user.
 * @param {object} reading - TelemetryReading document
 * @param {string} plugName
 * @param {string} applianceName
 * @param {object} metadata  - extra simulation metadata
 */
function broadcastReading(reading, plugName, applianceName, metadata = {}) {
  broadcastToUser(reading.userId, {
    type: 'reading',
    data: {
      plugId:        reading.plugId,
      plugName,
      applianceName,
      wattage:       reading.wattage,
      voltage:       reading.voltage,
      current:       reading.current,
      powerFactor:   reading.powerFactor,
      isAnomaly:     reading.isAnomaly,
      anomalyScore:  reading.anomalyScore,
      anomalyReason: reading.anomalyReason,
      timestamp:     reading.timestamp,
      ...metadata,
    },
  });
}

/**
 * Broadcast an anomaly alert to the owning user.
 */
function broadcastAnomaly(userId, payload) {
  broadcastToUser(userId, { type: 'anomaly', data: payload });
}

/**
 * Broadcast a device state change event.
 */
function broadcastStateChange(userId, plugId, plugName, oldState, newState) {
  broadcastToUser(userId, {
    type: 'state_change',
    data: { plugId, plugName, oldState, newState, ts: Date.now() },
  });
}

/** Count connected WebSocket clients */
function connectedCount() {
  let n = 0;
  for (const set of _clients.values()) n += set.size;
  return n;
}

module.exports = {
  attachWsServer,
  broadcastReading,
  broadcastAnomaly,
  broadcastStateChange,
  broadcastToUser,
  connectedCount,
};
