test_that("results reproduce the archived SILM 1.0.0 / hdi 0.1-10 / scalreg 1.0.1", {
  skip_on_cran()
  files <- fixture_files()
  expect_gt(length(files), 20)
  for (f in files) {
    fx <- readRDS(f)
    new <- run_fixture(fx)
    info <- paste("fixture", fx$id)
    old_value <- fx$value
    new_value <- new$value
    same <- same_platform(fx$fingerprint)
    if (!same && identical(fx$args$multiplecorr.method, "WY") && fx$fun == "lasso.proj") {
      # lasso.proj's WY adjustment simulates Gaussian vectors with
      # MASS::mvrnorm(), which depends on the eigenvectors computed by LAPACK:
      # exact only on the same platform; elsewhere agreement up to Monte Carlo
      # error (N = 2000 here).
      expect_equal(new_value$pval.corr, old_value$pval.corr, tolerance = 0.05, info = info)
      old_value$pval.corr <- new_value$pval.corr <- NULL
    }
    if (same) {
      expect_identical(new_value, old_value, info = info)
    } else {
      expect_equal(new_value, old_value, tolerance = 1e-8, info = info)
    }
    # The random number stream is consumed identically on every platform.
    # (.Random.seed[1] encodes the RNG kinds; R-devel changed its encoding,
    # so only the generator state is compared.)
    expect_identical(new$seed_after[-1], fx$seed_after[-1], info = info)
  }
})

test_that("the default nodewise reproduces SILM 1.0.0 as installed 2019-2026 (hdi 0.1-10)", {
  skip_on_cran()
  files <- grep("-znz\\.rds$", fixture_files(), value = TRUE)
  expect_length(files, 8)
  for (f in files) {
    fx <- readRDS(f)
    fx$new_args$nodewise <- NULL
    new <- run_fixture(fx)
    info <- paste("fixture", fx$id, "with the default nodewise")
    if (same_platform(fx$fingerprint)) {
      expect_identical(new$value, fx$value, info = info)
    } else {
      expect_equal(new$value, fx$value, tolerance = 1e-8, info = info)
    }
    expect_identical(new$seed_after[-1], fx$seed_after[-1], info = info)
  }
})
