test_that("SR, Sim.CI and Step return the documented structures", {
  d <- sim_data(s0 = 3, beta = c(1, 2), seed = 31)
  set.seed(1)
  sr <- SR(d$X, d$Y)
  expect_named(sr, c("de-biased Lasso", "scaled Lasso"))
  expect_true(all(1:3 %in% sr[["scaled Lasso"]]))

  ci <- Sim.CI(d$X, d$Y, 1:3, M = 50)
  expect_named(ci, c("de-biased Lasso", "band.nst", "band.st"))
  expect_equal(dim(ci$band.st), c(2, 3))
  expect_equal(rownames(ci$band.st), c("low.st", "up.st"))
  expect_true(all(ci$band.st[1, ] < ci$band.st[2, ]))

  st <- Step(d$X, d$Y, M = 50)
  expect_named(st, c("non-studentized test", "studentized test"))
  expect_true(all(1:3 %in% st[["studentized test"]]))
})

test_that("the nodewise options select different tuning rules; the default is \"ZnZ\"", {
  d <- sim_data(n = 60, p = 80, seed = 32)
  set.seed(3)
  cv <- Theta.hat(d$X, nodewise = "cv")
  set.seed(3)
  znz <- Theta.hat(d$X, nodewise = "ZnZ")
  expect_lte(attr(znz, "lambda"), attr(cv, "lambda"))
  set.seed(3)
  expect_identical(Theta.hat(d$X), znz)
  for (f in list(SR, ST, Sim.CI, Step, Theta.hat)) {
    expect_identical(eval(formals(f)$nodewise), c("ZnZ", "cv"))
  }
})

test_that("Theta.hat() records its nodewise rule; a different explicit nodewise warns", {
  d <- sim_data(n = 60, p = 80, seed = 32)
  set.seed(3)
  th <- Theta.hat(d$X, nodewise = "cv", center = TRUE)
  expect_identical(attr(th, "nodewise"), "cv")
  expect_null(attr(Theta.hat(d$X[, 1:20]), "nodewise"))
  calls <- list(
    SR = function(...) SR(d$X, d$Y, center = TRUE, Theta = th, ...),
    Sim.CI = function(...) Sim.CI(d$X, d$Y, 1:3, M = 20, center = TRUE, Theta = th, ...),
    Step = function(...) Step(d$X, d$Y, M = 20, center = TRUE, Theta = th, ...)
  )
  for (f in names(calls)) {
    set.seed(4)
    expect_warning(a <- calls[[f]](nodewise = "ZnZ"), "computed with nodewise = \"cv\"",
                   info = f)
    set.seed(4)
    expect_no_warning(b <- calls[[f]](nodewise = "cv"))
    set.seed(4)
    # The default is not flagged: the supplied Theta is used either way.
    expect_no_warning(cc <- calls[[f]]())
    expect_identical(a, b, info = f)
    expect_identical(b, cc, info = f)
  }
})

test_that("Step does not warn and keeps the RNG stream when all hypotheses are rejected", {
  withr::local_seed(8)
  X <- matrix(rnorm(1000), 100, 10)
  Y <- as.vector(X %*% rep(4, 10) + rnorm(100))
  set.seed(6)
  expect_silent(res <- Step(X, Y, M = 40))
  expect_identical(res[["non-studentized test"]], 1:10)
  expect_identical(res[["studentized test"]], 1:10)
})
