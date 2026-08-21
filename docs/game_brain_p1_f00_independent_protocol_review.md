# Independent review — P1-F00 difficulty evidence feasibility protocol

## Review record

| Field | Value |
| --- | --- |
| Review target | commit `01548894cd38708e33123c02edc84e7255b0c7af` |
| Protocol | `P1-F00 v1`, `DRAFT_FOR_INDEPENDENT_REVIEW` |
| Target document | `docs/game_brain_p1_f00_difficulty_evidence_feasibility_protocol.md` |
| Reviewer role | Independent Protocol Approver / Reviewer |
| Independence | `PROCEDURAL_INDEPENDENCE_ONLY` |
| Outcome visibility | Outcome blind; no real or synthetic result dataset inspected |
| P1-F01 status | Not run; no P1-F01 outcome calculated or inspected |
| Recommendation | `APPROVE_WITH_REQUIRED_CHANGES` |

The reviewer did not author or modify the protocol under review. This artifact
records a prospective critique only. It is not a P1-F01 result, Protocol Lock,
Gate adjudication, gameplay-authority approval, or Scenario Library approval.

## Finding summary

| Severity | Count | Disposition |
| --- | ---: | --- |
| Blocking | 0 | None. The design is salvageable without architectural redesign. |
| Major | 5 | Must be corrected before Protocol Lock. |
| Minor | 3 | Must be clarified with the major corrections. |
| Note | 3 | Boundaries that should remain unchanged. |

### Major findings

#### M1 — Common support is not fully defined

The comparable-context key omits `decisionLocus`, the exact canonical legal
candidate set, and a bounded representation of player-agency constraints or
selection route. The protocol also does not require candidates compared in a
stratum to share common support. Easy, Medium, and Hard could therefore each
meet their thresholds in disjoint strata while the protocol appears to support
a candidate comparison. This is a false-pass path.

#### M2 — Analysis-set denominators and formulas are incomplete

The protocol does not fully define the opportunity analysis set, candidate
missingness denominator, candidate-balance membership and zero-count handling,
the population of strata used for starvation, or how run segments and
calendar/run-order quintiles are constructed. “Qualifying stratum” is used in
the starvation rule before its membership rule is fixed, creating a circular
denominator that could omit the very starving strata the metric should detect.
The terminal rules cannot be reproduced mechanically until these formulas are
prospectively specified.

#### M3 — Comparable-sample threshold semantics and interactions are ambiguous

“At least 30 episodes per difficulty in at least 3 qualifying strata” does not
say whether 30 is required in each stratum, in total across three strata, or in
some other allocation. The relationship among the 300 total, 60-per-candidate,
30-comparable-sample, and legal-coverage thresholds is also not stated. With at
least 300 eligible opportunities, 40% legal coverage implies at least 120 legal
opportunities, making the separate minimum of 30 redundant. These interactions
could create accidental permanent `INCONCLUSIVE` behavior or permit inconsistent
implementations. No replacement numbers are recommended before the semantics
are fixed.

#### M4 — The Wilson precision target has no defined estimand

The protocol requires a 95% Wilson interval half-width no greater than 0.15 for
“terminal-outcome proportion,” but GEI-04B has five accepted terminal outcomes
in this slice. It does not identify the binary numerator, denominator,
candidate/stratum aggregation, or handling of multiple terminal categories.
Wilson intervals are appropriate only after each intended binomial proportion
is explicitly defined. The current precision gate is not reproducible.

#### M5 — Terminal precedence is contradictory

The protocol says to apply `FEASIBLE`, `INCONCLUSIVE`, and `NOT_FEASIBLE` “in
order,” but the `INCONCLUSIVE` rule depends on first knowing that no
`NOT_FEASIBLE` rule applies. Several failures can also satisfy the broad
`INCONCLUSIVE` language while matching a later predeclared `NOT_FEASIBLE` case.
The statuses are not yet mutually adjudicable by a mechanical procedure.

### Minor findings

#### m1 — Root-cause taxonomy scope is unclear

The taxonomy does not name missingness, unavailable measurement, or precision
failure. The protocol must either add suitable classifications or explicitly
state that the listed taxonomy applies only to asserted `NOT_FEASIBLE` root
causes and that `INCONCLUSIVE` records separate reason codes.

#### m2 — Test visibility is not an authorized analysis path

The collector exposes an immutable snapshot through debug-facing `GameState`
accessors used by tests. That verifies current QEO availability, but it is not
an authorized P1-F01 execution or export path. The measurement terminology
should distinguish “present in current runtime/test-visible state” from
“available to a governed P1-F01 measurement plan.”

#### m3 — Enablement is implied, not independently evidenced

