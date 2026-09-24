# DBZ (2017) Sections 5.1.1 and 5.1.2: coverage of individual two-sided 95%
# confidence intervals, original de-sparsified lasso (lasso.proj) versus the
# residual bootstrap (boot.lasso.proj), Figs 4, 5, 7 and 8; and, for Gaussian
# errors (Figs 4-5), the ZC approach (Zhang and Cheng: Gaussian multiplier
# bootstrap of the linearised part only), which is SILM's Sim.CI().
#
# Modelling assumptions (see CRITERIA.md (Part 2)):
# * One Toeplitz design (n = 100, p = 500, rho = 0.9) and one coefficient
#   vector of type U(-2, 2) with s0 = 3 at random positions, both generated
#   once (seeded) and held fixed. The paper uses "one generated design matrix
#   X and one generated coefficient vector" for each error type; we use the
#   same X and beta for the Gaussian and the chi-squared cell.
# * Errors are redrawn in every replication: N(0, 1) or (chi^2_1 - 1)/sqrt(2).
#   The model has no intercept; lasso.proj centres x and y (as hdi did);
#   Sim.CI is called with center = FALSE (the design has mean zero).
# * R = 100 realisations as in the paper. B = 500 bootstrap samples (the
#   paper does not state B for these simulations; hdi's default is 1000);
#   the lasso is re-tuned by cross-validation in every bootstrap sample
#   (boot.shortcut = FALSE, hdi's default), non-robust studentization
#   (homoscedastic errors, p. 703).
# * Z is computed once for the design and passed to every fit.
# * ZC (Gaussian cell only; ZC appears only in Figs 4-5): the individual
#   interval for beta_j is band.st of Sim.CI(X, y, set = j, M = 500,
#   alpha = 0.95, Theta = Theta), one call per coefficient, with
#   Theta = Theta.hat(X) (nodewise lasso with CV) computed once for the
#   design. For |set| = 1, band.nst equals band.st (the bootstrap quantile is
#   scale equivariant). SILM's ZC starts from the scaled lasso (as Zhang and
#   Cheng do) with SILM's own Theta; the paper's ZC presumably started from
#   the CV lasso with hdi's Z. This is why the ZC average-coverage tolerance
#   has 0.015 instead of 0.01 for the implementation difference.
# RLDPE (Figs 4-6) is not implemented in SILM and is not replicated.

source(file.path("replication", "common.R")); load_silm()
source(file.path("replication", "dbz_targets.R"))

id <- "dbz_coverage"
target <- "DBZ Sec. 5.1.1-5.1.2 individual CI coverage (Figs 4-5, 7-8)"
S <- dbz$toeplitz
R <- 100L
B <- dbz_B(500L)
M_zc <- 500L   # Sim.CI's default number of multiplier draws
level <- dbz$level

set.seed(dbz$seeds$cov_design)
X <- rmvn_design(S$n, cov_toeplitz(S$p, S$rho))
beta <- dbz_beta("U(-2,2)", S$p, S$s0)
active <- which(beta != 0)
Z <- dbz_Z(X)
set.seed(dbz$seeds$cov_theta)
Theta <- Theta.hat(X, parallel = rep_cores() > 1L, ncores = rep_cores())

# Individual ZC intervals for all p coefficients (p x 2 matrix).
zc_ci <- function(y) {
  t(vapply(seq_len(S$p), function(j) {
    Sim.CI(X, y, set = j, M = M_zc, alpha = level, Theta = Theta)$band.st[, 1]
  }, numeric(2)))
}

one_rep <- function(err) {
  function(r) {
    y <- drop(X %*% beta) + dbz_errors(err, S$n)
    fo <- lasso.proj(X, y, Z = Z, suppress.grouptesting = TRUE)
    ci_o <- confint(fo, level = level)
    fb <- dbz_quiet(boot.lasso.proj(X, y, Z = Z, B = B, multiplecorr.method = "none",
                                    return.bootdist = TRUE))
    ci_b <- confint(fb, level = level)
    res <- list(cov_o = dbz_covers(ci_o, beta), cov_b = dbz_covers(ci_b, beta),
                len_o = mean(ci_o[, 2] - ci_o[, 1]), len_b = mean(ci_b[, 2] - ci_b[, 1]))
    if (err != "gaussian") return(res)
    ci_z <- zc_ci(y)   # drawn last, so the other fits use the same random numbers
    c(res, list(cov_z = dbz_covers(ci_z, beta), len_z = mean(ci_z[, 2] - ci_z[, 1])))
  }
}

