// src/services/TuyaService.js
// ═══════════════════════════════════════════════════════════════════════════════
// Tuya IoT Platform integration service.
//
// Handles:
//   • HMAC-SHA256 request signing (Tuya's exact algorithm)  
//   • Access token lifecycle (Redis-cached, auto-refreshed before expiry)
//   • Device status polling → normalised { wattage, voltage, current, powerFactor }
//   • Device info / validation (used at registration time)
//   • Graceful degradation: logs + throws structured errors so the poller can
//     mark the plug offline instead of crashing the entire job
//
// Required env vars:
//   TUYA_CLIENT_ID      – From the Tuya IoT Platform project (Access Key)
//   TUYA_CLIENT_SECRET  – Secret Key
//   TUYA_BASE_URL       – Regional endpoint (defaults to EU which covers India)
//                         EU:  https://openapi.tuyaeu.com
//                         US:  https://openapi.tuyaus.com
//                         CN:  https://openapi.tuyacn.com
//                         IN:  https://openapi.tuyain.com
//
// Tuya SDK docs: https://developer.tuya.com/en/docs/cloud
// ═══════════════════════════════════════════════════════════════════════════════

const crypto = require('crypto');
const axios  = require('axios');
const { v4: uuidv4 } = require('uuid');

// ── Config ────────────────────────────────────────────────────────────────────
const BASE_URL       = process.env.TUYA_BASE_URL || 'https://openapi.tuyaeu.com';
const CLIENT_ID      = process.env.TUYA_CLIENT_ID;
const CLIENT_SECRET  = process.env.TUYA_CLIENT_SECRET;

// Token cache (single instance — rotate via Redis if multiple workers)
let _tokenCache = null; // { access_token, refresh_token, expires_at }
let _redis      = null;

const TOKEN_CACHE_KEY = 'tuya:access_token';

// ── Helpers ───────────────────────────────────────────────────────────────────

/** SHA-256 hex hash of a string (used for body content-hash) */
function _sha256(str) {
  return crypto.createHash('sha256').update(str).digest('hex');
}

/** HMAC-SHA256 uppercase hex */
function _hmacSha256(secret, message) {
  return crypto
    .createHmac('sha256', secret)
    .update(message)
    .digest('hex')
    .toUpperCase();
}

/** Current 13-digit millisecond timestamp */
function _ts() { return Date.now().toString(); }

/**
 * Build Tuya's `stringToSign` for a request.
 * Format: HTTPMethod + "\n" + SHA256(body) + "\n" + signedHeaders + "\n" + urlWithQuery
 */
function _buildStringToSign(method, urlPath, body = '') {
  const bodyHash   = _sha256(body || '');
  const headers    = ''; // We don't sign custom request headers
  return [method.toUpperCase(), bodyHash, headers, urlPath].join('\n');
}

/**
 * Generate sign + timestamp + nonce for a request.
 * Tuya signing:
 *   withToken:    sign = HMAC(secret, clientId + accessToken + t + nonce + stringToSign)
 *   tokenRequest: sign = HMAC(secret, clientId + t + nonce + stringToSign)
 */
function _sign(method, urlPath, body = '', accessToken = '') {
  const t            = _ts();
  const nonce        = uuidv4();
  const stringToSign = _buildStringToSign(method, urlPath, body);
  const preSign      = accessToken
    ? `${CLIENT_ID}${accessToken}${t}${nonce}${stringToSign}`
    : `${CLIENT_ID}${t}${nonce}${stringToSign}`;

  return { sign: _hmacSha256(CLIENT_SECRET, preSign), t, nonce };
}

// ── Redis helpers ──────────────────────────────────────────────────────────────

async function _getRedis() {
  if (_redis) return _redis;
  try {
    const Redis = require('ioredis');
    _redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379', {
      lazyConnect:       true,
      enableOfflineQueue: false,
      maxRetriesPerRequest: 1,
    });
    await _redis.ping();
    return _redis;
  } catch {
    _redis = null;
    return null;
  }
}

// ── Token management ──────────────────────────────────────────────────────────

/**
 * Obtain an access token from Tuya (grant_type=1 = client credentials).
 * Caches in Redis (if available) and in-memory.
 */
