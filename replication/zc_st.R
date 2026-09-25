# Replication of Zhang and Cheng (2017), Table 4 (Section 5.3): empirical size
# and power of the one-step procedure (no splitting, no screening) and of the
# three-step procedure (split, screen, test; SILM's ST()) for H0: beta_j = 0
# for all j in G, with the non-studentized (NST) and studentized (ST)
# statistics, at levels 5% and 1%.
#
# Models (p = 500, n = 100; fixed X and Theta-hat shared with zc_simci.R):
#   (i)  Toeplitz 0.9^|i-j|, beta_j = sqrt(10 log(p)/n) for j <= s0, s0 = 3 and
#        15, splitting proportion c0 = 1/5;
#   (ii) exchangeable 0.8, beta_j = 10 sqrt(log(p)/n) for j <= 3, c0 = 1/3.
# Test sets: s0 = 3: S0^c = {4..p} (size), {3} u S0^c, {2,3} u S0^c (power);
#            s0 = 15: {16..p} (size), {15} u .., {14,15} u .. (power).
#
# One-step procedure: max_{j in G} of the de-biased statistics on the full
# sample (p = 500, Theta-hat by the nodewise lasso) against the bootstrap
# critical value. It is computed with Sim.CI(set = G, alpha = 1 - level): the
# test rejects exactly when some simultaneous interval excludes 0.
#
# Three-step procedure: SILM's ST() for every G and level. The split, the
# screening and the nodewise lasso on D2 do not depend on G or on the level,
# so they are computed once per replication by st_three_step() below, which
# follows ST() line by line with SILM's internal helpers and replays the same
# bootstrap draws for each G. Started from the same RNG state it returns
# exactly what ST(X, Y, sub.size, test.set = G, alpha = a, nodewise =
# S$nodewise) returns; this is checked against ST() itself in the first
# replication of every cell (code-check row "Share of ST() calls reproduced
# exactly").
#
# Screening (Section 5.3, p. 25): SILM's ST() always uses the "remedy" (cross-
# validated lasso on D1, completed by marginal screening of the lasso
# residuals, |D2| - 1 variables in total). The paper describes plain marginal
# screening for case (i) and the remedy for case (ii); see CRITERIA.md (Part 1).
# For every model we record how often the remedy and plain marginal screening
# (same split) keep all relevant variables: compared with the paper's 0.98 and
# 0.59 for case (ii), s0 = 3, and reported as informational rows for case (i),
# where they show how much the remedy may change the three-step sizes.
#
# Run through replication/run.R (single-threaded BLAS).
# Criteria: replication/CRITERIA.md (Part 1).

source(file.path("replication", "common.R"))
load_silm()
source(file.path("replication", "zc_targets.R"))

ID <- "zc_st"
S <- zc_settings
n <- S$n
alphas <- S$alphas_st
t_start <- proc.time()[["elapsed"]]

