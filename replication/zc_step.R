# Replication of Zhang and Cheng (2017), Table 5 (Section 5.4): FWER and
# average power of the bootstrap step-down method (Step(), non-studentized and
# studentized) for the two-sided hypotheses H0j: beta_j = 0, j = 1..p, and of
# the Bonferroni-Holm procedure on the studentized statistics ("BH").
#
# Design (see zc_targets.R): p = 500, n = 100, (i) Toeplitz 0.9^|i-j| and
# (ii) block diagonal (blocks of 5, correlation 0.9); "the linear model
# considered in Section 5.1": beta ~ Unif[0, 2] on S0 = {1..s0}, s0 in
# {3, 15}, drawn once per (design, s0) and kept fixed (the Toeplitz betas are
# those of Tables 1-2); fixed X and Theta-hat per design; errors redrawn.
# FWER = P(some j outside S0 rejected); power = mean over j in S0 of the
# rejection indicator (averaged over runs), as defined on p. 25.
#
# Holm is not a SILM method: its p-values 2 (1 - Phi(|T_j|)) use the
# studentized statistics T_j = sqrt(n) b_j / sqrt(omega_jj) of SILM's de-biased
# fit, which are the statistics Step() uses.
#
# Draw sensitivity: every number of Table 5 depends strongly on the paper's
# unknown draw of beta (average power is the detection rate of the drawn
# coefficients; FWER in these correlated designs is driven by leakage from
# them). Every cell is therefore also run for draws 2..K_draws and for a
# variant that redraws beta in every run (S$R[["sens"]] runs each), and the
# per-cell numbers are judged by the range rule zc_range_check(). The robust
# qualitative claims are the headline evidence. Run through replication/run.R.
#
# Criteria: replication/CRITERIA.md (Part 1).

source(file.path("replication", "common.R"))
load_silm()
source(file.path("replication", "zc_targets.R"))

ID <- "zc_step"
S <- zc_settings
n <- S$n
alpha <- S$alpha_step
t_start <- proc.time()[["elapsed"]]

# `beta` is a fixed coefficient vector, or (per-run redraw) a function.
one_rep <- function(X, Theta, beta, err) {
  if (is.function(beta)) beta <- beta()
  Y <- as.numeric(X %*% beta + zc_errors(n, err))
  stp <- Step(X, Y, M = S$M, alpha = alpha, nodewise = S$nodewise, Theta = Theta)
  fit <- SILM:::.silm_fit(X, Y, S$nodewise, Theta)
  pval <- 2 * pnorm(-sqrt(n) * abs(as.numeric(fit$beta.db)) / sqrt(fit$Omega))
  holm <- which(p.adjust(pval, method = "holm") <= alpha)
  S0 <- which(beta != 0)
  f <- function(rej) c(fwer = any(!(rej %in% S0)), power = mean(S0 %in% rej))
  c(NST = f(stp[["non-studentized test"]]), ST = f(stp[["studentized test"]]), BH = f(holm))
}

summarise_step <- function(m, info) {
  do.call(rbind, lapply(c("NST", "ST", "BH"), function(meth) {
    data.frame(info, method = meth, metric = c("FWER", "Power"),
               est = c(mean(m[, paste0(meth, ".fwer")]), mean(m[, paste0(meth, ".power")])),
               sd = c(sd(m[, paste0(meth, ".fwer")]), sd(m[, paste0(meth, ".power")])),
               R = nrow(m), stringsAsFactors = FALSE, row.names = NULL)
  }))
}

# ---------------------------------------------------------------------------
# Simulation
# ---------------------------------------------------------------------------

