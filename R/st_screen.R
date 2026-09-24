# Helpers for the screening step of ST() (Zhang and Cheng, 2017, Section 5.3).

# Centre each column and scale it to unit Euclidean norm. (Numerically
# identical to SIS::standardize, which SILM 1.0.0 used for the screening
# statistic, so the screened sets are unchanged.)
.standardize_unitnorm <- function(X) {
  centred <- sweep(X, 2, colMeans(X))
  norms <- sqrt(apply(centred, 2, crossprod))
  sweep(centred, 2, norms, "/")
}
