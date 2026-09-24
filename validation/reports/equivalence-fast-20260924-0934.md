# Equivalence report (2026-09-24 09:34)

- Commit: `b14e406-dirty`; tier: `fast`
- R 4.5.2; glmnet 5.1; lars 1.3; BLAS: /opt/homebrew/Cellar/openblas/0.3.30/lib/libopenblasp-r0.3.30.dylib
- Oracles: SILM 1.0.0, hdi 0.1-10 (znz) / 0.1-6 (cv), scalreg 1.0.1
- Totals: 69 cases; 69 E0, 0 ALLOWED, 0 OLD-ERROR, 0 BOTH-ERROR, **0 FAIL**

Status: E0 = values and `.Random.seed` identical; ALLOWED = enumerated intentional
difference; OLD-ERROR = archived code errors, new code returns (enumerated fix).

| scenario | cases | E0 | ALLOWED | OLD_ERROR | BOTH_ERROR | FAIL | seeds_identical | max_abs_diff | seconds |
|---|---|---|---|---|---|---|---|---|---|
| C-lasso.proj | 44 | 44 | 0 | 0 | 0 | 0 | 44 | 0 | 39.8 |
| C-lasso.proj-binomial-legacy |  4 |  4 | 0 | 0 | 0 | 0 |  4 | 0 |  3.7 |
| D-boot.lasso.proj | 21 | 21 | 0 | 0 | 0 | 0 | 21 | 0 | 69.5 |

## Non-E0 cases

