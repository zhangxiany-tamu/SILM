# Settings and published results for the replication of
#   Zhang, X. and Cheng, G. (2017). Simultaneous inference for high-dimensional
#   linear models. Journal of the American Statistical Association 112, 757-768.
#
# Source of every number below: arXiv:1603.01295v1 (the only arXiv version;
# manuscript dated 24 Feb 2016, posted 3 Mar 2016, "to appear in JASA").
# The published JASA version could not be accessed (the publisher returned
# HTTP 403), so the arXiv tables are used; they may differ slightly from the
# published ones. Page numbers refer to the arXiv PDF: Section 5 is on
# pp. 21-26, Tables 1-5 on pp. 31-35.
#
# This file is sourced by replication/zc_simci.R, zc_sr.R, zc_st.R and
# zc_step.R (after replication/common.R). Besides the list `zc_targets` it
# defines the shared data generators (fixed designs, coefficients, errors),
# the seeds, the comparison helpers (including the range rule for
# draw-dependent numbers) and the report tags, so that all four scripts use
# the same fixed designs. Criteria: replication/CRITERIA.md (Part 1).

# Single-threaded BLAS: this machine's OpenBLAS uses OpenMP, whose thread pool
# does not survive fork(), so mclapply() children deadlock after the parent's
# first multi-threaded BLAS call. The thread count is read when R starts (the
# Sys.setenv() in common.R is too late), so run the zc_* scripts through
# replication/run.R, which starts each script with OMP_NUM_THREADS=1 and
# OPENBLAS_NUM_THREADS=1, or set both variables before calling Rscript.

# ---------------------------------------------------------------------------
# Settings (Section 5, pp. 21-26)
# ---------------------------------------------------------------------------

zc_settings <- list(
  n = 100L,               # p. 21: "sample size n = 100"
  R_paper = 1000L,        # p. 21 and every table note: 1,000 simulation runs
  # Our replication counts (multiplied by SILM_REP_SCALE in run_reps()).
  # Table 4 (ST) is reduced to 500: each replication needs a nodewise lasso on
  # the second sub-sample for each of 3 models x 2 error laws (about 12 s each).
  # `sens` is the count per variant of the draw-sensitivity runs (below).
  R = c(simci = 1000L, sr = 1000L, st = 500L, step = 1000L, sens = 200L),
  # Draw sensitivity: results that depend on the single unknown draw of beta
  # (or of the support) behind the paper's numbers are also computed for
  # draws 2..K_draws and for a variant that redraws beta in every run.
  K_draws = 5L,
  M = 500L,               # bootstrap draws: NOT stated in the paper; SILM default
  nodewise = "cv",        # p. 21: lambda_j by 10-fold CV pooled over all nodewise regressions
  levels_ci = c(0.95, 0.99),   # Tables 1-2: confidence levels
  alphas_st = c(0.05, 0.01),   # Table 4: nominal levels
  alpha_step = 0.05            # Table 5: nominal FWER
)
# Initial estimator: scaled lasso with lambda_0 = sqrt(2) L_n(k0/p) and the
# modified variance estimator sigma^2 = ||Y - X b||^2 / (n - ||b||_0), eq. (24)
# (pp. 21-22). Both are what SILM implements; nothing to set here.

# Fixed designs. Section 5.1 (p. 21): "the rows of X are fixed i.i.d.
# realizations from N_p(0, Sigma)". Section 5.2 uses "the simulation setup in
# Section 5.1", Section 5.4 "the linear model considered in Section 5.1", so
# ONE realization of X per (p, Sigma) is shared by all tables, all s0 and both
# error laws (the paper's widths are practically identical across error laws,
# which indicates a common X). Section 5.3 does not say; the same X is used.
#   (i)  Toeplitz      Sigma_ij = 0.9^|i-j|                         (5.1, 5.3, 5.4)
#   (ii) exchangeable  Sigma_ii = 1, Sigma_ij = 0.8                 (5.1, 5.2, 5.3)
#   (ii) block (5.4)   blocks of 5 with within-block correlation 0.9 (p. 25)
# X is used as generated (no centring or scaling): the model has no intercept
# and the rows are mean-zero Gaussian.
zc_designs <- list(
  T120 = list(p = 120L, cov = "toeplitz", rho = 0.9, seed = 20170101L),
  E120 = list(p = 120L, cov = "exchangeable", rho = 0.8, seed = 20170102L),
  T500 = list(p = 500L, cov = "toeplitz", rho = 0.9, seed = 20170103L),
  E500 = list(p = 500L, cov = "exchangeable", rho = 0.8, seed = 20170104L),
  B500 = list(p = 500L, cov = "block", rho = 0.9, block = 5L, seed = 20170105L)
)

