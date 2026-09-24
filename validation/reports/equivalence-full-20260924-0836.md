# Equivalence report (2026-09-24 08:36)

- Commit: `384011c-dirty`; tier: `full`
- R 4.5.2; glmnet 5.1; lars 1.3; BLAS: /opt/homebrew/Cellar/openblas/0.3.30/lib/libopenblasp-r0.3.30.dylib
- Oracles: SILM 1.0.0, hdi 0.1-10 (znz) / 0.1-6 (cv), scalreg 1.0.1
- Totals: 36 cases; 36 E0, 0 ALLOWED, 0 OLD-ERROR, 0 BOTH-ERROR, **0 FAIL**

Status: E0 = values and `.Random.seed` identical; ALLOWED = enumerated intentional
difference; OLD-ERROR = archived code errors, new code returns (enumerated fix).

| scenario | cases | E0 | ALLOWED | OLD_ERROR | BOTH_ERROR | FAIL | seeds_identical | max_abs_diff | seconds |
|---|---|---|---|---|---|---|---|---|---|
| A3-nodewise-hdi0.1-10 | 24 | 24 | 0 | 0 | 0 | 0 | 24 | 0 | 93.3 |
| A3-nodewise-hdi0.1-6 | 12 | 12 | 0 | 0 | 0 | 0 | 12 | 0 | 39.4 |

## Non-E0 cases

