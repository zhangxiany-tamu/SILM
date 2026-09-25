# SILM 2.0.0 revival: phased implementation plan

## 0. Summary

**Deliverable.** A self-contained GPL-3 package, `SILM` 2.0.0, at github.com/zhangxiany-tamu/SILM. It has no compiled code and imports only `glmnet`, `lars`, `MASS`, `parallel` and `stats`. It provides:

1. `SR`, `ST`, `Sim.CI` and `Step`, kept faithful to 1.0.0 with fixes. The nodewise tuning is now explicit and defaults to `"ZnZ"`, chosen by the pre-registered defaults study (`validation/calibration/DEFAULTS.md`).
2. `lasso.proj` and `boot.lasso.proj`, exact ports of hdi 0.1-10. Under `set.seed` they return the same numbers and leave the same `.Random.seed`.
   - With `robust = TRUE`, this holds with `robust.divisor = "n"` (hdi's normalisation); the default is `"n-s"` (item 3).
3. The Dezeure–Bühlmann–Zhang (2017, "DBZ") methods that hdi never shipped: simultaneous CIs (eq. 10), group p-values P_G, Mammen multipliers, the xyz-paired bootstrap, and the n − ŝ divisor of the robust s.e. (eq. 5). The divisor is the default (`robust.divisor = "n-s"`, chosen by the defaults study), so with `robust = TRUE` the ports of item 2 equal hdi only with `robust.divisor = "n"`.
4. A four-layer verification stack:
   - a live side-by-side harness against the archived CRAN packages;
   - fixture tests;
   - property tests;
   - pre-registered replication of both papers.

**How principle 6 is applied.** A behaviour counts as a *confirmed bug* in two cases:
- it gives wrong results on inputs that satisfy the documented model assumptions, or
- it contradicts the paper's specification.

Confirmed bugs are fixed by default, and the old behaviour stays available through an explicit argument. Two other cases are handled differently:
- Behaviour that only occurred on inputs that used to **error** can be fixed with no legacy switch, because no prior result exists to reproduce.
- Misuse outside the model assumptions keeps the old default. The package validates or warns, and the correction is opt-in.

Exception: where both options are compatible with the paper, or the old behaviour is what users ran for years, the default is decided by empirical performance (**decision 6**), not by this rule.

| Item | Old behaviour | Class | New default | Exact legacy |
|---|---|---|---|---|
| Nodewise λ in SR/ST/Sim.CI/Step/Theta.hat | Z&Z (hdi ≥ 0.1-7 changed a default under SILM) | Contradicts ZC paper Sec 5 ("10-fold CV"), but the default is decided by empirical performance (pre-registered defaults study, `validation/calibration/DEFAULTS.md`; results in `defaults-results/REPORT.md`, TODO-DEFAULTS-NUMBERS) | `nodewise = "ZnZ"` (= SILM 1.0.0 + hdi 0.1-7..0.1-10; selected by the study's decision rule, calibration first, then power: TODO-DEFAULTS-NUMBERS) | `nodewise = "cv"` (= SILM 1.0.0 + hdi 0.1-6, the paper's tuning); the default itself reproduces 2019–2026 |
| `lasso.proj(family="binomial")` intercept | Mean-centring of the IRLS working data | Bug on valid inputs (bias −0.67, 0% coverage) | Project out sqrt(w) | `legacy = TRUE` |
| ST studentized decision string | `"rejct"` | Bug | `"reject"` | `legacy = TRUE` |
| ST screening size when k = n0−1−\|set1\| = 0 | `1:0` keeps 1 extra variable (\|B\| = n0) | Contradicts paper (\|B\| = \|D2\|−1) | Keep none | `legacy = TRUE` |
| ST when G ∩ S = ∅ | −Inf statistic plus 2M+2 warnings | Contradicts paper Sec 3.2 (T = 0) | Statistic 0 and one warning; RNG burned so the stream is unchanged | `legacy = TRUE` (−Inf, no warnings) |
| Uncentred X / Y | Used raw | Outside the model assumptions (paper assumes mean-zero X, no intercept) | `center = FALSE` plus a calibrated warning | `center = TRUE` opt-in (**decision 1**) |
| Step when every hypothesis is rejected | Wasted pass and up to 2M warnings; results correct | Cosmetic | Guard with RNG burn (identical results and seed) | n/a |
| ST empty lasso set; ST k < 0; `drop` bug; constant columns; bad inputs | Errors | Error path only | Fixed or informative error | n/a |
| hdi `parallel=TRUE` (fold draws in forks) | Not reproducible | Bug | Pre-drawn fold ids, identical to hdi's sequential run | n/a |
| Robust s.e. divisor in lasso.proj/boot.lasso.proj (`robust = TRUE`) | 1/n (hdi; DBZ Sec 3.3.2) | Paper-compatible either way (DBZ eq. 5 uses n − ŝ); default decided by empirical performance (defaults study, `validation/calibration/DEFAULTS.md`, TODO-DEFAULTS-NUMBERS) | `robust.divisor = "n-s"` (eq. 5, original and bootstrap s.e.) | `robust.divisor = "n"` (= hdi 0.1-10) |
| Documented hdi quirks: type-7 confint quirk, df n−ŝ−1, homoscedastic WY covariance, (2c+1)/(B+1), shortcut interpolation, numeric-betainit scale, user-σ asymmetry | — | Not bugs, or paper-compatible | hdi behaviour, documented; warnings on the traps | — |

**Resolved decisions (2026-09-24):**
1. `center = FALSE` is the default for SR/ST/Sim.CI/Step, with a calibrated one-time warning on clearly uncentred data. `center = TRUE` is opt-in.
2. Sun & Zhang are cited (Description, Rd, CITATION, README, `inst/COPYRIGHTS`). Tingni Sun is **not** listed in Authors@R, because no scalreg code is included.
3. Version **2.0.0** (see §B).
4. The provenance commit is not backdated; its message records the source URL and sha256.
5. The dev libraries live in the cache directory. The user's global R library (glmnet 4.1-10) is never modified. The harness uses the current CRAN glmnet (5.1 at the time of writing) from `lib-glmnet-5.0`.
6. Each default is the option with the better empirical performance, as decided by the pre-registered defaults study (`validation/calibration/DEFAULTS.md`; results in `validation/calibration/defaults-results/REPORT.md`, TODO-DEFAULTS-NUMBERS); the rows of the table above say which defaults it changed. The previous behaviour stays available through the argument, and the equivalence harness and the fixture tests pass the old value explicitly.

---

## A. Repository and package skeleton

### A.1 Layout (every R file under 400 lines; line estimates in brackets)

```
SILM/
├── DESCRIPTION  NAMESPACE (roxygen)  NEWS.md  README.md
├── LICENSE.md (full GPL-3 text, .Rbuildignore'd, for GitHub detection)
├── .Rbuildignore  .gitignore  cran-comments.md
├── R/
│   ├── SILM-package.R      [60]  package doc, all @importFrom
│   ├── SR.R                [90]  export SR()
│   ├── ST.R               [160]  export ST() orchestrator
│   ├── Sim_CI.R           [110]  export Sim.CI()
│   ├── Stepdown.R         [130]  export Step()
│   ├── theta_hat.R         [80]  export Theta.hat(); .silm_theta()
│   ├── core_fit.R         [150]  .silm_fit() (verbatim arithmetic), .silm_boot_max()
│   ├── core_validate.R    [200]  .check_Xy(), .check_set(), .check_M_alpha(), .silm_center(), .warn_uncentred()
│   ├── st_screen.R        [140]  .st_split(), .st_screen(), .standardize_unitnorm(), .st_core() (fit once, test many)
│   ├── scaled_lasso.R     [110]  .scaled_lasso(), .lam0_quantile()
│   ├── nodewise_api.R     [150]  .nodewise(x, what, do_znz, foldid, ...), calculate.Z()
│   ├── nodewise_tuning.R  [200]  nodewise.getlambdasequence, cv.nodewise.bestlambda, cv.nodewise.err.unitfunction, cv.nodewise.totalerr
│   ├── nodewise_znz.R     [110]  improve.lambda.pick, calcM, calcMforcolumn
│   ├── nodewise_final.R   [140]  score.getThetaforlambda (oldschool arithmetic), score.getZforlambda(.unitfunction), score.rescale
│   ├── parallel_utils.R    [90]  .silm_mapply(), .draw_foldids(), .burn_rnorm()
│   ├── hdi_prepare.R      [150]  prepare.data, switch.family (+ projection fix)
│   ├── hdi_initial_fit.R  [180]  initial.estimator, do.initial.fit(foldid=)
│   ├── hdi_desparsified.R [120]  despars.lasso.est, est.stderr.despars.lasso, sandwich.var.est.stderr
│   ├── hdi_wy.R            [70]  p.adjust.wy
│   ├── lasso_proj.R       [200]  export lasso.proj()
│   ├── boot_lasso_proj.R  [250]  export boot.lasso.proj() orchestrator
│   ├── boot_validate.R    [120]  argument conflicts, early errors
│   ├── boot_resample.R    [160]  resample() (+multiplier), .rmammen(), .xyz_hats(), .xyz_index()
│   ├── boot_refit.R       [220]  boot.initial.fit (pre-drawn folds, two-phase fallback), boot.se, .compute_cbootdist(), .xyz_draw()
│   ├── boot_inference.R   [160]  .boot_pval(), .boot_wy(), .boot_padjust(), .boot_summaries()
│   ├── methods_confint.R  [200]  confint.silm_proj (individual = hdi verbatim; simultaneous)
│   ├── methods_print.R    [120]  print.silm_proj
│   └── group_test.R       [120]  groupTest() generic + silm_boot_lasso_proj method
├── inst/CITATION  inst/COPYRIGHTS
├── man/ (roxygen, markdown)
├── tests/testthat.R, tests/testthat/{helper-sim.R, helper-fixtures.R, test-*.R, fixtures/*.rds}
├── vignettes/SILM.Rmd
├── dev/DESIGN.md                   (.Rbuildignore'd: principle-6 table, RNG sequences, xyz resolutions)
├── validation/                     (.Rbuildignore'd) harness, fixtures generator, bench/
├── replication/                    (.Rbuildignore'd) CRITERIA.md, scripts, REPORT.md, results/
└── .github/workflows/{r.yml, equivalence.yml, coverage.yml}
```

Naming. Vendored hdi helpers keep their hdi names (all internal, `@noRd`), so a line-by-line diff against hdi stays reviewable. New internals use the `.silm_*` or `.xyz_*` prefix. The exported file names `SR.R`, `ST.R`, `Sim_CI.R` and `Stepdown.R` are kept so `git log --follow` keeps working.

### A.2 DESCRIPTION

```
Package: SILM
Title: Simultaneous Inference for High-Dimensional Linear Models
Version: 1.0.0.9000            # 2.0.0 at release
Authors@R: c(
  person("Xianyang", "Zhang", role = c("aut","cre"), email = "zhangxiany@stat.tamu.edu"),
  person("Guang", "Cheng", role = "aut"),
  person("Jincheng", "Bai", role = "aut"),
  person("Ruben", "Dezeure", role = c("ctb","cph"), comment = "hdi nodewise, lasso.proj and bootstrap code"),
  person("Lukas", "Meier", role = c("ctb","cph"), comment = "hdi code"),
  person("Nicolai", "Meinshausen", role = c("ctb","cph"), comment = "hdi code"),
  person("Martin", "Maechler", role = c("ctb","cph"), comment = "hdi code"),
  person("Peter", "Bühlmann", role = c("ctb","cph"), comment = "hdi code"))
Description: Simultaneous inference for high-dimensional linear models: the
  bootstrap-assisted de-sparsified Lasso procedures of Zhang and Cheng (2017)
  <doi:10.1080/01621459.2016.1166114> (simultaneous intervals, support recovery,
  screening-based tests, step-down FWER control), and the bootstrapped
  de-sparsified Lasso of Dezeure, Bühlmann and Zhang (2017)
  <doi:10.1007/s11749-017-0554-2> with residual, multiplier-wild and xyz-paired
  bootstraps, simultaneous confidence intervals, group tests and Westfall-Young
  adjustment. Includes 'lasso.proj()' and 'boot.lasso.proj()' reproducing the
  archived 'hdi' package, and a scaled Lasso following Sun and Zhang (2012)
  <doi:10.1093/biomet/ass043>.
License: GPL-3
Copyright: See file COPYRIGHTS
URL: https://github.com/zhangxiany-tamu/SILM, https://zhangxiany-tamu.r-universe.dev/SILM
BugReports: https://github.com/zhangxiany-tamu/SILM/issues
Depends: R (>= 4.1.0)
Imports: glmnet (>= 4.1), lars, MASS, parallel, stats
Suggests: testthat (>= 3.0.0), withr, knitr, rmarkdown
VignetteBuilder: knitr
Config/testthat/edition: 3
Encoding: UTF-8
Roxygen: list(markdown = TRUE)
RoxygenNote: 8.0.0
```

The R version floor comes from glmnet 5.0, which uses `apply(simplify=)` and so needs R ≥ 4.1.

The NAMESPACE, generated by roxygen, contains:
- `importFrom(glmnet, glmnet, cv.glmnet)`
- `importFrom(lars, lars, predict.lars)`
- `importFrom(MASS, mvrnorm)`
- `importFrom(parallel, mcmapply, mclapply)`
- `importFrom(stats, coef, confint, ecdf, p.adjust, p.adjust.methods, pnorm, predict, qnorm, quantile, rnorm, runif, sd)`
- exports: `SR`, `ST`, `Sim.CI`, `Step`, `Theta.hat`, `lasso.proj`, `boot.lasso.proj` and `groupTest`
- S3 registrations: `print.silm_proj`, `confint.silm_proj` and `groupTest.silm_boot_lasso_proj`

`utils` and `getFromNamespace` are gone.

### A.3 Legal and metadata files

**`inst/COPYRIGHTS`** records three things:
1. **hdi-derived files.** These are `R/nodewise_*.R`, `R/hdi_*.R`, `R/lasso_proj.R`, `R/boot_*.R` and the individual branch of `R/methods_confint.R`. Each entry lists:
   - the source file in hdi 0.1-10 (`helpers.nodewise.R`, `helpers.R`, `lasso-proj.R`, `boot.lasso-proj.R`, `methods.R`; tarball sha256 `15f37a62…9206`);
   - the copyright holders (the five hdi authors; Dezeure authored the nodewise and bootstrap code);
   - the original license, "GPL" (any version), redistributed here under GPL-3;
   - the modifications, per GPL-3 §5a.
   Each such file also carries the same header.
2. **Scaled lasso.** It is an independent implementation of Sun & Zhang (2012 Biometrika 99:879; 2013 JMLR 14:3385). Its algorithmic constants were chosen for numerical agreement with scalreg 1.0.1 (GPL-2-only, © Tingni Sun), and no scalreg code is included.
3. **`.standardize_unitnorm`.** It is an independent base-R helper. No SIS code is included.

**`inst/CITATION`** has a `bibentry()` for Zhang & Cheng (2017), JASA 112(518):757–768, and for Dezeure, Bühlmann & Zhang (2017), TEST 26(4):685–719, with a header saying which functions implement which paper.

**`NEWS.md`** has two sections:
- **`# SILM 2.0.0`**, with subsections:
  - *Revival and dependencies*: archived 2026-07-10 because scalreg was archived; scalreg, hdi and SIS removed.
  - *Reproducibility*: the `nodewise` argument, with this history. SILM 1.0.0 was published 2019-01-09 against hdi 0.1-6 and used the 10-fold-CV `lambda.min`. hdi 0.1-7 (2019-03-29) added `do.ZnZ = TRUE` as the default of an internal function SILM called, so from then until archival SILM silently used Z&Z and ignored `lambdatuningfactor = 1`. The default `"ZnZ"` reproduces that behaviour; `"cv"` reproduces hdi 0.1-6 (not breaking; see decision 6).
  - *ST fixes*, with the `legacy` argument.
  - *New functions (hdi-identical)*.
  - *New methods (SILM additions)*.
  - *lasso.proj binomial fix*.
  - *Performance*: bit-identical.
  - *Documentation*.
- **`# SILM 1.0.0 (2019-01-09)`**: initial CRAN release.

**`.Rbuildignore`** uses KDist's patterns plus `^validation$`, `^replication$`, `^dev$`, `^LICENSE\.md$`, `^cran-comments\.md$` and `^\.github$`. **`.gitignore`** uses KDist's patterns plus `validation/lib/`, `validation/cache/`, `replication/raw/` and `*.Rcheck/`.

---

## B. Git history, tags and version

**Setup (Phase 0).** Keep the working tree in Drive, like your other repositories. Everything bulky or regenerable goes outside Drive under `tools::R_user_dir("SILM-dev", "cache")`: the legacy libraries, replication raw output, check directories and tarballs. Optionally use `git init --separate-git-dir "$HOME/.gitdirs/SILM.git"` so the object store isn't synced.

```sh
git init -b main
git remote add origin https://github.com/zhangxiany-tamu/SILM.git
```

**Commit sequence.** Conventional Commits; every commit after #4 must leave the harness green.

| # | Commit | Content |
|---|---|---|
| 1 | `chore: import SILM 1.0.0 as published on CRAN` | Verbatim tarball contents including `MD5` and the CRAN DESCRIPTION fields. Message records the URL, sha256 `e6260ae5…51c5` and the equivalent `cran/SILM` commit `6a0fada6`. Author date `2019-01-09T17:50:36Z` (import noted in the message). Tag `v1.0.0`. |
| 2 | `build: modernize package metadata` | Authors@R, drop MD5 and CRAN fields, `.Rbuildignore`, `.gitignore`, `LICENSE.md`, `NEWS.md` stub. |
| 3 | `docs: convert Rd to roxygen2 markdown` | Same content, now roxygen-generated. |
| 4 | `test: add equivalence harness against archived CRAN packages` | `validation/`. First run: repo HEAD (still depending on hdi/scalreg, installed into the legacy lib) vs archived SILM gives E0. This is the harness self-test. |
| 5 | `feat: add scaled lasso implementation (Sun & Zhang 2012, 2013)` | `scaled_lasso.R` plus tests; harness A1 E0. |
| 6 | `chore(vendor): add hdi 0.1-10 helpers.nodewise.R verbatim` | Verbatim file with header only. |
| 7 | `refactor(nodewise): split vendored helpers, explicit do_znz/foldid, drop unreachable branches` | Harness A3 E0. |
| 8 | `refactor: remove scalreg, hdi and SIS dependencies` | Core now self-contained with **ZnZ** hard-wired, so it equals what users ran in 2019–2026 (E0 vs the legacy-znz lib). |
| 9 | `feat!: add nodewise argument; default to paper's 10-fold CV lambda` | `BREAKING CHANGE:` footer. E0 in both modes. (Default later changed to `"ZnZ"` by the defaults study, decision 6.) |
| 10–15 | `fix(ST): …` (one per fix), `fix(Step): …`, `feat: input validation`, `feat: center argument`, `feat: Theta argument and Theta.hat()` | Each with regression tests. |
| 16 | `perf: hoist Theta %*% t(X) out of bootstrap loops` | Bit-identical, E0. |
| 17 | `chore(vendor): add hdi 0.1-10 lasso.proj, boot.lasso.proj and helpers verbatim` | |
| 18–22 | `feat: export lasso.proj and boot.lasso.proj`, then `refactor(hdi): …` (splits, `.silm_mapply`, pre-drawn folds, early validation), `feat: SILM result classes and methods`, `fix(lasso.proj): project out sqrt(w) for binomial` | Harness C/D E0 at each step. |
| 23–26 | `feat(boot): simultaneous CIs (eq. 10)`, `feat(boot): group p-values`, `feat(boot): Mammen multipliers`, `feat(boot): xyz-paired bootstrap` | |
| 27+ | `test: fixtures…`, `docs: README, vignette…`, `ci: …`, `test(replication): …` | |
| last | `chore(release): SILM 2.0.0` | Tag `v2.0.0`, then `gh release create`. |

**Pushing.** Push commits 1–3 right away (provenance). Push the rest to `main` at the end of each phase, after a local check passes. Workflows are added in Phase 2, once the package installs without archived dependencies.

**Why v2.0.0.** Semver is judged against what users actually experienced:
- the default output of all four core functions changes relative to 2019–2026 installs (Z&Z → CV);
- ST's outputs change (`"reject"`, 0 statistic);
- the package scope grows substantially (hdi's methods absorbed, new classes).

The counter-argument for 1.1.0 is that `"cv"` restores 1.0.0 *as released*. It loses to the seven years of Z&Z behaviour users actually saw.

*Update (defaults study):* the nodewise default is now `"ZnZ"`, so the first point no longer applies; the other two still justify 2.0.0.

---

## C. Implementation phases and function specifications

### Phase map (effort in engineer-days)

| Phase | Content | Depends on | Effort |
|---|---|---|---|
| 0 | Environment, oracles, calibration | — | 1 |
| 1 | Provenance and skeleton (commits 1–3) | 0 | 0.5 |
| 2 | Self-contained core: scaled lasso, standardize, vendored nodewise, ZnZ parity, then `nodewise` arg; fixtures; CI | 1 | 3 |
| 3 | Core fixes, validation, `center`, `Theta` | 2 | 2 |
| 4 | Core performance (profile first) | 3 | 1 |
| 5 | hdi port (exact) | 2 (nodewise, scaled lasso) | 4 |
| 6 | DBZ additions | 5 | 4 |
| 7 | Docs, README, vignette, NEWS, CITATION | 3, 6 | 2 |
| 8 | Paper replication (compute in background during 6–7) | 4, 6 | 2 (+ about 5 h compute) |
| 9 | Release: as-cran check, R-universe, tag | all | 1 |

### Phase 0: environment and oracles

1. `install.packages(c("lars", "covr", "pak"), repos = "https://cloud.r-project.org")`.
2. Snapshot glmnet 4.1-10 into `<cache>/lib-glmnet-4.1-10`, then upgrade the user library to glmnet 5.0 (the CRAN version CI and users get). The harness runs once under each version to confirm the "bit-identical gaussian" NEWS claim.
3. Run `Rscript validation/setup_legacy_libs.R` (see D.1). It builds `<cache>/lib-legacy-znz` and `<cache>/lib-legacy-cv`.
4. Smoke test: old `SILM::SR` and `hdi::lasso.proj` run in callr children.
5. Calibrate the runtime estimates with `validation/bench/calibrate.R`. Measured today with `OPENBLAS_NUM_THREADS=1`:

   | Data | glmnet path fit | Fixed-λ fit | cv.glmnet | Nodewise (cv) | Z&Z extra |
   |---|---|---|---|---|---|
   | 100×500 | 12 ms | 8 ms | 71 ms | about 52 s | about 6 s |
   | 71×4088 (riboflavin) | | | 170 ms | about 11 min | |
   | 50×250 | | | 45 ms | about 10 s | |
   | 80×79 (ST reduced model) | | | | about 14 s | |

### Phase 2: shared internals

**`.scaled_lasso(X, y)`** is written from Sun & Zhang plus this functional spec. The engineer writes it from this spec; the harness is the check (A1: `identical()` coefficients and `hsigma` vs `scalreg::scalreg`).

- **Input handling:** `X <- as.matrix(X)`, `y <- as.numeric(y)`.
- **lam0:**
  - If p > 1e6, use the universal value `sqrt(2*log(p)/n)`.
  - Otherwise use the quantile rule. Solve for `L` by the damped fixed point: start `L = 0.1`, `Lold = 0`; while `abs(L - Lold) > 0.001`: `k = L^4 + 2*L^2`, `Lold = L`, `L = -qnorm(min(k/p, 0.99))`, `L = (L + Lold)/2`. If p == 1, `L = 0.5`. Then `lam0 = sqrt(2/n)*L`.
- **Lasso path:** `lars(X, y, type = "lasso", intercept = FALSE, normalize = FALSE, use.Gram = FALSE)`.
- **σ iteration:** start `sigmaint = 0.1`, `sigmanew = 5`, `flag = 0`. While `abs(sigmaint - sigmanew) > 1e-4 & flag <= 100`:
  - `flag = flag + 1`;
  - `sigmaint = sigmanew`;
  - `lam = lam0*sigmaint`;
  - `hy = predict.lars(fit, X, s = lam*n, type = "fit", mode = "lambda")$fit`;
  - `sigmanew = sqrt(mean((y - hy)^2))`. Use `mean()`, not `sum()/n`: it is not bit-identical.
- **Return value:** coefficients from `predict.lars(..., s = lam*n, type = "coefficients", mode = "lambda")$coef`, which is λ from the previous iterate. Also return `hsigma = sigmanew`, `lam0`, `iterations`, and `converged`.
- **Non-convergence:** add a warning when the loop hits the 101-iteration cap. This is new; the values are unchanged.

**`.standardize_unitnorm(X)`.** Centre with `colMeans`, then divide by `sqrt(apply(Xc, 2, crossprod))`. Do not use `colSums(Xc^2)`, which differs at about 1e-17. Checked with `identical()` against `SIS::standardize` in A2, including n×0 input and NaN for constant columns.

**Nodewise API** (one entry point for all six exported methods):
- `.nodewise(x, what = c("Theta","Z"), do_znz, K = 10L, foldid = NULL, parallel = FALSE, ncores = 1L, verbose = FALSE)` returns `list(out, bestlambda, lambdas, lambda.min, foldid)`.
- The internal sequence is: grid (`nodewise.getlambdasequence`, deterministic) → the **only** RNG draw, `if (is.null(foldid)) foldid <- sample(rep(1:K, length = n))`, taken at hdi's position → pooled CV → `if (do_znz) improve.lambda.pick else lambda.min * 1` → final `Theta` or `Z`.
- `do_znz` is a *required* argument with no default, so an upstream default can never again change results silently.
- Callers pass `x` untouched. SILM core passes raw or centred X; `lasso.proj` passes `prepare.data` output.
- Dead code dropped: the `oldschool` CV and Z loops, `lambdaseq = "linear"`, `cv.nodewise.stderr` and `nodewise.getlambdasequence.old`.
- `score.getThetaforlambda` keeps its arithmetic verbatim: `C %*% solve(diag(T2))` and the `oldtausq` T2 formula. Its per-column loop may run under `.silm_mapply`, which gives identical columns because no RNG is involved.
- Messages print only when `verbose = TRUE`.

**`parallel_utils.R`:**
- `.silm_mapply(FUN, ..., MoreArgs, parallel, ncores)`: uses `mapply` if `!parallel`, `ncores <= 1` or on Windows (with a one-time warning there); otherwise `mcmapply`. It always unnames the output.
- `.draw_foldids(n, B, K = 10)`: `lapply(seq_len(B), function(b) sample(rep(seq(K), length = n)))`.
- `.burn_rnorm(k, chunk = 2^20)`: sequential `rnorm` calls whose total is k. This leaves the same `.Random.seed` as one `rnorm(k)` or as `k/n` calls of `rnorm(n)`.

### SILM core exported functions

All four keep their existing positional arguments; new arguments are appended.

```r
SR(X, Y, nodewise = c("ZnZ", "cv"), center = FALSE, Theta = NULL,
   parallel = FALSE, ncores = getOption("mc.cores", 2L))
Sim.CI(X, Y, set, M = 500, alpha = 0.95, nodewise = c("ZnZ", "cv"), center = FALSE,
       Theta = NULL, parallel = FALSE, ncores = getOption("mc.cores", 2L))
Step(X, Y, M = 500, alpha = 0.05, nodewise = c("ZnZ", "cv"), center = FALSE,
     Theta = NULL, parallel = FALSE, ncores = getOption("mc.cores", 2L))
ST(X.f, Y.f, sub.size, test.set, M = 500, alpha = 0.05, nodewise = c("ZnZ", "cv"),
   center = FALSE, legacy = FALSE, parallel = FALSE, ncores = getOption("mc.cores", 2L))
Theta.hat(X, nodewise = c("ZnZ", "cv"), center = FALSE, parallel = FALSE,
          ncores = getOption("mc.cores", 2L))
```

`Theta.hat` returns the Θ̂ that SR, Sim.CI and Step would use, with attributes `"method"` (`"inverse-gram"` or `"nodewise"`) and `"lambda"`. It exists so the three functions can share one Θ̂ (today each draws its own CV folds), for speed, and so the bootstrap code can be tested with Θ injected.

**Kept verbatim** (the same expression text, so floating point matches exactly):
- `Gram <- t(X)%*%X/n`
- `if (p > floor(n/2))` for the nodewise-vs-`solve(Gram)` branch
- `sigma.sq <- sum((Y-X%*%beta.hat)^2)/(n-sum(abs(beta.hat)>0))`
- `beta.db <- beta.hat+Theta%*%t(X)%*%(Y-X%*%beta.hat)/n`
- `Omega <- diag(Theta%*%Gram%*%t(Theta))*sigma.sq`
- the `stat.*` expressions, quantile calls, band construction, and output names and order

These live in `.silm_fit()` and `.silm_boot_max()`; each call site keeps its exact expression form. For example, Sim.CI uses `max(abs(xi)/sqrt(Omega[set]))` and ST uses `max(abs(xi/sqrt(Omega[index])))`.

**Bootstrap loops: RNG preserved and bit-identical.** The old code evaluates `((Theta[set,] %*% t(X)) %*% e) * sqrt(sigma.sq) / sqrt(n)` on every draw. The new code computes `A <- Theta[set, , drop = FALSE] %*% t(X)` once, then per draw runs `e <- rnorm(n); xi.boot <- A %*% e * sqrt(sigma.sq)/sqrt(n)`.
- `A` is the same dgemm on the same inputs, and `A %*% e` is the same dgemv as before, so results are bit-identical.
- The per-draw `rnorm(n)` order is unchanged.
- Step computes `A_eta` once per step-down pass. ST computes `A` for `index` once.
- The fully vectorised `A %*% matrix(rnorm(n*M), n, M)` uses the same RNG stream but a different BLAS kernel, so it is **not** adopted by default. It becomes a Phase-4 candidate only if the harness shows E0 on both OpenBLAS (macOS) and reference BLAS (Ubuntu).

**Fixes and validation (all in `core_validate.R`).** Validation never rejects an input that SILM 1.0.0 processed successfully; the boundary cases are in the harness grid.
- **`.check_Xy`:**
  - convert a data.frame to a matrix;
  - require numeric data, no NA, and `nrow(X) == length(Y)`;
  - keep `Y` exactly as passed if it is a numeric vector or an n×1 matrix, because dimnames propagate into the outputs.
- **Nodewise branch:** error with the column names if any column has zero variance (previously a glmnet "y is constant" crash).
- **`solve(Gram)` branch:** wrap in `tryCatch` and rethrow with the aliased columns from `qr(X)$pivot`. No pre-check by rank tolerance, because that could reject designs `solve()` accepts. Document that β̆ is then no-intercept OLS.
- **Sim.CI:**
  - `set` must be indices in 1:p or a logical vector of length p;
  - `alpha` must be in (0,1), with a warning when `alpha < 0.5` saying that it is the confidence level here;
  - `M` must be a positive integer.
- **Step:** after `eta <- eta[rej.nst]`, if `length(eta) == 0` then `.burn_rnorm(n*M)` and stop. Do the same for `eta2`. Values and `.Random.seed` stay identical, with zero warnings.
- **`center = TRUE`:** centre X and Y. In ST, centre within D1 (before `cv.glmnet(intercept = FALSE)` and screening) and within D2 (the reduced model) separately.
- **`center = FALSE`:** run `.warn_uncentred()`. It warns once if `max_j |mean(X_j)|/sd(X_j) > 2*sqrt(2*log(2p)/n)` or `|mean(Y)|/sd(Y) > 3/sqrt(n)`.
- **`Theta` supplied:** check it is p×p. Document that the nodewise fold draw is then skipped, so the RNG stream differs from a `Theta = NULL` call.

**ST algorithm (both modes unless noted):**
1. Keep verbatim: `n0 <- n - floor(n1)` and `S1 <- sample(1:n, floor(n1), replace = FALSE)`. A `sub.size` in (0,1) is read as a proportion, `floor(sub.size*n)`; that input used to error.
2. `X.sub <- X.f[S1, , drop = FALSE]`, then `cv.glmnet(X.sub, Y.sub, intercept = FALSE)`, `cf`, `set1`, `resi` (all verbatim).
3. `a <- setdiff(seq_len(p), set1)`. This equals `(1:p)[-set1]` whenever `set1` is non-empty. Then `beta.m <- t(.standardize_unitnorm(X.sub[, a, drop = FALSE])) %*% resi`.
4. `k <- n0 - 1 - length(set1)`.
   - If `k < 0`, stop with an informative error suggesting a smaller `sub.size` (the paper uses c0 = 1/5 to 1/3). This used to error.
   - Otherwise `sel <- order(abs(beta.m), decreasing = TRUE)[seq_len(min(k, length(a)))]`. With `legacy = TRUE` and `k == 0`, `sel` is the first element (the old `1:0` behaviour).
   - Then `screen.set <- union(a[sort(sel)], set1)`, the original order with no outer `sort()`.
5. Drop D2-constant columns from `screen.set` with a warning (this used to crash).
6. Nodewise on `X <- X.f[-S1, screen.set, drop = FALSE]` (always nodewise), `Gram`, scaled lasso, `sigma.sq`, `test.set.i`, `index`, `Omega`, `beta.db` and the statistics, all verbatim.
7. If `test.set.i` is empty:
   - `legacy = FALSE`: return 0 for both statistics and `"fail to reject"`, issue one warning, then `.burn_rnorm(n0*M)`;
   - `legacy = TRUE`: return `-Inf` and `"fail to reject"` silently, with the same burn.
8. Otherwise run the hoisted bootstrap. The decision string is `"reject"`, or `"rejct"` when `legacy = TRUE`. The return is the same 4-element list with the same duplicated names, and the positional layout is documented.
8. `.st_core()` returns the reduced-model fit so the replication scripts can test several `test.set` values on one split, through the same code path.

### Phase 5: hdi port (exact)

**Signatures.** Hdi's arguments come first, with hdi's order and defaults; new arguments are appended.

```r
lasso.proj(x, y, family = "gaussian", standardize = TRUE, multiplecorr.method = "holm",
           N = 10000, parallel = FALSE, ncores = getOption("mc.cores", 2L),
           betainit = "cv lasso", sigma = NULL, Z = NULL, verbose = FALSE,
           return.Z = FALSE, suppress.grouptesting = FALSE, robust = FALSE,
           do.ZnZ = FALSE, legacy = FALSE)
boot.lasso.proj(x, y, family = "gaussian", standardize = TRUE, multiplecorr.method = "WY",
                parallel = FALSE, ncores = getOption("mc.cores", 2L), betainit = "cv lasso",
                sigma = NULL, Z = NULL, verbose = FALSE, return.Z = FALSE, robust = FALSE,
                B = 1000, boot.shortcut = FALSE, return.bootdist = FALSE, wild = FALSE,
                gaussian.stub = FALSE,
                boot.type = if (wild) "wild" else "residual",   # "residual","wild","xyz"
                multiplier = c("gaussian", "mammen"),           # wild only
                boot.H0c = identical(multiplecorr.method, "WY"),
                groups = NULL)
```

**Procedure:**
1. Vendor the files verbatim (commit 17).
2. Wire them in so the harness reaches E0.
3. Refactor in small commits, re-running the harness after each.

Allowed refactors:
- splitting functions and early validation (error paths only);
- `.silm_mapply` replacing hdi's always-`mcmapply` pattern (same numbers);
- pre-drawn fold ids;
- unnaming hdi's junk colnames;
- gating hdi's messages on `verbose`.

Not allowed: any reordering of floating-point operations. Literal expressions to keep include:
- `sigmahat*sqrt(diag(crossprod(Z)))/nrow(x)` for the original s.e.;
- `outer(sqrt(colSums(Z^2))/nrow(x), sigmahatstar)` for the bootstrap s.e.;
- the count rule `(2c+1)/(B+1)`;
- the WY `(#≥ + 1)/(B+1)`;
- the confint type-1/type-7 test `(alpha/2*B) %% 1 == 0`, including its floating-point quirk;
- `sum(as.vector(coef(glmnetfit, s = lambda)) != 0)`, which counts the intercept.

**RNG order**, as verified by the research:
- **lasso.proj:**
  1. [binomial: FOLD_cv]
  2. FOLD_nw (skipped if `Z` is supplied)
  3. FOLD_cv (cv lasso)
  4. [WY: `mvrnorm(N, 0, crossprod(Z))`, called exactly]
  5. [`!suppress.grouptesting`: `.burn_rnorm(N*p)`, which replaces the dropped `preprocess.group.testing` `mvrnorm`]
  
  Compute `crossprod(Z)` only when WY is used; that saves O(np²) and the p×p memory in the default holm case.
- **boot.lasso.proj:**
  1. FOLD_nw
  2. FOLD_cv
  3. The draw step, depending on the bootstrap:
     - stub: B × `rnorm(p)`;
     - residual: B × `sample(rc, replace = TRUE)`;
     - wild gaussian: B × `rnorm(n)`;
     - Mammen: B × `runif(n)`;
     - xyz: B × `sample.int(n, n, TRUE)`.
  4. `.draw_foldids(n, B)` (cv lasso without shortcut), then pass 1. Pass 1 may run in parallel with the default RNG kind and stays identical to hdi's *sequential* run.
  5. Shortcut fallback: do the RNG-free fits first, then draw fold ids for the flagged b in order, then refit.
  6. p-values.
  7. [H0c: fresh fold ids, then pass 2, reusing `rstar` or `idx`]
  8. WY or p.adjust (hdi's accuracy warning kept verbatim).

**Early validation (error paths only):**
- family must be gaussian, or binomial for lasso.proj;
- `multiplecorr.method` must be `"WY"` or one of `p.adjust.methods`;
- `betainit` must be valid; a numeric betainit needs `sigma` (lasso.proj) and is rejected up front for boot;
- p ≥ 3 unless `Z` is supplied;
- no zero-variance columns;
- `dim(Z) == dim(x)`;
- `B` and `N` must be positive integers, with B ≥ 2.

**New warnings:**
- numeric `betainit` with `standardize = TRUE` and any |sds − 1| > 1e-8: explain that it must be on the standardised scale;
- boot with a user-supplied `sigma`: σ is not propagated into s.e.*;
- `boot.shortcut = TRUE` with the scaled lasso: the shortcut has no effect.

The binomial σ-override warning is suppressed.

**Binomial (lasso.proj).** With `legacy = FALSE`:
- after `switch.family`, project every column of `xw` and `yw` onto the orthogonal complement of `sw = sqrt(w)`, i.e. `v - sw*sum(sw*v)/sum(w)`;
- use `(y - pihat)/diagW` instead of `solve(W, ·)`.

With `legacy = TRUE`, hdi's code runs verbatim, including `solve`. Logical and two-level factor `y` are converted to 0/1 in both modes (hdi errored on these).

**Result objects.**
- **`lasso.proj`** returns hdi's fields in hdi's order: `pval, pval.corr, groupTest = NULL, clusterGroupTest = NULL, sigmahat, standardize, sds, bhat, se, betahat, family, method, call, [Z]`. The NULL placeholders preserve list positions. SILM fields are appended: `robust, multiplecorr.method, legacy, tstat`. The class is `c("silm_lasso_proj","silm_proj")`.
- **`boot.lasso.proj`** returns hdi's fields (`… B, boot.shortcut, lambda, call, [Z], [cboot.dist], [cboot.dist.underH0c]`), followed by:
  - `boot.type, multiplier, robust, gaussian.stub`;
  - `tstat = bproj/se`, the exact hdi expression;
  - `boot.summary = list(max, min, absmax, absmax.H0c)`, B-vectors that are always stored;
  - `group.summary`, `boot.index` (xyz with `return.bootdist` only) and `B.eff`.
  
  The class is `c("silm_boot_lasso_proj","silm_proj")`.

### Phase 6: DBZ additions

These follow `dbz_spec.txt` as corrected by the verifier.

**Mammen multipliers.** `.rmammen(n)`: `s5 <- sqrt(5); ifelse(runif(n) <= (s5+1)/(2*s5), (1-s5)/2, (1+s5)/2)`. It is called inside `resample()` at the position of hdi's `rnorm`, so the Gaussian path stays verbatim. Validation: `multiplier = "mammen"` requires the wild bootstrap; it errors with `gaussian.stub`.

**xyz-paired bootstrap:**
- With `e = rc` and `s2 = sum(e^2)`: `xhat <- x - tcrossprod(e, crossprod(x, e))/s2`, `zhat` likewise, and `yhat <- xhat %*% betalasso + e`. Error if `s2 <= n*.Machine$double.eps`.
- `idx <- replicate(B, sample.int(n, n, TRUE))`.
- Per draw b:
  1. Take rows `idx[, b]` of `xhat`, `y_vec` and `zhat`.
  2. Centre X\*, Y\* and Z\* without rescaling.
  3. `nz <- colSums(zs*xs)/n`, O(np). If any value is ≤ 0 or non-finite, mark the draw invalid.
  4. `zs <- sweep(zs, 2, nz, "/")`.
  5. `do.initial.fit(xs, ys, betainit, lambda, foldid = f_b)`.
  6. `despars.lasso.est`, then `est.stderr.despars.lasso(xs, ys, zs, init$betalasso, init$sigmahat, robust)`.
- The centred pass uses `y_vec = yhat` with truth `betalasso`. The H0c pass reuses the same `idx` with `y_vec = e` and truth 0.
- Invalid draws are excluded from every summary. `B.eff` is reported with a warning, and the p-values use `B.eff`.
- Warn when `robust = FALSE`. With `gaussian.stub`, skip the hats and `idx` entirely so the RNG path matches hdi.

**Simultaneous CIs.** `confint.silm_proj(object, parm, level = 0.95, type = c("individual","simultaneous"), group = NULL, simult.stat = c("maxmin","abs"), ...)`.
- `type = "individual"` is `confint.hdi`'s code verbatim.
- For `"simultaneous"` (boot objects only):
  - **Defaults.** If `parm` is missing and `group` is given, then `parm <- group`. If both are missing, G is all coefficients. `parm` must be a subset of G.
  - **Lookup order.** Use `boot.summary` when G is everything, then `group.summary`, then `cboot.dist[G,]/se[G]`, and otherwise raise an informative error.
  - **maxmin:** `lower = bhat - se*q(M, 1-α/2)` and `upper = bhat - se*q(m, α/2)`, with `qtype` from `(α/2*B) %% 1 == 0`.
  - **abs:** `bhat ∓ se*q(A, 1-α)`, with `qtype` from `(α*B) %% 1 == 0`.
  - The √n on p.693 is treated as a typo and dropped.
  - Warn when `α/2*(B+1) < 5`.
  - Show a one-time message when `boot.type == "residual"`: it is valid for simultaneous inference only under homoscedastic errors. The trigger does not depend on `robust`.
  - Warn for `gaussian.stub` objects.

**Group p-values.** `groupTest(object, group, ...)`:
- `P_G = (sum(M0 >= max(abs(tstat[G]))) + 1)/(B+1)`, using H0c `M0` from the summaries or the stored matrix.
- `group` may be a list, which returns a named vector.
- It requires `boot.H0c = TRUE` (the default under WY) and errors with instructions otherwise.
- There is no adjustment across groups; this is documented.
- On a lasso.proj object it errors, because hdi's closures were not ported.

`groups = list(...)` at fit time precomputes the O(B) summaries per group.

**Printing.** `print.silm_proj` shows:
- method, `boot.type`, multiplier, robust flag and B;
- σ̂;
- the variables significant at 0.05 and 0.01 by `pval.corr`;
- a table of the 10 smallest `pval.corr`;
- one line noting the paper's recommendation (`robust = TRUE, wild = TRUE`) when `robust = FALSE`.

It returns `invisible(x)`.

---

## D. Verification design

### D.1 Live equivalence harness (`validation/`)

**Oracle libraries** are built by `setup_legacy_libs.R` in `tools::R_user_dir("SILM-dev","cache")/lib-*`, with `repos` set explicitly and sha256 checked:

| Library | Contents (archive tarballs, sha256 pinned) | Serves |
|---|---|---|
| `lib-legacy-znz` | scalreg 1.0.1 (`7daea208…`), hdi 0.1-10 (`15f37a62…`), SIS (CRAN) and its dependencies, linprog, lpSolve, lars, SILM 1.0.0 (`e6260ae5…`) | SILM `nodewise="ZnZ"`, `legacy=TRUE`; lasso.proj/boot; scalreg; SIS |
| `lib-legacy-cv` | scalreg 1.0.1, hdi 0.1-6 (`989d4023…`), SIS, SILM 1.0.0 | SILM `nodewise="cv"` |
| `lib-glmnet-4.1-10` | glmnet 4.1-10 | One-off 4.1-10 vs 5.0 identity check |

- glmnet and MASS are **never** installed into the legacy libraries. Old and new code both use the same shared glmnet, and each child asserts `packageVersion("glmnet")`.
- Install order: `lars, linprog, lpSolve, <SIS deps>, SIS` (from CRAN), then `scalreg` → `hdi` → `SILM` via `install.packages(<archive URL>, repos = NULL, type = "source", lib = …)`.
- **Fallback oracle** if hdi 0.1-6 fails to install on R 4.5: hdi 0.1-10's `score.nodewiselasso(do.ZnZ = FALSE)`. The research diff showed this is the only functional difference. The harness also cross-checks 0.1-6 against 0.1-10 with `do.ZnZ = FALSE` whenever both are available.

**Runner** (`run_equivalence.R --tier fast|full --cores 8 [--glmnet-lib path]`):
1. `R CMD INSTALL --library=<tmp-new-lib> .` for the working tree.
2. For each scenario, two `callr::r()` children:
   - old: `libpath = c(legacy_lib, .libPaths())`;
   - new: `libpath = c(new_lib, .libPaths())`;
   - both with `env = c(OPENBLAS_NUM_THREADS = "1", OMP_NUM_THREADS = "1")`.
   
   Scenarios run in parallel with `parallel::mclapply(mc.cores = cores %/% 2)`.
3. Each child sets:
   - `RNGkind("Mersenne-Twister", "Inversion", "Rejection")`, explicitly and never relying on defaults;
   - `set.seed(method_seed)` (data are generated beforehand in the parent with `data_seed = 1000 + k`);
   - the RNGversion("3.5.0") variant: `suppressWarnings(RNGversion("3.5.0"))` then `set.seed(3)`, mirroring hdi's own tests.
   
   Each child returns `list(value, seed_after = .Random.seed, warnings, messages, error, time, versions, La_library(), extSoftVersion()["BLAS"])`.
4. Old and new always use the same R binary. The harness never compares across R versions; archived outputs are regenerated live. R, glmnet, lars and BLAS versions go into `validation/reports/manifest.json`.
5. **`compare.R` normalizations.** Each is whitelisted and has a written justification:
   - drop `call`;
   - drop `class`;
   - lasso.proj: old `groupTest` and `clusterGroupTest` (functions or NULL) vs new NULL;
   - new-only appended fields (compare the hdi prefix and assert `names(new)[seq_along(hdi_names)] == hdi_names`);
   - unname the columns of `cboot.dist` and `cboot.dist.underH0c` (hdi's `mcmapply` USE.NAMES artefact).
   
   Nothing else is normalized. SILM core outputs are compared raw.

   The SILM side of every hdi scenario (groups C and D) is called with `robust.divisor = "n"` (hdi's normalisation) unless the scenario sets it (`validation/scenarios/hdi.R`, including the first call that computes `Z` for the `Z`-supplied configurations); SILM's default is `"n-s"`.
6. **Status per scenario:**
   - `E0`: `identical(norm(old), norm(new))` and `identical(seed_old, seed_new)`;
   - `E1`: `all.equal(tol = 1e-12)` only, which is a FAIL on default paths;
   - `ALLOWED`: an enumerated divergence, with classification recomputed by calling internal helpers with the same seed (e.g. `SILM:::.st_screen()` reports `set1`, `k` and the intersection):
     - ST `legacy = FALSE` differing only by `"reject"` vs `"rejct"`, 0 vs −Inf, or k == 0;
     - `boot.H0c = TRUE` with holm, where only the seed differs;
     - binomial `legacy = FALSE`;
   - `OLD-ERROR`: the old code errored and the new code returns, allowed only for enumerated fixes;
   - `FAIL`.
   
   The report is `validation/reports/equivalence-<date>-<sha>.md` plus `.rds`. It has a row per scenario: id, function, config, seed, status, max absolute difference, seed identical, time old and new. The run exits non-zero on any FAIL.

**Scenario grid.** The fast tier targets 20 minutes or less on a 4-core CI runner; the full tier runs about 2–3 hours on 10 cores.

*A. Unit oracles*

| Id | Comparison | Grid | Fast / Full |
|---|---|---|---|
| A1 | `.scaled_lasso` vs `scalreg::scalreg` (coefficients, hsigma) | n ∈ {20, 50, 100} × p ∈ {1, 5, 40, 100, 300} × design ∈ {iid, Toeplitz 0.9, duplicated column, near-collinear} × y-scale ∈ {1e-3, 1, 1e3} × colnames ∈ {no, yes} | 60 / 360 |
| A2 | `.standardize_unitnorm` vs `SIS::standardize` | Random matrices, including n×1, n×0 and constant columns | 50 / 200 |
| A3 | `.nodewise` vs `hdi:::score.nodewiselasso` (Theta) and `hdi:::calculate.Z` (Z) | 40×30 iid and 60×80 Toeplitz × `do_znz` ∈ {T, F} × seeds; also vs 0.1-6 | 8 / 40 |

*B. SILM core.* Old runs in the matching legacy library; new runs with `nodewise` ∈ {`"cv"`, `"ZnZ"`}. Seeds 1:3 (fast) or 1:20 (full).

| Cell | n | p | Design | s0 / β | Error | Purpose |
|---|---|---|---|---|---|---|
| B1 | 100 | 10 | Toeplitz 0.9 | 3, U(0,2) | t4/√2 | `solve` branch; Rd example; ST screens all columns |
| B2 | 100 | 50 | iid | 3 | Gamma | Boundary p = n/2, solve branch |
| B3 | 100 | 51 | Toeplitz 0.9 | 3 | t4/√2 | Boundary, nodewise branch |
| B4 | 60 | 120 | Toeplitz 0.9 | 3 | t4/√2 | p > n |
| B5 | 100 | 200 | Exchangeable 0.8 | 0 | Gaussian | Global null |
| B6 | 100 | 10 | iid | all β = 4 | Gaussian | Step all-rejected guard (values plus seed E0, no warnings) |
| B7 | = B3 | | | | | Named columns and Y as an n×1 matrix with a column name (dimnames propagation) |
| B8 (full) | 100 | 500 | Toeplitz 0.9 | 3 | t4/√2 | Paper size, seeds 1:3 |

Calls per cell:
- `SR`;
- `Sim.CI(set ∈ {1:3, 4:p, 1:p, 2}, M = 100, alpha ∈ {0.95, 0.99})`;
- `Step(M = 100, alpha ∈ {0.05, 0.10})`;
- `ST(sub.size ∈ {0.2n, 0.3n}, test.set ∈ {(s0+1):p, 3:p}, M = 100, legacy ∈ {TRUE, FALSE})` on B1, B4 and B5 (fast) and all cells (full).

ST edge cells:
- E1: global null, 100×200, `sub = 30` (empty `set1` in about half the cases; old errors);
- E2: 100×500, s0 = 30, U(1,2), `sub = 70` (k ≤ 0);
- E3: the Rd example over 200 seeds, to hit |set1| = p−1 (the `drop` bug);
- E4: `test.set = {j}` with j screened out (empty intersection).

Expected results:
- `legacy = TRUE`: E0 on every input where the old code did not error;
- `legacy = FALSE`: E0 on regular inputs and ALLOWED on the enumerated fix cases.

*C. lasso.proj.* Data: C-a 50×20 iid s0 = 2; C-b 100×60 Toeplitz 0.9 s0 = 3; C-c `riboflavin[, 1:16]`, downloaded from the hdi tarball, under RNGversion("3.5.0") with seed 3.

Configurations:
1. defaults
2. WY
3. WY with `suppress.grouptesting`
4. BH
5. bonferroni
6. none
7. scaled lasso
8. scaled lasso with WY
9. robust
10. robust with WY
11. `standardize = FALSE`
12. `standardize = FALSE` with robust
13. `do.ZnZ`
14. `do.ZnZ` with WY
15. `Z` supplied (from `return.Z`) with holm
16. `Z` supplied with WY and `standardize = FALSE`
17. `return.Z`
18. numeric betainit with `sigma = 1`
19. `sigma = 1.5`
20. `N = 2000` with WY
21. binomial, `legacy = TRUE`
22. binomial with WY, `legacy = TRUE`
23. new `parallel = TRUE, ncores = 2` vs old sequential
24. `verbose = TRUE`

For each, also compare `confint(level ∈ {0.95, 0.8}, parm ∈ {missing, 1:3, names})`. Fast tier: C-a × seeds 1:2. Full tier: C-a and C-b × seeds 1:5, plus C-c. C-c is also checked against the hard-coded reference values in hdi's `test-lasso.R` (tolerance 4e-7 for `bhat`, 5e-5 for the CI), an independent historical oracle.

*D. boot.lasso.proj.* Data: D-a 50×20 Toeplitz s0 = 3 t4; D-b 80×40 iid Gaussian. B = 50 (fast) or 200 (full).

Configurations:
1. defaults (WY, residual, cv)
2. holm
3. BH (small B, to trigger the accuracy warning; compare warning text)
4. wild
5. wild with robust
6. robust
7. scaled lasso
8. scaled lasso with shortcut
9. shortcut with cv
10. `standardize = FALSE`
11. `Z` supplied
12. `return.bootdist` with B = 100, plus `confint` at levels 0.95 and 0.5 (the type-1 path)
13. `return.Z`
14. `gaussian.stub`
15. `gaussian.stub` with holm
16. `sigma` supplied
17. new `parallel = TRUE` with `ncores` ∈ {2, 4} vs old sequential (must be E0)
18. new arguments passed explicitly at their defaults (`robust.divisor` is hdi's `"n"`, as in every C and D scenario; see step 5)
19. `boot.H0c = TRUE` with holm (`pval` and `pval.corr` identical; seed ALLOWED)
20. `wild` with `boot.type = "wild"` explicit
21. shortcut-fallback trigger (n = 15, p = 30, best effort)
22. RNGversion("3.5.0") variant of configuration 1

Fast tier: D-a × seeds 1:2. Full tier: both datasets × seeds 1:3.

**glmnet check.** Run the full tier once with `--glmnet-lib lib-glmnet-4.1-10` and once with 5.0, comparing *old vs old* across versions. Any difference is recorded in `dev/DESIGN.md` and the fixture policy.

### D.2 Fixtures and CI workflows

**`validation/make_fixtures.R`** runs the **archived** packages (in legacy-lib children) on small cases, about 30 files under 1 MB total:
- SILM core: n = 60–100, p ≤ 60, M = 50, both modes, `legacy = TRUE` ST;
- lasso.proj: 8 configurations;
- boot.lasso.proj: 8 configurations with B = 30.

It writes `tests/testthat/fixtures/<id>.rds = list(input_spec, seed, value, seed_after, meta)`, where `meta` records R version, RNGkind, glmnet, lars and hdi versions, BLAS, architecture, date and generator commit.

**Seed screening.** A seed is accepted only if its numerical margins are safe, so cross-platform floating-point noise cannot flip a discrete choice:
- the nodewise CV `err.mean` gap between the best and second-best λ exceeds 1e-8 relative;
- the Z&Z `M` values stay more than 1e-8 relative away from `1.25*Mcv`;
- min over (j, b) of |T\*_jb − t_j| exceeds 1e-10;
- bootstrap maxima stay away from the critical values in ST and Step.

**Test policy** (`helper-fixtures.R`):
- Skip exact-value tests with a message if `lars != 1.3` or `glmnet < 4.1-3` (the pre-C++ engine).
- If the platform fingerprint (R x.y, glmnet, lars, BLAS, architecture) matches the fixture, use `expect_identical` on everything, including `seed_after`.
- Otherwise use `expect_equal(tolerance = 1e-8)` on continuous fields and `expect_identical` on discrete fields (index sets, decisions, count-based p-values) and on `seed_after`.
- All fixture tests use `skip_on_cran()`. Structural and property tests run everywhere.
- The lasso.proj and boot.lasso.proj fixtures are run with `robust.divisor = "n"` (hdi's) unless the fixture's `new_args` sets it (`tests/testthat/helper-fixtures.R`).

**Workflows:**
- `.github/workflows/r.yml`: KDist's matrix (Ubuntu release and devel, macOS, Windows) with `error-on: '"warning"'` and `NOT_CRAN: true`. Two extra jobs:
  - Ubuntu release with `args: c("--as-cran","--no-manual")`, `_R_CHECK_CRAN_INCOMING_REMOTE_: false` and `NOT_CRAN: false` (simulates CRAN, where fixtures are skipped);
  - Ubuntu release with glmnet 4.1-10 from the archive (fixture exactness).
- `.github/workflows/equivalence.yml`:
  - triggers: push to `main` on `R/**` or `validation/**` (fast tier), weekly `cron: '0 6 * * 1'` (full tier, which also catches upstream glmnet or lars drift), and `workflow_dispatch` with a tier input;
  - runner: `ubuntu-latest`, R release;
  - `actions/cache` for the legacy libraries, keyed on OS + R version + `hashFiles('validation/setup_legacy_libs.R')`; the archive tarballs are cached too, with `remotes::install_github("cran/hdi@0.1-6")` as a fallback source;
  - the report goes to `$GITHUB_STEP_SUMMARY` and is uploaded as an artifact; the job fails on any FAIL;
  - the jobs that run `B-*-znz` scenarios also run them with `--no-new-args` (nodewise left at its default), so the default `"ZnZ"` itself is checked against lib-legacy-znz;
  - scheduled runs also execute the slow statistical tests (`SILM_SLOW_TESTS=true`).
- `.github/workflows/coverage.yml`: `covr::package_coverage()`. The job fails if total coverage is below 80% or any `R/` file is below 60%. The summary is printed; no Codecov token is needed.

### D.3 Unit and property tests (`tests/testthat/`)

Target: 80% or more coverage, measured with `Rscript -e 'covr::percent_coverage(covr::package_coverage())'`.

- **test-scaled-lasso:**
  - KKT conditions at the returned λ;
  - `hsigma` equals the RMS residual at the final iterate;
  - p == 1;
  - the cap warning;
  - invariance to y column names.
- **test-nodewise:** the Theta and Z shapes; `colSums(Z*x)/n == 1`; `do_znz` λ ≤ CV λ; a supplied `foldid` gives the same result as a seeded draw; parallel equals sequential (`skip_on_os("windows")`); exactly one `sample.int` draw (check `.Random.seed` against a manual `sample(rep(1:10, length = n))`).
- **test-SR / SimCI / Step / ST:**
  - output structure and names;
  - validation errors, one test per rule;
  - `alpha < 0.5` warning in Sim.CI;
  - length-1 `set`;
  - Step all-rejected: no warnings, seed identical to a manual burn;
  - ST regressions: global null does not error; `sub.size = 0.3` works; |set1| = p−1; k == 0 with `legacy = FALSE` gives |S| = n0−1; the empty intersection gives 0 and one warning (and −Inf with `legacy = TRUE`); `legacy = TRUE` returns `"rejct"`;
  - `center = TRUE`: invariant to shifting X and Y by constants;
  - uncentred-data warning fires on shifted data and not on the Rd example seed;
  - supplying `Theta = Theta.hat(X)` matches the internal computation.
- **test-lasso-proj:**
  - hdi field order;
  - NULL `groupTest`;
  - the class;
  - confint for lasso.proj;
  - binomial fix: n = 1000, p = 5, b0 = −2, β1 = 1.5: |bhat1 − glm MLE| < 0.1 with the fix, bias above 0.3 with `legacy = TRUE` (`skip_on_cran`);
  - numeric-betainit scale warning;
  - burn equivalence: with `suppress.grouptesting = FALSE`, the seed equals that of a manual `rnorm(N*p)`.
- **test-boot-*** (the verifier's corrected ideas):
  - Mammen constants: moments (0, 1, 1, 2) to 1e-14;
  - `rmammen(1e6)`: two-point support; proportion within 4 SE of p_a; RNG accounting equals `runif(n*B)`;
  - Gaussian wild path `identical()` to `r * matrix(rnorm(n*B), n, B)`;
  - `rc[replicate(B, sample.int(n, n, TRUE))]` `identical()` to hdi-style `replicate(B, sample(rc, replace = TRUE))`;
  - xyz identities:
    - `max|crossprod(xhat, rc)|`, `max|crossprod(zhat, rc)|` and `max|yhat − xhat β − rc|` are all < 1e-10 × scale;
    - with the identity index (`idx = 1:n`) and an injected β̂, b\* = β̂ and T\* = 0;
    - after per-draw rescale, `colSums(zs*xs)/n == 1`;
    - the sandwich check uses `init$betalasso`;
    - Z-scaling invariance is tested on the internal per-draw function with `zhat %*% diag(c)`, not through `calculate.Z`.
  - Simultaneous CIs:
    - a singleton group with maxmin `all.equal` to the individual CI, at level 0.95 (type 7) and at level 0.5 with B = 100 (type 1);
    - nesting: individual CI ⊂ simultaneous CI, and G1 ⊂ G2 implies CI_G1 ⊂ CI_G2, with tolerance;
    - abs variant symmetric about `bhat` (`all.equal`); `qabs ≥ −qmin` checked **only for type 7**;
    - `boot.summary` path equals the full-matrix path within 1e-12.
  - Group p-values:
    - `groupTest(obj, 1:p) == min(obj$pval.corr)` exactly;
    - P_G ≤ min over G of `pval.corr`;
    - values lie on the k/(B+1) grid;
    - numeric, logical and character group specifications give identical results; duplicates and ordering are ignored;
    - a named list returns a named vector;
    - informative error without an H0c bootstrap.
  - Argument conflicts: wild with xyz; Mammen with residual; `boot.H0c = FALSE` with WY; stub with xyz or Mammen; xyz with `robust = FALSE` warns.
  - Memory: with `return.bootdist = FALSE`, no element other than Z has length ≥ p·B.
  - Classes and methods: `inherits(obj, "hdi")` is FALSE; `print` returns invisibly; simultaneous confint on a lasso.proj object errors.
- **Slow statistical tests** (only when `SILM_SLOW_TESTS=true`; weekly CI): n = 100, p = 30, Toeplitz 0.5, 200 replications, B = 200:
  - wild with robust: simultaneous-CI joint coverage (maxmin and abs, G = all) in [0.88, 0.99] under heteroscedastic errors;
  - global null: rejection rate of P_G ≤ 0.05 in [0, 0.10] for G = all and for |G| = 5, under Gaussian and Mammen wild and under xyz with robust.

### D.4 Paper replication (`replication/`, excluded from the build)

**Pre-registration.** `replication/CRITERIA.md` is committed **before** any replication result. Git history proves the order.

**Conventions:**
- Seeding: `set.seed(base + r)` per replication, so results do not depend on core count.
- Parallelism: `mclapply` over replications with `parallel = FALSE` inside and `OPENBLAS_NUM_THREADS=1`.
- Designs are fixed per cell, following "fixed i.i.d. realizations"; X seeds are documented.
- The ZC and DBZ Gaussian cells cache Θ̂/Z per design, since they depend only on X. The folds are therefore fixed within a design. A 50-replication subset recomputes Θ̂ per replication to confirm the difference stays within MC error.
- DBZ data comes from the hdi 0.1-10 tarball (`data/riboflavin.RData`), downloaded to the cache at run time and never shipped.

**Documented modelling assumptions:**
- ZC: β is drawn once per cell.
- DBZ Sec 5.1.3 error mixture: implemented as ε = lζ + (1−l)η. The printed "(l−1)η" gives E ε = 1/2, which contradicts the paper's "maintaining the correctness of the linear model".
- DBZ Q_i: implemented literally with E[Z²] = 13/3. The constant does not affect correctness when β = 0.
- DBZ bootstrap: B = 1000 unless stated otherwise.

**Acceptance rule for proportions.** With SE_c = sqrt(π̄(1−π̄)(1/R + 1/R_paper)), a cell passes if |π̂ − π_paper| ≤ 3·SE_c + δ, where δ = 0.02 covers design realization and software drift. Widths pass if |L̂ − L| ≤ max(0.05·L, 3·SE_L). A table passes if at least 90% of its cells pass, no cell misses by more than twice its tolerance, and all qualitative claims (Q) hold. Failures are reported and investigated; nothing is retuned after the fact.

| Target | Setting | Replications (paper → ours) | Qualitative claims | 10-core wall time | When |
|---|---|---|---|---|---|
| ZC Tables 1–2 (`Sim.CI`, NST/ST; G = S0, S0ᶜ, [p]; 95/99%; EX rows skipped) | n = 100; p ∈ {120, 500}; Toeplitz 0.9 / exchangeable 0.8; s0 ∈ {3, 15}; β U[0,2]; t4/√2 and Gamma; M = 500 | 1000 → 1000 | Q1: S0ᶜ and [p] 95% coverage ≥ 0.92 in every s0 = 3 cell. Q2: cov(S0) < cov(S0ᶜ) in ≥ 80% of cells. Q3: s0 = 15, p = 500, exchangeable, ST [p] coverage < 0.75. | about 15 min | Implementation |
| ZC Table 3 (`SR`: SupRec and Lasso_sc rows) | As above, with β U[2,4] on a random support | 1000 → 1000 | Q4: mean d(SupRec) ≥ d(Lasso_sc) in every cell; FN ≤ 0.2 for s0 = 3. Mean d within ±0.03; FP and FN within max(0.2, 25%). | about 15 min | Implementation |
| ZC Table 4 (`ST` three-step vs one-step via `Sim.CI`) | p = 500; β_j = sqrt(10·log p / n); (i) Toeplitz, c0 = 1/5; (ii) exchangeable, c0 = 1/3; 9 test sets × 2 errors; `.st_core` fits once and tests many | 1000 → 200 (1000 documented) | Q5: three-step size ≤ 0.12 at 5% in (i); three-step power ≥ one-step in ≥ 3 of 4 case-(i) power cells. | about 45 min (about 4 h full) | 200 now; 1000 overnight, optional |
| ZC Table 5 (`Step` NST/ST vs Holm on studentized statistics) | p = 500; Toeplitz / block-diagonal 0.9; s0 ∈ {3, 15} | 1000 → 1000 | Q6: FWER ≤ 0.05 + 3 SE in every cell; step-down power ≥ Holm power − 0.01 in every cell. | about 20 min | Implementation |
| DBZ D1 (Figs 4/5): individual 95% CIs, one X, β U(−2,2), Gaussian | Toeplitz 100×500; lasso.proj vs boot residual non-robust (holm) | 100 → 100 | Mean coverage: boot in [0.940, 0.970] (paper 0.958), original in [0.945, 0.975] (paper 0.963). Worst-decile coverage of boot ≥ original's − 0.02. | about 20 min | Implementation |
| DBZ D2 (Figs 10/11): heteroscedastic Mammen-type model, no signal | n = 50, p = 250; original and boot × robust ∈ {F, T}; plus SILM extras (wild Gaussian, Mammen, xyz; all robust) | 100 → 100 | Robust original mean in [0.94, 0.975] (paper 0.959); robust boot in [0.935, 0.965] (paper 0.951). Non-robust worst-coefficient coverage ≤ 0.85; robust worst ≥ 0.84. Extras mean in [0.93, 0.975]. | about 40 min | Implementation |
| DBZ D3 (Figs 6/13): FWER, power, p_equiv; Gaussian Toeplitz | 6 coefficient types × 2 designs × 50 realizations, B = 200, WY vs Holm | 300 models × 100 → 12 × 50 | Pooled FWER_WY ≤ 0.05 + 3 SE; FWER_Holm ≤ FWER_WY + 0.01; power_WY ≥ power_Holm − 0.01; median p_equiv in [200, 400] (paper about 300). | about 40 min (full about 1.5–2 days) | Reduced now; full documented |
| DBZ D4 (Fig 12): heteroscedastic FWER | 10 designs × 50 realizations, B = 200, WY robust | 50 × 100 → 10 × 50 | FWER ≤ 0.05 + 3 SE | about 15 min | Implementation |
| DBZ D5: riboflavin (Sec 5.2.2) | n = 71, p = 4088; lasso.proj holm; boot WY, B = 1000; seeds 1:3 | — | min(pval.corr) > 0.05 for both methods and all seeds. p_equiv from `absmax.H0c` in [800, 2000] (indicative; paper dsmN71 median 1264). | about 10 min | Implementation |
| DBZ D6: hdi historical oracle | `riboflavin[, 1:16]`, RNGversion 3.5.0, `set.seed(3)` | — | bhat within 4e-7, CI within 5e-5 of hdi's hard-coded values | < 1 min | Implementation |
| dsmN71 p_equiv table (Sec 5.2.1), Fig 15 | Real designs × 6 signal types × 5 seeds × 100 realizations | — | Documented script only | days | Documented |

**Implementation-phase compute budget:** about 5 hours of wall time on 10 cores, run in the background.

**Outputs:**
- `replication/results/*.rds`: per-cell summaries only (raw output goes to the cache);
- `replication/make_report.R` → `replication/REPORT.md`, committed. It contains a pass/fail table per criterion with paper value, our value, SE and tolerance, plus session info, commit SHA and runtimes.

**Commands:**
- `Rscript replication/run.R --target all --profile implementation --cores 10`
- `Rscript replication/make_report.R`

---

## E. Performance: profile first

1. **Profiling.** `validation/bench/profile_*.R` uses `Rprof(interval = 0.01)` and `summaryRprof()` from base R, with no new dependencies, at realistic sizes:
   - SR, Sim.CI and Step at 100×500 with M = 500;
   - ST at 100×500 with `sub = 20`;
   - lasso.proj at 71×4088;
   - boot.lasso.proj at 100×500 with B = 200, for each `boot.type`.
   
   `microbenchmark` is used for micro-optimizations. Results go to `validation/bench/RESULTS.md`.
2. **Expected hotspots and treatment:**

| Hotspot | Treatment | Numerics |
|---|---|---|
| Nodewise CV: about 14p glmnet fits (52 s at p = 500; 11 min at p = 4088) | Parallelize over columns with `.silm_mapply` (no RNG inside); `Theta`/`Z` reuse across calls | Identical |
| Core bootstrap loops, O(M·\|set\|·p·n) | Hoist `A = Θ[set,] %*% t(X)` per call (per pass in Step) | Identical (same dgemm and dgemv) |
| Fully vectorised `A %*% E` | Only if the harness shows E0 on macOS OpenBLAS and Ubuntu reference BLAS | dgemm vs dgemv; harness-gated |
| `C %*% solve(diag(T2))` in Θ construction (O(p³); about 10¹¹ flops at p = 4088) | `sweep(C, 2, 1/T2, "*")` | IEEE-exact in principle; adopt only on harness E0 |
| `diag(crossprod(Z))` (O(np²)) | Keep (hdi literal); `crossprod(Z)` skipped when not WY | Identical |
| `Omega = diag(ΘGΘᵀ)` (O(p³), once) | Keep verbatim (the `rowSums` form differs at 1.6e-15) | — |
| boot refits: B or 2B `cv.glmnet` (142 s at 100×500 with B = 1000 and WY) | Pre-drawn fold ids make `parallel = TRUE` identical to hdi's sequential run; about 7× on 10 cores | Identical |
| WY counting (p×B logical matrix) | Keep hdi's code; the `findInterval` form only if profiling shows >5% and integers are `identical()` | Identical |
| lasso.proj WY `mvrnorm` (eigen, N×p) | Keep exactly (parity) | — |
| xyz per draw, O(np) rescale via `colSums` | Pure R | — |

3. **Rcpp gate.** Rcpp is adopted only if all three hold:
   - the region is at least 30% of end-to-end time at a realistic size;
   - it gives at least a 3× end-to-end speedup;
   - the harness shows E0 on macOS arm64 and Ubuntu x86_64. A 1e-12 tolerance with no discrete changes would need your sign-off.
   
   Rcpp **cannot** help the dominant costs (glmnet and lars fitting, cv.glmnet refits, `mvrnorm` eigen) without breaking exact equivalence, since reimplementing coordinate descent is not bit-identical. After hoisting and parallelism, no remaining region is expected to pass the gate, so the plan keeps `NeedsCompilation: no`. If Rcpp is ever adopted, the consequences are:
   - `LinkingTo: Rcpp`, `NeedsCompilation: yes`, and `src/` patterns in the ignore files;
   - Rtools and Xcode needed for source installs;
   - R-universe builds binaries;
   - building must happen outside the "My Drive" path, because of the space in it.

---

## F. Documentation

**Every export gets:**
- `@param` for each argument;
- a full `@return`:
  - ST's positional layout: `[[1]]` NST statistic, `[[2]]` NST decision, `[[3]]` ST statistic, `[[4]]` ST decision;
  - Step's list of two integer index vectors;
  - Sim.CI's `band.*` as a 2×|set| matrix;
  - the hdi fields plus the SILM fields;
- `@references`: ZC 2017, DBZ 2017, Sun & Zhang 2012 and 2013, van de Geer et al. 2014, Mammen 1993;
- fast `@examples` with `set.seed` and small p (B ≤ 50), with heavier cases in `\donttest{}`;
- `@seealso`.

**Mandatory `@details` content:**
- The model has **no intercept**. X should be column-centred and Y centred, and no column of 1s should be passed. Explain `center`.
- When p ≤ ⌊n/2⌋, Θ̂ = Gram⁻¹, so β̆ is no-intercept OLS.
- The nodewise tuning history, `"cv"` vs `"ZnZ"`.
- Sim.CI's `alpha` is the **confidence level** (0.95), unlike ST and Step.
- Step performs two-sided H₀,j: β_j = 0 (Sec 5.4) with fresh draws at each step.
- ST uses the Sec 5.3 Lasso-plus-residual screening, |B| = |D₂|−1. Recommend a `sub.size` between n/5 and n/3.
- What `legacy` gates.
- The RNG note: results from R < 3.6 need `RNGkind(sample.kind = "Rounding")`.

**lasso.proj and boot.lasso.proj** each get two Rd sections.
- **`\section{Compatibility with hdi 0.1-10}`** covers:
  - which results are identical under `set.seed`, and under which conditions (same glmnet, RNGkind; WY via `mvrnorm` depends on BLAS/LAPACK);
  - that the `groupTest` and `clusterGroupTest` closures are not ported;
  - the classes;
  - that `suppress.grouptesting` now only controls the RNG burn;
  - the binomial fix and `legacy`;
  - the robust-s.e. divisor: n − ŝ by default (`robust.divisor = "n-s"`, DBZ eq. 5); `robust.divisor = "n"` reproduces hdi;
  - the documented quirks (numeric betainit scale, user σ, df n−ŝ−1, type-7 confint, homoscedastic WY covariance, `standardize = FALSE` caveat, `cboot.dist.underH0c` naming).
- **`\section{SILM additions (not in hdi)}`** covers `boot.type`, `multiplier`, `boot.H0c`, `groups`, simultaneous confint and `groupTest`, the validity table (DBZ Theorems 1–3), and the recommendation `robust = TRUE` with `wild = TRUE`.

**Vignette (`vignettes/SILM.Rmd`, under 30 s to build):**
1. Zhang & Cheng methods (SR, Sim.CI, Step, ST, and `Theta.hat` reuse).
2. hdi-compatible lasso.proj and boot.lasso.proj (hdi's robust s.e. with `robust.divisor = "n"`).
3. DBZ additions: simultaneous CIs, P_G, Mammen, xyz.
4. Reproducing old results (`nodewise = "cv"` for SILM 1.0.0 with hdi 0.1-6, `legacy = TRUE`, RNGkind).
5. The relation between Sim.CI (the "ZC approach", which bootstraps only the linear part) and boot.lasso.proj.

**README:**
- badges: R-CMD-check, equivalence, R-universe;
- installation: `pak::pak("zhangxiany-tamu/SILM")`, `remotes::install_github(...)`, and `install.packages("SILM", repos = c("https://zhangxiany-tamu.r-universe.dev", "https://cloud.r-project.org"))`;
- a quick example per function;
- the "hdi-identical" vs "SILM additions" split;
- a migration table from hdi;
- how to cite (`citation("SILM")`);
- acknowledgments: the hdi authors, and Sun & Zhang for the scaled-lasso algorithm.

---

## G. Distribution and final checklist

**R-universe.** Create the repository and registry file:

```sh
gh repo create zhangxiany-tamu/zhangxiany-tamu.r-universe.dev --public -d "R-universe registry"
# packages.json:
[{"package": "SILM", "url": "https://github.com/zhangxiany-tamu/SILM"}]
```

You then install the R-universe GitHub app (https://github.com/apps/r-universe) for the account. After v2.0.0, `"branch": "*release"` can be added so the universe tracks tagged releases.

**Release commands:**

```sh
Rscript -e 'roxygen2::roxygenise()'
Rscript -e 'styler::style_pkg()'
Rscript -e 'testthat::test_local()'
Rscript -e 'rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "warning", check_dir = tempdir())'
git tag -a v2.0.0 -m "SILM 2.0.0"
git push origin main --tags
gh release create v2.0.0 --notes-file <NEWS 2.0.0 excerpt>
```

**Final checklist:**
- [ ] `R CMD check --as-cran`: 0 errors, 0 warnings; the only NOTE is "Package was archived on CRAN", expected for resubmission. Passes locally and on all CI jobs, including devel and the glmnet 4.1-10 job.
- [ ] Equivalence harness full tier: 0 FAIL. Report committed under `validation/reports/`. glmnet 4.1-10 vs 5.0 identity recorded.
- [ ] Fixture tests pass on all four operating systems. Coverage ≥ 80%.
- [ ] `replication/CRITERIA.md` precedes the results in git history. `REPORT.md` committed with every criterion's verdict, and failures explained.
- [ ] Examples each run in under 5 s. Tests run in under 2 min with `NOT_CRAN = false`.
- [ ] `inst/COPYRIGHTS`, file headers, Authors@R, `inst/CITATION` and NEWS all complete.
- [ ] The R-universe build is green, and `install.packages()` from the universe works on a clean library.
- [ ] `cran-comments.md` drafted for a later resubmission (dependency removal; same-cohort precedent HIMA).

---

## H. Risks and mitigations

| Risk | Mitigation |
|---|---|
| WY in lasso.proj depends on `mvrnorm` eigenvectors, and so on BLAS/LAPACK | The harness is always same-machine (old and new share BLAS); fixtures use tolerance plus seed screening; parity conditions documented |
| glmnet version drift (5.0 now, later releases) and FMA or compiler differences | Old and new always share one glmnet in the harness; weekly scheduled harness; fixture metadata and tolerance policy; CI job on 4.1-10 |
| lars 1.2 → 1.3 `eps` change | Fixtures require lars 1.3; exact 2019 reproduction declared out of scope (would also need glmnet 2.0-x and R < 3.6 RNG) |
| hdi 0.1-6 fails to install on R 4.5 | Oracle fallback to hdi 0.1-10 with `do.ZnZ = FALSE` (differences established by code diff); `cran/hdi@0.1-6` GitHub mirror as an alternative source |
| SIS dependency chain (gcdnet, msaenet) fails to compile in the legacy library | gfortran is present locally and on the Ubuntu runner; fallback to an SIS 0.8-x archive; A2 only needs `standardize` |
| Google Drive plus git: sync conflicts, `file (1).R` duplicates, many small files | Caches, legacy libraries, check directories and raw results kept outside Drive; optional `--separate-git-dir`; review `git status` before each commit |
| OpenBLAS threading with forked `mcmapply` (hangs, oversubscription, nondeterminism) | `OPENBLAS_NUM_THREADS=1` in the harness, replication and benchmarks; `parallel = FALSE` default; documented |
| Long bootstrap runtimes | Θ̂/Z caching for fixed designs; parallelism with pre-drawn folds; tiered grids; background runs |
| Replication mismatches from software drift, design realization or unspecified details | Pre-registered tolerance with δ; documented assumptions (A1–A3, the ε-mixture typo, Q_i); report honestly with no post-hoc tuning |
| Windows parallelism (`mc.cores > 1` unsupported) | `.silm_mapply` falls back to sequential with a one-time warning |
| `lasso.proj` masking `hdi::lasso.proj` if both are loaded | Documented (hdi is archived); classes differ, so methods do not collide |
| Licensing | hdi is "GPL", so GPL-3 is fine with credit; scalreg is reimplemented clean-room from the spec above (engineer does not copy scalreg code), verified numerically; SIS not copied |
| `.Random.seed` parity for dropped group-testing draws | Chunked `.burn_rnorm(N*p)` (0.5–1.5 s at p = 4088) instead of `mvrnorm` and its p×p eigen |

---

### Critical files for implementation

Planned files:
- `R/nodewise_api.R` (single nodewise entry point with a required `do_znz` and a `foldid`; basis of both the `"cv"`/`"ZnZ"` parity and the hdi parity)
- `R/scaled_lasso.R` (clean-room scaled lasso; must be `identical()` to scalreg 1.0.1)
- `R/boot_lasso_proj.R` (and `boot_refit.R`, `boot_resample.R`: exact hdi RNG order, pre-drawn folds, the DBZ additions)
- `R/ST.R` (the most fixes and the `legacy` gating)
- `validation/run_equivalence.R` (with `setup_legacy_libs.R` and `compare.R`: the live oracle behind every E0 claim)

Research inputs:
- `dbz_spec.txt`
- the hdi 0.1-10 sources in the same scratchpad directory
- `wn88aadid.output`
- `w23lgtosz.output`


---

# Appendices (research record, 2026-09-23/24)

*Superseded where they conflict with decision 6:* the robust-s.e. default is now `robust.divisor = "n-s"` (applied to the original, bootstrap and xyz standard errors); hdi's 1/n, which the appendices recommend keeping as the default, is `robust.divisor = "n"`.

These appendices hold the verified findings behind the plan. Sources: hdi 0.1-10 and SILM 1.0.0 (CRAN archive), Dezeure, Bühlmann & Zhang (2017, TEST) and Zhang & Cheng (2017, JASA; arXiv:1603.01295).

*Superseded where they conflict with decision 6:* the nodewise default is now `nodewise = "ZnZ"` (the suggested default `"cv"` below is hdi 0.1-6's behaviour, available through the argument).


## Appendix A. RNG sequences of hdi lasso.proj / boot.lasso.proj

Verified by sourcing the hdi 0.1-10 files in memory, tracing base::sample.int and stats::rnorm, in R 4.5.2 with glmnet 4.1-10.

Notation:
- FOLD_nw = the fold assignment in cv.nodewise.bestlambda, sample(rep(1:10, length=n)), which is one sample.int(n, n).
- FOLD_cv = cv.glmnet's `foldid = sample(rep(seq(nfolds), length = N))`, also one sample.int(n, n). This is the only RNG use in cv.glmnet. Passing foldid= gives identical fits and an identical .Random.seed afterwards (verified).
- MV = MASS::mvrnorm(N, 0, crossprod(Z)). It draws exactly rnorm(N*p); the eigen step is deterministic.
- RES = sample(rc, replace=TRUE), i.e. sample.int(n, n, replace=TRUE).
- WILD = rnorm(n). STUB = rnorm(p).
- No RNG in: glmnet(), scalreg/lars, Z&Z (improve.lambda.pick/calcM), the sandwich se, p.adjust, confint. hdi has no internal set.seed.

lasso.proj
1. family="binomial" only: FOLD_cv (switch.family's binomial cv.glmnet).
2. Z=NULL: FOLD_nw, whatever do.ZnZ, verbose or parallel are. The parallel forks only fit glmnet, and results plus the parent RNG state are identical to sequential (verified). If Z is supplied this draw is skipped, so every later draw shifts. For example the cv.glmnet folds change, so results under the same seed differ from a Z=NULL run.
3. betainit="cv lasso": FOLD_cv. "scaled lasso": nothing. Numeric: nothing (needs sigma, otherwise stop() after step 2).
4. multiplecorr.method="WY": MV. Any p.adjust method: nothing.
5. suppress.grouptesting=FALSE (the default): MV (preprocess.group.testing). This runs after every returned value is final; pval, pval.corr, bhat and se were verified identical with TRUE and FALSE, for holm and WY. Only the RNG state after the call differs, by N*p normals.

Resulting sequences:
- Default: FOLD_nw, FOLD_cv, rnorm(N*p).
- WY: FOLD_nw, FOLD_cv, rnorm(N*p) [WY], rnorm(N*p) [group].
- WY + suppress: FOLD_nw, FOLD_cv, rnorm(N*p).
- robust or do.ZnZ: same as the default.
- Binomial: FOLD_cv(binomial), FOLD_nw, FOLD_cv, rnorm(N*p).
- Numeric betainit + sigma, suppressed: FOLD_nw only.

boot.lasso.proj (gaussian only; do.ZnZ is always FALSE)
1. Z=NULL: FOLD_nw.
2. "cv lasso": FOLD_cv. Scaled lasso or numeric betainit: nothing.
3. gaussian.stub=TRUE: B x STUB (column b is draw b), and steps 4-5 are skipped. Otherwise resample: wild=FALSE gives B x RES, wild=TRUE gives B x WILD.
4. First bootstrap pass, b = 1..B in order, in-process when parallel=FALSE:
   - cv lasso without shortcut: one FOLD_cv per b.
   - Scaled lasso: nothing.
   - boot.shortcut with cv lasso: nothing, except a FOLD_cv (plus a message) for any b where the fixed-lambda glmnet leaves n - nnz(incl. intercept) <= 0.
   - Numeric betainit: stop() here, after step 3's draws.
5. multiplecorr.method="WY" (the default):
   - With gaussian.stub: B x STUB again.
   - Otherwise a pass under H0,complete on ystar = rstar. It reuses the same resampled residuals (no new resampling draws) and repeats step 4's per-b draws.
   - Non-WY methods: nothing (maybe an accuracy warning).
- robust, return.bootdist, return.Z and verbose: no RNG.

Resulting sequences (B=1000):
- Default (cv, residual, WY): FOLD_nw, FOLD_cv, 1000 x RES, 1000 x FOLD_cv, 1000 x FOLD_cv, i.e. 3002 sample.int calls.
- holm: FOLD_nw, FOLD_cv, B x RES, B x FOLD_cv.
- wild: FOLD_nw, FOLD_cv, B x rnorm(n), 2B x FOLD_cv.
- shortcut: FOLD_nw, FOLD_cv, B x RES (plus rare fallbacks).
- stub + WY: FOLD_nw, FOLD_cv, 2B x rnorm(p).
- Z supplied: drop FOLD_nw.

parallel=TRUE (ncores > 1, Unix): the draws in steps 4-5 happen in forked children.
- Mersenne-Twister (the default): mclapply's mc.set.seed removes .Random.seed in each child, so children re-seed randomly. Results are NOT reproducible under set.seed: two same-seed runs differed by up to 0.025 in cboot.dist, and the parent stream is not advanced.
- L'Ecuyer-CMRG: reproducible for a fixed ncores, but different for 2 vs 3 cores and different from sequential (verified).
- hdi's own tests use RNGversion("3.5.0") (sample.kind="Rounding"). Matching requires the same RNGkind.

Recipe for an exact port
- Draw the nodewise fold assignment inside the shared nodewise code (or accept a foldid argument).
- Then FOLD_cv for the initial fit, then the n x B resampling matrix in the main process.
- Then draw B foldids with sample(rep(seq(10), length=n)) in b order, immediately before pass 1 and again before the H0c pass. Pass them via cv.glmnet(foldid=).
- Verified: pval, pval.corr, cboot.dist, the H0c distribution and the .Random.seed after the call are all identical to hdi's sequential run, for ncores 1 and 2.
- Shortcut fallback: do the RNG-free fits first, find the b's that need the fallback, draw their foldids in b order, then refit.
- lasso.proj with suppress.grouptesting=FALSE: burn rnorm(N*p) in chunks (e.g. 4096). Verified to leave the same RNG state after the call as hdi's mvrnorm, without the p x p eigen or the N x p memory.

Proposed order for the new (non-hdi) options, to define and test
- Mammen multipliers (wild=TRUE, multiplier="mammen"): B x runif(n), one column per b, mapped to the two-point distribution -(sqrt5-1)/2 w.p. (sqrt5+1)/(2 sqrt5), else (sqrt5+1)/2. This takes the place of B x rnorm(n). multiplier="normal" (the default) keeps hdi's order.
- xyz-paired: B x sample.int(n, n, replace=TRUE) row indices in place of RES, then the same per-b FOLD_cv for pass 1. The H0c pass reuses the same indices, mirroring hdi's reuse of rstar.
- Simultaneous CIs (eq. 10 and the |T*| variant) and group p-values P_G: no RNG; they are functions of T* and T*0.
- Asking for P_G with a non-WY method: run the H0c pass after pass 1, in the same position as hdi's WY pass. pval and pval.corr are unchanged; only the RNG state after the call differs.


### Shared nodewise API

The two current nodewise paths

(a) lasso.proj / boot.lasso.proj
- calculate.Z(x = centred/standardised x, parallel, ncores, verbose, Z, do.ZnZ) calls score.nodewiselasso(x, wantTheta=FALSE, parallel, ncores, cv.verbose=verbose, verbose=FALSE, do.ZnZ=do.ZnZ). do.ZnZ defaults to FALSE in lasso.proj and is always FALSE in boot.lasso.proj; the other defaults are lambdaseq="quantile", oldschool=FALSE, lambdatuningfactor=1.
- Steps: nodewise.getlambdasequence, then cv.nodewise.bestlambda (mapply/mcmapply; exactly one FOLD_nw draw), then lambda.min (or Z&Z), then score.getZforlambda with oldschool=FALSE.
- The Z step: mapply of glmnet(x[,-i], x[,i]) with residuals from predict(newx, s=lambda), intercept included. Then score.rescale so that Z_j'x_j/n = 1.
- Returns list(Z, scaleZ) and emits 3 messages.

(b) SILM core (SR, ST, Sim.CI, Step in cran/SILM R/*.R)
- Calls getFromNamespace('score.nodewiselasso','hdi')(X, wantTheta=TRUE, verbose=FALSE, lambdaseq='quantile', parallel=FALSE, ncores=2, oldschool=FALSE, lambdatuningfactor=1).
- X is raw: not centred or scaled.
- do.ZnZ is not passed, so it takes the function default, TRUE. That default was added in hdi 0.1-7 (2019-03-29). SILM 1.0.0 (2019-01-09) was built against hdi 0.1-6, which had no Z&Z step and used lambda.min. SILM results therefore changed silently in 2019; on test data the Z&Z lambda was 0.158 x lambda.min.
- Steps: the same lambda grid and the same CV (one FOLD_nw draw), then improve.lambda.pick (calcM once or twice; no RNG), then score.getThetaforlambda(oldschool=TRUE, oldtausq=TRUE).
- The Theta step: a for-loop of glmnet(x[,-i], x[,i]) with coefficients from predict(type='coefficients', s=lambda)[-1] (intercept dropped), C[-i,i] = -gamma, T2 computed ignoring the intercept, Theta = t(C %*% solve(diag(T2))). No rescale, 2 messages.

Differences: output (Z vs Theta), the do.ZnZ default, parallel flags, messages, and the caller's preprocessing of x. Both consume exactly one sample.int(n) at the same point: verified identical .Random.seed after each path from the same seed.

Proposed single internal API (R/nodewise_*.R)
- .nodewise_tune(x, K = 10L, do_znz, lambdatuningfactor = 1, foldid = NULL, parallel = FALSE, ncores = 1L, cv_verbose = FALSE)
  - Returns list(lambdas, lambda.min, lambda.1se, bestlambda, foldid).
  - Grid: identical code to nodewise.getlambdasequence.
  - Its only RNG step: if (is.null(foldid)) foldid <- sample(rep(1:K, length = n)), taken at the same point as hdi. The grid is deterministic, so the relative order is preserved.
  - Then the pooled CV (cv.nodewise.totalerr code), then the Z&Z step via improve.lambda.pick/calcM when do_znz is TRUE, otherwise lambda.min * lambdatuningfactor (or lambda.1se).
- .nodewise_final(x, lambda, what = c('Z','Theta'), parallel, ncores)
  - One glmnet(x[,-i], x[,i]) fit per column.
  - Z_i = x_i - predict(fit, x[,-i], s=lambda), then score.rescale.
  - Theta column from predict(type='coefficients', s=lambda)[-1] with the oldtausq T2.
  - Can return both from the same fits. Verified: Z, scaleZ, Theta and bestlambda are bitwise identical to hdi's score.getZforlambda / score.getThetaforlambda, including when both come from one shared fit.
- .nodewise(x, what, do_znz, foldid = NULL, ...)
  - Equivalent to score.nodewiselasso; returns list(out, bestlambda, lambdas, foldid).
  - Never centres or scales x: lasso.proj passes prepared x, SILM core passes raw X.
- calculate.Z(x, Z, do.ZnZ, parallel, ncores, verbose)
  - Calls .nodewise(x, 'Z', do_znz = do.ZnZ). With a user-supplied Z it keeps hdi's all.equal(tol=1e-8) check and rescale.
- SILM core
  - Calls .nodewise(X, 'Theta', do_znz = <decision for the SILM-core stream>).
  - TRUE reproduces SILM with hdi 0.1-7 to 0.1-10 (what users have had since 2019); FALSE reproduces the original 2019 behaviour.
  - Either way the RNG order is unchanged, because the Z&Z step draws nothing.
- Dead code to leave out: the oldschool loops in cv.nodewise.bestlambda and score.getZforlambda, cv.nodewise.stderr, and nodewise.getlambdasequence.old (lambdaseq='linear'). Neither caller uses them.
- Parallel work inside the nodewise code has no RNG, so any backend gives identical results.


### Parallel notes

Current hdi behaviour
- boot.lasso.proj sets ncores <- 1 when parallel=FALSE. boot.initial.fit (always) and boot.se (robust=TRUE) then still call parallel::mcmapply(..., mc.cores=ncores).
- On Unix in R 4.5, mcmapply with n >= 2 calls mclapply. Its mc.set.seed step calls mc.reset.stream, which does nothing under Mersenne-Twister. With cores < 2 it runs lapply in-process, so RNG use is identical to a plain loop or mapply (verified).
- On Windows, parallel's stub mcmapply(mc.cores=1) is just mapply, which is fine. mc.cores > 1 stops with "'mc.cores' > 1 is not supported on Windows". So boot.lasso.proj(parallel=TRUE) errors on Windows when getOption('mc.cores', 2L) > 1.
- lasso.proj does not force ncores, but with parallel=FALSE the nodewise code uses mapply and never touches ncores. With parallel=TRUE it uses mcmapply(mc.cores=ncores) in cv.nodewise.bestlambda, calcM and score.getZforlambda. That errors on Windows if ncores > 1; on Unix it gives results and a parent RNG state identical to sequential (verified), because no RNG happens in the forked work.
- boot.lasso.proj(parallel=TRUE) with cv-lasso refits: the B (or 2B) cv.glmnet fold draws happen in forked children.
  - Default RNG: each child drops .Random.seed and re-seeds randomly, so results change between same-seed runs (verified) and the parent stream is not advanced.
  - L'Ecuyer-CMRG: reproducible, but the result depends on ncores and differs from sequential (verified).
- A side effect of mcmapply's USE.NAMES: bootstrap matrices get junk colnames c('x', NA, ...).

Recommended handling
1. Use one internal helper, .silm_mapply(FUN, ..., parallel, ncores). It uses mapply when !parallel, ncores <= 1, or on Windows (with a one-time warning there), and mcmapply otherwise. Drop the always-mcmapply pattern; results are identical. Also unname the outputs.
2. Draw all bootstrap cv.glmnet foldids in the main process, in b order, with sample(rep(seq(10), length = n)), and pass them via cv.glmnet(foldid=). This is bitwise identical to hdi's sequential results for any ncores and any OS (verified: pval, pval.corr, cboot.dist, the H0c distribution and the RNG state after the call). So parallel runs become reproducible under set.seed with the default RNG, and L'Ecuyer is no longer needed.
3. For the shortcut fallback, use the two-phase approach: RNG-free fits first, then fold draws for the flagged b in order.
4. The nodewise fold assignment can also be passed via foldid.
5. Keep the hdi defaults: parallel=FALSE, ncores=getOption('mc.cores', 2L). The `if(!parallel) ncores <- 1` semantics become moot.
6. parallel should go in Imports (it is base R). Optionally cap ncores with parallel::detectCores() and respect _R_CHECK_LIMIT_CORES_ in tests.


### Binomial support

What family="binomial" needs (lasso.proj only; boot.lasso.proj stops for any non-gaussian family)
- switch.family (helpers.R:435-464, about 30 lines).
- prepare.data's second centring step (already needed for gaussian).
- The `if(family=="binomial") sigma <- 1` line.

How switch.family works
- It fits cv.glmnet(x, y, family='binomial', standardize=FALSE) on the already-scaled x. This is one extra fold draw, made BEFORE the nodewise draw.
- It uses lambda.min (not lambda.1se) and predicts pihat (type='response') and the coefficients including the intercept.
- It builds W = diag(pihat(1-pihat)) as an n x n matrix. Then xw = sqrt(W) x and yw = sqrt(W)(cbind(1,x) betahat + solve(W, y - pihat)).
- After that the gaussian machinery runs on (xw, yw): nodewise on xw, then the cv.glmnet initial fit on the pseudo-data, with sigmahat forced to 1.

Quirks
- The forced sigma always triggers initial.estimator's 'Overriding the error variance estimate' warning. Suppressing it for binomial is safe; it has no numeric effect.
- solve(W, v) costs O(n^3) time and O(n^2) memory. It is not bitwise-equal to v/diag(W) (verified), so keep solve() for exactness or accept ~1e-16 differences.
- Fitted probabilities of exactly 0 or 1 make solve() fail with a singular-matrix error.
- The returned Z depends on y through W, so it cannot be reused across responses.
- betainit numeric is allowed because sigma is forced.
- family must be the string 'binomial'; family objects are not accepted.

Dependencies and RNG
- Only glmnet (predict.lognet, coef).
- One extra FOLD_cv draw at the very start.

Recommendation: keep it. It is small (about 40 lines in its own file), needs no new dependency, and is part of hdi's lasso.proj interface. Document that it is the hdi linearisation approach, not the paper's (the paper is gaussian only), and that boot.lasso.proj keeps its gaussian-only stop().


### hdi quirks

- **boot.initial.fit / boot.se (helpers.R:735-785)** (keep for compat: False): Always call parallel::mcmapply, even when parallel=FALSE (ncores forced to 1, so in-process lapply). The Windows stub maps to mapply; mc.cores>1 errors on Windows. *Note:* Replace with a .silm_mapply helper. The numbers and RNG use are identical (verified).
- **boot.lasso.proj parallel=TRUE** (keep for compat: False): The cv.glmnet refits' fold draws happen in forked children. Default RNG: not reproducible under set.seed (verified), and the parent stream is not advanced. L'Ecuyer: reproducible but depends on ncores and differs from sequential. *Note:* Pre-draw all foldids in the main process in b order and pass foldid= to cv.glmnet. Bitwise identical to hdi's sequential run for any ncores (verified).
- **boot.lasso.proj L41-42 vs lasso.proj** (keep for compat: True): boot sets ncores <- 1 when !parallel; lasso.proj does not (ncores unused there when parallel=FALSE). The default ncores = getOption('mc.cores', 2L). *Note:* Keep the argument defaults; the internal handling is moot with the helper.
- **confint.hdi boot branch (methods.R:222-230)** (keep for compat: True): Uses quantile type 1 only if ((1-level)/2*B) %% 1 == 0, else type 7. Because of floating point this test is FALSE for levels 0.95, 0.9, 0.99 and 0.8 with B = 100/200/1000 (e.g. 25.000000000000021), so type 7 is effectively always used; only exact cases like level=0.5 hit type 1. *Note:* Copy the exact expression to reproduce hdi CIs; reuse the same rule for the new simultaneous CIs for consistency.
- **confint.hdi boot branch** (keep for compat: True): Stops unless return.bootdist=TRUE. The stored cboot.dist is se/sds*T* (original scale), and CI = [bhat - q(1-a/2), bhat - q(a/2)] (paper eq. 9). *Note:* The SILM object can additionally store per-replicate max_j T*, min_j T* and max_j|T*| (length-B vectors) so simultaneous CIs over all p work without the p x B matrix. Arbitrary groups G still need return.bootdist.
- **initial.estimator (helpers.R:615-629)** (keep for compat: True): Numeric betainit with sigma=NULL stops ('Not sure what variance estimate to use here') only AFTER the expensive nodewise step; the code after the stop is dead. *Note:* Keep the error and message, but validate up front. Safe: only failing calls are affected.
- **initial.estimator L603-604** (keep for compat: False): The check `(is.numeric(betainit) && length(betainit)==ncol(x)) || (betainit %in% ...)` gives a length>1 condition for a numeric betainit of the wrong length. In R >= 4.3 that raises a coercion error instead of the intended message. *Note:* Fix the validation.
- **initial.estimator / lasso.proj** (keep for compat: True): A numeric betainit is used on the centred/standardised x scale (betahat = betainit/sds). Any non-NULL sigma (and binomial's forced sigma=1) always raises the 'Overriding the error variance estimate' warning. *Note:* Document the scale. Suppress the warning only in the internal binomial case.
- **boot.initial.fit L742-743** (keep for compat: True): A numeric betainit always errors ('We need to somehow specify the initial lasso method for the bootstrap!') after the nodewise and resampling draws, unless gaussian.stub=TRUE. *Note:* Validate early (safe). An optional future extension is an explicit lambda argument.
- **boot.lasso.proj L114-116 with betainit='scaled lasso'** (keep for compat: True): boot.shortcut=TRUE with the scaled lasso gets lambda=NULL, so no shortcut is actually used, yet the output reports boot.shortcut=TRUE and lambda=NULL. *Note:* Keep the values; adding a warning is safe.
- **do.initial.fit with lambda (boot.shortcut)** (keep for compat: True): The shortcut refits glmnet(x, ystar) on its default path and reads coef(s=lambda) by linear interpolation (exact=FALSE), which is approximate. If n - nnz(incl. intercept) <= 0 it falls back to cv.glmnet with a message and an RNG draw. *Note:* The fallback needs the two-phase foldid approach under pre-drawing.
- **do.initial.fit cv branch** (keep for compat: True): cv.glmnet(x, y) uses glmnet's defaults (intercept=TRUE, standardize=TRUE) on already-centred data. The intercept is about 1e-16 but nonzero, so it is counted in nnz: sigmahat = sqrt(RSS/(n - s_hat - 1)), whereas the paper's eq. (4) uses n - s_hat. lambda.1se is used (switch.family uses lambda.min). *Note:* Keep the literal expression sum(as.vector(coef(fit, s=lambda)) != 0).
- **do.initial.fit scaled lasso** (keep for compat: True): sigmahat is scalreg's hsigma. SILM core instead recomputes RSS/(n - s_hat) from the scalreg coefficients. *Note:* Keep a separate convention per caller.
- **prepare.data / standardize** (keep for compat: True): standardize=FALSE still centres x and y, and every glmnet/cv.glmnet call still standardises internally. The flag only affects sds, the scale of Z, and the pooling of the nodewise lambda grid. *Note:* Document.
- **lasso.proj / boot.lasso.proj output** (keep for compat: True): sds = apply(original x, 2, sd). bhat, se and betahat are divided by sds; sigmahat is not. return.Z gives the unrescaled Z for the standardised x via scale(Z, center=FALSE, scale=1/scaleZ), which carries a 'scaled:scale' attribute. cboot.dist = se/sds*T*. *Note:* Store the raw T* separately for the new simultaneous CIs and P_G to avoid round-trip error.
- **calculate.Z with supplied Z** (keep for compat: True): The return.Z -> Z= round trip is not bitwise identical (the rescale is redone; all.equal TRUE, identical FALSE, verified). It also skips the nodewise fold draw, which shifts the cv.glmnet folds, so results under the same seed differ from a Z=NULL run. *Note:* Document. Optionally expose the nodewise/initial foldids for reproducibility.
- **est.stderr.despars.lasso vs boot.se** (keep for compat: True): The original se uses sqrt(diag(crossprod(Z)))/n (a full p x p crossprod); the bootstrap se uses sqrt(colSums(Z^2))/n. They differ by about 2e-16 relative (verified). *Note:* Keep both literal expressions for bitwise results, or accept an all.equal tolerance if optimising memory.
- **sandwich.var.est.stderr** (keep for compat: True): The robust se is sqrt(sum_i(eps_i Z_ij - mean)^2)/n (divisor n). The paper's eq. (5) uses 1/(n - s_hat), while its Sec 3.3.2 uses 1/n. The internal robust.div.fixed=TRUE (not exposed) multiplies by n/(n - s_hat) instead of sqrt(n/(n - s_hat)). *Note:* Keep the hdi default. A paper-eq.(5) option could be added under a new argument.
- **lasso.proj WY (p.adjust.wy)** (keep for compat: True): Uses the homoscedastic crossprod(Z) covariance even when robust=TRUE. pcorr = ecdf(Gz)(pval) with no +1, so it can be 0. The result is platform-dependent through eigen() in mvrnorm (hdi 0.1-6 NEWS reports cross-platform mvrnorm reproducibility problems). *Note:* Call MASS::mvrnorm exactly.
- **lasso.proj L123-141 (preprocess.group.testing)** (keep for compat: True): Runs by default after pcorr: N*p normals, a p x p eigen, and two N x p matrices (about 650 MB for p=4088). It changes NO returned value (verified), only the RNG state after the call. mvrnorm could also abort the call if Sigma is judged not positive definite. *Note:* Keep the argument. When FALSE, burn rnorm(N*p) in 4096-sized chunks, which leaves an identical RNG state (verified) with none of the cost; TRUE skips the burn. Drop the closures and the mvrnorm error path.
- **lasso.proj L107-117 / boot L195-251** (keep for compat: False): multiplecorr.method is validated only after all computation. *Note:* Validate up front; valid calls are unaffected.
- **boot.lasso.proj p-values L182-188** (keep for compat: True): counts = #{T* <= t}; if counts >= B/2, use B - counts; pval = (2*counts + 1)/(B + 1). Ties count as <=. *Note:* Copy exactly.
- **boot.lasso.proj WY L195-221** (keep for compat: True): The H0,complete pass REUSES the same rstar (ystar = 0 + rstar; no new resampling), needs a second full set of B refits, and uses pcorr = (#{max_k|T*0_k| >= |t_j|} + 1)/(B + 1). This matches paper eq. (14) with hdi's +1 and >= convention. *Note:* Use the same convention for the new P_G, so that P_G over all p equals min_j pval.corr.
- **boot.lasso.proj p.adjust branch** (keep for compat: True): Warns when any pval <= 5/(B+1) and 5p/(B+1) > 0.05. *Note:* Keep.
- **boot.lasso.proj L89-90, 174** (keep for compat: True): rstar comes from centred residuals, but ystar is not re-centred, so the glmnet intercept absorbs the nonzero mean. The Z columns sum to about 0, so bstar is unaffected. *Note:* Needs care in the xyz-paired extension, where resampled Z* are not centred.
- **mcmapply USE.NAMES** (keep for compat: False): betainitstar, cboot.dist and cboot.dist.underH0c get colnames c('x', NA, NA, ...) (verified). *Note:* unname(); the numbers are unchanged.
- **gaussian.stub** (keep for compat: True): Developer option: replicate(B, rnorm(p)) replaces the bootstrap distribution (twice under WY) and ignores dependence. *Note:* Keep for compatibility, documented as internal/developer.
- **switch.family** (keep for compat: True): solve(diag(W), y - pihat) is O(n^3) and not bitwise-equal to division (verified); it errors if pihat is 0 or 1. *Note:* Keep solve for exactness.
- **print.hdi** (keep for compat: False): lasso.proj and boot.lasso.proj objects fall through to print.default, which prints the closures. *Note:* Write SILM-owned print methods; keep $method strings 'lasso.proj' / 'boot.lasso.proj'.
- **score.nodewiselasso default do.ZnZ=TRUE (since hdi 0.1-7)** (keep for compat: True): calculate.Z passes do.ZnZ explicitly (lasso.proj default FALSE, boot always FALSE), but SILM core relied on the function default. SILM's behaviour changed when hdi 0.1-7 appeared. *Note:* Make do_znz an explicit required argument of the internal API.
- **calculate.Z / score.getThetaforlambda messages** (keep for compat: False): Always prints 3 messages about Z (and 2 about Theta for SILM core); verbose only adds CV progress. *Note:* Making these verbose-only is safe.
- **edge cases** (keep for compat: False): p=1 fails in nodewise (x[,-1]). B=1 makes despars.lasso.est drop to a vector and breaks the WY sapply shape. A constant column gives sd 0 and NaN. *Note:* Validate p >= 2, B >= 2 and nonzero column sd.
- **hdi tests (tests/test-lasso.R)** (keep for compat: True): Reference values were produced under RNGversion('3.5.0') (sample.kind='Rounding') with set.seed(3) on riboflavin[, 1:16] (riboflavin.RData is 2.1 MB). The tolerances are 4e-7 and 5e-5, reflecting glmnet version drift. *Note:* Generate fixtures from hdi 0.1-10 in a throwaway library (data-raw/) instead of vendoring riboflavin.
- **boot.lasso.proj vs the Dezeure-Buhlmann-Zhang (2017) paper** (keep for compat: True): hdi implements only the residual bootstrap, the wild bootstrap with N(0,1) multipliers, WY max-T and individual CIs. It lacks the eq. 10 simultaneous CIs (max/min and |T*|), group P_G (the code says 'we don't yet support group testing'), Mammen multipliers and the xyz-paired bootstrap. The paper recommends robust=TRUE, but hdi's default is FALSE. *Note:* Add the missing parts as new arguments and methods with hdi-compatible defaults.


## Appendix B. SILM-core dependency research


### hdi_history

Short answer: yes, and it changed what SILM computes. SILM 1.0.0 was published on CRAN on 2019-01-09. At that time the current hdi release was 0.1-6 (cran/hdi commit 95c3aa29, 2016-03-21). No hdi release came between 0.1-6 and 0.1-7 (commit 7d62a06f, 2019-03-29).

In hdi 0.1-6, score.nodewiselasso had no do.ZnZ argument. Its signature ended at cv.verbose = FALSE. SILM's call therefore took bestlambda <- cvlambdas$lambda.min * lambdatuningfactor, which is the plain 10-fold nodewise CV lambda.min.

Commit 7d62a06f (hdi 0.1-7) changed R/helpers.nodewise.R: the blob sha went from 4d5f96f4 to 6506bf5f. That commit:
(a) added the argument do.ZnZ = TRUE to score.nodewiselasso;
(b) added improve.lambda.pick, calcM and calcMforcolumn (the Z&Z pick). This chooses the smallest grid lambda whose mean of ||Z_j||^2/(Z_j'x_j)^2 is below 1.25 times its value at lambda_cv, then refines on a 101-point sub-grid between that lambda and the next grid value;
(c) moved the lambdatuningfactor logic into the else-branch, so SILM's lambdatuningfactor = 1 is now ignored;
(d) added calculate.Z, which SILM does not use;
(e) changed cat() to message() in the verbose branch of cv.nodewise.err.unitfunction.

The other closure functions (nodewise.getlambdasequence, cv.nodewise.bestlambda, cv.nodewise.totalerr, score.getThetaforlambda) did not change. After that, helpers.nodewise.R is byte-identical in 0.1-7, 0.1-8 (b31648aa, 2021-05-13), 0.1-9 (3f51705e, 2021-05-27) and 0.1-10 (3eb71fb5, 2025-04-17): all have blob sha 6506bf5f. The file's last change is commit 7d62a06f.

hdi's NEWS entry for 0.1-6a says "added the missing Z & Z functionality for the lasso projection method". Its 0.1-7 entry says "fixed issues with RNG". The nodewise code contains no seed or RNG changes.

hdi's own lasso.proj() in 0.1-10 has the argument do.ZnZ = FALSE and passes it explicitly through calculate.Z. So hdi's exported methods kept the lambda.min behaviour. SILM calls the internal function and relies on its default, so SILM alone was silently switched to Z&Z.

Which version users effectively ran:
- 2019-01-09 to 2019-03-28: SILM 1.0.0 with hdi 0.1-6, using the CV lambda.min.
- 2019-03-29 to archival on 2026-07-10: hdi 0.1-7 through 0.1-10, using the Z&Z lambda (do.ZnZ = TRUE).
The most recent effective version is hdi 0.1-10 with Z&Z, which is exactly the local file helpers.nodewise.R.

In-memory check (n=40, p=30, set.seed(1), glmnet 4.1-10): the Z&Z lambda was 0.0868 versus lambda.min 0.395, and the maximum absolute difference in Theta was 0.97. The difference is material.

### scalreg_closure

Code path for scalreg(X, Y) in scalreg 1.0.1. The R files are byte-identical to 1.0 (same MD5s); 1.0.1 only dropped MASS from Depends and added a NAMESPACE importFrom("lars", "lars", "predict.lars"). Only the following is executed:
1. scalreg() runs X <- as.matrix(X) and y <- as.numeric(y). A Y given as an n x 1 matrix is therefore fine.
2. Because y is non-NULL, it calls slassoEst(X, y, lam0 = NULL). With LSE = FALSE, lse() is never called. slassoInv, predict.scalreg and print.scalreg are not used.
3. Choice of lam0:
   - If p > 1e6, lam0 = "univ", giving sqrt(2*log(p)/n).
   - Otherwise lam0 = "quantile". The line `if(lam0=="univ" | lam0=="universal")` is FALSE, then a fixed-point loop runs: L = 0.1, Lold = 0; while |L - Lold| > 0.001 { k = L^4 + 2*L^2; Lold = L; L = -qnorm(min(k/p, 0.99)); L = (L + Lold)/2 }. If p == 1, L = 0.5. Finally lam0 = sqrt(2/n)*L. This is the lambda_0 of Sun & Zhang (2013, JMLR 14:3385).
4. objlasso = lars(X, y, type = "lasso", intercept = FALSE, normalize = FALSE, use.Gram = FALSE). This is the full raw-scale lasso path with no centring and no scaling.
5. Sigma iteration: sigmaint = 0.1, sigmanew = 5, flag = 0. While |sigmaint - sigmanew| > 1e-4 & flag <= 100: flag = flag + 1; sigmaint = sigmanew; lam = lam0*sigmaint; hy = predict.lars(objlasso, X, s = lam*n, type = "fit", mode = "lambda")$fit; sigmanew = sqrt(mean((y - hy)^2)).
6. hbeta = predict.lars(..., s = lam*n, type = "coefficients", mode = "lambda")$coef. The fit is then recomputed once more (redundantly).
The only other dependency is stats::qnorm.

Quirks:
(a) The loop runs at most 101 times (flag <= 100). If it has not converged it stops silently, with no warning. The starting sigma is 5 regardless of the scale of y.
(b) The returned coefficients are at lambda = lam0*sigma_(k-1), the previous iterate. hsigma = sigma_k is the RMS residual of that fit, so hsigma and the lambda used differ by up to 1e-4.
(c) The factor s = lam*n is needed because lars' lambda is max|X'r| on the sum scale. lam0 is on the per-observation scale, so lars s = n * glmnet lambda.
(d) scalreg() then overwrites fitted.values with as.vector(X %*% coefficients) and residuals with y - fitted. SILM uses only $coefficients: it recomputes sigma.sq = RSS/(n - #nonzero) itself and never uses hsigma.
(e) Coefficients carry colnames(X) when X has them. Inactive coefficients are exactly 0, because lars sets dropped coefficients to 0 and interpolation keeps zeros, so SILM's abs(beta.hat) > 0 support count is well defined.
(f) The p > 1e6 branch uses the universal lambda instead. SILM never realistically reaches it.
(g) lam0 is compared with == on a possibly numeric value. This is harmless.

Dependency on lars: lars::lars and lars::predict.lars (mode = "lambda") are essential. lars is still on CRAN (1.3, GPL-2) and has many reverse dependencies. It includes compiled Fortran (delcol, reached via downdateR whenever a variable leaves the lasso path). So keep lars as an Imports dependency rather than vendoring it. A reimplementation of about 20 lines of slassoEst that calls lars::lars and lars::predict.lars with identical constants (start 5, tolerance 1e-4, cap flag <= 100, s = lam*n, quantile lam0) reproduces scalreg exactly.

### sis_standardize

Exact source, from cran/SIS R/standardize.R in version 1.5 (commit 97c211f3, 2026-03-14):

standardize <- function(X) {
  center <- colMeans(X)
  X.c <- sweep(X, 2, center)
  unit.var <- sqrt(apply(X.c, 2, crossprod))
  val <- sweep(X.c, 2, unit.var, "/")
  return(val)
}

The body is the same code as in 0.8-6 (3e0f17d8, 2018-02-13), which was current when SILM was released. Only whitespace and `=` versus `<-` differ. The file is unchanged in 0.8-7 and 0.8-8 (blob sha bb460341). It centres each column and scales it to unit Euclidean norm, not unit variance. A constant column gives NaN, and an n x 0 input gives n x 0.

Numerical identity was tested in memory on R 4.5.2 with OpenBLAS, over 200 random matrices:
- Xc <- X - rep(colMeans(X), each = nrow(X)); Xc / rep(sqrt(apply(Xc, 2, crossprod)), each = nrow(X)) was bit-identical in 200/200 cases.
- Versions that use sqrt(colSums(Xc^2)) were identical in only 3/200 cases. The maximum absolute difference was about 5.6e-17, because crossprod uses BLAS dsyrk while sum(x^2) uses long-double accumulation.

So a 2-3 line internal replacement is numerically identical only if it keeps sqrt(apply(Xc, 2, crossprod)) as the norm. Centring with sweep() or with rep() subtraction is also identical. In ST the result is used only to rank abs(t(std(X.sub[,-set1])) %*% resi), so ULP-level differences could matter only in exact ties. Still, keep crossprod for exact reproduction.

Pre-existing ST bug: if cv.glmnet selects nothing (set1 = integer(0)), then X.sub[,-set1] has zero columns and (1:p)[-set1] is empty, so screening breaks. It also breaks when n0-1-length(set1) <= 0 or exceeds p-length(set1).

### lars_notes

Versions: lars 1.2 (2013-04-23, cran/lars 5b6af0bc) was current throughout 2019 to 2022. lars 1.3 (2022-04-13, b2e7a903) is the current CRAN version. It is GPL-2, needs compilation (Fortran delcol), and has many reverse dependencies, so it is not at risk.

The 1.2 to 1.3 diff touches only one R file, R/lars.R:
(1) The default eps changed from .Machine$double.eps (2.2e-16) to 1e-12. The man page now says to increase eps if lars stops with NAs.
(2) gamhat <- min(min(gam[gam > eps], na.rm = TRUE), Cmax/A) is now NA-safe.

R/predict.lars.R is unchanged. With scalreg's settings (normalize = FALSE, so the nosignal check is skipped), eps affects:
- the early exit when Cmax < 100*eps;
- tie detection, new <- abs(C) >= Cmax - eps;
- the collinearity drop in updateR when rpp <= eps;
- the step-length and drop filters gam > eps and z1 > eps;
- rss.big < eps, which only affects Cp and sigma2.
Paths are therefore identical except for near-tied or near-collinear data, where lars 1.3 can differ from 1.2.

predict.lars(mode = "lambda") in 1.3, same as 1.2: s is clamped to [0, max(object$lambda)], and the breakpoint vector is c(object$lambda, 0). Coefficients are linearly interpolated between path breakpoints, which is exact because the lasso path is piecewise linear in lambda. Duplicate breakpoints are removed with unique(). type = "fit" returns scale(newx, meanx, FALSE) %*% t(beta) + mu, where meanx = 0 and mu = 0 when intercept = FALSE.

Caveat: the code assumes the last path row sits at lambda = 0. That holds when the path saturates, meaning min(p, n) active variables with intercept = FALSE and zero residual correlation. It fails if lars stops early at max.steps = 8*min(p, n) or at the Cmax < 100*eps break; small s would then be slightly mis-interpolated. This is rare and identical in 1.2 and 1.3.

With use.Gram = FALSE (scalreg's setting), the '>500 variables' message is not printed. Recommendation: keep lars as an Imports dependency (importFrom(lars, lars, predict.lars)) rather than vendoring it (GPL-2 only, plus Fortran). Do not swap in glmnet for the scaled lasso: the lasso at lars s = n*lam equals glmnet(lambda = lam, standardize = FALSE, intercept = FALSE) only up to convergence tolerance, not bit-for-bit, and the support could differ.

### rng_reproducibility

Only three sources of randomness exist:
(i) base::sample() inside hdi's cv.nodewise.bestlambda: dataselects <- sample(rep(1:K, length = n)) with K = 10 (helpers.nodewise.R line 518). This runs exactly once per score.nodewiselasso call, after the p deterministic glmnet fits in nodewise.getlambdasequence and before any CV fits.
(ii) base::sample() inside cv.glmnet: foldid = sample(rep(seq(10), length = N)), once per call.
(iii) rnorm() in SILM's bootstrap loops, plus ST's sample().
No RNG is used by glmnet fits, predict, quantile, calcM, improve.lambda.pick, score.getThetaforlambda, scalreg/lars, or solve(). Verified: the RNG state after cv.glmnet equals the state after a single sample(rep(seq(10), length = n)).

Order of draws per function:
- SR(X, Y): if p > floor(n/2), [nodewise] sample(rep(1:10, length = n)). Otherwise there are no draws, because Theta = solve(Gram). scalreg draws nothing.
- Sim.CI(X, Y, set, M, alpha): [nodewise sample(rep(1:10, length = n)) only if p > floor(n/2)], then M calls of rnorm(n) in loop order i = 1..M.
- Step(X, Y, M, alpha): [nodewise sample only if p > floor(n/2)]. Then the non-studentized step-down while-loop: each pass draws M times rnorm(n). The number of passes depends on the data, at least 1. Then the studentized while-loop draws M times rnorm(n) per pass, continuing the stream; it does not reuse the first loop's draws.
- ST(X.f, Y.f, sub.size, test.set, M, alpha):
  1. S1 <- sample(1:n, floor(sub.size)) (sample.int(n, size) algorithm; no hash, since n <= 1e7);
  2. cv.glmnet(X.sub, Y.sub, intercept = FALSE), giving sample(rep(seq(10), length = floor(sub.size)));
  3. score.nodewiselasso on the screened X, called unconditionally with no p > n/2 check, giving sample(rep(1:10, length = n0)) where n0 = n - floor(sub.size);
  4. M calls of rnorm(n0).

Details for exact reproduction:
(a) Keep these calls with identical arguments and in identical order. Do not add RNG calls (for example, do not pre-generate foldid in another way or add a random tie-breaker). Keep parallel = FALSE semantics: no RNG happens inside the mapply bodies, so parallel map would not change streams, but keep the single sample() before the map.
(b) sample.kind: R >= 3.6.0 defaults to 'Rejection', earlier R used 'Rounding'. Verified: fold ids differ between the two for the same seed. rnorm ('Inversion', 2 uniforms per normal) is unaffected. Results produced under R <= 3.5.x (e.g. Jan–Mar 2019) need RNGkind(sample.kind = 'Rounding') before set.seed.
(c) Even with identical RNG, results from 2019 through 2026-07 (hdi 0.1-7 to 0.1-10) used do.ZnZ = TRUE. SILM 1.0.0 as released against hdi 0.1-6 used CV lambda.min, and the RNG stream is the same either way because Z&Z uses no RNG.
(d) Small numerical drift can also come from the glmnet engine (Fortran before 4.1-3/4.1-4, C++ after), lars eps (1.2 versus 1.3), and BLAS (crossprod, %*%).
To verify, install the archived hdi 0.1-10, scalreg 1.0.1 and SIS in a throwaway library, run the old SILM under set.seed(k), and compare with identical() or tolerance 1e-12.


## Appendix C. DBZ extras specification (verifier-corrected)


### notation_mapping

Sources read: the paper (Dezeure, Bühlmann & Zhang 2017, TEST 26:685-719; all 35 pp.) and the hdi 0.1-10 source files (hdi_boot.lasso-proj.R = "BLP", hdi_helpers.R = "HLP", hdi_methods.R = "MTH", helpers.nodewise.R = "NW").

What hdi already has and what it lacks. hdi 0.1-10 only has the residual bootstrap and the Gaussian wild bootstrap (HLP resample() lines 787-800 uses rnorm only). From those it gives individual p-values, WY-adjusted p-values and individual bootstrap-t CIs. It has none of the four extras. BLP lines 258-260 set group.testing.function <- NULL ("For the moment we don't yet support group testing"). There is no simultaneous CI in confint.hdi (MTH 181-237), no non-Gaussian multiplier, and no paired or xyz resampling anywhere.

INTERNAL SCALE. All hdi internals are computed after prepare.data (HLP 651-670). There, x is column-centred and scaled to unit sd if standardize = TRUE, then centred again, and y is centred. Returned quantities are divided by sds = apply(x_raw, 2, sd), or 1 if standardize = FALSE (BLP 266-281).

Paper to hdi:
- X, X_j -> x, x[, j] (internal, centred and optionally standardised). Y -> y (centred).
- beta_hat (initial Lasso) -> betalasso, from initial.estimator/do.initial.fit (HLP 519-649). The glmnet intercept is dropped, so it does not enter any later formula. Returned as betahat = betalasso/sds.
- eps_hat = Y - X beta_hat -> r (BLP 89). Its mean is about 0 because x and y are centred. eps_hat_cent -> rc = r - mean(r) (BLP 90).
- Z_j -> Z[, j]: the nodewise-Lasso residual (NW 314-364), rescaled by score.rescale (NW 366-377) so that Z_j^T X_j / n = 1. The paper's denominators Z_j^T X_j equal n and |Z_j^T X_j / n| equals 1. scaleZ holds the original normalisers. return.Z gives back the unrescaled Z (Z * scaleZ). A user-supplied Z is rescaled in calculate.Z (NW 29-37).
- b_hat_j (eq. 2) -> bproj = betalasso + crossprod(Z, y - x %*% betalasso)/n, from despars.lasso.est (HLP 672-696). Returned as bhat = bproj/sds.
- s.e._j (eq. 4) -> se = sigmahat * sqrt(colSums(Z^2))/n when robust = FALSE (HLP 729). This equals n^{-1/2} sigma_hat ||Z_j||/sqrt(n). sigmahat is sqrt(RSS/(n - #nonzero coefficients including the intercept)) for "cv lasso", or scalreg's hsigma for "scaled lasso".
- s.e._robust,j (eq. 5) -> se when robust = TRUE, from sandwich.var.est.stderr (HLP 467-517): sqrt(sum_i (e_i Z_ij - n^{-1} sum_r e_r Z_rj)^2)/n, with e = y - x beta minus its mean. This is n^{-1/2} omega_hat_j with the 1/n version of omega_hat^2 (Sect. 3.3.2, p. 697), not the 1/(n - s_hat) version in eq. (5). robust.div.fixed = FALSE is hard-wired in boot.lasso.proj. The unused TRUE branch (HLP 726-727) would multiply se by n/(n - s_hat), not by sqrt(n/(n - s_hat)); do not expose it. Returned as se = se/sds.
- T_j for testing (Sect. 4.3, not centred) -> bproj/se, used verbatim in the individual p-values (BLP 182) and in WY (BLP 218). Store exactly this expression as tstat. Do not use bprojrescaled = bproj * (1/se), which can differ by 1 ulp.
- T_j for CIs (eq. 7): (b_hat_j - beta_j)/se_j, which is implicit in the CI.
- beta_hat*, sigma_hat* -> betainitstar, sigmahatstar. These are refitted per bootstrap sample by boot.initial.fit (HLP 735-756), with the same betainit method. lambda is re-tuned unless boot.shortcut = TRUE (BLP 114-116).
- b_hat*_j -> bstar = despars.lasso.est(x, ystar, Z, betainitstar), vectorised over the B columns (BLP 141-144).
- s.e.*_j -> sestar from boot.se (HLP 758-785).
- T*_j (eq. 8) -> cboot.dist[j, b] = (bstar - betalasso)/sestar (BLP 156, boot.truth = betalasso), a p x B matrix on the internal scale.
- T*0_j (Sect. 4.3, eq. 14) -> cboot.dist.underH0c[j, b] = (bstar0 - 0)/sestar0, with ystar = 0 + rstar (BLP 209-213). It reuses the same rstar, so no new residual or multiplier draws are made.
- eps*_i -> rstar[, b] = resample(rc, B, wild) (BLP 171-173). W_i -> Ui = replicate(B, rnorm(n)) (HLP 793). Y* -> ystar = x %*% betalasso + rstar. Y*0 -> 0 + rstar.
- q*_{j;nu} and CI_j (eq. 9) -> confint.hdi (MTH 214-233): bhat - quantile(se * T*_j, 1 - alpha/2), bhat - quantile(se * T*_j, alpha/2).
- Individual p-value (duality with eq. 9) -> pval (BLP 182-188). With c_j = #{b: T*_jb <= t_j}: if c_j >= B/2 then c_j <- B - c_j; pval_j = (2 c_j + 1)/(B + 1). The result is at most 1.
- P_{j,corr} (Sect. 4.3) -> pval.corr under "WY" (BLP 216-221): max.t.dist_b = max_k |T*0_kb|, and pval.corr_j = (1 + #{b: max.t.dist_b >= |t_j|})/(B + 1). hdi uses >= and +1, where the paper has > and no +1.
- Stored bootstrap distributions (return.bootdist = TRUE, BLP 288-299): out$cboot.dist = se/sds * T*, the p x B matrix of se_j (original scale) times T*_jb. out$cboot.dist.underH0c = se/sds * T*0. Rows are named by colnames(x). The hdi Rd calls the second one "cboot.dist.underH0", but the code field is "cboot.dist.underH0c"; keep the code name.
- To recover the studentised scale: Tstar = object$cboot.dist / object$se. Row-wise recycling is correct, but the result is only equal up to about 1.5e-16 relative (checked in R: not identical()). So store tstat and the H0c max vector exactly (see api_proposal) wherever exact identities matter.
- sqrt(n) in C(1 - alpha) (p. 693) has no counterpart. It is a typo; see simultaneous_ci.
- Scale invariance: every T, T*, T*0 and every quantile q* is scale-free. Only the final CI endpoints use bhat and se, which are already on the original scale.

### simultaneous_ci

Paper, Sect. 3.2, eq. (10), p. 694. For a group G:
- CI_simult,j = [ b_hat_j - se_j * qmax_G(1 - alpha/2), b_hat_j - se_j * qmin_G(alpha/2) ], for j in G.
- qmax_G(nu) is the nu-quantile over b of M_b = max_{j in G} T*_jb.
- qmin_G(nu) is the nu-quantile over b of m_b = min_{j in G} T*_jb.
- |T*| variant: CI_j = b_hat_j -/+ se_j * qabs_G(1 - alpha), where qabs_G(nu) is the nu-quantile of A_b = max_{j in G} |T*_jb|.
- T* is the CENTRED bootstrap distribution (eq. 8, hdi cboot.dist), not the H0c one.
- The standard error is the one the fit used: robust if robust = TRUE, non-robust otherwise ("Alternatively ... non-robust", p. 693).

Ambiguities and resolutions:
(a) Stray sqrt(n). The region C(1 - alpha) on p. 693 is written with sqrt(n)(b_hat_j - b_j)/s.e.. That contradicts eq. (8), where T* has no sqrt(n), and the componentwise eq. (10). Resolution: drop sqrt(n); the pivot is (b_hat_j - b_j)/se_j.
(b) Two-sided coverage. qmax(1 - alpha/2) and qmin(alpha/2) each spend alpha/2, so the joint coverage is at least 1 - alpha by a union bound. The joint event is not calibrated exactly. Keep the paper's definition and do not introduce a joint calibration.
(c) Quantile convention. The paper does not specify one. Use the hdi confint rule verbatim: alpha <- 1 - level; qtype <- if ((alpha/2 * B) %% 1 == 0) 1 else 7 for the max-min version. For the abs version use qtype <- if ((alpha * B) %% 1 == 0) 1 else 7, i.e. type 1 exactly when the target order statistic has an integer index.
  NOTE (checked in R 4.5.2): 1 - level is not exactly representable for common levels. For example, (1 - 0.95)/2 * 1000 = 25.000000000000021. So for level in {0.8, 0.9, 0.95, 0.99} and B in {100, ..., 2000}, hdi always uses type 7. Type 1 only occurs when 1 - level is dyadic, e.g. 0.5 or 0.75. Replicate this quirk exactly for type = "individual", which is an exact port. Use the same rule for the simultaneous versions so that the G = {j} max-min interval equals the individual interval.
(d) How G is specified. G is a set of variables, and the guarantee is P[beta_j in CI_j for all j in G] ~ 1 - alpha.

Algorithm for confint(object, parm, level = 0.95, type = "simultaneous", group = NULL, simult.stat = c("maxmin", "abs")):
1. Require object$method == "boot.lasso.proj".
2. pnames <- names(object$bhat), or seq_along if NULL. Resolve parm as confint.hdi does: missing -> all; numeric -> pnames[parm].
3. G <- if (is.null(group)) parm else resolve(group). Accept numeric indices, a logical vector of length p, or character names. Sort, take unique values, and error on NA, empty or out-of-range entries. Error if any parm is not in G, because intervals outside G carry no simultaneous guarantee.
4. Get the O(B) summaries over G on the internal studentised scale:
   - if G is all p variables, use the stored object$boot.summary$max, $min and $absmax;
   - else if G matches a precomputed entry in object$group.summary, use that;
   - else if !is.null(object$cboot.dist): T <- object$cboot.dist[G, , drop = FALSE] / object$se[G]; M <- apply(T, 2, max); m <- apply(T, 2, min); A <- apply(abs(T), 2, max);
   - else stop("rerun with return.bootdist = TRUE or groups = list(...)").
5. alpha <- 1 - level; B <- object$B.
   - maxmin: qhi <- quantile(M, 1 - alpha/2, type = qtype, names = FALSE); qlo <- quantile(m, alpha/2, type = qtype, names = FALSE); lower <- object$bhat[parm] - object$se[parm] * qhi; upper <- object$bhat[parm] - object$se[parm] * qlo.
   - abs: qab <- quantile(A, 1 - alpha, type = qtype.abs, names = FALSE); lower/upper <- bhat -/+ se * qab.
6. The returned matrix has dimnames list(parm, c("lower", "upper")), as in hdi. Add attr(, "simultaneous") = list(group = G, stat, level, quantiles = c(qlo, qhi) or qab, qtype).
7. Warn if alpha/2 * (B + 1) < 5 (maxmin) or alpha * (B + 1) < 5 (abs), in the spirit of hdi's "(4+1)/(B+1)" accuracy warning (BLP 230-247).

Scaling back. Because q is scale-free, CI_orig = (bproj - se_int * q)/sds = bhat - se * q, using the stored bhat and se (already divided by sds). No further sds handling is needed. The default parm (all) gives G = {1, ..., p}, the case the paper singles out, and needs no p x B storage.

Checked in R: in a heteroscedastic example with n = 100, p = 50 and the xyz-paired bootstrap with B = 200, qmax(0.975) = 4.01, qmin(0.025) = -4.18 and qabs(0.95) = 3.95. The corresponding Bonferroni normal quantile is 3.29. The Gaussian-wild and Mammen-wild quantiles (B = 100) were about 3.1 / -2.8 and 2.8 / -2.9. Both CI versions covered all of beta in that run.

### group_pvalue

Paper, Sect. 3.2, p. 694, and Sect. 4.3: P_G = P*0[ max_{j in G} |T*0_j| > max_{j in G} |t_j| ]. Here t_j = b_hat_j / se_j is the observed statistic, not centred, and T*0 is the bootstrap under H0,complete. For the residual or Gaussian-wild bootstrap this is Y*0 = eps* (eq. 14), i.e. hdi's ystar = 0 + rstar (BLP 209-213). For xyz, see xyz_paired. The same H0c distribution serves every group, which is the computational point of using H0c rather than H0,G (restricted subset pivotality, eq. 13).

Exact algorithm, boot.groupTest(object, group):
1. Require object$method == "boot.lasso.proj".
2. If is.list(group), return vapply(group, function(g) boot.groupTest(object, g), numeric(1)). This keeps list names, mirroring hdi's calculate.pvalue.for.group (HLP 183-191). Precompute abs(T0) once when many groups are given.
3. Resolve G: numeric indices, logical of length p, or character names. Sort, take unique values, and error on empty, NA or out-of-range entries.
4. obs <- max(abs(object$tstat[G])). tstat is stored as exactly bproj/se, the expression hdi uses at BLP 182/218.
5. M0 (a B-vector):
   - if length(G) == p, M0 <- object$boot.summary$absmax.H0c. This is identical to hdi's max.t.dist = apply(abs(cboot.dist.underH0c), 2, max) (BLP 216), computed with the same expression.
   - else if G matches a precomputed group, use its stored absmax.H0c;
   - else if !is.null(object$cboot.dist.underH0c): T0 <- object$cboot.dist.underH0c[G, , drop = FALSE] / object$se[G]; M0 <- apply(abs(T0), 2, max);
   - else stop(). The message should say the H0c bootstrap is needed: use multiplecorr.method = "WY" or boot.H0c = TRUE, plus return.bootdist = TRUE or groups = ....
6. P_G <- (sum(M0 >= obs) + 1) / (object$B + 1).

This uses the hdi WY conventions (>= and +1/(B+1)) instead of the paper's strict > with no +1. It keeps P_G on the same grid as pval.corr, {1, ..., B+1}/(B+1), and keeps the finite-B p-value conservative. Ties have probability zero except in degenerate resamples.

|G| = 1. Use the same formula: P_{j} = (1 + #{b: |T*0_jb| >= |t_j|})/(B + 1). Do NOT substitute object$pval[j], even though hdi's lasso.proj group test returns the individual p-value for singletons (HLP 229-231). Reasons: the paper's definition covers every G, and mixing two different bootstrap distributions in one list of groups would be incoherent. Document that P_{j} is a symmetric |.| test calibrated by the H0c bootstrap. pval[j] is the equal-tailed, doubled test from the centred bootstrap T* (BLP 182-188). The two are asymptotically equivalent under H0,j but not numerically equal.

Deterministic relations (useful as tests), taking pval.corr from WY:
- P_{1..p} == min(pval.corr) exactly. Checked in R: 0.004975124 for both.
- P_G <= min_{j in G} pval.corr_j. max_{j in G} |T*0| <= max_{all} |T*0| pointwise, and the minimising j is argmax_{j in G} |t_j|.
- In particular P_{j} <= pval.corr_j. Checked: TRUE for all 50 j.

No multiplicity correction is applied across several groups; that is the user's responsibility. hdi's cluster/hierarchical testing is out of scope. The H0,G-specific bootstrap that the paper mentions as an alternative is not implemented, because it needs a new bootstrap per group. P_G exists only when the H0c bootstrap was run. In hdi that happens only for multiplecorr.method = "WY"; see boot.H0c in api_proposal. The minimum attainable value is 1/(B + 1).

### mammen_multipliers

Mammen (1993) two-point distribution:
- W = a = (1 - sqrt(5))/2 = -0.618033988749895 with probability pa = (sqrt(5) + 1)/(2 sqrt(5)) = 0.723606797749979.
- W = b = (1 + sqrt(5))/2 = 1.618033988749895 with probability pb = 1 - pa = (sqrt(5) - 1)/(2 sqrt(5)) = 0.276393202250021.
- Moments (checked in R to 1e-15): E W = 0, E W^2 = 1, E W^3 = 1, E W^4 = 2 < infinity. This satisfies eq. (12): E W = 0, E W^2 = 1, E W^4 finite.
- The third moment of 1 is what makes the wild bootstrap match the skewness of eps.
- Per Theorem 3 (p. 701), (A6) relaxes to log|G| = o(n^{1/5}) for Mammen's wild bootstrap. In Sect. 1.1 the paper also says it found no substantial empirical improvement over Gaussian multipliers.

Draw method (explicit and version-stable). Do not use sample(prob = ...):
  rmammen <- function(n) { s5 <- sqrt(5); ifelse(runif(n) <= (s5 + 1)/(2 * s5), (1 - s5)/2, (1 + s5)/2) }
It consumes exactly n uniforms. runif never returns 0 or 1, and U == pa has probability zero. A Monte Carlo check with 1e6 draws gave moments 0.001, 1.001, 1.001.

Plugging into resample() (HLP 787-800):
  resample <- function(r, B, wild, multiplier = "gaussian") {
    if (wild) {
      Ui <- switch(multiplier,
                   gaussian = replicate(B, rnorm(length(r))),   # hdi verbatim
                   mammen   = replicate(B, rmammen(length(r))))
      rs <- r * Ui
    } else {
      rs <- replicate(B, sample(r, replace = TRUE))              # hdi verbatim
    }
    rs
  }
- r * Ui recycles r down each column, giving eps*W_ib = W_ib * rc_i, as in eq. (12).
- The draw happens at exactly the RNG position where hdi draws rnorm: after calculate.Z and initial.estimator, before any bootstrap Lasso fit. The Gaussian path is therefore bit-identical to hdi. Checked: replicate(B, rnorm(n)) is identical to matrix(rnorm(n*B), n, B).
- The H0c bootstrap automatically reuses the same multipliers (ystar = 0 + rstar), which is eq. (14).

Optional extras, not required: Rademacher (+/-1 with probability 1/2 each; E W^3 = 0, E W^4 = 1) and Mammen's continuous variant V/sqrt(2) + (V'^2 - 1)/2 with V, V' iid N(0, 1), which has the same first three moments (0, 1, 1). If added, extend match.arg choices; the default stays "gaussian".

### xyz_paired

Paper, Sect. 4.2, p. 698-699, plus the H0c sentence in Sect. 4.3, p. 700 and Theorem 3. Everything below is on hdi's internal scale: x and y after prepare.data, Z rescaled so that colSums(Z * x)/n = 1, and betalasso, rc and bproj/se as in the original fit.

STEP 0: original fit. Identical to hdi up to BLP line 105: bproj, se, betalasso, sigmahat, r, rc.

STEP 1: build the xyz matrix (n x (2p + 1)). Let e = rc and s2 = sum(e^2). If s2 <= n * .Machine$double.eps, stop, because the scheme is undefined when the Lasso interpolates.
  xhat <- x - tcrossprod(e, crossprod(x, e)) / s2   # X_hat_j = X_j - (X_j^T e / ||e||^2) e
  zhat <- Z - tcrossprod(e, crossprod(Z, e)) / s2   # Z_hat_j likewise
  yhat <- as.vector(xhat %*% betalasso) + e         # Y_hat = X_hat beta_hat + e
Resulting identities: X_hat^T e = 0, Z_hat^T e = 0, Y_hat - X_hat beta_hat = e, and X_hat, Y_hat have column means 0 (because x is centred and mean(e) = 0). Checked in R with n = 100, p = 50: max|X_hat^T e| = 9.9e-15 against max|X^T e| = 42.1 before the correction; max|Z_hat^T e| = 2e-14.

STEP 2: indices (RNG). Draw all indices up front, at the RNG position where hdi calls resample():
  idx <- replicate(B, sample.int(n, n, replace = TRUE))
This is an n x B integer matrix. It consumes the RNG exactly like hdi's replicate(B, sample(rc, replace = TRUE)); checked that rc[idx] is identical to hdi's rstar under the same seed. Drawing up front lets the H0c pass reuse the same rows, as hdi reuses rstar, and makes the rows independent of parallel scheduling.

STEP 3: per bootstrap sample b, a plug-in of the entire estimator except the nodewise Lasso. For i = idx[, b]:
  xs <- xhat[i, , drop = FALSE]; ys <- yvec[i]; zs <- zhat[i, , drop = FALSE]
  xs <- sweep(xs, 2, colMeans(xs)); ys <- ys - mean(ys); zs <- sweep(zs, 2, colMeans(zs))   # (R1) centre; no re-scaling
  zs <- score.rescale(zs, xs)$Z                                                             # (R2) Z*_j^T X*_j / n = 1
  init <- do.initial.fit(xs, ys, initial.lasso.method = betainit, lambda = lambda)          # (R3) lambda NULL unless boot.shortcut
  bs  <- despars.lasso.est(xs, ys, zs, init$betalasso)
  ses <- est.stderr.despars.lasso(xs, ys, zs, init$betalasso, init$sigmahat, robust)        # sandwich or sigma* ||Z*_j|| / n
  T   <- (bs - boot.truth) / ses
- Centred bootstrap: yvec = yhat, boot.truth = betalasso. T*_j = (b*_j - beta_hat_j)/se*_j, exactly hdi's centring at BLP 156/178.
- Z is never recomputed; the nodewise Lasso is not rerun, which is the paper's stated motivation.
- Loop over b with mcmapply/mclapply(mc.cores = ncores), mirroring hdi's parallel pattern. Never materialise n x p x B arrays. Store only p-vectors into p x B matrices, so the downstream pval/WY/confint code is reused unchanged.

STEP 4: H0,complete (for WY and P_G). Same idx[, b], with yvec = e (that is, Y_hat with beta_hat replaced by 0: X_hat 0 + e) and boot.truth = 0, so T*0_j = b*0_j / se*0_j. Run it after the centred pass, inside the WY branch or when boot.H0c = TRUE, as hdi does.

AMBIGUITIES and recommended resolutions:
(A1) Which rows are resampled under H0c. p. 700 says "For the heteroscedastic residual bootstrap ... i.i.d. resampling of the rows of (eps_cent, X, Z_j)", i.e. without hats and calling it "residual".
  Read it as the xyz-paired bootstrap under H0c: resample rows of (X_hat, e, Z_hat), with Y*0 = e[I*].
  With un-hatted X and Z, E*[X*_j^T eps*] = X_j^T e is not 0. By the Lasso KKT conditions it is about n*lambda for active j; 42.1 in the experiment. The bootstrap world would then not satisfy H0c, which contradicts the paper's own centring requirement on p. 699.
  The residual bootstrap under H0c stays as in hdi: ystar = 0 + rstar with X and Z fixed.
(A2) Normaliser. hdi assumes Z_j^T X_j / n = 1 (despars.lasso.est, and the non-robust se at HLP 729). In the bootstrap sample this no longer holds. In the experiment Z*_j^T X*_j / n ranged 0.56-0.83 over 200 resamples.
  The paper's plug-in rule uses denominators Z*_j^T X*_j in both b_hat* (eq. 2) and |Z*^T X*/n| in se*.
  Resolution: call score.rescale(zs, xs) before despars.lasso.est and est.stderr. This is algebraically identical to the plug-in denominators, including the |.| in se. sandwich.var.est.stderr then skips its own re-scaling (HLP 488-493).
  Guard: stop if any normaliser <= 0; warn if any normaliser < 0.1.
(A3) Centring inside the bootstrap sample. The paper is silent. Recommendation: centre X*, Y* and Z* per sample, but do not re-standardise, because that would change the bootstrap truth.
  Why: it mirrors prepare.data and the column-mean-zero nodewise residuals.
  Why: it is required for betainit = "scaled lasso", because scalreg fits no intercept (hdi sets intercept = 0).
  Why: despars.lasso.est ignores glmnet's intercept, which is harmless only if Z* is centred.
  Checked in R: centred vs uncentred T* differ by a median of 0.037 but by up to 1.16, so this is not negligible at n = 100. Both versions are asymptotically equivalent (the extra term is O_P(1/n)).
(A4) Re-tune the Lasso? Yes, by default. The paper's plug-in rule applies the same betainit method, re-tuning unless boot.shortcut = TRUE, in which case hdi's original lambda is used, as in the residual and wild bootstraps.
  Flag: paired resampling duplicates rows (about 63% are unique). cv.glmnet can then put copies of one observation in both training and test folds, which biases lambda.1se downwards. The paper does not address this.
  Keep plain cv.glmnet for the exact plug-in, document the issue, and suggest boot.shortcut = TRUE as the remedy. A possible future option is foldid by original row id.
(A5) Which standard error. The paper defines xyz with omega_hat* and se*_robust. Allow robust = FALSE for API symmetry, but warn (see interactions).
  The robust se uses hdi's 1/n omega_hat, not eq. (5)'s 1/(n - s_hat); see notation_mapping.
(A6) Scaling of Z before building Z_hat. It does not matter. Z_hat_j is linear in Z_j, and the per-sample rescaling removes any positive column scale. This gives a test: T* is invariant to Z column scaling.
(A7) Theory needs extra conditions (Theorem 3, p. 701): delta = 2, max_j ||Z_j||_2/|Z_j^T X_j| = o_P(1/sqrt(log(2|G|))), and sqrt(log(p)/n) = o_P(...). The paper also notes xyz "may not be competitive" with the Gaussian wild bootstrap. The experiment agrees: xyz simultaneous quantiles were about 4 against about 3 for wild. Document this and do not make xyz a default.

Cost. B (or 2B with H0c) Lasso fits, the same as hdi, plus O(np) per b to form, centre and rescale xs and zs. hdi's B-column vectorisation of despars.lasso.est is lost because the design changes with b. Peak extra memory is 2 n x p per worker plus an n x B integer index matrix.

### interactions

Validity of each combination (paper Theorems 1-3 and Sect. 3.2, 4.4, 5, 6.3):
1. Residual bootstrap, robust = FALSE, homoscedastic errors. Valid for individual CIs and p-values, simultaneous CIs (h(t) = t, -t, |t| with (A6)), WY and P_G (Theorem 1).
2. Residual bootstrap, robust = TRUE, heteroscedastic errors. Individual inference is valid (Theorem 2). Simultaneous inference is INCONSISTENT: simultaneous CIs, P_G with |G| > 1, and strictly also WY. Sect. 3.2 last paragraph and p. 697-698: the residual bootstrap makes errors i.i.d. and does not reproduce the correlation between the b_hat_j.
3. Wild bootstrap (gaussian or mammen) with robust = TRUE. Valid for individual and simultaneous inference, with homoscedastic or heteroscedastic errors (Theorem 3). This is the paper's recommended practical choice (Sect. 5.1.4, 6.3: "the wild bootstrap seems to be the preferred method"). Mammen additionally relaxes (A6) to log|G| = o(n^{1/5}), but the paper saw no clear empirical gain.
4. Wild bootstrap with robust = FALSE. Not covered by the theory. The wild bootstrap reproduces the heteroscedastic variance of b*, but the non-robust studentiser is not consistent. Allow it and document it.
5. xyz with robust = TRUE. Valid under the extra Theorem 3 conditions, but empirically less competitive than Gaussian wild. xyz with robust = FALSE: outside the paper's definition.
6. robust = TRUE is recommended whenever heteroscedasticity is possible. The paper's heteroscedastic example (Fig. 10-11) shows non-robust coverage collapsing. It also notes the WY power gain is "often rather marginal" with robust studentisation.

Warnings and errors to emit. The default boot.lasso.proj path must stay silent beyond hdi's own messages and warnings, to keep the port exact.
- Error: wild = TRUE together with boot.type != "wild" given explicitly. Test: !missing(boot.type) && !missing(wild) && xor(wild, boot.type == "wild").
- Error: multiplier != "gaussian" while boot.type != "wild" ("'multiplier' only applies to the wild bootstrap").
- Error: multiplecorr.method == "WY" && !boot.H0c.
- Warning at fit time: boot.type == "xyz" && !robust. Text: "the xyz-paired bootstrap is defined with the robust standard error (Dezeure et al. 2017, Sect. 4.2); robust = FALSE is not covered by the theory".
- Warning in the new functions (confint type = "simultaneous", or boot.groupTest with |G| > 1) when object$boot.type == "residual" && object$robust. Text: "the residual bootstrap is not consistent for simultaneous inference under heteroscedastic errors (Sect. 3.2); use wild = TRUE (or boot.type = 'xyz')". robust = TRUE is the user's signal that heteroscedasticity is a concern. Do NOT add this warning to the ported WY path; document it in the Rd instead.
- Warning in the new functions when gaussian.stub = TRUE: stub distributions are independent N(0, 1) rows with no dependence, so simultaneous and group results reduce to an independence (Sidak-type) approximation.
- Warning when B is too small for the requested level: alpha/2 * (B + 1) < 5 (max-min) or alpha * (B + 1) < 5 (abs). Note the minimum P_G is 1/(B + 1).
- Informative error when the needed distribution was not stored:
  - individual CI without return.bootdist: hdi's existing error, kept verbatim;
  - simultaneous CI, or P_G for G not equal to all, without return.bootdist or groups = ...;
  - P_G without an H0c bootstrap.
- Error from hdi, kept: family != "gaussian"; betainit numeric (boot.initial.fit stops, HLP 742-743), which also applies to xyz.
- boot.shortcut = TRUE is compatible with all three schemes. For xyz, the original lambda is applied to (X*, Y*); this is also the suggested remedy for CV on duplicated rows.
- parallel = TRUE: as in hdi, numbers differ from a serial run and are reproducible only with RNGkind("L'Ecuyer-CMRG"). The xyz indices and the Mammen/Gaussian multipliers are drawn in the main process before any parallel work, so only the per-fit cv.glmnet folds depend on scheduling.
- Several groups: no adjustment across groups; document this.
- confint type = "simultaneous" and boot.groupTest on lasso.proj (non-bootstrap) objects: error, because lasso.proj is ported "core only".

### api_proposal

1) boot.lasso.proj. Keep every hdi argument, its order and its default. Append new arguments after gaussian.stub so that positional calls are unchanged:
  boot.lasso.proj(x, y, family = "gaussian", standardize = TRUE, multiplecorr.method = "WY",
                  parallel = FALSE, ncores = getOption("mc.cores", 2L), betainit = "cv lasso",
                  sigma = NULL, Z = NULL, verbose = FALSE, return.Z = FALSE, robust = FALSE,
                  B = 1000, boot.shortcut = FALSE, return.bootdist = FALSE, wild = FALSE,
                  gaussian.stub = FALSE,
                  boot.type = if (wild) "wild" else "residual",   # c("residual", "wild", "xyz")
                  multiplier = c("gaussian", "mammen"),           # used only when boot.type == "wild"
                  boot.H0c = identical(multiplecorr.method, "WY"),# also run H0c when using p.adjust methods, for P_G
                  groups = NULL)                                  # optional list of groups whose O(B) summaries are stored
Behaviour:
- boot.type <- match.arg(boot.type, c("residual", "wild", "xyz")), with the conflict check from interactions; then wild <- boot.type == "wild". multiplier <- match.arg(multiplier).
- residual and wild: hdi code verbatim, except resample() gains a multiplier argument.
- xyz: see xyz_paired. The new compute.cbootdist.xyz(yvec, boot.truth) replaces BLP 170-178 and 209-213.
- With default new arguments, RNG consumption and all returned hdi fields are bit-identical to hdi 0.1-10. When boot.H0c = TRUE with a p.adjust method, the H0c pass runs after pcorr, so pval and pval.corr are unchanged.
- The non-WY p.adjust accuracy warning (BLP 230-247) is kept verbatim.

2) Result object. Use a SILM-owned class, e.g. class = c("silm_boot", "silm_proj"). These names are placeholders; they must match whatever the lasso.proj stream picks, for example "silm_proj" for lasso.proj.
- Keep all hdi fields in hdi's order and with hdi's names: pval, pval.corr, sigmahat, standardize, sds, bhat, se, betahat, family, method = "boot.lasso.proj", B, boot.shortcut, lambda, call, [Z], [cboot.dist = se/sds * T*], [cboot.dist.underH0c = se/sds * T*0]. Name bhat, se etc. by colnames(x), as hdi does.
- Append:
  boot.type; multiplier (NULL unless wild); robust.
  tstat = bproj/se, named, exactly the hdi expression.
  boot.summary = list(max = apply(T*, 2, max), min = apply(T*, 2, min), absmax = apply(abs(T*), 2, max), absmax.H0c = apply(abs(T*0), 2, max) or NULL). absmax.H0c is byte-identical to hdi's max.t.dist.
  group.summary: if groups is given, a list of list(index = G, max, min, absmax, absmax.H0c).
  boot.index: the n x B integer matrix, only for xyz and only when return.bootdist = TRUE.
- The O(B) summaries are always stored. They make simultaneous CIs over all p and P_{all} available without p x B storage, and give exact identities with pval.corr.

3) S3 methods.
- print.silm_proj: hdi's print.hdi falls through to print.default for these methods. Replace it with a short summary: method, boot.type, multiplier, robust, B, and the significant variables at 0.05 and 0.01 using pval.corr.
- confint.silm_proj(object, parm, level = 0.95, type = c("individual", "simultaneous"), group = NULL, simult.stat = c("maxmin", "abs"), ...).
  - type = "individual" is confint.hdi's code verbatim for lasso.proj and boot.lasso.proj, including the quantile-type rule and the error when cboot.dist is missing.
  - type = "simultaneous" follows simultaneous_ci and is allowed only for method == "boot.lasso.proj". G = group, which defaults to parm; parm must be a subset of G. Missing parm gives G = all p (the paper's main case), served from boot.summary.

4) Group test (not a closure, since hdi's groupTest and clusterGroupTest are out of scope):
  boot.groupTest(object, group)
- group is an integer, logical or character vector, or a (named) list of them.
- Returns a numeric vector of P_G, named from the list.
- Requires the H0c distribution: for G = all, boot.summary$absmax.H0c; for a precomputed group, group.summary; otherwise return.bootdist = TRUE. This requires multiplecorr.method = "WY" or boot.H0c = TRUE.

5) Memory. One p x B double matrix is 8pB bytes: 4 MB at p = 500, B = 1000; 32.7 MB at p = 4088 (riboflavin); 160 MB at p = 20000.
- hdi already materialises about 5-6 such arrays during the fit (bstar, sestar, betainitstar, cboot.dist, dist and its logical copy, counts.matrix), each twice when WY is used.
- return.bootdist = TRUE adds 2 p x B to the result. Do not also store unscaled copies; recover T* by dividing by se, which is exact to about 1 ulp.
- The always-stored summaries are 4B doubles (32 KB), and 4B per group in groups.
- xyz must loop over b and never build n x p x B arrays.
- Optional speed-up that keeps the counts identical: WY counts can be computed as B - findInterval(abs(tstat), sort(max.t.dist), left.open = TRUE), avoiding the p x B logical matrix. Only do this if it is shown to give identical integers; otherwise keep hdi's sapply verbatim.

6) Documentation.
- Cite Dezeure, Buhlmann & Zhang (2017), TEST 26:685-719, doi:10.1007/s11749-017-0554-2.
- State which parts are hdi-identical and which are SILM additions not present in hdi.
- Recommend robust = TRUE with wild = TRUE for heteroscedastic data.


### Verifier corrections (these take precedence over the text above)

The spec mostly matches the paper (read pp. 688-704 and 711-717 as images and text) and the hdi 0.1-10 sources.

What checks out:
- **Mammen law:** a = (1-√5)/2 with probability (√5+1)/(2√5), b = (1+√5)/2 otherwise. Moments 0, 1, 1, 2, verified in R.
- **Eq. (10) directions:** lower = b̂ − se·qmax(1−α/2), upper = b̂ − se·qmin(α/2). The abs variant is b̂ ∓ se·qabs(1−α), and T* is the centred eq. (8) statistic. The √n in C(1−α) is a typo.
- **P_G:** uses the H0,complete bootstrap, with (#{M0 ≥ obs} + 1)/(B + 1). The identity P_all == min(pval.corr) and the bound P_G ≤ min over G of pval.corr are exact.
- **xyz formulas:** the hat corrections reproduce in R (max|X̂ᵀe| drops from 60.9 to 2e-14).
- **What is recomputed per draw:** the Lasso fit and σ̂*, the normaliser Z*ᵀX*, b*, ω̂* and se*. Z itself is not recomputed.
- **H0c for xyz:** must use the hatted rows. Un-hatted Zᵀe/n was up to ±0.6 in the check.
- **RNG equivalences:** sample.int indices and rnorm via replicate draw the same stream as hdi. For common levels hdi always uses quantile type 7 (never type 1 for levels 0.8–0.99, B = 100–2000).
- **Stored objects:** the O(B) summaries plus the optional p×B matrices, tstat, se and B are enough to compute every simultaneous CI and P_G in confint() and group tests afterwards.

What needs fixing, by severity:
1. **Exact port breaks (notation_mapping).** The original non-robust se is `sigmahat*sqrt(diag(crossprod(Z)))/nrow(x)` (hdi_helpers.R line 729), not `colSums(Z^2)`. The two are not identical() in R, so the bit-identical fixtures would fail.
2. **xyz cost (xyz_paired).** Calling hdi's `score.rescale` per draw computes `diag(crossprod(Z, x))`, which is O(np²) per draw. That contradicts the "O(np)" claim and is expensive at p = 4088. Use `colSums(zs*xs)/n`. Also:
   - Aborting the whole run on one normaliser ≤ 0 is too harsh.
   - Behaviour with gaussian.stub is unspecified.
3. **API gaps.**
   - `gaussian.stub` is never stored, but a warning in the new functions depends on it.
   - `confint(obj, type = 'simultaneous', group = G)` with parm missing wrongly errors; parm should default to G.
4. **Interactions.** The warning for residual bootstrap with robust = TRUE rests on "robust signals heteroscedasticity". The paper (p. 693) recommends always using the robust se, and the residual bootstrap is valid for simultaneous inference under homoscedasticity (Theorem 1, Sect. 4.4.1).
5. **Citations.** The "preferred method" quote is from Sects. 4.4.1 and 6.3, not 5.1.4. The o(n^{1/5}) relaxation of (A6), stated after Theorem 3, covers both Mammen-wild and xyz.
6. **Test ideas.**
   - "qabs ≥ −qmin" fails for quantile type 1; counterexample found in R.
   - The symmetry and containment checks need a tolerance.
   - The sandwich test should use the Lasso β*, not bs.
   - The Z-scaling invariance test is vacuous, because calculate.Z rescales any user Z first.

Sources: the paper (doi:10.1007/s11749-017-0554-2) and the hdi 0.1-10 files hdi_boot.lasso-proj.R, hdi_helpers.R, hdi_methods.R and helpers.nodewise.R, plus the hdi Rd fetched via gh api.

**notation_mapping**: Most of the mapping checks out against BLP/HLP/NW and the paper. I verified: prepare.data; r and rc; bproj; the robust se as the 1/n omega (p. 697 form, not eq. 5's 1/(n - s_hat)); the robust.div.fixed branch multiplying by n/(n - s) rather than sqrt; T* and T*0; the resample() RNG; the pval formula (BLP 182-188) and WY (BLP 216-221, >= and +1); cboot.dist = se/sds*T*; and the Rd/code name mismatch (the Rd says 'cboot.dist.underH0', the code says 'cboot.dist.underH0c'). Errors and omissions:
(1) FACTUAL, and it breaks the exact port. The non-robust se of the ORIGINAL fit at HLP 729 is (sigmahat*sqrt(diag(crossprod(Z))))/nrow(x), not sigmahat*sqrt(colSums(Z^2))/n. Only boot.se (HLP 780) uses colSums(Z^2). I checked in R 4.5.2: sqrt(diag(crossprod(Z))) and sqrt(colSums(Z^2)) are NOT identical() (5 of 50 entries differ, 1.7e-16 relative). colSums accumulates in long double; BLAS does not. Using colSums in the port changes se, bhat/se, tstat, and possibly pval counts at ties, so the identical()-to-hdi fixtures would fail.
(2) Minor. 'The glmnet intercept ... does not enter any later formula' is not quite true. For 'cv lasso', sigmahat uses residual.vector = y - predict(glmnetfit, x) (HLP 589), which includes the intercept. The df count sum(coef != 0) (HLP 591) also counts the intercept whenever it is not exactly 0. The intercept is absent only from r/rc and bproj.
(3) Omission. A user-supplied sigma overrides sigmahat and emits a warning (HLP 609-643). It is used only for the original se. The bootstrap always uses the refitted sigmahatstar.
(4) Omission. With betainit = 'scaled lasso', initial.estimate$lambda is NULL, so boot.shortcut = TRUE silently has no effect.

*Corrected:* Replace the s.e._j line with: s.e._j (eq. 4) -> se = (sigmahat*sqrt(diag(crossprod(Z))))/nrow(x) when robust = FALSE (HLP 729). Port this expression verbatim. Do not use colSums(Z^2): it is not bit-identical (verified). The bootstrap s.e.* (HLP 780) does use outer(sqrt(colSums(Z^2))/nrow(x), sigmahatstar); keep that verbatim too.
Amend the beta_hat line: the intercept is excluded from r, rc and bproj, but for 'cv lasso' it enters sigmahat through predict() and through the nonzero-count df (HLP 589-591).
Add: if sigma is supplied, sigmahat = sigma is used for the original se only; the bootstrap uses the refitted sigmahatstar. boot.shortcut has no effect for betainit = 'scaled lasso' because lambda is NULL.
Everything else stands as written.

**simultaneous_ci**: The mathematics is correct. The quantile directions match eq. (10): the region C(1-alpha) requires (b_hat - b)/se <= qmax(1-alpha/2) and >= qmin(alpha/2), which gives lower = b_hat - se*qmax(1-alpha/2) and upper = b_hat - se*qmin(alpha/2). T* is the centred eq. (8) statistic ('with T*_j as in (8)', p. 693-694). The |T*| variant is b_hat -/+ se*qabs(1-alpha). The sqrt(n) on p. 693 is inconsistent with eq. (8)/(10) and should be dropped. The union-bound remark is correct. Scale-back through the stored bhat/se is valid. I verified the quantile-type quirk in R: for levels {0.8, 0.9, 0.95, 0.99} and every B in 100..2000, neither (alpha/2*B)%%1 nor (alpha*B)%%1 is ever 0, so hdi always uses type 7. For level 0.5 and 0.75, type 1 occurs. The stored objects suffice: level-free M/m/A for all p and for the precomputed groups, and cboot.dist/se for any other G.
One API defect remains. G defaults to parm, and a missing parm becomes all p. So confint(obj, type='simultaneous', group=1:5) with parm missing sets parm = all p and then trips the 'parm not in G' error. This is the most natural call, and it fails.

*Corrected:* Step 2/3: if (missing(parm) && !is.null(group)) parm <- names/indices of G; else if missing(parm), parm <- all and G <- all. Then G <- if (is.null(group)) parm else resolve(group). Error if parm is not a subset of G. Everything else is unchanged: maxmin uses qtype from (alpha/2*B)%%1; abs uses qtype from (alpha*B)%%1; the lookup order is boot.summary (G = all) -> group.summary -> cboot.dist[G,]/se[G] -> error.

**xyz_paired**: The construction is correct against p. 698-699. X_hat_j = X_j - (X_j^T e/||e||^2)e, Z_hat_j likewise, Y_hat = X_hat beta_hat + e, with e = eps_hat_cent. The centred truth is beta_hat (betalasso). Z is not recomputed, but beta_hat*, sigma_hat*, b*, omega_hat* and se* all are, with the normaliser Z*^T X* per draw.
I reproduced the identities in R (n = 100, p = 50, cv.glmnet). max|X^T e| = 60.9 before the correction and 2.1e-14 after; max|Z_hat^T e| = 2.2e-14; the column means of X_hat and Y_hat are about 1e-16. Z_hat^T X_hat/n ranged 0.92-1.00, so per-draw renormalisation is needed. The (A1) reading is sound: with un-hatted Z, Z^T e/n ranged -0.57 to 0.64, so un-hatted H0c rows would not be centred at 0. Indices drawn by sample.int are identical to hdi's sample(rc, replace = TRUE) stream (verified). Per-sample score.rescale is algebraically the plug-in denominator, including the |.| in se. Centring without re-standardising is defensible; glmnet standardises internally anyway.
Defects:
(1) EFFICIENCY/CORRECTNESS OF THE COST CLAIM. STEP 3 calls hdi's score.rescale(zs, xs). That function computes diag(crossprod(Z, x))/n (NW 366-377), which forms a p x p matrix: O(n p^2) per draw, done B or 2B times. For riboflavin (n = 71, p = 4088) that is about 1.2e9 flops per draw, comparable to or larger than the cv.glmnet fit. This contradicts the stated 'O(np) per b'. Use colSums(zs * xs)/n. The normalisation check in sandwich.var.est.stderr (HLP 488) already uses colSums and passes at 1e-8, so it will not re-rescale.
(2) Robustness. The guard 'stop if any normaliser <= 0' aborts the whole B-loop because of a single bad resample. Better: warn and record the draw (or error only if more than a small fraction fail).
(3) Clarify that the non-robust se* uses the sigmahat from do.initial.fit on (xs, ys), and that a user-supplied sigma is ignored in the bootstrap, as in hdi.
(4) gaussian.stub interplay is unspecified. With gaussian.stub = TRUE, hdi skips resampling entirely. The xyz setup (hat matrices and index draws) must also be skipped so that the RNG use matches hdi.
(5) The related test idea is wrong. It says 'sandwich.var.est.stderr applied to (xs, ys, bs, zs)', but the robust se uses residuals from the Lasso beta* (init$betalasso), not from the de-sparsified bs.
(6) The Z-column-scaling invariance test is vacuous. calculate.Z already rescales any user Z so that Z^T X/n = 1 before xyz starts, so it passes even without per-draw rescaling. Test the per-sample function directly with Z_hat %*% diag(c).

*Corrected:* STEP 3 (R2): replace zs <- score.rescale(zs, xs)$Z with
  nz <- colSums(zs * xs)/n
  if (any(!is.finite(nz) | nz <= 0)) { flag draw b; warning at end with the count }
  zs <- sweep(zs, 2, nz, '/')
This is O(np) and equals the plug-in denominators. est.stderr.despars.lasso(xs, ys, zs, init$betalasso, init$sigmahat, robust) then needs no internal rescaling. The non-robust se* is init$sigmahat*sqrt(colSums(zs^2))/n; a user sigma is ignored.
Add: if gaussian.stub, do not build xhat/zhat and do not draw idx (hdi RNG path).
Fix the test ideas: the sandwich check uses init$betalasso, not bs. The scale-invariance test calls the internal per-sample function with zhat %*% diag(c) instead of going through calculate.Z.
The rest of STEPS 0-4 and (A1)-(A7) stand. In (A7), add that the o(n^{1/5}) relaxation of (A6) also applies to xyz.

**interactions**: The validity table matches the theory. Theorem 1 covers residual + non-robust + homoscedastic, including simultaneous inference with (A6). Theorem 2 covers residual + robust for individual inference only. Theorem 3 covers wild (any multiplier satisfying eq. 12) + robust, individual and simultaneous; xyz additionally needs delta = 2 and the Z-norm/rate conditions. p. 694/697-698 establish that the residual bootstrap is inconsistent for simultaneous inference under heteroscedasticity.
Problems:
(1) The rationale for warning on residual && robust is mis-grounded: 'robust = TRUE is the user's signal that heteroscedasticity is a concern'. The paper says on p. 693: 'We propose to always use this robust standard error in practice', and repeats it in Sect. 5.1.4. Users following that advice with the default residual bootstrap will be warned on every simultaneous call, even when errors are homoscedastic. In that case the residual bootstrap is fine; see 4.4.1: 'The residual bootstrap also works for simultaneous inference as discussed in Theorem 1'. Conversely, residual + robust = FALSE under heteroscedasticity is also invalid, and it gets no warning.
(2) Citation: the phrase 'the wild bootstrap seems to be the preferred method' is in Sect. 4.4.1 (p. 702) and Sect. 6.3, not Sect. 5.1.4. Sect. 5.1.4 recommends the bootstrap with the robust se and notes that the Gaussian multiplier bootstrap performs well.
(3) Item 3/5: the (A6) relaxation to o(n^{1/5}) applies to xyz too, not only to Mammen.
(4) The gaussian.stub warning in the new functions requires a stored flag, which the api_proposal does not store.
(5) Unspecified: gaussian.stub combined with boot.type = 'xyz' or multiplier = 'mammen'. Either error, or document that the stub overrides them.
(6) Item 4 (wild + non-robust) is plausibly fine under homoscedasticity but not covered by a theorem; 'allow and document' is fine.
(7) 'coverage collapsing' for Fig. 10-11 is overstated. The average coverage is still about 95%; only the worst coefficients drop to 66-83%.

*Corrected:* Replace the residual-bootstrap warning with a trigger that does not depend on robust. In confint(type = 'simultaneous') and in boot.groupTest with |G| > 1, when object$boot.type == 'residual', emit a one-time message or warning: 'the residual bootstrap is valid for simultaneous inference only under homoscedastic errors (Dezeure et al. 2017, Thm 1 vs Sect. 3.2); under heteroscedasticity use boot.type = "wild" (recommended, with robust = TRUE) or "xyz"'. Alternatively, document this only and do not warn. Also drop the claim that robust = TRUE signals heteroscedasticity.
Add: gaussian.stub = TRUE with boot.type = 'xyz' or with multiplier != 'gaussian' -> error (or document that the stub overrides them). The warning in new functions reads object$gaussian.stub.
Fix citations: the 'preferred method' quote is from Sects. 4.4.1/6.3. The o(n^{1/5}) relaxation applies to both Mammen-wild and xyz.

**api_proposal**: Most of it is sound. New arguments appended after gaussian.stub keep positional compatibility. hdi field names and order are kept (checked against BLP 266-299, including lambda = NULL being retained by list()). tstat and the always-stored O(B) summaries (absmax.H0c equals hdi's max.t.dist when computed the same way) plus the optional cboot.dist/cboot.dist.underH0c are enough to compute every simultaneous CI and P_G post hoc. The memory arithmetic is right: 4 MB, 32.7 MB, 160 MB. The findInterval shortcut is algebraically right: B - #{v < x} = #{v >= x}. boot.H0c = TRUE with p.adjust leaves pval and pval.corr unchanged, because p.adjust uses no RNG.
Gaps:
(1) The result object does not store gaussian.stub, yet interactions requires a gaussian.stub warning in confint(simultaneous) and boot.groupTest. match.call() records it only if the user passed it explicitly.
(2) The confint signature inherits the parm/group default bug from simultaneous_ci.
(3) The class-name placeholders must be coordinated with the lasso.proj stream (acknowledged).
(4) Specify that boot.index is stored only when boot.type = 'xyz' and not gaussian.stub.
(5) Several test ideas are numerically unsound:
  - 'qabs_G(1-alpha) >= -qmin_G(alpha)' fails for quantile type 1. Verified in R with a singleton, all-negative T*, B = 100, alpha = 0.5: qabs = 0.7150 < -qmin = 0.7201, because type 1 is not symmetric under negation. It holds for type 7.
  - '(lower+upper)/2 == bhat' and 'simultaneous contains individual' for |G| = 1 need all.equal or a tolerance. cboot.dist/se versus direct quantiles differ by an ulp.
  - The memory test can trip on Z when return.Z = TRUE and n >= B.

*Corrected:* Append to the result: gaussian.stub (logical), next to boot.type, multiplier and robust. Store boot.index only for boot.type == 'xyz' && !gaussian.stub && return.bootdist.
confint.silm_proj(object, parm, level = 0.95, type = c('individual', 'simultaneous'), group = NULL, simult.stat = c('maxmin', 'abs'), ...). For type = 'simultaneous': if parm is missing and group is given, parm <- G; if both are missing, G = parm = all.
Test fixes:
  - Check qabs >= -qmin only with type 7, or compare order statistics directly.
  - Use all.equal for the symmetry and |G| = 1 containment checks.
  - Exclude Z from the memory-size assertion.
The rest stands.


### Test ideas

- Exact port regression: on a machine with hdi 0.1-10 installed, generate .rds fixtures once. Under set.seed(k), for n=50, p=20, B=50, run (i) defaults, (ii) wild=TRUE, (iii) robust=TRUE, (iv) boot.shortcut=TRUE, (v) multiplecorr.method='holm', (vi) return.bootdist=TRUE, (vii) betainit='scaled lasso'. Assert that SILM's pval, pval.corr, bhat, se, betahat, sigmahat, lambda, cboot.dist, cboot.dist.underH0c and confint() output are identical() to hdi's, and that .Random.seed after the call is identical.
- New arguments at their defaults do not change RNG use: boot.lasso.proj(..., boot.type='residual', multiplier='gaussian') gives identical() results and the same .Random.seed as the call without them. With multiplecorr.method='holm', boot.H0c=TRUE leaves pval and pval.corr identical to boot.H0c=FALSE; only the extra H0c fields are added.
- Mammen constants and moments, analytic: with a=(1-sqrt(5))/2, b=(1+sqrt(5))/2, pa=(sqrt(5)+1)/(2*sqrt(5)), check pa*a+pb*b=0, pa*a^2+pb*b^2=1, pa*a^3+pb*b^3=1 and pa*a^4+pb*b^4=2, each within 1e-14.
- Mammen draws: rmammen(1e6) takes only the two values a and b. The proportion equal to a is within 4 standard errors of pa. The sample moments 1..3 are within 4 Monte Carlo standard errors of (0,1,1).
- Mammen RNG accounting: after set.seed(s); rmammen(n*B), .Random.seed equals the state after set.seed(s); runif(n*B). resample(r, B, TRUE, 'mammen') equals r * replicate(B, rmammen(length(r))) under the same seed.
- Gaussian wild path is verbatim: resample(r, B, TRUE, 'gaussian') is identical() to r*replicate(B, rnorm(length(r))), which is identical() to r*matrix(rnorm(n*B), n, B) (verified).
- Residual resampling equals index resampling: under the same seed, replicate(B, sample(rc, replace=TRUE)) is identical() to matrix(rc[replicate(B, sample.int(n, n, TRUE))], n, B) (verified). This confirms the xyz index draw uses the RNG exactly like hdi's residual draw.
- xyz construction identities: max|crossprod(xhat, rc)|, max|crossprod(zhat, rc)| and max|yhat - xhat %*% betalasso - rc| are each < 1e-10*scale, and colMeans(xhat) and mean(yhat) are about 0. Exact bootstrap expectations: (1/n)*sum_i xhat[i,]*rc[i] = 0 and mean(rc) = 0, so E*[X*^T eps*] = E*[Z*^T eps*] = E*[eps*] = 0. Add a Monte Carlo check over 1e4 index draws.
- xyz identity resample: the internal per-sample function with idx = 1:n and the initial estimator injected as betalasso (mock do.initial.fit) must give b* = betalasso exactly (tolerance 1e-10) and hence T* = 0, because Z_hat is orthogonal to rc after centring and rescaling.
- xyz normaliser: inside the per-sample function, colSums(zs*xs)/n equals 1 (tolerance 1e-10) after score.rescale. sandwich.var.est.stderr applied to (xs, ys, bs, zs) equals n^{-1/2}*omega_hat*/|Z*^T X*/n| computed directly from the unrescaled zs.
- xyz invariance to Z column scaling: under the same seed, boot.lasso.proj(..., Z=Z0, boot.type='xyz') and (..., Z=Z0 %*% diag(runif(p, 0.5, 2))) give all.equal cboot.dist (tolerance 1e-8).
- xyz H0c reuses the indices: with return.bootdist=TRUE, boot.index is stored. Recomputing a single column b by hand for both the centred pass (yhat, truth betalasso) and the H0c pass (rc, truth 0) reproduces cboot.dist[,b]/se and cboot.dist.underH0c[,b]/se, provided cv.glmnet's folds are fixed via boot.shortcut=TRUE.
- Simultaneous CI with a singleton group equals the individual CI: for each j, confint(obj, parm=j, type='simultaneous', group=j, simult.stat='maxmin') is all.equal (tolerance 1e-12) to confint(obj, parm=j), because max=min=T*_j and the same quantile-type rule is used. Check both level=0.95 (type 7 through the float quirk) and level=0.5 with B=100 (type 1).
- Simultaneous CI contains the individual CI, deterministically, for type 1 and type 7: for every j in G, lower_simult <= lower_indiv and upper_simult >= upper_indiv. Nesting also holds: if G1 is a subset of G2 then CI_G1 is contained in CI_G2, for both maxmin and abs.
- The abs version is symmetric: (lower+upper)/2 == bhat[parm]. qabs_G(1-alpha) >= qmax_G(1-alpha) and qabs_G(1-alpha) >= -qmin_G(alpha). A higher level gives wider intervals.
- Storage paths agree: under the same seed, the simultaneous CI over all p from boot.summary (return.bootdist=FALSE) equals the one from the full matrix (return.bootdist=TRUE), within 1e-12. P_G for a group precomputed via groups= equals P_G from the full matrix.
- Group p-value identities: boot.groupTest(obj, 1:p) == min(obj$pval.corr) exactly (identical, using boot.summary$absmax.H0c and tstat; verified in an R experiment). For random groups G, boot.groupTest(obj, G) <= min(obj$pval.corr[G]). For every j, boot.groupTest(obj, j) <= obj$pval.corr[j]. All values lie on the grid k/(B+1) with k from 1 to B+1.
- Group input handling: numeric, logical and character specifications of the same G give identical P_G. Duplicate indices and permuted order do not change the result. A named list returns a named vector. Empty, NA or out-of-range groups error. Without an H0c distribution (multiplecorr.method='holm', boot.H0c=FALSE), the function errors with an informative message.
- Singleton relation (soft): under a global-null simulation, boot.groupTest(obj, j) and obj$pval[j] are strongly correlated across j (e.g. Spearman > 0.8) but are not required to be equal. Document the difference.
- Argument validation: wild=TRUE with boot.type='xyz' errors. multiplier='mammen' with boot.type='residual' errors. boot.type defaults to 'wild' when wild=TRUE. boot.H0c=FALSE with 'WY' errors. boot.type='xyz' with robust=FALSE warns. A simultaneous CI or group test on a residual-bootstrap object with robust=TRUE warns. B too small for the level warns. gaussian.stub objects warn in the new functions.
- Class and methods: inherits(obj, 'hdi') is FALSE. print() returns the object invisibly. confint dispatches for both lasso.proj and boot.lasso.proj objects. type='simultaneous' on a lasso.proj object errors.
- Memory: with return.bootdist=FALSE, no element of the result has length >= p*B (boot.summary vectors have length B), and object.size is far below 8*p*B. With return.bootdist=TRUE, cboot.dist is p x B with rownames equal to colnames(x).
- Slow statistical tests (skip_on_cran): with n=100, p=30, Toeplitz 0.5 design and 200 replications at B=200, check (a) the joint coverage of wild+robust simultaneous CIs (maxmin and abs) over G=all lies in [0.88, 0.99] for heteroscedastic errors; (b) under the global null, the rejection rate of P_G<=0.05 for G=all and for a fixed |G|=5 group is within [0, 0.10] for wild (gaussian and mammen) and xyz with robust=TRUE; (c) the residual bootstrap with robust=TRUE under strong heteroscedasticity may show distorted simultaneous coverage. This is a documentation example, not an assertion.


## Appendix D. Verified SILM 1.0.0 findings


### [package] Package cannot be installed: hard dependencies on archived scalreg and hdi (hdi used through an internal, unexported function)
*Severity:* critical; *category:* packaging; *changes default:* False

*Trigger:* install.packages('SILM') or remotes::install_github(...) with the current DESCRIPTION/NAMESPACE: dependency 'scalreg' (and 'hdi') not available.

*Action:* Fix now; this blocks installation. Vendor the listed hdi helpers into R/ and call them directly, crediting all five hdi authors (Dezeure as author of the file) as ctb/cph. Drop import(hdi), getFromNamespace and the scalreg Depends. For the scaled lasso, either vendor scalreg()/slassoEst() and license SILM as GPL-2, or reimplement it on top of lars and check it reproduces scalreg 1.0.1 coefficients and hsigma to about 1e-10. Keep Imports: lars and glmnet.

### [package] Since hdi 0.1-7, SILM's nodewise lasso silently uses the Z&Z lambda instead of the paper's 10-fold CV lambda; lambdatuningfactor=1 is ignored
*Severity:* medium; *category:* statistical-fidelity; *changes default:* True

*Trigger:* Any SR/Sim.CI/Step call with p > floor(n/2), and every ST call, under hdi >= 0.1-7.

*Action:* Fix behind an explicit argument, e.g. nodewise.tuning = c('cv','ZnZ') mapped to do.ZnZ=FALSE/TRUE, and never rely on an upstream default again. Suggested default: 'cv', which matches the paper and the intent shown by lambdatuningfactor=1. Add a NEWS entry saying results differ from SILM installed with hdi >= 0.1-7, and that 'ZnZ' reproduces that behaviour. If continuity with 2019-2026 installs matters more, default to 'ZnZ' and document it instead.

### [SR] solve(Gram) fails when p <= n/2 but X is rank-deficient (duplicate columns, full dummy coding, zero column)
*Severity:* low; *category:* numerical; *changes default:* False

*Trigger:* X <- matrix(rnorm(1000),100,10); X[,10] <- X[,9]; SR(X, Y) -> Error in solve.default(Gram): system is exactly singular

*Action:* Fix now, with no change to default outputs. Before solve(), check qr(X)$rank < p and stop with an informative message naming the aliased columns, or fall back to the nodewise Theta. Keep solve(Gram) for full-rank designs so results stay bit-identical; do not switch to chol2inv. Also fold in the documentation point from the duplicate entry: say in the Rd files that when p <= floor(n/2), Theta is the exact inverse Gram and the de-biased estimator is no-intercept OLS.

### [package] Constant columns (including an intercept column of 1s) crash the nodewise-lasso path, including constant-within-D2 columns in ST
*Severity:* medium; *category:* edge-case; *changes default:* False

*Trigger:* X <- cbind(1, matrix(rnorm(100*60),100)); SR(X, Y) -> Error in elnet(...): y is constant; gaussian glmnet fails at standardization step

*Action:* Fix now, with no default change for valid inputs. Reject or drop zero-variance columns with an informative error, and document that no intercept column should be supplied. In ST, drop columns that are constant within D2 from screen.set, and replace every '-set1' index with setdiff(1:p, set1) so an empty lasso set works. Clamp the screening size to be >= 0, and fix the 'rejct' typo and the duplicate names. The empty-set1 fix should be treated as high priority for ST.

### [package] No input validation: data.frame / character / NA inputs, and length mismatches, fail deep inside with cryptic errors
*Severity:* low; *category:* edge-case; *changes default:* False

*Trigger:* SR(as.data.frame(X), Y) -> Error in t(X) %*% X: requires numeric/complex matrix/vector arguments

*Action:* Fix now. A shared check_inputs() (as.matrix, numeric and NA checks, length match, set within 1:p, M a positive integer, alpha in (0,1)) leaves outputs unchanged for valid inputs. Also note in Sim.CI.Rd that its alpha is the confidence level (0.95), unlike Step and ST where alpha is the significance level.

### [package] Bootstrap loops and Omega are computed inefficiently (O(|set| p n) per draw, O(p^3) for Omega); Step pays this for every step
*Severity:* low; *category:* numerical; *changes default:* False

*Trigger:* Step(X, Y) or Sim.CI(X, Y, 1:p) with p around 1000 or more takes minutes in the bootstrap alone.

*Action:* Fix now. The changes keep outputs identical under set.seed up to floating-point rounding. Precompute A = Theta %*% t(X), compute beta.db and Omega from A, and vectorise the bootstrap. Process the draws in chunks if n*M*|set| is large.

### [package] Hardcoded parallel=FALSE/ncores=2, hdi message() output that verbose=FALSE does not silence, and no way to reuse Theta
*Severity:* low; *category:* api-design; *changes default:* False

*Trigger:* for (r in 1:1000) Step(X, Y) prints 2000 hdi messages; no argument can speed up the nodewise step.

*Action:* Fix now, with no default change. Gate or remove the message() calls in the vendored helpers. Expose parallel/ncores (default FALSE). Add an optional precomputed Theta argument, or an exported helper that returns Theta, so the three functions can share one Theta.

### [package] SIS is imported only for a 4-line standardize(); NAMESPACE imports all of hdi and an unused parallel::mcmapply
*Severity:* low; *category:* packaging; *changes default:* False

*Trigger:* Installing SILM pulls in a large dependency tree for one trivial helper; if gcdnet or msaenet is archived, SILM breaks again.

*Action:* Fix now, with no default change. Inline an identical internal standardize() so ST's screening order is unchanged. Drop SIS and hdi from Imports. Keep importFrom(parallel, mcmapply) only if the vendored helpers keep the parallel option.

### [package] X and Y are never centered or scaled, so de-biasing and omega_jj break for uncentered data (SR, ST, Sim.CI, Step)
*Severity:* high; *category:* statistical-fidelity; *changes default:* True

*Trigger:* Any real-data design with nonzero column means, or a response with an intercept, e.g. X <- matrix(rnorm(n*p), n, p) %*% R + 3; Y <- 5 + X %*% beta + eps; then SR(X, Y), Sim.CI(X, Y, set), Step(X, Y) or ST(...). The Rd examples use mean-zero X and no intercept, so they do not show the problem.

*Action:* Fix with an opt-in flag to keep default outputs unchanged:
1. Add center = FALSE to all four functions. It centers X columns and Y internally; ST should do this per subsample.
2. Optionally add scale = FALSE, which standardizes to ||x_j||^2/n = 1 and maps beta.db, Omega and the CI bands back to the original scale.
3. When center = FALSE and the column means of X or the mean of Y are far beyond sampling noise (e.g. max_j |mean_j|/sd_j > 2*sqrt(2*log(p)/n)), emit a warning recommending center=TRUE.
4. State in every Rd that the model has no intercept, that X should be column-centered and Y centered, and that no intercept column should be passed.
5. Consider making center=TRUE the default in a later major version, with a NEWS entry.

### [ST] ST crashes when cv.glmnet on the screening subsample selects zero variables (common under the null)
*Severity:* high; *category:* bug; *changes default:* False

*Trigger:* set.seed(1); X <- matrix(rnorm(100*200),100); Y <- rnorm(100); ST(X, Y, sub.size=30, test.set=1:200) -> Error in glmnet(x[, -c], x[, c]): x should be a matrix with 2 or more columns

*Action:* Fix now. Use a <- setdiff(seq_len(p), set1), X.sub[, a, drop=FALSE] and k <- max(0, min(n0-1-length(set1), length(a))). Keep the original ordering, screen.set <- union(a[sort(order(abs(beta.m), decreasing=TRUE)[seq_len(k)])], set1), with no outer sort(), so outputs for inputs that already work stay identical. Add a regression test with a global-null dataset. Merge the duplicate 'ST errors whenever the pilot cv.glmnet Lasso selects no variables' into this item.

### [ST] ST crashes or screens one variable too many when the lasso picks >= n0-1 variables (n0-1-length(set1) <= 0)
*Severity:* medium; *category:* edge-case; *changes default:* False

*Trigger:* n=100, p=500, beta_1..30 ~ U(1,2), sub.size=70: ST(X, Y, 70, test.set) -> Error: only 0's may be mixed with negative subscripts (in about 40% of seeds)

*Action:* Fix now, in a way that only affects inputs that currently error. Clamp the screen size with seq_len(max(0, ...)). When length(set1) > n0-1, either stop with an informative error suggesting a smaller sub.size, or truncate set1 to the n0-1 largest |cf| with a warning. Also document in the Rd that sub.size should be well below n/2 (the paper uses n/5 to n/3). The k == 0 'one extra variable' case is rare and paper-inconsistent. Fixing it is acceptable but should be noted in NEWS. It merges naturally with the finding-1 patch.

### [ST] Typo 'rejct' in ST's studentized decision string
*Severity:* medium; *category:* bug; *changes default:* True

*Trigger:* res <- ST(...); res[[4]] == "reject" is always FALSE even when the studentized test rejects.

*Action:* Fix now: change it to "reject" and record it in NEWS.md as a bug fix. Do not change any other part of the return structure in the same step (see the names finding). Merge the duplicate combined finding into this one.

### [ST] ST result list has duplicated names, so rejection decisions are unreachable by name
*Severity:* low; *category:* api-design; *changes default:* True

*Trigger:* res <- ST(X, Y, 30, 4:10); res$`studentized test` gives the statistic; there is no name that returns the studentized decision.

*Action:* Document now: state the positional layout [[1]] nst statistic, [[2]] nst decision, [[3]] st statistic, [[4]] st decision in the Rd \value section. Offer uniquely named, logical/p-value output only behind an opt-in argument (e.g. output = c("legacy","list")) or a new S3 class in a later major version. Leave the default names and order unchanged.

### [ST] ST silently drops test.set variables removed by screening and returns -Inf plus 2M+2 warnings when none survive
*Severity:* low; *category:* edge-case; *changes default:* False

*Trigger:* ST(X, Y, 30, test.set = j) where variable j was not screened in (for example a weak signal with large p): statistics = -Inf, 1002 warnings with M = 500.

*Action:* Fix now, in a paper-faithful way. When length(test.set.i) == 0, return 0/'fail to reject' for both tests, skip the bootstrap, and issue a single warning(). Note in NEWS that the statistic changes from -Inf to 0 and that the RNG stream is no longer advanced in this case. Validate test.set (integers in 1:p) with an informative error. Expose the tested and screened sets as attributes, not new list elements, so the 4-element list stays unchanged. Merge the duplicate '-Inf plus warnings' finding into this one.

### [ST] ST's sub.size is not validated; a proportion such as 0.3 (the paper's c0) or a value >= n crashes with obscure errors
*Severity:* medium; *category:* edge-case; *changes default:* False

*Trigger:* ST(X, Y, sub.size = 0.3, test.set = 4:10) -> error inside cv.glmnet; or p - length(set1) == 1 -> colMeans error.

*Action:* Fix now: use drop=FALSE on every column subset (X.sub[, a, drop=FALSE], Theta[index, , drop=FALSE]). This is required for a stable R CMD check or GitHub Actions run of the Rd example. Also add input validation with clear stop() messages (1 <= floor(sub.size) < n-2, test.set within 1:p). Optionally interpret sub.size in (0,1) as a proportion. That is backward compatible, because such inputs error today, and it should be documented. Consider adding set.seed() to the Rd example.

### [ST] ST always uses the Sec 5.3 Lasso+residual screening, not the Sec 3.2 marginal screening, and this is undocumented
*Severity:* low; *category:* statistical-fidelity; *changes default:* False

*Trigger:* Any ST call: the screened set differs from the Sec 3.2 Step 2 definition; for example, variables selected by the pilot Lasso are always kept.

*Action:* Document now: state in the Rd \details section that ST uses the Sec 5.3 Lasso-plus-residual screening with |B| = |D2|-1. Optionally add an opt-in argument such as screening = c('lasso-residual','marginal') and a screen.size argument, keeping the current default so existing outputs are unchanged.

### [Sim.CI] Sim.CI's 'alpha' is a confidence level (default 0.95) while ST/Step use alpha as a significance level (0.05)
*Severity:* medium; *category:* api-design; *changes default:* False

*Trigger:* Sim.CI(X, Y, set = 1:3, alpha = 0.05) returns bands with about 5% simultaneous coverage instead of 95%.

*Action:* Fix now without changing any default outputs. (1) Keep the signature Sim.CI(X, Y, set, M = 500, alpha = 0.95) so existing positional and named calls give identical results. (2) Rewrite the Rd/roxygen for alpha as: 'Confidence level of the simultaneous bands (default 0.95, i.e. 95% bands). Note: unlike ST() and Step(), where alpha is the significance level, here alpha is the coverage level 1 - alpha of Zhang and Cheng (2017).' (3) Validate the argument: stop() if it is not a single number strictly in (0,1), and warning() when alpha < 0.5, e.g. 'alpha is the confidence level in Sim.CI(); did you mean alpha = 0.95?'. Use a warning rather than an error so existing scripts keep running. (4) Optional: add a new trailing argument conf.level = alpha as the preferred name, placed after alpha so positional calls are unaffected. Do not deprecate alpha yet. (5) Optional: return the level used as an attribute or list element. Mention the change in NEWS.md.

### [Step] Step emits up to 2M warnings and runs a wasted bootstrap when every hypothesis is rejected (empty eta)
*Severity:* low; *category:* edge-case; *changes default:* False

*Trigger:* n = 100, p = 10, all beta_j = 2 (every hypothesis false): Step(X, Y) -> 'There were 50 or more warnings'.

*Action:* Fix now. Guard the empty set: after eta <- eta[rej.nst], if length(eta) == 0, stop the loop, and do the same for eta2. To keep old seeded outputs identical, discard the draws the old code would have used before breaking (invisible(rnorm(n*M))). Otherwise note in NEWS that seeded studentized results can differ in the all-rejected case. Using drop = FALSE is harmless but not needed. Add a regression test that all-false hypotheses give 1:p with no warnings.

### [Step] Step tests two-sided H0,j: beta_j = 0 (the Sec 5.4 setting), not the one-sided Sec 3.3 procedure; the Rd return value is also wrong
*Severity:* low; *category:* documentation; *changes default:* False

*Trigger:* A user expecting the Sec 3.3 one-sided test, or reading the Rd and treating the output as a single vector.

*Action:* Document only, now. In Step.Rd, state that it runs two-sided step-down tests of H0,j: beta_j = 0 for j = 1..p with asymptotic strong FWER control at level alpha, using the Sec 5.4 setting of Zhang & Cheng (2017). State that it returns a named list of two integer vectors, the rejected indices for the non-studentized and studentized statistics. Note that M bootstrap draws are made at each step, and that the results depend on the RNG seed. Keep the return structure and names unchanged. Optionally add null = 0 and alternative = c('two.sided', 'greater') arguments behind defaults that reproduce the current behaviour.


## Appendix E. Verified hdi 0.1-10 fidelity findings


### [high] family='binomial': the intercept is removed by plain mean-centring instead of weighted projection, which gives large bias and invalid CIs
*Where:* hdi_helpers.R:651-670 prepare.data (the centring at lines 666-667) together with switch.family lines 450-458; called from lasso.proj lines 44-53. *Paper:* Not covered by the TEST paper (which is linear-model only). The GLM de-sparsified Lasso in van de Geer et al. (2014, AoS) Sec 3 and Dezeure et al. (2015, Stat Sci) uses the weighted design with an unpenalised intercept, which is equivalent to projecting out sqrt(W)1.

switch.family builds the IRLS working data xw = sqrt(w)*x and yw = sqrt(w)*(b0 + x b) + (y - pi)/sqrt(w). prepare.data then removes the intercept by plain mean-centring of xw and yw. In the weighted problem the intercept column is sqrt(w_i), not 1, so a remainder (sqrt(w_i) - mean(sqrt(w)))*b0 stays in yw. That remainder is correlated with the columns of xw, because w depends on x through pi-hat. Simulations using the sourced hdi 0.1-10 code: (a) n=1000, p=5, b0=-2, beta1=1.5: mean bias of bhat[1] is -0.65 (MC se 0.012). With b0=0 the bias is 0.02. With the same code but sqrt(w) projected out of xw and yw, the bias is 0.03. glm's MLE has bias 0.04. (b) n=500, p=20, b0=-1, beta=(1, 0.5, 0, ...): 95% confint coverage is 0.53 for beta1 and 0.87 for beta2 (60 reps), mean bias -0.19 and -0.10. This makes inference invalid for essentially every logistic model whose intercept is not zero.

*Recommendation:* Fix by default in SILM's lasso.proj. For the binomial family, replace the mean-centring with projection onto the orthogonal complement of sqrt(w): v - sqrt(w)*<sqrt(w),v>/sum(w). Apply it to every column of xw and to yw. Verified above to remove the bias. Document this as a deliberate deviation from hdi. If bit-for-bit parity with hdi is ever needed, keep the old behaviour only behind a non-default legacy argument. The gaussian path is unaffected.

### [high] A numeric betainit is silently read on the internal centred/standardised-x scale
*Where:* hdi_helpers.R:600-649 initial.estimator (numeric branch, lines 615-629); used at hdi_lasso-proj.R:73-76 after x has been standardised at lines 44-49; returned as betahat = betalasso/sds at line 156. *Paper:* De-sparsified Lasso: b = beta_hat + Z^T(Y - X beta_hat)/n (TEST eq. 2, p.690). beta_hat has to be on the same X scale that Z and the regression use.

When standardize=TRUE (the default), prepare.data scales x before initial.estimator is called. A user-supplied numeric betainit is then used directly as the coefficient vector for the standardised x in despars.lasso.est. hdi's Rd never says this. Users naturally pass original-scale coefficients, e.g. from glmnet(x, y). Test with column sds of 0.2 and 5, n=100, p=150, true beta (10, 0.4, 10, 0.4, 0, ...), betainit taken from cv.glmnet on the raw x, sigma=1, same Z: bhat[5] = -9.17 for a null coefficient, and the largest |bhat difference|/se over the first 4 coefficients is 27.9 compared with passing betainit*sds. The returned betahat is betainit/sds (48.1 instead of 8.23), which shows hdi intends the internal scale. boot.lasso.proj rejects numeric betainit altogether (see the boot.shortcut finding).

*Recommendation:* Keep hdi's semantics so ports stay compatible, but document them prominently. Also emit a warning whenever a numeric betainit is combined with standardize=TRUE. Optionally add an opt-in argument such as betainit.scale = c('standardized', 'original'), where 'original' multiplies by sds internally.

### [medium] lasso.proj WY adjustment ignores robust=TRUE: it always uses the homoscedastic correlation Z'Z
*Where:* hdi_lasso-proj.R:101-113 (cov2 <- crossprod(Z); p.adjust.wy(cov = cov2, ...)); hdi_helpers.R:140-161. *Paper:* TEST Sec 2.2 eq. (5) robust s.e.; Sec 4 / 4.3 (simultaneous inference under heteroscedasticity needs the heteroscedastic dependence structure; the residual/homoscedastic calibration is inconsistent).

With robust=TRUE the marginal z-statistics are studentised with the sandwich s.e. However, the Westfall-Young-type minP simulation still draws from N(0, Z'Z), which is the covariance of Z'eps only when errors are homoscedastic. Under heteroscedasticity the correct covariance is Z' diag(sigma_i^2) Z, estimated as crossprod(Z * eps_hat_centred). As a result the joint (max-type) calibration does not match the marginal standardisation that robust=TRUE promises. FWER control can therefore be off in either direction when the design is correlated and the errors are heteroscedastic.

*Recommendation:* Keep hdi behaviour by default and document it. Add an opt-in (for example wy.cov = c('homoscedastic', 'robust'), or apply it automatically only when a new flag is set) that uses crossprod(Z * rc) with centred residuals rc whenever robust=TRUE.

### [medium] Robust s.e. uses 1/n rather than eq. (5)'s 1/(n - s_hat), and the dormant robust.div.fixed switch applies the wrong factor
*Where:* hdi_helpers.R:467-517 sandwich.var.est.stderr (return at line 515) and 698-733 est.stderr.despars.lasso (robust.div.fixed at lines 726-727); boot.se lines 758-785. *Paper:* TEST eq. (5) p.692 (1/(n - s_hat)) versus Sec 3.3.2 p.697 (n^-1). Sec 3.1 says to always use the robust s.e.

hdi's robust s.e. is sqrt(sum_i (eps_i Z_ij - n^-1 sum_r eps_r Z_rj)^2)/n. That equals n^-1/2 omega_j with omega_j^2 = n^-1 * sum(...), the Sec 3.3.2 / Theorem 2 version, not the proposed estimator in eq. (5), which uses 1/(n - s_hat). The internal switch robust.div.fixed=TRUE multiplies the s.e. by n/(n - s_hat). Eq. (5) actually implies a factor of sqrt(n/(n - s_hat)) on the s.e., because the n/(n - s_hat) belongs to omega^2. For example, n=100 and s_hat=10 gives 1.111 instead of 1.054. The switch cannot be reached from lasso.proj or boot.lasso.proj, which never pass it. Also, s_hat there counts non-zeros of beta excluding the intercept, whereas sigma_hat in the non-robust branch effectively counts the intercept (see the sigma df finding).

*Recommendation:* Keep the 1/n default (matches hdi numbers and the theory in Sec 3.3.2) and document that it is not literally eq. (5). If eq. (5) is offered, put it behind an opt-in argument and implement it as se * sqrt(n/(n - s_hat)), applied consistently to the original and bootstrap s.e. Do not port the n/(n - s_hat) factor.

### [medium] boot.shortcut: fixed-lambda fits use linearly interpolated coefficients; the shortcut is silently dropped for scaled lasso; numeric betainit fails late
*Where:* hdi_boot.lasso-proj.R:114-116 and 124-157; hdi_helpers.R:565-591 do.initial.fit (glmnet(x,y) at line 567, coef/predict at s=lambda at lines 587-591), 735-756 boot.initial.fit. *Paper:* TEST Sec 3 and 4.1-4.2: bootstrap estimators are computed with the plug-in rule (full re-computation). The shortcut is an hdi-only approximation, and the default boot.shortcut=FALSE matches the paper.

(1) With boot.shortcut=TRUE each bootstrap refit calls glmnet(x, ystar) on its own default lambda grid and reads coef(s=lambda.1se) with exact=FALSE. That is a linear interpolation between neighbouring grid solutions, not the lasso solution at lambda. In 50 residual-bootstrap draws (n=80, p=200) the maximum coefficient difference from the exact solution was 0.0025. The support size differed in 14/50 draws, which feeds into s_hat* and sigma_hat* (relative difference up to 2%). (2) With betainit='scaled lasso', initial.estimate$lambda is NULL, so the shortcut is silently ignored: every bootstrap sample is fully re-tuned while the output still reports boot.shortcut=TRUE. (3) If the fixed lambda leaves n - df <= 0, do.initial.fit silently refits by CV, which breaks the shortcut semantics. (4) A numeric betainit is only rejected inside boot.initial.fit, after the expensive nodewise Z computation.

*Recommendation:* For the exact port, keep the interpolation and the other behaviour so numbers match. Document all four points. Add a warning or message when boot.shortcut=TRUE has no effect (scaled lasso), and move the numeric-betainit check to the top of the function (it only changes an error path). An exact-lambda refit (e.g. glmnet(..., lambda = lambda) or exact=TRUE) could be offered as a new opt-in.

### [medium] A user-supplied sigma breaks the studentisation symmetry between T and T*
*Where:* hdi_boot.lasso-proj.R:83-86 and 97-103 (se uses the user-supplied sigma) versus 137-154 (sestar uses bootstrap sigma_hat*). *Paper:* TEST eqs. (7)-(9) and Theorem 1: T and T* must use the same s.e. formula, with se* obtained by the plug-in rule.

If sigma is given (and robust=FALSE), the observed pivot uses se = sigma_user * ||Z_j||/n. The bootstrap pivot T*_j = (b*_j - beta_hat_j)/se*_j uses the lasso-estimated sigma_hat* from each bootstrap fit. The two statistics are therefore studentised differently, and p-values and CIs are miscalibrated in proportion to sigma_user/sigma_hat*. For instance, the true sigma is usually smaller than the lambda.1se-based sigma_hat, which makes the test anti-conservative. The only feedback is the generic 'Overriding the error variance estimate' warning.

*Recommendation:* Keep hdi behaviour and document it. Warn specifically in boot.lasso.proj that a user-supplied sigma is not propagated into the bootstrap. As an opt-in, either use sigma_user in sestar too (a known-sigma pivot) or refuse sigma when robust=FALSE.

### [medium] hdi defaults contradict the paper's recommendation for heteroscedastic and simultaneous inference
*Where:* hdi_boot.lasso-proj.R:1-15 (defaults robust=FALSE, wild=FALSE, multiplecorr.method='WY'); hdi_lasso-proj.R:12. *Paper:* TEST Sec 3.1 p.693; Sec 3.2 last paragraph p.694; Sec 4.4.1 p.702; Sec 5.1.3-5.1.4 pp.707-712; Sec 6.3 p.717.

The paper recommends always using the robust s.e. (Sec 3.1, 5.1.4). It also states that the residual bootstrap is inconsistent for simultaneous inference, including WY under H0,complete, when errors are heteroscedastic, and that the wild bootstrap should then be used (Sec 3.2 end, 4.4.1, 6.3). hdi's defaults are the non-robust s.e. with the residual bootstrap and WY adjustment. Under heteroscedastic errors, the default boot.lasso.proj pval.corr is therefore not asymptotically valid, and the paper's own experiments (Fig. 10-11) show poor coverage with non-robust s.e.

*Recommendation:* Keep hdi-compatible defaults. State the paper's recommendation (robust=TRUE, wild=TRUE, preferably with Mammen multipliers once added) in the documentation and in the print method output.

### [low] Bootstrap p-value counting convention: slightly anti-conservative for some B and not exactly dual to confint
*Where:* hdi_boot.lasso-proj.R:182-188 (counts / (2*counts+1)/(B+1)); hdi_methods.R:220-232 (confint bootstrap CI). *Paper:* TEST eq. (8)-(9) p.693 ('p values ... computed by duality').

pval = (2c+1)/(B+1), where c = min(#{T* <= t}, #{T* > t}). The ties convention is asymmetric (<= for the lower tail, > for the upper). This is 1/(B+1) smaller than doubling the usual one-sided (c+1)/(B+1). Under exact exchangeability the size is 2(floor((alpha(B+1)-1)/2)+1)/(B+1), which can exceed alpha by up to 1/(B+1). Example: B=219, alpha=0.05 gives size 0.0545. With 2(c+1)/(B+1) the size is always <= alpha. For the default B=1000 at alpha=0.05 it is fine (0.04995). The p-values are also not exactly the duality inverse of confint, which uses type-7 quantiles (see the next finding). With B=199 at alpha=0.10, 51 of 8001 grid values of t gave a CI that excluded 0 while pval > 0.10, or the reverse. Otherwise the construction is right: T* is centred at the lasso beta_hat and studentised by se*, and the CI multiplies the quantiles by the original se, exactly as in eq. (9).

*Recommendation:* Keep hdi behaviour (required for identical numbers) and document the formula, the ties convention and the small non-duality. If a strictly valid or exactly dual version is wanted, add it as an opt-in (e.g. pval.type = 'hdi' / 'exact').

### [low] confint's intended type-1 quantile branch never fires for standard levels because of floating point
*Where:* hdi_methods.R:222-227 confint.hdi: if((alpha/2 * object$B) %% 1 == 0) type 1 else type 7. *Paper:* TEST eq. (9): q*_{j;nu} is the nu-quantile of the bootstrap distribution of T*_j (no specific quantile definition is given).

alpha = 1 - level is inexact. For level 0.95, 0.9, 0.99 and 0.8 with B = 100, 1000 or 2000, alpha/2*B equals values like 25.000000000000021 or 49.999999999999986, so %%1 is never 0. Checked in R 4.5.2. hdi therefore effectively always uses type 7 (symmetric interpolation), and type 1 is reached only for exactly representable alpha such as level=0.5. Type 7 is a reasonable choice, but the code does not do what it appears to do.

*Recommendation:* For exact parity, copy the expression verbatim, floating-point quirk included, and add a comment that type 7 is what is effectively used. Do not 'fix' it to an integer test by default, because that would change CIs for e.g. level=0.95 with B=1000.

### [low] lasso.proj WY adjusted p-values can be exactly 0 and fall below the raw p-value
*Where:* hdi_helpers.R:140-161 p.adjust.wy (ecdf(Gz)(pval)); hdi_lasso-proj.R:107-113. *Paper:* TEST Sec 4.3 P_{j,corr} (bootstrap version uses (count+1)/(B+1) in hdi); Buhlmann (2013) WY-type adjustment.

The adjusted p-value is the Monte Carlo ecdf of N=10000 simulated minP values, evaluated at p_j, with no +1 correction. For strong signals it is exactly 0. Run with n=100, p=30, beta1=3: pval[1]=1.5e-231 and pval.corr[1]=0, so pval.corr < pval. Reporting an adjusted p-value of 0 from a finite Monte Carlo is misleading, and the adjusted p-value is not guaranteed to be >= the raw one. The same non-monotonicity is possible in boot.lasso.proj, because pval (centred, equal-tailed) and pval.corr (H0,complete, max|T|) come from different bootstrap distributions.

*Recommendation:* Keep for parity and document that 0 means < 1/N. Optionally add an opt-in floor at 1/(N+1) and/or pmax(pval.corr, pval).

### [low] Non-robust sigma_hat: effectively RSS/(n - s_hat - 1), uses lambda.1se, and the df depends on a floating-point intercept
*Where:* hdi_helpers.R:576-591 do.initial.fit (sum(as.vector(coef(glmnetfit, s = lambda)) != 0) includes the intercept); line 560 lambda.1se. *Paper:* TEST eq. (4) p.691 (1/(n - s_hat), citing Reid, Tibshirani & Friedman 2016).

Eq. (4) uses sigma_hat^2 = ||Y - X beta_hat||^2/(n - s_hat). hdi counts non-zeros of coef() including the intercept. On centred data the glmnet intercept is numerically non-zero (observed -3.6e-18), so it is counted and the denominator becomes n - s_hat - 1. It is n - s_hat only in the rare case where the intercept is exactly 0. The initial lasso uses cv.glmnet's lambda.1se, which gives more shrinkage and a larger RSS, so sigma_hat is conservative. The Reid et al. (2016) recommendation cited by the paper is CV-based and does not specify 1se. betainit='scaled lasso' uses scalreg's own noise estimate, which has no n - s_hat correction. If n - df <= 0, sigma_hat is Inf/NaN after a single CV refit.

*Recommendation:* Keep hdi behaviour for parity and document the effective df (n - s_hat - 1), the lambda.1se choice, and the scaled-lasso difference. Do not change it by default.

### [low] Exact-port reproducibility: hidden RNG consumption, mvrnorm/LAPACK dependence, parallel RNG, glmnet version
*Where:* hdi_lasso-proj.R:101 and 123-141 (preprocess.group.testing -> mvrnorm(N, 0, crossprod(Z)) even when multiplecorr.method='holm'); hdi_helpers.R:155,170; mcmapply calls in boot.initial.fit/boot.se. *Paper:* n/a (implementation fidelity for the exact-port requirement).

(1) With the defaults (suppress.grouptesting=FALSE) lasso.proj draws N*p normals via MASS::mvrnorm after the results are computed. That also requires an eigen-decomposition of the p x p matrix Z'Z (about 330 MB of draws at p=4088). Dropping groupTest in SILM leaves lasso.proj outputs unchanged but changes the global RNG state after the call, so sequential calls under one set.seed will diverge from hdi. (2) WY p-values in lasso.proj depend on mvrnorm's eigenvectors, which vary with LAPACK/BLAS; hdi's own NEWS mentions mvrnorm reproducibility problems. (3) Numbers match hdi only with parallel=FALSE: mcmapply with mc.cores=1 falls back to mapply, while forked workers use different RNG streams. (4) cv.glmnet folds and the path depend on the glmnet version. The RNG order to preserve is: nodewise CV folds, then initial cv.glmnet, then resample(), then B sequential bootstrap cv.glmnet fits, then B more for WY. (5) hdi's own reference tests set RNGversion('3.5.0').

*Recommendation:* Document these parity conditions: parallel=FALSE, the same glmnet version, the RNG kind and sample.kind, and a note on WY parity across BLAS. Do not burn RNG to mimic the group-testing draws. Parity tests should compare lasso.proj outputs from fresh set.seed calls.

### [low] Edge cases produce cryptic errors: p <= 2, invalid B, constant columns, wrongly shaped Z, NaN se*
*Where:* hdi_helpers.nodewise.R:396 and 361 (glmnet(x[,-c], x[,c])); hdi_boot.lasso-proj.R:171-188; hdi_helpers.R:651-654; helpers.nodewise.R:29-37 (user Z). *Paper:* n/a

p == 2: x[,-i] drops to a vector, and glmnet fails with 'argument is of length zero'. p == 1 fails even with a user Z ('x should be a matrix with 2 or more columns' from cv.glmnet), so defaults require p >= 3. B = 0 errors inside arithmetic. A non-integer B makes replicate() round down while the p-values use the un-rounded B. Zero-variance columns give NaN after scale(). A Z supplied as a vector or with ncol(Z) != ncol(x) fails with 'invalid times argument' or 'non-conformable arrays'. None of these are silently wrong. If any bootstrap se* is NaN or Inf (for instance n - df* <= 0), then if(any(counts >= B/2)) hits NA and stops with 'missing value where TRUE/FALSE needed'.

*Recommendation:* Add up-front argument validation with clear error messages: p >= 3 unless Z and a numeric betainit are given, B a positive integer, no constant columns, dim(Z) == dim(x). This only changes error paths, so it is safe for an exact port.

### [low] Bootstrap b* depends on user-supplied Z being column-centred
*Where:* hdi_helpers.R:672-696 despars.lasso.est called at hdi_boot.lasso-proj.R:141-144 with ystar = x %*% betalasso + rstar (line 174; not centred). *Paper:* TEST Sec 3 eq. (6) and Sec 4.2 (the bootstrap requires E*[Z_j^T eps*] = 0; the paper's xyz construction explicitly enforces the centring).

The bootstrap responses ystar are not centred, since mean(eps*) != 0. The bootstrap lasso absorbs this in its intercept, but despars.lasso.est ignores the intercept, so b*_j picks up mean(Z_j)*mean(residual*). This is harmless for hdi's own nodewise Z (column means about 1e-17 because x is centred). A user-supplied Z that is not column-centred, e.g. computed on un-centred x, inflates or shifts the bootstrap distribution. The robust sandwich explicitly centres its residuals, but b* does not. lasso.proj is unaffected because y is centred.

*Recommendation:* Document that Z must come from the centred (and, if standardize=TRUE, standardised) x. Optionally centre user-supplied Z columns in calculate.Z. For hdi-computed Z this changes results only at the 1e-16 level.

### [low] standardize=FALSE is not scale-equivariant because one nodewise lambda is shared across columns
*Where:* hdi_helpers.nodewise.R:379-402 nodewise.getlambdasequence / single shared lambda; hdi_helpers.R:654 (standardize=FALSE only centres). *Paper:* TEST Sec 2.1 p.690 (common lambda_X for all nodewise regressions, implicitly on comparable scales).

The nodewise lambda grid pools glmnet lambda sequences whose scale is proportional to sd(x_j) (the response of each nodewise regression), and a single lambda is applied to every j. With standardize=FALSE and heterogeneous column scales, large-scale columns are barely penalised and small-scale columns get Z_j of about x_j. The quality of Z, and therefore the s.e. and power, then depend on the units. hdi's own equivariance test only covers standardize=TRUE. The initial cv.glmnet fit standardises internally in either case.

*Recommendation:* Keep the behaviour and document that standardize=FALSE is only sensible for columns already on comparable scales.

### [low] family='binomial': a spurious warning on every call, and a dense n x n solve
*Where:* hdi_lasso-proj.R:51-53 with hdi_helpers.R:627,641 (warning.sigma.message); hdi_helpers.R:451,458 (W <- diag(diagW); solve(W, y - pihat)). *Paper:* n/a

lasso.proj sets sigma <- 1 for binomial and then passes it to initial.estimator, which always emits the 'Overriding the error variance estimate with your own value' warning (observed once per call). The IRLS step also builds an n x n diagonal matrix and calls solve(), which costs O(n^3) in time and O(n^2) in memory for what is an elementwise division. Fitted probabilities near 0 or 1 make yw blow up. A factor y fails.

*Recommendation:* Suppress the internal-sigma warning for binomial. Replace solve(W, .) with (y - pihat)/diagW, which is numerically identical up to floating point. Accept 0/1 or two-level factor y.

### [low] API and doc mismatches: confint fails by default; returned element names and sigmahat description do not match the code
*Where:* hdi_methods.R:214-218 (confint requires cboot.dist); hdi_boot.lasso-proj.R:288-299 (returns cboot.dist.underH0c); man/boot.lasso.proj.Rd and man/lasso.proj.Rd. *Paper:* TEST eq. (9) (CI needs the T* distribution); eq. (14).

confint() on a boot.lasso.proj fit fails unless return.bootdist=TRUE, and that argument defaults to FALSE. The Rd documents the output 'cboot.dist.underH0', but the code returns 'cboot.dist.underH0c'. Both Rd files say sigmahat comes 'from the scaled lasso', while the default is 'cv lasso'. The hdi comment at boot line 197 says 'another B bootstrap samples', but the WY step reuses the same resampled residuals rstar under H0,complete. That is statistically fine (it follows eq. 14), but the comment is misleading.

*Recommendation:* Keep the argument defaults for compatibility. Make confint's error message tell the user to set return.bootdist=TRUE, or cheaply store per-coordinate quantiles or T* by default in the SILM object. Keep the element name cboot.dist.underH0c, which is what the code returns, and fix the documentation.

### [low] Paper details to handle when adding simultaneous CIs, P_G, Mammen and xyz-paired bootstraps
*Where:* New SILM code for TEST Sec 3.2 / 4.1-4.3 (not in hdi); builds on hdi_boot.lasso-proj.R:177-216 and 288-299. *Paper:* TEST Sec 3.2 pp.693-694 (C(1-alpha), eq. 10, P_G); Sec 4.1 eq. (12); Sec 4.2 p.699; Sec 4.3 eq. (14) and P_{j,corr} p.700.

(1) The region C(1-alpha) on p.693 contains a stray sqrt(n): the s.e. already carries n^-1/2, so eq. (10) is the consistent form, [b_j - se_j q*max(1-alpha/2), b_j - se_j q*min(alpha/2)], or ± q*abs(1-alpha) for the |T*| variant. (2) hdi returns cboot.dist and cboot.dist.underH0c multiplied by se/sds, so T* and T*0 are recovered by dividing by se/sds, not by se*. The H0c distribution is only computed when multiplecorr.method='WY', so P_G needs it computed regardless. (3) P_G on p.694 uses strict > and no +1, whereas hdi's WY uses (#{>=}+1)/(B+1); pick one convention so that P_G with G={1..p} agrees with pval.corr. P_{j} (G={j}) will not equal hdi's individual pval, which is centred and equal-tailed. (4) For the xyz-paired bootstrap, the row-resampled Z*_j no longer satisfy Z*_j'X*_j/n = 1, so the plug-in b*_j must renormalise by Z*_j'X*_j/n in each bootstrap sample (eq. 2 form). The residual used for Z-hat and X-hat is eps_hat_cent. (5) Mammen's two-point multipliers must satisfy E W=0, E W^2=1 (eq. 12). Under H0,complete the wild bootstrap is Y*0 = eps*W (eq. 14).

*Recommendation:* New behaviour, so expose it only through new opt-in arguments or functions. Implement eq. (10) without the sqrt(n) and document the conventions chosen for (2)-(5).


*Audit verifier overall:* All 18 findings survive. Checks were run against hdi 0.1-10 (helpers.R is byte-identical to cran/hdi), the TEST paper pages (pp. 689-702, 707-712, 717) and in-memory Rscript runs. The one high-severity bug is confirmed and is worse than reported. Binomial lasso.proj mean-centres the IRLS working data instead of projecting out sqrt(w). With n=1000, b0=-2, beta1=1.5 this gives a bias of -0.67 and 0% CI coverage. Projecting out sqrt(w) restores coverage to 98% and matches glm, so the default fix in SILM is justified. Finding 2 (numeric betainit on the standardised scale) reproduces, though it is better treated as a documentation/API trap of medium-high severity. Corrections to the findings' wording: in 5, the n - df refit emits a message rather than being silent, and the Rd does mention lambda=NULL. In 6, the anti-conservative direction is speculative. In 4, the dormant robust.div.fixed bug is only low-medium since it is unreachable. In 17, storing T* by default is not 'cheap'. In 18, P_G over all coordinates should equal min(pval.corr), and the xyz response Yhat = Xhat beta_hat + eps_hat_cent plus the H0c paired scheme should be added. The numeric claims were re-verified and hold: floating point makes confint always use type-7 quantiles; the p-value size is 0.0545 at B=219; WY pval.corr can be 0 (below pval); the glmnet intercept is never exactly 0, so the df is n - s_hat - 1; the shortcut's interpolation changes the support in about half of draws; p=2 fails with 'argument is of length zero'; binomial emits the sigma warning. For the exact port, keep hdi behaviour everywhere except the binomial projection fix and error-path validation, and add the paper's features as opt-ins.
