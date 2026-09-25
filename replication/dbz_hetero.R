# DBZ (2017) Section 5.1.3: heteroscedastic non-Gaussian errors without
# signal (Figs 10 and 11): coverage of individual 95% intervals for the
# original de-sparsified lasso and the residual bootstrap, each with the
# non-robust and the robust standard error. SILM additions (not in the
# paper's figures): the wild bootstrap with Gaussian and Mammen multipliers
# and the xyz-paired bootstrap, all with robust = TRUE (Secs 4.1, 4.2, 4.4),
# with their average coverage and their familywise error rates.
#
# Modelling assumptions (see dbz_targets.R and CRITERIA.md (Part 2)):
# * One design (n = 50, p = 250): rows N_p(0, I) times Z_i / 2, Z_i ~ U(1, 3),
#   generated once (seeded) together with Q_i = sum_{k<=5} X_ik^2 - 13/3.
# * beta = 0; per replication Y_i = (Q_i + 1) eps_i with the mean-zero normal
#   mixture eps_i = l_i zeta_i + (1 - l_i) eta_i (the printed "(l_i - 1)" is
#   read as a typo, see dbz_hetero_errors()).
# * R = 100 realisations (as in the paper), B = 300 bootstrap samples for
#   every bootstrap (paper: not stated), lasso re-tuned by CV in every
#   bootstrap sample (boot.shortcut = FALSE). Z computed once.
# * FWER (all hypotheses are null): for lasso.proj, any Holm-adjusted p-value
#   <= 0.05; for the additions, any Westfall-Young adjusted p-value <= 0.05
#   (bootstrap under the complete null, Sec. 4.3); for every bootstrap also
#   the non-coverage of the simultaneous intervals over all p coefficients
#   (eq. 10 with the max-|T| statistic), i.e. the FWER of the single-step
#   max-|T| test based on the centred bootstrap. The multi-design FWER study
#   of Fig. 12 is in dbz_fwer.R. With R = 100 these FWER rows are
#   gross-failure checks only (bound 0.135).
# * All seven methods are fitted to the same realisations; if one of them
#   fails, the realisation is dropped for all (paired comparisons). Failed
#   realisations are counted and the cell is flagged if more than 5% fail.

source(file.path("replication", "common.R")); load_silm()
source(file.path("replication", "dbz_targets.R"))

id <- "dbz_hetero"
target <- "DBZ Sec. 5.1.3 heteroscedastic errors, CI coverage (Figs 10-11) and additions"
H <- dbz$hetero
R <- 100L
B <- dbz_B(300L)
level <- dbz$level
alpha <- dbz$alpha

set.seed(dbz$seeds$het_design)
des <- dbz_hetero_design(H$n, H$p)
X <- des$X
Z <- dbz_Z(X)

# Bootstrap variants: name -> (type, multiplier, robust, WY)
boot_specs <- list(
  resid_nr = list(type = "residual", mult = NULL, robust = FALSE, wy = FALSE),
  resid_r = list(type = "residual", mult = NULL, robust = TRUE, wy = FALSE),
  wild_g = list(type = "wild", mult = "gaussian", robust = TRUE, wy = TRUE),
  wild_m = list(type = "wild", mult = "mammen", robust = TRUE, wy = TRUE),
  xyz = list(type = "xyz", mult = NULL, robust = TRUE, wy = TRUE))

# robust.divisor = "n" (hdi's divisor, the default when the stored results were
# computed) keeps them reproducible now that the default is "n-s".
fit_boot <- function(spec, y) {
  mc <- if (spec$wy) "WY" else "none"
  dbz_quiet(if (spec$type == "wild") {
    boot.lasso.proj(X, y, Z = Z, B = B, boot.type = "wild", multiplier = spec$mult,
                    robust = spec$robust, robust.divisor = "n", multiplecorr.method = mc,
                    return.bootdist = TRUE)
  } else {
    boot.lasso.proj(X, y, Z = Z, B = B, boot.type = spec$type, robust = spec$robust,
                    robust.divisor = "n", multiplecorr.method = mc, return.bootdist = TRUE)
  })
}

boot_result <- function(spec, y) {
  fb <- fit_boot(spec, y)
  sim <- dbz_quiet(confint(fb, level = level, type = "simultaneous", simult.stat = "abs"))
  list(cover = dbz_covers(confint(fb, level = level), 0),
       sim_miss = any(sim[, 1] > 0 | sim[, 2] < 0),
       wy_any = if (spec$wy) any(fb$pval.corr <= alpha) else NA,
       B_eff = fb$B.eff)
}

orig_result <- function(robust, y) {
  fo <- lasso.proj(X, y, Z = Z, robust = robust, robust.divisor = "n",
                   suppress.grouptesting = TRUE)
  list(cover = dbz_covers(confint(fo, level = level), 0), holm_any = any(fo$pval.corr <= alpha))
}

