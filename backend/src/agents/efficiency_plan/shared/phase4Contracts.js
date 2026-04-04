const { z } = require("zod");

const MAX_REVISION_ATTEMPTS = 2;
const MIN_STRATEGY_COUNT = 4;

const DEFAULT_STRATEGY_TEMPLATES = [
  {
    id: "baseline_strategy_1",
    actionSummary: "Optimize cooling runtime windows",
    fullDescription:
      "Run AC in shorter cycles and pair with fan circulation to reduce compressor load.",
  },
  {
    id: "baseline_strategy_2",
    actionSummary: "Shift heavy appliances to off-peak",
    fullDescription:
      "Use washing machine and water heater during lower-demand windows to flatten daily peaks.",
  },
  {
    id: "baseline_strategy_3",
    actionSummary: "Cut standby and idle loads",
    fullDescription:
      "Switch off set-top boxes, chargers, and kitchen devices when inactive to avoid passive draw.",
  },
  {
    id: "baseline_strategy_4",
    actionSummary: "Tune thermostat and fan settings",
    fullDescription:
      "Increase thermostat by 1-2C and maintain fan speed for comfort with lower total energy use.",
  },
  {
    id: "baseline_strategy_5",
    actionSummary: "Improve daily usage discipline",
    fullDescription:
      "Track one high-consumption appliance daily and cap unnecessary runtime by 15-20 minutes.",
  },
];

const AnomalySchema = z.object({
  id: z.string().min(1),
  item: z.string().min(1),
  description: z.string().min(1),
  rupeeCostImpact: z.number().finite().nonnegative(),
});

const StrategySchema = z.object({
  id: z.string().min(1),
  actionSummary: z.string().min(1),
  fullDescription: z.string().min(1),
  projectedSavings: z.number().finite().nonnegative(),
});

const KeyActionSchema = z.object({
  action: z.string().min(1),
  impact: z.string().min(1),
  estimatedSaving: z.union([z.string(), z.number()]).optional(),
});

const FinalPlanSchema = z.object({
  planType: z.string().min(1),
  title: z.string().min(1),
  status: z.string().min(1),
  summary: z.string().min(1),
  keyActions: z.array(KeyActionSchema).min(1),
  quickWins: z.array(z.string()).optional(),
  monthlyTip: z.string().optional(),
});

function parseEstimatedSaving(value) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === "string") {
    const normalized = value.replace(/[^0-9.-]/g, "");
    const parsed = Number(normalized);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  return 0;
}

function normalizeAnomalies(input = []) {
  const list = Array.isArray(input) ? input : [];
  const normalized = list
    .map((item, index) => ({
      id: String(item?.id || `anomaly_${index + 1}`),
      item: String(item?.item || "General Usage"),
      description: String(
        item?.description || "Detected unusual consumption pattern.",
      ),
      rupeeCostImpact: Number.isFinite(Number(item?.rupeeCostImpact))
        ? Math.max(0, Number(item.rupeeCostImpact))
        : 0,
    }))
    .filter((item) => item.id && item.item && item.description);

  if (normalized.length > 0) {
    return normalized;
  }

  return [
    {
      id: "baseline_anomaly",
      item: "General Household Load",
      description: "Baseline anomaly generated due to missing analyst output.",
      rupeeCostImpact: 150,
    },
  ];
}

