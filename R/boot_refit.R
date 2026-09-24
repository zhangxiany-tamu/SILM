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
                            ncores) {
  initstar <- boot.initial.fit(x = x, ystar = ystar, betainit = betainit, lambda = lambda,
                               parallel = parallel, ncores = ncores)
  betainitstar <- do.call(cbind, lapply(initstar, function(out) out$betalasso))
  sigmahatstar <- sapply(initstar, function(out) out$sigmahat)
  bstar <- despars.lasso.est(x = x, y = ystar, Z = Z, betalasso = betainitstar)
  sestar <- boot.se(x = x, ystar = ystar, Z = Z, betainitstar = betainitstar,
                    sigmahatstar = sigmahatstar, robust = robust, parallel = parallel,
                    ncores = ncores)
  (bstar - boot.truth) / sestar
}

# Initial lasso fit for each column of ystar (list of do.initial.fit() results).
boot.initial.fit <- function(x, ystar, betainit, lambda, parallel, ncores) {
  B <- ncol(ystar)
  fit_one <- function(b, foldid = NULL) {
    do.initial.fit(x = x, y = ystar[, b], initial.lasso.method = betainit, lambda = lambda,
                   foldid = foldid)
  }
  .boot_map(B, fit_one, draws_folds = identical(betainit, "cv lasso") && is.null(lambda),
            n = nrow(x), parallel = parallel, ncores = ncores)
}

# Apply fit_one(b, foldid) for b = 1..B. Sequentially, the folds are drawn
# inside each fit, in order. In parallel, they are pre-drawn in the same order
# (when the fits draw folds); if any fit had to refit with new folds (a rare
# fallback that draws again), the whole pass is recomputed sequentially from
# the same random state, so the results never depend on the mode.
.boot_map <- function(B, fit_one, draws_folds, n, parallel, ncores) {
  if (!.use_fork(parallel, ncores)) {
    return(lapply(seq_len(B), fit_one))
  }
  seed <- .get_seed()
  folds <- if (draws_folds) .draw_foldids(n, B) else vector("list", B)
  fits <- parallel::mcmapply(fit_one, b = seq_len(B), foldid = folds, SIMPLIFY = FALSE,
                             USE.NAMES = FALSE, mc.cores = ncores)
  if (any(vapply(fits, function(f) isTRUE(f$refitted), logical(1)))) {
    .set_seed(seed)
    fits <- lapply(seq_len(B), fit_one)
  }
  fits
}

# Bootstrap standard errors (p x B matrix).
boot.se <- function(x, ystar, Z, betainitstar, sigmahatstar, robust, parallel, ncores) {
  if (robust) {
    se_one <- function(b) {
      est.stderr.despars.lasso(x = x, y = ystar[, b], Z = Z, betalasso = betainitstar[, b],
                               sigmahat = sigmahatstar[b], robust = TRUE)
    }
    do.call(cbind, .silm_lapply(seq_len(ncol(ystar)), se_one, parallel, ncores))
  } else {
    outer(sqrt(colSums(Z^2)) / nrow(x), sigmahatstar)
  }
}

# Cross-validation folds as drawn by cv.glmnet(): sample(rep(seq(K), length = n)).
.draw_foldids <- function(n, B, K = 10) {
  lapply(seq_len(B), function(b) sample(rep(seq(K), length = n)))
}

.use_fork <- function(parallel, ncores) {
  isTRUE(parallel) && ncores > 1L && .Platform$OS.type != "windows"
}

.silm_lapply <- function(X, FUN, parallel, ncores) {
  if (.use_fork(parallel, ncores)) {
    parallel::mclapply(X, FUN, mc.cores = ncores)
  } else {
    lapply(X, FUN)
  }
}

.get_seed <- function() {
  if (!exists(".Random.seed", envir = globalenv(), inherits = FALSE)) stats::runif(1)
  get(".Random.seed", envir = globalenv(), inherits = FALSE)
}

.set_seed <- function(seed) {
  assign(".Random.seed", seed, envir = globalenv())
}
