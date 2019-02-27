
<!-- README.md is generated from README.Rmd. Please edit that file -->
aafractions.ncc
===============

Alcohol Attributable Fractions Lookup Tables

Provides lookup tables for use with alcohol attributable fractions analyses

Installation
------------

You can install aafractions.ncc from github with:

``` r
# install.packages("devtools")
devtools::install_github("ianbatesncc/aafractions.ncc")
```

Example
=======

    ## reconstruct current aaf lookup for hospital admissions

    t1 <- reconstruct("aaf_2017_phe", "morbidity")
