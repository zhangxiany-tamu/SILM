# Assemble replication/REPORT.md from replication/results/*.rds.
#
# Targets whose name carries a tag in brackets ("[draw-dependent]",
# "[expected failure]", "[informational]", "[code check]") are reported
# separately and are not part of the headline count (see CRITERIA.md).
source(file.path("replication", "common.R"))

files <- sort(list.files(file.path("replication", "results"), pattern = "\\.rds$", full.names = TRUE))
if (!length(files)) stop("no results in replication/results")
res <- lapply(files, readRDS)
crit <- do.call(rbind, lapply(res, function(r) r$cells$criteria))
crit$tag <- ifelse(grepl("\\[[^]]+\\]\\s*$", crit$target),
                   sub(".*\\[([^]]+)\\]\\s*$", "\\1", crit$target), "")

fmt <- function(x) {
  if (!is.numeric(x)) return(as.character(x))
  ifelse(is.na(x), "", formatC(x, digits = 3, format = "g"))
}
verdict <- function(p) ifelse(is.na(p), "n/a", ifelse(p, "yes", "**no**"))
esc <- function(x) gsub("|", "\\|", x, fixed = TRUE)

count_line <- function(sub) {
  sprintf("%d of %d passed", sum(sub$pass, na.rm = TRUE), sum(!is.na(sub$pass)))
}

target_section <- function(tg) {
  sub <- crit[crit$target == tg, ]
  c(sprintf("### %s (%s)", tg, count_line(sub)), "",
    "| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |",
    "|---|---|---|---|---|---|---|---|",
    sprintf("| %s | %s | %s | %s | %s | %s | %s | %s |", esc(sub$cell), esc(sub$metric),
            fmt(sub$paper), fmt(sub$ours), fmt(sub$se), fmt(sub$tol), verdict(sub$pass),
            esc(sub$note)), "")
}

head_rows <- crit[crit$tag == "", ]
lines <- c(
  "# Replication report", "",
  "Pre-registered criteria: `replication/CRITERIA.md` (committed before these results).",
  "Each target was run with the SILM version, glmnet version and replication scale below.", "",
  "| Target | Commit | SILM | glmnet | Scale | Date |", "|---|---|---|---|---|---|",
  vapply(res, function(r) sprintf("| %s | %s | %s | %s | %s | %s |", r$id, r$meta$commit,
                                  r$meta$silm, r$meta$glmnet, r$meta$scale, r$meta$date), ""),
  "",
  sprintf("**Headline criteria: %s.**", count_line(head_rows)), "",
  "| Group | Criteria | Passed |", "|---|---|---|",
  vapply(split(crit, factor(crit$tag, levels = unique(c("", crit$tag)))), function(s) {
    sprintf("| %s | %d | %d |", if (s$tag[1] == "") "headline" else s$tag[1],
            sum(!is.na(s$pass)), sum(s$pass, na.rm = TRUE))
  }, ""),
  "", "## Headline targets", ""
)
for (tg in unique(head_rows$target)) lines <- c(lines, target_section(tg))
tagged <- unique(crit$target[crit$tag != ""])
if (length(tagged)) {
  lines <- c(lines, "## Tagged targets (not in the headline count)", "",
             "See CRITERIA.md for the meaning of each tag.", "")
  for (tg in tagged) lines <- c(lines, target_section(tg))
}
writeLines(lines, file.path("replication", "REPORT.md"))
cat(sprintf("Headline: %s\n", count_line(head_rows)))
