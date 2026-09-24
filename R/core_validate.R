# Input validation and preprocessing for SR(), ST(), Sim.CI() and Step().
#
# Validation only rejects inputs on which SILM 1.0.0 failed or returned
# meaningless results; valid inputs are passed through unchanged, so results
# stay identical to SILM 1.0.0.

.stop <- function(...) stop(..., call. = FALSE)

.check_X <- function(X, arg = "X") {
  if (is.data.frame(X)) X <- as.matrix(X)
  # Logical matrices were used as 0/1 by SILM 1.0.0 and hdi.
  if (is.matrix(X) && is.logical(X)) storage.mode(X) <- "double"
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
  # A logical response was used as 0/1 (dims and names are kept).
  if (is.logical(Y)) storage.mode(Y) <- "double"
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

# A set of variables for Sim.CI(): a logical vector of length p, or indices
# with R's subsetting semantics (as SILM 1.0.0 indexed with `set` directly:
# negative indices exclude, 0 is dropped, fractional indices are truncated).
# The result is the equivalent vector of positive indices, which selects the
# same elements.
.check_index_set <- function(set, p, arg = "set") {
  if (is.logical(set)) {
    if (length(set) != p || anyNA(set)) .stop("A logical '", arg, "' must have length p = ", p, ".")
    set <- which(set)
  }
  if (!is.numeric(set) || !length(set) || anyNA(set) || any(abs(set) >= p + 1) ||
      (any(set < 0) && any(set > 0))) {
    .stop("'", arg, "' must contain column indices between 1 and ", p,
          " (or only negative indices, to exclude columns).")
  }
  idx <- seq_len(p)[set]
  if (!length(idx)) .stop("'", arg, "' selects no variable.")
  idx
}

# test.set of ST(): SILM 1.0.0 intersected it with the screened variables, so
# entries that are not column indices (outside 1:p, fractional, NA) never
# matched; they are dropped with a warning. An empty result is allowed (the
# test statistic is then 0).
.check_test_set <- function(set, p, arg = "test.set") {
  if (is.logical(set)) {
    if (length(set) != p || anyNA(set)) .stop("A logical '", arg, "' must have length p = ", p, ".")
    return(which(set))
  }
  if (!is.numeric(set) || !length(set)) .stop("'", arg, "' must contain column indices.")
  ok <- !is.na(set) & set >= 1 & set <= p & set == floor(set)
  if (!all(ok)) {
    warning("Ignoring entries of '", arg, "' that are not column indices in 1:", p, ": ",
            paste(utils::head(set[!ok], 10), collapse = ", "), ".", call. = FALSE)
  }
  set[ok]
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

# Flags of the hdi-compatible functions: hdi also accepted 0/1.
.check_flag01 <- function(x, arg) {
  if (length(x) != 1L || !(is.logical(x) || is.numeric(x)) || is.na(x)) {
    .stop("'", arg, "' must be TRUE or FALSE.")
  }
  as.logical(x)
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
# centred. The thresholds are far in the tails of the sampling distribution for
# mean-zero data (false alarms: about 1e-4 for Y; much less for X).
.warn_uncentred <- function(X, Y) {
  n <- nrow(X)
  p <- ncol(X)
  sds <- apply(X, 2, sd)
  ok <- sds > 0
  x_score <- if (any(ok)) max(abs(colMeans(X)[ok]) / sds[ok]) else 0
  y_sd <- sd(as.numeric(Y))
  y_score <- if (y_sd > 0) abs(mean(Y)) / y_sd else 0
  if (x_score > 2 * sqrt(2 * log(2 * p) / n) || y_score > 4 / sqrt(n)) {
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