# Screening in Section 5.3 (p. 25): with the lasso-plus-residual remedy, all
# three relevant variables are kept "with probability 0.98", against 0.59 for
# plain marginal screening (case (ii), s0 = 3; error law not stated).
zc_screening <- list(remedy = 0.98, marginal = 0.59)

# ---------------------------------------------------------------------------
# Published tables
# ---------------------------------------------------------------------------

# Tables 1 and 2 (pp. 31-32): coverage ("Cov") and width ("Len") of the
# simultaneous intervals. Columns, left to right: case (i) Toeplitz then
# (ii) exchangeable; within a case G = S0, S0^c, [p] ("all"); within G the
# levels 95% and 99%. Rows: p = 120 then 500; t(4)/sqrt(2) then Gamma;
# NST, ST, EX (EX = studentized statistic with the Gumbel approximation of
# Remark 2.4; NA for G = S0). ST/EX widths are averages over components.
.zc_ci_cols <- expand.grid(level = c(0.95, 0.99), set = c("S0", "S0c", "all"),
                           case = c("i", "ii"), stringsAsFactors = FALSE)
.zc_ci_row <- function(p, err, method, metric, v) {
  stopifnot(length(v) == nrow(.zc_ci_cols))
  data.frame(p = p, err = err, method = method, metric = metric, .zc_ci_cols,
             paper = v, stringsAsFactors = FALSE)
}

# Table 3 (p. 33): mean and SD of d(S0hat, S0), mean false positives (FP) and
# false negatives (FN), for s0 = 3 and s0 = 15. SILM computes "SupRec" (SR()
# component "de-biased Lasso") and "Lassosc" (SR() component "scaled Lasso");
# Stability selection and screen-and-clean ("S&C") are listed for completeness
# only (not in SILM, not replicated).
.zc_sr_row <- function(p, cov, err, method, s3, s15) {
  stopifnot(length(s3) == 4L, length(s15) == 4L)
  data.frame(p = p, cov = cov, err = err, method = method, s0 = c(3L, 15L),
             mean = c(s3[1], s15[1]), sd = c(s3[2], s15[2]), fp = c(s3[3], s15[3]),
             fn = c(s3[4], s15[4]), stringsAsFactors = FALSE)
}

# Table 4 (p. 34): empirical size (G without signals) and power. Columns:
# one-step then three-step procedure; within each t(4)/sqrt(2) then Gamma;
# within each NST then ST. Test sets: "S0c" = {4..p} (s0 = 3), "S0tc" =
# {16..p} (s0 = 15, S0tilde = {1..15}), "3+S0c" = {3} u S0c, "23+S0c" =
# {2,3} u S0c, "15+S0tc" = {15} u S0tilde^c, "1415+S0tc" = {14,15} u S0tilde^c.
.zc_st_cols <- expand.grid(stat = c("NST", "ST"), err = c("t", "gamma"),
                           procedure = c("one-step", "three-step"), stringsAsFactors = FALSE)
.zc_st_row <- function(case, set, alpha, v) {
  stopifnot(length(v) == nrow(.zc_st_cols))
  data.frame(case = case, set = set, alpha = alpha, .zc_st_cols, paper = v,
             stringsAsFactors = FALSE)
}
# First index of each test set G = {first, ..., p}, and the model's s0.
zc_st_sets <- data.frame(
  set = c("S0c", "3+S0c", "23+S0c", "S0tc", "15+S0tc", "1415+S0tc"),
  first = c(4L, 3L, 2L, 16L, 15L, 14L),
  s0 = c(3L, 3L, 3L, 15L, 15L, 15L),
  kind = c("size", "power", "power", "size", "power", "power"),
  stringsAsFactors = FALSE
)

# Table 5 (p. 35): FWER and average power of the step-down method (NST, ST)
# and of Bonferroni-Holm on the studentized statistic ("BH"); p = 500,
# nominal level 5%. Columns: s0 = 3 (i), s0 = 15 (i), s0 = 3 (ii), s0 = 15 (ii)
# with (i) Toeplitz and (ii) block diagonal; within each FWER then Power.
.zc_step_cols <- expand.grid(metric = c("FWER", "Power"), s0 = c(3L, 15L), case = c("i", "ii"),
                             stringsAsFactors = FALSE)
.zc_step_row <- function(err, method, v) {
  stopifnot(length(v) == nrow(.zc_step_cols))
  data.frame(err = err, method = method, .zc_step_cols, paper = v, stringsAsFactors = FALSE)
}

