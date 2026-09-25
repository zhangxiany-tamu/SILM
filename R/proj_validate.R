# Argument checks for lasso.proj() and boot.lasso.proj(). They reject only
# inputs on which hdi failed (often after the expensive nodewise step), so
# results for valid inputs are unchanged.

.check_proj_args <- function(x, y, family, standardize, multiplecorr.method, betainit, sigma,
                             Z, boot = FALSE, stub = FALSE) {
  if (boot && !identical(family, "gaussian")) {
    .stop("The function boot.lasso.proj is currently not supporting families other than 'gaussian'")
  }
  if (!is.character(family) || length(family) != 1L || !family %in% c("gaussian", "binomial")) {
    .stop("'family' must be \"gaussian\" or \"binomial\".")
  }
  x <- .check_X(x, "x")
  n <- nrow(x)
  p <- ncol(x)
  if (family == "binomial") {
    if (length(y) != n) .stop("'y' must have ", n, " elements (one per row of x).")
    y <- .binomial_response(y)
  } else {
    y <- .check_Y(y, n, "y")
  }
  .check_flag(standardize, "standardize")
  .multiplecorr_check(multiplecorr.method)

  if (is.null(Z)) {
    if (p < 3L) .stop("'x' must have at least 3 columns for the nodewise lasso (or supply 'Z').")
    if (n < 10L) {
      .stop("The nodewise lasso needs at least 10 observations (it uses 10-fold ",
            "cross-validation), or supply 'Z'.")
    }
  } else if (!is.matrix(Z) || !is.numeric(Z) || !all(dim(Z) == dim(x)) || anyNA(Z) ||
             any(!is.finite(Z))) {
    .stop("'Z' must be a finite numeric matrix of the same dimension as 'x'.")
  }
  constant <- .constant_columns(x)
  if (length(constant)) {
    .stop("Column(s) ", .column_labels(x, constant), " of 'x' are constant; remove them ",
          "(an intercept is added implicitly by centring).")
  }

  if (is.numeric(betainit)) {
    if (length(betainit) != p || anyNA(betainit) || any(!is.finite(betainit))) {
      .stop("A numeric 'betainit' must be a vector of length ncol(x) = ", p, ".")
    }
    if (boot && !stub) {
      .stop("We need to somehow specify the initial lasso method for the bootstrap! ",
            "Use betainit = \"cv lasso\" or \"scaled lasso\".")
    }
    if (is.null(sigma) && family != "binomial") {
      .stop("A numeric 'betainit' requires 'sigma' (the noise standard deviation).")
    }
    if (standardize && any(abs(apply(x, 2, sd) - 1) > 1e-8)) {
      warning("A numeric 'betainit' is used on the centred and scaled design ",
              "(standardize = TRUE): it must equal the coefficients on the original ",
              "scale multiplied by the column standard deviations.", call. = FALSE)
    }
  } else if (!is.character(betainit) || length(betainit) != 1L ||
             !betainit %in% c("scaled lasso", "cv lasso")) {
    .stop("The betainit argument needs to be either a vector of length ncol(x) or one of ",
          "'scaled lasso' or 'cv lasso'")
  }
  if (!is.null(sigma) && (!is.numeric(sigma) || length(sigma) != 1L || !is.finite(sigma) ||
                           !(sigma > 0))) {
    .stop("'sigma' must be a single positive finite number.")
  }
  list(x = x, y = y, sigma = sigma)
}

# 0/1 or logical flags of lasso.proj()/boot.lasso.proj(), checked under their
# user-facing names; returns the flags as logicals.
.check_proj_flags <- function(...) {
  flags <- list(...)
  lapply(stats::setNames(names(flags), names(flags)), function(nm) .check_flag01(flags[[nm]], nm))
}

.check_integer <- function(x, arg, what, min = 1) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < min || x != floor(x)) {
    .stop("'", arg, "' must be an integer >= ", min, " (", what, ").")
  }
  x
}

.check_divisor <- function(divisor, robust) {
  divisor <- match.arg(divisor, c("n", "n-s"))
  if (divisor != "n" && !isTRUE(as.logical(robust))) {
    warning("'robust.divisor' is only used with robust = TRUE.", call. = FALSE)
  }
  divisor
}
