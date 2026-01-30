import time
import uuid
import hashlib
from typing import List, Optional, Any
from ..atlas_schema import (
    AtlasPacket, IdentityParameters, SourceContext, 
    ContentPayload, TriageMetadata, SourceTier, 
    IngestMethod, ProcessingStatus
)
from ..db_utils import get_db_handle

# Get DB Connection
db = get_db_handle()
news_index = db['news_index']
raw_db = db['raw_news_db']

class Gate1Ingest:
    """
    Gate 1: Ingest, Filter, Dedup
    Objective: maximize capture, strict dedup, strict schema enforcement.
    """
    
    def __init__(self, mode="LIVE"):
        self.mode = mode

    def process_packet(
        self, 
        raw_input: Any, 
        source_id: str, 
        source_tier: SourceTier,
        ingest_method: IngestMethod
    ) -> Optional[AtlasPacket]:
        """
        Ingests a single raw item, standardizes it, checks duplications, 
        and returns an AtlasPacket or None if dropped.
        """
        
        # 1. Normalize Input (Assumes Dict for now, extendable)
        title = raw_input.get("title", "Unknown Title")
        url = raw_input.get("link", "") or raw_input.get("url", "")
        published_at = raw_input.get("published_parsed", None)
        
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
            
        # 4. Construct Packet
        packet = AtlasPacket(
            identity=IdentityParameters(
                artifact_id=str(uuid.uuid4()),
                content_hash=content_hash,
                canonical_url=url, # In production, resolve shortlinks here
                source_published_at=published_at
            ),
            source=SourceContext(
                source_id=source_id,
                source_tier=source_tier,
                ingest_method=ingest_method
            ),
            payload=ContentPayload(
                title=title,
                raw_text=title, # For RSS, often just title/summary. Scraper would go deeper.
                language_code="en" # Default, would run detection here
            ),
            triage=TriageMetadata(
                processing_status=ProcessingStatus.RAW
            )
        )
        
        packet.triage.add_history("GATE1_PASS")
        
        # 5. Persist to Raw DB
        self._persist_to_raw(packet)
        self._update_index(packet)
        
        return packet
        
    def _persist_to_raw(self, packet: AtlasPacket):
        """Saves the full packet to the Raw News DB."""
        raw_db.insert_one(packet.dict())
        
    def _update_index(self, packet: AtlasPacket):
        """Updates the simplified index for fast dedup lookups."""
        news_index.insert_one({
            "content_hash": packet.identity.content_hash,
            "url": packet.identity.canonical_url,
            "ingested_at": packet.identity.ingest_timestamp
        })
    