zc_targets <- list(
  source = paste("Zhang and Cheng (2017), JASA 112:757-768; numbers from arXiv:1603.01295v1",
                 "(Section 5, Tables 1-5); JASA version not accessible"),
  settings = zc_settings,
  designs = zc_designs,
  screening = zc_screening,

  # Table 1 (p. 31): S0 = {1, 2, 3}, p = 120 and 500.
  table1 = rbind(
    # p = 120, t(4)/sqrt(2)
    .zc_ci_row(120, "t", "NST", "Cov", c(0.82, 0.94, 0.97, 0.99, 0.95, 0.99, 0.91, 0.97, 0.93, 0.98, 0.93, 0.98)),
    .zc_ci_row(120, "t", "NST", "Len", c(0.99, 1.22, 1.49, 1.67, 1.50, 1.67, 0.97, 1.18, 1.49, 1.67, 1.49, 1.67)),
    .zc_ci_row(120, "t", "ST", "Cov", c(0.82, 0.93, 0.97, 0.99, 0.96, 0.99, 0.92, 0.97, 0.92, 0.98, 0.92, 0.98)),
    .zc_ci_row(120, "t", "ST", "Len", c(0.97, 1.19, 1.48, 1.64, 1.48, 1.64, 0.96, 1.18, 1.46, 1.62, 1.46, 1.63)),
    .zc_ci_row(120, "t", "EX", "Cov", c(NA, NA, 0.98, 1.00, 0.97, 0.99, NA, NA, 0.94, 0.98, 0.93, 0.98)),
    .zc_ci_row(120, "t", "EX", "Len", c(NA, NA, 1.51, 1.69, 1.51, 1.69, NA, NA, 1.49, 1.66, 1.49, 1.67)),
    # p = 120, Gamma
    .zc_ci_row(120, "gamma", "NST", "Cov", c(0.84, 0.93, 0.96, 0.99, 0.94, 0.98, 0.91, 0.97, 0.93, 0.98, 0.93, 0.98)),
    .zc_ci_row(120, "gamma", "NST", "Len", c(0.99, 1.22, 1.50, 1.67, 1.50, 1.67, 0.97, 1.18, 1.50, 1.68, 1.50, 1.68)),
    .zc_ci_row(120, "gamma", "ST", "Cov", c(0.82, 0.92, 0.97, 0.99, 0.95, 0.98, 0.90, 0.97, 0.92, 0.98, 0.92, 0.98)),
    .zc_ci_row(120, "gamma", "ST", "Len", c(0.97, 1.19, 1.48, 1.65, 1.48, 1.65, 0.97, 1.18, 1.46, 1.63, 1.46, 1.63)),
    .zc_ci_row(120, "gamma", "EX", "Cov", c(NA, NA, 0.97, 0.99, 0.96, 0.99, NA, NA, 0.93, 0.99, 0.93, 0.99)),
    .zc_ci_row(120, "gamma", "EX", "Len", c(NA, NA, 1.51, 1.69, 1.51, 1.69, NA, NA, 1.49, 1.67, 1.49, 1.67)),
    # p = 500, t(4)/sqrt(2)
    .zc_ci_row(500, "t", "NST", "Cov", c(0.76, 0.90, 0.96, 0.99, 0.94, 0.98, 0.92, 0.98, 0.92, 0.97, 0.92, 0.97)),
    .zc_ci_row(500, "t", "NST", "Len", c(0.89, 1.09, 1.47, 1.62, 1.47, 1.62, 0.97, 1.19, 1.65, 1.82, 1.65, 1.82)),
    .zc_ci_row(500, "t", "ST", "Cov", c(0.77, 0.90, 0.97, 0.99, 0.95, 0.98, 0.92, 0.97, 0.92, 0.97, 0.91, 0.97)),
    .zc_ci_row(500, "t", "ST", "Len", c(0.88, 1.08, 1.46, 1.60, 1.46, 1.60, 0.97, 1.18, 1.62, 1.77, 1.62, 1.77)),
    .zc_ci_row(500, "t", "EX", "Cov", c(NA, NA, 0.98, 0.99, 0.96, 0.98, NA, NA, 0.92, 0.97, 0.92, 0.97)),
    .zc_ci_row(500, "t", "EX", "Len", c(NA, NA, 1.48, 1.63, 1.48, 1.63, NA, NA, 1.64, 1.81, 1.64, 1.81)),
    # p = 500, Gamma
    .zc_ci_row(500, "gamma", "NST", "Cov", c(0.77, 0.90, 0.98, 0.99, 0.96, 0.98, 0.91, 0.97, 0.95, 0.98, 0.94, 0.98)),
    .zc_ci_row(500, "gamma", "NST", "Len", c(0.90, 1.10, 1.49, 1.63, 1.49, 1.64, 0.98, 1.19, 1.66, 1.83, 1.66, 1.83)),
    .zc_ci_row(500, "gamma", "ST", "Cov", c(0.77, 0.90, 0.98, 0.99, 0.96, 0.98, 0.90, 0.97, 0.93, 0.97, 0.93, 0.97)),
    .zc_ci_row(500, "gamma", "ST", "Len", c(0.89, 1.09, 1.47, 1.61, 1.47, 1.61, 0.97, 1.19, 1.63, 1.78, 1.63, 1.78)),
    .zc_ci_row(500, "gamma", "EX", "Cov", c(NA, NA, 0.98, 1.00, 0.96, 0.99, NA, NA, 0.94, 0.98, 0.94, 0.98)),
    .zc_ci_row(500, "gamma", "EX", "Len", c(NA, NA, 1.49, 1.64, 1.49, 1.64, NA, NA, 1.65, 1.82, 1.65, 1.82))
  ),

  # Table 2 (p. 32): S0 = {1, ..., 15}, p = 120 and 500. Same layout.
  table2 = rbind(
    # p = 120, t(4)/sqrt(2)
    .zc_ci_row(120, "t", "NST", "Cov", c(0.68, 0.87, 0.99, 1.00, 0.87, 0.95, 0.73, 0.88, 0.92, 0.98, 0.89, 0.96)),
    .zc_ci_row(120, "t", "NST", "Len", c(1.44, 1.73, 1.68, 1.92, 1.72, 1.97, 1.27, 1.48, 1.67, 1.90, 1.67, 1.91)),
    .zc_ci_row(120, "t", "ST", "Cov", c(0.50, 0.70, 0.99, 1.00, 0.75, 0.85, 0.68, 0.84, 0.83, 0.92, 0.74, 0.88)),
    .zc_ci_row(120, "t", "ST", "Len", c(1.30, 1.50, 1.55, 1.73, 1.56, 1.74, 1.23, 1.42, 1.53, 1.70, 1.53, 1.71)),
    .zc_ci_row(120, "t", "EX", "Cov", c(NA, NA, 0.99, 1.00, 0.77, 0.88, NA, NA, 0.85, 0.94, 0.77, 0.92)),
    .zc_ci_row(120, "t", "EX", "Len", c(NA, NA, 1.58, 1.77, 1.59, 1.78, NA, NA, 1.55, 1.74, 1.56, 1.75)),
    # p = 120, Gamma
    .zc_ci_row(120, "gamma", "NST", "Cov", c(0.69, 0.88, 0.99, 1.00, 0.86, 0.95, 0.77, 0.90, 0.93, 0.98, 0.90, 0.97)),
    .zc_ci_row(120, "gamma", "NST", "Len", c(1.44, 1.74, 1.69, 1.93, 1.72, 1.97, 1.27, 1.49, 1.68, 1.91, 1.68, 1.92)),
    .zc_ci_row(120, "gamma", "ST", "Cov", c(0.52, 0.70, 0.99, 1.00, 0.74, 0.86, 0.71, 0.87, 0.85, 0.94, 0.78, 0.91)),
    .zc_ci_row(120, "gamma", "ST", "Len", c(1.30, 1.51, 1.55, 1.73, 1.57, 1.75, 1.24, 1.43, 1.53, 1.71, 1.54, 1.71)),
    .zc_ci_row(120, "gamma", "EX", "Cov", c(NA, NA, 0.99, 1.00, 0.77, 0.88, NA, NA, 0.87, 0.96, 0.81, 0.94)),
    .zc_ci_row(120, "gamma", "EX", "Len", c(NA, NA, 1.59, 1.78, 1.60, 1.79, NA, NA, 1.56, 1.75, 1.57, 1.76)),
    # p = 500, t(4)/sqrt(2)
    .zc_ci_row(500, "t", "NST", "Cov", c(0.56, 0.82, 0.99, 1.00, 0.86, 0.95, 0.36, 0.57, 0.93, 0.98, 0.81, 0.94)),
    .zc_ci_row(500, "t", "NST", "Len", c(1.35, 1.65, 1.74, 1.95, 1.75, 1.97, 1.32, 1.55, 2.01, 2.38, 2.01, 2.38)),
    .zc_ci_row(500, "t", "ST", "Cov", c(0.34, 0.57, 0.99, 1.00, 0.76, 0.86, 0.35, 0.55, 0.61, 0.77, 0.49, 0.66)),
    .zc_ci_row(500, "t", "ST", "Len", c(1.22, 1.40, 1.58, 1.73, 1.59, 1.74, 1.28, 1.48, 1.71, 1.87, 1.71, 1.87)),
    .zc_ci_row(500, "t", "EX", "Cov", c(NA, NA, 0.99, 1.00, 0.78, 0.87, NA, NA, 0.65, 0.81, 0.53, 0.70)),
    .zc_ci_row(500, "t", "EX", "Len", c(NA, NA, 1.61, 1.77, 1.61, 1.77, NA, NA, 1.73, 1.90, 1.73, 1.91)),
    # p = 500, Gamma
    .zc_ci_row(500, "gamma", "NST", "Cov", c(0.52, 0.80, 1.00, 1.00, 0.86, 0.95, 0.38, 0.57, 0.94, 0.99, 0.83, 0.96)),
    .zc_ci_row(500, "gamma", "NST", "Len", c(1.36, 1.66, 1.75, 1.96, 1.76, 1.98, 1.34, 1.57, 2.04, 2.42, 2.04, 2.42)),
    .zc_ci_row(500, "gamma", "ST", "Cov", c(0.32, 0.52, 0.99, 1.00, 0.74, 0.85, 0.34, 0.53, 0.60, 0.77, 0.47, 0.66)),
    .zc_ci_row(500, "gamma", "ST", "Len", c(1.22, 1.41, 1.59, 1.75, 1.60, 1.75, 1.29, 1.50, 1.73, 1.90, 1.73, 1.90)),
    .zc_ci_row(500, "gamma", "EX", "Cov", c(NA, NA, 0.99, 1.00, 0.76, 0.87, NA, NA, 0.64, 0.80, 0.50, 0.69)),
    .zc_ci_row(500, "gamma", "EX", "Len", c(NA, NA, 1.61, 1.78, 1.62, 1.78, NA, NA, 1.75, 1.93, 1.76, 1.93))
  ),

  # Table 3 (p. 33): rows p = 120 (i), p = 120 (ii), p = 500 (i), p = 500 (ii);
  # within each t(4)/sqrt(2) then Gamma. Values: s0 = 3 (Mean, SD, FP, FN),
  # s0 = 15 (Mean, SD, FP, FN).
  table3 = rbind(
    .zc_sr_row(120, "toeplitz", "t", "SupRec", c(0.98, 0.05, 0.16, 0.00), c(0.98, 0.03, 0.68, 0.02)),
    .zc_sr_row(120, "toeplitz", "t", "Stability", c(0.93, 0.08, 0.52, 0.00), c(0.35, 0.07, 0.63, 12.64)),
    .zc_sr_row(120, "toeplitz", "t", "Lassosc", c(0.68, 0.10, 3.94, 0.00), c(0.72, 0.04, 13.87, 0.00)),
    .zc_sr_row(120, "toeplitz", "t", "S&C", c(0.99, 0.04, 0.04, 0.01), c(0.87, 0.15, 0.18, 3.14)),
    .zc_sr_row(120, "toeplitz", "gamma", "SupRec", c(0.97, 0.06, 0.20, 0.00), c(0.98, 0.03, 0.71, 0.00)),
    .zc_sr_row(120, "toeplitz", "gamma", "Stability", c(0.93, 0.08, 0.58, 0.00), c(0.36, 0.07, 0.61, 12.63)),
    .zc_sr_row(120, "toeplitz", "gamma", "Lassosc", c(0.68, 0.11, 3.98, 0.00), c(0.72, 0.04, 13.94, 0.00)),
    .zc_sr_row(120, "toeplitz", "gamma", "S&C", c(0.99, 0.03, 0.03, 0.01), c(0.87, 0.15, 0.14, 3.30)),
    .zc_sr_row(120, "exchangeable", "t", "SupRec", c(0.97, 0.06, 0.24, 0.00), c(0.98, 0.02, 0.55, 0.01)),
    .zc_sr_row(120, "exchangeable", "t", "Stability", c(0.97, 0.06, 0.26, 0.00), c(0.00, 0.00, 0.13, 15.00)),
    .zc_sr_row(120, "exchangeable", "t", "Lassosc", c(0.56, 0.09, 7.09, 0.00), c(0.65, 0.04, 20.24, 0.00)),
    .zc_sr_row(120, "exchangeable", "t", "S&C", c(0.99, 0.04, 0.04, 0.01), c(0.80, 0.24, 0.16, 4.41)),
    .zc_sr_row(120, "exchangeable", "gamma", "SupRec", c(0.97, 0.06, 0.23, 0.00), c(0.98, 0.02, 0.60, 0.00)),
    .zc_sr_row(120, "exchangeable", "gamma", "Stability", c(0.96, 0.06, 0.27, 0.00), c(0.00, 0.00, 0.13, 15.00)),
    .zc_sr_row(120, "exchangeable", "gamma", "Lassosc", c(0.56, 0.09, 7.07, 0.00), c(0.65, 0.04, 20.20, 0.00)),
    .zc_sr_row(120, "exchangeable", "gamma", "S&C", c(0.99, 0.03, 0.04, 0.00), c(0.81, 0.22, 0.24, 4.40)),
    .zc_sr_row(500, "toeplitz", "t", "SupRec", c(0.97, 0.06, 0.20, 0.00), c(0.53, 0.04, 0.14, 10.66)),
    .zc_sr_row(500, "toeplitz", "t", "Stability", c(0.84, 0.10, 1.32, 0.00), c(0.36, 0.03, 1.74, 11.97)),
    .zc_sr_row(500, "toeplitz", "t", "Lassosc", c(0.62, 0.09, 5.24, 0.00), c(0.38, 0.03, 19.25, 7.37)),
    .zc_sr_row(500, "toeplitz", "t", "S&C", c(0.96, 0.13, 0.36, 0.12), c(0.12, 0.17, 18.26, 14.04)),
    .zc_sr_row(500, "toeplitz", "gamma", "SupRec", c(0.97, 0.06, 0.18, 0.00), c(0.53, 0.04, 0.15, 10.68)),
    .zc_sr_row(500, "toeplitz", "gamma", "Stability", c(0.86, 0.09, 1.24, 0.00), c(0.36, 0.03, 1.75, 11.93)),
    .zc_sr_row(500, "toeplitz", "gamma", "Lassosc", c(0.62, 0.09, 5.38, 0.00), c(0.38, 0.03, 19.15, 7.36)),
    .zc_sr_row(500, "toeplitz", "gamma", "S&C", c(0.96, 0.14, 0.55, 0.14), c(0.56, 0.08, 18.22, 14.00)),
    .zc_sr_row(500, "exchangeable", "t", "SupRec", c(0.97, 0.06, 0.25, 0.00), c(0.96, 0.04, 1.38, 0.10)),
    .zc_sr_row(500, "exchangeable", "t", "Stability", c(0.96, 0.07, 0.34, 0.00), c(0.08, 0.10, 0.86, 14.59)),
    .zc_sr_row(500, "exchangeable", "t", "Lassosc", c(0.41, 0.05, 15.16, 0.00), c(0.50, 0.02, 45.64, 0.00)),
    .zc_sr_row(500, "exchangeable", "t", "S&C", c(0.98, 0.08, 0.05, 0.05), c(0.04, 0.11, 28.51, 14.61)),
    .zc_sr_row(500, "exchangeable", "gamma", "SupRec", c(0.97, 0.07, 0.27, 0.00), c(0.96, 0.04, 1.43, 0.04)),
    .zc_sr_row(500, "exchangeable", "gamma", "Stability", c(0.95, 0.07, 0.36, 0.00), c(0.08, 0.10, 0.86, 14.58)),
    .zc_sr_row(500, "exchangeable", "gamma", "Lassosc", c(0.41, 0.05, 15.18, 0.00), c(0.50, 0.02, 45.41, 0.00)),
    .zc_sr_row(500, "exchangeable", "gamma", "S&C", c(0.98, 0.06, 0.05, 0.05), c(0.05, 0.11, 27.54, 14.62))
  ),

  # Table 4 (p. 34), p = 500. Upper panel: sizes; lower panel: powers.
  table4 = rbind(
    .zc_st_row("i", "S0c", 0.05, c(0.03, 0.03, 0.02, 0.03, 0.06, 0.06, 0.07, 0.07)),
    .zc_st_row("i", "S0c", 0.01, c(0.01, 0.00, 0.00, 0.01, 0.01, 0.01, 0.03, 0.02)),
    .zc_st_row("i", "S0tc", 0.05, c(0.02, 0.01, 0.02, 0.02, 0.05, 0.04, 0.06, 0.05)),
    .zc_st_row("i", "S0tc", 0.01, c(0.01, 0.00, 0.01, 0.01, 0.02, 0.02, 0.03, 0.02)),
    .zc_st_row("ii", "S0c", 0.05, c(0.09, 0.08, 0.08, 0.08, 0.10, 0.11, 0.09, 0.10)),
    .zc_st_row("ii", "S0c", 0.01, c(0.02, 0.03, 0.03, 0.03, 0.04, 0.04, 0.03, 0.03)),
    .zc_st_row("i", "3+S0c", 0.05, c(0.66, 0.67, 0.61, 0.62, 0.74, 0.72, 0.73, 0.72)),
    .zc_st_row("i", "3+S0c", 0.01, c(0.54, 0.56, 0.49, 0.51, 0.62, 0.60, 0.63, 0.61)),
    .zc_st_row("i", "23+S0c", 0.05, c(0.89, 0.88, 0.88, 0.87, 0.93, 0.92, 0.94, 0.93)),
    .zc_st_row("i", "23+S0c", 0.01, c(0.80, 0.80, 0.79, 0.78, 0.87, 0.85, 0.87, 0.85)),
    .zc_st_row("i", "15+S0tc", 0.05, c(0.63, 0.64, 0.58, 0.59, 0.73, 0.72, 0.70, 0.68)),
    .zc_st_row("i", "15+S0tc", 0.01, c(0.53, 0.54, 0.48, 0.50, 0.63, 0.61, 0.60, 0.57)),
    .zc_st_row("i", "1415+S0tc", 0.05, c(0.86, 0.86, 0.82, 0.82, 0.93, 0.92, 0.93, 0.92)),
    .zc_st_row("i", "1415+S0tc", 0.01, c(0.76, 0.76, 0.71, 0.72, 0.86, 0.85, 0.87, 0.85)),
    .zc_st_row("ii", "3+S0c", 0.05, c(1.00, 1.00, 1.00, 1.00, 0.99, 0.99, 1.00, 1.00)),
    .zc_st_row("ii", "3+S0c", 0.01, c(1.00, 1.00, 1.00, 1.00, 0.99, 0.99, 1.00, 1.00)),
    .zc_st_row("ii", "23+S0c", 0.05, c(1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00)),
    .zc_st_row("ii", "23+S0c", 0.01, c(1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00))
  ),

  # Table 5 (p. 35): rows t(4)/sqrt(2) then Gamma; within each NST, ST, BH.
  table5 = rbind(
    .zc_step_row("t", "NST", c(0.037, 0.548, 0.008, 0.732, 0.046, 0.594, 0.005, 0.701)),
    .zc_step_row("t", "ST", c(0.028, 0.534, 0.009, 0.722, 0.048, 0.560, 0.005, 0.685)),
    .zc_step_row("t", "BH", c(0.024, 0.528, 0.006, 0.717, 0.040, 0.555, 0.004, 0.678)),
    .zc_step_row("gamma", "NST", c(0.034, 0.535, 0.014, 0.725, 0.039, 0.581, 0.001, 0.701)),
    .zc_step_row("gamma", "ST", c(0.033, 0.513, 0.016, 0.714, 0.046, 0.549, 0.004, 0.685)),
    .zc_step_row("gamma", "BH", c(0.023, 0.506, 0.011, 0.708, 0.038, 0.545, 0.004, 0.680))
  )
)

