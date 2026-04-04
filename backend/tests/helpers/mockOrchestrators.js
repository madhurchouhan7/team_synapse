const ApiError = require("../../src/utils/ApiError");

function defaultFinalPlan(title = "Mock Plan") {
  return {
    planType: "efficiency",
    title,
    status: "draft",
    summary: "Mock summary",
    estimatedCurrentMonthlyCost: 1000,
    estimatedSavingsIfFollowed: {
      units: 10,
      rupees: 100,
      percentage: 10,
    },
    efficiencyScore: 75,
    keyActions: [],
    slabAlert: {
      isInDangerZone: false,
      currentSlab: "Generic",
      warning: "",
    },
    quickWins: [],
    monthlyTip: "",
  };
}

function legacySuccessStub(finalPlan = defaultFinalPlan("Legacy Plan")) {
  return {
    invoke: jest.fn().mockResolvedValue({ finalPlan }),
    finalPlan,
  };
}

function collaborativeSuccessStub({
  finalPlan = defaultFinalPlan("Collaborative Plan"),
  qualityScore = 88,
  debateRounds = 2,
  revisionCount = 0,
  validationIssues = [],
  crossAgentChallenges = [],
  qualityGate = { minScore: 85, passed: false },
  consensusLog = [],
  safeFallbackActivated = false,
  consensusDecision = {
    stance: "revise",
    tieBreakApplied: false,
    tieBreakRule: null,
  },
  unresolvedRoute = "safe_fallback",
} = {}) {
  return {
    invoke: jest.fn().mockResolvedValue({
      finalPlan,
      qualityScore,
      debateRounds,
      revisionCount,
      validationIssues,
      crossAgentChallenges,
      qualityGate,
      consensusLog,
      safeFallbackActivated,
      consensusDecision,
      unresolvedRoute,
    }),
    finalPlan,
    qualityScore,
    debateRounds,
    revisionCount,
    validationIssues,
    crossAgentChallenges,
    qualityGate,
    consensusLog,
    safeFallbackActivated,
    consensusDecision,
    unresolvedRoute,
  };
}

function collaborativeFailureStub(
  error = new ApiError(500, "Collaborative path failed"),
) {
  return {
    invoke: jest.fn().mockRejectedValue(error),
    error,
  };
}

module.exports = {
  legacySuccessStub,
  collaborativeSuccessStub,
  collaborativeFailureStub,
  defaultFinalPlan,
};
