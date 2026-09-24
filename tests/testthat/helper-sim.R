# Simulated data used across the tests.
sim_data <- function(n = 100, p = 10, s0 = 3, rho = 0.9, beta = c(1, 2), error = c("t4", "gauss"),
                     seed = 1) {
  error <- match.arg(error)
  withr::local_seed(seed)
  sigma <- rho^abs(outer(seq_len(p), seq_len(p), "-"))
  X <- matrix(rnorm(n * p), n, p) %*% chol(sigma)
  b <- rep(0, p)
  if (s0 > 0) b[seq_len(s0)] <- runif(s0, beta[1], beta[2])
  eps <- if (error == "t4") rt(n, 4) / sqrt(2) else rnorm(n)
  list(X = X, Y = as.vector(X %*% b + eps), beta = b)
}

# RNG state after running `expr` from seed `seed`.
seed_after <- function(seed, expr) {
  withr::local_preserve_seed()
  set.seed(seed)
  force(expr)
  get(".Random.seed", globalenv())
}
