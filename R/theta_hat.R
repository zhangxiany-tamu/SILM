#' Estimate of the inverse Gram matrix used by SR, Sim.CI and Step
#'
#' Returns the matrix \eqn{\hat\Theta} that [SR()], [Sim.CI()] and [Step()]
#' use to de-bias the scaled lasso: the inverse of the Gram matrix
#' \eqn{X^\top X / n} when `p <= floor(n/2)`, and the nodewise lasso estimate
#' otherwise (Zhang and Cheng, 2017). Because \eqn{\hat\Theta} depends only on
#' the design, it can be computed once and passed to several calls through
#' their `Theta` argument.
#'
#' The nodewise lasso draws the cross-validation folds from the random number
#' generator. Supplying `Theta` therefore skips that draw, so the bootstrap
#' draws of a subsequent call differ from those of a call that computes
#' \eqn{\hat\Theta} itself under the same seed.
#'
#' @inheritParams SR
#' @return A p x p matrix with attributes `method` (`"inverse-gram"` or
#'   `"nodewise"`) and, for the nodewise lasso, `lambda` (the tuning parameter
#'   used).
#' @inherit SR references
#' @examples
#' set.seed(1)
#' X <- matrix(rnorm(40 * 60), 40, 60)
#' Y <- X[, 1] + rnorm(40)
#' Theta <- Theta.hat(X)
#' attr(Theta, "method")
#' SR(X, Y, Theta = Theta)
#' @export
Theta.hat <- function(X, nodewise = c("cv", "ZnZ"), center = FALSE, parallel = FALSE,
                      ncores = getOption("mc.cores", 2L)) {
  nodewise <- match.arg(nodewise)
  X <- .check_X(X)
  if (.check_flag(center, "center")) X <- X - rep(colMeans(X), each = nrow(X))
  n <- dim(X)[1]
  .silm_theta(X, t(X)%*%X/n, nodewise, parallel = .check_flag(parallel, "parallel"),
              ncores = ncores)
}
