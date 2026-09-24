# Checks of the boot.lasso.proj() arguments that are SILM additions.

.boot_check_extras <- function(boot.type, wild, wild_missing, type_missing, multiplier,
                               multiplier_missing, boot.H0c, multiplecorr.method, groups,
                               gaussian.stub, robust, p, pnames) {
  boot.type <- match.arg(boot.type, c("residual", "wild", "xyz"))
  if (!wild_missing && !type_missing && xor(isTRUE(wild), boot.type == "wild")) {
    .stop("'wild = ", wild, "' contradicts 'boot.type = \"", boot.type, "\"'; use boot.type only.")
  }
  multiplier <- match.arg(multiplier, c("gaussian", "mammen"))
  if (boot.type != "wild" && !multiplier_missing && multiplier != "gaussian") {
    .stop("'multiplier' only applies to the wild bootstrap (boot.type = \"wild\").")
  }
  if (multiplecorr.method == "WY" && !boot.H0c) {
    .stop("multiplecorr.method = \"WY\" needs the bootstrap under the complete null ",
          "hypothesis (boot.H0c = TRUE).")
  }
  if (gaussian.stub && (boot.type == "xyz" || multiplier != "gaussian")) {
    .stop("'gaussian.stub' replaces the bootstrap and cannot be combined with ",
          "boot.type = \"xyz\" or Mammen multipliers.")
  }
  if (boot.type == "xyz" && !robust) {
    warning("The xyz-paired bootstrap is defined with the robust standard error ",
            "(Dezeure, Buehlmann and Zhang, 2017, Section 4.2); robust = FALSE is not ",
            "covered by the theory.", call. = FALSE)
  }
  list(boot.type = boot.type, wild = boot.type == "wild",
       multiplier = if (boot.type == "wild") multiplier else NULL,
       boot.H0c = boot.H0c, groups = .resolve_groups(groups, p, pnames))
}

# A group of coefficients: indices, a logical vector of length p, or names.
# Returned as sorted unique indices.
.resolve_group <- function(group, p, pnames, arg = "group") {
  if (is.logical(group)) {
    if (length(group) != p || anyNA(group)) .stop("A logical '", arg, "' must have length ", p, ".")
    group <- which(group)
  } else if (is.character(group)) {
    if (is.null(pnames) || !all(group %in% pnames)) .stop("Unknown names in '", arg, "'.")
    group <- match(group, pnames)
  }
  if (!is.numeric(group) || !length(group) || anyNA(group) || any(group != floor(group)) ||
      any(group < 1 | group > p)) {
    .stop("'", arg, "' must contain coefficient indices between 1 and ", p, ".")
  }
  sort(unique(as.integer(group)))
}

.resolve_groups <- function(groups, p, pnames) {
  if (is.null(groups)) return(NULL)
  if (!is.list(groups)) groups <- list(groups)
  lapply(groups, .resolve_group, p = p, pnames = pnames, arg = "groups")
}
