# Replication of Zhang and Cheng (2017), Tables 1 and 2 (Section 5.1):
# coverage and width of simultaneous confidence intervals from Sim.CI(), for
# G = S0, S0^c and [p], n = 100, p in {120, 500}, Toeplitz (i) and
# exchangeable (ii) designs, s0 in {3, 15}, t(4)/sqrt(2) and Gamma errors.
#
# Design (see zc_targets.R): one fixed X per (p, Sigma), Theta-hat computed
# once per design, beta ~ Unif[0, 2] on {1..s0} drawn once per (design, s0);
# errors redrawn in every replication. For each replication, Sim.CI() is
# called for the three sets at both levels (alpha is the CONFIDENCE level in
# Sim.CI()). Coverage = all components of G covered; width = interval width
# averaged over the components of G (constant for NST).
#
# EX (the Gumbel approximation of Remark 2.4) is not a SILM method. It is
# computed from SILM's de-biased fit (the same estimates and variances that
# Sim.CI() uses; checked in every replication) with the critical value from
# eq. (15), |G| in place of p. The noise-level check of Figure S.1 uses the
# same fit: sigma_SL = ||Y - X b||/sqrt(n) (scaled lasso) and the modified
# estimator of eq. (24) that SILM uses.
#
# Draw sensitivity: coverages that depend on the paper's unknown draw of beta
# (G = S0 for s0 = 3; every G for s0 = 15) are also computed for draws
# 2..K_draws of beta and for a variant that redraws beta in every run, with
# S$R[["sens"]] runs each. Those numbers are judged by the range rule
# zc_range_check(). Run through replication/run.R (single-threaded BLAS).
#
# Criteria: replication/CRITERIA.md (Part 1).

source(file.path("replication", "common.R"))
load_silm()
source(file.path("replication", "zc_targets.R"))

ID <- "zc_simci"
S <- zc_settings
n <- S$n
t_start <- proc.time()[["elapsed"]]

# Gumbel critical value for max_j n (b_j - beta_j)^2 / omega_jj over |G| = g
# components (eq. (15)): 2 log g - log log g + x, with
# exp(-exp(-x/2)/sqrt(pi)) = level.
ex_crit <- function(g, level) {
  sqrt(2 * log(g) - log(log(g)) - 2 * log(-sqrt(pi) * log(level)))
}

# One replication. `beta` is a fixed coefficient vector, or (per-run redraw
# variant) a function returning a new draw; `set_names` selects the sets G.
one_rep <- function(X, Theta, beta, s0, err, set_names = c("S0", "S0c", "all")) {
  p <- ncol(X)
  if (is.function(beta)) beta <- beta()
  Y <- as.numeric(X %*% beta + zc_errors(n, err))
  sets <- list(S0 = seq_len(s0), S0c = (s0 + 1L):p, all = seq_len(p))[set_names]
  fit <- SILM:::.silm_fit(X, Y, S$nodewise, Theta)
  out <- numeric()
  db_gap <- 0
  for (lev in S$levels_ci) {
    for (s in names(sets)) {
      idx <- sets[[s]]
      b <- beta[idx]
      key <- paste(s, lev, sep = "_")
      ci <- Sim.CI(X, Y, set = idx, M = S$M, alpha = lev, nodewise = S$nodewise, Theta = Theta)
      out[paste0("cov_NST_", key)] <- all(ci$band.nst[1, ] <= b & b <= ci$band.nst[2, ])
      out[paste0("len_NST_", key)] <- mean(ci$band.nst[2, ] - ci$band.nst[1, ])
      out[paste0("cov_ST_", key)] <- all(ci$band.st[1, ] <= b & b <= ci$band.st[2, ])
      out[paste0("len_ST_", key)] <- mean(ci$band.st[2, ] - ci$band.st[1, ])
      half <- ex_crit(length(idx), lev) * sqrt(fit$Omega[idx] / n)
      out[paste0("cov_EX_", key)] <- all(abs(fit$beta.db[idx] - b) <= half)
      out[paste0("len_EX_", key)] <- mean(2 * half)
      db_gap <- max(db_gap, abs(as.numeric(fit$beta.db[idx]) - as.numeric(ci[["de-biased Lasso"]])))
    }
  }
  k <- sum(fit$beta.hat != 0)
  c(out, db_gap = db_gap, sig_mod = sqrt(fit$sigma.sq),
    sig_sl = sqrt(fit$sigma.sq * (n - k) / n))
}

