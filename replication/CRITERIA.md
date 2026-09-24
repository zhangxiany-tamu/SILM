# Replication of the simulation studies: pre-registered criteria

This document fixes, **before the full replication runs**, how SILM's results
are compared with the published results of

1. Zhang, X. and Cheng, G. (2017). Simultaneous inference for high-dimensional
   linear models. *JASA* 112, 757–768 (Section 5, Tables 1–5); and
2. Dezeure, R., Bühlmann, P. and Zhang, C.-H. (2017). High-dimensional
   simultaneous inference with the bootstrap. *TEST* 26, 685–719 (Section 5,
   Figures 4–15 and the table on p. 713), plus hdi's own regression-test values.

The scripts, settings and extracted numbers were written by one agent per
paper, reviewed adversarially against the paper by a second agent, and revised.
What was seen before the rules were fixed (exploratory runs and the reviewers'
pilots) is disclosed in each part below. The git history shows that this file
was committed before `replication/results/` and `REPORT.md`.

Run everything with

```sh
Rscript replication/run.R --install replication/zc_*.R replication/dbz_*.R
Rscript replication/make_report.R
```

(`run.R` installs the working tree into a separate library, forces
single-threaded BLAS and passes `SILM_REP_SCALE`/`SILM_REP_CORES`.)

Common rule for proportions compared with a published value (from
`replication/common.R`): pass if
|ours − paper| ≤ 3·sqrt(p̄(1 − p̄)(1/R + 1/R_paper)) + δ, with δ = 0.02 unless
stated otherwise. Targets tagged `[draw-dependent]`, `[expected failure]`,
`[informational]` or `[code check]` are reported but not counted in the
headline.

---

## Part 1 — Pre-registered criteria: Zhang and Cheng (2017)

Replication of the simulation study (Section 5, Tables 1-5) of

> Zhang, X. and Cheng, G. (2017). Simultaneous inference for high-dimensional
> linear models. *Journal of the American Statistical Association* 112, 757-768.

with SILM's `Sim.CI()`, `SR()`, `ST()` and `Step()`.

| File | Contents |
|---|---|
| `replication/zc_targets.R` | settings, every published number used, shared data generators, seeds, range rule, report tags |
| `replication/zc_simci.R` | Tables 1-2 (simultaneous confidence intervals), id `zc_simci` |
| `replication/zc_sr.R` | Table 3 (support recovery), id `zc_sr` |
| `replication/zc_st.R` | Table 4 (testing sparse signals: one-step and three-step), id `zc_st` |
| `replication/zc_step.R` | Table 5 (step-down FWER control), id `zc_step` |

Run: `Rscript replication/run.R replication/zc_simci.R replication/zc_sr.R replication/zc_st.R replication/zc_step.R`.
Always run the scripts through `run.R` (see assumption 4).

### What was seen before these rules were fixed

The rules below were fixed before the full run, but not before every result
had been seen. In order:

1. **First version.** Before the first version was written, two exploratory
   runs were made. One computed SILM's bootstrap widths for G = S0^c across 5
   realizations of X per design (σ = 1). It showed 1-2% variation between
   designs, which informed the allowance for the design realization in the
   width band. The other compared `nodewise = "cv"` with `"ZnZ"` at T120 and
   E500 for s0 = 3 and 15 (40 runs; widths and S0 coverage). It informed
   ambiguity 3 below. The smoke tests (`--scale 0.02`) were used only to check
   that the scripts run.
2. **This revision.** It follows an adversarial review. The reviewer's pilot
   ran R = 100-200 on some cells: T120, T500 and E500 with t errors, 5 β draws
   for Table 2 (T500, s0 = 15) and Table 5 (T500, s0 = 3), and single cells of
   Tables 1, 3 and 4. We saw its results. They informed these changes:
   - the draw-dependent classification and range rule;
   - the expected-failure class;
   - the restated σ̂ claim (claim 5 of `zc_simci`), since the pilot suggested
     that the first wording could fail even when the paper's claim holds;
   - the tighter width band for Table 1 (10% → 5%);
   - the tighter NST power claim for Table 5 (6 → 7 of 8);
   - separate targets for code checks;
   - informational screening rows.

   Two of these, the reclassification and the σ̂ claim, make passing easier
   for results that the pilot suggested could fail. They are disclosed as
   such. The same revision changed the seed offsets (assumption 3), so the
   primary β draws and θ̂ folds of the full run are new. No results with them
   have been seen.

### Headline evidence and report tags

Every published number gets a row. A row's target name carries a tag when the
row is **not** part of the headline evidence for SILM:

| Tag | Meaning | Verdict |
|---|---|---|
| (none) | headline evidence: the per-cell numbers and qualitative claims robust to the unknown draws | ordinary rule |
| `[draw-dependent]` | the number is decided mainly by the paper's one unknown draw of β or the support, not by SILM | range rule over 5 draws + per-run redraw (below) |
| `[expected failure]` | the paper's number cannot come from a shared X with pooled CV tuning (ambiguity 3) | ordinary rule; failures are expected |
| `[informational]` | no published value; shown to help judge a deviation | none (`pass = NA`) |
| `[code check]` | a check of the replication code, not a claim of the paper | must pass |

`make_report.R` counts every row in its "Overall" line. For this paper, the
headline count is the sum over the untagged targets. The per-target lines give
the tagged counts separately.

### Source of the published numbers

The JASA article could not be accessed (the publisher returned HTTP 403), so
all numbers come from **arXiv:1603.01295v1**. It is the only arXiv version
(manuscript dated 24 Feb 2016, posted 3 Mar 2016, marked "to appear in JASA").
Section 5 is on pp. 21-26, Tables 1-5 on pp. 31-35 and Figure S.1 on
supplement p. 14. The published tables may differ slightly. The numbers were
extracted with `pdftotext -layout`, parsed by a script and checked against the
page images of Tables 4 and 5. The reviewer compared all 960 entries
independently and found no mismatch.

### Common settings and assumptions

| Item | Paper | Here |
|---|---|---|
| n | 100 (p. 21) | 100 |
| Monte Carlo runs | 1,000 for every table | 1,000 (Tables 1, 2, 3, 5); **500 (Table 4)**; 200 per sensitivity variant |
| Initial estimator | scaled lasso, λ0 = √2 L̃n(k0/p) (p. 21) | SILM's scaled lasso (same rule) |
| Noise level | modified estimator (24): ‖Y − Xβ̂‖² / (n − ‖β̂‖0) | same (SILM) |
| Nodewise λ | 10-fold CV pooled over all nodewise regressions | `nodewise = "cv"` |
| Bootstrap draws M | **not stated** | 500 (SILM default) |
| Designs | "rows of X are fixed i.i.d. realizations from N_p(0, Σ)" | one X per (p, Σ), drawn from a fixed seed |
| Toeplitz (i) | Σij = 0.9^{\|i−j\|} | `cov_toeplitz(p, 0.9)` |
| Exchangeable (ii) | Σii = 1, Σij = 0.8 | `cov_exch(p, 0.8)` |
| Block (Table 5, ii) | blocks of 5, within-block correlation 0.9 | `cov_block(p, 0.9, 5)` |
| t errors | t(4)/√2 | `rt(n, 4) / sqrt(2)` |
| Gamma errors | (Gamma(4, 1) − 4)/2 | `(rgamma(n, 4, 1) - 4) / 2` |

