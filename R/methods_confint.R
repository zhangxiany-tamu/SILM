# Confidence intervals for lasso.proj() and boot.lasso.proj() results.
#
# The individual intervals are those of hdi 0.1-10 (R/methods.R: confint.hdi;
# GPL, see inst/COPYRIGHTS), computed with the same expressions.

#' Confidence intervals from the de-sparsified lasso
#'
#' Individual or simultaneous confidence intervals for the coefficients.
#'
#' **Individual intervals** (`type = "individual"`) come from the asymptotic
#' Gaussian distribution for [lasso.proj()] and from the bootstrap
#' distribution for [boot.lasso.proj()] (which requires `return.bootdist =
#' TRUE`); they are identical to those of the archived 'hdi' package when the
#' fit used hdi's standard errors (`robust = FALSE`, or `robust = TRUE` with
#' `robust.divisor = "n"`). With the default `robust.divisor = "n-s"`, the
#' robust intervals differ from hdi's: those of [lasso.proj()] are wider by
#' the factor \eqn{\sqrt{n/(n-\hat s)}}{sqrt(n / (n - s))}, and the bootstrap
#' intervals change because \eqn{\hat{s.e.}_j}{se_j} and every
#' \eqn{\hat{s.e.}^*_j}{se*_j} are rescaled. For the bootstrap, the interval
#' for \eqn{\beta_j} is
#' \eqn{[\hat b_j - q^*_{j;1-\alpha/2}, \hat b_j - q^*_{j;\alpha/2}]}{[b_j - q*_j(1 - a/2), b_j - q*_j(a/2)]},
#' where \eqn{q^*_{j;\nu}}{q*_j(nu)} are quantiles of the bootstrap distribution
#' of \eqn{\hat{s.e.}_j T^*_j}{se_j T*_j} (Dezeure, Bühlmann and Zhang, 2017,
#' eq. 9). As in hdi, quantile type 1 is used when \eqn{B (1 - level) / 2} is
#' an integer and type 7 otherwise; because of floating-point rounding this
#' test fails for common levels such as 0.95, so type 7 is used in practice.
#'
#' **Simultaneous intervals** (`type = "simultaneous"`, [boot.lasso.proj()]
#' only; not available in hdi) cover all \eqn{\beta_j}, \eqn{j \in G},
#' jointly with probability approximately `level` (Dezeure, Bühlmann and Zhang,
#' 2017, Section 3.2, eq. 10):
#' * `simult.stat = "maxmin"`:
#'   \eqn{[\hat b_j - \hat{s.e.}_j q^*_{\max;G}(1-\alpha/2), \hat b_j - \hat{s.e.}_j q^*_{\min;G}(\alpha/2)]}{[b_j - se_j qmax_G(1 - a/2), b_j - se_j qmin_G(a/2)]},
#'   where \eqn{q^*_{\max;G}}{qmax_G} and \eqn{q^*_{\min;G}}{qmin_G} are quantiles
#'   of the bootstrap distributions of \eqn{\max_{j \in G} T^*_j} and
#'   \eqn{\min_{j \in G} T^*_j};
#' * `simult.stat = "abs"`: \eqn{\hat b_j \mp \hat{s.e.}_j q^*_{abs;G}(1-\alpha)}{b_j -/+ se_j qabs_G(1 - a)},
#'   with the quantile of \eqn{\max_{j \in G} |T^*_j|}.
#'
#' Here \eqn{T^*_j = (\hat b^*_j - \hat\beta_j) / \hat{s.e.}^*_j} is the
#' studentized centred bootstrap statistic (the factor \eqn{\sqrt{n}} in the
#' display of the region \eqn{C(1-\alpha)} on p. 693 of the paper is a typo).
#' The quantile type follows the rule above. The group `G` defaults to `parm`
#' (all coefficients if both are missing); intervals over all coefficients, or
#' over a group given in `groups` when fitting, are available without
#' `return.bootdist = TRUE`. The residual bootstrap is valid for simultaneous
#' inference only under homoscedastic errors; use the wild (or xyz-paired)
#' bootstrap otherwise (the paper's Theorems 1 and 3).
#'
#' @param object A result of [lasso.proj()] or [boot.lasso.proj()].
#' @param parm Coefficients (indices or names) for which intervals are
#'   returned; by default all coefficients (or all of `group`).
#' @param level Confidence level (joint level for simultaneous intervals).
#' @param type `"individual"` (default) or `"simultaneous"`.
#' @param group For simultaneous intervals: the group \eqn{G} of coefficients
#'   covered jointly (indices, names or a logical vector); must contain
#'   `parm`. Defaults to `parm`.
#' @param simult.stat `"maxmin"` (default; eq. 10) or `"abs"`.
#' @param ... Not used.
#' @return A matrix with columns `lower` and `upper` and one row per
#'   coefficient. Simultaneous intervals carry an attribute `"simultaneous"`
#'   with the group, the statistic, the level and the bootstrap quantiles.
#' @references Dezeure, R., Bühlmann, P. and Zhang, C.-H. (2017).
#'   High-dimensional simultaneous inference with the bootstrap. \emph{TEST},
#'   26, 685-719.
#' @seealso [lasso.proj()], [boot.lasso.proj()], [groupTest()]
#' @examples
#' set.seed(1)
#' x <- matrix(rnorm(50 * 15), 50, 15)
#' y <- x[, 1] + rnorm(50)
#' fit <- boot.lasso.proj(x, y, B = 50, boot.shortcut = TRUE, wild = TRUE,
#'                        robust = TRUE, return.bootdist = TRUE)
#' confint(fit, parm = 1:3)                           # individual
#' confint(fit, type = "simultaneous")[1:3, ]         # all 15 jointly
#' confint(fit, type = "simultaneous", group = 1:5)   # the first 5 jointly
#' @export
confint.silm_proj <- function(object, parm, level = 0.95,
                              type = c("individual", "simultaneous"), group = NULL,
                              simult.stat = c("maxmin", "abs"), ...) {
  type <- match.arg(type)
  stat_given <- !missing(simult.stat)
  simult.stat <- match.arg(simult.stat)
  if (!is.numeric(level) || length(level) != 1L || !(level > 0 && level < 1)) {
    .stop("'level' must be a number between 0 and 1.")
  }
  pnames <- if (is.null(names(object$bhat))) seq_along(object$bhat) else names(object$bhat)
  if (type == "simultaneous") {
    return(.confint_simultaneous(object, if (missing(parm)) NULL else parm, level, group,
                                 simult.stat, pnames))
  }
  if (!is.null(group) || stat_given) {
    warning("'group' and 'simult.stat' are only used with type = \"simultaneous\".",
            call. = FALSE)
  }
  parm <- if (missing(parm)) pnames else .resolve_parm(parm, pnames)
  .confint_individual(object, parm, level)
}

