# Settings, published values and shared helpers for the replication of
#
#   Dezeure, R., Buehlmann, P. and Zhang, C.-H. (2017). High-dimensional
#   simultaneous inference with the bootstrap. TEST, 26, 685-719.  ("DBZ")
#
# Sourced by replication/dbz_*.R (after common.R and load_silm()). It defines
# objects and functions only; running it on its own does nothing.
#
# Page references are journal pages (PDF page = journal page - 684). Values
# printed in the text or inside a figure (e.g. the "Avg" column of Figs 5, 8,
# 11 and the table on p. 713) are exact. Values read off plots (boxplot
# medians, histogram bar heights) are marked `approx = TRUE`; histogram bars
# have width 0.01 and were read as counts of coefficients per coverage value
# (checked against the printed coverages of the lowest-coverage coefficients
# in Figs 5, 8, 11 and against the printed averages: the reconstructed
# histograms of Figs 4, 7 and 10 (robust panels) reproduce the printed "Avg"
# to 0.1 percentage point). The Fig. 4 histograms, the Fig. 13 boxplots and
# the Fig. 15 medians were re-read from the figures' vector graphics (PyMuPDF,
# axes calibrated to their tick marks); a bar is keyed by its right edge.
#
# Terminology: "original" = lasso.proj() (asymptotic Gaussian intervals and
# Bonferroni-Holm, "BH" in the paper); "bootstrap" = boot.lasso.proj() with
# the residual bootstrap (the paper's default, p. 703), studentized with the
# non-robust s.e. for homoscedastic errors and the robust s.e. for
# heteroscedastic errors unless stated otherwise; "WY" = Westfall-Young with
# the bootstrap under the complete null hypothesis (Sec. 4.3).

dbz <- list(alpha = 0.05, level = 0.95)

# ---------------------------------------------------------------------------
# Simulation settings (Sec. 5.1, pp. 704-709)
# ---------------------------------------------------------------------------
dbz$toeplitz <- list(n = 100, p = 500, rho = 0.9, s0 = 3, sigma = 1,
                     ref = "Sec. 5.1, p. 705: X ~ N_p(0, Sigma), Sigma_jk = 0.9^|j-k|")
# Six coefficient types for the s0 = 3 active coefficients (p. 705).
dbz$signal_types <- c("U(0,2)", "U(0,4)", "U(-2,2)", "fixed1", "fixed2", "fixed10")
dbz$R_paper <- 100L          # realisations per model for every probability (p. 703)
dbz$fwer_models_paper <- 300L  # 50 Toeplitz designs x 6 coefficient types (p. 705)
dbz$hetero <- list(
  n = 50, p = 250,
  ref = "Sec. 5.1.3, p. 709 (after Mammen, 1993)",
  design = "rows N_p(0, I) multiplied by Z_i / 2, Z_i ~ U(1, 3)",
  errors = "eps_i = l_i zeta_i + (1 - l_i) eta_i, l ~ Bern(0.5), zeta ~ N(1/2, 1.2^2), eta ~ N(-1/2, 0.7^2)",
  response = "Y_i = Q_i eps_i + eps_i, Q_i = sum_{k<=5} X_ik^2 - E[Z_i^2] (E[Z_i^2] = 13/3)",
  designs_fwer_paper = 50L)

