const ApiError = require("../../../utils/ApiError");
const { assertMemoryIdentity } = require("./memoryKeys");
const { validateMemoryEvent } = require("./memorySchema");
const { redactMemoryPayload } = require("./redaction");
const memoryStore = require("./memoryStore.redis");

function buildRevisionId() {
  return `rev-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

async function writeEvent(input = {}) {
  const identity = assertMemoryIdentity(input);

  const event = {
    ...input,
    ...identity,
    revisionId: input.revisionId || buildRevisionId(),
    timestamp: input.timestamp || new Date().toISOString(),
    payload: redactMemoryPayload(input.payload || {}),
  };

  const parsed = validateMemoryEvent(event);
  if (!parsed.success) {
    throw new ApiError(
      400,
      parsed.error.issues.map((i) => i.message).join("; "),
    );
  }

  return memoryStore.appendEvent(identity, parsed.data);
}

async function getRecent(scope, { limit = 12 } = {}) {
  const identity = assertMemoryIdentity(scope);
  return memoryStore.listRecentEvents(identity, limit);
}

async function getHistorical(scope, query = "", options = {}) {
  const identity = assertMemoryIdentity(scope);
  return memoryStore.listHistoricalEvents(identity, query, options);
}

module.exports = {
  writeEvent,
  getRecent,
  getHistorical,
};
