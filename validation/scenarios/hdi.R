# Groups C and D: lasso.proj() and boot.lasso.proj() against hdi 0.1-10.
#
# Both sides return the hdi fields (without `call`, hdi's group-test closures
# and SILM's additional fields) plus confint() output, so that identical()
# compares exactly the results hdi produced. hdi's bootstrap matrices carry
# meaningless column names (an artefact of mcmapply); they are removed.

hdi_fields <- c("pval", "pval.corr", "sigmahat", "standardize", "sds", "bhat", "se", "betahat",
                "family", "method", "B", "boot.shortcut", "lambda", "Z", "cboot.dist",
                "cboot.dist.underH0c")

extract_hdi_fit <- function(fit, a) {
  keep <- intersect(names(fit), hdi_fields)
  out <- unclass(fit)[keep]
  for (m in c("cboot.dist", "cboot.dist.underH0c")) {
    if (!is.null(out[[m]])) {
      colnames(out[[m]]) <- NULL
      if (is.null(rownames(out[[m]]))) dimnames(out[[m]]) <- NULL
    }
  }
  if (!is.null(out$Z)) out$Z <- unname(out$Z)
  ci <- list()
  if (isTRUE(a$ci)) {
    for (lev in a$levels %||% c(0.95, 0.8)) {
      ci[[as.character(lev)]] <- stats::confint(fit, level = lev)
      ci[[paste0(lev, "-parm")]] <- stats::confint(fit, parm = 1:3, level = lev)
    }
  }
  list(fit = out, ci = ci)
}

run_proj <- function(pkg, d, a) {
  fun <- getExportedValue(pkg, a$fun)
  call <- a$call
  # hdi's parallel bootstrap drew random numbers in worker processes and is not
  # reproducible; SILM's parallel results must equal hdi's sequential ones.
  if (pkg == "hdi" && identical(a$fun, "boot.lasso.proj")) call$parallel <- NULL
  args <- c(list(d$x, d$y), call)
  if (!is.null(a$Z_from)) {
    # Z computed by a first call with return.Z = TRUE (same package).
    zfit <- do.call(fun, c(list(d$x, d$y), a$Z_from, list(return.Z = TRUE)))
    args$Z <- zfit$Z
  }
  if (pkg == "SILM") args <- c(args, a$new_args)
  fit <- do.call(fun, args)
  extract_hdi_fit(fit, a)
}
old_proj <- function(d, a) run_proj("hdi", d, a)
new_proj <- function(d, a) run_proj("SILM", d, a)

# The child processes only receive the functions and their enclosing
# environment; bind the helpers into one environment that is shipped along.
local({
  env <- new.env(parent = baseenv())
  env$`%||%` <- function(a, b) if (is.null(a)) b else a
  env$hdi_fields <- hdi_fields
  for (f in c("extract_hdi_fit", "run_proj", "old_proj", "new_proj")) {
    fn <- get(f, globalenv())
    environment(fn) <- env
    env[[f]] <- fn
    assign(f, fn, globalenv())
  }
})

hdi_data <- function() {
  set.seed(7001)
  xa <- matrix(rnorm(50 * 20), 50, 20)
  ya <- as.vector(xa[, 1:2] %*% c(1.5, -1) + rnorm(50))
  set.seed(7002)
  xb <- matrix(rnorm(100 * 60), 100, 60) %*% chol(0.9^abs(outer(1:60, 1:60, "-")))
  yb <- as.vector(xb[, 1:3] %*% c(1, 1.5, 2) + rt(100, 4) / sqrt(2))
  set.seed(7003)
  xbin <- matrix(rnorm(120 * 15), 120, 15)
  ybin <- rbinom(120, 1, plogis(-1 + xbin[, 1] - xbin[, 2]))
  set.seed(7004)
  xd <- matrix(rnorm(50 * 20), 50, 20) %*% chol(0.9^abs(outer(1:20, 1:20, "-")))
  yd <- as.vector(xd[, 1:3] %*% c(1, 1, 1) + rt(50, 4) / sqrt(2))
  set.seed(7005)
  xe <- matrix(rnorm(80 * 40), 80, 40)
  ye <- as.vector(xe[, 1:3] %*% c(1, 1, 1) + rnorm(80))
  list(Ca = list(x = xa, y = ya), Cb = list(x = xb, y = yb), Cbin = list(x = xbin, y = ybin),
       Da = list(x = xd, y = yd), Db = list(x = xe, y = ye))
}

lasso_proj_configs <- function() {
  L <- function(label, call = list(), ci = TRUE, Z_from = NULL, new_args = NULL, rng = "default") {
    list(label = label, call = call, ci = ci, Z_from = Z_from, new_args = new_args, rng = rng)
  }
  list(
    L("default"),
    L("WY", list(multiplecorr.method = "WY")),
    L("WY-suppress", list(multiplecorr.method = "WY", suppress.grouptesting = TRUE)),
    L("BH", list(multiplecorr.method = "BH")),
    L("bonferroni", list(multiplecorr.method = "bonferroni")),
    L("none", list(multiplecorr.method = "none")),
    L("scaled", list(betainit = "scaled lasso")),
    L("scaled-WY", list(betainit = "scaled lasso", multiplecorr.method = "WY")),
    L("robust", list(robust = TRUE)),
    L("robust-WY", list(robust = TRUE, multiplecorr.method = "WY")),
    L("nostd", list(standardize = FALSE)),
    L("nostd-robust", list(standardize = FALSE, robust = TRUE)),
    L("ZnZ", list(do.ZnZ = TRUE)),
    L("ZnZ-WY", list(do.ZnZ = TRUE, multiplecorr.method = "WY")),
    L("Z-supplied", list(), Z_from = list()),
    L("Z-supplied-WY-nostd", list(multiplecorr.method = "WY", standardize = FALSE),
      Z_from = list(standardize = FALSE)),
    L("return.Z", list(return.Z = TRUE)),
    L("sigma=1.5", list(sigma = 1.5)),
    L("N=2000-WY", list(multiplecorr.method = "WY", N = 2000)),
    L("parallel-2", list(parallel = TRUE, ncores = 2)),
    L("verbose", list(verbose = TRUE)),
    L("rng-3.5.0", list(), rng = "3.5.0")
  )
}

