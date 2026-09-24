## Resubmission of an archived package

SILM was archived on 2026-07-10 because it required the archived package
'scalreg' (and imported 'hdi', archived for the same reason). This version
removes both dependencies: SILM now imports only 'glmnet', 'lars' and 'MASS'
(plus base packages).

* The scaled lasso is an independent implementation (no code from 'scalreg').
* Code adapted from 'hdi' (GPL) is credited in Authors@R (ctb, cph) and
  documented in inst/COPYRIGHTS.
* The results of SILM 1.0.0 remain reproducible exactly; the package also
  provides lasso.proj() and boot.lasso.proj(), which were only available in
  the archived 'hdi'.

## Test environments

* local macOS (aarch64), R 4.5.2
* GitHub Actions: ubuntu-latest (release, devel, oldrel-1), macOS-latest
  (release), windows-latest (release)

## R CMD check results

0 errors | 0 warnings | 1 note

* "Package was archived on CRAN" (see above).
