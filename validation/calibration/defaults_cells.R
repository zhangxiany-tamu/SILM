# One replication of each kind of cell of the defaults study (DEFAULTS.md).
# Each function returns a named list of metric vectors, one per variant; all
# variants of a replication see the same errors and the same multiplier or
# bootstrap draws (paired comparison).

M_ZC <- 500L    # multiplier draws of Sim.CI/Step/ST (the SILM default)
B_DBZ <- 499L   # bootstrap samples of boot.lasso.proj
LEVEL <- 0.95
ALPHA <- 0.05

quiet <- function(expr) suppressWarnings(suppressMessages(expr))
covers <- function(lo, up, b) lo <= b & b <= up
na_if_empty <- function(idx, value) if (length(idx)) value else NA_real_

# Seeds: every cell has a base; a replication adds r, a purpose adds an offset.
SEED_OFFSET <- c(errors = 0, simci = 3e5, step = 4e5, st = 5e5, boot = 6e5, asym = 7e5)
rep_seed <- function(base, r, purpose) base + SEED_OFFSET[[purpose]] + r

# ---- Sim.CI / Step / SR ----------------------------------------------------------

zc_rep <- function(r, cell, setup) {
  d <- ZC_DESIGNS[[cell$design]]
  X <- setup$zc[[cell$design]]$X
  p <- ncol(X)
  beta <- zc_beta(p, cell$s0, cell$sign, seed = d$seed + 2e5 + cell$s0)
  S0 <- which(beta != 0)
  sets <- list(S0 = S0, S0c = setdiff(seq_len(p), S0), all = seq_len(p))
  base <- cell$seed_base
  set.seed(rep_seed(base, r, "errors"))
  y <- drop(X %*% beta) + t_errors(N_ZC)
  lapply(c(cv = "cv", ZnZ = "ZnZ"), function(nw) {
    theta <- setup$zc[[cell$design]]$theta[[nw]]
    out <- numeric()
    for (g in names(sets)) {
      idx <- sets[[g]]
      set.seed(rep_seed(base, r, "simci"))
      ci <- quiet(Sim.CI(X, y, idx, M = M_ZC, alpha = LEVEL, nodewise = nw, Theta = theta))
      for (stat in c("nst", "st")) {
        band <- ci[[paste0("band.", stat)]]
        out[paste0("cov_", stat, "_", g)] <- all(covers(band[1, ], band[2, ], beta[idx]))
        out[paste0("width_", stat, "_", g)] <- mean(band[2, ] - band[1, ])
      }
    }
    set.seed(rep_seed(base, r, "step"))
    step <- quiet(Step(X, y, M = M_ZC, alpha = ALPHA, nodewise = nw, Theta = theta))
    for (k in 1:2) {
      stat <- c("nst", "st")[k]
      out[paste0("fwer_step_", stat)] <- any(!step[[k]] %in% S0)
      out[paste0("power_step_", stat)] <- mean(S0 %in% step[[k]])
    }
    out
  })
}

# ---- SR -----------------------------------------------------------------------------

sr_rep <- function(r, cell, setup) {
  d <- ZC_DESIGNS[[cell$design]]
  X <- setup$zc[[cell$design]]$X
  beta <- sr_beta(ncol(X), cell$s0, seed = d$seed + 3e5 + cell$s0)
  S0 <- which(beta != 0)
  set.seed(rep_seed(cell$seed_base, r, "errors"))
  y <- drop(X %*% beta) + t_errors(N_ZC)
  lapply(c(cv = "cv", ZnZ = "ZnZ"), function(nw) {
    sel <- quiet(SR(X, y, nodewise = nw, Theta = setup$zc[[cell$design]]$theta[[nw]]))[[1]]
    c(sr_exact = setequal(sel, S0), sr_no_fp = all(sel %in% S0), sr_tpr = mean(S0 %in% sel),
      sr_fp = sum(!sel %in% S0), sr_fn = sum(!S0 %in% sel))
  })
}

