# GB-POLICY-01C — Timeout-Concentration Comparator Policy Candidate Freeze

Date: 2026-10-03

Status:

```text
CANDIDATE DESIGN FROZEN
VALIDATION INPUT MANIFEST FROZEN
IMPLEMENTATION NOT YET AUTHORIZED BY THIS ARTIFACT
VALIDATION EXECUTION NOT AUTHORIZED
POLICY VALIDATED = NO
POLICY AUTHORITY = NONE
mayAffectGameplay = false
```

1. Authority and parent gate
Parent governance:
GB-POLICY-01A
VersionedChooseDifficultyPolicy structural boundary

GB-POLICY-01B
Choose-Difficulty Policy Research / Validation Gate
CONTRACT FROZEN / NO POLICY VALIDATED

GB-STATUS-RECONCILE-01
current frontier = GB-POLICY-01B

This artifact opens one bounded concrete policy candidate.
It does not validate it.
It does not authorize a shadow study.
It does not authorize gameplay influence.
2. Candidate identity
Policy ID:
timeout_concentration_comparator_preference

Policy version:
1

Future implementation must conform to:
VersionedChooseDifficultyPolicy

and must consume only:
ChooseDifficultyEpistemicPreservationSet

Output remains restricted to:
ChooseDifficultyNoPreference
ChooseDifficultyPreferredCandidate

3. Research rationale
The current repository contains an accepted:
TimeoutConcentrationAtDifficulty

scenario path with preserved:
targetDifficulty
comparatorDifficulty
recorded scenario match state
canonical context

A matched timeout-concentration observation does not establish:
best difficulty
ability
mastery
need to reduce difficulty
learning benefit
causal benefit
gameplay authority

This candidate therefore tests only a narrow research hypothesis:
In an exact two-candidate preserved decision envelope, when exactly one
unambiguous accepted timeout-concentration contribution is matched for one
target relative to the other canonically supplied comparator, can a
deterministic policy emit that comparator as a research preference while
abstaining everywhere else?

The comparator is used because it is explicitly supplied by the governed
evidence path.
The policy must not infer whether that comparator is easier, harder, adjacent,
better, or pedagogically desirable.
4. Exact decision envelope
Validation envelope:
DecisionContext = chooseDifficulty

Context:
operation      = addition
numberType     = natural
representation = directNumeric

Candidate universe:
Easy / Medium / Hard

Preference-eligible legal envelope:
exactly TWO distinct preserved candidates

Candidate order:
NO SEMANTIC MEANING

The two candidates may be any two distinct members of the Phase-1 candidate
universe.
The policy must not infer topology from:
enum order
labels
numeric values
historical exposure
list position

5. Exact candidate rule
A preferred candidate may be emitted only when ALL conditions hold.
A. evidence.candidates.length == 2

B. both preserved candidates have:
   availability == present

C. total timeout contributions across the complete preservation set == 1

D. that contribution belongs to its preserved target candidate

E. contribution.context == evidence.context

F. contribution.candidateDifficulty != contribution.comparatorDifficulty

G. comparatorDifficulty is the other preserved candidate

H. contribution.entries.length == 1

I. the single recorded disposition == matched

J. no other timeout contribution exists anywhere in the input

When A-J all hold:
ChooseDifficultyPreferredCandidate(
  candidate = contribution.comparatorDifficulty
)

Otherwise:
ChooseDifficultyNoPreference

There is no fallback ranking.
There is no tie-breaker.
There is no weighting.
There is no threshold introduced by this policy.
6. Explicitly prohibited policy inputs
The candidate must not use or invent:
candidate list order
Difficulty enum order
difficulty label semantics
accuracy threshold
score
utility function
reward function
scenario weight
candidate weight
mastery
learner ability
player profile
age inference
RecentImprovement
RecentDecline
Recovery
ProductiveChallenge
Overchallenge
Underchallenge
raw response-time interpretation
reliable-change receipt
hidden application state
future observations
randomness

The policy may not reinterpret raw timeout rates itself.
It consumes the already-governed scenario disposition.
7. Synthetic validation artifact
Frozen fixture manifest:
research/game_brain/gb_policy_01c/validation_fixture_manifest_v1.json

SHA-256:
288392de02e9fcdc70cdaa8535d0bedcef6e793fac51528e939d5b2ba0accaa9

The manifest is:
SYNTHETIC ONLY
NO REAL PLAYER DATA
NO REMOTE DATA
NO PERSONAL DATA

The manifest defines the exact semantic fixture matrix.
Future tests must construct equivalent
ChooseDifficultyEpistemicPreservationSet inputs through the existing
governed source pipeline.
Expected outcomes may not be changed after observing implementation results.
8. Frozen fixture coverage
Positive cases prove:
single matched contribution
canonical comparator selection
candidate-order invariance
no Easy/Medium/Hard ordinal assumption

Negative/abstention cases prove:
no contribution
target evidence absent
comparator evidence absent
empty contribution
notMatched evidence
contradicted evidence
multiple entries
mixed entries
duplicate contributions
competing contributions
three-candidate ambiguity
comparator outside preserved candidate set
target == comparator
single-candidate input
empty input