one_rep <- function(r) {
  y <- (des$Q + 1) * dbz_hetero_errors(H$n)   # beta = 0
  c(list(orig_nr = orig_result(FALSE, y), orig_r = orig_result(TRUE, y)),
    lapply(boot_specs, boot_result, y = y))
}

out <- dbz_reps(R, one_rep, seed_base = dbz$seeds$het_ci, what = "hetero CI cell")
reps <- dbz_rep_counts(out)
Rn <- length(out)
methods <- c("orig_nr", "orig_r", names(boot_specs))
cov_sum <- lapply(stats::setNames(methods, methods), function(m) {
  dbz_cov_summary(do.call(rbind, lapply(out, function(o) o[[m]]$cover)))
})
prop_of <- function(m, field) mc_prop(vapply(out, function(o) as.numeric(o[[m]][[field]]), 0))
fwer <- list(
  holm = lapply(c(orig_nr = "orig_nr", orig_r = "orig_r"), prop_of, field = "holm_any"),
  simultaneous = lapply(stats::setNames(names(boot_specs), names(boot_specs)), prop_of, field = "sim_miss"),
  wy = lapply(c(wild_g = "wild_g", wild_m = "wild_m", xyz = "xyz"), prop_of, field = "wy_any"))
B_eff_xyz <- vapply(out, function(o) o$xyz$B_eff, 0)

# ---------------------------------------------------------------------------
# Pre-registered criteria (CRITERIA.md (Part 2), section "dbz_hetero")
# ---------------------------------------------------------------------------
tg <- dbz$coverage$hetero
paper_name <- c(orig_nr = "original", resid_nr = "bootstrap", orig_r = "robust_original",
                resid_r = "robust_bootstrap")
rq <- sprintf("R = %d (paper 100), B = %d", Rn, B)
fwer_bound <- 0.05 + 3 * sqrt(0.05 * 0.95 / Rn) + 0.02

avg_row <- function(m, extra) {
  s <- cov_sum[[m]]
  pv <- tg$avg[[paper_name[[m]]]]
  tol <- 3 * s$se + extra
  txt <- unname(tg$avg_text[paper_name[[m]]])
  txt_note <- if (is.na(txt)) "" else sprintf(" (the text on p. 710 says %.3f)", txt)
  criterion_row(target, m, sprintf("average coverage (%s)", paper_name[[m]]), pv, s$avg, s$se, tol,
                abs(s$avg - pv) <= tol,
                sprintf("Fig. 11 Avg (exact)%s; tol = 3 MC s.e. + %.3f; %s", txt_note, extra, rq))
}
low_row <- function(m) {
  s <- cov_sum[[m]]
  pv <- tg$frac_low[[paper_name[[m]]]]
  ck <- check_prop(s$frac_low, H$p, pv, H$p)
  criterion_row(target, m, sprintf("share of coefficients with coverage <= 0.90 (%s)", paper_name[[m]]),
                pv, s$frac_low, NA, ck$tol, ck$pass,
                "Fig. 10 histogram (approx); check_prop over the 250 coefficients, delta 0.02")
}
gap_row <- function(nr, rb, label, paper_gap) {
  d <- cov_sum[[nr]]$frac_low - cov_sum[[rb]]$frac_low
  criterion_row(target, paste(nr, "vs", rb), sprintf("%s: share <= 0.90, non-robust minus robust", label),
                paper_gap, d, NA, 0.05, d >= 0.05,
                "claim p. 710: 'coverage is very poor for the non-robust methods'; pass if >= 0.05")
}
same_row <- function(a, b, label, paper_diff, tol, note) {
  d <- abs(cov_sum[[a]]$avg - cov_sum[[b]]$avg)
  criterion_row(target, paste(a, "vs", b), label, paper_diff, d, NA, tol, d <= tol, note)
}
bound_row <- function(p, cell, label, note) {
  criterion_row(target, cell, label, NA, p$est, p$se, fwer_bound - 0.05, p$est <= fwer_bound,
                sprintf("%s; gross-failure check only (R = %d); pass if <= 0.05 + 3 sqrt(0.05*0.95/R) + 0.02 = %.3f",
                        note, Rn, fwer_bound))
}

