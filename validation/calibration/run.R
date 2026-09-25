# Calibration study: finite-sample coverage and error control of
# boot.lasso.proj() (fixed-lambda shortcut vs full refit; robust.divisor "n"
# vs "n-s") and of Sim.CI()/Step() (nodewise "cv" vs "ZnZ"), in response to
# the external audit of 2026-09-24. Not a paper replication: the designs
# follow the audit's diagnostic designs.
#
# Usage (one shard of the replications; see calibration.yml):
#   OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
#     Rscript validation/calibration/run.R --shard 1 --nshards 40 --cores 4 --out DIR
#
# Every replication has its own seed, so the shards can run anywhere and in any
# order. Within a replication, all methods see the same response and the same
# bootstrap draws (paired comparison).

suppressPackageStartupMessages(library(SILM))

N <- 100L
P <- 120L
R_DBZ <- 200L   # response replications per DBZ cell
R_ZC <- 300L    # response replications per ZC cell
B <- 499L       # bootstrap samples
M <- 999L       # Gaussian multiplier samples (Sim.CI, Step)
ALPHA <- 0.05
S0 <- 1:3

parse_args <- function(args) {
  opt <- list(shard = 1L, nshards = 1L, cores = 1L, out = "calibration-out")
  for (i in seq(1L, length(args), by = 2L)) {
    key <- sub("^--", "", args[i])
    if (!key %in% names(opt)) stop("unknown argument: ", args[i])
    opt[[key]] <- if (key == "out") args[i + 1L] else as.integer(args[i + 1L])
  }
  opt
}

toeplitz_design <- function(rho, seed) {
  set.seed(seed)
  matrix(rnorm(N * P), N) %*% chol(rho^abs(outer(1:P, 1:P, "-")))
}

quiet <- function(expr) suppressWarnings(suppressMessages(expr))
covers <- function(ci, beta) ci[, 1] <= beta & beta <= ci[, 2]

# ---- Dezeure, Buehlmann and Zhang (2017): boot.lasso.proj --------------------

dbz_setup <- function() {
  X <- toeplitz_design(0.5, 20260924)
  set.seed(20260925)
  Z <- lasso.proj(X, rnorm(N), return.Z = TRUE, suppress.grouptesting = TRUE)$Z
  beta <- c(1.5, -1, 2, rep(0, P - 3))
  hetero_sd <- 0.5 + abs(X[, 1])
  list(X = X, Z = Z, beta = beta,
       sd = list(homo = rep(1, N), hetero = hetero_sd / sqrt(mean(hetero_sd^2))))
}

dbz_metrics <- function(fit, asym, beta) {
  # Holm on the bootstrap p-values is not reported: with B = 499 their
  # resolution (1/500) is too coarse for a Bonferroni-type correction.
  ind <- covers(confint(fit), beta)
  asym_ind <- covers(confint(asym), beta)
  c(ind_cov = mean(ind), ind_cov_S0 = mean(ind[S0]),
    joint_maxmin = all(covers(quiet(confint(fit, type = "simultaneous")), beta)),
    joint_abs = all(covers(quiet(confint(fit, type = "simultaneous", simult.stat = "abs")), beta)),
    fwer_wy = any(fit$pval.corr[-S0] <= ALPHA), power_wy = mean(fit$pval.corr[S0] <= ALPHA),
    asym_ind_cov = mean(asym_ind), asym_ind_cov_S0 = mean(asym_ind[S0]),
    asym_fwer_holm = any(asym$pval.corr[-S0] <= ALPHA),
    asym_power_holm = mean(asym$pval.corr[S0] <= ALPHA))
}

# One replication of an error model: the same response and bootstrap draws for
# every method.
dbz_replication <- function(r, errors, setup) {
  wild <- errors == "hetero"
  set.seed(1e6 + r + if (wild) 5e5 else 0)
  y <- drop(setup$X %*% setup$beta) + setup$sd[[errors]] * rnorm(N)
  rows <- list()
  for (shortcut in c(TRUE, FALSE)) {
    for (divisor in c("n", "n-s")) {
      set.seed(2e6 + r)
      fit <- quiet(boot.lasso.proj(setup$X, y, Z = setup$Z, B = B, robust = TRUE, wild = wild,
                                   boot.shortcut = shortcut, robust.divisor = divisor,
                                   return.bootdist = TRUE))
      set.seed(3e6 + r)
      asym <- quiet(lasso.proj(setup$X, y, Z = setup$Z, robust = TRUE,
                               suppress.grouptesting = TRUE, robust.divisor = divisor))
      cell <- paste("dbz", errors, if (wild) "wild" else "residual",
                    if (shortcut) "shortcut" else "full", divisor, sep = "_")
      rows[[cell]] <- c(rep = r, dbz_metrics(fit, asym, setup$beta))
    }
  }
  rows
}