All negative cases must return:
ChooseDifficultyNoPreference

9. Comparator / reference definition
No causal counterfactual is defined.
For validation reporting only, the structural reference policy is:
AlwaysNoPreference

It is used only to describe how often the candidate policy emits a preference
within the frozen synthetic fixtures.
It is not a scientific baseline for learning benefit, correctness, utility,
or gameplay performance.
10. Predeclared validation measures
The future frozen execution must report:
fixture_exact_resolution_count
fixture_exact_resolution_rate

deterministic_repeat_count
deterministic_repeat_match_rate

preferred_candidate_membership_violations

authority_violations
mayAffectGameplay_violations

positive_fixture_count
no_preference_fixture_count

candidate_order_invariance

No metric may be invented after results are seen for purposes of acceptance.
11. Predeclared acceptance criteria
Every condition is mandatory.
1. Exact expected fixture resolutions = 100%

2. Every frozen fixture evaluated 100 repeated times
   must return bit-for-bit equivalent semantic resolution.

3. Deterministic repeat match rate = 100%.

4. Preferred candidate membership violations = 0.

5. authority violations = 0.

6. mayAffectGameplay violations = 0.

7. P01 and P02 must produce the same semantic preferred candidate.

8. P03 must prove no enum/list-order assumption by preferring the canonically
   supplied comparator even though its label must not be interpreted as
   easier/harder by the policy.

9. Every frozen negative fixture must return
   ChooseDifficultyNoPreference.

10. Targeted policy tests must PASS.

11. flutter analyze must PASS.

12. full non-golden test suite must PASS.

Failure of any mandatory criterion means:
EXECUTED_NOT_ACCEPTED

provided execution was otherwise valid.
12. Reproducibility runtime
The future validation execution is frozen to:
PLATFORM = linux/amd64

FLUTTER_VERSION = 3.47.5
FLUTTER_FRAMEWORK_REVISION =
6a19cca56475dbfba1478ee68d7bd0c2ef891da1

FLUTTER_ENGINE_REVISION =
af7e796e161ae0bb1ff0758c71a7105418bd9ded

DART_VERSION = 3.13.4

FLUTTER_ARCHIVE_SHA256 =
2132e990f236f8d22e7c6314b29a191a95b10d7cbcfec9b4e2e303d996652cbb

Randomness:
NONE

Seeds:
NOT APPLICABLE

13. Implementation binding remains unresolved
At this contract-freeze stage:
IMPLEMENTATION COMMIT/HASH = NOT YET BOUND

Therefore GB-POLICY-01B validation readiness remains:
NOT_READY

A later implementation step may not execute validation automatically.
After implementation, a separate pre-execution binding/review step must freeze:
exact implementation commit/hash
exact implementation file
exact targeted test file
manifest hash verification
runtime verification
independent review result

Only after that bounded gate passes may validation execution be separately
authorized.
14. Expected future implementation scope
This artifact does NOT itself authorize code changes.
If separately authorized after this contract is merged, the intended bounded
implementation scope is:
lib/features/game_brain/policy/
  timeout_concentration_comparator_policy.dart

test/features/game_brain/
  timeout_concentration_comparator_policy_test.dart

A barrel export may be added only if required for the existing GameBrain
library convention.
Prohibited implementation changes:
game_state wiring
question generation
difficulty execution
adaptive activation
UI
persistence
Player Experience Model mutation
mastery mutation
Target Clash
IQ Spark / Mental Math behavior
Time Bank behavior
production telemetry expansion
networking
real-player research capture

15. Independent review requirement
Implementation correctness and scientific acceptance remain separate.
Before validation execution:
independent implementation review = REQUIRED
scientific/gate review            = REQUIRED

No implementation author may self-declare the policy validated.
16. Frozen research outcomes
Only GB-POLICY-01B outcomes remain legal:
NOT_READY
EXECUTED_NOT_ACCEPTED
ACCEPTED_FOR_SHADOW_STUDY

There is no:
ACCEPTED_FOR_GAMEPLAY

Even ACCEPTED_FOR_SHADOW_STUDY requires a later separately governed shadow
study.
17. Authority firewall
Always:
PREFERRED != BEST
PREFERRED != LEARNER ABILITY
PREFERRED != MASTERY
PREFERRED != AUTHORIZED
PREFERRED != EXECUTED

POLICY VERSION != VALIDITY
VALIDATION PASS != GAMEPLAY AUTHORITY
SHADOW STUDY != LIVE ADAPTATION

POLICY AUTHORITY = NONE
mayAffectGameplay = false

18. Current disposition
After this contract is merged:
GB-POLICY-01C CANDIDATE DESIGN = FROZEN
SYNTHETIC VALIDATION MANIFEST   = FROZEN

POLICY IMPLEMENTATION           = NOT YET IMPLEMENTED
POLICY VALIDATED                = NO
VALIDATION READINESS            = NOT_READY

NEXT STEP =
INDEPENDENT CONTRACT REVIEW
THEN
SEPARATELY AUTHORIZED AGENT IMPLEMENTATION
