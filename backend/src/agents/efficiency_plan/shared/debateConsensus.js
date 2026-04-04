const DEFAULT_ROLE_WEIGHTS = {
  analyst: 0.35,
  strategist: 0.35,
  copywriter: 0.3,
};

function normalizeReflections(reflections = []) {
  return (Array.isArray(reflections) ? reflections : [])
    .map((item) => ({
      role: String(item?.role || "unknown"),
      score: Number.isFinite(item?.score) ? item.score : 0,
      approved: Boolean(item?.approved),
      issues: Array.isArray(item?.issues) ? item.issues : [],
    }))
    .filter((item) => item.role !== "unknown");
}

function weightedAverageScore(reflections = []) {
  const normalized = normalizeReflections(reflections);
  if (normalized.length === 0) {
    return 0;
  }

  let weightedSum = 0;
  let totalWeight = 0;

  for (const reflection of normalized) {
    const weight =
      DEFAULT_ROLE_WEIGHTS[reflection.role] ||
      1 / Math.max(normalized.length, 1);
    weightedSum += reflection.score * weight;
    totalWeight += weight;
  }

  return Math.round(weightedSum / Math.max(totalWeight, 1));
}

function buildVotes(reflections = [], round = 1) {
  return normalizeReflections(reflections).map((reflection) => ({
    role: reflection.role,
    confidence: Math.max(0, Math.min(100, Math.round(reflection.score))),
    stance: reflection.approved ? "approve" : "revise",
    rationale:
      reflection.issues.length === 0
        ? `round-${round}:validated`
        : `round-${round}:issues=${reflection.issues.length}`,
  }));
}

function resolveVoteDecision(votes = []) {
  const weighted = {
    approve: 0,
    revise: 0,
  };

  for (const vote of Array.isArray(votes) ? votes : []) {
    const roleWeight = DEFAULT_ROLE_WEIGHTS[vote.role] || 0.33;
    const confidence = Number.isFinite(vote.confidence) ? vote.confidence : 0;
    const stance = vote.stance === "approve" ? "approve" : "revise";
    weighted[stance] += roleWeight * confidence;
  }

  const delta = Math.abs(weighted.approve - weighted.revise);
  if (delta <= 1) {
    const priority = ["analyst", "strategist", "copywriter"];
    for (const role of priority) {
      const roleVote = votes.find((item) => item.role === role);
      if (roleVote) {
        return {
          stance: roleVote.stance,
          tieBreakApplied: true,
          tieBreakRule: `priority:${role}`,
          weighted,
        };
      }
    }
  }

  return {
    stance: weighted.approve >= weighted.revise ? "approve" : "revise",
    tieBreakApplied: false,
    tieBreakRule: null,
    weighted,
  };
}

function applyRoundAdjustments({
  baseScore,
  issueCount,
  challengeCount,
  round,
}) {
  const issuePenalty = Math.max(0, issueCount * 4 - round * 2);
  const challengePenalty = Math.max(0, challengeCount * 3 - round * 2);
  const roundRecovery = round * 3;
  const adjusted = baseScore - issuePenalty - challengePenalty + roundRecovery;
  return Math.max(0, Math.min(100, Math.round(adjusted)));
}

function runDebateAndConsensus({
  reflections = [],
  validationIssues = [],
  challenges = [],
  maxRounds = 2,
  minQualityScore = 85,
}) {
  const issueCount = Array.isArray(validationIssues)
    ? validationIssues.length
    : 0;
  const challengeCount = Array.isArray(challenges) ? challenges.length : 0;
  const baseScore = weightedAverageScore(reflections);

  const consensusLog = [];
  let finalScore = applyRoundAdjustments({
    baseScore,
    issueCount,
    challengeCount,
    round: 1,
  });

  consensusLog.push({
    round: 1,
    votes: buildVotes(reflections, 1),
    qualityScore: finalScore,
    unresolvedChallenges: challengeCount,
    unresolvedIssues: issueCount,
  });

  let rounds = 1;
  while (rounds < maxRounds && finalScore < minQualityScore) {
    rounds += 1;
    finalScore = applyRoundAdjustments({
      baseScore,
      issueCount,
      challengeCount,
      round: rounds,
    });

    consensusLog.push({
      round: rounds,
      votes: buildVotes(reflections, rounds),
      qualityScore: finalScore,
      unresolvedChallenges: Math.max(0, challengeCount - (rounds - 1)),
      unresolvedIssues: Math.max(0, issueCount - (rounds - 1)),
    });
  }

  const finalRound = consensusLog[consensusLog.length - 1] || {
    votes: [],
  };
  const decision = resolveVoteDecision(finalRound.votes);

  return {
    finalQualityScore: finalScore,
    debateRounds: rounds,
    gatePassed: finalScore >= minQualityScore,
    consensusLog,
    minQualityScore,
    decision,
    unresolvedRoute:
      finalScore >= minQualityScore ? "publish" : "safe_fallback",
  };
}

module.exports = {
  runDebateAndConsensus,
};
