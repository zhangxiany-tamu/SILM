# Replication report

Pre-registered criteria: `replication/CRITERIA.md` (committed before these results).
Each target was run with the SILM version, glmnet version and replication scale below.

| Target | Commit | SILM | glmnet | Scale | Date |
|---|---|---|---|---|---|
| dbz_coverage | 368a83e | 1.0.0.9000 | 5.1 | 1 | 2026-09-24 14:51 |
| dbz_fwer | 368a83e | 1.0.0.9000 | 5.1 | 1 | 2026-09-24 16:26 |
| dbz_hdi_reference | e9797b7 | 1.0.0.9000 | 5.1 | 1 | 2026-09-24 12:57 |
| dbz_hetero | 368a83e | 1.0.0.9000 | 5.1 | 1 | 2026-09-24 15:29 |
| dbz_riboflavin | 368a83e | 1.0.0.9000 | 5.1 | 1 | 2026-09-24 16:49 |
| zc_simci | 368a83e | 1.0.0.9000 | 5.1 | 1 | 2026-09-24 14:13 |
| zc_sr | 368a83e | 1.0.0.9000 | 5.1 | 1 | 2026-09-24 13:06 |
| zc_st | 368a83e | 1.0.0.9000 | 5.1 | 1 | 2026-09-24 18:39 |
| zc_step | 368a83e | 1.0.0.9000 | 5.1 | 1 | 2026-09-24 13:23 |

**Headline criteria: 629 of 684 passed.**

| Group | Criteria | Passed |
|---|---|---|
| headline | 684 | 629 |
| draw-dependent | 192 | 183 |
| expected failure | 64 | 11 |
| code check | 2 | 2 |
| informational | 0 | 0 |

## Headline targets

### DBZ Sec. 5.1.1-5.1.2 individual CI coverage (Figs 4-5, 7-8) (22 of 24 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| gaussian | average coverage, original | 0.963 | 0.958 | 0.000925 | 0.0128 | yes | Sec. 5.1.1, Fig. 4 (p. 706) and Fig. 5 (p. 707); printed Avg (exact); tol = 3 MC s.e. + 0.010 (single design); R = 100 (paper 100), B = 500 |
| gaussian | average coverage, bootstrap | 0.958 | 0.949 | 0.00115 | 0.0135 | yes | Sec. 5.1.1, Fig. 4 (p. 706) and Fig. 5 (p. 707); printed Avg (exact); tol = 3 MC s.e. + 0.010 (single design); R = 100 (paper 100), B = 500 |
| gaussian | bootstrap average coverage closer to 0.95 than original (\|orig-0.95\| - \|boot-0.95\|) | 0.005 | 0.00676 |  |    0 | yes | qualitative (p. 705, 708); pass if > 0 |
| gaussian | share of coefficients with coverage <= 0.90, original | 0.048 | 0.08 |  | 0.0664 | yes | paper value from the histogram (vector graphics); check_prop over coefficients, delta 0.02 |
| gaussian | share of coefficients with coverage <= 0.90, bootstrap | 0.012 | 0.038 |  | 0.0496 | yes | paper value from the histogram (vector graphics); check_prop over coefficients, delta 0.02 |
| gaussian | under-coverage: share <= 0.90, bootstrap minus original | -0.036 | -0.042 |  |    0 | yes | qualitative: original has more under-coverage (Figs 4, 7); pass if < 0 |
| gaussian | over-coverage: share >= 0.99, bootstrap minus original | -0.14 | -0.16 |  |    0 | yes | qualitative: original has more over-coverage (Figs 4, 7); pass if < 0 |
| gaussian | minimum coverage, bootstrap minus original | 0.08 | 0.12 |  |    0 | yes | qualitative: poorest coverage improved by the bootstrap (Figs 5, 8); pass if > 0 |
| gaussian | mean CI length ratio bootstrap / original |    1 | 0.853 |  | 0.05 | yes | claim p. 710: better coverage 'without increasing the confidence interval lengths'; pass if <= 1.05 |
| gaussian | average coverage, ZC (Sim.CI) | 0.962 | 0.958 | 0.000983 | 0.0179 | yes | Sec. 5.1.1, Fig. 4 (p. 706) and Fig. 5 (p. 707); printed Avg (exact); tol = 3 MC s.e. + 0.015 (single design); R = 100 (paper 100), B = 500 |
| gaussian | share of coefficients with coverage <= 0.90, ZC (Sim.CI) | 0.06 | 0.032 |  | 0.0597 | yes | paper value from the histogram (vector graphics); check_prop over coefficients, delta 0.02 |
| gaussian | ZC no better than original: share <= 0.90, ZC minus original | 0.012 | -0.048 |  |    0 | **no** | claim Figs 4-5 captions: ZC 'does not show any improvements' over the original; pass if >= -0.02 |
| gaussian | bootstrap better than ZC: share <= 0.90, bootstrap minus ZC | -0.048 | 0.006 |  |    0 | **no** | claim p. 711: bootstrapping only the linearised part is 'clearly sub-ideal'; pass if < 0 |
| gaussian | minimum coverage, bootstrap minus ZC | 0.09 | 0.05 |  |    0 | yes | claim p. 711 (Fig. 5: 0.88 vs 0.79); pass if > 0; ZC mean length / original = 0.949 |
| chisq | average coverage, original | 0.965 | 0.957 | 0.000809 | 0.0124 | yes | Sec. 5.1.2, Fig. 7 (p. 708) and Fig. 8 (p. 709); printed Avg (exact); tol = 3 MC s.e. + 0.010 (single design); R = 100 (paper 100), B = 500 |
| chisq | average coverage, bootstrap | 0.961 | 0.953 | 0.00116 | 0.0135 | yes | Sec. 5.1.2, Fig. 7 (p. 708) and Fig. 8 (p. 709); printed Avg (exact); tol = 3 MC s.e. + 0.010 (single design); R = 100 (paper 100), B = 500 |
| chisq | bootstrap average coverage closer to 0.95 than original (\|orig-0.95\| - \|boot-0.95\|) | 0.004 | 0.0043 |  |    0 | yes | qualitative (p. 705, 708); pass if > 0 |
| chisq | share of coefficients with coverage <= 0.90, original | 0.064 | 0.092 |  | 0.0709 | yes | paper value from the histogram (vector graphics); check_prop over coefficients, delta 0.02 |
| chisq | share of coefficients with coverage <= 0.90, bootstrap | 0.01 | 0.018 |  | 0.0423 | yes | paper value from the histogram (vector graphics); check_prop over coefficients, delta 0.02 |
| chisq | under-coverage: share <= 0.90, bootstrap minus original | -0.054 | -0.074 |  |    0 | yes | qualitative: original has more under-coverage (Figs 4, 7); pass if < 0 |
| chisq | over-coverage: share >= 0.99, bootstrap minus original | -0.178 | -0.192 |  |    0 | yes | qualitative: original has more over-coverage (Figs 4, 7); pass if < 0 |
| chisq | minimum coverage, bootstrap minus original | 0.13 |  0.2 |  |    0 | yes | qualitative: poorest coverage improved by the bootstrap (Figs 5, 8); pass if > 0 |
| chisq | mean CI length ratio bootstrap / original |    1 | 0.842 |  | 0.05 | yes | claim p. 710: better coverage 'without increasing the confidence interval lengths'; pass if <= 1.05 |
| chisq vs gaussian | original: share <= 0.90, chi-squared minus Gaussian | 0.016 | 0.012 |  |    0 | yes | claim p. 706: under-coverage of the original 'even more pronounced' with chi-squared errors; pass if >= 0 |

### DBZ Sec. 5.1.1-5.1.2/5.2 multiple testing, Toeplitz (Figs 6, 9, 13) (16 of 16 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| gaussian | FWER, WY | 0.03 | 0.0729 | 0.0153 | 0.0505 | yes | paper: median over 300 models (approx, Fig. 6 (p. 708); Fig. 13 top (p. 713)); ours: pooled over 24 models x 12 = 288 realisations, B = 100 |
| gaussian | FWER, BH (Holm, lasso.proj) | 0.02 | 0.0556 | 0.0135 | 0.0451 | yes | paper: median over 300 models (approx, Fig. 6 (p. 708); Fig. 13 top (p. 713)); ours: pooled over 24 models x 12 = 288 realisations, B = 100 |
| gaussian | FWER, WY minus BH | 0.01 | 0.0174 |  |    0 | yes | claim pp. 705, 707: the bootstrap (WY) is the least conservative; pass if >= 0 |
| gaussian | FWER control, WY | 0.05 | 0.0729 | 0.0153 | 0.0385 | yes | claim p. 705: WY has proper error control; pass if <= 0.05 + 3 s.e. |
| gaussian | power, WY (median over models) | 0.72 | 0.847 |  |  0.2 | yes | approx; tol 0.2: median over 24 models vs 300 models in the paper |
| gaussian | power, WY minus BH (pooled) | 0.02 | 0.0185 |  |  | yes | claim p. 705: no visible power difference, WY not less powerful; pass if in [-0.02, 0.10] |
| gaussian | p_equiv, WY (median over realisations) |  290 |  326 |  |   58 | yes | Fig. 13 median (vector graphics) and 'about 300' (p. 712); relative tol 20% (about +-0.05 in t_rej); lasso re-tuned in each bootstrap sample. Sensitivity, boot.shortcut = TRUE on the same realisations: median p_equiv 317 (quartiles 244, 411), WY FWER 0.080 |
| gaussian | p_equiv, BH (median over realisations) [descriptive] |  498 |  497 |  |  | n/a | descriptive, not a criterion: p - (number of Holm rejections), a consistency check of the definition |
| gaussian | p_equiv threshold reproduces the WY decisions (mismatches) |    0 |    0 |  |    0 | yes | internal check of the WY threshold used for eq. (15) |
| chisq | FWER, WY | 0.025 | 0.0625 | 0.0143 | 0.0479 | yes | paper: median over 300 models (approx, Fig. 9 (p. 709); Fig. 13 bottom (p. 713)); ours: pooled over 24 models x 12 = 288 realisations, B = 100 |
| chisq | FWER, BH (Holm, lasso.proj) | 0.01 | 0.0382 | 0.0113 | 0.0379 | yes | paper: median over 300 models (approx, Fig. 9 (p. 709); Fig. 13 bottom (p. 713)); ours: pooled over 24 models x 12 = 288 realisations, B = 100 |
| chisq | FWER, WY minus BH | 0.015 | 0.0243 |  |    0 | yes | claim pp. 705, 707: the bootstrap (WY) is the least conservative; pass if >= 0 |
| chisq | FWER control, WY | 0.05 | 0.0625 | 0.0143 | 0.0385 | yes | claim p. 705: WY has proper error control; pass if <= 0.05 + 3 s.e. |
| chisq | power, WY (median over models) | 0.69 | 0.778 |  |  0.2 | yes | approx; tol 0.2: median over 24 models vs 300 models in the paper |
| chisq | power, WY minus BH (pooled) | 0.02 | 0.00463 |  |  | yes | claim p. 705: no visible power difference, WY not less powerful; pass if in [-0.02, 0.10] |
| chisq | p_equiv, WY (median over realisations) |  295 |  332 |  |   59 | yes | Fig. 13 median (vector graphics) and 'about 300' (p. 712); relative tol 20% (about +-0.05 in t_rej); lasso re-tuned in each bootstrap sample. Sensitivity, boot.shortcut = TRUE on the same realisations: median p_equiv 307 (quartiles 243, 414), WY FWER 0.049 |
| chisq | p_equiv, BH (median over realisations) [descriptive] |  498 |  497 |  |  | n/a | descriptive, not a criterion: p - (number of Holm rejections), a consistency check of the definition |
| chisq | p_equiv threshold reproduces the WY decisions (mismatches) |    0 |    0 |  |    0 | yes | internal check of the WY threshold used for eq. (15) |

### DBZ Sec. 5.1.3 multiple testing, heteroscedastic (Fig. 12) (5 of 8 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| non-robust | FWER, WY | 0.06 | 0.284 | 0.0252 | 0.0651 | **no** | paper: median over 50 designs (approx, Fig. 12); ours: pooled over 16 designs x 20 = 320 realisations, B = 100 |
| non-robust | FWER, BH | 0.03 | 0.275 | 0.025 | 0.0558 | **no** | paper: median over 50 designs (approx, Fig. 12); ours: pooled over 16 designs x 20 = 320 realisations, B = 100 |
| robust | FWER, WY | 0.04 | 0.0406 | 0.011 | 0.0539 | yes | paper: median over 50 designs (approx, Fig. 12); ours: pooled over 16 designs x 20 = 320 realisations, B = 100 |
| robust | FWER, BH | 0.02 | 0.0125 | 0.00621 | 0.0439 | yes | paper: median over 50 designs (approx, Fig. 12); ours: pooled over 16 designs x 20 = 320 realisations, B = 100 |
| non-robust | FWER, WY minus BH | 0.03 | 0.00938 |  |    0 | yes | claim p. 710: the bootstrap is less conservative; pass if >= 0 |
| robust | FWER, WY minus BH | 0.02 | 0.0281 |  |    0 | yes | claim p. 710: the bootstrap is less conservative; pass if >= 0 |
| robust | FWER control, robust WY | 0.05 | 0.0406 | 0.011 | 0.0366 | yes | pass if <= 0.05 + 3 s.e. |
| all | largest FWER of the four methods |  | 0.284 |  | 0.0566 | **no** | claim p. 710: all methods 'perform adequately'; pass if <= 0.05 + 3 s.e. + 0.02 |

### hdi 0.1-10 tests/test-lasso.R reference values (riboflavin[, 1:16], seed 3) (6 of 6 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| riboflavin[, 1:16] | (1) pval invariant to x -> 2 + 4x |    0 | 8.4e-15 |  | 1.5e-08 | yes | all.equal(fit.lasso$pval, fit.lasso2$pval) |
| riboflavin[, 1:16] | (2) bhat / bhat(2 + 4x) - 4 (range) |    0 | 1.41e-13 |  | 1.5e-08 | yes | all.equal(c(0,0), range(fit.lasso$bhat / fit.lasso2$bhat - 4)) (absolute difference) |
| riboflavin[, 1:16] | (3) CI(x) = 4 CI(2 + 4x) |    0 | 4.85e-15 |  | 1.5e-08 | yes | all.equal(ci.lasso, ci.lasso2 * 4) |
| riboflavin[, 1:16] | (4) bhat vs hard-coded reference |    0 | 1e-08 |  | 4e-07 | yes | hdi test tolerance tol = 4e-7 ('# 1e-8' in the test file) |
| riboflavin[, 1:16] | (5) 95% CI vs hard-coded reference |    0 | 1.13e-06 |  | 5e-05 | yes | hdi test tolerance tol = 5e-5 |
| riboflavin[, 1:16] | (6) parallel fit = sequential fit (pval, bhat, se) |    0 |    0 |  | 1.5e-08 | yes | SILM addition: hdi refits with parallel = TRUE but does not check the result |

### DBZ Sec. 5.1.3 heteroscedastic errors, CI coverage (Figs 10-11) and additions (15 of 24 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| orig_r | average coverage (robust_original) | 0.963 | 0.956 | 0.00203 | 0.0161 | yes | Fig. 11 Avg (exact) (the text on p. 710 says 0.959); tol = 3 MC s.e. + 0.010; R = 100 (paper 100), B = 300 |
| resid_r | average coverage (robust_bootstrap) | 0.956 | 0.944 | 0.0031 | 0.0193 | yes | Fig. 11 Avg (exact) (the text on p. 710 says 0.951); tol = 3 MC s.e. + 0.010; R = 100 (paper 100), B = 300 |
| orig_nr | average coverage (original) | 0.949 | 0.896 | 0.0023 | 0.0219 | **no** | Fig. 11 Avg (exact); tol = 3 MC s.e. + 0.015; R = 100 (paper 100), B = 300 |
| resid_nr | average coverage (bootstrap) | 0.946 | 0.887 | 0.00308 | 0.0242 | **no** | Fig. 11 Avg (exact); tol = 3 MC s.e. + 0.015; R = 100 (paper 100), B = 300 |
| orig_r | share of coefficients with coverage <= 0.90 (robust_original) |    0 | 0.024 |  | 0.0492 | yes | Fig. 10 histogram (approx); check_prop over the 250 coefficients, delta 0.02 |
| resid_r | share of coefficients with coverage <= 0.90 (robust_bootstrap) | 0.012 | 0.08 |  | 0.0762 | yes | Fig. 10 histogram (approx); check_prop over the 250 coefficients, delta 0.02 |
| orig_nr | share of coefficients with coverage <= 0.90 (original) | 0.16 | 0.476 |  | 0.145 | **no** | Fig. 10 histogram (approx); check_prop over the 250 coefficients, delta 0.02 |
| resid_nr | share of coefficients with coverage <= 0.90 (bootstrap) | 0.172 | 0.532 |  | 0.148 | **no** | Fig. 10 histogram (approx); check_prop over the 250 coefficients, delta 0.02 |
| orig_nr vs orig_r | original: share <= 0.90, non-robust minus robust | 0.16 | 0.452 |  | 0.05 | yes | claim p. 710: 'coverage is very poor for the non-robust methods'; pass if >= 0.05 |
| resid_nr vs resid_r | bootstrap: share <= 0.90, non-robust minus robust | 0.16 | 0.452 |  | 0.05 | yes | claim p. 710: 'coverage is very poor for the non-robust methods'; pass if >= 0.05 |
| resid_r vs orig_r | robust: bootstrap average closer to 0.95 than original (gap difference) | 0.007 | -0.00036 |  |    0 | **no** | claim p. 710: 'slightly more correct for the bootstrap'; pass if > 0 |
| resid_r vs orig_r | robust: \|average bootstrap - average original\| | 0.007 | 0.0118 |  | 0.01 | **no** | claim p. 710 / Fig. 10: 'hardly any difference' once the s.e. is chosen; pass if <= 0.01 |
| resid_nr vs orig_nr | non-robust: \|average bootstrap - average original\| | 0.003 | 0.00892 |  | 0.01 | yes | claim Fig. 10 caption: 'hardly any difference'; pass if <= 0.01 |
| wild_g vs resid_r | addition: \|average wild (Gaussian) - average residual (robust)\| |  | 0.00912 |  | 0.01 | yes | claim p. 712: Gaussian multiplier bootstrap 'very similar to the residual bootstrap'; pass if <= 0.01 |
| wild_g vs resid_r | addition: share <= 0.90, wild (Gaussian) minus residual (robust) |  | 0.04 |  | 0.02 | **no** | claim p. 712: handles heteroscedastic errors 'as good as' the robust residual bootstrap; pass if <= 0.02 |
| wild_m vs wild_g | addition: \|average wild (Mammen) - average wild (Gaussian)\| |  | 0.0781 |  | 0.015 | **no** | claim p. 688: no substantial empirical improvement from non-Gaussian multipliers; pass if <= 0.015 |
| xyz vs wild_g | addition: xyz not more accurate than wild (Gaussian): \|xyz-0.95\| - \|wild-0.95\| |  | -0.00768 |  |    0 | **no** | claim p. 699: xyz 'may not be competitive' with the Gaussian wild bootstrap; weak directional check (average coverage only); pass if >= 0 |
| wild_g | addition: simultaneous non-coverage over all p (max-\|T\| FWER) |  | 0.06 | 0.0237 | 0.0854 | yes | Theorem 3 (wild bootstrap valid for simultaneous inference); gross-failure check only (R = 100); pass if <= 0.05 + 3 sqrt(0.05*0.95/R) + 0.02 = 0.135 |
| wild_m | addition: simultaneous non-coverage over all p (max-\|T\| FWER) |  | 0.06 | 0.0237 | 0.0854 | yes | Theorem 3 and p. 701 (Mammen multipliers); gross-failure check only (R = 100); pass if <= 0.05 + 3 sqrt(0.05*0.95/R) + 0.02 = 0.135 |
| xyz | addition: simultaneous non-coverage over all p (max-\|T\| FWER) |  | 0.03 | 0.0171 | 0.0854 | yes | Theorem 3 (xyz-paired bootstrap); gross-failure check only (R = 100); pass if <= 0.05 + 3 sqrt(0.05*0.95/R) + 0.02 = 0.135 |
| wild_g | addition: FWER of Westfall-Young at 0.05 |  | 0.07 | 0.0255 | 0.0854 | yes | Sec. 4.3 and Theorem 3; gross-failure check only (R = 100); pass if <= 0.05 + 3 sqrt(0.05*0.95/R) + 0.02 = 0.135 |
| wild_m | addition: FWER of Westfall-Young at 0.05 |  | 0.07 | 0.0255 | 0.0854 | yes | Sec. 4.3 and Theorem 3; gross-failure check only (R = 100); pass if <= 0.05 + 3 sqrt(0.05*0.95/R) + 0.02 = 0.135 |
| xyz | addition: FWER of Westfall-Young at 0.05 |  | 0.03 | 0.0171 | 0.0854 | yes | Sec. 4.3 and Theorem 3; gross-failure check only (R = 100); pass if <= 0.05 + 3 sqrt(0.05*0.95/R) + 0.02 = 0.135 |
| wild_g vs resid_r | simultaneous: \|wild - 0.05\| - \|residual robust - 0.05\| |  | 0.01 |  | 0.0436 | yes | claim p. 702: wild bootstrap preferred for simultaneous inference with heteroscedastic errors; weak directional check (allows the wild bootstrap to be up to 2 s.e. worse); pass if <= 2 s.e. |