Effective GameBrain enablement is derivable from the current capture invariant:
the runtime adds a QEO only when effective enablement is true at accepted
completion. There is no independent per-observation provenance field, however.
The audit should distinguish derivability from independent auditability instead
of classifying the fact simply as unavailable.

### Notes

- The eligible-episode definition correctly says an ordinary QEO alone is not
  a `chooseDifficulty` episode and truthfully requires a future canonical
  opportunity, legal-option, and linkage seam.
- Natural/canonical starvation is correctly observational. The protocol does
  not attribute starvation to GameBrain, which still has no gameplay authority.
- `UNKNOWN` is not bad fit, lack of exposure is not negative evidence, and
  canonical unavailability is not candidate failure.

## Threshold-by-threshold assessment

No alternate threshold value is proposed. Numerical changes would be arbitrary
until the affected definitions, estimands, denominators, and interactions are
fixed.

| Threshold | Operational? | Prospectively measurable? | Protection and failure challenge | Assessment |
| --- | --- | --- | --- | --- |
| Total eligible opportunities `>=300` | Partial | Not with GEI-04B alone | Limits tiny-N conclusions, but the opportunity analysis set and missing/unlinked opportunity treatment are undefined. Raw N cannot establish common support. | Retain for revision; define denominator and interaction with candidate thresholds. |
| Natural exposure `>=60` per difficulty | Partial | Future seam required | Protects against incidental exposure, but does not require comparable exposure among candidates and interacts ambiguously with the 30-sample gate. | Retain for revision; define analysis set and relationship to comparable N. |
| Effective comparable sample `>=30` per difficulty in `>=3` strata | No | Future seam required | Intends repeated context control, but “30 in 3” is ambiguous and disjoint candidate strata can pass. It may be either permissive or unnecessarily restrictive depending on implementation. | Required change. |
| Run diversity `>=10` segments; no segment `>25%` of candidate evidence | Partial | Future seam required | Prevents one activity period from dominating, but segment boundaries, independence, candidate denominator, and cross-run treatment are undefined. | Required formula clarification. |
| Missingness `<=5%` global and `<=10%` per candidate | Partial | Future seam required | Candidate-specific threshold is useful, but candidate assignment and denominator for missing/unlinked records are undefined; systematic missingness can be hidden by excluding records before denominator construction. | Required formula clarification. |
| Candidate imbalance ratio `<=3.0` within a qualifying stratum | Partial | Future seam required | Limits observed domination only if stratum membership and common support are defined. The rule does not state which legal candidates enter the ratio or how zero counts are handled. | Required formula clarification. |
| Legal-option coverage `>=40%` and `>=30` opportunities per candidate | Partial | Future seam required | Correctly separates legal-but-unexposed from not-legal, but does not ensure pairwise/common-support coverage. Given total N `>=300`, 40% already implies `>=120`, so the 30-count limb is redundant. | Retain rate only if justified; explain or revise count interaction. |
| Starvation `<=20%` of qualifying strata with a legal candidate `<10` observations | No | Future seam required | Correct target is natural/canonical starvation, but “qualifying” can circularly exclude starving strata and the eligible stratum population is unspecified. | Required change. |
| Temporal balance: no quintile `>50%` of candidate comparable observations | Partial | Future seam required | Guards temporal concentration, but quintile construction, order source, ties, short runs, and candidate denominator are undefined. | Required formula clarification. |
| Wilson half-width `<=0.15` in each qualifying stratum | No | QEO outcome exists; governed seam still required | Could protect decision-relevant binary precision, but no binary endpoint or denominator is defined across five terminal outcomes. Applying Wilson to a non-binomial aggregate would be invalid. | Required change. |
| Precision coverage in `>=3` strata per candidate | Partial | Future seam required | Prevents one precise context from standing for the envelope, but inherits the undefined estimand, qualifying-stratum, and “30 in 3” semantics. | Reassess after precision and common-support corrections. |

The draft honestly labels all numerical cutoffs as methodological/product
judgments rather than learner-derived facts. That labeling must remain. The
review cannot determine whether any number is too permissive or restrictive
until the definitions above become executable; changing numbers now would be
N worship rather than a decision-relevant correction.

## Required review dimensions

