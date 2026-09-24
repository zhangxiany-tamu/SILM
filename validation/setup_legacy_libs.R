# Build the oracle libraries used by the equivalence harness.
#
# The archived CRAN packages (SILM 1.0.0, hdi, scalreg) are installed into
# throwaway libraries outside the repository. glmnet is never installed into
# the legacy libraries: old and new code must share one glmnet build.
#
# Usage: Rscript validation/setup_legacy_libs.R [--glmnet5]

source(file.path("validation", "paths.R"))

ARCHIVE_URL <- "https://cran.r-project.org/src/contrib/Archive"
CRAN <- local({
  repos <- getOption("repos")
  if (is.null(repos) || !nzchar(repos[1]) || identical(unname(repos[1]), "@CRAN@")) {
    "https://cloud.r-project.org"
  } else {
    repos
  }
})

TARBALLS <- list(
  scalreg = list(path = "scalreg/scalreg_1.0.1.tar.gz",
                 sha256 = "7daea20898b0eacb93dfc7149eeb26274260bfcc3ee8213a0ecfdccb127dcc4d"),
  hdi_0.1_10 = list(path = "hdi/hdi_0.1-10.tar.gz",
                    sha256 = "15f37a620e2c51b158d50472e442b34391c7eef92acd9291e8d468e14ba49206"),
  hdi_0.1_6 = list(path = "hdi/hdi_0.1-6.tar.gz",
                   sha256 = "989d4023d6c1ee429cc49b7efbbc44b69c3ffec13a48f24dc44192f09924fed3"),
  SILM = list(path = "SILM/SILM_1.0.0.tar.gz",
              sha256 = "e6260ae569018ee2894abdcc37bacdae07ea66c2602adc4a75b2a1d0dbdd51c5")
)

sha256_file <- function(file) {
  out <- system2("shasum", c("-a", "256", shQuote(file)), stdout = TRUE)
  strsplit(out, "\\s+")[[1]][1]
}

fetch_tarball <- function(entry) {
  dest <- file.path(silm_dev_path("archive"), basename(entry$path))
  if (!file.exists(dest)) {
    utils::download.file(file.path(ARCHIVE_URL, entry$path), dest, mode = "wb", quiet = TRUE)
  }
  got <- sha256_file(dest)
  if (!identical(got, entry$sha256)) {
    stop("sha256 mismatch for ", basename(dest), ": ", got, call. = FALSE)
  }
  dest
}

is_installed <- function(pkg, lib) {
  file.exists(file.path(lib, pkg, "DESCRIPTION"))
}

install_cran <- function(pkgs, lib, lib_search) {
  missing <- pkgs[!vapply(pkgs, function(p) {
    nzchar(system.file(package = p, lib.loc = lib_search))
  }, logical(1))]
  if (length(missing)) {
    utils::install.packages(missing, lib = lib, repos = CRAN, type = getOption("pkgType"),
                            dependencies = c("Depends", "Imports", "LinkingTo"),
                            Ncpus = 4L, quiet = TRUE)
  }
}

install_tarball <- function(file, lib, lib_search) {
  withr_libs <- c(lib, lib_search)
  old <- .libPaths()
  on.exit(.libPaths(old), add = TRUE)
  .libPaths(withr_libs)
  utils::install.packages(file, lib = lib, repos = NULL, type = "source", quiet = TRUE)
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  use_dev_makevars()
  base_libs <- .libPaths()
  lib_dev <- silm_dev_path("lib-dev")
  lib_znz <- silm_dev_path("lib-legacy-znz")
  lib_cv <- silm_dev_path("lib-legacy-cv")

  # Development tooling (shared by old and new code).
  install_cran(c("lars", "covr"), lib_dev, c(lib_dev, base_libs))

  if ("--glmnet5" %in% args) {
    lib_g5 <- silm_dev_path("lib-glmnet-5.0")
    if (!is_installed("glmnet", lib_g5)) {
      utils::install.packages("glmnet", lib = lib_g5, repos = CRAN, type = "source",
                              dependencies = c("Depends", "Imports", "LinkingTo"),
                              Ncpus = 4L, quiet = TRUE)
    }
  }

  # Legacy stack with hdi 0.1-10 (SILM as used 2019-03 .. 2026-07).
  search_znz <- c(lib_znz, lib_dev, base_libs)
  install_cran(c("linprog", "SIS"), lib_znz, search_znz)
  for (key in c("scalreg", "hdi_0.1_10", "SILM")) {
    pkg <- sub("_.*$", "", key)
    if (!is_installed(pkg, lib_znz)) {
      install_tarball(fetch_tarball(TARBALLS[[key]]), lib_znz, c(lib_dev, base_libs))
    }
  }

  # hdi 0.1-6 masks 0.1-10 when lib-legacy-cv precedes lib-legacy-znz.
  if (!is_installed("hdi", lib_cv)) {
    install_tarball(fetch_tarball(TARBALLS[["hdi_0.1_6"]]), lib_cv, c(lib_znz, lib_dev, base_libs))
  }

  report <- vapply(c(lib_dev, lib_znz, lib_cv), function(l) {
    paste(basename(l), paste(sort(list.files(l)), collapse = ", "), sep = ": ")
  }, character(1))
  writeLines(report)
}

main()
