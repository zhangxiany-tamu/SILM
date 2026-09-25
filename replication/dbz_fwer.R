# DBZ (2017) Sections 5.1 and 5.2: multiple testing. Familywise error rate
# (FWER) and power of Westfall-Young (WY, residual bootstrap) versus
# Bonferroni-Holm on the original de-sparsified lasso (BH), and the
# equivalent number of tests p_equiv of eq. (15), for Toeplitz designs with
# homoscedastic Gaussian and chi-squared errors (Figs 6, 9, 13); and the FWER
# for heteroscedastic errors without signal (Fig. 12).
#
# Modelling assumptions and reductions (see CRITERIA.md (Part 2)):
# * Compute goes to realisations rather than bootstrap samples: B = 100
#   (paper: not stated). With B = 100 the WY decision at 5% is still exact
#   for the drawn bootstrap sample (reject iff |T_j| exceeds the 5th largest
#   of the 100 null maxima; the smallest attainable adjusted p-value is
#   1/101), and the median of p_equiv is essentially unaffected.
# * Toeplitz part: the paper uses 50 designs x 6 coefficient types = 300
#   models with 100 realisations each. We use 4 designs x 6 types = 24 models
#   with 12 realisations each (288 per error type), the same designs and
#   coefficient vectors for both error types, the lasso re-tuned by CV in
#   every bootstrap sample (boot.shortcut = FALSE, hdi's default), and
#   non-robust studentization (homoscedastic errors, p. 703). The paper's
#   boxplot medians over models are compared with our pooled rates (FWER),
#   our median over models (power) and our median over realisations (p_equiv).
# * Sensitivity (summaries and notes only, no criterion): a second WY fit per
#   Toeplitz realisation with boot.shortcut = TRUE (lasso refitted at the
#   original lambda), which the paper does not rule out and which lowers the
#   WY threshold (see dbz_riboflavin.R). It is drawn after the other fits.
# * p_equiv for WY uses the exact WY rejection threshold t_rej computed from
#   the bootstrap maxima under the complete null (dbz_wy_threshold()); for BH
#   the Holm threshold after r rejections is alpha / (p - r), so p_equiv = p - r.
#   The BH p_equiv rows are descriptive (pass = NA): with s0 = 3 they are a
#   consistency check of the definition, not a replication test.
# * Heteroscedastic part (Fig. 12): the paper uses 50 designs x 100
#   realisations; we use 16 designs x 20 realisations (320), B = 100,
#   residual bootstrap with the non-robust and the robust s.e., and Holm on
#   lasso.proj with the non-robust and the robust s.e.
# * Z is computed once per design. Errors (and nothing else) are redrawn per
#   realisation; coefficient vectors are drawn once per model with random
#   positions of the s0 = 3 active coefficients.

source(file.path("replication", "common.R")); load_silm()
source(file.path("replication", "dbz_targets.R"))

id <- "dbz_fwer"
target_hom <- "DBZ Sec. 5.1.1-5.1.2/5.2 multiple testing, Toeplitz (Figs 6, 9, 13)"
target_het <- "DBZ Sec. 5.1.3 multiple testing, heteroscedastic (Fig. 12)"
alpha <- dbz$alpha
S <- dbz$toeplitz
B <- dbz_B(100L)

# ---------------------------------------------------------------------------
# Toeplitz designs and models
# ---------------------------------------------------------------------------
n_designs <- dbz_count(4L)
reps_per_model <- 12L
set.seed(dbz$seeds$fwer_design)
designs <- lapply(seq_len(n_designs), function(d) {
  X <- rmvn_design(S$n, cov_toeplitz(S$p, S$rho))
  list(X = X, Z = dbz_Z(X))
})
models <- do.call(c, lapply(seq_len(n_designs), function(d) {
  lapply(dbz$signal_types, function(type) list(design = d, type = type, beta = dbz_beta(type, S$p, S$s0)))
}))
n_models <- length(models)

