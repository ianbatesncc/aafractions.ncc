% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/example_analysis__hes_ip.R
\name{gen_codes}
\alias{gen_codes}
\title{Generate icd code space}
\usage{
gen_codes(len = c("len3", "len4", "len34"))
}
\arguments{
\item{len}{Overall length of code.  3 corresponds to Xnn, 4 to Xnnn, 34 to both.}
}
\value{
(character vector) All possible codes
}
\description{
Generate all possible (valid and invalid) icd10 codes of the form
[A-Z][0-9]{nn} where nn is either two or three digits in length (or both).
}
\seealso{
Other examples_of_analysis: \code{\link{ab_labels_from_breaks}},
  \code{\link{create__dummy_hesip}},
  \code{\link{create_lu_ageband}},
  \code{\link{create_lu_gender}},
  \code{\link{examples_of_analysis}},
  \code{\link{main__example_analysis__aa_morbidity}},
  \code{\link{main__example_analysis__ac_morbidity}},
  \code{\link{main__example_analysis__sa_morbidity}},
  \code{\link{main__example_analysis__uc_morbidity}},
  \code{\link{main__examples_analysis}},
  \code{\link{ricd10}}
}
\concept{examples_of_analysis}