### DBZ Sec. 5.2.1-5.2.2 riboflavin (dsmN71) (5 of 6 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| real data | share of CV seeds with no Holm rejection (lasso.proj, non-robust) |  |    1 |  |  | yes | claim p. 714: no rejection at 5% with Holm; pass if >= 0.5 of 6 seeds; rejections per seed: 0,0,0,0,0,0; rule set after development runs (not blind); results conditional on one Z |
| real data | share of CV seeds with no WY rejection (residual bootstrap) |  | 0.667 |  |  | yes | claim p. 714: no rejection with WY; B = 1000, full refits; pass if >= 0.5 of 6 seeds; rejections per seed: 0,0,0,1,1,0 (shortcut: 0,0,0,0,0,0); rule set after development runs (not blind); results conditional on one Z |
| simulated signal | median p_equiv, WY | 1.26e+03 | 1.32e+03 |  |  316 | yes | table p. 713 (exact); relative tol 25% (about +-0.06 in t_rej); 6 fits vs 30 models x 100, B = 1000; raw column scale |
| simulated signal | median p_equiv, BH (p - number of Holm rejections) [descriptive] | 4.09e+03 | 4.09e+03 |  |  | n/a | descriptive, not a criterion: table p. 713 (exact); p - (number of Holm rejections), a consistency check of the definition |
| Fig. 15, c = 3 | share of columns j where WY rejects H0,j |  |  0.9 |  | 0.75 | yes | claim p. 714: WY rejects 'almost all the time' for c > 2.5; 10 random columns (raw scale), B = 200; pass if >= 0.75 |
| Fig. 15, c = 3 | WY minus Holm rejection share |  |    0 |  |    0 | yes | claim Fig. 15: WY clearly has higher power (Holm median -log p about 1.0-1.9 at c = 2.91-3.15); pass if >= 0 |
| Fig. 15, c = 2 | WY minus Holm rejection share |  |    0 |  |    0 | **no** | Fig. 15 (vector graphics): median -log p 6.2 for WY and 0 for Holm at c = 1.97; pass if > 0 |

### ZC Table 1 (Sim.CI, s0=3) (224 of 224 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| p=120 (i) Gamma G=[p] | Cov EX 95% | 0.96 | 0.958 | 0.00634 | 0.0466 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Cov EX 99% | 0.99 | 0.993 | 0.00264 | 0.0323 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Len EX 95% | 1.51 | 1.49 | 0.00442 | 0.0942 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Len EX 99% | 1.69 | 1.67 | 0.00495 | 0.105 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Cov NST 95% | 0.94 | 0.951 | 0.00683 | 0.0505 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Cov NST 99% | 0.98 | 0.988 | 0.00344 | 0.0368 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Len NST 95% |  1.5 | 1.47 | 0.00444 | 0.0938 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Len NST 99% | 1.67 | 1.65 | 0.00503 | 0.105 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Cov ST 95% | 0.95 | 0.95 | 0.00689 | 0.0492 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Cov ST 99% | 0.98 | 0.987 | 0.00358 | 0.0371 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Len ST 95% | 1.48 | 1.46 | 0.00441 | 0.0927 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Len ST 99% | 1.65 | 1.63 | 0.00496 | 0.104 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0 | Len NST 95% | 0.99 | 0.948 | 0.00295 | 0.062 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0 | Len NST 99% | 1.22 | 1.17 | 0.00388 | 0.0775 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0 | Len ST 95% | 0.97 | 0.941 | 0.00293 | 0.0609 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0 | Len ST 99% | 1.19 | 1.15 | 0.00381 | 0.0756 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Cov EX 95% | 0.97 | 0.972 | 0.00522 | 0.0425 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Cov EX 99% | 0.99 | 0.999 | 0.000999 | 0.0299 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Len EX 95% | 1.51 | 1.49 | 0.00441 | 0.0942 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Len EX 99% | 1.69 | 1.67 | 0.00494 | 0.105 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Cov NST 95% | 0.96 | 0.967 | 0.00565 | 0.0452 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Cov NST 99% | 0.99 | 0.993 | 0.00264 | 0.0323 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Len NST 95% |  1.5 | 1.47 | 0.0044 | 0.0937 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Len NST 99% | 1.67 | 1.64 | 0.00513 | 0.105 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Cov ST 95% | 0.97 | 0.966 | 0.00573 | 0.0436 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Cov ST 99% | 0.99 | 0.997 | 0.00173 | 0.0308 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Len ST 95% | 1.48 | 1.46 | 0.00435 | 0.0924 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Len ST 99% | 1.65 | 1.63 | 0.005 | 0.104 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Cov EX 95% | 0.93 | 0.933 | 0.00791 | 0.0539 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Cov EX 99% | 0.99 | 0.985 | 0.00384 | 0.0349 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Len EX 95% | 1.49 | 1.48 | 0.00426 | 0.0926 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Len EX 99% | 1.67 | 1.66 | 0.00477 | 0.104 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Cov NST 95% | 0.93 | 0.928 | 0.00817 | 0.0545 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Cov NST 99% | 0.98 | 0.981 | 0.00432 | 0.0386 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Len NST 95% |  1.5 | 1.49 | 0.00436 | 0.0935 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Len NST 99% | 1.68 | 1.66 | 0.00507 | 0.106 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Cov ST 95% | 0.92 | 0.923 | 0.00843 | 0.0561 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Cov ST 99% | 0.98 | 0.97 | 0.00539 | 0.0409 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Len ST 95% | 1.46 | 1.45 | 0.00425 | 0.091 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Len ST 99% | 1.63 | 1.62 | 0.00484 | 0.102 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0 | Len NST 95% | 0.97 | 1.02 | 0.00303 | 0.0614 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0 | Len NST 99% | 1.18 | 1.25 | 0.00411 | 0.0764 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0 | Len ST 95% | 0.97 | 1.02 | 0.00302 | 0.0613 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0 | Len ST 99% | 1.18 | 1.24 | 0.0041 | 0.0764 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Cov EX 95% | 0.93 | 0.936 | 0.00774 | 0.0535 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Cov EX 99% | 0.99 | 0.985 | 0.00384 | 0.0349 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Len EX 95% | 1.49 | 1.48 | 0.00425 | 0.0925 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Len EX 99% | 1.67 | 1.66 | 0.00476 | 0.104 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Cov NST 95% | 0.93 | 0.931 | 0.00801 | 0.0541 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Cov NST 99% | 0.98 | 0.982 | 0.0042 | 0.0383 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Len NST 95% |  1.5 | 1.48 | 0.00438 | 0.0936 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Len NST 99% | 1.68 | 1.66 | 0.00501 | 0.105 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Cov ST 95% | 0.92 | 0.923 | 0.00843 | 0.0561 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Cov ST 99% | 0.98 | 0.969 | 0.00548 | 0.0411 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Len ST 95% | 1.46 | 1.45 | 0.00423 | 0.091 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Len ST 99% | 1.63 | 1.62 | 0.00485 | 0.102 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Cov EX 95% | 0.97 | 0.965 | 0.00581 | 0.0438 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Cov EX 99% | 0.99 | 0.994 | 0.00244 | 0.032 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Len EX 95% | 1.51 | 1.49 | 0.00771 | 0.108 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Len EX 99% | 1.69 | 1.67 | 0.00863 | 0.121 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Cov NST 95% | 0.95 | 0.958 | 0.00634 | 0.0481 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Cov NST 99% | 0.99 | 0.994 | 0.00244 | 0.032 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Len NST 95% |  1.5 | 1.47 | 0.00763 | 0.107 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Len NST 99% | 1.67 | 1.64 | 0.00859 | 0.12 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Cov ST 95% | 0.96 | 0.955 | 0.00656 | 0.0471 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Cov ST 99% | 0.99 | 0.991 | 0.00299 | 0.033 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Len ST 95% | 1.48 | 1.46 | 0.00758 | 0.106 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Len ST 99% | 1.64 | 1.63 | 0.00852 | 0.118 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0 | Len NST 95% | 0.99 | 0.947 | 0.00493 | 0.0704 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0 | Len NST 99% | 1.22 | 1.16 | 0.00629 | 0.0877 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0 | Len ST 95% | 0.97 | 0.941 | 0.00497 | 0.0696 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0 | Len ST 99% | 1.19 | 1.15 | 0.00625 | 0.086 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Cov EX 95% | 0.98 | 0.975 | 0.00494 | 0.0399 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Cov EX 99% |    1 | 0.997 | 0.00173 | 0.0252 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Len EX 95% | 1.51 | 1.49 | 0.0077 | 0.108 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Len EX 99% | 1.69 | 1.67 | 0.00863 | 0.121 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Cov NST 95% | 0.97 | 0.971 | 0.00531 | 0.0427 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Cov NST 99% | 0.99 | 0.995 | 0.00223 | 0.0316 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Len NST 95% | 1.49 | 1.47 | 0.00763 | 0.107 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Len NST 99% | 1.67 | 1.64 | 0.00864 | 0.12 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Cov ST 95% | 0.97 | 0.969 | 0.00548 | 0.0431 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Cov ST 99% | 0.99 | 0.994 | 0.00244 | 0.032 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Len ST 95% | 1.48 | 1.46 | 0.00756 | 0.106 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Len ST 99% | 1.64 | 1.62 | 0.00854 | 0.118 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Cov EX 95% | 0.93 | 0.934 | 0.00785 | 0.0538 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Cov EX 99% | 0.98 | 0.978 | 0.00464 | 0.0392 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Len EX 95% | 1.49 | 1.47 | 0.00718 | 0.105 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Len EX 99% | 1.67 | 1.64 | 0.00804 | 0.118 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Cov NST 95% | 0.93 | 0.912 | 0.00896 | 0.0562 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Cov NST 99% | 0.98 | 0.973 | 0.00513 | 0.0403 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Len NST 95% | 1.49 | 1.47 | 0.00724 | 0.105 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Len NST 99% | 1.67 | 1.65 | 0.00819 | 0.118 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Cov ST 95% | 0.92 | 0.919 | 0.00863 | 0.0565 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Cov ST 99% | 0.98 | 0.971 | 0.00531 | 0.0407 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Len ST 95% | 1.46 | 1.44 | 0.00708 | 0.103 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Len ST 99% | 1.63 |  1.6 | 0.00801 | 0.115 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0 | Len NST 95% | 0.97 | 1.01 | 0.00508 | 0.0701 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0 | Len NST 99% | 1.18 | 1.23 | 0.00628 | 0.0857 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0 | Len ST 95% | 0.96 | 1.01 | 0.00506 | 0.0695 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0 | Len ST 99% | 1.18 | 1.23 | 0.00622 | 0.0854 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Cov EX 95% | 0.94 | 0.937 | 0.00768 | 0.0522 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Cov EX 99% | 0.98 | 0.98 | 0.00443 | 0.0388 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Len EX 95% | 1.49 | 1.46 | 0.00716 | 0.105 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Len EX 99% | 1.66 | 1.64 | 0.00802 | 0.117 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Cov NST 95% | 0.93 | 0.924 | 0.00838 | 0.0549 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Cov NST 99% | 0.98 | 0.971 | 0.00531 | 0.0407 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Len NST 95% | 1.49 | 1.47 | 0.00721 | 0.105 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Len NST 99% | 1.67 | 1.64 | 0.00816 | 0.118 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Cov ST 95% | 0.92 | 0.925 | 0.00833 | 0.0559 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Cov ST 99% | 0.98 | 0.975 | 0.00494 | 0.0399 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Len ST 95% | 1.46 | 1.44 | 0.00704 | 0.103 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Len ST 99% | 1.62 |  1.6 | 0.00793 | 0.115 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Cov EX 95% | 0.96 | 0.948 | 0.00702 | 0.0481 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Cov EX 99% | 0.99 | 0.983 | 0.00409 | 0.0355 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Len EX 95% | 1.49 |  1.5 | 0.00439 | 0.0931 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Len EX 99% | 1.64 | 1.65 | 0.00484 | 0.103 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Cov NST 95% | 0.96 | 0.94 | 0.00751 | 0.0492 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Cov NST 99% | 0.98 | 0.983 | 0.00409 | 0.0381 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Len NST 95% | 1.49 |  1.5 | 0.00439 | 0.0931 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Len NST 99% | 1.64 | 1.64 | 0.00499 | 0.103 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Cov ST 95% | 0.96 | 0.94 | 0.00751 | 0.0492 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Cov ST 99% | 0.98 | 0.978 | 0.00464 | 0.0392 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Len ST 95% | 1.47 | 1.48 | 0.00436 | 0.092 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Len ST 99% | 1.61 | 1.62 | 0.00496 | 0.102 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0 | Len NST 95% |  0.9 | 0.882 | 0.00271 | 0.0565 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0 | Len NST 99% |  1.1 | 1.08 | 0.00356 | 0.0701 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0 | Len ST 95% | 0.89 | 0.88 | 0.00272 | 0.056 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0 | Len ST 99% | 1.09 | 1.08 | 0.00355 | 0.0695 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Cov EX 95% | 0.98 | 0.977 | 0.00474 | 0.0395 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Cov EX 99% |    1 | 0.997 | 0.00173 | 0.0252 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Len EX 95% | 1.49 |  1.5 | 0.00439 | 0.0931 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Len EX 99% | 1.64 | 1.65 | 0.00484 | 0.103 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Cov NST 95% | 0.98 | 0.971 | 0.00531 | 0.0407 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Cov NST 99% | 0.99 | 0.995 | 0.00223 | 0.0316 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Len NST 95% | 1.49 |  1.5 | 0.00442 | 0.0933 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Len NST 99% | 1.63 | 1.64 | 0.00497 | 0.103 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Cov ST 95% | 0.98 | 0.97 | 0.00539 | 0.0409 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Cov ST 99% | 0.99 | 0.99 | 0.00315 | 0.0333 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Len ST 95% | 1.47 | 1.48 | 0.00439 | 0.0921 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Len ST 99% | 1.61 | 1.62 | 0.00491 | 0.101 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Cov EX 95% | 0.94 | 0.933 | 0.00791 | 0.0527 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Cov EX 99% | 0.98 | 0.982 | 0.0042 | 0.0383 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Len EX 95% | 1.65 | 1.61 | 0.00496 | 0.104 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Len EX 99% | 1.82 | 1.78 | 0.00546 | 0.114 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Cov NST 95% | 0.94 | 0.931 | 0.00801 | 0.053 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Cov NST 99% | 0.98 | 0.977 | 0.00474 | 0.0395 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Len NST 95% | 1.66 | 1.61 | 0.00497 | 0.104 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Len NST 99% | 1.83 | 1.77 | 0.00567 | 0.116 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Cov ST 95% | 0.93 | 0.925 | 0.00833 | 0.0548 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Cov ST 99% | 0.97 | 0.976 | 0.00484 | 0.0417 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Len ST 95% | 1.63 | 1.59 | 0.00491 | 0.102 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Len ST 99% | 1.78 | 1.75 | 0.00554 | 0.113 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0 | Len NST 95% | 0.98 | 1.02 | 0.00328 | 0.0629 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0 | Len NST 99% | 1.19 | 1.25 | 0.00419 | 0.0773 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0 | Len ST 95% | 0.97 | 1.02 | 0.00326 | 0.0623 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0 | Len ST 99% | 1.19 | 1.24 | 0.00415 | 0.0771 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Cov EX 95% | 0.94 | 0.934 | 0.00785 | 0.0526 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Cov EX 99% | 0.98 | 0.982 | 0.0042 | 0.0383 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Len EX 95% | 1.65 | 1.61 | 0.00496 | 0.104 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Len EX 99% | 1.82 | 1.78 | 0.00545 | 0.114 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Cov NST 95% | 0.95 | 0.928 | 0.00817 | 0.0521 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Cov NST 99% | 0.98 | 0.978 | 0.00464 | 0.0392 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Len NST 95% | 1.66 | 1.61 | 0.00502 | 0.104 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Len NST 99% | 1.83 | 1.77 | 0.00556 | 0.115 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Cov ST 95% | 0.93 | 0.92 | 0.00858 | 0.0553 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Cov ST 99% | 0.97 | 0.975 | 0.00494 | 0.0419 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Len ST 95% | 1.63 | 1.59 | 0.00495 | 0.102 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Len ST 99% | 1.78 | 1.74 | 0.00544 | 0.112 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Cov EX 95% | 0.96 | 0.959 | 0.00627 | 0.0464 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Cov EX 99% | 0.98 | 0.983 | 0.00409 | 0.0381 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Len EX 95% | 1.48 | 1.48 | 0.00708 | 0.104 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Len EX 99% | 1.63 | 1.63 | 0.0078 | 0.115 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Cov NST 95% | 0.94 | 0.952 | 0.00676 | 0.0503 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Cov NST 99% | 0.98 | 0.985 | 0.00384 | 0.0376 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Len NST 95% | 1.47 | 1.48 | 0.00708 | 0.104 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Len NST 99% | 1.62 | 1.62 | 0.00786 | 0.114 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Cov ST 95% | 0.95 | 0.947 | 0.00708 | 0.0497 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Cov ST 99% | 0.98 | 0.982 | 0.0042 | 0.0383 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Len ST 95% | 1.46 | 1.46 | 0.007 | 0.103 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Len ST 99% |  1.6 |  1.6 | 0.00775 | 0.113 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0 | Len NST 95% | 0.89 | 0.871 | 0.00424 | 0.0625 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0 | Len NST 99% | 1.09 | 1.07 | 0.00538 | 0.0773 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0 | Len ST 95% | 0.88 | 0.87 | 0.00424 | 0.062 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0 | Len ST 99% | 1.08 | 1.07 | 0.00537 | 0.0768 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Cov EX 95% | 0.98 | 0.978 | 0.00464 | 0.0392 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Cov EX 99% | 0.99 | 0.997 | 0.00173 | 0.0308 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Len EX 95% | 1.48 | 1.48 | 0.00708 | 0.104 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Len EX 99% | 1.63 | 1.63 | 0.0078 | 0.115 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Cov NST 95% | 0.96 | 0.972 | 0.00522 | 0.0443 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Cov NST 99% | 0.99 | 0.997 | 0.00173 | 0.0308 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Len NST 95% | 1.47 | 1.48 | 0.0071 | 0.104 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Len NST 99% | 1.62 | 1.62 | 0.00787 | 0.114 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Cov ST 95% | 0.97 | 0.971 | 0.00531 | 0.0427 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Cov ST 99% | 0.99 | 0.994 | 0.00244 | 0.032 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Len ST 95% | 1.46 | 1.46 | 0.007 | 0.103 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Len ST 99% |  1.6 |  1.6 | 0.00777 | 0.113 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Cov EX 95% | 0.92 | 0.939 | 0.00757 | 0.0543 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Cov EX 99% | 0.97 | 0.977 | 0.00474 | 0.0415 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Len EX 95% | 1.64 |  1.6 | 0.00752 | 0.114 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Len EX 99% | 1.81 | 1.76 | 0.00827 | 0.126 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Cov NST 95% | 0.92 | 0.923 | 0.00843 | 0.0561 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Cov NST 99% | 0.97 | 0.978 | 0.00464 | 0.0414 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Len NST 95% | 1.65 |  1.6 | 0.00753 | 0.114 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Len NST 99% | 1.82 | 1.75 | 0.00841 | 0.127 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Cov ST 95% | 0.91 | 0.925 | 0.00833 | 0.0569 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Cov ST 99% | 0.97 | 0.975 | 0.00494 | 0.0419 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Len ST 95% | 1.62 | 1.58 | 0.00746 | 0.113 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Len ST 99% | 1.77 | 1.73 | 0.00829 | 0.124 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0 | Len NST 95% | 0.97 | 1.02 | 0.00486 | 0.0691 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0 | Len NST 99% | 1.19 | 1.24 | 0.00622 | 0.0859 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0 | Len ST 95% | 0.97 | 1.01 | 0.00485 | 0.0691 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0 | Len ST 99% | 1.18 | 1.24 | 0.00611 | 0.0849 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Cov EX 95% | 0.92 | 0.941 | 0.00745 | 0.0541 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Cov EX 99% | 0.97 | 0.977 | 0.00474 | 0.0415 | yes | (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Len EX 95% | 1.64 |  1.6 | 0.00751 | 0.114 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Len EX 99% | 1.81 | 1.76 | 0.00827 | 0.126 | yes | width: 3 MC s.e. + 5% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Cov NST 95% | 0.92 | 0.931 | 0.00801 | 0.0552 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Cov NST 99% | 0.97 | 0.98 | 0.00443 | 0.0409 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Len NST 95% | 1.65 | 1.59 | 0.00748 | 0.114 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Len NST 99% | 1.82 | 1.75 | 0.00833 | 0.126 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Cov ST 95% | 0.92 | 0.93 | 0.00807 | 0.0553 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Cov ST 99% | 0.97 | 0.969 | 0.00548 | 0.0431 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Len ST 95% | 1.62 | 1.58 | 0.00743 | 0.113 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Len ST 99% | 1.77 | 1.73 | 0.00824 | 0.123 | yes | width: 3 MC s.e. + 5% of paper; R=1000 vs paper R=1000 |

