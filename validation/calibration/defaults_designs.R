# Designs of the defaults study (see DEFAULTS.md): the simulation designs of
# Zhang and Cheng (2017, Section 5) and Dezeure, Buehlmann and Zhang (2017,
# Section 5.1), plus sign-alternating variants and the audit's stress designs.
# Every design, coefficient vector, Theta and Z is fixed by a seed; only the
# errors are redrawn in each replication.

N_ZC <- 100L

cov_toeplitz <- function(p, rho) rho^abs(outer(seq_len(p), seq_len(p), "-"))
cov_exch <- function(p, rho) {
  s <- matrix(rho, p, p)
  diag(s) <- 1
  s
}
rmvn <- function(n, sigma) matrix(rnorm(n * ncol(sigma)), n) %*% chol(sigma)

# Unit-variance errors.
t_errors <- function(n) rt(n, 4) / sqrt(2)

# ---- Zhang and Cheng: Sim.CI, Step, SR (nodewise cv vs ZnZ) -----------------

# Paper designs (replication/zc_targets.R): Toeplitz 0.9 and exchangeable 0.8,
# p = 120 and 500.
ZC_DESIGNS <- list(
  T120 = list(p = 120L, cov = "toeplitz", rho = 0.9, seed = 71001L),
  E120 = list(p = 120L, cov = "exchangeable", rho = 0.8, seed = 71002L),
  T500 = list(p = 500L, cov = "toeplitz", rho = 0.9, seed = 71003L),
  E500 = list(p = 500L, cov = "exchangeable", rho = 0.8, seed = 71004L)
)

zc_design_matrix <- function(d) {
  sigma <- if (d$cov == "toeplitz") cov_toeplitz(d$p, d$rho) else cov_exch(d$p, d$rho)
  set.seed(d$seed)
  rmvn(N_ZC, sigma)
}

# Coefficients on S0 = {1, ..., s0}: the paper's Unif[0, 2] draw ("positive")
# or the same magnitudes with alternating signs ("alternating"); and the
# audit's stress vectors (1.5, -1, 2) and (1.5, 1, 2).
zc_beta <- function(p, s0, sign, seed) {
  beta <- numeric(p)
  if (sign %in% c("stress_mixed", "stress_positive")) {
    beta[1:3] <- if (sign == "stress_mixed") c(1.5, -1, 2) else c(1.5, 1, 2)
    return(beta)
  }
  set.seed(seed)
  mag <- runif(s0, 0, 2)
  beta[seq_len(s0)] <- if (sign == "positive") mag else mag * rep_len(c(1, -1), s0)
  beta
}

# Sim.CI and Step: the paper's designs (Tables 1, 2 and 5) with positive and
# alternating signs, and the stress vectors at p = 120 (the audit's design)
# and p = 500.
ZC_CELLS <- rbind(
  expand.grid(design = names(ZC_DESIGNS), s0 = c(3L, 15L), sign = c("positive", "alternating"),
              stringsAsFactors = FALSE),
  expand.grid(design = c("T120", "T500"), s0 = 3L, sign = c("stress_mixed", "stress_positive"),
              stringsAsFactors = FALSE)
)
ZC_CELLS$name <- with(ZC_CELLS, paste("zc", design, paste0("s", s0), sign, sep = "_"))

# SR (Section 5.2): s0 coefficients Unif[2, 4] on a random support, drawn once
# per (design, s0).
SR_CELLS <- expand.grid(design = names(ZC_DESIGNS), s0 = c(3L, 15L), stringsAsFactors = FALSE)
SR_CELLS$name <- with(SR_CELLS, paste("sr", design, paste0("s", s0), sep = "_"))

sr_beta <- function(p, s0, seed) {
  set.seed(seed)
  beta <- numeric(p)
  beta[sort(sample.int(p, s0))] <- runif(s0, 2, 4)
  beta
}

# ST (Table 4, p. 34): p = 500; beta_j = sqrt(10 log(p) / n) on {1, ..., s0}
# (Toeplitz, case i, splitting proportion 1/5; s0 = 3 or 15) or
# 10 sqrt(log(p) / n) (exchangeable, case ii, proportion 1/3; s0 = 3); test
# sets {s0 + 1, ..., p} (size) and {s0, ..., p} (power).
ST_CELLS <- data.frame(design = c("T500", "T500", "E500"), case = c("i", "i", "ii"),
                       s0 = c(3L, 15L, 3L), sub = c(1 / 5, 1 / 5, 1 / 3), stringsAsFactors = FALSE)
ST_CELLS$name <- with(ST_CELLS, paste("st", design, paste0("s", s0), sep = "_"))

st_beta <- function(p, case, s0) {
  b <- if (case == "i") sqrt(10 * log(p) / N_ZC) else 10 * sqrt(log(p) / N_ZC)
  c(rep(b, s0), numeric(p - s0))
}

# ---- Dezeure, Buehlmann and Zhang: robust.divisor n vs n - s -----------------