| Dimension | Assessment |
| --- | --- |
| Eligible episode | `REQUIRES_CHANGE`: correctly requires an explicit canonical opportunity and supplied legal candidates, but the analysis-set denominator and missing/unlinked treatment need formalization. |
| Comparable context | `REQUIRES_CHANGE`: exact matching protects against invalid pooling, but missing decision locus, legal-set, player-agency/route, and common-support requirements allow disjoint comparisons. |
| Primary metrics | `REQUIRES_CHANGE`: the list is relevant, but several formulas and denominators are not executable. |
| Minimum candidate exposure | `REQUIRES_CHANGE`: purpose is defensible; analysis-set and interaction with comparable N are not. |
| Minimum effective comparable sample | `REQUIRES_CHANGE`: “30 per difficulty in 3 strata” is ambiguous. |
| Player/run diversity | `REQUIRES_CHANGE`: boundaries and independence of run segments are not defined. |
| Maximum missingness | `REQUIRES_CHANGE`: global and candidate-specific limits exist, but denominators can hide systematic missingness. |
| Candidate imbalance | `REQUIRES_CHANGE`: stratum membership and zero-count handling are absent. |
| Legal-option coverage | `REQUIRES_CHANGE`: canonical legality is respected, but common support and threshold redundancy remain. |
| Starvation | `REQUIRES_CHANGE`: causal language is correct; denominator is circular. |
| Uncertainty/precision | `REQUIRES_CHANGE`: confidence level and width exist; binary estimand does not. |
| Confounding | `REQUIRES_CHANGE`: named flags and fail-closed treatments exist, but common-support omissions and incomplete formula definitions prevent reproducible detection. |
| Abstention | `ACCEPTABLE_WITH_TERMINAL_FIX`: missing or unresolved evidence produces `INCONCLUSIVE`; precedence must be made mechanical. |
| `FEASIBLE` | `REQUIRES_CHANGE`: all-pass intent is sound, but current thresholds can pass without shared candidate support. |
| `INCONCLUSIVE` | `REQUIRES_CHANGE`: appropriate default for uncertainty, but overlaps `NOT_FEASIBLE`. |
| `NOT_FEASIBLE` | `REQUIRES_CHANGE`: requires measurable predeclared failure, but must take explicit precedence over overlapping inconclusive cases. |
| Root-cause classification | `REQUIRES_CLARIFICATION`: taxonomy scope omits missingness, measurement, and precision reasons. |
| Measurement dependencies | `ACCEPTABLE_WITH_CLARIFICATION`: missing opportunity/linkage/route/context/cross-run seams are truthfully identified; availability terminology needs refinement. |
| Protocol amendment/data lineage | `ACCEPTABLE`: amendments are prospective, seen data becomes derivation evidence, and thresholds may not move retroactively. |
| Role separation | `ACCEPTABLE`: owner, approver, analyst, outcome reviewer, and adjudicator responsibilities are separated. |

## Confounding assessment

| Flag | Detection/treatment review | Verdict |
| --- | --- | --- |
| `PLAYER_SELECTION_CONFOUNDING` | Detects differing/unavailable agency or route, excludes unmatched evidence, and forces `INCONCLUSIVE` if unresolved. The context key still lacks a bounded matching representation. | Requires common-support correction. |
| `ADAPTIVE_CANONICAL_SELECTION_CONFOUNDING` | Requires route stratification and does not infer Adaptive from outcomes. | Acceptable once route capture and stratum formulas are defined. |
| `MODE_CONTEXT_CONFOUNDING` | Excludes violations of the frozen envelope and fails closed when material. | Acceptable; threshold denominator still needs definition. |
| `TEMPORAL_IMBALANCE` | Detects concentration and uses stratification/`INCONCLUSIVE`, but quintile construction is unspecified. | Requires formula clarification. |
| `ANSWER_FORMAT_NUMBER_TYPE_IMBALANCE` | Prohibits pooling unlike answer styles or number types and excludes absent values. | Acceptable; no causal claim is made. |

The protocol consistently describes these as observational limitations and does
not turn association into causal attribution. Stratification cannot create
counterfactual evidence.

## False-pass challenge

The following hypothetical patterns can pass or appear to pass without meeting
the scientific purpose:

1. Easy, Medium, and Hard each exceed 60 observations and meet precision in
   three different, non-overlapping context strata. There is no common support,
   but the per-candidate wording can report all thresholds as passed.
2. A large global sample has high overall legal coverage while one candidate is
   nearly absent wherever another candidate is observed. Aggregate coverage and
   disjoint per-candidate strata conceal the comparison failure.
3. Starving strata are excluded from the undefined “qualifying” set before the
   starvation percentage is calculated, producing an apparently acceptable
   starvation rate.
4. Missing opportunity/linkage records are excluded before candidate-specific
   denominators are assigned, allowing systematic candidate missingness to pass
   both limits.
5. Incompatible player-agency constraints or legal candidate sets are pooled
   because neither is part of the complete comparison key.

These are material false-pass paths; M1 and M2 are required changes.

## False-fail and permanent-`INCONCLUSIVE` challenge

