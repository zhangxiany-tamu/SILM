# Equivalence harness: run archived (old) and current (new) code side by side.
#
# Each scenario provides a list of cases. For every case the parent generates
# the data once; the old and the new side then run in separate R processes
# (callr) with their own library paths, the same RNG kind and the same seed.
# Results are compared with identical() on the extracted values AND on the
# .Random.seed left behind by the call.

source(file.path("validation", "paths.R"))

RNG_DEFAULT <- c("Mersenne-Twister", "Inversion", "Rejection")

# ---------------------------------------------------------------------------
# Child-side runner (executed inside callr processes)
# ---------------------------------------------------------------------------

child_run_cases <- function(cases, fun, threads) {
  Sys.setenv(OPENBLAS_NUM_THREADS = threads, OMP_NUM_THREADS = threads)
  run_one <- function(case) {
    if (identical(case$rng, "3.5.0")) {
      suppressWarnings(RNGversion("3.5.0"))
    } else {
      RNGkind("Mersenne-Twister", "Inversion", "Rejection")
    }
    set.seed(case$seed)
    warns <- character()
    msgs <- character()
    t0 <- proc.time()[["elapsed"]]
    value <- tryCatch(
      withCallingHandlers(
        fun(case$data, case$args),
        warning = function(w) {
          warns <<- c(warns, conditionMessage(w))
          invokeRestart("muffleWarning")
        },
        message = function(m) {
          msgs <<- c(msgs, conditionMessage(m))
          invokeRestart("muffleMessage")
        }
      ),
      error = function(e) structure(list(message = conditionMessage(e)), class = "harness_error")
    )
    list(
      value = value,
      seed_after = if (exists(".Random.seed", globalenv())) get(".Random.seed", globalenv()) else NULL,
      warnings = unique(warns),
      n_warnings = length(warns),
      messages = unique(msgs),
      time = proc.time()[["elapsed"]] - t0
    )
  }
  versions <- vapply(c("SILM", "glmnet", "lars", "hdi", "scalreg"), function(p) {
    if (nzchar(system.file(package = p))) as.character(utils::packageVersion(p)) else NA_character_
  }, character(1))
  list(results = lapply(cases, run_one), versions = versions,
       blas = extSoftVersion()[["BLAS"]], lapack = La_library(),
       libpaths = .libPaths())
}

# ---------------------------------------------------------------------------
# Parent-side helpers
# ---------------------------------------------------------------------------

install_new <- function(pkg_dir = ".", lib = silm_dev_path("lib-new"), extra_libs = NULL) {
  use_dev_makevars()
  unlink(file.path(lib, "SILM"), recursive = TRUE)
  env <- c(R_LIBS = paste(c(lib, extra_libs, silm_dev_path("lib-dev"), .libPaths()),
                          collapse = .Platform$path.sep))
  out <- system2(file.path(R.home("bin"), "R"),
                 c("CMD", "INSTALL", "--no-docs", "--no-multiarch", "--no-test-load",
                   paste0("--library=", shQuote(lib)), shQuote(normalizePath(pkg_dir))),
                 stdout = TRUE, stderr = TRUE, env = paste0(names(env), "=", env))
  status <- attr(out, "status")
  if (!is.null(status) && status != 0) {
    stop("R CMD INSTALL failed:\n", paste(out, collapse = "\n"), call. = FALSE)
  }
  lib
}

run_side_bg <- function(cases, fun, libpath, threads = "1") {
  callr::r_bg(child_run_cases, args = list(cases = cases, fun = fun, threads = threads),
              libpath = libpath, env = c(callr::rcmd_safe_env(), OPENBLAS_NUM_THREADS = threads,
                                         OMP_NUM_THREADS = threads),
              supervise = TRUE)
}

collect_side <- function(proc) {
  proc$wait()
  tryCatch(proc$get_result(),
           error = function(e) structure(list(message = conditionMessage(e)), class = "side_error"))
}

