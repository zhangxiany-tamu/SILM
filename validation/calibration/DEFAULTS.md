# Defaults study: pre-registration

This file was committed **before** the study was run; the git history shows
the order. The results go to `defaults-results/REPORT.md`. Before the run,
the design, code and rule were reviewed by three independent reviewers
(statistics, code, execution); their confirmed findings are reflected here.

## Why

The first calibration study (`run.R`, `results/`), prompted by an external
audit, suggested that two defaults of SILM 2.0.0 may not be the better choice:

* `nodewise = "cv"` (SR, ST, Sim.CI, Step, Theta.hat): in a Toeplitz(0.9)
  design with signals (1.5, -1, 2), the joint coverage of `Sim.CI()` was about
  0.72 with `"cv"` and 0.87 with `"ZnZ"` (interim, 131 replications).
* `robust.divisor = "n"` (lasso.proj, boot.lasso.proj with `robust = TRUE`):
  the n - s divisor of equation (5) of Dezeure, Bühlmann and Zhang (2017)
  reduced the Westfall-Young FWER from 0.09-0.18 to about 0.08 in a
  Toeplitz(0.5) design, with the same power.

The package author decided on 2026-09-24 that **each default should be the
option with the better empirical performance**. One stress design is not
enough to establish that, so this study compares the options on the papers'
own simulation designs as well, and fixes the decision rule in advance.

## Comparisons

| Comparison | Current default | Candidate | Functions |
|---|---|---|---|
| A: `nodewise` | `"cv"` | `"ZnZ"` | `SR()`, `ST()`, `Sim.CI()`, `Step()`, `Theta.hat()` |
| B: `robust.divisor` | `"n"` | `"n-s"` | `lasso.proj()`, `boot.lasso.proj()` |
| C (informational): `do.ZnZ` | `FALSE` | `TRUE` | `lasso.proj()` (asymptotic only) |

Comparison C is reported but does not change a default by itself; its result
will be put to the package author.

## Designs (`defaults_designs.R`)

All designs, coefficient vectors, Theta and Z are fixed by seeds; only the
errors are redrawn. Every variant of a replication uses the same errors and
the same multiplier or bootstrap draws (paired comparison).

**A (Zhang and Cheng, 2017, Section 5):** n = 100; X ~ N(0, Σ) with Σ
Toeplitz 0.9 or exchangeable 0.8; p = 120 or 500; t(4)/√2 errors.

* `Sim.CI()` (95%, G = S0, S0^c and [p]) and `Step()` (α = 0.05), Tables 1,
  2 and 5: s0 = 3 or 15 with β_j ~ Unif[0, 2] on {1, ..., s0} (the paper), and
  the same magnitudes with alternating signs; plus the audit's stress vectors
  (1.5, -1, 2) and (1.5, 1, 2) at p = 120 (the audit's design) and p = 500
  (Toeplitz). 20 cells, 200 replications each, M = 500 (SILM's default).
* `SR()` (Section 5.2): s0 = 3 or 15 coefficients Unif[2, 4] on a random
  support drawn once per (design, s0). 8 cells, 200 replications.
* `ST()` (Table 4): p = 500; β_j = sqrt(10 log p / n) on {1, ..., s0} with
  Toeplitz 0.9 and splitting proportion 1/5 (case i; s0 = 3 and 15), or
  10 sqrt(log p / n) with exchangeable 0.8 and proportion 1/3 (case ii;
  s0 = 3); test sets {s0 + 1, ..., p} (size) and {s0, ..., p} (power).
  3 cells, 200 replications.

**B and C (Dezeure, Bühlmann and Zhang, 2017, Section 5.1):** robust standard
errors throughout (the divisor only acts there); B = 499.

* n = 100, p = 500, Toeplitz 0.9, s0 = 3 at random positions, coefficients
  U(-2, 2), U(0, 2) or all 1; Gaussian errors; residual bootstrap.
* The same with s0 = 15 (U(-2, 2)), and an exchangeable 0.8 design (U(-2, 2)).
* The heteroscedastic example of Section 5.1.3 (n = 50, p = 250, no signal),
  wild bootstrap.
* The audit's Toeplitz 0.5 design (n = 100, p = 120, β = (1.5, -1, 2)) with
  error standard deviation proportional to 0.5 + |X_1|, wild bootstrap.
* 7 cells, 100 replications each (the paper's count). `boot.lasso.proj()`
  with `boot.shortcut = TRUE` in every cell, and with the default full refit
  in the first Toeplitz cell and the heteroscedastic example;
  `lasso.proj()` with Z from the nodewise lasso with and without the Z&Z rule.

## Metrics

* Calibration, coverage type (target 0.95): A: joint coverage of the NST and
  ST intervals for G = S0, S0^c, [p]. B, C: individual coverage averaged over
  all coefficients and over S0, joint coverage of the simultaneous intervals
  (eq. 10, `boot.lasso.proj()` only).
* Calibration, error type (target 0.05): A: FWER of `Step()` (NST, ST), size
  of `ST()` (NST, ST). B, C: FWER of the Westfall-Young (bootstrap) or Holm
  (`lasso.proj()`) adjusted p-values.
* Power (higher is better): A: average power of `Step()` (NST, ST), power of
  `ST()` (NST, ST), and for `SR()` the probabilities of exact recovery and of
  no false positive, and the true positive rate. B, C: average power of the
  adjusted p-values at level 0.05.
* Reported, not scored: interval widths (and their ratios between the
  variants), the size s_hat of the lasso support, false positive and false
  negative counts of `SR()`.

Metrics that are undefined in a cell (S0 empty) are left out for both
variants.

## Decision rule (`defaults_summary.R`)

For each comparison, a *unit* is a (cell, variant pair, metric). For a
calibration unit with Monte Carlo mean v, the shortfall is max(0, 0.95 - v)
(coverage) or max(0, v - 0.05) (error rate). The calibration score of a
variant is the mean shortfall over all calibration units; its power score is
the mean over all power units.

1. If the candidate's calibration score is lower than the current default's
   by more than 0.005 **and** the 95% bootstrap interval of the difference
   lies below 0, the candidate is better; if it is higher by more than 0.005
   and the interval lies above 0, the current default is better.
2. Otherwise (a tie on calibration), the candidate is better if its power
   score is higher by more than 0.01; if not, the current default stays.
3. Exception: if the option that is better on calibration loses more than
   0.05 in power score, no default is changed automatically; the trade-off
   is put to the package author.

95% intervals for the score differences come from 2000 bootstrap resamples
of the replications within each cell (paired: the same replications for both
variants). The report also breaks the differences down by kind of cell and
metric, to show where a decision comes from; this breakdown does not enter
the decision.

**Completeness.** The analysis needs every replication. A replication that
fails is listed in the report, the cause is investigated, and the study is
rerun after a fix; no decision is taken from incomplete data. All jobs must
run with the same package versions (checked).

**Known limitations** (stated in advance): the calibration score is
one-sided, so an option is not penalised for over-coverage except through
power; power in the robust.divisor cells is close to 1, so the power guard is
not sensitive there; widths are reported for this reason. Each cell uses one
fixed design.

## What will be done with the result

* A decides the default of `nodewise` for all five functions together.
* B decides the default of `robust.divisor` for both functions.
* If a default changes, the previous behaviour stays available through the
  argument, the equivalence harness passes the old value explicitly, and
  NEWS, README and the help pages say so.
* The report is committed whatever the outcome.
