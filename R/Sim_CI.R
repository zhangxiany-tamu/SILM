#' Simultaneous Confidence Intervals
#'
#' Constructs simultaneous confidence intervals for \eqn{\beta_j},
#' \eqn{j \in} `set`, based on the de-biased lasso and a Gaussian multiplier
#' bootstrap of the maximum statistic (Zhang and Cheng, 2017, Section 2).
#' Both the non-studentized and the studentized versions are returned.
#'
#' **Note on `alpha`.** Unlike [ST()] and [Step()], where `alpha` is the
#' significance level, here `alpha` is the **confidence level** of the
#' simultaneous intervals (default 0.95, i.e. 95\% intervals). This is kept for
#' compatibility with SILM 1.0.0; a value below 0.5 triggers a warning.
#'
#' See [SR()] for the model assumptions (no intercept, centred data) and the
#' estimation of \eqn{\Theta}.
#'
#' @inheritParams SR
#' @param set The set of variables of interest: column indices of `X`, or a
#'   logical vector of length p.
#' @param M The number of bootstrap replications (default 500).
#' @param alpha The confidence level of the simultaneous intervals (default
#'   0.95).
#' @return A list with three components:
#'   \item{de-biased Lasso}{the de-biased lasso estimates of \eqn{\beta_j},
#'     \eqn{j \in} `set`;}
#'   \item{band.nst}{a 2 x |`set`| matrix whose rows `low.nst` and `up.nst`
#'     are the lower and upper bounds of the intervals from the
#'     non-studentized statistic;}
#'   \item{band.st}{the same for the studentized statistic (rows `low.st`,
#'     `up.st`).}
#' @inheritSection SR Nodewise tuning
#' @inherit SR references
#' @seealso [SR()], [Step()], [ST()], [boot.lasso.proj()] for the bootstrapped
#'   de-sparsified lasso of Dezeure, Bühlmann and Zhang (2017).
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
#' beta[1:s0] <- runif(s0,0,2)
#' Y <- X%*%beta+rt(n,4)/sqrt(2)
#' Sim.CI(X, Y, set)
#' @export
Sim.CI <- function(X, Y, set, M = 500, alpha = 0.95, nodewise = c("cv", "ZnZ"),
                   center = FALSE, Theta = NULL, parallel = FALSE,
                   ncores = getOption("mc.cores", 2L)) {
  nodewise <- match.arg(nodewise)
  data <- .prepare_xy(X, Y, center)
  set <- .check_index_set(set, ncol(data$X), "set")
  .check_count(M)
  .check_level(alpha)
  if (alpha < 0.5) {
    warning("'alpha' is the confidence level in Sim.CI() (e.g. 0.95 for 95% intervals); ",
            "did you mean alpha = ", 1 - alpha, "?", call. = FALSE)
  }
  X <- data$X
  fit <- .silm_fit(X, data$Y, nodewise, Theta, .check_flag(parallel, "parallel"), ncores)
  n <- fit$n
  Theta <- fit$Theta
  sigma.sq <- fit$sigma.sq
  beta.db <- fit$beta.db
  Omega <- fit$Omega

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
  result
}