run_cell <- function(err) {
  out <- dbz_reps(R, one_rep(err), seed_base = dbz$seeds[[paste0("cov_", err)]], what = err)
  mean_of <- function(name) mean(vapply(out, `[[`, 0, name))
  cell <- list(original = dbz_cov_summary(dbz_stack(out, "cov_o"), active),
               bootstrap = dbz_cov_summary(dbz_stack(out, "cov_b"), active),
               len_ratio = mean_of("len_b") / mean_of("len_o"),
               R = length(out), B = B, reps = dbz_rep_counts(out))
  if (err != "gaussian") return(cell)
  c(cell, list(zc = dbz_cov_summary(dbz_stack(out, "cov_z"), active),
               len_ratio_zc = mean_of("len_z") / mean_of("len_o"), M_zc = M_zc))
}

cells <- list(gaussian = run_cell("gaussian"), chisq = run_cell("chisq"))

# ---------------------------------------------------------------------------
# Pre-registered criteria (CRITERIA.md (Part 2), section "dbz_coverage")
# ---------------------------------------------------------------------------
rq <- function(err) sprintf("R = %d (paper 100), B = %d", cells[[err]]$R, B)

avg_row <- function(err, meth, s, extra = 0.01, what = meth) {
  tg <- dbz$coverage[[err]]
  tol <- 3 * s$se + extra
  criterion_row(target, err, sprintf("average coverage, %s", what), tg$avg[[meth]], s$avg,
                s$se, tol, abs(s$avg - tg$avg[[meth]]) <= tol,
                sprintf("%s; printed Avg (exact); tol = 3 MC s.e. + %.3f (single design); %s",
                        tg$ref, extra, rq(err)))
}
low_row <- function(err, meth, s, what = meth) {
  hs <- dbz_hist_stats(dbz$coverage[[err]]$hist[[meth]])
  ck <- check_prop(s$frac_low, length(s$coverage), hs[["frac_low"]], length(s$coverage))
  criterion_row(target, err, sprintf("share of coefficients with coverage <= 0.90, %s", what),
                hs[["frac_low"]], s$frac_low, NA, ck$tol, ck$pass,
                "paper value from the histogram (vector graphics); check_prop over coefficients, delta 0.02")
}
diff_row <- function(err, metric, paper, ours, pass, note) {
  criterion_row(target, err, metric, paper, ours, NA, 0, pass, note)
}

cell_rows <- function(err) {
  cl <- cells[[err]]
  tg <- dbz$coverage[[err]]
  hs <- lapply(tg$hist[c("original", "bootstrap")], dbz_hist_stats)
  o <- cl$original
  b <- cl$bootstrap
  gap_o <- abs(o$avg - 0.95)
  gap_b <- abs(b$avg - 0.95)
  rows <- rbind(
    avg_row(err, "original", o),
    avg_row(err, "bootstrap", b),
    diff_row(err, "bootstrap average coverage closer to 0.95 than original (|orig-0.95| - |boot-0.95|)",
             abs(tg$avg[["original"]] - 0.95) - abs(tg$avg[["bootstrap"]] - 0.95), gap_o - gap_b,
             gap_o - gap_b > 0, "qualitative (p. 705, 708); pass if > 0"),
    low_row(err, "original", o),
    low_row(err, "bootstrap", b),
    diff_row(err, "under-coverage: share <= 0.90, bootstrap minus original",
             hs$bootstrap[["frac_low"]] - hs$original[["frac_low"]], b$frac_low - o$frac_low,
             b$frac_low < o$frac_low, "qualitative: original has more under-coverage (Figs 4, 7); pass if < 0"),
    diff_row(err, "over-coverage: share >= 0.99, bootstrap minus original",
             hs$bootstrap[["frac_high"]] - hs$original[["frac_high"]], b$frac_high - o$frac_high,
             b$frac_high < o$frac_high, "qualitative: original has more over-coverage (Figs 4, 7); pass if < 0"),
    diff_row(err, "minimum coverage, bootstrap minus original",
             dbz_min_cov(tg, "bootstrap") - dbz_min_cov(tg, "original"), b$min - o$min, b$min > o$min,
             "qualitative: poorest coverage improved by the bootstrap (Figs 5, 8); pass if > 0"),
    criterion_row(target, err, "mean CI length ratio bootstrap / original", 1, cl$len_ratio, NA, 0.05,
                  cl$len_ratio <= 1.05,
                  "claim p. 710: better coverage 'without increasing the confidence interval lengths'; pass if <= 1.05"))
  dbz_flag(rows, list(cl$reps))
}