# ---- Zhang and Cheng (2017): Sim.CI and Step --------------------------------

zc_setup <- function() {
  X <- toeplitz_design(0.9, 20260926)
  theta <- lapply(c(cv = "cv", ZnZ = "ZnZ"), function(nw) {
    set.seed(20260927)
    Theta.hat(X, nodewise = nw)
  })
  list(X = X, theta = theta,
       beta = list(mixed = c(1.5, -1, 2, rep(0, P - 3)), positive = c(1.5, 1, 2, rep(0, P - 3))))
}

zc_replication <- function(r, setup) {
  rows <- list()
  for (signal in names(setup$beta)) {
    beta <- setup$beta[[signal]]
    set.seed(4e6 + r)
    y <- drop(setup$X %*% beta) + rt(N, 4) / sqrt(2)
    for (nw in names(setup$theta)) {
      set.seed(5e6 + r)
      ci <- quiet(Sim.CI(setup$X, y, 1:P, M = M, Theta = setup$theta[[nw]]))
      set.seed(6e6 + r)
      step <- quiet(Step(setup$X, y, M = M, Theta = setup$theta[[nw]]))
      rows[[paste("zc", signal, nw, sep = "_")]] <- c(
        rep = r,
        joint_nst = all(covers(t(ci$band.nst), beta)),
        joint_st = all(covers(t(ci$band.st), beta)),
        joint_nst_S0 = all(covers(t(ci$band.nst)[S0, , drop = FALSE], beta[S0])),
        joint_nst_S0c = all(covers(t(ci$band.nst)[-S0, , drop = FALSE], beta[-S0])),
        fwer_step_nst = any(step[[1]] > 3), fwer_step_st = any(step[[2]] > 3),
        power_step_nst = mean(S0 %in% step[[1]]), power_step_st = mean(S0 %in% step[[2]]))
    }
  }
  rows
}

# ---- driver -------------------------------------------------------------------

shard_reps <- function(R, shard, nshards) seq_len(R)[(seq_len(R) - 1L) %% nshards == shard - 1L]

run_reps <- function(reps, fun, cores, ...) {
  ans <- parallel::mclapply(reps, function(r) {
    tryCatch(fun(r, ...), error = function(e) structure(conditionMessage(e), class = "rep_error"))
  }, mc.cores = cores, mc.set.seed = FALSE)
  failed <- vapply(ans, inherits, logical(1), what = "rep_error")
  if (any(failed)) {
    stop(sum(failed), " replication(s) failed: ", paste(unique(unlist(ans[failed])), collapse = "; "))
  }
  cells <- names(ans[[1]])
  stats::setNames(lapply(cells, function(cell) do.call(rbind, lapply(ans, `[[`, cell))), cells)
}

main <- function() {
  opt <- parse_args(commandArgs(trailingOnly = TRUE))
  dir.create(opt$out, recursive = TRUE, showWarnings = FALSE)
  t0 <- proc.time()[["elapsed"]]
  zc <- run_reps(shard_reps(R_ZC, opt$shard, opt$nshards), zc_replication,
                 cores = opt$cores, setup = zc_setup())
  message(sprintf("ZC cells done after %.0f s", proc.time()[["elapsed"]] - t0))
  setup <- dbz_setup()
  dbz <- lapply(c(homo = "homo", hetero = "hetero"), function(errors) {
    run_reps(shard_reps(R_DBZ, opt$shard, opt$nshards), dbz_replication,
             cores = opt$cores, errors = errors, setup = setup)
  })
  message(sprintf("DBZ cells done after %.0f s", proc.time()[["elapsed"]] - t0))
  out <- c(zc, unlist(unname(dbz), recursive = FALSE))
  attr(out, "info") <- list(shard = opt$shard, nshards = opt$nshards, N = N, P = P, B = B, M = M,
                            R_DBZ = R_DBZ, R_ZC = R_ZC, silm = as.character(packageVersion("SILM")),
                            session = utils::capture.output(sessionInfo()))
  saveRDS(out, file.path(opt$out, sprintf("shard-%02d.rds", opt$shard)))
}

main()