These assumptions fill gaps in the paper (see `zc_targets.R`):

1. **Fixed X, shared.** Each (p, Σ) has one realization of X, shared by all
   tables, both values of s0 and both error laws. The paper does not say
   whether its tables share X. It does share X across error laws: the
   published widths are almost identical for t and Gamma errors. θ̂ depends only
   on X, so it is computed once per design with a seeded CV fold draw and
   passed as `Theta =`. X is used as generated, with no centring. The model has
   no intercept and the rows have mean zero.
2. **Fixed β (primary analysis).** The paper does not say whether β is redrawn
   in each run. As with X (and in van de Geer et al. 2014, whose setup it
   follows), the primary analysis draws β once per (design, s0) ("draw 1") and
   keeps it fixed across runs and error laws. The tiny SDs in Table 3 (e.g. SD
   of d = 0.04 with 10.66 false negatives) support a fixed support. Tables 1,
   2 and 5 use the same Toeplitz p = 500 β. Only the errors are redrawn in each
   run. The draw-sensitivity runs (below) cover the alternatives.
3. **Seeds.** Design seeds are 20170101-20170105. The other seeds add offsets
   that no two purposes share:
   - θ̂: design seed + 1e5;
   - β draw d of Tables 1, 2 and 5: + 2e5 + 100(d − 1) + s0;
   - support draw d of Table 3: + 3e5 + 100(d − 1) + s0.

   Replication r of main cell k of a script uses `set.seed(base + 1e4 k + r)`,
   with base = 1e8 (simci), 2e8 (sr), 3e8 (st) or 4e8 (step). Variant v of
   the sensitivity runs for cell k uses cell number 100 + 10k + v in the same
   formula.
4. **Single-threaded BLAS.** This machine's OpenBLAS is built with OpenMP,
   whose thread pool does not survive `fork()`. Once the parent has made one
   multi-threaded BLAS call, the `mclapply()` children deadlock. `run.R` starts
   each script with `OMP_NUM_THREADS=1` and `OPENBLAS_NUM_THREADS=1` in its
   environment. That is required, because the `Sys.setenv()` in `common.R`
   runs after BLAS has read the thread count. The scripts no longer restart
   themselves. To run one without `run.R`, set both variables before calling
   `Rscript`. This does not change any result.

### Draw-dependent numbers and the range rule

The paper's numbers come from **one unknown realization of β (or of the
support)**. Some of them are decided mainly by that draw. In the reviewer's
pilot at T500 with t errors (5 β draws), Table 5 ST power for s0 = 3 was
0.53-0.99 across draws (paper 0.534), and FWER was 0.00-0.09. Table 2 ST
coverage of S0 at 95% was 0.20-0.32, and of [p] 0.55-0.73. The spread between
draws is 2-5 times the `check_prop` tolerance. The classification follows from
the mechanism, not from agreement with the paper:

- **Coverage of G = S0** (Tables 1 and 2): governed by the bias of the
  de-biased lasso for the drawn active coefficients.
- **Every coverage in Table 2** (s0 = 15): with 15 active coefficients, the
  bias spills into S0^c and [p] (strongly so under the exchangeable design).
  For s0 = 3, the S0^c and [p] coverages are near nominal and stay in the
  headline.
- **Table 3, p = 500, Toeplitz, s0 = 15** (both methods, both error laws): a
  phase transition whose counts depend on where the 15 support points fall.
- **Every number of Table 5** (FWER and average power): average power is the
  detection rate of the drawn coefficients, and FWER in these correlated
  designs is driven by leakage from them.

For these cells the scripts also run **draws 2-5** of β (or the support) and a
**per-run redraw** variant, with 200 runs each.

**Range rule.** Let v range over draw 1 (R = 1,000), draws 2-5 and the redraw
variant (R = 200 each), and let tol_v be the ordinary tolerance for variant v
(below). The row passes if the paper value lies in
[min_v (est_v − tol_v), max_v (est_v + tol_v)]. In other words, the ordinary
rule passes for some variant, or the paper value lies between two variants'
estimates. For the SD of d in Table 3 the redraw variant is left out: its SD
mixes different supports. The row's `ours` is the draw-1 estimate. The note
gives the range, the redraw estimate and the draw-1 verdict under the
ordinary rule. With 5 fixed draws, a sixth draw falls outside their range with
probability 1/3, so a failure here is weak evidence.

### Tolerance rules (ordinary)

- **Proportions** (coverage, size, power, FWER, average power, screening
  probability): `check_prop(est, R, paper, R_paper = 1000)` with δ = 0.02,
  i.e. |est − paper| ≤ 3 √(p̄(1 − p̄)(1/R + 1/R_paper)) + 0.02. Average power
  (Table 5) is a mean of s0 indicators per run. Its per-run variance is at most
  p̄(1 − p̄), so this rule is conservative for it.
- **Interval widths** ("Len"): |est − paper| ≤ 3 sd √(1/R + 1/R_paper) +
  b · paper. Here sd is our per-run SD, standing in for the paper's. The band b
  is:
  - **5% in Table 1.** The exploratory check found a between-design SD of 1-2%,
    so 5% allows about 3 SD for the paper's unknown X and CV folds.
  - **10% in Table 2.** Its widths are inconsistent with Table 1 under a common
    X and pooled tuning (ambiguity 3). The pilot's ST/EX widths for S0^c and
    [p] were about 5% below the paper's, and 10% below for S0.

  The ratio ours/paper of every width is saved in the summaries
  (`width_ratio`) as a continuous measure.
- **Mean of d(Ŝ0, S0)** (Table 3): |est − paper| ≤ 3 √(sd²/R + sd_paper²/R_paper)
  + 0.02, using the published SD.
- **SD of d** (Table 3): |est − paper| ≤ 3 √(sd²/(2R) + sd_paper²/(2 R_paper))
  + 0.02 + 0.25 · paper.
- **Mean FP / FN counts** (Table 3): |est − paper| ≤ 3 sd √(1/R + 1/R_paper)
  + 0.1 + 0.2 · paper, with our per-run SD standing in for the paper's.
- **Qualitative claims**: `paper = NA`. The rule and the value the rule gives
  on the paper's own numbers are stated in the note. Thresholds follow the
  paper's wording:
  - "in general", "tends to" and "overall": ≥ 75-80% of comparisons;
  - "all" and "across all cases": all comparisons, with one exception allowed
    only where it is justified (Table 5, NST).

  Each exception to these conventions is justified where it appears. Claims
  are evaluated on draw 1.

### Target zc_simci: Tables 1 and 2 (Section 5.1)

- **Setting.** n = 100, p ∈ {120, 500}, Σ ∈ {Toeplitz (i), exchangeable (ii)}.
  S0 = {1..s0} with s0 = 3 (Table 1) or 15 (Table 2), and β_j ~ Unif[0, 2]
  (fixed). The errors are t(4)/√2 or centred Gamma. Levels are 95% and 99%,
  and G ∈ {S0, S0^c, [p]}. `Sim.CI(X, Y, set = G, M = 500, alpha = level,
  nodewise = "cv", Theta = θ̂)`. Note that `alpha` is the confidence level in
  `Sim.CI()`.
