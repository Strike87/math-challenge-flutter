# P1-F01 readiness recheck after the locked v1.2 no-replacement envelope

## 1. Record

| Field | Value |
| --- | --- |
| Artifact type | Documentation-only readiness recheck |
| Repository | `D:\FlutterProjects\math_challenge_flutter_p1f01_next` |
| Audited HEAD | `932129e6225f8d55a3769ffae12cf6fdf868b30c` — "Implement P1-F00 v1.2 no-replacement envelope" |
| Protocol basis | P1-F00 v1 (LOCKED / HISTORICAL), P1-F00 v1.1 (LOCKED / CURRENT PROSPECTIVE PROTOCOL), P1-F00 v1.2 no-replacement envelope amendment (amendment text = `c11dd39`; lock status = established by the companion lock declaration `docs/game_brain_p1_f00_v1_2_lock_declaration.md`) |
| Implementation basis | `703bee7` integrity store, `231fe27` device probe, `1f05bd5` deterministic transaction-boundary validation, `263ff9e` boundary identity, `932129e` v1.2 envelope implementation |
| Evidence basis | `docs/game_brain_p1_f01_device_integrity_validation.md`, `docs/game_brain_p1_f01_post_r4_measurement_readiness_rerecheck.md` |
| Governance basis | `GD-P1F01-INTEGRITY-001` (AUTHORIZED) |
| Confirmatory window | CLOSED / NOT OPENED |
| Outcome data | NOT INSPECTED |
| Production code changed by this artifact | NONE |
| Tests changed by this artifact | NONE |
| Authority change | NONE |
| Revision | Corrected after review: reconciled identified physical-device boundary trials (`P1_F01_ANDROID_TRANSACTION_BOUNDARY = DEVICE_PROVEN`) were incorporated; the previously stated pending device-validation blocker was removed as already closed. Second correction pass: fixed §2 firewall/reconciliation wording, scoped K_under to confirmatory-eligible divergence only, downgraded Property 11 to source/unit evidence, and restated study-evidence claims as audit-scope statements rather than proofs of absence. |

This artifact supersedes no historical document and overwrites nothing. It is
a re-evaluation only. No confirmatory window is opened and no feasibility is
claimed.

## 2. What commit `932129e` actually implements

The production diff is exactly eight lines in `lib/engine/game_state.dart`
plus a focused test file:

1. A `@visibleForTesting` accessor
   `debugP1F01IntegrityRunEligible => _p1F01IntegrityRunEligible`.
2. In the `PowerUp.switchOp` branch of `usePowerUp`, after the synchronous
   terminal claim succeeds and **before** any replacement question can open,
   a call to `_leaveP1F01IntegrityUnclean()`.

Audited semantics against locked v1.2 §2:

| v1.2 requirement | Implementation observation | Verdict |
| --- | --- | --- |
| Synchronous local admission-disabled state before replacement `_generateQ()` executes | `_leaveP1F01IntegrityUnclean()` sets `_p1F01IntegrityRunEligible = false` synchronously; the replacement generation runs later inside a 500 ms `Timer`. The firewall is established strictly before the replacement opening can exist. | SATISFIED |
| No further admissions from that run enter confirmatory evidence | Every admission/reconcile/close path guards on `_p1F01IntegrityRunEligible`; once false, `_admitP1F01DifficultyOpportunityIfSupported`, `_reconcileP1F01TerminalIfSupported`, and `_closeP1F01IntegrityCleanly` all return without touching the store. | SATISFIED |
| Gameplay continues normally and unchanged | The power-up is not blocked, delayed, or capped; the replacement timer, terminal claim, and QEO capture flow are untouched. The focused test suite proves turn accounting, acceptance state, and question replacement are unchanged. | SATISFIED |
| Durable `LEFT_UNCLEAN` bookkeeping may complete asynchronously; gameplay never awaits it | `_leaveP1F01IntegrityUnclean()` enqueues `markLeftUnclean()` via `unawaited(...)` on the store's serialized queue. Nothing in the switchOp path awaits it. | SATISFIED |
| `mayAffectGameplay = false` | The hook only mutates measurement-layer eligibility flags and durable bookkeeping. No gameplay decision reads them. | SATISFIED |

