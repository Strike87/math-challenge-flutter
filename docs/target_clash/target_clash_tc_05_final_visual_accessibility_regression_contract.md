# Target Clash TC-05 — Final Visual / Accessibility / Regression Contract

Status: FROZEN / OWNER APPROVED

Date: 2026-09-29

Baseline:

main
85f6eafcf083063b512b67e1cf37dc8ceb646d6f

## 1. Authority

TC-00 through TC-04 remain authoritative. TC-05 owns only:

- final visual parity;
- accessibility closure;
- responsive proof;
- controlled Target Clash golden coverage;
- final retained regression closure;
- explicit GameBrain/P1/learner-model firewall proof;
- service/persistence firewall proof; and
- narrowly necessary presentation remediation discovered by approved tests.

TC-05 must not reinterpret gameplay semantics.

## 2. Owner decisions — closed

OWNER_DECISIONS_REQUIRED = 0

OD-01 = APPROVED_SPECIFICATION

OD-02 = APPROVED_1_5X

TARGET_CLASH_TEXT_SCALE_ACCEPTANCE = 1.5x at 360x640

Required TC-05 proof at that threshold includes:

- gameplay controls/HUD;
- Results; and
- technical-failure readability/state comprehension.

## 3. Reduced motion

REDUCED_MOTION = RETAIN_FROZEN_BEHAVIOR

- The canonical 1300ms Target Clash Clash Reveal remains unchanged.
- TC-05 introduces no new motion dependency.
- Accessibility proof verifies readability/state comprehension.
- TC-05 does not shorten, skip, suppress, or reinterpret the reveal.
- No gameplay/timing semantic change is authorized.

## 4. Controlled golden environment

FLUTTER_VERSION = 3.47.5

FLUTTER_CHANNEL = stable

FLUTTER_FRAMEWORK_REVISION = 6a19cca56475dbfba1478ee68d7bd0c2ef891da1

FLUTTER_ENGINE_REVISION = af7e796e161ae0bb1ff0758c71a7105418bd9ded

DART_VERSION = 3.13.4

Official Flutter archive:

https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.5-stable.tar.xz

FLUTTER_ARCHIVE_SHA256 = 2132e990f236f8d22e7c6314b29a191a95b10d7cbcfec9b4e2e303d996652cbb

FLUTTER_ARCHIVE_SIZE = 1576266884 bytes (informational only)

Archive SHA256 is the integrity authority; archive size is not.

## 5. Base OCI image

BASE_IMAGE_INDEX = ubuntu@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3

BASE_IMAGE_INDEX_DIGEST = sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3

BASE_IMAGE_AMD64_MANIFEST_DIGEST = sha256:496754492fb28b4d3049432f2ca787449331e23fb14f0dd3fffea86bf5a93eb4

PLATFORM = linux/amd64

The moving tag `ubuntu:24.04` alone is not authority.

## 6. Font authority

The frozen font authority is:

| File | SHA256 |
| --- | --- |
| `assets/fonts/Baloo2-Bold.ttf` | `A4C5BC453CA281D90EA079E596DA7AE0DFEB5777497C29EC254E76D97FF6F890` |
| `assets/fonts/Baloo2-ExtraBold.ttf` | `A4C5BC453CA281D90EA079E596DA7AE0DFEB5777497C29EC254E76D97FF6F890` |
| `assets/fonts/Baloo2-Black.ttf` | `A4C5BC453CA281D90EA079E596DA7AE0DFEB5777497C29EC254E76D97FF6F890` |
| `assets/fonts/PlusJakartaSans-Medium.ttf` | `57F73E11F51999432BF7AB22CE55B6F945D5ECA1BF824404CFA9EC2E3718C84E` |
| `assets/fonts/PlusJakartaSans-SemiBold.ttf` | `A4C5BC453CA281D90EA079E596DA7AE0DFEB5777497C29EC254E76D97FF6F890` |
| `assets/fonts/PlusJakartaSans-Bold.ttf` | `A4C5BC453CA281D90EA079E596DA7AE0DFEB5777497C29EC254E76D97FF6F890` |
| `assets/fonts/PlusJakartaSans-ExtraBold.ttf` | `A4C5BC453CA281D90EA079E596DA7AE0DFEB5777497C29EC254E76D97FF6F890` |
| `assets/fonts/OpenDyslexic-Regular.otf` | `32F5840FB2BF844BDABAFE372591DDFB9286E98117F5B21950AAF54EA856919A` |

FONT_HASH_COUNT = 8

All eight repository files must match these frozen hashes before controlled golden execution. A mismatch blocks execution; no substitute value may be silently recalculated.

## 7. Golden authority

GOLDEN_AUTHORITY = exact base OCI digest + linux/amd64 + Flutter exact framework/engine revision + Dart exact version + official Flutter archive SHA256 + exact 8 repo font hashes + DPR 1.0 + explicitly declared viewport + deterministic SettingsService state + deterministic fixture state + explicit locale + explicit text scale + deterministic settling.

ENVIRONMENT_SPECIFICATION_VERIFIED = YES

ENVIRONMENT_RUNTIME_VERIFIED = NO

## 8. Runtime proof gate

RUNTIME_PROOF_REQUIRED_BEFORE_ANY_GOLDEN_GENERATION_OR_UPDATE = YES

Until runtime proof succeeds in the frozen environment:

