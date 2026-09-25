# SILM 2.0.0 (2026-09-24)

SILM was archived on CRAN on 2026-07-10 because its dependency 'scalreg' was
archived (and with it 'hdi', which SILM also used). This release makes SILM
self-contained and adds the methods of Dezeure, Bühlmann and Zhang (2017),
which were available only in the archived 'hdi'.

## Dependencies

* SILM no longer depends on 'scalreg', 'hdi' or 'SIS'. It imports only
  'glmnet', 'lars' and 'MASS' (all on CRAN) and base R packages.
* The scaled lasso is SILM's own implementation of Sun and Zhang (2012, 2013);
  its results are identical to 'scalreg' 1.0.1. The nodewise lasso and the
  de-sparsified lasso code are adapted from 'hdi' 0.1-10 (GPL; credited in
  `Authors@R` and `inst/COPYRIGHTS`).

## Reproducibility

* Every result of SILM 1.0.0 can be reproduced exactly (same numbers and
  random number state under the same seed). This is verified continuously
  against the archived CRAN packages (`validation/`, and the `equivalence`
  GitHub workflow).
* New argument `nodewise = c("ZnZ", "cv")` for `SR()`, `ST()`, `Sim.CI()`,
  `Step()` and `Theta.hat()`: the tuning rule of the nodewise lasso is now
  explicit. SILM 1.0.0 took the nodewise lasso from an internal function of
  'hdi' and did not set its tuning rule. With hdi 0.1-6, current when SILM
  1.0.0 was published (January 2019), that was the cross-validated lambda
  described in Zhang and Cheng (2017, Section 5). hdi 0.1-7 (March 2019)
  silently changed it to the Z&Z rule, so SILM 1.0.0 installations used Z&Z
  from then until SILM was archived. The default `"ZnZ"` was chosen by a
  pre-registered study of both rules (`validation/calibration/DEFAULTS.md`;
  results in `validation/calibration/defaults-results/REPORT.md`) under its
  fixed decision rule (calibration first, then power): over 20
  `Sim.CI()`/`Step()` settings, 8 `SR()` settings and 3 `ST()` settings (200
  replications each), `"ZnZ"` halved the mean calibration shortfall (coverage
  below 95%, error rates above 5%) from 0.100 to 0.053 (95% bootstrap interval
  of the difference [-0.051, -0.044]). The joint coverage of `Sim.CI()` for
  all p coefficients was higher or equal in all 20 settings (for example 0.77
  with `"cv"` and 0.90 with `"ZnZ"` for signals (1.5, -1, 2) at p = 500), and
  exact support recovery by `SR()` improved; the price is about 12% wider
  intervals and 0.02-0.07 less power of `Step()` and `ST()`. With the default
  (and
  `legacy = TRUE` for `ST()`), results are those of SILM 1.0.0 as installed
  from 2019 to 2026, so this is not a breaking change for them;
  `nodewise = "cv"` gives the paper's tuning and reproduces SILM 1.0.0 with
  hdi 0.1-6 (January to March 2019). The rule only matters when `p > n/2`
  (and always for `ST()`). A `Theta` computed by `Theta.hat()` records its
  rule, and `SR()`, `Sim.CI()` and `Step()` warn when it is used with a
  different explicit `nodewise`.
* The simulation studies of Zhang and Cheng (2017) and Dezeure, Bühlmann and
  Zhang (2017) were rerun against pre-registered criteria (`replication/`):
  629 of 684 headline criteria pass, and the papers' main qualitative
  conclusions are reproduced. The comparison is statistical (the papers'
  random draws cannot be recovered), and the Zhang and Cheng targets come from
  arXiv:1603.01295v1. The replication was run with the settings of the papers
  and of hdi at the time (`nodewise = "cv"`, `robust.divisor = "n"`).

## Breaking changes

* `ST()`: the decision of the studentized test was spelled `"rejct"`; it is
  now `"reject"`. Two deviations from the paper were corrected: with exactly
  |D2| - 1 variables selected by the screening lasso, one extra variable was
  kept; and when no variable of `test.set` survived the screening, both
  statistics were `-Inf` (with 2M + 2 warnings) instead of 0. Use
  `legacy = TRUE` to reproduce SILM 1.0.0 exactly.

