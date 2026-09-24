# Confidence intervals for lasso.proj() and boot.lasso.proj() results.
#
# The individual intervals are those of hdi 0.1-10 (R/methods.R: confint.hdi;
# GPL, see inst/COPYRIGHTS), computed with the same expressions.

#' Confidence intervals from the de-sparsified lasso
#'
#' Individual confidence intervals for the coefficients, from the asymptotic
#' Gaussian distribution ([lasso.proj()]) or from the bootstrap distribution
#' ([boot.lasso.proj()], which requires `return.bootdist = TRUE`). The
#' individual intervals are identical to those of the archived 'hdi' package.
#'
#' For [boot.lasso.proj()], the interval for \eqn{\beta_j} is
#' \eqn{[\hat b_j - q^*_{j;1-\alpha/2}, \hat b_j - q^*_{j;\alpha/2}]}{[b_j - q*_j(1 - a/2), b_j - q*_j(a/2)]},
#' where \eqn{q^*_{j;\nu}}{q*_j(nu)} are quantiles of the bootstrap distribution
#' of \eqn{\hat{s.e.}_j T^*_j}{se_j T*_j} (Dezeure, Bühlmann and Zhang, 2017,
#' eq. 9). As in hdi, quantile type 1 is used when \eqn{B (1 - level) / 2} is
#' an integer and type 7 otherwise; because of floating-point rounding this
#' test fails for common levels such as 0.95, so type 7 is used in practice.
#'
#' @param object A result of [lasso.proj()] or [boot.lasso.proj()].
#' @param parm Coefficients (indices or names); all by default.
#' @param level Confidence level.
#' @param ... Not used.
#' @return A matrix with columns `lower` and `upper` and one row per
#'   coefficient.
#' @seealso [lasso.proj()], [boot.lasso.proj()]
#' @export
confint.silm_proj <- function(object, parm, level = 0.95, ...) {
  if (!is.numeric(level) || length(level) != 1L || !(level > 0 && level < 1)) {
    .stop("'level' must be a number between 0 and 1.")
  }
  pnames <- if (is.null(names(object$bhat))) seq_along(object$bhat) else names(object$bhat)
  parm <- if (missing(parm)) pnames else .resolve_parm(parm, pnames)
  .confint_individual(object, parm, level)
}

.resolve_parm <- function(parm, pnames) {
  if (is.numeric(parm)) {
    if (any(parm < 1 | parm > length(pnames) | parm != floor(parm))) {
      .stop("'parm' must contain indices between 1 and ", length(pnames), ".")
    }
    return(pnames[parm])
  }
  if (is.character(parm) && all(parm %in% pnames)) return(parm)
  .stop("'parm' must be coefficient indices or names.")
}

.confint_individual <- function(object, parm, level) {
  obj <- object$bhat
  if (object$method == "lasso.proj") {
    quant <- qnorm(1 - (1 - level) / 2)
    add <- object$se[parm] * (quant + 0)
    m <- cbind(obj[parm] - add, obj[parm] + add)
  } else {
    if (is.null(object$cboot.dist)) {
      .stop("Bootstrap output is missing the bootstrap distribution necessary to compute ",
            "confidence intervals. Rerun the bootstrap with return.bootdist = TRUE.")
    }
    alpha <- 1 - level
    quantile.type <- if ((alpha / 2 * object$B) %% 1 == 0) 1 else 7
    qstar <- apply(object$cboot.dist, 1, quantile, probs = c(alpha / 2, 1 - alpha / 2),
                   type = quantile.type)
    m <- cbind(obj[parm] - qstar[2, parm], obj[parm] - qstar[1, parm])
  }
  dimnames(m) <- list(parm, c("lower", "upper"))
  m
}
