# Replication of Zhang and Cheng (2017), Table 3 (Section 5.2): support
# recovery with SR(). "SupRec" is SR()'s "de-biased Lasso" component
# (threshold sqrt(2 log p) on the studentized de-biased statistics, i.e.
# tau* = 2 of Proposition 3.1) and "Lassosc" is its "scaled Lasso" component.
# Stability selection and screen-and-clean are not in SILM and are not run.
#
# Design (see zc_targets.R): the fixed X of Section 5.1 per (p, Sigma),
# Theta-hat computed once per design; support = s0 draws without replacement
# from {1..p} and coefficients ~ Unif[2, 4], drawn once per (design, s0) and
# kept fixed; errors redrawn in every replication.
# d(S0hat, S0) = |S0hat n S0| / sqrt(|S0hat| |S0|), taken as 0 when S0hat is
# empty. FP = |S0hat \ S0|, FN = |S0 \ S0hat|.
#
# Draw sensitivity: the cell p = 500, Toeplitz, s0 = 15 is a phase transition
# whose results depend on where the paper's unknown 15 support points fell. It
# is also run for support draws 2..K_draws and for a variant that redraws the
# support and values in every run (S$R[["sens"]] runs each); its numbers are
# judged by the range rule zc_range_check(). Run through replication/run.R.
#
# Criteria: replication/CRITERIA.md (Part 1).

source(file.path("replication", "common.R"))
load_silm()
source(file.path("replication", "zc_targets.R"))

ID <- "zc_sr"
S <- zc_settings
n <- S$n
t_start <- proc.time()[["elapsed"]]

recovery <- function(sel, S0) {
  tp <- length(intersect(sel, S0))
  d <- if (length(sel)) tp / sqrt(length(sel) * length(S0)) else 0
  c(d = d, fp = length(sel) - tp, fn = length(S0) - tp)
}

# `beta` is a fixed coefficient vector, or (per-run redraw) a function.
one_rep <- function(X, Theta, beta, err) {
  if (is.function(beta)) beta <- beta()
  Y <- as.numeric(X %*% beta + zc_errors(n, err))
  sr <- SR(X, Y, nodewise = S$nodewise, Theta = Theta)
  S0 <- which(beta != 0)
  c(SupRec = recovery(sr[["de-biased Lasso"]], S0), Lassosc = recovery(sr[["scaled Lasso"]], S0))
}

summarise_sr <- function(m, info) {
  do.call(rbind, lapply(c("SupRec", "Lassosc"), function(meth) {
    col <- function(k) m[, paste(meth, k, sep = ".")]
    data.frame(info, method = meth, R = nrow(m), mean = mean(col("d")), sd = sd(col("d")),
               fp = mean(col("fp")), fp_sd = sd(col("fp")), fn = mean(col("fn")), fn_sd = sd(col("fn")),
               stringsAsFactors = FALSE, row.names = NULL)
  }))
}

# Pre-registered draw-dependent cells (CRITERIA.md (Part 1)).
is_draw_cell <- function(p, cov, s0) p == 500L & cov == "toeplitz" & s0 == 15L

# ---------------------------------------------------------------------------
# Simulation
# ---------------------------------------------------------------------------

designs <- c(T120 = "toeplitz", E120 = "exchangeable", T500 = "toeplitz", E500 = "exchangeable")
variants <- zc_sens_variants()
runs <- list()
sens_runs <- list()
cell <- 0L
for (dn in names(designs)) {
  des <- zc_design(dn)
  Theta <- zc_theta(des)
  for (s0 in c(3L, 15L)) {
    beta <- zc_beta_sr(des, s0)
    sens <- is_draw_cell(des$p, designs[[dn]], s0)
    if (sens) {
      sens_beta <- c(lapply(seq_len(S$K_draws)[-1], function(d) zc_beta_sr(des, s0, d)),
                     list(function() zc_support_beta(des$p, s0)))
    }
    info <- data.frame(design = dn, p = des$p, cov = designs[[dn]], s0 = s0, stringsAsFactors = FALSE)
    for (err in c("t", "gamma")) {
      cell <- cell + 1L
      t0 <- proc.time()[["elapsed"]]
      reps <- run_reps(S$R[["sr"]], function(r) one_rep(des$X, Theta, beta, err),
                       seed_base = zc_seed_base("sr", cell))
      runs[[length(runs) + 1L]] <- list(info = cbind(info, err = err), mat = zc_bind(reps),
                                        support = which(beta != 0), minutes = zc_elapsed(t0))
      message(sprintf("%s s0=%d %s: %d reps in %.2f min", dn, s0, err, length(reps),
                      runs[[length(runs)]]$minutes))
      if (!sens) next
      t0 <- proc.time()[["elapsed"]]
      for (v in seq_along(variants)) {
        reps <- run_reps(S$R[["sens"]], function(r) one_rep(des$X, Theta, sens_beta[[v]], err),
                         seed_base = zc_sens_seed_base("sr", cell, v))
        sens_runs[[length(sens_runs) + 1L]] <- list(
          info = cbind(info, err = err, variant = variants[v], stringsAsFactors = FALSE),
          mat = zc_bind(reps),
          support = if (is.function(sens_beta[[v]])) NULL else which(sens_beta[[v]] != 0))
      }
      message(sprintf("%s s0=%d %s: sensitivity (%d variants) in %.2f min", dn, s0, err,
                      length(variants), zc_elapsed(t0)))
    }
  }
}

