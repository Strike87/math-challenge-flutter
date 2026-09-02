# GB-PREVIEW-01 Ruleset Research 02 — Quality Adjudication

**Batch:** `FULL-TEXT-EXTRACTION-01`
**Purpose:** source-quality and transfer appraisal only. No numeric quality score is used.

## Governance rule

Source quality and transfer relevance are separate. A high-tier source can be weakly transferable to `PreviewEvidence`, and a lower-tier source can still be useful for construct boundaries. No source below is granted ruleset authority by its tier.

| Source ID | Full text reviewed? | Final source type | Final tier | Tier rationale | Methodological strengths relevant here | Methodological limitations | Construct relevance | Transfer relevance | Tensions/conflicts observed | Retain for synthesis? | Reason |
|---|---|---|---|---|---|---|---|---|---|---|---|
| R01 | Yes | Scoping review | C | Scoping review is not a systematic review/meta-analysis under the frozen hierarchy; useful authoritative construct mapping | Broad mapping of mathematics productive-struggle literature; explicit heterogeneity/gap analysis | Heterogeneous measures; many qualitative/non-empirical studies; not an effect-size synthesis | High for productive-struggle boundaries | Low | Tension with any performance-only definition of “productive challenge” | Yes | Useful to prevent construct collapse and to define what is missing from PreviewEvidence |
| R03 | No | Meta-analysis by bibliographic identity only | PENDING_FULL_TEXT | Final quality cannot be adjudicated without full text | Not adjudicated | Not adjudicated | Potentially high for productive failure | Unknown | Not adjudicated | Pending | Complete text required before accepting design, inclusion, moderators, and effect interpretation |
| R04 | Yes | Comparative theoretical review/integration | C | Theory/comparative guidance, not a methodological standard or systematic review | Explicitly compares desirable-difficulty and cognitive-load assumptions; strong construct-separation value | Proposed integration remains conceptual and calls for empirical validation | High for difficulty/load boundaries | Low | Shows that “more difficulty” can help or harm depending on complexity/expertise, contradicting universal monotonic rules | Yes | Important boundary-condition source despite low direct transfer |
| X02 | No | Systematic review by bibliographic identity only | PENDING_FULL_TEXT | Final Tier A cannot be awarded until complete text and methods are appraised | Not adjudicated | Not adjudicated | Potentially high for cognitive-load management | Unknown | Not adjudicated | Pending | Restricted full text in this execution |
| R06 | No | Educational measurement application by bibliographic identity | PENDING_FULL_TEXT | “Strong Tier B” cannot be established without design/method appraisal | Not adjudicated | Not adjudicated | Potentially high for recent-change/reliability | Unknown | Not adjudicated | Pending | Accepted-manuscript record found but complete file not reviewed |
| R07 | Yes | Peer-reviewed methodological comparison | C | Methodological comparison is not automatically a peer-reviewed methodological standard under the frozen hierarchy | Extensive comparison across estimands/sample regimes; clearly states model assumptions and method dependence | Not educational; assumes independent binomial samples; recommendations are inferential-method-specific | High for sparse-proportion precision limits | Very low | Conflicts with any attempt to use one arbitrary small-n threshold independent of sampling/model assumptions | Yes | Useful for ruling out unsupported threshold transfer |
| R08 | Yes | Technical survey/preprint | C | Authoritative technical guidance/survey, but not validated educational measurement | Clear taxonomy of ambiguity vs novelty rejection and evaluation trade-offs | Preprint; ML-model assumptions; no educational validation | Moderate for abstention vocabulary | Very low | Shows ambiguity/novelty are model/data concepts, not synonyms for generic conflict/sparsity | Yes | Retain only for conceptual abstention/rejection structure |
| R09 | Yes | Peer-reviewed theoretical methods paper | C | Theory/method paper; not educational-measurement standard | Formalizes cost/risk/coverage reject formulations and conditions for optimal rejection | Requires probabilities, loss/risk, target coverage/reject cost, model-specific uncertainty | Moderate for H/E/G structure | None to current contract | Demonstrates that precedence/rejection is objective-dependent, undermining arbitrary winner selection | Yes | Useful primarily to document non-transfer and objective-dependence |
| R10 | Yes | Professional educational/psychological testing standards | A | Fits frozen Tier A as authoritative methodological standards/validated measurement governance | Direct standards for validity arguments, reliability/precision, interpretation/use, cut-score justification | General; supplies no GB-PREVIEW-01 scenario rule | Very high for validity/interpretation governance | High for governance, low for concrete scenario mapping | Strongly constrains any source family that would equate raw observed variables with validated constructs | Yes | Foundational synthesis source for admissibility and abstention burden |
| R11 | No | Educational-measurement review by bibliographic identity | PENDING_FULL_TEXT | Final Tier A requires full-text appraisal of its measurement basis and role | Not adjudicated | Not adjudicated | Potentially high for response-time/log-data validity | Unknown | Not adjudicated | Pending | Full article body not reliably obtained |

## Final tier counts for reviewed sources

```text
Tier A               = 1   (R10)
Tier B               = 0
Tier C               = 5   (R01, R04, R07, R08, R09)
PENDING_FULL_TEXT    = 4   (R03, X02, R06, R11)
```

## Cross-source quality observations allowed at this stage

These are quality/transfer observations, not ruleset synthesis:

1. R10 has the strongest direct authority for the **burden of interpretation validity**, but it does not supply a scenario predicate.
2. R01 and R04 show that productive struggle, desirable difficulty, task difficulty, and cognitive load are not interchangeable operational constructs.
3. R07 shows that even a narrow statistical question such as two-proportion precision depends on explicit sampling/model assumptions and estimand; this cannot be converted into a generic evidence-count cutoff.
4. R08 and R09 support abstention/rejection as legitimate decision architectures only inside predictive/risk frameworks whose core ingredients are absent from PreviewEvidence.
5. No reviewed source validates synthetic latency category, aggregate accuracy, or timeout count as a standalone measure of productive challenge, cognitive load, overchallenge, or underchallenge.
