# Equivalence report (2026-09-24 09:37)

- Commit: `e626b6b`; tier: `full`
- R 4.5.2; glmnet 5.1; lars 1.3; BLAS: /opt/homebrew/Cellar/openblas/0.3.30/lib/libopenblasp-r0.3.30.dylib
- Oracles: SILM 1.0.0, hdi 0.1-10 (znz) / 0.1-6 (cv), scalreg 1.0.1
- Totals: 180 cases; 180 E0, 0 ALLOWED, 0 OLD-ERROR, 0 BOTH-ERROR, **0 FAIL**

Status: E0 = values and `.Random.seed` identical; ALLOWED = enumerated intentional
difference; OLD-ERROR = archived code errors, new code returns (enumerated fix).

| scenario | cases | E0 | ALLOWED | OLD_ERROR | BOTH_ERROR | FAIL | seeds_identical | max_abs_diff | seconds |
|---|---|---|---|---|---|---|---|---|---|
| C-lasso.proj | 132 | 132 | 0 | 0 | 0 | 0 | 132 | 0 | 393.9 |
| C-lasso.proj-binomial-legacy |   6 |   6 | 0 | 0 | 0 | 0 |   6 | 0 |   3.5 |
| D-boot.lasso.proj |  42 |  42 | 0 | 0 | 0 | 0 |  42 | 0 | 479.3 |

## Non-E0 cases