# Coefficients by name, or by index with R's subsetting semantics (as hdi's
# confint.hdi: negative indices exclude, 0 is dropped).
.resolve_parm <- function(parm, pnames) {
  if (is.numeric(parm)) {
    if (!length(parm) || anyNA(parm) || any(abs(parm) >= length(pnames) + 1) ||
        (any(parm < 0) && any(parm > 0))) {
      .stop("'parm' must contain indices between 1 and ", length(pnames), ".")
    }
    out <- pnames[parm]
    if (!length(out)) .stop("'parm' selects no coefficient.")
    return(out)
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
    quantile.type <- if ((alpha / 2 * .boot_B(object)) %% 1 == 0) 1 else 7
    qstar <- apply(object$cboot.dist, 1, quantile, probs = c(alpha / 2, 1 - alpha / 2),
                   type = quantile.type)
    m <- cbind(obj[parm] - qstar[2, parm], obj[parm] - qstar[1, parm])
  }
  dimnames(m) <- list(parm, c("lower", "upper"))
  m
}

# Number of bootstrap samples behind the centred distribution.
.boot_B <- function(object) {
  if (!is.null(object$B.eff)) object$B.eff else object$B
}

.confint_simultaneous <- function(object, parm, level, group, stat, pnames) {
  if (!identical(object$method, "boot.lasso.proj")) {
    .stop("Simultaneous confidence intervals require a boot.lasso.proj() fit.")
  }
  p <- length(object$bhat)
  pn <- names(object$bhat)
  # Rows in the order of `parm` (as for individual intervals); the group
  # defaults to the coefficients in `parm`.
  idx <- if (is.null(parm)) NULL else match(.resolve_parm(parm, pnames), pnames)
  G <- if (!is.null(group)) {
    .resolve_group(group, p, pn, "group")
  } else if (!is.null(idx)) {
    sort(unique(idx))
  } else {
    seq_len(p)
  }
  if (is.null(idx)) idx <- G
  if (!all(idx %in% G)) .stop("'parm' must be contained in 'group'.")
  .warn_simultaneous(object)

  stats <- .group_boot_stats(object, G, h0c = FALSE)
  alpha <- 1 - level
  B <- length(stats$max)
  if (stat == "maxmin") {
    if (alpha / 2 * (B + 1) < 5) .warn_small_B(B, level)
    qtype <- if ((alpha / 2 * B) %% 1 == 0) 1 else 7
    q_hi <- quantile(stats$max, 1 - alpha / 2, type = qtype, names = FALSE)
    q_lo <- quantile(stats$min, alpha / 2, type = qtype, names = FALSE)
    lower <- object$bhat[idx] - object$se[idx] * q_hi
    upper <- object$bhat[idx] - object$se[idx] * q_lo
    quants <- c(min = q_lo, max = q_hi)
  } else {
    if (alpha * (B + 1) < 5) .warn_small_B(B, level)
    qtype <- if ((alpha * B) %% 1 == 0) 1 else 7
    q_abs <- quantile(stats$absmax, 1 - alpha, type = qtype, names = FALSE)
    lower <- object$bhat[idx] - object$se[idx] * q_abs
    upper <- object$bhat[idx] + object$se[idx] * q_abs
    quants <- c(abs = q_abs)
  }
  m <- cbind(lower, upper)
  dimnames(m) <- list(pnames[idx], c("lower", "upper"))
  attr(m, "simultaneous") <- list(group = G, stat = stat, level = level, quantiles = quants,
                                  quantile.type = qtype, B = B)
  class(m) <- c("silm_confint", "matrix", "array")
  m
}

