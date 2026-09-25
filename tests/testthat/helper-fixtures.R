# Reference results of the archived packages (validation/make_fixtures.R):
# SILM 1.0.0 with hdi 0.1-6 ("cv") or 0.1-10 ("znz"), scalreg 1.0.1.

fixture_files <- function() {
  sort(list.files(test_path("fixtures"), pattern = "\\.rds$", full.names = TRUE))
}

# Run the current SILM on a fixture's inputs with the same seed and extract the
# same values as the archived run.
run_fixture <- function(fx) {
  withr::local_preserve_seed()
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(20260924)
  fun <- getExportedValue("SILM", fx$fun)
  if (fx$fun %in% c("lasso.proj", "boot.lasso.proj")) {
    # hdi divided the robust standard error by n; SILM's default
    # robust.divisor is "n-s" (equation 5 of Dezeure, Buehlmann and Zhang).
    new_args <- fx$new_args
    if (is.null(new_args$robust.divisor)) new_args$robust.divisor <- "n"
    fit <- suppressWarnings(suppressMessages(do.call(fun, c(list(fx$data$x, fx$data$y), fx$args,
                                                            new_args))))
    keep <- intersect(names(fit), c("pval", "pval.corr", "sigmahat", "sds", "bhat", "se",
                                    "betahat", "lambda", "cboot.dist", "cboot.dist.underH0c"))
    val <- unclass(fit)[keep]
    if (isTRUE(fx$ci)) val$ci <- stats::confint(fit, level = 0.9)
  } else {
    val <- suppressWarnings(suppressMessages(do.call(fun, c(list(fx$data$X, fx$data$Y), fx$args,
                                                            fx$new_args))))
  }
  list(value = val, seed_after = get(".Random.seed", globalenv()))
}

# Same platform (R version, BLAS, glmnet, lars) as the fixture: exact
# comparison. Otherwise continuous values within 1e-8 and discrete values
# (indices, decisions, counts) exactly.
same_platform <- function(fp) {
  identical(fp$R, paste(R.version$major, R.version$minor, sep = ".")) &&
    identical(fp$platform, R.version$platform) &&
    identical(fp$blas, extSoftVersion()[["BLAS"]]) &&
    identical(fp$glmnet, as.character(utils::packageVersion("glmnet"))) &&
    identical(fp$lars, as.character(utils::packageVersion("lars")))
}
