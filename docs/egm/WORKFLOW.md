# Project-wide Elephant / Goldfish workflow

This integrates with (does not override) [AGENTS.md](../../AGENTS.md), including its independent parity and regression gates, scope/approval requirements, source-of-truth and prohibited changes.

## Gate 0 — Resume, don't duplicate
Read [PROJECT_MEMORY](PROJECT_MEMORY.md), [WORK_REGISTER](WORK_REGISTER.md), the tracker, and current GitHub open/merged PRs. Confirm main HEAD. Classify proposal as NEW/CONTINUATION/DUPLICATE/REGRESSION. If duplicate, stop and link the existing evidence.

## Gate 1 — Elephant specification (no implementation)
Using the [task template](TASK_TEMPLATE.md), identify user outcome, exact existing behavior, relevant source lines/docs, cross-system dependencies, product decisions, acceptance tests, explicit exclusions, revert plan, open unknowns. No ungrounded “implemented” statements.

## Gate 2 — Fresh Goldfish review
A separate reviewer must receive **only** the draft specification and enumerated reference sources; not the Elephant conversation or its prior chain of thought. Ask:
- What would you have to guess to implement this?
- Which other game mode, shared generator, GameBrain gate, persistence key, reset, ads, IAP, privacy, UI, or device capability could this affect?
- What assumption or duplicate work did the spec overlook?
- Are authority boundaries, failure cases, tests, rollback and scope explicit?

Return `PASS`, `BLOCKED` or `INCONCLUSIVE` with precise findings. A single assistant rereading its own work in the same context is **not** an independent Goldfish. If no fresh-context agent is available, log `INDEPENDENT_REVIEW_UNAVAILABLE` and follow the existing AGENTS.md governance; do not fake a result.

## Gate 3 — Owner decision
Owner resolves alternatives and approves the **bounded** design and implementation step. Documentation-only changes do not preapprove behavior changes, merge, signing, APK/AAB or production release.

## Gate 4 — Implement within existing governance
Use the existing root orchestrator / parity_reasoner / flutter_worker / regression_reviewer workflow. Clean current-main-based branch, one authorized boundary at a time; no broad GameState redesign. Follow [AGENTS.md](../../AGENTS.md).

## Gate 5 — Verify and close
Run relevant focused tests, full non-golden when shared behavior affected, visual parity and analyzer per AGENTS.md, plus safety and diff checks. Separate `CI_PASS`, `REVIEW_PASS`, `MERGED`, `DEVICE_PASS`, `RELEASED`. Record exact SHAs, test counts, skips, environment, reviewer independence and unresolved risks.

## Gate 6 — Handoff / drift report
Before ending any workstream, update WORK_REGISTER + relevant original tracker if authorized. Compare this index with current code, PRs and contracts; report discrepancies without automatically reconciling conflicting sources. Write the next smallest action and **authorization needed**.

## Installation is separate
Official Google EGM plugin: https://github.com/google/elephant-goldfish-model
Install the complete plugin in a supported Codex/Claude/Antigravity/ChatGPT environment that offers fresh subagents to run genuine Goldfish checks. Repository documentation alone does not install a plugin or enable new subagents.