summ <- do.call(rbind, lapply(runs, function(rn) {
  cbind(summarise_sr(rn$mat, rn$info), support = paste(rn$support, collapse = ","),
        minutes = rn$minutes, stringsAsFactors = FALSE)
}))
sens_summ <- do.call(rbind, lapply(sens_runs, function(rn) {
  cbind(summarise_sr(rn$mat, rn$info),
        support = if (is.null(rn$support)) "redrawn per run" else paste(rn$support, collapse = ","),
        stringsAsFactors = FALSE)
}))

# ---------------------------------------------------------------------------
# Criteria: SupRec and Lassosc numbers of Table 3
# ---------------------------------------------------------------------------

R_paper <- S$R_paper
paper <- zc_targets$table3[zc_targets$table3$method %in% c("SupRec", "Lassosc"), ]
cmp <- merge(paper, summ, by = c("p", "cov", "err", "method", "s0"), suffixes = c("_paper", ""),
             sort = FALSE)
cmp <- cmp[order(cmp$s0, cmp$p, cmp$cov, cmp$err, cmp$method), ]
stopifnot(nrow(cmp) == nrow(paper))

# Ordinary tolerances (CRITERIA.md (Part 1)) for an estimate from R runs.
tol_mean_d <- function(est, sd, R, x) zc_check_mean(est, sd, R, x$mean_paper, R_paper, 0.02, x$sd_paper)$tol
tol_sd_d <- function(sd, R, x) 3 * sqrt(sd^2 / (2 * R) + x$sd_paper^2 / (2 * R_paper)) + 0.02 + 0.25 * x$sd_paper
tol_count <- function(est, sd, R, pap) zc_check_mean(est, sd, R, pap, R_paper, 0.1 + 0.2 * pap)$tol

# Range rule for a draw-dependent number: est/tol over draw 1 (the primary run)
# and the sensitivity variants `sv` (redraw included only when use_redraw).
range_row <- function(target, cell, metric, pap, x_est, x_se, est_v, tol_v, variant, R1, Rs,
                      tol1, use_redraw = TRUE) {
  keep <- use_redraw | variant != "redraw"
  rc <- zc_range_check(est_v[keep], tol_v[keep], pap)
  fixed <- est_v[variant != "redraw"]
  criterion_row(target, cell, metric, pap, x_est, x_se, NA_real_, rc$pass,
                sprintf(paste("range rule: pass if paper in [%.3f, %.3f] = %d fixed support draws (%.3f-%.3f;",
                              "draw 1 R=%d, others R=%d)%s, each +- its ordinary tolerance%s;",
                              "draw 1 alone: %s (tol %.3f)"),
                        rc$lo, rc$hi, length(fixed), min(fixed), max(fixed), R1, Rs,
                        if (use_redraw) sprintf(" and per-run redraw (%.3f)", est_v[variant == "redraw"]) else "",
                        if (use_redraw) "" else sprintf("; per-run redraw (%.3f) excluded: its SD mixes supports",
                                                        est_v[variant == "redraw"]),
                        if (abs(x_est - pap) <= tol1) "pass" else "fail", tol1))
}

