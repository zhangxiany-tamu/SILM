# SILM 2.0.0

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

## Breaking changes

* New argument `nodewise = c("cv", "ZnZ")` for `SR()`, `ST()`, `Sim.CI()` and
  `Step()`. SILM 1.0.0 took the nodewise lasso from an internal function of
  'hdi' and did not set its tuning rule. With hdi 0.1-6, current when SILM
  1.0.0 was published (January 2019), that was the cross-validated lambda
  described in Zhang and Cheng (2017, Section 5). hdi 0.1-7 (March 2019)
  changed the default to the Z&Z rule, so from then until SILM was archived,
  SILM silently used Z&Z. The default is now `"cv"`, following the paper and
  SILM 1.0.0 as released; `nodewise = "ZnZ"` reproduces results obtained with
  hdi 0.1-7 to 0.1-10. This only matters when `p > n/2` (and always for `ST()`).
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

## New features

* `lasso.proj()` and `boot.lasso.proj()`: ports of the archived
  `hdi::lasso.proj()` and `hdi::boot.lasso.proj()` (same arguments, defaults
  and results under the same seed), with `print()` and `confint()` methods.
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
  * the xyz-paired bootstrap (`boot.type = "xyz"`).
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