max_abs_diff <- function(a, b) {
  flat <- function(x) {
    if (is.list(x)) return(unlist(lapply(x, flat), use.names = FALSE))
    if (is.numeric(x) || is.logical(x)) return(as.numeric(x))
    numeric()
  }
  fa <- flat(a)
  fb <- flat(b)
  if (length(fa) != length(fb) || !length(fa)) return(NA_real_)
  d <- abs(fa - fb)
  d[is.nan(d)] <- 0
  if (all(is.na(d))) return(NA_real_)
  max(d, na.rm = TRUE)
}

classify_case <- function(old, new, scenario, case) {
  old_err <- inherits(old$value, "harness_error")
  new_err <- inherits(new$value, "harness_error")
  same_val <- identical(old$value, new$value)
  same_seed <- identical(old$seed_after, new$seed_after)
  allowed <- scenario$allowed
  status <- if (old_err && new_err) {
    if (isTRUE(scenario$both_error_ok)) "BOTH-ERROR" else "FAIL"
  } else if (old_err && !new_err) {
    if (isTRUE(scenario$old_error_ok)) "OLD-ERROR" else "FAIL"
  } else if (new_err) {
    "FAIL"
  } else if (same_val && same_seed) {
    "E0"
  } else if (is.function(allowed) && isTRUE(allowed(old, new, case))) {
    "ALLOWED"
  } else {
    "FAIL"
  }
  list(status = status, same_value = same_val, same_seed = same_seed,
       max_abs_diff = if (!old_err && !new_err) max_abs_diff(old$value, new$value) else NA_real_,
       old_error = if (old_err) old$value$message else NA_character_,
       new_error = if (new_err) new$value$message else NA_character_,
       old_warnings = old$n_warnings, new_warnings = new$n_warnings,
       time_old = old$time, time_new = new$time)
}

run_scenario <- function(scenario, new_lib, glmnet_lib = NULL, extra_new_libs = NULL) {
  cases <- scenario$cases
  old_lp <- if (is.null(scenario$old_libpath)) {
    legacy_libpaths(scenario$legacy_mode, glmnet_lib)
  } else {
    scenario$old_libpath
  }
  new_lp <- c(glmnet_lib, new_lib, extra_new_libs, silm_dev_path("lib-dev"), .libPaths())
  t0 <- proc.time()[["elapsed"]]
  old_proc <- run_side_bg(cases, scenario$old_fun, old_lp)
  new_proc <- run_side_bg(cases, scenario$new_fun, new_lp)
  old <- collect_side(old_proc)
  new <- collect_side(new_proc)
  if (inherits(old, "side_error") || inherits(new, "side_error")) {
    msg <- paste("side crashed:", if (inherits(old, "side_error")) old$message else "",
                 if (inherits(new, "side_error")) new$message else "")
    rows <- lapply(seq_along(cases), function(i) {
      list(status = "FAIL", same_value = FALSE, same_seed = FALSE, max_abs_diff = NA_real_,
           old_error = msg, new_error = msg, old_warnings = NA, new_warnings = NA,
           time_old = NA, time_new = NA)
    })
    return(list(id = scenario$id, rows = rows, cases = cases, versions_old = NULL,
                versions_new = NULL, elapsed = proc.time()[["elapsed"]] - t0))
  }
  rows <- Map(function(o, n, case) classify_case(o, n, scenario, case),
              old$results, new$results, cases)
  list(id = scenario$id, rows = rows, cases = cases,
       versions_old = old$versions, versions_new = new$versions,
       blas = new$blas, elapsed = proc.time()[["elapsed"]] - t0,
       old_results = if (isTRUE(scenario$keep_results)) old$results,
       new_results = if (isTRUE(scenario$keep_results)) new$results)
}

# Split scenarios into jobs of at most `size` cases (for load balancing) and
# merge the job results back into one run per scenario.
chunk_scenarios <- function(scenarios, size = 6L) {
  jobs <- list()
  for (sc in scenarios) {
    idx <- split(seq_along(sc$cases), ceiling(seq_along(sc$cases) / size))
    for (ix in idx) {
      job <- sc
      job$cases <- sc$cases[ix]
      jobs[[length(jobs) + 1L]] <- job
    }
  }
  jobs
}