function normalizeStrategies(input = [], anomalies = []) {
  const anomalyBudget = Math.max(
    1,
    normalizeAnomalies(anomalies).reduce(
      (sum, item) => sum + item.rupeeCostImpact,
      0,
    ),
  );

  const list = Array.isArray(input) ? input : [];
  const normalized = list
    .map((item, index) => ({
      id: String(item?.id || `strategy_${index + 1}`),
      actionSummary: String(
        item?.actionSummary || "Reduce non-essential runtime",
      ),
      fullDescription: String(
        item?.fullDescription ||
          "Shift high-consumption usage to shorter windows and avoid idle loads.",
      ),
      projectedSavings: Number.isFinite(Number(item?.projectedSavings))
        ? Math.max(0, Number(item.projectedSavings))
        : 0,
    }))
    .filter((item) => item.actionSummary.length > 0);

  const bounded = normalized.map((item) => ({
    ...item,
    projectedSavings: Math.min(item.projectedSavings, anomalyBudget * 1.2),
  }));

  const minRequired = Math.min(
    MIN_STRATEGY_COUNT,
    DEFAULT_STRATEGY_TEMPLATES.length,
  );
  if (bounded.length >= minRequired) {
    return bounded;
  }

  const fallbackSavings = Math.max(50, Math.round(anomalyBudget * 0.15));
  const existingSummaries = new Set(
    bounded.map((item) => item.actionSummary.toLowerCase()),
  );
  const supplemented = [...bounded];

  for (const template of DEFAULT_STRATEGY_TEMPLATES) {
    if (supplemented.length >= minRequired) {
      break;
    }
    if (existingSummaries.has(template.actionSummary.toLowerCase())) {
      continue;
    }
    supplemented.push({
      id: `${template.id}_${supplemented.length + 1}`,
      actionSummary: template.actionSummary,
      fullDescription: template.fullDescription,
      projectedSavings: fallbackSavings,
    });
  }

  return supplemented;
}

function buildFallbackFinalPlan(strategies = []) {
  const safeStrategies = normalizeStrategies(strategies, []);
  const rupees = safeStrategies.reduce(
    (sum, item) => sum + item.projectedSavings,
    0,
  );

  return {
    planType: "efficiency",
    title: "Collaborative Efficiency Plan",
    status: "draft",
    summary: "This plan was generated with validated specialist outputs.",
    estimatedCurrentMonthlyCost: 0,
    estimatedSavingsIfFollowed: {
      units: 0,
      rupees,
      percentage: 0,
    },
    efficiencyScore: null,
    keyActions: safeStrategies.map((item) => ({
      priority: "high",
      appliance: "General Household",
      action: item.actionSummary,
      impact: item.fullDescription,
      estimatedSaving: item.projectedSavings,
    })),
    slabAlert: {
      isInDangerZone: false,
      currentSlab: "unknown",
      warning: "",
    },
    quickWins: ["Use shorter appliance cycles", "Avoid idle standby loads"],
    monthlyTip: "Review your highest runtime appliance weekly.",
  };
}

function validateAnomalies(anomalies = []) {
  const parsed = z.array(AnomalySchema).safeParse(anomalies);
  if (parsed.success) {
    return { ok: true, issues: [] };
  }

  return {
    ok: false,
    issues: parsed.error.issues.map(
      (issue) => `analyst:${issue.path.join(".")}:${issue.message}`,
    ),
  };
}

function validateStrategies(strategies = []) {
  const parsed = z.array(StrategySchema).safeParse(strategies);
  if (parsed.success) {
    return { ok: true, issues: [] };
  }

  return {
    ok: false,
    issues: parsed.error.issues.map(
      (issue) => `strategist:${issue.path.join(".")}:${issue.message}`,
    ),
  };
}

function validateFinalPlan(finalPlan = {}) {
  const parsed = FinalPlanSchema.safeParse(finalPlan);
  if (!parsed.success) {
    return {
      ok: false,
      issues: parsed.error.issues.map(
        (issue) => `copywriter:${issue.path.join(".")}:${issue.message}`,
      ),
    };
  }

  return { ok: true, issues: [] };
}

