# Generate reference fixtures for tests/testthat from the ARCHIVED packages
# (SILM 1.0.0 with hdi 0.1-6 / 0.1-10, scalreg 1.0.1). The tests then compare
# the current code with these fixtures without needing the archived packages.
#
# Usage: Rscript validation/make_fixtures.R

source(file.path("validation", "harness.R"))
glmnet_lib <- silm_dev_path("lib-glmnet-5.0")
out_dir <- file.path("tests", "testthat", "fixtures")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

sim <- function(n, p, s0, seed) {
  set.seed(seed)
  X <- matrix(rnorm(n * p), n, p) %*% chol(0.9^abs(outer(1:p, 1:p, "-")))
  b <- c(runif(s0, 1, 2), rep(0, p - s0))
  list(X = X, Y = as.vector(X %*% b + rt(n, 4) / sqrt(2)))
}
d_small <- sim(60, 10, 3, 101)   # p <= n/2: Theta = inverse Gram
d_wide <- sim(50, 40, 3, 102)    # p > n/2: nodewise lasso

# Each fixture: SILM function, data, arguments (shared by old and new code) and
# SILM-only arguments for the new code. `mode` selects the archived hdi.
core <- list()
for (mode in c("cv", "znz")) {
  new_nw <- list(nodewise = if (mode == "cv") "cv" else "ZnZ")
  for (dn in c("small", "wide")) {
    d <- if (dn == "small") d_small else d_wide
    core <- c(core, list(
      list(id = sprintf("SR-%s-%s", dn, mode), mode = mode, fun = "SR", data = d, args = list(), new_args = new_nw),
      list(id = sprintf("SimCI-%s-%s", dn, mode), mode = mode, fun = "Sim.CI", data = d,
           args = list(set = 1:5, M = 50, alpha = 0.95), new_args = new_nw),
      list(id = sprintf("Step-%s-%s", dn, mode), mode = mode, fun = "Step", data = d,
           args = list(M = 50, alpha = 0.1), new_args = new_nw),
      list(id = sprintf("ST-%s-%s", dn, mode), mode = mode, fun = "ST", data = d,
           args = list(sub.size = 15, test.set = 4:ncol(d$X), M = 50),
           new_args = c(new_nw, list(legacy = TRUE)))
    ))
  }
}
set.seed(103)
xp <- matrix(rnorm(50 * 15), 50, 15)
dp <- list(x = xp, y = as.vector(xp[, 1:2] %*% c(1.5, -1) + rnorm(50)))
set.seed(104)
xb <- matrix(rnorm(80 * 8), 80, 8)
db <- list(x = xb, y = rbinom(80, 1, plogis(-0.5 + xb[, 1])))
proj <- list(
  list(id = "lasso.proj-default", fun = "lasso.proj", data = dp, args = list()),
  list(id = "lasso.proj-WY-robust", fun = "lasso.proj", data = dp,
       args = list(multiplecorr.method = "WY", robust = TRUE, N = 2000)),
  list(id = "lasso.proj-scaled", fun = "lasso.proj", data = dp, args = list(betainit = "scaled lasso")),
  list(id = "lasso.proj-binomial-legacy", fun = "lasso.proj", data = db,
       args = list(family = "binomial"), new_args = list(legacy = TRUE)),
  list(id = "boot-default", fun = "boot.lasso.proj", data = dp, args = list(B = 30)),
  list(id = "boot-wild-robust-bootdist", fun = "boot.lasso.proj", data = dp,
       args = list(B = 30, wild = TRUE, robust = TRUE, return.bootdist = TRUE), ci = TRUE),
  list(id = "boot-shortcut-holm", fun = "boot.lasso.proj", data = dp,
       args = list(B = 30, boot.shortcut = TRUE, multiplecorr.method = "holm")),
  list(id = "boot-scaled", fun = "boot.lasso.proj", data = dp,
       args = list(B = 20, betainit = "scaled lasso"))
)
for (i in seq_along(proj)) proj[[i]]$mode <- "znz"

# Old side: run the archived function, extract comparable values.
old_run <- function(fx) {
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(20260924)
  if (fx$fun %in% c("lasso.proj", "boot.lasso.proj")) {
    fit <- suppressWarnings(suppressMessages(do.call(getExportedValue("hdi", fx$fun),
                                                     c(list(fx$data$x, fx$data$y), fx$args))))
    keep <- intersect(names(fit), c("pval", "pval.corr", "sigmahat", "sds", "bhat", "se",
                                    "betahat", "lambda", "cboot.dist", "cboot.dist.underH0c"))
    val <- unclass(fit)[keep]
    for (m in c("cboot.dist", "cboot.dist.underH0c")) {
      if (!is.null(val[[m]])) {
        colnames(val[[m]]) <- NULL
        if (is.null(rownames(val[[m]]))) dimnames(val[[m]]) <- NULL
      }
    }
    if (isTRUE(fx$ci)) val$ci <- stats::confint(fit, level = 0.9)
  } else {
    val <- suppressWarnings(suppressMessages(do.call(getExportedValue("SILM", fx$fun),
                                                     c(list(fx$data$X, fx$data$Y), fx$args))))
  }
  list(value = val, seed_after = .Random.seed,
       versions = vapply(c("SILM", "hdi", "scalreg", "glmnet", "lars"),
                         function(p) as.character(utils::packageVersion(p)), ""))
}

fingerprint <- function() {
  list(R = paste(R.version$major, R.version$minor, sep = "."), platform = R.version$platform,
       blas = extSoftVersion()[["BLAS"]], glmnet = as.character(utils::packageVersion("glmnet")),
       lars = as.character(utils::packageVersion("lars")))
}

all_fx <- c(core, proj)
for (fx in all_fx) {
  res <- callr::r(function(fx, old_run, fingerprint) {
    r <- old_run(fx)
    r$fingerprint <- fingerprint()
    r
  }, args = list(fx = fx, old_run = old_run, fingerprint = fingerprint),
  libpath = legacy_libpaths(fx$mode, glmnet_lib), env = c(callr::rcmd_safe_env(), OPENBLAS_NUM_THREADS = "1"))
  saveRDS(c(fx[c("id", "fun", "mode", "data", "args")], list(new_args = fx$new_args, ci = isTRUE(fx$ci)), res),
          file.path(out_dir, paste0(fx$id, ".rds")), compress = "xz")
  message("wrote ", fx$id)
}
