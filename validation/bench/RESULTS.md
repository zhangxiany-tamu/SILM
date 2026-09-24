# Performance notes

Machine: Apple silicon (10 cores), R 4.5.2, OpenBLAS 0.3.30 (1 thread),
glmnet 5.1. Data: n = 100, p = 500, Toeplitz(0.9) design.

## SILM core (validation/bench/bench_core.R)

| Step | SILM 1.0.0 code path | SILM 2.0.0 | Results |
|---|---|---|---|
| Theta (nodewise lasso), sequential | 39.1 s | 38.5 s | identical |
| Theta (nodewise lasso), `parallel = TRUE, ncores = 8` | n/a | 8.3 s | identical |
| `Sim.CI(set = 1:p, M = 500)` given Theta | 1.36 s | 0.13 s | identical |
| `Step(M = 500)` given Theta | 6.97 s | 0.17 s | identical |
| `SR()` given Theta | 0.12 s | 0.08 s | identical |

The bootstrap speed-up comes from computing `Theta[set, ] %*% t(X)` once per
call (per step in `Step()`) instead of once per bootstrap draw. The same BLAS
operations are applied to the same inputs, so the results are bit-identical
(harness report `validation/reports/equivalence-fast-20260924-0919.md`).
A fully vectorised bootstrap (`A %*% matrix(rnorm(n * M), n, M)`) would use a
different BLAS kernel and was not adopted: the remaining bootstrap cost is
already negligible.

## Rcpp assessment

After hoisting, more than 99% of the run time of the core functions is spent in
the nodewise lasso, i.e. in about 14p glmnet fits (compiled code). Replacing
them by a custom C++ coordinate descent could not reproduce glmnet's results
bit for bit, which the correctness requirement rules out. The gate for
adopting Rcpp (region >= 30% of the run time, >= 3x end-to-end speed-up,
identical results on macOS and Linux) is therefore not met; the package keeps
`NeedsCompilation: no`. The practical speed-up is `parallel = TRUE`, which is
exact because the parallelised computations draw no random numbers.
