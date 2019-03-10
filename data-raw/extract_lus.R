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

    lus <- wss %>% bind_rows() %>%
        rename(version = "Version")

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
        arrange(sortkey, codes, desc(version)) %>%
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
        select(-version, -analysis_type, -sortkey, -condition_fuid) %>%
        unique()

    # Versions
    #
    # Keep version, condition_uid
    # Drop analysis_type

    aa_versions <- lus %>%
        select(version, condition_uid) %>%
        unique() %>%
        arrange(desc(version), condition_uid)

    # list of fractions
    #
    # Keep version, condition_uid, ageband, sex, analysis_type and aaf
    # Need to do some work to melt ageband_sex fields
    #
    # ... and do something clever to get 'all' mapped to the other analysis
    # types

    aa_fractions <- lus %>%
        select(
            version
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
        arrange(version, condition_uid)

    aa_fractions <- aa_fractions %>%
        arrange(version, condition_uid, analysis_type, sex, aa_ageband)

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

    # age bands

    lu2 <- wss[["ab_sa_explode"]] %>%
        # missing arg to use default value
        gather(key = "ab_sa_explode", , -ab_sa, na.rm = TRUE) %>%
        select(-value)

    # relative risk
    #
    # ... and do something clever to get analysis_type 'all' mapped to the other
    # analysis types

    sa_relrisk <- lu1 %>%
        gather(contains("en_"), key = "gss", value = "srr") %>%
        mutate(gss = sub("en_", "en;", gss)) %>%
        separate(gss, into = c("sex", "smoking_status"), sep = ";") %>%
        select_at(vars(
            "analysis_type", "condition_uid"
            , ab_sa = "age", "sex"
            , "smoking_status", "srr"
        )) %>%
        # explode overlapping age bands
        merge(
            lu2
            , by.x = "ab_sa", by.y = "ab_sa"
            , all.x = TRUE, all.y = FALSE
        ) %>%
        # clean smoking_status (current/ex) and sex fields (men/women -> M/F)
        mutate(
            smoking_status = tstrsplit(
                smoking_status, split = "_", keep = 1
            ) %>% unlist()
            , sex = substr(sex, 1, 1)
            , sex = toupper(ifelse(sex == "w", "f", sex))
        ) %>%
        #
        # analysis_type == "all" -> morbidity and mortality
        # - missing values filled with 1 i.e. no change in risk
        #
        spread(key = "analysis_type", "srr", fill = NA) %>%
        mutate(
            # no-op - just to be clear that NA values exist in mortality field
            mortality = ifelse(!is.na(all), all, all)
            , morbidity = ifelse(is.na(morbidity), all, morbidity)
        ) %>%
        select(-all) %>%
        gather(key = "analysis_type", value = "srr", starts_with("mor")) %>%
        filter(!is.na(srr)) %>%
        mutate(version = "nhsd_ss_2018") %>%
        arrange(
            analysis_type, condition_uid
            , sex, ab_sa, ab_sa_explode
            , smoking_status
        )

    # Versions
    #
    # Keep version, condition_uid
    # Drop analysis_type

    sa_versions <- sa_relrisk %>%
        select(version, condition_uid) %>%
        unique() %>%
        arrange(desc(version), condition_uid)

    # save

    if (bWriteCSV) {
        data.table::fwrite(sa_conditions, "./data-raw/sa_conditions.csv")
        usethis::use_data(sa_conditions, overwrite = TRUE)

        data.table::fwrite(sa_versions, "./data-raw/sa_versions.csv")
        usethis::use_data(sa_versions, overwrite = TRUE)

        data.table::fwrite(sa_relrisk, "./data-raw/sa_relrisk.csv")
        usethis::use_data(sa_relrisk, overwrite = TRUE)
    }

    invisible(list(
        sa_conditions = sa_conditions
        , sa_relrisk = sa_relrisk
    ))

}

extract_sp <- function(
    bWriteCSV = TRUE
) {
    require("dplyr")
    require("data.table")

    this_csv <- devtools::package_file("./data-raw/PHE_LTCP_SP_20190304_indicators-DistrictUA.data.csv")

    #sp <- fread(this_csv) %>%
    sp <- read.csv(this_csv, as.is = TRUE) %>%
        janitor::clean_names() %>%
        filter(
            category_type == ""
            , indicator_name %like% "adults - (current|ex).*APS"
        ) %>%
        mutate(
            indicator_name = sub(
                "^Smoking Prevalence in adults - ", "", indicator_name
            )
            , calyear = as.integer(time_period)
        ) %>%
        select_at(vars(c(
            "indicator_name"
            , calyear
            , starts_with("area_")
            , sex, age
            , value
        ))) %>%
        mutate(
            sex = substr(sex, 1, 1)
            , indicator_name = tstrsplit(
                indicator_name, split = " ", keep = 1
            ) %>% unlist()
        ) %>%
        rename(smoking_status = "indicator_name") %>%
        mutate(
            units = "percent"
            , multiplier = 100
            , version = "phe_ltcp_201903"
        )

    if (bWriteCSV) {
        data.table::fwrite(sp, "./data-raw/sp.csv")
        usethis::use_data(sp, overwrite = TRUE)
    }

    sp
}

#' do the business

main__extract_lus <- function(
    bWriteCSV = TRUE
) {
    # bWriteCSV = FALSE
    rv_aa <- extract_aa(bWriteCSV = bWriteCSV)
    rv_sa <- extract_sa(bWriteCSV = bWriteCSV)
    rv_sp <- extract_sp(bWriteCSV = bWriteCSV)

    invisible(list(aa = rv_aa, sa = rv_sa, sp = rv_sp))
}
