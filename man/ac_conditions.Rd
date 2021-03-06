% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{ac_conditions}
\alias{ac_conditions}
\title{List of Ambulatory care sensitive conditions}
\format{data frame with 13 rows and 12 fields

\preformatted{
Observations: 13
Variables: 12
$ cat1                  <chr> "Cardiovascular diseases", "Cardiovascular diseases", "Cardiovascular diseases", "Card...
$ cat2                  <chr> "Atrial Fibrillation", "Angina", "Chronic heart disease", "Congestive heart failure", ...
$ condition_description <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
$ age                   <chr> "All ages", "All ages", "All ages", "All ages", "All ages", "All ages", "All ages", "A...
$ primary_diagnosis     <chr> "I48", "I20", "I25", "I50;I11.0;J81X;I13.0", "I10X;I11.9", "D51-D52;D50.1;D50.8;D50.9"...
$ secondary_diagnoses   <chr> NA, NA, NA, NA, NA, NA, "-D57", NA, NA, NA, NA, "J41-44;J47", NA
$ procedures            <chr> NA, "-A-W;-X0-X5", "-A-W;-X0-X5", "-K0-K4;-K50;-K52;-K55-K57;-K60-61;-K67-69;-K71;-K73...
$ prim_diag_regexp      <chr> "I48", "I20", "I25", "I50|I110|J81X|I130", "I10X|I119", "D5[12]|D50[189]", "B18[01]", ...
$ proc_regex            <chr> NA, "[A-W]|X[0-5]", "[A-W]|X[0-5]", "K[0-4]|K5[025-7]|K6[016-9]|K7[134]", "K[0-4]|K5[0...
$ sec_diag_regex        <chr> NA, NA, NA, NA, NA, NA, "-D57", NA, NA, NA, NA, "J4[12347]", NA
$ condition_uid         <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
$ version               <chr> "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "c...
}}
\usage{
ac_conditions
}
\description{
Provides lookup tables for use with Ambulatory care sensitive analyses.
}
\examples{
if (isNamespaceLoaded("dplyr")) {
  require("dplyr")

  aafractions.ncc::ac_conditions \%>\%
    mutate_if(is.character, as.factor) \%>\%
    select(-starts_with("condition_"), -starts_with("primary")) \%>\%
    summary(16)
}


}
\seealso{
Other ambulatory care sensitive datasets: \code{\link{ac_attribution}},
  \code{\link{ac_versions}}, \code{\link{acs_datasets}},
  \code{\link{lu_acc_icd10}}
}
\concept{ambulatory care sensitive datasets}
\keyword{datasets}
