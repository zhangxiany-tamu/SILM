#' Print results of lasso.proj and boot.lasso.proj
#'
#' @param x A result of [lasso.proj()] or [boot.lasso.proj()].
#' @param n Maximal number of coefficients shown (those with the smallest
#'   adjusted p-values).
#' @param ... Not used.
#' @return `x`, invisibly.
#' @details Duplicated predictor names are made unique in the printed display;
#'   the names stored in `x` are unchanged.
#' @export
print.silm_proj <- function(x, n = 10L, ...) {
  boot <- identical(x$method, "boot.lasso.proj")
  cat(if (boot) "Bootstrapped de-sparsified lasso" else "De-sparsified lasso", "\n")
  se_type <- if (isTRUE(x$robust)) {
    # hdi's divisor n (robust.divisor = "n"), or n - s (equation 5, the default).
    sprintf("robust (divisor %s)", if (identical(x$robust.divisor, "n")) "n" else "n - s")
  } else {
    "homoscedastic"
  }
  settings <- c(sprintf("family %s", x$family), sprintf("%s standard errors", se_type))
  if (boot) {
    boot_desc <- x$boot.type
    if (identical(x$boot.type, "wild")) boot_desc <- paste0(boot_desc, " (", x$multiplier, " multipliers)")
    B_desc <- if (!is.null(x$B.eff) && x$B.eff < x$B) sprintf("%d (%d usable)", x$B, x$B.eff) else x$B
    settings <- c(settings, sprintf("%s bootstrap, B = %s", boot_desc, B_desc))
  }
  cat(paste(settings, collapse = "; "), "\n")
  cat("Estimated noise level (sigmahat):", format(x$sigmahat, digits = 4), "\n")
  # Disambiguate labels only for display, in the original coefficient order.
  # The fitted vectors retain the predictor names supplied by the caller.
  labels <- make.unique(as.character(names(x$bhat) %||% seq_along(x$bhat)))
  for (a in c(0.05, 0.01)) {
    sel <- which(x$pval.corr <= a)
    cat(sprintf("Significant at level %s (adjusted p-values): %s\n", a,
                if (length(sel)) paste(labels[sel], collapse = ", ") else "none"))
  }
  ord <- utils::head(order(x$pval.corr, x$pval), n)
  tab <- data.frame(estimate = x$bhat[ord], se = x$se[ord], p.value = x$pval[ord],
                    p.adjusted = x$pval.corr[ord], row.names = labels[ord])
  cat(sprintf("\nCoefficients with the smallest adjusted p-values (%d of %d):\n",
              length(ord), length(x$bhat)))
  print(signif(tab, 4))
  if (!isTRUE(x$robust)) {
    cat("\nNote: robust = TRUE is recommended in practice (Dezeure, Buehlmann and Zhang, 2017).\n")
  }
  invisible(x)
}

`%||%` <- function(a, b) if (is.null(a)) b else a
