# Input validation and preprocessing for SR(), ST(), Sim.CI() and Step().
#
# Validation only rejects inputs on which SILM 1.0.0 failed or returned
# meaningless results; valid inputs are passed through unchanged, so results
# stay identical to SILM 1.0.0.

.stop <- function(...) stop(..., call. = FALSE)

.check_X <- function(X, arg = "X") {
  if (is.data.frame(X)) X <- as.matrix(X)
  if (!is.matrix(X) || !is.numeric(X)) .stop("'", arg, "' must be a numeric matrix.")
  if (nrow(X) < 2L || ncol(X) < 1L) .stop("'", arg, "' must have at least 2 rows and 1 column.")
  if (anyNA(X) || any(!is.finite(X))) .stop("'", arg, "' must not contain missing or infinite values.")
  X
}

# Y may be a numeric vector or an n x 1 matrix; it is returned as given
# (its dimnames propagate into the results, as in SILM 1.0.0).
.check_Y <- function(Y, n, arg = "Y") {
  if (is.data.frame(Y)) {
    if (ncol(Y) != 1L) .stop("'", arg, "' must be a vector or a single column.")
    Y <- as.matrix(Y)
  }
  if (!is.numeric(Y) || (is.matrix(Y) && ncol(Y) != 1L)) {
    .stop("'", arg, "' must be a numeric vector or a one-column matrix.")
  }
  if (length(Y) != n) .stop("'", arg, "' must have ", n, " elements (one per row of X).")
  if (anyNA(Y) || any(!is.finite(Y))) .stop("'", arg, "' must not contain missing or infinite values.")
  Y
}

.check_count <- function(M, arg = "M") {
  if (!is.numeric(M) || length(M) != 1L || !is.finite(M) || M < 1) {
    .stop("'", arg, "' must be a positive number of bootstrap replications.")
  }
  M
}

.check_level <- function(alpha, arg = "alpha") {
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) || alpha < 0 || alpha > 1) {
    .stop("'", arg, "' must be a single number between 0 and 1.")
  }
  alpha
}

# A set of variables: integer indices in 1:p, or a logical vector of length p.
# With ignore_out_of_range = TRUE (ST's test.set, which SILM 1.0.0 intersected
# with the screened set), indices outside 1:p are dropped with a warning.
.check_index_set <- function(set, p, arg = "set", ignore_out_of_range = FALSE) {
  if (is.logical(set)) {
    if (length(set) != p || anyNA(set)) .stop("A logical '", arg, "' must have length p = ", p, ".")
    set <- which(set)
  }
  if (!is.numeric(set) || !length(set) || anyNA(set) || any(set != floor(set))) {
    .stop("'", arg, "' must contain column indices between 1 and ", p, ".")
  }
  outside <- set < 1 | set > p
  if (any(outside)) {
    if (!ignore_out_of_range || all(outside)) {
      .stop("'", arg, "' must contain column indices between 1 and ", p, ".")
    }
    warning("Ignoring indices in '", arg, "' outside 1:", p, ": ",
            paste(utils::head(set[outside], 10), collapse = ", "), ".", call. = FALSE)
  }
  set
}

.check_theta <- function(Theta, p) {
  if (!is.matrix(Theta) || !is.numeric(Theta) || !all(dim(Theta) == p)) {
    .stop("'Theta' must be a numeric ", p, " x ", p, " matrix.")
  }
  if (anyNA(Theta) || any(!is.finite(Theta))) .stop("'Theta' must be finite.")
  Theta
}

.check_flag <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) .stop("'", arg, "' must be TRUE or FALSE.")
  x
}

.constant_columns <- function(X) {
  which(apply(X, 2, function(col) all(col == col[1])))
}

.column_labels <- function(X, idx) {
  labs <- colnames(X)[idx]
  if (is.null(labs)) labs <- idx
  paste(utils::head(labs, 10), collapse = ", ")
}

.center_xy <- function(X, Y) {
  X <- X - rep(colMeans(X), each = nrow(X))
  Y <- Y - mean(Y)
  list(X = X, Y = Y)
}

# The procedures assume a linear model without intercept, with centred
# covariates and response. Warn (once per call) when the data are clearly not
# centred; the threshold is far beyond sampling noise of mean-zero data.
.warn_uncentred <- function(X, Y) {
  n <- nrow(X)
  p <- ncol(X)
  sds <- apply(X, 2, sd)
  ok <- sds > 0
  x_score <- if (any(ok)) max(abs(colMeans(X)[ok]) / sds[ok]) else 0
  y_sd <- sd(as.numeric(Y))
  y_score <- if (y_sd > 0) abs(mean(Y)) / y_sd else 0
  if (x_score > 2 * sqrt(2 * log(2 * p) / n) || y_score > 3 / sqrt(n)) {
    warning("The columns of X and/or Y do not appear to be centred. The procedures ",
            "assume a linear model without intercept; consider 'center = TRUE' or ",
            "centring the data beforehand.", call. = FALSE)
  }
  invisible(NULL)
}

# Validate and (optionally) centre the data for SR(), Sim.CI() and Step().
.prepare_xy <- function(X, Y, center, xname = "X", yname = "Y") {
  X <- .check_X(X, xname)
  Y <- .check_Y(Y, nrow(X), yname)
  if (.check_flag(center, "center")) {
    return(.center_xy(X, Y))
  }
  .warn_uncentred(X, Y)
  list(X = X, Y = Y)
}
