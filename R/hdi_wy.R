# Westfall-Young type multiple testing adjustment of lasso.proj().
#
# Adapted from 'hdi' 0.1-10 (R/helpers.R: p.adjust.wy; GPL, see
# inst/COPYRIGHTS). Unchanged.

# Simulate the null distribution of the minimum p-value from a Gaussian with
# covariance `cov` (here crossprod(Z)) and adjust the p-values by its ECDF.
p.adjust.wy <- function(cov, pval, N = 10000) {
  zz <- MASS::mvrnorm(N, rep(0, ncol(cov)), cov)
  zz2 <- scale(zz, center = FALSE, scale = sqrt(diag(cov)))
  Gz <- apply(2 * pnorm(abs(zz2), lower.tail = FALSE), 1, min)
  ecdf(Gz)(pval)
}

.multiplecorr_check <- function(method) {
  if (!is.character(method) || length(method) != 1L ||
      !(method == "WY" || method %in% p.adjust.methods)) {
    .stop("Unknown multiple correction method specified: use \"WY\" or one of ",
          paste(dQuote(p.adjust.methods, FALSE), collapse = ", "), ".")
  }
  method
}
