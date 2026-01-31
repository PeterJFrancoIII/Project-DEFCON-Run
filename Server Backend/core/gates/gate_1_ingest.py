import time
import uuid
import hashlib
import json
import os
import google.generativeai as genai
from typing import List, Optional, Any
from ..atlas_schema import (
    AtlasPacket, IdentityParameters, SourceContext, 
    ContentPayload, TriageMetadata, SourceTier, 
    IngestMethod, ProcessingStatus
)
from ..db_utils import get_db_handle

# --- LOAD API KEY ---
try:
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    INPUTS_DIR = os.path.join(BASE_DIR, 'Developer Inputs')
    import sys
    if INPUTS_DIR not in sys.path:
        sys.path.append(INPUTS_DIR)
    import api_config
    genai.configure(api_key=api_config.GATE_1_KEY)
except:
    # Fallback to env
    genai.configure(api_key=os.environ.get('GATE_1_KEY', ''))

# Get DB Connection
db = get_db_handle()
news_index = db['news_index']
raw_db = db['raw_news_db']

class Gate1Ingest:
    """
    Gate 1: Ingest, Filter, Dedup
    Model: Gemini 2.5 Flash Lite
    Objective: maximize capture, strict dedup, AI-powered relevance filtering.
    """
    
    def __init__(self, mode="LIVE"):
        self.mode = mode
        try:
            self.model = genai.GenerativeModel("models/gemini-2.5-flash-lite")
        except:
            self.model = genai.GenerativeModel("gemini-1.5-flash-8b")  # Fallback

    def process_packet(
        self, 
        raw_input: Any, 
        source_id: str, 
        source_tier: SourceTier,
        ingest_method: IngestMethod,
        source_validity: int = 75  # Developer-configured validity score from CSV
    ) -> Optional[AtlasPacket]:
        """
        Ingests a single raw item, filters via AI, checks duplications, 
        and returns an AtlasPacket or None if dropped.
        """
        
        # 1. Normalize Input (Assumes Dict for now, extendable)
        title = raw_input.get("title", "Unknown Title")
        url = raw_input.get("link", "") or raw_input.get("url", "")
        summary = raw_input.get("summary", "") or raw_input.get("description", "")
        published_at = raw_input.get("published_parsed", None)
        source_name = raw_input.get("source", source_id)  # Track source name
        
        if published_at:
            # Convert struct_time to float if needed
            try:
                published_at = time.mktime(published_at)
            except:
                published_at = time.time()
        
        # 2. Generate Content Hash (Title + URL) for Dedup
        normalized_str = f"{title.strip().lower()}|{url.strip()}"
        content_hash = IdentityParameters.generate_hash(normalized_str)
        
        # 3. Drift Detection (Dedup Check)
        if news_index.find_one({"content_hash": content_hash}):
            # Duplicate found - DROP
            print(f"[GATE 1] Drop Duplicate: {title[:30]}...")
            return None
        
        # 4. AI-Powered Relevance Filter (Keywords, Sentiment, Heuristics)
        relevance_result = self._check_relevance(title, summary, source_tier)
        
        if not relevance_result.get("is_relevant", False):
            print(f"[GATE 1] Drop Irrelevant: {title[:30]}... Reason: {relevance_result.get('reason', 'N/A')}")
            return None
            
        # 5. Construct Packet with Full Metadata
        packet = AtlasPacket(
            identity=IdentityParameters(
                artifact_id=str(uuid.uuid4()),
                content_hash=content_hash,
                canonical_url=url,
                source_published_at=published_at
            ),
            source=SourceContext(
                source_id=source_name,  # Use source name from CSV
                source_tier=source_tier,
                ingest_method=ingest_method
            ),
            payload=ContentPayload(
                title=title,
                raw_text=summary if summary else title,
                language_code=relevance_result.get("language", "en")
            ),
            triage=TriageMetadata(
                processing_status=ProcessingStatus.RAW,
                validity_score=source_validity  # Initialize with developer-configured score
            )
        )
        
        # Add AI-extracted metadata + source validity
        packet.triage.add_history("GATE1_PASS")
        packet.triage.add_history(f"GATE1_SOURCE_VALIDITY:{source_validity}")
        packet.triage.add_history(f"GATE1_SENTIMENT:{relevance_result.get('sentiment', 'NEUTRAL')}")
        packet.triage.add_history(f"GATE1_KEYWORDS:{','.join(relevance_result.get('keywords', [])[:3])}")
        
        # 6. Persist to Raw DB
        self._persist_to_raw(packet)
        self._update_index(packet)
        
        return packet
    
    def _check_relevance(self, title: str, summary: str, source_tier: SourceTier) -> dict:
        """
        Uses Gemini 2.5 Flash Lite to check relevance via keywords, sentiment, and heuristics.
        Returns dict with is_relevant, reason, sentiment, keywords, language.
        """
        prompt = f"""
        ACT AS: OSINT Intake Filter (Gate 1)
        TASK: Determine if this news item is relevant for geopolitical/security intelligence.
        
        INPUT:
        Title: {title}
        Summary: {summary[:500] if summary else 'N/A'}
        Source Tier: {source_tier}
        
        RELEVANCE CRITERIA:
        - ACCEPT: Military, conflict, political instability, civil unrest, terrorism, major government actions, international relations, sanctions, protests, coups, elections with security implications.
        - REJECT: Entertainment, sports, celebrities, product launches, lifestyle, weather (unless disaster), general business news without security angle.
        
        TASKS:
        1. Determine if relevant (true/false).
        2. If not relevant, provide brief reason.
        3. Extract sentiment (POSITIVE, NEGATIVE, NEUTRAL, ALARMING).
        4. Extract top 3 security-related keywords.
        5. Detect language code (en, ar, ru, zh, etc.).
        
        OUTPUT JSON ONLY:
        {{
            "is_relevant": true | false,
            "reason": "string (only if not relevant)",
            "sentiment": "POSITIVE" | "NEGATIVE" | "NEUTRAL" | "ALARMING",
            "keywords": ["keyword1", "keyword2", "keyword3"],
            "language": "en"
        }}
        """
        
        try:
            resp = self.model.generate_content(prompt)
            data = json.loads(resp.text.replace('```json', '').replace('```', '').strip())
            return data
        except Exception as e:
            print(f"[GATE 1] AI Filter Error: {e}")
            # Fail-open for Tier 1 sources, fail-closed for others
            if source_tier == SourceTier.TIER_1:
                return {"is_relevant": True, "sentiment": "NEUTRAL", "keywords": [], "language": "en"}
            else:
                return {"is_relevant": False, "reason": f"AI error: {str(e)}", "sentiment": "NEUTRAL", "keywords": [], "language": "en"}
        
    def _persist_to_raw(self, packet: AtlasPacket):
        """Saves the full packet to the Raw News DB."""
        raw_db.insert_one(packet.dict())
        
    def _update_index(self, packet: AtlasPacket):
        """Updates the simplified index for fast dedup lookups."""
        news_index.insert_one({
            "content_hash": packet.identity.content_hash,
            "link_hash": hashlib.md5(packet.identity.canonical_url.encode('utf-8')).hexdigest(),
            "url": packet.identity.canonical_url,
            "ingested_at": packet.identity.ingest_timestamp
        })
