#' Stepdown Method for Multiple Testing
#'
#' Tests \eqn{H_{0,j}: \beta_j = 0} against two-sided alternatives for all
#' \eqn{j = 1, \dots, p} with the bootstrap-assisted stepdown procedure of
#' Zhang and Cheng (2017, Section 3.3, in the two-sided form used in Section
#' 5.4), which controls the familywise error rate asymptotically at level
#' `alpha`. Critical values are recomputed with fresh bootstrap draws at every
#' step. Both the non-studentized and the studentized statistics are used.
#'
#' See [SR()] for the model assumptions (no intercept, centred data) and the
#' estimation of \eqn{\Theta}.
#'
#' @inheritParams SR
#' @param M The number of bootstrap replications per step (default 500).
#' @param alpha The significance level (familywise error rate; default 0.05).
#' @return A list with two integer vectors, `"non-studentized test"` and
#'   `"studentized test"`: the indices of the rejected hypotheses.
#' @inheritSection SR Nodewise tuning
#' @inherit SR references
#' @seealso [SR()], [Sim.CI()], [ST()]
#' @examples
#' ## The function is intended for large n and p.
#' ## Use small p here for illustration purpose only.
#' set.seed(1)
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
Step <- function(X, Y, M = 500, alpha = 0.05, nodewise = c("cv", "ZnZ"), center = FALSE,
                 Theta = NULL, parallel = FALSE, ncores = getOption("mc.cores", 2L)) {
  nodewise <- match.arg(nodewise)
  data <- .prepare_xy(X, Y, center)
  .check_count(M)
  .check_level(alpha)
  X <- data$X
  fit <- .silm_fit(X, data$Y, nodewise, Theta, .check_flag(parallel, "parallel"), ncores)
  n <- fit$n
  p <- fit$p
  count.st <- count.nst <- rep(1,p)

  margin.test.nst <- sqrt(n)*abs(fit$beta.db)
  margin.test.st <- sqrt(n)*abs(fit$beta.db)/sqrt(fit$Omega)

  eta <- .stepdown(fit, X, margin.test.nst, M, alpha, studentized = FALSE)
  count.nst[eta] <- 0
  eta2 <- .stepdown(fit, X, margin.test.st, M, alpha, studentized = TRUE)
  count.st[eta2] <- 0

  rej.nst <- (1:p)[count.nst==1]
  rej.st <- (1:p)[count.st==1]
  result <- list(rej.nst, rej.st)
  names(result) <- c("non-studentized test", "studentized test")
  result
}

# One stepdown sequence. Returns the indices of the hypotheses that are NOT
# rejected. When every hypothesis gets rejected, SILM 1.0.0 performed one more
# (empty) bootstrap pass; its draws are skipped here but consumed from the RNG
# stream, so the results and the RNG state are unchanged.
.stepdown <- function(fit, X, margin, M, alpha, studentized) {
  n <- fit$n
  Theta <- fit$Theta
  sigma.sq <- fit$sigma.sq
  Omega <- fit$Omega
  eta <- 1:fit$p
  stop.sd <- 1
  while (stop.sd) {
    stat.boot <- rep(NA,M)
    A <- Theta[eta, , drop = FALSE]%*%t(X)
    for (i in 1:M) {
      e <- rnorm(n)
      xi.boot <- A%*%e*sqrt(sigma.sq)/sqrt(n)
      stat.boot[i] <- if (studentized) max(abs(xi.boot)/sqrt(Omega[eta])) else max(abs(xi.boot))
    }
    crit.eta <- quantile(stat.boot,1-alpha)
    keep <- margin[eta]<crit.eta
    if (sum(keep)==length(keep)) {
      stop.sd <- 0
    } else {
      eta <- eta[keep]
      if (!length(eta)) {
        .burn_rnorm(n * M)
        stop.sd <- 0
      }
    }
  }
  eta
}
