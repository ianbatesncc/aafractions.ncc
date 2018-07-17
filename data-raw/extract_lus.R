#
# Script to extract tables from .xlsx
#
#

#' extract data from xl
#'
#' Pull in tables from worksheets.
#' Split each table into
#'  - list of conditions
#'  - condition to age, gender
#' Melt on age and gender
#' Save as data
#'
#' @param bWriteCSV Flag to indicate to write data to file
#'
#' @return list(lu_conditions, lu_versions, lu_fractions)
#'

main__extract <- function(
    bWriteCSV = FALSE
) {

    require("readxl")
    require("dplyr")
    require("data.table")

    # load tables as list of tables

    this_wb = "./data-raw/aafraction_lus.xlsx"

    these_wss <- readxl::excel_sheets(path = this_wb)

    wss <- setdiff(these_wss, "Tables") %>%
        lapply(
            function(x, y) {
                cat("INFO: reading sheet", x, "...", "\n")
                readxl::read_excel(path = y, sheet = x, skip = 5, col_names = TRUE)
            }, this_wb
        )

    names(wss) <- setdiff(these_wss, "Tables")

    # combine tables

    lus <- wss %>% bind_rows()

    # add condition id number
    #
    # Globally unique across all version
    # (cat1, cat2, desc, codes) as key
    # fucid - factor
    # gucid - numeric

    lus <- lus %>%
        filter(!grepl("^§", desc)) %>%
        mutate_if(is.character, as.factor) %>%
        mutate(condition_fuid = interaction(cat1, cat2, desc, codes, drop = TRUE)) %>%
        arrange(sortkey, codes, desc(Version)) %>%
        mutate(
            condition_fuid = factor(condition_fuid, levels = unique(condition_fuid), ordered = TRUE)
            , condition_uid = as.integer(condition_fuid)
        )

    # Globally each condition, across all versions, has a unique (cat1, cat2, description, codes) key.
    # One condition can exist in multiple version differing by alcohol fractions
    # {set of conditions} 1:many {set of versions} 1:1 {set of attributable fractions}
    # conditions: KEY:(gucid), VALUES: (cat1, cat2, desc, codes)
    # versions: KEY:(version, gucid)
    # fractions: KEY:(version, gucid, gender, sex) VALUES: (aaf)

    # list of conditions
    # drops Version, analysis_type, sortkey

    lu_conditions <- lus %>%
        select(-dplyr::matches(":[MF]")) %>%
        select(-Version, -analysis_type, -sortkey) %>% unique()

    # conditions
    # unique on cat1, cat2, description, codes
    # Can be mapped to more than one version
    #

    lu_versions <- lus %>%
        select(Version, condition_fuid, condition_uid) %>%
        arrange(desc(Version), condition_fuid)

    # list of fractions
    # Includes Version

    lu_fractions <- lus %>%
        select(Version, condition_fuid, condition_uid, analysis_type, dplyr::matches(":[MF]")) %>%
        data.table::setDT() %>%
        data.table::melt(
            measure.vars = patterns(":[MF]")
            , value.name = "aaf"
        ) %>%
        .[, c("aa_ageband", "sex") := data.table::tstrsplit(variable, ":")] %>%
        select(-variable) %>%
        data.table::dcast(... ~ analysis_type, value.var = "aaf", fun = sum, fill = NA) %>%
        .[!is.na(all), `:=`(morbidity = all, mortality = all)] %>%
        select(-all) %>%
        data.table::melt(
            measure.vars = c("mortality", "morbidity")
            , value.name = "aaf"
            , variable.name = "analysis_type", variable.factor = FALSE
        )

    # save

    lu_conditions <- lu_conditions %>%
        arrange(condition_fuid)

    lu_versions <- lu_versions %>%
        arrange(Version, condition_fuid)

    lu_fractions <- lu_fractions %>%
        arrange(Version, condition_fuid, analysis_type, sex, aa_ageband)

    # save

    if (bWriteCSV) {
        data.table::fwrite(lu_conditions, "./data-raw/lu_conditions.csv")
        devtools::use_data(lu_conditions, overwrite = TRUE)

        data.table::fwrite(lu_versions, "./data-raw/lu_versions.csv")
        devtools::use_data(lu_versions, overwrite = TRUE)

        data.table::fwrite(lu_fractions, "./data-raw/lu_fractions.csv")
        devtools::use_data(lu_fractions, overwrite = TRUE)
    }

    invisible(list(
        lu_conditions = lu_conditions
        , lu_versions = lu_versions
        , lu_fractions = lu_fractions
    ))
}

main__extract(TRUE)