async function _fetchFreshToken() {
  const urlPath = '/v1.0/token?grant_type=1';
  const { sign, t, nonce } = _sign('GET', urlPath, '', '');

  const response = await axios.get(`${BASE_URL}${urlPath}`, {
    headers: {
      client_id:   CLIENT_ID,
      sign,
      sign_method: 'HMAC-SHA256',
      t,
      nonce,
    },
    timeout: 10_000,
  });

  if (!response.data.success) {
    throw new Error(
      `Tuya token request failed: ${response.data.code} – ${response.data.msg}`,
    );
  }

  const { access_token, refresh_token, expire_time } = response.data.result;
  const expiresAt = Date.now() + expire_time * 1000;

  const cached = { access_token, refresh_token, expires_at: expiresAt };

  // Store in Redis with TTL
  const redis = await _getRedis();
  if (redis) {
    await redis.set(
      TOKEN_CACHE_KEY,
      JSON.stringify(cached),
      'EX', expire_time - 60, // expire 1 min early
    );
  }

  _tokenCache = cached;
  console.log('[TuyaService] ✅ New access token obtained (expires in', expire_time, 's)');
  return access_token;
}

/**
 * Return a valid access token, refreshing if needed.
 */
async function _getAccessToken() {
  const now = Date.now();

  // 1. Check in-memory cache
  if (_tokenCache && _tokenCache.expires_at > now + 60_000) {
    return _tokenCache.access_token;
  }

  // 2. Check Redis cache
  const redis = await _getRedis();
  if (redis) {
    try {
      const raw = await redis.get(TOKEN_CACHE_KEY);
      if (raw) {
        const cached = JSON.parse(raw);
        if (cached.expires_at > now + 60_000) {
          _tokenCache = cached;
          return cached.access_token;
        }
      }
    } catch {
      // Redis read failed — proceed to fetch fresh
    }
  }

  // 3. Fetch fresh token
  return _fetchFreshToken();
}

// ── Core HTTP client ───────────────────────────────────────────────────────────

/**
 * Make an authenticated Tuya API request.
 * @param {'GET'|'POST'|'PUT'|'DELETE'} method
 * @param {string} urlPath  – e.g. '/v1.0/iot-03/devices/xxx/status'
 * @param {object|null} body
 * @returns {any}           – response.data.result
 */
async function _request(method, urlPath, body = null) {
  if (!CLIENT_ID || !CLIENT_SECRET) {
    throw new Error(
      'Tuya credentials not configured. Set TUYA_CLIENT_ID and TUYA_CLIENT_SECRET in .env',
    );
  }

  const accessToken  = await _getAccessToken();
  const bodyStr      = body ? JSON.stringify(body) : '';
  const { sign, t, nonce } = _sign(method, urlPath, bodyStr, accessToken);

  const response = await axios({
    method,
    url:     `${BASE_URL}${urlPath}`,
    headers: {
      client_id:    CLIENT_ID,
      access_token: accessToken,
      sign,
      sign_method:  'HMAC-SHA256',
      t,
      nonce,
      'Content-Type': 'application/json',
    },
    data:    body || undefined,
    timeout: 10_000,
  });

  const { success, code, msg, result } = response.data;
  if (!success) {
    throw new Error(`Tuya API error [${code}]: ${msg}`);
  }
  return result;
}

// ── Public API ─────────────────────────────────────────────────────────────────

/**
 * Get raw device status (array of DP objects).
 * @param {string} deviceId – Tuya device ID from the app / platform
 * @returns {Array<{ code: string, value: any }>}
 *
 * Standard energy monitoring DP codes:
 *   cur_power   – active power, unit: 0.1 W  (divide by 10 → Watts)
 *   cur_voltage – voltage,      unit: 0.1 V  (divide by 10 → Volts)
 *   cur_current – current,      unit: 1 mA   (divide by 1000 → Amperes)
 *   add_ele     – cumulative energy, unit: kWh (already direct)
 *   switch_1    – bool, plug on/off
 *   relay_status – for some devices instead of switch_1
 */
async function getDeviceStatus(deviceId) {
  return _request('GET', `/v1.0/iot-03/devices/${deviceId}/status`);
}

/**
 * Get device basic info (name, category, online status, etc.)
 * Used at plug registration to verify the device exists and belongs to the account.
 */
