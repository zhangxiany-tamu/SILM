# Equivalence report (2026-09-24 09:19)

- Commit: `1149cec-dirty`; tier: `fast`
- R 4.5.2; glmnet 5.1; lars 1.3; BLAS: /opt/homebrew/Cellar/openblas/0.3.30/lib/libopenblasp-r0.3.30.dylib
- Oracles: SILM 1.0.0, hdi 0.1-10 (znz) / 0.1-6 (cv), scalreg 1.0.1
- Totals: 484 cases; 465 E0, 0 ALLOWED, 15 OLD-ERROR, 4 BOTH-ERROR, **0 FAIL**

Status: E0 = values and `.Random.seed` identical; ALLOWED = enumerated intentional
difference; OLD-ERROR = archived code errors, new code returns (enumerated fix).

| scenario | cases | E0 | ALLOWED | OLD_ERROR | BOTH_ERROR | FAIL | seeds_identical | max_abs_diff | seconds |
|---|---|---|---|---|---|---|---|---|---|
| B-SR-znz |  14 |  14 | 0 | 0 | 0 | 0 |  14 |  0 |  76.9 |
| B-SR-cv |  14 |  14 | 0 | 0 | 0 | 0 |  14 |  0 |  64.9 |
| B-SimCI-znz | 112 | 112 | 0 | 0 | 0 | 0 | 112 |  0 | 571.0 |
| B-SimCI-cv | 112 | 112 | 0 | 0 | 0 | 0 | 112 |  0 | 500.6 |
| B-Step-znz |  28 |  28 | 0 | 0 | 0 | 0 |  28 |  0 | 143.0 |
| B-Step-cv |  28 |  28 | 0 | 0 | 0 | 0 |  28 |  0 | 122.0 |
| B-ST-znz |  56 |  52 | 0 | 4 | 0 | 0 |  52 |  0 | 266.2 |
| B-ST-cv |  56 |  52 | 0 | 4 | 0 | 0 |  52 |  0 | 215.4 |
| E-ST-E1-null |  12 |   7 | 0 | 5 | 0 | 0 |   7 |  0 | 118.3 |
| E-ST-E2-oversize |   4 |   0 | 0 | 0 | 4 | 0 |   4 | NA |   1.2 |
| E-ST-E3-rd-example |  36 |  34 | 0 | 2 | 0 | 0 |  34 |  0 |  15.0 |
| E-ST-E4-singleton |  12 |  12 | 0 | 0 | 0 | 0 |  12 |  0 | 122.5 |

## Non-E0 cases

- `B-ST-znz` case 33 (B5,sub=20,test=2..200,seed=1): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `B-ST-znz` case 35 (B5,sub=20,test=3..200,seed=1): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `B-ST-znz` case 37 (B5,sub=30,test=2..200,seed=1): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `B-ST-znz` case 39 (B5,sub=30,test=3..200,seed=1): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `B-ST-cv` case 33 (B5,sub=20,test=2..200,seed=1): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `B-ST-cv` case 35 (B5,sub=20,test=3..200,seed=1): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `B-ST-cv` case 37 (B5,sub=30,test=2..200,seed=1): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `B-ST-cv` case 39 (B5,sub=30,test=3..200,seed=1): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `E-ST-E1-null` case 2 (E1-null,sub=30,seed=2): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `E-ST-E1-null` case 3 (E1-null,sub=30,seed=3): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `E-ST-E1-null` case 6 (E1-null,sub=30,seed=6): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `E-ST-E1-null` case 7 (E1-null,sub=30,seed=7): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `E-ST-E1-null` case 10 (E1-null,sub=30,seed=10): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: x should be a matrix with 2 or more columns
- `E-ST-E2-oversize` case 1 (E2-oversize,sub=70,seed=1): **BOTH-ERROR**; value identical=FALSE, seed identical=TRUE, max|diff|=NA; old error: only 0's may be mixed with negative subscripts; new error: The screening lasso selected 30 variables, more than |D2| - 1 = 29; use a smaller 'sub.size' (Zhang and Cheng (2017) use n/5 to n/3).
- `E-ST-E2-oversize` case 2 (E2-oversize,sub=70,seed=2): **BOTH-ERROR**; value identical=FALSE, seed identical=TRUE, max|diff|=NA; old error: only 0's may be mixed with negative subscripts; new error: The screening lasso selected 32 variables, more than |D2| - 1 = 29; use a smaller 'sub.size' (Zhang and Cheng (2017) use n/5 to n/3).
- `E-ST-E2-oversize` case 3 (E2-oversize,sub=70,seed=3): **BOTH-ERROR**; value identical=FALSE, seed identical=TRUE, max|diff|=NA; old error: only 0's may be mixed with negative subscripts; new error: The screening lasso selected 30 variables, more than |D2| - 1 = 29; use a smaller 'sub.size' (Zhang and Cheng (2017) use n/5 to n/3).
- `E-ST-E2-oversize` case 4 (E2-oversize,sub=70,seed=4): **BOTH-ERROR**; value identical=FALSE, seed identical=TRUE, max|diff|=NA; old error: only 0's may be mixed with negative subscripts; new error: The screening lasso selected 35 variables, more than |D2| - 1 = 29; use a smaller 'sub.size' (Zhang and Cheng (2017) use n/5 to n/3).
- `E-ST-E3-rd-example` case 4 (E3-rd-example,sub=30,test=4..10,seed=4): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: 'x' must be an array of at least two dimensions
- `E-ST-E3-rd-example` case 32 (E3-rd-example,sub=30,test=4..10,seed=32): **OLD-ERROR**; value identical=FALSE, seed identical=FALSE, max|diff|=NA; old error: 'x' must be an array of at least two dimensions
