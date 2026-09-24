#' Testing for Sparse Signals
#'
#' Tests \eqn{H_{0,G}: \beta_j = 0} for all \eqn{j \in G} = `test.set`, a
#' possibly large group of variables, with the three-step procedure of Zhang
#' and Cheng (2017, Sections 3.2 and 5.3): (1) the sample is split at random
#' into \eqn{D_1} of size `sub.size` and \eqn{D_2}; (2) on \eqn{D_1} the
#' variables are screened (the cross-validated lasso selection, completed by
#' the variables most correlated with the lasso residuals, \eqn{|D_2| - 1} in
#' total); (3) on \eqn{D_2} the maximum of the de-biased lasso statistics over
#' the screened variables in \eqn{G} is compared with a Gaussian multiplier
#' bootstrap critical value. If no variable of \eqn{G} survives the screening,
#' the test statistic is 0 and the hypothesis is not rejected.
#'
#' See [SR()] for the model assumptions (no intercept, centred data). In ST the
#' matrix \eqn{\Theta} is always estimated by the nodewise lasso.
#'
#' @inheritParams SR
#' @param X.f Design matrix (n x p).
#' @param Y.f Response variable (length n).
#' @param sub.size The size of the screening sub-sample \eqn{D_1}: a number
#'   of observations (`floor(sub.size)` is used), or a proportion of n if
#'   smaller than 1. Zhang and Cheng (2017) use n/5 to n/3.
#' @param test.set The group of variables to be tested: column indices, or a
#'   logical vector of length p.
#' @param M The number of bootstrap replications (default 500).
#' @param alpha The significance level (default 0.05).
#' @param nodewise Tuning rule for the nodewise lasso that estimates
#'   \eqn{\Theta} on \eqn{D_2}: `"cv"` (default) or `"ZnZ"`; see [SR()].
#' @param center Logical. If `TRUE`, `X.f` and `Y.f` are centred separately
#'   within each sub-sample before screening and testing. The default `FALSE`
#'   uses the data as given and warns when they do not appear to be centred.
#' @param legacy Logical. If `TRUE`, reproduce SILM 1.0.0 exactly, including
#'   three behaviours that were corrected in SILM 2.0.0: the decision of the
#'   studentized test was spelled `"rejct"`; when `sub.size` left exactly
#'   \eqn{|D_2| - 1} variables selected by the screening lasso, one additional
#'   variable was kept; and when no variable of `test.set` survived the
#'   screening, the statistics were `-Inf` (now 0, with a warning).
#' @return A list of four elements, in this order (note that the names are
#'   duplicated, as in SILM 1.0.0, so use positions):
#'   1. the non-studentized test statistic;
#'   2. its decision, `"reject"` or `"fail to reject"`;
#'   3. the studentized test statistic;
#'   4. its decision.
#' @inheritSection SR Nodewise tuning
#' @inherit SR references
#' @seealso [SR()], [Sim.CI()], [Step()]
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
#' test.set <- (s0+1):p
#' sub.size <- n*0.3
#' ST(X, Y, sub.size, test.set)
#' test.set <- s0:p
#' ST(X, Y, sub.size, test.set)
#' @export
ST <- function(X.f, Y.f, sub.size, test.set, M = 500, alpha = 0.05,
               nodewise = c("cv", "ZnZ"), center = FALSE, legacy = FALSE,
               parallel = FALSE, ncores = getOption("mc.cores", 2L)) {
  nodewise <- match.arg(nodewise)
  X.f <- .check_X(X.f, "X.f")
  Y.f <- .check_Y(Y.f, nrow(X.f), "Y.f")
  n <- dim(X.f)[1]
  p <- dim(X.f)[2]
  if (p < 2L) .stop("'X.f' must have at least 2 columns.")
  test.set <- .check_index_set(test.set, p, "test.set", ignore_out_of_range = TRUE)
  .check_count(M)
  .check_level(alpha)
  center <- .check_flag(center, "center")
  legacy <- .check_flag(legacy, "legacy")
  parallel <- .check_flag(parallel, "parallel")
  if (!center) .warn_uncentred(X.f, Y.f)

  # Step 1: sample splitting.
  n1 <- .st_subsample_size(sub.size, n)
  n0 <- n-n1
  S1 <- sample(1:n, n1, replace=FALSE)

  # Step 2: screening on D1.
  X.sub <- X.f[S1, , drop = FALSE]
  Y.sub <- Y.f[S1]
  if (center) {
    centred <- .center_xy(X.sub, Y.sub)
    X.sub <- centred$X
    Y.sub <- centred$Y
  }
  screen.set <- .st_screen(X.sub, Y.sub, n0, legacy)
  screen.set <- .st_drop_constant(X.f, S1, screen.set)

  # Step 3: de-biased lasso and bootstrap test on D2.
  X <- X.f[-S1, screen.set, drop = FALSE]
  Y <- Y.f[-S1]
  if (center) {
    centred <- .center_xy(X, Y)
    X <- centred$X
    Y <- centred$Y
  }
  .st_test(X, Y, n0, screen.set, test.set, M, alpha, nodewise, legacy, parallel, ncores)
}

