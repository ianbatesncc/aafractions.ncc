#
# data.R
#

#' List of alcohol attributable conditions
#'
#' Provides lookup tables for use with alcohol attributable fractions analyses.
#'
#' @format data frame with 69 rows and 8 fields
#'
#' \preformatted{
#' 'data.frame':	69 obs. of  8 variables:
#' $ cat1          : Factor w/ 3 levels "Partially attributable conditions - acute conditions",..: 3 3 3 3 3 3 3 3 3 3 ...
#' $ cat2          : Factor w/ 12 levels "Cardiovascular disease",..: 12 12 12 12 12 12 12 12 12 12 ...
#' $ desc          : Factor w/ 68 levels "§","§§","Accidental excessive cold",..: 9 49 21 14 13 10 11 12 7 8 ...
#' $ attribution   : logi  NA NA NA NA NA NA ...
#' $ cause         : logi  NA NA NA NA NA NA ...
#' $ codes         : Factor w/ 68 levels "A15-A19","C00-C14",..: 11 12 13 15 16 19 27 28 34 35 ...
#' $ condition_fuid: Ord.factor w/ 69 levels "Wholly attributable conditions.Wholly attributable conditions.Alcohol-induced pseudo-Cushing's syndrome.E24.4"<..: 1 2 3 4 5 6 7 8 9 10 ...
#' $ condition_uid : int  1 2 3 4 5 6 7 8 9 10 ...
#' }
#'
#' @examples
#' if (isNamespaceLoaded("dplyr")) {
#'   require("dplyr")
#'
#'   aafractions.ncc::aa_conditions %>%
#'     mutate_if(is.character, as.factor) %>%
#'     select(-starts_with("condition_"), -codes, -desc) %>%
#'     summary(16)
#' }
#'
"aa_conditions"


#' List of alcohol attributable fractions by condition, age and sex
#'
#' Provides lookup tables for use with alcohol attributable fractions analyses.
#'
#' @format data frame with 213 rows and 3 fields
#'
#' \preformatted{
#' 'data.frame':	213 obs. of  3 variables:
#' $ Version       : Factor w/ 4 levels "aaf_2007_ni39",..: 1 1 1 1 1 1 1 1 1 1 ...
#' $ condition_fuid: Ord.factor w/ 69 levels "Wholly attributable conditions.Wholly attributable conditions.Alcohol-induced pseudo-Cushing's syndrome.E24.4"<..: 1 2 3 4 5 6 7 10 13 14 ...
#' $ condition_uid : int  1 2 3 4 5 6 7 10 13 14 ...
#' }
#'
#' @examples
#' if (isNamespaceLoaded("dplyr")) {
#'   require("dplyr")
#'
#'   aafractions.ncc::aa_versions %>%
#'     dplyr::mutate_if(is.character, as.factor) %>%
#'     dplyr::select(-starts_with("condition_")) %>%
#'     summary(16)
#' }
#'
"aa_versions"


#' List of alcohol attributable fractions by condition, age and sex
#'
#' Provides lookup tables for use with alcohol attributable fractions analyses.
#'
#' @format data frame with 5,920 rows and 7 fields
#'
#' \preformatted{
#' 'data.frame':	5920 obs. of  7 variables:
#' $ Version       : Factor w/ 4 levels "aaf_2007_ni39",..: 1 1 1 1 1 1 1 1 1 1 ...
#' $ condition_fuid: Ord.factor w/ 69 levels "Wholly attributable conditions.Wholly attributable conditions.Alcohol-induced pseudo-Cushing's syndrome.E24.4"<..: 1 1 1 1 1 1 1 1 1 1 ...
#' $ condition_uid : int  1 1 1 1 1 1 1 1 1 1 ...
#' $ aa_ageband    : chr  "00-15 Yrs" "16-24 Yrs" "25-34 Yrs" "35-44 Yrs" ...
#' $ sex           : chr  "F" "F" "F" "F" ...
#' $ analysis_type : chr  "morbidity" "morbidity" "morbidity" "morbidity" ...
#' $ aaf           : num  1 1 1 1 1 1 1 1 1 1 ...
#' }
#'
#' @examples
#' if (isNamespaceLoaded("dplyr")) {
#'   require("dplyr")
#'
#'   aafractions.ncc::aa_fractions %>%
#'     mutate_if(is.character, as.factor) %>%
#'     select(-starts_with("condition_")) %>%
#'     summary(16)
#' }
#'
"aa_fractions"

#' Lookup between alcohol attributable conditions and icd10 codes
#'
#' Provides lookup tables for use with alcohol attributable fractions analyses.
#'
#' @format data frame with 69 rows and 7 fields
#'
#' @examples
#' if (all(sapply(c("dplyr", "reshape2"), isNamespaceLoaded))) {
#'   require("dplyr")
#'   require("reshape2")
#'
#'   aafractions.ncc::lu_aac_icd10 %>%
#'     merge(aafractions.ncc::aa_versions, by = "condition_uid", allow.cartesian = TRUE) %>%
#'     dcast(... ~ Version, value.var = "condition_uid", fun = paste, collapse = "|") %>%
#'     arrange(icd10) %>%
#'     head(16)
#' }
"lu_aac_icd10"
