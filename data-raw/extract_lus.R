#
# Script to extract tables from .xlsx
#

#' Extract data from xl
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
#' Each worksheet contains a table, one row for each condition (with metadata)
#' and (age, sex) specific attributable fractions in additional column fields.
#'
#' @return list(lu_conditions, lu_versions, lu_fractions)
#'

extract_aa <- function(
    bWriteCSV = FALSE
) {

    require("readxl")
    require("dplyr")
    require("data.table")

    # load tables as list of tables

    this_wb = devtools::package_file("./data-raw/aafraction_lus.xlsx")

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
    #
    # generate key, sort, reorder key

    lus <- lus %>%
        filter(!grepl("^§", desc)) %>%
        mutate_if(is.character, as.factor) %>%
        mutate(
            condition_fuid = interaction(cat1, cat2, desc, codes, drop = TRUE)
        ) %>%
        arrange(sortkey, codes, desc(Version)) %>%
        mutate(
            condition_fuid = factor(
                condition_fuid
                , levels = unique(condition_fuid)
                , ordered = TRUE
            )
            , condition_uid = as.integer(condition_fuid)
        )

    # Globally each condition, across all versions, has a unique (cat1, cat2, description, codes) key.
    # One condition can exist in multiple version differing by alcohol fractions
    # {set of conditions} 1:many {set of versions} 1:1 {set of attributable fractions}
    # conditions: KEY:(gucid), VALUES: (cat1, cat2, desc, codes)
    # versions: KEY:(version, gucid)
    # fractions: KEY:(version, gucid, gender, sex) VALUES: (aaf)

    # list of conditions
    #
    # unique on cat1, cat2, description, codes
    # Can be mapped to more than one version
    #
    # Keep categories and codes
    # Drop Version, analysis_type, sortkey, aafs

    aa_conditions <- lus %>%
        select(-dplyr::matches(":[MF]")) %>%
        select(-Version, -analysis_type, -sortkey, -condition_fuid) %>%
        unique()

    # versions
    #
    # Keep Version, condition_uid
    # Drop analysis_type

    aa_versions <- lus %>%
        select(Version, condition_uid) %>%
        unique() %>%
        arrange(desc(Version), condition_uid)

    # list of fractions
    #
    # Keep Version, condition_uid, ageband, sex, analysis_type and aaf
    # Need to do some work to melt ageband_sex fields
    # ... and do something clever to get 'all' mapped to the other analysis
    # types

    aa_fractions <- lus %>%
        select(
            Version
            , condition_uid
            , analysis_type
            , dplyr::matches(":[MF]")
        ) %>%
        # melt the af fields
        data.table::setDT() %>%
        data.table::melt(
            measure.vars = patterns(":[MF]")
            , value.name = "aaf"
        ) %>%
        .[, c("aa_ageband", "sex") := data.table::tstrsplit(variable, ":")] %>%
        select(-variable) %>%
        data.table::dcast.data.table(
            ... ~ analysis_type
            , value.var = "aaf"
            , fun = sum
            , fill = NA
        ) %>%
        # deal "all" out to other analysis types
        .[!is.na(all), `:=`(morbidity = all, mortality = all)] %>%
        select(-all) %>%
        data.table::melt(
            measure.vars = c("mortality", "morbidity")
            , value.name = "aaf"
            , variable.name = "analysis_type", variable.factor = FALSE
        )

    # store

    aa_conditions <- aa_conditions %>%
        arrange(condition_uid)

    aa_versions <- aa_versions %>%
        arrange(Version, condition_uid)

    aa_fractions <- aa_fractions %>%
        arrange(Version, condition_uid, analysis_type, sex, aa_ageband)

    # save

    if (bWriteCSV) {
        data.table::fwrite(aa_conditions, "./data-raw/aa_conditions.csv")
        usethis::use_data(aa_conditions, overwrite = TRUE)

        data.table::fwrite(aa_versions, "./data-raw/aa_versions.csv")
        usethis::use_data(aa_versions, overwrite = TRUE)

        data.table::fwrite(aa_fractions, "./data-raw/aa_fractions.csv")
        usethis::use_data(aa_fractions, overwrite = TRUE)
    }

    invisible(list(
        aa_conditions = aa_conditions
        , aa_versions = aa_versions
        , aa_fractions = aa_fractions
    ))
}

#' Extract the data into R objects
#'
#' Smoking attributable fractions tables
#'
#' 1. compact table of conditions, codes, and relative risk
#' 2.
#'
#'
extract_sa <- function(
    bWriteCSV = FALSE
) {
    require("readxl")
    require("dplyr")
    require("tidyr")
    #require("data.table")
    require("janitor")

    # load worksheets

    this_xl <- devtools::package_file("./data-raw/srelrisk_lus.xlsx")

    these_wss <- excel_sheets(this_xl)

    these_sheets <- intersect(these_wss, c("B1", "B2", "ab_sa_explode"))

    wss <- these_sheets %>%
        lapply(
            function(x, y) {
                cat("INFO: reading sheet", x, "...", "\n")
                this_skip = 6
                readxl::read_excel(
                    path = y, sheet = x, skip = this_skip, col_names = TRUE
                )
            }, this_xl
        )

    names(wss) <- these_sheets

    # clean
    #
    # generate key, sort, reorder key

    lu1 <- wss[["B2"]] %>%
        #
        # clean
        #
        janitor::clean_names() %>%
        select(-"footnote") %>%
        filter(!is.na(icd_10_code)) %>%
        #
        # generate UID
        #
        mutate_if(is.character, as.factor) %>%
        mutate(
            condition_fuid = interaction(
                cat1, disease_category, icd_10_code, drop = TRUE
            )
        ) %>%
        mutate(
            condition_fuid = factor(
                condition_fuid
                , levels = unique(condition_fuid)
                , ordered = TRUE
            )
            , condition_uid = as.integer(condition_fuid)
        )

    # conditions

    sa_conditions <- lu1 %>%
        select(-contains("en_"), -"age", -"condition_fuid") %>%
        unique()

    # fractions

    sa_fractions <- lu1 %>%
        gather(contains("en_"), key = "gss", value = "srr") %>%
        mutate(gss = sub("en_", "en;", gss)) %>%
        separate(gss, into = c("sex", "smoking_status"), sep = ";") %>%
        select_at(vars("condition_uid", "age", "sex", "smoking_status", "srr"))

    # save

    if (bWriteCSV) {
        data.table::fwrite(sa_conditions, "./data-raw/sa_conditions.csv")
        usethis::use_data(sa_conditions, overwrite = TRUE)

        data.table::fwrite(sa_fractions, "./data-raw/sa_fractions.csv")
        usethis::use_data(sa_fractions, overwrite = TRUE)
    }

    invisible(list(
        sa_conditions = sa_conditions
        , sa_fractions = sa_fractions
    ))

}

#' do the business

main__extract_lus <- function(
    bWriteCSV = TRUE
) {
    # bWriteCSV = FALSE
    rv_aa <- extract_aa(bWriteCSV = bWriteCSV)
    rv_sa <- extract_sa(bWriteCSV = bWriteCSV)

    invisible(list(aa = rv_aa, sa = rv_sa))
}
