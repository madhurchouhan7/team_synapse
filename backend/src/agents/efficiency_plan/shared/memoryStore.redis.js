const cacheService = require("../../../services/CacheService");
const { assertMemoryIdentity, buildMemoryKeys } = require("./memoryKeys");

const ACTIVE_TTL_SECONDS = 60 * 60 * 24 * 30;
const inMemoryStore = new Map();

function getList(key) {
  return inMemoryStore.get(key) || [];
}

function setList(key, value) {
  inMemoryStore.set(key, value);
}

async function appendEvent(identity, event) {
  const validated = assertMemoryIdentity(identity);
  const { eventsKey } = buildMemoryKeys(validated);

  const serialized = JSON.stringify(event);

  if (cacheService.isConnected && cacheService.client) {
    await cacheService.client.rpush(eventsKey, serialized);
    await cacheService.client.expire(eventsKey, ACTIVE_TTL_SECONDS);
  } else {
    const curr = getList(eventsKey);
    curr.push(serialized);
    setList(eventsKey, curr);
  }

  return event;
}

async function listRecentEvents(identity, limit = 12) {
  const validated = assertMemoryIdentity(identity);
  const { eventsKey } = buildMemoryKeys(validated);

  const start = Math.max(-limit, -1000);
  const rows =
    cacheService.isConnected && cacheService.client
      ? await cacheService.client.lrange(eventsKey, start, -1)
      : getList(eventsKey).slice(start);

  return rows.map((item) => JSON.parse(item));
}

async function listHistoricalEvents(identity, query = "", options = {}) {
  const validated = assertMemoryIdentity(identity);
  const { eventsKey } = buildMemoryKeys(validated);
  const rows =
    cacheService.isConnected && cacheService.client
      ? await cacheService.client.lrange(eventsKey, 0, -1)
      : getList(eventsKey);

  const parsed = rows.map((item) => JSON.parse(item));
  if (!query) {
    return parsed;
  }

  const q = String(query).toLowerCase();
  const maxItems = options.maxItems || 100;
  return parsed
    .filter((event) => JSON.stringify(event).toLowerCase().includes(q))
    .slice(0, maxItems);
}

async function archiveEvent(identity, event) {
  const validated = assertMemoryIdentity(identity);
  const { archiveKey } = buildMemoryKeys(validated);
  const serialized = JSON.stringify(event);

  if (cacheService.isConnected && cacheService.client) {
    await cacheService.client.rpush(archiveKey, serialized);
  } else {
    const curr = getList(archiveKey);
    curr.push(serialized);
    setList(archiveKey, curr);
  }

  return true;
}

function __resetForTests() {
  inMemoryStore.clear();
}

module.exports = {
  appendEvent,
  listRecentEvents,
  listHistoricalEvents,
  archiveEvent,
  __resetForTests,
};
