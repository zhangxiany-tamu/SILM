# SILM: Simultaneous Inference for Linear Models

<!-- badges: start -->
[![R-CMD-check](https://github.com/zhangxiany-tamu/SILM/actions/workflows/R-CMD-check.yml/badge.svg)](https://github.com/zhangxiany-tamu/SILM/actions/workflows/R-CMD-check.yml)
[![equivalence](https://github.com/zhangxiany-tamu/SILM/actions/workflows/equivalence.yml/badge.svg)](https://github.com/zhangxiany-tamu/SILM/actions/workflows/equivalence.yml)
<!-- badges: end -->

SILM implements the simultaneous inference procedures for high-dimensional
linear models of Zhang and Cheng (2017), *Journal of the American Statistical
Association*, 112, 757–768 ([doi:10.1080/01621459.2016.1166114](https://doi.org/10.1080/01621459.2016.1166114)).

SILM was on CRAN from 2019 until July 2026, when it was archived because a
dependency ('scalreg', and with it 'hdi') was archived. This repository revives
it as a self-contained package that depends only on packages available on
CRAN. **Work in progress** towards SILM 2.0.0 — see `NEWS.md`.

## Installation

```r
# install.packages("pak")
pak::pak("zhangxiany-tamu/SILM")
# or: remotes::install_github("zhangxiany-tamu/SILM")
```

## Reproducibility

Every result of SILM 1.0.0 can be reproduced exactly (same numbers under the
same random seed); the equivalence is checked continuously against the archived
CRAN packages (`validation/`). Note that SILM 1.0.0 computed different results
depending on the installed version of 'hdi'; use `nodewise = "ZnZ"` to
reproduce results obtained with hdi 0.1-7 or later (2019–2026), and see
`?SR` for details.

## Citation

Zhang, X. and Cheng, G. (2017). Simultaneous inference for high-dimensional
linear models. *Journal of the American Statistical Association*, 112(518),
757–768.