.st_test <- function(X, Y, n0, screen.set, test.set, M, alpha, nodewise, legacy,
                     parallel, ncores) {
  node <- .nodewise(X, what = "Theta", do_znz = identical(nodewise, "ZnZ"),
                    parallel = parallel, ncores = ncores)
  Theta <- node$out
  Gram<-t(X)%*%X/n0

  sreg <- .scaled_lasso(X,Y)
  beta.hat <- sreg$coefficients
  sigma.sq <- sum((Y-X%*%beta.hat)^2)/(n0-sum(abs(beta.hat)>0))
  test.set.i <- intersect(screen.set,test.set)
  index <- screen.set%in%test.set.i

  if (!any(index)) {
    # SILM 1.0.0 still ran the M bootstrap draws here; consume them so the RNG
    # stream is unchanged.
    .burn_rnorm(n0 * M)
    if (legacy) return(.st_result(-Inf, "fail to reject", -Inf, "fail to reject"))
    warning("No variable of 'test.set' survived the screening step; the test statistic ",
            "is 0 and the hypothesis is not rejected.", call. = FALSE)
    return(.st_result(0, "fail to reject", 0, "fail to reject"))
  }

  Omega <- diag(Theta%*%Gram%*%t(Theta))*sigma.sq
  beta.db <- beta.hat+Theta%*%t(X)%*%(Y-X%*%beta.hat)/n0
  margin.st <- sqrt(n0)*abs(beta.db[index])/sqrt(Omega[index])
  margin.nst <- sqrt(n0)*abs(beta.db[index])
  stat.st <- max(margin.st)
  stat.nst <- max(margin.nst)

  stat.boot.st <- stat.boot.nst <- rep(NA,M)
  for (i in 1:M) {
    e <- rnorm(n0)
    xi.boot <- Theta[index,]%*%t(X)%*%e*sqrt(sigma.sq)/sqrt(n0)
    stat.boot.nst[i] <- max(abs(xi.boot))
    stat.boot.st[i] <- max(abs(xi.boot/sqrt(Omega[index])))
  }

  rej.nst <- if (stat.nst>quantile(stat.boot.nst,1-alpha)) "reject" else "fail to reject"
  rej.st <- if (stat.st>quantile(stat.boot.st,1-alpha)) {
    if (legacy) "rejct" else "reject"
  } else {
    "fail to reject"
  }
  .st_result(stat.nst, rej.nst, stat.st, rej.st)
}

.st_result <- function(stat.nst, rej.nst, stat.st, rej.st) {
  result <- list(stat.nst, rej.nst, stat.st, rej.st)
  names(result) <- c("non-studentized test","non-studentized test","studentized test","studentized test")
  result
}
