#
# data.R
#

#' Alcohol datasets
#'
#' @name alcohol_datasets
#' @family alcohol datasets
NULL

#' Smoking datasets
#'
#' @name smoking_datasets
#' @family smoking datasets
NULL

#
# Alcohol
#

#' List of alcohol attributable conditions
#'
#' Provides lookup tables for use with alcohol attributable fractions analyses.
#'
#' @format data frame with 69 rows and 7 fields
#'
#' \preformatted{
#' Classes ‘tbl_df’, ‘tbl’ and 'data.frame':	69 obs. of  7 variables:
#' $ cat1         : Factor w/ 3 levels "Partially attributable conditions - acute conditions",..: 3 3 3 3 3 3 3 3 3 3 ...
#' $ cat2         : Factor w/ 12 levels "Cardiovascular disease",..: 12 12 12 12 12 12 12 12 12 12 ...
#' $ desc         : Factor w/ 66 levels "Accidental excessive cold",..: 7 47 19 12 11 8 9 10 5 6 ...
#' $ attribution  : logi  NA NA NA NA NA NA ...
#' $ cause        : logi  NA NA NA NA NA NA ...
#' $ codes        : Factor w/ 68 levels "A15-A19","C00-C14",..: 11 12 13 15 16 19 27 28 34 35 ...
#' $ condition_uid: int  1 2 3 4 5 6 7 8 9 10 ...
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
#' @family alcohol datasets
#'
"aa_conditions"


#' List of alcohol attributable fractions by condition, age and sex
#'
#' Provides lookup tables for use with alcohol attributable fractions analyses.
#'
#' @format data frame with 185 rows and 2 fields
#'
#' \preformatted{
#' Class 'data.frame':	185 obs. of  2 variables:
#' $ version      : Factor w/ 4 levels "aaf_2007_ni39",..: 1 1 1 1 1 1 1 1 1 1 ...
#' $ condition_uid: int  1 2 3 4 5 6 7 10 13 14 ...
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
#' @family alcohol datasets
#'
"aa_versions"


#' List of alcohol attributable fractions by condition, age and sex
#'
#' Provides lookup tables for use with alcohol attributable fractions analyses.
#'
#' @format data frame with 5,920 rows and 7 fields
#'
#' \preformatted{
#' 'data.frame':	5920 obs. of  6 variables:
#' $ version      : Factor w/ 4 levels "aaf_2007_ni39",..: 1 1 1 1 1 1 1 1 1 1 ...
#' $ condition_uid: int  1 1 1 1 1 1 1 1 1 1 ...
#' $ aa_ageband   : chr  "00-15 Yrs" "16-24 Yrs" "25-34 Yrs" "35-44 Yrs" ...
#' $ sex          : chr  "F" "F" "F" "F" ...
#' $ analysis_type: chr  "morbidity" "morbidity" "morbidity" "morbidity" ...
#' $ aaf          : num  1 1 1 1 1 1 1 1 1 1 ...
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
#' @family alcohol datasets
#'
"aa_fractions"

#' Lookup between alcohol attributable conditions and icd10 codes
#'
#' Provides lookup tables for use with alcohol attributable fractions analyses.
#'
#' @format data frame with 69 rows and 7 fields
#'
#' \preformatted{
#' 'data.frame':	5920 obs. of  6 variables:
#' $ version      : Factor w/ 4 levels "aaf_2007_ni39",..: 1 1 1 1 1 1 1 1 1 1 ...
#' $ condition_uid: int  1 1 1 1 1 1 1 1 1 1 ...
#' $ aa_ageband   : chr  "00-15 Yrs" "16-24 Yrs" "25-34 Yrs" "35-44 Yrs" ...
#' $ sex          : chr  "F" "F" "F" "F" ...
#' $ analysis_type: chr  "morbidity" "morbidity" "morbidity" "morbidity" ...
#' $ aaf          : num  1 1 1 1 1 1 1 1 1 1 ...
#' }
#'
#' #' @examples
#' if (all(sapply(c("dplyr", "reshape2"), isNamespaceLoaded))) {
#'   require("dplyr")
#'   require("reshape2")
#'
#'   aafractions.ncc::lu_aac_icd10 %>%
#'     merge(aafractions.ncc::aa_versions, by = "condition_uid", allow.cartesian = TRUE) %>%
#'     dcast(... ~ version, value.var = "condition_uid", fun = paste, collapse = "|") %>%
#'     arrange(icd10) %>%
#'     head(16)
#' }
#'
#' @family alcohol datasets
#'
"lu_aac_icd10"

#
# Smoking
#

#' List of smoking attributable conditions
#'
#' Provides lookup tables for use with smoking attributable fractions analyses.
#'
#' # @format data frame with 26 rows and 4 fields
#'
#' \preformatted{
#' Observations: 26
#' Variables: 4
#' $ cat1             <fct> Cancers which can be caused by smoking, Cancers which can be caused by smoking, Cancer...
#' $ disease_category <fct> "Trachea, Lung, Bronchus", "Upper respiratory sites", "Oesophagus", "Larynx", "Cervica...
#' $ icd_10_code      <fct> "C33-C34", "C00-C14", "C15", "C32", "C53", "C67", "C64-C66,C68", "C16", "C25", "C80", ...
#' $ condition_uid    <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,...
#' }
#'
#' @examples
#' if (isNamespaceLoaded("magrittr")) {
#'   require("magrittr")
#'
#'   aafractions.ncc::sa_conditions %>%
#'     head(16)
#' }
#'
#' @family smoking datasets
#'
"sa_conditions"


