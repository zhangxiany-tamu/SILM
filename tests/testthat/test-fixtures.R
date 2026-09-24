test_that("results reproduce the archived SILM 1.0.0 / hdi 0.1-10 / scalreg 1.0.1", {
  skip_on_cran()
  files <- fixture_files()
  expect_gt(length(files), 20)
  for (f in files) {
    fx <- readRDS(f)
    new <- run_fixture(fx)
    info <- paste("fixture", fx$id)
    if (same_platform(fx$fingerprint)) {
      expect_identical(new$value, fx$value, info = info)
    } else {
      expect_equal(new$value, fx$value, tolerance = 1e-8, info = info)
    }
    # The random number stream is consumed identically on every platform.
    expect_identical(new$seed_after, fx$seed_after, info = info)
  }
})