# ---------------------------------------------------------------------------
# Shared data generators
# ---------------------------------------------------------------------------

zc_err_label <- c(t = "t4/sqrt2", gamma = "Gamma")
zc_case_label <- c(i = "(i)", ii = "(ii)")

# The fixed design `name` (see zc_designs): X is drawn once from its seed, so
# every script and every run sees the same matrix.
zc_design <- function(name) {
  d <- zc_designs[[name]]
  sigma <- switch(d$cov,
    toeplitz = cov_toeplitz(d$p, d$rho),
    exchangeable = cov_exch(d$p, d$rho),
    block = cov_block(d$p, d$rho, d$block))
  set.seed(d$seed)
  c(d, list(name = name, X = rmvn_design(zc_settings$n, sigma)))
}

# Seed offsets from the design seed, chosen so that no two purposes share a
# seed (design seeds differ by at most 4; draw d of beta adds 100 (d - 1) + s0).
zc_seed_offset <- c(theta = 1e5, beta_ci = 2e5, beta_sr = 3e5)

# Theta-hat of SR/Sim.CI/Step for a fixed design (nodewise lasso, pooled
# 10-fold CV). Computed once per design; the seed fixes the CV folds.
zc_theta <- function(design) {
  set.seed(design$seed + zc_seed_offset[["theta"]])
  Theta.hat(design$X, nodewise = zc_settings$nodewise, parallel = rep_cores() > 1L,
            ncores = rep_cores())
}

