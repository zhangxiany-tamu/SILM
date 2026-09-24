# Scaled lasso (Sun and Zhang, 2012), computed on the lars lasso path.
#
# The scaled lasso jointly estimates the regression coefficients and the noise
# level by alternating
#   beta  <- lasso(y ~ X, lambda = lam0 * sigma)
#   sigma <- ||y - X beta|| / sqrt(n)
# until sigma stabilises. lam0 defaults to the quantile-based penalty level of
# Sun and Zhang (2013), obtained from a damped fixed-point iteration.
#
# This is an independent implementation. Its numerical conventions (starting
# value 5 for sigma, tolerance 1e-4, at most 101 updates, the lambda of the
# previous iterate for the returned coefficients) were chosen so that results
# agree exactly with the archived 'scalreg' package (version 1.0.1), which the
# procedures of Zhang and Cheng (2017) and the 'hdi' package relied on.
#
# References:
#   Sun, T. and Zhang, C.-H. (2012). Scaled sparse linear regression.
#     Biometrika, 99(4), 879-898.
#   Sun, T. and Zhang, C.-H. (2013). Sparse matrix inversion with scaled lasso.
#     Journal of Machine Learning Research, 14, 3385-3418.

SCALED_LASSO_SIGMA_START <- 5
SCALED_LASSO_TOL <- 1e-4
SCALED_LASSO_MAX_UPDATES <- 100L

# Quantile-based penalty level lambda_0 = sqrt(2/n) * L, where L solves
# L = qnorm(1 - (L^4 + 2 L^2) / p) (Sun and Zhang, 2013), found by damped
# fixed-point iteration.
.lam0_quantile <- function(n, p) {
  level <- 0.1
  previous <- 0
  while (abs(level - previous) > 0.001) {
    tail_prob <- level^4 + 2 * level^2
    previous <- level
    level <- -qnorm(min(tail_prob / p, 0.99))
    level <- (level + previous) / 2
  }
  if (p == 1) level <- 0.5
  sqrt(2 / n) * level
}

.lam0_universal <- function(n, p) sqrt(2 * log(p) / n)

.resolve_lam0 <- function(lam0, n, p) {
  if (is.null(lam0)) lam0 <- if (p > 10^6) "univ" else "quantile"
  if (is.numeric(lam0)) return(lam0)
  switch(lam0,
    quantile = .lam0_quantile(n, p),
    univ = ,
    universal = .lam0_universal(n, p),
    stop("'lam0' must be NULL, numeric, \"quantile\" or \"univ\".", call. = FALSE)
  )
}

#' Scaled lasso
#'
#' @param X Numeric design matrix (no intercept column; the lasso is fitted
#'   without intercept and without normalisation).
#' @param y Numeric response.
#' @param lam0 Penalty level: `NULL` (quantile rule, or the universal rule when
#'   p > 1e6), `"quantile"`, `"univ"`, or a number.
#' @return A list with `coefficients`, `hsigma` (noise level estimate),
#'   `lam0`, `lambda` (penalty of the returned fit, per observation),
#'   `iterations` and `converged`.
#' @noRd
.scaled_lasso <- function(X, y, lam0 = NULL) {
  X <- as.matrix(X)
  y <- as.numeric(y)
  n <- dim(X)[1]
  lam0 <- .resolve_lam0(lam0, n, dim(X)[2])

  path <- lars::lars(X, y, type = "lasso", intercept = FALSE, normalize = FALSE,
                     use.Gram = FALSE)
  path_fit <- function(lambda, type) {
    lars::predict.lars(path, X, s = lambda * n, type = type, mode = "lambda")
  }

  sigma_old <- 0.1
  sigma <- SCALED_LASSO_SIGMA_START
  updates <- 0L
  while (abs(sigma_old - sigma) > SCALED_LASSO_TOL & updates <= SCALED_LASSO_MAX_UPDATES) {
    updates <- updates + 1L
    sigma_old <- sigma
    lambda <- lam0 * sigma_old
    fitted <- path_fit(lambda, "fit")$fit
    sigma <- sqrt(mean((y - fitted)^2))
  }
  converged <- abs(sigma_old - sigma) <= SCALED_LASSO_TOL
  if (!converged) {
    warning("scaled lasso: noise level did not converge within ",
            SCALED_LASSO_MAX_UPDATES + 1L, " updates.", call. = FALSE)
  }

  list(
    coefficients = path_fit(lambda, "coefficients")$coefficients,
    hsigma = sigma,
    lam0 = lam0,
    lambda = lambda,
    iterations = updates,
    converged = converged
  )
}