# ---------------------------------------------------------------------------
# Individual 95% confidence intervals (one design, one U(-2,2) coefficient
# vector, 100 realisations; Figs 4, 5, 7, 8, 10, 11)
# ---------------------------------------------------------------------------
# Histogram counts: names = coverage in %, values = number of coefficients.
dbz$coverage <- list(
  gaussian = list(
    ref = "Sec. 5.1.1, Fig. 4 (p. 706) and Fig. 5 (p. 707)",
    avg = c(original = 0.963, rldpe = 0.969, bootstrap = 0.958, zc = 0.962),  # Fig. 5 "Avg", exact
    active = list(original = c(90, 98, 83), bootstrap = c(95, 92, 90),        # Fig. 5, exact (%)
                  zc = c(93, 99, 83)),
    lowest15 = list(original = c(80, 83, 83, 83, 84, 85, 85, 86, 86, 87, 87, 88, 88, 88, 89),
                    bootstrap = c(88, 88, 89, 90, 90, 91, 91, 91, 91, 91, 92, 92, 92, 92, 92),
                    zc = c(79, 80, 82, 82, 83, 83, 84, 85, 85, 85, 86, 86, 87, 87, 87)),
    hist = list(  # Fig. 4, vector graphics (sum 500; implied averages 96.34, 95.76, 96.17)
      original = c(`80` = 1, `83` = 4, `84` = 1, `85` = 2, `86` = 2, `87` = 2, `88` = 3,
                   `89` = 5, `90` = 4, `91` = 9, `92` = 8, `93` = 19, `94` = 31, `95` = 47,
                   `96` = 66, `97` = 95, `98` = 96, `99` = 71, `100` = 34),
      bootstrap = c(`88` = 2, `89` = 1, `90` = 3, `91` = 5, `92` = 22, `93` = 34, `94` = 59,
                    `95` = 82, `96` = 104, `97` = 79, `98` = 74, `99` = 33, `100` = 2),
      # ZC panel. Its leftmost bar (keyed 80) holds the printed 0.79 and 0.80
      # of Fig. 5, so the minimum is taken from `lowest15` (exact), not from
      # the bar keys (see dbz_min_cov()).
      zc = c(`80` = 2, `82` = 2, `83` = 3, `84` = 1, `85` = 3, `86` = 2, `87` = 3, `88` = 5,
             `89` = 1, `90` = 8, `91` = 6, `92` = 9, `93` = 24, `94` = 24, `95` = 56,
             `96` = 69, `97` = 80, `98` = 104, `99` = 65, `100` = 33))),
  chisq = list(
    ref = "Sec. 5.1.2, Fig. 7 (p. 708) and Fig. 8 (p. 709)",
    avg = c(original = 0.965, bootstrap = 0.961),                             # Fig. 8 "Avg", exact
    active = list(original = c(96, 98, 95), bootstrap = c(93, 94, 93)),
    lowest15 = list(original = c(73, 81, 83, 84, 84, 84, 84, 84, 85, 85, 85, 85, 86, 86, 87),
                    bootstrap = c(86, 90, 90, 90, 90, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91)),
    hist = list(  # Fig. 7, approx (sum 500; implied averages 96.54 and 96.07)
      original = c(`73` = 1, `81` = 1, `83` = 1, `84` = 5, `85` = 4, `86` = 2, `87` = 2,
                   `88` = 4, `89` = 7, `90` = 5, `91` = 4, `92` = 13, `93` = 16, `94` = 22,
                   `95` = 41, `96` = 58, `97` = 63, `98` = 107, `99` = 88, `100` = 56),
      bootstrap = c(`86` = 1, `90` = 4, `91` = 12, `92` = 12, `93` = 33, `94` = 43, `95` = 65,
                    `96` = 98, `97` = 99, `98` = 78, `99` = 50, `100` = 5))),
  hetero = list(
    ref = "Sec. 5.1.3, Fig. 10 (p. 710), Fig. 11 (p. 711) and text p. 710",
    # Fig. 11 "Avg" (exact). The text on p. 710 says "95.1 versus 95.9" for the
    # robust bootstrap and robust original; the figure (and the reconstructed
    # robust histograms of Fig. 10, implied averages 95.62 and 96.26) give
    # 95.6 and 96.3. We use the figure values and record the text values.
    avg = c(original = 0.949, bootstrap = 0.946, robust_original = 0.963, robust_bootstrap = 0.956),
    avg_text = c(robust_bootstrap = 0.951, robust_original = 0.959),
    lowest18 = list(
      original = c(66, 75, 76, 77, 77, 79, 80, 80, 80, 81, 81, 81, 81, 82, 82, 82, 82, 83),
      bootstrap = c(67, 72, 74, 75, 76, 78, 78, 79, 80, 80, 80, 81, 81, 81, 82, 83, 83, 83),
      robust_original = c(91, 91, 91, 91, 92, 92, 92, 92, 92, 93, 93, 93, 93, 93, 93, 93, 93, 93),
      robust_bootstrap = c(89, 89, 90, 91, 91, 91, 91, 91, 91, 91, 91, 92, 92, 92, 92, 92, 92, 92)),
    hist = list(  # Fig. 10 robust panels, approx (sum 250)
      robust_original = c(`91` = 4, `92` = 5, `93` = 19, `94` = 23, `95` = 28, `96` = 44,
                          `97` = 59, `98` = 37, `99` = 21, `100` = 10),
      robust_bootstrap = c(`89` = 2, `90` = 1, `91` = 8, `92` = 7, `93` = 21, `94` = 24,
                           `95` = 51, `96` = 50, `97` = 44, `98` = 20, `99` = 17, `100` = 5)),
    # Non-robust panels of Fig. 10 (approx): coefficients with coverage <= 0.90
    # (40 and 43 of 250) and >= 0.99 (83 and 73 of 250).
    frac_low = c(original = 40 / 250, bootstrap = 43 / 250, robust_original = 0,
                 robust_bootstrap = 3 / 250),
    frac_high = c(original = 83 / 250, bootstrap = 73 / 250, robust_original = 31 / 250,
                  robust_bootstrap = 22 / 250)))

