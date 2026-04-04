"""
Semantic memory integration using Pinecone and Gemini embeddings.
"""

import json
import logging
import os
from typing import Any

logger = logging.getLogger("wattwise.agents.memory.semantic")

_pc = None
_index = None
_embeddings = None


def init_pinecone() -> None:
    global _pc, _index, _embeddings
    api_key = os.environ.get("PINECONE_API_KEY")
    if not api_key:
        return

    try:
        from pinecone import Pinecone
        from langchain_google_genai import GoogleGenerativeAIEmbeddings
        
        _pc = Pinecone(api_key=api_key)
        _index = _pc.Index(os.environ.get("PINECONE_INDEX_NAME", "wattwise-memory"))
        _embeddings = GoogleGenerativeAIEmbeddings(
            model="models/embedding-001",
            google_api_key=os.environ.get("GEMINI_API_KEY", "dummy")
        )
        logger.info("Pinecone semantic memory initialized.")
    except Exception as exc:
        logger.error(f"Failed to initialize Pinecone: {exc}")


async def embed_and_store(identity: dict, event: dict) -> None:
    if not _index or not _embeddings:
        return
    try:
        import asyncio
        
        text = json.dumps(event.get("payload", {}), default=str)
        if not text or text == "{}":
            return
            
        vector = await _embeddings.aembed_query(text)
        
        namespace = f"{identity.get('tenantId', 'default')}:{identity.get('userId', 'default')}"
        event_id = event.get("revisionId", "anon-event")
        
        # Pinecone upsert is synchronous by default unless using async client. 
        # For simplicity and standard client compatibility, we will run it in a thread.
        def _upsert():
            _index.upsert(
                vectors=[{
                    "id": event_id,
                    "values": vector,
                    "metadata": {
                        "threadId": str(identity.get("threadId")),
                        "timestamp": str(event.get("timestamp")),
                        "text": text,
                        "eventType": str(event.get("eventType"))
                    }
                }],
                namespace=namespace
            )
            
        await asyncio.to_thread(_upsert)
    except Exception as exc:
        logger.error(f"Pinecone store error: {exc}")


async def semantic_search(identity: dict, query: str, top_k: int = 5) -> list[dict]:
    if not _index or not _embeddings or not query:
        return []
    try:
        import asyncio
        vector = await _embeddings.aembed_query(query)
        namespace = f"{identity.get('tenantId', 'default')}:{identity.get('userId', 'default')}"
        
        def _query():
            return _index.query(
                namespace=namespace,
                vector=vector,
                top_k=top_k,
                include_metadata=True
            )
            
        results = await asyncio.to_thread(_query)
        
        out = []
        for match in results.matches:
            # Reconstruct an event-like dictionary
            try:
                payload = json.loads(match.metadata.get("text", "{}"))
            except Exception:
                payload = {}
                
            out.append({
                "revisionId": match.id,
                "score": match.score,
                "threadId": match.metadata.get("threadId"),
                "timestamp": match.metadata.get("timestamp"),
                "eventType": match.metadata.get("eventType"),
                "payload": payload,
            })
            
        return out
    except Exception as exc:
        logger.error(f"Pinecone search error: {exc}")
        return []

# Initialize immediately if env vars hit
init_pinecone()
