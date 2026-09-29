# The first two coefficients deliberately have the same label and opposite
# signs. Supplied initial estimates and nodewise residuals isolate interval
# extraction from tuning and numerical convergence.
indexing_fits <- function(groups = NULL) {
  withr::local_seed(701)
  x <- scale(matrix(rnorm(60 * 4), 60, 4), scale = FALSE)
  colnames(x) <- c("same", "same", "third", "fourth")
  beta <- c(2, -3, 0, 0)
  y <- as.vector(x %*% beta + rnorm(60))
  args <- list(x = x, y = y, standardize = FALSE, Z = x, betainit = beta, sigma = 1)
  list(
    lasso = suppressWarnings(do.call(lasso.proj, c(args, list(suppress.grouptesting = TRUE)))),
    boot = suppressWarnings(do.call(boot.lasso.proj, c(args, list(
      gaussian.stub = TRUE, B = 200, wild = TRUE, return.bootdist = TRUE, groups = groups))))
  )
}

test_that("individual intervals preserve positions with duplicated predictor names", {
  fits <- indexing_fits()
  for (fit in fits) {
    expected <- if (fit$method == "lasso.proj") {
      cbind(lower = fit$bhat - qnorm(0.975) * fit$se,
            upper = fit$bhat + qnorm(0.975) * fit$se)
    } else {
      q <- apply(fit$cboot.dist, 1, quantile, probs = c(0.025, 0.975), type = 7)
      cbind(lower = fit$bhat - q[2, ], upper = fit$bhat - q[1, ])
    }
    expect_gt(expected[1, "lower"], 0)
    expect_lt(expected[2, "upper"], 0)
    expect_equal(confint(fit), expected)
    expect_equal(confint(fit, parm = 2), expected[2, , drop = FALSE])
    expect_equal(confint(fit, parm = c(2, 1, 2)), expected[c(2, 1, 2), , drop = FALSE])
    expect_equal(confint(fit, parm = c(-1, -3, -4)), expected[2, , drop = FALSE])
    # Retain the documented R subsetting conventions for zero and truncation.
    expect_equal(confint(fit, parm = c(0, 2.8, 1)), expected[c(2, 1), , drop = FALSE])
    expect_equal(confint(fit, parm = "third"), expected[3, , drop = FALSE])
    expect_error(confint(fit, parm = "same"), "Ambiguous.*'parm'.*numeric indices")
  }
})

test_that("simultaneous intervals and their groups preserve coefficient positions", {
  fit <- indexing_fits()$boot
  for (stat in c("maxmin", "abs")) {
    ci <- function(...) suppressWarnings(confint(fit, type = "simultaneous",
                                                 simult.stat = stat, ...))
    for (G in list(1:4, 1:3, 2L)) {
      T <- fit$cboot.dist[G, , drop = FALSE] / fit$se[G]
      if (stat == "maxmin") {
        lo <- quantile(apply(T, 2, min), 0.025, names = FALSE)
        hi <- quantile(apply(T, 2, max), 0.975, names = FALSE)
      } else {
        hi <- quantile(apply(abs(T), 2, max), 0.95, names = FALSE)
        lo <- -hi
      }
      expected <- cbind(lower = fit$bhat[G] - fit$se[G] * hi,
                        upper = fit$bhat[G] - fit$se[G] * lo)
      actual <- ci(group = G)
      expect_equal(actual[, , drop = FALSE], expected)
      expect_identical(attr(actual, "simultaneous")$group, G)
      idx <- rev(G)
      reordered <- ci(parm = idx, group = G)
      expect_equal(reordered[, , drop = FALSE], expected[rev(seq_along(G)), , drop = FALSE])
    }
    # Missing parm, explicit numeric parm, and exclusion select the same
    # coefficients even when the output has repeated row labels.
    expect_identical(ci(), ci(parm = 1:4))
    expect_identical(ci(parm = c(-1, -3, -4)), ci(parm = 2))
    expect_identical(ci(parm = 2, group = 2), ci(parm = 2))
    expect_identical(ci(parm = "third"), ci(parm = 3))
    expect_error(ci(parm = "same"), "Ambiguous.*'parm'.*numeric indices")
    expect_error(ci(group = "same"), "Ambiguous.*'group'.*numeric indices")
    expect_error(ci(parm = 2, group = 1), "must be contained")
  }
})

test_that("group APIs require unambiguous names and accept numeric duplicate-label positions", {
  fit <- indexing_fits()$boot
  expected <- (sum(abs(fit$cboot.dist.underH0c[2, ] / fit$se[2]) >= abs(fit$tstat[2])) + 1) /
    (fit$B.eff + 1)
  expect_equal(groupTest(fit, group = 2), unname(expected))
  expect_equal(groupTest(fit, group = "third"), groupTest(fit, group = 3))
  expect_error(groupTest(fit, group = "same"), "Ambiguous.*'group'.*numeric indices")
  expect_error(indexing_fits(groups = list("same")),
               "Ambiguous.*'groups'.*numeric indices")
})

test_that("unambiguous coefficient names retain order and allow repeated selection", {
  for (fit in indexing_fits()) {
    pn <- c("first", "second", "third", "fourth")
    names(fit$bhat) <- names(fit$se) <- pn
    if (!is.null(fit$cboot.dist)) rownames(fit$cboot.dist) <- pn
    expect_identical(confint(fit, parm = c("second", "first", "second")),
                     confint(fit, parm = c(2, 1, 2)))
    if (fit$method == "boot.lasso.proj") {
      ci <- function(...) suppressWarnings(confint(fit, type = "simultaneous", ...))
      expect_identical(ci(parm = "second", group = c("first", "second")),
                       ci(parm = 2, group = 1:2))
    }
  }
})

test_that("printing duplicate predictor names disambiguates labels without changing the fit", {
  for (fit in indexing_fits()) {
    original <- fit
    out <- capture.output(ret <- print(fit))
    expect_identical(ret, original)
    expect_identical(fit, original)
    expect_match(paste(out, collapse = "\n"), "same.1", fixed = TRUE)
    expect_match(paste(out, collapse = "\n"), "-2.814", fixed = TRUE)
  }
})

test_that("invalid confidence levels and empty coefficient selections give clear errors", {
  fit <- indexing_fits()$lasso
  for (level in list(NA_real_, NaN, Inf, 0, 1, numeric(), c(0.9, 0.95), 0.95 + 0i)) {
    expect_error(confint(fit, level = level), "'level' must be a number between 0 and 1")
  }
  expect_error(confint(fit, parm = character()), "'parm'")
  expect_error(confint(fit, parm = numeric()), "'parm'")
})
