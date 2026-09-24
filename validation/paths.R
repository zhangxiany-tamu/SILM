# Locations of development caches and oracle libraries (outside the repository,
# so that Google Drive never syncs installed packages or large outputs).

silm_dev_cache <- function() {
  path <- Sys.getenv("SILM_DEV_CACHE", tools::R_user_dir("SILM-dev", "cache"))
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path)
}

silm_dev_path <- function(...) {
  path <- file.path(silm_dev_cache(), ...)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path)
}

# Use a private Makevars (if present in the cache) for source builds, without
# touching the user's ~/.R/Makevars.
use_dev_makevars <- function() {
  mk <- file.path(silm_dev_cache(), "Makevars")
  if (file.exists(mk)) Sys.setenv(R_MAKEVARS_USER = mk)
  invisible(mk)
}

# Library search paths for the two sides of a comparison.
#   mode "znz": SILM 1.0.0 + hdi 0.1-10 (+ scalreg 1.0.1)
#   mode "cv" : SILM 1.0.0 + hdi 0.1-6  (+ scalreg 1.0.1)
legacy_libpaths <- function(mode = c("znz", "cv"), glmnet_lib = NULL) {
  mode <- match.arg(mode)
  libs <- c(silm_dev_path("lib-legacy-znz"), silm_dev_path("lib-dev"))
  if (mode == "cv") libs <- c(silm_dev_path("lib-legacy-cv"), libs)
  c(glmnet_lib, libs, .libPaths())
}

new_libpaths <- function(new_lib, glmnet_lib = NULL) {
  c(glmnet_lib, new_lib, silm_dev_path("lib-dev"), .libPaths())
}
