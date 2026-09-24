# P-values of boot.lasso.proj() (Dezeure, Buehlmann and Zhang, 2017,
# Sections 3.1 and 4.3).
#
# Adapted from 'hdi' 0.1-10 (R/boot.lasso-proj.R; GPL, see inst/COPYRIGHTS).
# The expressions are those of hdi, so the p-values agree exactly.

# Two-sided bootstrap p-values from the centred bootstrap distribution of the
# studentized statistics: with c_j = #{b: T*_jb <= t_j}, replaced by B - c_j
# when c_j >= B/2, pval_j = (2 c_j + 1) / (B + 1).
.boot_pvalues <- function(bproj, se, cboot.dist, B) {
  dist <- bproj / se - cboot.dist
  counts <- apply(dist >= 0, 1, sum)
  if (any(counts >= B / 2)) {
    counts[counts >= B / 2] <- B - counts[counts >= B / 2]
  }
  counts <- 2 * counts
  (counts + 1) / (B + 1)
}

# Westfall-Young (max-T) adjusted p-values from the bootstrap under the
# complete null hypothesis: (1 + #{b: max_k |T*0_kb| >= |t_j|}) / (B + 1).
.boot_wy <- function(bproj, se, cboot.dist.underH0c, B) {
  max.t.dist <- apply(abs(cboot.dist.underH0c), 2, max)
  counts.matrix <- sapply(max.t.dist, FUN = ">=", abs(bproj / se))
  counts <- apply(counts.matrix, 1, sum)
  (counts + 1) / (B + 1)
}

# p.adjust() of the bootstrap p-values, warning when B is too small for the
# smallest adjusted p-values to be accurate.
.boot_padjust <- function(pval, method, B, p) {
  inaccurate.pval <- pval <= (4 + 1) / (B + 1)
  B.toosmall.formc <- (1 + 4) / (B + 1) * p > 0.05
  if (any(inaccurate.pval) & B.toosmall.formc) {
    warning(paste("Lacking accuracy for multiple testing:\n",
                  "The provided number of bootstrap samples B was not high enough to ",
                  "accurately compute\nthe smallest multiple testing corrected p-values.\n",
                  "The lowest attainable p-value for the chosen B value is 1/(B+1)=",
                  signif(1 / (B + 1), 3), ".\n",
                  "Reasonable accuracy is only attained starting from (4+1)/(B+1)=",
                  signif((4 + 1) / (B + 1), 3), ".\n",
                  "This issue is easily solved by using 'WY' as multiple testing method.",
                  sep = ""))
  }
  p.adjust(pval, method = method)
}
