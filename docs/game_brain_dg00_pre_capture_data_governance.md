# DG-00 — GameBrain / GEI pre-capture data governance

## 1. Status and authority

`DG00_OUTCOME = PRE_CAPTURE_GOVERNANCE_READY`.

This is a governance contract, not collection authority. `mayAffectGameplay`
remains `false`, P0 remains dormant, and GEI-04B remains unauthorized. The
canonical game and Adaptive Difficulty remain independent of GameBrain.

## 2. Purpose and scope

This contract defines the conditions under which a later approved feature may
capture, retain, process, or use GameBrain / Game Experience Intelligence
(GEI) data. It applies to future Question Experience, Run Experience, memory,
scenario, model, evaluation, and decision records. It does not change runtime
behavior, storage, UI, age-gate behavior, cloud save, analytics, or parental
approval.

Technical capability is not collection authority. Every retained field needs a
named purpose, consumer, retention justification, deletion behavior, and an
approved authority gate.

## 3. Definitions

- **Observed**: a fact directly produced by an executed game experience.
- **Derived**: a bounded summary computed from observations.
- **Predicted, preferred, authorized, and executed**: separate typed concepts;
  none may be flattened into a generic activity log.
- **GameBrain OFF**: a master product state, not Adaptive Difficulty OFF.
- **Clear data**: deletion of the GEI store and its derived GEI state.
- **Protected band**: an audience band for which the applicable law, store
  policy, or product policy requires a protective approval/eligibility path.

## 4. Current Question Experience inventory

GEI-04A is a passive source-level contract only. Its facts are direct,
effective execution facts, not learner interpretation:

| Fact | Purpose if later authorized | Sensitivity / aggregation risk | Persistence and disclosure rule |
| --- | --- | --- | --- |
| Operation | describe mathematical context | can contribute to an education profile in aggregate | local-only is sufficient; no cloud/telemetry now |
| NumberType | describe numeric domain | can contribute to an education profile in aggregate | local-only is sufficient; no cloud/telemetry now |
| Difficulty | describe effective presented difficulty | can contribute to an education profile in aggregate | local-only is sufficient; no cloud/telemetry now |
| AnswerStyle | describe presentation context | low alone, profile-relevant in aggregate | local-only is sufficient; no cloud/telemetry now |
| Terminal result | describe lifecycle outcome | outcome history can be profile-relevant in aggregate | local-only is sufficient; no cloud/telemetry now |

None contains identity, mastery, response time, raw question content,
assistance attribution, or provenance. That does not make aggregated history
harmless: an aggregate can become a more sensitive educational profile.

## 5. Data-family classification

| Family | DG-00 classification | Future gate |
| --- | --- | --- |
| Question Experience facts | structurally planned, not authorized to capture | GEI-04B after all preconditions |
| Run Experience summaries | structurally planned, not authorized | separate run-summary contract |
| Long-Term Experience Memory | prohibited until separate gate | memory/retention/storage gate |
| Scenario state and Player Experience Model | prohibited until separate gate | scenario/model gate |
| CandidateEvaluation | prohibited for gameplay influence | authority and adapter gate |
| DecisionEpisode and policy/audit provenance | prohibited until separate audit gate | decision-audit gate |
| GameBrain enablement state | structurally planned for GB-UX-00 | GB-UX-00 |
| Age/eligibility and parental approval state | structurally planned | GB-PARENT-00 where applicable |
| Deletion/reset state | structurally planned with any persistence | persistence implementation gate |
| GEI diagnostics/telemetry | not required; prohibited now | explicit telemetry gate |

## 6. Purpose limitation and minimization

The only candidate purpose category for a future GEI-04B local observation is
bounded local educational personalization, after enablement and eligibility
are valid. Player explanation, fit evaluation, reliability, policy audit,
research, product analytics, advertising, and cross-product profiling are
separate purposes and require separate approval. Education data must never be
silently repurposed for advertising, unrelated analytics, or research.

No psychological labels, causal attributions, counterfactual outcomes, raw
answers, raw prompts, latency, persistent question/run IDs, account IDs,
device IDs, or generic provenance metadata are authorized. `Medium -> outcome`
does not establish a hypothetical Easy or Hard outcome. Future uncertainty must
remain explicitly `DIRECTLY_OBSERVED`, `SUPPORTED_BY_COMPARABLE_HISTORY`,
`GENERALIZED_INFERRED`, or `UNKNOWN`.

## 7. Age, eligibility, and parental approval

The neutral Age Gate supplies an age/audience input only. It is neither
parental approval nor GameBrain enablement and must not encourage older-age
selection. The product shall keep at least these policy bands: **general
eligible**, **protected**, and **unknown/unresolved**. Jurisdiction and store
mapping for each band is `LEGAL_POLICY_REVIEW_REQUIRED`; no universal numeric
threshold is frozen here.

For a protected or unknown band, GameBrain is OFF and locked by default until a
future verified approval/eligibility path permits enablement. A child cannot
bypass that path. Approval and enablement remain distinct: eligible+OFF,
eligible+ON, approval-required+not-approved, approved+OFF, approved+ON, and
approval-revoked are separate states. Revocation forces OFF where approval is
required.

GB-PARENT-00 may retain only the minimum approval state justified by counsel:
approval status, policy version, approval timestamp/version, and revocation
state. It must not collect parent identity unless that mechanism is separately
approved and necessary.

## 8. GameBrain ON/OFF, delete, and reset

OFF prohibits GameBrain gameplay influence, policy execution, scenario
personalization, influence-capable candidate evaluation, new personalized
Question/Run Experience capture, new GEI long-term updates, and use of a
last-known personalized recommendation. Canonical gameplay continues; Adaptive
Difficulty remains unchanged.

