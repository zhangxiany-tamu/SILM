# hdi's own regression-test values for lasso.proj() (the paper's "original"
# de-sparsified lasso), reproduced with SILM.
#
# Source: tests/test-lasso.R in the archived hdi_0.1-10.tar.gz (development
# cache, archive/). With x = riboflavin design, y = riboflavin response and
# x.use = x[, 1:16] (the non-interactive branch, p. = 16), hdi runs
#   suppressWarnings(RNGversion("3.5.0")); set.seed(3); fit.lasso  <- lasso.proj(x.use, y)
#   suppressWarnings(RNGversion("3.5.0")); set.seed(3); fit.lasso2 <- lasso.proj(2 + 4 * x.use, y)
# and checks with stopifnot(all.equal(...)):
#   (1) pval equal for x and 2 + 4 x (default tolerance 1.5e-8),
#   (2) range(bhat / bhat2 - 4) equal to c(0, 0) (absolute, 1.5e-8),
#   (3) confint(fit.lasso) equal to 4 * confint(fit.lasso2) (1.5e-8),
#   (4) bhat equal to 16 hard-coded values (tol = 4e-7),
#   (5) confint(level = 0.95) equal to a hard-coded 16 x 2 matrix (tol = 5e-5).
# all.equal() on numbers uses the mean relative difference
# mean(|target - current|) / mean(|target|) (absolute if mean(|target|) is
# below the tolerance); a check passes if it is <= the tolerance. hdi also
# refits with parallel = TRUE without checking the result; SILM documents
# that parallel fits equal sequential ones, so we add that check (6).

source(file.path("replication", "common.R")); load_silm()
source(file.path("replication", "dbz_targets.R"))

id <- "dbz_hdi_reference"
target <- "hdi 0.1-10 tests/test-lasso.R reference values (riboflavin[, 1:16], seed 3)"

rb <- load_riboflavin()
x.use <- rb$x[, 1:16]
y <- rb$y

ref_bhat <- c(0.54650099, -0.64364814, 0.079821945, 0.26406221, -0.21405501,
              -0.63576549, -0.095448048, 0.40801737, -1.2194818, -0.11113313,
              0.3474404, 1.1425587, -0.54460967, 0.45298509, -0.31922868, 0.42184791)
ref_ci <- matrix(c(-0.186587, -1.88574, -1.03822, -0.274364, -0.808168, -1.30643,
                   -0.994648, -0.446016, -2.29657, -1.23525, -0.728214, 0.256838,
                   -1.297,    -0.416467, -1.16564, -0.593977, 1.27959, 0.598448,
                   1.19786,   0.802489, 0.380058, 0.0348979, 0.803752, 1.26205,
                   -0.142394, 1.01298,  1.42309, 2.02828, 0.207783, 1.32244,
                   0.527183, 1.43767), 16, 2)

# Fit with hdi's random number generator settings, then restore the default.
fit_seed3 <- function(xx, ...) {
  suppressWarnings(RNGversion("3.5.0"))
  on.exit(RNGversion(as.character(getRversion())), add = TRUE)
  set.seed(3)
  lasso.proj(x = xx, y = y, ...)
}
fit1 <- fit_seed3(x.use)
fit2 <- fit_seed3(2 + 4 * x.use)
fit_par <- fit_seed3(x.use, parallel = TRUE, ncores = 2L)
ci1 <- confint(fit1, level = 0.95)
ci2 <- confint(fit2, level = 0.95)

# all.equal.numeric's statistic (see header).
all_equal_stat <- function(target, current, tolerance = 1.5e-8) {
  target <- as.vector(target)
  current <- as.vector(current)
  xy <- mean(abs(target - current))
  xn <- mean(abs(target))
  if (is.finite(xn) && xn > tolerance) xy / xn else xy
}
check <- function(what, target_v, current_v, tolerance, note) {
  st <- all_equal_stat(target_v, current_v, tolerance)
  agree <- isTRUE(all.equal(as.vector(target_v), as.vector(current_v), tolerance = tolerance))
  criterion_row(target, "riboflavin[, 1:16]", what, 0, st, NA, tolerance, st <= tolerance && agree,
                note)
}

rows <- list(
  check("(1) pval invariant to x -> 2 + 4x", fit1$pval, fit2$pval, 1.5e-8,
        "all.equal(fit.lasso$pval, fit.lasso2$pval)"),
  check("(2) bhat / bhat(2 + 4x) - 4 (range)", c(0, 0), range(fit1$bhat / fit2$bhat - 4), 1.5e-8,
        "all.equal(c(0,0), range(fit.lasso$bhat / fit.lasso2$bhat - 4)) (absolute difference)"),
  check("(3) CI(x) = 4 CI(2 + 4x)", ci1, ci2 * 4, 1.5e-8, "all.equal(ci.lasso, ci.lasso2 * 4)"),
  check("(4) bhat vs hard-coded reference", ref_bhat, fit1$bhat, 4e-7,
        "hdi test tolerance tol = 4e-7 ('# 1e-8' in the test file)"),
  check("(5) 95% CI vs hard-coded reference", ref_ci, unname(ci1), 5e-5,
        "hdi test tolerance tol = 5e-5"),
  check("(6) parallel fit = sequential fit (pval, bhat, se)", c(fit1$pval, fit1$bhat, fit1$se),
        c(fit_par$pval, fit_par$bhat, fit_par$se), 1.5e-8,
        "SILM addition: hdi refits with parallel = TRUE but does not check the result"))

summaries <- list(bhat = fit1$bhat, ref_bhat = ref_bhat, ci = ci1, ref_ci = ref_ci,
                  max_abs_diff = c(bhat = max(abs(fit1$bhat - ref_bhat)),
                                   ci = max(abs(unname(ci1) - ref_ci))),
                  rng = "RNGversion('3.5.0') (sample.kind = 'Rounding'), set.seed(3)")
save_criteria(id, criteria = do.call(rbind, rows), summaries = summaries)
