#' Simultaneous Confidence Interval
#'
#' This function implements the method for constructing simultaneous confidence
#' interval in Zhang and Cheng (2017).
#'
#' @param X n times p design matrix.
#' @param Y Response variable.
#' @param set The set of variables of interest.
#' @param M The number of bootstrap replications (default 500).
#' @param alpha The nominal level alpha (default 0.95).
#' @param nodewise Tuning rule for the nodewise lasso that estimates
#'   \eqn{\Theta} (the inverse of the Gram matrix) when `p > floor(n/2)`:
#'   `"cv"` (default) uses the lambda minimising 10-fold cross-validation
#'   error pooled over all nodewise regressions, as described in Zhang and
#'   Cheng (2017, Section 5); `"ZnZ"` refines that lambda with the rule of
#'   Zhang and Zhang (2014). See the section "Nodewise tuning" below.
#' @return The de-biased Lasso estimator, the confidence bands (lower bound and
#'   upper bound) delivered by the non-studentized and the studentized
#'   statistics.
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
#'   Zhang, C.-H. and Zhang, S. S. (2014). Confidence intervals for low
#'   dimensional parameters in high dimensional linear models. \emph{Journal
#'   of the Royal Statistical Society, Series B}, 76, 217-242.
#' @examples
#' ## The function is intended for large n and p.
#' ## Use small p here for illustration purpose only.
#' n <- 100
#' p <- 10
#' s0 <- 3
#' set <- 1:s0
#' Sigma <- matrix(NA, p, p)
#' for (i in 1:p) Sigma[i,] <- 0.9^(abs(i-(1:p)))
#' X <- matrix(rnorm(n*p), n, p)
#' X <- t(t(chol(Sigma))%*%t(X))
#' beta <- rep(0,p)
#' beta[1:s0] <- runif(s0,0,2)
#' Y <- X%*%beta+rt(n,4)/sqrt(2)
#' Sim.CI(X, Y, set)
#' @export
Sim.CI <- function(X, Y, set, M=500, alpha=0.95, nodewise = c("cv", "ZnZ")) {
  nodewise <- match.arg(nodewise)

 n <- dim(X)[1]
 p <- dim(X)[2]
 Gram <- t(X)%*%X/n
 if (p > floor(n/2)) {
    node <- .nodewise(X, what = "Theta", do_znz = identical(nodewise, "ZnZ"))
    Theta <- node$out
 } else {
    Theta <- solve(Gram)
 }

  sreg <- .scaled_lasso(X, Y)
  beta.hat <- sreg$coefficients
  sigma.sq <- sum((Y-X%*%beta.hat)^2)/(n-sum(abs(beta.hat)>0))
  beta.db <- beta.hat+Theta%*%t(X)%*%(Y-X%*%beta.hat)/n
  Omega <- diag(Theta%*%Gram%*%t(Theta))*sigma.sq
  stat.boot.st <- stat.boot.nst <- rep(NA,M)

  for (i in 1:M) {
     e <- rnorm(n)
     xi.boot <- Theta[set,]%*%t(X)%*%e*sqrt(sigma.sq)/sqrt(n)
     stat.boot.nst[i] <- max(abs(xi.boot))
     stat.boot.st[i] <- max(abs(xi.boot)/sqrt(Omega[set]))
  }

  crit.nst <- quantile(stat.boot.nst, alpha)
  crit.st <- quantile(stat.boot.st, alpha)

  up.nst <- beta.db[set] + crit.nst/sqrt(n)
  low.nst <- beta.db[set] - crit.nst/sqrt(n)

  up.st <- beta.db[set] + crit.st*sqrt(Omega[set])/sqrt(n)
  low.st <- beta.db[set] - crit.st*sqrt(Omega[set])/sqrt(n)

  band.nst <- rbind(low.nst, up.nst)
  band.st <- rbind(low.st, up.st)
  result <- list(beta.db[set], band.nst, band.st)
  names(result) <- c("de-biased Lasso", "band.nst", "band.st")
  return(result)
}
