const crypto = require("crypto");

const SENSITIVE_KEYS = new Set([
  "token",
  "apiKey",
  "password",
  "secret",
  "authorization",
]);

function tokenize(value) {
  const normalized = typeof value === "string" ? value : JSON.stringify(value);
  const digest = crypto
    .createHash("sha256")
    .update(normalized)
    .digest("hex")
    .slice(0, 12);
  return `[TOKENIZED:${digest}]`;
}

function redactMemoryPayload(payload) {
  if (Array.isArray(payload)) {
    return payload.map((item) => redactMemoryPayload(item));
  }

  if (payload && typeof payload === "object") {
    const out = {};
    for (const [key, value] of Object.entries(payload)) {
      if (SENSITIVE_KEYS.has(key)) {
        out[key] = tokenize(value);
      } else {
        out[key] = redactMemoryPayload(value);
      }
    }
    return out;
  }

  return payload;
}

module.exports = {
  redactMemoryPayload,
};
