# Interpretation of the replication (post hoc)

`REPORT.md` applies the criteria of `CRITERIA.md`, which were committed before
the full run (commit e9797b7). This document was written **after** seeing the
results. It offers explanations for the failures and is not part of the
pre-registered evidence. The explanations are hypotheses. Most were not tested
by further experiments, and agreement with legacy code or higher power does not
by itself show that a discrepancy is harmless.

Some limits apply to the whole comparison:

* The Zhang and Cheng targets come from the arXiv manuscript
  (arXiv:1603.01295v1), because the published article could not be accessed.
  The published tables may differ.
* The Zhang and Cheng methods (and the "ZC approach" in the DBZ comparison)
  were run with `nodewise = "cv"`, the tuning described in the paper. The
  default of SILM 2.0.0 is `"ZnZ"`, chosen afterwards by the defaults study
  (`validation/calibration/defaults-results/REPORT.md`,
  TODO-DEFAULTS-NUMBERS).
* The papers' random designs, coefficient draws and seeds cannot be recovered,
  and some settings are not fully specified. The comparison is therefore
  statistical, not exact.
* Some tolerances and expected-failure tags in `CRITERIA.md` were informed by
  exploratory runs before registration, as `CRITERIA.md` states.

## Summary

* **629 of 684 headline criteria pass (92%)**, under the pre-registered
  criteria and reporting rules of `CRITERIA.md` (headline rows only;
  draw-dependent rows and expected failures are reported separately in
  `REPORT.md`).
* Every row that compares SILM with an exact reference passes:
  * hdi's own regression-test values on `riboflavin[, 1:16]`: `bhat` within
    1e-8 and confidence limits within 1.1e-6, against tolerances of 4e-7 and
    5e-5;
  * parallel fits equal sequential fits;
  * the `ST()` fast path equals `ST()`.
  (Exact reproduction of the archived SILM, hdi and scalreg code is checked
  separately, by the equivalence harness in `validation/`.)
* The papers' main qualitative conclusions are reproduced:
  * **Zhang and Cheng (2017):**
    * Table 1 passes 224/224.
    * The simultaneous intervals over S0^c and [p] have close to nominal
      coverage, while coverage over S0 suffers when s0 = 15.
    * The scaled lasso underestimates the noise level.
    * SupRec beats the scaled lasso in support recovery.
    * The three-step test is more powerful than the one-step test.
    * The step-down procedure controls the FWER (maximum 0.054).
    * The studentized step-down procedure is at least as powerful as Holm in
      all 8 cells.
  * **Dezeure, Bühlmann and Zhang (2017):**
    * individual coverage of the original and bootstrapped de-sparsified
      lasso;
    * WY and Holm FWER control, and the power of WY on the Toeplitz designs
      (16/16);
    * robust inference under heteroscedastic errors;
    * the riboflavin conclusions (no rejection by Holm or WY; median
      p_equiv 1324 against the paper's 1264).

## The 55 headline failures

| Group | Rows | What happened | Our explanation (a hypothesis) |
|---|---|---|---|
| ZC Table 4, power in case (i) | 23 | SILM's power is **higher** than published, by 0.06–0.18, for both the one-step and the three-step test. The size rows of the same table all pass (48/48; mean absolute difference from the paper 0.01), and so does case (ii) power (32/32). | Probably not an error. The higher power at the correct size may come from the paper's particular design/β draw or from its 2016 implementation (e.g. the nodewise tuning); we did not test this. |
| ZC Table 2, width of the NST interval for G = S0 | 8 | SILM's intervals are narrower than published (e.g. 1.22 vs 1.44). | Probably not. Table 2's NST widths are internally inconsistent with Tables 1 and 2's studentized widths; `CRITERIA.md` flags the NST rows for G = S0^c and [p] as expected failures and these G = S0 rows as "at risk". Coverage of S0 depends on the unknown β draw. |
| ZC Table 3, scaled lasso at p = 120, case (i) | 5 | The scaled lasso (the comparison method, not SupRec) selects more false positives than published (5.5 vs 4.0). | Probably not an error in SILM: its scaled lasso reproduces scalreg 1.0.1 exactly (harness A1: 324/324), so the difference most likely reflects the design/β realisation. All SupRec rows pass. |
| DBZ Sec. 5.1.3, heteroscedastic example, non-robust methods | 7 | With the non-robust standard error, coverage (0.89–0.90 vs 0.95) and FWER (0.28 vs 0.06) are much worse than published. The robust versions match: coverage 0.956 and 0.944 vs 0.963 and 0.956; WY FWER 0.041 vs 0.04. | Probably the error model. The paper's formulas for this example (p. 709) contain an apparent typo, and the supplementary material was not available, so our error model is a reading of the text. Its heteroscedasticity appears to be stronger than the paper's, which would hurt exactly the non-robust methods. |
| DBZ comparison with the "ZC approach" | 2 | SILM's `Sim.CI()` (the ZC approach) has **better** coverage than the ZC implementation used in the DBZ paper, so "ZC is no better than the original estimator" and "the bootstrap beats ZC" fail. | Not a failure of SILM's `Sim.CI()`, which does better than expected; the reason for the difference from the paper's ZC implementation is unknown. |
| SILM additions in the heteroscedastic example | 4 | Mammen multipliers give an average coverage of 0.857 (Gaussian wild 0.935). The xyz-paired bootstrap was the most accurate (0.958). These rows encoded expectations, not published numbers. | See the next section. |
| ZC Sec. 5.3, marginal screening in case (ii) | 2 | The replication's own implementation of plain marginal screening keeps all relevant variables far more often than the published 0.59. SILM's screening, the paper's remedy, matches (0.964/0.978 vs 0.98). | Not SILM code: marginal screening was implemented in the replication scripts. |
| ZC Table 4, size claim | 1 | The paper reports a slightly inflated size (0.062) for the three-step test with Gamma errors; SILM's is 0.045. | SILM's size is closer to nominal. |
| ZC Table 5, NST step-down vs Holm | 1 | The non-studentized step-down test is at least as powerful as Holm in 5 of 8 cells (paper: all). The studentized version is in 8 of 8. | Possibly the β draw (Table 5 is tagged draw-dependent). |
| DBZ Fig. 15 at c = 2 | 1 | WY and Holm reject equally often, where the paper shows WY ahead. The replication uses only 10 riboflavin columns. | Possibly the reduced design (10 columns). |
| DBZ Fig. 12, largest FWER of four methods | 1 | Same as the non-robust heteroscedastic rows. | As above. |

## Mammen multipliers

In the paper's heteroscedastic example (n = 50, p = 250), the wild bootstrap
with Mammen multipliers covered 0.857 on average, against 0.935 with Gaussian
multipliers. To look for an implementation error:

* The two-point law has moments 0, 1, 1 and 2, and each value uses exactly
  one uniform draw (unit tests).
* In benign designs with independent covariates, homoscedastic Gaussian
  errors, B = 400 and 100 replications, Mammen multipliers came close to the
  nominal level: 0.924 vs 0.939 with Gaussian multipliers at n = 100 and
  p = 50, and 0.923 vs 0.951 at the example's own dimensions, n = 50 and
  p = 250.

Our checks found no implementation error. The low coverage in the example
suggests a finite-sample limitation of two-point multipliers under strong
heteroscedasticity at n = 50: with them, the bootstrap standard error varies
strongly across bootstrap samples. The paper also reports no advantage of
Mammen multipliers (p. 688). We recommend the default Gaussian multipliers.
