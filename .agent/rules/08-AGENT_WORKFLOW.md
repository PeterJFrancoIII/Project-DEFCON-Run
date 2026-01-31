# SENTINEL — AGENT WORKFLOW
Version: Canonical Alpha
## PHASE 0 — CONTEXT INGESTION
Read AGENT_RULES.md, SYSTEM_CONTEXT_PRESERVATION.md, PROMPT_HISTORY.md.
## PHASE 1 — SCOPE VALIDATION
Confirm what may change and what invariants are implicated.
## PHASE 2 — STRUCTURAL ANALYSIS
Analyze schemas, flags, HITL, drift, capacity impacts.
## PHASE 3 — DESIGN SELECTION
If multiple implementations exist, select ONE canonical version.
## PHASE 4 — IMPLEMENTATION
Minimal file changes. Annotate what and why. Add guards first.
## PHASE 5 — SAFETY SELF-AUDIT
Verify Drift Guard, Evidence, HITL, Capacity, Restricted Zones.
## PHASE 6 — OUTPUT & DOCS
Provide code + docs + concise rationale.
## STOP CONDITIONS
Any safety regression halts the task.