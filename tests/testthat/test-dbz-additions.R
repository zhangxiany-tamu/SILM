# Methods of Dezeure, Buehlmann and Zhang (2017) that hdi did not implement.

dbz_data <- function(n = 60, p = 12, seed = 1, hetero = FALSE) {
  withr::local_seed(seed)
  x <- matrix(rnorm(n * p), n, p)
  sd <- if (hetero) 0.5 + abs(x[, 2]) else 1
  list(x = x, y = as.vector(x[, 1] * 1.5 + rnorm(n, sd = sd)))
}

fit_boot <- function(d, ..., seed = 1) {
  set.seed(seed)
  suppressWarnings(boot.lasso.proj(d$x, d$y, boot.shortcut = TRUE, ...))
}

test_that("Mammen multipliers have moments 0, 1, 1, 2 and use one uniform each", {
  s5 <- sqrt(5)
  a <- (1 - s5) / 2
  b <- (1 + s5) / 2
  pa <- (s5 + 1) / (2 * s5)
  moments <- vapply(1:4, function(k) pa * a^k + (1 - pa) * b^k, 0)
  expect_equal(moments, c(0, 1, 1, 2), tolerance = 1e-14)
  withr::local_seed(1)
  w <- SILM:::.rmammen(1e5)
  expect_setequal(unique(w), c(a, b))
  expect_lt(abs(mean(w == a) - pa), 4 * sqrt(pa * (1 - pa) / 1e5))
  expect_identical(seed_after(3, SILM:::.rmammen(50)), seed_after(3, runif(50)))
})

test_that("the Gaussian wild and residual resampling draw exactly as hdi", {
  r <- rnorm(20)
  set.seed(4)
  a <- SILM:::resample(r, 5, wild = TRUE)
  set.seed(4)
  expect_identical(a, r * matrix(rnorm(100), 20, 5))
  set.seed(4)
  b <- SILM:::resample(r, 5, wild = FALSE)
  set.seed(4)
  expect_identical(b, matrix(r[replicate(5, sample.int(20, 20, TRUE))], 20, 5))
})

test_that("xyz hat construction makes the bootstrap errors orthogonal", {
  d <- dbz_data(seed = 2)
  x <- scale(d$x, scale = FALSE)
  set.seed(1)
  Z <- SILM:::.nodewise(x, "Z", do_znz = FALSE)$out$Z
  beta <- c(1.4, rep(0, 11))
  e <- as.vector(d$y - mean(d$y) - x %*% beta)
  e <- e - mean(e)
  h <- SILM:::.xyz_hats(x, Z, beta, e)
  expect_lt(max(abs(crossprod(h$xhat, e))), 1e-10)
  expect_lt(max(abs(crossprod(h$zhat, e))), 1e-10)
  expect_equal(h$yhat - as.vector(h$xhat %*% beta), e)
  # With all rows (identity resample) and the lasso refit at beta, the
  # de-sparsified estimate equals beta up to the refit: T* is its deviation.
  draw <- SILM:::.xyz_draw(seq_len(60), h, h$yhat, beta, "scaled lasso", NULL, TRUE,
                           divisor = "n")
  expect_length(draw$T, 12)
  expect_true(all(is.finite(draw$T)))
})

test_that("new arguments at their defaults do not change results or the RNG stream", {
  d <- dbz_data(seed = 3)
  s1 <- seed_after(5, a <- fit_boot(d, B = 20, return.bootdist = TRUE))
  s2 <- seed_after(5, b <- fit_boot(d, B = 20, return.bootdist = TRUE, boot.type = "residual",
                                    multiplier = "gaussian", boot.H0c = TRUE))
  expect_identical(s1, s2)
  a$call <- b$call <- NULL
  expect_identical(a, b)
  s3 <- seed_after(5, w1 <- fit_boot(d, B = 20, wild = TRUE))
  s4 <- seed_after(5, w2 <- fit_boot(d, B = 20, boot.type = "wild"))
  expect_identical(s3, s4)
  expect_identical(w1$pval.corr, w2$pval.corr)
})

test_that("boot.H0c = TRUE with a p.adjust method keeps the p-values", {
  d <- dbz_data(seed = 4)
  a <- fit_boot(d, B = 20, multiplecorr.method = "holm")
  b <- fit_boot(d, B = 20, multiplecorr.method = "holm", boot.H0c = TRUE)
  expect_identical(a$pval, b$pval)
  expect_identical(a$pval.corr, b$pval.corr)
  expect_null(a$boot.summary$absmax.H0c)
  expect_length(b$boot.summary$absmax.H0c, 20)
})

test_that("a singleton simultaneous interval equals the individual interval", {
  d <- dbz_data(seed = 5)
  fit <- fit_boot(d, B = 100, return.bootdist = TRUE, wild = TRUE, robust = TRUE)
  for (lev in c(0.95, 0.5)) {
    for (j in c(1, 7)) {
      ind <- confint(fit, parm = j, level = lev)
      sim <- suppressWarnings(suppressMessages(
        confint(fit, parm = j, level = lev, type = "simultaneous")))
      expect_equal(unname(sim[1, ]), unname(ind[1, ]), tolerance = 1e-12)
    }
  }
})

