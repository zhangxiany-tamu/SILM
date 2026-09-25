# Behaviour settled by the code review of SILM 2.0.0.

test_that("Sim.CI follows R's subsetting semantics for `set`, like SILM 1.0.0", {
  d <- sim_data(seed = 51)
  run <- function(set) {
    set.seed(3)
    Sim.CI(d$X, d$Y, set, M = 30)
  }
  expect_identical(run(-(1:3)), run(4:10))
  expect_identical(run(c(0, 1, 2)), run(1:2))
  expect_identical(run(c(1.7, 2)), run(c(1, 2)))
  expect_error(run(c(-1, 2)), "only negative")
  expect_error(run(-(1:10)), "no variable")
})

test_that("logical designs and responses are used as 0/1", {
  withr::local_seed(52)
  Xl <- matrix(runif(1000) > 0.5, 100, 10)
  y <- as.vector(Xl[, 1] + rnorm(100))
  set.seed(1)
  a <- suppressWarnings(SR(Xl, y))
  set.seed(1)
  b <- suppressWarnings(SR(Xl * 1, y))
  expect_identical(a, b)
  x <- matrix(rnorm(40 * 12), 40, 12)
  yl <- x[, 1] + rnorm(40) > 0
  set.seed(2)
  f1 <- lasso.proj(x, yl, suppress.grouptesting = TRUE)
  set.seed(2)
  f2 <- lasso.proj(x, as.numeric(yl), suppress.grouptesting = TRUE)
  f1$call <- f2$call <- NULL
  expect_identical(f1, f2)
})

test_that("0/1 flags are accepted by the hdi-compatible functions", {
  withr::local_seed(53)
  x <- matrix(rnorm(40 * 12), 40, 12)
  y <- x[, 1] + rnorm(40)
  set.seed(1)
  a <- lasso.proj(x, y, robust = 1, suppress.grouptesting = 1)
  set.seed(1)
  b <- lasso.proj(x, y, robust = TRUE, suppress.grouptesting = TRUE)
  expect_identical(a$pval, b$pval)
  expect_error(lasso.proj(x, y, do.ZnZ = NA), "'do.ZnZ'")
  expect_error(lasso.proj(x, y, multiplecorr.method = "WY", N = 100.5), "'N'")
})

test_that("a numeric betainit is accepted with gaussian.stub, as in hdi", {
  withr::local_seed(54)
  x <- matrix(rnorm(400), 40, 10)
  y <- x[, 1] + rnorm(40)
  set.seed(2)
  fit <- suppressWarnings(boot.lasso.proj(x, y, betainit = c(1, rep(0, 9)), sigma = 1,
                                          gaussian.stub = TRUE, B = 20))
  expect_length(fit$pval, 10)
})

test_that("confint: negative parm, parm order and misplaced simultaneous arguments", {
  withr::local_seed(55)
  x <- matrix(rnorm(600), 50, 12)
  y <- x[, 1] + rnorm(50)
  set.seed(1)
  lp <- lasso.proj(x, y, suppress.grouptesting = TRUE)
  expect_identical(confint(lp, parm = -(1:9)), confint(lp, parm = 10:12))
  set.seed(1)
  fit <- boot.lasso.proj(x, y, B = 60, wild = TRUE, robust = TRUE, boot.shortcut = TRUE,
                         return.bootdist = TRUE)
  sim <- suppressWarnings(confint(fit, parm = c(3, 1), type = "simultaneous", group = 1:3))
  expect_identical(rownames(sim), c("3", "1"))
  expect_warning(confint(fit, group = 1:3), "only used with type")
})

test_that("inputs on which the nodewise lasso always failed give clear errors", {
  withr::local_seed(56)
  expect_error(SR(matrix(rnorm(72), 9, 8), rnorm(9)), "at least 10 observations")
  X <- matrix(rnorm(60 * 80), 60, 80)
  expect_error(ST(X, X[, 1] + rnorm(60), 52, 2:80), "10 for testing")
  expect_error(ST(X[, 1:2], rnorm(60), 20, 2), "at least 3 columns")
  expect_error(lasso.proj(matrix(rnorm(45), 9, 5), rnorm(9)), "at least 10 observations")
})

