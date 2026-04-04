const {
  buildCrossAgentChallenges,
  buildFallbackFinalPlan,
  buildReflection,
  detectHallucinationRisks,
  normalizeAnomalies,
  normalizeStrategies,
  validateAnomalies,
  validateFinalPlan,
  validateStrategies,
} = require("../src/agents/efficiency_plan/shared/phase4Contracts");

describe("phase4 validation contracts", () => {
  it("normalizes and validates specialist outputs", () => {
    const anomalies = normalizeAnomalies([{ item: "AC", description: "high usage", rupeeCostImpact: 900 }]);
    const strategies = normalizeStrategies(
      [{ actionSummary: "raise temp", fullDescription: "set AC to 25C", projectedSavings: 2000 }],
      anomalies,
    );
    const finalPlan = buildFallbackFinalPlan(strategies);

    expect(validateAnomalies(anomalies).ok).toBe(true);
    expect(validateStrategies(strategies).ok).toBe(true);
    expect(validateFinalPlan(finalPlan).ok).toBe(true);
  });

  it("ensures a minimum strategy floor for actionable plans", () => {
    const anomalies = normalizeAnomalies([
      { id: "a1", item: "AC", description: "high usage", rupeeCostImpact: 600 },
    ]);
    const strategies = normalizeStrategies(
      [
        {
          id: "s1",
          actionSummary: "Raise AC setpoint",
          fullDescription: "Keep AC at 24-25C for most hours.",
          projectedSavings: 180,
        },
      ],
      anomalies,
    );
    const finalPlan = buildFallbackFinalPlan(strategies);

    expect(strategies.length).toBeGreaterThanOrEqual(4);
    expect(finalPlan.keyActions.length).toBeGreaterThanOrEqual(4);
  });

  it("detects hallucination risk when savings envelope is exceeded", () => {
    const anomalies = normalizeAnomalies([{ id: "a1", item: "Fridge", description: "spike", rupeeCostImpact: 100 }]);
    const strategies = [
      {
        id: "s1",
        actionSummary: "replace all appliances",
        fullDescription: "large unsupported savings",
        projectedSavings: 2000,
      },
    ];
    const finalPlan = {
      planType: "efficiency",
      title: "Plan",
      status: "draft",
      summary: "x",
      keyActions: [{ action: "replace all", impact: "huge", estimatedSaving: 5000 }],
    };

    const risks = detectHallucinationRisks(anomalies, strategies, finalPlan);
    expect(risks.length).toBeGreaterThan(0);
  });

  it("builds cross-agent challenge records and reflection verdicts", () => {
    const anomalies = [];
    const strategies = [{ id: "s1", actionSummary: "shift load", fullDescription: "off peak", projectedSavings: 100 }];
    const finalPlan = buildFallbackFinalPlan(strategies);

    const challenges = buildCrossAgentChallenges(anomalies, strategies, finalPlan);
    const reflection = buildReflection("strategist", ["qa:missing-evidence"], challenges);

    expect(challenges.length).toBeGreaterThan(0);
    const strategistChallenge = challenges.find(
      (item) => item.source === "strategist" && item.target === "analyst",
    );
    expect(strategistChallenge).toBeTruthy();
    expect(strategistChallenge).toHaveProperty("challengeId");
    expect(strategistChallenge).toHaveProperty("severity");
    expect(strategistChallenge).toHaveProperty("evidence");
    expect(strategistChallenge).toHaveProperty("expectedCorrection");
    expect(reflection.approved).toBe(false);
    expect(reflection.score).toBeLessThan(100);
  });
});