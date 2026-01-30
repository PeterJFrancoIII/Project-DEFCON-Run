import google.generativeai as genai
import json
import os
from typing import Optional
from ..atlas_schema import (
    AtlasPacket, ProcessingStatus, RiskDomain
)
from ..db_utils import get_db_handle

# --- LOAD API KEY (Replicating views.py logic) ---
try:
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    INPUTS_DIR = os.path.join(BASE_DIR, 'Developer Inputs')
    import sys
    if INPUTS_DIR not in sys.path:
        sys.path.append(INPUTS_DIR)
    import api_config
    genai.configure(api_key=api_config.GEMINI_API_KEY)
except:
    # Fallback to env
    genai.configure(api_key=os.environ.get('GEMINI_API_KEY', ''))

class Gate2Base:
    """
    Gate 2 Base: Classify & Score
    Agent: Classification Agent
    Model: Gemini 2.5 Flash Lite (Fast, Low Cost)
    """

    def __init__(self):
        try:
             self.model = genai.GenerativeModel("models/gemini-2.5-flash-lite")
        except:
             self.model = genai.GenerativeModel("gemini-1.5-flash-8b") # Fallback

    def process_packet(self, packet: AtlasPacket) -> AtlasPacket:
        """
        Analyzes the packet payload to determine Region, Domain, and Validity Score.
        Updates triage metadata and routing status.
        """
        
        prompt = f"""
        ACT AS: Intelligence Officer (Gate 2 Screener)
        TASK: Analyze this raw OSINT packet.
        
        INPUT:
        Title: {packet.payload.title}
        Text: {packet.payload.raw_text[:500]}... (Truncated)
        Source Tier: {packet.source.source_tier}
        
        REQUIREMENTS:
        1. Classify Risk Domain (KINETIC, POLITICAL, CIVIL_UNREST, etc).
        2. Identify Broad Target Region (e.g. SE_ASIA, EAST_EUROPE).
        3. Score Validity (0-100). 
           - 100 = Confirmed by Trusted Source (Tier 1).
           - 50 = Plausible but needs verification.
           - 0 = Irrelevant / Spam / Ad.
           
        OUTPUT JSON ONLY:
        {{
            "risk_domain": "ENUM_VALUE",
            "target_region": "STRING",
            "validity_score": INTEGER
        }}
        """
        
        try:
            resp = self.model.generate_content(prompt)
            data = json.loads(resp.text.replace('```json', '').replace('```', '').strip())
            
            # --- UPDATE PACKET ---
            packet.triage.validity_score = data.get('validity_score', 0)
            packet.triage.target_region = data.get('target_region', 'UNKNOWN')
            
            # Map Domain
            domain_str = data.get('risk_domain', 'UNCLASSIFIED')
            try:
                packet.triage.risk_domain = RiskDomain(domain_str)
            except:
                packet.triage.risk_domain = RiskDomain.UNCLASSIFIED
                
            # --- ROUTING LOGIC ---
            score = packet.triage.validity_score
            
            packet.triage.add_history(f"GATE2_BASE_SCORE:{score}")
            
            if score > 66:
                packet.triage.processing_status = ProcessingStatus.CLEAN
                packet.triage.add_history("GATE2_BASE_ADMIT")
            elif score >= 33:
                packet.triage.processing_status = ProcessingStatus.PENDING_REINFORCED
                packet.triage.add_history("GATE2_BASE_MAYBE")
            else:
                packet.triage.processing_status = ProcessingStatus.DROP
                packet.triage.add_history("GATE2_BASE_DROP")
                
        except Exception as e:
            print(f"[GATE 2 BASE] AI Error: {e}")
            # Fail Safe -> Drop or Manual Review? Defaulting to DROP for safety in auto-pilot
            packet.triage.processing_status = ProcessingStatus.DROP
            packet.triage.add_history(f"GATE2_BASE_ERROR:{str(e)}")
            
        return packet
