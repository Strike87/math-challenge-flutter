# Math Challenge Codex Workflow Prompts

## Verify repository setup

```text
Do not edit anything.

Summarize the repository instructions loaded from AGENTS.md.
Read docs/refactor_tracker.md and identify the first unchecked Active item.
List the custom agents available for this project.
```

## Audit-only cycle

```text
Read AGENTS.md, docs/behavior_contracts.md, and docs/refactor_tracker.md.

Work only on the first unchecked Active tracker item.

Delegate the investigation to parity_reasoner.

Requirements:
- parity_reasoner must remain read-only;
- inspect the real implementation and relevant tests;
- make no production changes;
- wait for the subagent to finish;
- return its complete evidence-based report;
- do not begin implementation afterward.

Do not edit, commit, or push anything.
```

## Approved implementation cycle

```text
Read AGENTS.md, docs/behavior_contracts.md, and docs/refactor_tracker.md.

The approved audit concluded:

[PASTE THE APPROVED AUDIT SUMMARY]

Delegate only the approved implementation to flutter_worker.

The worker must:
- confirm the repository, branch, and clean status;
- inspect the current implementation;
- change only the approved files;
- preserve documented behavior and ordering;
- run focused tests;
- run the full non-golden suite when shared behavior is touched;
- run visual parity tests;
- run flutter analyze;
- run git diff --check;
- not commit or push.

Wait for flutter_worker and inspect the complete diff.
Do not begin another tracker item.
```

## Regression review cycle

```text
Delegate a final review to regression_reviewer.

Review the current uncommitted diff against main.

Use:
- AGENTS.md;
- docs/behavior_contracts.md;
- the approved audit;
- the implementation report.

Focus on actual behavior regressions, timer/lifecycle risks, persistence,
rewards, scoring, achievements, navigation, ads, missing tests, and scope
violations.

Do not edit files.
Wait for the reviewer and summarize confirmed findings by severity.
```

## Feature-design cycle

```text
Read AGENTS.md, docs/behavior_contracts.md, and the named feature
specification under docs/features/.

Do not implement yet.

Delegate the integration audit to parity_reasoner.

The report must include:
1. Current related behavior
2. Recommended integration point
3. State ownership
4. Persistence and migration impact
5. Impact on every mode
6. Scoring, coins, and achievement impact
7. Timer and lifecycle impact
8. Ads and IAP impact
9. Navigation and reset impact
10. Minimal file plan
11. Automated test plan
12. Manual acceptance criteria
13. Rollback plan

Wait for the report and do not edit production code.
```

## Correcting one confirmed reviewer finding

```text
The reviewer confirmed this defect:

[PASTE ONE FINDING]

Send only this correction to flutter_worker.
Do not address unrelated suggestions.
Rerun the affected tests and review the resulting diff.
```
