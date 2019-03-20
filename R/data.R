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

#' Urgent care sensitive datasets
#'
#' @name ucs_datasets
#' @family urgent care sensitive datasets
NULL

#' Ambulatory care sensitive Emergency datasets
#'
#' @name acs_datasets
#' @family ambulatory care sensitive datasets
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


#' List of alcohol attributable conditions by version
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
#' @examples
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
#' @examples
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

#
# Urgent care sensitive
#

#' List of Urgent care sensitive conditions
#'
#' Provides lookup tables for use with Urgent care sensitive analyses.
#'
#' @format data frame with 14 rows and 7 fields
#'
#' \preformatted{
#' Observations: 14
#' Variables: 7
#' $ condition_description <chr> "COPD", "Acute mental health crisis", "Non-specific chest pain", "Falls", "Non-specific abdomin...
#' $ primary_diagnosis     <chr> "J40; J41; J42; J43; J44", "F", "R072; R073; R074", "W0; W1-W19", "R10", "I80; I81; I82", "L03"...
#' $ age                   <chr> "All ages", "All ages", "All ages", "75+ yrs", "All ages", "All ages", "All ages", "0 - 5 yrs",...
#' $ primary_regex         <chr> "J4[0-4]", "F", "R07[2-4]", "W[01][0-9]", "R10", "I8[0-2]", "L03", "R50", "T830", "E1[0-5];E16[...
#' $ cat1                  <chr> "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All"
#' $ cat2                  <chr> "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All", "All"
#' $ condition_uid         <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
#' }
#'
#' @examples
#' if (isNamespaceLoaded("dplyr")) {
#'   require("dplyr")
#'
#'   aafractions.ncc::uc_conditions %>%
#'     mutate_if(is.character, as.factor) %>%
#'     select(-starts_with("condition_"), -starts_with("primary")) %>%
#'     summary(16)
#' }
#'
#' @family urgent care sensitive datasets
#'
"uc_conditions"


#' List of Urgent care sensitive conditions by version
#'
#' Provides lookup tables for use with Urgent care sensitive analyses.
#'
#' @format data frame with 14 rows and 2 fields
#'
#' \preformatted{
#' Observations: 14
#' Variables: 2
#' $ version       <chr> "ccg_iaf_201617", "ccg_iaf_201617", "ccg_iaf_201617", "ccg_iaf_201617", "ccg_iaf_201617", "ccg_iaf_2016...
#' $ condition_uid <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
#' }
#'
#' @examples
#' if (isNamespaceLoaded("dplyr")) {
#'   require("dplyr")
#'
#'   aafractions.ncc::uc_versions %>%
#'     mutate_if(is.character, as.factor) %>%
#'     select(-starts_with("condition_")) %>%
#'     summary(16)
#' }
#'
#' @family urgent care sensitive datasets
#'
"uc_versions"


#' List of Urgent care sensitive fractions by condition and age
#'
#' Provides lookup tables for use with Urgent care sensitive analyses.
#'
#' @format data frame with 38 rows and 4 fields
#'
#' \preformatted{
#' Observations: 38
#' Variables: 8
#' $ ab_ucs                <chr> "0 - 5 yrs", "75+ yrs", "All ages", "All ages", "All ages", "All ages", "All ages", "All ages",...
#' $ condition_description <chr> "Pyrexial child", "Falls", "COPD", "COPD", "COPD", "Acute mental health crisis", "Acute mental ...
#' $ primary_diagnosis     <chr> "R50", "W0; W1-W19", "J40; J41; J42; J43; J44", "J40; J41; J42; J43; J44", "J40; J41; J42; J43;...
#' $ primary_regex         <chr> "R50", "W[01][0-9]", "J4[0-4]", "J4[0-4]", "J4[0-4]", "F", "F", "F", "R07[2-4]", "R07[2-4]", "R...
#' $ condition_uid         <int> 8, 4, 1, 1, 1, 2, 2, 2, 3, 3, 3, 12, 12, 12, 5, 5, 5, 6, 6, 6, 7, 7, 7, 9, 9, 9, 10, 10, 10, 11...
#' $ version               <chr> "ccg_iaf_201617", "ccg_iaf_201617", "ccg_iaf_201617", "ccg_iaf_201617", "ccg_iaf_201617", "ccg_...
#' $ ab_ucs_explode        <chr> "0 - 5 yrs", "75+ yrs", "0 - 5 yrs", "6 - 74 yrs", "75+ yrs", "0 - 5 yrs", "6 - 74 yrs", "75+ y...
#' $ ucs_af                <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,...
#' }
#'
#' @examples
#' if (all(sapply(c("dplyr", "reshape2"), isNamespaceLoaded))) {
#'   require("dplyr", warn.conflicts = FALSE)
#'   require("reshape2", warn.conflicts = FALSE)
#'
#'   uc_attribution %>%
#'     dcast(
#'       condition_uid + condition_description ~ ab_ucs_explode
#'       , value.var = "ucs_af", fill = 0
#'     )
#' }
#'
#' @family urgent care sensitive datasets
#'
"uc_attribution"