# ---- ST ---------------------------------------------------------------------------

st_rep <- function(r, cell, setup) {
  X <- setup$zc[[cell$design]]$X
  p <- ncol(X)
  beta <- st_beta(p, cell$case, cell$s0)
  base <- cell$seed_base
  set.seed(rep_seed(base, r, "errors"))
  y <- drop(X %*% beta) + t_errors(N_ZC)
  lapply(c(cv = "cv", ZnZ = "ZnZ"), function(nw) {
    out <- numeric()
    for (kind in c("size", "power")) {
      test.set <- (if (kind == "size") cell$s0 + 1L else cell$s0):p
      set.seed(rep_seed(base, r, "st"))
      st <- quiet(ST(X, y, sub.size = cell$sub, test.set = test.set, M = M_ZC, alpha = ALPHA,
                     nodewise = nw))
      out[paste0(kind, "_st_nst")] <- st[[2]] == "reject"
      out[paste0(kind, "_st_st")] <- st[[4]] == "reject"
    }
    out
  })
}

# ---- boot.lasso.proj / lasso.proj -------------------------------------------------

boot_metrics <- function(fit, beta, S0) {
  ind <- covers(confint(fit)[, 1], confint(fit)[, 2], beta)
  joint <- quiet(confint(fit, type = "simultaneous"))
  c(ind_cov = mean(ind), ind_cov_S0 = na_if_empty(S0, mean(ind[S0])),
    joint_maxmin = all(covers(joint[, 1], joint[, 2], beta)),
    fwer_wy = any(fit$pval.corr[setdiff(seq_along(beta), S0)] <= ALPHA),
    power_wy = na_if_empty(S0, mean(fit$pval.corr[S0] <= ALPHA)),
    width = mean(confint(fit)[, 2] - confint(fit)[, 1]))
}

asym_metrics <- function(fit, beta, S0) {
  ci <- confint(fit)
  ind <- covers(ci[, 1], ci[, 2], beta)
  c(ind_cov = mean(ind), ind_cov_S0 = na_if_empty(S0, mean(ind[S0])),
    fwer_holm = any(fit$pval.corr[setdiff(seq_along(beta), S0)] <= ALPHA),
    power_holm = na_if_empty(S0, mean(fit$pval.corr[S0] <= ALPHA)),
    width = mean(ci[, 2] - ci[, 1]), s_hat = sum(fit$betahat != 0))
}

dbz_rep <- function(r, cell, setup) {
  spec <- DBZ_CELLS[[cell$design]]
  des <- setup$dbz[[cell$design]]
  S0 <- which(des$beta != 0)
  base <- cell$seed_base
  set.seed(rep_seed(base, r, "errors"))
  y <- drop(des$X %*% des$beta) + dbz_errors(spec, des$scale)
  out <- list()
  modes <- c(shortcut = TRUE, full = FALSE)[c(TRUE, spec$full)]
  for (mode in names(modes)) {
    for (divisor in c("n", "n-s")) {
      set.seed(rep_seed(base, r, "boot"))
      fit <- quiet(boot.lasso.proj(des$X, y, Z = des$Z$cv, B = B_DBZ, robust = TRUE,
                                   wild = spec$wild, boot.shortcut = modes[[mode]],
                                   robust.divisor = divisor, return.bootdist = TRUE))
      out[[paste("boot", mode, divisor, sep = "/")]] <- boot_metrics(fit, des$beta, S0)
    }
  }
  for (z in c("cv", "ZnZ")) {
    for (divisor in c("n", "n-s")) {
      set.seed(rep_seed(base, r, "asym"))
      fit <- quiet(lasso.proj(des$X, y, Z = des$Z[[z]], robust = TRUE,
                              suppress.grouptesting = TRUE, robust.divisor = divisor))
      out[[paste("asym", z, divisor, sep = "/")]] <- asym_metrics(fit, des$beta, S0)
    }
  }
  out
}
