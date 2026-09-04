# GB-MEASURE-01F-EXEC — Fresh Independent Post-Execution Outcome Review

**Review date:** 2026-09-04  
**Review role:** fresh reviewer with no prior involvement in building R1/R2 in the review conversation.  
**Review basis:** raw `research.zip` package contents, including executor source and result CSV/JSON/Markdown artifacts.  
**Per-replicate RNG replay:** not performed.  
**Outcome:** `PASS / INDEPENDENT_OUTCOME_VERIFIED`

## Independent findings

### Hash / artifact integrity — CONFIRMED

- ZIP SHA-256, frozen manifest SHA-256, and execution code SHA-256 matched the values recorded in the execution package.
- All non-empty result files matched `result_hashes.json`.
- The three no-survivor output files hashed to the SHA-256 of an empty file, consistent with protocol gating.

### Coverage — CONFIRMED

```text
design_grid.csv       = 49 rows
screening_metrics.csv = 441 rows = 49 × 9
missing design×scenario cells = 0
duplicate design×scenario cells = 0
R per screening cell = 3000
AB = 1500
BA = 1500
```

### Hard-screen recomputation — CONFIRMED

The reviewer independently reimplemented the hard-screen logic from source rather than calling the executor's `hard_fail()` function, applied it across all 441 screening rows, and diffed the reconstructed exclusions against `screening_exclusions.csv`.

```text
mismatches = 0
excluded designs = 49 / 49
screening survivors = 0
```

Reason strings matched.

### S09 decisive result — CONFIRMED

Independent Wilson-bound recomputation reproduced:

```text
S09 calibration-pass rate range
= 0.900667 to 0.984333

lower 99% Wilson bound range
= 0.885704 to 0.977334

frozen failing boundary
= > 0.200
```

The lowest observed S09 calibration-pass rate occurred at:

```text
GBM01-N1-400-N2-200
2702 / 3000
= 0.900667

lower 99% Wilson bound
= 0.885704
```

Therefore all 49 designs independently satisfy the frozen hard-screen exclusion condition through the S09 calibration-pass sentinel alone. The result is not a borderline threshold or rounding artifact.

### Confirmatory / sensitivity gating — CONFIRMED

The executor gates confirmatory and sensitivity work behind `if survivors:`. With `survivors=[]`, the three empty files are protocol-consistent and do not represent missing work:

```text
confirmatory_metrics.csv
s09_sentinel.csv
sensitivity_power_fnr.csv
```

### RNG hygiene — CONFIRMED

The executor uses deterministic component-keyed:

```text
np.random.Generator(np.random.PCG64DXSM(seed(...)))
```

No Python `random`, `default_rng`, global NumPy RNG state, wall-clock entropy, or OS entropy was found in the execution code.

### Authority boundary — CONFIRMED

```text
mayAffectGameplay = false
```

No production/gameplay path is introduced by the research executor.

## Review limitations

The reviewer verified the supplied package, source, hashes, aggregate outputs, coverage, interval arithmetic, and exclusion reconstruction. The reviewer did **not** replay every per-replicate random draw under the exact runtime.

That limitation does not undermine the independently reconstructed zero-survivor conclusion from the supplied governed aggregate screening artifacts.

## Verdict

```text
GB-MEASURE-01F-EXEC
INDEPENDENT POST-EXECUTION OUTCOME REVIEW
= PASS

NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID
= INDEPENDENTLY SUPPORTED

screening survivors
= 0 / 49

mayAffectGameplay
= false
```

This review validates the execution outcome. It does not convert the no-pass result into a successful reliable-change capability and does not authorize a new calibration design, threshold change, real-player measurement layer, policy activation, or gameplay influence.