test_that("simultaneous intervals nest and the |T| version is symmetric", {
  d <- dbz_data(seed = 6)
  fit <- fit_boot(d, B = 200, return.bootdist = TRUE, wild = TRUE, robust = TRUE,
                  groups = list(first = 1:5))
  ind <- confint(fit)
  all_ci <- confint(fit, type = "simultaneous")
  g5 <- confint(fit, type = "simultaneous", group = 1:5)
  tol <- 1e-10
  expect_true(all(all_ci[, 1] <= ind[, 1] + tol & all_ci[, 2] >= ind[, 2] - tol))
  expect_true(all(all_ci[1:5, 1] <= g5[, 1] + tol & all_ci[1:5, 2] >= g5[, 2] - tol))
  abs_ci <- confint(fit, type = "simultaneous", simult.stat = "abs")
  expect_equal(unname(rowMeans(abs_ci)), unname(fit$bhat))
  # max_j |T*_j| >= max_j T*_j and >= -min_j T*_j pointwise, so the type-7
  # quantiles at the same level are ordered.
  q_abs <- attr(abs_ci, "simultaneous")$quantiles[["abs"]]
  expect_gte(q_abs, quantile(fit$boot.summary$max, 0.95, names = FALSE) - tol)
  expect_gte(q_abs, quantile(-fit$boot.summary$min, 0.95, names = FALSE) - tol)
  # Summaries (no stored matrix needed) give the same intervals.
  fit_small <- fit_boot(d, B = 200, wild = TRUE, robust = TRUE, groups = list(first = 1:5))
  expect_equal(confint(fit_small, type = "simultaneous"), all_ci, tolerance = 1e-12)
  expect_equal(confint(fit_small, type = "simultaneous", group = 1:5), g5, tolerance = 1e-12)
  expect_error(confint(fit_small, type = "simultaneous", group = 2:4), "return.bootdist")
  expect_error(confint(fit, type = "simultaneous", parm = 6, group = 1:5), "contained")
})

test_that("group p-values: all coefficients give min(pval.corr); monotonicity; inputs", {
  d <- dbz_data(seed = 7)
  fit <- fit_boot(d, B = 100, return.bootdist = TRUE, wild = TRUE, robust = TRUE)
  expect_identical(groupTest(fit, 1:12), min(fit$pval.corr))
  pg <- groupTest(fit, list(a = 2:5, b = 1:3, c = 9))
  expect_named(pg, c("a", "b", "c"))
  expect_true(pg[["a"]] <= min(fit$pval.corr[2:5]) + 1e-12)
  expect_true(pg[["c"]] <= fit$pval.corr[9] + 1e-12)
  expect_true(all(abs(pg * 101 - round(pg * 101)) < 1e-9))
  expect_identical(groupTest(fit, c(5, 3, 3, 4)), groupTest(fit, 3:5))
  expect_identical(groupTest(fit, seq_len(12) %in% 3:5), groupTest(fit, 3:5))
  expect_error(groupTest(fit, 13), "between 1 and 12")
  holm <- fit_boot(d, B = 20, multiplecorr.method = "holm")
  expect_error(groupTest(holm, 1:3), "complete null")
  set.seed(1)
  lp <- lasso.proj(d$x, d$y, suppress.grouptesting = TRUE)
  expect_error(groupTest(lp, 1:3), "boot.lasso.proj")
  expect_error(confint(lp, type = "simultaneous"), "boot.lasso.proj")
})

test_that("the xyz-paired bootstrap and Mammen multipliers run and are reproducible", {
  d <- dbz_data(seed = 8, hetero = TRUE)
  x1 <- fit_boot(d, B = 30, boot.type = "xyz", robust = TRUE, return.bootdist = TRUE, seed = 2)
  x2 <- fit_boot(d, B = 30, boot.type = "xyz", robust = TRUE, return.bootdist = TRUE, seed = 2)
  x1$call <- x2$call <- NULL
  expect_identical(x1, x2)
  expect_identical(x1$boot.type, "xyz")
  expect_equal(dim(x1$boot.index), c(60, 30))
  expect_true(all(x1$pval > 0 & x1$pval <= 1))
  m <- fit_boot(d, B = 30, wild = TRUE, multiplier = "mammen", robust = TRUE)
  expect_identical(m$multiplier, "mammen")
  expect_false(identical(m$pval, fit_boot(d, B = 30, wild = TRUE, robust = TRUE)$pval))
})

test_that("xyz-paired parallel equals sequential", {
  skip_on_os("windows")
  skip_on_cran()
  d <- dbz_data(seed = 9)
  set.seed(3)
  a <- boot.lasso.proj(d$x, d$y, B = 12, boot.type = "xyz", robust = TRUE)
  set.seed(3)
  b <- boot.lasso.proj(d$x, d$y, B = 12, boot.type = "xyz", robust = TRUE, parallel = TRUE,
                       ncores = 2)
  a$call <- b$call <- NULL
  expect_identical(a, b)
})

test_that("conflicting or unsupported combinations are rejected", {
  d <- dbz_data()
  expect_error(boot.lasso.proj(d$x, d$y, wild = TRUE, boot.type = "xyz"), "contradicts")
  expect_error(boot.lasso.proj(d$x, d$y, multiplier = "mammen"), "wild bootstrap")
  expect_error(boot.lasso.proj(d$x, d$y, boot.H0c = FALSE), "complete null")
  expect_error(boot.lasso.proj(d$x, d$y, gaussian.stub = TRUE, boot.type = "xyz"), "gaussian.stub")
  expect_warning(boot.lasso.proj(d$x, d$y, B = 5, boot.type = "xyz", boot.shortcut = TRUE),
                 "robust")
})

test_that("messages and warnings of simultaneous inference", {
  d <- dbz_data(seed = 10)
  fit <- fit_boot(d, B = 50)
  expect_warning(suppressMessages(confint(fit, type = "simultaneous", level = 0.99)), "few")
  stub <- fit_boot(d, B = 30, gaussian.stub = TRUE)
  expect_warning(suppressMessages(groupTest(stub, 1:12)), "gaussian.stub")
})