lasso_proj_binomial_configs <- function() {
  list(
    list(label = "binomial-legacy", call = list(family = "binomial"), ci = TRUE,
         new_args = list(legacy = TRUE), rng = "default"),
    list(label = "binomial-legacy-WY", call = list(family = "binomial", multiplecorr.method = "WY"),
         ci = TRUE, new_args = list(legacy = TRUE), rng = "default")
  )
}

boot_configs <- function(B) {
  D <- function(label, call = list(), ci = FALSE, Z_from = NULL, levels = NULL, rng = "default",
                new_args = NULL, allow_seed_diff = FALSE) {
    list(label = label, call = utils::modifyList(list(B = B), call), ci = ci, Z_from = Z_from,
         levels = levels, rng = rng, new_args = new_args, allow_seed_diff = allow_seed_diff)
  }
  list(
    D("default"),
    D("holm", list(multiplecorr.method = "holm")),
    D("BH-smallB", list(multiplecorr.method = "BH", B = 20)),
    D("wild", list(wild = TRUE)),
    D("wild-robust", list(wild = TRUE, robust = TRUE)),
    D("robust", list(robust = TRUE)),
    D("scaled", list(betainit = "scaled lasso")),
    D("scaled-shortcut", list(betainit = "scaled lasso", boot.shortcut = TRUE)),
    D("shortcut", list(boot.shortcut = TRUE)),
    D("nostd", list(standardize = FALSE)),
    D("Z-supplied", list(), Z_from = list(B = 2, multiplecorr.method = "holm")),
    D("bootdist", list(return.bootdist = TRUE, B = 100), ci = TRUE, levels = c(0.95, 0.5)),
    D("bootdist-wild-robust", list(return.bootdist = TRUE, wild = TRUE, robust = TRUE), ci = TRUE),
    D("return.Z", list(return.Z = TRUE)),
    D("stub", list(gaussian.stub = TRUE)),
    D("stub-holm", list(gaussian.stub = TRUE, multiplecorr.method = "holm")),
    D("sigma", list(sigma = 1)),
    D("parallel-2", list(parallel = TRUE, ncores = 2)),
    D("parallel-4-wild", list(parallel = TRUE, ncores = 4, wild = TRUE)),
    D("parallel-2-shortcut", list(parallel = TRUE, ncores = 2, boot.shortcut = TRUE)),
    D("rng-3.5.0", list(), rng = "3.5.0"),
    # SILM arguments passed explicitly at their defaults: must be identical.
    D("new-args-at-defaults", new_args = list(boot.type = "residual", multiplier = "gaussian",
                                              boot.H0c = TRUE, groups = list(1:3))),
    D("wild-via-boot.type", list(wild = TRUE), new_args = list(boot.type = "wild")),
    # Extra H0c pass with a p.adjust method: identical p-values, the RNG state
    # differs by the extra pass (enumerated ALLOWED difference).
    D("holm-with-H0c", list(multiplecorr.method = "holm"), new_args = list(boot.H0c = TRUE),
      allow_seed_diff = TRUE)
  )
}

make_proj_cases <- function(datasets, configs, fun, seeds) {
  cases <- list()
  for (dn in names(datasets)) for (cf in configs) for (s in seeds) {
    a <- cf
    a$fun <- fun
    cases[[length(cases) + 1L]] <- list(data = datasets[[dn]], args = a, seed = s, rng = cf$rng,
                                        label = sprintf("%s,%s,seed=%d", dn, cf$label, s))
  }
  cases
}

hdi_scenarios <- function(tier) {
  dat <- hdi_data()
  seeds <- if (tier == "full") 1:3 else 1:2
  lp_data <- if (tier == "full") dat[c("Ca", "Cb")] else dat["Ca"]
  bt_data <- if (tier == "full") dat[c("Da", "Db")] else dat["Da"]
  B <- if (tier == "full") 200 else 50
  list(
    list(id = "C-lasso.proj", legacy_mode = "znz",
         cases = make_proj_cases(lp_data, lasso_proj_configs(), "lasso.proj", seeds),
         old_fun = old_proj, new_fun = new_proj),
    list(id = "C-lasso.proj-binomial-legacy", legacy_mode = "znz",
         cases = make_proj_cases(dat["Cbin"], lasso_proj_binomial_configs(), "lasso.proj", seeds),
         old_fun = old_proj, new_fun = new_proj),
    list(id = "D-boot.lasso.proj", legacy_mode = "znz",
         cases = make_proj_cases(bt_data, boot_configs(B), "boot.lasso.proj", seeds[1]),
         old_fun = old_proj, new_fun = new_proj,
         allowed = function(old, new, case) {
           isTRUE(case$args$allow_seed_diff) && identical(old$value, new$value)
         })
  )
}