# cv.glmnet on the small screening sub-sample (20 or 33 rows) warns that it
# enforces grouped = FALSE; that is expected here.
quiet_grouped <- function(expr) {
  withCallingHandlers(expr, warning = function(w) {
    if (grepl("grouped=FALSE", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning")
  })
}

# Three-step procedure of ST() (R/ST.R, SILM 2.x, legacy = FALSE,
# center = FALSE, parallel = FALSE) for several test sets and levels, with the
# nodewise rule of the ST() call it is checked against.
st_three_step <- function(X.f, Y.f, sub.size, test.sets, M, alphas, nodewise) {
  n <- nrow(X.f)
  # Step 1: sample splitting.
  n1 <- SILM:::.st_subsample_size(sub.size, n)
  n0 <- n - n1
  S1 <- sample(1:n, n1, replace = FALSE)
  # Step 2: screening on D1.
  X.sub <- X.f[S1, , drop = FALSE]
  Y.sub <- Y.f[S1]
  screen.set <- quiet_grouped(SILM:::.st_screen(X.sub, Y.sub, n0, FALSE))
  screen.set <- SILM:::.st_drop_constant(X.f, S1, screen.set)
  # Step 3 (.st_test): de-biased lasso on D2.
  X <- X.f[-S1, screen.set, drop = FALSE]
  Y <- Y.f[-S1]
  node <- SILM:::.nodewise(X, what = "Theta", do_znz = identical(nodewise, "ZnZ"),
                           parallel = FALSE, ncores = 1L)
  Theta <- node$out
  Gram <- t(X) %*% X / n0
  sreg <- SILM:::.scaled_lasso(X, Y)
  beta.hat <- sreg$coefficients
  sigma.sq <- sum((Y - X %*% beta.hat)^2) / (n0 - sum(abs(beta.hat) > 0))
  Omega <- diag(Theta %*% Gram %*% t(Theta)) * sigma.sq
  beta.db <- beta.hat + Theta %*% t(X) %*% (Y - X %*% beta.hat) / n0
  rng <- get(".Random.seed", envir = globalenv())
  res <- lapply(test.sets, function(test.set) {
    assign(".Random.seed", rng, envir = globalenv())
    index <- screen.set %in% intersect(screen.set, test.set)
    if (!any(index)) {
      return(list(stat = c(NST = 0, ST = 0),
                  reject = matrix(FALSE, 2, length(alphas), dimnames = list(c("NST", "ST"), NULL))))
    }
    margin.st <- sqrt(n0) * abs(beta.db[index]) / sqrt(Omega[index])
    margin.nst <- sqrt(n0) * abs(beta.db[index])
    stat.st <- max(margin.st)
    stat.nst <- max(margin.nst)
    A <- Theta[index, , drop = FALSE] %*% t(X)
    stat.boot.st <- stat.boot.nst <- rep(NA, M)
    for (i in 1:M) {
      e <- rnorm(n0)
      xi.boot <- A %*% e * sqrt(sigma.sq) / sqrt(n0)
      stat.boot.nst[i] <- max(abs(xi.boot))
      stat.boot.st[i] <- max(abs(xi.boot / sqrt(Omega[index])))
    }
    reject <- rbind(NST = vapply(alphas, function(a) stat.nst > quantile(stat.boot.nst, 1 - a), NA),
                    ST = vapply(alphas, function(a) stat.st > quantile(stat.boot.st, 1 - a), NA))
    list(stat = c(NST = stat.nst, ST = stat.st), reject = reject)
  })
  list(res = res, S1 = S1, screen.set = screen.set)
}

# Plain marginal screening on D1 (not a SILM method): the |D2| - 1 variables
# with the largest |standardized X_j' Y| (Section 3.2, step 2).
marginal_screen <- function(X.sub, Y.sub, k) {
  w <- abs(crossprod(SILM:::.standardize_unitnorm(X.sub), Y.sub))
  order(w, decreasing = TRUE)[seq_len(k)]
}

one_rep <- function(r, model, X, Theta, beta, err) {
  p <- ncol(X)
  Y <- as.numeric(X %*% beta + zc_errors(n, err))
  sets <- lapply(model$sets, function(s) zc_st_sets$first[zc_st_sets$set == s]:p)
  names(sets) <- model$sets
  out <- numeric()
  # One-step procedure (Sim.CI on the full sample).
  for (a in alphas) {
    for (s in names(sets)) {
      ci <- Sim.CI(X, Y, set = sets[[s]], M = S$M, alpha = 1 - a, nodewise = S$nodewise, Theta = Theta)
      out[sprintf("one_%s_%s_NST", s, a)] <- any(ci$band.nst[1, ] > 0 | ci$band.nst[2, ] < 0)
      out[sprintf("one_%s_%s_ST", s, a)] <- any(ci$band.st[1, ] > 0 | ci$band.st[2, ] < 0)
    }
  }
  # Three-step procedure (ST), from a recorded RNG state.
  st_seed <- sample.int(.Machine$integer.max, 1L)
  sub.size <- model$c0 * n
  set.seed(st_seed)
  three <- st_three_step(X, Y, sub.size, sets, S$M, alphas, S$nodewise)
  for (j in seq_along(sets)) {
    for (k in seq_along(alphas)) {
      for (stat in c("NST", "ST")) {
        out[sprintf("three_%s_%s_%s", names(sets)[j], alphas[k], stat)] <- three$res[[j]]$reject[stat, k]
      }
    }
  }
  # Screening diagnostics on the same split.
  S0 <- which(beta != 0)
  n0 <- n - length(three$S1)
  out["screen_remedy"] <- all(S0 %in% three$screen.set)
  out["screen_marginal"] <- all(S0 %in% marginal_screen(X[three$S1, , drop = FALSE], Y[three$S1], n0 - 1L))
  # Exactness check against ST() itself (first replication of each cell):
  # every G at the first level, and the first G at every other level.
  out["check_n"] <- 0
  out["check_ok"] <- 0
  if (r == 1L) {
    checks <- rbind(expand.grid(j = seq_along(sets), k = 1L), expand.grid(j = 1L, k = seq_along(alphas)[-1]))
    for (q in seq_len(nrow(checks))) {
      j <- checks$j[q]
      k <- checks$k[q]
      set.seed(st_seed)
      ref <- quiet_grouped(ST(X, Y, sub.size, test.set = sets[[j]], M = S$M, alpha = alphas[k],
                              nodewise = S$nodewise))
      ok <- isTRUE(all.equal(unname(c(ref[[1]], ref[[3]])), unname(three$res[[j]]$stat), tolerance = 0)) &&
        identical(c(ref[[2]] == "reject", ref[[4]] == "reject"), unname(three$res[[j]]$reject[, k]))
      out["check_n"] <- out["check_n"] + 1
      out["check_ok"] <- out["check_ok"] + ok
    }
  }
  out
}

# ---------------------------------------------------------------------------
# Simulation
# ---------------------------------------------------------------------------

models <- list(
  list(key = "i3", design = "T500", case = "i", s0 = 3L, c0 = 1 / 5, sets = c("S0c", "3+S0c", "23+S0c")),
  list(key = "i15", design = "T500", case = "i", s0 = 15L, c0 = 1 / 5,
       sets = c("S0tc", "15+S0tc", "1415+S0tc")),
  list(key = "ii3", design = "E500", case = "ii", s0 = 3L, c0 = 1 / 3, sets = c("S0c", "3+S0c", "23+S0c"))
)
cache <- list()
runs <- list()
cell <- 0L
for (model in models) {
  if (is.null(cache[[model$design]])) {
    des <- zc_design(model$design)
    cache[[model$design]] <- list(des = des, Theta = zc_theta(des))
  }
  des <- cache[[model$design]]$des
  Theta <- cache[[model$design]]$Theta
  beta <- zc_beta_st(des, model$s0, model$case)
  for (err in c("t", "gamma")) {
    cell <- cell + 1L
    t0 <- proc.time()[["elapsed"]]
    reps <- run_reps(S$R[["st"]], function(r) one_rep(r, model, des$X, Theta, beta, err),
                     seed_base = zc_seed_base("st", cell))
    runs[[length(runs) + 1L]] <- list(model = model, err = err, mat = zc_bind(reps),
                                      minutes = zc_elapsed(t0))
    message(sprintf("%s %s: %d reps in %.2f min", model$key, err, length(reps),
                    runs[[length(runs)]]$minutes))
  }
}

summ <- do.call(rbind, lapply(runs, function(rn) {
  m <- rn$mat
  keys <- grep("^(one|three)_", colnames(m), value = TRUE)
  parts <- do.call(rbind, strsplit(keys, "_"))
  data.frame(case = rn$model$case, s0 = rn$model$s0, err = rn$err,
             procedure = ifelse(parts[, 1] == "one", "one-step", "three-step"), set = parts[, 2],
             alpha = as.numeric(parts[, 3]), stat = parts[, 4],
             est = colMeans(m[, keys, drop = FALSE]), R = nrow(m), minutes = rn$minutes,
             stringsAsFactors = FALSE, row.names = NULL)
}))
diag_summ <- do.call(rbind, lapply(runs, function(rn) {
  m <- rn$mat
  data.frame(case = rn$model$case, s0 = rn$model$s0, err = rn$err, R = nrow(m),
             screen_remedy = mean(m[, "screen_remedy"]), screen_marginal = mean(m[, "screen_marginal"]),
             check_n = sum(m[, "check_n"]), check_ok = sum(m[, "check_ok"]), minutes = rn$minutes)
}))

# ---------------------------------------------------------------------------
# Criteria: every number of Table 4
# ---------------------------------------------------------------------------

R_paper <- S$R_paper
paper <- merge(zc_targets$table4, zc_st_sets[, c("set", "s0", "kind")], by = "set", sort = FALSE)
cmp <- merge(paper, summ, by = c("case", "s0", "set", "alpha", "stat", "err", "procedure"), sort = FALSE)
stopifnot(nrow(cmp) == nrow(paper))
set_label <- c(S0c = "S0c", "3+S0c" = "{3}+S0c", "23+S0c" = "{2,3}+S0c", S0tc = "S0~c",
               "15+S0tc" = "{15}+S0~c", "1415+S0tc" = "{14,15}+S0~c")
cmp <- cmp[order(cmp$kind == "power", cmp$case, cmp$s0, match(cmp$set, names(set_label)),
                 cmp$procedure, cmp$err, cmp$stat, -cmp$alpha), ]

rows <- list()
for (i in seq_len(nrow(cmp))) {
  x <- cmp[i, ]
  chk <- check_prop(x$est, x$R, x$paper, R_paper)
  rows[[length(rows) + 1L]] <- criterion_row(
    target = sprintf("ZC Table 4 (%s)", if (x$kind == "size") "size" else "power"),
    cell = sprintf("%s G=%s %s %s", zc_case_label[[x$case]], set_label[[x$set]], x$procedure,
                   zc_err_label[[x$err]]),
    metric = sprintf("%s %s %g%%", if (x$kind == "size") "Size" else "Power", x$stat, 100 * x$alpha),
    paper = x$paper, ours = x$est, se = sqrt(x$est * (1 - x$est) / x$R), tol = chk$tol,
    pass = chk$pass,
    note = sprintf("%sR=%d vs paper R=%d (reduced)",
                   if (x$procedure == "one-step") "one-step via Sim.CI; " else "", x$R, R_paper))
}

# Screening probabilities quoted on p. 25 (case (ii), s0 = 3).
for (err in c("t", "gamma")) {
  d <- diag_summ[diag_summ$case == "ii" & diag_summ$s0 == 3L & diag_summ$err == err, ]
  for (k in c("remedy", "marginal")) {
    est <- d[[paste0("screen_", k)]]
    chk <- check_prop(est, d$R, zc_screening[[k]], R_paper)
    rows[[length(rows) + 1L]] <- criterion_row(
      "ZC Section 5.3 screening", sprintf("(ii) s0=3 %s", zc_err_label[[err]]),
      sprintf("P(all 3 relevant variables kept), %s", k), zc_screening[[k]], est,
      se = sqrt(est * (1 - est) / d$R), tol = chk$tol, pass = chk$pass,
      note = paste0(if (k == "remedy") "SILM ST() screening" else
                      "plain marginal screening, not a SILM method",
                    "; error law not stated in the paper; paper R assumed 1000"))
  }
}

# Case (i): no published value. The paper describes plain marginal screening
# for this case, SILM screens with the remedy; if a relevant variable is missed
# on D1, its correlated Toeplitz neighbours in G absorb its effect and the
# three-step size is inflated. Reported so that readers can judge the effect
# of this deviation (no verdict).
for (s0_k in c(3L, 15L)) {
  for (err in c("t", "gamma")) {
    d <- diag_summ[diag_summ$case == "i" & diag_summ$s0 == s0_k & diag_summ$err == err, ]
    for (k in c("remedy", "marginal")) {
      est <- d[[paste0("screen_", k)]]
      rows[[length(rows) + 1L]] <- criterion_row(
        zc_tagged("ZC Section 5.3 screening, case (i)", "info"),
        sprintf("(i) s0=%d %s", s0_k, zc_err_label[[err]]),
        sprintf("P(all %d relevant variables kept), %s", s0_k, k), NA, est,
        se = sqrt(est * (1 - est) / d$R), pass = NA,
        note = paste0(if (k == "remedy") "SILM ST() screening (used here)" else
                        "plain marginal screening (the paper's step 2), not a SILM method",
                      "; informational, no published value"))
    }
  }
}

# ---------------------------------------------------------------------------
# Qualitative claims (Section 5.3, p. 25) and the code check
# ---------------------------------------------------------------------------

claims <- "ZC Table 4 claims"
pp <- merge(zc_targets$table4, zc_st_sets[, c("set", "s0", "kind")], by = "set")
pp$est <- pp$paper
pick <- function(d, ...) {
  f <- list(...)
  keep <- rep(TRUE, nrow(d))
  for (nm in names(f)) keep <- keep & d[[nm]] %in% f[[nm]]
  d$est[keep]
}
tol_mean <- function(k, R) 3 * sqrt(0.05 * 0.95 / (k * R))  # 3 s.e. of a mean of k sizes

# (1) One-step size under Toeplitz is below the nominal level ("downward size
# distortion"): mean of the 8 one-step 5%-sizes of the two (i) size rows.
d1 <- pick(summ, case = "i", set = c("S0c", "S0tc"), procedure = "one-step", alpha = 0.05)
m1 <- mean(d1)
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "(i) size rows, one-step, 5%", "Mean empirical size (8 values)", NA, m1,
  pass = m1 < 0.05,
  note = sprintf("'one-step ... downward size distortion'; pass if < 0.05 (paper: %.3f)",
                 mean(pick(pp, case = "i", set = c("S0c", "S0tc"), procedure = "one-step", alpha = 0.05))))

# (2) Three-step size under Toeplitz with t errors is reasonable. Bound 0.035:
# the paper's own maximum deviation (0.01) plus about 2.5 MC s.e. of a size
# near 0.05 at R = 500 (s.e. 0.0097); a tighter bound would fail by Monte
# Carlo error alone if the true sizes equalled the paper's. Sizes of 0.07,
# which the paper calls "slightly upward distorted" for Gamma errors, are
# only 0.02 from nominal, so the bound cannot separate the two; claim (3)
# carries the t / Gamma contrast.
d2 <- pick(summ, case = "i", set = c("S0c", "S0tc"), procedure = "three-step", err = "t", alpha = 0.05)
m2 <- max(abs(d2 - 0.05))
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "(i) size rows, three-step, t errors, 5%", "Max |size - 0.05| (4 values)", NA, m2,
  pass = m2 <= 0.035,
  note = sprintf("'reasonable size for t errors'; pass if <= 0.035 (paper: %.3f)",
                 max(abs(pick(pp, case = "i", set = c("S0c", "S0tc"), procedure = "three-step",
                              err = "t", alpha = 0.05) - 0.05))))