Two ordering facts are recorded for completeness, and they are not in
conflict:

- Canonical/QEO capture of the `QuestionReplaced` observation may occur while
  the durable `LEFT_UNCLEAN` persistence is still pending. This is explicitly
  permitted by v1.2 §2 ("durable `LEFT_UNCLEAN` bookkeeping ... is bookkeeping
  evidence of the exclusion, not a prerequisite for gameplay progression").
- After the synchronous firewall, no P1-F01 admission, reconciliation, or
  clean-close may enter durable accounting from that run: every such path
  guards on `_p1F01IntegrityRunEligible`, which is already false. The window
  ends `LEFT_UNCLEAN` either way, so its openings remain excluded from
  confirmatory use.

## 3. Bound semantics honored

Canonical eligible `chooseDifficulty` opening remains `O_raw` truth. Durable
storage records that truth; the durable commit does **not** redefine whether
the canonical opportunity occurred. Replacement-generated questions remain
full canonical gameplay truth; they are prospectively excluded from the v1.2
confirmatory-eligible `O_raw` population only. `LEFT_UNCLEAN` windows retain
their canonical openings as historical truth.

## 4. Re-evaluation of the eleven locked v1.1 §15 properties

Status vocabulary: `SOURCE_PRESENT` (implementation exists at HEAD),
`UNIT_EVIDENCE` (focused test coverage exists at HEAD),
`DEVICE_EVIDENCE` (physical-device proof recorded),
`DEVICE_PARTIAL` (partial physical proof recorded),
`NOT_VALIDATED`, `NOT_IMPLEMENTED`.

Labels refer to the strongest available evidence tier per property; weaker
tiers are implied where a stronger one is claimed.

| # | Locked property | Status at `932129e` | Basis |
| ---: | --- | --- | --- |
| 1 | Complete detection of admitted unclean windows | SOURCE_PRESENT; UNIT_EVIDENCE; DEVICE_EVIDENCE | `recoverOpenWindows()` transactionally converts every durable `OPEN` to `LEFT_UNCLEAN` before new admission; `admitWindow()` performs the same conversion inline. Device G1 (`OPEN` → force-stop → relaunch → durable `LEFT_UNCLEAN`) and G2 (repeated recovery with no duplication) are PROVEN. The switchOp path adds a second, synchronous route to the same fail-closed state. |
| 2 | Monotonic admitted `O_raw` | SOURCE_PRESENT; UNIT_EVIDENCE; DEVICE_EVIDENCE | `admitted_o_raw_count` increments only inside the admission transaction and is never decremented by reconcile, close, recovery, or the new switchOp path. Device snapshots show counts stable or increasing across kill/restart/recovery. |
| 3 | Exact legal-set / candidate membership | SOURCE_PRESENT; UNIT_EVIDENCE; DEVICE_EVIDENCE | `P1F01LegalSetCode` serializes the exact Phase-1 mask (`V1_EMH_MASK_[1-7]`) or explicit `V1_UNKNOWN`; counters are keyed by `(window_sequence, legal_set_code)` with upsert-in-transaction. Device records show exact codes (`V1_EMH_MASK_7`). Uncertain membership stays `UNKNOWN`; nothing is fabricated. |
| 4 | Crash-consistent durable commits | SOURCE_PRESENT; UNIT_EVIDENCE; DEVICE_EVIDENCE | All accounting advances inside single SQLite transactions (`db.transaction`). The deterministic identified physical-device boundary trials are complete and PASS on both sides of the commit: the identified BEFORE_COMMIT trial captured exact `{windowSequence, opportunityOrdinal, phase}`, was force-stopped at the boundary, and showed no durable admission, no `O_raw`/legal-counter increment, no partial transaction state, and recovery to `LEFT_UNCLEAN`; the identified AFTER_COMMIT_BEFORE_ACK trial captured the exact immutable boundary identity, was force-stopped after commit before higher-level acknowledgement, and showed the complete admission persisted atomically with consistent `O_raw`/ordinal/legal-counter state and restart recovery to `LEFT_UNCLEAN`. Frozen conclusion: `P1_F01_ANDROID_TRANSACTION_BOUNDARY = DEVICE_PROVEN`. |
| 5 | Finite outstanding-accounting gap | SOURCE_PRESENT; UNIT_EVIDENCE; DEVICE_EVIDENCE | Ordinal mismatch/gap paths fail closed to `LEFT_UNCLEAN` with a defect marker inside the admission transaction; reconciliation requires strict ordinal adjacency. Device F2 gap/conflict retries returned `failedClosed` with zero accounting inflation, and the identified BEFORE_COMMIT boundary trial showed no partial transaction state and no counter increment at the interruption instant. The residual gap between last admitted and last reconciled ordinal within one window is bounded by the window's own opening count. |
| 6 | Idempotent recovery/retry or finite duplicate bound | SOURCE_PRESENT; UNIT_EVIDENCE; DEVICE_EVIDENCE | Same-ordinal/same-code retry returns `alreadyAdmitted` with no mutation; contradictory retry fails closed. Device F1 (twice-repeated `retryExact` → `alreadyAdmitted`, counters unchanged) and fresh-window F2 conflict/gap fail-closed results are PROVEN for exercised store semantics. |
| 7 | Finite validated `K_under` | FINITE_UNIFORM_CEILING_ESTABLISHED; NOT_EXACT_EQUALITY | See §5. The v1.2 envelope supplies a uniform conservative ceiling of 25 per admissible window, and the identified BEFORE_COMMIT device trial empirically confirmed the undercount mechanism (no durable admission at the interruption instant, recovery to `LEFT_UNCLEAN`). Exact equality to any specific number is not claimed. |
| 8 | Finite `K_over` | ZERO_BY_CONSTRUCTION; DEVICE_CONFIRMED | See §6. Production `K_over = 0` holds by construction: durable units exist only through the admission transaction that a just-occurred canonical opening invoked; the identified AFTER_COMMIT_BEFORE_ACK trial confirmed atomic all-or-nothing persistence with no duplicate or orphan unit; debug/validation injection surfaces are debug-build + flag gated and write no production accounting rows. |
| 9 | Defensible divergence direction | UNDERCOUNT_ONLY — ESTABLISHED | See §7. With `K_over = 0` by construction and device-confirmed atomic commit behavior, plus a finite uniform undercount ceiling, the only possible divergence direction is undercount. |
| 10 | Conservative threshold evaluability | PROTOCOL_PRESENT; NO_CONFORMING_STUDY_EVALUATOR_VERIFIED_IN_THIS_RECHECK | v1.1 §14 conservative bounded-uncertainty semantics exist on paper only. No conforming implementation of an `O_valid` evaluator, common-support evaluator, temporal/run segmentation, cross-run aggregation, Wilson evaluator, or final FEASIBLE/INCONCLUSIVE/NOT_FEASIBLE adjudicator was verified or identified in this readiness recheck; the exhaustive component inventory is the next bounded audit. Property 10 is NOT complete. |
| 11 | Gameplay independence from measurement-storage success | SOURCE_PRESENT; UNIT_EVIDENCE | All store calls are fire-and-forget (`unawaited`) behind a serialized queue; failures set measurement-failed flags read by no gameplay path. Storage-failure unit tests show fail-closed integrity handling without canonical gameplay mutation. No physical-device storage-failure gameplay-independence trial is cited in the recorded evidence, so no DEVICE_EVIDENCE tier is claimed for this property. The v1.2 hook strengthens the source-level guarantee: the exclusion is synchronous local state, so gameplay never waits on SQLite. |

## 5. `K_under` under the locked v1.2 envelope

Claim evaluated:

```text
VALIDATED_UNIFORM_K_UNDER_CEILING <= 25   (per single admissible window)
```

Derivation, each step traced to audited facts:

1. A supported no-replacement run has at most `maxTurns = 1 × questionTarget`
   eligible canonical openings, with `questionTarget ∈ {10, 15, 20, 25}` — so
   at most 25.
2. Warm-up questions consume the same unconditional terminal turn increment;
   they are inside that budget.
3. Answer/incorrect/timeout/skip all converge on one handler performing
   exactly one turn increment per consumed turn.
4. `switchOp` is the only supported-envelope generation path bypassing the
   turn budget — and since `932129e`, a requested switchOp synchronously
   disables further admissions before the replacement opens, so replacement
   openings contribute zero additional admitted openings.
5. Therefore the maximum number of true admitted canonical `O_raw` openings
   that could be absent from durable accounting at any integrity-failure
   boundary cannot exceed the total openings of one window: **25**.

Verdict: the uniform conservative ceiling

```text
VALIDATED_UNIFORM_K_UNDER_CEILING <= 25
```

is **supported prospectively** for a single admissible window. Per locked
instruction, exact equality (`K_under == 25`) is NOT claimed; the evidence
proves an upper bound, not the attained value. Conservative notation is used
throughout: `0 <= K_under <= 25` per window, ceiling uniform across all
admissible confirmatory executions.

Scope clarification: `K_under` measures divergence between confirmatory-
eligible canonical `O_raw` and durable accounting. The v1.2 protocol exclusion
of switchOp replacement openings is **not** K_under, because those openings
are prospectively outside the v1.2 confirmatory-eligible `O_raw` population;
they are canonical gameplay truth, but never part of the population whose
durability K_under bounds. An admission whose atomic transaction commits is
durably complete; this does not prove global `K_under = 0`, because process
loss before commit remains physically possible for eligible openings.

This satisfies the v1.1 §12 requirement that `K_under` be finite, uniform, and
validatable before confirmatory collection opens. The identified
BEFORE_COMMIT device trial empirically exercised exactly this undercount
mechanism: force-stop at the boundary produced no durable admission, no
counter increment, no partial state, and recovery to `LEFT_UNCLEAN`. The
ceiling is a conservative uniform upper bound, not exact equality; the
attained per-window value remains bounded by `0 <= K_under <= 25`.

## 6. Production `K_over = 0`

Evaluated and **retained**:

- A durable accounting unit (window-row increment + counter upsert) is created
  only inside `admitOpportunity`'s single transaction, which runs only when a
  canonical eligible opening has just occurred and the run is admission-
  eligible.
- Idempotence (`alreadyAdmitted` on exact retry) prevents duplicate units from
  retry; contradiction paths fail closed without inserting anything.
- Recovery converts status only; it never inserts accounting units.
- The transaction-boundary controller and device probe are gated by
  `kDebugMode && P1_F01_DEVICE_VALIDATION=true`; their invocation counters are
  test-only fields never read in production paths, and they insert no rows.
  Validation-only debug injection is therefore excluded from production
  accounting.

No path exists at HEAD by which a durable unit outlives its canonical-opening
cause. `K_over = 0` holds by construction for production code, and the
identified AFTER_COMMIT_BEFORE_ACK device trial confirmed the atomic,
all-or-nothing persistence that the construction relies on: the complete
admission persisted consistently with no duplicate or orphan unit.

## 7. Divergence direction

`DIVERGENCE_DIRECTION = UNDERCOUNT_ONLY` remains **defensible**:

- Overcount divergence requires `K_over > 0`; production `K_over = 0` by
  construction (§6).
- Undercount divergence refers only to divergence between confirmatory-
  eligible canonical `O_raw` and durable accounting — e.g. process loss of an
  eligible opening before its admission transaction commits. It does not
  include the v1.2 switchOp exclusion, which is a prospective protocol rule,
  not accounting divergence.
- `NONE` is not claimed because that eligible-opening undercount remains
  physically possible and was exactly the mechanism exercised by the
  identified BEFORE_COMMIT device trial (force-stop at the boundary produced
  no durable admission; the opening was lost to accounting while remaining
  canonical truth).

The direction claim is closed: `K_over = 0` excludes overcount, the finite
uniform ceiling bounds undercount, and the identified device trials confirmed
both the no-partial-commit and atomic-persist behaviors on physical hardware.

## 8. G → F → E status

| Step | Status at `932129e` | Remaining gap |
| --- | --- | --- |
| G — complete admitted-window detection | PROVEN (device) + strengthened by v1.2 synchronous firewall | None identified for the exercised scenarios. |
| F — idempotent recovery / finite duplicate bound | PROVEN (device) for exercised store semantics: exact retry, conflict fail-closed, gap fail-closed, repeated recovery without inflation | None identified for the exercised scenarios. |
| E — finite `K_under`, `K_over`, divergence direction | CLOSED: uniform conservative ceiling `K_under <= 25` per window (not exact equality); `K_over = 0` by construction; `UNDERCOUNT_ONLY`. The identified BEFORE_COMMIT and AFTER_COMMIT_BEFORE_ACK physical-device trials both PASS (`P1_F01_ANDROID_TRANSACTION_BOUNDARY = DEVICE_PROVEN`), confirming no partial transaction state at the pre-commit boundary and atomic consistent persistence at the post-commit boundary. | None identified for the integrity-accounting foundation. |

## 9. INTEGRITY READINESS vs STUDY EVIDENCE READINESS

These are separate claims and are assessed separately.

### INTEGRITY READINESS

The integrity mechanism itself — window admission, monotonic accounting,
exact legal-set membership, crash-consistent transactions, complete unclean
detection, idempotent recovery, finite bounded divergence, and gameplay
independence at source level — is implemented, focused-tested, and
device-proven for the properties whose evidence tiers claim it (properties
1–6 device-backed per §4; property 11 source/unit-backed). The v1.2
no-replacement envelope closes the last known supported-envelope generation
leak (switchOp replacements) with a synchronous, fail-closed,
gameplay-neutral firewall, and supplies the uniform conservative `K_under`
ceiling that v1.1 §12 required before collection could even be contemplated.
The identified physical-device boundary trials closed the final transaction-
boundary evidence gap: `P1_F01_ANDROID_TRANSACTION_BOUNDARY = DEVICE_PROVEN`.

No implementation work remains for the integrity-accounting foundation.

### STUDY EVIDENCE READINESS

Study evidence is a different pipeline and is not ready. In this readiness
recheck, no conforming implementation was verified or identified for any of
the following components (this is an audit-scope statement, not a proof of
absence; the exhaustive inventory is exactly the Phase-1 audit of the next
bounded task):

| Component | Status in this recheck |
| --- | --- |
| `O_valid` evaluator (required-field validity, linkage, executed-difficulty-in-legal-set) | NO CONFORMING IMPLEMENTATION VERIFIED/IDENTIFIED IN THIS RECHECK |
| Common-support evaluator (full 14-dimension key, `S_support` / `S_qual` construction) | NO CONFORMING IMPLEMENTATION VERIFIED/IDENTIFIED IN THIS RECHECK |
| Temporal segmentation (canonical segment order, quintile construction) | NO CONFORMING IMPLEMENTATION VERIFIED/IDENTIFIED IN THIS RECHECK |
| Run segmentation (segment identity, ≤25% concentration, ≥10 segments) | NO CONFORMING IMPLEMENTATION VERIFIED/IDENTIFIED IN THIS RECHECK |
| Cross-run aggregation (pooled evidence across ≥10 runs) | NO CONFORMING IMPLEMENTATION VERIFIED/IDENTIFIED IN THIS RECHECK |
| Wilson precision evaluator (95% half-width ≤ 0.15 per candidate over pooled `C_qual`) | NO CONFORMING IMPLEMENTATION VERIFIED/IDENTIFIED IN THIS RECHECK |
| Final FEASIBLE / INCONCLUSIVE / NOT_FEASIBLE adjudicator (v1 ordered terminal rules) | NO CONFORMING IMPLEMENTATION VERIFIED/IDENTIFIED IN THIS RECHECK |

The integrity store intentionally persists none of the study-evidence payload
(QEO content, support keys, order facts); a separately governed
retention/aggregation mechanism is required for study evidence, and its
architecture is not selected here.

Property 10 is therefore NOT complete — and this incompleteness blocks
STUDY EVIDENCE readiness only. It does not qualify the now-closed
integrity-accounting foundation: properties 1–9 and 11 are established, the
G → F → E proof is closed with `P1_F01_ANDROID_TRANSACTION_BOUNDARY =
DEVICE_PROVEN`, and no confirmatory metric is currently evaluable solely
because the evaluators that would consume integrity-clean evidence do not
exist yet.

## 10. Final statuses

```text
P1_F01_INTEGRITY_READINESS       = READY

P1_F01_STUDY_EVIDENCE_READINESS  = NOT READY
                                   (no conforming O_valid, common-support,
                                    temporal/run segmentation, cross-run
                                    aggregation, Wilson evaluation, or final
                                    adjudication implementation verified or
                                    identified in this recheck)

P1_F01_CONFIRMATORY_WINDOW       = CLOSED / NOT OPENED
```

`P1_F01_INTEGRITY_READINESS = READY` is stated without qualification: the
integrity-accounting foundation is implemented and focused-tested, and
physical-device evidence exists for the lifecycle, recovery, retry, and
identified transaction-boundary properties described in §4 (Property 11
remains source/unit-backed). It does NOT mean study
evidence is ready; that is a separate pipeline that is not ready — no
conforming study-evidence implementation was verified in this recheck, and
that determination stands until the exhaustive inventory is complete (§9,
§11).

No outcome data was inspected. No authority was expanded. `mayAffectGameplay =
false` remains true.

## 11. Exact next bounded engineering task

If this audit is accepted, the single next bounded task is:

**BOUNDED STUDY EVIDENCE PIPELINE FOUNDATION.**

This task is an audit-first, implementation-second slice:

Phase 1 — audit (read-only):

1. Inventory which frozen P1-F00 v1/v1.1 evaluability components already
   exist in the repository at HEAD, component by component: `O_valid`
   evaluator, common-support evaluator (`S_support` / `S_qual`), temporal
   segmentation, run segmentation, cross-run aggregation, Wilson precision
   evaluator, and final FEASIBLE / INCONCLUSIVE / NOT_FEASIBLE adjudicator.
2. For each existing component, record its source location and whether it
   satisfies the locked definitions exactly (full 14-dimension support key,
   strict threshold boundaries, ordered terminal precedence, conservative
   abstention semantics).
3. For each missing or nonconforming component, identify the smallest
   protocol-conformant implementation slice that would close it.

Phase 2 — smallest implementation slice:

4. Implement only the single smallest missing slice identified by the Phase-1
   audit, under a separately approved scope. Any new retention of
   study-evidence payload requires separate governance authorization beyond
   `GD-P1F01-INTEGRITY-001`.

Out of scope for this task: opening the confirmatory window, inspecting any
outcome data, changing gameplay, amending locked v1/v1.1/v1.2 documents, and
modifying the proven integrity-accounting foundation.

## 12. Review requirement

This recheck is documentation-only and stops here for independent review. It
does not authorize implementation, capture beyond `GD-P1F01-INTEGRITY-001`,
collection, or window opening.
