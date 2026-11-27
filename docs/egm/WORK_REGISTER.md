# Work register — evidence-backed handoffs

This register is a manually verified index, not an automatic GitHub mirror.
Every row records the last verification time and must be refreshed before work
starts. `CI_PASSED`, `REVIEWED`, `MERGED`, `DEVICE_ACCEPTED`, and `RELEASED`
are separate facts; one never implies another.

**Last verified:** 2026-11-23 (Africa/Cairo; PR #110/#112 post-merge reconciliation; other rows retain their own verification dates)
**EGM bootstrap merge:** [PR #101](https://github.com/Strike87/math-challenge-flutter/pull/101) → `766e1a5dfbf1e85df071b437e960ecd29f96f67c`
**Verified against:** `main` `f5ad982695bc9985e456934a00cc44553d546021` (post-PR #110 merge; this documentation closeout is a separate draft proposal)

| ID | Scope | Status | Base → head / merge | Last verified | Evidence | Next permitted action |
| --- | --- | --- | --- | --- | --- | --- |
| MENU-UX-01 | Project Home and Practice navigation | MERGED; release/device not asserted | `059796f98bf854421b36138a9842575b625558d2` → `4385473da3bb2efc6a4b0386c7c9863090054617`; merge `c6aa227a3b9f7eb5b691ee43e01ba8dbc838579a` | 2026-11-20T19:23:13Z | [PR #98](https://github.com/Strike87/math-challenge-flutter/pull/98) | Reuse existing evidence; do not duplicate. |
| TC-V5.4 | Target Clash gameplay, generator optimization, responsive UX | MERGED; CI passed; device/release not asserted | `c6aa227a3b9f7eb5b691ee43e01ba8dbc838579a` → `62aba9b38b30063fadfc6e1e540101142563d538`; merge `5b2259cc3725d7ae7bff1c1fcb567e318ecc47ae` | 2026-11-20T19:23:13Z | [PR #99](https://github.com/Strike87/math-challenge-flutter/pull/99) | Device acceptance or release requires separate approval. |
| TC-V5.5-A | Read-only 36-configuration difficulty baseline and governed lint repair | **MERGED; CI passed; external independent final review PASS reported; device/release not asserted** | `5b2259cc3725d7ae7bff1c1fcb567e318ecc47ae` → `bc7db33d6397e3d2e2ba92d71b7402faa84af6f6`; merge `130113359603efa9c68205997904c5c0d26220ae` | 2026-11-22 | [PR #100](https://github.com/Strike87/math-challenge-flutter/pull/100); [post-merge main CI](https://github.com/Strike87/math-challenge-flutter/actions/runs/44952145408) Flutter and VM guard SUCCESS; owner-supplied separate fresh-context Goldfish PASS (not GitHub-native approval). Historical pre-review lint change, revert and governed replay retained in tracker. | No additional implementation under this scope. Direct boss/current-difficulty cap (`3/4/5`) assertions remain separate and not yet authorized. |
| EGM-BOOTSTRAP | Project-wide Elephant/Goldfish process and handoff | **MERGED; CI passed; device/release not asserted** | `5b2259cc3725d7ae7bff1c1fcb567e318ecc47ae` → `76e9190c3e2a02c77f8229c27ad7ea2f5f83fb6b`; merge `766e1a5dfbf1e85df071b437e960ecd29f96f67c` | 2026-11-22 | [PR #101](https://github.com/Strike87/math-challenge-flutter/pull/101); [recorded independent review](REVIEW_STATUS.md); accepted merge on GitHub. No claim of plugin installation, runtime authorization or release. | Retain EGM governance and independently refresh evidence for new workstreams. |
| TC-V55A-LINT-01 | One-time Target Clash V5.5-A lint-repair governance exception | **CLOSED / EXPIRED / NON-REUSABLE; historical violation preserved** | [PR #102](https://github.com/Strike87/math-challenge-flutter/pull/102) → merge `63d8ea410741f236c54625cd552837ec4ccc4ff2`; dependent [PR #100](https://github.com/Strike87/math-challenge-flutter/pull/100) → merge `130113359603efa9c68205997904c5c0d26220ae` | 2026-11-22 | [Owner-authorized and separately Goldfish-reviewed closure proposal](https://github.com/Strike87/math-challenge-flutter/pull/102#issuecomment-7069905930); [main post-merge checks](https://github.com/Strike87/math-challenge-flutter/actions/runs/44952145408) PASS; initial out-of-order commit `bb873517`, inverse `c046bce`, governed replay `bc7db33` recorded in tracker. | No reuse; future Target Clash tests require their own tracker-authorized task. GBI remains first unchecked Active. |
| TC-V55B-GOV-F0NI | Single-target non-independent PR #112 governance review exception | **MERGED; one-use deviation CONSUMED / EXPIRED; not independent Goldfish PASS** | PR #112 reviewed HEAD `d11f71a6aac44eebedaffc2d7c2bfc7201ac9a24`; merge `14342c4f655798189220d356f273c4d1be3562c5` | 2026-11-23 | [PR #112](https://github.com/Strike87/math-challenge-flutter/pull/112); owner accepted non-independent governance-review risk in coordinating ChatGPT conversation. | Closed; no repeat waiver, activation, or release. |
| TC-V55B-TRIPLE-MATRIX-TEST-01 | V5.5-B 24×6 Triple domain test matrix | **MERGED; PR-head CI SUCCESS; bounded NON_INDEPENDENT F3 PASS; device/release not asserted** | PR #110 fixed HEAD `e2f3d300996fa120e1b05ab3026f60b7f1559f70`; merge `f5ad982695bc9985e456934a00cc44553d546021` | 2026-11-23 | [PR #110](https://github.com/Strike87/math-challenge-flutter/pull/110); [CI run](https://github.com/Strike87/math-challenge-flutter/actions/runs/45027283169); [F2 activation](https://github.com/Strike87/math-challenge-flutter/pull/110#issuecomment-7087196729); [F3 audit](https://github.com/Strike87/math-challenge-flutter/pull/110#issuecomment-7087207498). Domain-only; no real GameState RNG sequence equivalence claim. | Exception closed, one-use fallback consumed. No new implementation or release authorized. |
| GAMEBRAIN | Legacy and ongoing GameBrain authority gates | TRACKER_CONTROLLED; not globally complete | See [refactor tracker](../refactor_tracker.md) and [integration architecture](../game_brain_integration_architecture.md) | 2026-11-20T22:34:26Z | [refactor tracker](../refactor_tracker.md) | Only an explicitly authorized tracker item may proceed; never infer runtime gameplay authority. |

| MD3-UX-05-GOV / PR #119 | Documentation-only reconciliation; frozen historical candidate | **PR #120 MERGED; historical authorization BLOCKED finding preserved; PR #119 remains frozen/draft/unmerged; Recovery CLOSED** | PR #120 merge `7bed4a8c2d59097385c2c228bfb48f9fbd253bf3`; PR #119 head `a85b6a4bb0a06f54463237962db0ac764bd83c49` | 2026-11-27 (Africa/Cairo) | [Task record](MD3_UX_05_GOV.md); [PR #120](https://github.com/Strike87/math-challenge-flutter/pull/120); [PR #119](https://github.com/Strike87/math-challenge-flutter/pull/119) | Preserve historical findings; no retrospective acceptance or merge of #119. |
| MD3-UX-05-RECOVERY | REC-01 HUD, REC-02 Results, REC-03 Practice, REC-04 IQ Spark | **CLOSED / 4 of 4 MERGED; post-merge CI PASS; owner-supplied Goldfish PASS and human visual acceptance recorded; no device/release claim** | #121 merge `ec365c1fb58e42193befc6928a03100babd87300`; #122 `1f9b054d98f941ea2dea070dc519c08a87aa3f91`; #123 `e9122ab86f33721e431f6aaa6a80893e4757e481`; #124 `571b6362efa92be16efd3703ffe9bb58105ab91e` | 2026-11-27 (Africa/Cairo) | [Reviewed heads and acceptance links](MD3_UX_05_GOV.md#verified-recovery-evidence); [main CI](https://github.com/Strike87/math-challenge-flutter/actions/runs/46012218178) | Close recovery; separate activation for 05F-01. |
| MD3-UX-05F-ACT | Docs-only conditional 05F-01 Modal Header & Shell exception | **PROPOSED / REVIEW PENDING; NOT EFFECTIVE; no implementation authority** | Verified base `571b6362efa92be16efd3703ffe9bb58105ab91e`; candidate head pending exact patch review | 2026-11-27 (Africa/Cairo) | [Bounded scope and gates](MD3_UX_05_GOV.md#conditional-exception-md3-ux-05f-01-only--modal-header--shell); [base CI PASS](https://github.com/Strike87/math-challenge-flutter/actions/runs/46012218178) | Exact patch PASS before commit/push, final review and separate owner governance merge approval; verify main/CI; separate owner implementation authority and fresh Goldfish review. GBI unchanged; 05F-02 onward separately gated. |

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
