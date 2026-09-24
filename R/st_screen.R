# Helpers for the screening step of ST() (Zhang and Cheng, 2017, Section 5.3).

# Centre each column and scale it to unit Euclidean norm. (Numerically
# identical to SIS::standardize, which SILM 1.0.0 used for the screening
# statistic, so the screened sets are unchanged.)
.standardize_unitnorm <- function(X) {
  centred <- sweep(X, 2, colMeans(X))
  norms <- sqrt(apply(centred, 2, crossprod))
  sweep(centred, 2, norms, "/")
}

# Sub-sample size |D1|: a count, or a proportion of n when in (0, 1).
.st_subsample_size <- function(sub.size, n) {
  if (!is.numeric(sub.size) || length(sub.size) != 1L || !is.finite(sub.size) || sub.size <= 0) {
    .stop("'sub.size' must be a positive number (a count, or a proportion of n).")
  }
  n1 <- if (sub.size < 1) floor(sub.size * n + sqrt(.Machine$double.eps)) else floor(sub.size)
  if (n1 < 2 || n - n1 < 3) {
    .stop("'sub.size' must leave at least 2 observations for screening and 3 for ",
          "testing (n = ", n, ", floor(sub.size) = ", n1, ").")
  }
  n1
}

# Screening on the first sub-sample D1: the cross-validated lasso selects set1;
# the remaining variables are ranked by their standardized correlation with
# the lasso residuals, and the top k = n0 - 1 - |set1| are added, so that the
# screened set has size |D2| - 1 (Section 5.3).
.st_screen <- function(X.sub, Y.sub, n0, legacy) {
  p <- dim(X.sub)[2]
  cvfit <- cv.glmnet(X.sub, Y.sub, intercept=FALSE)
  cf <- as.numeric(coef(cvfit, s="lambda.min"))[-1]
  set1 <- (1:p)[abs(cf)>0]
  resi <- Y.sub-X.sub%*%cf
  k <- n0-1-length(set1)
  if (k < 0) {
    .stop("The screening lasso selected ", length(set1), " variables, more than |D2| - 1 = ",
          n0 - 1, "; use a smaller 'sub.size' (Zhang and Cheng (2017) use n/5 to n/3).")
  }
  a <- setdiff(seq_len(p), set1)
  if (!length(a)) return(set1)
  beta.m <- t(.standardize_unitnorm(X.sub[, a, drop = FALSE]))%*%resi
  ranked <- order(abs(beta.m),decreasing=TRUE)
  # SILM 1.0.0 indexed with 1:k, which keeps one variable when k = 0.
  top <- if (legacy && k == 0) ranked[1] else ranked[seq_len(min(k, length(a)))]
  union(a[sort(top)],set1)
}

# Remove screened variables that are constant on D2 (the nodewise lasso cannot
# regress on a constant response); SILM 1.0.0 stopped with an error.
.st_drop_constant <- function(X.f, S1, screen.set) {
  constant <- .constant_columns(X.f[-S1, screen.set, drop = FALSE])
  if (length(constant)) {
    warning("Removed ", length(constant), " screened variable(s) that are constant on the ",
            "testing sub-sample: ", .column_labels(X.f, screen.set[constant]), ".", call. = FALSE)
    screen.set <- screen.set[-constant]
  }
  if (length(screen.set) < 2L) {
    .stop("Fewer than 2 variables remain after screening; the test cannot be computed.")
  }
  screen.set
}
