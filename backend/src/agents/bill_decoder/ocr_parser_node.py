"""
OCR Parser Node — Node 1 of Bill Decoder workflow.

Uses Gemini Vision (gemini-2.0-flash) to extract structured bill fields
from raw OCR text and/or base64 image. This is the first agent in the pipeline.
"""

import json
import logging
import os
import re
from typing import Any

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage

logger = logging.getLogger("wattwise.agents.bill_decoder.ocr_parser")

# ── LLM (Gemini 2.0 Flash with vision support) ────────────────────────
llm = ChatGoogleGenerativeAI(
    model="gemini-2.0-flash",
    google_api_key=os.environ.get("GEMINI_API_KEY", "dummy"),
    temperature=0.1,   # Low temp for deterministic field extraction
)

SYSTEM_PROMPT = SystemMessage(content=(
    "You are an expert OCR Post-Processor and Electricity Bill Parser for the Indian market.\n"
    "Your SOLE job is to extract structured data from electricity bill text or images.\n\n"
    "RULES:\n"
    "1. Extract ALL fields you can find. If a field is missing, use null.\n"
    "2. Normalize dates to ISO 8601 format (YYYY-MM-DD).\n"
    "3. All monetary amounts must be numbers (no currency symbols).\n"
    "4. Units consumed must be a number (kWh).\n"
    "5. Return ONLY a strict JSON object — no markdown, no explanation.\n"
    "6. Set 'ocrConfidence' (0.0–1.0) based on how confidently you could read the bill.\n"
    "   - 0.9+ : all key fields clearly readable\n"
    "   - 0.7–0.89 : some fields unclear but recoverable\n"
    "   - <0.7 : major fields missing or ambiguous\n\n"
    "OUTPUT SCHEMA:\n"
    "{\n"
    '  "billNumber": "string or null",\n'
    '  "consumerNumber": "string or null",\n'
    '  "billerId": "string or null",\n'
    '  "amount": number_or_null,\n'
    '  "grossAmount": number_or_null,\n'
    '  "subsidy": number_or_null,\n'
    '  "units": number_or_null,\n'
    '  "periodStart": "YYYY-MM-DD or null",\n'
    '  "periodEnd": "YYYY-MM-DD or null",\n'
    '  "dueDate": "YYYY-MM-DD or null",\n'
    '  "utilityName": "string or null",\n'
    '  "consumerName": "string or null",\n'
    '  "meterNumber": "string or null",\n'
    '  "tariffCategory": "string or null",\n'
    '  "sanctionedLoad": "string or null",\n'
    '  "ocrConfidence": 0.0\n'
    "}"
))


async def run_ocr_parser(state: dict[str, Any]) -> dict[str, Any]:
    """Extract structured fields from raw bill OCR text and/or image."""
    logger.info("--> [BillDecoder] OCR Parser Node Executing")

    raw_text = state.get("rawBillText", "")
    image_b64 = state.get("imageBase64")
    existing = state.get("existingBillData") or {}

    if not raw_text and not image_b64:
        logger.warning("[BillDecoder] OCR Parser: No bill text or image provided.")
        return {
            "extractedFields": existing,
            "ocrConfidence": 0.0,
            "validationIssues": ["ocr_parser:no_input:rawBillText and imageBase64 both missing"],
        }

    try:
        if not os.environ.get("GEMINI_API_KEY"):
            logger.info("--> [BillDecoder] OCR Parser: mock fallback (no GEMINI_API_KEY).")
            return _mock_extracted_fields(existing)

        # Build user message — support text and optional image
        content_parts: list[Any] = []

        if raw_text:
            content_parts.append({
                "type": "text",
                "text": (
                    f"Extract all bill fields from this OCR text:\n\n{raw_text}\n\n"
                    "Also merge any pre-filled fields below if the OCR text doesn't override them:\n"
                    f"{json.dumps(existing, indent=2, default=str)}"
                ),
            })
        elif existing:
            content_parts.append({
                "type": "text",
                "text": (
                    "Extract bill fields from the image and merge with pre-filled data:\n"
                    f"{json.dumps(existing, indent=2, default=str)}"
                ),
            })

        if image_b64:
            # Gemini vision: inline base64 image
            content_parts.append({
                "type": "image_url",
                "image_url": {"url": f"data:image/jpeg;base64,{image_b64}"},
            })

        user_message = HumanMessage(content=content_parts)
        response = await llm.ainvoke([SYSTEM_PROMPT, user_message])

        raw_json = re.sub(r"```(?:json)?\n?", "", response.content).strip()
        extracted = json.loads(raw_json)

        confidence = float(extracted.get("ocrConfidence", 0.7))
        logger.info(f"--> [BillDecoder] OCR Parser done. Confidence={confidence}")

        return {
            "extractedFields": extracted,
            "ocrConfidence": confidence,
        }

    except Exception as exc:
        logger.error(f"[BillDecoder] OCR Parser Error: {exc}")
        return _mock_extracted_fields(existing)


def _mock_extracted_fields(existing: dict) -> dict:
    """Return a mock extraction for development / fallback."""
    return {
        "extractedFields": {
            "billNumber": existing.get("billNumber", "MOCK-BILL-2024"),
            "consumerNumber": existing.get("consumerNumber", "MOCK-9876543210"),
            "billerId": existing.get("billerId"),
            "amount": existing.get("amount", 1850.00),
            "grossAmount": existing.get("grossAmount", 1950.00),
            "subsidy": existing.get("subsidy", 100.00),
            "units": existing.get("units", 320),
            "periodStart": existing.get("periodStart", "2024-02-01"),
            "periodEnd": existing.get("periodEnd", "2024-03-01"),
            "dueDate": existing.get("dueDate", "2024-03-20"),
            "utilityName": existing.get("utilityName", "Maharashtra State Electricity Distribution Co."),
            "consumerName": existing.get("consumerName"),
            "meterNumber": existing.get("meterNumber"),
            "tariffCategory": existing.get("tariffCategory", "LT-I Residential"),
            "sanctionedLoad": existing.get("sanctionedLoad", "5 kW"),
            "ocrConfidence": 0.72,
        },
        "ocrConfidence": 0.72,
    }