- **Metrics.** "Cov" is the share of runs in which every β_j, j ∈ G, lies in its
  interval. "Len" is the width averaged over the components of G and over runs
  (the paper averages over components for ST).
  - NST = `band.nst` and ST = `band.st`.
  - EX is the studentized statistic with the Gumbel critical value of Remark 2.4,
    eq. (15), with |G| in place of p. It is NA for G = S0 in the paper. EX is
    **not a SILM method**. It is computed from SILM's internal de-biased fit
    (`SILM:::.silm_fit`), and every run checks that the fit's estimates equal
    `Sim.CI()`'s.
- **Paper values.** Every non-NA entry of Tables 1-2 (pp. 31-32): 256 per table,
  512 rows in all, in these classes:

  | Class | Rows | Count | Rule |
  |---|---|---|---|
  | Table 1, headline | all widths; Cov for G = S0^c and [p] | 224 | ordinary (widths 5%) |
  | Table 1 `[draw-dependent]` | Cov for G = S0 (NST, ST) | 32 | range rule |
  | Table 2, headline | Len of ST (all G), EX (S0^c, [p]), NST (S0) | 96 | ordinary (widths 10%) |
  | Table 2 `[draw-dependent]` | every Cov except NST for S0^c and [p] | 96 | range rule |
  | Table 2 `[expected failure]` | NST Cov and Len for G = S0^c and [p] | 64 | ordinary (widths 10%) |

  Sensitivity runs: for s0 = 3, G = S0 only; for s0 = 15, every G. All 16
  (design, s0, error) cells have 5 variants of 200 runs.
- **Qualitative claims** (p. 23 and Figure S.1):
  1. "The coverage is in general more accurate for S0^c (as compared to S0)":
     |Cov(S0^c) − level| ≤ |Cov(S0) − level| in ≥ 80% of the 64 (table, p,
     error, Σ, NST/ST, level) combinations. The paper's own share is 98%.
  2. "The non-studentized test statistic tends to provide better coverage (but
     with larger width) as compared to its studentized version when s0 is
     large": in Table 2, Cov(NST) ≥ Cov(ST) − 0.01 in ≥ 80% of 48
     combinations, and Len(NST) > Len(ST) in ≥ 80%. The paper gives 100% for
     both. Only the direction can be checked. With pooled CV our NST intervals
     are only about 1% wider than ST (ambiguity 3).
  3. "When s0 = 15 ... the coverage for the active set can be significantly
     lower than the nominal level": in Table 2 with G = S0,
     Cov ≤ level − 0.05 in ≥ 75% of 32 combinations. The paper gives 100%.
  4. "Overall, the non-studentized method provides satisfactory coverage": in
     Table 1, NST with G ∈ {S0^c, [p]} has |Cov − level| ≤ 0.04 in ≥ 80% of
     32 combinations. The paper gives 100%.
  5. Figure S.1 / eq. (24): the scaled lasso underestimates σ, and the
     modified estimator removes the underestimation. The check uses t errors
     and the 8 (design, s0) cells, and has two parts:
     - (a) the median σ̂_SL < 1 in ≥ 6 of 8 cells;
     - (b) |median modified σ̂ − 1| ≤ 0.05 and median modified σ̂ ≥ median
       σ̂_SL in ≥ 6 of 8 cells.

     Here σ̂_SL = ‖Y − Xβ̂‖/√n, which is exactly the scaled-lasso noise estimate
     at the returned coefficients. The modified estimate is
     σ̂_SL √(n/(n − ‖β̂‖0)) ≥ σ̂_SL in every run, so the second condition of (b)
     always holds. The first version required the modified median to be
     *closer to 1* than σ̂_SL. That fails when σ̂_SL is only about 1% low
     (s0 = 3) and the modified estimator overshoots by 2%, although the
     paper's claim holds.
- **Code check** (target `ZC code checks [code check]`): the EX computation
  uses exactly the `Sim.CI()` estimates (max difference < 1e-10, over all
  runs including the sensitivity runs).
- **R.** 1,000 runs per cell (16 cells), as in the paper, plus 5 × 200 per cell
  for the sensitivity runs.

### Target zc_sr: Table 3 (Section 5.2)

- **Setting.** Designs as in Section 5.1 (p ∈ {120, 500}, Σ ∈ {(i), (ii)}).
  The support S0 is s0 draws without replacement from {1..p}, with s0 ∈ {3, 15}
  and β_j ~ Unif[2, 4]. Support and values are drawn once per (design, s0) and
  saved in the summaries. The errors are t or Gamma.
  `SR(X, Y, nodewise = "cv", Theta = θ̂)`.
- **Metrics.** d(Ŝ0, S0) = |Ŝ0 ∩ S0| / √(|Ŝ0||S0|) (0 when Ŝ0 is empty), with its
  mean and SD, and mean FP and FN. "SupRec" is the `"de-biased Lasso"`
  component (threshold √(2 log p) on the studentized statistic, i.e. τ* = 2)
  and "Lassosc" is the `"scaled Lasso"` component. Stability selection and
  screen-and-clean are not in SILM and are not replicated; their numbers are
  kept in `zc_targets.R` for reference.
- **Paper values.** The SupRec and Lassosc rows of Table 3 (p. 33): 16 cells ×
  2 methods × 4 numbers = 128 rows.
  - 112 are headline rows.
  - 16 are `[draw-dependent]`: the cell p = 500, Toeplitz, s0 = 15, a phase
    transition. The paper reports d = 0.53 with FN = 10.66 for SupRec and
    FN = 7.37 for the lasso. In the pilot, with another support, the lasso
    had FN = 2.06. This cell has sensitivity runs with 4 more fixed supports
    and a per-run redraw.
  - The SD of d under the redraw variant is saved in the summaries. It shows
    whether the paper's small SD is compatible with a redrawn support.
- **Qualitative claims** (p. 24):
  1. For s0 = 3, SupRec "clearly outperforms Lasso": mean d(SupRec) >
     mean d(Lassosc) in all 8 cells.
  2. For s0 = 15, it "in general outperforms" Lasso: the same comparison in
     ≥ 6 of 8 cells. The paper gives 8 of 8.
- **R.** 1,000 runs per cell, as in the paper, plus 5 × 200 for each of the 2
  draw-dependent cells.

### Target zc_st: Table 4 (Section 5.3)

- **Setting.** p = 500. Case (i) is Toeplitz, with β_j = √(10 log(p)/n) ≈ 0.788
  for j ≤ s0 (s0 = 3 and 15) and c0 = 1/5 (|D1| = 20). Case (ii) is
  exchangeable, with β_j = 10 √(log(p)/n) ≈ 2.49 for j ≤ 3 and c0 = 1/3
  (|D1| = 33). The β formulas are on p. 24, and β is deterministic, so there
  is no draw dependence. The test sets G are:
  - s0 = 3: S0^c = {4..p} (size), {3} ∪ S0^c and {2,3} ∪ S0^c (power);
  - s0 = 15: S̃0^c = {16..p} (size), {15} ∪ S̃0^c and {14,15} ∪ S̃0^c (power).

  The levels are 5% and 1%, and the statistics NST and ST.
- **One-step procedure** (no splitting, no screening):
  `Sim.CI(X, Y, set = G, alpha = 1 − level, Theta = θ̂)`. It rejects when some
  simultaneous interval excludes 0, which is exactly
  max_{j∈G} √n|β̆_j| (or its studentized version) > bootstrap critical value.
