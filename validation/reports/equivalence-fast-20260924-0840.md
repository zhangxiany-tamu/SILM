# Equivalence report (2026-09-24 08:40)

- Commit: `4a904e7-dirty`; tier: `fast`
- R 4.5.2; glmnet 5.1; lars 1.3; BLAS: /opt/homebrew/Cellar/openblas/0.3.30/lib/libopenblasp-r0.3.30.dylib
- Oracles: SILM 1.0.0, hdi 0.1-10 (znz) / 0.1-6 (cv), scalreg 1.0.1
- Totals: 210 cases; 206 E0, 0 ALLOWED, 0 OLD-ERROR, 4 BOTH-ERROR, **0 FAIL**

Status: E0 = values and `.Random.seed` identical; ALLOWED = enumerated intentional
difference; OLD-ERROR = archived code errors, new code returns (enumerated fix).

| scenario | cases | E0 | ALLOWED | OLD_ERROR | BOTH_ERROR | FAIL | seeds_identical | max_abs_diff | seconds |
|---|---|---|---|---|---|---|---|---|---|
| B-SR-znz |  14 |  14 | 0 | 0 | 0 | 0 |  14 | 0 |  76.3 |
| B-SimCI-znz | 112 | 112 | 0 | 0 | 0 | 0 | 112 | 0 | 581.4 |
| B-Step-znz |  28 |  28 | 0 | 0 | 0 | 0 |  28 | 0 | 144.6 |
| B-ST-znz |  56 |  52 | 0 | 0 | 4 | 0 |  56 | 0 | 201.0 |

## Non-E0 cases

- `B-ST-znz` case 33 (B5,sub=20,test=2..200,seed=1): **BOTH-ERROR**; value identical=TRUE, seed identical=TRUE, max|diff|=NA; old error: x should be a matrix with 2 or more columns; new error: x should be a matrix with 2 or more columns
- `B-ST-znz` case 35 (B5,sub=20,test=3..200,seed=1): **BOTH-ERROR**; value identical=TRUE, seed identical=TRUE, max|diff|=NA; old error: x should be a matrix with 2 or more columns; new error: x should be a matrix with 2 or more columns
- `B-ST-znz` case 37 (B5,sub=30,test=2..200,seed=1): **BOTH-ERROR**; value identical=TRUE, seed identical=TRUE, max|diff|=NA; old error: x should be a matrix with 2 or more columns; new error: x should be a matrix with 2 or more columns
- `B-ST-znz` case 39 (B5,sub=30,test=3..200,seed=1): **BOTH-ERROR**; value identical=TRUE, seed identical=TRUE, max|diff|=NA; old error: x should be a matrix with 2 or more columns; new error: x should be a matrix with 2 or more columns
