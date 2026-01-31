# GOVERNANCE

SSOT: MASTER_DESCRIPTION.md governs identity, architecture, safety, metrics. Supersedes all other docs (incl. deprecated Context_Window_Copy.txt).

Change Control:
1. Implement in code
2. Reflect in MASTER_DESCRIPTION.md
3. Log in PROMPT_HISTORY.md (if affects AI/safety/outputs)

Prompt History: Final Source of Truth for technical evolution. Append-only, never rewritten/truncated. Format: Date|Agent|Detailed Change Summary|Reason|ApprovedBy. Unlogged changes invalid.

Context Preservation: Ensure Sentinel can be rebuilt/audited/resumed without memory loss. Maintain MASTER_DESCRIPTION.md, preserve decision rationale, never delete history without Founder approval. Protects long-term continuity.

Enforcement: Changes not in SSOT invalid. Rollback if SSOT not updated.
