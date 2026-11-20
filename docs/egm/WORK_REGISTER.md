# Work register — evidence-backed handoffs

State is **as of the referenced check**, not automatically synchronized with GitHub. Each active agent must refresh live status before acting.

| ID | Scope | Status at 2026-11-20 check | Evidence | Next gate |
| --- | --- | --- | --- | --- |
| TC-V5.4 | Target Clash gameplay, generator optimization, responsive UX | MERGED / release NOT verified | [PR #99](https://github.com/Strike87/math-challenge-flutter/pull/99), merge `5b2259cc3725d7ae7bff1c1fcb567e318ecc47ae` | Device acceptance and any release require separate approval |
| TC-V5.5-A | Read-only 36-configuration difficulty baseline | DRAFT PR, CI status must be refreshed | [PR #100](https://github.com/Strike87/math-challenge-flutter/pull/100), branch `codex/target-clash-v55a-difficulty-matrix` | Check current CI and matrix output; independent review; no automatic merge |
| EGM-BOOTSTRAP | Project-wide Elephant/Goldfish process and handoff | DRAFT PROCESS PROPOSAL | This branch / resulting draft PR | Independent review + owner approval before merge |
| GAMEBRAIN | Legacy and ongoing GameBrain authority gates | TRACKER-CONTROLLED, not globally “done” | [refactor tracker](../refactor_tracker.md) + [integration architecture](../game_brain_integration_architecture.md) | Follow specific subtask authorization; never infer runtime gameplay permission |

## Before any work
1. Search this register, the tracker, open PRs, recent merged PRs and relevant tests for an existing implementation.
2. If similar work exists, classify `DUPLICATE`, `CONTINUATION`, `REGRESSION` or `NEW`; include links.
3. Verify the current target branch SHA and PR status.
4. Record a bounded scope, exclusions, owner approval, rollback plan and test gate.

## Status vocabulary
`PROPOSED` → `DESIGNING` → `GOLDFISH_REVIEW_PENDING` → `DESIGN_APPROVED` → `IMPLEMENTING` → `CI_PENDING` → `REVIEW_PENDING` → `MERGE_APPROVAL_PENDING` → `MERGED` → `DEVICE_ACCEPTANCE_PENDING` → `RELEASED`.

Additional terminal states: `CLOSED_NO_CHANGE`, `BLOCKED`, `DUPLICATE`, `SUPERSEDED`. Use `UNKNOWN` rather than guess.

## Ledger update rules
- **One line per workstream**, not one per conversation.
- Every completed assertion links an authoritative PR/commit/test/review.
- Preserve old decisions in Git history; do not erase disagreements.
- Never label `MERGED` as `RELEASED`, and never conflate CI success with human or device approval.
- Update this table when a workstream changes; this is not automatic.
