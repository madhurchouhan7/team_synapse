const ApiError = require("../../../utils/ApiError");

function assertMemoryIdentity(ctx = {}) {
  const tenantId = String(ctx.tenantId || "").trim();
  const userId = String(ctx.userId || "").trim();
  const threadId = String(ctx.threadId || "").trim();

  if (!tenantId || !userId || !threadId) {
    throw new ApiError(
      400,
      "Missing required memory identity keys: tenantId, userId, threadId",
    );
  }

  return { tenantId, userId, threadId };
}

function buildThreadScope(ctx = {}) {
  const { tenantId, userId, threadId } = assertMemoryIdentity(ctx);
  return `${tenantId}:${userId}:${threadId}`;
}

function buildMemoryKeys(ctx = {}) {
  const scope = buildThreadScope(ctx);
  return {
    scope,
    eventsKey: `memory:${scope}:events`,
    archiveKey: `memory:${scope}:archive`,
  };
}

module.exports = {
  assertMemoryIdentity,
  buildThreadScope,
  buildMemoryKeys,
};
