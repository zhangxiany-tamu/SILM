# Data preparation for lasso.proj() and boot.lasso.proj().
#
# Adapted from 'hdi' 0.1-10 (R/helpers.R: prepare.data, switch.family; GPL,
# see inst/COPYRIGHTS). With legacy = TRUE the computations are exactly those
# of hdi. With legacy = FALSE (default), the binomial case removes the
# intercept by projecting the weighted working data onto the orthogonal
# complement of sqrt(w) (see .binomial_working_data()).

# Centre (and optionally scale) the columns of x; centre y. For the binomial
# family, x and y are first replaced by the IRLS working data.
prepare.data <- function(x, y, standardize, family, legacy = TRUE) {
  x <- scale(x, center = TRUE, scale = standardize)
  if (family == "gaussian") {
    dataset <- list(x = x, y = y)
  } else if (legacy) {
    dataset <- switch.family(x = x, y = y, family = family)
  } else {
    return(.binomial_working_data(x, y))
  }
  # Centre the columns and the response to get rid of the intercept.
  x <- scale(dataset$x, center = TRUE, scale = FALSE)
  y <- scale(dataset$y, scale = FALSE)
  y <- as.numeric(y)
  list(x = x, y = y)
}

# Linearisation of the logistic model at a cross-validated lasso fit (hdi):
# weights w = pi (1 - pi), working design sqrt(w) x and working response
# sqrt(w) (x_l beta + (y - pi) / w).
switch.family <- function(x, y, family) {
  switch(family,
    "binomial" = {
      fitnet <- cv.glmnet(x, y, family = "binomial", standardize = FALSE)
      glmnetfit <- fitnet$glmnet.fit
      netlambda.min <- fitnet$lambda.min
      netpred <- predict(glmnetfit, x, s = netlambda.min, type = "response")
      betahat <- predict(glmnetfit, x, s = netlambda.min, type = "coefficients")
      betahat <- as.vector(betahat)
      pihat <- netpred[, 1]

      diagW <- pihat * (1 - pihat)
      W <- diag(diagW)
      xl <- cbind(rep(1, nrow(x)), x)

      # Adjusted design matrix and response.
      xw <- sqrt(diagW) * x
      yw <- sqrt(diagW) * (xl %*% betahat + solve(W, y - pihat))
    },
    .stop("The provided family is not supported (yet). Currently supported are ",
          "gaussian and binomial.")
  )
  list(x = xw, y = yw, sqrtw = sqrt(diagW))
}

# Binomial working data with the intercept removed correctly. In the working
# linear model sqrt(w) * (intercept + x beta) the intercept multiplies sqrt(w),
# not a column of ones, so it is removed by projecting every column of the
# working design and the working response onto the orthogonal complement of
# sqrt(w). (hdi subtracts plain means instead, which leaves the intercept in
# the model when the weights vary and biases the estimates; legacy = TRUE.)
# The division (y - pi) / w equals hdi's solve(diag(w), y - pi) without the
# n x n matrix.
.binomial_working_data <- function(x, y) {
  fitnet <- cv.glmnet(x, y, family = "binomial", standardize = FALSE)
  glmnetfit <- fitnet$glmnet.fit
  lambda <- fitnet$lambda.min
  pihat <- predict(glmnetfit, x, s = lambda, type = "response")[, 1]
  betahat <- as.vector(predict(glmnetfit, x, s = lambda, type = "coefficients"))
  w <- pihat * (1 - pihat)
  if (any(w <= 0)) {
    .stop("Fitted probabilities of 0 or 1 occurred in the logistic working model; ",
          "the linearisation is not defined.")
  }
  sw <- sqrt(w)
  xl <- cbind(1, x)
  xw <- sw * x
  yw <- as.vector(sw * (xl %*% betahat + (y - pihat) / w))
  project <- function(v) v - sw * sum(sw * v) / sum(w)
  xw <- apply(xw, 2, project)
  dimnames(xw) <- dimnames(x)
  list(x = xw, y = project(yw))
}

# Response of the binomial family: 0/1 numbers, logical, or a two-level factor.
.binomial_response <- function(y) {
  if (is.factor(y)) {
    if (nlevels(y) != 2L) .stop("A factor response must have exactly two levels.")
    y <- as.numeric(y == levels(y)[2L])
  } else if (is.logical(y)) {
    y <- as.numeric(y)
  }
  if (!all(y %in% c(0, 1))) .stop("For family = \"binomial\", 'y' must be 0/1, logical or a two-level factor.")
  y
}
