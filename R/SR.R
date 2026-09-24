#' Support Recovery Procedure
#'
#' This function implements the support recovery procedure in Zhang and Cheng
#' (2017).
#'
#' @param X n times p design matrix.
#' @param Y Response variable.
#' @return The sets of active variables selected by the support recovery
#'   procedure and the scaled Lasso.
#' @references Zhang, X., and Cheng, G. (2017) Simultaneous Inference for
#'   High-dimensional Linear Models, \emph{Journal of the American Statistical
#'   Association}, 112, 757-768.
#' @examples
#' ## The function is intended for large n and p.
#' ## Use small p here for illustration purpose only.
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
SR <- function(X, Y) {
  n <- dim(X)[1]
  p <- dim(X)[2]
  Gram <- t(X)%*%X/n
  score.nodewiselasso = getFromNamespace("score.nodewiselasso", "hdi")

  if(p > floor(n/2)) {
     node <- score.nodewiselasso(X, wantTheta=TRUE, verbose=FALSE, lambdaseq="quantile",
     parallel=FALSE, ncores=2, oldschool = FALSE, lambdatuningfactor = 1)
     Theta <- node$out
  } else {
     Theta <- solve(Gram)
  }

  sreg <- scalreg(X,Y)
  beta.hat <- sreg$coefficients
  sigma.sq <- sum((Y-X%*%beta.hat)^2)/(n-sum(abs(beta.hat)>0))
  beta.db <- beta.hat+Theta%*%t(X)%*%(Y-X%*%beta.hat)/n
  Omega <- diag(Theta%*%Gram%*%t(Theta))*sigma.sq
  stat.st <- sqrt(n)*abs(beta.db)/sqrt(Omega)
  active.db <- (1:p)[stat.st>sqrt(2*log(p))]
  active.lasso <- (1:p)[abs(beta.hat)>0]
  result <- list(active.db, active.lasso)
  names(result) <- c("de-biased Lasso", "scaled Lasso")
  return(result)
}
