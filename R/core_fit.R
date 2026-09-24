# De-biased lasso fit shared by SR(), Sim.CI() and Step() (Zhang and Cheng,
# 2017, Sections 2 and 5). The arithmetic is exactly that of SILM 1.0.0, so
# results are unchanged.

# Theta: inverse of the Gram matrix when p <= n/2, otherwise the nodewise
# lasso estimate.
.silm_theta <- function(X, Gram, nodewise, force_nodewise = FALSE, parallel = FALSE,
                        ncores = 1L) {
  n <- dim(X)[1]
  p <- dim(X)[2]
  if (force_nodewise || p > floor(n / 2)) {
    if (p < 3L) .stop("The nodewise lasso needs at least 3 columns.")
    if (n < 10L) {
      .stop("The nodewise lasso needs at least 10 observations (it uses 10-fold ",
            "cross-validation).")
    }
    constant <- .constant_columns(X)
    if (length(constant)) {
      .stop("Column(s) ", .column_labels(X, constant), " of the design are constant; ",
            "remove them (the model has no intercept; see 'center').")
    }
    node <- .nodewise(X, what = "Theta", do_znz = identical(nodewise, "ZnZ"),
                      parallel = parallel, ncores = ncores)
    Theta <- node$out
    attr(Theta, "lambda") <- node$bestlambda
    attr(Theta, "method") <- "nodewise"
    return(Theta)
  }
  Theta <- tryCatch(solve(Gram), error = function(e) {
    .stop("The Gram matrix t(X) %*% X / n is singular (p <= n/2, so Theta is its ",
          "inverse): the columns of X are linearly dependent. Remove redundant columns. (",
          conditionMessage(e), ")")
  })
  attr(Theta, "method") <- "inverse-gram"
  Theta
}

.strip_theta_attr <- function(Theta) {
  attr(Theta, "lambda") <- NULL
  attr(Theta, "method") <- NULL
  attr(Theta, "center") <- NULL
  Theta
}

# A Theta from Theta.hat() records whether X was centred; warn on a mismatch.
.check_theta_center <- function(Theta, center) {
  used <- attr(Theta, "center")
  if (!is.null(used) && !identical(used, center)) {
    warning("'Theta' was computed with center = ", used, " but is used with center = ",
            center, "; compute it with Theta.hat(X, center = ", center, ").", call. = FALSE)
  }
  invisible(NULL)
}

# Scaled lasso, variance estimate, de-biased lasso and its variances.
.silm_fit <- function(X, Y, nodewise, Theta = NULL, parallel = FALSE, ncores = 1L,
                      center = FALSE) {
  n <- dim(X)[1]
  p <- dim(X)[2]
  Gram <- t(X)%*%X/n
  Theta <- if (is.null(Theta)) {
    .strip_theta_attr(.silm_theta(X, Gram, nodewise, parallel = parallel, ncores = ncores))
  } else {
    .check_theta_center(Theta, center)
    .strip_theta_attr(.check_theta(Theta, p))
  }

  sreg <- .scaled_lasso(X, Y)
  beta.hat <- sreg$coefficients
  sigma.sq <- sum((Y-X%*%beta.hat)^2)/(n-sum(abs(beta.hat)>0))
  beta.db <- beta.hat+Theta%*%t(X)%*%(Y-X%*%beta.hat)/n
  Omega <- diag(Theta%*%Gram%*%t(Theta))*sigma.sq
  list(n = n, p = p, Gram = Gram, Theta = Theta, beta.hat = beta.hat,
       sigma.sq = sigma.sq, beta.db = beta.db, Omega = Omega)
}

# Burn k standard normal draws in chunks. Leaves the same RNG state as
# rnorm(k) (or as k / n calls of rnorm(n)), without allocating k numbers.
.burn_rnorm <- function(k, chunk = 2^20) {
  k <- as.numeric(k)
  while (k > 0) {
    m <- min(k, chunk)
    rnorm(m)
    k <- k - m
  }
  invisible(NULL)
}
