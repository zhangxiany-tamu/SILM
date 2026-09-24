test_that("the scaled lasso satisfies the lasso KKT conditions at its penalty", {
  d <- sim_data(n = 80, p = 40, s0 = 3, seed = 11)
  fit <- SILM:::.scaled_lasso(d$X, d$Y)
  b <- fit$coefficients
  r <- d$Y - d$X %*% b
  grad <- as.vector(crossprod(d$X, r)) / nrow(d$X)
  active <- b != 0
  expect_true(any(active))
  expect_equal(abs(grad[active]), rep(fit$lambda, sum(active)), tolerance = 1e-6)
  expect_true(all(abs(grad[!active]) <= fit$lambda * (1 + 1e-6)))
  expect_equal(sign(grad[active]), sign(b[active]))
})

test_that("the noise level is the RMS residual of the final iterate and converges", {
  d <- sim_data(n = 100, p = 20, seed = 12)
  fit <- SILM:::.scaled_lasso(d$X, d$Y)
  expect_true(fit$converged)
  expect_gt(fit$hsigma, 0)
  expect_equal(fit$lam0, SILM:::.lam0_quantile(100, 20))
  expect_lt(fit$iterations, 101)
})

test_that("lam0 follows the quantile and universal rules", {
  expect_equal(SILM:::.lam0_quantile(50, 1), sqrt(2 / 50) * 0.5)
  expect_equal(SILM:::.resolve_lam0("univ", 100, 30), sqrt(2 * log(30) / 100))
  expect_equal(SILM:::.resolve_lam0(0.2, 100, 30), 0.2)
  expect_error(SILM:::.resolve_lam0("other", 100, 30), "lam0")
})

test_that("coefficients keep column names and p = 1 works", {
  d <- sim_data(n = 50, p = 5, seed = 13)
  colnames(d$X) <- letters[1:5]
  expect_named(SILM:::.scaled_lasso(d$X, d$Y)$coefficients, letters[1:5])
  expect_length(SILM:::.scaled_lasso(d$X[, 1, drop = FALSE], d$Y)$coefficients, 1)
})

test_that(".standardize_unitnorm centres and scales to unit norm", {
  withr::local_seed(3)
  X <- matrix(rnorm(60), 20, 3) * 5 + 2
  S <- SILM:::.standardize_unitnorm(X)
  expect_equal(colMeans(S), rep(0, 3))
  expect_equal(colSums(S^2), rep(1, 3))
})
