# GB-PREVIEW-01 — Ruleset Research Protocol

## 1. Status and authority

```text
Research ID                  = GB-PREVIEW-01-RULESET-RESEARCH-00
Research version             = 0.1
Research status              = FROZEN / READY FOR RESEARCH EXECUTION
Ruleset status               = NOT DEFINED
Ruleset authorization        = NOT AUTHORIZED
Implementation authorization = NOT AUTHORIZED
mayAffectGameplay            = false
```

This is research and design only. It defines neither an interpreter ruleset
nor an implementation, and it confers no product, gameplay, or evidence
authority.

## 2. Upstream frozen boundaries

The only upstream sources are
`docs/game_brain_gb_preview_01_frozen_experiment_contract.md` and
`docs/game_brain_gb_preview_01_implementation_design.md`. Their frozen
taxonomy, synthetic `PreviewEvidence` input contract, oracle boundary,
fixture construction and expectations, baseline isolation, determinism, and
authority constraints remain unchanged.

Only `PreviewEvidence` may cross the future interpreter boundary. Fixture IDs,
expected outcomes, oracle labels, baseline labels, fixture metadata, and hidden
scenario identity remain harness-only and must not be supplied to, imported by,
or otherwise accessible to an interpreter.

## 3. Research objective

Determine what independently sourced, construct-valid evidence would be
needed before a separate ruleset proposal could justify scenario predicates,
sufficiency, performance-band, timeout/friction, latency, convergent-evidence,
temporal-improvement, contradiction, ambiguity, abstention, primary-scenario
precedence, or scenario-compatibility semantics for synthetic preview inputs.

## 4. Anti-overfitting firewall

No candidate predicate, threshold, precedence, compatibility decision, or
interpretation rule may be derived from fixture values, expected outcomes,
baseline thresholds, fixture identities, oracle labels, or an expected-outcome
matrix. Frozen fixtures may later test an independently derived ruleset; they
cannot be its source. No fixture-specific branch, lookup, or reconstruction is
admissible.

## 5. Construct-by-construct research questions

### A. Productive challenge

What evidence can distinguish successful performance with meaningful friction
from underchallenge and overchallenge?

### B. Overchallenge

What performance-failure and friction evidence, if any, would justify a
bounded overchallenge interpretation?

### C. Underchallenge

What evidence is necessary before strong performance may be interpreted as
insufficient challenge rather than successful performance?

### D. Recent improvement

What earlier-versus-recent change is meaningful, what assumptions and evidence
are required, and what prevents a durability claim?

### E. Sparse evidence and abstention

What evidence is required before substantive interpretation, and how do
missing context, segmentation, latency, or other evidence constrain it?

### F. Conflict

When does co-existing support for incompatible hypotheses require conflict
rather than a mixed or abstaining output?

### G. Uncertainty

How can uncertainty be represented without confidence or probability output?

### H. Precedence

If multiple candidate predicates hold, what justified precedence or abstention
approach prevents arbitrary winner selection?

## 6. Source inclusion/exclusion criteria

Use this source-quality hierarchy:

- Tier A: systematic reviews, meta-analyses, peer-reviewed methodological
  standards, and validated educational-measurement literature.
- Tier B: strong peer-reviewed empirical studies relevant to the construct.
- Tier C: theory papers and authoritative technical guidance.

Blogs, product documentation, unsourced heuristics, fixture-derived
thresholds, and arbitrary round numbers are excluded as rule authority.
Every candidate rule record must state its construct/question, source,
population and domain relevance, operational measure, assumptions, minimum
evidence, threshold or predicate only if supported, uncertainty and
limitations, applicability to synthetic preview inputs, transfer-risk note,
and abstention condition.

Research execution must retain a search/discovery log recording each database
or search channel, search date, exact query or query-family, any language or
date-range restriction, whether backward or forward citation chasing was used,
and the number of records discovered. It must retain the recorded flow
`discovered → deduplicated → title/abstract screened → full-text reviewed →
included → excluded with reason`. Exclusion reasons must be retained. A source
must not be excluded merely because its result disagrees with a desired future
ruleset.

## 7. Evidence extraction schema

