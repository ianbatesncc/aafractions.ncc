#' aafractions.ncc: Alcohol Attributable Fractions Lookup Tables
#'
#' Provides lookup tables for use with alcohol attributable fractions analyses.
#'
#' @section Functions:
#'
#' \code{\link{reconstruct}}
#'
#'
# @import dplyr
# @importFrom data.table setDT dcast.data.table
#'
#' @docType package
#' @name aafractions.ncc
#'
NULL

if (TRUE) {
    # To keep check happy for field names
    globalVariables(c(
        "."
        , "aa_rank_1_highest"
        , "aaf"
        , "ab_aaf"
        , "ab_sa"
        , "ab_uc"
        , "ADMISORC"
        , "Admission_Method_Code"
        , "af"
        , "age"
        , "Age_at_Start_of_Episode_D"
        , "analysis_type"
        , "attribution_type"
        , "calyear"
        , "cat1"
        , "cat2"
        , "condition_uid"
        , "Consultant_Episode_End_Date"
        , "Consultant_Episode_Number"
        , "Consultant_Episode_Start_Date"
        , "Diagnosis_ICD_1"
        , "Diagnosis_ICD_Concatenated_D"
        , "Episode_Duration_from_Grouper"
        , "Episode_Status"
        , "from"
        , "genderC"
        , "Generated_Record_Identifier"
        , "GIS_LSOA_2011_D"
        , "GRID"
        , "icd10"
        , "icd10_prim"
        , "icd10_sec"
        , "lab"
        , "Local_Authority_District"
        , "matches_proc_exclude"
        , "matches_sec_diag_exclude"
        , "matches_sec_diag_include"
        , "meta_admeth"
        , "meta_calyear"
        , "multiplier"
        , "opcs_all"
        , "Patient_Classification"
        , "pos"
        , "proc_exclude_regexp"
        , "Procedure_OPCS_Concatenated_D"
        , "s_end"
        , "s_sta"
        , "sec_diag_exclude_regexp"
        , "sec_diag_include_regexp"
        , "sp"
        , "srr"
        , "to"
        , "to_include"
    ))
}

if (FALSE) {
    # output from devtools::check()
    strsplit(
        gsub("\n", " ", "
. ADMISORC Admission_Method_Code Age_at_Start_of_Episode_D
Consultant_Episode_End_Date Consultant_Episode_Number
Consultant_Episode_Start_Date Diagnosis_ICD_1
Diagnosis_ICD_Concatenated_D Episode_Duration_from_Grouper
Episode_Status GIS_LSOA_2011_D GRID Generated_Record_Identifier
Local_Authority_District Patient_Classification
Procedure_OPCS_Concatenated_D aa_rank_1_highest aaf ab_aaf ab_sa
ab_uc af age analysis_type attribution_type calyear cat1 cat2
condition_uid from genderC icd10 icd10_prim icd10_sec lab
matches_proc_exclude matches_sec_diag_exclude
matches_sec_diag_include meta_admeth meta_calyear multiplier opcs_all
pos proc_exclude_regexp s_end s_sta sec_diag_exclude_regexp
sec_diag_include_regexp sp srr to to_include
")
        , split = c(" ", "\n")
    ) %>%
        unlist() %>%
        unique() %>%
        sort() %>%
        lapply(function(x) {cat(paste0(", \"", x, "\""), "\n")}) %>%
        invisible()
}