designs <- c(T500 = "i", B500 = "ii")
variants <- zc_sens_variants()
runs <- list()
sens_runs <- list()
cell <- 0L
for (dn in names(designs)) {
  des <- zc_design(dn)
  Theta <- zc_theta(des)
  for (s0 in c(3L, 15L)) {
    beta <- zc_beta_ci(des, s0)
    sens_beta <- c(lapply(seq_len(S$K_draws)[-1], function(d) zc_beta_ci(des, s0, d)),
                   list(function() zc_unif_beta(des$p, s0)))
    info <- data.frame(design = dn, case = designs[[dn]], s0 = s0, stringsAsFactors = FALSE)
    for (err in c("t", "gamma")) {
      cell <- cell + 1L
      t0 <- proc.time()[["elapsed"]]
      reps <- run_reps(S$R[["step"]], function(r) one_rep(des$X, Theta, beta, err),
                       seed_base = zc_seed_base("step", cell))
      runs[[length(runs) + 1L]] <- list(info = cbind(info, err = err), mat = zc_bind(reps),
                                        beta_S0 = beta[seq_len(s0)], minutes = zc_elapsed(t0))
      message(sprintf("%s s0=%d %s: %d reps in %.2f min", dn, s0, err, length(reps),
                      runs[[length(runs)]]$minutes))
      t0 <- proc.time()[["elapsed"]]
      for (v in seq_along(variants)) {
        reps <- run_reps(S$R[["sens"]], function(r) one_rep(des$X, Theta, sens_beta[[v]], err),
                         seed_base = zc_sens_seed_base("step", cell, v))
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

summ <- do.call(rbind, lapply(runs, function(rn) {
  cbind(summarise_step(rn$mat, rn$info), beta_S0 = paste(round(rn$beta_S0, 3), collapse = ","),
        minutes = rn$minutes, stringsAsFactors = FALSE)
}))
sens_summ <- do.call(rbind, lapply(sens_runs, function(rn) {
  cbind(summarise_step(rn$mat, rn$info),
        beta_S0 = if (is.null(rn$beta_S0)) "redrawn per run" else paste(round(rn$beta_S0, 3), collapse = ","),
        stringsAsFactors = FALSE)
}))

# ---------------------------------------------------------------------------
# Criteria: every number of Table 5 (draw-dependent: range rule)
# ---------------------------------------------------------------------------

R_paper <- S$R_paper
cmp <- merge(zc_targets$table5, summ, by = c("err", "method", "metric", "s0", "case"), sort = FALSE)
cmp <- cmp[order(cmp$case, cmp$s0, cmp$err, cmp$metric, cmp$method), ]
stopifnot(nrow(cmp) == nrow(zc_targets$table5))

rows <- list()
for (i in seq_len(nrow(cmp))) {
  x <- cmp[i, ]
  sv <- sens_summ[sens_summ$case == x$case & sens_summ$s0 == x$s0 & sens_summ$err == x$err &
                    sens_summ$method == x$method & sens_summ$metric == x$metric, ]
  sv <- sv[match(variants, sv$variant), ]
  if (anyNA(sv$est)) stop("missing sensitivity estimates for a Table 5 cell")
  # Average power is a mean of s0 indicators per run; its per-run variance is
  # at most pbar (1 - pbar), so check_prop() is conservative for it.
  chk <- check_prop(x$est, x$R, x$paper, R_paper)
  est_v <- c(x$est, sv$est)
  tol_v <- mapply(function(e, r) check_prop(e, r, x$paper, R_paper)$tol, est_v, c(x$R, sv$R))
  rc <- zc_range_check(est_v, tol_v, x$paper)
  fixed <- est_v[c(TRUE, sv$variant != "redraw")]
  rows[[length(rows) + 1L]] <- criterion_row(
    target = zc_tagged("ZC Table 5 (Step, p=500)", "draw"),
    cell = sprintf("s0=%d %s %s", x$s0, zc_case_label[[x$case]], zc_err_label[[x$err]]),
    metric = paste(x$metric, x$method), paper = x$paper, ours = x$est, se = x$sd / sqrt(x$R),
    tol = NA_real_, pass = rc$pass,
    note = sprintf(paste("%srange rule: pass if paper in [%.3f, %.3f] = %d fixed beta draws (%.3f-%.3f;",
                         "draw 1 R=%d, others R=%d) and per-run redraw (%.3f), each +- its check_prop",
                         "tolerance; draw 1 alone: %s (tol %.3f)"),
                   if (x$method == "BH") "Holm: not a SILM method; " else "",
                   rc$lo, rc$hi, length(fixed), min(fixed), max(fixed), x$R, min(sv$R),
                   sv$est[sv$variant == "redraw"], if (chk$pass) "pass" else "fail", chk$tol))
}

# ---------------------------------------------------------------------------
# Qualitative claims (Section 5.4, pp. 25-26), evaluated on draw 1
# ---------------------------------------------------------------------------

claims <- "ZC Table 5 claims"
# Estimates of `method` (one or more) in one cell of a summary table.
val <- function(d, s0, case, err, method, metric) {
  v <- d$est[d$s0 == s0 & d$case == case & d$err == err & d$method %in% method & d$metric == metric]
  stopifnot(length(v) == length(method))
  v
}
grid <- expand.grid(s0 = c(3L, 15L), case = c("i", "ii"), err = c("t", "gamma"),
                    stringsAsFactors = FALSE)
paper5 <- zc_targets$table5
paper5$est <- paper5$paper
R_min <- min(summ$R)

# (1) FWER control: every FWER <= alpha + 3 MC s.e. (at alpha).
fw <- summ[summ$metric == "FWER", ]
bound <- alpha + 3 * sqrt(alpha * (1 - alpha) / R_min)
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "8 cells x {NST, ST, BH}", "Max FWER (control at 5%)", NA, max(fw$est),
  tol = bound - alpha, pass = max(fw$est) <= bound,
  note = sprintf("pass if <= %.3f (5%% + 3 MC s.e.; paper max %.3f)", bound,
                 max(paper5$paper[paper5$metric == "FWER"])))

# (2) "the two procedures provide similar control on the FWER".
gapf <- function(d) {
  mapply(function(s0, case, err) {
    max(abs(val(d, s0, case, err, c("NST", "ST"), "FWER") - val(d, s0, case, err, "BH", "FWER")))
  }, grid$s0, grid$case, grid$err)
}
g <- max(gapf(summ))
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "8 cells", "Max |FWER(step-down) - FWER(Holm)|", NA, g, pass = g <= 0.03,
  note = sprintf("'similar control on the FWER'; pass if <= 0.03 (paper: %.3f)", max(gapf(paper5))))

# (3) "the step-down method delivers slightly higher average power across all
# cases considered". ST step-down vs Holm: all 8 cells. NST step-down vs
# Holm: at least 7 of 8, because NST's rejections are not nested in Holm's
# (it orders hypotheses by |b_j|, not |T_j|) and the paper's own margins are
# as small as 0.015.
pw_st <- function(d) mapply(function(s0, case, err) {
  val(d, s0, case, err, "ST", "Power") >= val(d, s0, case, err, "BH", "Power")
}, grid$s0, grid$case, grid$err)
pw_nst <- function(d) mapply(function(s0, case, err) {
  val(d, s0, case, err, "NST", "Power") >= val(d, s0, case, err, "BH", "Power")
}, grid$s0, grid$case, grid$err)
k_st <- sum(pw_st(summ))
k_nst <- sum(pw_nst(summ))
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "8 cells", "Cells with Power(ST step-down) >= Power(Holm)", NA, k_st, pass = k_st == 8L,
  note = sprintf("'slightly higher average power across all cases'; pass if 8 of 8 (paper: %d)",
                 sum(pw_st(paper5))))
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "8 cells", "Cells with Power(NST step-down) >= Power(Holm)", NA, k_nst, pass = k_nst >= 7L,
  note = sprintf("'across all cases'; pass if >= 7 of 8, NST not nested in Holm (paper: %d)",
                 sum(pw_nst(paper5))))

criteria <- do.call(rbind, rows)
save_criteria(ID, criteria = criteria, summaries = list(estimates = summ, sensitivity = sens_summ),
              meta = list(R_target = S$R[["step"]], R_sens = S$R[["sens"]], K_draws = S$K_draws,
                          R_paper = R_paper, M = S$M, minutes = zc_elapsed(t_start)))
message(sprintf("%s: %d/%d criteria passed, %.1f min", ID, sum(criteria$pass, na.rm = TRUE),
                nrow(criteria), zc_elapsed(t_start)))
