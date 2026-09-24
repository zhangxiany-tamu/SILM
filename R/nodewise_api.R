# Nodewise lasso: the single entry point used by SR(), ST(), Sim.CI(), Step(),
# lasso.proj() and boot.lasso.proj().
#
# Adapted from the 'hdi' package, version 0.1-10 (R/helpers.nodewise.R,
# written by Ruben Dezeure; hdi is Copyright (C) L. Meier, R. Dezeure,
# N. Meinshausen, M. Maechler and P. Buehlmann, GPL). Modifications for SILM:
# the Z&Z choice is an explicit, required argument (hdi 0.1-7 changed its
# default silently); the cross-validation folds can be supplied; parallel
# execution goes through .silm_mapply(); progress messages are only printed
# when verbose = TRUE; unreachable branches were removed. The numerical
# computations are unchanged. See inst/COPYRIGHTS.
#
# References:
#   Meinshausen, N. and Buehlmann, P. (2006). High-dimensional graphs and
#     variable selection with the lasso. Annals of Statistics, 34, 1436-1462.
#   van de Geer, S., Buehlmann, P., Ritov, Y. and Dezeure, R. (2014). On
#     asymptotically optimal confidence regions and tests for high-dimensional
#     models. Annals of Statistics, 42, 1166-1202.

#' Nodewise lasso regressions
#'
#' Chooses one tuning parameter for all nodewise lasso regressions of the
#' columns of `x` on the remaining columns (pooled K-fold cross-validation over
#' a common lambda grid, optionally refined by the Z&Z rule) and returns either
#' the matrix Theta (approximate inverse of the Gram matrix) or the rescaled
#' nodewise residuals Z.
#'
#' @param x Numeric matrix (n x p), p >= 2. Used as given (no centring).
#' @param what `"Theta"` or `"Z"`.
#' @param do_znz Logical, required. `TRUE` picks lambda with the Z&Z rule
#'   (as hdi >= 0.1-7 did by default); `FALSE` uses the cross-validated
#'   lambda.min times `lambdatuningfactor` (hdi 0.1-6 behaviour).
#' @param K Number of cross-validation folds.
#' @param foldid Optional fold assignment (integer vector of length n). When
#'   `NULL`, it is drawn as `sample(rep(1:K, length = n))`, which is the only
#'   random number generation in this function.
#' @param lambdatuningfactor Multiplier for lambda.min, or `"lambda.1se"`.
#' @param parallel,ncores Parallel execution over columns (no effect on the
#'   results; never used on Windows).
#' @param verbose Print diagnostic information (lambda grid, chosen lambda).
#' @param cv_verbose Print the progress of the cross-validation.
#' @return A list with `out` (Theta, or `list(Z, scaleZ)`), `bestlambda`,
#'   `lambdas`, `lambda.min`, `lambda.1se` and `foldid`.
#' @noRd
.nodewise <- function(x, what = c("Theta", "Z"), do_znz, K = 10L, foldid = NULL,
                      lambdatuningfactor = 1, parallel = FALSE, ncores = 1L,
                      verbose = FALSE, cv_verbose = verbose) {
  what <- match.arg(what)
  if (missing(do_znz) || !is.logical(do_znz) || length(do_znz) != 1L || is.na(do_znz)) {
    stop("'do_znz' must be TRUE or FALSE.", call. = FALSE)
  }
  lambdas <- nodewise.getlambdasequence(x)
  if (verbose) cat("Using the following lambda values:", lambdas, "\n")

  cv <- cv.nodewise.bestlambda(lambdas = lambdas, x = x, K = K, foldid = foldid,
                               parallel = parallel, ncores = ncores, verbose = cv_verbose)
  if (verbose) {
    cat(paste("lambda.min is", cv$lambda.min), "\n")
    cat(paste("lambda.1se is", cv$lambda.1se), "\n")
  }

  bestlambda <- .nodewise_pick_lambda(x, lambdas, cv, do_znz, lambdatuningfactor,
                                      parallel, ncores, verbose)
  out <- if (what == "Theta") {
    score.getThetaforlambda(x = x, lambda = bestlambda, parallel = parallel,
                            ncores = ncores, verbose = verbose)
  } else {
    score.getZforlambda(x = x, lambda = bestlambda, parallel = parallel, ncores = ncores)
  }
  list(out = out, bestlambda = bestlambda, lambdas = lambdas,
       lambda.min = cv$lambda.min, lambda.1se = cv$lambda.1se, foldid = cv$foldid)
}

.nodewise_pick_lambda <- function(x, lambdas, cv, do_znz, lambdatuningfactor,
                                  parallel, ncores, verbose) {
  if (do_znz) {
    bestlambda <- improve.lambda.pick(x = x, parallel = parallel, ncores = ncores,
                                      lambdas = lambdas, bestlambda = cv$lambda.min,
                                      verbose = verbose)
    if (verbose) {
      cat("Doing Z&Z technique for picking lambda\n")
      cat("The new lambda is", bestlambda, "\n")
      cat("In comparison to the cross validation lambda, lambda = c * lambda_cv\n")
      cat("c=", bestlambda / cv$lambda.min, "\n")
    }
  } else if (identical(lambdatuningfactor, "lambda.1se")) {
    if (verbose) cat("lambda.1se used for nodewise tuning\n")
    bestlambda <- cv$lambda.1se
  } else {
    if (verbose) cat("lambdatuningfactor used is", lambdatuningfactor, "\n")
    bestlambda <- cv$lambda.min * lambdatuningfactor
  }
  if (verbose) cat("Picked the best lambda:", bestlambda, "\n")
  bestlambda
}

# Z for lasso.proj()/boot.lasso.proj(): compute it with the nodewise lasso, or
# check and rescale a user-supplied Z so that t(Z_j) x_j / n = 1.
calculate.Z <- function(x, parallel, ncores, verbose, Z, do.ZnZ = FALSE, foldid = NULL) {
  if (is.null(Z)) {
    if (verbose) {
      message("Nodewise regressions will be computed as no argument Z was provided.")
      message("You can store Z to avoid the majority of the computation next time around.")
      message("Z only depends on the design matrix x.")
    }
    # As in hdi, `verbose` only shows the progress of the cross-validation.
    nodewise <- .nodewise(x, what = "Z", do_znz = do.ZnZ, foldid = foldid,
                          parallel = parallel, ncores = ncores, verbose = FALSE,
                          cv_verbose = verbose)
    return(list(Z = nodewise$out$Z, scaleZ = nodewise$out$scaleZ))
  }
  scaleZ <- rep(1, ncol(Z))
  if (!isTRUE(all.equal(rep(1, ncol(x)), colSums(Z * x) / nrow(x), tolerance = 10^-8))) {
    rescale.out <- score.rescale(Z = Z, x = x)
    Z <- rescale.out$Z
    scaleZ <- rescale.out$scaleZ
  }
  list(Z = Z, scaleZ = scaleZ)
}
