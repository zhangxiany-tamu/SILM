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
# - each bootstrap sample is centred (without rescaling) before fitting, as the
#   original data were;
# - the nodewise residuals are divided by the plug-in normaliser Z*_j' X*_j / n
#   (signed in b*, in absolute value in se*, as in the paper); samples with a
#   non-finite or numerically zero normaliser are discarded (see B.eff);
# - when the lasso is re-tuned by cross-validation, the folds are formed by
#   original observation, so that copies of a resampled row never fall into
#   both the training and the test folds (which would bias lambda downwards).

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

# Cross-validation folds for a paired bootstrap sample: one fold per original
# observation, drawn as cv.glmnet() draws folds for the distinct rows.
.xyz_foldid <- function(rows, K = 10) {
  distinct <- unique(rows)
  sample(rep(seq(K), length = length(distinct)))[match(rows, distinct)]
}

# Studentized statistics of one xyz bootstrap sample (NA if the sample has to
# be discarded).
.xyz_draw <- function(rows, hats, yvec, truth, betainit, lambda, robust, foldid = NULL) {
  n <- length(rows)
  # The folds are drawn first, so that the random number stream does not
  # depend on which samples are discarded (parallel runs pre-draw them).
  if (is.null(foldid) && identical(betainit, "cv lasso") && is.null(lambda)) {
    foldid <- .xyz_foldid(rows)
  }
  xs <- hats$xhat[rows, , drop = FALSE]
  zs <- hats$zhat[rows, , drop = FALSE]
  ys <- yvec[rows]
  xs <- sweep(xs, 2, colMeans(xs))
  zs <- sweep(zs, 2, colMeans(zs))
  ys <- ys - mean(ys)
  normaliser <- colSums(zs * xs) / n
  if (any(!is.finite(normaliser) | abs(normaliser) <= sqrt(.Machine$double.eps))) {
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

# p x B matrix of studentized statistics over the bootstrap samples in `index`
# (NA columns for discarded samples). Folds are handled by .boot_map().
.xyz_cbootdist <- function(hats, index, yvec, truth, betainit, lambda, robust, parallel,
                           ncores) {
  draw_one <- function(b, foldid = NULL) {
    .xyz_draw(index[, b], hats, yvec, truth, betainit, lambda, robust, foldid)
  }
  fold_fun <- if (identical(betainit, "cv lasso") && is.null(lambda)) {
    function(b) .xyz_foldid(index[, b])
  }
  draws <- .boot_map(ncol(index), draw_one, fold_fun, parallel = parallel, ncores = ncores)
  do.call(cbind, lapply(draws, `[[`, "T"))
}
