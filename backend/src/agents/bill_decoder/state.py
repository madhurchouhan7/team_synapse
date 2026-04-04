"""
State schema for the Bill Decoder multi-agent workflow.
"""

from typing import Any, Optional
from typing_extensions import TypedDict


class BillDecoderState(TypedDict, total=False):
    """State object passed between LangGraph nodes in the Bill Decoder graph."""

    # Raw input from the Flutter app (OCR text + image base64 + existing bill data)
    rawBillText: Optional[str]             # OCR-extracted raw text from bill scan
    imageBase64: Optional[str]             # Base64-encoded bill image (for vision model)
    existingBillData: Optional[dict[str, Any]]  # Partially filled bill data from frontend

    # Intermediate outputs
    extractedFields: Optional[dict[str, Any]]  # Fields extracted by OCR parser node
    validatedBill: Optional[dict[str, Any]]    # Validated and corrected bill by validator node

    # Final output
    finalBillData: Optional[dict[str, Any]]    # Flutter-ready bill JSON
    validationIssues: list[str]                # List of validation warnings/errors
    ocrConfidence: float                       # Overall OCR confidence score (0–1)
    requiresUserVerification: bool             # True if human review is recommended
