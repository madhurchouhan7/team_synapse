"""
WattWise Bill Decoder LangGraph Workflow Definition.

Pipeline:  OCR Parser → Bill Validator → Bill Formatter
- OCR Parser: Gemini Vision extracts structured fields from raw OCR text / image
- Bill Validator: GPT-4o-mini cross-checks amounts, units, dates, and flags issues
- Bill Formatter: Deterministic node maps to MongoDB Bill.model.js schema
"""

from langgraph.graph import StateGraph, START, END

from .state import BillDecoderState
from .ocr_parser_node import run_ocr_parser
from .bill_validator_node import run_bill_validator
from .bill_formatter_node import run_bill_formatter

# 1. Initialise graph
workflow = StateGraph(BillDecoderState)

# 2. Add nodes
workflow.add_node("OcrParser", run_ocr_parser)
workflow.add_node("BillValidator", run_bill_validator)
workflow.add_node("BillFormatter", run_bill_formatter)

# 3. Define sequential pipeline edges
workflow.add_edge(START, "OcrParser")
workflow.add_edge("OcrParser", "BillValidator")
workflow.add_edge("BillValidator", "BillFormatter")
workflow.add_edge("BillFormatter", END)

# 4. Compile
bill_decoder_app = workflow.compile()