hom_rep <- function(err) {
  function(r) {
    m <- (r - 1L) %% n_models + 1L
    mod <- models[[m]]
    X <- designs[[mod$design]]$X
    Z <- designs[[mod$design]]$Z
    act <- which(mod$beta != 0)
    y <- drop(X %*% mod$beta) + dbz_errors(err, S$n)
    fo <- lasso.proj(X, y, Z = Z, suppress.grouptesting = TRUE)
    fb <- boot.lasso.proj(X, y, Z = Z, B = B, multiplecorr.method = "WY")
    fs <- boot.lasso.proj(X, y, Z = Z, B = B, multiplecorr.method = "WY", boot.shortcut = TRUE)
    rej_bh <- fo$pval.corr <= alpha
    rej_wy <- fb$pval.corr <= alpha
    rej_sc <- fs$pval.corr <= alpha
    t_rej <- dbz_wy_threshold(fb$boot.summary$absmax.H0c, alpha)
    t_rej_sc <- dbz_wy_threshold(fs$boot.summary$absmax.H0c, alpha)
    c(model = m, fwer_wy = any(rej_wy[-act]), fwer_bh = any(rej_bh[-act]),
      pow_wy = mean(rej_wy[act]), pow_bh = mean(rej_bh[act]),
      pequiv_wy = dbz_pequiv(t_rej, alpha), pequiv_bh = S$p - sum(rej_bh), t_rej = t_rej,
      thr_mismatch = sum((abs(fb$tstat) > t_rej) != rej_wy),
      fwer_sc = any(rej_sc[-act]), pow_sc = mean(rej_sc[act]),
      pequiv_sc = dbz_pequiv(t_rej_sc, alpha), t_rej_sc = t_rej_sc)
  }
}

run_hom <- function(err) {
  out <- dbz_reps(n_models * reps_per_model, hom_rep(err),
                  seed_base = dbz$seeds[[paste0("fwer_", err)]], what = paste("Toeplitz", err))
  res <- as.data.frame(do.call(rbind, out))
  per_model <- aggregate(cbind(fwer_wy, fwer_bh, pow_wy, pow_bh) ~ model, data = res, FUN = mean)
  list(results = res, per_model = per_model,
       fwer = list(WY = mc_prop(res$fwer_wy), BH = mc_prop(res$fwer_bh)),
       power = list(WY = mc_mean(res$pow_wy), BH = mc_mean(res$pow_bh)),
       power_median_models = c(WY = median(per_model$pow_wy), BH = median(per_model$pow_bh)),
       pequiv = list(WY = quantile(res$pequiv_wy, c(0.25, 0.5, 0.75)),
                     BH = quantile(res$pequiv_bh, c(0.25, 0.5, 0.75))),
       shortcut = list(fwer = mc_prop(res$fwer_sc), power = mc_mean(res$pow_sc),
                       pequiv = quantile(res$pequiv_sc, c(0.25, 0.5, 0.75)),
                       t_rej = quantile(res$t_rej_sc, c(0.25, 0.5, 0.75))),
       thr_mismatch = sum(res$thr_mismatch), R = nrow(res), reps = dbz_rep_counts(out))
}

hom <- list(gaussian = run_hom("gaussian"), chisq = run_hom("chisq"))

# ---------------------------------------------------------------------------
# Heteroscedastic designs (Fig. 12), no signal
# ---------------------------------------------------------------------------
H <- dbz$hetero
n_het_designs <- dbz_count(16L)
reps_per_het_design <- 20L
set.seed(dbz$seeds$fwer_het_design)
het_designs <- lapply(seq_len(n_het_designs), function(d) {
  des <- dbz_hetero_design(H$n, H$p)
  c(des, list(Z = dbz_Z(des$X)))
})

het_rep <- function(r) {
  d <- (r - 1L) %% n_het_designs + 1L
  des <- het_designs[[d]]
  y <- (des$Q + 1) * dbz_hetero_errors(H$n)   # beta = 0: every rejection is false
  # robust.divisor = "n" (hdi's, the default when the stored results were
  # computed) keeps them reproducible now that the default is "n-s".
  any_holm <- function(robust) {
    any(lasso.proj(des$X, y, Z = des$Z, robust = robust, robust.divisor = "n",
                   suppress.grouptesting = TRUE)$pval.corr <= alpha)
  }
  any_wy <- function(robust) {
    any(boot.lasso.proj(des$X, y, Z = des$Z, B = B, robust = robust, robust.divisor = "n",
                        multiplecorr.method = "WY")$pval.corr <= alpha)
  }
  c(design = d, BH = any_holm(FALSE), WY = any_wy(FALSE),
    robust_BH = any_holm(TRUE), robust_WY = any_wy(TRUE))
}

