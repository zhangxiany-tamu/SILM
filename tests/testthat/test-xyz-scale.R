test_that("xyz projections depend on residual direction, not response units", {
  withr::local_seed(20260929)
  x <- scale(matrix(rnorm(240), 60, 4), scale = FALSE)
  Z <- scale(matrix(rnorm(240), 60, 4), scale = FALSE)
  e <- rnorm(60)
  e <- e - mean(e)
  beta <- c(2, -1, 0, 0)
  reference <- SILM:::.xyz_hats(x, Z, beta, e)

  # Independent QR projection onto the orthogonal complement of e.
  expect_equal(reference$xhat, qr.resid(qr(matrix(e, ncol = 1)), x),
               ignore_attr = TRUE, tolerance = 1e-12)
  expect_equal(reference$zhat, qr.resid(qr(matrix(e, ncol = 1)), Z),
               ignore_attr = TRUE, tolerance = 1e-12)
  expect_lt(max(abs(crossprod(e, reference$xhat))), 1e-11)
  expect_lt(max(abs(crossprod(e, reference$zhat))), 1e-11)

  # These cover the former absolute cutoff, plus squaring under/overflow.
  for (units in c(1e-200, 1e-9, -1e-9, 1e200)) {
    fit <- SILM:::.xyz_hats(x, Z, beta * units, e * units)
    expect_equal(fit$xhat, reference$xhat, tolerance = 1e-12)
    expect_equal(fit$zhat, reference$zhat, tolerance = 1e-12)
    expect_equal(fit$yhat / units, reference$yhat, tolerance = 1e-12)
    expect_equal(fit$e / units, e, tolerance = 1e-12)
  }
})

test_that("xyz projections reject an exactly zero residual direction", {
  x <- matrix(seq_len(30), 10, 3)
  expect_error(SILM:::.xyz_hats(x, x, rep(0, 3), rep(0, 10)),
               "residuals are .* zero")
})

test_that("the xyz bootstrap preserves inference after changing response units", {
  withr::local_seed(20260929)
  n <- 60
  x <- scale(matrix(rnorm(n * 5), n, 5), scale = FALSE)
  y <- as.vector(2 * x[, 1] - x[, 2] + rnorm(n))
  Z <- x %*% solve(crossprod(x) / n)
  run <- function(units) {
    set.seed(73)
    boot.lasso.proj(x, y * units, Z = Z, standardize = FALSE,
                    betainit = "scaled lasso", boot.type = "xyz", robust = TRUE,
                    B = 19, return.bootdist = TRUE)
  }
  fit <- run(1)
  small <- run(1e-9)
  expect_equal(small$bhat / 1e-9, fit$bhat, tolerance = 1e-8)
  expect_equal(small$se / 1e-9, fit$se, tolerance = 1e-8)
  # Public bootstrap draws have the response units (the pivot times se).
  expect_equal(small$cboot.dist / 1e-9, fit$cboot.dist, tolerance = 1e-8)
  expect_equal(small$cboot.dist.underH0c / 1e-9, fit$cboot.dist.underH0c, tolerance = 1e-8)
  expect_identical(small$pval, fit$pval)
  expect_identical(small$pval.corr, fit$pval.corr)
  expect_equal(confint(small) / 1e-9, confint(fit), tolerance = 1e-8)
})
