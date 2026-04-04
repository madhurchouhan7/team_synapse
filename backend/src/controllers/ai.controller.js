// src/controllers/ai.controller.js
const { sendSuccess } = require("../utils/ApiResponse");
const ApiError = require("../utils/ApiError");

/**
 * @desc    Generate AI Efficiency Plan via Multi-Agent LangGraph Workflow
 * @route   POST /api/v1/ai/generate-plan
 * @access  Private
 */
const getEfficiencyPlan = async (req, res, next) => {
  try {
    const FASTAPI_URL = process.env.LANGGRAPH_SERVICE_URL || "http://127.0.0.1:8000";
    
    // Prepare headers to forward user identity/context to the Python sidecar
    const headers = {
      "Content-Type": "application/json",
    };
    
    if (req.get("x-ai-mode")) headers["x-ai-mode"] = req.get("x-ai-mode");
    if (req.get("x-thread-id")) headers["x-thread-id"] = req.get("x-thread-id");
    if (req.id) headers["x-request-id"] = String(req.id);
    
    const tenantId = req.user?.tenantId || req.body?.user?.tenantId || req.user?.firebaseUid;
    if (tenantId) headers["x-user-tenant-id"] = String(tenantId);
    
    const userId = req.user?.id || req.user?._id || req.body?.user?.id || req.body?.user?.userId;
    if (userId) headers["x-user-id"] = String(userId);
    
    const firebaseUid = req.user?.firebaseUid;
    if (firebaseUid) headers["x-user-firebase-uid"] = String(firebaseUid);

    const response = await fetch(`${FASTAPI_URL}/generate-plan`, {
        method: "POST",
        headers,
        body: JSON.stringify(req.body)
    });

    if (!response.ok) {
        let errorData;
        try {
            errorData = await response.json();
        } catch(e) {
            errorData = { detail: response.statusText };
        }
        throw new ApiError(response.status, errorData.detail || "Failed to generate plan from agent service");
    }

    const result = await response.json();
    return sendSuccess(res, 200, result.message || "Plan generated successfully.", result.data);

  } catch (error) {
    if (error.cause && error.cause.code === 'ECONNREFUSED') {
       console.error("Agent service is not running on port 8000.");
       return next(new ApiError(503, "Agent sidecar service is unavailable."));
    }
    console.error("AI Plan Proxy Error:", error.message);
    next(error);
  }
};

module.exports = {
  getEfficiencyPlan,
};