# One row per (metric, method, set, level) of a replication matrix.
summarise_mat <- function(m, info) {
  keys <- grep("^(cov|len)_", colnames(m), value = TRUE)
  parts <- do.call(rbind, strsplit(keys, "_"))
  data.frame(info, metric = ifelse(parts[, 1] == "cov", "Cov", "Len"), method = parts[, 2],
             set = parts[, 3], level = as.numeric(parts[, 4]),
             est = colMeans(m[, keys, drop = FALSE]), sd = apply(m[, keys, drop = FALSE], 2, sd),
             R = nrow(m), stringsAsFactors = FALSE, row.names = NULL)
}

# ---------------------------------------------------------------------------
# Simulation
# ---------------------------------------------------------------------------

designs <- c(T120 = "i", E120 = "ii", T500 = "i", E500 = "ii")
variants <- zc_sens_variants()
runs <- list()
sens_runs <- list()
cell <- 0L
for (dn in names(designs)) {
  des <- zc_design(dn)
  t0 <- proc.time()[["elapsed"]]
  Theta <- zc_theta(des)
  message(sprintf("%s: Theta-hat (%s) in %.1f s, lambda = %.4g", dn, attr(Theta, "method"),
                  proc.time()[["elapsed"]] - t0, attr(Theta, "lambda") %||% NA))
  for (s0 in c(3L, 15L)) {
    beta <- zc_beta_ci(des, s0)
    # Draw-sensitivity variants: fixed draws 2..K and a per-run redraw. Only the
    # sets whose coverage is classified as draw-dependent are computed.
    sens_beta <- c(lapply(seq_len(S$K_draws)[-1], function(d) zc_beta_ci(des, s0, d)),
                   list(function() zc_unif_beta(des$p, s0)))
    sens_sets <- if (s0 == 3L) "S0" else c("S0", "S0c", "all")
    info <- data.frame(design = dn, p = des$p, case = designs[[dn]], s0 = s0, stringsAsFactors = FALSE)
    for (err in c("t", "gamma")) {
      cell <- cell + 1L
      t0 <- proc.time()[["elapsed"]]
      reps <- run_reps(S$R[["simci"]], function(r) one_rep(des$X, Theta, beta, s0, err),
                       seed_base = zc_seed_base("simci", cell))
      runs[[length(runs) + 1L]] <- list(info = cbind(info, err = err), mat = zc_bind(reps),
                                        beta_S0 = beta[seq_len(s0)], minutes = zc_elapsed(t0))
      message(sprintf("%s s0=%d %s: %d reps in %.2f min", dn, s0, err, length(reps),
                      runs[[length(runs)]]$minutes))
      t0 <- proc.time()[["elapsed"]]
      for (v in seq_along(variants)) {
        reps <- run_reps(S$R[["sens"]],
                         function(r) one_rep(des$X, Theta, sens_beta[[v]], s0, err, sens_sets),
                         seed_base = zc_sens_seed_base("simci", cell, v))
        sens_runs[[length(sens_runs) + 1L]] <- list(
          info = cbind(info, err = err, variant = variants[v], stringsAsFactors = FALSE),
          mat = zc_bind(reps),
          beta_S0 = if (is.function(sens_beta[[v]])) NULL else sens_beta[[v]][seq_len(s0)])
      }
      message(sprintf("%s s0=%d %s: sensitivity (%d variants) in %.2f min", dn, s0, err,
                      length(variants), zc_elapsed(t0)))
    }
  }
}

# ---------------------------------------------------------------------------
# Summaries
# ---------------------------------------------------------------------------

summ <- do.call(rbind, lapply(runs, function(rn) summarise_mat(rn$mat, rn$info)))
sens_summ <- do.call(rbind, lapply(sens_runs, function(rn) summarise_mat(rn$mat, rn$info)))
sigma_summ <- do.call(rbind, lapply(runs, function(rn) {
  data.frame(rn$info[c("design", "s0", "err")], R = nrow(rn$mat),
             sig_mod_mean = mean(rn$mat[, "sig_mod"]), sig_sl_mean = mean(rn$mat[, "sig_sl"]),
             sig_mod_median = median(rn$mat[, "sig_mod"]), sig_sl_median = median(rn$mat[, "sig_sl"]),
             db_gap = max(rn$mat[, "db_gap"]), minutes = rn$minutes)
}))
db_gap_all <- max(sigma_summ$db_gap, vapply(sens_runs, function(rn) max(rn$mat[, "db_gap"]), 0))

