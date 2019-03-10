#' Reconstruct lu tables
#'
#' Reconstruct alcohol attributable fractions table for given version and
#' analysis type.
#'
#' @param this_version table version to reconstruct
#' @param this_analysistype specify analysis type: either morbidity or mortality
#' @param verbose show messages about which table is being reconstructed
#' @param molten boolean to indicate cast or molten on (sex, ageband)
#'
#' @import dplyr
#' @importFrom data.table setDT dcast.data.table
#'
#' @examples
#'
#' t1 <- reconstruct("aaf_2017_phe", "morbidity")
#' str(t1)
#'
#' t2 <- reconstruct("aaf_2017_phe", "morbidity", molten = TRUE)
#' str(t2)
#'
#'
#' @export
#'
reconstruct <- function(
    this_version = c(
        "aaf_2017_phe"
        , "aaf_2014_ljucph"
        , "aaf_2008_ljucph"
        , "aaf_2007_ni39"
    )
    , this_analysistype = c("morbidity", "mortality")
    , verbose = TRUE
    , molten = FALSE
) {
    this_version <- match.arg(this_version)
    this_analysistype <- match.arg(this_analysistype)

    if (verbose) {
        cat(
            "INFO: reconstruct: (version, analysis_type) = ("
            , paste(this_version, this_analysistype, sep = ", "), ")"
            , "\n"
        )
    }

    this_table <- aafractions.ncc::aa_versions %>%
        filter(version == this_version) %>%
        merge(aafractions.ncc::aa_conditions, by = "condition_uid") %>%
        mutate(analysis_type = this_analysistype) %>%
        merge(
            aafractions.ncc::aa_fractions
            , by = c("version", "analysis_type", "condition_uid")
        )

    if (!molten) {
        this_table <- this_table %>%
            data.table::setDT() %>%
            data.table::dcast.data.table(
                ... ~ aa_ageband + sex, value.var = "aaf", fun = sum
            ) %>%
            as.data.frame()
    }

    this_table
}
