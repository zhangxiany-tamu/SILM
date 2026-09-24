# lasso.proj(): the de-sparsified lasso with asymptotic Gaussian inference.
#
# Port of hdi 0.1-10 R/lasso-proj.R (Ruben Dezeure; GPL, see
# inst/COPYRIGHTS). Results are identical to hdi::lasso.proj() under the same
# random seed (see the section "Compatibility with hdi 0.1-10").

#' P-values and confidence intervals based on the de-sparsified lasso
#'
#' Computes the de-sparsified (de-biased) lasso of van de Geer et al. (2014)
#' and Zhang and Zhang (2014), individual p-values based on its asymptotic
#' Gaussian distribution, and p-values adjusted for multiple testing. This is
#' a port of `lasso.proj()` from the archived package 'hdi' (version 0.1-10)
#' and has the same arguments and defaults. Confidence intervals are obtained
#' with [confint()][confint.silm_proj].
#'
#' The columns of `x` are centred (and scaled if `standardize = TRUE`) and `y`
#' is centred, so the model may contain an intercept. The nodewise lasso that
#' estimates the matrix Z uses one tuning parameter for all regressions,
#' chosen by 10-fold cross-validation (or with the Z&Z rule if `do.ZnZ =
#' TRUE`). For `family = "binomial"`, the method is applied to the linearised
#' (IRLS) working model of a logistic lasso fit, as in hdi.
#'
#' @section Compatibility with hdi 0.1-10:
#' For the same data, arguments and random seed, `lasso.proj()` returns the
#' same `pval`, `pval.corr`, `bhat`, `se`, `betahat` and `sigmahat` as
#' `hdi::lasso.proj()` and leaves the random number generator in the same
#' state; this is verified against the archived hdi package (with the same
#' version of glmnet; `multiplecorr.method = "WY"` also depends on the
#' BLAS/LAPACK used by `MASS::mvrnorm()`). The differences are:
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
#'   hdi's results. For both families a logical or two-level factor response
#'   is accepted.
#' * Arguments are checked before the computations start.
#'
#' Documented properties of hdi that are kept: a numeric `betainit` refers to
#' the centred and (if `standardize = TRUE`) scaled design; with the "cv lasso"
#' initial fit, `sigmahat` is \eqn{\|y - \hat y\|/\sqrt{n - \hat s - 1}}{||y - yhat|| / sqrt(n - s - 1)}
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
#' @param parallel,ncores Compute the nodewise regressions in parallel
#'   (forking; not on Windows). Does not change the results.
#' @param betainit Initial estimator: `"cv lasso"` (default; lasso with
#'   lambda.1se from 10-fold cross-validation), `"scaled lasso"`, or a numeric
#'   vector of coefficients for the centred (and scaled) design, which requires
#'   `sigma`.
#' @param sigma Optional noise standard deviation, overriding the estimate.
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
#' @param legacy Reproduce hdi exactly for `family = "binomial"` (see the
#'   section "Compatibility with hdi 0.1-10").
#' @return An object of class `c("silm_lasso_proj", "silm_proj")`: a list with
#'   elements `pval` (individual p-values), `pval.corr` (adjusted p-values),
#'   `groupTest` and `clusterGroupTest` (both `NULL`), `sigmahat`,
#'   `standardize`, `sds` (column standard deviations of `x`, or ones), `bhat`
#'   (de-sparsified lasso estimates), `se` (their standard errors), `betahat`
#'   (initial estimate), `family`, `method` (`"lasso.proj"`), `call`, `Z` (if
#'   `return.Z = TRUE`), and the SILM additions `robust`, `multiplecorr.method`,
#'   `legacy` and `tstat` (the statistics `bhat / se` on the internal scale).
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
                       legacy = FALSE) {
  args <- .check_proj_args(x, y, family, standardize, multiplecorr.method, betainit, sigma, Z,
                           robust, legacy, parallel)
  x <- args$x
  y <- args$y
  .check_count(N, "N")
  if (!is.character(betainit)) sigma <- args$sigma

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
                                 sigmahat = sigmahat, robust = robust)
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
  out$tstat <- stats::setNames(bproj / se, colnames(x))
  class(out) <- c("silm_lasso_proj", "silm_proj")
  out
}
