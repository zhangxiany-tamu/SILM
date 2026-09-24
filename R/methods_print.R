#' Print results of lasso.proj and boot.lasso.proj
#'
#' @param x A result of [lasso.proj()] or [boot.lasso.proj()].
#' @param n Maximal number of coefficients shown (those with the smallest
#'   adjusted p-values).
#' @param ... Not used.
#' @return `x`, invisibly.
#' @export
print.silm_proj <- function(x, n = 10L, ...) {
  boot <- identical(x$method, "boot.lasso.proj")
  cat(if (boot) "Bootstrapped de-sparsified lasso" else "De-sparsified lasso", "\n")
  se_type <- if (isTRUE(x$robust)) "robust" else "homoscedastic"
  settings <- c(sprintf("family %s", x$family), sprintf("%s standard errors", se_type))
  if (boot) {
    boot_desc <- x$boot.type
    if (identical(x$boot.type, "wild")) boot_desc <- paste0(boot_desc, " (", x$multiplier, " multipliers)")
    settings <- c(settings, sprintf("%s bootstrap, B = %d", boot_desc, x$B))
  }
  cat(paste(settings, collapse = "; "), "\n")
  cat("Estimated noise level (sigmahat):", format(x$sigmahat, digits = 4), "\n")
  for (a in c(0.05, 0.01)) {
    sel <- which(x$pval.corr <= a)
    cat(sprintf("Significant at level %s (adjusted p-values): %s\n", a,
                if (length(sel)) paste(names(sel) %||% sel, collapse = ", ") else "none"))
  }
  ord <- utils::head(order(x$pval.corr, x$pval), n)
  tab <- data.frame(estimate = x$bhat[ord], se = x$se[ord], p.value = x$pval[ord],
                    p.adjusted = x$pval.corr[ord])
  rownames(tab) <- names(x$bhat)[ord] %||% ord
  cat(sprintf("\nCoefficients with the smallest adjusted p-values (%d of %d):\n",
              length(ord), length(x$bhat)))
  print(signif(tab, 4))
  if (!isTRUE(x$robust)) {
    cat("\nNote: robust = TRUE is recommended in practice (Dezeure, Buehlmann and Zhang, 2017).\n")
  }
  invisible(x)
}

`%||%` <- function(a, b) if (is.null(a)) b else a
