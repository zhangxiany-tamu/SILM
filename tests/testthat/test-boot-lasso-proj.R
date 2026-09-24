boot_data <- function(n = 50, p = 15, seed = 1) {
  withr::local_seed(seed)
  x <- matrix(rnorm(n * p), n, p)
  list(x = x, y = as.vector(x[, 1] + rnorm(n)))
}

test_that("boot.lasso.proj returns hdi's fields in order, plus summaries", {
  d <- boot_data()
  set.seed(1)
  fit <- boot.lasso.proj(d$x, d$y, B = 30, boot.shortcut = TRUE, return.bootdist = TRUE)
  expect_s3_class(fit, "silm_boot_lasso_proj")
  expect_identical(names(fit)[1:16], c("pval", "pval.corr", "sigmahat", "standardize", "sds",
    "bhat", "se", "betahat", "family", "method", "B", "boot.shortcut", "lambda", "call",
    "cboot.dist", "cboot.dist.underH0c"))
  expect_equal(dim(fit$cboot.dist), c(15, 30))
  expect_length(fit$boot.summary$absmax.H0c, 30)
  # The WY p-values are the H0c max-T p-values.
  wy <- (vapply(abs(fit$tstat), function(t) sum(fit$boot.summary$absmax.H0c >= t), 0) + 1) / 31
  expect_equal(unname(fit$pval.corr), unname(wy))
  # p-values lie on the grid k / (B + 1).
  expect_true(all(abs(fit$pval * 31 - round(fit$pval * 31)) < 1e-9))
})

test_that("bootstrap confidence intervals follow hdi's definition", {
  d <- boot_data(seed = 2)
  set.seed(2)
  fit <- suppressWarnings(boot.lasso.proj(d$x, d$y, B = 40, boot.shortcut = TRUE,
                                          return.bootdist = TRUE, multiplecorr.method = "holm"))
  ci <- confint(fit, parm = 1:2, level = 0.9)
  q <- apply(fit$cboot.dist[1:2, ], 1, quantile, probs = c(0.05, 0.95))
  expect_equal(unname(ci[, "lower"]), unname(fit$bhat[1:2] - q[2, ]))
  expect_equal(unname(ci[, "upper"]), unname(fit$bhat[1:2] - q[1, ]))
  expect_warning(fit2 <- boot.lasso.proj(d$x, d$y, B = 20, boot.shortcut = TRUE,
                                         multiplecorr.method = "holm"), "Lacking accuracy")
  expect_error(confint(fit2), "return.bootdist")
})

test_that("argument checks", {
  d <- boot_data()
  expect_error(boot.lasso.proj(d$x, d$y, family = "binomial"), "not supporting")
  expect_error(boot.lasso.proj(d$x, d$y, betainit = rep(0, 15), sigma = 1), "bootstrap")
  expect_error(boot.lasso.proj(d$x, d$y, B = 1), "'B'")
  expect_warning(boot.lasso.proj(d$x, d$y, B = 5, betainit = "scaled lasso", boot.shortcut = TRUE,
                                 multiplecorr.method = "WY"), "no effect")
})

test_that("parallel bootstrap equals the sequential one", {
  skip_on_os("windows")
  skip_on_cran()
  d <- boot_data(seed = 3)
  set.seed(5)
  a <- boot.lasso.proj(d$x, d$y, B = 20, return.bootdist = TRUE)
  set.seed(5)
  b <- boot.lasso.proj(d$x, d$y, B = 20, return.bootdist = TRUE, parallel = TRUE, ncores = 2)
  a$call <- b$call <- NULL
  expect_identical(a, b)
})

test_that("print shows the settings and returns the object invisibly", {
  d <- boot_data(seed = 4)
  set.seed(4)
  fit <- boot.lasso.proj(d$x, d$y, B = 20, boot.shortcut = TRUE, robust = TRUE, wild = TRUE)
  out <- capture.output(res <- print(fit))
  expect_identical(res, fit)
  expect_true(any(grepl("wild \\(gaussian multipliers\\)", out)))
  expect_true(any(grepl("robust standard errors", out)))
})
