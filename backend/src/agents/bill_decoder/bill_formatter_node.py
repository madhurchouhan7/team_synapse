"""
Bill Formatter Node — Node 3 (Final) of Bill Decoder workflow.

Assembles the validated bill fields into the exact MongoDB Bill.model.js
schema that the Node.js backend expects, so it can be directly upserted.
No LLM call — this is a pure deterministic transformation node.
"""

import logging
from datetime import datetime, timezone
from typing import Any

logger = logging.getLogger("wattwise.agents.bill_decoder.bill_formatter")


def _safe_float(value: Any, default: float | None = None) -> float | None:
    """Safely coerce a value to float."""
    if value is None:
        return default
    try:
        result = float(value)
        return result if result == result else default  # NaN check
    except (TypeError, ValueError):
        return default


def _safe_date_str(value: Any) -> str | None:
    """Return ISO date string or None."""
    if not value:
        return None
    if isinstance(value, str):
        try:
            datetime.fromisoformat(value)
            return value  # Already valid ISO
        except ValueError:
            return None
    return None


async def run_bill_formatter(state: dict[str, Any]) -> dict[str, Any]:
    """Assemble a Flutter-ready / MongoDB-compatible bill object."""
    logger.info("--> [BillDecoder] Bill Formatter Node Executing")

    validated = state.get("validatedBill") or state.get("extractedFields") or {}
    ocr_confidence = float(state.get("ocrConfidence", 0.7))
    requires_verify = bool(state.get("requiresUserVerification", False))
    issues = list(state.get("validationIssues") or [])

    # Determine source — if image was provided it's 'ocr', else 'manual'
    source = "ocr" if state.get("imageBase64") or state.get("rawBillText") else "manual"

    amount = _safe_float(validated.get("amount"))
    gross_amount = _safe_float(validated.get("grossAmount"))
    subsidy = _safe_float(validated.get("subsidy"), 0.0)
    units = _safe_float(validated.get("units"))
    period_start = _safe_date_str(validated.get("periodStart"))
    period_end = _safe_date_str(validated.get("periodEnd"))
    due_date = _safe_date_str(validated.get("dueDate"))

    # Compute confidence-driven status
    is_verified = ocr_confidence >= 0.85 and not requires_verify

    final_bill: dict[str, Any] = {
        # Core identifiers
        "source": source,
        "status": "UNPAID",
        "isVerified": is_verified,
        "isActive": True,

        # Extracted identifiers
        "billNumber": validated.get("billNumber"),
        "consumerNumber": validated.get("consumerNumber"),
        "billerId": validated.get("billerId"),

        # Financial
        "amount": amount,
        "grossAmount": gross_amount,
        "subsidy": subsidy,

        # Consumption
        "units": units,

        # Dates
        "periodStart": period_start,
        "periodEnd": period_end,
        "dueDate": due_date,

        # OCR metadata
        "ocrConfidence": round(ocr_confidence, 4),
        "rawText": state.get("rawBillText"),

        # Extended enrichment (stored in custom response envelope, not in Bill schema directly)
        "_enrichment": {
            "utilityName": validated.get("utilityName"),
            "consumerName": validated.get("consumerName"),
            "meterNumber": validated.get("meterNumber"),
            "tariffCategory": validated.get("tariffCategory"),
            "sanctionedLoad": validated.get("sanctionedLoad"),
        },
    }

    logger.info(
        f"--> [BillDecoder] Formatter done. "
        f"amount={amount}, units={units}, isVerified={is_verified}"
    )

    return {
        "finalBillData": final_bill,
        "validationIssues": issues,
        "ocrConfidence": ocr_confidence,
        "requiresUserVerification": requires_verify,
    }