Disable is not delete. While OFF, retained GEI data is dormant and unavailable
for personalization. Re-enable may not reuse old data until an approved
recency/supersession policy says it is eligible. A separate Clear Data action
must delete retained GEI observations, summaries, models, decision audit data,
and local identifiers. Future app reset must either include that complete GEI
wipe or explicitly present the separate choice; it must not leave hidden GEI
state. Approval revocation applies the protected-band deletion/retention rule
set by GB-PARENT-00. Uninstall removes local data subject to platform backup
behavior; a future cloud reset is a separate cloud feature.

## 9. Local-first, identifiers, retention, and security

Local-first is the default. GEI cloud persistence is not authorized and may
not be added to existing progression cloud payloads. Any cloud sync requires a
separate purpose, data-flow, security, deletion, jurisdiction, and store-policy
gate. GEI data must never be used for advertising.

Start with no persistent identifier. Any later correlation must be justified in
order: run-local anonymous scope, local profile scope, account scope, then
cloud identity. Each requires purpose, lifetime, storage, deletion, and
linkability analysis.

No unbounded raw history is permitted. Working evidence is run-local and
discarded at its boundary; summaries/memory/audit windows require bounded,
versioned retention classes, supersession, maximum need, and clear/delete
behavior before implementation. Memory is evidence, not identity: older
evidence can retain historical meaning while losing current authority. Do not
freeze a universal decay coefficient.

Least privilege applies: local computation accesses only data needed for its
approved purpose; player/parent UI exposes comprehensible summaries only;
developer, support, cloud, and analytics access to detailed profiles is denied
unless separately justified. Future storage must have proportional at-rest
protection, secure transport if cloud is approved, no GEI debug logs or exports,
backup/deletion handling, and fail-safe corruption behavior.

## 10. Telemetry, third parties, research, and transparency

Raw Question Experience, derived profiles, and decision records are prohibited
from Firebase Analytics, Crashlytics, Sentry, performance tools, logs,
breadcrumbs, support exports, advertising, authentication providers, and cloud
storage now. Third-party use is either **prohibited** (advertising), **not
currently required** (analytics/crash/support/cloud), or **conditionally
allowable only after a separate reviewed purpose and data-flow gate**.

Production personalization data cannot silently become research or developer
diagnostic data. Real-player research requires its own purpose, population,
minimization, retention, access, and authorization review.

Future UX must explain what GameBrain observes, why, enabled status, whether it
changes gameplay, local/cloud location, OFF versus Clear Data, advertising
prohibition, and protected-user handling. The gameplay badge means only
“GameBrain enabled”; it does not assert influence on the current question,
confidence, or parental supervision. Parent/teacher wording must distinguish
direct observations, derived summaries, and uncertainty.

## 11. Legal and platform review

This is not legal advice. Before a release that collects or transmits GEI data,
qualified privacy/legal review must map the actual audience, jurisdictions,
data flows, identifiers, SDKs, consent/approval method, retention, and store
declarations. Official sources consulted on 2026-08-14:

- [FTC COPPA Rule](https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa).
- [Google Play Families policy](https://support.google.com/googleplay/android-developer/answer/17122218) and [Data safety requirements](https://support.google.com/googleplay/android-developer/answer/10787469).
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) and [Kids category guidance](https://developer.apple.com/kids/).
- [Firebase Analytics collection controls](https://firebase.google.com/docs/analytics/configure-data-collection).

These sources require current disclosures and impose audience- and service-
dependent obligations; they do not supply a universal age threshold for this
product. `LEGAL_POLICY_REVIEW_REQUIRED` remains for jurisdiction mapping,
whether local profiles are personal data under applicable law, valid approval/
consent mechanics, child-directed status, retention periods, and any future
third-party SDK/cloud flow.

## 12. Fail-closed behavior and migration

Unknown eligibility, required approval, consent, policy version, storage
integrity, or governance state fails closed: no GEI capture or influence, no
crash, and no interruption to canonical gameplay. Optional Intelligence must
remain optional when disabled, unsupported, uncertain, slow, or unavailable.

Future persisted schemas must be versioned. A migration must preserve semantic
and epistemic distinctions; incompatible meaning, policy, approval, or schema
versions require explicit migration, deletion, or quarantine behavior rather
than silent reinterpretation.

## 13. Preconditions and gate answers

**GEI-04B may not capture now.** It may begin only after: (1) this DG-00
contract remains approved; (2) GB-UX-00 implements and verifies the main-screen
control, canonical-only OFF behavior, badge semantics, clear/delete path, and
fail-closed persistence state; (3) GB-PARENT-00 implements and verifies the
protected/unknown eligibility and approval path where applicable; (4) legal/
policy mapping and store disclosures are completed for the shipped audience;
(5) the capture scope, local storage, retention, reset, access, and tests have
a separate approved implementation gate. Cloud, telemetry, long-term memory,
DecisionEpisode, scenario/model, and gameplay influence each require their own
later gate.

GB-UX-00 must not add capture or influence. It must expose the master control,
persist only the minimum enablement state after its storage review, apply OFF
semantics immediately, offer a distinct Clear Data route, and keep the badge
meaning narrow. GB-PARENT-00 must establish the jurisdiction/store policy
mapping, protected/unknown fail-closed behavior, non-bypassable approval,
revocation handling, and minimum approval state before protected users can
enable collection.

`NEXT_AUTHORIZED_GEI_TASK = GB-UX-00`. GEI-04B remains unauthorized.

## 14. Explicit prohibitions

DG-00 does not authorize runtime capture, persistence, telemetry, cloud sync,
research collection, DecisionEpisode capture, policy execution, personalization,
GameBrain gameplay influence, UI implementation, Age Gate changes, parental
approval implementation, or changes to GameState/GameBrain Core.
