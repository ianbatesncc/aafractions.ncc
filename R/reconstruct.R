#
#
#

#' Reconstruct tables
#'
#' Reconstruct alcohol attributable fractions table for given version and analysis type.
#'
#' @param this_version table version to reconstruct
#' @param this_analysistype specify analysis type: either morbidity or mortality
#'
#' @import dplyr
#' @importFrom data.table dcast
#'
#' @export
#'
reconstruct <- function(
    this_version = c("aaf_2017_phe", "aaf_2014_ljucph", "aaf_2008_ljucph", "aaf_2007_ni39")
    , this_analysistype = c("morbidity", "mortality")
) {
    this_version <- match.arg(this_version)
    this_analysistype <- match.arg(this_analysistype)

    cat("INFO: reconstruct: (version, analysis_type) = ("
        , paste(this_version, this_analysistype, sep = ", "), ")"
        , "\n")

    this_table <- aafractions.ncc::lu_versions %>%
        filter(Version == this_version) %>%
        merge(
            aafractions.ncc::lu_conditions %>% select(-condition_uid)
            , by = "condition_fuid"
        ) %>%
        mutate(analysis_type = this_analysistype) %>%
        merge(
            aafractions.ncc::lu_fractions %>% select(-condition_uid)
            , by = c("Version", "analysis_type", "condition_fuid")
        ) %>%
        data.table::dcast(... ~ aa_ageband + sex, value.var = "aaf", fun = sum)

    invisible(this_table)
}
