# Validate the completeness and consistency of the saved fast-tier records.
# This verifies saved comparisons; it does not rerun model fits.
# Usage: Rscript validation/bugfix-20260929/verify-equivalence.R FILE.rds OUTDIR
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
invisible(parse("validation/run_equivalence.R"))
source("validation/harness.R")
x <- readRDS(args[1])
stopifnot(length(x$runs) == 23L)
for (run in x$runs) {
  stopifnot(length(run$rows) == length(run$cases),
            run$versions_old[["glmnet"]] == run$versions_new[["glmnet"]])
  for (row in run$rows) {
    if (row$status == "E0") {
      # max_abs_diff is NA for empty/non-numeric outputs (e.g. empty support).
      stopifnot(isTRUE(row$same_value), isTRUE(row$same_seed),
                is.na(row$max_abs_diff) || row$max_abs_diff == 0)
    } else if (row$status == "ALLOWED") {
      stopifnot(run$id == "D-boot.lasso.proj", isTRUE(row$same_value),
                identical(row$same_seed, FALSE), row$max_abs_diff == 0)
    } else if (row$status == "OLD-ERROR") {
      stopifnot(!is.na(row$old_error), is.na(row$new_error))
    } else if (row$status == "BOTH-ERROR") {
      stopifnot(!is.na(row$old_error), !is.na(row$new_error))
    } else stop("Unexpected comparison status: ", row$status)
  }
}
tab <- summarise_run(x$runs)
totals <- colSums(tab[c("cases", "E0", "ALLOWED", "OLD_ERROR", "BOTH_ERROR", "FAIL")])
stopifnot(identical(as.numeric(totals), c(662, 642, 1, 15, 4, 0)))
dir.create(args[2], showWarnings = FALSE, recursive = TRUE)
write.csv(tab, file.path(args[2], "equivalence-counts.csv"), row.names = FALSE)
# Retain compact comparison metadata and seeds, without repeated design arrays.
x$runs <- lapply(x$runs, function(run) {
  run$cases <- lapply(run$cases, function(case) { case$data <- NULL; case })
  run
})
saveRDS(x, file.path(args[2], "equivalence-records.rds"))
print(totals)
cat("All saved records are complete and consistent; current runner parses cleanly.\n")