# Derived histogram summaries (approx): share of coefficients with coverage
# <= 0.90 and >= 0.99, and the minimum coverage.
dbz_hist_stats <- function(h) {
  cov <- as.numeric(names(h)) / 100
  c(frac_low = sum(h[cov <= 0.905]) / sum(h), frac_high = sum(h[cov >= 0.985]) / sum(h),
    min = min(cov), avg = sum(cov * h) / sum(h))
}
# Minimum coverage of a method: the printed lowest coverage (exact) when the
# paper prints it, otherwise the lowest histogram bar.
dbz_min_cov <- function(tg, meth) {
  low <- tg$lowest15[[meth]]
  if (!is.null(low)) min(low) / 100 else dbz_hist_stats(tg$hist[[meth]])[["min"]]
}

# ---------------------------------------------------------------------------
# Multiple testing (Figs 6, 9, 12, 13, 14 and the table on p. 713)
# ---------------------------------------------------------------------------
# Boxplot summaries over models (each model's FWER/power from 100
# realisations), read off the plots: all approx (resolution about 0.005 for
# FWER, 0.02 for power, 5 for p_equiv).
dbz$fwer <- list(
  gaussian = list(ref = "Fig. 6 (p. 708); Fig. 13 top (p. 713)",
                  fwer_median = c(WY = 0.03, BH = 0.02, BH_rldpe = 0.00),
                  fwer_quartiles = list(WY = c(0.02, 0.05), BH = c(0.01, 0.03)),
                  fwer_median_fig13 = c(WY = 0.04, BH = 0.02),  # Fig. 13 top differs from Fig. 6
                  power_median = c(WY = 0.72, BH = 0.70, BH_rldpe = 0.43),
                  power_quartiles = list(WY = c(0.57, 1.00), BH = c(0.53, 1.00)),
                  pequiv_median = c(WY = 290, BH = 498),   # vector graphics: 289.7, 498.0
                  pequiv_quartiles = list(WY = c(265, 316))),
  chisq = list(ref = "Fig. 9 (p. 709); Fig. 13 bottom (p. 713)",
               fwer_median = c(WY = 0.025, BH = 0.01),
               fwer_quartiles = list(WY = c(0.01, 0.04), BH = c(0.01, 0.03)),
               power_median = c(WY = 0.69, BH = 0.67),
               pequiv_median = c(WY = 295, BH = 498),      # vector graphics: 295.4, 498.0
               pequiv_quartiles = list(WY = c(271, 321))),
  hetero = list(ref = "Fig. 12 (p. 711); 50 designs, no signal",
                fwer_median = c(WY = 0.06, BH = 0.03, robust_WY = 0.04, robust_BH = 0.02),
                fwer_quartiles = list(WY = c(0.05, 0.09), BH = c(0.02, 0.04),
                                      robust_WY = c(0.03, 0.05), robust_BH = c(0.01, 0.03))),
  pequiv_text = "Multiple testing with the bootstrap is often equivalent to about 300 tests (p. 712)")