# Sections 5.1 and 5.4: beta_j ~ Unif[0, 2] on S0 = {1, ..., s0} (one draw from
# the current RNG state).
zc_unif_beta <- function(p, s0) {
  beta <- numeric(p)
  beta[seq_len(s0)] <- runif(s0, 0, 2)
  beta
}

# The paper does not say whether beta is redrawn per run; like X (and as in
# van de Geer et al. 2014, whose setup it follows) the primary analysis draws
# it ONCE per (design, s0) (draw = 1) and keeps it fixed across runs and error
# laws. Tables 1, 2 and 5 share it for T500. Draws 2..K_draws are used only by
# the draw-sensitivity runs.
zc_beta_ci <- function(design, s0, draw = 1L) {
  set.seed(design$seed + zc_seed_offset[["beta_ci"]] + 100L * (draw - 1L) + s0)
  zc_unif_beta(design$p, s0)
}

# Section 5.2: beta_j ~ Unif[2, 4] on S0 = "a realization of s0 i.i.d draws
# without replacement from {1, ..., p}" (one draw from the current RNG state).
zc_support_beta <- function(p, s0) {
  support <- sort(sample.int(p, s0))
  beta <- numeric(p)
  beta[support] <- runif(s0, 2, 4)
  beta
}

# Support and values drawn once per (design, s0) and kept fixed (the paper's
# tiny SD of d, e.g. 0.04 with 10.66 false negatives, indicates a fixed
# support). Draws 2..K_draws are used only by the draw-sensitivity runs.
zc_beta_sr <- function(design, s0, draw = 1L) {
  set.seed(design$seed + zc_seed_offset[["beta_sr"]] + 100L * (draw - 1L) + s0)
  zc_support_beta(design$p, s0)
}

