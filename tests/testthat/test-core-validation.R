test_that("invalid inputs give informative errors", {
  d <- sim_data()
  expect_error(SR(letters, d$Y), "numeric matrix")
  expect_error(SR(d$X, d$Y[-1]), "100 elements")
  X_na <- d$X
  X_na[1, 1] <- NA
  expect_error(SR(X_na, d$Y), "missing")
  expect_error(Sim.CI(d$X, d$Y, set = 11), "between 1 and 10")
  expect_error(Sim.CI(d$X, d$Y, set = 1:3, M = 0), "positive")
  expect_error(Step(d$X, d$Y, alpha = 2), "between 0 and 1")
  expect_error(SR(d$X, d$Y, nodewise = "other"), "should be one of")
  expect_error(SR(d$X, d$Y, center = NA), "TRUE or FALSE")
  expect_error(SR(d$X, d$Y, Theta = diag(3)), "10 x 10")
})

test_that("data frames and one-column matrices are accepted", {
  d <- sim_data()
  set.seed(1)
  a <- SR(d$X, d$Y)
  set.seed(1)
  b <- SR(as.data.frame(d$X), matrix(d$Y, ncol = 1))
  expect_identical(a, b)
})

test_that("Sim.CI warns when alpha looks like a significance level", {
  d <- sim_data()
  expect_warning(Sim.CI(d$X, d$Y, 1:3, M = 20, alpha = 0.05), "confidence level")
})

test_that("a logical set is equivalent to its indices", {
  d <- sim_data()
  set.seed(2)
  a <- Sim.CI(d$X, d$Y, 1:3, M = 30)
  set.seed(2)
  b <- Sim.CI(d$X, d$Y, seq_len(10) <= 3, M = 30)
  expect_identical(a, b)
})

test_that("singular Gram matrices and constant columns give informative errors", {
  d <- sim_data()
  X <- d$X
  X[, 10] <- X[, 9]
  expect_error(SR(X, d$Y), "singular")
  d2 <- sim_data(n = 40, p = 30)
  X2 <- d2$X
  X2[, 5] <- 1
  expect_error(suppressWarnings(SR(X2, d2$Y)), "constant")
})

test_that("uncentred data trigger a warning; center = TRUE removes location", {
  d <- sim_data()
  expect_silent(SR(d$X, d$Y))
  Xs <- d$X + 5
  Ys <- d$Y + 3
  expect_warning(SR(Xs, Ys), "centred")
  set.seed(4)
  a <- SR(d$X, d$Y, center = TRUE)
  set.seed(4)
  b <- SR(Xs, Ys, center = TRUE)
  expect_equal(a, b)
})

test_that("a supplied Theta reproduces the internal computation", {
  d <- sim_data(n = 60, p = 80, seed = 5)
  set.seed(10)
  a <- Sim.CI(d$X, d$Y, 1:3, M = 30)
  set.seed(10)
  th <- Theta.hat(d$X)
  b <- Sim.CI(d$X, d$Y, 1:3, M = 30, Theta = th)
  expect_identical(a, b)
  expect_identical(attr(th, "method"), "nodewise")
  expect_identical(attr(Theta.hat(d$X[, 1:20]), "method"), "inverse-gram")
})
