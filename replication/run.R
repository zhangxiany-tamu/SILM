# Run replication targets.
#
# Usage: Rscript replication/run.R [--install] [--scale 1] [--cores 10] TARGET_SCRIPT...
#   --install   install the working tree into the replication library first
#   --scale s   multiply all replication counts by s (e.g. 0.02 for a smoke test)
#   TARGET_SCRIPT  e.g. replication/zc_table1_2.R (each writes results/<id>.rds)

args <- commandArgs(trailingOnly = TRUE)
opt <- list(install = FALSE, scale = "1", cores = "10", scripts = character())
i <- 1L
while (i <= length(args)) {
  a <- args[i]
  if (a == "--install") {
    opt$install <- TRUE
  } else if (a %in% c("--scale", "--cores")) {
    opt[[sub("--", "", a)]] <- args[i + 1L]
    i <- i + 1L
  } else {
    opt$scripts <- c(opt$scripts, a)
  }
  i <- i + 1L
}
Sys.setenv(SILM_REP_SCALE = opt$scale, SILM_REP_CORES = opt$cores)

source(file.path("validation", "harness.R"))
if (opt$install || !dir.exists(file.path(silm_dev_path("lib-rep"), "SILM"))) {
  message("Installing the working tree into ", silm_dev_path("lib-rep"))
  install_new(".", silm_dev_path("lib-rep"), extra_libs = silm_dev_path("lib-glmnet-5.0"))
}
for (s in opt$scripts) {
  message(format(Sys.time(), "%H:%M:%S"), " running ", s)
  t0 <- proc.time()[["elapsed"]]
  # Single-threaded BLAS in the script process: an OpenMP-threaded BLAS does not
  # survive fork(), so mclapply workers would hang after the first
  # multi-threaded BLAS call in the parent.
  status <- system2(file.path(R.home("bin"), "Rscript"), shQuote(s),
                    env = c(paste0("SILM_REP_SCALE=", opt$scale), paste0("SILM_REP_CORES=", opt$cores),
                            "OMP_NUM_THREADS=1", "OPENBLAS_NUM_THREADS=1"))
  message(sprintf("%s finished with status %s in %.1f min", s, status,
                  (proc.time()[["elapsed"]] - t0) / 60))
}
