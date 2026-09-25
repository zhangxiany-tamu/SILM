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
#'   `"ZnZ"` (default) refines the lambda minimising 10-fold cross-validation
#'   error pooled over all nodewise regressions with the rule of Zhang and
#'   Zhang (2014); `"cv"` uses that cross-validated lambda itself, as
#'   described in Zhang and Cheng (2017, Section 5). See the section
#'   "Nodewise tuning" below.
#' @param center Logical. If `TRUE`, the columns of `X` and `Y` are centred
#'   before the analysis. The default `FALSE` uses the data as given (as SILM
#'   1.0.0 did) and warns when they do not appear to be centred.
#' @param Theta Optional precomputed \eqn{\hat\Theta} (a p x p matrix, e.g.
#'   from [Theta.hat()]) to avoid recomputing it. Note that supplying it skips
#'   the random draw of the nodewise cross-validation folds, and that
#'   `nodewise` is then not used: the tuning rule is the one `Theta` was
#'   computed with. [Theta.hat()] records it (attribute `"nodewise"`), and a
#'   warning is given when `nodewise` is supplied explicitly and differs.
#' @param parallel,ncores Compute the nodewise regressions in parallel on
#'   `ncores` cores (forking; not on Windows). This does not change the
#'   results. With a BLAS library that uses OpenMP threads, forked workers can
#'   occasionally stall; setting the environment variable `OMP_NUM_THREADS=1`
#'   before starting R avoids this.
#' @return A list with two integer vectors: `"de-biased Lasso"`, the variables
#'   selected by the support recovery procedure, and `"scaled Lasso"`, the
#'   support of the scaled lasso.
#' @section Nodewise tuning:
#' SILM 1.0.0 obtained \eqn{\Theta} from an internal function of the 'hdi'
#' package. With hdi 0.1-6, current when SILM 1.0.0 was released (January
#' 2019), the tuning parameter was the cross-validated lambda described in
#' Zhang and Cheng (2017, Section 5) (`"cv"`). hdi 0.1-7 (March 2019)
#' silently changed the default of that internal function to the Z&Z rule,
#' so from then until SILM was archived (July 2026) SILM installations
#' computed `nodewise = "ZnZ"` without saying so.
#'
#' The default `"ZnZ"` of SILM 2.0.0 was chosen by a pre-registered study
#' that compared the two rules on the simulation designs of Zhang and Cheng
#' (2017) and on stress designs, under a decision rule fixed in advance
#' (calibration first, then power): over 20 `Sim.CI()`/`Step()` settings, 8 `SR()`
#' settings and 3 `ST()` settings (200 replications each), `"ZnZ"` halved the mean
#' calibration shortfall (coverage below 95%, error rates above 5%) from 0.100 to 0.053
#' (95% bootstrap interval of the difference: -0.051 to -0.044). The joint coverage of
#' `Sim.CI()` for all p coefficients was higher or equal in all 20 settings (for example
#' 0.77 with `"cv"` and 0.90 with `"ZnZ"` for signals (1.5, -1, 2) at p = 500), and exact
#' support recovery by `SR()` improved; the price is about 12% wider intervals and
#' 0.02-0.07 less power of `Step()` and `ST()` (see `validation/calibration/DEFAULTS.md`
#' and `validation/calibration/defaults-results/REPORT.md` in the source repository). With
#' the default, the results equal those of SILM 1.0.0 as
#' installed from 2019 to 2026 (with hdi 0.1-7 to 0.1-10; for `ST()` together
#' with `legacy = TRUE`). Use `nodewise = "cv"` for the tuning of the paper;
#' it reproduces SILM 1.0.0 with hdi 0.1-6. Both settings reproduce the
#' respective archived versions exactly (same numbers under the same random
#' seed).
#'
#' [lasso.proj()] and [boot.lasso.proj()] keep hdi's default for their
#' nodewise residuals (`do.ZnZ = FALSE`, the cross-validated lambda).
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
SR <- function(X, Y, nodewise = c("ZnZ", "cv"), center = FALSE, Theta = NULL,
               parallel = FALSE, ncores = getOption("mc.cores", 2L)) {
  nodewise_given <- !missing(nodewise)
  nodewise <- match.arg(nodewise)
  data <- .prepare_xy(X, Y, center)
  fit <- .silm_fit(data$X, data$Y, nodewise, Theta, .check_flag(parallel, "parallel"), ncores,
                   center = center, nodewise_given = nodewise_given)
  n <- fit$n
  p <- fit$p

  stat.st <- sqrt(n)*abs(fit$beta.db)/sqrt(fit$Omega)
  active.db <- (1:p)[stat.st>sqrt(2*log(p))]
  active.lasso <- (1:p)[abs(fit$beta.hat)>0]
  result <- list(active.db, active.lasso)
  names(result) <- c("de-biased Lasso", "scaled Lasso")
  result
}