cov_case <- c(toeplitz = "(i)", exchangeable = "(ii)")
rows <- list()
for (i in seq_len(nrow(cmp))) {
  x <- cmp[i, ]
  draw <- is_draw_cell(x$p, x$cov, x$s0)
  target <- zc_tagged(sprintf("ZC Table 3 (SR, s0=%d)", x$s0), if (draw) "draw" else NULL)
  cell <- sprintf("p=%d %s %s", x$p, cov_case[[x$cov]], zc_err_label[[x$err]])
  note <- sprintf("R=%d vs paper R=%d", x$R, R_paper)
  tol_m <- tol_mean_d(x$mean, x$sd, x$R, x)
  tol_s <- tol_sd_d(x$sd, x$R, x)
  tol_k <- c(fp = tol_count(x$fp, x$fp_sd, x$R, x$fp_paper), fn = tol_count(x$fn, x$fn_sd, x$R, x$fn_paper))
  if (!draw) {
    # Mean of d: paper SD used for the paper's MC error.
    rows[[length(rows) + 1L]] <- criterion_row(target, cell, paste(x$method, "mean d"), x$mean_paper,
                                               x$mean, x$sd / sqrt(x$R), tol_m,
                                               abs(x$mean - x$mean_paper) <= tol_m, note)
    # SD of d: s.e. of an SD ~ SD / sqrt(2R); delta 0.02 + 25% of the paper value.
    rows[[length(rows) + 1L]] <- criterion_row(target, cell, paste(x$method, "SD d"), x$sd_paper,
                                               x$sd, x$sd / sqrt(2 * x$R), tol_s,
                                               abs(x$sd - x$sd_paper) <= tol_s, note)
    # Mean FP and FN counts: our per-run SD stands in for the paper's.
    for (k in c("fp", "fn")) {
      est <- x[[k]]
      pap <- x[[paste0(k, "_paper")]]
      rows[[length(rows) + 1L]] <- criterion_row(target, cell, paste(x$method, toupper(k)), pap, est,
                                                 x[[paste0(k, "_sd")]] / sqrt(x$R), tol_k[[k]],
                                                 abs(est - pap) <= tol_k[[k]], note)
    }
    next
  }
  sv <- sens_summ[sens_summ$p == x$p & sens_summ$cov == x$cov & sens_summ$s0 == x$s0 &
                    sens_summ$err == x$err & sens_summ$method == x$method, ]
  sv <- sv[match(variants, sv$variant), ]
  if (anyNA(sv$mean)) stop("missing sensitivity estimates for a draw-dependent cell")
  vars <- c("draw1", sv$variant)
  Rv <- c(x$R, sv$R)
  Rs <- min(sv$R)
  est_m <- c(x$mean, sv$mean)
  sd_m <- c(x$sd, sv$sd)
  rows[[length(rows) + 1L]] <- range_row(
    target, cell, paste(x$method, "mean d"), x$mean_paper, x$mean, x$sd / sqrt(x$R), est_m,
    mapply(tol_mean_d, est_m, sd_m, Rv, MoreArgs = list(x = x)), vars, x$R, Rs, tol_m)
  rows[[length(rows) + 1L]] <- range_row(
    target, cell, paste(x$method, "SD d"), x$sd_paper, x$sd, x$sd / sqrt(2 * x$R), sd_m,
    mapply(tol_sd_d, sd_m, Rv, MoreArgs = list(x = x)), vars, x$R, Rs, tol_s, use_redraw = FALSE)
  for (k in c("fp", "fn")) {
    pap <- x[[paste0(k, "_paper")]]
    est_k <- c(x[[k]], sv[[k]])
    sd_k <- c(x[[paste0(k, "_sd")]], sv[[paste0(k, "_sd")]])
    rows[[length(rows) + 1L]] <- range_row(
      target, cell, paste(x$method, toupper(k)), pap, x[[k]], x[[paste0(k, "_sd")]] / sqrt(x$R), est_k,
      mapply(tol_count, est_k, sd_k, Rv, MoreArgs = list(pap = pap)), vars, x$R, Rs, tol_k[[k]])
  }
}

# ---------------------------------------------------------------------------
# Qualitative claims (Section 5.2, p. 24)
# ---------------------------------------------------------------------------

claims <- "ZC Table 3 claims"
wide <- merge(summ[summ$method == "SupRec", c("design", "s0", "err", "mean")],
              summ[summ$method == "Lassosc", c("design", "s0", "err", "mean")],
              by = c("design", "s0", "err"), suffixes = c("_sup", "_las"))
pw <- merge(zc_targets$table3[zc_targets$table3$method == "SupRec", c("p", "cov", "err", "s0", "mean")],
            zc_targets$table3[zc_targets$table3$method == "Lassosc", c("p", "cov", "err", "s0", "mean")],
            by = c("p", "cov", "err", "s0"), suffixes = c("_sup", "_las"))
for (s0 in c(3L, 15L)) {
  w <- wide[wide$s0 == s0, ]
  k <- sum(w$mean_sup > w$mean_las)
  need <- if (s0 == 3L) 8L else 6L
  pk <- sum(pw$mean_sup[pw$s0 == s0] > pw$mean_las[pw$s0 == s0])
  rows[[length(rows) + 1L]] <- criterion_row(
    claims, sprintf("s0=%d, 8 cells", s0), "Cells with mean d(SupRec) > mean d(Lassosc)",
    NA, k, pass = k >= need,
    note = sprintf("%s; pass if >= %d of 8 (paper: %d of 8)",
                   if (s0 == 3L) "'clearly outperforms Lasso' (s0=3)" else
                     "'in general outperforms' (s0=15)", need, pk))
}

criteria <- do.call(rbind, rows)
save_criteria(ID, criteria = criteria, summaries = list(estimates = summ, sensitivity = sens_summ),
              meta = list(R_target = S$R[["sr"]], R_sens = S$R[["sens"]], K_draws = S$K_draws,
                          R_paper = R_paper, minutes = zc_elapsed(t_start)))
message(sprintf("%s: %d/%d criteria passed, %.1f min", ID, sum(criteria$pass, na.rm = TRUE),
                nrow(criteria), zc_elapsed(t_start)))
