# Final nodewise fits at the chosen lambda: Theta (approximate inverse of the
# Gram matrix) and the rescaled nodewise residuals Z.
#
# Adapted from 'hdi' 0.1-10 (R/helpers.nodewise.R, Ruben Dezeure; GPL); see
# nodewise_api.R and inst/COPYRIGHTS. The arithmetic is unchanged.

# Theta via nodewise regressions, dropping the unpenalised intercept
# (hdi's "oldschool" computation with the original tau^2 formula).
score.getThetaforlambda <- function(x, lambda, parallel = FALSE, ncores = 8, verbose = FALSE) {
  if (verbose) {
    message("Calculating Thetahat by doing nodewise regressions and dropping the unpenalized intercept")
  }
  n <- nrow(x)
  p <- ncol(x)
  C <- diag(rep(1, p))
  T2 <- numeric(p)

  fits <- .silm_mapply(.theta_column, i = 1:p, MoreArgs = list(x = x, lambda = lambda),
                       SIMPLIFY = FALSE, parallel = parallel, ncores = ncores)
  for (i in 1:p) {
    C[-i, i] <- -as.vector(fits[[i]]$coeffs)
    T2[i] <- fits[[i]]$tau2
  }
  thetahat <- C %*% solve(diag(T2))
  if (verbose) cat("1/tau_j^2:", solve(diag(T2)), "\n")
  # This is Thetahat^T.
  thetahat <- t(thetahat)
  if (all(thetahat[lower.tri(thetahat)] == 0, thetahat[upper.tri(thetahat)] == 0) && verbose) {
    cat("Thetahat is a diagonal matrix!\n")
  }
  thetahat
}

# Nodewise regression of column i: coefficients (without intercept) and tau^2.
.theta_column <- function(i, x, lambda) {
  n <- nrow(x)
  glmnetfit <- glmnet(x[, -i], x[, i])
  coeffs <- as.vector(predict(glmnetfit, x[, -i], type = "coefficients", s = lambda))[-1]
  # The intercept is ignored here (as in hdi); it is small for centred data.
  tau2 <- as.numeric(crossprod(x[, i]) / n - x[, i] %*% (x[, -i] %*% coeffs) / n)
  list(coeffs = coeffs, tau2 = tau2)
}

# Nodewise residuals Z at lambda, rescaled so that t(Z_j) x_j / n = 1.
score.getZforlambda <- function(x, lambda, parallel = FALSE, ncores = 8) {
  p <- ncol(x)
  Z <- .silm_mapply(score.getZforlambda.unitfunction, i = 1:p,
                    MoreArgs = list(x = x, lambda = lambda),
                    parallel = parallel, ncores = ncores)
  score.rescale(Z, x)
}

score.getZforlambda.unitfunction <- function(i, x, lambda) {
  glmnetfit <- glmnet(x[, -i], x[, i])
  prediction <- predict(glmnetfit, x[, -i], s = lambda)
  x[, i] - prediction
}

# Rescale Z such that t(Z_j) x_j / n = 1 for all j.
score.rescale <- function(Z, x) {
  scaleZ <- diag(crossprod(Z, x)) / nrow(x)
  Z <- scale(Z, center = FALSE, scale = scaleZ)
  list(Z = Z, scaleZ = scaleZ)
}
