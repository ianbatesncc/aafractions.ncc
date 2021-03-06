#
# Script to extract tables from .xlsx
#

require("readxl", warn.conflicts = FALSE)
require("dplyr", warn.conflicts = FALSE)
require("data.table", warn.conflicts = FALSE)
require("devtools", warn.conflicts = FALSE)
require("tidyr", warn.conflicts = FALSE)
require("janitor", warn.conflicts = FALSE)

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
    # load tables as list of tables

    this_wb = devtools::package_file("./data-raw/aafraction_lus.xlsx")

    these_wss <- readxl::excel_sheets(path = this_wb)

    these_sheets <- setdiff(these_wss, "Tables")

    wss <- these_sheets %>%
        lapply(
            function(x, y) {
                cat("INFO: reading sheet", x, "...", "\n")
                readxl::read_excel(path = y, sheet = x, skip = 5, col_names = TRUE)
            }, this_wb
        )

    names(wss) <- these_sheets

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
        filter(!grepl("^\\[S", desc)) %>%
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
    this_csv <- devtools::package_file(
        "./data-raw/PHE_LTCP_SP_20190304_indicators-DistrictUA.data.csv"
    )

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

#' Extract UCS
#'
extract_uc <- function(
    bWriteCSV = FALSE
) {
    # load tables as list of tables

    this_wb = devtools::package_file("./data-raw/ucs_lus.xlsx")

    these_wss <- readxl::excel_sheets(path = this_wb)

    these_sheets <- setdiff(these_wss, c("Overview", "UCS meta"))

    wss <- these_sheets %>%
        lapply(
            function(x, y) {
                cat("INFO: reading sheet", x, "...", "\n")
                readxl::read_excel(path = y, sheet = x, skip = 2, col_names = TRUE)
            }, this_wb
        )

    names(wss) <- these_sheets

    # conditions

    uc_conditions <- lapply(
        "ccg_iaf_201617"
        , function(x, y) {
            y[[x]] %>%
                janitor::clean_names() %>%
                mutate(
                    condition_uid = row_number()
                    , version = x
                )
        }
        , y = wss
    ) %>% bind_rows()

    # age bands

    lu <- wss[["ab_ucs_explode"]] %>%
        # missing arg to use default value
        gather(key = "ab_ucs_explode", , -ab_ucs, na.rm = TRUE) %>%
        select(-value)

    # versions

    uc_versions <- uc_conditions %>%
        select(version, condition_uid)

    # attribution

    uc_attribution <- uc_conditions %>%
        merge(lu, by.x = "age", by.y = "ab_ucs") %>%
        select(contains("uid"), ab_ucs = age, ab_ucs_explode, version) %>%
        mutate(ucs_af = 1L)

    # ... back to conditions

    uc_conditions <- uc_conditions %>% select(-version)

    # save

    if (bWriteCSV) {
        data.table::fwrite(uc_conditions, "./data-raw/uc_conditions.csv")
        usethis::use_data(uc_conditions, overwrite = TRUE)

        data.table::fwrite(uc_versions, "./data-raw/uc_versions.csv")
        usethis::use_data(uc_versions, overwrite = TRUE)

        data.table::fwrite(uc_attribution, "./data-raw/uc_attribution.csv")
        usethis::use_data(uc_attribution, overwrite = TRUE)
    }

    invisible(list(
        uc_conditions = uc_conditions
        , uc_versions = uc_versions
        , uc_attribution = uc_attribution
    ))
}

#' Extract Ambulatory Care Sensitive
#'
extract_ac <- function(
    bWriteCSV = FALSE
) {
    # load tables as list of tables

    this_wb = devtools::package_file("./data-raw/acs_lus.xlsx")

    these_wss <- readxl::excel_sheets(path = this_wb)

    these_sheets <- setdiff(these_wss, c("Overview", "ACS meta"))

    wss <- these_sheets %>%
        lapply(
            function(x, y) {
                cat("INFO: reading sheet", x, "...", "\n")
                readxl::read_excel(path = y, sheet = x, skip = 0, col_names = TRUE)
            }
            , y = this_wb
        )

    names(wss) <- these_sheets

    # conditions

    ac_conditions_all <- lapply(
        #"ccg_ois_26"
        these_sheets
        , function(x, y) {
            y[[x]] %>%
                janitor::clean_names() %>%
                mutate(
                    condition_uid = row_number()
                    , version = x
                )
        }
        , y = wss
    ) # %>% bind_rows()
    names(ac_conditions_all) <- these_sheets

    #
    # Add sub-detail to general lookup
    #
    # conditions still 'broad'
    # detail an extra step if needed
    #

    lu1 <- ac_conditions_all[[1]] %>%
        select(
            desc = condition_description
            , primary_diagnosis = primary_diagnosis_detail
            , condition_uid
        ) %>%
        mutate(primary_diagnosis = gsub("\\.", "", primary_diagnosis))

    lu2 <- ac_conditions_all[[2]] %>%
        select(
            -condition_description
            , -condition_uid
            , primary_diagnosis_broad = primary_diagnosis
        )

    ac_conditions <- merge(lu2, lu1) %>%
        mutate(is_match = mapply(grepl, prim_diag_regexp, primary_diagnosis)) %>%
        filter(is_match == TRUE) %>%
        select(-is_match) %>%
        arrange(condition_uid, primary_diagnosis) %>%
        select(cat1, cat2, condition_uid, desc, primary_diagnosis, everything())

    # versions

    ac_versions <- ac_conditions %>%
        select(version, condition_uid)

    # attribution

    ac_attribution <- ac_conditions %>%
        select(contains("uid"), version) %>%
        mutate(acs_af = 1L)

    # ... back to conditions

    ac_conditions <- ac_conditions %>% select(-version)

    # save

    if (bWriteCSV) {
        data.table::fwrite(ac_conditions, "./data-raw/ac_conditions.csv")
        usethis::use_data(ac_conditions, overwrite = TRUE)

        data.table::fwrite(ac_versions, "./data-raw/ac_versions.csv")
        usethis::use_data(ac_versions, overwrite = TRUE)

        data.table::fwrite(ac_attribution, "./data-raw/ac_attribution.csv")
        usethis::use_data(ac_attribution, overwrite = TRUE)
    }

    invisible(list(
        ac_conditions = ac_conditions
        , ac_versions = ac_versions
        , ac_attribution = ac_attribution
    ))
}

#' Do the business
#'
#' @param what (character vector) what to process
#' @param bWriteCSV (logical) to save or not
#'
#' @return (list) lookup tables
#'

main__extract_lus <- function(
    what = c("aa", "sa", "sp", "uc", "ac")
    , bWriteCSV = TRUE
) {
    what <- match.arg(what, several.ok = TRUE)

    rv <- what %>% lapply(
        function(x, y) {
            cat("INFO: extracting", x, "...", "\n")
            this_extract <- switch(
                x
                , aa = extract_aa
                , sa = extract_sa
                , sp = extract_sp
                , uc = extract_uc
                , ac = extract_ac
            )
            this_extract(y)
        }
        , y = bWriteCSV
    )
    names(rv) <- what

    invisible(rv)
}