function detectHallucinationRisks(
  anomalies = [],
  strategies = [],
  finalPlan = null,
) {
  const normalizedAnomalies = normalizeAnomalies(anomalies);
  const anomalyBudget = normalizedAnomalies.reduce(
    (sum, item) => sum + item.rupeeCostImpact,
    0,
  );
  const strategySavings = normalizeStrategies(
    strategies,
    normalizedAnomalies,
  ).reduce((sum, item) => sum + item.projectedSavings, 0);

  const risks = [];
  if (strategySavings > anomalyBudget * 1.8) {
    risks.push(
      `qa:projectedSavings_excess:${strategySavings} exceeds expected ceiling for anomaly budget ${anomalyBudget}`,
    );
  }

  if (finalPlan && Array.isArray(finalPlan.keyActions)) {
    const planSavings = finalPlan.keyActions.reduce(
      (sum, action) => sum + parseEstimatedSaving(action.estimatedSaving),
      0,
    );

    if (planSavings > Math.max(strategySavings * 1.8, 1)) {
      risks.push(
        `qa:keyActionSavings_excess:${planSavings} exceeds strategy savings envelope ${strategySavings}`,
      );
    }
  }

  return risks;
}

function buildCrossAgentChallenges(
  anomalies = [],
  strategies = [],
  finalPlan = null,
) {
  const normalizedAnomalies = normalizeAnomalies(anomalies);
  const normalizedStrategies = normalizeStrategies(
    strategies,
    normalizedAnomalies,
  );
  const anomalyBudget = normalizedAnomalies.reduce(
    (sum, item) => sum + item.rupeeCostImpact,
    0,
  );
  const strategyBudget = normalizedStrategies.reduce(
    (sum, item) => sum + item.projectedSavings,
    0,
  );
  const challenges = [];
  const makeChallenge = (input, index) => ({
    challengeId: `ch_${input.source}_${input.target}_${input.type}_${index + 1}`,
    severity: input.severity || "medium",
    ...input,
  });

  if (
    (Array.isArray(strategies) &&
      strategies.length > 0 &&
      (!Array.isArray(anomalies) || anomalies.length === 0)) ||
    (strategyBudget > 0 && anomalyBudget <= 0)
  ) {
    challenges.push(
      makeChallenge(
        {
          source: "strategist",
          target: "analyst",
          type: "missing_evidence",
          severity: "high",
          reason: "Strategies were generated without anomaly evidence.",
          evidence: {
            anomalyCount: Array.isArray(anomalies) ? anomalies.length : 0,
            strategyCount: Array.isArray(strategies) ? strategies.length : 0,
            anomalyBudget,
            strategyBudget,
          },
          expectedCorrection:
            "Provide anomaly-backed evidence or reduce projected savings before publish.",
        },
        challenges.length,
      ),
    );
  }

  if (
    finalPlan &&
    Array.isArray(finalPlan.keyActions) &&
    finalPlan.keyActions.length < (strategies || []).length
  ) {
    challenges.push(
      makeChallenge(
        {
          source: "copywriter",
          target: "strategist",
          type: "coverage_gap",
          severity: "medium",
          reason:
            "Some strategist outputs were not represented in final keyActions.",
          evidence: {
            strategyCount: Array.isArray(strategies) ? strategies.length : 0,
            keyActionCount: Array.isArray(finalPlan.keyActions)
              ? finalPlan.keyActions.length
              : 0,
          },
          expectedCorrection:
            "Map each validated strategy to at least one keyAction.",
        },
        challenges.length,
      ),
    );
  }

  return challenges;
}

function buildReflection(role, issues = [], challenges = []) {
  const issuePenalty = Math.min(60, issues.length * 20);
  const challengePenalty = Math.min(25, challenges.length * 5);
  const score = Math.max(0, 100 - issuePenalty - challengePenalty);

  return {
    role,
    approved: issues.length === 0,
    score,
    issues,
    challengeCount: challenges.length,
    reviewedAt: new Date().toISOString(),
  };
}

module.exports = {
  MAX_REVISION_ATTEMPTS,
  buildCrossAgentChallenges,
  buildFallbackFinalPlan,
  buildReflection,
  detectHallucinationRisks,
  normalizeAnomalies,
  normalizeStrategies,
  validateAnomalies,
  validateStrategies,
  validateFinalPlan,
};
