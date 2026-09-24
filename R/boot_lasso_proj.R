# boot.lasso.proj(): the bootstrapped de-sparsified lasso of Dezeure,
# Buehlmann and Zhang (2017).
#
# Port of hdi 0.1-10 R/boot.lasso-proj.R (Ruben Dezeure; GPL, see
# inst/COPYRIGHTS). Results are identical to hdi::boot.lasso.proj() under the
# same random seed (see the section "Compatibility with hdi 0.1-10").

#' Bootstrapped de-sparsified lasso: p-values and confidence intervals
#'
#' Bootstraps the entire de-sparsified lasso (initial lasso fit included) to
#' obtain individual p-values, p-values adjusted for multiple testing with the
#' Westfall-Young max-T procedure, and bootstrap confidence intervals
#' (Dezeure, Bühlmann and Zhang, 2017). This is a port of
#' `boot.lasso.proj()` from the archived package 'hdi' (version 0.1-10) with
#' the same arguments and defaults.
#'
#' The residual bootstrap (default) resamples the centred lasso residuals; the
#' wild bootstrap (`wild = TRUE`) multiplies them by independent standard
#' normal variables and is also valid for heteroscedastic errors. For every
#' bootstrap response the initial lasso is refitted (with the same tuning
#' method, or with the original lambda if `boot.shortcut = TRUE`) and the
#' de-sparsified lasso and its standard error are recomputed; the nodewise
#' residuals Z are computed once. Westfall-Young adjusted p-values use a
#' second bootstrap under the complete null hypothesis (all coefficients
#' zero), with the same resampled errors.
#'
#' The paper recommends the robust standard error (`robust = TRUE`) in
#' practice, and the wild bootstrap under heteroscedastic errors.
#'
#' @section Compatibility with hdi 0.1-10:
#' For the same data, arguments and random seed, `boot.lasso.proj()` returns
#' the same `pval`, `pval.corr`, `bhat`, `se`, `betahat`, `sigmahat`, `lambda`
#' and bootstrap distributions as `hdi::boot.lasso.proj()` run sequentially,
#' and leaves the random number generator in the same state; this is verified
#' against the archived hdi package (with the same version of glmnet). The
#' differences are:
#' * The result has class `c("silm_boot_lasso_proj", "silm_proj")` instead of
#'   `"hdi"`, and additional elements (see Value).
#' * With `parallel = TRUE`, hdi drew the cross-validation folds of the
#'   bootstrap refits in the worker processes, so its results were not
#'   reproducible. SILM draws them in the main process in the same order as a
#'   sequential run: parallel results are identical to sequential ones and to
#'   hdi's sequential results.
#' * Arguments are checked before the computations start; parallel execution
#'   falls back to sequential on Windows.
#'
#' Documented properties of hdi that are kept: a user-supplied `sigma` only
#' affects the standard errors of the original fit, not those of the
#' bootstrap fits (a warning is given); `boot.shortcut` has no effect with
#' `betainit = "scaled lasso"` (a warning is given) and uses glmnet's linear
#' interpolation along its lambda path; the robust standard error uses the
#' divisor n (Dezeure, Bühlmann and Zhang, 2017, Section 3.3.2); the
#' individual p-values are (2 c + 1) / (B + 1), where c is the smaller of the
#' two tail counts of the bootstrap distribution.
#'
#' @inheritParams lasso.proj
#' @param family Only `"gaussian"` is supported.
#' @param multiplecorr.method `"WY"` (default; Westfall-Young max-T procedure
#'   based on the bootstrap under the complete null hypothesis) or any method
#'   of [stats::p.adjust()].
#' @param betainit `"cv lasso"` (default) or `"scaled lasso"`.
#' @param B Number of bootstrap samples.
#' @param boot.shortcut Refit the bootstrap lasso at the lambda of the
#'   original fit instead of re-tuning it (faster).
#' @param return.bootdist Return the bootstrap distributions (needed for
#'   [confint()][confint.silm_proj]).
#' @param wild Use the wild bootstrap with Gaussian multipliers.
#' @param gaussian.stub Developer option of hdi: replace the bootstrap
#'   distribution by independent standard normal draws.
#' @return An object of class `c("silm_boot_lasso_proj", "silm_proj")`: a list
#'   with the elements of hdi's result, in the same order, `pval`,
#'   `pval.corr`, `sigmahat`, `standardize`, `sds`, `bhat`, `se`, `betahat`,
#'   `family`, `method` (`"boot.lasso.proj"`), `B`, `boot.shortcut`, `lambda`,
#'   `call`, `Z` (if `return.Z = TRUE`), `cboot.dist` and
#'   `cboot.dist.underH0c` (if `return.bootdist = TRUE`: the bootstrap
#'   distributions of the estimator on the scale of `bhat`, centred and under
#'   the complete null hypothesis), followed by the SILM additions
#'   `boot.type`, `multiplier`, `robust`, `gaussian.stub`, `B.eff` (number of
#'   usable bootstrap samples), `tstat` (the studentized statistics),
#'   `boot.summary` (per bootstrap sample, the maximum, minimum and maximal
#'   absolute value of the studentized bootstrap statistics, and the maximal
#'   absolute value under the complete null hypothesis), `group.summary` and
#'   `boot.index`.
#' @references Dezeure, R., Bühlmann, P. and Zhang, C.-H. (2017).
#'   High-dimensional simultaneous inference with the bootstrap. \emph{TEST},
#'   26, 685-719.
#'
#'   Dezeure, R., Bühlmann, P., Meier, L. and Meinshausen, N. (2015).
#'   High-dimensional inference: confidence intervals, p-values and
#'   R-software hdi. \emph{Statistical Science}, 30, 533-558.
#' @seealso [lasso.proj()], [confint.silm_proj()], [Sim.CI()]
#' @examples
#' set.seed(1)
#' x <- matrix(rnorm(50 * 15), 50, 15)
#' y <- x[, 1] + rnorm(50)
#' fit <- boot.lasso.proj(x, y, B = 50, boot.shortcut = TRUE, return.bootdist = TRUE)
#' fit
#' confint(fit, parm = 1:3)
#' @export
boot.lasso.proj <- function(x, y, family = "gaussian", standardize = TRUE,
                            multiplecorr.method = "WY", parallel = FALSE,
                            ncores = getOption("mc.cores", 2L), betainit = "cv lasso",
                            sigma = NULL, Z = NULL, verbose = FALSE, return.Z = FALSE,
                            robust = FALSE, B = 1000, boot.shortcut = FALSE,
                            return.bootdist = FALSE, wild = FALSE, gaussian.stub = FALSE) {
  args <- .check_proj_args(x, y, family, standardize, multiplecorr.method, betainit, sigma, Z,
                           robust, legacy = FALSE, parallel = parallel, boot = TRUE)
  x <- args$x
  y <- args$y
  B <- .check_boot_B(B)
  for (flag in c("boot.shortcut", "return.bootdist", "wild", "gaussian.stub", "return.Z")) {
    .check_flag(get(flag), flag)
  }
  if (!is.null(sigma)) {
    warning("A user-supplied 'sigma' is used for the standard errors of the original fit ",
            "only; the bootstrap fits estimate the noise level (as in hdi).", call. = FALSE)
  }
  if (boot.shortcut && identical(betainit, "scaled lasso")) {
    warning("'boot.shortcut' has no effect with betainit = \"scaled lasso\".", call. = FALSE)
  }
  if (!parallel) ncores <- 1

  # Data, nodewise residuals and the original de-sparsified lasso.
  p <- ncol(x)
  sds <- if (standardize) apply(x, 2, sd) else rep(1, p)
  pdata <- prepare.data(x = x, y = y, standardize = standardize, family = family)
  x <- pdata$x
  y <- pdata$y
  Zout <- calculate.Z(x = x, parallel = parallel, ncores = ncores, verbose = verbose, Z = Z)
  Z <- Zout$Z
  scaleZ <- Zout$scaleZ

  initial.estimate <- initial.estimator(betainit = betainit, sigma = sigma, x = x, y = y)
  betalasso <- initial.estimate$beta.lasso
  sigmahat <- initial.estimate$sigmahat
  r <- y - x %*% betalasso
  rc <- as.vector(r) - mean(r)
  bproj <- despars.lasso.est(x = x, y = y, Z = Z, betalasso = betalasso)
  se <- est.stderr.despars.lasso(x = x, y = y, Z = Z, betalasso = betalasso,
                                 sigmahat = sigmahat, robust = robust)
  lambda <- NULL
  if (boot.shortcut) lambda <- initial.estimate$lambda

  compute <- function(ystar, boot.truth) {
    .boot_cbootdist(ystar = ystar, boot.truth = boot.truth, x = x, Z = Z, betainit = betainit,
                    lambda = lambda, robust = robust, parallel = parallel, ncores = ncores)
  }

  # Centred bootstrap distribution and individual p-values.
  if (gaussian.stub) {
    cboot.dist <- replicate(B, rnorm(ncol(x)))
  } else {
    rstar <- resample(r = rc, B = B, wild = wild)
    ystar <- as.vector(x %*% betalasso) + rstar
    cboot.dist <- compute(ystar, boot.truth = betalasso)
  }
  pval <- .boot_pvalues(bproj, se, cboot.dist, B)

  # Multiple testing adjustment.
  cboot.dist.underH0c <- NULL
  if (multiplecorr.method == "WY") {
    # Bootstrap under the complete null hypothesis, reusing the resampled errors.
    cboot.dist.underH0c <- if (gaussian.stub) replicate(B, rnorm(ncol(x))) else compute(0 + rstar, 0)
    pcorr <- .boot_wy(bproj, se, cboot.dist.underH0c, B)
  } else {
    pcorr <- .boot_padjust(pval, multiplecorr.method, B, ncol(x))
  }

  out <- list(pval = as.vector(pval), pval.corr = pcorr, sigmahat = sigmahat,
              standardize = standardize, sds = sds, bhat = bproj / sds, se = se / sds,
              betahat = betalasso / sds, family = family, method = "boot.lasso.proj",
              B = B, boot.shortcut = boot.shortcut, lambda = lambda, call = match.call())
  if (return.Z) out <- c(out, list(Z = scale(Z, center = FALSE, scale = 1 / scaleZ)))
  names(out$pval) <- names(out$pval.corr) <- names(out$bhat) <- names(out$sds) <-
    names(out$se) <- names(out$betahat) <- colnames(x)
  if (return.bootdist) {
    out <- c(out, list(cboot.dist = se / sds * cboot.dist))
    rownames(out$cboot.dist) <- names(out$bhat)
    if (!is.null(cboot.dist.underH0c)) {
      out <- c(out, list(cboot.dist.underH0c = se / sds * cboot.dist.underH0c))
      rownames(out$cboot.dist.underH0c) <- names(out$bhat)
    }
  }
  out <- c(out, list(
    boot.type = if (wild) "wild" else "residual",
    multiplier = if (wild) "gaussian" else NULL,
    robust = robust, gaussian.stub = gaussian.stub, B.eff = B,
    tstat = stats::setNames(bproj / se, colnames(x)),
    boot.summary = .boot_summary(cboot.dist, cboot.dist.underH0c)
  ))
  class(out) <- c("silm_boot_lasso_proj", "silm_proj")
  out
}

.check_boot_B <- function(B) {
  if (!is.numeric(B) || length(B) != 1L || !is.finite(B) || B < 2 || B != floor(B)) {
    .stop("'B' must be an integer >= 2.")
  }
  B
}

# Per bootstrap sample: max, min and max |.| of the studentized bootstrap
# statistics, and max |.| under the complete null hypothesis (identical to
# hdi's max.t.dist). Enough for simultaneous inference over all coefficients.
.boot_summary <- function(cboot.dist, cboot.dist.underH0c) {
  list(max = unname(apply(cboot.dist, 2, max)),
       min = unname(apply(cboot.dist, 2, min)),
       absmax = unname(apply(abs(cboot.dist), 2, max)),
       absmax.H0c = if (!is.null(cboot.dist.underH0c)) {
         unname(apply(abs(cboot.dist.underH0c), 2, max))
       })
}
