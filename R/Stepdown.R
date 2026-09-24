#' Stepdown Method for Multiple Testing
#'
#' This function implements the stepdown method in Zhang and Cheng (2017).
#'
#' @param X n times p design matrix.
#' @param Y Response variable.
#' @param M The number of bootstrap replications (default 500).
#' @param alpha The nominal level alpha (default 0.05).
#' @return A vector indicating which hypotheses are being rejected.
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
#' beta[1:s0] <- runif(s0,1,2)
#' Y <- X%*%beta+rt(n,4)/sqrt(2)
#' Step(X, Y, M=500, alpha=0.05)
#' @export
Step <- function(X, Y, M=500, alpha=0.05) {
  n <- dim(X)[1]
  p <- dim(X)[2]
  count.st <- count.nst <- rep(1,p)

  Gram <- t(X)%*%X/n
  if (p > floor(n/2)) {
     node <- .nodewise(X, what = "Theta", do_znz = TRUE)
     Theta <- node$out
  } else {
     Theta <- solve(Gram)
  }

  sreg <- .scaled_lasso(X,Y)
  beta.hat <- sreg$coefficients
  sigma.sq <- sum((Y-X%*%beta.hat)^2)/(n-sum(abs(beta.hat)>0))
  beta.db <- beta.hat+Theta%*%t(X)%*%(Y-X%*%beta.hat)/n

  Omega <- diag(Theta%*%Gram%*%t(Theta))*sigma.sq
  margin.test.nst <- sqrt(n)*abs(beta.db)
  margin.test.st <- sqrt(n)*abs(beta.db)/sqrt(Omega)

  eta <- 1:p
  stop.sd <- 1
  while (stop.sd) {
     stat.boot.nst <- rep(NA,M)
     for (i in 1:M) {
       e <- rnorm(n)
       xi.boot <- Theta[eta,]%*%t(X)%*%e*sqrt(sigma.sq)/sqrt(n)
       stat.boot.nst[i] <- max(abs(xi.boot))
     }
     crit.eta.nst <- quantile(stat.boot.nst,1-alpha)
     rej.nst <- margin.test.nst[eta]<crit.eta.nst
     if (sum(rej.nst)==length(rej.nst)) stop.sd <- 0 else eta <- eta[rej.nst]
  }
  count.nst[eta] <- 0

  eta2 <- 1:p
  stop.sd2 <- 1
  while (stop.sd2) {
    stat.boot.st <- rep(NA,M)
     for (i in 1:M) {
       e <- rnorm(n)
       xi.boot <- Theta[eta2,]%*%t(X)%*%e*sqrt(sigma.sq)/sqrt(n)
       stat.boot.st[i] <- max(abs(xi.boot)/sqrt(Omega[eta2]))
     }
     crit.eta.st <- quantile(stat.boot.st,1-alpha)
     rej.st <- margin.test.st[eta2]<crit.eta.st
     if (sum(rej.st)==length(rej.st)) stop.sd2 <- 0 else eta2 <- eta2[rej.st]
  }
  count.st[eta2] <- 0

  rej.nst <- (1:p)[count.nst==1]
  rej.st <- (1:p)[count.st==1]
  result <- list(rej.nst, rej.st)
  names(result) <- c("non-studentized test", "studentized test")
  return(result)
}