### ZC Table 2 (Sim.CI, s0=15) (88 of 96 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| p=120 (i) Gamma G=[p] | Len EX 95% |  1.6 | 1.52 | 0.00473 | 0.18 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Len EX 99% | 1.79 |  1.7 | 0.0053 | 0.201 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Len ST 95% | 1.57 | 1.49 | 0.00472 | 0.177 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Len ST 99% | 1.75 | 1.66 | 0.00531 | 0.198 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0 | Len NST 95% | 1.44 | 1.22 | 0.00388 | 0.16 | **no** | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0 | Len NST 99% | 1.74 | 1.42 | 0.0047 | 0.194 | **no** | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0 | Len ST 95% |  1.3 | 1.22 | 0.00389 | 0.146 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0 | Len ST 99% | 1.51 | 1.41 | 0.00465 | 0.171 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Len EX 95% | 1.59 | 1.51 | 0.0047 | 0.179 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Len EX 99% | 1.78 |  1.7 | 0.00527 |  0.2 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Len ST 95% | 1.55 | 1.48 | 0.00467 | 0.175 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Len ST 99% | 1.73 | 1.65 | 0.00538 | 0.196 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Len EX 95% | 1.57 |  1.5 | 0.00512 | 0.179 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Len EX 99% | 1.76 | 1.67 | 0.00574 |  0.2 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Len ST 95% | 1.54 | 1.47 | 0.00506 | 0.175 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Len ST 99% | 1.71 | 1.63 | 0.00568 | 0.195 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0 | Len NST 95% | 1.27 | 1.25 | 0.00435 | 0.145 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0 | Len NST 99% | 1.49 | 1.45 | 0.00527 | 0.171 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0 | Len ST 95% | 1.24 | 1.22 | 0.00428 | 0.142 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0 | Len ST 99% | 1.43 | 1.41 | 0.00504 | 0.164 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Len EX 95% | 1.56 | 1.48 | 0.00507 | 0.178 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Len EX 99% | 1.75 | 1.66 | 0.00569 | 0.199 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Len ST 95% | 1.53 | 1.45 | 0.00503 | 0.174 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Len ST 99% | 1.71 | 1.62 | 0.00572 | 0.195 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Len EX 95% | 1.59 | 1.51 | 0.00727 | 0.19 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Len EX 99% | 1.78 | 1.69 | 0.00814 | 0.213 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Len ST 95% | 1.56 | 1.48 | 0.00719 | 0.187 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Len ST 99% | 1.74 | 1.65 | 0.00796 | 0.208 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0 | Len NST 95% | 1.44 | 1.21 | 0.00585 | 0.169 | **no** | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0 | Len NST 99% | 1.73 |  1.4 | 0.00686 | 0.202 | **no** | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0 | Len ST 95% |  1.3 | 1.21 | 0.00583 | 0.155 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0 | Len ST 99% |  1.5 |  1.4 | 0.00686 | 0.179 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Len EX 95% | 1.58 |  1.5 | 0.00722 | 0.189 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Len EX 99% | 1.77 | 1.68 | 0.0081 | 0.211 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Len ST 95% | 1.55 | 1.47 | 0.00712 | 0.185 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Len ST 99% | 1.73 | 1.63 | 0.00801 | 0.207 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Len EX 95% | 1.56 | 1.49 | 0.00783 | 0.189 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Len EX 99% | 1.75 | 1.67 | 0.00877 | 0.212 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Len ST 95% | 1.53 | 1.46 | 0.00779 | 0.186 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Len ST 99% | 1.71 | 1.62 | 0.00858 | 0.207 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0 | Len NST 95% | 1.27 | 1.24 | 0.00648 | 0.154 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0 | Len NST 99% | 1.48 | 1.44 | 0.00781 | 0.181 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0 | Len ST 95% | 1.23 | 1.22 | 0.0064 | 0.15 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0 | Len ST 99% | 1.42 | 1.41 | 0.00757 | 0.174 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Len EX 95% | 1.55 | 1.47 | 0.00775 | 0.188 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Len EX 99% | 1.74 | 1.65 | 0.0087 | 0.211 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Len ST 95% | 1.53 | 1.45 | 0.00762 | 0.185 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Len ST 99% |  1.7 | 1.61 | 0.00847 | 0.206 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Len EX 95% | 1.62 | 1.52 | 0.0046 | 0.182 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Len EX 99% | 1.78 | 1.68 | 0.00506 | 0.199 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Len ST 95% |  1.6 |  1.5 | 0.00455 | 0.179 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Len ST 99% | 1.75 | 1.65 | 0.0051 | 0.197 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0 | Len NST 95% | 1.36 |  1.1 | 0.00334 | 0.15 | **no** | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0 | Len NST 99% | 1.66 | 1.28 | 0.00416 | 0.184 | **no** | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0 | Len ST 95% | 1.22 |  1.1 | 0.00336 | 0.136 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0 | Len ST 99% | 1.41 | 1.27 | 0.00412 | 0.158 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Len EX 95% | 1.61 | 1.52 | 0.00459 | 0.18 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Len EX 99% | 1.78 | 1.68 | 0.00506 | 0.199 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Len ST 95% | 1.59 |  1.5 | 0.00459 | 0.178 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Len ST 99% | 1.75 | 1.64 | 0.00511 | 0.197 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Len EX 95% | 1.76 | 1.64 | 0.0058 | 0.201 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Len EX 99% | 1.93 |  1.8 | 0.00639 | 0.22 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Len ST 95% | 1.73 | 1.62 | 0.00575 | 0.197 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Len ST 99% |  1.9 | 1.77 | 0.00634 | 0.217 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0 | Len NST 95% | 1.34 | 1.25 | 0.00451 | 0.153 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0 | Len NST 99% | 1.57 | 1.44 | 0.00541 | 0.18 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0 | Len ST 95% | 1.29 | 1.24 | 0.00447 | 0.148 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0 | Len ST 99% |  1.5 | 1.43 | 0.0053 | 0.173 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Len EX 95% | 1.75 | 1.64 | 0.00579 |  0.2 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Len EX 99% | 1.93 |  1.8 | 0.00637 | 0.22 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Len ST 95% | 1.73 | 1.61 | 0.00575 | 0.197 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Len ST 99% |  1.9 | 1.77 | 0.00643 | 0.217 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Len EX 95% | 1.61 | 1.53 | 0.00998 | 0.203 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Len EX 99% | 1.77 | 1.68 | 0.011 | 0.224 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Len ST 95% | 1.59 | 1.51 | 0.00993 | 0.201 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Len ST 99% | 1.74 | 1.65 | 0.011 | 0.221 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0 | Len NST 95% | 1.35 | 1.11 | 0.00728 | 0.166 | **no** | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0 | Len NST 99% | 1.65 | 1.28 | 0.0085 | 0.201 | **no** | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0 | Len ST 95% | 1.22 |  1.1 | 0.00724 | 0.153 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0 | Len ST 99% |  1.4 | 1.27 | 0.00844 | 0.176 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Len EX 95% | 1.61 | 1.53 | 0.00997 | 0.203 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Len EX 99% | 1.77 | 1.68 | 0.011 | 0.224 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Len ST 95% | 1.58 |  1.5 | 0.0099 |  0.2 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Len ST 99% | 1.73 | 1.65 | 0.0107 | 0.218 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Len EX 95% | 1.73 | 1.64 | 0.013 | 0.228 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Len EX 99% | 1.91 | 1.81 | 0.0143 | 0.252 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Len ST 95% | 1.71 | 1.62 | 0.013 | 0.226 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Len ST 99% | 1.87 | 1.78 | 0.0142 | 0.247 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0 | Len NST 95% | 1.32 | 1.25 | 0.0101 | 0.175 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0 | Len NST 99% | 1.55 | 1.45 | 0.0116 | 0.204 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0 | Len ST 95% | 1.28 | 1.24 | 0.00991 | 0.17 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0 | Len ST 99% | 1.48 | 1.43 | 0.0113 | 0.196 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Len EX 95% | 1.73 | 1.64 | 0.013 | 0.228 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Len EX 99% |  1.9 |  1.8 | 0.0143 | 0.251 | yes | width: 3 MC s.e. + 10% of paper (EX: Gumbel approximation, not a SILM method); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Len ST 95% | 1.71 | 1.62 | 0.0127 | 0.225 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Len ST 99% | 1.87 | 1.77 | 0.0139 | 0.246 | yes | width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |

### ZC Tables 1-2 claims (7 of 7 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| Tables 1-2, NST and ST, 64 combinations | Share with \|Cov(S0c) - level\| <= \|Cov(S0) - level\| |  | 0.984 |  |  | yes | claim (i) p. 23; pass if >= 0.80 (paper: 0.98) |
| Table 2 (s0=15), 48 combinations | Share with Cov(NST) >= Cov(ST) - 0.01 |  | 0.896 |  |  | yes | claim (ii) p. 23; pass if >= 0.80 (paper: 1.00) |
| Table 2 (s0=15), 48 combinations | Share with Len(NST) > Len(ST) |  |    1 |  |  | yes | claim (ii) p. 23; pass if >= 0.80 (paper: 1.00); direction only, see ambiguity 3 |
| Table 2 (s0=15), G=S0, 32 combinations | Share with Cov(S0) <= level - 0.05 |  |    1 |  |  | yes | claim (iii) p. 23; pass if >= 0.75 (paper: 1.00) |
| Table 1 (s0=3), NST, G=S0c,[p], 32 combinations | Share with \|Cov - level\| <= 0.04 |  |    1 |  |  | yes | p. 22 'satisfactory coverage'; pass if >= 0.80 (paper: 1.00) |
| t errors, 8 (design, s0) cells | Cells with median sigma_SL < 1 (scaled lasso underestimates) |  |    8 |  |  | yes | Figure S.1; pass if >= 6 of 8 |
| t errors, 8 (design, s0) cells | Cells with \|median modified sigma - 1\| <= 0.05 (and >= median sigma_SL) |  |    8 |  |  | yes | Figure S.1 / eq. (24): underestimation removed; pass if >= 6 of 8 |

### ZC Table 3 (SR, s0=3) (59 of 64 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| p=120 (ii) Gamma | Lassosc mean d | 0.56 | 0.527 | 0.00251 | 0.0314 | **no** | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | Lassosc SD d | 0.09 | 0.0794 | 0.00178 | 0.0506 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | Lassosc FP | 7.07 | 8.48 | 0.0983 | 1.93 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | SupRec mean d | 0.97 | 0.964 | 0.00205 | 0.0284 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | SupRec SD d | 0.06 | 0.0648 | 0.00145 | 0.0409 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | SupRec FP | 0.23 | 0.279 | 0.0165 | 0.216 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | SupRec FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | Lassosc mean d | 0.56 | 0.53 | 0.0024 | 0.0312 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | Lassosc SD d | 0.09 | 0.0758 | 0.00169 | 0.0504 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | Lassosc FP | 7.09 | 8.28 | 0.0922 | 1.91 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | SupRec mean d | 0.97 | 0.963 | 0.0021 | 0.0285 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | SupRec SD d | 0.06 | 0.0664 | 0.00148 | 0.041 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | SupRec FP | 0.24 | 0.291 | 0.0169 | 0.22 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | SupRec FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | Lassosc mean d | 0.68 | 0.609 | 0.00268 | 0.0332 | **no** | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | Lassosc SD d | 0.11 | 0.0849 | 0.0019 | 0.0568 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | Lassosc FP | 3.98 | 5.53 | 0.0708 |  1.2 | **no** | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | SupRec mean d | 0.97 | 0.975 | 0.00181 | 0.0279 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | SupRec SD d | 0.06 | 0.0572 | 0.00128 | 0.0406 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | SupRec FP |  0.2 | 0.197 | 0.0144 | 0.201 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | SupRec FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | Lassosc mean d | 0.68 | 0.601 | 0.00266 | 0.0324 | **no** | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | Lassosc SD d |  0.1 | 0.0843 | 0.00188 | 0.0538 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | Lassosc FP | 3.94 | 5.78 | 0.0718 | 1.19 | **no** | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | SupRec mean d | 0.98 | 0.974 | 0.00179 | 0.0272 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | SupRec SD d | 0.05 | 0.0565 | 0.00126 | 0.0376 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | SupRec FP | 0.16 | 0.202 | 0.014 | 0.192 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | SupRec FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | Lassosc mean d | 0.41 | 0.399 | 0.00145 | 0.0264 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | Lassosc SD d | 0.05 | 0.0458 | 0.00102 | 0.037 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | Lassosc FP | 15.2 | 16.6 | 0.133 |  3.7 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | SupRec mean d | 0.97 | 0.966 | 0.00205 | 0.0291 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | SupRec SD d | 0.07 | 0.0649 | 0.00145 | 0.0439 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | SupRec FP | 0.27 | 0.267 | 0.0167 | 0.225 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | SupRec FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | Lassosc mean d | 0.41 | 0.399 | 0.00144 | 0.0264 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | Lassosc SD d | 0.05 | 0.0454 | 0.00102 | 0.037 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | Lassosc FP | 15.2 | 16.6 | 0.13 | 3.69 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | SupRec mean d | 0.97 | 0.966 | 0.00204 | 0.0283 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | SupRec SD d | 0.06 | 0.0644 | 0.00144 | 0.0409 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | SupRec FP | 0.25 | 0.268 | 0.0164 | 0.22 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | SupRec FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma | Lassosc mean d | 0.62 | 0.595 | 0.00275 | 0.0319 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma | Lassosc SD d | 0.09 | 0.087 | 0.00195 | 0.0509 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma | Lassosc FP | 5.38 | 5.98 | 0.0786 | 1.51 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma | SupRec mean d | 0.97 | 0.98 | 0.00156 | 0.0274 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma | SupRec SD d | 0.06 | 0.0493 | 0.0011 | 0.0402 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma | SupRec FP | 0.18 | 0.152 | 0.012 | 0.187 | yes | R=1000 vs paper R=1000 |
| p=500 (i) Gamma | SupRec FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 | Lassosc mean d | 0.62 | 0.607 | 0.00285 | 0.0321 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 | Lassosc SD d | 0.09 | 0.09 | 0.00201 | 0.051 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 | Lassosc FP | 5.24 | 5.65 | 0.0767 | 1.47 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 | SupRec mean d | 0.97 | 0.981 | 0.00155 | 0.0273 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 | SupRec SD d | 0.06 | 0.0489 | 0.00109 | 0.0402 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 | SupRec FP |  0.2 | 0.146 | 0.012 | 0.191 | yes | R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 | SupRec FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |

### ZC Table 3 (SR, s0=15) (48 of 48 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| p=120 (ii) Gamma | Lassosc mean d | 0.65 | 0.628 | 0.00101 | 0.0249 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | Lassosc SD d | 0.04 | 0.032 | 0.000716 | 0.0334 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | Lassosc FP | 20.2 | 23.3 | 0.121 | 4.65 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | SupRec mean d | 0.98 | 0.977 | 0.000843 | 0.0232 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | SupRec SD d | 0.02 | 0.0267 | 0.000596 | 0.0272 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | SupRec FP |  0.6 | 0.746 | 0.0286 | 0.341 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) Gamma | SupRec FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | Lassosc mean d | 0.65 | 0.627 | 0.00105 | 0.0249 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | Lassosc SD d | 0.04 | 0.0333 | 0.000745 | 0.0335 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | Lassosc FP | 20.2 | 23.5 | 0.127 | 4.69 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | SupRec mean d | 0.98 | 0.976 | 0.000889 | 0.0233 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | SupRec SD d | 0.02 | 0.0281 | 0.000629 | 0.0273 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | SupRec FP | 0.55 | 0.768 | 0.0299 | 0.337 | yes | R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 | SupRec FN | 0.01 | 0.006 | 0.00424 | 0.12 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | Lassosc mean d | 0.72 | 0.733 | 0.00119 | 0.0252 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | Lassosc SD d | 0.04 | 0.0377 | 0.000844 | 0.0337 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | Lassosc FP | 13.9 | 13.2 | 0.0908 | 3.27 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | SupRec mean d | 0.98 | 0.987 | 0.000653 | 0.0235 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | SupRec SD d | 0.03 | 0.0206 | 0.000461 | 0.0299 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | SupRec FP | 0.71 | 0.415 | 0.0215 | 0.333 | yes | R=1000 vs paper R=1000 |
| p=120 (i) Gamma | SupRec FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | Lassosc mean d | 0.72 | 0.731 | 0.00117 | 0.0252 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | Lassosc SD d | 0.04 | 0.0371 | 0.000829 | 0.0337 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | Lassosc FP | 13.9 | 13.3 | 0.0905 | 3.26 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | SupRec mean d | 0.98 | 0.986 | 0.000652 | 0.0235 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | SupRec SD d | 0.03 | 0.0206 | 0.000461 | 0.0299 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | SupRec FP | 0.68 | 0.429 | 0.021 | 0.325 | yes | R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 | SupRec FN | 0.02 | 0.005 | 0.00412 | 0.121 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | Lassosc mean d |  0.5 |  0.5 | 0.000596 | 0.0226 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | Lassosc SD d | 0.02 | 0.0189 | 0.000422 | 0.0268 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | Lassosc FP | 45.4 | 45.4 | 0.144 | 9.79 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | Lassosc FN |    0 |    0 |    0 |  0.1 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | SupRec mean d | 0.96 | 0.964 | 0.00111 | 0.025 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | SupRec SD d | 0.04 | 0.035 | 0.000783 | 0.0336 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | SupRec FP | 1.43 | 1.12 | 0.037 | 0.543 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) Gamma | SupRec FN | 0.04 | 0.062 | 0.00776 | 0.141 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | Lassosc mean d |  0.5 | 0.499 | 0.000624 | 0.0227 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | Lassosc SD d | 0.02 | 0.0197 | 0.000441 | 0.0269 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | Lassosc FP | 45.6 | 45.5 | 0.148 | 9.85 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | Lassosc FN |    0 | 0.006 | 0.00374 | 0.116 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | SupRec mean d | 0.96 | 0.96 | 0.00137 | 0.0256 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | SupRec SD d | 0.04 | 0.0433 | 0.000968 | 0.034 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | SupRec FP | 1.38 | 1.18 | 0.0386 | 0.54 | yes | R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 | SupRec FN |  0.1 | 0.132 | 0.0204 | 0.207 | yes | R=1000 vs paper R=1000 |

### ZC Table 3 claims (2 of 2 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| s0=3, 8 cells | Cells with mean d(SupRec) > mean d(Lassosc) |  |    8 |  |  | yes | 'clearly outperforms Lasso' (s0=3); pass if >= 8 of 8 (paper: 8 of 8) |
| s0=15, 8 cells | Cells with mean d(SupRec) > mean d(Lassosc) |  |    6 |  |  | yes | 'in general outperforms' (s0=15); pass if >= 6 of 8 (paper: 8 of 8) |

### ZC Table 4 (size) (48 of 48 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| (i) G=S0c one-step Gamma | Size NST 5% | 0.02 | 0.024 | 0.00684 | 0.0437 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0c one-step Gamma | Size NST 1% |    0 | 0.004 | 0.00282 | 0.026 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0c one-step Gamma | Size ST 5% | 0.03 | 0.022 | 0.00656 | 0.0468 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0c one-step Gamma | Size ST 1% | 0.01 |    0 |    0 | 0.0334 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0c one-step t4/sqrt2 | Size NST 5% | 0.03 | 0.032 | 0.00787 | 0.0483 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0c one-step t4/sqrt2 | Size NST 1% | 0.01 |    0 |    0 | 0.0334 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0c one-step t4/sqrt2 | Size ST 5% | 0.03 | 0.04 | 0.00876 | 0.0495 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0c one-step t4/sqrt2 | Size ST 1% |    0 | 0.002 | 0.002 | 0.0242 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0c three-step Gamma | Size NST 5% | 0.07 | 0.056 | 0.0103 | 0.0606 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0c three-step Gamma | Size NST 1% | 0.03 | 0.014 | 0.00525 | 0.0455 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0c three-step Gamma | Size ST 5% | 0.07 | 0.052 | 0.00993 | 0.0602 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0c three-step Gamma | Size ST 1% | 0.02 | 0.012 | 0.00487 | 0.0414 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0c three-step t4/sqrt2 | Size NST 5% | 0.06 | 0.036 | 0.00833 | 0.0565 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0c three-step t4/sqrt2 | Size NST 1% | 0.01 | 0.016 | 0.00561 | 0.0379 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0c three-step t4/sqrt2 | Size ST 5% | 0.06 | 0.05 | 0.00975 | 0.058 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0c three-step t4/sqrt2 | Size ST 1% | 0.01 | 0.018 | 0.00595 | 0.0384 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c one-step Gamma | Size NST 5% | 0.02 | 0.004 | 0.00282 | 0.0398 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c one-step Gamma | Size NST 1% | 0.01 | 0.002 | 0.002 | 0.034 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c one-step Gamma | Size ST 5% | 0.02 | 0.008 | 0.00398 | 0.0406 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c one-step Gamma | Size ST 1% | 0.01 | 0.004 | 0.00282 | 0.0346 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c one-step t4/sqrt2 | Size NST 5% | 0.02 | 0.018 | 0.00595 | 0.0426 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c one-step t4/sqrt2 | Size NST 1% | 0.01 | 0.006 | 0.00345 | 0.0352 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c one-step t4/sqrt2 | Size ST 5% | 0.01 | 0.016 | 0.00561 | 0.0379 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c one-step t4/sqrt2 | Size ST 1% |    0 | 0.008 | 0.00398 | 0.0285 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c three-step Gamma | Size NST 5% | 0.06 | 0.032 | 0.00787 | 0.056 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c three-step Gamma | Size NST 1% | 0.03 | 0.012 | 0.00487 | 0.0451 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c three-step Gamma | Size ST 5% | 0.05 | 0.04 | 0.00876 | 0.0547 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c three-step Gamma | Size ST 1% | 0.02 | 0.014 | 0.00525 | 0.0418 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c three-step t4/sqrt2 | Size NST 5% | 0.05 | 0.032 | 0.00787 | 0.0537 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c three-step t4/sqrt2 | Size NST 1% | 0.02 | 0.012 | 0.00487 | 0.0414 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c three-step t4/sqrt2 | Size ST 5% | 0.04 | 0.034 | 0.0081 | 0.0514 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G=S0~c three-step t4/sqrt2 | Size ST 1% | 0.02 | 0.024 | 0.00684 | 0.0437 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c one-step Gamma | Size NST 5% | 0.08 | 0.084 | 0.0124 | 0.0649 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c one-step Gamma | Size NST 1% | 0.03 | 0.034 | 0.0081 | 0.0486 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c one-step Gamma | Size ST 5% | 0.08 | 0.092 | 0.0129 | 0.0656 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c one-step Gamma | Size ST 1% | 0.03 | 0.024 | 0.00684 | 0.0471 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c one-step t4/sqrt2 | Size NST 5% | 0.09 | 0.11 | 0.014 | 0.0686 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c one-step t4/sqrt2 | Size NST 1% | 0.02 | 0.038 | 0.00855 | 0.0461 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c one-step t4/sqrt2 | Size ST 5% | 0.08 | 0.114 | 0.0142 | 0.0673 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c one-step t4/sqrt2 | Size ST 1% | 0.03 | 0.03 | 0.00763 | 0.048 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c three-step Gamma | Size NST 5% | 0.09 | 0.07 | 0.0114 | 0.0654 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c three-step Gamma | Size NST 1% | 0.03 | 0.022 | 0.00656 | 0.0468 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c three-step Gamma | Size ST 5% |  0.1 | 0.088 | 0.0127 | 0.0684 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c three-step Gamma | Size ST 1% | 0.03 | 0.032 | 0.00787 | 0.0483 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c three-step t4/sqrt2 | Size NST 5% |  0.1 | 0.096 | 0.0132 | 0.069 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c three-step t4/sqrt2 | Size NST 1% | 0.04 | 0.03 | 0.00763 | 0.0509 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c three-step t4/sqrt2 | Size ST 5% | 0.11 | 0.104 | 0.0137 | 0.071 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G=S0c three-step t4/sqrt2 | Size ST 1% | 0.04 | 0.038 | 0.00855 | 0.0519 | yes | R=500 vs paper R=1000 (reduced) |

### ZC Table 4 (power) (73 of 96 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| (i) G={3}+S0c one-step Gamma | Power NST 5% | 0.61 | 0.634 | 0.0215 | 0.0998 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c one-step Gamma | Power NST 1% | 0.49 | 0.53 | 0.0223 | 0.102 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c one-step Gamma | Power ST 5% | 0.62 | 0.668 | 0.0211 | 0.0991 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c one-step Gamma | Power ST 1% | 0.51 | 0.572 | 0.0221 | 0.102 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c one-step t4/sqrt2 | Power NST 5% | 0.66 | 0.636 | 0.0215 | 0.0983 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c one-step t4/sqrt2 | Power NST 1% | 0.54 | 0.548 | 0.0223 | 0.102 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c one-step t4/sqrt2 | Power ST 5% | 0.67 | 0.664 | 0.0211 | 0.0974 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c one-step t4/sqrt2 | Power ST 1% | 0.56 | 0.568 | 0.0222 | 0.102 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c three-step Gamma | Power NST 5% | 0.73 | 0.76 | 0.0191 | 0.0921 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c three-step Gamma | Power NST 1% | 0.63 | 0.666 | 0.0211 | 0.0988 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c three-step Gamma | Power ST 5% | 0.72 | 0.768 | 0.0189 | 0.0924 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c three-step Gamma | Power ST 1% | 0.61 | 0.678 | 0.0209 | 0.0992 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c three-step t4/sqrt2 | Power NST 5% | 0.74 | 0.754 | 0.0193 | 0.0917 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c three-step t4/sqrt2 | Power NST 1% | 0.62 | 0.656 | 0.0212 | 0.0992 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c three-step t4/sqrt2 | Power ST 5% | 0.72 | 0.754 | 0.0193 | 0.0928 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={3}+S0c three-step t4/sqrt2 | Power ST 1% |  0.6 | 0.668 | 0.0211 | 0.0996 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c one-step Gamma | Power NST 5% | 0.88 | 0.956 | 0.00917 | 0.0681 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c one-step Gamma | Power NST 1% | 0.79 |  0.9 | 0.0134 | 0.0822 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c one-step Gamma | Power ST 5% | 0.87 | 0.964 | 0.00833 | 0.069 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c one-step Gamma | Power ST 1% | 0.78 | 0.924 | 0.0119 | 0.082 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c one-step t4/sqrt2 | Power NST 5% | 0.89 | 0.934 | 0.0111 | 0.0683 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c one-step t4/sqrt2 | Power NST 1% |  0.8 | 0.88 | 0.0145 | 0.0822 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c one-step t4/sqrt2 | Power ST 5% | 0.88 | 0.94 | 0.0106 | 0.0693 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c one-step t4/sqrt2 | Power ST 1% |  0.8 | 0.894 | 0.0138 | 0.0815 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c three-step Gamma | Power NST 5% | 0.94 | 0.982 | 0.00595 | 0.0544 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c three-step Gamma | Power NST 1% | 0.87 | 0.966 | 0.0081 | 0.0689 | **no** | R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c three-step Gamma | Power ST 5% | 0.93 | 0.988 | 0.00487 | 0.056 | **no** | R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c three-step Gamma | Power ST 1% | 0.85 | 0.964 | 0.00833 | 0.0718 | **no** | R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c three-step t4/sqrt2 | Power NST 5% | 0.93 | 0.976 | 0.00684 | 0.0574 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c three-step t4/sqrt2 | Power NST 1% | 0.87 | 0.942 | 0.0105 | 0.0706 | **no** | R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c three-step t4/sqrt2 | Power ST 5% | 0.92 | 0.97 | 0.00763 | 0.06 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={2,3}+S0c three-step t4/sqrt2 | Power ST 1% | 0.85 | 0.94 | 0.0106 | 0.0734 | **no** | R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c one-step Gamma | Power NST 5% | 0.58 | 0.57 | 0.0221 | 0.101 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c one-step Gamma | Power NST 1% | 0.48 | 0.46 | 0.0223 | 0.102 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c one-step Gamma | Power ST 5% | 0.59 | 0.65 | 0.0213 |  0.1 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c one-step Gamma | Power ST 1% |  0.5 | 0.53 | 0.0223 | 0.102 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c one-step t4/sqrt2 | Power NST 5% | 0.63 | 0.564 | 0.0222 |  0.1 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c one-step t4/sqrt2 | Power NST 1% | 0.53 | 0.456 | 0.0223 | 0.102 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c one-step t4/sqrt2 | Power ST 5% | 0.64 | 0.648 | 0.0214 | 0.0987 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c one-step t4/sqrt2 | Power ST 1% | 0.54 | 0.522 | 0.0223 | 0.102 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c three-step Gamma | Power NST 5% |  0.7 | 0.692 | 0.0206 | 0.0955 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c three-step Gamma | Power NST 1% |  0.6 | 0.56 | 0.0222 | 0.101 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c three-step Gamma | Power ST 5% | 0.68 | 0.716 | 0.0202 | 0.0959 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c three-step Gamma | Power ST 1% | 0.57 | 0.608 | 0.0218 | 0.101 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c three-step t4/sqrt2 | Power NST 5% | 0.73 | 0.696 | 0.0206 | 0.0939 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c three-step t4/sqrt2 | Power NST 1% | 0.63 | 0.594 | 0.022 | 0.0998 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c three-step t4/sqrt2 | Power ST 5% | 0.72 | 0.708 | 0.0203 | 0.0941 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={15}+S0~c three-step t4/sqrt2 | Power ST 1% | 0.61 | 0.634 | 0.0215 | 0.0998 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c one-step Gamma | Power NST 5% | 0.82 | 0.926 | 0.0117 | 0.0778 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c one-step Gamma | Power NST 1% | 0.71 | 0.848 | 0.0161 | 0.0906 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c one-step Gamma | Power ST 5% | 0.82 | 0.956 | 0.00917 | 0.0761 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c one-step Gamma | Power ST 1% | 0.72 | 0.902 | 0.0133 | 0.088 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c one-step t4/sqrt2 | Power NST 5% | 0.86 | 0.936 | 0.0109 | 0.0724 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c one-step t4/sqrt2 | Power NST 1% | 0.76 | 0.848 | 0.0161 | 0.087 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c one-step t4/sqrt2 | Power ST 5% | 0.86 | 0.96 | 0.00876 | 0.0707 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c one-step t4/sqrt2 | Power ST 1% | 0.76 | 0.912 | 0.0127 | 0.0844 | **no** | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c three-step Gamma | Power NST 5% | 0.93 | 0.988 | 0.00487 | 0.056 | **no** | R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c three-step Gamma | Power NST 1% | 0.87 | 0.948 | 0.00993 | 0.0702 | **no** | R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c three-step Gamma | Power ST 5% | 0.92 | 0.99 | 0.00445 | 0.058 | **no** | R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c three-step Gamma | Power ST 1% | 0.85 | 0.958 | 0.00897 | 0.0722 | **no** | R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c three-step t4/sqrt2 | Power NST 5% | 0.93 | 0.966 | 0.0081 | 0.0584 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c three-step t4/sqrt2 | Power NST 1% | 0.86 | 0.92 | 0.0121 | 0.0734 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c three-step t4/sqrt2 | Power ST 5% | 0.92 | 0.972 | 0.00738 | 0.0598 | yes | R=500 vs paper R=1000 (reduced) |
| (i) G={14,15}+S0~c three-step t4/sqrt2 | Power ST 1% | 0.85 | 0.938 | 0.0108 | 0.0735 | **no** | R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c one-step Gamma | Power NST 5% |    1 |    1 |    0 | 0.0216 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c one-step Gamma | Power NST 1% |    1 |    1 |    0 | 0.0216 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c one-step Gamma | Power ST 5% |    1 |    1 |    0 | 0.0216 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c one-step Gamma | Power ST 1% |    1 |    1 |    0 | 0.0216 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c one-step t4/sqrt2 | Power NST 5% |    1 | 0.998 | 0.002 | 0.0242 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c one-step t4/sqrt2 | Power NST 1% |    1 | 0.998 | 0.002 | 0.0242 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c one-step t4/sqrt2 | Power ST 5% |    1 | 0.998 | 0.002 | 0.0242 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c one-step t4/sqrt2 | Power ST 1% |    1 | 0.998 | 0.002 | 0.0242 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c three-step Gamma | Power NST 5% |    1 | 0.994 | 0.00345 | 0.0273 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c three-step Gamma | Power NST 1% |    1 | 0.992 | 0.00398 | 0.0285 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c three-step Gamma | Power ST 5% |    1 | 0.994 | 0.00345 | 0.0273 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c three-step Gamma | Power ST 1% |    1 | 0.992 | 0.00398 | 0.0285 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c three-step t4/sqrt2 | Power NST 5% | 0.99 | 0.982 | 0.00595 | 0.0384 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c three-step t4/sqrt2 | Power NST 1% | 0.99 | 0.978 | 0.00656 | 0.0393 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c three-step t4/sqrt2 | Power ST 5% | 0.99 | 0.98 | 0.00626 | 0.0388 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={3}+S0c three-step t4/sqrt2 | Power ST 1% | 0.99 | 0.978 | 0.00656 | 0.0393 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c one-step Gamma | Power NST 5% |    1 |    1 |    0 | 0.0216 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c one-step Gamma | Power NST 1% |    1 |    1 |    0 | 0.0216 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c one-step Gamma | Power ST 5% |    1 |    1 |    0 | 0.0216 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c one-step Gamma | Power ST 1% |    1 |    1 |    0 | 0.0216 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c one-step t4/sqrt2 | Power NST 5% |    1 |    1 |    0 | 0.0216 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c one-step t4/sqrt2 | Power NST 1% |    1 |    1 |    0 | 0.0216 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c one-step t4/sqrt2 | Power ST 5% |    1 |    1 |    0 | 0.0216 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c one-step t4/sqrt2 | Power ST 1% |    1 |    1 |    0 | 0.0216 | yes | one-step via Sim.CI; R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c three-step Gamma | Power NST 5% |    1 |    1 |    0 | 0.0216 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c three-step Gamma | Power NST 1% |    1 |    1 |    0 | 0.0216 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c three-step Gamma | Power ST 5% |    1 |    1 |    0 | 0.0216 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c three-step Gamma | Power ST 1% |    1 |    1 |    0 | 0.0216 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c three-step t4/sqrt2 | Power NST 5% |    1 | 0.998 | 0.002 | 0.0242 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c three-step t4/sqrt2 | Power NST 1% |    1 | 0.998 | 0.002 | 0.0242 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c three-step t4/sqrt2 | Power ST 5% |    1 | 0.998 | 0.002 | 0.0242 | yes | R=500 vs paper R=1000 (reduced) |
| (ii) G={2,3}+S0c three-step t4/sqrt2 | Power ST 1% |    1 | 0.998 | 0.002 | 0.0242 | yes | R=500 vs paper R=1000 (reduced) |

