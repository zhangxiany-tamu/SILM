st_null <- function(seed = 1) {
  withr::local_seed(seed)
  X <- matrix(rnorm(100 * 60), 100, 60)
  list(X = X, Y = rnorm(100))
}

test_that("ST works when the screening lasso selects no variable (global null)", {
  d <- st_null(2)
  hit <- FALSE
  for (s in 1:15) {
    set.seed(s)
    S1 <- sample(1:100, 30)
    fit <- glmnet::cv.glmnet(d$X[S1, ], d$Y[S1], intercept = FALSE)
    if (all(as.numeric(coef(fit, s = "lambda.min"))[-1] == 0)) {
      hit <- TRUE
      set.seed(s)
      res <- ST(d$X, d$Y, 30, 1:60, M = 50)
      expect_length(res, 4)
      expect_true(is.finite(res[[1]]))
      break
    }
  }
  expect_true(hit)
})

test_that("sub.size may be a proportion", {
  d <- sim_data(seed = 41)
  set.seed(1)
  a <- ST(d$X, d$Y, 30, 4:10, M = 30)
  set.seed(1)
  b <- ST(d$X, d$Y, 0.3, 4:10, M = 30)
  expect_identical(a, b)
  expect_error(ST(d$X, d$Y, 99, 4:10), "sub.size")
})

test_that("the result keeps SILM 1.0.0's layout; legacy spells 'rejct'", {
  d <- sim_data(s0 = 3, beta = c(2, 3), seed = 42)
  set.seed(3)
  res <- ST(d$X, d$Y, 30, 1:10, M = 50)
  set.seed(3)
  old <- ST(d$X, d$Y, 30, 1:10, M = 50, legacy = TRUE)
  expect_named(res, rep(c("non-studentized test", "studentized test"), each = 2))
  expect_identical(res[[4]], "reject")
  expect_identical(old[[4]], "rejct")
  expect_identical(res[-4], old[-4])
})

test_that("an empty intersection gives statistic 0 (legacy: -Inf) and the same RNG state", {
  skip_on_cran()
  # Variable 200 is pure noise and is screened out for seed 7.
  d <- sim_data(n = 100, p = 200, s0 = 3, beta = c(2, 3), seed = 43)
  s_new <- seed_after(7, res <- suppressWarnings(ST(d$X, d$Y, 30, 200L, M = 40)))
  s_old <- seed_after(7, old <- ST(d$X, d$Y, 30, 200L, M = 40, legacy = TRUE))
  expect_identical(old[[1]], -Inf)
  expect_identical(res[[1]], 0)
  expect_identical(res[[2]], "fail to reject")
  expect_identical(s_new, s_old)
  set.seed(7)
  expect_warning(ST(d$X, d$Y, 30, 200L, M = 40), "survived the screening")
})

test_that("out-of-range test.set indices are ignored with a warning", {
  d <- sim_data(seed = 44)
  set.seed(5)
  expect_warning(a <- ST(d$X, d$Y, 30, c(4:10, 11), M = 30), "Ignoring")
  set.seed(5)
  b <- ST(d$X, d$Y, 30, 4:10, M = 30)
  expect_identical(a, b)
})

test_that("default and legacy results differ only in the corrected behaviours", {
  skip_on_cran()
  d <- sim_data(n = 100, p = 40, s0 = 3, beta = c(0.5, 1.5), seed = 45)
  for (s in 1:6) {
    set.seed(s)
    a <- suppressWarnings(ST(d$X, d$Y, 30, 4:40, M = 30))
    set.seed(s)
    b <- ST(d$X, d$Y, 30, 4:40, M = 30, legacy = TRUE)
    b[[4]] <- sub("rejct", "reject", b[[4]])
    expect_identical(a, b)
  }
})
