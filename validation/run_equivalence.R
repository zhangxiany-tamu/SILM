# Run the equivalence harness.
#
# Usage:
#   Rscript validation/run_equivalence.R [--tier fast|full] [--cores 8]
#       [--only REGEX] [--glmnet cran|user] [--self-test] [--no-st-legacy]
#       [--modes znz,cv] [--report-dir validation/reports]
#
#   --self-test     new side = current repository code that still depends on
#                   the archived packages (harness sanity check before the
#                   dependencies are removed); only "znz" scenarios are run.
#   --no-new-args   call the new functions with the old signatures only
#                   ("znz" scenarios; used before the nodewise argument exists).
#   --with-legacy-deps  also give the new side access to the archived packages
#                   (needed while the repository still declares them).
#   --glmnet cran   use the current CRAN glmnet from lib-glmnet-5.0 (default);
#   --glmnet user   use the glmnet of the user library instead.

source(file.path("validation", "harness.R"))
for (f in list.files(file.path("validation", "scenarios"), pattern = "\\.R$", full.names = TRUE)) {
  source(f)
}

parse_args <- function(args) {
  opt <- list(tier = "fast", cores = 8L, only = NULL, glmnet = "cran", self_test = FALSE,
              st_legacy = TRUE, modes = c("znz", "cv"), report_dir = file.path("validation", "reports"),
              chunk = 6L, legacy_deps = FALSE, no_new_args = FALSE)
  i <- 1L
  while (i <= length(args)) {
    a <- args[i]
    val <- if (i < length(args)) args[i + 1L] else NA_character_
    switch(a,
      "--tier" = { opt$tier <- val; i <- i + 1L },
      "--cores" = { opt$cores <- as.integer(val); i <- i + 1L },
      "--only" = { opt$only <- val; i <- i + 1L },
      "--glmnet" = { opt$glmnet <- val; i <- i + 1L },
      "--modes" = { opt$modes <- strsplit(val, ",")[[1]]; i <- i + 1L },
      "--report-dir" = { opt$report_dir <- val; i <- i + 1L },
      "--chunk" = { opt$chunk <- as.integer(val); i <- i + 1L },
      "--self-test" = { opt$self_test <- TRUE },
      "--with-legacy-deps" = { opt$legacy_deps <- TRUE },
      "--no-new-args" = { opt$no_new_args <- TRUE },
      "--no-st-legacy" = { opt$st_legacy <- FALSE },
      stop("unknown argument: ", a)
    )
    i <- i + 1L
  }
  if (opt$self_test || opt$no_new_args) opt$modes <- "znz"
  opt
}

all_scenarios <- function(opt) {
  sc <- list()
  if (exists("unit_scenarios") && !opt$self_test) sc <- c(sc, unit_scenarios(opt$tier))
  sc <- c(sc, core_scenarios(opt$tier, opt$modes, opt$self_test || opt$no_new_args, opt$st_legacy))
  if (exists("hdi_scenarios") && !opt$self_test) sc <- c(sc, hdi_scenarios(opt$tier))
  if (!is.null(opt$only)) sc <- Filter(function(s) grepl(opt$only, s$id), sc)
  sc
}

git_commit <- function() {
  sha <- tryCatch(system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE),
                  error = function(e) "unknown")
  dirty <- tryCatch(length(system2("git", c("status", "--porcelain", "--", "R", "DESCRIPTION",
                                            "NAMESPACE"), stdout = TRUE)) > 0,
                    error = function(e) FALSE)
  paste0(sha, if (dirty) "-dirty" else "")
}

main <- function() {
  opt <- parse_args(commandArgs(trailingOnly = TRUE))
  glmnet_lib <- if (opt$glmnet == "cran") silm_dev_path("lib-glmnet-5.0") else NULL
  extra_new <- if (opt$self_test || opt$legacy_deps) silm_dev_path("lib-legacy-znz") else NULL
  message("Installing the working tree into ", silm_dev_path("lib-new"))
  new_lib <- install_new(".", silm_dev_path("lib-new"), extra_libs = c(glmnet_lib, extra_new))
  scenarios <- all_scenarios(opt)
  message(sprintf("Running %d scenarios (%d cases) on %d cores, tier '%s'", length(scenarios),
                  sum(vapply(scenarios, function(s) length(s$cases), integer(1))), opt$cores, opt$tier))
  jobs <- chunk_scenarios(scenarios, size = opt$chunk)
  job_runs <- parallel::mclapply(jobs, run_scenario, new_lib = new_lib, glmnet_lib = glmnet_lib,
                                 extra_new_libs = extra_new, mc.cores = max(1L, opt$cores %/% 2L),
                                 mc.preschedule = FALSE)
  bad <- vapply(job_runs, function(r) inherits(r, "try-error"), logical(1))
  if (any(bad)) stop("scenario runner crashed: ", paste(job_runs[bad], collapse = "\n"))
  runs <- merge_runs(job_runs)

  versions <- runs[[1]]$versions_new
  meta <- list(
    date = format(Sys.time(), "%Y-%m-%d %H:%M"), commit = git_commit(), tier = opt$tier,
    r = paste(R.version$major, R.version$minor, sep = "."),
    glmnet = versions[["glmnet"]], lars = versions[["lars"]], blas = runs[[1]]$blas %||% "",
    silm_old = "1.0.0", hdi_znz = "0.1-10", hdi_cv = "0.1-6", scalreg = "1.0.1"
  )
  dir.create(opt$report_dir, showWarnings = FALSE, recursive = TRUE)
  stamp <- format(Sys.time(), "%Y%m%d-%H%M")
  base <- file.path(opt$report_dir, sprintf("equivalence-%s-%s%s", opt$tier, stamp,
                                            if (opt$self_test) "-selftest" else ""))
  tab <- write_report(runs, paste0(base, ".md"), meta)
  saveRDS(list(meta = meta, runs = runs), file.path(silm_dev_path("reports"), paste0(basename(base), ".rds")))
  print(tab, row.names = FALSE)
  message("Report: ", paste0(base, ".md"))
  if (sum(tab$FAIL) > 0) quit(status = 1L)
}

main()
