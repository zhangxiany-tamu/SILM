# Shared helpers for the replication of Zhang and Cheng (2017, JASA) and
# Dezeure, Buehlmann and Zhang (2017, TEST). Excluded from the package build.
#
# Conventions
# - Every script defines one or more targets and calls run_target().
# - Replication r uses set.seed(seed_base + r), so results do not depend on
#   the number of cores. Replications run in parallel with mclapply; each fit
#   runs sequentially (parallel = FALSE) with one BLAS thread.
# - Results are summarised per cell (never raw fits) into
#   replication/results/<target>.rds together with the session information.
# - Acceptance criteria are pre-registered in replication/CRITERIA.md.

source(file.path("validation", "paths.R"))
Sys.setenv(OPENBLAS_NUM_THREADS = "1", OMP_NUM_THREADS = "1")

# Load the SILM version of the working tree (installed by run.R into lib-rep).
load_silm <- function() {
  lib <- silm_dev_path("lib-rep")
  .libPaths(c(silm_dev_path("lib-glmnet-5.0"), lib, silm_dev_path("lib-dev"), .libPaths()))
  suppressPackageStartupMessages(library(SILM, lib.loc = lib))
  invisible(utils::packageVersion("SILM"))
}

rep_cores <- function() as.integer(Sys.getenv("SILM_REP_CORES", "10"))
rep_scale <- function() as.numeric(Sys.getenv("SILM_REP_SCALE", "1"))  # e.g. 0.05 for a smoke test

# Run `fun(r)` for r = 1..R in parallel; returns the list of results.
run_reps <- function(R, fun, seed_base, cores = rep_cores()) {
  R <- max(2L, as.integer(round(R * rep_scale())))
  one <- function(r) {
    set.seed(seed_base + r)
    tryCatch(fun(r), error = function(e) structure(list(msg = conditionMessage(e)), class = "rep_error"))
  }
  out <- parallel::mclapply(seq_len(R), one, mc.cores = cores, mc.preschedule = FALSE)
  bad <- vapply(out, function(o) inherits(o, "rep_error") || inherits(o, "try-error"), logical(1))
  if (any(bad)) {
    warning(sum(bad), " of ", R, " replications failed; first error: ",
            conditionMessage(attr(out[bad][[1]], "condition") %||% simpleError(out[bad][[1]]$msg)))
  }
  out[!bad]
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# Monte Carlo summary of a proportion (or mean) with its standard error.
mc_prop <- function(x) {
  x <- as.numeric(x)
  m <- mean(x)
  list(est = m, se = sqrt(m * (1 - m) / length(x)), n = length(x))
}
mc_mean <- function(x) {
  x <- as.numeric(x)
  list(est = mean(x), se = sd(x) / sqrt(length(x)), n = length(x))
}

# Pre-registered comparison of a proportion with a published value:
# |est - paper| <= 3 * sqrt(pbar (1 - pbar) (1/R + 1/R_paper)) + delta.
check_prop <- function(est, R, paper, R_paper, delta = 0.02) {
  pbar <- (est * R + paper * R_paper) / (R + R_paper)
  se_c <- sqrt(max(pbar * (1 - pbar), 1e-4) * (1 / R + 1 / R_paper))
  tol <- 3 * se_c + delta
  list(pass = abs(est - paper) <= tol, diff = est - paper, tol = tol)
}

# Toeplitz / exchangeable / block-diagonal covariance and designs.
cov_toeplitz <- function(p, rho = 0.9) rho^abs(outer(seq_len(p), seq_len(p), "-"))
cov_exch <- function(p, rho = 0.8) { s <- matrix(rho, p, p); diag(s) <- 1; s }
cov_block <- function(p, rho = 0.9, block = 5) {
  s <- diag(p)
  for (b in split(seq_len(p), ceiling(seq_len(p) / block))) s[b, b] <- rho
  diag(s) <- 1
  s
}
rmvn_design <- function(n, sigma) matrix(rnorm(n * ncol(sigma)), n) %*% chol(sigma)

save_target <- function(id, cells, meta = list()) {
  dir.create(file.path("replication", "results"), showWarnings = FALSE)
  obj <- list(id = id, cells = cells, meta = c(meta, list(
    date = format(Sys.time(), "%Y-%m-%d %H:%M"),
    commit = tryCatch(system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE), error = function(e) NA),
    silm = as.character(utils::packageVersion("SILM")),
    glmnet = as.character(utils::packageVersion("glmnet")),
    R = R.version.string, scale = rep_scale(), cores = rep_cores())))
  saveRDS(obj, file.path("replication", "results", paste0(id, ".rds")))
  invisible(obj)
}

# One row of the replication report: a pre-registered criterion and its verdict.
# `paper` may be NA for qualitative claims (then `ours` describes the result).
criterion_row <- function(target, cell, metric, paper, ours, se = NA_real_, tol = NA_real_,
                          pass, note = "") {
  data.frame(target = target, cell = cell, metric = metric, paper = paper, ours = ours,
             se = se, tol = tol, pass = as.logical(pass), note = note, stringsAsFactors = FALSE)
}

# Save a target's criteria table (and optional per-cell summaries).
save_criteria <- function(id, criteria, summaries = NULL, meta = list()) {
  save_target(id, cells = list(criteria = criteria, summaries = summaries), meta = meta)
}

# Riboflavin data (Buehlmann, Kalisch and Meier, 2014) from the archived hdi
# tarball in the development cache (not shipped with SILM).
load_riboflavin <- function() {
  tb <- file.path(silm_dev_path("archive"), "hdi_0.1-10.tar.gz")
  exdir <- silm_dev_path("riboflavin")
  f <- file.path(exdir, "hdi", "data", "riboflavin.RData")
  if (!file.exists(f)) utils::untar(tb, files = "hdi/data/riboflavin.RData", exdir = exdir)
  env <- new.env()
  load(f, envir = env)
  rb <- env$riboflavin
  list(x = as.matrix(rb$x), y = as.numeric(rb$y))
}
