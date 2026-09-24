#' SILM: Simultaneous Inference for High-Dimensional Linear Models
#'
#' Simultaneous inference for the high-dimensional linear model
#' \eqn{Y = X\beta + \epsilon} based on the de-biased (de-sparsified) lasso and
#' the bootstrap.
#'
#' @section Zhang and Cheng (2017):
#' Bootstrap of the linear part of the de-biased lasso with Gaussian
#' multipliers:
#' * [Sim.CI()]: simultaneous confidence intervals for a group of coefficients;
#' * [SR()]: support recovery;
#' * [ST()]: testing for sparse signals in a large group (screening plus
#'   bootstrap test);
#' * [Step()]: stepdown multiple testing with familywise error control;
#' * [Theta.hat()]: the estimate of the inverse Gram matrix they use.
#'
#' @section Dezeure, Bühlmann and Zhang (2017):
#' Bootstrap of the entire de-sparsified lasso (residual, wild with Gaussian or
#' Mammen multipliers, or xyz-paired bootstrap), with robust standard errors:
#' * [boot.lasso.proj()]: p-values and Westfall-Young adjusted p-values;
#' * [confint.silm_proj()]: individual and simultaneous confidence intervals;
#' * [groupTest()]: group tests.
#'
#' [lasso.proj()] computes the de-sparsified lasso with asymptotic Gaussian
#' inference (van de Geer et al., 2014). `lasso.proj()` and `boot.lasso.proj()`
#' reproduce the functions of the archived package 'hdi' (version 0.1-10).
#'
#' @section Reproducibility:
#' SILM 2.0.0 reproduces SILM 1.0.0 and hdi 0.1-10 exactly (the same numbers
#' under the same random seed); see the sections "Nodewise tuning" in [SR()]
#' and "Compatibility with hdi 0.1-10" in [lasso.proj()] and
#' [boot.lasso.proj()] for the options that select older behaviour.
#'
#' @references Zhang, X. and Cheng, G. (2017). Simultaneous inference for
#'   high-dimensional linear models. \emph{Journal of the American Statistical
#'   Association}, 112, 757-768.
#'
#'   Dezeure, R., Bühlmann, P. and Zhang, C.-H. (2017). High-dimensional
#'   simultaneous inference with the bootstrap. \emph{TEST}, 26, 685-719.
#' @keywords internal
"_PACKAGE"

## Exports are declared in each function's roxygen block.

#' @importFrom stats coef confint ecdf p.adjust p.adjust.methods pnorm predict
#' @importFrom stats qnorm quantile rnorm runif sd
#' @importFrom glmnet glmnet cv.glmnet
NULL