# Section 5.3 (p. 24): (i) Toeplitz, beta_j = sqrt(10 log(p) / n);
# (ii) exchangeable, beta_j = 10 sqrt(log(p) / n); for 1 <= j <= s0.
zc_beta_st <- function(design, s0, case) {
  n <- zc_settings$n
  p <- design$p
  b <- if (case == "i") sqrt(10 * log(p) / n) else 10 * sqrt(log(p) / n)
  beta <- numeric(p)
  beta[seq_len(s0)] <- b
  beta
}

# Errors with unit variance: t(4)/sqrt(2) and (Gamma(4, 1) - 4)/2.
zc_errors <- function(n, type) {
  switch(type,
    t = rt(n, 4) / sqrt(2),
    gamma = (rgamma(n, shape = 4, rate = 1) - 4) / 2,
    stop("unknown error law ", type))
}

# Distinct seed_base for run_reps(): replication r of cell k of a script uses
# set.seed(base + 1e4 k + r).
zc_seed_base <- function(script, cell) {
  base <- c(simci = 1e8, sr = 2e8, st = 3e8, step = 4e8)[[script]]
  as.integer(base + 1e4 * cell)
}

# ---------------------------------------------------------------------------
# Draw sensitivity and report tags
# ---------------------------------------------------------------------------