# (3) ... "slightly upward distorted for Gamma errors".
d3 <- pick(summ, case = "i", set = c("S0c", "S0tc"), procedure = "three-step", err = "gamma", alpha = 0.05)
m3 <- mean(d3)
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "(i) size rows, three-step, Gamma errors, 5%", "Mean empirical size (4 values)", NA, m3,
  pass = m3 > 0.05,
  note = sprintf("'slightly upward distorted for Gamma errors'; pass if > 0.05 (paper: %.3f)",
                 mean(pick(pp, case = "i", set = c("S0c", "S0tc"), procedure = "three-step",
                           err = "gamma", alpha = 0.05))))

# (4) Exchangeable: "both procedures show upward size distortions".
for (proc in c("one-step", "three-step")) {
  d4 <- pick(summ, case = "ii", set = "S0c", procedure = proc, alpha = 0.05)
  m4 <- mean(d4)
  rows[[length(rows) + 1L]] <- criterion_row(
    claims, sprintf("(ii) size row, %s, 5%%", proc), "Mean empirical size (4 values)", NA, m4,
    pass = m4 > 0.05,
    note = sprintf("'both procedures show upward size distortions'; pass if > 0.05 (paper: %.3f)",
                   mean(pick(pp, case = "ii", set = "S0c", procedure = proc, alpha = 0.05))))
}