### ZC Section 5.3 screening (2 of 4 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| (ii) s0=3 t4/sqrt2 | P(all 3 relevant variables kept), remedy | 0.98 | 0.964 | 0.00833 | 0.0458 | yes | SILM ST() screening; error law not stated in the paper; paper R assumed 1000 |
| (ii) s0=3 t4/sqrt2 | P(all 3 relevant variables kept), marginal | 0.59 | 0.946 | 0.0101 | 0.0947 | **no** | plain marginal screening, not a SILM method; error law not stated in the paper; paper R assumed 1000 |
| (ii) s0=3 Gamma | P(all 3 relevant variables kept), remedy | 0.98 | 0.978 | 0.00656 | 0.0434 | yes | SILM ST() screening; error law not stated in the paper; paper R assumed 1000 |
| (ii) s0=3 Gamma | P(all 3 relevant variables kept), marginal | 0.59 | 0.972 | 0.00738 | 0.094 | **no** | plain marginal screening, not a SILM method; error law not stated in the paper; paper R assumed 1000 |

### ZC Table 4 claims (6 of 7 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| (i) size rows, one-step, 5% | Mean empirical size (8 values) |  | 0.0205 |  |  | yes | 'one-step ... downward size distortion'; pass if < 0.05 (paper: 0.022) |
| (i) size rows, three-step, t errors, 5% | Max \|size - 0.05\| (4 values) |  | 0.018 |  |  | yes | 'reasonable size for t errors'; pass if <= 0.035 (paper: 0.010) |
| (i) size rows, three-step, Gamma errors, 5% | Mean empirical size (4 values) |  | 0.045 |  |  | **no** | 'slightly upward distorted for Gamma errors'; pass if > 0.05 (paper: 0.062) |
| (ii) size row, one-step, 5% | Mean empirical size (4 values) |  |  0.1 |  |  | yes | 'both procedures show upward size distortions'; pass if > 0.05 (paper: 0.083) |
| (ii) size row, three-step, 5% | Mean empirical size (4 values) |  | 0.0895 |  |  | yes | 'both procedures show upward size distortions'; pass if > 0.05 (paper: 0.100) |
| (i) power rows, 32 comparisons | Share with power(three-step) > power(one-step) |  |    1 |  |  | yes | pass if >= 0.75 (paper: 1.00) |
| (ii) power rows, 32 values | Min power |  | 0.978 |  |  | yes | 'close to 1 in case (ii)'; pass if >= 0.95 (paper: 0.99) |

### ZC Table 5 claims (3 of 4 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| 8 cells x {NST, ST, BH} | Max FWER (control at 5%) |  | 0.054 |  | 0.0207 | yes | pass if <= 0.071 (5% + 3 MC s.e.; paper max 0.048) |
| 8 cells | Max \|FWER(step-down) - FWER(Holm)\| |  | 0.011 |  |  | yes | 'similar control on the FWER'; pass if <= 0.03 (paper: 0.013) |
| 8 cells | Cells with Power(ST step-down) >= Power(Holm) |  |    8 |  |  | yes | 'slightly higher average power across all cases'; pass if 8 of 8 (paper: 8) |
| 8 cells | Cells with Power(NST step-down) >= Power(Holm) |  |    5 |  |  | **no** | 'across all cases'; pass if >= 7 of 8, NST not nested in Holm (paper: 8) |

## Tagged targets (not in the headline count)

See CRITERIA.md for the meaning of each tag.

### ZC Table 1 (Sim.CI, s0=3) [draw-dependent] (32 of 32 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| p=120 (i) Gamma G=S0 | Cov NST 95% | 0.84 | 0.849 | 0.0113 |  | yes | range rule: pass if paper in [0.642, 0.974] = 5 fixed beta draws (0.750-0.870; draw 1 R=1000, others R=200) and per-run redraw (0.805), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.069) |
| p=120 (i) Gamma G=S0 | Cov NST 99% | 0.93 | 0.94 | 0.00751 |  | yes | range rule: pass if paper in [0.808, 1.019] = 5 fixed beta draws (0.895-0.940; draw 1 R=1000, others R=200) and per-run redraw (0.890), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.053) |
| p=120 (i) Gamma G=S0 | Cov ST 95% | 0.82 | 0.841 | 0.0116 |  | yes | range rule: pass if paper in [0.633, 0.982] = 5 fixed beta draws (0.745-0.875; draw 1 R=1000, others R=200) and per-run redraw (0.810), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.070) |
| p=120 (i) Gamma G=S0 | Cov ST 99% | 0.92 | 0.941 | 0.00745 |  | yes | range rule: pass if paper in [0.795, 1.012] = 5 fixed beta draws (0.885-0.941; draw 1 R=1000, others R=200) and per-run redraw (0.880), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.054) |
| p=120 (ii) Gamma G=S0 | Cov NST 95% | 0.91 | 0.902 | 0.0094 |  | yes | range rule: pass if paper in [0.781, 1.006] = 5 fixed beta draws (0.870-0.920; draw 1 R=1000, others R=200) and per-run redraw (0.880), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.059) |
| p=120 (ii) Gamma G=S0 | Cov NST 99% | 0.97 | 0.964 | 0.00589 |  | yes | range rule: pass if paper in [0.877, 1.030] = 5 fixed beta draws (0.940-0.970; draw 1 R=1000, others R=200) and per-run redraw (0.955), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.044) |
| p=120 (ii) Gamma G=S0 | Cov ST 95% |  0.9 | 0.902 | 0.0094 |  | yes | range rule: pass if paper in [0.774, 1.009] = 5 fixed beta draws (0.865-0.920; draw 1 R=1000, others R=200) and per-run redraw (0.880), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.060) |
| p=120 (ii) Gamma G=S0 | Cov ST 99% | 0.97 | 0.969 | 0.00548 |  | yes | range rule: pass if paper in [0.877, 1.034] = 5 fixed beta draws (0.940-0.975; draw 1 R=1000, others R=200) and per-run redraw (0.955), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.043) |
| p=120 (i) t4/sqrt2 G=S0 | Cov NST 95% | 0.82 | 0.849 | 0.0113 |  | yes | range rule: pass if paper in [0.639, 0.982] = 5 fixed beta draws (0.750-0.875; draw 1 R=1000, others R=200) and per-run redraw (0.815), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.070) |
| p=120 (i) t4/sqrt2 G=S0 | Cov NST 99% | 0.94 | 0.946 | 0.00715 |  | yes | range rule: pass if paper in [0.779, 1.020] = 5 fixed beta draws (0.860-0.946; draw 1 R=1000, others R=200) and per-run redraw (0.910), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.051) |
| p=120 (i) t4/sqrt2 G=S0 | Cov ST 95% | 0.82 | 0.844 | 0.0115 |  | yes | range rule: pass if paper in [0.649, 0.963] = 5 fixed beta draws (0.760-0.855; draw 1 R=1000, others R=200) and per-run redraw (0.840), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.070) |
| p=120 (i) t4/sqrt2 G=S0 | Cov ST 99% | 0.93 | 0.945 | 0.00721 |  | yes | range rule: pass if paper in [0.782, 1.019] = 5 fixed beta draws (0.865-0.945; draw 1 R=1000, others R=200) and per-run redraw (0.925), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.052) |
| p=120 (ii) t4/sqrt2 G=S0 | Cov NST 95% | 0.91 | 0.91 | 0.00905 |  | yes | range rule: pass if paper in [0.766, 1.025] = 5 fixed beta draws (0.855-0.940; draw 1 R=1000, others R=200) and per-run redraw (0.910), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.058) |
| p=120 (ii) t4/sqrt2 G=S0 | Cov NST 99% | 0.97 | 0.973 | 0.00513 |  | yes | range rule: pass if paper in [0.894, 1.052] = 5 fixed beta draws (0.955-0.995; draw 1 R=1000, others R=200) and per-run redraw (0.970), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.042) |
| p=120 (ii) t4/sqrt2 G=S0 | Cov ST 95% | 0.92 | 0.914 | 0.00887 |  | yes | range rule: pass if paper in [0.763, 1.017] = 5 fixed beta draws (0.850-0.935; draw 1 R=1000, others R=200) and per-run redraw (0.905), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.057) |
| p=120 (ii) t4/sqrt2 G=S0 | Cov ST 99% | 0.97 | 0.975 | 0.00494 |  | yes | range rule: pass if paper in [0.894, 1.052] = 5 fixed beta draws (0.955-0.995; draw 1 R=1000, others R=200) and per-run redraw (0.965), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.042) |
| p=500 (i) Gamma G=S0 | Cov NST 95% | 0.77 | 0.703 | 0.0144 |  | yes | range rule: pass if paper in [0.555, 0.922] = 5 fixed beta draws (0.675-0.755; draw 1 R=1000, others R=200) and per-run redraw (0.805), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.079) |
| p=500 (i) Gamma G=S0 | Cov NST 99% |  0.9 | 0.843 | 0.0115 |  | yes | range rule: pass if paper in [0.726, 0.999] = 5 fixed beta draws (0.820-0.885; draw 1 R=1000, others R=200) and per-run redraw (0.910), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.065) |
| p=500 (i) Gamma G=S0 | Cov ST 95% | 0.77 | 0.71 | 0.0143 |  | yes | range rule: pass if paper in [0.560, 0.922] = 5 fixed beta draws (0.680-0.775; draw 1 R=1000, others R=200) and per-run redraw (0.805), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.079) |
| p=500 (i) Gamma G=S0 | Cov ST 99% |  0.9 | 0.853 | 0.0112 |  | yes | range rule: pass if paper in [0.726, 1.004] = 5 fixed beta draws (0.820-0.890; draw 1 R=1000, others R=200) and per-run redraw (0.915), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.064) |
| p=500 (ii) Gamma G=S0 | Cov NST 95% | 0.91 | 0.884 | 0.0101 |  | yes | range rule: pass if paper in [0.608, 0.949] = 5 fixed beta draws (0.705-0.884; draw 1 R=1000, others R=200) and per-run redraw (0.820), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.061) |
| p=500 (ii) Gamma G=S0 | Cov NST 99% | 0.97 | 0.967 | 0.00565 |  | yes | range rule: pass if paper in [0.796, 1.010] = 5 fixed beta draws (0.865-0.967; draw 1 R=1000, others R=200) and per-run redraw (0.915), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.043) |
| p=500 (ii) Gamma G=S0 | Cov ST 95% |  0.9 | 0.889 | 0.00993 |  | yes | range rule: pass if paper in [0.622, 0.956] = 5 fixed beta draws (0.720-0.889; draw 1 R=1000, others R=200) and per-run redraw (0.810), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.061) |
| p=500 (ii) Gamma G=S0 | Cov ST 99% | 0.97 | 0.97 | 0.00539 |  | yes | range rule: pass if paper in [0.812, 1.013] = 5 fixed beta draws (0.880-0.970; draw 1 R=1000, others R=200) and per-run redraw (0.910), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.043) |
| p=500 (i) t4/sqrt2 G=S0 | Cov NST 95% | 0.76 | 0.739 | 0.0139 |  | yes | range rule: pass if paper in [0.564, 0.894] = 5 fixed beta draws (0.685-0.775; draw 1 R=1000, others R=200) and per-run redraw (0.755), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.078) |
| p=500 (i) t4/sqrt2 G=S0 | Cov NST 99% |  0.9 | 0.864 | 0.0108 |  | yes | range rule: pass if paper in [0.732, 0.975] = 5 fixed beta draws (0.825-0.885; draw 1 R=1000, others R=200) and per-run redraw (0.855), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.063) |
| p=500 (i) t4/sqrt2 G=S0 | Cov ST 95% | 0.77 | 0.738 | 0.0139 |  | yes | range rule: pass if paper in [0.565, 0.902] = 5 fixed beta draws (0.685-0.785; draw 1 R=1000, others R=200) and per-run redraw (0.755), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.078) |
| p=500 (i) t4/sqrt2 G=S0 | Cov ST 99% |  0.9 | 0.868 | 0.0107 |  | yes | range rule: pass if paper in [0.721, 0.975] = 5 fixed beta draws (0.815-0.885; draw 1 R=1000, others R=200) and per-run redraw (0.845), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.063) |
| p=500 (ii) t4/sqrt2 G=S0 | Cov NST 95% | 0.92 | 0.893 | 0.00978 |  | yes | range rule: pass if paper in [0.569, 0.952] = 5 fixed beta draws (0.665-0.893; draw 1 R=1000, others R=200) and per-run redraw (0.790), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.059) |
| p=500 (ii) t4/sqrt2 G=S0 | Cov NST 99% | 0.98 | 0.966 | 0.00573 |  | yes | range rule: pass if paper in [0.816, 1.008] = 5 fixed beta draws (0.880-0.966; draw 1 R=1000, others R=200) and per-run redraw (0.890), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.042) |
| p=500 (ii) t4/sqrt2 G=S0 | Cov ST 95% | 0.92 | 0.898 | 0.00957 |  | yes | range rule: pass if paper in [0.611, 0.957] = 5 fixed beta draws (0.705-0.898; draw 1 R=1000, others R=200) and per-run redraw (0.800), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.059) |
| p=500 (ii) t4/sqrt2 G=S0 | Cov ST 99% | 0.97 | 0.968 | 0.00557 |  | yes | range rule: pass if paper in [0.812, 1.011] = 5 fixed beta draws (0.880-0.968; draw 1 R=1000, others R=200) and per-run redraw (0.900), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.043) |