#' Lookup between Urgent care sensitive conditions and icd10 codes
#'
#' Provides lookup tables for use with Urgent care sensitive analyses.
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
#' @examples
#' if (all(sapply(c("dplyr", "reshape2"), isNamespaceLoaded))) {
#'   require("dplyr", warn.conflicts = FALSE)
#'   require("reshape2", warn.conflicts = FALSE)
#'
#'   aafractions.ncc::lu_ucc_icd10 %>%
#'     merge(aafractions.ncc::uc_versions, by = "condition_uid", allow.cartesian = TRUE) %>%
#'     dcast(... ~ version, value.var = "condition_uid", fun = paste, collapse = "|") %>%
#'     arrange(icd10) %>%
#'     head(16)
#' }
#'
#' @family urgent care sensitive datasets
#'
"lu_ucc_icd10"

#
# Ambulatory care sensitive emergency
#

#' List of Ambulatory care sensitive conditions
#'
#' Provides lookup tables for use with Ambulatory care sensitive analyses.
#'
#' @format data frame with 13 rows and 12 fields
#'
#' \preformatted{
#' Observations: 13
#' Variables: 12
#' $ cat1                  <chr> "Cardiovascular diseases", "Cardiovascular diseases", "Cardiovascular diseases", "Card...
#' $ cat2                  <chr> "Atrial Fibrillation", "Angina", "Chronic heart disease", "Congestive heart failure", ...
#' $ condition_description <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#' $ age                   <chr> "All ages", "All ages", "All ages", "All ages", "All ages", "All ages", "All ages", "A...
#' $ primary_diagnosis     <chr> "I48", "I20", "I25", "I50;I11.0;J81X;I13.0", "I10X;I11.9", "D51-D52;D50.1;D50.8;D50.9"...
#' $ secondary_diagnoses   <chr> NA, NA, NA, NA, NA, NA, "-D57", NA, NA, NA, NA, "J41-44;J47", NA
#' $ procedures            <chr> NA, "-A-W;-X0-X5", "-A-W;-X0-X5", "-K0-K4;-K50;-K52;-K55-K57;-K60-61;-K67-69;-K71;-K73...
#' $ prim_diag_regexp      <chr> "I48", "I20", "I25", "I50|I110|J81X|I130", "I10X|I119", "D5[12]|D50[189]", "B18[01]", ...
#' $ proc_regex            <chr> NA, "[A-W]|X[0-5]", "[A-W]|X[0-5]", "K[0-4]|K5[025-7]|K6[016-9]|K7[134]", "K[0-4]|K5[0...
#' $ sec_diag_regex        <chr> NA, NA, NA, NA, NA, NA, "-D57", NA, NA, NA, NA, "J4[12347]", NA
#' $ condition_uid         <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
#' $ version               <chr> "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "c...
#' }
#'
#' @examples
#' if (isNamespaceLoaded("dplyr")) {
#'   require("dplyr")
#'
#'   aafractions.ncc::ac_conditions %>%
#'     mutate_if(is.character, as.factor) %>%
#'     select(-starts_with("condition_"), -starts_with("primary")) %>%
#'     summary(16)
#' }
#'
#'
#' @family ambulatory care sensitive datasets
#'
"ac_conditions"

