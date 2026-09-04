# GB-MEASURE-01F-INPUT-FREEZE-RECOVERY-R2 — Fresh Independent Review

**Verdict:** `PASS / APPROVED_FOR_01F_EXEC`

## Findings

1. **Baseline:** branch and HEAD match. Only the prior v1 governance inputs are untracked; no tracked production change is present.

2. **Integrity:** JSON parses. SHA-256 matches:

```text
918ba80bccadea4f45807c6c3329c54389a769e1f15c0d39d3e6672a5af5d79e
```

Markdown and JSON agree on the execution-critical R2 fields.

3. **RC-3:** resolved. R2 explicitly freezes complete-data-only simulation, forbids all listed incomplete-data handling, fails a malformed replicate closed, retains it in all denominators, and reserves missingness/censoring for a new prospective version.

4. **RC-4:** resolved. R2 freezes CPython 3.13.5, NumPy 2.3.5, `PCG64DXSM`, `Generator.normal`, `Generator.binomial`, canonical tokens, component labels, sub-seed hashing, draw order, and fail-closed version mismatch. Component-specific seeds make execution and parallel scheduling order independent.

5. **R1 regression check:** still resolved. The independent decision pair and AB/BA rule remain explicit. The plug-in variance remains correctly:

```text
V_adj = VD + VF + VP + 2 × orientation_sign × Cov(F_hat, P_hat)
```

No new blocking scientific or execution-input defect found.

## Freeze-readiness

| Freeze item | Status |
|---|---|
| Candidate grid and allocations | Pass |
| Replications and phases | Pass |
| RNG/reproducibility | Pass |
| Binary DGM | Pass |
| Null and sensitivity change | Pass |
| Variance scenarios | Pass |
| Form/order/item assumptions | Pass |
| Practice effects | Pass |
| Missingness/censoring | Pass |
| Decision criterion | Pass |
| Precision tolerances | Pass |
| False-positive gate | Pass |
| Sensitivity reporting | Pass |
| Indeterminate handling | Pass |
| Worst-case rule | Pass |
| Minimum-design ordering | Pass |
| Invalid-run handling | Pass |
| Required outputs | Pass |
| Independent-review gate | Pass |
| Authority boundary | Pass |

No simulation was run or inspected, and no file was modified. R2 is execution-input complete.

The reviewed host had Python 3.14.0, so the frozen CPython 3.13.5 preflight would correctly fail closed there; governed execution requires the specified runtime and explicit protocol-owner approval.
