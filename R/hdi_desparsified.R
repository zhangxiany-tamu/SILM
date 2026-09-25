# De-sparsified (de-biased) lasso estimator and its standard errors.
#
# Adapted from 'hdi' 0.1-10 (R/helpers.R: despars.lasso.est,
# est.stderr.despars.lasso, sandwich.var.est.stderr; code by Ruben Dezeure;
# GPL, see inst/COPYRIGHTS). The expressions are kept literally so that the
# results agree exactly with hdi.
#
# References:
#   van de Geer, S., Buehlmann, P., Ritov, Y. and Dezeure, R. (2014). On
#     asymptotically optimal confidence regions and tests for high-dimensional
#     models. Annals of Statistics, 42, 1166-1202.
#   Dezeure, R., Buehlmann, P. and Zhang, C.-H. (2017). High-dimensional
#     simultaneous inference with the bootstrap. TEST, 26, 685-719.

# b = betalasso + t(Z) (y - x betalasso) / n. y and betalasso may be matrices
# (one column per bootstrap sample).
despars.lasso.est <- function(x, y, Z, betalasso) {
  b <- crossprod(Z, y - x %*% betalasso) / nrow(x) + betalasso
  if (ncol(b) == 1) b <- as.vector(b)
  b
}

# Standard errors of the de-sparsified lasso: sigmahat ||Z_j|| / n (Z rescaled
# so that t(Z_j) x_j / n = 1), or the robust (sandwich) version. For the robust
# version, divisor = "n" is hdi's (and Section 3.3.2's) normalisation;
# divisor = "n-s" gives equation (5) of Dezeure, Buehlmann and Zhang (2017),
# i.e. the standard error multiplied by sqrt(n / (n - s_hat)). `divisor` has
# no default (as the helpers that pass it on): the exported default "n-s"
# differs from hdi's "n", so every caller must say which one it uses.
est.stderr.despars.lasso <- function(x, y, Z, betalasso, sigmahat, robust, divisor) {
  if (robust) {
    se <- sandwich.var.est.stderr(x = x, y = y, Z = Z, betainit = betalasso)
    .robust_df_adjust(se, nrow(x), betalasso, divisor)
  } else {
    (sigmahat * sqrt(diag(crossprod(Z)))) / nrow(x)
  }
}

.robust_df_adjust <- function(se, n, betalasso, divisor) {
  if (identical(divisor, "n")) return(se)
  s <- sum(betalasso != 0)
  if (s >= n) {
    # (A numeric betainit of lasso.proj() is checked earlier, by
    # .check_divisor_betainit(), with a message that names the default.)
    .stop("robust.divisor = \"n-s\" divides by n - s, where s is the number of non-zero ",
          "coefficients of the initial estimate; here s = ", s, " >= n = ", n, ". Use ",
          "robust.divisor = \"n\" (hdi's normalisation).")
  }
  se * sqrt(n / (n - s))
}

# Robust standard error (Dezeure, Buehlmann and Zhang, 2017, Section 3.3.2):
# sqrt(sum_i (e_i Z_ij - mean_r(e_r Z_rj))^2) / n, with centred residuals e.
sandwich.var.est.stderr <- function(x, y, betainit, Z) {
  n <- nrow(x)
  p <- ncol(x)
  if (!isTRUE(all.equal(rep(1, p), colSums(Z * x) / n, tolerance = 10^-8))) {
    Z <- score.rescale(Z = Z, x = x)$Z
  }
  if (length(betainit) > ncol(x)) {
    x <- cbind(rep(1, nrow(x)), x)
  }
  eps.tmp <- as.vector(y - x %*% betainit)
  # Centre the residuals, as if the model had been fitted with an intercept.
  eps.tmp <- eps.tmp - mean(eps.tmp)
  sigmahatZ.direct <- sqrt(colSums(sweep(eps.tmp * Z, MARGIN = 2,
                                         STATS = crossprod(eps.tmp, Z) / n,
                                         FUN = `-`)^2))
  sigmahatZ.direct / n
}
