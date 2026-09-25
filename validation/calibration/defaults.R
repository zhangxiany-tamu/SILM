# Defaults study (pre-registered in DEFAULTS.md): nodewise = "cv" vs "ZnZ"
# for SR/ST/Sim.CI/Step, and robust.divisor = "n" vs "n-s" for
# lasso.proj/boot.lasso.proj, on the papers' simulation designs.
#
# Usage (see .github/workflows/defaults-study.yml):
#   OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 Rscript validation/calibration/defaults.R \
#     --setup --cores 4 --out DIR          # designs, Theta and Z -> DIR/setup.rds
#   ... --shard k --nshards K --cores 4 --setup-file DIR/setup.rds --out DIR2
#   ... --smoke                             # 1 replication per cell, locally
#
# Replication r of every cell goes to shard ((r - 1) mod K) + 1, so each shard
# gets the same mix of cheap and expensive cells.

suppressPackageStartupMessages(library(SILM))
local({
  here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
  source(file.path(here, "defaults_designs.R"))
  source(file.path(here, "defaults_cells.R"))
})

R_COUNTS <- c(zc = 200L, sr = 200L, st = 200L, dbz = 100L)

parse_args <- function(args) {
  opt <- list(setup = FALSE, smoke = FALSE, shard = 1L, nshards = 1L, cores = 1L,
              out = "defaults-out", setup_file = NULL)
  i <- 1L
  while (i <= length(args)) {
    key <- gsub("-", "_", sub("^--", "", args[i]))
    if (key %in% c("setup", "smoke")) {
      opt[[key]] <- TRUE
    } else if (key %in% names(opt)) {
      val <- args[i + 1L]
      opt[[key]] <- if (key %in% c("out", "setup_file")) val else as.integer(val)
      i <- i + 1L
    } else {
      stop("unknown argument: ", args[i])
    }
    i <- i + 1L
  }
  opt
}

# All cells, with their kind, replication count and seed base.
all_cells <- function() {
  zc <- lapply(seq_len(nrow(ZC_CELLS)), function(i) {
    c(as.list(ZC_CELLS[i, ]), kind = "zc", R = R_COUNTS[["zc"]])
  })
  sr <- lapply(seq_len(nrow(SR_CELLS)), function(i) {
    c(as.list(SR_CELLS[i, ]), kind = "sr", R = R_COUNTS[["sr"]])
  })
  st <- lapply(seq_len(nrow(ST_CELLS)), function(i) {
    c(as.list(ST_CELLS[i, ]), kind = "st", R = R_COUNTS[["st"]])
  })
  dbz <- lapply(names(DBZ_CELLS), function(nm) {
    list(design = nm, name = paste("dbz", nm, sep = "_"), kind = "dbz", R = R_COUNTS[["dbz"]])
  })
  cells <- c(zc, sr, st, dbz)
  for (k in seq_along(cells)) cells[[k]]$seed_base <- 1e7 * k
  stats::setNames(cells, vapply(cells, `[[`, "", "name"))
}

rep_fun <- list(zc = zc_rep, sr = sr_rep, st = st_rep, dbz = dbz_rep)

# The (cell, replication) tasks of one shard, the most expensive first.
shard_tasks <- function(cells, shard, nshards, smoke) {
  tasks <- list()
  for (cell in cells) {
    reps <- if (smoke) 1L else seq_len(cell$R)[(seq_len(cell$R) - 1L) %% nshards == shard - 1L]
    for (r in reps) tasks[[length(tasks) + 1L]] <- list(cell = cell$name, r = r)
  }
  cost <- c(dbz = 3, st = 2, zc = 1, sr = 0)[vapply(tasks, function(t) cells[[t$cell]]$kind, "")]
  tasks[order(-cost)]
}

# Runs the tasks; failed tasks are returned with their error message (the
# shard file is written before the job fails, so nothing else is lost).
run_tasks <- function(tasks, cells, setup, cores) {
  parallel::mclapply(tasks, function(t) {
    cell <- cells[[t$cell]]
    tryCatch(list(cell = t$cell, r = t$r, values = rep_fun[[cell$kind]](t$r, cell, setup)),
             error = function(e) list(cell = t$cell, r = t$r, error = conditionMessage(e)))
  }, mc.cores = cores, mc.preschedule = FALSE, mc.set.seed = FALSE)
}

task_failures <- function(res) {
  ok <- vapply(res, function(x) is.list(x) && is.null(x$error) && !is.null(x$values), logical(1))
  vapply(res[!ok], function(x) {
    if (!is.list(x)) paste("worker error:", paste(as.character(x), collapse = " "))
    else paste0(x$cell, " r=", x$r, ": ", x$error %||% "no result")
  }, "")
}

`%||%` <- function(a, b) if (is.null(a)) b else a

cpu_seconds <- function() {
  t <- proc.time()
  sum(t[c("user.self", "sys.self", "user.child", "sys.child")], na.rm = TRUE)
}

main <- function() {
  opt <- parse_args(commandArgs(trailingOnly = TRUE))
  dir.create(opt$out, recursive = TRUE, showWarnings = FALSE)
  t0 <- proc.time()[["elapsed"]]
  if (opt$setup) {
    saveRDS(study_setup(opt$cores), file.path(opt$out, "setup.rds"))
    message(sprintf("setup done after %.0f s", proc.time()[["elapsed"]] - t0))
    return(invisible())
  }
  if (opt$smoke) {
    # Fewer draws: the smoke test checks that every cell runs, nothing else.
    M_ZC <<- 100L
    B_DBZ <<- 49L
  }
  setup <- if (is.null(opt$setup_file)) study_setup(opt$cores) else readRDS(opt$setup_file)
  if (!identical(setup$versions, package_versions())) {
    stop("package versions differ from the setup job: ",
         paste(names(setup$versions), setup$versions, "vs", package_versions(), collapse = "; "))
  }
  cells <- all_cells()
  tasks <- shard_tasks(cells, opt$shard, opt$nshards, opt$smoke)
  message(sprintf("shard %d/%d: %d tasks", opt$shard, opt$nshards, length(tasks)))
  res <- run_tasks(tasks, cells, setup, opt$cores)
  failures <- task_failures(res)
  info <- list(shard = opt$shard, nshards = opt$nshards, smoke = opt$smoke, R = R_COUNTS,
               M = M_ZC, B = B_DBZ, versions = package_versions(), cores = opt$cores,
               setup_md5 = if (!is.null(opt$setup_file)) unname(tools::md5sum(opt$setup_file)),
               cells = lapply(cells, function(x) x[setdiff(names(x), "name")]),
               failures = failures, elapsed = proc.time()[["elapsed"]] - t0,
               cpu = cpu_seconds(), session = utils::capture.output(sessionInfo()))
  saveRDS(structure(res, info = info), file.path(opt$out, sprintf("shard-%02d.rds", opt$shard)))
  message(sprintf("shard %d done after %.0f s", opt$shard, info$elapsed))
  if (length(failures)) {
    message(length(failures), " task(s) failed:\n", paste(utils::head(failures, 20), collapse = "\n"))
    quit(status = 1)
  }
}

main()
