"""
FastAPI application for the WattWise Efficiency Plan Multi-Agent Workflow.

This service runs as a sidecar to the main Node.js/Express backend.
The Express ai.controller.js proxies requests here via HTTP.

Usage:
    uvicorn src.agents.efficiency_plan.app:app --host 0.0.0.0 --port 8000 --reload
    or:
    python -m src.agents.efficiency_plan.app
"""

import json
import logging
import os
import time
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import Any, Optional
from urllib.parse import quote

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Load .env from backend root
load_dotenv(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".env"))

from .index import efficiency_plan_app
from .collaborative_index import collaborative_plan_app
from .orchestrators.mode_resolver import resolve_orchestration_mode
from .orchestrators.response_envelope import build_plan_response_envelope
from .exceptions import ApiError

# New agents
from ..bill_decoder.index import bill_decoder_app
from ..upgrade_advisor.index import upgrade_advisor_app


# ── Logging ────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("wattwise.agents.fastapi")


# ── Lifespan ───────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("⚡ WattWise LangGraph Agent Service starting...")
    yield
    logger.info("🛑 WattWise LangGraph Agent Service shutting down...")


# ── FastAPI App ────────────────────────────────────────────────────────
app = FastAPI(
    title="WattWise LangGraph Agent Service",
    description="Multi-agent workflow service: Efficiency Plan, Bill Decoder, Upgrade Advisor",
    version="3.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Request / Response Models ──────────────────────────────────────────
class UserData(BaseModel):
    """Flexible model — accepts any JSON body the Flutter app sends."""
    model_config = {"extra": "allow"}


class PlanResponse(BaseModel):
    success: bool = True
    message: str = "Plan generated successfully."
    data: Optional[dict[str, Any]] = None


class BillDecodeResponse(BaseModel):
    success: bool = True
    message: str = "Bill decoded successfully."
    data: Optional[dict[str, Any]] = None


class UpgradeResponse(BaseModel):
    success: bool = True
    message: str = "Upgrade recommendations generated."
    data: Optional[dict[str, Any]] = None


class HealthResponse(BaseModel):
    status: str = "ok"
    service: str = "wattwise-langgraph-agent"
    timestamp: str


# ── Helper ─────────────────────────────────────────────────────────────
def _log_agentic_plan(event: str, payload: dict) -> None:
    logger.info(f"[AGENTIC_PLAN] {event} {json.dumps(payload, default=str)}")


async def _fetch_weather(location: str) -> str:
    """Fetch real-time weather from OpenWeather API."""
    api_key = os.environ.get("OPEN_WEATHER_API_KEY")
    if not api_key:
        return "No live weather data provided."

    try:
        url = (
            f"https://api.openweathermap.org/data/2.5/weather"
            f"?q={quote(location)}&appid={api_key}&units=metric"
        )
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(url)
            if resp.status_code == 200:
                w = resp.json()
                return (
                    f"Temperature: {w['main']['temp']}°C, "
                    f"Conditions: {w['weather'][0]['description']}, "
                    f"Humidity: {w['main']['humidity']}%"
                )
            else:
                logger.warning(f"[WeatherAPI] Fetch failed with status {resp.status_code}")
    except Exception as exc:
        logger.error(f"[WeatherAPI] Error fetching weather context: {exc}")

    return "No live weather data provided."


# ── Endpoints ──────────────────────────────────────────────────────────
@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check for the LangGraph agent service."""
    return HealthResponse(
        status="ok",
        service="wattwise-langgraph-agent",
        timestamp=datetime.now(timezone.utc).isoformat(),
    )


@app.post("/generate-plan", response_model=PlanResponse)
async def generate_plan(
    request: Request,
    x_ai_mode: Optional[str] = Header(None),
    x_thread_id: Optional[str] = Header(None),
    x_request_id: Optional[str] = Header(None),
    x_user_tenant_id: Optional[str] = Header(None),
    x_user_id: Optional[str] = Header(None),
    x_user_firebase_uid: Optional[str] = Header(None),
):
    """
    Generate AI Efficiency Plan via Multi-Agent LangGraph Workflow.
    
    This endpoint mirrors the Express POST /api/v1/ai/generate-plan route.
    The Node.js controller forwards all relevant context via headers.
    """
    requested_mode = "unspecified"
    execution_path = "unknown"
    run_id = None
    thread_id = None
    start_time = time.time()

    try:
        # Parse the raw JSON body
        user_data = await request.json()

        if not user_data or len(user_data) == 0:
            raise ApiError(
                400,
                "No user data provided. Send appliances, bill, and context.",
            )

        # ── 1. Resolve orchestration mode ──────────────────────────────
        headers = dict(request.headers)
        body_dict = user_data if isinstance(user_data, dict) else {}
        query_dict = dict(request.query_params)

        mode_result = resolve_orchestration_mode(
            body=body_dict,
            query=query_dict,
            headers=headers,
        )
        requested_mode = mode_result["requestedMode"]
        execution_path = mode_result["executionPath"]

        selected_app = (
            collaborative_plan_app
            if execution_path == "collaborative"
            else efficiency_plan_app
        )

        # ── 2. Fetch weather ───────────────────────────────────────────
        user_location = "India"
        if isinstance(user_data.get("user"), dict):
            user_location = user_data["user"].get("location", "India")

        weather_context = await _fetch_weather(user_location)

        # ── 3. Extract identity from forwarded headers ─────────────────
        request_id = x_request_id or str(int(time.time() * 1000))
        run_id = user_data.get("runId") or f"run-{request_id}"
        thread_id = x_thread_id or user_data.get("threadId") or request_id

        tenant_id = (
            x_user_tenant_id
            or (user_data.get("user", {}) or {}).get("tenantId")
            or x_user_firebase_uid
            or x_user_id
        )
        memory_user_id = (
            x_user_id
            or (user_data.get("user", {}) or {}).get("id")
            or (user_data.get("user", {}) or {}).get("userId")
        )

        if execution_path == "collaborative":
            if not tenant_id or not memory_user_id or not thread_id:
                raise ApiError(
                    400,
                    "Missing required memory identity keys for collaborative mode: "
                    "tenantId, userId, threadId",
                )

        _log_agentic_plan("start", {
            "requestId": request_id,
            "userId": memory_user_id,
            "tenantId": tenant_id,
            "requestedMode": requested_mode,
            "executionPath": execution_path,
            "runId": run_id,
            "threadId": thread_id,
            "hasWeatherContext": bool(weather_context),
            "applianceCount": (
                len(user_data["appliances"])
                if isinstance(user_data.get("appliances"), list)
                else 0
            ),
        })

        # ── 4. Invoke LangGraph workflow ───────────────────────────────
        initial_state: dict[str, Any] = {
            "userData": user_data,
            "weatherContext": weather_context,
        }

        if execution_path == "collaborative":
            initial_state["memoryMeta"] = {
                "tenantId": tenant_id,
                "userId": memory_user_id,
                "threadId": thread_id,
                "runId": run_id,
                "requestId": request_id,
                "query": user_data.get("query", ""),
            }

        result_state = await selected_app.invoke(initial_state)
        plan = result_state.get("finalPlan")

        if not plan:
            raise ApiError(
                500,
                "Failed to generate AI plan via multi-agent workflow",
            )

        # ── 5. Build response envelope ─────────────────────────────────
        consensus_log = result_state.get("consensusLog", [])
        consensus_rationale = []
        if isinstance(consensus_log, list):
            for entry in consensus_log:
                votes = entry.get("votes", [])
                consensus_rationale.append({
                    "round": entry.get("round"),
                    "qualityScore": entry.get("qualityScore"),
                    "unresolvedIssues": entry.get("unresolvedIssues"),
                    "unresolvedChallenges": entry.get("unresolvedChallenges"),
                    "votes": [
                        {
                            "role": v.get("role"),
                            "stance": v.get("stance"),
                            "confidence": v.get("confidence"),
                            "rationale": v.get("rationale"),
                        }
                        for v in (votes if isinstance(votes, list) else [])
                    ],
                })

        validation_issues = result_state.get("validationIssues", [])
        cross_agent_challenges = result_state.get("crossAgentChallenges", [])

        response_envelope = build_plan_response_envelope(
            final_plan=plan,
            requested_mode=requested_mode,
            execution_path=execution_path,
            request_id=request_id,
            run_id=result_state.get("runId") or run_id,
            thread_id=result_state.get("threadId") or thread_id,
            quality_score=result_state.get("qualityScore"),
            debate_rounds=result_state.get("debateRounds"),
            revision_count=result_state.get("revisionCount"),
            validation_issue_count=(
                len(validation_issues) if isinstance(validation_issues, list) else None
            ),
            challenge_count=(
                len(cross_agent_challenges) if isinstance(cross_agent_challenges, list) else None
            ),
            role_retry_budgets=result_state.get("roleRetryBudgets"),
            quality_gate=result_state.get("qualityGate"),
            consensus_round_count=(
                len(consensus_log)
                if isinstance(consensus_log, list)
                else result_state.get("debateRounds")
            ),
            consensus_rationale=consensus_rationale,
            safe_fallback_activated=bool(result_state.get("safeFallbackActivated")),
            consensus_decision=result_state.get("consensusDecision"),
            unresolved_route=result_state.get("unresolvedRoute"),
            degradation_events=result_state.get("degradationEvents"),
        )

        metadata = response_envelope.get("metadata", {})
        _log_agentic_plan("complete", {
            "requestId": request_id,
            "runId": (metadata.get("memoryTrace") or {}).get("runId") or run_id,
            "threadId": (metadata.get("memoryTrace") or {}).get("threadId") or thread_id,
            "requestedMode": metadata.get("requestedMode", requested_mode),
            "executionPath": metadata.get("executionPath", execution_path),
            "durationMs": round((time.time() - start_time) * 1000),
            "qualityScore": metadata.get("qualityScore"),
            "debateRounds": metadata.get("debateRounds"),
            "phase4": metadata.get("phase4"),
            "phase5": metadata.get("phase5"),
            "phase6": metadata.get("phase6"),
        })

        return PlanResponse(
            success=True,
            message="Plan generated successfully.",
            data=response_envelope,
        )

    except ApiError:
        raise
    except HTTPException:
        raise
    except Exception as error:
        _log_agentic_plan("error", {
            "requestId": x_request_id,
            "runId": run_id,
            "threadId": thread_id,
            "requestedMode": requested_mode,
            "executionPath": execution_path,
            "durationMs": round((time.time() - start_time) * 1000),
            "message": str(error),
        })
        logger.error(f"AI Plan Generation Error: {error}")
        raise HTTPException(status_code=500, detail=str(error))


# ── Bill Decoder Endpoint ─────────────────────────────────────────────
@app.post("/decode-bill", response_model=BillDecodeResponse)
async def decode_bill(
    request: Request,
    x_user_id: Optional[str] = Header(None),
):
    """
    Decode an OCR-scanned electricity bill via the Bill Decoder multi-agent workflow.

    Expected body:
      {
        "rawBillText": "...",         // OCR text from Flutter (optional if imageBase64 set)
        "imageBase64": "...",         // Base64 image (optional)
        "existingBillData": { ... }   // Pre-filled fields from frontend (optional)
      }
    """
    start_time = time.time()
    try:
        body = await request.json()
        if not body:
            raise HTTPException(status_code=400, detail="Empty request body.")

        initial_state: dict[str, Any] = {
            "rawBillText": body.get("rawBillText"),
            "imageBase64": body.get("imageBase64"),
            "existingBillData": body.get("existingBillData", {}),
        }

        result = await bill_decoder_app.invoke(initial_state)
        final_bill = result.get("finalBillData")

        if not final_bill:
            raise HTTPException(status_code=500, detail="Bill decoding produced no output.")

        return BillDecodeResponse(
            success=True,
            message="Bill decoded successfully.",
            data={
                "bill": final_bill,
                "ocrConfidence": result.get("ocrConfidence", 0.0),
                "requiresUserVerification": result.get("requiresUserVerification", True),
                "validationIssues": result.get("validationIssues", []),
                "durationMs": round((time.time() - start_time) * 1000),
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        logger.error(f"Bill Decoder Error: {error}")
        raise HTTPException(status_code=500, detail=str(error))


# ── Upgrade Advisor Endpoint ──────────────────────────────────────────
@app.post("/upgrade-advice", response_model=UpgradeResponse)
async def upgrade_advice(
    request: Request,
    x_user_id: Optional[str] = Header(None),
):
    """
    Generate appliance upgrade recommendations via the Upgrade Advisor multi-agent workflow.

    Expected body:
      {
        "appliances": [ ...user appliance objects... ],
        "bills": [ ...past bill objects... ],
        "user": { "location": "Mumbai" }   // optional, for weather fetch
      }
    """
    start_time = time.time()
    try:
        body = await request.json()
        if not body:
            raise HTTPException(status_code=400, detail="Empty request body.")

        # Fetch weather for upgrade context
        user_location = "India"
        if isinstance(body.get("user"), dict):
            user_location = body["user"].get("location", "India")
        weather_context = await _fetch_weather(user_location)

        initial_state: dict[str, Any] = {
            "appliances": body.get("appliances", []),
            "bills": body.get("bills", []),
            "weatherContext": weather_context,
        }

        result = await upgrade_advisor_app.invoke(initial_state)
        recommendations = result.get("upgradeRecommendations")

        if not recommendations:
            raise HTTPException(
                status_code=500, detail="Upgrade advisor produced no recommendations."
            )

        return UpgradeResponse(
            success=True,
            message="Upgrade recommendations generated.",
            data={
                "recommendations": recommendations,
                "weatherContext": weather_context,
                "durationMs": round((time.time() - start_time) * 1000),
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        logger.error(f"Upgrade Advisor Error: {error}")
        raise HTTPException(status_code=500, detail=str(error))


# ── Main ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("LANGGRAPH_PORT", "8000"))
    uvicorn.run(
        "src.agents.efficiency_plan.app:app",
        host="0.0.0.0",
        port=port,
        reload=True,
    )

