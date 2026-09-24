# The xyz-paired bootstrap of Dezeure, Buehlmann and Zhang (2017, Section 4.2)
# (a SILM addition; hdi did not implement it).
#
# The rows of (X_hat, Y_hat, Z_hat) are resampled with replacement, where
#   X_hat_j = X_j - (X_j' e / ||e||^2) e,  Z_hat_j likewise,
#   Y_hat   = X_hat beta_hat + e,
# and e are the centred lasso residuals. Then E*[X*' eps*] = E*[Z*' eps*] = 0
# with eps* = Y* - X* beta_hat, so the bootstrap world satisfies the model.
# For every bootstrap sample the entire estimator except the nodewise lasso is
# recomputed: the initial lasso (same tuning method, or the original lambda
# with boot.shortcut), the de-sparsified lasso with normaliser Z*_j' X*_j / n,
# and its standard error. The bootstrap under the complete null hypothesis
# (for Westfall-Young and group p-values) uses the same rows with response e.
#
# Conventions where the paper is not explicit (see dev/DESIGN.md, Appendix C):
# each bootstrap sample is centred (without rescaling) before fitting, as the
# original data were; the nodewise residuals are rescaled so that
# Z*_j' X*_j / n = 1, which is the plug-in normaliser of the paper; samples
# with a non-positive normaliser are discarded (reported in B.eff).

.xyz_hats <- function(x, Z, betalasso, e) {
  s2 <- sum(e^2)
  if (s2 <= length(e) * .Machine$double.eps) {
    .stop("The lasso residuals are (numerically) zero; the xyz-paired bootstrap is not defined.")
  }
  xhat <- x - tcrossprod(e, crossprod(x, e)) / s2
  zhat <- Z - tcrossprod(e, crossprod(Z, e)) / s2
  yhat <- as.vector(xhat %*% betalasso) + e
  list(xhat = xhat, zhat = zhat, yhat = yhat, e = e)
}

# Row indices of the bootstrap samples (n x B matrix).
.xyz_index <- function(n, B) replicate(B, sample.int(n, n, replace = TRUE))

# Studentized statistics of one xyz bootstrap sample.
.xyz_draw <- function(rows, hats, yvec, truth, betainit, lambda, robust, foldid = NULL) {
  n <- length(rows)
  xs <- hats$xhat[rows, , drop = FALSE]
  zs <- hats$zhat[rows, , drop = FALSE]
  ys <- yvec[rows]
  xs <- sweep(xs, 2, colMeans(xs))
  zs <- sweep(zs, 2, colMeans(zs))
  ys <- ys - mean(ys)
  normaliser <- colSums(zs * xs) / n
  if (any(!is.finite(normaliser) | normaliser <= 0)) {
    # Discarded sample: still consume its fold draw, so that the random number
    # stream does not depend on which samples are discarded (and parallel runs,
    # which pre-draw one fold assignment per sample, stay identical).
    if (is.null(foldid) && identical(betainit, "cv lasso") && is.null(lambda)) {
      sample(rep(seq(10), length = n))
    }
    return(list(T = rep(NA_real_, ncol(xs)), refitted = FALSE))
  }
  zs <- sweep(zs, 2, normaliser, "/")
  init <- do.initial.fit(x = xs, y = ys, initial.lasso.method = betainit, lambda = lambda,
                         foldid = foldid)
  bs <- despars.lasso.est(x = xs, y = ys, Z = zs, betalasso = init$betalasso)
  ses <- if (robust) {
    sandwich.var.est.stderr(x = xs, y = ys, betainit = init$betalasso, Z = zs)
  } else {
    init$sigmahat * sqrt(colSums(zs^2)) / n
  }
  list(T = as.vector((bs - truth) / ses), refitted = init$refitted)
}

# p x B matrix of studentized statistics over the bootstrap samples in `index`.
# Folds are handled by .boot_map() (reproducible in parallel mode).
.xyz_cbootdist <- function(hats, index, yvec, truth, betainit, lambda, robust, parallel,
                           ncores) {
  draw_one <- function(b, foldid = NULL) {
    .xyz_draw(index[, b], hats, yvec, truth, betainit, lambda, robust, foldid)
  }
  draws <- .boot_map(ncol(index), draw_one,
                     draws_folds = identical(betainit, "cv lasso") && is.null(lambda),
                     n = nrow(index), parallel = parallel, ncores = ncores)
  do.call(cbind, lapply(draws, `[[`, "T"))
}