merge_runs <- function(job_runs) {
  ids <- unique(vapply(job_runs, `[[`, character(1), "id"))
  lapply(ids, function(id) {
    parts <- Filter(function(r) identical(r$id, id), job_runs)
    list(id = id,
         rows = do.call(c, lapply(parts, `[[`, "rows")),
         cases = do.call(c, lapply(parts, `[[`, "cases")),
         versions_old = parts[[1]]$versions_old, versions_new = parts[[1]]$versions_new,
         blas = parts[[1]]$blas,
         elapsed = sum(vapply(parts, `[[`, numeric(1), "elapsed")))
  })
}

summarise_run <- function(runs) {
  do.call(rbind, lapply(runs, function(r) {
    st <- vapply(r$rows, `[[`, character(1), "status")
    mad <- suppressWarnings(max(vapply(r$rows, function(x) {
      if (is.na(x$max_abs_diff)) -Inf else x$max_abs_diff
    }, numeric(1))))
    data.frame(
      scenario = r$id, cases = length(st),
      E0 = sum(st == "E0"), ALLOWED = sum(st == "ALLOWED"),
      OLD_ERROR = sum(st == "OLD-ERROR"), BOTH_ERROR = sum(st == "BOTH-ERROR"),
      FAIL = sum(st == "FAIL"),
      seeds_identical = sum(vapply(r$rows, `[[`, logical(1), "same_seed")),
      max_abs_diff = if (is.finite(mad)) signif(mad, 3) else NA_real_,
      seconds = round(r$elapsed, 1), stringsAsFactors = FALSE
    )
  }))
}

failure_details <- function(runs) {
  out <- character()
  for (r in runs) {
    for (i in seq_along(r$rows)) {
      row <- r$rows[[i]]
      if (row$status %in% c("FAIL", "ALLOWED", "OLD-ERROR", "BOTH-ERROR")) {
        out <- c(out, sprintf(
          "- `%s` case %d (%s): **%s**; value identical=%s, seed identical=%s, max|diff|=%s%s%s",
          r$id, i, r$cases[[i]]$label %||% "", row$status, row$same_value, row$same_seed,
          format(row$max_abs_diff, digits = 3),
          if (!is.na(row$old_error)) paste0("; old error: ", row$old_error) else "",
          if (!is.na(row$new_error)) paste0("; new error: ", row$new_error) else ""))
      }
    }
  }
  out
}

`%||%` <- function(a, b) if (is.null(a)) b else a

write_report <- function(runs, file, meta) {
  tab <- summarise_run(runs)
  md_table <- function(df) {
    hdr <- paste0("| ", paste(names(df), collapse = " | "), " |")
    sep <- paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|")
    body <- apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))
    c(hdr, sep, body)
  }
  lines <- c(
    sprintf("# Equivalence report (%s)", meta$date),
    "",
    sprintf("- Commit: `%s`; tier: `%s`", meta$commit, meta$tier),
    sprintf("- R %s; glmnet %s; lars %s; BLAS: %s", meta$r, meta$glmnet, meta$lars, meta$blas),
    sprintf("- Oracles: SILM %s, hdi %s (znz) / %s (cv), scalreg %s",
            meta$silm_old, meta$hdi_znz, meta$hdi_cv, meta$scalreg),
    sprintf("- Totals: %d cases; %d E0, %d ALLOWED, %d OLD-ERROR, %d BOTH-ERROR, **%d FAIL**",
            sum(tab$cases), sum(tab$E0), sum(tab$ALLOWED), sum(tab$OLD_ERROR),
            sum(tab$BOTH_ERROR), sum(tab$FAIL)),
    "",
    "Status: E0 = values and `.Random.seed` identical; ALLOWED = enumerated intentional",
    "difference; OLD-ERROR = archived code errors, new code returns (enumerated fix).",
    "",
    md_table(tab),
    "",
    "## Non-E0 cases",
    "",
    failure_details(runs)
  )
  writeLines(lines, file)
  invisible(tab)
}
