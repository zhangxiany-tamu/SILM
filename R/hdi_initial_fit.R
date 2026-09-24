# Initial lasso fit for lasso.proj() and boot.lasso.proj().
#
# Adapted from 'hdi' 0.1-10 (R/helpers.R: initial.estimator, do.initial.fit;
# GPL, see inst/COPYRIGHTS). Changes: the scaled lasso is SILM's own
# .scaled_lasso() (numerically identical to scalreg, which hdi used); the
# cross-validation folds of cv.glmnet() can be supplied (`foldid`, giving the
# same result as the fold draw inside cv.glmnet()); argument checks were moved
# to the callers. The computations are unchanged.

# Lasso fit with the "scaled lasso" or cross-validated ("cv lasso", with
# lambda.1se) tuning, or at a given lambda. Returns the coefficients without
# intercept, the noise level estimate, the intercept and the lambda used.
do.initial.fit <- function(x, y, initial.lasso.method = c("scaled lasso", "cv lasso"),
                           lambda, verbose = FALSE, foldid = NULL) {
  no.lambda.given <- missing(lambda) || is.null(lambda)
  if (!no.lambda.given && verbose) {
    cat("A value for lambda was provided to the do.initial.fit function,\n")
    cat("the initial.lasso.method option was therefore ignored.\n")
    cat("We now do a lasso with the tuning parameter instead of a self-tuning procedure.\n")
  }

  if (no.lambda.given) {
    switch(initial.lasso.method,
      "scaled lasso" = {
        scaledlassofit <- .scaled_lasso(x, y)
        lambda <- NULL
      },
      "cv lasso" = {
        glmnetfit <- .cv_glmnet(x = x, y = y, foldid = foldid)
        lambda <- glmnetfit$lambda.1se
      },
      .stop("Not sure what lasso.method you want me to use for the initial fit. ",
            "The only options for the moment are: 1)scaled lasso 2)cvlasso")
    )
  } else {
    # Fit for a range of lambda.
    glmnetfit <- glmnet(x = x, y = y)
  }

  refitted <- FALSE
  if (no.lambda.given && identical(initial.lasso.method, "scaled lasso")) {
    intercept <- 0
    betalasso <- scaledlassofit$coefficients
    sigmahat <- scaledlassofit$hsigma
  } else {
    if ((nrow(x) - sum(as.vector(coef(glmnetfit, s = lambda)) != 0)) <= 0) {
      # The lambda used all degrees of freedom: refit with cross-validation,
      # which draws new folds (reported as `refitted` so that the bootstrap can
      # keep the random number stream of a sequential run).
      message("Refitting using cross validation: your lambda used all degrees of freedom")
      glmnetfit <- cv.glmnet(x = x, y = y)
      lambda <- glmnetfit$lambda.1se
      refitted <- TRUE
    }
    intercept <- coef(glmnetfit, s = lambda)[1]
    betalasso <- as.vector(coef(glmnetfit, s = lambda))[-1]
    residual.vector <- y - predict(glmnetfit, newx = x, s = lambda)
    sigmahat <- sqrt(sum((residual.vector)^2) /
                       (nrow(x) - sum(as.vector(coef(glmnetfit, s = lambda)) != 0)))
  }
  list(betalasso = betalasso, sigmahat = sigmahat, intercept = intercept, lambda = lambda,
       refitted = refitted)
}

# cv.glmnet with glmnet's defaults; `foldid = NULL` lets cv.glmnet draw the
# folds, which is identical to supplying sample(rep(seq(10), length = n)).
.cv_glmnet <- function(x, y, foldid = NULL) {
  if (is.null(foldid)) cv.glmnet(x = x, y = y) else cv.glmnet(x = x, y = y, foldid = foldid)
}

# Validate betainit/sigma and compute the initial estimate.
initial.estimator <- function(betainit, x, y, sigma, foldid = NULL, warn_sigma = TRUE) {
  warning.sigma.message <- function() {
    if (warn_sigma) {
      warning("Overriding the error variance estimate with your own value. The initial ",
              "estimate implies an error variance estimate and if they don't correspond ",
              "the testing might not be correct anymore.", call. = FALSE)
    }
  }
  lambda <- NULL
  if (is.numeric(betainit)) {
    beta.lasso <- betainit
    sigmahat <- sigma
    warning.sigma.message()
  } else {
    initial.fit <- do.initial.fit(x = x, y = y, initial.lasso.method = betainit, foldid = foldid)
    beta.lasso <- initial.fit$betalasso
    lambda <- initial.fit$lambda
    if (is.null(sigma)) {
      sigmahat <- initial.fit$sigmahat
    } else {
      warning.sigma.message()
      sigmahat <- sigma
    }
  }
  list(beta.lasso = beta.lasso, sigmahat = sigmahat, lambda = lambda)
}
