test_that("ST rejects an impossible screening split before drawing the split", {
  withr::local_seed(29)
  x <- matrix(rnorm(40 * 3), 40, 3)
  y <- x[, 1] + rnorm(40)
  before <- .Random.seed
  for (sub.size in c(2, 2.9, 2 / 40)) {
    expect_error(ST(x, y, sub.size, 1:3, M = 5, center = TRUE),
                 "at least 3 observations for screening")
    expect_identical(.Random.seed, before)
  }
  expect_equal(SILM:::.st_subsample_size(3, 13), 3)
  set.seed(7)
  fit <- suppressWarnings(ST(x, y, 3, 1:3, M = 5, center = TRUE))
  expect_length(fit, 4)
  expect_true(all(is.finite(unlist(fit[c(1, 3)]))))
})

test_that("single-predictor Gaussian stubs retain bootstrap dimensions and values", {
  withr::local_seed(29)
  x <- matrix(rnorm(40), 40, 1, dimnames = list(NULL, "signal"))
  y <- 0.1 * x[, 1] + rnorm(40)
  z <- scale(x, scale = FALSE)
  for (B in c(2, 9)) {
    for (robust in c(FALSE, TRUE)) {
      set.seed(7)
      draws <- rnorm(B)
      draws0 <- rnorm(B)
      seed <- .Random.seed
      set.seed(7)
      fit <- suppressWarnings(boot.lasso.proj(x, y, standardize = FALSE,
        Z = z, betainit = 0, sigma = 1, B = B, robust = robust,
        gaussian.stub = TRUE, return.bootdist = TRUE, groups = 1))
      expect_identical(.Random.seed, seed)
      expect_equal(dim(fit$cboot.dist), c(1, B))
      expect_equal(dim(fit$cboot.dist.underH0c), c(1, B))
      expect_equal(as.vector(fit$cboot.dist / fit$se), draws)
      expect_equal(as.vector(fit$cboot.dist.underH0c / fit$se), draws0)
      expect_equal(fit$B.eff, B)
      statistic <- as.vector(fit$bhat / fit$se)
      count <- min(sum(draws <= statistic), sum(draws > statistic))
      expect_equal(unname(fit$pval), (2 * count + 1) / (B + 1))
      wy <- (sum(abs(draws0) >= abs(statistic)) + 1) / (B + 1)
      expect_equal(unname(fit$pval.corr), wy)
      expect_equal(groupTest(fit, 1), wy)
      quantiles <- quantile(draws * as.vector(fit$se), c(0.025, 0.975), names = FALSE)
      expect_equal(as.vector(confint(fit)), as.vector(fit$bhat) - rev(quantiles))
    }
  }
  set.seed(7)
  fit <- suppressWarnings(boot.lasso.proj(x, y, standardize = FALSE,
    Z = z, betainit = 0, sigma = 1, B = 9, gaussian.stub = TRUE,
    multiplecorr.method = "holm", return.bootdist = TRUE))
  expect_null(fit$cboot.dist.underH0c)
  expect_equal(unname(fit$pval.corr), unname(fit$pval))
})

test_that("Gaussian WY supports one Monte Carlo draw and one predictor", {
  withr::local_seed(29)
  for (p in c(1, 3)) {
    x <- matrix(rnorm(40 * p), 40, p)
    y <- x[, 1] + rnorm(40)
    z <- scale(x, scale = FALSE)
    # Reproduce the Gaussian null distribution directly on the score scale.
    scores <- sweep(z, 2, colSums(z^2) / nrow(z), "/")
    covariance <- crossprod(scores)
    for (N in c(1, 7)) {
      set.seed(7)
      draws <- matrix(MASS::mvrnorm(N, rep(0, p), covariance), nrow = N, ncol = p)
      null.p <- 2 * pnorm(abs(sweep(draws, 2, sqrt(diag(covariance)), "/")),
                          lower.tail = FALSE)
      minima <- apply(null.p, 1, min)
      seed <- .Random.seed
      set.seed(7)
      fit <- suppressWarnings(lasso.proj(x, y, standardize = FALSE, Z = scores,
        betainit = rep(0, p), sigma = 1, N = N, multiplecorr.method = "WY",
        suppress.grouptesting = TRUE))
      expect_identical(.Random.seed, seed)
      expect_equal(unname(fit$pval.corr), vapply(fit$pval, function(q) mean(minima <= q), 0))
    }
  }
})
