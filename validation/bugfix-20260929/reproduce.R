# Run after installing this checkout, with its library first in R_LIBS.
# Rscript validation/bugfix-20260929/reproduce.R
library(SILM)

set.seed(92)
n <- 120L
p <- 6L
q <- qr.Q(qr(cbind(1, matrix(rnorm(n * (p + 1)), n))))
X <- q[, 2:(p + 1)] * sqrt(n)
y <- as.vector(X %*% c(20, -15, rep(0, p - 2)) + sqrt(n) * q[, p + 2])
width <- function(units, solver) {
  set.seed(93)
  fit <- Sim.CI(X, units * y, seq_len(p), M = 199, scaled.lasso = solver)
  diff(fit$band.st[, 1]) / (2 * units)
}
units <- do.call(rbind, lapply(c("legacy", "equivariant"), function(solver) {
  original <- width(1, solver)
  converted <- width(1e-6, solver)
  data.frame(solver, original, converted, ratio = converted / original)
}))
cat("Studentized half-width after converting back to original response units:\n")
print(units, row.names = FALSE, digits = 10)
stopifnot(abs(units$ratio[2] - 1) < 1e-8)

set.seed(702)
x <- matrix(rnorm(80 * 3), 80, 3)
colnames(x) <- c("dup", "dup", "other")
y <- 2 * x[, 1] - 3 * x[, 2] + rnorm(80)
fit <- lasso.proj(x, y, suppress.grouptesting = TRUE)
expected <- fit$bhat[2] + c(-1, 1) * qnorm(0.975) * fit$se[2]
cat("\nDuplicate-name numeric selection, coefficient 2:\n")
print(confint(fit, parm = 2))
stopifnot(isTRUE(all.equal(as.numeric(confint(fit, parm = 2)), unname(expected))))
invisible(capture.output(print(fit)))

msg <- tryCatch(ST(x, y, sub.size = 2, test.set = 1, M = 9), error = conditionMessage)
stopifnot(is.character(msg), grepl("at least 3", msg))
cat("\nST screening boundary: ", msg, "\n", sep = "")
wy <- lasso.proj(x, y, multiplecorr.method = "WY", N = 1,
                  suppress.grouptesting = TRUE)
stopifnot(all(is.finite(wy$pval.corr)))
stub <- suppressWarnings(boot.lasso.proj(x[, 1, drop = FALSE], y,
               Z = x[, 1, drop = FALSE], betainit = 0, sigma = 1, B = 9,
               gaussian.stub = TRUE, return.bootdist = TRUE))
stopifnot(identical(dim(stub$cboot.dist), c(1L, 9L)),
          all(is.finite(stub$pval.corr)), all(is.finite(confint(stub))))
cat("WY N=1 and single-predictor Gaussian-stub bootstrap: passed.\n")
sessionInfo()