# ---------------------------------------------------------------------------
# Criteria: every published number of Tables 1-2
# ---------------------------------------------------------------------------

R_paper <- S$R_paper
paper <- rbind(cbind(table = 1L, s0 = 3L, zc_targets$table1),
               cbind(table = 2L, s0 = 15L, zc_targets$table2))
paper <- paper[!is.na(paper$paper), ]
cmp <- merge(paper, summ, by = c("p", "case", "s0", "err", "metric", "method", "set", "level"),
             all.x = TRUE, sort = FALSE)
cmp <- cmp[order(cmp$table, cmp$p, cmp$err, cmp$case, cmp$set, cmp$method, cmp$metric, cmp$level), ]
if (anyNA(cmp$est)) stop("missing estimates for some published cells")

# Pre-registered classes (CRITERIA.md (Part 1)):
#   "fail"    Table 2, NST, G = S0c or [p]: the published NST/ST width ratio
#             cannot arise with a shared X and pooled CV tuning (expected failures);
#   "draw"    coverage of G = S0 (both tables) and every Table 2 coverage:
#             decided mainly by the paper's unknown beta draw (range rule);
#   "primary" everything else (headline evidence).
ci_class <- function(table, method, set, metric) {
  if (table == 2L && method == "NST" && set %in% c("S0c", "all")) return("fail")
  if (metric == "Cov" && (set == "S0" || table == 2L)) return("draw")
  "primary"
}
# Relative width band: 5% of the paper value in Table 1; 10% in Table 2, whose
# widths are inconsistent with Table 1 under a common X (CRITERIA.md (Part 1)).
width_band <- c(0.05, 0.10)

# Estimates of the sensitivity variants for one published cell, in variant order.
sens_cell <- function(x) {
  d <- sens_summ[sens_summ$p == x$p & sens_summ$case == x$case & sens_summ$s0 == x$s0 &
                   sens_summ$err == x$err & sens_summ$metric == x$metric &
                   sens_summ$method == x$method & sens_summ$set == x$set &
                   sens_summ$level == x$level, ]
  d <- d[match(variants, d$variant), ]
  if (anyNA(d$est)) stop("missing sensitivity estimates for a draw-dependent cell")
  d
}

set_label <- c(S0 = "S0", S0c = "S0c", all = "[p]")
rows <- list()
for (i in seq_len(nrow(cmp))) {
  x <- cmp[i, ]
  cls <- ci_class(x$table, x$method, x$set, x$metric)
  if (x$metric == "Cov") {
    chk <- check_prop(x$est, x$R, x$paper, R_paper)
    se <- sqrt(x$est * (1 - x$est) / x$R)
    note <- ""
  } else {
    rel <- width_band[x$table]
    chk <- zc_check_mean(x$est, x$sd, x$R, x$paper, R_paper, delta = rel * x$paper)
    se <- x$sd / sqrt(x$R)
    note <- sprintf("width: 3 MC s.e. + %d%% of paper", round(100 * rel))
  }
  if (x$method == "EX") note <- trimws(paste(note, "(EX: Gumbel approximation, not a SILM method)"))
  note <- sprintf("%sR=%d vs paper R=%d", if (nzchar(note)) paste0(note, "; ") else "", x$R, R_paper)
  pass <- chk$pass
  tol <- chk$tol
  if (cls == "fail") {
    note <- paste("expected failure: NST/ST width ratio not reproducible with pooled CV tuning",
                  "(CRITERIA.md (Part 1), ambiguity 3);", note)
  } else if (cls == "draw") {
    sv <- sens_cell(x)
    est_v <- c(x$est, sv$est)
    tol_v <- mapply(function(e, r) check_prop(e, r, x$paper, R_paper)$tol, est_v, c(x$R, sv$R))
    rc <- zc_range_check(est_v, tol_v, x$paper)
    fixed <- est_v[c(TRUE, sv$variant != "redraw")]
    note <- sprintf(paste("range rule: pass if paper in [%.3f, %.3f] = %d fixed beta draws (%.3f-%.3f;",
                          "draw 1 R=%d, others R=%d) and per-run redraw (%.3f), each +- its check_prop",
                          "tolerance; draw 1 alone: %s (tol %.3f)"),
                    rc$lo, rc$hi, length(fixed), min(fixed), max(fixed), x$R, min(sv$R),
                    sv$est[sv$variant == "redraw"], if (chk$pass) "pass" else "fail", chk$tol)
    pass <- rc$pass
    tol <- NA_real_
  }
  rows[[length(rows) + 1L]] <- criterion_row(
    target = zc_tagged(sprintf("ZC Table %d (Sim.CI, s0=%d)", x$table, x$s0),
                       if (cls == "primary") NULL else cls),
    cell = sprintf("p=%d %s %s G=%s", x$p, zc_case_label[[x$case]], zc_err_label[[x$err]],
                   set_label[[x$set]]),
    metric = sprintf("%s %s %d%%", x$metric, x$method, round(100 * x$level)),
    paper = x$paper, ours = x$est, se = se, tol = tol, pass = pass, note = note)
}

