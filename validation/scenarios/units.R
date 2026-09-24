# Group A: unit oracles for internal building blocks.
#   A1  SILM:::.scaled_lasso       vs scalreg::scalreg   (scalreg 1.0.1)
#   A2  SILM:::.standardize_unitnorm vs SIS::standardize
#   A3  SILM:::.nodewise           vs hdi:::score.nodewiselasso (0.1-10 and 0.1-6)

a1_cases <- function(tier) {
  grid <- expand.grid(n = c(20, 50, 100), p = c(1, 5, 40, 100, 300),
                      design = c("iid", "toeplitz", "dup", "nearcol"),
                      y_scale = c(1e-3, 1, 1e3), names = c(FALSE, TRUE),
                      stringsAsFactors = FALSE)
  grid <- grid[!(grid$p < 2 & grid$design %in% c("dup", "nearcol")), ]
  if (tier == "fast") {
    set.seed(99)
    grid <- grid[sort(sample(nrow(grid), 60)), ]
  }
  data_fun <- function(g) {
    X <- make_design(g$n, g$p, if (g$design %in% c("dup", "nearcol")) "iid" else g$design)
    if (g$design == "dup") X[, g$p] <- X[, 1]
    if (g$design == "nearcol") X[, g$p] <- X[, 1] + 1e-8 * rnorm(g$n)
    b <- c(runif(min(3, g$p), 1, 2), rep(0, g$p - min(3, g$p)))
    y <- (as.vector(X %*% b) + rt(g$n, 4) / sqrt(2)) * g$y_scale
    if (g$names) colnames(X) <- paste0("x", seq_len(g$p))
    list(X = X, y = y)
  }
  make_cases(grid, data_fun, method_seeds = 1)
}

old_A1 <- function(d, a) {
  fit <- scalreg::scalreg(d$X, d$y)
  list(coefficients = fit$coefficients, hsigma = fit$hsigma)
}
new_A1 <- function(d, a) {
  fit <- SILM:::.scaled_lasso(d$X, d$y)
  list(coefficients = fit$coefficients, hsigma = fit$hsigma)
}

a2_cases <- function(tier) {
  shapes <- list(c(50, 20), c(100, 1), c(30, 0), c(200, 500), c(15, 3))
  reps <- if (tier == "fast") 10 else 40
  cases <- list()
  set.seed(4242)
  for (r in seq_len(reps)) {
    sh <- shapes[[(r - 1) %% length(shapes) + 1]]
    X <- matrix(rnorm(sh[1] * sh[2], sd = 10^runif(1, -3, 3)), sh[1], sh[2])
    if (sh[2] >= 3 && r %% 3 == 0) X[, 2] <- 7  # constant column -> NaN in both
    cases[[r]] <- list(data = list(X = X), args = list(), seed = 1, rng = "default",
                       label = sprintf("%dx%d,r=%d", sh[1], sh[2], r))
  }
  cases
}
old_A2 <- function(d, a) SIS::standardize(d$X)
new_A2 <- function(d, a) SILM:::.standardize_unitnorm(d$X)

a3_cases <- function(tier) {
  designs <- list(list(n = 40, p = 30, design = "iid"), list(n = 60, p = 80, design = "toeplitz"))
  if (tier == "full") designs <- c(designs, list(list(n = 100, p = 150, design = "toeplitz")))
  cases <- list()
  k <- 0L
  for (dz in designs) {
    k <- k + 1L
    set.seed(3000L + k)
    X <- make_design(dz$n, dz$p, dz$design)
    for (znz in c(TRUE, FALSE)) for (s in if (tier == "full") 1:4 else 1:2) {
      cases[[length(cases) + 1L]] <- list(
        data = list(X = X), args = list(do_znz = znz), seed = s, rng = "default",
        label = sprintf("%dx%d %s, do.ZnZ=%s, seed=%d", dz$n, dz$p, dz$design, znz, s))
    }
  }
  cases
}
old_A3 <- function(d, a) {
  f <- utils::getFromNamespace("score.nodewiselasso", "hdi")
  args <- list(d$X, wantTheta = TRUE, verbose = FALSE, lambdaseq = "quantile", parallel = FALSE,
               ncores = 2, oldschool = FALSE, lambdatuningfactor = 1)
  if ("do.ZnZ" %in% names(formals(f))) args$do.ZnZ <- a$do_znz
  out <- suppressMessages(do.call(f, args))
  list(Theta = out$out, bestlambda = out$bestlambda)
}
new_A3 <- function(d, a) {
  out <- SILM:::.nodewise(d$X, what = "Theta", do_znz = a$do_znz)
  list(Theta = out$out, bestlambda = out$bestlambda)
}

unit_scenarios <- function(tier) {
  a3 <- a3_cases(tier)
  a3_cv <- Filter(function(cs) !cs$args$do_znz, a3)
  list(
    list(id = "A1-scaled-lasso", legacy_mode = "znz", cases = a1_cases(tier),
         old_fun = old_A1, new_fun = new_A1),
    list(id = "A2-standardize", legacy_mode = "znz", cases = a2_cases(tier),
         old_fun = old_A2, new_fun = new_A2),
    list(id = "A3-nodewise-hdi0.1-10", legacy_mode = "znz", cases = a3,
         old_fun = old_A3, new_fun = new_A3),
    list(id = "A3-nodewise-hdi0.1-6", legacy_mode = "cv", cases = a3_cv,
         old_fun = old_A3, new_fun = new_A3)
  )
}