#' List of smoking attributable conditions by version
#'
#' Provides lookup tables for use with alcohol attributable fractions analyses.
#'
#' @format data frame with 26 rows and 2 fields
#'
#' \preformatted{
#' Observations: 26
#' Variables: 2
#' $ version       <chr> "nhsd_ss_2018", "nhsd_ss_2018", "nhsd_ss_2018", "nhsd_ss_2018", "nhsd_ss_2018", "nhsd_ss_...
#' $ condition_uid <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25...
#' }
#'
#' @examples
#' if (isNamespaceLoaded("dplyr")) {
#'   require("dplyr")
#'
#'   aafractions.ncc::sa_versions %>%
#'     dplyr::mutate_if(is.character, as.factor) %>%
#'     dplyr::select(-starts_with("condition_")) %>%
#'     summary(16)
#' }
#'
#' @family alcohol datasets
#'
"sa_versions"

#' List of smoking relative risks by condition, age and sex
#'
#' Provides lookup tables for use with smoking attributable fractions analyses.
#'
#' @format data frame with 1,016 rows and 8 fields
#'
#' \preformatted{
#' Observations: 1,016
#' Variables: 8
#' $ age            <fct> 35 - 54, 35 - 54, 35 - 54, 35 - 54, 35 - 54, 35 - 54, 35 - 54, 35 - 54, 35 - 54, 35 - 54...
#' $ condition_uid  <int> 16, 16, 16, 16, 16, 16, 16, 16, 18, 18, 18, 18, 18, 18, 18, 18, 14, 14, 14, 14, 14, 14, ...
#' $ sex            <chr> "men", "men", "men", "men", "women", "women", "women", "women", "men", "men", "men", "me...
#' $ smoking_status <chr> "current", "current", "ex", "ex", "current", "current", "ex", "ex", "current", "current"...
#' $ ab_sa_explode  <chr> "35 - 44", "45 - 54", "35 - 44", "45 - 54", "35 - 44", "45 - 54", "35 - 44", "45 - 54", ...
#' $ analysis_type  <chr> "morbidity", "morbidity", "morbidity", "morbidity", "morbidity", "morbidity", "morbidity...
#' $ srr            <dbl> 4.20, 4.20, 2.00, 2.00, 5.30, 5.30, 2.60, 2.60, 4.40, 4.40, 1.10, 1.10, 5.40, 5.40, 1.30...
#' $ version        <chr> "nhsd_ss_2018", "nhsd_ss_2018", "nhsd_ss_2018", "nhsd_ss_2018", "nhsd_ss_2018", "nhsd_ss...#'
#' }
#'
#' @examples
#' if (isNamespaceLoaded("dplyr")) {
#'   require("dplyr")
#'
#'   aafractions.ncc::sa_relrisk %>%
#'     mutate_if(is.character, as.factor) %>%
#'     select(-starts_with("condition_")) %>%
#'     summary(16)
#' }
#'
#' @family smoking datasets
#'
"sa_relrisk"


#' Lookup between Smoking attributable conditions and icd10 codes
#'
#' Provides lookup tables for use with smoking relative risks / attributable
#' fractions analyses.
#'
#' @format data frame with 1,335 rows and 2 fields
#'
#' \preformatted{
#' Observations: 1,335
#' Variables: 2
#' $ condition_uid <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2,...
#' $ icd10         <chr> "C330", "C331", "C332", "C333", "C334", "C335", "C336", "C337", "C338", "C339", "C33X", "...
#' }
#'
#' #' @examples
#' if (all(sapply(c("dplyr", "reshape2"), isNamespaceLoaded))) {
#'   require("dplyr")
#'   require("reshape2")
#'
#'   aafractions.ncc::lu_sac_icd10 %>%
#'     merge(aafractions.ncc::sa_conditions, by = "condition_uid", allow.cartesian = TRUE) %>%
#'     dcast(... ~ version, value.var = "condition_uid", fun = paste, collapse = "|") %>%
#'     arrange(icd10) %>%
#'     head(16)
#' }
#'
#' @family smoking datasets
#'
"lu_sac_icd10"


#' Lookup for smoking prevalence
#'
#' To be combined with relative risk to arrive at attributable fraction
#'
#' @format data frame with 19,012 rows and 9 fields
#'
#' \preformatted{
#' Observations: 19,012
#' Variables: 9
#' $ smoking_status <chr> "current", "current", "current", "current", "current", "current", "current", "current", ...
#' $ calyear        <int> 2011, 2011, 2011, 2011, 2011, 2011, 2011, 2011, 2011, 2011, 2011, 2011, 2011, 2011, 2011...
#' $ area_code      <chr> "E92000001", "E92000001", "E92000001", "E92000001", "E92000001", "E92000001", "E92000001...
#' $ area_name      <chr> "England", "England", "England", "England", "England", "England", "England", "England", ...
#' $ area_type      <chr> "England", "England", "England", "England", "England", "England", "England", "England", ...
#' $ sex            <chr> "M", "F", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P"...
#' $ age            <chr> "18+ yrs", "18+ yrs", "25-29 yrs", "30-34 yrs", "35-39 yrs", "40-44 yrs", "45-49 yrs", "...
#' $ value          <dbl> 22.1785, 17.6335, 27.1005, 24.1422, 23.3574, 22.5773, 21.5718, 20.1515, 19.4923, 16.2628...
#' $ version        <chr> "phe_ltcp_201903", "phe_ltcp_201903", "phe_ltcp_201903", "phe_ltcp_201903", "phe_ltcp_20...
#' }
#'
#' @examples
#' head(sp)
#'
#' @family smoking datasets
#'
"sp"
