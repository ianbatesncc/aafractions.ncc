<!-- README.md is generated from README.Rmd. Please edit that file -->
aafractions.ncc
===============

Alcohol Attributable Fractions Lookup Tables

Provides lookup tables for use with alcohol attributable fractions analyses

Example
=======

    ## reconstruct current aaf lookup for hospital admissions

    t1 <- reconstruct("aaf_2017_phe", "morbidity")
