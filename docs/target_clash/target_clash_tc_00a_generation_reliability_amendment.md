# Target Clash TC-00A: Generation Reliability Amendment

Status: **OWNER APPROVED FOR CORRECTIVE IMPLEMENTATION**  
Baseline: `4f386f96a106c4359b81c90f775ab7766714848b`

The random-anchor-first feasibility mechanism is superseded for Target Clash.
Target Clash now takes its finite, canonical direct-result domain from
`QuestionGenerator`, evaluates every possible target against the complete
requested stage profile, and selects randomly only from targets proven feasible.
The domain query is pure and does not consume the ordinary question RNG.

The selected target is materialized with `buildDirectForResult`; the complete
immutable stage is built before exposure. A Stage 2 target at Medium or Hard
also preflights the retained Triple Clash profile. This does not alter Triple
permutation, Target retention, zones, scoring, rewards, timing, or gameplay
tuning.

Retry counts no longer govern legal Target Clash success. Technical failures
remain fail-closed for unsupported input, empty or infeasible domains, and a
canonical-domain/materialization contradiction.
