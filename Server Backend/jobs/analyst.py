import os
import json
import logging
import requests
from django.conf import settings
from .db_models import JobsDAO

logger = logging.getLogger(__name__)

class GeminiAnalyst:
    """
    Interface for the Gemini 3 Pro Moderation Analyst.
    Enforces strict JSON output for Sentinel Jobs.
    Uses Direct REST API to avoid global genai namespace conflicts.
    """
    
    MODEL_NAME = 'gemini-2.5-flash-lite' 
    API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL_NAME}:generateContent"
    
    @classmethod
    def analyze_case(cls, evidence_packet: dict) -> dict:
        """
        Runs the analyst prompt against the evidence packet.
        Returns the specific decision JSON object.
        """
        # Fetch Key Dynamically
        # Default to the one provided in chat if DB empty
        DEFAULT_KEY = "AIzaSyB1MmBbioaghNYtwoesXZw7yoVfoZ0hpV4"
        api_key = JobsDAO.get_config("jobs_analyst_api_key", DEFAULT_KEY)
        
        prompt = f"""
        ROLE: You are the SENTINEL MODERATION ANALYST (AI-ITL).
        AUTHORITY: You have the final say on permanent bans/removals for the Jobs Board.
        PHILOSOPHY: fail_closed (safety first), but avoid permanent bans if uncertain (prefer extend_suspension).
        
        INPUT DATA (EVIDENCE PACKET):
        {json.dumps(evidence_packet, indent=2)}
        
        TASK:
        Review the case and output a JSON decision.
        
        STRICT OUTPUT SCHEMA (JSON):
        {{
          "decision": "reinstate" | "extend_suspension" | "remove_listing" | "ban_account",
          "confidence": 0.0 to 1.0,
          "rationale": "One short sentence explaining why.",
          "key_evidence": ["list", "of", "specific", "strings", "from", "evidence"],
          "risk_assessment": "low" | "medium" | "high" | "critical",
          "recommended_duration_hours": 0 (if extend_suspension, else 0)
        }}
        
        CRITICAL RULES:
        1. If confidence < 0.8, decision MUST NOT be "ban_account". Use "extend_suspension" to allow human review.
        2. Do NOT hallucinate evidence. Use exact substrings from the input.
        3. Output VALID JSON only. No markdown fences.
        """
        
        try:
            # REST API Payload
            payload = {
                "contents": [{
                    "parts": [{"text": prompt}]
                }],
                "generationConfig": {
                    "response_mime_type": "application/json"
                }
            }
            
            response = requests.post(
                f"{cls.API_URL}?key={api_key}",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=30
            )
            
            if response.status_code != 200:
                logger.error(f"Analyst API Error {response.status_code}: {response.text}")
                return None
                
            data = response.json()
            # Extract Text
            try:
                raw_text = data['candidates'][0]['content']['parts'][0]['text']
                # Clean fences just in case
                raw_text = raw_text.replace('```json', '').replace('```', '').strip()
                result = json.loads(raw_text)
            except (KeyError, IndexError, json.JSONDecodeError) as parse_err:
                 logger.error(f"Failed to parse Analyst response: {parse_err} | Raw: {data}")
                 return None
            
            # Basic Validation
            if "decision" not in result or "confidence" not in result:
                logger.error("Invalid JSON schema from Analyst")
                return None
                
            return result
            
        except Exception as e:
            logger.error(f"Analyst Execution Error: {e}")
            return None