test_that("a Theta computed with a different `center` triggers a warning", {
  withr::local_seed(57)
  X <- matrix(rnorm(1000), 100, 10) + 3
  Y <- as.vector(X[, 1] + rnorm(100) + 2)
  th <- Theta.hat(X)
  expect_identical(attr(th, "center"), FALSE)
  expect_warning(Sim.CI(X, Y, 1:3, M = 20, center = TRUE, Theta = th), "center = FALSE")
})

test_that("xyz: the sign of a normaliser does not matter; folds follow original rows", {
  withr::local_seed(58)
  n <- 60
  x <- scale(matrix(rnorm(n * 8), n, 8), scale = FALSE)
  set.seed(1)
  Z <- SILM:::.nodewise(x, "Z", do_znz = FALSE)$out$Z
  beta <- c(1, rep(0, 7))
  e <- as.vector(x %*% c(1, rep(0, 7)) + rnorm(n))
  e <- e - mean(e) - as.vector(x %*% beta)
  h <- SILM:::.xyz_hats(x, Z, beta, e)
  h_neg <- h
  h_neg$zhat[, 2] <- -h_neg$zhat[, 2]
  rows <- sample.int(n, n, TRUE)
  a <- SILM:::.xyz_draw(rows, h, h$yhat, beta, "scaled lasso", NULL, TRUE, divisor = "n")
  b <- SILM:::.xyz_draw(rows, h_neg, h_neg$yhat, beta, "scaled lasso", NULL, TRUE, divisor = "n")
  expect_equal(a$T, b$T, tolerance = 1e-12)
  f <- SILM:::.xyz_foldid(rows)
  expect_true(all(tapply(f, rows, function(v) length(unique(v))) == 1))
})

test_that("non-finite or degenerate Z, sigma and betainit are rejected", {
  withr::local_seed(56)
  x <- matrix(rnorm(60 * 12), 60, 12)
  y <- x[, 1] + rnorm(60)
  run <- function(...) lasso.proj(x, y, suppress.grouptesting = TRUE, ...)
  expect_error(run(Z = matrix(0, 60, 12)), "not usable")
  z1 <- matrix(rnorm(60 * 12), 60, 12)
  z1[, 3] <- 0
  expect_error(run(Z = z1), "column\\(s\\) 3")
  expect_error(run(Z = matrix(Inf, 60, 12)), "finite numeric matrix")
  expect_error(run(sigma = Inf), "positive finite")
  expect_error(run(betainit = c(Inf, rep(0, 11)), sigma = 1), "numeric 'betainit'")
  expect_error(boot.lasso.proj(x, y, B = 10, sigma = Inf), "positive finite")
})

test_that("the default robust.divisor \"n-s\" applies equation (5) of Dezeure, Buehlmann and Zhang", {
  withr::local_seed(57)
  x <- matrix(rnorm(60 * 12), 60, 12)
  y <- x[, 1:2] %*% c(1, -1) + rnorm(60)
  fit <- function(...) {
    set.seed(4)
    lasso.proj(x, y, robust = TRUE, suppress.grouptesting = TRUE, return.Z = TRUE, ...)
  }
  a <- fit(robust.divisor = "n")
  b <- fit()
  b_given <- fit(robust.divisor = "n-s")
  expect_identical(a$robust.divisor, "n")
  expect_identical(b$robust.divisor, "n-s")
  b$call <- b_given$call <- NULL
  expect_identical(b, b_given)
  for (f in list(lasso.proj, boot.lasso.proj)) {
    expect_identical(eval(formals(f)$robust.divisor), c("n-s", "n"))
  }
  s <- sum(a$betahat != 0)
  expect_gt(s, 0)
  expect_equal(b$se, a$se * sqrt(60 / (60 - s)))
  expect_identical(a$bhat, b$bhat)
  expect_true(all(b$pval >= a$pval))
  expect_error(lasso.proj(x, y, robust = TRUE, robust.divisor = "df"), "should be one of")
})

