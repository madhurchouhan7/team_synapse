// src/services/gemini.service.js
// ⚠️ DEPRECATED: This monolithic service has been replaced by the Multi-Agent LangGraph Workflow.
// Do not use this file. All new logic lives in src/agents/efficiency_plan/.

/**
 * Legacy code is retained conditionally for historical reference.
 */
module.exports = {
    generateEfficiencyPlan: async () => {
        throw new Error("DEPRECATED: Use the LangGraph workflow exported from src/agents/efficiency_plan/index.js instead.");
    }
};
