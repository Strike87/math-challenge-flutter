# TC-V55B — PR #110 single-use Goldfish review recovery (governance proposal)

> **STATUS: PROPOSED / INACTIVE / NOT REVIEWED / NOT MERGED / NOT ACTIVATED.**  
> **Task ID:** `TC-V55B-REVIEW-RECOVERY-01`  
> **Classification:** CONTINUATION / GOVERNANCE-ONLY  
> **Owner authorization (2026-11-22, Africa/Cairo):** permission to prepare the proposed governance change and a separate docs-only Draft PR. **No approval to merge, activate, waive review, modify code, or release.**

## 1. Fixed scope and purpose

The sole purpose is to request **one additional independent read-only final implementation review** of [PR #110](https://github.com/Strike87/math-challenge-flutter/pull/110) after the first external Muse review was `INCONCLUSIVE` and the original Push/PR CI logs later became available as owner-exported archives.

| Field | Immutable value |
| --- | --- |
| Repository | `Strike87/math-challenge-flutter` |
| Target | PR #110, `test: TC-V55B 144-case Triple domain permutation matrix` |
| Base | `e87d623391f05e219c350366713d5f8569ba6120` |
| HEAD | `e2f3d300996fa120e1b05ab3026f60b7f1559f70` |
| Implementation diff | one new test: `test/target_clash_v55b_triple_permutation_matrix_test.dart` (+199/-0) |
| Frozen instruction | [comment 7079802240](https://github.com/Strike87/math-challenge-flutter/pull/110#issuecomment-7079802240) |
| Original technical contract | [Issue #107 R1](https://github.com/Strike87/math-challenge-flutter/issues/107#issuecomment-7070591871) and [activation contract](https://github.com/Strike87/math-challenge-flutter/issues/107#issuecomment-7079481557) |
| Existing bounded test authority | [PR #109](https://github.com/Strike87/math-challenge-flutter/pull/109) already merged at the listed base; GBI stays the first unchecked Active item |

The historical first Muse review was `INCONCLUSIVE` due to missing original log access and lack of demonstrable isolation. Later GPT-6/Manus preflights returned `BLOCKED — ONE_REVIEW_PER_UNCHANGED_HEAD` without technical acceptance. Retain their original conclusions and provenance; **do not** recast any as `PASS`.

## 2. Proposed one-time exception — **not operative yet**

Only **after** (a) an independent fresh-context governance Goldfish returns `PASS` on this separate documentation PR's exact diff, (b) the owner **separately approves merging that governance PR**, (c) that governance-only merge is verified on `main`, and (d) **the repository owner separately and explicitly approves activation** after the verified governance-only merge, and that approval is captured in a distinct activation record linked to the frozen instruction, this addendum would prospectively supersede **only** the sentence **“One review only per unchanged HEAD”** in [comment 7079802240](https://github.com/Strike87/math-challenge-flutter/pull/110#issuecomment-7079802240) for **one** additional *substantive* independent implementation review of the **exact** PR #110 base/HEAD above.

The **separate activation approval** must be given by the project/repository owner (not inferred from the governance-merge approval). The activation record must include the named approver and authority, decision timestamp with time zone, the specific one-review-only scope, PR #110 exact base/HEAD, the approved governance PR #111 head and verified merge SHA, a permanent link or verbatim dated owner authorization as source evidence, the activated addendum reference, and the explicitly limited one-use lifecycle. The record must be independently checkable before any PR #110 replacement review starts; if any field or explicit owner decision is missing, remain `INACTIVE / BLOCKED`. An earlier general instruction to progress or to merge documentation is not a substitute for this separate recorded approval.

No other term of that frozen handoff is weakened. Historical comments and outcomes stay untouched. This is a proposal to change authorization prospectively, **not** a retrospective reinterpretation of earlier attempts, and does not grant blanket retries for any other PR or SHA.

If a governance reviewer determines a two-document amendment conflicts with `AGENTS.md`, the Tracker, or `docs/egm/WORKFLOW.md`, the result is `BLOCKED`; no silent widening or adoption is permitted.

## 3. Preconditions for the single implementation-review opportunity

Before any substantive review, the prospective reviewer must:

1. Be genuinely separate from the implementer/coordinator and all prior PR #110 reviewers. Disclose the **actual model identity**, context isolation method, and verify that no prior implementer chat, review summaries, `MEMORY.md`, or preloaded project memories enter the reviewing context. If identity/isolation cannot be established, stop `INCONCLUSIVE`.
2. Receive only the immutable source/contract references needed for the implementation audit and the now-effective recovery addendum. Do not inject previous review opinions, transcripts, or coordinator verdicts. A separate governance coordinator may verify eligibility without polluting technical review context.
3. Independently open the complete **owner-exported original GitHub Actions log archives**, not coordinator extracts. Verify archive integrity against the owner-supplied SHA-256 manifest and compare run/job identity, checkout SHA and step metadata with GitHub where possible. Hash agreement proves internal package consistency, **not** remote authenticity. Stop `INCONCLUSIVE` if provenance is inadequate.
4. Verify complete `TARGET_CLASH_V55B_TRIPLE_MATRIX=` lines with all **144 case rows** for both jobs, plus full non-golden test output, `flutter analyze`, VM guard and intended V5.5-A/36k-stress behavior. Never infer counts from green checks.
5. Verify the frozen contract's complete implementation acceptance items 1–7 on primary code at the exact SHA, including 24×6 cases, dual seeds, retained preflight target, typed `MathFact`, tick relations/zones, and `DOES_NOT_PROVE_REAL_GAMESTATE_RNG_SEQUENCE_EQUIVALENCE`. No code modifications or local test execution are authorized by this review.

**Evidence references:** Push run `45027221064`, Flutter job `137222752280`; PR run `45027283169`, Flutter job `137222949277`. Owner-exported handoff ZIP SHA-256: `50665837aec432cdb869cedbe1cd7d36e3cdfe632e9c727e9a72f51a51646e35`. Distinguish the file package's claimed provenance from independently authenticated GitHub content; never request credentials in chat.

A preflight that fails does not issue implementation PASS. It cannot be repeated indefinitely: additional eligibility uncertainty stops the process pending a separately approved decision.

## 4. One-use outcome and expiry

After **one** substantive independent implementation audit, record exactly one terminal `PASS`, `BLOCKED`, or `INCONCLUSIVE`, including reviewer/model, isolation evidence, exact reviewed SHA, UTC/EET timestamp, raw-log/source provenance, P0–P3 findings and unresolved limitations.

The recovery opportunity is **consumed on any terminal substantive outcome**. Do not reset it by changing the HEAD cosmetically, replacing reviewers, relabeling the same-context review, or reusing coordinator evidence. A meaningful candidate/code or contract drift requires separately scoped new governance authorization; it is not covered here.

The opportunity expires on rejection/withdrawal, failed or absent independent governance PASS, lack of separate owner approval, missing merge/activation record, target SHA drift, or consumption by a substantive review. Maintain a non-destructive historical record.

## 5. Independent gates — no automatic merge

- **Gate G1:** independently review this governance-only two-file diff and return `PASS / BLOCKED / INCONCLUSIVE`. This is **not** PR #110 implementation Goldfish.
- **Gate G2:** obtain explicit **owner authorization to merge the governance PR** after independent governance PASS; verify the docs-only merge SHA on `main`. This merge approval is **not** activation approval. Draft publication and governance merge are not activation.
- **Gate G3 (separate owner activation):** **after G2**, obtain and record the project/repository owner's **distinct explicit approval to activate this exact one-review-only exception**, listing approver/authority, date/time zone, PR #111 verified merge SHA, PR #110 immutable base/HEAD, exact permitted scope, one-use expiry, and permalink or dated verbatim source evidence. Link this activation record to the frozen PR #110 handoff. Without explicit owner authorization and a verifiable record, the exception remains `INACTIVE`; no implementation-review retry is allowed.
- **Gate I1:** under an effective addendum only, perform the one isolated read-only implementation Goldfish review with full owner-exported original logs and exact-source validation.
- **Gate I2:** if and only if I1 returns accepted `PASS`, CI and diff scope remain valid, and the owner **separately authorizes merging PR #110 at its exact HEAD**, consider that merge. No automatic merge.
- **Gate C:** any later Tracker exception expiry / EGM register reconciliation requires separate scope and authorization. No production release/build/signing is authorized.

Nothing here changes `AGENTS.md`, general EGM governance, the GBI-first Tracker sequence, TC-V55B's existing bounded test-only authority, `GameState`, GameBrain, UI, persistence, payments, credentials, family/privacy, Flutter source/tests, golden baselines, CI workflows, dependencies, or release policy.

## 6. Risk and rollback

This process addresses a review-eligibility deadlock, not a proven defect. Preserve earlier `INCONCLUSIVE` and `BLOCKED` evidence; do not launder it into PASS. If the proposal is rejected before merge, abandon/close the Draft governance PR without changing `main` or PR #110. If merged but later revoked, use only a separately approved, reviewed history-preserving documentation correction; never force-push, reset a shared ref, or delete the audit trail.

**Current status:** `PROPOSED / INACTIVE / NO ADDITIONAL PR110 REVIEW AUTHORITY / NO MERGE OR RELEASE AUTHORITY`.

## 7. Proposed bounded fallback — **NOT APPROVED / NOT ACTIVE / NO MERGE AUTHORITY**

> **Additional governance proposal only.** Task `TC-V55B-PR110-FALLBACK-01`, classified `CONTINUATION / DOCS-ONLY / PRE-AUTHORIZATION DESIGN`. This section is **not** effective merely because it is present in a Draft branch or PR. The merged independent-review recovery mechanism in §§1–6 and [activation comment 7084820892](https://github.com/Strike87/math-challenge-flutter/pull/110#issuecomment-7084820892) remain the current effective rules until a distinct reviewed and owner-approved change is merged and activated. Do not retrospectively reinterpret the frozen contract.

### 7.1. Reason and eligibility

Multiple distinct external reviewers stopped with `INCONCLUSIVE` at eligibility or could not access the full raw logs: the initial Muse implementation reviewer, Manus cleanroom session `8zCFDcFQUEJdCeuS3D6bPK`, Muse Spark with injected prior `MEMORY.md`, and GPT-6 Temporary Chat unable to certify complete isolation. These results remain **not** independent implementation PASS and do not justify repeated attempts without authorization.

`AGENTS.md` has an existing `OWNER_AUTHORIZED_BOUNDED_FALLBACK_AUDIT` policy for **ordinary bounded feature work** where independent review is demonstrably unavailable after documented attempts. PR #110 introduces **only** one Dart test, `test/target_clash_v55b_triple_permutation_matrix_test.dart` (+199/-0), with **no production, CI, dependencies, user data, persistence, payments, credentials, privacy, schema, or release changes**. This makes it a *candidate* for that policy; it does **not** establish a review PASS. The high-risk exceptions in `AGENTS.md` are NOT waived.

However, the [frozen final review contract](https://github.com/Strike87/math-challenge-flutter/pull/110#issuecomment-7079802240), the TC-V55B Tracker entry, and current §5 Gate I1 still specifically require a *truly independent* implementation Goldfish. **Therefore this fallback cannot be used under current effective governance.** A targeted, prior independently reviewed and owner-approved governance change must explicitly permit it; a coordinator opinion or user desire for speed does not.

### 7.2. Proposed one-time replacement — narrow prospective override

**Only after** all gates in §7.4 complete, and only for [PR #110](https://github.com/Strike87/math-challenge-flutter/pull/110) at unchanged base `e87d623391f05e219c350366713d5f8569ba6120` and HEAD `e2f3d300996fa120e1b05ab3026f60b7f1559f70`, the project owner may authorize **one terminal, read-only, explicitly NON-INDEPENDENT bounded fallback audit** in lieu of the otherwise-mandatory final independent implementation Goldfish. The prospective exception would supersede **only that independent-review requirement** for this specific test-only candidate (including the matching final-review language in the frozen handoff, the Tracker's TC-V55B verification gate, and §5 I1); it would not broaden `AGENTS.md`, reorder GBI, or change any other technical acceptance criteria. It is **not** a precedent, automatic waiver, or second implementation review track.

The already activated independent-recovery path must be recorded as **PAUSED / SUPERSEDED FOR THIS TARGET** at actual fallback activation; it cannot coexist as an unlimited alternate retry option. If the fallback is rejected, remains unapproved, or fails, the old path is **not silently reset or reactivated**.

### 7.3. Exact fallback audit requirements

A reviewer with repository/source and original-log access must inspect the candidate source directly, not rely on coordinator summaries, and record that their audit is **`OWNER_AUTHORIZED_BOUNDED_FALLBACK_AUDIT / NON_INDEPENDENT`**. The reviewer shall:

1. Confirm exact unchanged PR base/HEAD and one-file +199/-0 diff, current Tracker exception, `AGENTS.md`, `docs/egm/WORKFLOW.md`, and immutable contract from Issue #107 / PR #110.
2. Independently **analyze the source and assertions**, including all 24×6 configurations, six canonical orderings, retained ordinary Stage 2 target, deterministic dual seeds, genuine `MathFact` checks, slot relation/zone/tick calculations, typed failure diagnostics, atomic three-question result, and `DOES_NOT_PROVE_REAL_GAMESTATE_RNG_SEQUENCE_EQUIVALENCE`. Clearly identify weaknesses/limits, including whether successful-case slot/fact details are emitted in the machine-readable report.
3. Inspect **both full owner-exported original Push/PR GitHub Actions archives**, confirm each nested archive SHA-256, check exact job/run/checkout identity against GitHub to the extent possible, parse all 144 `rows`, revalidate 24 configurations and seed sequences, verify `+1439 ~2`, analyzer success, V5.5-A 36 cases, skipped R3 stress, and the separate VM guard conclusions. Recognize that ZIP internal consistency alone does **not** establish remote authenticity.
4. Disclose unavailable tests/tools, the absence of an independent reviewer, any P0–P3 findings, and the bounded nature of `DOMAIN_ONLY` coverage. Do not assert a separate focused `flutter test` invocation if none occurred. Do not conceal uncertainty or infer validity from green CI alone.
5. Return exactly `PASS / BLOCKED / INCONCLUSIVE` **as a bounded fallback decision**, with reviewer identity/model, provenance, SHA, date/timezone, evidence sources, P0–P3, risk and unresolved limitations. Never label it `Goldfish PASS` or an independent audit.

No implementation editing, new commits, CI changes, GitHub reviewer posts or merges by the fallback reviewer.

### 7.4. Prospective authorization gates

- **F0 — Governance amendment review:** create a distinct docs-only Draft proposal with the matching appended Tracker entry; obtain a genuine independent **governance-diff** review `PASS` on that exact proposal HEAD. If unavailable, `BLOCKED`, not silently bypassed. This review must assess precedence over the frozen implementation contract and GBI tracker authority.
- **F1 — Governance merge:** **separate explicit owner approval to merge** the amended docs-only governance PR after F0 PASS and successful CI; verify the governance merge SHA on `main`. Neither approval nor merge activates fallback.
- **F2 — Distinct fallback activation and execution authorization:** after F1, the owner explicitly authorizes *this* one-time non-independent fallback audit of PR #110 and its execution, with an auditable record naming approver, authority, date/time zone, permanent source decision evidence, exact PR #110 SHA, reviewed governance HEAD / merge SHA, original independent-recovery pause, permitted reviewer, read-only scope, one-use consumption and expiry. This must be distinct from governance merge consent. No F2 means **INACTIVE**.
- **F3 — One bounded technical audit:** follow §7.3; a terminal substantive `PASS`, `BLOCKED` or `INCONCLUSIVE` **consumes the one-use fallback slot**. No change of SHA, cosmetic resubmission, or retry by another reviewer to reset the slot.
- **F4 — Owner merge decision:** only if F3 returns a supported bounded `PASS`, verify still-current CI/diff/branch protections and obtain **another explicit owner approval to merge PR #110**, fully disclosing that final review was *non-independent*, not Goldfish. A `PASS` is necessary but **not** itself authority to merge. If merge occurs, close/expire the TC-V55B single-use Tracker exception separately as authorized. No product release is authorized.

**Exclusions:** production `GameState`, RNG or behavior changes, new tests or goldens, `AGENTS.md`, `WORKFLOW.md`, CI, dependencies, payments, credentials, user data, unrelated work items, device acceptance, build/signing/release. Any discovered P0/P1 or insufficient authenticated evidence requires `BLOCKED` or `INCONCLUSIVE`, not an automatic exception.

**Proposed status today:** `DOCS_PROPOSAL_ONLY / NOT INDEPENDENTLY_REVIEWED / NOT MERGED / NOT ACTIVE / NO FALLBACK REVIEW AUTHORITY / NO MERGE AUTHORITY`.


### 7.5. Proposed exceptional F0 substitution — OWNER REQUESTED / NOT EFFECTIVE

**Task:** `TC-V55B-PR112-GOVERNANCE-REVIEW-EXCEPTION-01`. **Classification:** `GOVERNANCE-ONLY / PROSPECTIVE / SINGLE-TARGET / NON_INDEPENDENT`. This paragraph is a **proposed amendment to the F0 prerequisite itself**, not evidence that F0 has already passed. It is not a self-executing waiver. It applies only to the governance-diff review of PR #112 and must not be construed as an independent Goldfish PASS, a generic amendment to `AGENTS.md` or `WORKFLOW.md`, or authorization to review or merge PR #110.

**Recorded owner instruction:** In the coordinating ChatGPT conversation on **2026-11-23 (Africa/Cairo, UTC+02:00)**, after two Claude reviews returned `INCONCLUSIVE / SOURCE_SCOPE_LIMIT`, the owner requested `اعمل انت المراجعه دى اعمل استثناء` (perform the review yourself and make an exception). When asked specifically whether to **modify PR #112 to add an explicit non-independent governance-review exception** while preserving separate approvals, the owner replied `موافق` (approved). This is a coordinator-recorded user instruction, **not** a signed GitHub owner approval, independent review, or merge/activation authorization.

**Proposed narrow precedence rule:** For this exact PR #112 governance amendment **only**, if the project owner subsequently approves merging the complete amended governance diff, the owner may **explicitly accept one disclosed, read-only, non-independent governance audit** in place of the independent governance-diff PASS otherwise required by §7.4 F0, §5 G1, the Tracker and EGM Gate 2. This is a **specific prospective exception to those independence prerequisites**, not a claim that those requirements were already satisfied. The owner must explicitly acknowledge this deviation and its residual conflict-of-interest risk at the separate merge-decision gate. All other gates, including complete-source and exact-SHA verification, successful CI, one-use F2/F3, and separate F4 merge permission, remain mandatory. No broader change to project-wide reviewer policy or GBI ordering is authorized.

**Qualifying audit and evidence:** The coordinating GPT-6 assistant's initial source review is **NON_INDEPENDENT / PRELIMINARY**, and **cannot be treated as a final F0 PASS for a changed HEAD**. After this paragraph and its matching Tracker entry are committed, one bounded read-only audit must inspect the **entire new PR #112 diff at its new exact HEAD**, full relevant governance files at base and HEAD, frozen PR #110 handoff and activation comments with primary GitHub provenance, and exact-head CI evidence. The audit must report its own identity/model as actually known, coordinator-context contamination, UTC/EET timestamp, source URLs/SHAs, P0–P3 findings, precedence analysis, and `PASS / BLOCKED / INCONCLUSIVE` expressly labeled `OWNER_AUTHORIZED_NON_INDEPENDENT_GOVERNANCE_AUDIT`. Any `BLOCKED` or `INCONCLUSIVE` stops this route; no retroactive PASS or unlimited attempts. One terminal substantive outcome consumes this audit opportunity.

**Approval sequencing (replaces only F0 independence for this target):**
- **F0-NI:** perform and record the one exact-HEAD, fully sourced **non-independent** governance audit. It may support, but cannot itself authorize, a merge.
- **F1-NI:** only following a supported F0-NI `PASS` and verified CI, request a **new, separate, explicit owner decision** to accept the disclosed non-independent governance review and merge PR #112. Record the deviation, risk acceptance, source decision and merge SHA on `main`. The current `موافق` authorizes drafting this proposal **only**, not F1-NI.
- **F2–F4 unchanged:** only after F1-NI merge, request a **different owner approval** to activate and execute the one-use non-independent PR #110 technical fallback, pause the existing independent-review recovery route, and require a final distinct owner approval before any PR #110 merge. No release authority.

**Fail closed:** Until this amendment is validly merged and its distinct approvals are recorded, the existing independent F0 requirement remains effective and unsatisfied. This proposal must not be used to declare an independent governance PASS, bypass technical acceptance, merge either PR, or silently change existing historical findings.