test_that("\"n-s\" needs fewer non-zero entries of a numeric betainit than observations", {
  withr::local_seed(60)
  x <- matrix(rnorm(30 * 40), 30, 40)
  y <- x[, 1] + rnorm(30)
  Z <- lasso.proj(x, y, standardize = FALSE, return.Z = TRUE, suppress.grouptesting = TRUE)$Z
  lp <- function(...) {
    lasso.proj(x, y, Z = Z, betainit = rep(0.01, 40), sigma = 1, robust = TRUE,
               standardize = FALSE, suppress.grouptesting = TRUE, ...)
  }
  # s_hat = 40 >= n = 30: checked before the nodewise lasso, and the message
  # says "(the default)" only when robust.divisor was not given.
  err <- expect_error(lp(), "\\(the default\\) divides by n - s, where s = 40")
  expect_match(conditionMessage(err), "robust.divisor = \"n\"", fixed = TRUE)
  err_given <- expect_error(lp(robust.divisor = "n-s"), "s = 40")
  expect_false(grepl("the default", conditionMessage(err_given), fixed = TRUE))
  # hdi's normalisation has no such restriction.
  fit <- suppressWarnings(lp(robust.divisor = "n"))
  expect_true(all(is.finite(fit$se)))
  # A sparse numeric betainit works with the default.
  b <- c(0.9, rep(0, 39))
  a <- suppressWarnings(lasso.proj(x, y, Z = Z, betainit = b, sigma = 1, robust = TRUE,
                                   standardize = FALSE, suppress.grouptesting = TRUE))
  a_n <- suppressWarnings(lasso.proj(x, y, Z = Z, betainit = b, sigma = 1, robust = TRUE,
                                     standardize = FALSE, suppress.grouptesting = TRUE,
                                     robust.divisor = "n"))
  expect_equal(a$se, a_n$se * sqrt(30 / 29))
})

test_that("robust.divisor warns only when \"n-s\" is given with robust = FALSE", {
  withr::local_seed(59)
  x <- matrix(rnorm(40 * 10), 40, 10)
  y <- x[, 1] + rnorm(40)
  lp <- function(...) {
    set.seed(1)
    lasso.proj(x, y, suppress.grouptesting = TRUE, ...)
  }
  expect_warning(lp(robust.divisor = "n-s"), "only used with robust = TRUE")
  expect_no_warning(a <- lp())
  expect_no_warning(b <- lp(robust.divisor = "n"))
  # Without robust = TRUE the divisor has no effect.
  expect_identical(a$se, b$se)
  expect_identical(a$pval, b$pval)
  bp <- function(...) boot.lasso.proj(x, y, B = 10, boot.shortcut = TRUE, ...)
  expect_warning(bp(robust.divisor = "n-s"), "only used with robust = TRUE")
  expect_no_warning(bp())
  expect_no_warning(bp(robust.divisor = "n"))
  expect_no_warning(bp(robust = TRUE, robust.divisor = "n-s"))
})

test_that("robust.divisor rescales the bootstrap standard errors consistently", {
  withr::local_seed(58)
  x <- matrix(rnorm(50 * 10), 50, 10)
  y <- x[, 1] + rnorm(50)
  for (type in c("wild", "xyz")) {
    fit <- function(divisor) {
      set.seed(5)
      boot.lasso.proj(x, y, B = 20, robust = TRUE, boot.type = type, boot.shortcut = TRUE,
                      return.bootdist = TRUE, robust.divisor = divisor)
    }
    a <- fit("n")
    b <- fit("n-s")
    ratio_orig <- b$se / a$se
    expect_equal(unname(ratio_orig), rep(ratio_orig[[1]], 10))
    expect_gt(ratio_orig[[1]], 1)
    # T* = (b* - b) / se*: each bootstrap se* is inflated by its own
    # sqrt(n / (n - s*)), the same factor for all p coordinates of a sample.
    ratio_boot <- (b$cboot.dist / b$se) / (a$cboot.dist / a$se)
    expect_equal(ratio_boot, matrix(ratio_boot[1, ], 10, ncol(ratio_boot), byrow = TRUE),
                 ignore_attr = TRUE)
    expect_true(all(ratio_boot > 0 & ratio_boot <= 1 + 1e-12))
    expect_identical(a$bhat, b$bhat)
  }
})
