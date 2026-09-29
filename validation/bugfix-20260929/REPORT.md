# SILM correctness repairs — September 29, 2026

Base: SILM 2.0.0, Git commit `f319dfcbc83cc7b78ff15961ba6e79fac58ada62`.
This report describes repairs prepared against that commit, prompted by
the independent audit supplied by the user. It does not change the audit's
verdict about the released commit.

## Reproductions and repairs

| Finding | Repair and verification |
|---|---|
| Duplicate predictor names select the wrong confidence interval | Keep integer positions internally; names are display labels. Tested default selections, reordered/repeated/excluded numeric indices, individual Gaussian and bootstrap intervals, and simultaneous intervals including `parm = 2, group = 2`. Selected ambiguous character names now produce an error directing callers to numeric indices. |
| Printing fails on repeated names | Create unique display labels without changing coefficient names or values in the fitted object. |
| Response units change scaled-lasso inference | Normalize the response by its RMS before constructing the lars path; use relative noise-level convergence at `1e-8`. Rescale coefficients, noise and penalty afterward. Independent tests verify lasso KKT conditions, RMS residuals, fixed-point equations and a closed-form one-predictor solution. |
| ST accepts screening size 2 and fails downstream | Require at least 3 screening observations before drawing the split. The minimum supported size 3 is also exercised. |
| One-predictor Gaussian stub drops matrix dimensions | Preserve p-by-B matrices for both bootstrap passes and the Westfall–Young comparison matrix. Check stored draws, RNG state, p-values, confidence intervals and group-test formulas directly. |
| Gaussian WY with N=1 drops its sample dimension | Keep the Gaussian draw as a one-row matrix; verify against direct Gaussian null draws for p=1 and p=3. |
| Additional units-dependent xyz cutoff | Project using a normalized residual direction, avoiding an absolute residual-size cutoff and squared-residual underflow/overflow. Verified against independent QR projections and an end-to-end xyz bootstrap at response scale `1e-9`. |
| Undefined inference from zero estimated noise | Retain the exact zero solution in the internal optimization routine, but reject zero/non-finite estimated noise before inference. A supplied positive noise estimate still permits Gaussian inference. |

`confint()` also gives clear errors for non-finite levels and empty selections.

## Controlled units example

The supplied report described an orthogonal design with n=120, p=6, signal
coefficients (20, -15, 0, 0, 0, 0), and a unit-RMS orthogonal residual. A fresh
construction of that design reproduced its **3.482923-fold** width distortion.
The matched bootstrap draws here use M=199; the absolute widths need not equal
the supplied audit's widths because its exact random design/seed was not supplied.

| Solver | Studentized half-width at original units | Half-width after Y × 1e-6, converted back | Ratio |
|---|---:|---:|---:|
| Historical (`scaled.lasso = "legacy"`) | 0.2323185260 | 0.8091476261 | 3.482923381 |
| Corrected default (`"equivariant"`) | 0.2323182299 | 0.2323182299 | 1.000000000 |

See `reproduce.R` for a runnable installation-level demonstration of the units,
duplicate-name and three boundary cases. The regression tests also exercise
response multipliers from `1e-12` to `1e12`, negative response scaling, all six
inference entry points, and residual/wild/xyz fitting components as applicable.

## Historical compatibility

All six inference functions now accept the trailing argument
`scaled.lasso = c("equivariant", "legacy")`. It only affects scaled-lasso
initialization and refits; the projection functions' default CV lasso is unchanged.
The legacy choice deliberately retains the historical numerical defect, including
the absolute tolerance, initial noise scale, iteration cap and returned-iterate
convention. It should be used for archived replication, not to obtain corrected
inference in arbitrary response units.

Archived fixture and equivalence tests explicitly select the legacy solver.
Their stored expected values were not regenerated or loosened. Other historical
options remain necessary where applicable: ST's `legacy = TRUE`, the matching
nodewise rule, and `robust.divisor = "n"` for hdi's robust variance convention.
Default-solver correctness is tested independently of these historical comparisons.

## Verification

The final source package passes **R CMD check --no-manual: Status OK**, including
**569 assertions**, help examples, vignette execution and vignette rebuilding.
There are no test failures, errors, warnings or skips. The development test runs
also cover all 569 assertions in two installed runtimes (an initial complete
563-assertion suite, followed by the expanded 48-assertion response-units file
after adding six zero-noise checks):

* Homebrew R 4.5.2, OpenBLAS, glmnet 4.1-10, lars 1.3, MASS 7.3-65.
* CRAN-framework R 4.5.0, its bundled BLAS, glmnet 4.1-10, lars 1.3,
  MASS 7.3-65.

Both runtimes are on Apple Silicon/macOS 26.6.2. R 4.3's retained library directory
exists, but its executable is absent; the original audit's R 4.3.2 environment was
not rerun here. Source build, including HTML vignette creation, passes.
The sandboxed check could not query CRAN/Bioconductor indexes; installed
dependencies were used. These repository-access warnings are retained in
`evidence/R-CMD-check-console.log`; the package check still reports Status OK.

The fresh fast tier completed all **662 cases across 23 scenarios**:

| Outcome | Cases |
|---|---:|
| Exact compared values and final RNG state | 642 |
| Expected additional RNG draws for Holm with `boot.H0c = TRUE` | 1 |
| Archived ST fails; repaired ST succeeds | 15 |
| Both reject the oversized screening selection | 4 |
| Unexpected difference/failure | 0 |

The one allowed case has identical compared numerical outputs. Warning text and
SILM-only fields are not part of the exact comparisons; historical numerical
agreement is not a correctness or convergence guarantee.

**Runner bookkeeping:** I edited a comment in the runner after starting it.
Rscript read the rest of that file after the long computation and encountered
a trailing parse error. This happened after all comparisons, the report and the
RDS records were written, so the runner process exited 1 despite the comparison
table containing no failures. `verify-equivalence.R` subsequently verified all
662 saved records, exact-match flags, allowed-difference/error categories, matching
glmnet versions, and the current runner's syntax; that verification exited 0.
The original console log and compact saved records are included in `evidence/`.
Text-log trailing whitespace is normalized and the workspace path is replaced
by `<workspace>` for publication; reported values are unchanged.
This was an audit execution error, not a SILM runtime error.

The archived run's installed snapshot includes the numerical repairs; the final
zero-noise diagnostic guard was added after it started and is covered by the
final package check above. The large simulation/full-equivalence tiers were not
rerun.

## Limits

These repairs establish the reported defects and their regression coverage;
they do not prove correct inference for every design or finite sample. The
relative convergence change can alter ordinary-scale results slightly. The
large calibration/default-selection and paper-replication studies were not
rerun, and their historical results should not be relabeled as validation of
the new solver. The 101-update cap remains and nonconvergence still warns.

This work does not exhaustively repair all low-priority diagnostics listed in
the audit (for example missing `ncores`, one-class binomial input, or a constant
screening response). With one predictor, glmnet's CV-lasso backend still requires
at least two columns; supplied numeric or scaled-lasso initialization is usable
with supplied Z. A single WY draw is now handled consistently but is not useful
for inferential accuracy. Linux, Windows and R-devel were not tested.

Validation was performed locally before publication. No package release was
performed as part of this audit.
