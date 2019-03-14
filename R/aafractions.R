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

# TO keep check happy for field names
globalVariables(c(
    # create__dummy_hesip
    "Diagnosis_ICD_Concatenated_D"
    , "Age_at_Start_of_Episode_D"
    , "Consultant_Episode_End_Date"
    , "Episode_Duration_from_Grouper"
    , "Local_Authority_District"
    , "GIS_LSOA_2011_D"
    # create_lu_ageband : ab_labels_from_breaks
    , "from"
    , "to"
    , "lab"
    , "s_sta"
    , "s_end"
    # create_lu_ageband
    , "age"
    # example_analysis
    , "Episode_Status"
    , "Patient_Classification"
    , "Generated_Record_Identifier"
    , "."
    , "GRID"
    , "pos"
    , "icd10"
    , "genderC"
    , "ab_aaf"
    , "analysis_type"
    , "aaf"
    , "aa_rank_1_highest"
    , "Consultant_Episode_Number"
    , "aa_aa_rank_1_highest"
    # example_analysis: main__example_analysis__sa_morbidity
    , "Diagnosis_ICD_1"
    , "ab_sa"
    , "sp"
    , "meta_calyear"
    , "calyear"
    , "multiplier"
    , "srr"
    # example_analysis: main__example_analysis__uc_morbidity
    , "Admission_Method_Code"
    , "ab_uc"
    # vignettes : counting_aa_events
    , "version"
))