# Section 5.1: n = 100, p = 500, Toeplitz 0.9, s0 = 3 active coefficients at
# random positions, several coefficient types; plus s0 = 15, an exchangeable
# design, the heteroscedastic example of Section 5.1.3 (n = 50, p = 250, no
# signal) and the audit's Toeplitz 0.5 stress design with heteroscedastic
# errors. Robust standard errors throughout (robust.divisor only acts there).
DBZ_CELLS <- list(
  T500_U22 = list(n = 100L, p = 500L, cov = "toeplitz", rho = 0.9, s0 = 3L, type = "U(-2,2)",
                  errors = "gaussian", wild = FALSE, full = TRUE, seed = 72001L),
  T500_U02 = list(n = 100L, p = 500L, cov = "toeplitz", rho = 0.9, s0 = 3L, type = "U(0,2)",
                  errors = "gaussian", wild = FALSE, full = FALSE, seed = 72002L),
  T500_fixed1 = list(n = 100L, p = 500L, cov = "toeplitz", rho = 0.9, s0 = 3L, type = "fixed1",
                     errors = "gaussian", wild = FALSE, full = FALSE, seed = 72003L),
  T500_s15 = list(n = 100L, p = 500L, cov = "toeplitz", rho = 0.9, s0 = 15L, type = "U(-2,2)",
                  errors = "gaussian", wild = FALSE, full = FALSE, seed = 72004L),
  E500_U22 = list(n = 100L, p = 500L, cov = "exchangeable", rho = 0.8, s0 = 3L, type = "U(-2,2)",
                  errors = "gaussian", wild = FALSE, full = FALSE, seed = 72005L),
  hetero_mammen93 = list(n = 50L, p = 250L, cov = "hetero", s0 = 0L, type = "none",
                         errors = "hetero", wild = TRUE, full = TRUE, seed = 72006L),
  T120_stress_wild = list(n = 100L, p = 120L, cov = "toeplitz", rho = 0.5, s0 = 3L,
                          type = "stress", errors = "x1", wild = TRUE, full = FALSE,
                          seed = 72007L)
)

dbz_beta <- function(type, p, s0) {
  beta <- numeric(p)
  if (type == "none") return(beta)
  if (type == "stress") {
    beta[1:3] <- c(1.5, -1, 2)
    return(beta)
  }
  vals <- switch(type, "U(-2,2)" = runif(s0, -2, 2), "U(0,2)" = runif(s0, 0, 2),
                 fixed1 = rep(1, s0), stop("unknown type ", type))
  beta[sample.int(p, s0)] <- vals
  beta
}

# Design, coefficients and the per-observation error scale of a DBZ cell.
dbz_design <- function(cell) {
  set.seed(cell$seed)
  if (cell$cov == "hetero") {
    # Section 5.1.3 (as resolved in replication/dbz_targets.R): rows N(0, I)
    # times Z_i / 2, Z_i ~ U(1, 3); Y_i = (Q_i + 1) eps_i with
    # Q_i = sum_{k <= 5} X_ik^2 - 13/3 and a mean-zero normal mixture eps_i.
    zz <- runif(cell$n, 1, 3)
    X <- matrix(rnorm(cell$n * cell$p), cell$n, cell$p) * (zz / 2)
    scale <- rowSums(X[, 1:5]^2) - 13 / 3 + 1
  } else {
    sigma <- if (cell$cov == "toeplitz") cov_toeplitz(cell$p, cell$rho) else cov_exch(cell$p, cell$rho)
    X <- rmvn(cell$n, sigma)
    scale <- if (cell$errors == "x1") {
      s <- 0.5 + abs(X[, 1])
      s / sqrt(mean(s^2))
    } else {
      rep(1, cell$n)
    }
  }
  list(X = X, beta = dbz_beta(cell$type, cell$p, cell$s0), scale = scale)
}

dbz_errors <- function(cell, scale) {
  n <- cell$n
  eps <- if (cell$errors == "hetero") {
    l <- rbinom(n, 1, 0.5)
    l * rnorm(n, 0.5, 1.2) + (1 - l) * rnorm(n, -0.5, 0.7)
  } else {
    rnorm(n)
  }
  scale * eps
}

# ---- setup: everything that depends only on the designs ------------------------

package_versions <- function() {
  c(R = R.version.string,
    vapply(c("SILM", "glmnet", "lars", "MASS"), function(p) format(utils::packageVersion(p)), ""))
}

# Theta (cv and ZnZ) for each ZC design, Z (cv and ZnZ) for each DBZ design.
study_setup <- function(cores) {
  par <- cores > 1L
  zc <- lapply(ZC_DESIGNS, function(d) {
    X <- zc_design_matrix(d)
    theta <- lapply(c(cv = "cv", ZnZ = "ZnZ"), function(nw) {
      set.seed(d$seed + 1e5)
      Theta.hat(X, nodewise = nw, parallel = par, ncores = cores)
    })
    list(X = X, theta = theta)
  })
  dbz <- lapply(DBZ_CELLS, function(cell) {
    des <- dbz_design(cell)
    des$Z <- lapply(c(cv = FALSE, ZnZ = TRUE), function(znz) {
      set.seed(cell$seed + 1e5)
      lasso.proj(des$X, rnorm(cell$n), return.Z = TRUE, suppress.grouptesting = TRUE,
                 do.ZnZ = znz, parallel = par, ncores = cores)$Z
    })
    des
  })
  list(zc = zc, dbz = dbz, versions = package_versions())
}
