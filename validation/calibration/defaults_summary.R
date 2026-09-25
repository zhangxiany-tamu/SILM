# Combine the shards of defaults.R and apply the pre-registered decision rule
# of DEFAULTS.md.
#   Rscript validation/calibration/defaults_summary.R SHARD_DIR [OUT_DIR]

LEVEL <- 0.95
ALPHA <- 0.05
MARGIN_SCORE <- 0.005   # DEFAULTS.md, rule 1
MARGIN_POWER <- 0.01    # rule 2
POWER_GUARD <- 0.05     # rule 3
N_BOOT <- 2000L

# ---- read and check -------------------------------------------------------------

read_shards <- function(dir) {
  files <- sort(list.files(dir, "^shard-[0-9]+\\.rds$", full.names = TRUE, recursive = TRUE))
  if (!length(files)) stop("no shard files in ", dir)
  shards <- lapply(files, readRDS)
  info <- attr(shards[[1]], "info")
  if (!info$smoke && length(files) != info$nshards) {
    stop("found ", length(files), " of ", info$nshards, " shards")
  }
  infos <- lapply(shards, attr, "info")
  versions <- unique(lapply(infos, `[[`, "versions"))
  if (length(versions) != 1L) stop("the shards ran with different package versions")
  md5 <- unique(lapply(infos, `[[`, "setup_md5"))
  if (length(md5) != 1L) stop("the shards used different setup files")
  failures <- unlist(lapply(infos, `[[`, "failures"))
  results <- Filter(function(x) is.list(x) && is.null(x$error) && !is.null(x$values),
                    do.call(c, lapply(shards, unclass)))
  list(results = results, info = info, failures = failures,
       elapsed = vapply(infos, `[[`, numeric(1), "elapsed"),
       cpu = vapply(infos, function(i) i$cpu %||% NA_real_, numeric(1)))
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# data[[cell]][[variant]]: a matrix with one row per replication (ordered by r).
tabulate_results <- function(results, info) {
  cells <- unique(vapply(results, `[[`, "", "cell"))
  data <- lapply(stats::setNames(cells, cells), function(cell) {
    res <- Filter(function(x) x$cell == cell, results)
    r <- vapply(res, `[[`, numeric(1), "r")
    expected <- if (info$smoke) 1 else seq_len(info$cells[[cell]]$R)
    if (!identical(as.numeric(sort(r)), as.numeric(expected))) {
      stop("cell ", cell, ": replications missing or duplicated")
    }
    res <- res[order(r)]
    variants <- names(res[[1]]$values)
    lapply(stats::setNames(variants, variants), function(v) {
      do.call(rbind, lapply(res, function(x) x$values[[v]]))
    })
  })
  data
}

# ---- comparisons (DEFAULTS.md) -------------------------------------------------------

# A comparison: for each cell kind, pairs of variants (current, candidate) and
# the metrics that enter the calibration score and the power score.
COMPARISONS <- list(
  nodewise = list(
    current = "cv", candidate = "ZnZ",
    pairs = list(zc = list(c("cv", "ZnZ")), sr = list(c("cv", "ZnZ")), st = list(c("cv", "ZnZ"))),
    coverage = list(zc = c("cov_nst_S0", "cov_st_S0", "cov_nst_S0c", "cov_st_S0c",
                           "cov_nst_all", "cov_st_all")),
    error = list(zc = c("fwer_step_nst", "fwer_step_st"), st = c("size_st_nst", "size_st_st")),
    power = list(zc = c("power_step_nst", "power_step_st"),
                 sr = c("sr_exact", "sr_no_fp", "sr_tpr"),
                 st = c("power_st_nst", "power_st_st"))),
  robust.divisor = list(
    current = "n", candidate = "n-s",
    pairs = list(dbz = list(c("boot/shortcut/n", "boot/shortcut/n-s"),
                            c("boot/full/n", "boot/full/n-s"),
                            c("asym/cv/n", "asym/cv/n-s"))),
    coverage = list(dbz = c("ind_cov", "ind_cov_S0", "joint_maxmin")),
    error = list(dbz = c("fwer_wy", "fwer_holm")),
    power = list(dbz = c("power_wy", "power_holm"))),
  do.ZnZ = list(   # informational (DEFAULTS.md): lasso.proj's Z
    current = "cv Z", candidate = "ZnZ Z", informational = TRUE,
    pairs = list(dbz = list(c("asym/cv/n", "asym/ZnZ/n"), c("asym/cv/n-s", "asym/ZnZ/n-s"))),
    coverage = list(dbz = c("ind_cov", "ind_cov_S0")),
    error = list(dbz = "fwer_holm"),
    power = list(dbz = "power_holm"))
)

cell_kind <- function(cell) sub("_.*", "", cell)

# The units of a comparison: (cell, current variant, candidate variant, metric,
# type) for every metric that both variants report with a non-missing value.
comparison_units <- function(cmp, data) {
  units <- list()
  for (cell in names(data)) {
    kind <- cell_kind(cell)
    for (pair in cmp$pairs[[kind]]) {
      if (!all(pair %in% names(data[[cell]]))) next
      for (type in c("coverage", "error", "power")) {
        for (metric in cmp[[type]][[kind]]) {
          a <- data[[cell]][[pair[1]]]
          if (!metric %in% colnames(a) || all(is.na(a[, metric]))) next
          units[[length(units) + 1L]] <- data.frame(cell = cell, current = pair[1],
                                                    candidate = pair[2], metric = metric,
                                                    type = type, stringsAsFactors = FALSE)
        }
      }
    }
  }
  do.call(rbind, units)
}

shortfall <- function(value, type) {
  ifelse(type == "coverage", pmax(0, LEVEL - value), pmax(0, value - ALPHA))
}

# Means of each unit for replication indices `idx[[cell]]`.
unit_means <- function(units, data, idx, which) {
  vapply(seq_len(nrow(units)), function(u) {
    m <- data[[units$cell[u]]][[units[[which]][u]]]
    mean(m[idx[[units$cell[u]]], units$metric[u]])
  }, numeric(1))
}

scores <- function(units, data, idx) {
  cur <- unit_means(units, data, idx, "current")
  cand <- unit_means(units, data, idx, "candidate")
  cal <- units$type != "power"
  pw <- units$type == "power"
  c(score_current = mean(shortfall(cur[cal], units$type[cal])),
    score_candidate = mean(shortfall(cand[cal], units$type[cal])),
    power_current = if (any(pw)) mean(cur[pw]) else NA,
    power_candidate = if (any(pw)) mean(cand[pw]) else NA)
}

# Rules 1-3 of DEFAULTS.md. `ci` is the bootstrap interval of the calibration
# score difference (candidate - current).
decide <- function(s, ci) {
  d_score <- s[["score_candidate"]] - s[["score_current"]]
  d_power <- s[["power_candidate"]] - s[["power_current"]]
  calibration <- if (d_score < -MARGIN_SCORE && ci[2] < 0) {
    "candidate"
  } else if (d_score > MARGIN_SCORE && ci[1] > 0) {
    "current"
  } else {
    NA_character_
  }
  better <- if (!is.na(calibration)) {
    calibration
  } else if (!is.na(d_power) && d_power > MARGIN_POWER) {
    "candidate"
  } else {
    "current"
  }
  lost <- if (better == "candidate") -d_power else d_power
  if (!is.na(calibration) && !is.na(lost) && lost > POWER_GUARD) better <- "ask the user"
  better
}

# Report only (not part of the decision): the mean shortfall difference and
# power difference by cell kind and metric, to show where a decision comes from.
strata_table <- function(units, data, idx) {
  cur <- unit_means(units, data, idx, "current")
  cand <- unit_means(units, data, idx, "candidate")
  diff <- ifelse(units$type == "power", cand - cur,
                 shortfall(cand, units$type) - shortfall(cur, units$type))
  key <- paste(cell_kind(units$cell), units$current, units$type, sep = " | ")
  agg <- stats::aggregate(diff, list(stratum = key), function(v) c(n = length(v), mean = mean(v)))
  data.frame(stratum = agg$stratum, units = agg$x[, "n"], mean_difference = agg$x[, "mean"])
}

compare <- function(cmp, data, seed = 1L) {
  units <- comparison_units(cmp, data)
  full <- lapply(data, function(cell) seq_len(nrow(cell[[1]])))
  point <- scores(units, data, full)
  set.seed(seed)
  boot <- replicate(N_BOOT, {
    idx <- lapply(full, function(i) sample(i, replace = TRUE))
    s <- scores(units, data, idx)
    c(d_score = s[["score_candidate"]] - s[["score_current"]],
      d_power = s[["power_candidate"]] - s[["power_current"]])
  })
  ci <- apply(boot, 1, stats::quantile, c(0.025, 0.975), na.rm = TRUE)
  list(units = units, point = point, decision = decide(point, ci[, "d_score"]), ci = ci,
       strata = strata_table(units, data, full))
}

# ---- report ----------------------------------------------------------------------------

fmt_mean <- function(m, metric) {
  v <- m[, metric]
  if (all(is.na(v))) return("-")
  sprintf("%.3f", mean(v))
}

cell_table <- function(data, cells, variants, metrics) {
  head <- c(paste("| cell | variant |", paste(metrics, collapse = " | "), "|"),
            paste0("|---|---|", strrep("---|", length(metrics))))
  rows <- character()
  for (cell in cells) {
    for (v in intersect(variants, names(data[[cell]]))) {
      vals <- vapply(metrics, function(k) {
        if (k %in% colnames(data[[cell]][[v]])) fmt_mean(data[[cell]][[v]], k) else "-"
      }, "")
      rows <- c(rows, paste("|", cell, "|", v, "|", paste(vals, collapse = " | "), "|"))
    }
  }
  c(head, rows)
}

comparison_lines <- function(name, cmp, res) {
  p <- res$point
  head <- sprintf(paste0("* **%s** (%s vs %s; %d units): calibration shortfall %.4f vs %.4f ",
                         "(difference %.4f, 95%% bootstrap interval [%.4f, %.4f]); mean power %.3f vs %.3f ",
                         "(difference %.3f, [%.3f, %.3f]). **Decision: %s.**"),
                  name, cmp$current, cmp$candidate, nrow(res$units), p[["score_current"]],
                  p[["score_candidate"]], p[["score_candidate"]] - p[["score_current"]],
                  res$ci[1, "d_score"], res$ci[2, "d_score"], p[["power_current"]],
                  p[["power_candidate"]], p[["power_candidate"]] - p[["power_current"]],
                  res$ci[1, "d_power"], res$ci[2, "d_power"],
                  paste0(switch(res$decision, candidate = paste("use", sQuote(cmp$candidate, FALSE)),
                                current = paste("keep", sQuote(cmp$current, FALSE)), res$decision),
                         if (isTRUE(cmp$informational)) " (informational only; no default is changed)" else ""))
  strata <- sprintf("  * %s: %d units, mean difference (candidate - current; shortfall for calibration, level for power) %.4f",
                    res$strata$stratum, res$strata$units, res$strata$mean_difference)
  c(head, strata)
}

# Mean of log(width candidate / width current) per cell (report only).
width_ratios <- function(data, pairs, metric) {
  rows <- character()
  for (cell in names(data)) {
    for (pair in pairs) {
      if (!all(pair %in% names(data[[cell]])) || !metric %in% colnames(data[[cell]][[pair[1]]])) next
      r <- mean(log(data[[cell]][[pair[2]]][, metric] / data[[cell]][[pair[1]]][, metric]))
      rows <- c(rows, sprintf("| %s | %s vs %s | %.3f |", cell, pair[1], pair[2], exp(r)))
    }
  }
  c("| cell | variants | geometric mean width ratio |", "|---|---|---|", rows)
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  out_dir <- if (length(args) > 1) args[2] else "validation/calibration/defaults-results"
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  sh <- read_shards(args[1])
  if (length(sh$failures)) {
    message(length(sh$failures), " replication(s) failed; the study is incomplete:\n",
            paste(utils::head(sh$failures, 20), collapse = "\n"))
  }
  data <- tabulate_results(sh$results, sh$info)
  saveRDS(structure(data, info = sh$info), file.path(out_dir, "raw.rds"))
  res <- lapply(COMPARISONS, compare, data = data)
  cells <- names(data)
  zc <- grep("^zc", cells, value = TRUE)
  sr <- grep("^sr", cells, value = TRUE)
  st <- grep("^st", cells, value = TRUE)
  dbz <- grep("^dbz", cells, value = TRUE)
  report <- c(
    "# Defaults study: results (generated by defaults_summary.R)", "",
    sprintf("SILM %s; %s; M = %d, B = %d; replications per cell: %s; %d shards, %.1f CPU-hours.%s",
            sh$info$versions[["SILM"]], paste(names(sh$info$versions), sh$info$versions, collapse = ", "),
            sh$info$M, sh$info$B, paste(names(sh$info$R), sh$info$R, sep = " = ", collapse = ", "),
            length(sh$elapsed), sum(sh$cpu, na.rm = TRUE) / 3600,
            if (sh$info$smoke) " SMOKE TEST: NOT A RESULT." else ""),
    if (length(sh$failures)) c("", "**Failed replications:**", paste("*", sh$failures)),
    "", "## Decisions (rules of DEFAULTS.md)", "",
    unlist(Map(comparison_lines, names(COMPARISONS), COMPARISONS, res)),
    "", "## Sim.CI and Step (nodewise)", "",
    cell_table(data, zc, c("cv", "ZnZ"),
               c("cov_nst_S0", "cov_st_S0", "cov_nst_S0c", "cov_st_S0c", "cov_nst_all",
                 "cov_st_all", "fwer_step_nst", "fwer_step_st", "power_step_nst", "power_step_st")),
    "", "Interval widths (ZnZ relative to cv):", "",
    width_ratios(data[zc], list(c("cv", "ZnZ")), "width_nst_all"),
    "", "## SR (nodewise)", "",
    cell_table(data, sr, c("cv", "ZnZ"), c("sr_exact", "sr_no_fp", "sr_tpr", "sr_fp", "sr_fn")),
    "", "## ST (nodewise)", "",
    cell_table(data, st, c("cv", "ZnZ"), c("size_st_nst", "size_st_st", "power_st_nst", "power_st_st")),
    "", "## boot.lasso.proj and lasso.proj (robust standard errors)", "",
    cell_table(data, dbz, c("boot/shortcut/n", "boot/shortcut/n-s", "boot/full/n", "boot/full/n-s"),
               c("ind_cov", "ind_cov_S0", "joint_maxmin", "fwer_wy", "power_wy", "width")),
    "", cell_table(data, dbz, c("asym/cv/n", "asym/cv/n-s", "asym/ZnZ/n", "asym/ZnZ/n-s"),
                   c("ind_cov", "ind_cov_S0", "fwer_holm", "power_holm", "width", "s_hat")),
    "", "Interval widths (candidate relative to current):", "",
    width_ratios(data[dbz], c(COMPARISONS$robust.divisor$pairs$dbz, COMPARISONS$do.ZnZ$pairs$dbz), "width"))
  writeLines(report, file.path(out_dir, "REPORT.md"))
  saveRDS(res, file.path(out_dir, "decisions.rds"))
  writeLines(sh$info$session, file.path(out_dir, "session.txt"))
  cat(report, sep = "\n")
}

main()
