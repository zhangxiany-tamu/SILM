# Parallel map and random-number helpers.

# mapply() or parallel::mcmapply(). Forking is only used when requested, with
# more than one core, and not on Windows (where mcmapply cannot fork). Callers
# only parallelise computations that draw no random numbers, so the results
# never depend on the backend.
.silm_mapply <- function(FUN, ..., MoreArgs = NULL, SIMPLIFY = TRUE, parallel = FALSE,
                         ncores = 1L) {
  use_fork <- isTRUE(parallel) && ncores > 1L
  if (use_fork && .Platform$OS.type == "windows") {
    .warn_once("windows_parallel",
               "Parallel computation uses forking, which is not available on Windows; ",
               "running sequentially.")
    use_fork <- FALSE
  }
  if (use_fork) {
    parallel::mcmapply(FUN, ..., MoreArgs = MoreArgs, SIMPLIFY = SIMPLIFY,
                       USE.NAMES = FALSE, mc.cores = ncores)
  } else {
    mapply(FUN, ..., MoreArgs = MoreArgs, SIMPLIFY = SIMPLIFY, USE.NAMES = FALSE)
  }
}

.silm_env <- new.env(parent = emptyenv())

.warn_once <- function(key, ...) {
  if (is.null(.silm_env[[key]])) {
    .silm_env[[key]] <- TRUE
    warning(..., call. = FALSE)
  }
  invisible(NULL)
}
