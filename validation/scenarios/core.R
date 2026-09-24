# Group B: SILM core functions (SR, Sim.CI, Step, ST) against SILM 1.0.0.
#
# The old side runs SILM 1.0.0 with hdi 0.1-10 ("znz") or hdi 0.1-6 ("cv").
# The new side passes `new_args` (e.g. nodewise = "cv") unless running the
# harness self-test, where the repository code still uses the archived deps.

core_cells <- function(tier) {
  cells <- list(
    B1 = list(n = 100, p = 10, design = "toeplitz", s0 = 3, beta = "U(0,2)", error = "t4"),
    B2 = list(n = 100, p = 50, design = "iid", s0 = 3, beta = "U(0,2)", error = "gamma"),
    B3 = list(n = 100, p = 51, design = "toeplitz", s0 = 3, beta = "U(0,2)", error = "t4"),
    B4 = list(n = 60, p = 120, design = "toeplitz", s0 = 3, beta = "U(1,2)", error = "t4"),
    B5 = list(n = 100, p = 200, design = "exch", rho = 0.8, s0 = 0, error = "gauss"),
    B6 = list(n = 100, p = 10, design = "iid", s0 = 10, beta = 4, error = "gauss"),
    B7 = list(n = 100, p = 51, design = "toeplitz", s0 = 3, beta = "U(0,2)", error = "t4",
              y_matrix = TRUE, names = TRUE)
  )
  if (tier == "full") {
    cells$B8 <- list(n = 100, p = 500, design = "toeplitz", s0 = 3, beta = "U(0,2)", error = "t4")
  }
  cells
}

core_seeds <- function(tier) if (tier == "full") 1:10 else 1:2

core_cases <- function(tier, calls) {
  cells <- core_cells(tier)
  cases <- list()
  k <- 0L
  for (id in names(cells)) {
    cell <- cells[[id]]
    k <- k + 1L
    set.seed(1000L + k)
    d <- do.call(sim_linear, c(cell[setdiff(names(cell), "rho")],
                               if (!is.null(cell$rho)) list(rho = cell$rho)))
    for (cl in calls(cell)) {
      for (s in core_seeds(tier)) {
        cases[[length(cases) + 1L]] <- list(
          data = d, args = cl, seed = s, rng = "default",
          label = paste0(id, ",", cl$label, ",seed=", s)
        )
      }
    }
  }
  cases
}

sr_calls <- function(cell) list(list(label = "SR"))

simci_calls <- function(cell) {
  p <- cell$p
  s0 <- max(cell$s0, 1)
  sets <- list(seq_len(min(3, p)), if (p > s0) (s0 + 1):p else seq_len(p), seq_len(p), 2L)
  out <- list()
  for (st in sets) for (a in c(0.95, 0.99)) {
    out[[length(out) + 1L]] <- list(label = sprintf("set=%d..%d(%d),alpha=%s", min(st), max(st),
                                                    length(st), a),
                                    set = st, M = 100, alpha = a)
  }
  out
}

step_calls <- function(cell) {
  lapply(c(0.05, 0.10), function(a) list(label = paste0("alpha=", a), M = 100, alpha = a))
}

st_calls <- function(cell) {
  n <- cell$n
  p <- cell$p
  s0 <- max(cell$s0, 1)
  out <- list()
  for (frac in c(0.2, 0.3)) for (ts in list((s0 + 1):p, min(3, p):p)) {
    out[[length(out) + 1L]] <- list(label = sprintf("sub=%s,test=%d..%d", frac * n, min(ts), max(ts)),
                                    sub.size = frac * n, test.set = ts, M = 100)
  }
  out
}

# Functions executed in the child processes (namespace-qualified only).
old_SR <- function(d, a) SILM::SR(d$X, d$Y)
new_SR <- function(d, a) do.call(SILM::SR, c(list(d$X, d$Y), a$new_args))
old_SimCI <- function(d, a) SILM::Sim.CI(d$X, d$Y, a$set, M = a$M, alpha = a$alpha)
new_SimCI <- function(d, a) do.call(SILM::Sim.CI, c(list(d$X, d$Y, a$set, M = a$M, alpha = a$alpha),
                                                    a$new_args))
old_Step <- function(d, a) SILM::Step(d$X, d$Y, M = a$M, alpha = a$alpha)
new_Step <- function(d, a) do.call(SILM::Step, c(list(d$X, d$Y, M = a$M, alpha = a$alpha), a$new_args))
old_ST <- function(d, a) SILM::ST(d$X, d$Y, a$sub.size, a$test.set, M = a$M)
new_ST <- function(d, a) do.call(SILM::ST, c(list(d$X, d$Y, a$sub.size, a$test.set, M = a$M),
                                             a$new_args))

with_new_args <- function(cases, new_args) {
  lapply(cases, function(cs) {
    cs$args$new_args <- new_args
    cs
  })
}

core_scenarios <- function(tier, modes = c("znz", "cv"), self_test = FALSE, st_legacy = TRUE) {
  specs <- list(
    SR = list(calls = sr_calls, old = old_SR, new = new_SR),
    SimCI = list(calls = simci_calls, old = old_SimCI, new = new_SimCI),
    Step = list(calls = step_calls, old = old_Step, new = new_Step),
    ST = list(calls = st_calls, old = old_ST, new = new_ST)
  )
  out <- list()
  for (fn in names(specs)) {
    base_cases <- core_cases(tier, specs[[fn]]$calls)
    for (mode in modes) {
      new_args <- if (self_test) NULL else list(nodewise = if (mode == "znz") "ZnZ" else "cv")
      if (fn == "ST" && !self_test && st_legacy) new_args$legacy <- TRUE
      out[[length(out) + 1L]] <- list(
        id = sprintf("B-%s-%s", fn, mode), legacy_mode = mode,
        cases = with_new_args(base_cases, new_args),
        old_fun = specs[[fn]]$old, new_fun = specs[[fn]]$new,
        both_error_ok = TRUE
      )
    }
  }
  out
}
