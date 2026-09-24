# Tuning of the nodewise lasso: common lambda grid and pooled K-fold
# cross-validation over all nodewise regressions.
#
# Adapted from 'hdi' 0.1-10 (R/helpers.nodewise.R, Ruben Dezeure; GPL); see
# nodewise_api.R and inst/COPYRIGHTS. The arithmetic is unchanged.

# Equidistant quantiles (100) of the pooled default glmnet lambda paths of all
# p nodewise regressions, in decreasing order.
nodewise.getlambdasequence <- function(x) {
  nlambda <- 100
  p <- ncol(x)
  lambdas <- c()
  for (c in 1:p) {
    lambdas <- c(lambdas, glmnet(x[, -c], x[, c])$lambda)
  }
  lambdas <- quantile(lambdas, probs = seq(0, 1, length.out = nlambda))
  sort(lambdas, decreasing = TRUE)
}

# K-fold cross-validation error of the nodewise regression of column c on the
# other columns, for every lambda (matrix: lambdas x folds).
cv.nodewise.totalerr <- function(c, K, dataselects, x, lambdas) {
  totalerr <- matrix(nrow = length(lambdas), ncol = K)
  for (i in 1:K) {
    whichj <- dataselects == i
    glmnetfit <- glmnet(x = x[!whichj, -c, drop = FALSE],
                        y = x[!whichj, c, drop = FALSE],
                        lambda = lambdas)
    predictions <- predict(glmnetfit, newx = x[whichj, -c, drop = FALSE], s = lambdas)
    totalerr[, i] <- apply((x[whichj, c] - predictions)^2, 2, mean)
  }
  totalerr
}

cv.nodewise.err.unitfunction <- function(c, K, dataselects, x, lambdas, verbose, p) {
  if (verbose) {
    interesting.points <- round(c(1 / 4, 2 / 4, 3 / 4, 4 / 4) * p)
    names(interesting.points) <- c("25%", "50%", "75%", "100%")
    if (c %in% interesting.points) {
      message("The expensive computation is now ",
              names(interesting.points)[c == interesting.points], " done")
    }
  }
  cv.nodewise.totalerr(c = c, K = K, dataselects = dataselects, x = x, lambdas = lambdas)
}

# Pooled K-fold cross-validation over all nodewise regressions. Returns
# lambda.min, lambda.1se and the fold assignment. The fold assignment is the
# only random draw: sample(rep(1:K, length = n)) unless `foldid` is supplied.
cv.nodewise.bestlambda <- function(lambdas, x, K = 10, foldid = NULL, parallel = FALSE,
                                   ncores = 8, verbose = FALSE) {
  n <- nrow(x)
  p <- ncol(x)
  dataselects <- if (is.null(foldid)) sample(rep(1:K, length = n)) else foldid

  totalerr <- .silm_mapply(cv.nodewise.err.unitfunction,
                           c = 1:p,
                           MoreArgs = list(K = K, dataselects = dataselects, x = x,
                                           lambdas = lambdas, verbose = verbose, p = p),
                           SIMPLIFY = FALSE, parallel = parallel, ncores = ncores)
  # (lambda, cv-fold, predictor)
  err.array <- array(unlist(totalerr), dim = c(length(lambdas), K, p))
  err.mean <- apply(err.array, 1, mean)
  # Mean over predictors for every lambda x fold, then the standard error over folds.
  err.se <- apply(apply(err.array, c(1, 2), mean), 1, sd) / sqrt(K)

  pos.min <- which.min(err.mean)
  lambda.min <- lambdas[pos.min]
  stderr.lambda.min <- err.se[pos.min]
  list(lambda.min = lambda.min,
       lambda.1se = max(lambdas[err.mean < (min(err.mean) + stderr.lambda.min)]),
       foldid = dataselects)
}