### ZC Table 2 (Sim.CI, s0=15) [draw-dependent] (87 of 96 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| p=120 (i) Gamma G=[p] | Cov EX 95% | 0.77 | 0.76 | 0.0135 |  | yes | range rule: pass if paper in [0.581, 0.888] = 5 fixed beta draws (0.700-0.770; draw 1 R=1000, others R=200) and per-run redraw (0.725), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.077) |
| p=120 (i) Gamma G=[p] | Cov EX 99% | 0.88 | 0.873 | 0.0105 |  | yes | range rule: pass if paper in [0.732, 0.971] = 5 fixed beta draws (0.845-0.875; draw 1 R=1000, others R=200) and per-run redraw (0.830), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.064) |
| p=120 (i) Gamma G=[p] | Cov ST 95% | 0.74 | 0.735 | 0.014 |  | yes | range rule: pass if paper in [0.557, 0.862] = 5 fixed beta draws (0.680-0.740; draw 1 R=1000, others R=200) and per-run redraw (0.715), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.079) |
| p=120 (i) Gamma G=[p] | Cov ST 99% | 0.86 | 0.847 | 0.0114 |  | yes | range rule: pass if paper in [0.702, 0.951] = 5 fixed beta draws (0.820-0.850; draw 1 R=1000, others R=200) and per-run redraw (0.805), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.067) |
| p=120 (i) Gamma G=S0 | Cov NST 95% | 0.69 | 0.478 | 0.0158 |  | **no** | range rule: pass if paper in [0.233, 0.680] = 5 fixed beta draws (0.365-0.550; draw 1 R=1000, others R=200) and per-run redraw (0.460), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| p=120 (i) Gamma G=S0 | Cov NST 99% | 0.88 | 0.676 | 0.0148 |  | **no** | range rule: pass if paper in [0.509, 0.808] = 5 fixed beta draws (0.615-0.705; draw 1 R=1000, others R=200) and per-run redraw (0.645), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.076) |
| p=120 (i) Gamma G=S0 | Cov ST 95% | 0.52 | 0.483 | 0.0158 |  | yes | range rule: pass if paper in [0.249, 0.676] = 5 fixed beta draws (0.385-0.540; draw 1 R=1000, others R=200) and per-run redraw (0.465), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.087) |
| p=120 (i) Gamma G=S0 | Cov ST 99% |  0.7 | 0.687 | 0.0147 |  | yes | range rule: pass if paper in [0.487, 0.836] = 5 fixed beta draws (0.615-0.710; draw 1 R=1000, others R=200) and per-run redraw (0.655), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.082) |
| p=120 (i) Gamma G=S0c | Cov EX 95% | 0.99 | 0.992 | 0.00282 |  | yes | range rule: pass if paper in [0.935, 1.041] = 5 fixed beta draws (0.980-0.992; draw 1 R=1000, others R=200) and per-run redraw (1.000), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.033) |
| p=120 (i) Gamma G=S0c | Cov EX 99% |    1 | 0.997 | 0.00173 |  | yes | range rule: pass if paper in [0.968, 1.022] = 5 fixed beta draws (0.995-1.000; draw 1 R=1000, others R=200) and per-run redraw (1.000), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.025) |
| p=120 (i) Gamma G=S0c | Cov ST 95% | 0.99 | 0.986 | 0.00372 |  | yes | range rule: pass if paper in [0.935, 1.037] = 5 fixed beta draws (0.980-0.990; draw 1 R=1000, others R=200) and per-run redraw (0.995), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.035) |
| p=120 (i) Gamma G=S0c | Cov ST 99% |    1 | 0.997 | 0.00173 |  | yes | range rule: pass if paper in [0.968, 1.022] = 5 fixed beta draws (0.995-1.000; draw 1 R=1000, others R=200) and per-run redraw (1.000), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.025) |
| p=120 (ii) Gamma G=[p] | Cov EX 95% | 0.81 | 0.647 | 0.0151 |  | yes | range rule: pass if paper in [0.350, 0.887] = 5 fixed beta draws (0.470-0.775; draw 1 R=1000, others R=200) and per-run redraw (0.660), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.080) |
| p=120 (ii) Gamma G=[p] | Cov EX 99% | 0.94 | 0.826 | 0.012 |  | yes | range rule: pass if paper in [0.589, 0.973] = 5 fixed beta draws (0.680-0.895; draw 1 R=1000, others R=200) and per-run redraw (0.840), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.063) |
| p=120 (ii) Gamma G=[p] | Cov ST 95% | 0.78 | 0.616 | 0.0154 |  | yes | range rule: pass if paper in [0.316, 0.843] = 5 fixed beta draws (0.440-0.725; draw 1 R=1000, others R=200) and per-run redraw (0.620), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.082) |
| p=120 (ii) Gamma G=[p] | Cov ST 99% | 0.91 | 0.802 | 0.0126 |  | yes | range rule: pass if paper in [0.530, 0.954] = 5 fixed beta draws (0.630-0.865; draw 1 R=1000, others R=200) and per-run redraw (0.800), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.067) |
| p=120 (ii) Gamma G=S0 | Cov NST 95% | 0.77 | 0.511 | 0.0158 |  | yes | range rule: pass if paper in [0.244, 0.849] = 5 fixed beta draws (0.370-0.730; draw 1 R=1000, others R=200) and per-run redraw (0.565), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.084) |
| p=120 (ii) Gamma G=S0 | Cov NST 99% |  0.9 | 0.733 | 0.014 |  | yes | range rule: pass if paper in [0.492, 0.990] = 5 fixed beta draws (0.595-0.900; draw 1 R=1000, others R=200) and per-run redraw (0.765), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.072) |
| p=120 (ii) Gamma G=S0 | Cov ST 95% | 0.71 | 0.554 | 0.0157 |  | yes | range rule: pass if paper in [0.265, 0.845] = 5 fixed beta draws (0.395-0.720; draw 1 R=1000, others R=200) and per-run redraw (0.565), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |
| p=120 (ii) Gamma G=S0 | Cov ST 99% | 0.87 | 0.765 | 0.0134 |  | yes | range rule: pass if paper in [0.481, 0.978] = 5 fixed beta draws (0.590-0.880; draw 1 R=1000, others R=200) and per-run redraw (0.760), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.072) |
| p=120 (ii) Gamma G=S0c | Cov EX 95% | 0.87 | 0.722 | 0.0142 |  | yes | range rule: pass if paper in [0.518, 0.911] = 5 fixed beta draws (0.625-0.810; draw 1 R=1000, others R=200) and per-run redraw (0.770), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.074) |
| p=120 (ii) Gamma G=S0c | Cov EX 99% | 0.96 | 0.882 | 0.0102 |  | yes | range rule: pass if paper in [0.711, 0.989] = 5 fixed beta draws (0.790-0.910; draw 1 R=1000, others R=200) and per-run redraw (0.920), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.056) |
| p=120 (ii) Gamma G=S0c | Cov ST 95% | 0.85 | 0.69 | 0.0146 |  | yes | range rule: pass if paper in [0.489, 0.871] = 5 fixed beta draws (0.600-0.765; draw 1 R=1000, others R=200) and per-run redraw (0.720), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.076) |
| p=120 (ii) Gamma G=S0c | Cov ST 99% | 0.94 | 0.856 | 0.0111 |  | yes | range rule: pass if paper in [0.647, 0.978] = 5 fixed beta draws (0.735-0.900; draw 1 R=1000, others R=200) and per-run redraw (0.900), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.061) |
| p=120 (i) t4/sqrt2 G=[p] | Cov EX 95% | 0.77 | 0.765 | 0.0134 |  | yes | range rule: pass if paper in [0.606, 0.907] = 5 fixed beta draws (0.725-0.790; draw 1 R=1000, others R=200) and per-run redraw (0.785), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.077) |
| p=120 (i) t4/sqrt2 G=[p] | Cov EX 99% | 0.88 | 0.867 | 0.0107 |  | yes | range rule: pass if paper in [0.743, 0.985] = 5 fixed beta draws (0.840-0.890; draw 1 R=1000, others R=200) and per-run redraw (0.870), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.065) |
| p=120 (i) t4/sqrt2 G=[p] | Cov ST 95% | 0.75 | 0.742 | 0.0138 |  | yes | range rule: pass if paper in [0.583, 0.876] = 5 fixed beta draws (0.705-0.755; draw 1 R=1000, others R=200) and per-run redraw (0.735), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.078) |
| p=120 (i) t4/sqrt2 G=[p] | Cov ST 99% | 0.85 | 0.852 | 0.0112 |  | yes | range rule: pass if paper in [0.721, 0.967] = 5 fixed beta draws (0.825-0.865; draw 1 R=1000, others R=200) and per-run redraw (0.850), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.068) |
| p=120 (i) t4/sqrt2 G=S0 | Cov NST 95% | 0.68 | 0.511 | 0.0158 |  | **no** | range rule: pass if paper in [0.278, 0.626] = 5 fixed beta draws (0.410-0.511; draw 1 R=1000, others R=200) and per-run redraw (0.495), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| p=120 (i) t4/sqrt2 G=S0 | Cov NST 99% | 0.87 | 0.698 | 0.0145 |  | **no** | range rule: pass if paper in [0.549, 0.795] = 5 fixed beta draws (0.655-0.698; draw 1 R=1000, others R=200) and per-run redraw (0.690), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.075) |
| p=120 (i) t4/sqrt2 G=S0 | Cov ST 95% |  0.5 | 0.519 | 0.0158 |  | yes | range rule: pass if paper in [0.254, 0.651] = 5 fixed beta draws (0.390-0.519; draw 1 R=1000, others R=200) and per-run redraw (0.515), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.087) |
| p=120 (i) t4/sqrt2 G=S0 | Cov ST 99% |  0.7 |  0.7 | 0.0145 |  | yes | range rule: pass if paper in [0.523, 0.831] = 5 fixed beta draws (0.650-0.705; draw 1 R=1000, others R=200) and per-run redraw (0.700), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.081) |
| p=120 (i) t4/sqrt2 G=S0c | Cov EX 95% | 0.99 | 0.994 | 0.00244 |  | yes | range rule: pass if paper in [0.935, 1.037] = 5 fixed beta draws (0.980-0.995; draw 1 R=1000, others R=200) and per-run redraw (0.995), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.032) |
| p=120 (i) t4/sqrt2 G=S0c | Cov EX 99% |    1 | 0.998 | 0.00141 |  | yes | range rule: pass if paper in [0.968, 1.022] = 5 fixed beta draws (0.995-1.000; draw 1 R=1000, others R=200) and per-run redraw (0.995), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.024) |
| p=120 (i) t4/sqrt2 G=S0c | Cov ST 95% | 0.99 | 0.99 | 0.00315 |  | yes | range rule: pass if paper in [0.918, 1.033] = 5 fixed beta draws (0.965-0.990; draw 1 R=1000, others R=200) and per-run redraw (0.990), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.033) |
| p=120 (i) t4/sqrt2 G=S0c | Cov ST 99% |    1 | 0.998 | 0.00141 |  | yes | range rule: pass if paper in [0.968, 1.022] = 5 fixed beta draws (0.995-1.000; draw 1 R=1000, others R=200) and per-run redraw (0.995), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.024) |
| p=120 (ii) t4/sqrt2 G=[p] | Cov EX 95% | 0.77 | 0.65 | 0.0151 |  | yes | range rule: pass if paper in [0.335, 0.863] = 5 fixed beta draws (0.460-0.745; draw 1 R=1000, others R=200) and per-run redraw (0.645), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.081) |
| p=120 (ii) t4/sqrt2 G=[p] | Cov EX 99% | 0.92 | 0.843 | 0.0115 |  | yes | range rule: pass if paper in [0.632, 0.975] = 5 fixed beta draws (0.725-0.890; draw 1 R=1000, others R=200) and per-run redraw (0.820), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.063) |
| p=120 (ii) t4/sqrt2 G=[p] | Cov ST 95% | 0.74 | 0.608 | 0.0154 |  | yes | range rule: pass if paper in [0.282, 0.828] = 5 fixed beta draws (0.410-0.705; draw 1 R=1000, others R=200) and per-run redraw (0.630), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.083) |
| p=120 (ii) t4/sqrt2 G=[p] | Cov ST 99% | 0.88 | 0.812 | 0.0124 |  | yes | range rule: pass if paper in [0.556, 0.952] = 5 fixed beta draws (0.660-0.855; draw 1 R=1000, others R=200) and per-run redraw (0.800), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.068) |
| p=120 (ii) t4/sqrt2 G=S0 | Cov NST 95% | 0.73 | 0.555 | 0.0157 |  | yes | range rule: pass if paper in [0.246, 0.897] = 5 fixed beta draws (0.375-0.775; draw 1 R=1000, others R=200) and per-run redraw (0.625), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.084) |
| p=120 (ii) t4/sqrt2 G=S0 | Cov NST 99% | 0.88 | 0.752 | 0.0137 |  | yes | range rule: pass if paper in [0.499, 0.995] = 5 fixed beta draws (0.605-0.900; draw 1 R=1000, others R=200) and per-run redraw (0.805), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.072) |
| p=120 (ii) t4/sqrt2 G=S0 | Cov ST 95% | 0.68 | 0.579 | 0.0156 |  | yes | range rule: pass if paper in [0.268, 0.887] = 5 fixed beta draws (0.400-0.760; draw 1 R=1000, others R=200) and per-run redraw (0.640), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |
| p=120 (ii) t4/sqrt2 G=S0 | Cov ST 99% | 0.84 | 0.79 | 0.0129 |  | yes | range rule: pass if paper in [0.492, 0.993] = 5 fixed beta draws (0.605-0.890; draw 1 R=1000, others R=200) and per-run redraw (0.795), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.072) |
| p=120 (ii) t4/sqrt2 G=S0c | Cov EX 95% | 0.85 | 0.717 | 0.0142 |  | yes | range rule: pass if paper in [0.509, 0.876] = 5 fixed beta draws (0.620-0.770; draw 1 R=1000, others R=200) and per-run redraw (0.735), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.075) |
| p=120 (ii) t4/sqrt2 G=S0c | Cov EX 99% | 0.94 | 0.883 | 0.0102 |  | yes | range rule: pass if paper in [0.742, 0.973] = 5 fixed beta draws (0.825-0.895; draw 1 R=1000, others R=200) and per-run redraw (0.850), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.058) |
| p=120 (ii) t4/sqrt2 G=S0c | Cov ST 95% | 0.83 | 0.673 | 0.0148 |  | **no** | range rule: pass if paper in [0.496, 0.826] = 5 fixed beta draws (0.610-0.715; draw 1 R=1000, others R=200) and per-run redraw (0.705), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.078) |
| p=120 (ii) t4/sqrt2 G=S0c | Cov ST 99% | 0.92 | 0.842 | 0.0115 |  | yes | range rule: pass if paper in [0.700, 0.961] = 5 fixed beta draws (0.790-0.875; draw 1 R=1000, others R=200) and per-run redraw (0.840), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.063) |
| p=500 (i) Gamma G=[p] | Cov EX 95% | 0.76 | 0.664 | 0.0149 |  | yes | range rule: pass if paper in [0.523, 0.884] = 5 fixed beta draws (0.645-0.720; draw 1 R=1000, others R=200) and per-run redraw (0.765), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.081) |
| p=500 (i) Gamma G=[p] | Cov EX 99% | 0.87 | 0.785 | 0.013 |  | yes | range rule: pass if paper in [0.657, 0.978] = 5 fixed beta draws (0.760-0.880; draw 1 R=1000, others R=200) and per-run redraw (0.835), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.071) |
| p=500 (i) Gamma G=[p] | Cov ST 95% | 0.74 | 0.646 | 0.0151 |  | yes | range rule: pass if paper in [0.516, 0.862] = 5 fixed beta draws (0.640-0.705; draw 1 R=1000, others R=200) and per-run redraw (0.740), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.082) |
| p=500 (i) Gamma G=[p] | Cov ST 99% | 0.85 | 0.757 | 0.0136 |  | yes | range rule: pass if paper in [0.618, 0.939] = 5 fixed beta draws (0.725-0.835; draw 1 R=1000, others R=200) and per-run redraw (0.815), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.073) |
| p=500 (i) Gamma G=S0 | Cov NST 95% | 0.52 | 0.26 | 0.0139 |  | **no** | range rule: pass if paper in [0.099, 0.461] = 5 fixed beta draws (0.235-0.325; draw 1 R=1000, others R=200) and per-run redraw (0.310), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |
| p=500 (i) Gamma G=S0 | Cov NST 99% |  0.8 | 0.457 | 0.0158 |  | **no** | range rule: pass if paper in [0.338, 0.665] = 5 fixed beta draws (0.457-0.545; draw 1 R=1000, others R=200) and per-run redraw (0.510), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |
| p=500 (i) Gamma G=S0 | Cov ST 95% | 0.32 | 0.257 | 0.0138 |  | yes | range rule: pass if paper in [0.098, 0.448] = 5 fixed beta draws (0.225-0.320; draw 1 R=1000, others R=200) and per-run redraw (0.275), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.081) |
| p=500 (i) Gamma G=S0 | Cov ST 99% | 0.52 | 0.449 | 0.0157 |  | yes | range rule: pass if paper in [0.304, 0.681] = 5 fixed beta draws (0.440-0.545; draw 1 R=1000, others R=200) and per-run redraw (0.505), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.087) |
| p=500 (i) Gamma G=S0c | Cov EX 95% | 0.99 | 0.995 | 0.00223 |  | yes | range rule: pass if paper in [0.941, 1.041] = 5 fixed beta draws (0.985-1.000; draw 1 R=1000, others R=200) and per-run redraw (0.990), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.032) |
| p=500 (i) Gamma G=S0c | Cov EX 99% |    1 | 0.998 | 0.00141 |  | yes | range rule: pass if paper in [0.961, 1.022] = 5 fixed beta draws (0.990-1.000; draw 1 R=1000, others R=200) and per-run redraw (1.000), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.024) |
| p=500 (i) Gamma G=S0c | Cov ST 95% | 0.99 | 0.992 | 0.00282 |  | yes | range rule: pass if paper in [0.941, 1.037] = 5 fixed beta draws (0.985-0.995; draw 1 R=1000, others R=200) and per-run redraw (0.990), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.033) |
| p=500 (i) Gamma G=S0c | Cov ST 99% |    1 | 0.997 | 0.00173 |  | yes | range rule: pass if paper in [0.961, 1.022] = 5 fixed beta draws (0.990-1.000; draw 1 R=1000, others R=200) and per-run redraw (1.000), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.025) |
| p=500 (ii) Gamma G=[p] | Cov EX 95% |  0.5 | 0.684 | 0.0147 |  | yes | range rule: pass if paper in [0.499, 0.836] = 5 fixed beta draws (0.635-0.700; draw 1 R=1000, others R=200) and per-run redraw (0.675), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| p=500 (ii) Gamma G=[p] | Cov EX 99% | 0.69 | 0.852 | 0.0112 |  | yes | range rule: pass if paper in [0.639, 1.004] = 5 fixed beta draws (0.765-0.880; draw 1 R=1000, others R=200) and per-run redraw (0.810), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.076) |
| p=500 (ii) Gamma G=[p] | Cov ST 95% | 0.47 | 0.66 | 0.015 |  | yes | range rule: pass if paper in [0.464, 0.831] = 5 fixed beta draws (0.600-0.695; draw 1 R=1000, others R=200) and per-run redraw (0.640), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.087) |
| p=500 (ii) Gamma G=[p] | Cov ST 99% | 0.66 | 0.824 | 0.012 |  | yes | range rule: pass if paper in [0.626, 0.972] = 5 fixed beta draws (0.755-0.845; draw 1 R=1000, others R=200) and per-run redraw (0.785), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.079) |
| p=500 (ii) Gamma G=S0 | Cov NST 95% | 0.38 | 0.482 | 0.0158 |  | yes | range rule: pass if paper in [0.282, 0.755] = 5 fixed beta draws (0.415-0.620; draw 1 R=1000, others R=200) and per-run redraw (0.435), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| p=500 (ii) Gamma G=S0 | Cov NST 99% | 0.57 | 0.696 | 0.0145 |  | yes | range rule: pass if paper in [0.490, 0.914] = 5 fixed beta draws (0.625-0.780; draw 1 R=1000, others R=200) and per-run redraw (0.655), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |
| p=500 (ii) Gamma G=S0 | Cov ST 95% | 0.34 | 0.469 | 0.0158 |  | yes | range rule: pass if paper in [0.230, 0.763] = 5 fixed beta draws (0.360-0.630; draw 1 R=1000, others R=200) and per-run redraw (0.420), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| p=500 (ii) Gamma G=S0 | Cov ST 99% | 0.53 | 0.668 | 0.0149 |  | yes | range rule: pass if paper in [0.459, 0.905] = 5 fixed beta draws (0.595-0.770; draw 1 R=1000, others R=200) and per-run redraw (0.615), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| p=500 (ii) Gamma G=S0c | Cov EX 95% | 0.64 | 0.781 | 0.0131 |  | yes | range rule: pass if paper in [0.579, 0.900] = 5 fixed beta draws (0.710-0.781; draw 1 R=1000, others R=200) and per-run redraw (0.770), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.081) |
| p=500 (ii) Gamma G=S0c | Cov EX 99% |  0.8 | 0.909 | 0.00909 |  | yes | range rule: pass if paper in [0.744, 1.020] = 5 fixed beta draws (0.855-0.910; draw 1 R=1000, others R=200) and per-run redraw (0.885), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.067) |
| p=500 (ii) Gamma G=S0c | Cov ST 95% |  0.6 | 0.764 | 0.0134 |  | yes | range rule: pass if paper in [0.542, 0.887] = 5 fixed beta draws (0.675-0.764; draw 1 R=1000, others R=200) and per-run redraw (0.755), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.082) |
| p=500 (ii) Gamma G=S0c | Cov ST 99% | 0.77 | 0.886 | 0.0101 |  | yes | range rule: pass if paper in [0.698, 0.980] = 5 fixed beta draws (0.815-0.886; draw 1 R=1000, others R=200) and per-run redraw (0.855), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.071) |
| p=500 (i) t4/sqrt2 G=[p] | Cov EX 95% | 0.78 | 0.679 | 0.0148 |  | yes | range rule: pass if paper in [0.510, 0.848] = 5 fixed beta draws (0.630-0.730; draw 1 R=1000, others R=200) and per-run redraw (0.710), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.080) |
| p=500 (i) t4/sqrt2 G=[p] | Cov EX 99% | 0.87 | 0.792 | 0.0128 |  | yes | range rule: pass if paper in [0.663, 0.944] = 5 fixed beta draws (0.765-0.845; draw 1 R=1000, others R=200) and per-run redraw (0.810), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.070) |
| p=500 (i) t4/sqrt2 G=[p] | Cov ST 95% | 0.76 | 0.659 | 0.015 |  | yes | range rule: pass if paper in [0.482, 0.840] = 5 fixed beta draws (0.605-0.720; draw 1 R=1000, others R=200) and per-run redraw (0.685), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.081) |
| p=500 (i) t4/sqrt2 G=[p] | Cov ST 99% | 0.86 | 0.77 | 0.0133 |  | yes | range rule: pass if paper in [0.635, 0.927] = 5 fixed beta draws (0.740-0.825; draw 1 R=1000, others R=200) and per-run redraw (0.790), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.072) |
| p=500 (i) t4/sqrt2 G=S0 | Cov NST 95% | 0.56 | 0.251 | 0.0137 |  | **no** | range rule: pass if paper in [0.084, 0.471] = 5 fixed beta draws (0.220-0.285; draw 1 R=1000, others R=200) and per-run redraw (0.335), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| p=500 (i) t4/sqrt2 G=S0 | Cov NST 99% | 0.82 | 0.466 | 0.0158 |  | **no** | range rule: pass if paper in [0.310, 0.648] = 5 fixed beta draws (0.430-0.530; draw 1 R=1000, others R=200) and per-run redraw (0.515), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.084) |
| p=500 (i) t4/sqrt2 G=S0 | Cov ST 95% | 0.34 | 0.252 | 0.0137 |  | yes | range rule: pass if paper in [0.082, 0.450] = 5 fixed beta draws (0.210-0.295; draw 1 R=1000, others R=200) and per-run redraw (0.320), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.081) |
| p=500 (i) t4/sqrt2 G=S0 | Cov ST 99% | 0.57 | 0.467 | 0.0158 |  | yes | range rule: pass if paper in [0.264, 0.665] = 5 fixed beta draws (0.400-0.530; draw 1 R=1000, others R=200) and per-run redraw (0.510), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.087) |
| p=500 (i) t4/sqrt2 G=S0c | Cov EX 95% | 0.99 | 0.995 | 0.00223 |  | yes | range rule: pass if paper in [0.947, 1.037] = 5 fixed beta draws (0.990-0.995; draw 1 R=1000, others R=200) and per-run redraw (0.990), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.032) |
| p=500 (i) t4/sqrt2 G=S0c | Cov EX 99% |    1 | 0.999 | 0.000999 |  | yes | range rule: pass if paper in [0.968, 1.022] = 5 fixed beta draws (0.999-1.000; draw 1 R=1000, others R=200) and per-run redraw (0.995), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.023) |
| p=500 (i) t4/sqrt2 G=S0c | Cov ST 95% | 0.99 | 0.992 | 0.00282 |  | yes | range rule: pass if paper in [0.941, 1.037] = 5 fixed beta draws (0.985-0.995; draw 1 R=1000, others R=200) and per-run redraw (0.985), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.033) |
| p=500 (i) t4/sqrt2 G=S0c | Cov ST 99% |    1 | 0.998 | 0.00141 |  | yes | range rule: pass if paper in [0.968, 1.022] = 5 fixed beta draws (0.995-1.000; draw 1 R=1000, others R=200) and per-run redraw (0.995), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.024) |
| p=500 (ii) t4/sqrt2 G=[p] | Cov EX 95% | 0.53 | 0.705 | 0.0144 |  | yes | range rule: pass if paper in [0.424, 0.900] = 5 fixed beta draws (0.605-0.765; draw 1 R=1000, others R=200) and per-run redraw (0.560), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |
| p=500 (ii) t4/sqrt2 G=[p] | Cov EX 99% |  0.7 | 0.847 | 0.0114 |  | yes | range rule: pass if paper in [0.604, 1.003] = 5 fixed beta draws (0.765-0.880; draw 1 R=1000, others R=200) and per-run redraw (0.730), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.076) |
| p=500 (ii) t4/sqrt2 G=[p] | Cov ST 95% | 0.49 | 0.679 | 0.0148 |  | yes | range rule: pass if paper in [0.384, 0.866] = 5 fixed beta draws (0.550-0.730; draw 1 R=1000, others R=200) and per-run redraw (0.520), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| p=500 (ii) t4/sqrt2 G=[p] | Cov ST 99% | 0.66 | 0.831 | 0.0119 |  | yes | range rule: pass if paper in [0.586, 0.977] = 5 fixed beta draws (0.755-0.850; draw 1 R=1000, others R=200) and per-run redraw (0.715), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.078) |
| p=500 (ii) t4/sqrt2 G=S0 | Cov NST 95% | 0.36 | 0.486 | 0.0158 |  | yes | range rule: pass if paper in [0.268, 0.779] = 5 fixed beta draws (0.470-0.645; draw 1 R=1000, others R=200) and per-run redraw (0.400), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| p=500 (ii) t4/sqrt2 G=S0 | Cov NST 99% | 0.57 | 0.714 | 0.0143 |  | yes | range rule: pass if paper in [0.475, 0.924] = 5 fixed beta draws (0.685-0.790; draw 1 R=1000, others R=200) and per-run redraw (0.610), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.084) |
| p=500 (ii) t4/sqrt2 G=S0 | Cov ST 95% | 0.35 | 0.466 | 0.0158 |  | yes | range rule: pass if paper in [0.249, 0.784] = 5 fixed beta draws (0.450-0.650; draw 1 R=1000, others R=200) and per-run redraw (0.380), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| p=500 (ii) t4/sqrt2 G=S0 | Cov ST 99% | 0.55 | 0.694 | 0.0146 |  | yes | range rule: pass if paper in [0.414, 0.944] = 5 fixed beta draws (0.650-0.810; draw 1 R=1000, others R=200) and per-run redraw (0.550), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |
| p=500 (ii) t4/sqrt2 G=S0c | Cov EX 95% | 0.65 | 0.799 | 0.0127 |  | yes | range rule: pass if paper in [0.539, 0.934] = 5 fixed beta draws (0.705-0.805; draw 1 R=1000, others R=200) and per-run redraw (0.670), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.080) |
| p=500 (ii) t4/sqrt2 G=S0c | Cov EX 99% | 0.81 | 0.902 | 0.0094 |  | yes | range rule: pass if paper in [0.714, 1.013] = 5 fixed beta draws (0.830-0.905; draw 1 R=1000, others R=200) and per-run redraw (0.825), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.067) |
| p=500 (ii) t4/sqrt2 G=S0c | Cov ST 95% | 0.61 | 0.773 | 0.0132 |  | yes | range rule: pass if paper in [0.517, 0.922] = 5 fixed beta draws (0.655-0.790; draw 1 R=1000, others R=200) and per-run redraw (0.650), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.082) |
| p=500 (ii) t4/sqrt2 G=S0c | Cov ST 99% | 0.77 | 0.889 | 0.00993 |  | yes | range rule: pass if paper in [0.693, 1.014] = 5 fixed beta draws (0.810-0.900; draw 1 R=1000, others R=200) and per-run redraw (0.830), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.070) |