# Variants of the draw-sensitivity runs: fixed draws 2..K_draws of beta (draw 1
# is the primary run) and "redraw", which draws a new beta in every run.
zc_sens_variants <- function() c(paste0("draw", seq_len(zc_settings$K_draws)[-1]), "redraw")

# seed_base of variant v (1..K_draws) of main cell k: cells 100 + 10 k + v
# never coincide with a main cell (at most 16 per script).
zc_sens_seed_base <- function(script, cell, v) zc_seed_base(script, 100L + 10L * cell + v)

# Pre-registered range rule for draw-dependent numbers: the paper value must lie
# in [min_v (est_v - tol_v), max_v (est_v + tol_v)] over the variants v (the
# primary draw, the other fixed draws and the per-run redraw), where tol_v is
# the variant's own tolerance under the ordinary rule. Equivalently: the
# ordinary rule passes for some variant, or the paper value lies between two
# variants' estimates.
zc_range_check <- function(est, tol, paper) {
  lo <- min(est - tol)
  hi <- max(est + tol)
  list(pass = paper >= lo && paper <= hi, lo = lo, hi = hi)
}

# Tags appended to a target's name. Tagged targets are reported but are not
# part of the headline evidence (see CRITERIA.md (Part 1), "Headline evidence").
zc_tag <- c(draw = "[draw-dependent]", fail = "[expected failure]",
            info = "[informational]", code = "[code check]")
zc_tagged <- function(target, tag) if (is.null(tag)) target else paste(target, zc_tag[[tag]])

# ---------------------------------------------------------------------------
# Comparison helper for means (proportions use check_prop() of common.R)
# ---------------------------------------------------------------------------

# |est - paper| <= 3 sqrt(sd^2/R + sd_paper^2/R_paper) + delta. The paper's
# per-run SD is used when published (d in Table 3); otherwise ours stands in.
zc_check_mean <- function(est, sd, R, paper, R_paper, delta, sd_paper = sd) {
  tol <- 3 * sqrt(sd^2 / R + sd_paper^2 / R_paper) + delta
  list(pass = abs(est - paper) <= tol, diff = est - paper, tol = tol)
}

# Row-bind replication outputs (named numeric vectors) into a matrix.
zc_bind <- function(reps) {
  if (!length(reps)) stop("all replications failed")
  do.call(rbind, reps)
}

zc_elapsed <- function(t0) round((proc.time()[["elapsed"]] - t0) / 60, 2)
