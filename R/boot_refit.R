# Bootstrap refits for boot.lasso.proj(): the initial lasso, the de-sparsified
# lasso and its standard error are recomputed for every bootstrap response
# (Dezeure, Buehlmann and Zhang, 2017: bootstrapping the entire estimator).
#
# Adapted from 'hdi' 0.1-10 (R/boot.lasso-proj.R: compute.cbootdist;
# R/helpers.R: boot.initial.fit, boot.se; code by Ruben Dezeure; GPL, see
# inst/COPYRIGHTS). The results agree exactly with hdi's sequential
# computation. In parallel mode, the cross-validation folds of the refits are
# drawn in the main process in the order in which a sequential run draws
# them, so parallel results are reproducible and identical to sequential ones
# (in hdi they depended on the random streams of the worker processes).

# Studentized bootstrap statistics (b* - boot.truth) / se* (p x B matrix).
.boot_cbootdist <- function(ystar, boot.truth, x, Z, betainit, lambda, robust, parallel,
                            ncores, divisor = "n") {
  initstar <- boot.initial.fit(x = x, ystar = ystar, betainit = betainit, lambda = lambda,
                               parallel = parallel, ncores = ncores)
  betainitstar <- do.call(cbind, lapply(initstar, function(out) out$betalasso))
  sigmahatstar <- sapply(initstar, function(out) out$sigmahat)
  bstar <- despars.lasso.est(x = x, y = ystar, Z = Z, betalasso = betainitstar)
  sestar <- boot.se(x = x, ystar = ystar, Z = Z, betainitstar = betainitstar,
                    sigmahatstar = sigmahatstar, robust = robust, parallel = parallel,
                    ncores = ncores, divisor = divisor)
  (bstar - boot.truth) / sestar
}

# Initial lasso fit for each column of ystar (list of do.initial.fit() results).
boot.initial.fit <- function(x, ystar, betainit, lambda, parallel, ncores) {
  B <- ncol(ystar)
  fit_one <- function(b, foldid = NULL) {
    do.initial.fit(x = x, y = ystar[, b], initial.lasso.method = betainit, lambda = lambda,
                   foldid = foldid)
  }
  n <- nrow(x)
  fold_fun <- if (identical(betainit, "cv lasso") && is.null(lambda)) {
    function(b) sample(rep(seq(10), length = n))
  }
  .boot_map(B, fit_one, fold_fun, parallel = parallel, ncores = ncores)
}

# Apply fit_one(b, foldid) for b = 1..B. Sequentially, the folds are drawn
# inside each fit, in order. In parallel, fold_fun(b) pre-draws them in the
# same order (when the fits draw folds); if any fit had to refit with new folds
# (a rare fallback that draws again), the pass is recomputed sequentially from
# the same random state, so the results never depend on the mode.
.boot_map <- function(B, fit_one, fold_fun, parallel, ncores) {
  if (!.use_fork(parallel, ncores)) {
    return(lapply(seq_len(B), fit_one))
  }
  seed <- .get_seed()
  folds <- if (is.null(fold_fun)) vector("list", B) else lapply(seq_len(B), fold_fun)
  fits <- parallel::mcmapply(function(b, foldid) suppressMessages(fit_one(b, foldid)),
                             b = seq_len(B), foldid = folds, SIMPLIFY = FALSE,
                             USE.NAMES = FALSE, mc.cores = ncores)
  .stop_on_worker_error(fits)
  if (any(vapply(fits, function(f) isTRUE(f$refitted), logical(1)))) {
    .set_seed(seed)
    fits <- lapply(seq_len(B), fit_one)
  }
  fits
}

# Re-raise the first error of a forked worker (mcmapply returns try-error
# objects instead of stopping).
.stop_on_worker_error <- function(results) {
  err <- Filter(function(r) inherits(r, "try-error"), results)
  if (length(err)) {
    cond <- attr(err[[1]], "condition")
    stop(if (is.null(cond)) as.character(err[[1]]) else conditionMessage(cond), call. = FALSE)
  }
  invisible(NULL)
}

# Bootstrap standard errors (p x B matrix).
boot.se <- function(x, ystar, Z, betainitstar, sigmahatstar, robust, parallel, ncores,
                    divisor = "n") {
  if (robust) {
    se_one <- function(b) {
      est.stderr.despars.lasso(x = x, y = ystar[, b], Z = Z, betalasso = betainitstar[, b],
                               sigmahat = sigmahatstar[b], robust = TRUE, divisor = divisor)
    }
    do.call(cbind, .silm_lapply(seq_len(ncol(ystar)), se_one, parallel, ncores))
  } else {
    outer(sqrt(colSums(Z^2)) / nrow(x), sigmahatstar)
  }
}

.use_fork <- function(parallel, ncores) {
  isTRUE(parallel) && ncores > 1L && .Platform$OS.type != "windows"
}

.silm_lapply <- function(X, FUN, parallel, ncores) {
  if (!.use_fork(parallel, ncores)) return(lapply(X, FUN))
  out <- parallel::mclapply(X, FUN, mc.cores = ncores)
  .stop_on_worker_error(out)
  out
}

.get_seed <- function() {
  if (!exists(".Random.seed", envir = globalenv(), inherits = FALSE)) stats::runif(1)
  get(".Random.seed", envir = globalenv(), inherits = FALSE)
}

.set_seed <- function(seed) {
  assign(".Random.seed", seed, envir = globalenv())
}
