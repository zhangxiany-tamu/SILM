test_that("scaled lasso agrees with the closed-form one-predictor solution", {
  n <- 50
  x <- matrix(seq(-2, 2, length.out = n), ncol = 1)
  x <- x / sqrt(mean(x^2))
  noise <- cos(seq_len(n))
  noise <- as.vector(noise - x %*% (crossprod(x, noise) / n))
  y <- as.vector(2 * x + noise)
  lam0 <- 0.1

  # For x'x/n = 1 with an active positive coefficient, the fixed-point
  # equations give sigma^2 = RMS(OLS residual)^2 / (1 - lambda0^2).
  beta.ols <- as.vector(crossprod(x, y)) / n
  sigma <- sqrt(mean((y - x * beta.ols)^2) / (1 - lam0^2))
  beta <- beta.ols - lam0 * sigma
  for (units in c(1, 1e-9, 1e9, -1e-9)) {
    fit <- SILM:::.scaled_lasso(x, y * units, lam0 = lam0)
    expect_true(fit$converged)
    expect_equal(unname(fit$coefficients) / units, beta, tolerance = 2e-8)
    expect_equal(fit$hsigma / abs(units), sigma, tolerance = 2e-8)
    expect_equal(fit$lambda / abs(units), lam0 * sigma, tolerance = 2e-8)
  }
})

test_that("scaled lasso recognises the zero-coefficient KKT solution", {
  x <- matrix(rep(c(-1, 1), 20), ncol = 1)
  # Both correlations are exactly zero: no nonzero lars path exists.
  for (y in list(rep(1, 40), rep(c(1, -1, -1, 1), 10))) {
    fit <- SILM:::.scaled_lasso(x, y)
    expect_equal(fit$coefficients, 0)
    expect_equal(fit$hsigma, 1)
    expect_equal(fit$lambda, fit$lam0)
    expect_true(fit$converged)
  }
})