# Table on p. 713 (exact): real designs, simulated signal (6 types x 5 seeds),
# homoscedastic Gaussian errors, medians over models/realisations.
dbz$real_designs <- data.frame(
  dataset = c("dsmN71", "Brain", "Breast", "Lymphoma", "Leukemia", "Colon", "Prostate", "nci"),
  pequiv_WY = c(1264, 886, 1162, 1083, 1230, 655, 2466, 1289),
  pequiv_BH = c(4088, 5596, 7129, 4025, 3570, 2000, 6032, 5243),
  p = c(4088, 5597, 7129, 4026, 3571, 2000, 6033, 5244),
  fwer_WY = c(0.02, 0.06, 0.05, 0.05, 0.05, 0.03, 0.06, 0.03),
  fwer_BH = c(0.00, 0.02, 0.01, 0.01, 0.03, 0.00, 0.04, 0.01),
  stringsAsFactors = FALSE)

# Riboflavin (Sec. 5.2.2, pp. 714-715; dsmN71 = riboflavin, n = 71, p = 4088).
dbz$riboflavin <- list(
  holm_rejections = 0L,   # "does not manage to reject any null hypothesis" (p. 714)
  wy_rejections = 0L,     # "does not reject any hypotheses either with WY" (p. 714)
  B = 1000L,              # Fig. 15 caption
  fig15 = list(ref = "Fig. 15 (p. 715), vector graphics",
               claim = "WY rejects the relevant hypothesis almost always for c > 2.5",
               # The boxes sit at c = 0.1, ..., 0.5, 0.8, 1, then 1.5 + 0.2357 k
               # (k = 0..14, up to 4.8), 5 and 10. Medians of -log(p_corr)
               # (natural log; the rejection line -log(0.05) = 3.0), keyed by c
               # rounded to 2 decimals. WY medians are 0 for c <= 1 and equal the
               # floor -log(1/1001) = 6.91 for every c >= 2.21; BH medians are 0
               # for c <= 2.44 (the BH box at c = 10 lies above the plot).
               wy_median_neglogp = c(`1.5` = 0.08, `1.74` = 2.63, `1.97` = 6.22, `2.21` = 6.91),
               bh_median_neglogp = c(`2.44` = 0, `2.68` = 0.22, `2.91` = 1.04, `3.15` = 1.89,
                                     `3.39` = 2.72, `3.62` = 3.60, `3.86` = 4.51, `4.09` = 5.41,
                                     `4.33` = 6.50, `4.56` = 7.69, `4.8` = 9.18, `5` = 10.78)))

# ---------------------------------------------------------------------------
# Seeds (replication r of a cell uses set.seed(seed_base + r); designs are
# generated once per cell from their own seed)
# ---------------------------------------------------------------------------
dbz$seeds <- list(
  cov_design = 17001L, cov_gaussian = 1710000L, cov_chisq = 1720000L, cov_theta = 17008L,
  het_design = 17002L, het_ci = 1730000L,
  fwer_design = 17003L, fwer_gaussian = 1740000L, fwer_chisq = 1750000L,
  fwer_het_design = 17004L, fwer_het = 1760000L,
  ribo_Z = 17005L, ribo_real = 1770000L, ribo_sim_design = 17006L, ribo_sim = 1780000L,
  ribo_fig15_design = 17007L, ribo_fig15 = 1790000L)

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------
# Smoke tests (SILM_REP_SCALE < 0.1) use at most 50 bootstrap samples and
# fewer designs so that every script finishes in a few minutes; the code path
# is otherwise identical. Full runs use the B and design counts given.
dbz_smoke <- function() rep_scale() < 0.1
dbz_B <- function(B) if (dbz_smoke()) min(B, 50L) else as.integer(B)
dbz_count <- function(k) if (rep_scale() < 1) max(1L, as.integer(round(k * rep_scale()))) else as.integer(k)

# Coefficient vector with s0 active coefficients of a given type at random
# positions (the paper permutes the coefficient vector for every model).
dbz_beta <- function(type, p, s0 = 3L) {
  vals <- switch(type,
    "U(0,2)" = runif(s0, 0, 2), "U(0,4)" = runif(s0, 0, 4), "U(-2,2)" = runif(s0, -2, 2),
    "fixed1" = rep(1, s0), "fixed2" = rep(2, s0), "fixed10" = rep(10, s0),
    stop("unknown signal type: ", type))
  beta <- numeric(p)
  beta[sample.int(p, s0)] <- vals
  beta
}

