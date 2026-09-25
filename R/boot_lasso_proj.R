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
#' @section SILM additions (not in hdi):
#' * `boot.type = "wild"` with `multiplier = "mammen"`: the wild bootstrap
#'   with Mammen's two-point multipliers (Section 4.1), which also match the
#'   third moment of the errors. The paper found no advantage over Gaussian
#'   multipliers; in our replication of its small heteroscedastic example
#'   (n = 50) they under-covered (average 0.86 vs 0.94), so the Gaussian
#'   default is recommended.
#' * `boot.type = "xyz"`: the xyz-paired bootstrap (Section 4.2), which
#'   resamples rows of the design, the response and the nodewise residuals
#'   after a correction that makes the bootstrap errors orthogonal to them.
#'   It is defined with `robust = TRUE`; the paper reports that it is less
#'   competitive than the Gaussian wild bootstrap. When the lasso is re-tuned
#'   by cross-validation, the folds are formed by original observation, since
#'   resampled rows are duplicated. Bootstrap samples with a degenerate
#'   normaliser \eqn{Z^{*\top}_j X^*_j/n}{Z*_j'X*_j/n} are discarded (`B.eff`).
#' * Simultaneous confidence intervals (eq. 10) via
#'   `confint(fit, type = "simultaneous")` and group tests via [groupTest()].
#'
#' Validity (the paper's Theorems 1-3): the residual bootstrap is valid for
#' individual inference, and for simultaneous inference under homoscedastic
#' errors; the wild bootstrap with `robust = TRUE` is valid for individual and
#' simultaneous inference under heteroscedastic errors and is the paper's
#' preferred method in that case.
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
#' @param boot.type `"residual"`, `"wild"` or `"xyz"` (xyz-paired bootstrap).
#'   Defaults to `"wild"` if `wild = TRUE`, else `"residual"`.
#' @param multiplier Multipliers of the wild bootstrap: `"gaussian"` (default,
#'   as in hdi) or `"mammen"`.
#' @param boot.H0c Also compute the bootstrap under the complete null
#'   hypothesis (always done, and required, for `multiplecorr.method = "WY"`);
#'   needed for [groupTest()].
#' @param groups Optional group (vector of indices or names) or list of groups
#'   for which bootstrap summaries are stored, so that simultaneous intervals
#'   and group tests for them are available without `return.bootdist = TRUE`.
#' @return An object of class `c("silm_boot_lasso_proj", "silm_proj")`: a list
#'   with the elements of hdi's result, in the same order, `pval`,
#'   `pval.corr`, `sigmahat`, `standardize`, `sds`, `bhat`, `se`, `betahat`,
#'   `family`, `method` (`"boot.lasso.proj"`), `B`, `boot.shortcut`, `lambda`,
#'   `call`, `Z` (if `return.Z = TRUE`), `cboot.dist` and
#'   `cboot.dist.underH0c` (if `return.bootdist = TRUE`: p x B matrices of
#'   \eqn{\hat{s.e.}_j T^*_j}{se_j T*_j}, where
#'   \eqn{T^*_j = (\hat b^*_j - \hat\beta_j)/\hat{s.e.}^*_j}{T*_j = (b*_j - betahat_j)/se*_j}
#'   is the studentized centred bootstrap statistic, and the same under the
#'   complete null hypothesis, on the scale of `bhat`, as in hdi), followed by
#'   the SILM additions `boot.type`, `multiplier`, `robust`, `gaussian.stub`,
#'   `B.eff` (number of bootstrap samples used; smaller than `B` only when
#'   xyz-paired samples had to be discarded), `tstat` (the studentized
#'   statistics \eqn{\hat b_j/\hat{s.e.}_j}{b_j / se_j}), `boot.summary` (per
#'   bootstrap sample, the maximum, minimum and maximal absolute value of the
#'   \eqn{T^*_j}{T*_j}, and the maximal absolute value under the complete null
#'   hypothesis), `group.summary` (the same per group in `groups`) and
#'   `boot.index` (xyz-paired bootstrap with `return.bootdist = TRUE`: the
#'   resampled rows, one column per column of `cboot.dist`).
#' @references Dezeure, R., Bühlmann, P. and Zhang, C.-H. (2017).
#'   High-dimensional simultaneous inference with the bootstrap. \emph{TEST},
#'   26, 685-719.
#'
#'   Dezeure, R., Bühlmann, P., Meier, L. and Meinshausen, N. (2015).
#'   High-dimensional inference: confidence intervals, p-values and
#'   R-software hdi. \emph{Statistical Science}, 30, 533-558.
#' @seealso [lasso.proj()], [confint.silm_proj()], [groupTest()], [Sim.CI()]
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
                            return.bootdist = FALSE, wild = FALSE, gaussian.stub = FALSE,
                            boot.type = if (wild) "wild" else "residual",
                            multiplier = c("gaussian", "mammen"),
                            boot.H0c = identical(multiplecorr.method, "WY"), groups = NULL) {
  # (missing() is unreliable once an argument has been modified.)
  given <- c(wild = !missing(wild), boot.type = !missing(boot.type),
             multiplier = !missing(multiplier))
  flags <- .check_proj_flags(parallel = parallel, verbose = verbose, return.Z = return.Z,
                             robust = robust, boot.shortcut = boot.shortcut,
                             return.bootdist = return.bootdist, wild = wild,
                             gaussian.stub = gaussian.stub)
  for (nm in names(flags)) assign(nm, flags[[nm]])
  args <- .check_proj_args(x, y, family, standardize, multiplecorr.method, betainit, sigma, Z,
                           boot = TRUE, stub = gaussian.stub)
  x <- args$x
  y <- args$y
  B <- .check_integer(B, "B", "number of bootstrap samples", min = 2)
  extras <- .boot_check_extras(boot.type, wild, !given[["wild"]], !given[["boot.type"]], multiplier,
                               !given[["multiplier"]], .check_flag01(boot.H0c, "boot.H0c"),
                               multiplecorr.method, groups, gaussian.stub, robust, ncol(x),
                               colnames(x))
  boot.type <- extras$boot.type
  wild <- extras$wild
  if (!is.null(sigma)) {
    if (robust) {
      warning("A user-supplied 'sigma' has no effect on the robust standard errors; it is ",
              "only reported as 'sigmahat'.", call. = FALSE)
    } else {
      warning("A user-supplied 'sigma' is used for the standard errors of the original fit ",
              "only; the bootstrap fits estimate the noise level (as in hdi).", call. = FALSE)
    }
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

  # Centred bootstrap distribution. The resampling draws are made here, as in
  # hdi; the bootstrap under the complete null hypothesis reuses them.
  if (gaussian.stub) {
    cboot.dist <- replicate(B, rnorm(ncol(x)))
  } else if (boot.type == "xyz") {
    hats <- .xyz_hats(x, Z, betalasso, rc)
    index <- .xyz_index(nrow(x), B)
    compute_xyz <- function(yvec, truth) {
      .xyz_cbootdist(hats, index, yvec, truth, betainit = betainit, lambda = lambda,
                     robust = robust, parallel = parallel, ncores = ncores)
    }
    cboot.dist <- compute_xyz(hats$yhat, betalasso)
  } else {
    rstar <- resample(r = rc, B = B, wild = wild, multiplier = extras$multiplier)
    ystar <- as.vector(x %*% betalasso) + rstar
    cboot.dist <- compute(ystar, boot.truth = betalasso)
  }

  # Bootstrap under the complete null hypothesis (for Westfall-Young and group
  # p-values), reusing the resampled errors (or rows).
  cboot.dist.underH0c <- NULL
  if (extras$boot.H0c) {
    cboot.dist.underH0c <- if (gaussian.stub) {
      replicate(B, rnorm(ncol(x)))
    } else if (boot.type == "xyz") {
      compute_xyz(hats$e, 0)
    } else {
      compute(0 + rstar, 0)
    }
  }
  if (boot.type == "xyz") {
    kept <- .xyz_kept(cboot.dist, cboot.dist.underH0c)
    cboot.dist <- cboot.dist[, kept, drop = FALSE]
    if (!is.null(cboot.dist.underH0c)) cboot.dist.underH0c <- cboot.dist.underH0c[, kept, drop = FALSE]
    index <- index[, kept, drop = FALSE]
  }
  B.eff <- ncol(cboot.dist)

  # Individual p-values and the multiple testing adjustment.
  pval <- .boot_pvalues(bproj, se, cboot.dist, B.eff)
  pcorr <- if (multiplecorr.method == "WY") {
    .boot_wy(bproj, se, cboot.dist.underH0c, B.eff)
  } else {
    .boot_padjust(pval, multiplecorr.method, B.eff, ncol(x))
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
  tstat <- stats::setNames(bproj / se, colnames(x))
  out <- c(out, list(
    boot.type = boot.type, multiplier = extras$multiplier, robust = robust,
    gaussian.stub = gaussian.stub,
    B.eff = B.eff,
    tstat = tstat,
    boot.summary = .boot_summary(cboot.dist, cboot.dist.underH0c),
    group.summary = .boot_group_summary(extras$groups, cboot.dist, cboot.dist.underH0c),
    boot.index = if (boot.type == "xyz" && return.bootdist) index
  ))
  class(out) <- c("silm_boot_lasso_proj", "silm_proj")
  out
}

# xyz-paired bootstrap: samples that could not be computed (non-finite or
# zero normaliser Z*'X*/n) in either pass are discarded, with one warning.
.xyz_kept <- function(dist, dist0 = NULL) {
  ok <- colSums(!is.finite(dist)) == 0
  if (!is.null(dist0)) ok <- ok & colSums(!is.finite(dist0)) == 0
  if (!all(ok)) {
    warning(sum(!ok), " of ", length(ok), " xyz bootstrap samples were discarded (degenerate ",
            "normaliser Z*'X*/n); see 'B.eff'.", call. = FALSE)
  }
  if (sum(ok) < 2) .stop("Fewer than 2 usable bootstrap samples.")
  ok
}

# Summaries per group of coefficients (for simultaneous inference over groups
# without storing the full bootstrap distributions).
.boot_group_summary <- function(groups, cboot.dist, cboot.dist.underH0c) {
  if (is.null(groups)) return(NULL)
  lapply(groups, function(G) {
    c(list(index = G), .boot_summary(cboot.dist[G, , drop = FALSE],
                                     if (!is.null(cboot.dist.underH0c)) cboot.dist.underH0c[G, , drop = FALSE]))
  })
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
