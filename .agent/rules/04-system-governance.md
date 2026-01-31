---
trigger: always_on
---

# SYSTEM GOVERNANCE — SOURCE OF TRUTH

Authority
`MASTER_DESCRIPTION.md` is the Single Source of Truth (SSOT) for the Sentinel system.

Scope
The SSOT governs:
- System identity and mission.
- Core architecture and data flow.
- Safety invariants and escalation logic.
- Canonical metrics, thresholds, and definitions.

Precedence
`MASTER_DESCRIPTION.md` supersedes all other documentation, including deprecated files such as `Context_Window_Copy.txt`.

Change Control
Any change affecting system behavior, architecture, identity, or metrics MUST be:
1. Implemented in code.
2. Reflected explicitly in `MASTER_DESCRIPTION.md`.
3. Logged (if applicable) in `PROMPT_HISTORY.md`.

Enforcement
- Changes not reflected in the SSOT are invalid.
- Implementations may be rolled back if the SSOT is not updated.