### ZC Table 2 (Sim.CI, s0=15) [expected failure] (11 of 64 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| p=120 (i) Gamma G=[p] | Cov NST 95% | 0.86 | 0.753 | 0.0136 | 0.073 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Cov NST 99% | 0.95 | 0.864 | 0.0108 | 0.059 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Len NST 95% | 1.72 |  1.5 | 0.00475 | 0.192 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=[p] | Len NST 99% | 1.97 | 1.68 | 0.00541 | 0.22 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Cov NST 95% | 0.99 | 0.987 | 0.00358 | 0.0343 | yes | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Cov NST 99% |    1 | 0.997 | 0.00173 | 0.0252 | yes | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Len NST 95% | 1.69 | 1.49 | 0.00471 | 0.189 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) Gamma G=S0c | Len NST 99% | 1.93 | 1.67 | 0.00546 | 0.216 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Cov NST 95% |  0.9 | 0.632 | 0.0153 | 0.0768 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Cov NST 99% | 0.97 | 0.824 | 0.012 | 0.0608 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Len NST 95% | 1.68 |  1.5 | 0.0052 | 0.19 | yes | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=[p] | Len NST 99% | 1.92 | 1.68 | 0.00586 | 0.217 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Cov NST 95% | 0.93 | 0.742 | 0.0138 | 0.0697 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Cov NST 99% | 0.98 | 0.901 | 0.00944 | 0.0517 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Len NST 95% | 1.68 | 1.48 | 0.00514 | 0.19 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) Gamma G=S0c | Len NST 99% | 1.91 | 1.66 | 0.00589 | 0.216 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Cov NST 95% | 0.87 | 0.762 | 0.0135 | 0.072 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Cov NST 99% | 0.95 | 0.855 | 0.0111 | 0.0598 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Len NST 95% | 1.72 | 1.49 | 0.00729 | 0.203 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=[p] | Len NST 99% | 1.97 | 1.66 | 0.00808 | 0.231 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Cov NST 95% | 0.99 | 0.989 | 0.0033 | 0.0337 | yes | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Cov NST 99% |    1 | 0.998 | 0.00141 | 0.0242 | yes | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Len NST 95% | 1.68 | 1.48 | 0.00718 | 0.198 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (i) t4/sqrt2 G=S0c | Len NST 99% | 1.92 | 1.65 | 0.00814 | 0.227 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Cov NST 95% | 0.89 | 0.619 | 0.0154 | 0.0777 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Cov NST 99% | 0.96 | 0.812 | 0.0124 | 0.0626 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Len NST 95% | 1.67 | 1.49 | 0.00789 |  0.2 | yes | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=[p] | Len NST 99% | 1.91 | 1.67 | 0.00879 | 0.228 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Cov NST 95% | 0.92 | 0.744 | 0.0138 | 0.0702 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Cov NST 99% | 0.98 | 0.882 | 0.0102 | 0.054 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Len NST 95% | 1.67 | 1.48 | 0.00775 |  0.2 | yes | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=120 (ii) t4/sqrt2 G=S0c | Len NST 99% |  1.9 | 1.65 | 0.00884 | 0.227 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Cov NST 95% | 0.86 | 0.689 | 0.0146 | 0.0761 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Cov NST 99% | 0.95 | 0.814 | 0.0123 | 0.0633 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Len NST 95% | 1.76 | 1.52 | 0.00459 | 0.195 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=[p] | Len NST 99% | 1.98 | 1.67 | 0.00519 | 0.22 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Cov NST 95% |    1 | 0.993 | 0.00264 | 0.0279 | yes | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Cov NST 99% |    1 | 0.998 | 0.00141 | 0.0242 | yes | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Len NST 95% | 1.75 | 1.52 | 0.00464 | 0.195 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) Gamma G=S0c | Len NST 99% | 1.96 | 1.67 | 0.00517 | 0.218 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Cov NST 95% | 0.83 | 0.697 | 0.0145 | 0.077 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Cov NST 99% | 0.96 | 0.847 | 0.0114 | 0.0596 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Len NST 95% | 2.04 | 1.63 | 0.00582 | 0.229 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=[p] | Len NST 99% | 2.42 | 1.79 | 0.00639 | 0.269 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Cov NST 95% | 0.94 | 0.789 | 0.0129 | 0.0659 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Cov NST 99% | 0.99 | 0.906 | 0.00923 | 0.0498 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Len NST 95% | 2.04 | 1.63 | 0.00579 | 0.229 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) Gamma G=S0c | Len NST 99% | 2.42 | 1.79 | 0.00653 | 0.27 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Cov NST 95% | 0.86 | 0.726 | 0.0141 | 0.0744 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Cov NST 99% | 0.95 | 0.815 | 0.0123 | 0.0632 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Len NST 95% | 1.75 | 1.52 | 0.00998 | 0.217 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=[p] | Len NST 99% | 1.97 | 1.67 | 0.0112 | 0.245 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Cov NST 95% | 0.99 | 0.993 | 0.00264 | 0.0323 | yes | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Cov NST 99% |    1 |    1 |    0 | 0.0213 | yes | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Len NST 95% | 1.74 | 1.52 | 0.00991 | 0.216 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (i) t4/sqrt2 G=S0c | Len NST 99% | 1.95 | 1.67 | 0.0109 | 0.241 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Cov NST 95% | 0.81 | 0.711 | 0.0143 | 0.0773 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Cov NST 99% | 0.94 | 0.848 | 0.0114 | 0.0613 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Len NST 95% | 2.01 | 1.64 | 0.0131 | 0.257 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=[p] | Len NST 99% | 2.38 |  1.8 | 0.0143 | 0.299 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Cov NST 95% | 0.93 | 0.808 | 0.0125 | 0.0653 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Cov NST 99% | 0.98 | 0.91 | 0.00905 | 0.0506 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Len NST 95% | 2.01 | 1.63 | 0.0129 | 0.256 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |
| p=500 (ii) t4/sqrt2 G=S0c | Len NST 99% | 2.38 | 1.79 | 0.0142 | 0.298 | **no** | expected failure: NST/ST width ratio not reproducible with pooled CV tuning (CRITERIA.md (Part 1), ambiguity 3); width: 3 MC s.e. + 10% of paper; R=1000 vs paper R=1000 |

### ZC code checks [code check] (2 of 2 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| zc_simci, all runs incl. sensitivity | max \|b(fit) - b(Sim.CI)\| (EX uses the Sim.CI estimates) |  |    0 |  |  | yes | consistency check of the replication code |
| zc_st, first replication of each cell | Share of ST() calls reproduced exactly |  |    1 |  |  | yes | 24 ST() calls; three-step = ST() (statistics and decisions) |

### ZC Table 3 (SR, s0=15) [draw-dependent] (16 of 16 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| p=500 (i) Gamma | Lassosc mean d | 0.38 | 0.31 | 0.0006 |  | yes | range rule: pass if paper in [0.287, 0.770] = 5 fixed support draws (0.310-0.742; draw 1 R=1000, others R=200) and per-run redraw (0.599), each +- its ordinary tolerance; draw 1 alone: fail (tol 0.023) |
| p=500 (i) Gamma | Lassosc SD d | 0.03 | 0.019 | 0.000424 |  | yes | range rule: pass if paper in [-0.011, 0.069] = 5 fixed support draws (0.019-0.035; draw 1 R=1000, others R=200), each +- its ordinary tolerance; per-run redraw (0.102) excluded: its SD mixes supports; draw 1 alone: pass (tol 0.030) |
| p=500 (i) Gamma | Lassosc FP | 19.1 | 19.1 | 0.0501 |  | yes | range rule: pass if paper in [7.847, 23.673] = 5 fixed support draws (12.385-19.072; draw 1 R=1000, others R=200) and per-run redraw (18.755), each +- its ordinary tolerance; draw 1 alone: pass (tol 4.143) |
| p=500 (i) Gamma | Lassosc FN | 7.36 |    9 | 0.0109 |  | yes | range rule: pass if paper in [-1.583, 10.614] = 5 fixed support draws (0.000-8.996; draw 1 R=1000, others R=200) and per-run redraw (1.935), each +- its ordinary tolerance; draw 1 alone: fail (tol 1.618) |
| p=500 (i) Gamma | SupRec mean d | 0.53 |    0 |    0 |  | yes | range rule: pass if paper in [-0.024, 1.012] = 5 fixed support draws (0.000-0.985; draw 1 R=1000, others R=200) and per-run redraw (0.669), each +- its ordinary tolerance; draw 1 alone: fail (tol 0.024) |
| p=500 (i) Gamma | SupRec SD d | 0.04 |    0 |    0 |  | yes | range rule: pass if paper in [-0.033, 0.152] = 5 fixed support draws (0.000-0.106; draw 1 R=1000, others R=200), each +- its ordinary tolerance; per-run redraw (0.302) excluded: its SD mixes supports; draw 1 alone: fail (tol 0.033) |
| p=500 (i) Gamma | SupRec FP | 0.15 |    0 |    0 |  | yes | range rule: pass if paper in [-0.130, 1.616] = 5 fixed support draws (0.000-1.365; draw 1 R=1000, others R=200) and per-run redraw (0.365), each +- its ordinary tolerance; draw 1 alone: fail (tol 0.130) |
| p=500 (i) Gamma | SupRec FN | 10.7 |   15 |    0 |  | yes | range rule: pass if paper in [-2.064, 17.236] = 5 fixed support draws (0.325-15.000; draw 1 R=1000, others R=200) and per-run redraw (6.640), each +- its ordinary tolerance; draw 1 alone: fail (tol 2.236) |
| p=500 (i) t4/sqrt2 | Lassosc mean d | 0.38 | 0.31 | 0.00061 |  | yes | range rule: pass if paper in [0.286, 0.769] = 5 fixed support draws (0.310-0.742; draw 1 R=1000, others R=200) and per-run redraw (0.590), each +- its ordinary tolerance; draw 1 alone: fail (tol 0.023) |
| p=500 (i) t4/sqrt2 | Lassosc SD d | 0.03 | 0.0193 | 0.000431 |  | yes | range rule: pass if paper in [-0.011, 0.067] = 5 fixed support draws (0.019-0.034; draw 1 R=1000, others R=200), each +- its ordinary tolerance; per-run redraw (0.104) excluded: its SD mixes supports; draw 1 alone: pass (tol 0.030) |
| p=500 (i) t4/sqrt2 | Lassosc FP | 19.2 |   19 | 0.0509 |  | yes | range rule: pass if paper in [7.847, 23.784] = 5 fixed support draws (12.310-19.007; draw 1 R=1000, others R=200) and per-run redraw (18.890), each +- its ordinary tolerance; draw 1 alone: pass (tol 4.166) |
| p=500 (i) t4/sqrt2 | Lassosc FN | 7.37 | 9.01 | 0.0108 |  | yes | range rule: pass if paper in [-1.592, 10.628] = 5 fixed support draws (0.015-9.008; draw 1 R=1000, others R=200) and per-run redraw (2.135), each +- its ordinary tolerance; draw 1 alone: fail (tol 1.620) |
| p=500 (i) t4/sqrt2 | SupRec mean d | 0.53 |    0 |    0 |  | yes | range rule: pass if paper in [-0.024, 1.011] = 5 fixed support draws (0.000-0.984; draw 1 R=1000, others R=200) and per-run redraw (0.613), each +- its ordinary tolerance; draw 1 alone: fail (tol 0.024) |
| p=500 (i) t4/sqrt2 | SupRec SD d | 0.04 |    0 |    0 |  | yes | range rule: pass if paper in [-0.033, 0.162] = 5 fixed support draws (0.000-0.115; draw 1 R=1000, others R=200), each +- its ordinary tolerance; per-run redraw (0.323) excluded: its SD mixes supports; draw 1 alone: fail (tol 0.033) |
| p=500 (i) t4/sqrt2 | SupRec FP | 0.14 |    0 |    0 |  | yes | range rule: pass if paper in [-0.139, 1.600] = 5 fixed support draws (0.000-1.360; draw 1 R=1000, others R=200) and per-run redraw (0.340), each +- its ordinary tolerance; draw 1 alone: fail (tol 0.128) |
| p=500 (i) t4/sqrt2 | SupRec FN | 10.7 |   15 |    0 |  | yes | range rule: pass if paper in [-2.045, 17.232] = 5 fixed support draws (0.390-15.000; draw 1 R=1000, others R=200) and per-run redraw (7.550), each +- its ordinary tolerance; draw 1 alone: fail (tol 2.232) |

