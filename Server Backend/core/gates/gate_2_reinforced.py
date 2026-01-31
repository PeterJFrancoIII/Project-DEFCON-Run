import google.generativeai as genai
import json
import os
from ..atlas_schema import (
    AtlasPacket, ProcessingStatus
)
from ..db_utils import get_db_handle

# --- API KEY ---
try:
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    INPUTS_DIR = os.path.join(BASE_DIR, 'Developer Inputs')
    import sys
    if INPUTS_DIR not in sys.path:
        sys.path.append(INPUTS_DIR)
    import api_config
    genai.configure(api_key=api_config.GATE_2_REINFORCED_KEY)
except:
    genai.configure(api_key=os.environ.get('GATE_2_REINFORCED_KEY', ''))

class Gate2Reinforced:
    """
    Gate 2 Reinforced: Deep Verification
    Agent: Senior Analyst
    Model: Gemini 2.0 Flash (Reasoning Capable)
    Status: Only runs on PENDING_REINFORCED items (33-66 score).
    """

    def __init__(self):
        # Using a stronger model for disambiguation
        try:
             self.model = genai.GenerativeModel("models/gemini-3-flash-preview")
        except:
             self.model = genai.GenerativeModel("models/gemini-2.5-pro")

    def process_packet(self, packet: AtlasPacket) -> AtlasPacket:
        """
        Re-evaluates ambiguous packets with "Chain of Thought" reasoning.
        """
        if packet.triage.processing_status != ProcessingStatus.PENDING_REINFORCED:
            return packet

        prompt = f"""
        ACT AS: Senior Intelligence Analyst (Gate 2 Reinforced)
        TASK: Verify this ambiguous OSINT packet.
        
        CONTEXT:
        The preliminary screener flagged this as "MAYBE" (Score: {packet.triage.validity_score}).
        It might be rumors, propaganda, or misidentified noise.
        
        INPUT:
        Title: {packet.payload.title}
        Text: {packet.payload.raw_text[:1000]}
        Source Tier: {packet.source.source_tier}
        
        INSTRUCTIONS:
        1. Look for corroborating signals or obvious disqualifiers (e.g. gaming news vs war news).
        2. Assign a FINAL Binary Decision: ADMIT or DROP.
        3. Assign a strictly updated score (>50 for ADMIT).
        
        OUTPUT JSON ONLY:
        {{
            "final_decision": "ADMIT" | "DROP",
            "reasoning": "String explanation...",
            "validity_score": INTEGER
        }}
        """
        
        try:
            resp = self.model.generate_content(prompt)
            data = json.loads(resp.text.replace('```json', '').replace('```', '').strip())
            
            new_score = data.get('validity_score', 0)
            decision = data.get('final_decision', 'DROP')
            
            # --- UDPATE PACKET ---
            packet.triage.validity_score = new_score
            packet.triage.add_history(f"GATE2_REINFORCED_SCORE:{new_score}")
            packet.triage.add_history(f"REASON:{data.get('reasoning', 'N/A')[:50]}")
            
            if decision == "ADMIT" and new_score > 50:
                 packet.triage.processing_status = ProcessingStatus.CLEAN
                 packet.triage.add_history("GATE2_REINFORCED_ADMIT")
            else:
                 packet.triage.processing_status = ProcessingStatus.DROP
                 packet.triage.add_history("GATE2_REINFORCED_DROP")
                 
        except Exception as e:
            print(f"[GATE 2 REINFORCED] AI Error: {e}")
            packet.triage.processing_status = ProcessingStatus.DROP
            packet.triage.add_history(f"GATE2_REINFORCED_ERROR:{str(e)}")
            
        return packet