gap_r <- abs(cov_sum$orig_r$avg - 0.95) - abs(cov_sum$resid_r$avg - 0.95)
gap_xyz <- abs(cov_sum$xyz$avg - 0.95) - abs(cov_sum$wild_g$avg - 0.95)
sim_w <- fwer$simultaneous$wild_g$est
sim_r <- fwer$simultaneous$resid_r$est
se_sim <- sqrt(0.05 * 0.95 / Rn)
rows <- list(
  avg_row("orig_r", 0.01), avg_row("resid_r", 0.01),
  avg_row("orig_nr", 0.015), avg_row("resid_nr", 0.015),
  low_row("orig_r"), low_row("resid_r"), low_row("orig_nr"), low_row("resid_nr"),
  gap_row("orig_nr", "orig_r", "original", tg$frac_low[["original"]] - tg$frac_low[["robust_original"]]),
  gap_row("resid_nr", "resid_r", "bootstrap", tg$frac_low[["bootstrap"]] - tg$frac_low[["robust_bootstrap"]]),
  criterion_row(target, "resid_r vs orig_r", "robust: bootstrap average closer to 0.95 than original (gap difference)",
                abs(tg$avg[["robust_original"]] - 0.95) - abs(tg$avg[["robust_bootstrap"]] - 0.95),
                gap_r, NA, 0, gap_r > 0,
                "claim p. 710: 'slightly more correct for the bootstrap'; pass if > 0"),
  same_row("resid_r", "orig_r", "robust: |average bootstrap - average original|", 0.007, 0.01,
           "claim p. 710 / Fig. 10: 'hardly any difference' once the s.e. is chosen; pass if <= 0.01"),
  same_row("resid_nr", "orig_nr", "non-robust: |average bootstrap - average original|", 0.003, 0.01,
           "claim Fig. 10 caption: 'hardly any difference'; pass if <= 0.01"),
  # SILM additions (claims of Secs 4.4.1 and 5.1.4, results in the ESM).
  same_row("wild_g", "resid_r", "addition: |average wild (Gaussian) - average residual (robust)|", NA, 0.01,
           "claim p. 712: Gaussian multiplier bootstrap 'very similar to the residual bootstrap'; pass if <= 0.01"),
  criterion_row(target, "wild_g vs resid_r", "addition: share <= 0.90, wild (Gaussian) minus residual (robust)",
                NA, cov_sum$wild_g$frac_low - cov_sum$resid_r$frac_low, NA, 0.02,
                cov_sum$wild_g$frac_low - cov_sum$resid_r$frac_low <= 0.02,
                "claim p. 712: handles heteroscedastic errors 'as good as' the robust residual bootstrap; pass if <= 0.02"),
  same_row("wild_m", "wild_g", "addition: |average wild (Mammen) - average wild (Gaussian)|", NA, 0.015,
           "claim p. 688: no substantial empirical improvement from non-Gaussian multipliers; pass if <= 0.015"),
  criterion_row(target, "xyz vs wild_g", "addition: xyz not more accurate than wild (Gaussian): |xyz-0.95| - |wild-0.95|",
                NA, gap_xyz, NA, 0, gap_xyz >= 0,
                "claim p. 699: xyz 'may not be competitive' with the Gaussian wild bootstrap; weak directional check (average coverage only); pass if >= 0"),
  bound_row(fwer$simultaneous$wild_g, "wild_g", "addition: simultaneous non-coverage over all p (max-|T| FWER)",
            "Theorem 3 (wild bootstrap valid for simultaneous inference)"),
  bound_row(fwer$simultaneous$wild_m, "wild_m", "addition: simultaneous non-coverage over all p (max-|T| FWER)",
            "Theorem 3 and p. 701 (Mammen multipliers)"),
  bound_row(fwer$simultaneous$xyz, "xyz", "addition: simultaneous non-coverage over all p (max-|T| FWER)",
            "Theorem 3 (xyz-paired bootstrap)"),
  bound_row(fwer$wy$wild_g, "wild_g", "addition: FWER of Westfall-Young at 0.05", "Sec. 4.3 and Theorem 3"),
  bound_row(fwer$wy$wild_m, "wild_m", "addition: FWER of Westfall-Young at 0.05", "Sec. 4.3 and Theorem 3"),
  bound_row(fwer$wy$xyz, "xyz", "addition: FWER of Westfall-Young at 0.05", "Sec. 4.3 and Theorem 3"),
  criterion_row(target, "wild_g vs resid_r", "simultaneous: |wild - 0.05| - |residual robust - 0.05|",
                NA, abs(sim_w - 0.05) - abs(sim_r - 0.05), NA, 2 * se_sim,
                abs(sim_w - 0.05) <= abs(sim_r - 0.05) + 2 * se_sim,
                "claim p. 702: wild bootstrap preferred for simultaneous inference with heteroscedastic errors; weak directional check (allows the wild bootstrap to be up to 2 s.e. worse); pass if <= 2 s.e."))

summaries <- list(design = list(n = H$n, p = H$p, seed = dbz$seeds$het_design,
                                Q_summary = summary(des$Q)),
                  coverage = cov_sum, fwer = fwer, B_eff_xyz = summary(B_eff_xyz),
                  R = Rn, reps = reps, B = B, paper = tg)
save_criteria(id, criteria = dbz_flag(do.call(rbind, rows), list(reps)), summaries = summaries,
              meta = list(R = Rn, R_paper = 100L, B = B))