#' List of Ambulatory care sensitive conditions by version
#'
#' Provides lookup tables for use with Ambulatory care sensitive analyses.
#'
#' @format data frame with 13 rows and 2 fields
#'
#' \preformatted{
#' Observations: 13
#' Variables: 2
#' $ version       <chr> "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_2...
#' $ condition_uid <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
#' }
#'
#' @examples
#' if (isNamespaceLoaded("dplyr")) {
#'   require("dplyr")
#'
#'   aafractions.ncc::ac_versions %>%
#'     mutate_if(is.character, as.factor) %>%
#'     select(-starts_with("condition_")) %>%
#'     summary(16)
#' }
#'
#'
#' @family ambulatory care sensitive datasets
#'
"ac_versions"

#' List of Ambulatory care sensitive fractions by condition and age
#'
#' Provides lookup tables for use with Ambulatory care sensitive analyses.
#'
#' @format data frame with 13 rows and 3 fields
#'
#' \preformatted{
#' Observations: 13
#' Variables: 3
#' $ condition_uid <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
#' $ version       <chr> "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_26", "ccg_ois_2...
#' $ acs_af        <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
#' }
#'
#' @examples
#' if (all(sapply(c("dplyr", "reshape2"), isNamespaceLoaded))) {
#'   require("dplyr", warn.conflicts = FALSE)
#'   require("reshape2", warn.conflicts = FALSE)
#'
#'   ac_attribution %>%
#'     dcast(
#'       condition_uid + condition_description ~ ab_ucs_explode
#'       , value.var = "ucs_af", fill = 0
#'     )
#' }
#'
#'
#' @family ambulatory care sensitive datasets
#'
"ac_attribution"

#' Lookup between Ambulatory care sensitive conditions and icd10 codes
#'
#' Provides lookup tables for use with Ambulatory care sensitive analyses.
#' Primary condition: primary diagnosis codes.
#'
#' @format data frame with 277 rows and 2 fields
#'
#' \preformatted{
#' Observations: 277
#' Variables: 2
#' $ condition_uid <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,...
#' $ icd10         <chr> "I480", "I481", "I482", "I483", "I484", "I485", "I486", "I487", "I488", "I489", "I48X", "I48", "I200", "...
#' }
#'
#' @examples
#' if (all(sapply(c("dplyr", "reshape2"), isNamespaceLoaded))) {
#'   require("dplyr", warn.conflicts = FALSE)
#'   require("reshape2", warn.conflicts = FALSE)
#'
#'   aafractions.ncc::lu_acc_icd10 %>%
#'     merge(aafractions.ncc::ac_versions, by = "condition_uid", allow.cartesian = TRUE) %>%
#'     dcast(... ~ version, value.var = "condition_uid", fun = paste, collapse = "|") %>%
#'     arrange(icd10) %>%
#'     head(16)
#' }
#'
#' @examples
#' str(aafractions.ncc::lu_acc_icd10)
#'
#' @family ambulatory care sensitive datasets
#'
"lu_acc_icd10"

#' Lookup between Ambulatory care sensitive conditions and icd10 codes
#'
#' Provides lookup tables for use with Ambulatory care sensitive analyses.
#' Secondary condition: secondary diagnosis codes.
#'
#' @format data frame with 60 rows and 2 fields
#'
#' \preformatted{
#' Observations: 60
#' Variables: 2
#' $ condition_uid <int> 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, ...
#' $ icd10         <chr> "J410", "J411", "J412", "J413", "J414", "J415", "J416", "J417", "J418", "J419", "J41X", "J41", "J420", "...
#' }
#'
#' @examples
#' str(aafractions.ncc::lu_acc_icd10_sec)
#'
#' @family ambulatory care sensitive datasets
#'
NULL
# "lu_acc_icd10_sec"

#' Lookup between Ambulatory care sensitive conditions and icd10 codes
#'
#' Provides lookup tables for use with Ambulatory care sensitive analyses.
#' Tertiary condition: procedure codes.
#'
#' @format data frame with 0 rows and 2 fields
#'
#' \preformatted{
#' Observations: 0
#' Variables: 2
#' $ condition_uid <int>
#' $ icd10         <chr>
#' }
#'
#' @examples
#' str(aafractions.ncc::lu_acc_opcs)
#'
#' @family ambulatory care sensitive datasets
#'
NULL
# "lu_acc_opcs"
