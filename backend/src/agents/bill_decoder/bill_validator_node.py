"""
Bill Validator Node — Node 2 of Bill Decoder workflow.

Uses GPT-4o-mini (via OpenRouter) to cross-check extracted fields,
detect anomalies (e.g. units/amount mismatch, suspicious dates),
and flag fields that need user verification.
"""

import json
import logging
import math
import os
import re
from datetime import datetime
from typing import Any

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

logger = logging.getLogger("wattwise.agents.bill_decoder.bill_validator")

# ── LLM (GPT-4o-mini via OpenRouter) ─────────────────────────────────
llm = ChatOpenAI(
    model="openai/gpt-4o-mini",
    api_key=os.environ.get("OPENROUTER_API_KEY", "dummy"),
    base_url="https://openrouter.ai/api/v1",
    temperature=0.0,  # Deterministic — we want consistent validation
)

SYSTEM_PROMPT = SystemMessage(content=(
    "You are a meticulous Electricity Bill Validator specialising in Indian discom bills.\n"
    "You receive extracted OCR fields and must:\n"
    "1. Cross-check amounts vs units using typical Indian tariff rates (₹4–₹10/unit).\n"
    "2. Validate date logic: periodStart < periodEnd < dueDate.\n"
    "3. Flag any field that looks incorrect or needs user confirmation.\n"
    "4. Correct obvious OCR typos (e.g. 'O' vs '0', extra spaces in numbers).\n"
    "5. Return a 'requiresUserVerification' boolean — true if ANY critical field is suspect.\n\n"
    "RULES:\n"
    "- Return ONLY a strict JSON object.\n"
    "- Do NOT hallucinate values. If you cannot determine the correct value, keep original.\n"
    "- Keep 'validationIssues' as a string array describing each problem found.\n\n"
    "OUTPUT SCHEMA:\n"
    "{\n"
    '  "correctedFields": { ...same shape as input extractedFields... },\n'
    '  "validationIssues": ["issue description 1", ...],\n'
    '  "requiresUserVerification": true/false,\n'
    '  "confidenceAdjustment": -0.1   // how much to add/subtract from ocrConfidence\n'
    "}"
))

# Indian tariff sanity bounds (₹/kWh)
_MIN_RATE = 3.0
_MAX_RATE = 12.0


def _local_validate(fields: dict) -> list[str]:
    """Fast rule-based checks before calling the LLM."""
    issues: list[str] = []

    amount = fields.get("amount")
    units = fields.get("units")

    if amount is not None and units is not None:
        try:
            a, u = float(amount), float(units)
            if u > 0:
                rate = a / u
                if rate < _MIN_RATE:
                    issues.append(
                        f"amount_per_unit:{rate:.2f} ₹/kWh is below expected minimum {_MIN_RATE}"
                    )
                elif rate > _MAX_RATE:
                    issues.append(
                        f"amount_per_unit:{rate:.2f} ₹/kWh exceeds expected maximum {_MAX_RATE}"
                    )
        except (TypeError, ValueError, ZeroDivisionError):
            issues.append("amount_or_units:invalid_numeric_value")

    # Date ordering
    try:
        ps = fields.get("periodStart")
        pe = fields.get("periodEnd")
        dd = fields.get("dueDate")
        if ps and pe:
            if datetime.fromisoformat(ps) >= datetime.fromisoformat(pe):
                issues.append("dates:periodStart_not_before_periodEnd")
        if pe and dd:
            if datetime.fromisoformat(pe) >= datetime.fromisoformat(dd):
                issues.append("dates:periodEnd_not_before_dueDate")
    except (ValueError, TypeError):
        pass  # Date format issues will be caught by LLM

    return issues


async def run_bill_validator(state: dict[str, Any]) -> dict[str, Any]:
    """Validate and correct extracted OCR bill fields."""
    logger.info("--> [BillDecoder] Bill Validator Node Executing")

    extracted = state.get("extractedFields") or {}
    ocr_confidence = float(state.get("ocrConfidence", 0.7))
    prior_issues = list(state.get("validationIssues") or [])

    if not extracted:
        logger.warning("[BillDecoder] Validator: No extracted fields to validate.")
        return {
            "validatedBill": {},
            "validationIssues": [*prior_issues, "validator:no_extracted_fields"],
            "requiresUserVerification": True,
        }

    # Fast local checks first
    local_issues = _local_validate(extracted)

    try:
        if not os.environ.get("OPENROUTER_API_KEY"):
            logger.info("--> [BillDecoder] Validator: mock fallback (no OPENROUTER_API_KEY).")
            return _mock_validated_bill(extracted, local_issues, prior_issues, ocr_confidence)

        user_message = HumanMessage(
            content=(
                f"Validate these extracted bill fields:\n"
                f"{json.dumps(extracted, indent=2, default=str)}\n\n"
                f"Local validation pre-checks found these issues:\n"
                f"{json.dumps(local_issues)}"
            )
        )
        response = await llm.ainvoke([SYSTEM_PROMPT, user_message])

        raw_json = re.sub(r"```(?:json)?\n?", "", response.content).strip()
        result = json.loads(raw_json)

        corrected = result.get("correctedFields", extracted)
        llm_issues = result.get("validationIssues", [])
        adj = float(result.get("confidenceAdjustment", 0.0))
        final_confidence = max(0.0, min(1.0, ocr_confidence + adj))
        requires_verify = bool(result.get("requiresUserVerification", len(llm_issues) > 0))

        all_issues = list({*prior_issues, *local_issues, *llm_issues})

        logger.info(
            f"--> [BillDecoder] Validator done. Issues={len(all_issues)}, "
            f"requiresVerification={requires_verify}"
        )

        return {
            "validatedBill": corrected,
            "validationIssues": all_issues,
            "ocrConfidence": final_confidence,
            "requiresUserVerification": requires_verify,
        }

    except Exception as exc:
        logger.error(f"[BillDecoder] Validator Error: {exc}")
        return _mock_validated_bill(extracted, local_issues, prior_issues, ocr_confidence)


def _mock_validated_bill(
    extracted: dict,
    local_issues: list,
    prior_issues: list,
    confidence: float,
) -> dict:
    all_issues = list({*prior_issues, *local_issues})
    return {
        "validatedBill": extracted,
        "validationIssues": all_issues,
        "ocrConfidence": confidence,
        "requiresUserVerification": len(all_issues) > 0,
    }
