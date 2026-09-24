proj_data <- function(n = 60, p = 20, seed = 1) {
  withr::local_seed(seed)
  x <- matrix(rnorm(n * p), n, p)
  list(x = x, y = as.vector(x[, 1:2] %*% c(1.5, -1) + rnorm(n)))
}

test_that("lasso.proj returns hdi's fields in hdi's order plus SILM fields", {
  d <- proj_data()
  set.seed(1)
  fit <- lasso.proj(d$x, d$y)
  expect_s3_class(fit, c("silm_lasso_proj", "silm_proj"), exact = TRUE)
  expect_false(inherits(fit, "hdi"))
  expect_identical(names(fit)[1:13], c("pval", "pval.corr", "groupTest", "clusterGroupTest",
    "sigmahat", "standardize", "sds", "bhat", "se", "betahat", "family", "method", "call"))
  expect_null(fit$groupTest)
  expect_true(all(fit$pval[1:2] < 1e-4))
  expect_true(all(fit$pval.corr >= fit$pval))
  expect_equal(unname(fit$tstat), unname(fit$bhat / fit$se))
})

test_that("confint for lasso.proj is symmetric Gaussian and respects parm/level", {
  d <- proj_data(seed = 2)
  set.seed(2)
  fit <- lasso.proj(d$x, d$y)
  ci <- confint(fit)
  expect_equal(dim(ci), c(20, 2))
  expect_equal(unname(rowMeans(ci)), unname(fit$bhat))
  expect_equal(unname(ci[, 2] - ci[, 1]), unname(2 * qnorm(0.975) * fit$se))
  expect_equal(confint(fit, parm = 1:3), ci[1:3, ])
  expect_true(all(apply(confint(fit, level = 0.99), 1, diff) > apply(ci, 1, diff)))
  expect_error(confint(fit, parm = 21), "indices")
})

test_that("group-test draws are consumed unless suppressed", {
  d <- proj_data(seed = 3)
  s_default <- seed_after(4, lasso.proj(d$x, d$y, N = 500))
  s_manual <- seed_after(4, {
    lasso.proj(d$x, d$y, N = 500, suppress.grouptesting = TRUE)
    rnorm(500 * 20)
  })
  expect_identical(s_default, s_manual)
})

test_that("argument checks fail early with informative messages", {
  d <- proj_data()
  expect_error(lasso.proj(d$x, d$y, family = "poisson"), "family")
  expect_error(lasso.proj(d$x, d$y, multiplecorr.method = "xyz"), "multiple correction")
  expect_error(lasso.proj(d$x, d$y, betainit = rep(0, 20)), "sigma")
  expect_error(lasso.proj(d$x, d$y, betainit = "ridge"), "betainit")
  expect_error(lasso.proj(d$x[, 1:2], d$y), "at least 3 columns")
  expect_error(lasso.proj(d$x, d$y, Z = matrix(0, 3, 3)), "same dimension")
  x <- d$x
  x[, 4] <- 2
  expect_error(lasso.proj(x, d$y), "constant")
  expect_warning(
    expect_warning(lasso.proj(d$x * 3, d$y, betainit = rep(0, 20), sigma = 1,
                              suppress.grouptesting = TRUE), "Overriding"),
    "scaled design")
})

test_that("binomial: the corrected intercept removal is unbiased, legacy reproduces hdi", {
  skip_on_cran()
  withr::local_seed(11)
  n <- 1000
  x <- matrix(rnorm(n * 5), n, 5)
  y <- rbinom(n, 1, plogis(-2 + 1.5 * x[, 1]))
  mle <- unname(coef(glm(y ~ x, family = binomial))[2])
  fixed <- lasso.proj(x, y, family = "binomial", standardize = FALSE, suppress.grouptesting = TRUE)
  legacy <- suppressWarnings(lasso.proj(x, y, family = "binomial", standardize = FALSE,
                                        suppress.grouptesting = TRUE, legacy = TRUE))
  expect_lt(abs(fixed$bhat[[1]] - mle), 0.1)
  expect_gt(abs(legacy$bhat[[1]] - mle), 0.3)
  ci <- confint(fixed, parm = 1)
  expect_true(ci[1] < 1.5 && 1.5 < ci[2])
  # Logical and factor responses are accepted.
  set.seed(1)
  a <- lasso.proj(x, y == 1, family = "binomial", suppress.grouptesting = TRUE)
  set.seed(1)
  b <- lasso.proj(x, factor(y), family = "binomial", suppress.grouptesting = TRUE)
  expect_identical(a$bhat, b$bhat)
})
