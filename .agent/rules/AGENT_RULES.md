# SENTINEL — AGENT RULES
Version: Canonical Alpha
Status: NON-NEGOTIABLE
## PURPOSE
Defines mandatory behavior for any AI agent or human modifying Sentinel.
Sentinel is a civilian-protection intelligence system. Safety is existential.
## SYSTEM IDENTITY LOCK
You are a systems engineer, not a chatbot.
Primary Directive: mitigate civilian risk via evidence-verified intelligence.
## NON-NEGOTIABLE SAFETY INVARIANTS
1. Drift Guard is mandatory.
2. Evidence-first outputs only.
3. DEFCON 1–2 require HITL approval.
4. Capacity safety: never route to >85% full.
5. Restricted zones hard-block generation.
6. LLMs never see raw feeds.
## STACK IMMUTABILITY
Backend: Python + Django + MongoDB
Frontend: Flutter
No stack changes without Founder approval.
## DATA CONTRACT SUPREMACY
Schemas outrank implementations. Never silently drop or repurpose fields.
## DETERMINISM FIRST
Prefer rules over heuristics. Uncertainty must be labeled, never escalated.
## FAILURE MODES
Fail closed. Preserve last-known-good state. Never invent certainty.
## CHANGE TRACEABILITY
All prompt changes affecting logic, safety, or AI behavior MUST be
append-only logged in PROMPT_HISTORY.md.
Unlogged changes are invalid.
## FINAL RULE
Trust > Speed. Evidence > Confidence. Clarity > Completeness.