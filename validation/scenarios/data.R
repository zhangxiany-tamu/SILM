# Data generators for the equivalence harness (run in the parent process).

toeplitz_sigma <- function(p, rho) rho^abs(outer(seq_len(p), seq_len(p), "-"))

exch_sigma <- function(p, rho) {
  s <- matrix(rho, p, p)
  diag(s) <- 1
  s
}

make_design <- function(n, p, design = "toeplitz", rho = 0.9) {
  if (design == "iid") return(matrix(rnorm(n * p), n, p))
  sigma <- switch(design,
    toeplitz = toeplitz_sigma(p, rho),
    exch = exch_sigma(p, rho),
    stop("unknown design ", design)
  )
  matrix(rnorm(n * p), n, p) %*% chol(sigma)
}

make_errors <- function(n, error = "t4") {
  switch(error,
    t4 = rt(n, 4) / sqrt(2),
    gamma = rgamma(n, 4, 2) - 2,
    gauss = rnorm(n),
    stop("unknown error ", error)
  )
}

# Linear model data; `beta` may be a numeric vector or a spec like "U(0,2)".
sim_linear <- function(n, p, design = "toeplitz", rho = 0.9, s0 = 3, beta = "U(0,2)",
                       error = "t4", y_matrix = FALSE, names = FALSE, y_scale = 1) {
  X <- make_design(n, p, design, rho)
  b <- rep(0, p)
  if (s0 > 0) {
    b[seq_len(s0)] <- if (is.numeric(beta)) {
      rep_len(beta, s0)
    } else {
      lim <- as.numeric(strsplit(gsub("[U() ]", "", beta), ",")[[1]])
      runif(s0, lim[1], lim[2])
    }
  }
  Y <- as.vector(X %*% b) * y_scale + make_errors(n, error) * y_scale
  if (y_matrix) Y <- matrix(Y, ncol = 1)
  if (names) {
    colnames(X) <- paste0("V", seq_len(p))
    if (y_matrix) colnames(Y) <- "y"
  }
  list(X = X, Y = Y, beta = b)
}

# Build a list of cases from a grid; the data are generated with data_seed.
make_cases <- function(grid, data_fun, method_seeds, label_fun = NULL) {
  cases <- list()
  for (i in seq_len(nrow(grid))) {
    g <- grid[i, , drop = FALSE]
    set.seed(10000L + i)
    data <- data_fun(g)
    for (s in method_seeds) {
      lab <- if (is.null(label_fun)) paste(names(g), unlist(g), sep = "=", collapse = ",") else label_fun(g)
      cases[[length(cases) + 1L]] <- list(
        data = data, args = as.list(g), seed = s, rng = "default",
        label = paste0(lab, ",seed=", s)
      )
    }
  }
  cases
}