# (5) "the three-step procedure generates higher power for the Toeplitz
# covariance structure": share of the 32 (i) power comparisons.
pw_share <- function(d) {
  g <- unique(d[d$case == "i" & d$kind == "power", c("set", "err", "stat", "alpha")])
  mean(mapply(function(set, err, stat, alpha) {
    pick(d, case = "i", set = set, err = err, stat = stat, alpha = alpha, procedure = "three-step") >
      pick(d, case = "i", set = set, err = err, stat = stat, alpha = alpha, procedure = "one-step")
  }, g$set, g$err, g$stat, g$alpha))
}
summ_k <- merge(summ, zc_st_sets[, c("set", "kind")], by = "set")
q5 <- pw_share(summ_k)
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "(i) power rows, 32 comparisons", "Share with power(three-step) > power(one-step)", NA, q5,
  pass = q5 >= 0.75, note = sprintf("pass if >= 0.75 (paper: %.2f)", pw_share(pp)))

# (6) "the empirical powers of both procedures are close to 1 in case (ii)".
d6 <- pick(summ_k, case = "ii", kind = "power")
rows[[length(rows) + 1L]] <- criterion_row(
  claims, "(ii) power rows, 32 values", "Min power", NA, min(d6), pass = min(d6) >= 0.95,
  note = sprintf("'close to 1 in case (ii)'; pass if >= 0.95 (paper: %.2f)",
                 min(pick(pp, case = "ii", kind = "power"))))

# Code check (not a claim of the paper): exactness of the shared three-step
# computation.
cn <- sum(diag_summ$check_n)
co <- sum(diag_summ$check_ok)
rows[[length(rows) + 1L]] <- criterion_row(
  zc_tagged("ZC code checks", "code"), "zc_st, first replication of each cell",
  "Share of ST() calls reproduced exactly", NA,
  if (cn > 0) co / cn else NA_real_, pass = cn > 0 && co == cn,
  note = sprintf("%d ST() calls; three-step = ST() (statistics and decisions)", cn))

criteria <- do.call(rbind, rows)
save_criteria(ID, criteria = criteria, summaries = list(estimates = summ, diagnostics = diag_summ),
              meta = list(R_target = S$R[["st"]], R_paper = R_paper, M = S$M,
                          minutes = zc_elapsed(t_start)))
message(sprintf("%s: %d/%d criteria passed, %.1f min", ID, sum(criteria$pass, na.rm = TRUE),
                nrow(criteria), zc_elapsed(t_start)))
