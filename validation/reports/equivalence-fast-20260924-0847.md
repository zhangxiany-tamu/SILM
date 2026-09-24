# Equivalence report (2026-09-24 08:47)

- Commit: `84a8306-dirty`; tier: `fast`
- R 4.5.2; glmnet 5.1; lars 1.3; BLAS: /opt/homebrew/Cellar/openblas/0.3.30/lib/libopenblasp-r0.3.30.dylib
- Oracles: SILM 1.0.0, hdi 0.1-10 (znz) / 0.1-6 (cv), scalreg 1.0.1
- Totals: 420 cases; 412 E0, 0 ALLOWED, 0 OLD-ERROR, 8 BOTH-ERROR, **0 FAIL**

Status: E0 = values and `.Random.seed` identical; ALLOWED = enumerated intentional
difference; OLD-ERROR = archived code errors, new code returns (enumerated fix).

| scenario | cases | E0 | ALLOWED | OLD_ERROR | BOTH_ERROR | FAIL | seeds_identical | max_abs_diff | seconds |
|---|---|---|---|---|---|---|---|---|---|
| B-SR-znz |  14 |  14 | 0 | 0 | 0 | 0 |  14 | 0 |  75.0 |
| B-SR-cv |  14 |  14 | 0 | 0 | 0 | 0 |  14 | 0 |  63.9 |
| B-SimCI-znz | 112 | 112 | 0 | 0 | 0 | 0 | 112 | 0 | 575.1 |
| B-SimCI-cv | 112 | 112 | 0 | 0 | 0 | 0 | 112 | 0 | 501.5 |
| B-Step-znz |  28 |  28 | 0 | 0 | 0 | 0 |  28 | 0 | 145.5 |
| B-Step-cv |  28 |  28 | 0 | 0 | 0 | 0 |  28 | 0 | 123.4 |
| B-ST-znz |  56 |  52 | 0 | 0 | 4 | 0 |  56 | 0 | 210.0 |
| B-ST-cv |  56 |  52 | 0 | 0 | 4 | 0 |  56 | 0 | 179.0 |

## Non-E0 cases

- `B-ST-znz` case 33 (B5,sub=20,test=2..200,seed=1): **BOTH-ERROR**; value identical=TRUE, seed identical=TRUE, max|diff|=NA; old error: x should be a matrix with 2 or more columns; new error: x should be a matrix with 2 or more columns
- `B-ST-znz` case 35 (B5,sub=20,test=3..200,seed=1): **BOTH-ERROR**; value identical=TRUE, seed identical=TRUE, max|diff|=NA; old error: x should be a matrix with 2 or more columns; new error: x should be a matrix with 2 or more columns
- `B-ST-znz` case 37 (B5,sub=30,test=2..200,seed=1): **BOTH-ERROR**; value identical=TRUE, seed identical=TRUE, max|diff|=NA; old error: x should be a matrix with 2 or more columns; new error: x should be a matrix with 2 or more columns
- `B-ST-znz` case 39 (B5,sub=30,test=3..200,seed=1): **BOTH-ERROR**; value identical=TRUE, seed identical=TRUE, max|diff|=NA; old error: x should be a matrix with 2 or more columns; new error: x should be a matrix with 2 or more columns
- `B-ST-cv` case 33 (B5,sub=20,test=2..200,seed=1): **BOTH-ERROR**; value identical=TRUE, seed identical=TRUE, max|diff|=NA; old error: x should be a matrix with 2 or more columns; new error: x should be a matrix with 2 or more columns
- `B-ST-cv` case 35 (B5,sub=20,test=3..200,seed=1): **BOTH-ERROR**; value identical=TRUE, seed identical=TRUE, max|diff|=NA; old error: x should be a matrix with 2 or more columns; new error: x should be a matrix with 2 or more columns
- `B-ST-cv` case 37 (B5,sub=30,test=2..200,seed=1): **BOTH-ERROR**; value identical=TRUE, seed identical=TRUE, max|diff|=NA; old error: x should be a matrix with 2 or more columns; new error: x should be a matrix with 2 or more columns
- `B-ST-cv` case 39 (B5,sub=30,test=3..200,seed=1): **BOTH-ERROR**; value identical=TRUE, seed identical=TRUE, max|diff|=NA; old error: x should be a matrix with 2 or more columns; new error: x should be a matrix with 2 or more columns