## Bug fixes

* `ST()` no longer fails when the screening lasso selects no variable
  (common under the null), when a single variable remains unselected, or when
  a screened variable is constant on the testing sub-sample. When the lasso
  selects more than |D2| - 1 variables, it now stops with an informative
  error that suggests a smaller `sub.size`.
* `Step()` no longer emits up to 2M warnings when every hypothesis is
  rejected; the results are unchanged.
* All functions validate their inputs, with informative errors (singular Gram
  matrix, constant columns, missing values, wrong dimensions, ...), while
  accepting every input that SILM 1.0.0 processed.
* `lasso.proj()` and `boot.lasso.proj()` reject a supplied `Z`, `sigma` or
  numeric `betainit` with infinite values, and a supplied `Z` with a zero
  normaliser t(Z_j) x_j / n. hdi returned meaningless p-values for them.

## New features

* `lasso.proj()` and `boot.lasso.proj()`: ports of the archived
  `hdi::lasso.proj()` and `hdi::boot.lasso.proj()` (same arguments and
  defaults, and the same results under the same seed except as listed here),
  with `print()` and `confint()` methods.
  * With `robust = TRUE`, the robust standard errors use the n - s divisor of
    equation (5) of Dezeure, Bühlmann and Zhang (2017) by default (see
    `robust.divisor` below), so the results differ from hdi's;
    `robust.divisor = "n"` reproduces hdi.
  * `boot.lasso.proj(parallel = TRUE)` is now reproducible, and identical to the
    sequential computation; hdi's parallel results depended on worker random
    streams.
  * `lasso.proj(family = "binomial")` removes the intercept of the linearised
    model correctly (hdi mean-centred the working data, which biased the
    estimates and gave near-zero coverage when the weights vary);
    `legacy = TRUE` reproduces hdi.
* Methods of Dezeure, Bühlmann and Zhang (2017) that hdi did not implement:
  * simultaneous confidence intervals (eq. 10) via
    `confint(fit, type = "simultaneous")`;
  * group tests via `groupTest()`;
  * Mammen multipliers for the wild bootstrap (`multiplier = "mammen"`);
  * the xyz-paired bootstrap (`boot.type = "xyz"`);
  * the n - s divisor of the robust standard error in equation (5)
    (`robust.divisor = "n-s"`), applied to the original and all bootstrap
    standard errors. It is the default, chosen by a pre-registered study
    (`validation/calibration/DEFAULTS.md`; results in
    `validation/calibration/defaults-results/REPORT.md`) under its fixed
    decision rule (calibration first, then power): over 7 designs (100
    replications each), `"n-s"` reduced the mean calibration shortfall from
    0.055 to 0.031 (95% bootstrap interval of the difference [-0.028,
    -0.018]), mainly by bringing the familywise error rate closer to 5% (for
    example Westfall-Young 0.12 to 0.05 and Holm 0.11 to 0.05 in the paper's
    Toeplitz design), at a mean power loss of 0.027. `robust.divisor = "n"` is
    hdi's
    normalisation (Section 3.3.2 of the paper) and reproduces hdi. With a
    numeric `betainit`, `"n-s"` needs fewer than n non-zero entries.
* `Theta.hat()` returns the matrix Theta used by `SR()`, `Sim.CI()` and
  `Step()`, and these functions accept a precomputed `Theta`.
* `center = TRUE` centres the data; by default the data are used as given (as
  in SILM 1.0.0), with a warning when they are clearly not centred.
* `parallel`/`ncores`: the nodewise regressions and the bootstrap refits can
  run in parallel, with identical results.
* `ST()`: `sub.size` may be a proportion of n; `test.set` may be logical.

## Performance

* The bootstrap loops of `Sim.CI()`, `Step()` and `ST()` compute
  `Theta[set, ] %*% t(X)` once instead of once per draw. With n = 100 and
  p = 500 this makes `Step()` about 40 times faster and `Sim.CI()` about 10
  times faster, with bit-identical results.

# SILM 1.0.0 (2019-01-09)

* Initial CRAN release.