A healthy observational pattern could remain permanently `INCONCLUSIVE` if an
implementation interprets “30 per difficulty in at least 3 strata” as 30 for
each difficulty in each of three exact-match strata, especially after exact
matching fragments natural evidence. Conversely, another implementation could
interpret it as 30 total across three strata. Undefined run boundaries and
quintiles can also make otherwise diverse evidence fail differently across
analysts. This is not evidence that the numerical safeguards should be relaxed;
it requires prospective semantic and formula corrections before judging their
strictness.

## Measurement-availability audit

Repository inspection confirms that current QEOs contain executed difficulty,
operation, number type, answer style, and terminal outcome in an in-memory
active-run collector. The snapshot is immutable to its caller and exposed
through debug-facing `GameState` accessors. Capture is gated by effective
GameBrain enablement at accepted completion, but that value is not stored as
independent per-observation provenance.

| Required input | Review finding |
| --- | --- |
| QEO context and accepted terminal outcome | Present in current run-local runtime state; test-visible, not by itself an authorized P1-F01 analysis path. |
| Effective enablement | Derivable from the capture invariant; not independently auditable from a stored observation field. |
| Canonical decision opportunity | `NOT_CURRENTLY_CAPTURED` in the inspected GEI-04B path. |
| Supplied legal candidates | `NOT_CURRENTLY_CAPTURED` in the inspected GEI-04B path. |
| Opportunity-to-question linkage and legal execution validation | `NOT_CURRENTLY_CAPTURED` in the inspected GEI-04B path. |
| Canonical selection route / Adaptive classification | `NOT_CURRENTLY_CAPTURED` in the inspected GEI-04B path. |
| Player-agency constraint / selection route | `NOT_CURRENTLY_CAPTURED` in the inspected GEI-04B path. |
| Activity/run classification and independent segments | `NOT_CURRENTLY_CAPTURED` by QEO. |
| Timestamp or run-order facts | `NOT_CURRENTLY_CAPTURED` by QEO. |
| Cross-run evidence plan | `REQUIRES_FUTURE_MEASUREMENT_SEAM` and separate governance authorization. |

P1-F01 cannot be adjudicated from GEI-04B alone. This audit establishes field
availability only; it does not authorize a measurement seam, persistence,
export, or analysis execution.

## Governance, amendment, and data lineage

The draft does not authorize persistence, cloud upload, analytics, telemetry,
remote research collection, player identifiers, gameplay-distribution changes,
or gameplay authority. Any opportunity record, legal-option record, run/context
ordering, or cross-run plan remains a separately governed dependency.

The prospective-amendment rule is adequate: once data is inspected while
changing a future version, those data are protocol-derivation evidence and
cannot silently become clean confirmatory evidence for that revision.
Thresholds may not move after results are known.

## Required changes before Protocol Lock

1. Extend comparability and common-support rules to include decision locus, the
   exact supplied legal-candidate set, and bounded player-agency/selection
   constraints; require candidate comparisons to share declared support.
2. Define the opportunity analysis set and every denominator/formula, including
   candidate missingness, imbalance membership and zero counts, qualifying
   strata, starvation, run segments, and temporal quintiles.
3. Resolve “30 per difficulty in at least 3 strata” and document interactions
   or redundancy among the 300-total, 60-exposure, comparable-sample, and
   legal-coverage thresholds. Reassess numbers only after semantics are fixed.
4. Define each binary terminal-outcome estimand, numerator, denominator, and
   candidate/stratum level to which the Wilson half-width applies.
5. Replace the contradictory terminal ordering with explicit, mutually
   adjudicable precedence for `NOT_FEASIBLE`, `INCONCLUSIVE`, and `FEASIBLE`.
6. Clarify root-cause versus inconclusive-reason taxonomy and refine measurement
   terms to distinguish runtime/test-visible, derivable, independently
   auditable, and authorized-for-P1-F01 availability.

## Unresolved dissent

The reviewer does not endorse the proposed numerical values as validated
cutoffs. They remain openly labeled methodological judgments. The reviewer also
does not recommend different values before the definitions and simulations of
hypothetical edge patterns are fixed prospectively. This dissent does not
require redesign of the chooseDifficulty authority boundary.

## Final recommendation

`APPROVE_WITH_REQUIRED_CHANGES`

P1-F00 v1 is structurally salvageable and preserves the frozen GameBrain
authority and governance boundaries, but the five major findings make the
current draft unsuitable for Protocol Lock. The six listed changes must be
made prospectively by the Protocol Owner and independently re-reviewed before
lock. P1-F01 remains unrun, and the protocol file itself was not modified by
this review.
