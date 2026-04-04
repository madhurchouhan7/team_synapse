let tiktokenLib = null;

try {
  tiktokenLib = require("js-tiktoken");
} catch (_err) {
  tiktokenLib = null;
}

function rankHistoricalEvents(events = [], query = "") {
  if (!query) return events;
  const q = query.toLowerCase();

  return [...events]
    .map((event, idx) => {
      const text = JSON.stringify(event).toLowerCase();
      const lexical = text.includes(q) ? 2 : 0;
      const recency = 1 / (idx + 1);
      return { event, score: lexical + recency };
    })
    .filter((entry) => entry.score >= 2)
    .sort((a, b) => b.score - a.score)
    .map((entry) => entry.event);
}

function estimateTokens(text = "") {
  if (tiktokenLib && typeof tiktokenLib.encodingForModel === "function") {
    try {
      const enc = tiktokenLib.encodingForModel("gpt-4o-mini");
      const tokens = enc.encode(text).length;
      if (enc.free) enc.free();
      return tokens;
    } catch (_err) {
      // Fall through to heuristic.
    }
  }

  return Math.ceil(String(text).length / 4);
}

function selectWithinBudget(items, tokenBudget) {
  const selected = [];
  let used = 0;

  for (const item of items) {
    const cost = estimateTokens(JSON.stringify(item));
    if (used + cost > tokenBudget) {
      break;
    }
    selected.push(item);
    used += cost;
  }

  return { selected, tokenUsage: used };
}

function composeAgentContext({
  recentEvents = [],
  historicalEvents = [],
  query = "",
  tokenBudget = 6000,
  recentLimit = 12,
} = {}) {
  const recent = recentEvents.slice(-recentLimit);
  const rankedHistorical = rankHistoricalEvents(historicalEvents, query);

  const merged = [...recent, ...rankedHistorical];
  const { selected, tokenUsage } = selectWithinBudget(merged, tokenBudget);

  const hasHistorical = selected.length > recent.length;
  if (!hasHistorical) {
    const fallback = selectWithinBudget(recent, tokenBudget);
    return {
      contextEvents: fallback.selected,
      tokenUsage: fallback.tokenUsage,
      usedFallback: true,
    };
  }

  return {
    contextEvents: selected,
    tokenUsage,
    usedFallback: false,
  };
}

module.exports = {
  composeAgentContext,
};
