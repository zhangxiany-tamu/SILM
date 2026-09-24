# Resampling for boot.lasso.proj().
#
# resample() is adapted from 'hdi' 0.1-10 (R/helpers.R; GPL, see
# inst/COPYRIGHTS): the residual bootstrap and the wild bootstrap with Gaussian
# multipliers draw exactly as in hdi. The Mammen multipliers are a SILM
# addition (Dezeure, Buehlmann and Zhang, 2017, Section 4.1).

# n x B matrix of bootstrap errors built from the centred residuals r.
resample <- function(r, B, wild, multiplier = "gaussian") {
  if (wild) {
    Ui <- switch(multiplier,
      gaussian = replicate(B, rnorm(length(r))),
      mammen = replicate(B, .rmammen(length(r)))
    )
    rs <- r * Ui
  } else {
    rs <- replicate(B, sample(r, replace = TRUE))
  }
  rs
}

# Two-point distribution of Mammen (1993): (1 - sqrt(5)) / 2 with probability
# (sqrt(5) + 1) / (2 sqrt(5)), otherwise (1 + sqrt(5)) / 2. It has mean 0 and
# second and third moments 1. Uses one uniform draw per value.
.rmammen <- function(n) {
  s5 <- sqrt(5)
  ifelse(runif(n) <= (s5 + 1) / (2 * s5), (1 - s5) / 2, (1 + s5) / 2)
}
