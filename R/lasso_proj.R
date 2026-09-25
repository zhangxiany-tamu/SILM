# lasso.proj(): the de-sparsified lasso with asymptotic Gaussian inference.
#
# Port of hdi 0.1-10 R/lasso-proj.R (Ruben Dezeure; GPL, see
# inst/COPYRIGHTS). Results are identical to hdi::lasso.proj() under the same
# random seed, with robust.divisor = "n" when robust = TRUE (see the section
# "Compatibility with hdi 0.1-10").

#' P-values and confidence intervals based on the de-sparsified lasso
#'
#' Computes the de-sparsified (de-biased) lasso of van de Geer et al. (2014)
#' and Zhang and Zhang (2014), individual p-values based on its asymptotic
#' Gaussian distribution, and p-values adjusted for multiple testing. This is
#' a port of `lasso.proj()` from the archived package 'hdi' (version 0.1-10)
#' and has the same arguments and defaults, plus a few additions; the results
#' differ from hdi's only where the section "Compatibility with hdi 0.1-10"
#' says so. Confidence intervals are obtained with
#' [confint()][confint.silm_proj].
#'
#' The columns of `x` are centred (and scaled if `standardize = TRUE`) and `y`
#' is centred, so the model may contain an intercept. The nodewise lasso that
#' estimates the matrix Z uses one tuning parameter for all regressions,
#' chosen by 10-fold cross-validation (or with the Z&Z rule if `do.ZnZ =
#' TRUE`). For `family = "binomial"`, the method is applied to the linearised
#' (IRLS) working model of a logistic lasso fit, as in hdi.
#'
#' @section Compatibility with hdi 0.1-10:
#' For the same data, arguments and random seed (and `robust.divisor = "n"`
#' if `robust = TRUE`), `lasso.proj()` returns the same `pval`, `pval.corr`,
#' `bhat`, `se`, `betahat` and `sigmahat` as `hdi::lasso.proj()` and leaves
#' the random number generator in the same state; this is verified against
#' the archived hdi package (with the same version of glmnet;
#' `multiplecorr.method = "WY"` also depends on the BLAS/LAPACK used by
#' `MASS::mvrnorm()`). The differences are:
#' * `robust = TRUE`: the robust standard error uses the divisor
#'   \eqn{n - \hat s}{n - s} of equation (5) of Dezeure, Bühlmann and Zhang
#'   (2017) by default (`robust.divisor = "n-s"`), so its standard errors are
#'   larger by the factor \eqn{\sqrt{n/(n-\hat s)}}{sqrt(n / (n - s))} and
#'   its p-values are at least as large as hdi's. hdi divided by n (Section
#'   3.3.2 of the paper); `robust.divisor = "n"` reproduces hdi exactly.
#'   Results with `robust = FALSE` (the default) are not affected.
#' * The result has class `c("silm_lasso_proj", "silm_proj")` instead of
#'   `"hdi"`, and the elements `groupTest` and `clusterGroupTest` (functions
#'   for group tests in hdi) are `NULL`: those tests are not provided. The
#'   draws hdi made to prepare them are still consumed from the random number
#'   stream unless `suppress.grouptesting = TRUE`, so later results in a
#'   session are unaffected.
#' * `family = "binomial"`: hdi removed the intercept of the working model by
#'   mean-centring, which leaves it in the model when the weights vary and
#'   biases the estimates and the confidence intervals. SILM projects out the
#'   intercept direction \eqn{\sqrt{w}} instead. Use `legacy = TRUE` to obtain
#'   hdi's results. For `family = "binomial"` a logical or two-level factor
#'   response is also accepted (with or without `legacy`); for `"gaussian"`, a
#'   logical response is used as 0/1, as in hdi.
#' * Arguments are checked before the computations start.
#'
#' Documented properties of hdi that are kept: a numeric `betainit` refers to
#' the centred and (if `standardize = TRUE`) scaled design; with the "cv lasso"
#' initial fit, `sigmahat` is \eqn{\|y - \hat y\|/\sqrt{n - \hat s - 1}}{||y - yhat|| /
#' sqrt(n - s - 1)}
#' (the intercept of the glmnet fit is counted); the WY adjustment uses the
#' homoscedastic covariance `crossprod(Z)` even when `robust = TRUE`, and its
#' adjusted p-values can be 0 (below the Monte Carlo resolution 1/N).
#'
#' @param x Design matrix (n x p), without intercept column.
#' @param y Response vector of length n.
#' @param family `"gaussian"` or `"binomial"`.
#' @param standardize Should the columns of `x` be scaled to unit variance
#'   (they are always centred)?
#' @param multiplecorr.method Multiple testing adjustment: `"WY"` (a
#'   Westfall-Young type procedure based on simulated Gaussian vectors) or any
#'   method of [stats::p.adjust()] (default `"holm"`).
#' @param N Number of Monte Carlo samples for `multiplecorr.method = "WY"`.
#' @param parallel,ncores Compute the nodewise regressions (and, in
#'   boot.lasso.proj(), the bootstrap refits) in parallel (forking; not on
#'   Windows). Does not change the results. With a BLAS library that uses
#'   OpenMP threads, forked workers can occasionally stall; setting
#'   `OMP_NUM_THREADS=1` before starting R avoids this.
#' @param betainit Initial estimator: `"cv lasso"` (default; lasso with
#'   lambda.1se from 10-fold cross-validation), `"scaled lasso"`, or a numeric
#'   vector of coefficients for the centred (and scaled) design, which requires
#'   `sigma`. With `robust = TRUE` and the default `robust.divisor = "n-s"`, a
#'   numeric `betainit` must have fewer than n non-zero entries (see
#'   `robust.divisor`).
#' @param sigma Optional noise standard deviation, overriding the estimate
#'   (not used with `robust = TRUE`, whose standard errors do not involve it,
#'   nor for `family = "binomial"`).
#' @param Z Optional matrix of nodewise residuals (e.g. from a previous call
#'   with `return.Z = TRUE`) to skip the nodewise lasso. This also skips the
#'   random draw of its cross-validation folds.
#' @param verbose Print progress information.
#' @param return.Z Return the nodewise residuals Z.
#' @param suppress.grouptesting In hdi this skipped the preparation of the
#'   group tests. Here it only decides whether the corresponding random draws
#'   are consumed (`FALSE`, as hdi's default) or not.
#' @param robust Use the robust (sandwich) standard errors of Dezeure,
#'   Bühlmann and Zhang (2017), valid under heteroscedastic errors.
#' @param do.ZnZ Choose the nodewise tuning parameter with the Z&Z rule.
#' @param legacy Reproduce hdi exactly for `family = "binomial"` (with
#'   `robust = TRUE`, also set `robust.divisor = "n"`; see the section
#'   "Compatibility with hdi 0.1-10").
#' @param robust.divisor Normalisation of the robust standard error, only
#'   used with `robust = TRUE`: `"n-s"` (default) is equation (5) of
#'   Dezeure, Bühlmann and Zhang (2017), which multiplies the standard error
#'   with divisor n by \eqn{\sqrt{n/(n-\hat s)}}{sqrt(n / (n - s))}, where
#'   \eqn{\hat s}{s} is the number of variables selected by the initial
#'   lasso (for a numeric `betainit`, its number of non-zero entries, which
#'   must be smaller than n; p for a dense estimate); `"n"` is hdi's
#'   normalisation (Section 3.3.2 of the paper), reproduces hdi and has no
#'   such restriction. The default was chosen by a pre-registered study
#'   that compared the two on the paper's simulation designs and a
#'   heteroscedastic stress design (Gaussian linear models with lasso
#'   initial fits), under a decision rule fixed in advance (calibration
#'   first, then power): over 7 designs (100 replications each), `"n-s"` reduced the mean
#'   calibration shortfall from 0.055 to 0.031 (95% bootstrap interval of the difference:
#'   -0.028 to -0.018), mainly by bringing the familywise error rate closer to 5% (for
#'   example Westfall-Young 0.12 to 0.05 and Holm 0.11 to 0.05 in the paper's Toeplitz
#'   design), at a mean power loss of 0.027 (see `validation/calibration/DEFAULTS.md` and
#'   `validation/calibration/defaults-results/REPORT.md` in the source repository). In
#'   `lasso.proj()` it also applies to `family = "binomial"`
#'   (the linearised model) and to a numeric `betainit`, which the study did
#'   not cover.
#' @return An object of class `c("silm_lasso_proj", "silm_proj")`: a list with
#'   elements `pval` (individual p-values), `pval.corr` (adjusted p-values),
#'   `groupTest` and `clusterGroupTest` (both `NULL`), `sigmahat`,
#'   `standardize`, `sds` (column standard deviations of `x`, or ones), `bhat`
#'   (de-sparsified lasso estimates), `se` (their standard errors), `betahat`
#'   (initial estimate), `family`, `method` (`"lasso.proj"`), `call`, `Z` (if
#'   `return.Z = TRUE`), and the SILM additions `robust`, `multiplecorr.method`,
#'   `legacy`, `robust.divisor` (the normalisation of the robust standard
#'   errors; it has no effect when `robust = FALSE`) and `tstat` (the
#'   statistics `bhat / se` on the internal scale).
#' @references van de Geer, S., Bühlmann, P., Ritov, Y. and Dezeure, R. (2014).
#'   On asymptotically optimal confidence regions and tests for
#'   high-dimensional models. \emph{Annals of Statistics}, 42, 1166-1202.
#'
#'   Zhang, C.-H. and Zhang, S. S. (2014). Confidence intervals for low
#'   dimensional parameters in high dimensional linear models. \emph{Journal
#'   of the Royal Statistical Society, Series B}, 76, 217-242.
#'
#'   Dezeure, R., Bühlmann, P., Meier, L. and Meinshausen, N. (2015).
#'   High-dimensional inference: confidence intervals, p-values and
#'   R-software hdi. \emph{Statistical Science}, 30, 533-558.
#'
#'   Dezeure, R., Bühlmann, P. and Zhang, C.-H. (2017). High-dimensional
#'   simultaneous inference with the bootstrap. \emph{TEST}, 26, 685-719.
#' @seealso [boot.lasso.proj()], [confint.silm_proj()]
#' @examples
#' set.seed(1)
#' x <- matrix(rnorm(50 * 20), 50, 20)
#' y <- x[, 1] - x[, 2] + rnorm(50)
#' fit <- lasso.proj(x, y)
#' fit
#' confint(fit, parm = 1:3)
#' @export
lasso.proj <- function(x, y, family = "gaussian", standardize = TRUE,
                       multiplecorr.method = "holm", N = 10000, parallel = FALSE,
                       ncores = getOption("mc.cores", 2L), betainit = "cv lasso",
                       sigma = NULL, Z = NULL, verbose = FALSE, return.Z = FALSE,
                       suppress.grouptesting = FALSE, robust = FALSE, do.ZnZ = FALSE,
                       legacy = FALSE, robust.divisor = c("n-s", "n")) {
  # (missing() is unreliable once an argument has been modified.)
  divisor_given <- !missing(robust.divisor)
  robust.divisor <- .check_divisor(robust.divisor, robust, given = divisor_given)
  args <- .check_proj_args(x, y, family, standardize, multiplecorr.method, betainit, sigma, Z)
  x <- args$x
  y <- args$y
  .check_integer(N, "N", "number of Monte Carlo samples")
  flags <- .check_proj_flags(parallel = parallel, verbose = verbose, return.Z = return.Z,
                             suppress.grouptesting = suppress.grouptesting, robust = robust,
                             do.ZnZ = do.ZnZ, legacy = legacy)
  for (nm in names(flags)) assign(nm, flags[[nm]])
  .check_divisor_betainit(betainit, nrow(x), robust, robust.divisor, divisor_given)
  if (family == "binomial" && !is.null(sigma)) {
    warning("'sigma' is ignored for family = \"binomial\": the linearised model has unit ",
            "variance.", call. = FALSE)
  }

  n <- nrow(x)
  p <- ncol(x)
  sds <- if (standardize) apply(x, 2, sd) else rep(1, p)
  pdata <- prepare.data(x = x, y = y, standardize = standardize, family = family,
                        legacy = legacy)
  x <- pdata$x
  y <- pdata$y
  # The linearised logistic model has unit noise level.
  binomial <- family == "binomial"
  if (binomial) sigma <- 1

  Zout <- calculate.Z(x = x, parallel = parallel, ncores = ncores, verbose = verbose, Z = Z,
                      do.ZnZ = do.ZnZ)
  Z <- Zout$Z
  scaleZ <- Zout$scaleZ

  initial.estimate <- initial.estimator(betainit = betainit, sigma = sigma, x = x, y = y,
                                        warn_sigma = !binomial)
  betalasso <- initial.estimate$beta.lasso
  sigmahat <- initial.estimate$sigmahat

  bproj <- despars.lasso.est(x = x, y = y, Z = Z, betalasso = betalasso)
  se <- est.stderr.despars.lasso(x = x, y = y, Z = Z, betalasso = betalasso,
                                 sigmahat = sigmahat, robust = robust, divisor = robust.divisor)
  scaleb <- 1 / se
  bprojrescaled <- bproj * scaleb
  pval <- 2 * pnorm(abs(bprojrescaled), lower.tail = FALSE)

  pcorr <- if (multiplecorr.method == "WY") {
    # Westfall-Young like procedure as in the ridge projection method
    # (Buehlmann, 2013); constants are left out since the p-values are rescaled.
    p.adjust.wy(cov = crossprod(Z), pval = pval, N = N)
  } else {
    p.adjust(pval, method = multiplecorr.method)
  }
  # hdi then simulated N Gaussian vectors to prepare its group tests; consume
  # the same draws so that the random number stream is unchanged.
  if (!suppress.grouptesting) .burn_rnorm(as.numeric(N) * p)

  out <- list(pval = as.vector(pval), pval.corr = pcorr, groupTest = NULL,
              clusterGroupTest = NULL, sigmahat = sigmahat, standardize = standardize,
              sds = sds, bhat = bproj / sds, se = se / sds, betahat = betalasso / sds,
              family = family, method = "lasso.proj", call = match.call())
  if (return.Z) out <- c(out, list(Z = scale(Z, center = FALSE, scale = 1 / scaleZ)))
  names(out$pval) <- names(out$pval.corr) <- names(out$bhat) <- names(out$sds) <-
    names(out$se) <- names(out$betahat) <- colnames(x)
  out$robust <- robust
  out$multiplecorr.method <- multiplecorr.method
  out$legacy <- legacy
  out$robust.divisor <- robust.divisor
  out$tstat <- stats::setNames(bproj / se, colnames(x))
  class(out) <- c("silm_lasso_proj", "silm_proj")
  out
}