- **Three-step procedure.** `ST(X, Y, sub.size = c0 n, test.set = G, M = 500,
  alpha = level, nodewise = "cv")`. The split, the screening and the nodewise
  lasso on D2 (about 12 s) do not depend on G or the level. They are therefore
  computed once per run by `st_three_step()`, which follows `ST()` line by line
  with SILM's internal helpers and replays the same bootstrap draws for every G.
  Started from the same RNG state, it gives the same statistics and decisions as
  `ST()`. This is **verified against `ST()` itself** in the first run of every
  cell: 4 calls per cell, all of which must match exactly (row "Share of ST()
  calls reproduced exactly" = 1 in `ZC code checks [code check]`).
- **Paper values.** Every entry of Table 4 (p. 34): 18 rows × 8 = 144 criteria.
  In addition, the screening probabilities quoted on p. 25 for case (ii) with
  s0 = 3 are checked for both error laws. The remedy keeps all three relevant
  variables with probability 0.98 (SILM's screening); plain marginal
  screening, which is not a SILM method, does so with probability 0.59. The
  paper's R for these is assumed to be 1,000.
- **Qualitative claims** (p. 25):
  1. "The one-step procedure has downward size distortion" (Toeplitz): the mean
     of the 8 one-step 5% sizes in the (i) size rows is < 0.05. Paper: 0.0225.
  2. "The three-step procedure has reasonable size for t errors" (Toeplitz):
     max |size − 0.05| ≤ 0.035 over the 4 values. Paper: 0.01. The bound is
     the paper's 0.01 plus about 2.5 MC s.e. of a size near 0.05 at R = 500
     (s.e. 0.0097). A bound near the paper's 0.01 would fail on Monte Carlo
     error alone even if the true sizes equalled the paper's. The bound also
     accepts sizes of 0.07, which the paper calls "slightly upward distorted"
     for Gamma errors, so claim 3 carries the t/Gamma contrast.
  3. "... slightly upward distorted for Gamma errors": the mean of the 4 values
     is > 0.05. Paper: 0.0625.
  4. "For exchangeable covariance structure, both procedures show upward size
     distortions": the mean 5% size in row (ii) S0^c is > 0.05, for each
     procedure. Paper: 0.083 and 0.10.
  5. "The three-step procedure generates higher power for the Toeplitz
     covariance structure": power(three-step) > power(one-step) in ≥ 75% of the
     32 case-(i) comparisons. Paper: 100%.
  6. "Powers of both procedures are close to 1 in case (ii)": the minimum over
     the 32 values (2 sets × 2 levels × 2 procedures × 2 error laws × 2
     statistics) is ≥ 0.95. Paper: 0.99.
- **R.** **500 runs per cell** (6 cells), against the paper's 1,000. Each run
  needs a nodewise lasso on D2 for each of 3 models × 2 error laws, and 1,000
  runs would take about 2 hours on 10 cores. The rules use the actual R.
- **Known deviation.** SILM's `ST()` always screens with the paper's "remedy":
  a cross-validated lasso on D1, completed by marginal screening of the lasso
  residuals up to |D2| − 1 variables. The paper describes plain marginal
  screening as step 2 and introduces the remedy for the exchangeable case. It
  does not say whether case (i) used the remedy. Here both cases use SILM's
  screening. The deviation matters for the case (i) three-step sizes: if a
  relevant variable is missed on D1, its correlated Toeplitz neighbours in G
  absorb its effect and the size is inflated. For case (i), s0 = 3 and 15, the
  target `ZC Section 5.3 screening, case (i) [informational]` therefore
  reports P(S0 ⊆ screened set) under both screenings, on the same split and
  for both error laws. It has 8 rows with no published value and no verdict.
  The one-step procedure uses the full-sample θ̂ of the fixed design.

### Target zc_step: Table 5 (Section 5.4)

- **Setting.** p = 500. Σ is (i) Toeplitz or (ii) block diagonal (5 × 5 blocks,
  0.9). The data follow "the linear model considered in Section 5.1": β_j ~
  Unif[0, 2] on S0 = {1..s0}, s0 ∈ {3, 15}, fixed, with the same Toeplitz β as
  Tables 1-2. The errors are t or Gamma, and the hypotheses are two-sided
  H0j: β_j = 0 for all j. `Step(X, Y, M = 500, alpha = 0.05, nodewise = "cv",
  Theta = θ̂)` is used for NST and ST. "BH" is Bonferroni-Holm on the p-values
  2(1 − Φ(|T_j|)) of the studentized statistics T_j = √n β̆_j / ω̂_jj^{1/2} from
  SILM's de-biased fit. It is **not a SILM method**; it is computed as the
  paper describes.
- **Metrics.** FWER = P(some j ∉ S0 rejected). Average power = mean over
  j ∈ S0 of P(H0j rejected), as defined on p. 25.
- **Paper values.** Every entry of Table 5 (p. 35): 48 rows, all
  `[draw-dependent]` and judged by the range rule. Every cell has sensitivity
  runs.
- **Qualitative claims** (pp. 25-26; the headline evidence for Table 5):
  1. FWER control: every FWER ≤ 0.05 + 3 √(0.05 · 0.95 / R).
  2. "The two procedures provide similar control on the FWER":
     max |FWER(step-down) − FWER(Holm)| ≤ 0.03. Paper: 0.013.
  3. "The step-down method delivers slightly higher average power across all
     cases": power(ST step-down) ≥ power(Holm) in all 8 cells, and
     power(NST step-down) ≥ power(Holm) in ≥ 7 of 8. The paper gives 8 and 8.
     NST is allowed one exception because its rejections are not nested in
     Holm's (it orders hypotheses by |β̆_j|, not by |T_j|), and the paper's own
     NST − Holm margins are as small as 0.015. The first version allowed two
     exceptions.
- **R.** 1,000 runs per cell (8 cells), as in the paper, plus 5 × 200 per cell
  for the sensitivity runs.

### Ambiguities noted in the paper

1. **M** (the number of bootstrap draws) is not stated. SILM's default of 500
   is used.
2. **Whether X and β are shared or redrawn** across tables, cells and runs is
   not stated. See the assumptions and the draw-sensitivity runs above.
3. **Table 2 widths.** The table's note says λ_j is "chosen via 10-fold
   cross-validation among all nodewise regressions". Table 1's note adds "to
   be the same".
   - **σ̂ cancels in the width ratio.** For a fixed G, the NST half-width is
     q_NST/√n, where q_NST is a bootstrap quantile of
     max_{j∈G} |(Θ̂X'e)_j| σ̂/√n. It is therefore proportional to σ̂. The ST
     half-width of component j is q_ST (ω̂_jj/n)^{1/2}, where q_ST does not
     depend on σ̂ and ω̂_jj ∝ σ̂². So the ratio of the NST width to the average
     ST width depends only on X, Θ̂ and G, up to bootstrap noise.
   - **The two tables disagree.** G = [p] is the same set in Tables 1 and 2,
     and S0^c nearly so ({4..p} against {16..p}). With a shared X and pooled
     CV θ̂, the ratio would therefore be the same in both tables. It is not.
     For G ∈ {S0^c, [p]} the published NST/ST ratio is 1.007-1.031 in Table 1
     but 1.084-1.274 in Table 2 (NST widths 8-27% larger). For example,
     p = 500 (ii), [p], 99%: 1.82/1.77 = 1.03 in Table 1 against
     2.38/1.87 = 1.27 in Table 2. For G = S0 (a different set in each table)
     the ratio is 1.000-1.025 in Table 1 and 1.024-1.179 in Table 2.
   - **What it implies.** The paper's Table 2 must have used a different X or
     different nodewise tuning. Our construction gives a ratio of about 1.01
     for both tables. A quick check with `nodewise = "ZnZ"` raised both widths
     by about 12%, so the ratio stayed near 1.01. Per-regression CV of λ_j is
     a possible explanation but cannot be tested with SILM.
   - **Consequences for the criteria.** The Table 2 NST rows (Cov and Len) for
     G = S0^c and [p] are registered as `[expected failure]`. The Table 2 ST
     and EX widths are expected to be about 5-10% below the paper's, hence
     the 10% band. The NST width for G = S0 stays in the headline, but it is
     at risk for the same reason.
4. **Screening in case (i)** of Section 5.3: plain marginal screening or the
   remedy? SILM implements only the remedy. The informational rows show how
   often each screening keeps S0.
5. **Error law** for the screening probabilities 0.98 and 0.59 (p. 25) is not
   stated. Both laws are checked.
6. **EX critical value.** Eq. (15) is stated for max over all p components. We
   use |G| in place of p for G = S0^c and [p].

### Runtime (full run, 10 cores)

The core time per run comes from the reviewer's benchmark, which ran at load
averages of 30-97, so these times are upper bounds. The smoke tests
(`--scale 0.02 --cores 2`) only check that the scripts run.

| Script | Main runs | Sensitivity runs | Core time per run | Estimated wall time |
|---|---|---|---|---|
| zc_simci | 16 × 1,000 | 16 × 5 × 200 | 0.26 s (p = 120), 0.75 s (p = 500); about 1/3 of that when only G = S0 | about 23 min |
| zc_sr | 16 × 1,000 | 2 × 5 × 200 | 0.2 s | about 6 min |
| zc_st | 6 × 500 | none | 14-15 s (case i), 10 s (case ii) | 65-75 min |
| zc_step | 8 × 1,000 | 8 × 5 × 200 | 0.23 s | about 6 min |
| Total | | | | about 1.7-1.9 h (budget 2.5 h) |

Each script also computes θ̂ for its fixed designs: 39 s (T500) and 83 s (E500)
on one core, about 5-10 s on 10 cores. In the first run of each cell, `zc_st`
also makes 4 extra `ST()` calls (about 50 s of core time) for the code check.

---

## Part 2 — Pre-registered replication criteria: Dezeure, Bühlmann and Zhang (2017)

Dezeure, R., Bühlmann, P. and Zhang, C.-H. (2017). High-dimensional simultaneous
inference with the bootstrap. *TEST*, 26, 685–719 ("DBZ"). Sections 5.1–5.2
(journal pp. 702–715). Page numbers below are journal pages (PDF page = journal
page − 684).

These criteria were fixed before the full runs. The only runs made before
fixing them were smoke tests at scale 0.02, which only check that the scripts
run. There is one exception. The riboflavin "no rejection" rule (dbz_riboflavin
rows 1–2) was set after development runs on the real data (assumption 10), so
it is not blind. The criteria were revised once after an adversarial review,
still before any full run. The revision:

* added the ZC cell (SILM's `Sim.CI`);
* moved compute from bootstrap samples to realisations in the FWER studies;
* added a `boot.shortcut` sensitivity fit;
* made the Bonferroni–Holm p_equiv rows descriptive;
* removed a slack term from the xyz rule;
* corrected three transcriptions against the figures' vector graphics.

No tolerance was loosened.

Each script below implements its criteria and writes
`replication/results/<id>.rds`, which holds the criteria table and per-cell
summaries. `replication/dbz_targets.R` holds the published values and
settings, with their sources.

| Script | Result id | Paper material |
|---|---|---|
| `dbz_coverage.R` | `dbz_coverage` | Secs 5.1.1–5.1.2, Figs 4, 5, 7, 8 (incl. ZC = `Sim.CI`) |
| `dbz_hetero.R` | `dbz_hetero` | Sec. 5.1.3, Figs 10, 11; SILM additions (wild Gaussian/Mammen, xyz) |
| `dbz_fwer.R` | `dbz_fwer` | Secs 5.1–5.2, Figs 6, 9, 12, 13, eq. (15) |
| `dbz_riboflavin.R` | `dbz_riboflavin` | Secs 5.2.1–5.2.2, table p. 713 (dsmN71), Fig. 15 |
| `dbz_hdi_reference.R` | `dbz_hdi_reference` | hdi 0.1-10 `tests/test-lasso.R` reference values |

### Conventions

* "Original" = `lasso.proj()`: asymptotic intervals, with Bonferroni–Holm
  ("BH") for multiple testing.
* "Bootstrap" = `boot.lasso.proj()` with the residual bootstrap, the paper's
  default (p. 703).
* "WY" = the bootstrap's Westfall–Young adjustment, with the bootstrap under
  the complete null (Sec. 4.3).
* "ZC" = the Gaussian multiplier bootstrap of the linearised part only (Zhang
  and Cheng), i.e. SILM's `Sim.CI()`.
* Homoscedastic settings use the non-robust s.e. Heteroscedastic settings
  report both the non-robust and the robust s.e., as the paper does.
* Exact values are those printed in the paper: the "Avg" column of Figs 5, 8
  and 11, the coverages written above the intervals, and the table on p. 713.
* The following were read from the figures' vector graphics (PyMuPDF, with the
  axes calibrated to their tick marks): the Fig. 4 histograms, the Fig. 13
  boxplots and the Fig. 15 medians.
* The other boxplot medians and histogram bars were read from the rendered
  figures and are marked *approx*: FWER to about ±0.005, power to ±0.02,
  p_equiv to ±5, histogram bars to ±1 coefficient. The reconstructed
  histograms of Figs 4 and 7, and of the robust panels of Fig. 10, reproduce
  the printed averages to 0.1 percentage point.
* A proportion compared with a published value uses `check_prop()` from
  `common.R`: |est − paper| ≤ 3·sqrt(p̄(1 − p̄)(1/R + 1/R_paper)) + 0.02.
  * For FWERs, R is our number of realisations and R_paper is the paper's
    total: 300 models × 100 = 30000 for Toeplitz, and 50 × 100 = 5000 for
    Fig. 12. The extra 0.02 also absorbs the difference between the paper's
    median over models and our pooled rate.
  * For shares of coefficients (histograms), R = R_paper = p.
* Average coverages have a tolerance of 3 MC s.e. + 0.01, or + 0.015 for the
  non-robust heteroscedastic methods and for ZC. The MC s.e. is
  sd(per-replication average coverage)/sqrt(R). The extra term covers the
  single design and coefficient vector, which differ from the paper's
  (unknown) ones. For ZC it also covers the difference in implementation
  (assumption 14).
* A qualitative claim has `paper = NA` or a signed difference as `paper`. Its
  pass rule is stated explicitly in the `note` column.
* **Descriptive rows** have `pass = NA` and "[descriptive]" in the metric.
  They are not criteria. `make_report.R` counts them in the total number of
  rows but never as passes, so subtract them when reading the overall count.
  There are three: the two Toeplitz BH p_equiv rows and the riboflavin BH
  p_equiv row.
* **Failed replications.** `run_reps()` drops a failed replication with only a
  warning. The dbz scripts use `dbz_reps()` instead, which records the number
  of replications requested, obtained and failed in the summaries (`reps`).
  Any failures are appended to the notes of the affected rows. If more than 5%
  of a cell's replications fail, its criteria are set to `pass = FALSE` and
  marked "FLAGGED". A script stops only if every replication of a cell fails.
* Replication r of a cell uses `set.seed(seed_base + r)`. Designs, coefficient
  vectors, Z and Θ are generated once per cell from their own seeds
  (`dbz$seeds`).

### Modelling assumptions and resolved ambiguities

1. **Error mixture of Sec. 5.1.3 (p. 709).** The printed
   ε_i = l_i ζ_i + (l_i − 1) η_i has mean 1/2: for l_i = 0 it equals −η_i ~
   N(1/2, 0.7²). With Y_i = Q_i ε_i + ε_i this gives E[Y_i | X_i] = (Q_i + 1)/2,
   a nonlinear function of X, which contradicts "maintaining the correctness of
   the linear model". We read it as a typo for ε_i = l_i ζ_i + (1 − l_i) η_i,
   the mean-zero mixture ½ N(1/2, 1.2²) + ½ N(−1/2, 0.7²).
2. **Q_i (p. 709).** Q_i = Σ_{k≤5} X_ik² − E[Z_i²] is used literally, with
   E[Z_i²] = 13/3 for Z_i ~ U(1, 3); the rows of X are N_p(0, I) times Z_i/2.
   Centring by E[Σ_k X_ik²] = 65/12 instead would shift Q_i by 13/12. With
   mean-zero errors the linear model (β = 0) holds either way.
3. **Average coverage, Sec. 5.1.3.** The text (p. 710) says the robust
   bootstrap and robust original average 95.1 and 95.9. Fig. 11 prints 95.6
   and 96.3, and the robust histograms of Fig. 10 imply 95.62 and 96.26. We
   use the figure values; both sources agree that the bootstrap is closer to
   95.
4. **Fig. 6 vs Fig. 13 (top).** Both show the same Gaussian Toeplitz study, but
   the WY FWER median is 0.03 in Fig. 6 and 0.04 in Fig. 13. We use Fig. 6
   (0.03) and record the Fig. 13 value; the tolerance covers both.
5. **Text p. 710 cites Fig. 9** for the heteroscedastic multiple-testing
   results; the relevant figure is Fig. 12.
6. **B and the refit of the lasso.** The paper does not state B for the
   simulations (hdi's default is 1000; Fig. 15 uses 1000). It also does not
   say whether the lasso is re-tuned in each bootstrap sample.
   * We re-tune by 10-fold CV in every bootstrap sample (`boot.shortcut =
     FALSE`, hdi's default).
   * B = 500 for coverage, 300 for the heteroscedastic CI cell, 100 for the
     FWER studies, 200 for Fig. 15 and 1000 for riboflavin (a) and (b).
   * B = 100 still gives the exact WY decision at 5% for the drawn bootstrap
     sample: reject iff |T_j| exceeds the 5th largest of the 100 null maxima.
     It leaves the median of p_equiv essentially unaffected.
   * Development runs on the real riboflavin response (3 seeds, each fit with
     its own CV folds, so the comparison is between distributions, not
     paired) gave p_equiv ≈ 1050–1200 with `boot.shortcut = TRUE` versus
     ≈ 1470–1570 with re-tuning. The shortcut is therefore not neutral for WY
     thresholds, and it is recorded only as a sensitivity analysis (see 15).
7. **Designs held fixed.** The coverage study uses one Toeplitz design and one
   U(−2, 2) coefficient vector (s0 = 3, random positions), the same for the
   Gaussian and the chi-squared cell. Errors are redrawn per realisation.
8. **Reduced multiple-testing studies.**
   * Toeplitz: 4 designs × 6 coefficient types = 24 models, 12 realisations
     each, i.e. 288 per error type (paper: 300 models × 100).
   * Heteroscedastic (Fig. 12): 16 designs × 20 realisations = 320 (paper:
     50 × 100).
   * The paper's boxplot medians over models are compared with our pooled
     FWER, our median power over models and our median p_equiv over
     realisations.
   * With these R the FWER comparisons still have limited resolution:
     * `check_prop` accepts ±0.050 (Toeplitz WY, paper 0.03), ±0.045
       (Toeplitz BH) and ±0.04–0.06 (Fig. 12).
     * The control bounds are 0.089 (Toeplitz) and 0.087 (heteroscedastic),
       and the "largest FWER" bound is 0.107.
     * These rows detect a failure of error control or a wrong order of
       magnitude. They do not test the paper's second decimal.
9. **p_equiv (eq. 15).**
   * For WY, t_rej is the exact rejection threshold for |T_j| implied by the
     adjusted p-values (1 + #{b: M_b ≥ |t|})/(B + 1) ≤ α. It is the (k+1)-th
     largest bootstrap maximum M_b, with k = ⌊α(B + 1) − 1⌋. The scripts check
     that |T_j| > t_rej reproduces the WY decisions.
   * For BH, the Holm threshold after r rejections is α/(p − r), so
     p_equiv = p − r. This matches the table on p. 713: 4088 = p for dsmN71,
     and 5596 = 5597 − 1 for Brain.
   * With s0 = 3 and few Holm rejections, the BH p_equiv median can only
     deviate from the paper when Holm rejects many hypotheses. These rows are
     therefore descriptive consistency checks, not replication tests.
10. **Riboflavin seed dependence (rule not blind).**
    * With Z fixed, the conclusions of Sec. 5.2.2 depend on the random CV
      folds of the initial lasso. In development runs WY rejected one
      hypothesis in 1 of 3 seeds, and Holm on a fit that also recomputed Z
      rejected one hypothesis.
    * The rule "no rejection in at least 3 of 6 CV seeds" was chosen after
      these runs. It is lenient: 3 of 6 seeds with rejections still pass.
    * The notes report the number of rejections per seed so that the reader
      can judge.
    * Z is computed once (one nodewise-CV seed), so the result is conditional
      on that Z. Recomputing Z per seed would cost about 3 min per seed.
    * The robust-s.e. Holm results are reported in the summaries only. The
      paper does not discuss them, and in development runs they rejected in
      most seeds.
11. **Riboflavin with simulated signal (table p. 713) and Fig. 15.**
    * Table p. 713: one coefficient vector per type (6 types; s0 = 3, random
      positions), Y = xβ + N(0, 1), one realisation each, B = 1000 (paper:
      6 types × 5 seeds × 100 realisations). Only the p_equiv medians are
      compared.
    * Fig. 15: 10 random columns, c ∈ {2, 3}, B = 200.
    * Column scale: the simulated signal and Fig. 15's Y' = Y + X_j c use the
      riboflavin columns as stored in hdi (raw log expression, SDs 0.10–1.84,
      median 0.36), not standardized columns. The effective signal size of a
      given c, and therefore rows 5–7 of dbz_riboflavin, depends on this
      scaling. We assume the paper used the data as stored in hdi.
    * Fig. 15's grid is c = 0.1, …, 0.5, 0.8, 1, 1.5 + 0.2357k (k = 0, …, 14),
      5 and 10. The WY median −log p is 6.22 at c = 1.97 and at its floor
      (6.91) from c = 2.21 on. The Holm median is 0 up to c = 2.44 and 1.04 at
      c = 2.91.
12. **Not replicated.** RLDPE in Figs 4–6 (not in SILM), the seven other real
    designs of the table on p. 713 (data not available), and the Electronic
    Supplementary Material.
13. **SILM additions in the heteroscedastic cell.** Their "FWER" is reported
    in two forms on the single design with R = 100:
    * the Westfall–Young FWER (any adjusted p ≤ 0.05; all hypotheses are
      null);
    * the non-coverage of the simultaneous intervals over all p coefficients
      (eq. 10 with max |T*|), i.e. the FWER of the single-step max-|T| test
      from the centred bootstrap.

    With R = 100 the bound is 0.135, so these rows are gross-failure checks
    only. All seven methods of this cell are fitted to the same realisations.
    A realisation in which any method fails is dropped for all of them (and
    counted; see Conventions).
14. **ZC = `Sim.CI` (Figs 4–5, Gaussian errors only).**
    * The paper's ZC bootstraps only the linearised part of the de-sparsified
      estimator with Gaussian multipliers. This is Zhang and Cheng's
      procedure, which SILM implements as `Sim.CI()`.
    * The individual interval for β_j is `band.st` of
      `Sim.CI(X, y, set = j, M = 500, alpha = 0.95, Theta = Θ)`, one call per
      coefficient. Θ = `Theta.hat(X)` (nodewise lasso with CV) is computed
      once for the design.
    * For a single coefficient, `band.nst` = `band.st`, because the bootstrap
      quantile is scale equivariant.
    * Implementation difference: SILM's ZC starts from the scaled lasso (as
      Zhang and Cheng do) and uses SILM's own Θ and noise estimate. The
      paper's ZC presumably started from its CV lasso and hdi's Z. We allow
      +0.015 instead of +0.01 on its average coverage.
    * ZC uses the same realisations as the original and the bootstrap. Its
      multiplier draws are made after the other fits.
15. **Toeplitz p_equiv sensitivity.** The Toeplitz WY p_equiv may well fail
    against the paper's 290. The adversarial review pointed out that, with the
    population Θ of the AR(0.9) design, neighbouring statistics correlate at
    about −0.5 and are nearly uncorrelated beyond that, which suggests a value
    near 400–450. Because B and the refit rule are unstated, every Toeplitz realisation
    also gets a WY fit with `boot.shortcut = TRUE`. Its median and quartiles
    of p_equiv and its FWER are recorded in the summaries and in the note of
    the p_equiv row; they are not a criterion. The pre-registered tolerance
    is unchanged. A failure of the p_equiv row cannot be attributed to SILM
    unless the shortcut fit also disagrees with the paper.

### Criteria

### dbz_coverage (Figs 4–5, 7–8; one design, R = 100, B = 500)

For each error type (Gaussian: Figs 4 and 5; chi-squared: Figs 7 and 8):

| # | Metric | Paper | Pass rule |
|---|---|---|---|
| 1 | Average coverage, original | 0.963 / 0.965 (exact) | within 3 s.e. + 0.01 |
| 2 | Average coverage, bootstrap | 0.958 / 0.961 (exact) | within 3 s.e. + 0.01 |
| 3 | Bootstrap average closer to 0.95 than original | +0.005 / +0.004 | abs(orig − .95) − abs(boot − .95) > 0 |
| 4 | Share of coefficients with coverage ≤ 0.90, original | 0.048 / 0.064 | `check_prop`, R = R_paper = 500 |
| 5 | Same, bootstrap | 0.012 / 0.010 | `check_prop` |
| 6 | Under-coverage share, bootstrap − original | −0.036 / −0.054 | < 0 |
| 7 | Over-coverage share (≥ 0.99), bootstrap − original | −0.14 / −0.18 | < 0 |
| 8 | Minimum coverage, bootstrap − original | +0.08 / +0.13 (exact) | > 0 |
| 9 | Mean CI length ratio bootstrap/original | 1 (claim p. 710) | ≤ 1.05 |

ZC (`Sim.CI`), Gaussian errors only (Figs 4–5):

| # | Metric | Paper | Pass rule |
|---|---|---|---|
| Z1 | Average coverage, ZC | 0.962 (exact) | within 3 s.e. + 0.015 |
| Z2 | Share of coefficients with coverage ≤ 0.90, ZC | 0.060 (Fig. 4) | `check_prop`, R = R_paper = 500 (tolerance ≈ 0.065) |
| Z3 | ZC no better than original: share ≤ 0.90, ZC − original | +0.012 (captions of Figs 4–5: "does not show any improvements") | ≥ −0.02 |
| Z4 | Bootstrap better than ZC: share ≤ 0.90, bootstrap − ZC | −0.048 (p. 711: "clearly sub-ideal") | < 0 |
| Z5 | Minimum coverage, bootstrap − ZC | +0.09 (0.88 vs 0.79, exact) | > 0 |

One more criterion: the original's under-coverage share, chi-squared minus
Gaussian, must be ≥ 0 (claim p. 706, "even more pronounced").

### dbz_hetero (Figs 10–11; one design, R = 100, B = 300)

| # | Metric | Paper | Pass rule |
|---|---|---|---|
| 1–2 | Average coverage, robust original / robust bootstrap | 0.963 / 0.956 (Fig. 11) | within 3 s.e. + 0.01 |
| 3–4 | Average coverage, non-robust original / bootstrap | 0.949 / 0.946 | within 3 s.e. + 0.015 |
| 5–8 | Share ≤ 0.90 for the four methods | 0 / 0.012 / 0.16 / 0.17 (approx) | `check_prop`, R = R_paper = 250 |
| 9–10 | Share ≤ 0.90, non-robust − robust (original; bootstrap) | 0.16 / 0.16 | ≥ 0.05 |
| 11 | Robust: bootstrap average closer to 0.95 than original | +0.007 | > 0 |
| 12–13 | abs(avg bootstrap − avg original) (robust; non-robust) | 0.007 / 0.003 | ≤ 0.01 |
| 14 | Wild (Gaussian): abs(avg − avg residual robust) | claim p. 712 | ≤ 0.01 |
| 15 | Wild (Gaussian): share ≤ 0.90 minus residual robust | claim p. 712 | ≤ 0.02 |
| 16 | Wild (Mammen): abs(avg − avg wild Gaussian) | claim p. 688 | ≤ 0.015 |
| 17 | xyz not more accurate than wild Gaussian: abs(xyz − .95) − abs(wild − .95) | claim p. 699 (weak directional check) | ≥ 0 |
| 18–20 | Simultaneous non-coverage (max-abs(T) FWER): wild G, wild M, xyz | Theorem 3 (gross-failure check) | ≤ 0.05 + 3·sqrt(0.0475/R) + 0.02 = 0.135 |
| 21–23 | WY FWER: wild G, wild M, xyz | Theorem 3 (gross-failure check) | same bound |
| 24 | Simultaneous: abs(wild − 0.05) − abs(residual robust − 0.05) | claim p. 702 (weak directional check) | ≤ 2·sqrt(0.0475/R) |

### dbz_fwer (Figs 6, 9, 12, 13)

Toeplitz, for each error type (Gaussian: Fig. 6 and the top of Fig. 13;
chi-squared: Fig. 9 and the bottom of Fig. 13). 24 models × 12 realisations,
B = 100:

| # | Metric | Paper | Pass rule |
|---|---|---|---|
| 1 | FWER, WY (pooled) | 0.03 / 0.025 (approx) | `check_prop`, R_paper = 30000 (tolerance ≈ 0.050 / 0.048) |
| 2 | FWER, BH (pooled) | 0.02 / 0.01 (approx) | `check_prop` (≈ 0.045 / 0.038) |
| 3 | FWER WY − BH | +0.01 / +0.015 | ≥ 0 |
| 4 | FWER control, WY | 0.05 | ≤ 0.05 + 3·sqrt(0.0475/R) = 0.089 |
| 5 | Power, WY, median over models | 0.72 / 0.69 (approx) | within 0.2 |
| 6 | Power WY − BH (pooled) | +0.02 / +0.02 | in [−0.02, 0.10] |
| 7 | p_equiv WY, median over realisations | 290 / 295 (Fig. 13; "about 300") | within ±20% (≈ ±0.05 in t_rej); shortcut sensitivity in the note |
| 8 | p_equiv BH, median [descriptive] | 498 | none (`pass = NA`) |
| 9 | Threshold check: WY decisions reproduced by t_rej | 0 mismatches | = 0 |

Heteroscedastic, no signal (Fig. 12). 16 designs × 20 realisations, B = 100:

| # | Metric | Paper (approx) | Pass rule |
|---|---|---|---|
| 1–4 | FWER: WY, BH, robust WY, robust BH (pooled) | 0.06, 0.03, 0.04, 0.02 | `check_prop`, R_paper = 5000 |
| 5–6 | FWER WY − BH (non-robust; robust) | +0.03 / +0.02 | ≥ 0 |
| 7 | FWER control, robust WY | 0.05 | ≤ 0.05 + 3·sqrt(0.0475/R) = 0.087 |
| 8 | Largest FWER of the four | claim p. 710 ("adequately") | ≤ 0.05 + 3·sqrt(0.0475/R) + 0.02 = 0.107 |

### dbz_riboflavin (Sec. 5.2; n = 71, p = 4088)

| # | Metric | Paper | Pass rule |
|---|---|---|---|
| 1 | Share of 6 CV seeds with no Holm rejection | no rejection (p. 714) | ≥ 0.5 (set after development runs; per-seed counts in the note) |
| 2 | Share of 6 CV seeds with no WY rejection (B = 1000) | no rejection (p. 714) | ≥ 0.5 (same) |
| 3 | Median p_equiv, WY, simulated signal on dsmN71 (6 fits, B = 1000) | 1264 (exact) | within ±25% (≈ ±0.06 in t_rej) |
| 4 | Median p_equiv, BH, same fits [descriptive] | 4088 (exact) | none (`pass = NA`) |
| 5 | Fig. 15, c = 3: share of 10 random columns where WY rejects | "almost all the time" | ≥ 0.75 |
| 6 | Fig. 15, c = 3: WY − Holm rejection share | WY higher | ≥ 0 |
| 7 | Fig. 15, c = 2: WY − Holm rejection share | WY median −log p 6.2, Holm 0 (c = 1.97) | > 0 |

### dbz_hdi_reference (hdi 0.1-10 `tests/test-lasso.R`)

The setup is `x.use = riboflavin x[, 1:16]`, with `RNGversion("3.5.0")` and
`set.seed(3)` before each fit. The statistic is `all.equal`'s mean relative
difference (absolute when the target is 0). A check passes if the statistic
is ≤ the test's tolerance and `all.equal()` is `TRUE`.

| # | Check | Tolerance |
|---|---|---|
| 1 | `pval` equal for x and 2 + 4x | 1.5e-8 |
| 2 | `range(bhat / bhat(2 + 4x) − 4)` equal to (0, 0) | 1.5e-8 (absolute) |
| 3 | CI(x) = 4 × CI(2 + 4x) | 1.5e-8 |
| 4 | `bhat` equal to the 16 hard-coded values | 4e-7 |
| 5 | 95% CIs equal to the hard-coded 16 × 2 matrix | 5e-5 |
| 6 | (SILM addition) `parallel = TRUE` fit equal to the sequential fit | 1.5e-8 |

### Runtime (full run, `--cores 10`)

The estimates come from single-fit timings at full B and from the smoke tests.
The machine is an Apple M1 Max (8 performance + 2 efficiency cores). On it:

* One cross-validated lasso refit costs about 0.10 s (n = 100, p = 500),
  0.055 s (n = 50, p = 250) and 0.18 s (n = 71, p = 4088).
* A WY fit with B = 100 takes 21 s (Toeplitz) and 10.5 s (heteroscedastic),
  or 2.5 s with `boot.shortcut = TRUE`.
* One `Sim.CI` call with a single coefficient and Θ given takes 0.10 s.

With the machine heavily loaded by other jobs (load average above 40), the
same work took 1.2–2 times longer.

| Script | Work | Idle machine | Loaded |
|---|---|---|---|
| `dbz_coverage.R` | 2 × 100 replications × 500 refits, plus 100 × 500 `Sim.CI` calls; Z and Θ once | ≈ 26 min | ≈ 45 min |
| `dbz_hetero.R` | 100 replications × (2 × 300 + 3 × 600 refits); Z once | ≈ 22 min | ≈ 25–35 min |
| `dbz_fwer.R` | 2 × 288 replications × (200 refits + shortcut fit) (p = 500), plus 320 × 400 refits (p = 250); Z for 20 designs | ≈ 35 min | ≈ 55 min |
| `dbz_riboflavin.R` | Z (≈ 3 min), plus 6 seeds × (2000 + 2000 shortcut), 6 × 2000 and 20 × 400 refits, each fit parallel over the cores | ≈ 23 min | ≈ 33 min |
| `dbz_hdi_reference.R` | three fits with p = 16 | < 1 min | < 1 min |
| **Total** | | **≈ 1.8 h** | **≈ 2.6 h** |

Smoke tests (`--scale 0.02 --cores 2`, B ≤ 50, first 300 riboflavin columns),
run with all five scripts in parallel against the current `lib-rep` build and
a machine load average of 40–150: 2.8 min (coverage, including 2 × 500
`Sim.CI` calls), 0.8 min (hetero), 2.1 min (fwer), 1.9 min (riboflavin) and
< 0.1 min (hdi reference). All exited with status 0.

**BLAS threads.** `run.R` starts every script with `OMP_NUM_THREADS=1` and
`OPENBLAS_NUM_THREADS=1` in its environment (`system2(env = ...)`), which
keeps BLAS single-threaded in the script and in its forked `mclapply`
workers. `common.R` also calls `Sys.setenv()`, but that comes too late for a
script started directly with `Rscript`, because OpenBLAS reads the variables
when R starts.

That case matters with Homebrew's OpenMP build of OpenBLAS. A threaded matrix
product in the parent (e.g. `rmvn_design()` with p = 500) followed by a
threaded product in a forked child deadlocks. This was observed before
`run.R` set the variables: the children sat idle in `dgemm -> GOMP_parallel`.
As a fallback, `dbz_targets.R` also sets the OpenMP thread count to 1 at run
time (`dbz_blas_single_thread()`, via libgomp's `omp_set_num_threads_`). This
is a no-op when the environment already requests one thread.
