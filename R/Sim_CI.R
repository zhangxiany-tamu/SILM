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
#' @return The de-biased Lasso estimator, the confidence bands (lower bound and
#'   upper bound) delivered by the non-studentized and the studentized
#'   statistics.
#' @references Zhang, X., and Cheng, G. (2017) Simultaneous Inference for
#'   High-dimensional Linear Models, \emph{Journal of the American Statistical
#'   Association}, 112, 757-768.
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
Sim.CI <- function(X, Y, set, M=500, alpha=0.95) {

 n <- dim(X)[1]
 p <- dim(X)[2]
 Gram <- t(X)%*%X/n
 if (p > floor(n/2)) {
    node <- .nodewise(X, what = "Theta", do_znz = TRUE)
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
