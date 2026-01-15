# PROMPT HISTORY
## PURPOSE
Maintain full traceability of all prompts that affect Sentinel’s logic,
outputs, safety behavior, or AI decision-making.
This file exists to:
- Prevent silent behavior drift
- Enable post-incident audits
- Preserve long-term AI consistency across rebuilds and contributors
## GOVERNING RULE
The root file `PROMPT_HISTORY.md` MUST always be maintained.
This file is:
- Append-only
- Never rewritten
- Never truncated
- Never reordered
No silent prompt changes are allowed.
## WHAT MUST BE LOGGED
Log **any prompt** that affects:
- Intelligence logic
- DEFCON computation or gating
- Evacuation, routing, or logistics
- Safety language or phrasing
- Evidence handling or drift behavior
- Agent role behavior or authority
- Cost / polling / cadence logic
If a prompt can change what civilians see or how the system reasons, it MUST be logged.
This includes system prompts, analyst prompts, agent rules, guardrails, and any prompt embedded in code or configuration.
## FORMAT (MANDATORY)
Date | Agent | Detailed Change Summary | Reason | Approved By
Example: 2026-01-14 | AntiGravity | Tightened Drift Guard thresholds by way of...(etc) | Prevent reprint escalation | Founder
## ENFORCEMENT
- Unlogged prompt changes are considered **invalid changes**
- Any build using unlogged prompts may be rejected or rolled back
- Repeated violations may result in removal from critical paths
## FINAL PRINCIPLE
Prompt history is not documentation.
It is **change control** for a safety-critical intelligence system.
Traceability is a safety feature.