# Continuous width comparison (ours / paper), reported in the summaries.
width_ratio <- cmp[cmp$metric == "Len", c("table", "p", "case", "err", "method", "set", "level",
                                          "paper", "est")]
width_ratio$ratio <- width_ratio$est / width_ratio$paper

# ---------------------------------------------------------------------------
# Qualitative claims (Section 5.1, p. 23, and Figure S.1)
# ---------------------------------------------------------------------------

claims <- "ZC Tables 1-2 claims"
get_est <- function(d, s0, p, err, case, method, set, level, metric = "Cov") {
  v <- d$est[d$s0 == s0 & d$p == p & d$err == err & d$case == case & d$method == method &
               d$set == set & d$level == level & d$metric == metric]
  stopifnot(length(v) == 1L)
  v
}
grid_all <- expand.grid(s0 = c(3L, 15L), p = c(120L, 500L), err = c("t", "gamma"), case = c("i", "ii"),
                        method = c("NST", "ST"), level = S$levels_ci, stringsAsFactors = FALSE)
paper_long <- rbind(cbind(s0 = 3L, zc_targets$table1), cbind(s0 = 15L, zc_targets$table2))
paper_long$est <- paper_long$paper

# (1) "the coverage is in general more accurate for S0^c (as compared to S0)".
closer_S0c <- function(d) {
  mapply(function(s0, p, err, case, method, level) {
    abs(get_est(d, s0, p, err, case, method, "S0c", level) - level) <=
      abs(get_est(d, s0, p, err, case, method, "S0", level) - level)
  }, grid_all$s0, grid_all$p, grid_all$err, grid_all$case, grid_all$method, grid_all$level)
}
q1 <- mean(closer_S0c(summ))
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "Tables 1-2, NST and ST, 64 combinations",
  "Share with |Cov(S0c) - level| <= |Cov(S0) - level|", NA, q1, pass = q1 >= 0.8,
  note = sprintf("claim (i) p. 23; pass if >= 0.80 (paper: %.2f)", mean(closer_S0c(paper_long))))

# (2) "the non-studentized ... better coverage (but with larger width) as
# compared to its studentized version when s0 is large" (s0 = 15).
grid15 <- expand.grid(p = c(120L, 500L), err = c("t", "gamma"), case = c("i", "ii"),
                      set = c("S0", "S0c", "all"), level = S$levels_ci, stringsAsFactors = FALSE)
nst_vs_st <- function(d, metric) {
  mapply(function(p, err, case, set, level) {
    a <- get_est(d, 15L, p, err, case, "NST", set, level, metric)
    b <- get_est(d, 15L, p, err, case, "ST", set, level, metric)
    if (metric == "Cov") a >= b - 0.01 else a > b
  }, grid15$p, grid15$err, grid15$case, grid15$set, grid15$level)
}
q2c <- mean(nst_vs_st(summ, "Cov"))
q2l <- mean(nst_vs_st(summ, "Len"))
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "Table 2 (s0=15), 48 combinations", "Share with Cov(NST) >= Cov(ST) - 0.01",
  NA, q2c, pass = q2c >= 0.8,
  note = sprintf("claim (ii) p. 23; pass if >= 0.80 (paper: %.2f)", mean(nst_vs_st(paper_long, "Cov"))))
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "Table 2 (s0=15), 48 combinations", "Share with Len(NST) > Len(ST)",
  NA, q2l, pass = q2l >= 0.8,
  note = sprintf("claim (ii) p. 23; pass if >= 0.80 (paper: %.2f); direction only, see ambiguity 3",
                 mean(nst_vs_st(paper_long, "Len"))))

# (3) "when s0 = 15 ... the coverage for the active set can be significantly
# lower than the nominal level".
grid_s0 <- expand.grid(p = c(120L, 500L), err = c("t", "gamma"), case = c("i", "ii"),
                       method = c("NST", "ST"), level = S$levels_ci, stringsAsFactors = FALSE)