# Homoscedastic errors of variance 1: Gaussian or centred chi-squared(1) (p. 706).
dbz_errors <- function(type, n) {
  switch(type,
    gaussian = rnorm(n),
    chisq = (rchisq(n, df = 1) - 1) / sqrt(2),
    stop("unknown error type: ", type))
}

# Heteroscedastic design of Sec. 5.1.3. Q_i is fixed with the design.
# Resolution of the formulas on p. 709 (documented in CRITERIA.md (Part 2)):
# * errors: the printed eps_i = l_i zeta_i + (l_i - 1) eta_i has mean 1/2
#   (for l_i = 0 it is -eta_i ~ N(1/2, 0.7^2)), which with Y_i = (Q_i + 1)
#   eps_i makes E[Y_i | X_i] = (Q_i + 1)/2 nonlinear in X and contradicts
#   "maintaining the correctness of the linear model". We use the mean-zero
#   mixture eps_i = l_i zeta_i + (1 - l_i) eta_i (weights 1/2 on N(1/2, 1.44)
#   and N(-1/2, 0.49)).
# * Q_i = sum_{k<=5} X_ik^2 - E[Z_i^2] is taken literally, E[Z_i^2] = 13/3 for
#   Z_i ~ U(1, 3). (Centring instead by E[sum_k X_ik^2] = 65/12 would only
#   shift Q_i by 13/12; with mean-zero errors the linear model holds either way.)
dbz_hetero_design <- function(n, p) {
  zz <- runif(n, 1, 3)
  X <- matrix(rnorm(n * p), n, p) * (zz / 2)   # row i multiplied by Z_i / 2
  list(X = X, Q = rowSums(X[, 1:5]^2) - 13 / 3)
}
dbz_hetero_errors <- function(n) {
  l <- rbinom(n, 1, 0.5)
  l * rnorm(n, 0.5, 1.2) + (1 - l) * rnorm(n, -0.5, 0.7)
}

# Nodewise residuals Z of a fixed design (depend on X only; the response is a
# dummy). The nodewise regressions run in parallel over the replication cores.
dbz_Z <- function(X, ncores = rep_cores()) {
  fit <- lasso.proj(X, rnorm(nrow(X)), return.Z = TRUE, suppress.grouptesting = TRUE,
                    parallel = ncores > 1L, ncores = ncores)
  fit$Z
}

# Does each interval cover the truth?
dbz_covers <- function(ci, beta) as.vector(ci[, 1] <= beta & beta <= ci[, 2])

