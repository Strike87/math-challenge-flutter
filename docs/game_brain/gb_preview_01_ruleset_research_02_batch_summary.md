# GB-PREVIEW-01 Ruleset Research 02 — Full-Text Extraction Batch 01 Summary

**Research execution:** `GB-PREVIEW-01-RULESET-RESEARCH-02`
**Batch:** `FULL-TEXT-EXTRACTION-01`

## Scope

The batch attempted full-text retrieval and extraction for exactly 10 preselected DISCOVERY-01 sources:

`R01`, `R03`, `R04`, `X02`, `R06`, `R07`, `R08`, `R09`, `R10`, `R11`.

No additional source was silently admitted to the extraction corpus.

## Extraction status

```text
Batch sources                    = 10
Full texts obtained/reviewed     = 6
Full texts not obtained          = 4
Reviewed sources retained        = 6
Reviewed sources excluded        = 0
Pending-access sources           = 4
```

Reviewed: `R01`, `R04`, `R07`, `R08`, `R09`, `R10`.

Pending access: `R03`, `X02`, `R06`, `R11`.

## Final quality status

```text
Tier A               = 1
Tier B               = 0
Tier C               = 5
PENDING_FULL_TEXT    = 4
```

The Tier A source is R10 (AERA/APA/NCME Standards). The five reviewed Tier C sources are R01, R04, R07, R08, and R09. No reviewed empirical source in this batch was promoted to final Tier B merely from bibliographic identity.

## Constructs actually represented by reviewed full text

- productive struggle in mathematics education;
- desirable difficulties and retrieval effort;
- task/item difficulty;
- cognitive-load theory, including intrinsic/extraneous load and element interactivity;
- statistical interval estimation for two independent binomial proportions;
- reject option/selective prediction;
- ambiguity rejection versus novelty rejection;
- selective risk, coverage, reject cost, and uncertainty-score concepts;
- validity of score interpretations/uses;
- reliability/precision and measurement error;
- cut-score/classification governance.

## Measures actually represented by reviewed full text

The reviewed literature does **not** converge on one common operational measure. Instead it contains distinct measurement families:

- qualitative/quantitative indicators of engagement with challenging mathematics and instructional practice (R01);
- task manipulation, retrieval difficulty, later retention, material complexity, element interactivity, expertise, and cognitive-load framing (R04);
- independent binomial samples, sample proportions, estimands, interval coverage, and method performance (R07);
- predictor outputs, training distribution, targets, uncertainty/confidence, rejection rate/coverage, and loss/cost (R08/R09);
- validity evidence, reliability/precision, measurement error, intended use, and cut-score justification (R10).

These measures are operationally non-equivalent and were not averaged or collapsed.

## Major transfer barriers to PreviewEvidence

1. **Challenge/task demand is missing.** Accuracy and latency do not reveal material complexity, effort, persistence, or instructional challenge.
2. **Learner expertise/prior knowledge is missing.** R04 treats expertise as a material moderator of effective difficulty/cognitive load.
3. **Learning/retention outcomes are missing.** Immediate performance cannot stand in for desirable-difficulty benefits that concern later retention/transfer.
4. **Validated response-time/cognitive-load measurement is missing.** The categorical synthetic latency field cannot be assumed to measure effort or cognitive load.
5. **Sampling-model assumptions are missing.** R07 assumes two independent binomial samples and a specified estimand; PreviewEvidence does not establish this.
6. **Predictive-model machinery is missing.** R08/R09 require a predictor/target/training distribution and/or risk/loss/coverage structure not present in the contract.
7. **Construct-validity evidence is missing.** R10 requires a validity argument linking observed measures to intended interpretations; no reviewed source supplies that link for GB-PREVIEW-01 fields.

## Source-level tensions retained

These tensions are retained as research facts, not resolved into a rule:

- Productive-struggle literature describes a process of engagement with challenge and persistence; it is not equivalent to strong or weak aggregate performance.
- Desirable-difficulty and cognitive-load perspectives can recommend opposite directions under different complexity/expertise conditions; “more difficulty is better” and “less difficulty is better” are both overgeneralizations.
- Statistical precision methodology can recommend different procedures by sample/model regime, which argues against a context-free evidence-count threshold.
- Reject-option theory legitimizes abstention but makes the optimal reject decision dependent on prediction/risk objectives absent from PreviewEvidence.
- Educational-measurement standards require a validity argument before observed scores/fields are given substantive meaning.

## Pending sources and Batch-02 access gaps

`R03`, `X02`, `R06`, and `R11` require complete lawful text before source-level extraction and final tier adjudication. Their expected research roles remain:

- R03: meta-analytic evidence on learning from failure/productive failure;
- X02: systematic-review evidence on cognitive-load management in mobile learning;
- R06: repeated-measure reliability and reliable-change interpretation in education;
- R11: educational-measurement treatment of response-time/log data and validity/reliability dependencies.

The batch does not infer their full-text conclusions from abstracts or metadata.

## New candidates from citation chasing

No formal backward/forward citation-chasing pass was used to admit or screen new sources in this batch. No new candidate was added to the extraction corpus.

## Research status after Batch 01

The reviewed sources strengthen the evidence that several intuitive mappings are **not yet defensible**:

```text
synthetic latency category  != validated response-time/cognitive-load measure
aggregate accuracy          != validated challenge measure
timeout count                != validated cognitive-load/frustration measure
segment difference           != durable learning/reliable change
reject-option theory         != preview precedence rule
```

This is an extraction-stage observation about transfer limits, not a ruleset.

The project-level threshold status remains:

```text
NO DEFENSIBLE EXACT THRESHOLD IDENTIFIED
```

No performance band, minimum evidence count, timeout cutoff, latency cutoff, scenario predicate, compatibility matrix, precedence order, or fixture-derived rule was selected.

```text
FULL-TEXT-EXTRACTION-01
= R1 INDEPENDENT RE-REVIEW = PASS
= FULL-TEXT-EXTRACTION-01 = APPROVED_FOR_BATCH_CLOSE

Ruleset = NOT DEFINED
Ruleset authorization = NOT AUTHORIZED
Implementation authorization = NOT AUTHORIZED
mayAffectGameplay = false
```
