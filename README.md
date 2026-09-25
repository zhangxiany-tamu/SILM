# SILM: Simultaneous Inference for High-Dimensional Linear Models

<!-- badges: start -->
[![R-CMD-check](https://github.com/zhangxiany-tamu/SILM/actions/workflows/R-CMD-check.yml/badge.svg)](https://github.com/zhangxiany-tamu/SILM/actions/workflows/R-CMD-check.yml)
[![equivalence](https://github.com/zhangxiany-tamu/SILM/actions/workflows/equivalence.yml/badge.svg)](https://github.com/zhangxiany-tamu/SILM/actions/workflows/equivalence.yml)
[![R-universe](https://zhangxiany-tamu.r-universe.dev/badges/SILM)](https://zhangxiany-tamu.r-universe.dev/SILM)
<!-- badges: end -->

SILM provides simultaneous inference for high-dimensional linear models
$Y = X\beta + \epsilon$ (p possibly much larger than n), based on the de-biased
(de-sparsified) lasso and the bootstrap. It implements

* **Zhang and Cheng (2017)**, *Simultaneous inference for high-dimensional
  linear models*, JASA 112, 757–768: simultaneous confidence intervals
  (`Sim.CI()`), support recovery (`SR()`), testing for sparse signals (`ST()`)
  and stepdown multiple testing (`Step()`);
* **Dezeure, Bühlmann and Zhang (2017)**, *High-dimensional simultaneous
  inference with the bootstrap*, TEST 26, 685–719: the bootstrapped
  de-sparsified lasso (`boot.lasso.proj()`) with residual, wild and
  xyz-paired bootstrap, robust standard errors, Westfall–Young multiple
  testing, simultaneous confidence intervals and group tests;
* the de-sparsified lasso with asymptotic inference (`lasso.proj()`).

## Why a new version?

SILM 1.0.0 was on CRAN from 2019 until July 2026, when it was archived because
its dependency 'scalreg' was archived. The package 'hdi', which provided the
nodewise lasso used by SILM and the only implementation of Dezeure, Bühlmann
and Zhang (2017), was archived on the same day. SILM 2.0.0 is self-contained
(it depends only on 'glmnet', 'lars' and 'MASS') and takes over
`lasso.proj()` and `boot.lasso.proj()` from hdi, with the same arguments and
(up to the differences listed under "Coming from hdi") the same results.

## Installation

```r
# From R-universe (binaries, no compiler needed):
install.packages("SILM", repos = c("https://zhangxiany-tamu.r-universe.dev",
                                   "https://cloud.r-project.org"))

# Or from GitHub:
# install.packages("pak")
pak::pak("zhangxiany-tamu/SILM")
# or: remotes::install_github("zhangxiany-tamu/SILM")
```

## Example

```r
library(SILM)
set.seed(1)
n <- 100; p <- 200
X <- matrix(rnorm(n * p), n, p) %*% chol(0.9^abs(outer(1:p, 1:p, "-")))
Y <- as.vector(X[, 1:3] %*% c(1.5, -1, 2) + rt(n, 4) / sqrt(2))

# Zhang and Cheng (2017)
Theta <- Theta.hat(X, parallel = TRUE)       # nodewise lasso; reusable
Sim.CI(X, Y, set = 1:10, alpha = 0.95, Theta = Theta)   # simultaneous CIs
Step(X, Y, alpha = 0.05, Theta = Theta)                  # FWER control
SR(X, Y, Theta = Theta)                                  # support recovery
ST(X, Y, sub.size = 0.3, test.set = 4:p)                 # H0: beta_j = 0, j in 4:p

# Dezeure, Buehlmann and Zhang (2017)
fit <- boot.lasso.proj(X, Y, B = 1000, robust = TRUE, wild = TRUE,
                       return.bootdist = TRUE, parallel = TRUE)
fit                                                      # WY-adjusted p-values
confint(fit, parm = 1:5)                                 # individual CIs
confint(fit, type = "simultaneous")                      # all p jointly
groupTest(fit, list(signal = 1:3, noise = 4:p))          # group tests
```

See `vignette("SILM")` for a guided tour.

## Coming from hdi

`lasso.proj()` and `boot.lasso.proj()` accept the same arguments as in hdi
0.1-10 and, for the Gaussian family with the default `robust = FALSE`, return
the same numbers under the same random seed, so replacing `hdi::` by `SILM::`
is enough. With `robust = TRUE`, the robust standard errors use the n - s
divisor of equation (5) of Dezeure, Bühlmann and Zhang (2017) by default,
chosen by a pre-registered study under its fixed decision rule (calibration
first, then power): over 7 designs (100 replications each), `"n-s"` reduced
the mean calibration shortfall from 0.055 to 0.031 (95% bootstrap interval of
the difference [-0.028, -0.018]), mainly by bringing the familywise error rate
closer to 5% (for example Westfall-Young 0.12 to 0.05 and Holm 0.11 to 0.05 in
the paper's Toeplitz design), at a mean power loss of 0.027
(`validation/calibration/defaults-results/REPORT.md`); add
`robust.divisor = "n"` to get hdi's numbers. The differences:

| | hdi 0.1-10 | SILM 2.0.0 |
|---|---|---|
| result class | `"hdi"` | `"silm_lasso_proj"` / `"silm_boot_lasso_proj"` (with `print`, `confint`) |
| robust standard error (`robust = TRUE`) | divisor n (Section 3.3.2) | divisor n - s, equation (5) (`robust.divisor = "n-s"`, default); `robust.divisor = "n"` gives hdi's result |
| `lasso.proj()` group tests (`groupTest`, `clusterGroupTest` closures) | yes | not provided (`NULL`); use `boot.lasso.proj()` + `groupTest()` |
| `boot.lasso.proj(parallel = TRUE)` | not reproducible | reproducible, identical to the sequential result |
| `lasso.proj(family = "binomial")` | biased intercept removal | corrected; `legacy = TRUE` gives hdi's result (with `robust = TRUE`, also set `robust.divisor = "n"`) |
| simultaneous CIs, group tests, Mammen multipliers, xyz-paired bootstrap | no | yes (see `?boot.lasso.proj`) |

## Reproducibility and correctness

* **Archived versions.** Every result of SILM 1.0.0 and of hdi 0.1-10's
  `lasso.proj()`/`boot.lasso.proj()` can be reproduced exactly (same numbers
  and random-number state under the same seed). The source repository runs
  the archived CRAN packages and the current code side by side and compares
  them with `identical()` (`validation/`; the *equivalence* workflow above).
* **SILM 1.0.0 and hdi versions.** SILM 1.0.0 computed different results
  depending on the installed version of hdi: with hdi 0.1-6 (January to March
  2019) its nodewise lasso used the cross-validated tuning parameter described
  in the paper; hdi 0.1-7 (March 2019) silently switched it to the Z&Z rule.
  SILM 2.0.0 makes the rule explicit. Its default, `nodewise = "ZnZ"`, gives
  the results of 2019 to 2026 (for `ST()` with `legacy = TRUE`) and was
  chosen by a pre-registered study under its fixed decision rule (calibration
  first, then power): over 20 `Sim.CI()`/`Step()` settings, 8 `SR()` settings
  and 3 `ST()` settings (200 replications each), `"ZnZ"` halved the mean
  calibration shortfall (coverage below 95%, error rates above 5%) from 0.100
  to 0.053 (95% bootstrap interval of the difference [-0.051, -0.044]). The
  joint coverage of `Sim.CI()` for all p coefficients was higher or equal in
  all 20 settings (for example 0.77 with `"cv"` and 0.90 with `"ZnZ"` for
  signals (1.5, -1, 2) at p = 500), and exact support recovery by `SR()`
  improved; the price is about 12% wider intervals and 0.02-0.07 less power of
  `Step()` and `ST()` (`validation/calibration/DEFAULTS.md` and
  `validation/calibration/defaults-results/REPORT.md`); `nodewise = "cv"`
  gives the paper's tuning and the results of SILM 1.0.0 with hdi 0.1-6.
* **Papers.** `replication/` reruns the simulation studies of both papers
  (with the settings of the papers and of hdi at the time: `nodewise = "cv"`
  and `robust.divisor = "n"`) and compares them with criteria committed
  before the run (`replication/CRITERIA.md`). Under these criteria, 629 of
  684 headline criteria pass (`replication/REPORT.md`), and the papers' main
  qualitative conclusions are reproduced. The comparison is statistical, not
  exact: the papers' random designs and coefficient draws cannot be
  recovered, and the Zhang and Cheng targets are taken from the arXiv version
  (arXiv:1603.01295v1). `replication/INTERPRETATION.md` discusses the
  failures; its explanations were written after seeing the results and are
  hypotheses.
* **Finite samples.** All methods are asymptotic, and their finite-sample
  coverage and error control depend on the design, the signal and n. See the
  sections "Finite-sample behaviour" of `?Sim.CI`, `?Step` and
  `?boot.lasso.proj`, and the calibration studies in `validation/calibration/`
  (including the defaults study, `DEFAULTS.md` and
  `defaults-results/REPORT.md`).

## Citation

```r
citation("SILM")
```

Zhang, X. and Cheng, G. (2017). Simultaneous inference for high-dimensional
linear models. *Journal of the American Statistical Association*, 112(518),
757–768. doi:10.1080/01621459.2016.1166114

Dezeure, R., Bühlmann, P. and Zhang, C.-H. (2017). High-dimensional
simultaneous inference with the bootstrap. *TEST*, 26(4), 685–719.
doi:10.1007/s11749-017-0554-2

## Acknowledgements

The nodewise lasso, `lasso.proj()` and `boot.lasso.proj()` are adapted from
the 'hdi' package by Lukas Meier, Ruben Dezeure, Nicolai Meinshausen, Martin
Mächler and Peter Bühlmann (GPL). The scaled lasso follows Sun and Zhang
(2012, 2013) and reproduces the archived 'scalreg' package by Tingni Sun.

## License

GPL-3. See `inst/COPYRIGHTS` for the code derived from other packages.
