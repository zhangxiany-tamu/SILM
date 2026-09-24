#' Group tests with the bootstrap
#'
#' P-values for the null hypotheses \eqn{H_{0,G}: \beta_j = 0} for all
#' \eqn{j \in G}, based on the max-type statistic
#' \eqn{\max_{j \in G} |T_j|}, \eqn{T_j = \hat b_j / \hat{s.e.}_j}, calibrated
#' by the bootstrap under the complete null hypothesis (Dezeure, Bühlmann and
#' Zhang, 2017, Sections 3.2 and 4.3):
#' \deqn{P_G = \frac{1 + \#\{b: \max_{j \in G} |T^{*0}_{jb}| \ge \max_{j \in G} |T_j|\}}{B + 1},}{P_G = (1 + #{b: max_G |T*0_jb| >= max_G |T_j|}) / (B + 1),}
#' with the same conventions as the Westfall-Young adjusted p-values of
#' [boot.lasso.proj()]; in particular, the p-value of the group of all
#' coefficients equals the smallest adjusted p-value. This test is not
#' available in hdi's `boot.lasso.proj()`.
#'
#' No adjustment is made across several groups. The fit must contain the
#' bootstrap under the complete null hypothesis (`multiplecorr.method = "WY"`,
#' the default, or `boot.H0c = TRUE`) and, for groups other than all
#' coefficients, either `return.bootdist = TRUE` or the group in `groups`.
#'
#' @param object A result of [boot.lasso.proj()].
#' @param group A group of coefficients (indices, names or a logical vector),
#'   or a list of groups.
#' @param ... Not used.
#' @return The p-values, one per group (named if `group` is a named list).
#' @references Dezeure, R., Bühlmann, P. and Zhang, C.-H. (2017).
#'   High-dimensional simultaneous inference with the bootstrap. \emph{TEST},
#'   26, 685-719.
#' @seealso [boot.lasso.proj()], [confint.silm_proj()]
#' @examples
#' set.seed(1)
#' x <- matrix(rnorm(50 * 15), 50, 15)
#' y <- x[, 1] + rnorm(50)
#' fit <- boot.lasso.proj(x, y, B = 50, boot.shortcut = TRUE, return.bootdist = TRUE)
#' groupTest(fit, list(signal = 1:3, noise = 4:15))
#' @export
groupTest <- function(object, group, ...) UseMethod("groupTest")

#' @export
groupTest.default <- function(object, group, ...) {
  .stop("groupTest() requires a boot.lasso.proj() fit.")
}

#' @export
groupTest.silm_boot_lasso_proj <- function(object, group, ...) {
  if (is.null(object$boot.summary$absmax.H0c)) {
    .stop("The fit does not contain the bootstrap under the complete null hypothesis; ",
          "refit with multiplecorr.method = \"WY\" or boot.H0c = TRUE.")
  }
  p <- length(object$bhat)
  groups <- if (is.list(group)) group else list(group)
  pv <- vapply(groups, function(g) {
    G <- .resolve_group(g, p, names(object$bhat), "group")
    if (length(G) > 1L) .warn_simultaneous(object)
    M0 <- .group_boot_stats(object, G, h0c = TRUE)$absmax.H0c
    (sum(M0 >= max(abs(object$tstat[G]))) + 1) / (length(M0) + 1)
  }, numeric(1))
  names(pv) <- if (is.list(group)) names(group) else NULL
  pv
}
