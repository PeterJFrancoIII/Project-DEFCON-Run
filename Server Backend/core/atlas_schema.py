from pydantic import BaseModel, Field, validator
from typing import List, Optional
from enum import Enum
import time
import hashlib

# --- ENUMS ---

class SourceTier(int, Enum):
    OFFICIAL = 1
    TRUSTED_MEDIA = 2
    LOCAL_MEDIA = 3
    SOCIAL_VERIFIED = 4
    ANONYMOUS = 5

class IngestMethod(str, Enum):
    RSS = "RSS"
    API = "API"
    SCRAPE = "SCRAPE"
    MANUAL = "MANUAL"

class ProcessingStatus(str, Enum):
    RAW = "RAW"
    PENDING_REINFORCED = "PENDING_REINFORCED"
    CLEAN = "CLEAN"
    DROP = "DROP"

class RiskDomain(str, Enum):
    KINETIC = "KINETIC"
    POLITICAL = "POLITICAL"
    INFRASTRUCTURE = "INFRASTRUCTURE"
    LOGISTICS = "LOGISTICS"
    CIVIL_UNREST = "CIVIL_UNREST"
    NOISE = "NOISE"
    UNCLASSIFIED = "UNCLASSIFIED"

# --- DATA CLASSES ---

class IdentityParameters(BaseModel):
    artifact_id: str = Field(..., description="Unique UUID for this ingestion event")
    content_hash: str = Field(..., description="MD5 hash of normalized text for dedup")
    canonical_url: str = Field(..., description="Resolved URL after redirects")
    ingest_timestamp: float = Field(default_factory=time.time, description="Unix timestamp of ingestion")
    source_published_at: Optional[float] = Field(None, description="Unix timestamp claimed by source")

    @staticmethod
    def generate_hash(text: str) -> str:
        return hashlib.md5(text.encode('utf-8')).hexdigest()

class SourceContext(BaseModel):
    source_id: str = Field(..., description="Internal reference ID for origin")
    source_tier: SourceTier = Field(..., description="Reliability 1-5")
    ingest_method: IngestMethod = Field(..., description="Acquisition method")

class ContentPayload(BaseModel):
    title: str = Field(..., description="Headline or first 50-100 chars")
    raw_text: str = Field(..., description="Full body text with ads stripped")
    language_code: str = Field("en", description="ISO 639-1 language code")
    is_translated: bool = Field(False, description="True if text is a translation")

class TriageMetadata(BaseModel):
    processing_status: ProcessingStatus = Field(ProcessingStatus.RAW, description="Current pipeline state")
    validity_score: int = Field(0, description="Confidence score 0-100")
    risk_domain: RiskDomain = Field(RiskDomain.UNCLASSIFIED, description="Primary threat category")
    target_region: str = Field("UNKNOWN", description="Broad geographical focus")
    gate_history: List[str] = Field(default_factory=list, description="Append-only log of gates passed")

    def add_history(self, entry: str):
        self.gate_history.append(entry)

class AtlasPacket(BaseModel):
    """
    The Container Object that flows through the pipeline.
    """
    identity: IdentityParameters
    source: SourceContext
    payload: ContentPayload
    triage: TriageMetadata
