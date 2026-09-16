# GB-POLICY-01B — Choose-Difficulty Policy Research / Validation Gate

**Status:** `GB-POLICY-01B` — `CONTRACT FROZEN / NO POLICY VALIDATED`

## Purpose and status boundary

This document freezes the minimum governance contract required before a
concrete `VersionedChooseDifficultyPolicy` may be scientifically tested,
accepted, rejected, or considered for later shadow use.

```text
policy contract exists != policy scientifically validated
policy scientifically validated != gameplay authority
shadow result != executed difficulty
```

This gate creates no concrete policy, decision episode, simulation, empirical
research, threshold, sample-size requirement, seed, scenario, acceptance
number, gameplay influence, or production Dart change.

## Frozen validation subject and input boundary

A future validation subject must consume the already-frozen
`ChooseDifficultyEpistemicPreservationSet` and conform to
`VersionedChooseDifficultyPolicy`.

Its resolution output is restricted to:

- `ChooseDifficultyNoPreference`
- `ChooseDifficultyPreferredCandidate`

The validation protocol must not bypass, reinterpret, replace, reorder, or
otherwise resolve the source Epistemic Preservation layer. The supplied legal
candidate set remains canonical. A preferred candidate, if produced, must be
one of those preserved candidates.

## Research eligibility gate

A concrete policy is ineligible for validation unless its validation package
explicitly supplies and freezes every item below before execution.

1. **Policy identity:** exact policy id and exact version.
2. **Policy implementation:** exact immutable implementation under test; rules
   must not move during evaluation.
3. **Decision context:** exact `chooseDifficulty` context/envelope under test
   and the canonical supplied legal candidate set.
4. **Input evidence contract:** exact source structures and semantic meanings,
   exact evidence-availability states, exact scenario-contribution types, and
   no hidden inputs.
5. **Evaluation dataset or simulation input:** exact origin, scope,
   inclusion/exclusion rules, and frozen version or hash where applicable.
6. **Comparator / reference definition:** when used, define exactly what it
   compares. It must not be called a causal counterfactual without separate
   justification.
7. **Evaluation measures:** name and define measures before execution; do not
   invent metrics after observing results.
8. **Acceptance / rejection criteria:** specify before execution. This gate
   supplies no numeric thresholds. When criteria are not justified and frozen,
   validation remains `NOT_READY`.
9. **Reproducibility inputs:** state the exact runtime/toolchain as applicable.
   Use deterministic seeds only when required; exact seed values belong only
   to the future concrete validation package.
10. **Independence / review:** implementation result and scientific acceptance
    are separate judgments. Independent review is required before declaring a
    policy validated.

If any required item is missing, the validation status is `NOT_READY`. Do not
substitute assumptions.

## Frozen research-governance outcomes

Only these outcomes exist for this gate:

| Outcome | Definition |
| --- | --- |
| `NOT_READY` | Required pre-execution validation inputs are incomplete or unfrozen. |
| `EXECUTED_NOT_ACCEPTED` | A frozen validation ran but did not satisfy its predeclared acceptance contract, or execution could not support acceptance. |
| `ACCEPTED_FOR_SHADOW_STUDY` | The frozen policy satisfied its predeclared validation contract sufficiently to permit only a later, separately governed shadow study. |

`ACCEPTED_FOR_SHADOW_STUDY` does not mean gameplay authority, deployment,
user-facing recommendation, execution, correctness for an individual player,
mastery inference, best difficulty, causal benefit, or production validity
beyond the tested envelope.

There is no `ACCEPTED_FOR_GAMEPLAY` outcome.

## Acceptance firewall

```text
VALIDATION PASS != GAMEPLAY AUTHORITY
SCIENTIFIC ACCEPTANCE != PRODUCT AUTHORIZATION
SHADOW STUDY != LIVE ADAPTATION
PREFERRED CANDIDATE != BEST DIFFICULTY
PREFERRED CANDIDATE != LEARNER ABILITY
PREFERRED CANDIDATE != MASTERY
NO_PREFERENCE != FAILURE
NO_PREFERENCE != NEGATIVE EVIDENCE
NO_PREFERENCE != EVIDENCE ABSENCE
POLICY VERSION != VALIDITY
POLICY VERSION != AUTHORITY
OBSERVED != PREDICTED != PREFERRED != AUTHORIZED != EXECUTED
```

## Prohibited invention

GB-POLICY-01B does not invent a minimum sample requirement, statistical power,
confidence level, alpha, effect-size threshold, accuracy threshold,
false-positive threshold, false-negative threshold, utility score, reward
function, ranking metric, policy score, evidence weight, scenario weight,
candidate precedence, tie-breaker, seed count, simulation replication,
synthetic regime, reliable-change threshold, starvation threshold, replay
tolerance, or candidate-allocation rule.

If any such item becomes necessary, it belongs to a future concrete,
separately frozen validation package supported by evidence.

## Current scientific limits

- GB-POLICY-01A defines only the structural versioned policy boundary; it
  provides no validated decision rule.
- Epistemic Preservation preserves evidence; it does not resolve trade-offs.
- Candidate-list order has no preference meaning.
- Evidence availability does not itself choose a candidate.
- Timeout scenario evidence does not automatically authorize a
  timeout-specific policy.
- Existing evidence must not gain policy authority merely because it is
  structurally available.
- Reliable-change logic is unavailable for policy use unless separately
  reopened and justified.
- No topology may be inferred from difficulty labels or enum order.

## Future concrete validation package template

```text
Policy ID:
Policy version:
Implementation commit/hash:
Decision envelope:
Input contract:
Dataset/simulation artifact:
Dataset/artifact hash:
Comparator/reference:
Predeclared measures:
Predeclared acceptance criteria:
Runtime/toolchain:
Seeds (if applicable):
Execution result:
Independent review:
Final research disposition:
```

The template contains placeholders only. It supplies no scientific values.

## Next-gate rule

After GB-POLICY-01B, policy research does not start automatically. A next task
may begin only when a specific concrete candidate policy has explicit rationale
and sufficient inputs to freeze a real validation package.

Until then:

```text
POLICY IMPLEMENTATION = NONE VALIDATED
POLICY AUTHORITY = NONE
mayAffectGameplay = false
```
