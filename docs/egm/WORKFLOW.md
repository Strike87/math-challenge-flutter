# Project-wide Elephant / Goldfish workflow

This integrates with (does not override) [AGENTS.md](../../AGENTS.md), the
behavior contracts, the refactor tracker, and existing independent review
gates. It grants no runtime, GameBrain, merge, build, signing, or release
authority.

## Gate 0 — Resume, don't duplicate

Read [PROJECT_MEMORY](PROJECT_MEMORY.md), [WORK_REGISTER](WORK_REGISTER.md),
the tracker, relevant source contracts, open and merged GitHub PRs, and tests.
Confirm current `main`, target branch, head SHA, PR state, checks, reviews, and
the last verification timestamp. Classify the proposal as `NEW`,
`CONTINUATION`, `DUPLICATE`, or `REGRESSION`. If duplicate or continuation
evidence exists, stop and link it instead of starting parallel work.

### Mandatory tracker authorization gate

Read `docs/refactor_tracker.md` before authorizing work. **Only the first
unchecked item under `Active` may start.** The current first unchecked item is
`GBI — GameBrain integration (INCREMENTAL AUTHORIZATION ONLY)`. A proposal
outside that item is `BLOCKED` unless the task records explicit, valid
governance authorization for the exception, including who authorized it, the
scope, date, and source evidence. EGM documents cannot widen or reorder the
tracker.

## Gate 1 — Elephant specification (no implementation)

Using [TASK_TEMPLATE](TASK_TEMPLATE.md), record all mandatory metadata before
implementation:

- unique task ID, classification, responsible owner, and user goal;
- source baseline, base SHA, target branch, and current head SHA;
- authoritative source paths, contracts, prior PRs/issues, and observed facts;
- exact approved scope, exclusions, rollback/dependency risks, and the
  first-unchecked tracker item or documented authorization exception;
- owner authorization evidence and the next permitted action;
- CI results with direct links, device/build/release status, and unresolved
  findings.

No assumption becomes a decision merely because it appears in a draft.

## Gate 2 — Fresh Goldfish review

A separate reviewer receives only the draft specification and enumerated
reference sources, not the Elephant conversation or prior chain of thought.
Record reviewer identity, model/agent context, isolation method, review SHA,
timestamp, classification (`PASS`, `BLOCKED`, or `INCONCLUSIVE`), findings,
and dispositions. A same-context reread is not independent. If no fresh
context is available, record `INDEPENDENT_REVIEW_UNAVAILABLE` and stop.

The reviewer must check forgotten requirements, duplicate work, branches/PRs/
commits/checks/approvals, tracker authorization, GameBrain boundaries,
cross-feature effects, failure cases, rollback, and verification evidence.

## Gate 3 — Owner decision

The owner approves the bounded design and implementation step explicitly.
Documentation-only work does not preapprove behavior changes, merge, signing,
APK/AAB, or production release.

## Gate 4 — Implement within existing governance

Use the existing root orchestrator / parity_reasoner / flutter_worker /
regression_reviewer workflow where applicable. Work from a clean branch based
on verified `main`, one authorized boundary at a time. Do not decompose
`GameState` broadly or alter GameBrain runtime authority.

## Gate 5 — Verify and close

Run relevant checks and record exact commands, counts, skips, environment,
commit SHA, CI links, independent review provenance, and unresolved risks.
Keep `CI_PASSED`, `REVIEW_PASSED`, `MERGED`, `DEVICE_ACCEPTED`, and `RELEASED`
as separate statuses. Passing CI never substitutes for independent review or
owner approval.

## Gate 6 — Handoff and drift detection

Before ending a workstream, update the register and relevant tracker only when
authorized. Run this checklist and record the result:

- [ ] Register rows match current open/merged PRs, branch names, head/base SHAs,
      review decisions, check conclusions, and timestamps.
- [ ] Every claimed merge links the merge commit; every claimed CI result links
      the exact check; no CI result is represented as review or release.
- [ ] The first unchecked tracker item is recorded and the task is authorized
      under it, or a valid exception is cited and classified.
- [ ] Project memory links still resolve to authoritative source files and do
      not duplicate or contradict behavior contracts.
- [ ] GameBrain authority statements still match the integration architecture
      and runtime boundaries.
- [ ] Completed, duplicate, superseded, blocked, and pending work is not
      silently omitted.
- [ ] Next permitted action and authorization still needed are explicit.

If any check cannot be verified, record `UNKNOWN` or `DRIFT` and stop rather
than reconciling conflicting sources by assumption.

## Installation is separate

Official Google EGM plugin: https://github.com/google/elephant-goldfish-model
Repository documentation alone does not install a plugin or enable fresh
reviewer contexts.