### ZC Section 5.3 screening, case (i) [informational] (0 of 0 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| (i) s0=3 t4/sqrt2 | P(all 3 relevant variables kept), remedy |  | 0.956 | 0.00917 |  | n/a | SILM ST() screening (used here); informational, no published value |
| (i) s0=3 t4/sqrt2 | P(all 3 relevant variables kept), marginal |  |    1 |    0 |  | n/a | plain marginal screening (the paper's step 2), not a SILM method; informational, no published value |
| (i) s0=3 Gamma | P(all 3 relevant variables kept), remedy |  | 0.956 | 0.00917 |  | n/a | SILM ST() screening (used here); informational, no published value |
| (i) s0=3 Gamma | P(all 3 relevant variables kept), marginal |  |    1 |    0 |  | n/a | plain marginal screening (the paper's step 2), not a SILM method; informational, no published value |
| (i) s0=15 t4/sqrt2 | P(all 15 relevant variables kept), remedy |  | 0.842 | 0.0163 |  | n/a | SILM ST() screening (used here); informational, no published value |
| (i) s0=15 t4/sqrt2 | P(all 15 relevant variables kept), marginal |  | 0.97 | 0.00763 |  | n/a | plain marginal screening (the paper's step 2), not a SILM method; informational, no published value |
| (i) s0=15 Gamma | P(all 15 relevant variables kept), remedy |  | 0.854 | 0.0158 |  | n/a | SILM ST() screening (used here); informational, no published value |
| (i) s0=15 Gamma | P(all 15 relevant variables kept), marginal |  | 0.972 | 0.00738 |  | n/a | plain marginal screening (the paper's step 2), not a SILM method; informational, no published value |

### ZC Table 5 (Step, p=500) [draw-dependent] (48 of 48 passed)

| Cell | Metric | Paper | Ours | MC s.e. | Tolerance | Pass | Note |
|---|---|---|---|---|---|---|---|
| s0=3 (i) Gamma | FWER BH | 0.023 | 0.028 | 0.00522 |  | yes | Holm: not a SILM method; range rule: pass if paper in [-0.043, 0.091] = 5 fixed beta draws (0.010-0.035; draw 1 R=1000, others R=200) and per-run redraw (0.025), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.041) |
| s0=3 (i) Gamma | FWER NST | 0.034 | 0.036 | 0.00589 |  | yes | range rule: pass if paper in [-0.036, 0.108] = 5 fixed beta draws (0.025-0.045; draw 1 R=1000, others R=200) and per-run redraw (0.025), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.045) |
| s0=3 (i) Gamma | FWER ST | 0.033 | 0.03 | 0.0054 |  | yes | range rule: pass if paper in [-0.045, 0.102] = 5 fixed beta draws (0.015-0.040; draw 1 R=1000, others R=200) and per-run redraw (0.035), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.043) |
| s0=3 (i) Gamma | Power BH | 0.506 |    1 |    0 |  | yes | Holm: not a SILM method; range rule: pass if paper in [0.451, 1.078] = 5 fixed beta draws (0.587-1.000; draw 1 R=1000, others R=200) and per-run redraw (0.652), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.078) |
| s0=3 (i) Gamma | Power NST | 0.535 |    1 | 0.000333 |  | yes | range rule: pass if paper in [0.453, 1.076] = 5 fixed beta draws (0.588-1.000; draw 1 R=1000, others R=200) and per-run redraw (0.648), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.077) |
| s0=3 (i) Gamma | Power ST | 0.513 |    1 |    0 |  | yes | range rule: pass if paper in [0.459, 1.078] = 5 fixed beta draws (0.595-1.000; draw 1 R=1000, others R=200) and per-run redraw (0.655), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.078) |
| s0=3 (i) t4/sqrt2 | FWER BH | 0.024 | 0.024 | 0.00484 |  | yes | Holm: not a SILM method; range rule: pass if paper in [-0.044, 0.097] = 5 fixed beta draws (0.010-0.040; draw 1 R=1000, others R=200) and per-run redraw (0.040), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.041) |
| s0=3 (i) t4/sqrt2 | FWER NST | 0.037 | 0.029 | 0.00531 |  | yes | range rule: pass if paper in [-0.047, 0.110] = 5 fixed beta draws (0.015-0.040; draw 1 R=1000, others R=200) and per-run redraw (0.045), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.044) |
| s0=3 (i) t4/sqrt2 | FWER ST | 0.028 | 0.027 | 0.00513 |  | yes | range rule: pass if paper in [-0.046, 0.105] = 5 fixed beta draws (0.010-0.045; draw 1 R=1000, others R=200) and per-run redraw (0.045), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.042) |
| s0=3 (i) t4/sqrt2 | Power BH | 0.528 | 0.997 | 0.0011 |  | yes | Holm: not a SILM method; range rule: pass if paper in [0.446, 1.074] = 5 fixed beta draws (0.582-0.997; draw 1 R=1000, others R=200) and per-run redraw (0.697), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.077) |
| s0=3 (i) t4/sqrt2 | Power NST | 0.548 | 0.997 | 0.0011 |  | yes | range rule: pass if paper in [0.436, 1.073] = 5 fixed beta draws (0.572-0.997; draw 1 R=1000, others R=200) and per-run redraw (0.687), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.076) |
| s0=3 (i) t4/sqrt2 | Power ST | 0.534 | 0.998 | 0.000998 |  | yes | range rule: pass if paper in [0.454, 1.074] = 5 fixed beta draws (0.590-0.998; draw 1 R=1000, others R=200) and per-run redraw (0.700), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.077) |
| s0=15 (i) Gamma | FWER BH | 0.011 | 0.004 | 0.002 |  | yes | Holm: not a SILM method; range rule: pass if paper in [-0.038, 0.048] = 5 fixed beta draws (0.004-0.005; draw 1 R=1000, others R=200) and per-run redraw (0.005), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.032) |
| s0=15 (i) Gamma | FWER NST | 0.014 | 0.009 | 0.00299 |  | yes | range rule: pass if paper in [-0.037, 0.057] = 5 fixed beta draws (0.009-0.010; draw 1 R=1000, others R=200) and per-run redraw (0.010), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.034) |
| s0=15 (i) Gamma | FWER ST | 0.016 | 0.01 | 0.00315 |  | yes | range rule: pass if paper in [-0.042, 0.070] = 5 fixed beta draws (0.005-0.020; draw 1 R=1000, others R=200) and per-run redraw (0.005), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.035) |
| s0=15 (i) Gamma | Power BH | 0.708 | 0.656 | 0.00224 |  | yes | Holm: not a SILM method; range rule: pass if paper in [0.441, 0.854] = 5 fixed beta draws (0.569-0.729; draw 1 R=1000, others R=200) and per-run redraw (0.668), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.082) |
| s0=15 (i) Gamma | Power NST | 0.725 | 0.643 | 0.00225 |  | yes | range rule: pass if paper in [0.427, 0.834] = 5 fixed beta draws (0.554-0.710; draw 1 R=1000, others R=200) and per-run redraw (0.657), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.082) |
| s0=15 (i) Gamma | Power ST | 0.714 | 0.66 | 0.00224 |  | yes | range rule: pass if paper in [0.447, 0.858] = 5 fixed beta draws (0.574-0.733; draw 1 R=1000, others R=200) and per-run redraw (0.672), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.082) |
| s0=15 (i) t4/sqrt2 | FWER BH | 0.006 | 0.007 | 0.00264 |  | yes | Holm: not a SILM method; range rule: pass if paper in [-0.036, 0.049] = 5 fixed beta draws (0.000-0.010; draw 1 R=1000, others R=200) and per-run redraw (0.000), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.031) |
| s0=15 (i) t4/sqrt2 | FWER NST | 0.008 | 0.009 | 0.00299 |  | yes | range rule: pass if paper in [-0.039, 0.051] = 5 fixed beta draws (0.000-0.010; draw 1 R=1000, others R=200) and per-run redraw (0.000), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.032) |
| s0=15 (i) t4/sqrt2 | FWER ST | 0.009 | 0.007 | 0.00264 |  | yes | range rule: pass if paper in [-0.040, 0.052] = 5 fixed beta draws (0.005-0.010; draw 1 R=1000, others R=200) and per-run redraw (0.000), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.032) |
| s0=15 (i) t4/sqrt2 | Power BH | 0.717 | 0.649 | 0.00245 |  | yes | Holm: not a SILM method; range rule: pass if paper in [0.439, 0.864] = 5 fixed beta draws (0.566-0.740; draw 1 R=1000, others R=200) and per-run redraw (0.683), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.082) |
| s0=15 (i) t4/sqrt2 | Power NST | 0.732 | 0.637 | 0.00248 |  | yes | range rule: pass if paper in [0.430, 0.847] = 5 fixed beta draws (0.556-0.724; draw 1 R=1000, others R=200) and per-run redraw (0.670), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.082) |
| s0=15 (i) t4/sqrt2 | Power ST | 0.722 | 0.654 | 0.00247 |  | yes | range rule: pass if paper in [0.445, 0.869] = 5 fixed beta draws (0.572-0.746; draw 1 R=1000, others R=200) and per-run redraw (0.690), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.082) |
| s0=3 (ii) Gamma | FWER BH | 0.038 | 0.035 | 0.00581 |  | yes | Holm: not a SILM method; range rule: pass if paper in [-0.043, 0.116] = 5 fixed beta draws (0.035-0.050; draw 1 R=1000, others R=200) and per-run redraw (0.020), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.045) |
| s0=3 (ii) Gamma | FWER NST | 0.039 | 0.042 | 0.00635 |  | yes | range rule: pass if paper in [-0.034, 0.132] = 5 fixed beta draws (0.042-0.065; draw 1 R=1000, others R=200) and per-run redraw (0.030), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.046) |
| s0=3 (ii) Gamma | FWER ST | 0.046 | 0.036 | 0.00589 |  | yes | range rule: pass if paper in [-0.037, 0.135] = 5 fixed beta draws (0.036-0.065; draw 1 R=1000, others R=200) and per-run redraw (0.030), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.047) |
| s0=3 (ii) Gamma | Power BH | 0.545 | 0.656 | 0.00236 |  | yes | Holm: not a SILM method; range rule: pass if paper in [0.201, 0.833] = 5 fixed beta draws (0.337-0.698; draw 1 R=1000, others R=200) and per-run redraw (0.675), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| s0=3 (ii) Gamma | Power NST | 0.581 | 0.658 | 0.00222 |  | yes | range rule: pass if paper in [0.201, 0.829] = 5 fixed beta draws (0.337-0.695; draw 1 R=1000, others R=200) and per-run redraw (0.683), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.085) |
| s0=3 (ii) Gamma | Power ST | 0.549 | 0.657 | 0.00227 |  | yes | range rule: pass if paper in [0.202, 0.833] = 5 fixed beta draws (0.338-0.698; draw 1 R=1000, others R=200) and per-run redraw (0.680), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| s0=3 (ii) t4/sqrt2 | FWER BH | 0.04 | 0.043 | 0.00642 |  | yes | Holm: not a SILM method; range rule: pass if paper in [-0.048, 0.106] = 5 fixed beta draws (0.015-0.043; draw 1 R=1000, others R=200) and per-run redraw (0.040), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.047) |
| s0=3 (ii) t4/sqrt2 | FWER NST | 0.046 | 0.049 | 0.00683 |  | yes | range rule: pass if paper in [-0.056, 0.135] = 5 fixed beta draws (0.010-0.065; draw 1 R=1000, others R=200) and per-run redraw (0.035), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.049) |
| s0=3 (ii) t4/sqrt2 | FWER ST | 0.048 | 0.054 | 0.00715 |  | yes | range rule: pass if paper in [-0.052, 0.131] = 5 fixed beta draws (0.015-0.054; draw 1 R=1000, others R=200) and per-run redraw (0.060), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.050) |
| s0=3 (ii) t4/sqrt2 | Power BH | 0.555 | 0.651 | 0.00258 |  | yes | Holm: not a SILM method; range rule: pass if paper in [0.211, 0.835] = 5 fixed beta draws (0.347-0.700; draw 1 R=1000, others R=200) and per-run redraw (0.690), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| s0=3 (ii) t4/sqrt2 | Power NST | 0.594 | 0.653 | 0.0025 |  | yes | range rule: pass if paper in [0.213, 0.833] = 5 fixed beta draws (0.348-0.700; draw 1 R=1000, others R=200) and per-run redraw (0.693), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.085) |
| s0=3 (ii) t4/sqrt2 | Power ST | 0.56 | 0.652 | 0.00254 |  | yes | range rule: pass if paper in [0.212, 0.835] = 5 fixed beta draws (0.348-0.700; draw 1 R=1000, others R=200) and per-run redraw (0.693), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.086) |
| s0=15 (ii) Gamma | FWER BH | 0.004 | 0.008 | 0.00282 |  | yes | Holm: not a SILM method; range rule: pass if paper in [-0.033, 0.046] = 5 fixed beta draws (0.000-0.008; draw 1 R=1000, others R=200) and per-run redraw (0.010), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.030) |
| s0=15 (ii) Gamma | FWER NST | 0.001 | 0.01 | 0.00315 |  | yes | range rule: pass if paper in [-0.027, 0.048] = 5 fixed beta draws (0.000-0.015; draw 1 R=1000, others R=200) and per-run redraw (0.005), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.030) |
| s0=15 (ii) Gamma | FWER ST | 0.004 | 0.01 | 0.00315 |  | yes | range rule: pass if paper in [-0.033, 0.053] = 5 fixed beta draws (0.000-0.010; draw 1 R=1000, others R=200) and per-run redraw (0.015), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.031) |
| s0=15 (ii) Gamma | Power BH | 0.68 | 0.558 | 0.00181 |  | yes | Holm: not a SILM method; range rule: pass if paper in [0.390, 0.899] = 5 fixed beta draws (0.521-0.772; draw 1 R=1000, others R=200) and per-run redraw (0.645), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |
| s0=15 (ii) Gamma | Power NST | 0.701 | 0.559 | 0.00182 |  | yes | range rule: pass if paper in [0.395, 0.906] = 5 fixed beta draws (0.524-0.781; draw 1 R=1000, others R=200) and per-run redraw (0.652), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |
| s0=15 (ii) Gamma | Power ST | 0.685 | 0.561 | 0.00181 |  | yes | range rule: pass if paper in [0.395, 0.902] = 5 fixed beta draws (0.526-0.775; draw 1 R=1000, others R=200) and per-run redraw (0.652), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |
| s0=15 (ii) t4/sqrt2 | FWER BH | 0.004 | 0.006 | 0.00244 |  | yes | Holm: not a SILM method; range rule: pass if paper in [-0.033, 0.046] = 5 fixed beta draws (0.000-0.010; draw 1 R=1000, others R=200) and per-run redraw (0.000), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.029) |
| s0=15 (ii) t4/sqrt2 | FWER NST | 0.005 | 0.009 | 0.00299 |  | yes | range rule: pass if paper in [-0.035, 0.048] = 5 fixed beta draws (0.000-0.010; draw 1 R=1000, others R=200) and per-run redraw (0.000), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.031) |
| s0=15 (ii) t4/sqrt2 | FWER ST | 0.005 | 0.009 | 0.00299 |  | yes | range rule: pass if paper in [-0.035, 0.048] = 5 fixed beta draws (0.005-0.010; draw 1 R=1000, others R=200) and per-run redraw (0.000), each +- its check_prop tolerance; draw 1 alone: pass (tol 0.031) |
| s0=15 (ii) t4/sqrt2 | Power BH | 0.678 | 0.564 | 0.00201 |  | yes | Holm: not a SILM method; range rule: pass if paper in [0.401, 0.901] = 5 fixed beta draws (0.532-0.774; draw 1 R=1000, others R=200) and per-run redraw (0.637), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |
| s0=15 (ii) t4/sqrt2 | Power NST | 0.701 | 0.564 | 0.00203 |  | yes | range rule: pass if paper in [0.408, 0.906] = 5 fixed beta draws (0.537-0.781; draw 1 R=1000, others R=200) and per-run redraw (0.644), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |
| s0=15 (ii) t4/sqrt2 | Power ST | 0.685 | 0.567 | 0.002 |  | yes | range rule: pass if paper in [0.409, 0.904] = 5 fixed beta draws (0.539-0.778; draw 1 R=1000, others R=200) and per-run redraw (0.643), each +- its check_prop tolerance; draw 1 alone: fail (tol 0.085) |

