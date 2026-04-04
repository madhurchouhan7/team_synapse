// src/controllers/ai.controller.js
// const { generateEfficiencyPlan } = require('../services/gemini.service'); // DEPRECATED
const { efficiencyPlanApp } = require("../agents/efficiency_plan/index");
const {
  collaborativePlanApp,
} = require("../agents/efficiency_plan/collaborative.index");
const {
  resolveOrchestrationMode,
} = require("../agents/efficiency_plan/orchestrators/modeResolver");
const {
  buildPlanResponseEnvelope,
} = require("../agents/efficiency_plan/orchestrators/responseEnvelope");
const { sendSuccess } = require("../utils/ApiResponse");
const ApiError = require("../utils/ApiError");

function logAgenticPlan(event, payload) {
  console.info(`[AGENTIC_PLAN] ${event} ${JSON.stringify(payload)}`);
}

/**
 * @desc    Generate AI Efficiency Plan via Multi-Agent LangGraph Workflow
 * @route   POST /api/v1/ai/generate-plan
 * @access  Private
 */
const getEfficiencyPlan = async (req, res, next) => {
  let requestedMode = "unspecified";
  let executionPath = "unknown";
  let runId = null;
  let threadId = null;
  const startTime = Date.now();

  try {
    const userData = req.body;

    if (!userData || Object.keys(userData).length === 0) {
      throw new ApiError(
        400,
        "No user data provided. Send appliances, bill, and context.",
      );
    }

    // 1. Fetch real-time weather data
    let weatherContext = "No live weather data provided.";
    const weatherApiKey = process.env.OPENWEATHER_API_KEY;
    const userLocation = userData.user?.location || "India";

    if (weatherApiKey) {
      try {
        // We use dynamic import for fetch since Node > 18 or node-fetch might be required
        const wRes = await fetch(
          `https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(userLocation)}&appid=${weatherApiKey}&units=metric`,
        );
        if (wRes.ok) {
          const wData = await wRes.json();
          weatherContext = `Temperature: ${wData.main.temp}°C, Conditions: ${wData.weather[0].description}, Humidity: ${wData.main.humidity}%`;
        } else {
          console.warn(`[WeatherAPI] Fetch failed with status ${wRes.status}`);
        }
      } catch (error) {
        console.error(
          "[WeatherAPI] Error fetching weather context:",
          error.message,
        );
      }
    }

    // 2. Invoke LangGraph Workflow
    const initialState = {
      userData: userData,
      weatherContext: weatherContext,
    };

    ({ requestedMode, executionPath } = resolveOrchestrationMode(req));
    const selectedApp =
      executionPath === "collaborative"
        ? collaborativePlanApp
        : efficiencyPlanApp;

    runId = userData.runId || `run-${req.id || Date.now()}`;
    threadId = req.get("x-thread-id") || userData.threadId || req.id;
    const tenantId =
      req.user?.tenantId ||
      userData.user?.tenantId ||
      req.user?.firebaseUid ||
      (req.user?._id ? String(req.user._id) : undefined) ||
      req.user?.id;
    const memoryUserId =
      req.user?.id ||
      req.user?._id ||
      userData.user?.id ||
      userData.user?.userId;

    if (executionPath === "collaborative") {
      if (!tenantId || !memoryUserId || !threadId) {
        throw new ApiError(
          400,
          "Missing required memory identity keys for collaborative mode: tenantId, userId, threadId",
        );
      }
    }

    logAgenticPlan("start", {
      requestId: req.id,
      userId: memoryUserId,
      tenantId,
      requestedMode,
      executionPath,
      runId,
      threadId,
      hasWeatherContext: Boolean(weatherContext),
      applianceCount: Array.isArray(userData.appliances)
        ? userData.appliances.length
        : 0,
    });

    const resultState = await selectedApp.invoke({
      ...initialState,
      memoryMeta:
        executionPath === "collaborative"
          ? {
              tenantId,
              userId: memoryUserId,
              threadId,
              runId,
              requestId: req.id,
              query: userData.query || "",
            }
          : undefined,
    });
    const plan = resultState.finalPlan;

    if (!plan) {
      throw new ApiError(
        500,
        "Failed to generate AI plan via multi-agent workflow",
      );
    }

    const responseEnvelope = buildPlanResponseEnvelope({
      finalPlan: plan,
      requestedMode,
      executionPath,
      requestId: req.id,
      runId: resultState.runId || runId,
      threadId: resultState.threadId || threadId,
      qualityScore: resultState.qualityScore,
      debateRounds: resultState.debateRounds,
      revisionCount: resultState.revisionCount,
      validationIssueCount: Array.isArray(resultState.validationIssues)
        ? resultState.validationIssues.length
        : undefined,
      challengeCount: Array.isArray(resultState.crossAgentChallenges)
        ? resultState.crossAgentChallenges.length
        : undefined,
      roleRetryBudgets: resultState.roleRetryBudgets,
      qualityGate: resultState.qualityGate,
      consensusRoundCount: Array.isArray(resultState.consensusLog)
        ? resultState.consensusLog.length
        : resultState.debateRounds,
      consensusRationale: Array.isArray(resultState.consensusLog)
        ? resultState.consensusLog.map((entry) => ({
            round: entry.round,
            qualityScore: entry.qualityScore,
            unresolvedIssues: entry.unresolvedIssues,
            unresolvedChallenges: entry.unresolvedChallenges,
            votes: Array.isArray(entry.votes)
              ? entry.votes.map((vote) => ({
                  role: vote.role,
                  stance: vote.stance,
                  confidence: vote.confidence,
                  rationale: vote.rationale,
                }))
              : [],
          }))
        : [],
      safeFallbackActivated: Boolean(resultState.safeFallbackActivated),
      consensusDecision: resultState.consensusDecision,
      unresolvedRoute: resultState.unresolvedRoute,
      degradationEvents: resultState.degradationEvents,
    });

    const metadata = responseEnvelope?.metadata || {};
    logAgenticPlan("complete", {
      requestId: req.id,
      runId: metadata?.memoryTrace?.runId || runId,
      threadId: metadata?.memoryTrace?.threadId || threadId,
      requestedMode: metadata.requestedMode || requestedMode,
      executionPath: metadata.executionPath || executionPath,
      durationMs: Date.now() - startTime,
      qualityScore: metadata.qualityScore,
      debateRounds: metadata.debateRounds,
      phase4: metadata.phase4 || null,
      phase5: metadata.phase5 || null,
      phase6: metadata.phase6 || null,
    });

    return sendSuccess(
      res,
      200,
      "Plan generated successfully.",
      responseEnvelope,
    );
  } catch (error) {
    logAgenticPlan("error", {
      requestId: req.id,
      runId,
      threadId,
      requestedMode,
      executionPath,
      durationMs: Date.now() - startTime,
      message: error.message,
    });
    console.error("AI Plan Generation Error:", error.message);
    next(error);
  }
};

module.exports = {
  getEfficiencyPlan,
};