- no canonical Target Clash golden may be generated;
- no Target Clash golden may be updated;
- no existing golden may be replaced;
- no local Windows render may be promoted to canonical; and
- no moving CI runner may be treated as canonical golden authority.

Lack of local Docker is not permission to weaken this gate.

## 9. Existing visual baseline classification

PRE_EXISTING_ENVIRONMENT_BASELINE_MISMATCH

Accepted evidence:

- local current: 23 PASS / 32 FAIL;
- parent: 23 PASS / 32 FAIL;
- isolatedDiff: 38 / 38 identical;
- TC04C new visual failures: 0; and
- TC04C changed visual failures: 0.

These failures must not be repaired through a broad golden refresh during TC-05.

## 10. Minimal Target Clash golden strategy

No broad application golden refresh is authorized. Candidate controlled Target Clash golden boundaries include only reviewed states needed to prove layout/theme parity:

- ordinary gameplay/open state;
- Clash Reveal;
- light and dark gameplay boundary;
- Power Shot ready / Triple-blocked boundary;
- Results light;
- Results dark;
- Results landscape;
- technical failure; and
- one justified tablet boundary.

Do not snapshot every gameplay phase mechanically. Semantic and state behavior remains primarily widget-test responsibility.

## 11. Responsive matrix

Minimum controlled proof:

| Viewport | Required proof |
| --- | --- |
| 360x640 portrait | text scale 1.5x; accessibility acceptance case |
| 390x844 portrait | primary phone visual baseline |
| 844x390 landscape | gameplay/results/technical-failure responsive proof |
| 834x1194 tablet | one justified controlled Target Clash boundary |

DPR for controlled golden execution: 1.0.

Required proof includes no Flutter exception, no RenderFlex/overflow diagnostic, reachable required controls and Results actions, correct enabled/disabled state, and present semantics labels.

## 12. Accessibility contract

Final proof requires:

- relation semantics: Less than target, Equal to target, Greater than target;
- logical source/traversal order;
- Material button roles;
- stable explicit semantics where required;
- practical tap targets;
- 1.5x text scaling;
- light/dark readability;
- color-independent state meaning;
- success/failure text distinction;
- Power Shot state comprehension;
- Results action semantics;
- technical-failure action semantics;
- scroll/reachability; and
- responsive non-overflow.

Presentation meaning must not depend on color alone.

## 13. GameBrain / P1 firewall

Target Clash must remain unable to enter:

- GameBrain instance observation;
- QuestionExperienceObservation;
- ContextEvidenceObservation;
- P1 study admission or record;
- Canonical Fact Center GameBrain projection;
- learner model;
- skill/mastery mutation;
- adaptive selection or adaptive shadow calls;
- recommendation;
- chooseDifficulty authority; or
- GameBrain-governed telemetry.

Firewall proof must be call-path based, not keyword absence only.

## 14. Service / persistence firewall

Target Clash must not mutate:

- High Score;
- Hall of Fame;
- coins/economy;
- achievements;
- cloud progress;
- generic Target Clash persistence;
- ordinary completion persistence; or
- ordinary power-up state.

Allowed side effects remain only the canonical per-question timer and finished-only existing completed-game ad cadence. TC-05 must not create a new service policy.

## 15. Allowed implementation scope

Future TC-05 implementation may touch only when required by approved proof:

- new Target Clash visual/accessibility test files;
- `test/visual_parity_test.dart`;
- explicitly reviewed Target Clash golden files;
- `lib/features/target_clash/presentation/target_clash_gameplay.dart`; and
- `lib/features/target_clash/presentation/target_clash_results.dart`.

Presentation files may change only to correct a proven TC-05 visual/accessibility gap. GameState changes are not authorized by this contract without separate owner approval.

## 16. Forbidden scope

TC-05 must not introduce or change:

- Target Clash mechanics, scoring, target zones, timing, or 1300ms reveal semantics;
- Boss, Fever, Triple, or Power Shot semantics;
- relation correctness or question counts;
- persistence schema;
- rewards/economy or achievements;
- GameBrain evidence, adaptive behavior, learner modeling, or new product metrics; or
- broad application redesign or broad golden refresh.

## 17. Final regression matrix

Before TC-05 closure require:

- focused TC-05 visual/accessibility tests;
- retained TC-01, TC-02, TC-03, and TC-04;
- ordinary gameplay regressions;
- Operation Quest regressions;
- Mental Math / IQ Spark regressions;
- AdMob parity;
- GameBrain/P1 firewall regressions;
- service/persistence firewall proof;
- full non-golden suite;
- controlled Target Clash golden suite;
- `flutter analyze --no-pub`;
- `git diff --check`;
- exact scope review;
- clean tracked/index state; and
- independent final review.

Raw OS-sensitive local golden mismatch must not be classified as a product regression without controlled parent/environment evidence.

## 18. Exit criteria

TC-05 closes only when runtime proof of the frozen golden environment, approved focused accessibility tests, controlled Target Clash golden tests, retained TC-01 through TC-04, the full non-golden regression, GameBrain/P1 firewall, persistence/service firewall, analyzer, diff check, zero scope drift, zero forbidden semantic changes, and independent review all pass.

## 19. Owner status

OD-01 = APPROVED_SPECIFICATION

OD-02 = APPROVED_1_5X

OWNER_DECISIONS_REQUIRED = 0

TC_05_CONTRACT = FROZEN

GOLDEN_MUTATION = BLOCKED_PENDING_RUNTIME_PROOF