het_out <- dbz_reps(n_het_designs * reps_per_het_design, het_rep, seed_base = dbz$seeds$fwer_het,
                    what = "heteroscedastic FWER")
het_res <- as.data.frame(do.call(rbind, het_out))
het_methods <- c("WY", "BH", "robust_WY", "robust_BH")
het <- list(results = het_res,
            per_design = aggregate(cbind(WY, BH, robust_WY, robust_BH) ~ design, data = het_res, FUN = mean),
            fwer = lapply(stats::setNames(het_methods, het_methods), function(m) mc_prop(het_res[[m]])),
            R = nrow(het_res), reps = dbz_rep_counts(het_out))

# ---------------------------------------------------------------------------
# Pre-registered criteria (CRITERIA.md (Part 2), section "dbz_fwer")
# ---------------------------------------------------------------------------
R_paper_hom <- dbz$fwer_models_paper * dbz$R_paper          # 30000 realisations
R_paper_het <- dbz$hetero$designs_fwer_paper * dbz$R_paper  # 5000 realisations

prop_row <- function(target, cell, metric, est, R, paper, R_paper, note) {
  ck <- check_prop(est$est, R, paper, R_paper)
  criterion_row(target, cell, metric, paper, est$est, est$se, ck$tol, ck$pass, note)
}

hom_rows <- function(err) {
  h <- hom[[err]]
  tg <- dbz$fwer[[err]]
  Rn <- h$R
  red <- sprintf("paper: median over 300 models (approx, %s); ours: pooled over %d models x %d = %d realisations, B = %d",
                 tg$ref, n_models, reps_per_model, Rn, B)
  bound <- 0.05 + 3 * sqrt(0.05 * 0.95 / Rn)
  dpow <- h$power$WY$est - h$power$BH$est
  pe <- h$pequiv$WY[["50%"]]
  pe_bh <- h$pequiv$BH[["50%"]]
  sc <- h$shortcut
  rows <- rbind(
    prop_row(target_hom, err, "FWER, WY", h$fwer$WY, Rn, tg$fwer_median[["WY"]], R_paper_hom, red),
    prop_row(target_hom, err, "FWER, BH (Holm, lasso.proj)", h$fwer$BH, Rn, tg$fwer_median[["BH"]],
             R_paper_hom, red),
    criterion_row(target_hom, err, "FWER, WY minus BH", tg$fwer_median[["WY"]] - tg$fwer_median[["BH"]],
                  h$fwer$WY$est - h$fwer$BH$est, NA, 0, h$fwer$WY$est >= h$fwer$BH$est,
                  "claim pp. 705, 707: the bootstrap (WY) is the least conservative; pass if >= 0"),
    criterion_row(target_hom, err, "FWER control, WY", 0.05, h$fwer$WY$est, h$fwer$WY$se, bound - 0.05,
                  h$fwer$WY$est <= bound, "claim p. 705: WY has proper error control; pass if <= 0.05 + 3 s.e."),
    criterion_row(target_hom, err, "power, WY (median over models)", tg$power_median[["WY"]],
                  h$power_median_models[["WY"]], NA, 0.2,
                  abs(h$power_median_models[["WY"]] - tg$power_median[["WY"]]) <= 0.2,
                  sprintf("approx; tol 0.2: median over %d models vs 300 models in the paper", n_models)),
    criterion_row(target_hom, err, "power, WY minus BH (pooled)", tg$power_median[["WY"]] - tg$power_median[["BH"]],
                  dpow, NA, NA, dpow >= -0.02 && dpow <= 0.10,
                  "claim p. 705: no visible power difference, WY not less powerful; pass if in [-0.02, 0.10]"),
    criterion_row(target_hom, err, "p_equiv, WY (median over realisations)", tg$pequiv_median[["WY"]], pe, NA,
                  0.2 * tg$pequiv_median[["WY"]], abs(pe / tg$pequiv_median[["WY"]] - 1) <= 0.2,
                  sprintf(paste0("Fig. 13 median (vector graphics) and 'about 300' (p. 712); relative tol 20%% ",
                                 "(about +-0.05 in t_rej); lasso re-tuned in each bootstrap sample. Sensitivity, ",
                                 "boot.shortcut = TRUE on the same realisations: median p_equiv %.0f (quartiles %.0f, %.0f), ",
                                 "WY FWER %.3f"), sc$pequiv[["50%"]], sc$pequiv[["25%"]], sc$pequiv[["75%"]], sc$fwer$est)),
    criterion_row(target_hom, err, "p_equiv, BH (median over realisations) [descriptive]", tg$pequiv_median[["BH"]],
                  pe_bh, NA, NA, NA,
                  "descriptive, not a criterion: p - (number of Holm rejections), a consistency check of the definition"),
    criterion_row(target_hom, err, "p_equiv threshold reproduces the WY decisions (mismatches)", 0,
                  h$thr_mismatch, NA, 0, h$thr_mismatch == 0,
                  "internal check of the WY threshold used for eq. (15)"))
  dbz_flag(rows, list(h$reps))
}