# Evaluate `expr`, muffling only boot.lasso.proj()'s "Lacking accuracy for
# multiple testing" warning (irrelevant when only intervals are used) and
# the one-off message about simultaneous intervals from the residual bootstrap.
dbz_quiet <- function(expr) {
  withCallingHandlers(expr,
    warning = function(w) {
      if (grepl("Lacking accuracy", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning")
    },
    message = function(m) {
      if (grepl("valid for simultaneous inference only", conditionMessage(m), fixed = TRUE)) {
        invokeRestart("muffleMessage")
      }
    })
}

# Westfall-Young rejection threshold for |T| (Sec. 5.2): with the bootstrap
# maxima M_b = max_k |T*0_k| (b = 1..B) and adjusted p-values
# (1 + #{b: M_b >= |t|}) / (B + 1), H_0j is rejected at level alpha iff
# |t_j| > t_rej = the (k+1)-th largest M_b, k = floor(alpha (B + 1) - 1).
dbz_wy_threshold <- function(absmax, alpha = dbz$alpha) {
  k <- floor(alpha * (length(absmax) + 1) - 1)
  if (k < 0) return(Inf)
  sort(absmax, decreasing = TRUE)[k + 1]
}
# Equivalent number of tests, eq. (15).
dbz_pequiv <- function(t_rej, alpha = dbz$alpha) alpha / (2 * pnorm(-t_rej))

# Summary of an R x p matrix of coverage indicators.
dbz_cov_summary <- function(cov_mat, active = integer()) {
  cov <- colMeans(cov_mat)
  rep_avg <- rowMeans(cov_mat)
  list(avg = mean(cov), se = sd(rep_avg) / sqrt(nrow(cov_mat)),
       frac_low = mean(cov <= 0.905), frac_high = mean(cov >= 0.985), min = min(cov),
       active = cov[active], hist = table(round(100 * cov)), R = nrow(cov_mat),
       coverage = cov)
}

# Stack element `name` of every replication result into a matrix (rows = reps).
dbz_stack <- function(out, name) do.call(rbind, lapply(out, `[[`, name))

dbz_require_reps <- function(out, what) {
  if (length(out) == 0L) stop("All replications failed for ", what, ".", call. = FALSE)
  invisible(out)
}

# run_reps() drops failed replications with only a warning. dbz_reps() runs
# the same replications and records how many were requested, obtained and
# failed (attribute "reps"); it stops only if every replication failed.
# Criteria of a cell in which more than dbz_max_fail of the replications
# failed are flagged (pass = FALSE) by dbz_flag().
dbz_max_fail <- 0.05
dbz_reps <- function(R, fun, seed_base, what, cores = rep_cores()) {
  requested <- max(2L, as.integer(round(R * rep_scale())))   # as in run_reps()
  out <- dbz_require_reps(run_reps(R, fun, seed_base, cores = cores), what)
  structure(out, reps = c(requested = requested, obtained = length(out),
                          failed = requested - length(out)))
}
dbz_rep_counts <- function(out) attr(out, "reps")

# Flag criteria rows that depend on cells with too many failed replications.
# `reps` is a list of dbz_rep_counts() vectors (one per cell the rows use).
# Returns a new data frame; the note records any failures.
dbz_flag <- function(rows, reps) {
  failed <- sum(vapply(reps, `[[`, 0, "failed"))
  if (failed == 0) return(rows)
  share <- max(vapply(reps, function(r) r[["failed"]] / r[["requested"]], 0))
  ok <- share <= dbz_max_fail
  msg <- sprintf("; %d of %d replications failed%s", as.integer(failed),
                 as.integer(sum(vapply(reps, `[[`, 0, "requested"))),
                 if (ok) "" else sprintf(" (FLAGGED: more than %.0f%% in a cell, pass set to FALSE)",
                                         100 * dbz_max_fail))
  transform(rows, pass = ifelse(is.na(pass), NA, pass & ok), note = paste0(note, msg))
}

# Single-threaded BLAS before any fork. run.R starts every script with
# OMP_NUM_THREADS=1 and OPENBLAS_NUM_THREADS=1 in its environment, which is
# the actual fix. This function is a fallback for scripts started directly
# with Rscript: common.R's Sys.setenv() comes too late (OpenBLAS reads the
# variables when R starts), and with an OpenMP build of OpenBLAS (Homebrew R)
# a threaded matrix product in the parent (e.g. rmvn_design() for p = 500)
# followed by one in a forked child (mclapply) deadlocks (observed before
# run.R set the variables: the nodewise lasso hung in dgemm -> GOMP_parallel).
# Setting the OpenMP thread count to 1 at run time (through libgomp's Fortran
# binding, which takes a pointer and so can be called with .C) avoids both
# the deadlock and the oversubscription; it is a no-op when the environment
# already says 1. For a pthreads build, openblas_set_num_threads_ is used.
# Results do not depend on the number of BLAS threads beyond rounding.
dbz_blas_single_thread <- function() {
  blas <- tryCatch(extSoftVersion()[["BLAS"]], error = function(e) "")
  if (!grepl("openblas", blas, ignore.case = TRUE)) return(invisible(FALSE))
  deps <- tryCatch(
    if (Sys.info()[["sysname"]] == "Darwin") {
      system2("otool", c("-L", shQuote(blas)), stdout = TRUE)
    } else {
      system2("ldd", shQuote(blas), stdout = TRUE)
    },
    error = function(e) character(), warning = function(w) character())
  gomp <- regmatches(deps, regexpr("/[^ ]*libgomp[^ ]*", deps))
  ok <- tryCatch({
    if (length(gomp) > 0L) {
      .C(getNativeSymbolInfo("omp_set_num_threads_", dyn.load(gomp[1], local = TRUE)), 1L)
    } else {
      .C(getNativeSymbolInfo("openblas_set_num_threads_", dyn.load(blas, local = TRUE)), 1L)
    }
    TRUE
  }, error = function(e) {
    warning("Could not limit OpenBLAS to one thread (", conditionMessage(e), "); forked ",
            "replications may deadlock.", call. = FALSE)
    FALSE
  })
  invisible(ok)
}
dbz_blas_single_thread()
