#' Support Recovery Procedure
#'
#' Implements the support recovery procedure of Zhang and Cheng (2017,
#' Section 3.1): variable \eqn{j} is selected when its studentized de-biased
#' lasso statistic \eqn{\sqrt{n}|\breve\beta_j|/\hat\omega_{jj}^{1/2}} exceeds
#' \eqn{\sqrt{2\log p}}.
#'
#' The model is \eqn{Y = X\beta + \epsilon} **without intercept**: the columns
#' of `X` and the response `Y` are assumed to be centred (use `center = TRUE`
#' to centre them), and `X` must not contain a column of ones. The initial
#' estimator is the scaled lasso (Sun and Zhang, 2012). When
#' `p <= floor(n/2)`, \eqn{\hat\Theta} is the inverse of the Gram matrix, so
#' the de-biased estimator equals the least-squares estimator (without
#' intercept); otherwise \eqn{\hat\Theta} is estimated by the nodewise lasso.
#'
#' @param X Design matrix (n x p).
#' @param Y Response variable (a numeric vector of length n, or an n x 1
#'   matrix).
#' @param nodewise Tuning rule for the nodewise lasso that estimates
#'   \eqn{\Theta} (the inverse of the Gram matrix) when `p > floor(n/2)`:
#'   `"cv"` (default) uses the lambda minimising 10-fold cross-validation
#'   error pooled over all nodewise regressions, as described in Zhang and
#'   Cheng (2017, Section 5); `"ZnZ"` refines that lambda with the rule of
#'   Zhang and Zhang (2014). See the section "Nodewise tuning" below.
#' @param center Logical. If `TRUE`, the columns of `X` and `Y` are centred
#'   before the analysis. The default `FALSE` uses the data as given (as SILM
#'   1.0.0 did) and warns when they do not appear to be centred.
#' @param Theta Optional precomputed \eqn{\hat\Theta} (a p x p matrix, e.g.
#'   from [Theta.hat()]) to avoid recomputing it. Note that supplying it skips
#'   the random draw of the nodewise cross-validation folds.
#' @param parallel,ncores Compute the nodewise regressions in parallel on
#'   `ncores` cores (forking; not on Windows). This does not change the
#'   results.
#' @return A list with two integer vectors: `"de-biased Lasso"`, the variables
#'   selected by the support recovery procedure, and `"scaled Lasso"`, the
#'   support of the scaled lasso.
#' @section Nodewise tuning:
#' SILM 1.0.0 obtained \eqn{\Theta} from an internal function of the 'hdi'
#' package. With hdi 0.1-6, current when SILM 1.0.0 was released (January
#' 2019), the tuning parameter was the cross-validated lambda (`"cv"`). hdi
#' 0.1-7 (March 2019) changed the default of that internal function to the
#' Z&Z rule, so from then until SILM was archived (July 2026) SILM computed
#' `nodewise = "ZnZ"` without saying so. SILM now follows the paper by
#' default; use `nodewise = "ZnZ"` to reproduce results obtained with SILM
#' 1.0.0 and hdi 0.1-7 to 0.1-10. Both settings reproduce the respective
#' archived versions exactly (same numbers under the same random seed).
#' @references Zhang, X., and Cheng, G. (2017) Simultaneous Inference for
#'   High-dimensional Linear Models, \emph{Journal of the American Statistical
#'   Association}, 112, 757-768.
#'
#'   Sun, T. and Zhang, C.-H. (2012). Scaled sparse linear regression.
#'   \emph{Biometrika}, 99, 879-898.
#'
#'   Zhang, C.-H. and Zhang, S. S. (2014). Confidence intervals for low
#'   dimensional parameters in high dimensional linear models. \emph{Journal
#'   of the Royal Statistical Society, Series B}, 76, 217-242.
#' @seealso [Sim.CI()], [Step()], [ST()], [Theta.hat()]
#' @examples
#' ## The function is intended for large n and p.
#' ## Use small p here for illustration purpose only.
#' set.seed(1)
#' n <- 100
#' p <- 10
#' s0 <- 7
#' set <- 1:s0
#' Sigma <- matrix(NA, p, p)
#' for (i in 1:p) Sigma[i,] <- 0.9^(abs(i-(1:p)))
#' X <- matrix(rnorm(n*p), n, p)
#' X <- t(t(chol(Sigma))%*%t(X))
#' beta <- rep(0,p)
#' beta[1:s0] <- runif(s0,1,2)
#' Y <- X%*%beta+rt(n,4)/sqrt(2)
#' SR(X, Y)
#' @export
SR <- function(X, Y, nodewise = c("cv", "ZnZ"), center = FALSE, Theta = NULL,
               parallel = FALSE, ncores = getOption("mc.cores", 2L)) {
  nodewise <- match.arg(nodewise)
  data <- .prepare_xy(X, Y, center)
  fit <- .silm_fit(data$X, data$Y, nodewise, Theta, .check_flag(parallel, "parallel"), ncores)
  n <- fit$n
  p <- fit$p

  stat.st <- sqrt(n)*abs(fit$beta.db)/sqrt(fit$Omega)
  active.db <- (1:p)[stat.st>sqrt(2*log(p))]
  active.lasso <- (1:p)[abs(fit$beta.hat)>0]
  result <- list(active.db, active.lasso)
  names(result) <- c("de-biased Lasso", "scaled Lasso")
  result
}
