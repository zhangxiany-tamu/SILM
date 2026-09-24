# Z&Z refinement of the nodewise tuning parameter (Zhang and Zhang, 2014):
# pick the smallest lambda whose average variance proxy ||Z_j||^2 / (Z_j'x_j)^2
# is within 25% of its value at the cross-validated lambda.
#
# Adapted from 'hdi' 0.1-10 (R/helpers.nodewise.R, Ruben Dezeure; GPL); see
# nodewise_api.R and inst/COPYRIGHTS. The arithmetic is unchanged.
#
# Reference:
#   Zhang, C.-H. and Zhang, S. S. (2014). Confidence intervals for low
#     dimensional parameters in high dimensional linear models. Journal of the
#     Royal Statistical Society, Series B, 76, 217-242.

improve.lambda.pick <- function(x, parallel, ncores, lambdas, bestlambda, verbose) {
  # Decreasing lambdas, i.e. increasing variance.
  lambdas <- sort(lambdas, decreasing = TRUE)
  M <- calcM(x = x, lambdas = lambdas, parallel = parallel, ncores = ncores)
  Mcv <- M[which(lambdas == bestlambda)]

  if (length(which(M < 1.25 * Mcv)) > 0) {
    lambdapick <- min(lambdas[which(M < 1.25 * Mcv)])
  } else {
    if (verbose) cat("no better lambdapick found\n")
    lambdapick <- bestlambda
  }

  if (max(which(M < 1.25 * Mcv)) < length(lambdas)) {
    # Refine the interval between the last admissible and the next grid value.
    if (verbose) {
      cat("doing a second step of discretisation of the lambda space to improve the lambda pick\n")
    }
    lambda.number <- max(which(M < 1.25 * Mcv))
    newlambdas <- seq(lambdas[lambda.number], lambdas[lambda.number + 1],
                      (lambdas[lambda.number + 1] - lambdas[lambda.number]) / 100)
    newlambdas <- sort(newlambdas, decreasing = TRUE)
    M2 <- calcM(x = x, lambdas = newlambdas, parallel = parallel, ncores = ncores)

    if (length(which(M2 < 1.25 * Mcv)) > 0) {
      evenbetterlambdapick <- min(newlambdas[which(M2 < 1.25 * Mcv)])
    } else {
      if (verbose) cat("no -even- better lambdapick found\n")
      evenbetterlambdapick <- lambdapick
    }

    if (is.infinite(evenbetterlambdapick)) {
      # Refitting can raise M2 above the threshold everywhere; keep lambdapick.
      if (verbose) {
        cat("the better lambda pick after the second step of discretisation is Inf\n")
      }
    } else {
      lambdapick <- evenbetterlambdapick
    }
  }
  lambdapick
}

# Mean over the nodewise regressions of the variance proxy, for each lambda.
calcM <- function(x, lambdas, parallel, ncores) {
  M <- .silm_mapply(calcMforcolumn, j = 1:ncol(x), MoreArgs = list(x = x, lambdas = lambdas),
                    parallel = parallel, ncores = ncores)
  apply(M, 1, mean)
}

calcMforcolumn <- function(x, j, lambdas) {
  glmnetfit <- glmnet(x[, -j], x[, j], lambda = lambdas)
  predictions <- predict(glmnetfit, x[, -j], s = lambdas)
  Zj <- x[, j] - predictions
  Znorms <- apply(Zj^2, 2, sum)
  Zxjnorms <- as.vector(crossprod(Zj, x[, j])^2)
  Znorms / Zxjnorms
}
