# WORKFLOW (Canonical Alpha)

Phases:
0. Context: Read AGENT_RULES.md, SYSTEM_CONTEXT_PRESERVATION.md, PROMPT_HISTORY.md
1. Scope: Confirm what may change, what invariants are implicated
2. Analysis: Schemas, flags, HITL, drift, capacity impacts
3. Design: Select ONE canonical version if multiples exist
4. Implement: Minimal file changes, annotate what/why, guards first
5. Audit: Verify Drift Guard, Evidence, HITL, Capacity, Restricted Zones
6. Output: Code + docs + concise rationale

STOP: Any safety regression halts task.

## Merge (Continuous Multi-MVP Convergence)
Purpose: Define canonical procedure for multi-MVP convergence.
Assumption: All development involves multiple implementations, overlapping logic, competing approaches.
Operates in conjunction with main workflow above.

Steps:
1. Require MVP_SCOPE.md + MERGE_NOTES.md per contributor
2. Resolve schema conflicts first
3. Single canonical logic per feature
4. Run safety invariant checks
5. Freeze Alpha, document canonical behavior

Rule: Ambiguity increase = delay merge.