het_rows <- function() {
  tg <- dbz$fwer$hetero
  Rn <- het$R
  note <- sprintf("paper: median over 50 designs (approx, Fig. 12); ours: pooled over %d designs x %d = %d realisations, B = %d",
                  n_het_designs, reps_per_het_design, Rn, B)
  f <- het$fwer
  bound <- 0.05 + 3 * sqrt(0.05 * 0.95 / Rn)
  worst <- max(vapply(f, `[[`, 0, "est"))
  rows <- rbind(
    prop_row(target_het, "non-robust", "FWER, WY", f$WY, Rn, tg$fwer_median[["WY"]], R_paper_het, note),
    prop_row(target_het, "non-robust", "FWER, BH", f$BH, Rn, tg$fwer_median[["BH"]], R_paper_het, note),
    prop_row(target_het, "robust", "FWER, WY", f$robust_WY, Rn, tg$fwer_median[["robust_WY"]], R_paper_het, note),
    prop_row(target_het, "robust", "FWER, BH", f$robust_BH, Rn, tg$fwer_median[["robust_BH"]], R_paper_het, note),
    criterion_row(target_het, "non-robust", "FWER, WY minus BH", tg$fwer_median[["WY"]] - tg$fwer_median[["BH"]],
                  f$WY$est - f$BH$est, NA, 0, f$WY$est >= f$BH$est,
                  "claim p. 710: the bootstrap is less conservative; pass if >= 0"),
    criterion_row(target_het, "robust", "FWER, WY minus BH",
                  tg$fwer_median[["robust_WY"]] - tg$fwer_median[["robust_BH"]],
                  f$robust_WY$est - f$robust_BH$est, NA, 0, f$robust_WY$est >= f$robust_BH$est,
                  "claim p. 710: the bootstrap is less conservative; pass if >= 0"),
    criterion_row(target_het, "robust", "FWER control, robust WY", 0.05, f$robust_WY$est, f$robust_WY$se,
                  bound - 0.05, f$robust_WY$est <= bound, "pass if <= 0.05 + 3 s.e."),
    criterion_row(target_het, "all", "largest FWER of the four methods", NA, worst, NA, bound + 0.02 - 0.05,
                  worst <= bound + 0.02,
                  "claim p. 710: all methods 'perform adequately'; pass if <= 0.05 + 3 s.e. + 0.02"))
  dbz_flag(rows, list(het$reps))
}

rows <- list(hom_rows("gaussian"), hom_rows("chisq"), het_rows())
summaries <- list(
  toeplitz = lapply(hom, function(h) h[c("per_model", "fwer", "power", "power_median_models", "pequiv",
                                          "shortcut", "thr_mismatch", "R", "reps")]),
  toeplitz_results = lapply(hom, `[[`, "results"),
  models = lapply(models, function(m) list(design = m$design, type = m$type,
                                           active = which(m$beta != 0), values = m$beta[m$beta != 0])),
  hetero = het, B = B, paper = dbz$fwer)
save_criteria(id, criteria = do.call(rbind, rows), summaries = summaries,
              meta = list(B = B, n_models = n_models, reps_per_model = reps_per_model,
                          n_het_designs = n_het_designs, reps_per_het_design = reps_per_het_design))
