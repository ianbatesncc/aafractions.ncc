% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{uc_conditions}
\alias{uc_conditions}
\title{List of Urgent care sensitive conditions}
\format{data frame with 14 rows and 7 fields

\preformatted{
Observations: 14
Variables: 7
$ condition_description <chr> "COPD", "Acute mental health crisis", "Non-specific chest pain", "Falls", "Non-specific abdomin...
$ primary_diagnosis     <chr> "J40; J41; J42; J43; J44", "F", "R072; R073; R074", "W0; W1-W19", "R10", "I80; I81; I82", "L03"...
$ age                   <chr> "All ages", "All ages", "All ages", "75+ yrs", "All ages", "All ages", "All ages", "0 - 5 yrs",...
$ primary_regex         <chr> "J4[0-4]", "F", "R07[2-4]", "W[01][0-9]", "R10", "I8[0-2]", "L03", "R50", "T830", "E1[0-5];E16[...
$ cat1                  <chr> "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All"
$ cat2                  <chr> "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All"
$ condition_uid         <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
}}
\usage{
uc_conditions
}
\description{
Provides lookup tables for use with Urgent care sensitive analyses.
}
\examples{
if (isNamespaceLoaded("dplyr")) {
  require("dplyr")

  aafractions.ncc::uc_conditions \%>\%
    mutate_if(is.character, as.factor) \%>\%
    select(-starts_with("condition_"), -starts_with("primary")) \%>\%
    summary(16)
}

}
\seealso{
Other urgent care sensitive datasets: \code{\link{lu_ucc_icd10}},
  \code{\link{uc_attribution}}, \code{\link{uc_versions}},
  \code{\link{ucs_datasets}}
}
\concept{urgent care sensitive datasets}
\keyword{datasets}