Record the following for each eligible source: bibliographic identity and
quality tier; research question and construct; population, domain, setting,
and task; study design; operational measures; reported evidence requirements;
reported threshold or predicate when present; assumptions; uncertainty and
limitations; synthetic-preview applicability; transfer risks; and a proposed
abstention condition. Extraction records describe source evidence; they do not
create rules.

Every extraction and future candidate-rule record must retain a source
identifier or citation and sufficient provenance to reconstruct why it was
included. No uncited synthesized claim may become rule authority.

Synthesis and adjudication must not average or merge operationally
non-equivalent constructs or measures. Source quality and transfer relevance
must be assessed separately; a higher tier does not automatically override a
more directly applicable lower-tier source without explicit justification.
Conflicting credible evidence must be retained, not suppressed. An unresolved
material conflict requires `NEEDS_MORE_EVIDENCE` or qualitative-only treatment,
not an invented compromise threshold. An exact threshold requires convergent,
defensible evidence for the same construct and measure plus defensible transfer
to `PreviewEvidence`; otherwise retain `NO DEFENSIBLE EXACT THRESHOLD
IDENTIFIED`.

## 8. Threshold-admissibility criteria

An exact threshold is admissible only when the evidence supports it for the
relevant construct and operational measure and its transfer to the synthetic
preview representation is defensible. Otherwise record exactly:

```text
NO DEFENSIBLE EXACT THRESHOLD IDENTIFIED
```

When that condition holds, the subsequent proposal must use only qualitative
structural predicates, narrow the experiment, revise the contract through
`REFINE_CONTRACT`, or `SIMPLIFY`. This protocol sets no numeric, percentage,
sample, or timeout threshold.

## 9. Predicate-admissibility criteria

A predicate may be proposed only after its construct definition, operational
measure, source support, assumptions, minimum evidence, synthetic-input
applicability, transfer risks, and abstention boundary are independently
documented. Unsupported predicate components must be omitted, narrowed, or
left for abstention. This protocol defines no predicate.

## 10. Conflict / ambiguity / abstention research requirements

Research must establish whether incompatible support can be identified from
the permitted evidence, what missing or contradictory information prevents a
substantive interpretation, and how uncertainty is expressed without scores
or probabilities. Any future treatment must retain explicit abstention where
the evidence does not justify a result. This protocol defines no conflict,
ambiguity, or abstention decision rule.

## 11. Scenario compatibility research requirements

Research must separately assess which scenario combinations are conceptually
compatible, which cannot be supported together, and when the evidence instead
requires abstention. Compatibility is not decided here, and no precedence or
primary-scenario rule is defined.

## 12. Transferability limitations

Published evidence may not transfer from its population, domain, measure,
setting, or real-world instrumentation to finite synthetic `PreviewEvidence`.
Every proposal must state those limits, avoid claims about real learners or
durable evidence validity, and abstain where the transfer cannot be defended.

## 13. Falsification conditions

A future candidate must be rejected or returned for refinement when source
support is inadequate, measures do not map defensibly to permitted synthetic
inputs, assumptions conflict, transfer risk is unresolved, a required
abstention boundary is absent, or a proposed rule relies on the frozen oracle
or fixtures. Falsification is a research gate, not an interpreter rule.

## 14. Research audit trail

The final research record must include the search log, screening log,
included-source table, excluded-source table with reasons, extraction table,
synthesis/adjudication notes, unresolved conflicts, and final decision outcome.
This is research governance only and does not create a ruleset.

## 15. Decision outcomes

- `RULESET_RESEARCH_READY`: the research record supports a separately reviewed
  ruleset proposal without oracle-derived logic.
- `NEEDS_MORE_EVIDENCE`: the record is incomplete or support is insufficient.
- `REFINE_CONTRACT`: the frozen contract lacks a defensible representation
  needed for the researched construct.
- `SIMPLIFY`: the proposed scope should be reduced to what evidence supports.

These are research-process outcomes only; none authorizes a ruleset or
implementation.

## 16. Explicit non-authorization

Ruleset remains **NOT AUTHORIZED**. Implementation remains **NOT AUTHORIZED**.
No interpreter, tests, Dart, ruleset, production integration, persistence,
network activity, or gameplay effect is authorized by this document.
