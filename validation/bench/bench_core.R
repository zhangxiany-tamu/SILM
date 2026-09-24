# Timing of the SILM core functions at a realistic size (n = 100, p = 500).
# Usage: Rscript validation/bench/bench_core.R [label]
source(file.path("validation", "paths.R"))
.libPaths(c(silm_dev_path("lib-glmnet-5.0"), silm_dev_path("lib-dev"), .libPaths()))
Sys.setenv(OPENBLAS_NUM_THREADS = "1")
suppressMessages(pkgload::load_all(".", quiet = TRUE))
set.seed(1)
n <- 100; p <- 500
X <- matrix(rnorm(n * p), n, p) %*% chol(0.9^abs(outer(1:p, 1:p, "-")))
Y <- as.vector(X[, 1:3] %*% c(1, 1.5, 2) + rt(n, 4) / sqrt(2))
set.seed(2)
th <- system.time(Theta <- Theta.hat(X))[["elapsed"]]
tm <- function(expr) system.time(expr)[["elapsed"]]
set.seed(3); t_ci <- tm(Sim.CI(X, Y, 1:p, M = 500, Theta = Theta))
set.seed(3); t_step <- tm(Step(X, Y, M = 500, Theta = Theta))
set.seed(3); t_sr <- tm(SR(X, Y, Theta = Theta))
cat(sprintf("%s: Theta.hat %.1fs | Sim.CI(set=1:p) %.2fs | Step %.2fs | SR %.2fs\n",
            commandArgs(TRUE)[1], th, t_ci, t_step, t_sr))
