# MD3-UX-05-GOV — proposed governance reconciliation and Dialogs scope

**Status: PROPOSED / INACTIVE / GOVERNANCE REVIEW PENDING.** This document is a review candidate, not an activation, a retrospective approval, or permission to change application code.

## Gate 0 / Gate 1 — task record

- **Task ID / classification:** MD3-UX-05-GOV / CONTINUATION / GOVERNANCE-ONLY.
- **Responsible owner:** project owner (repository owner Strike87); orchestrator: coordinating ChatGPT session.
- **Goal:** reconcile the existing UI candidate and address the user-supplied Goldfish BLOCKED report before any new 05F code.
- **Owner evidence, 2026-11-26 (Africa/Cairo), coordinating ChatGPT conversation:** “موافق على إعداد PR حوكمي مستقل MD3-UX-05-GOV لتسوية نطاق PR #119 وتوثيق تفويض مرحلة MD3-UX-05F وفق ملاحظات Goldfish، مع Commit وPush للوثائق فقط، دون دمج أو تعديل كود اللعبة.”
- **Exact present authority:** prepare, commit and push this documentation-only draft PR. No activation, code/test/workflow edit, rebase, merge, release or production authority. The future proposal below requires separate owner decisions.
- **Verified main/base:** `afbe133241bd5f6653f63640b5417d989c24e1b4`; governance branch `docs/md3-ux-05-gov` based on that SHA. Existing [PR #119](https://github.com/Strike87/math-challenge-flutter/pull/119), branch `feat/md3-ux-05b-gameplay-hud`, head `a85b6a4bb0a06f54463237962db0ac764bd83c49`, is open, draft, not merged. Last verification: 2026-11-26 (Cairo).
- **Sources:** [AGENTS](../../AGENTS.md), [tracker](../refactor_tracker.md), [behavior contracts](../behavior_contracts.md), [EGM workflow](WORKFLOW.md), [task template](TASK_TEMPLATE.md), [register](WORK_REGISTER.md), [modal source at reviewed head](https://github.com/Strike87/math-challenge-flutter/blob/a85b6a4bb0a06f54463237962db0ac764bd83c49/lib/widgets/modals.dart), [modal behavior tests](https://github.com/Strike87/math-challenge-flutter/blob/a85b6a4bb0a06f54463237962db0ac764bd83c49/test/modal_behavior_test.dart), [Adult Gate tests](https://github.com/Strike87/math-challenge-flutter/blob/a85b6a4bb0a06f54463237962db0ac764bd83c49/test/iap_adult_gate_test.dart).
- **Tracker gate:** GBI remains first unchecked under Active. The 2026-11-23 UI/Design → AdMob → GBI priority decision is not blanket authority. The B1-F wrapping proposal is historical/superseded; the owner's single-line attribution preference stays intact. Prior one-time exceptions are not reused.
- **Cross-feature boundary:** UI/accessibility presentation only in a future authorized slice; GameState, generator/RNG, GameBrain, modes, scoring, timers, persistence/reset, ads/IAP, family/privacy and navigation semantics remain unchanged. Performance and layout regressions must be checked, not assumed absent.

## Historical reconciliation — fixed PR #119 snapshot

The observed candidate contains 11 changed paths:

- `.github/workflows/gameplay-hud-review.yml`, `.github/workflows/practice-visual-review.yml`, `.github/workflows/results-visual-review.yml`
- `lib/screens/game_screen.dart`, `lib/screens/practice_screen.dart`, `lib/screens/practice_style_screen.dart`, `lib/widgets/modals.dart`
- `test/gameplay_hud_review_test.dart`, `test/practice_visual_review_test.dart`, `test/results_visual_review_test.dart`, `test/timing_style_foundation_test.dart`

Reported prior slices 05A audit, 05B gameplay HUD, 05C answer controls, 05D results, 05E practice are a candidate, **not accepted or retrospectively authorized**. Goldfish identified the missing tracker authorization (P0); the orchestrator acknowledges the governance gap. Preserve the branch and history as evidence, freeze further changes and merge, and review the complete fixed diff against main and contracts. Do not use CI to excuse earlier sequencing. The one-line test import repair at `a85b6a4bb0a06f54463237962db0ac764bd83c49` has an [owner-authorized non-independent audit record](https://github.com/Strike87/math-challenge-flutter/pull/119#issuecomment-7203777517); that narrow exception is not reusable and does not establish whole-PR approval.

Observed fixed-head CI: [Full CI](https://github.com/Strike87/math-challenge-flutter/actions/runs/45898481425) PASS (1509 non-golden tests passed, 2 skipped, analyzer no issues; VM guard PASS); [Practice](https://github.com/Strike87/math-challenge-flutter/actions/runs/45898481450), [Results](https://github.com/Strike87/math-challenge-flutter/actions/runs/45898481428), [HUD](https://github.com/Strike87/math-challenge-flutter/actions/runs/45898481426) automation PASS. Human screenshot acceptance, actual Android, independent final review, merge, build/signing and release are not established. Earlier CI [45888109833](https://github.com/Strike87/math-challenge-flutter/actions/runs/45888109833) exposed an intermittent Target Clash numeric-target assertion; rerun passing did not resolve its contract or determinism. Track separately; no generator or test weakening in this scope.

**Recovery proposed, not activated:** independent reviewer examines this governance draft and the full fixed PR #119 diff, records dispositions for each prior slice and any behavior drift. Owner separately approves a governance merge; after verified merge/main drift check, approve a bounded recovery/replay plan on fresh main, keeping the existing PR as evidence. No automatic grandfathering, no retrospective PASS; choose governed replay or another explicitly reviewed recovery disposition before new implementation. Prior slices must receive their own acceptance/review, not merely a successful workflow. Do not silently amend the existing branch or discard evidence.

## User-supplied Goldfish review — BLOCKED

Source: owner supplied review text in coordinating conversation 2026-11-26; reported review target `a85b6a4bb0a06f54463237962db0ac764bd83c49`. Reviewer identity/model/isolation/timestamp beyond the conversation date are UNKNOWN; no native GitHub approval asserted. The supplied result is BLOCKED; no independent PASS for this governance draft has occurred.

| Severity | Finding | Required disposition |
| --- | --- | --- |
| P0 | Missing tracker authorization | Separate governance review, explicit activation and implementation decision; audit previous PR #119 work |
| P1 | Only compact WinModal action wrapper enforces 48dp; normal Wrap/NeoButton actions not guaranteed | Measure actual interactive bounds for every affected action, preserve callbacks |
| P1 | Default header one-line FittedBox and ellipsized subtitle | Readable bounded wrapping/non-ellipsizing strategy; preserve custom headers and visual identity |
| P1 | Body-only scrolling; compact result height and short/keyboard layouts insufficiently proven | Bounded layout and reachable content/actions including short landscape and keyboard |
| P2 | SetupWordFitText search can approach zero for unbreakable words | Readable nonzero floor and explicit fallback, without changing attribution footer contract |
| P2 | Incomplete modal/theme/scale coverage | Complete matrix plus focused behavior, focus and Escape regressions |

## Proposed future 05F implementation exception — INACTIVE

Only following governance review and separate owner decisions: presentation-only responsive modal modernization, one bounded slice at a time. Candidate exact production paths: `lib/widgets/modals.dart`, `lib/widgets/setup_word_fit_text.dart` (only if necessary for bounded readable fallback). Candidate test paths: existing `test/modal_behavior_test.dart`, `test/iap_adult_gate_test.dart`, `test/results_visual_review_test.dart`, `test/visual_parity_test.dart` (no baseline changes), proposed `test/modal_visual_review_test.dart` and `test/setup_word_fit_text_test.dart`. A new artifact workflow, support file, golden refresh, additional production file or any expansion needs separate recorded approval; existing test expectations must not be weakened. No code, tests or workflows are authorized by the present docs approval.

- 05F-01: bounded header and shell layout; default and custom headers, safe areas, keyboard insets, body and pinned actions; retain all routes, dismissal/focus and semantic callbacks.
- 05F-02: actual action hit targets >=48 x 48 logical dp, adaptive layout, readable text fallback including single unbreakable word; preserve results presentation and existing footer.
- 05F-03: focused and complete visual/behavior matrix. All 17 consumers: Training Arena, Operation Quest, Settings, Master Intro, Daily Boss, Daily IQ Spark, Stage Cleared, Win, Quit Confirm, Hall of Fame, Achievements, Tutorial, Avatar Builder, Skills Dashboard, Coin Shop, Adult Gate, Daily Challenges. 320x568, 390x844, 844x390; scales 1.0, 1.5, 2.0; light/dark = 306 planned layout cases, not executed. Record actual coverage and any state prerequisites, not just screenshot count.
- 05F-04: independent final review and separate owner acceptance.

**Acceptance:** no overflow/layout exceptions; readable untruncated titles/subtitles; actual hit targets measured; content and actions reachable with scroll; Adult Gate usable above portrait/landscape keyboards; focus closed loop and Escape unchanged (Win/Stage Cleared inert; safe Coin Shop/IAP exits), Win replay/menu and all callbacks unchanged; avatar picker, progression, settings and rewards unchanged. No GameState/GameBrain/domain/generator/persistence/navigation/ads/IAP/family/privacy behavior changes. Preserve existing visual identity and footer. No new packages or unrelated refactoring.

**Required evidence before acceptance:** focused modal and text-fitting tests; full non-golden tests; visual parity tests including existing baselines (no blanket golden refresh); flutter analyze --no-pub; git diff --check; full diff/scope audit; visual human review and record device acceptance separately. Use exact SHAs, commands, logs, counts/skips and independent reviewer provenance. No build/sign/release permission. If constraints cannot be met within paths, stop and request bounded scope expansion. Revert only the authorized slice if regression occurs, preserve history and main.

## Gates and closure

1. Review exact governance draft independently (no new Goldfish review yet; no fallback authorization for this draft). Obtain explicit owner merge approval; do not merge now.
2. Verify main and existing PR head; resolve prior-slice recovery and obtain explicit owner activation and implementation scope/commit authority. Until then all 05F work and PR #119 merge remain BLOCKED. Re-review any drift.
3. Implement, verify, independently review and record one bounded slice at a time. 05G/05H/05I, AdMob and GBI remain separate gates.
4. Update register after actual changes. A passing CI is not review, authorization, merge, device acceptance or release.

**Current implementation:** documentation-only proposal on `docs/md3-ux-05-gov`, no application files changed. **Closure:** pending governance review, owner merge decision, and governed recovery; no merge/release. **Next permitted action:** review this draft. **Authorization still needed:** independent review PASS or separately governed valid exception, separate governance merge approval and verified activation/recovery decision, then bounded code authority; no assumption of future approval.

## MD3-UX-05F-ACT — recovery closeout and conditional 05F-01 activation (2026-11-27)

**Current disposition (supersedes historical status/gate wording above, without erasing it):** Recovery CLOSED / 4 of 4 MERGED / post-merge CI PASS. MD3-UX-05F-ACT is a documentation-only activation candidate, NOT EFFECTIVE until separately approved and merged and current main verified. PR #119 remains open, draft, unmerged and frozen at `a85b6a4bb0a06f54463237962db0ac764bd83c49`; no retrospective authorization, merge, or reuse of the historical exception.

**Owner / classification:** Strike87 / CONTINUATION / GOVERNANCE-ONLY / single bounded tracker exception. Owner instruction in coordinating conversation, 2026-11-27 (Africa/Cairo): “موافق على إعداد MD3-UX-05F-ACT لتوثيق إغلاق Recovery وتفعيل النطاق المحدد للمرحلة 05F-01 في وثائق الحوكمة والـTracker والـWork Register فقط، مع Commit وPush بعد نجاح main CI ومراجعة Goldfish، دون تعديل كود الإنتاج أو الدمج.” This authorizes only preparation of the exact three-file documentation candidate and its commit/push after CI and pre-implementation Goldfish PASS. The initial pre-review returned BLOCKED because the exact candidate diff was missing. This exact diff is submitted for re-review; no PASS is asserted for it yet.

### Verified recovery evidence

Verified 2026-11-27 (Africa/Cairo), main `571b6362efa92be16efd3703ffe9bb58105ab91e`. Governance PR #120 merged at `7bed4a8c2d59097385c2c228bfb48f9fbd253bf3`. The four recovery PRs were separately reviewed, authorized, visually accepted by the owner, and merged. Goldfish PASS reports are owner-supplied; reviewer identity/model/isolation not independently verified and no native GitHub review or automated golden comparison is asserted.

| Slice | Reviewed head | Merge SHA | Owner acceptance / post-merge CI |
| --- | --- | --- | --- |
| REC-01 Gameplay/HUD | `d923b59b0a5b2930a37c3a343393b96947456e91` | `ec365c1fb58e42193befc6928a03100babd87300` | [PR #121 acceptance](https://github.com/Strike87/math-challenge-flutter/pull/121#issuecomment-7217404485) / [CI 45992847278](https://github.com/Strike87/math-challenge-flutter/actions/runs/45992847278) PASS |
| REC-02 Results | `df028263f2feeef1d9d5e8f40d44209addf8dd42` | `1f9b054d98f941ea2dea070dc519c08a87aa3f91` | [PR #122 acceptance](https://github.com/Strike87/math-challenge-flutter/pull/122#issuecomment-7218439313) / [CI 45999974006](https://github.com/Strike87/math-challenge-flutter/actions/runs/45999974006) PASS |
| REC-03 Practice | `cfe8670d66e8e2f5ebb266c394b5d45107b4e2fa` | `e9122ab86f33721e431f6aaa6a80893e4757e481` | [PR #123 acceptance](https://github.com/Strike87/math-challenge-flutter/pull/123#issuecomment-7218928189) / [CI 46003284193](https://github.com/Strike87/math-challenge-flutter/actions/runs/46003284193) PASS |
| REC-04 IQ Spark results / FIX-01 | `83b797b507ac24f0ac9a48ba5c0474b28c73304c` | `571b6362efa92be16efd3703ffe9bb58105ab91e` | [PR #124 acceptance](https://github.com/Strike87/math-challenge-flutter/pull/124#issuecomment-7220239474) / [CI 46012218178](https://github.com/Strike87/math-challenge-flutter/actions/runs/46012218178) PASS |

REC-04 reviewed-head [CI 46008899421](https://github.com/Strike87/math-challenge-flutter/actions/runs/46008899421): 1533 passed, 2 skipped, analyzer/product guard PASS; [visual run 46008899448](https://github.com/Strike87/math-challenge-flutter/actions/runs/46008899448): 40/40 and 80 captures; [artifact 15202314529](https://github.com/Strike87/math-challenge-flutter/actions/runs/46008899448/artifacts/15202314529), subject to retention. Recovery did not authorize merging PR #119. Preserve the separate Target Clash intermittent assertion concern; defer Practice title wrapping observation to 05G per owner decision. No device acceptance or release claimed.

### Conditional exception: MD3-UX-05F-01 only — Modal Header & Shell

- **Goal:** presentation-only readable complete default titles/subtitles and responsive shared modal shell, respecting custom headers, safe areas, keyboard insets, bounded sizing, body scrolling and reachable/pinned actions. Keep existing compact results behavior and visual identity. If available height cannot fit pinned header/actions plus body, require a bounded scroll fallback with reachable controls; do not introduce nested/unbounded scroll layouts or change dismissal semantics.
- **Exact proposed future production path:** `lib/widgets/modals.dart`, restricted to `ModalRouter` presentation constraints, `ModalShell`, and `_ModalDefaultHeader`; preserve consumer callbacks, custom header content and existing `scrollChild` semantics. No changes to `setup_word_fit_text.dart` under 05F-01. **Proposed future test edits:** `test/modal_behavior_test.dart` and `test/iap_adult_gate_test.dart` only, additive assertions/fixtures. Run existing results/visual parity tests without edits. Additional paths, new workflows/support files, dependencies or golden refresh require separate reviewed owner approval.
- **Acceptance:** verify 320x568, 390x844 and 844x390; light/dark, 1.0/1.5/2.0 scale for representative default/custom header and short/keyboard cases. Check complete readable title/subtitle, no overflow/clipping, body/action reachability, safe area/keyboard constraints, and unchanged modal focus, Escape and callbacks, including Win/Stage Cleared, Adult Gate, Avatar Builder and Coin Shop. Preserve existing compact 48dp actions; global action sizing and unbreakable-word fallback are 05F-02, not authority under 05F-01. All 17 consumers x 3 sizes x 3 scales x 2 themes = 306 planned cases in 05F-03, not completed or authorized by this candidate.
- **Non-negotiable exclusions:** navigation semantics, focus/dismissal behavior, gameplay/modes, scoring, timers, RNG/generator, GameState, GameBrain, progression, persistence/reset, family/privacy, ads, billing/IAP, rewards and single-line attribution footer unchanged. No unrelated refactor. GBI remains first unchecked Active with no order/status/runtime authority change; only the named 05F-01 exception may become effective. 05F-02/03/04, 05G/H/I, AdMob and GBI require separate gates.
- **Evidence / stop rule:** focused modal and Adult Gate tests, existing Results visual workflow and full non-golden suite, analyzer, visual parity against existing goldens (no silent refresh), full diff check and independent final review; report exact SHAs, failures, skips and reviewer provenance. Separate owner visual and merge approvals; device acceptance distinct. If an existing golden differs, report actual diff for separate decision, do not weaken assertions or auto-update. If scope cannot meet acceptance or a regression is found, stop, preserve evidence, request bounded expansion or separate owner-approved rollback; no destructive history changes.

### Activation and authority gates

1. Obtain Goldfish PASS on this exact documentation-only patch before commit/push, verify clean base main and successful CI 46012218178. Create a draft PR with only the three authorized docs; record exact diff/head and review provenance. No code, tests, workflows or merge authorized by this step.
2. Independently review the exact committed candidate, verify its CI, and obtain separate explicit owner governance merge approval. Only after the governance PR merges and current main and post-merge CI are verified does this narrow tracker exception become effective. The word activation does not itself grant implementation authority.
3. Obtain separately recorded owner implementation scope/commit/push authority and fresh pre-implementation Goldfish review on the exact baseline before editing any production/test file. Then implement, test, independently review, and seek separate merge approval. No build/signing/release/production deployment authority is granted. Record subsequent evidence without retroactively rewriting the historical findings.