#' @export
print.silm_confint <- function(x, digits = getOption("digits"), ...) {
  info <- attr(x, "simultaneous")
  if (!is.null(info)) {
    cat(sprintf("Simultaneous %s%% confidence intervals (group of %d coefficients; %s; B = %d)\n",
                format(100 * info$level), length(info$group),
                if (info$stat == "maxmin") "max/min statistic" else "max |T| statistic", info$B))
  }
  m <- unclass(x)
  attr(m, "simultaneous") <- NULL
  print(m, digits = digits, ...)
  invisible(x)
}

# Per-sample max, min and max |.| over the group G of the studentized bootstrap
# statistics (centred, or under the complete null hypothesis if h0c = TRUE).
.group_boot_stats <- function(object, G, h0c) {
  p <- length(object$bhat)
  if (length(G) == p) return(object$boot.summary)
  for (gs in object$group.summary) {
    if (identical(gs$index, G)) return(gs)
  }
  dist <- if (h0c) object$cboot.dist.underH0c else object$cboot.dist
  if (is.null(dist)) {
    .stop("The bootstrap distribution for this group was not stored: refit with ",
          "return.bootdist = TRUE, or list the group in 'groups'",
          if (h0c) " (the bootstrap under the complete null hypothesis is needed: use multiplecorr.method = \"WY\" or boot.H0c = TRUE)" else "",
          ".")
  }
  # The stored distributions are se_j * T*_j on the scale of bhat.
  T <- dist[G, , drop = FALSE] / object$se[G]
  if (h0c) return(list(absmax.H0c = unname(apply(abs(T), 2, max))))
  list(max = unname(apply(T, 2, max)), min = unname(apply(T, 2, min)),
       absmax = unname(apply(abs(T), 2, max)))
}

.warn_simultaneous <- function(object) {
  if (isTRUE(object$gaussian.stub)) {
    warning("This fit used gaussian.stub = TRUE: the bootstrap distribution consists of ",
            "independent N(0, 1) draws and ignores the dependence between coefficients.",
            call. = FALSE)
  }
  if (identical(object$boot.type, "residual")) {
    .message_once("residual_simultaneous",
                  "The residual bootstrap is valid for simultaneous inference only under ",
                  "homoscedastic errors (Dezeure, Buehlmann and Zhang, 2017, Theorem 1 and ",
                  "Section 3.2); under heteroscedasticity use boot.type = \"wild\" with ",
                  "robust = TRUE.")
  }
}

.warn_small_B <- function(B, level) {
  warning("B = ", B, " bootstrap samples are few for level ", level,
          ": the extreme quantiles are inaccurate.", call. = FALSE)
}
