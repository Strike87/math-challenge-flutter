# Work register — evidence-backed handoffs

This register is a manually verified index, not an automatic GitHub mirror.
Every row records the last verification time and must be refreshed before work
starts. `CI_PASSED`, `REVIEWED`, `MERGED`, `DEVICE_ACCEPTED`, and `RELEASED`
are separate facts; one never implies another.

**Last verified:** 2026-11-20T22:42:00Z
**EGM live head at last verification:** `3724b184af7c8f4921e23dd95e88263549874bc1`
**Verified against:** `main` `5b2259cc3725d7ae7bff1c1fcb567e318ecc47ae`

| ID | Scope | Status | Base → head / merge | Last verified | Evidence | Next permitted action |
| --- | --- | --- | --- | --- | --- | --- |
| MENU-UX-01 | Project Home and Practice navigation | MERGED; release/device not asserted | `059796f98bf854421b36138a9842575b625558d2` → `4385473da3bb2efc6a4b0386c7c9863090054617`; merge `c6aa227a3b9f7eb5b691ee43e01ba8dbc838579a` | 2026-11-20T19:23:13Z | [PR #98](https://github.com/Strike87/math-challenge-flutter/pull/98) | Reuse existing evidence; do not duplicate. |
| TC-V5.4 | Target Clash gameplay, generator optimization, responsive UX | MERGED; CI passed; device/release not asserted | `c6aa227a3b9f7eb5b691ee43e01ba8dbc838579a` → `62aba9b38b30063fadfc6e1e540101142563d538`; merge `5b2259cc3725d7ae7bff1c1fcb567e318ecc47ae` | 2026-11-20T19:23:13Z | [PR #99](https://github.com/Strike87/math-challenge-flutter/pull/99) | Device acceptance or release requires separate approval. |
| TC-V5.5-A | Read-only 36-configuration difficulty baseline | DRAFT; CI_FAILED; review/merge not authorized | `5b2259cc3725d7ae7bff1c1fcb567e318ecc47ae` → `66a2796944fba37504db300ddfdbdb6bfadbe59b`; [PR #100](https://github.com/Strike87/math-challenge-flutter/pull/100) | 2026-11-20T18:54:26Z | Flutter failures: [run 44796520787](https://github.com/Strike87/math-challenge-flutter/actions/runs/44796520787/job/136497365501), [run 44796466421](https://github.com/Strike87/math-challenge-flutter/actions/runs/44796466421/job/136497183618). VM guards passed: [run 44796520787](https://github.com/Strike87/math-challenge-flutter/actions/runs/44796520787/job/136497365514), [run 44796466421](https://github.com/Strike87/math-challenge-flutter/actions/runs/44796466421/job/136497183063). | Diagnose and re-run failed CI; independent review and owner merge approval remain required. |
| EGM-BOOTSTRAP | Project-wide Elephant/Goldfish process and handoff | DRAFT; CI_PENDING; REVIEW_PENDING; no GitHub review decision | branch `docs/egm-project-wide-governance`; base `5b2259cc3725d7ae7bff1c1fcb567e318ecc47ae`; last substantive amendment head `3aee7fe6a44efc4211c263bf0af8a2fb6ea70f72`; last live head checked `3724b184af7c8f4921e23dd95e88263549874bc1`; [PR #101](https://github.com/Strike87/math-challenge-flutter/pull/101) | 2026-11-20T22:42:00Z | Last observed checks: [Flutter](https://github.com/Strike87/math-challenge-flutter/actions/runs/44831058325/job/136615809674), [Flutter](https://github.com/Strike87/math-challenge-flutter/actions/runs/44831069844/job/136615853756), [VM guard](https://github.com/Strike87/math-challenge-flutter/actions/runs/44831058325/job/136615810054), [VM guard](https://github.com/Strike87/math-challenge-flutter/actions/runs/44831069844/job/136615853527). Review evidence: none yet (`reviewDecision` empty). Verification-only commits may advance the branch; re-read live PR head and checks immediately before review. | Revalidate live head/checks, run a fresh independent Goldfish review against that exact head, then request separate merge approval. |
| GAMEBRAIN | Legacy and ongoing GameBrain authority gates | TRACKER_CONTROLLED; not globally complete | See [refactor tracker](../refactor_tracker.md) and [integration architecture](../game_brain_integration_architecture.md) | 2026-11-20T22:34:26Z | [refactor tracker](../refactor_tracker.md) | Only an explicitly authorized tracker item may proceed; never infer runtime gameplay authority. |

## Mandatory pre-work gate

1. Read this register, the tracker, open and merged PRs, relevant tests, and
   the applicable source contracts.
2. Verify current `main`, target branch, head SHA, PR state, checks, reviews,
   and last verification time.
3. Classify the proposal as `NEW`, `CONTINUATION`, `DUPLICATE`, or
   `REGRESSION`; link existing work before starting anything.
4. Read `docs/refactor_tracker.md`. **Only the first unchecked item under
   `Active` may start. The current first unchecked item is `GBI`.** If a
   proposal is outside that item, classify it `BLOCKED` unless explicit valid
   governance authorization is recorded with the task.
5. Record the bounded scope, exclusions, owner, authorization evidence,
   rollback plan, and verification gate.

## Status vocabulary

`PROPOSED` → `DESIGNING` → `GOLDFISH_REVIEW_PENDING` → `DESIGN_APPROVED` →
`IMPLEMENTING` → `CI_PENDING` → `CI_PASSED`/`CI_FAILED` → `REVIEW_PENDING` →
`REVIEW_PASSED`/`REVIEW_BLOCKED` → `MERGE_APPROVAL_PENDING` → `MERGED` →
`DEVICE_ACCEPTANCE_PENDING` → `DEVICE_ACCEPTED` → `RELEASED`.

Additional terminal states: `CLOSED_NO_CHANGE`, `BLOCKED`, `DUPLICATE`,
`SUPERSEDED`, and `UNKNOWN` (when evidence is unavailable).

## Ledger rules

- Keep one row per workstream, not one row per conversation.
- Every completed assertion links an authoritative PR, commit, check, test, or
  review and includes its verification timestamp.
- Preserve old decisions in Git history; do not erase disagreements.
- A passing CI check is not a review, merge, device acceptance, or release.
- Refresh the row whenever the workstream changes; this register cannot update
  itself.
