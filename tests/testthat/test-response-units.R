test_that("scaled lasso obeys response units and its fixed-point equations", {
  d <- sim_data(n = 80, p = 30, rho = 0.4, seed = 91)
  ref <- SILM:::.scaled_lasso(d$X, d$Y)
  expect_true(ref$converged)
  expect_equal(ref$hsigma, sqrt(mean((d$Y - d$X %*% ref$coefficients)^2)),
               tolerance = 1e-12)
  expect_equal(ref$lambda, ref$lam0 * ref$hsigma, tolerance = 2e-8)
  for (units in c(1e-12, 1e-6, -1e-6, 1e6, 1e12)) {
    fit <- SILM:::.scaled_lasso(d$X, units * d$Y)
    expect_equal(fit$coefficients / units, ref$coefficients, tolerance = 1e-9)
    expect_equal(fit$hsigma / abs(units), ref$hsigma, tolerance = 1e-9)
    expect_equal(fit$lambda / abs(units), ref$lambda, tolerance = 1e-9)
    expect_true(fit$converged)
  }
})

test_that("a zero solver solution does not produce undefined inference", {
  d <- sim_data(n = 40, p = 6, seed = 96)
  y <- rep(0, 40)
  expect_error(SR(d$X, y), "estimated noise level is zero")
  expect_error(Sim.CI(d$X, y, set = 1:3, M = 9), "estimated noise level is zero")
  expect_error(Step(d$X, y, M = 9), "estimated noise level is zero")
  expect_error(lasso.proj(d$X, y, Z = d$X, betainit = "scaled lasso"),
               "estimated noise level is zero")
  expect_error(boot.lasso.proj(d$X, y, Z = d$X, betainit = "scaled lasso", B = 9),
               "estimated noise level is zero")
  fit <- suppressWarnings(lasso.proj(d$X, y, Z = d$X, betainit = "scaled lasso",
                                     sigma = 1, suppress.grouptesting = TRUE))
  expect_true(all(is.finite(fit$pval)))
})

test_that("orthogonal-design simultaneous intervals do not depend on response units", {
  withr::local_seed(92)
  n <- 120L
  p <- 6L
  q <- qr.Q(qr(cbind(1, matrix(rnorm(n * (p + 1)), n))))
  X <- q[, 2:(p + 1)] * sqrt(n)
  y <- as.vector(X %*% c(20, -15, rep(0, p - 2)) + sqrt(n) * q[, p + 2])
  ci <- function(units, mode = "equivariant") {
    set.seed(93)
    Sim.CI(X, units * y, seq_len(p), M = 199, scaled.lasso = mode)
  }
  ref <- ci(1)
  for (units in c(1e-6, 1e6)) {
    fit <- ci(units)
    for (j in seq_along(ref)) expect_equal(fit[[j]] / units, ref[[j]], tolerance = 1e-9)
  }
  # This case distinguishes the repair from the archived stopping convention.
  width <- function(z) diff(z$band.st[, 1])
  expect_gt(width(ci(1e-6, "legacy")) / 1e-6 / width(ci(1, "legacy")), 3)
})

test_that("inference callers propagate the equivariant scaled-lasso solver", {
  d <- sim_data(n = 80, p = 10, rho = 0.3, seed = 94)
  X <- scale(d$X, scale = FALSE)
  y <- d$Y - mean(d$Y)
  Z <- X
  run <- function(units) {
    set.seed(95)
    list(sr = SR(X, units * y), step = Step(X, units * y, M = 49),
         st = ST(X, units * y, sub.size = 40, test.set = 1:3, M = 49),
         lp = lasso.proj(X, units * y, Z = Z, betainit = "scaled lasso",
                         suppress.grouptesting = TRUE),
         bp = boot.lasso.proj(X, units * y, Z = Z, betainit = "scaled lasso",
                              B = 19, return.bootdist = TRUE, robust = TRUE))
  }
  ref <- run(1)
  fit <- run(1e-6)
  expect_identical(fit$sr, ref$sr)
  expect_identical(fit$step, ref$step)
  expect_equal(fit$st[[1]] / 1e-6, ref$st[[1]], tolerance = 1e-7)
  expect_equal(fit$st[-1], ref$st[-1], tolerance = 1e-7)
  for (name in c("lp", "bp")) {
    expect_equal(fit[[name]]$bhat / 1e-6, ref[[name]]$bhat, tolerance = 1e-8)
    expect_equal(fit[[name]]$se / 1e-6, ref[[name]]$se, tolerance = 1e-8)
    expect_equal(fit[[name]]$pval, ref[[name]]$pval, tolerance = 1e-8)
    expect_equal(confint(fit[[name]]) / 1e-6, confint(ref[[name]]), tolerance = 1e-8)
  }
})