under_S0 <- function(d) {
  mapply(function(p, err, case, method, level) {
    get_est(d, 15L, p, err, case, method, "S0", level) <= level - 0.05
  }, grid_s0$p, grid_s0$err, grid_s0$case, grid_s0$method, grid_s0$level)
}
q3 <- mean(under_S0(summ))
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "Table 2 (s0=15), G=S0, 32 combinations", "Share with Cov(S0) <= level - 0.05",
  NA, q3, pass = q3 >= 0.75,
  note = sprintf("claim (iii) p. 23; pass if >= 0.75 (paper: %.2f)", mean(under_S0(paper_long))))

# (4) "Overall, the non-studentized method provides satisfactory coverage
# probability" (made concrete for s0 = 3 and G = S0^c, [p]).
grid_nst <- expand.grid(p = c(120L, 500L), err = c("t", "gamma"), case = c("i", "ii"),
                        set = c("S0c", "all"), level = S$levels_ci, stringsAsFactors = FALSE)
nst_ok <- function(d) {
  mapply(function(p, err, case, set, level) {
    abs(get_est(d, 3L, p, err, case, "NST", set, level) - level) <= 0.04
  }, grid_nst$p, grid_nst$err, grid_nst$case, grid_nst$set, grid_nst$level)
}
q4 <- mean(nst_ok(summ))
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "Table 1 (s0=3), NST, G=S0c,[p], 32 combinations", "Share with |Cov - level| <= 0.04",
  NA, q4, pass = q4 >= 0.8,
  note = sprintf("p. 22 'satisfactory coverage'; pass if >= 0.80 (paper: %.2f)", mean(nst_ok(paper_long))))

# (5) Figure S.1 / p. 22: the scaled lasso underestimates the noise level and
# the modified estimator (24) removes the underestimation (t errors, sigma = 1).
# The modified estimate is sigma_SL * sqrt(n / (n - ||b||_0)) >= sigma_SL in
# every run, so its median is never below the median of sigma_SL.
st_rows <- sigma_summ[sigma_summ$err == "t", ]
k5a <- sum(st_rows$sig_sl_median < 1)
k5b <- sum(abs(st_rows$sig_mod_median - 1) <= 0.05 & st_rows$sig_mod_median >= st_rows$sig_sl_median)
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "t errors, 8 (design, s0) cells", "Cells with median sigma_SL < 1 (scaled lasso underestimates)",
  NA, k5a, pass = k5a >= 6, note = "Figure S.1; pass if >= 6 of 8")
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "t errors, 8 (design, s0) cells",
  "Cells with |median modified sigma - 1| <= 0.05 (and >= median sigma_SL)",
  NA, k5b, pass = k5b >= 6, note = "Figure S.1 / eq. (24): underestimation removed; pass if >= 6 of 8")

# Code check (not a claim of the paper): EX uses the Sim.CI() estimates.
rows[[length(rows) + 1L]] <- criterion_row(
  zc_tagged("ZC code checks", "code"), "zc_simci, all runs incl. sensitivity",
  "max |b(fit) - b(Sim.CI)| (EX uses the Sim.CI estimates)",
  NA, db_gap_all, pass = db_gap_all < 1e-10, note = "consistency check of the replication code")

criteria <- do.call(rbind, rows)
# The fixed beta draws (shared by both error laws, so listed once).
beta_draws <- c(lapply(Filter(function(rn) rn$info$err == "t", runs),
                       function(rn) list(design = rn$info$design, s0 = rn$info$s0, draw = "draw1",
                                         beta_S0 = rn$beta_S0)),
                lapply(Filter(function(rn) !is.null(rn$beta_S0) && rn$info$err == "t", sens_runs),
                       function(rn) list(design = rn$info$design, s0 = rn$info$s0,
                                         draw = rn$info$variant, beta_S0 = rn$beta_S0)))
save_criteria(ID, criteria = criteria,
              summaries = list(estimates = summ, sensitivity = sens_summ, sigma = sigma_summ,
                               width_ratio = width_ratio, beta_S0 = beta_draws),
              meta = list(R_target = S$R[["simci"]], R_sens = S$R[["sens"]], K_draws = S$K_draws,
                          R_paper = R_paper, M = S$M, minutes = zc_elapsed(t_start)))
message(sprintf("%s: %d/%d criteria passed, %.1f min", ID, sum(criteria$pass, na.rm = TRUE),
                nrow(criteria), zc_elapsed(t_start)))
