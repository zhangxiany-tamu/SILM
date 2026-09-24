# Equivalence report (2026-09-24 08:34)

- Commit: `b213b32-dirty`; tier: `full`
- R 4.5.2; glmnet 5.1; lars 1.3; BLAS: /opt/homebrew/Cellar/openblas/0.3.30/lib/libopenblasp-r0.3.30.dylib
- Oracles: SILM 1.0.0, hdi 0.1-10 (znz) / 0.1-6 (cv), scalreg 1.0.1
- Totals: 364 cases; 364 E0, 0 ALLOWED, 0 OLD-ERROR, 0 BOTH-ERROR, **0 FAIL**

Status: E0 = values and `.Random.seed` identical; ALLOWED = enumerated intentional
difference; OLD-ERROR = archived code errors, new code returns (enumerated fix).

| scenario | cases | E0 | ALLOWED | OLD_ERROR | BOTH_ERROR | FAIL | seeds_identical | max_abs_diff | seconds |
|---|---|---|---|---|---|---|---|---|---|
| A1-scaled-lasso | 324 | 324 | 0 | 0 | 0 | 0 | 324 | 0 | 58.3 |
| A2-standardize |  40 |  40 | 0 | 0 | 0 | 0 |  40 | 0 |  7.6 |

## Non-E0 cases