# ZC (Sim.CI), Gaussian errors only (Figs 4-5; claims pp. 706-707 and 711).
zc_rows <- function() {
  cl <- cells$gaussian
  tg <- dbz$coverage$gaussian
  hs <- lapply(tg$hist, dbz_hist_stats)
  o <- cl$original
  b <- cl$bootstrap
  z <- cl$zc
  zc <- "ZC (Sim.CI)"
  rows <- rbind(
    avg_row("gaussian", "zc", z, extra = 0.015, what = zc),
    low_row("gaussian", "zc", z, what = zc),
    diff_row("gaussian", "ZC no better than original: share <= 0.90, ZC minus original",
             hs$zc[["frac_low"]] - hs$original[["frac_low"]], z$frac_low - o$frac_low,
             z$frac_low - o$frac_low >= -0.02,
             "claim Figs 4-5 captions: ZC 'does not show any improvements' over the original; pass if >= -0.02"),
    diff_row("gaussian", "bootstrap better than ZC: share <= 0.90, bootstrap minus ZC",
             hs$bootstrap[["frac_low"]] - hs$zc[["frac_low"]], b$frac_low - z$frac_low,
             b$frac_low < z$frac_low,
             "claim p. 711: bootstrapping only the linearised part is 'clearly sub-ideal'; pass if < 0"),
    diff_row("gaussian", "minimum coverage, bootstrap minus ZC",
             dbz_min_cov(tg, "bootstrap") - dbz_min_cov(tg, "zc"), b$min - z$min, b$min > z$min,
             sprintf("claim p. 711 (Fig. 5: 0.88 vs 0.79); pass if > 0; ZC mean length / original = %.3f",
                     cl$len_ratio_zc)))
  dbz_flag(rows, list(cl$reps))
}

g_low <- cells$gaussian$original$frac_low
c_low <- cells$chisq$original$frac_low
hs_g <- dbz_hist_stats(dbz$coverage$gaussian$hist$original)
hs_c <- dbz_hist_stats(dbz$coverage$chisq$hist$original)
rows <- list(
  cell_rows("gaussian"),
  zc_rows(),
  cell_rows("chisq"),
  dbz_flag(criterion_row(target, "chisq vs gaussian", "original: share <= 0.90, chi-squared minus Gaussian",
                         hs_c[["frac_low"]] - hs_g[["frac_low"]], c_low - g_low, NA, 0, c_low >= g_low,
                         "claim p. 706: under-coverage of the original 'even more pronounced' with chi-squared errors; pass if >= 0"),
           list(cells$gaussian$reps, cells$chisq$reps)))

summaries <- list(design = list(n = S$n, p = S$p, rho = S$rho, beta_active = beta[active],
                                active = active, seed = dbz$seeds$cov_design,
                                theta = list(method = attr(Theta, "method"), lambda = attr(Theta, "lambda"),
                                             seed = dbz$seeds$cov_theta)),
                  cells = cells,   # per-coefficient coverages are in cells$<err>$<method>$coverage
                  reps = lapply(cells, `[[`, "reps"),
                  paper = dbz$coverage[c("gaussian", "chisq")])
save_criteria(id, criteria = do.call(rbind, rows), summaries = summaries,
              meta = list(R = cells$gaussian$R, R_paper = 100L, B = B, M_zc = M_zc))