async function getDeviceInfo(deviceId) {
  return _request('GET', `/v1.0/iot-03/devices/${deviceId}`);
}

/**
 * Read real-time power metrics from a Tuya energy-monitoring smart plug.
 * Normalises the raw DPS array into the standard WattSense format.
 *
 * @param {string} deviceId
 * @returns {{
 *   wattage:     number,   // Watts
 *   voltage:     number,   // Volts
 *   current:     number,   // Amperes
 *   powerFactor: number,   // 0–1
 *   isOnline:    boolean,
 *   isOn:        boolean,
 *   rawDps:      object,   // raw code→value map for debugging
 * }}
 */
async function readPlugMetrics(deviceId) {
  const statuses = await getDeviceStatus(deviceId);

  // Convert DPS array to a flat map: { code: value }
  const dp = {};
  for (const { code, value } of statuses) {
    dp[code] = value;
  }

  // ── Power ─────────────────────────────────────────────────────────────────
  // Tuya reports in 0.1 W units; some devices use integer watts directly.
  // Check the most common code names:
  const rawPower =
    dp['cur_power']  ??   // standard
    dp['power']      ??   // some older models
    dp['watt']       ??
    0;
  // Heuristic: if the raw value is > 10×typical-wattage it's in 0.1W units
  const wattage = rawPower > 0 && rawPower < 50000
    ? rawPower / 10    // 0.1W → W
    : rawPower;        // already in W

  // ── Voltage ───────────────────────────────────────────────────────────────
  const rawVoltage =
    dp['cur_voltage'] ??
    dp['voltage']     ??
    2300; // default 230.0 V
  const voltage = rawVoltage / 10; // 0.1V → V

  // ── Current ───────────────────────────────────────────────────────────────
  const rawCurrent =
    dp['cur_current'] ??
    dp['current']     ??
    0;
  const current = rawCurrent / 1000; // mA → A

  // ── Power factor ──────────────────────────────────────────────────────────
  // Calculated from measured values; cap at 1.0
  const powerFactor =
    (voltage > 0 && current > 0 && wattage > 0)
      ? Math.min(1, wattage / (voltage * current))
      : 0.92;

  // ── Switch state ──────────────────────────────────────────────────────────
  const isOn =
    dp['switch_1']    ??
    dp['switch']      ??
    dp['relay_status'] ??
    true;

  // ── Online state ──────────────────────────────────────────────────────────
  // If we got at least one DP back, the device is online
  const isOnline = statuses.length > 0;

  return {
    wattage:     isOn ? Math.max(0, Math.round(wattage * 10) / 10) : 0,
    voltage:     Math.round(voltage * 10) / 10,
    current:     isOn ? Math.round(current * 1000) / 1000 : 0,
    powerFactor: Math.round(powerFactor * 100) / 100,
    isOnline,
    isOn,
    rawDps: dp,
  };
}

/**
 * Validate that a Tuya device ID exists and is an energy-monitoring plug.
 * Called at SmartPlug registration to give the user early feedback.
 *
 * @param {string} deviceId
 * @returns {{ valid: boolean, name: string, category: string, online: boolean }}
 */
async function validateDevice(deviceId) {
  try {
    const info = await getDeviceInfo(deviceId);
    return {
      valid:    true,
      name:     info.name     || deviceId,
      category: info.category || 'unknown',
      online:   info.online   ?? false,
    };
  } catch (err) {
    return { valid: false, name: deviceId, category: 'unknown', online: false, error: err.message };
  }
}

/**
 * List all devices in this Tuya account.
 * Useful for onboarding — user can pick from a list instead of typing IDs.
 */
async function listDevices({ page = 1, pageSize = 20 } = {}) {
  return _request('GET', `/v2.0/cloud/thing/device?page_no=${page}&page_size=${pageSize}`);
}

/**
 * Send an on/off command to a plug.
 * @param {string} deviceId
 * @param {boolean} turnOn
 */
async function setPlugState(deviceId, turnOn) {
  return _request('POST', `/v1.0/iot-03/devices/${deviceId}/commands`, {
    commands: [{ code: 'switch_1', value: turnOn }],
  });
}

module.exports = {
  readPlugMetrics,
  getDeviceStatus,
  getDeviceInfo,
  validateDevice,
  listDevices,
  setPlugState,
};
