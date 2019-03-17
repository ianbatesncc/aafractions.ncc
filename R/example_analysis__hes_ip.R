#' Example analysis
#'
#' @name examples_of_analysis
#' @family examples_of_analysis
#'
NULL

#' Generate icd code space
#'
#' Generate all possible (valid and invalid) icd10 codes of the form
#' [A-Z][0-9]{nn} where nn is either two or three digits in length (or both).
#'
#' @param len Overall length of code.  3 corresponds to Xnn, 4 to Xnnn, 34 to both.
#'
#' @return (character vector) All possible codes
#'
#' @family examples_of_analysis
#'
gen_codes <- function(len = c("len3", "len4", "len34")) {
    len <- match.arg(len)

    if (len == "34") {
        c3 <- gen_codes("len3")
        c4 <- gen_codes("len4")

        retval <- c(c3, c4)
    } else {

        len <- as.numeric(substr(len, 4, 4)) - 1

        seq_end <- 10^(len - 1) - 1

        if (seq_end < 1)
            stop("unusual sequence end limit.")

        retval <- list(c = LETTERS, nn = seq(0, seq_end)) %>%
            purrr::cross() %>%
            purrr::map_chr(function(x) {
                paste0(x$c, formatC(x$nn, flag = "0", width = len))
            })
    }

    retval
}

#' Case insensitive like
#'
#' @param vector (character) string to match
#' @param pattern (character) passed to \code{grepl}
#'
#' @return (logical vector) indicate matches
#'
#' @details
#'
#' Inspiration from data.table \code{like}.
#'
ilike <- function(vector, pattern) {
    grepl(pattern, vector, ignore.case = TRUE)
}
`%ilike%` <- ilike

#' Return a random icd10 code.
#'
#' @param n (integer) number of records to return
#' @param mix_type (character) Specify code mix - len3:all Xnn, len4:all Xnnn,
#'   len34:any Xnn/Xnnn, aa_only:only alcohol attributable related, or
#'   5050aalen34mix a 50/50 mix of aa_only and len34
#' @param nmultiple (integer) return up to this many codes separated by ";" in
#'   each record.  Default 1 (and no ";").
#'
#' Sampling from generated code space used, however for 50/50 mix due to problme
#' space the icd10 codesa re generated randomly on-the-fly rather than sampled
#' from full generated pattern space.  Still random but might not be the same
#' random ... but probably is.
#'
#' @return (character vector) n records of 1 to nmultiple (varying) icd10-like
#'   codes.
#'
#' @family examples_of_analysis
#'
ricd10 <- function(
    n = 1024
    , mix_type = c(
        "5050aalen34mix", "5050salen34mix", "5050uclen34mix", "5050aclen34mix"
        , "len3", "len4", "len34"
        , "aa_only", "sa_only", "uc_only", "ac_only"
    )
    , nmultiple = 1
) {
    mix_type <- match.arg(mix_type)

    codes <- NULL

    if (mix_type %in% c("len3", "len4", "len34")) {
        codes <- gen_codes(len = mix_type)
    } else if (mix_type %ilike% "aa") {
        # aa_only, 5050aamix
        codes <- unique(aafractions.ncc::lu_aac_icd10$icd10)
    } else if (mix_type %ilike% "sa") {
        # sa_only, 5050samix
        codes <- unique(aafractions.ncc::lu_sac_icd10$icd10)
    } else if (mix_type %ilike% "uc") {
        # uc_only, 5050ucmix
        codes <- unique(aafractions.ncc::lu_ucc_icd10$icd10)
    } else if (mix_type %ilike% "ac") {
        # uc_only, 5050acmix
        codes <- unique(aafractions.ncc::lu_acc_icd10$icd10)
    } else {
        stop("Should not reach here: Unknown mix_type.")
    }

    # return n character strings ...

    if (nmultiple == 1) {
        # ... each containing one icd10 code

        if (!(mix_type %ilike% "^5050[a-z]{1,}len34mix$")) {
            retval <- sample(codes, n, replace = TRUE)
        } else {
            retval <- c(
                sample(codes, round(n / 2), replace = TRUE)
                # faster 3/4 selection
                # - n letters A-Z ; n numbers, [x]xx, zero padded
                , paste0(
                    sample(LETTERS, n, replace = TRUE)
                    , formatC(
                        sample(seq.int(1e3) - 1, n, replace = TRUE)
                        , flag = "0", width = "2"
                    )
                )
            )[sample(seq.int(n), n)]
        }

    } else {
        # ... each containing up to nmultiple icd10 codes ...

        retval <- replicate(
            n
            , paste(
                ricd10(sample.int(nmultiple, 1), mix_type = mix_type)
                , collapse = ";"
            )
        )
    }

    retval
}

#' Create dummy HES table
#'
#' Generate a psudo random HES IP table good enough to put any analysis through
#' its paces.
#'
#' @param n (integer) length of table
#' @param mix_type (character) passed to ricd10 (random diagnosis code
#'   generator)
#'
#' @return (data.frame) dummy HES table
#'
#' @family examples_of_analysis
#'
create__dummy_hesip <- function(
    n = 1024
    , mix_type = NULL
) {

    ip <- data.frame(
        Generated_Record_Identifier = 1e6 + seq(1, n)

        , Admission_Method_Code = sample(
            c(11, 21, 31, 82, 99)
            , prob = c(50, 50, 5, 2, 1)
            , n, replace = TRUE
        )

        , ADMISORC = sample(
            c(19, 29, 39, 49, 50, 69, 79, 89, 99)
            , prob = c(100, 2, 2, 2, 2, 2, 2, 2, 1)
            , n, replace = TRUE
        )

        # aligned with concat later
        , Diagnosis_ICD_1 = NA
        , Diagnosis_ICD_Concatenated_D = ricd10(
            n, mix_type = mix_type, nmultiple = 20
        )

        , Consultant_Episode_End_Date = as.POSIXct("2019/01/01")
        , Consultant_Episode_Number = sample(
            seq(1, 4), n, prob = c(100, 10, 5, 1), replace = TRUE
        )
        , Financial_Year_D = "2018/19"

        , Episode_Status = sample(c(3), n, replace = TRUE)
        , Patient_Classification = sample(
            seq(1, 5), n, prob = c(100, 100, 1, 1, 100), replace = TRUE
        )

        , Age_at_Start_of_Episode_D = sample(
            seq.int(121) - 1, n, replace = TRUE
        )
        , Age_On_Admission = NA
        , Gender = sample(
            c(0, 1, 9), n, prob = c(100, 100, 1), replace = TRUE
        )

        , HES_Identifier_Encrypted = 1e6 +
            sample.int(round(n / 4), n, replace = TRUE)

        , Ethnic_Category = "Ethnic Category Unknown"

        # aligned with episode duration later
        , Consultant_Episode_Start_Date = NA
        , Episode_Duration_from_Grouper = sample(seq(0, 14), n, replace = TRUE)

        , Admission_Date_Hospital_Provider_Spell = NA
        , Discharge_Date_Hospital_Spell_Provider = NA
        , SUS_Generated_Spell_Id = NA

        , Local_Authority_District = sample(
            c(
                "E06000018"
                , "E07000170", "E07000171", "E07000172", "E07000173"
                , "E07000174", "E07000175", "E07000176", "E99999999"
            )
            , n
            , replace = TRUE
        )
        , GIS_LSOA_2011_D = paste0(
            "E0100"
            , formatC(
                sample(seq.int(1e3) - 1, n, replace = TRUE)
                , flag = "0", width = 4
            )
        )

        # aligned with concat later
        , Procedure_OPCS_1 = NA
        , Procedure_OPCS_Concatenated_D = ricd10(
            n, mix_type = "len3", nmultiple = 24
        )

        , stringsAsFactors = FALSE
    ) %>%
        mutate(
            Diagnosis_ICD_1 = data.table::tstrsplit(
                Diagnosis_ICD_Concatenated_D, ";", keep = 1
            ) %>% unlist()

            , Age_On_Admission = Age_at_Start_of_Episode_D

            , Consultant_Episode_Start_Date =
                Consultant_Episode_End_Date -
                as.difftime(Episode_Duration_from_Grouper, units = "days")

            , GIS_LSOA_2011_D = ifelse(
                Local_Authority_District == "E99999999"
                , "E01999999"
                , GIS_LSOA_2011_D
            )

            , Procedure_OPCS_1 = data.table::tstrsplit(
                Procedure_OPCS_Concatenated_D, ";", keep = 1
            ) %>% unlist()
        )

    ip
}

#' Create ageband labels
#'
#' Given breaks construct ageband labels of the form "xx-yy Yrs" and "zz+
#' Yrs"
#'
#' @param breaks (integer vector) breaks
#' @param style (character) choose style alcohol: "00-00 Yrs", smoking: "00 -
#'   00", generic: "a0000"
#' @param flag (character) number formatting (see formatC)
#' @param width (integer) number formatting (see formatC)
#'
#' @details
#'
#' A general ageband has an age range, specfied by lower (inclusive) and upper
#' (exclusive).
#'
#' An ageband label is of the general form:
#'
#' <prefix> <value lower> <separator> <value upper> <suffix>
#'
#' with the last age band of the form:
#'
#' <prefix> <value upper> "+" <suffix>
#'
#' Variations are tailored for specific lookup tables.
#'
#' * alcohol: 00-00 Yrs
#' * smoking: 00 - 00
#' * generic: a0000
#' * ucs:     0 - 0 yrs
#'
#' @return (character vector) labels
#'
#' @family examples_of_analysis
#'
ab_labels_from_breaks <- function(
    breaks
    , style = c("alcohol", "smoking", "generic", "ucs")
    , flag = "0"
    , width = 2
){
    style <- match.arg(style)

    # Adjust style settings

    if (missing(flag))
        flag <- switch(style, ucs = "", "0")

    if (missing(width))
        width <- switch(style, ucs = -1, 2)

    ab_prefix <- switch(
        style
        , generic = "a"
        , ""
    )

    ab_sep <- switch(
        style
        , alcohol = "-"
        , smoking = " - "
        , ucs = " - "
        , ""
    )

    ab_suffix <- switch(
        style
        , alcohol = " Yrs"
        , ucs = " yrs"
        , ""
    )

    # create the labels

    nlabs <- length(breaks)
    dlabs <- data.frame(
        from = breaks[seq(1, nlabs - 1)]
        , to = breaks[seq(2, nlabs)]
    ) %>%
        mutate(
            s_sta = formatC(from, flag = flag, width = width)
            , s_end = formatC(to - 1, flag = flag, width = width)
            , lab = ifelse(
                to == max(breaks)
                , paste0(s_sta, "+")
                , paste0(s_sta, ab_sep, s_end)
            )
            , lab = paste0(ab_prefix, lab, ab_suffix)
        )

    dlabs$lab
}

#' Create age band looks for aa and esp
#'
#' @param style (character) choose label foramtting and breaks (alcohol,
#'   smoking, generic - 5 year agebands to 95+)
#' @param name (character) choose field name
#'
#' @return (data.frame) with fields age, ab, ab_style ab optionally renamed)
#'
#' @examples
#' require("dplyr")
#' aafractions.ncc:::create_lu_ageband() %>% mutate_if(is.character, as.factor) %>% summary(20)
#' aafractions.ncc:::create_lu_ageband() %>% select(starts_with("ab_")) %>% unique()
#'
#' @family examples_of_analysis
#'
create_lu_ageband <- function(
    style = c("alcohol", "smoking", "generic", "ucs")
    , name = NULL
) {
    style <- match.arg(style)

    breaks_esp <- c(seq(0, 95, 5), 120)

    these_breaks <- switch(
        style
        , alcohol = c(0, 16, 25, 35, 45, 55, 65, 75, 120)
        , smoking = c(0, 35, 45, 55, 65, 75, 120)
        , ucs = c(0, 6, 75, 120)
        , breaks_esp
    )

    lu <- data.frame(
        age = seq(0, 120)
    ) %>%
        mutate(
            ab_esp2013 = cut(
                age
                , breaks = breaks_esp
                , labels = ab_labels_from_breaks(breaks_esp, style)
                , right = FALSE, include.lowest = TRUE
            )
            , ab = cut(
                age
                , breaks = these_breaks
                , labels = ab_labels_from_breaks(these_breaks, style)
                , right = FALSE, include.lowest = TRUE
            )
            , ab_style = style
        ) %>%
        mutate_if(is.factor, as.character)

    if (!is.null(name)) {
        this_var <- "ab"
        names(this_var) <- name
        lu <- rename(lu, !!!this_var)
    }

    lu
}

#' Create age band looks for aa and esp
#'
#'
#'
#' @family examples_of_analysis
#'
create_lu_gender <- function() {
    data.table::fread(text = "
gender,genderC,genderName
0,M,Male
1,F,Female
9,P,Unknown
")
}


#' Example analysis
#'
#' Alcohol morbidity
#'
#' - suitable for vignette
#'
#' @family examples_of_analysis
#'
main__example_analysis__aa_morbidity <- function(
) {
    ip <- create__dummy_hesip(mix_type = "5050aa")

    # Split out diagnosis codes

    tbl__AA__PHIT_IP__melt <- ip %>%
        filter(
            Consultant_Episode_Number == 1
            , Episode_Status == 3
            , Patient_Classification %in% c(1, 2, 5)
        ) %>%
        select(
            GRID = Generated_Record_Identifier
            , Diag_Concat_adj = Diagnosis_ICD_Concatenated_D
        ) %>%
        split(.$GRID) %>%
        purrr::map_dfr(function(x) {
            these_codes <- strsplit(x$Diag_Concat_adj, ";")
            data.frame(
                GRID = x$GRID
                , icd10 = these_codes[[1]]
                , pos = seq_along(these_codes[[1]])
                , stringsAsFactors = FALSE
            )
        }) %>%
        merge(
            aafractions.ncc::lu_aac_icd10 %>%
                merge(
                    aafractions.ncc::aa_versions %>%
                        filter(version == "aaf_2017_phe")
                    , by = "condition_uid"
                )
            , by.x = "icd10", by.y = "icd10"
            , all.x = FALSE, all.y = FALSE
        ) %>%
        arrange(GRID, pos, icd10)

    # Tag on attributable fraction

    lu_ageband <- create_lu_ageband(style = "alcohol", name = "ab_aaf")

    lu_sex <- create_lu_gender()

    tbl__AA__PHIT_IP__melt <- ip %>%
        filter(
            Generated_Record_Identifier %in% unique(tbl__AA__PHIT_IP__melt$GRID)
        ) %>%
        merge(
            lu_ageband
            , by.x = "Age_at_Start_of_Episode_D"
            , by.y = "age"
        ) %>%
        merge(
            lu_sex
            , by.x = "Gender"
            , by.y = "gender"
        ) %>%
        select(
            GRID = Generated_Record_Identifier
            , GenderC = genderC
            , AgeBand_AA = ab_aaf
        ) %>%
        merge(
            tbl__AA__PHIT_IP__melt
            , by = "GRID"
            , all.x = TRUE, all.y = FALSE
        ) %>%
        merge(
            aafractions.ncc::aa_fractions %>%
                filter(analysis_type == "morbidity")
            , by.x = c("version", "condition_uid", "AgeBand_AA", "GenderC")
            , by.y = c("version", "condition_uid", "aa_ageband", "sex")
            , all.x = TRUE, all.y = FALSE
        )

    # Construct methods

    methods__broad <- tbl__AA__PHIT_IP__melt %>%
        filter(aaf > 0) %>%
        group_by(GRID) %>%
        mutate(aa_rank_1_highest = order(order(desc(aaf), pos))) %>%
        ungroup() %>%
        filter(aa_rank_1_highest == 1) %>%
        mutate(method = "alcohol-related (broad)")

    methods__narrow <- tbl__AA__PHIT_IP__melt %>%
        filter(
            (aaf > 0)
            , (pos == 1) | (data.table::like(icd10, "^[VWXY]"))
        ) %>%
        group_by(GRID) %>%
        mutate(aa_rank_1_highest = order(order(desc(aaf), pos))) %>%
        ungroup() %>%
        filter(aa_rank_1_highest == 1) %>%
        mutate(method = "alcohol-related (narrow)")

    methods__specific <- tbl__AA__PHIT_IP__melt %>%
        filter(aaf > 0.99) %>%
        group_by(GRID) %>%
        mutate(aa_rank_1_highest = order(order(desc(aaf), pos))) %>%
        ungroup() %>%
        filter(aa_rank_1_highest == 1) %>%
        mutate(method = "alcohol-specific")

    aa_methods <- bind_rows(
        methods__broad
        , methods__narrow
        , methods__specific
    ) %>% select(-aa_rank_1_highest)

    aa_methods
}

#' Example analysis
#'
#' Smoking morbidity
#'
#' - suitable for vignette
#'
#' Methodology
#'
#' Finished Admission Episodes (epiorder = 1, epistat = 3, patclass (1, 2, 5))
#'
#'
#' @family examples_of_analysis
#'
main__example_analysis__sa_morbidity <- function(
) {
    ip <- create__dummy_hesip(mix_type = "5050sa")

    # Split out diagnosis codes

    tbl__SA__PHIT_IP__melt <- ip %>%
        filter(
            Consultant_Episode_Number == 1
            , Episode_Status == 3
            , Patient_Classification %in% c(1, 2, 5)
        ) %>%
        select(
            GRID = Generated_Record_Identifier
            , icd10 = Diagnosis_ICD_1
        ) %>%
        mutate(pos = 1) %>%
        merge(
            aafractions.ncc::lu_sac_icd10 %>%
                merge(
                    aafractions.ncc::sa_versions %>%
                        filter(version == "nhsd_ss_2018")
                    , by = "condition_uid"
                )
            , by.x = "icd10", by.y = "icd10"
            , all.x = FALSE, all.y = FALSE
        ) %>%
        arrange(GRID, pos, icd10)

    # Tag on relative risk
    #
    # meta: age, gender, LAD, CalYear
    #

    lu_ageband <- create_lu_ageband(style = "smoking", name = "ab_sa")

    lu_sex <- create_lu_gender()

    tbl__SA__PHIT_IP__melt <- ip %>%
        filter(
            Generated_Record_Identifier %in% unique(tbl__SA__PHIT_IP__melt$GRID)
        ) %>%
        #
        # gather record meta data
        #
        merge(
            lu_ageband
            , by.x = "Age_at_Start_of_Episode_D", by.y = "age"
        ) %>%
        merge(
            lu_sex
            , by.x = "Gender", by.y = "gender"
        ) %>%
        mutate(
            meta_calyear = as.integer(
                lubridate::year(Consultant_Episode_End_Date)
            )
        ) %>%
        select(
            GRID = Generated_Record_Identifier
            , GenderC = genderC
            , AgeBand_SA = ab_sa
            , meta_lad = Local_Authority_District
            , meta_calyear
        ) %>%
        merge(
            tbl__SA__PHIT_IP__melt
            , by = "GRID"
            , all.x = TRUE, all.y = FALSE
        ) %>%
        #
        # tag on relative risk
        #
        # condition, age, gender
        # - expand by smoking_status
        #
        merge(
            aafractions.ncc::sa_relrisk %>%
                filter(analysis_type == "morbidity")
            , by.x = c("version", "condition_uid", "AgeBand_SA", "GenderC")
            , by.y = c("version", "condition_uid", "ab_sa_explode", "sex")
            , all.x = FALSE, all.y = FALSE
        ) %>%
        #
        # tag on smoking prevalence
        #
        # age == 18+, gender, smoking_status
        #
        merge(
            aafractions.ncc::sp %>%
                select_at(vars(c(
                    "smoking_status", "calyear", "area_code", "sex", "value", "multiplier"
                ))) %>%
                rename(sp = "value") %>%
                mutate(sp = sp / multiplier) %>%
                select(-multiplier) %>%
                filter(calyear == 2017)
            , by.x = c("GenderC", "smoking_status", "meta_lad") # , "meta_calyear")
            , by.y  = c("sex", "smoking_status", "area_code") # , "calyear")
            , all.x = TRUE, all.y = FALSE
        ) %>%
        #
        # Calculate attributable fraction
        #
        group_by_at(vars(-"smoking_status", -"sp", -"srr", -"calyear")) %>%
        summarise(saf = {
            da = sum(sp * (srr - 1))
            da / (1 + da)
        }) %>%
        ungroup()


    # Construct methods

    methods__specific <- tbl__SA__PHIT_IP__melt %>%
        #filter(saf > 0.99) %>%
        #group_by(GRID) %>%
        #mutate(aa_rank_1_highest = order(order(desc(aaf), pos))) %>%
        #ungroup() %>%
        #filter(aa_rank_1_highest == 1) %>%
        mutate(method = "smoking-attributable")

    sa_methods <- bind_rows(
        methods__specific
    )

    sa_methods
}

#' Example analysis
#'
#' Urgent care sensitive morbidity
#'
#' - suitable for vignette
#'
#' Methodology
#'
#' Finished Admission Episodes (epiorder = 1, epistat = 3, patclass (1, 2, 5))
#' Emergency admission - admeth %like% '^2'
#'
#'
#' @family examples_of_analysis
#'
main__example_analysis__uc_morbidity <- function(
) {
    ip <- create__dummy_hesip(mix_type = "5050uc")

    # Split out diagnosis codes

    tbl__UC__PHIT_IP__melt <- ip %>%
        #
        # Finished admission episodes EMERGENCY method
        #
        filter(
            Consultant_Episode_Number == 1
            , Episode_Status == 3
            , Patient_Classification %in% c(1, 2, 5)
            , data.table::like(Admission_Method_Code, "^2")
        ) %>%
        select(
            GRID = Generated_Record_Identifier
            , icd10 = Diagnosis_ICD_1
        ) %>%
        mutate(pos = 1) %>%
        merge(
            aafractions.ncc::lu_ucc_icd10 %>%
                merge(
                    aafractions.ncc::uc_versions %>%
                        filter(version == "ccg_iaf_201617")
                    , by = "condition_uid"
                )
            , by.x = "icd10", by.y = "icd10"
            , all.x = FALSE, all.y = FALSE
        ) %>%
        arrange(GRID, pos, icd10)

    # Tag on attribution
    #
    # meta: age
    #

    lu_ageband <- create_lu_ageband(style = "ucs", name = "ab_uc")

    lu_sex <- create_lu_gender()

    tbl__UC__PHIT_IP__melt <- ip %>%
        filter(
            Generated_Record_Identifier %in% unique(tbl__UC__PHIT_IP__melt$GRID)
        ) %>%
        #
        # gather record meta data
        #
        merge(
            lu_ageband
            , by.x = "Age_at_Start_of_Episode_D", by.y = "age"
        ) %>%
        merge(
            lu_sex
            , by.x = "Gender", by.y = "gender"
        ) %>%
        mutate(
            meta_calyear = as.integer(
                lubridate::year(Consultant_Episode_End_Date)
            )
        ) %>%
        select(
            GRID = Generated_Record_Identifier
            , GenderC = genderC
            , AgeBand_UC = ab_uc
            , meta_lad = Local_Authority_District
            , meta_calyear
        ) %>%
        merge(
            tbl__UC__PHIT_IP__melt
            , by = "GRID"
            , all.x = TRUE, all.y = FALSE
        ) %>%
        #
        # tag on attribution
        #
        # condition, age
        #
        merge(
            aafractions.ncc::uc_attribution
            , by.x = c("version", "condition_uid", "AgeBand_UC")
            , by.y = c("version", "condition_uid", "ab_ucs_explode")
            , all.x = FALSE, all.y = FALSE
        )

    # Construct methods

    methods__all <- tbl__UC__PHIT_IP__melt %>%
        mutate(method = "urgent-care-sensitive")

    uc_methods <- bind_rows(
        methods__all
    )

    uc_methods
}

#' Example analysis
#'
#' Urgent care sensitive morbidity
#'
#' - suitable for vignette
#'
#' Methodology
#'
#' Finished Admission Episodes (epiorder = 1, epistat = 3, patclass (1))
#' Emergency admission - admeth %like% '^2'
#'
#' candidates: diagnosis
#'
#' @family examples_of_analysis
#'
main__example_analysis__ac_morbidity <- function(
) {
    ip <- create__dummy_hesip(mix_type = "5050aclen34mix")
    # Split out diagnosis codes

    tbl__AC__PHIT_IP__melt <- ip %>%
        #
        # Finished admission episodes
        # EMERGENCY method
        # not a transfer
        #
        filter(
            Consultant_Episode_Number == 1
            , Episode_Status == 3
            , Patient_Classification %in% c(1)
            , data.table::like(Admission_Method_Code, "^2")
            , !(ADMISORC %in% c(51, 52, 53))
        ) %>%
        select(
            GRID = Generated_Record_Identifier
            , icd10 = Diagnosis_ICD_1
            , icd10_sec = Diagnosis_ICD_Concatenated_D
            , opcs_all = Procedure_OPCS_Concatenated_D
        ) %>%
        mutate(pos = 1) %>%
        #
        # First filter: check primary diagnoses
        #
        merge(
            aafractions.ncc::lu_acc_icd10 %>%
                merge(
                    aafractions.ncc::ac_versions %>%
                        filter(version == "ccg_ois_26")
                    , by = "condition_uid"
                )
            , by.x = "icd10", by.y = "icd10"
            , all.x = FALSE, all.y = FALSE
        ) %>%
        #
        # Secondary filter: tag secondary diagnoses and procedures of relevance
        #
        merge(
            aafractions.ncc::ac_conditions %>%
                select(condition_uid, contains("_regexp"))
            , by = "condition_uid"
        ) %>%
        mutate(
            matches_sec_diag_include = mapply(
                data.table::like, icd10_sec, sec_diag_include_regexp
            )
            , matches_sec_diag_exclude = mapply(
                data.table::like, icd10_sec, sec_diag_exclude_regexp
            )
            , matches_proc_exclude = mapply(
                data.table::like, opcs_all, proc_exclude_regexp
            )
            , to_include = mapply(
                all
                , matches_sec_diag_include
                , !matches_sec_diag_exclude
                , !matches_proc_exclude
                , MoreArgs = list(na.rm = TRUE)
            )
        ) %>%
        select(
            -contains("regexp")
            , -starts_with("matches")
            , -contains("_sec")
            , -contains("opcs")
        ) %>%
        #
        # Secondary filter: filter on secondary diagnoses and procedures of
        # relevance
        #
        filter(to_include == TRUE) %>%
        select(-to_include) %>%
        #
        # Done
        #
        arrange(GRID, pos, icd10)


    tbl__AC__PHIT_IP__melt <- ip %>%
        filter(
            Generated_Record_Identifier %in% unique(tbl__AC__PHIT_IP__melt$GRID)
        ) %>%
        #
        # gather record meta data
        #
        mutate(
            meta_calyear = as.integer(
                lubridate::year(Consultant_Episode_Start_Date) # NOTE start
            )
        ) %>%
        select(
            GRID = Generated_Record_Identifier
            , meta_lad = Local_Authority_District
            , meta_calyear
        ) %>%
        merge(
            tbl__AC__PHIT_IP__melt
            , by = "GRID"
            , all.x = TRUE, all.y = FALSE
        ) %>%
        #
        # tag on attribution
        #
        # condition, age
        #
        merge(
            aafractions.ncc::ac_attribution
            , by.x = c("version", "condition_uid")
            , by.y = c("version", "condition_uid")
            , all.x = FALSE, all.y = FALSE
        )

    # Construct methods

    methods__all <- tbl__AC__PHIT_IP__melt %>%
        mutate(method = "ambulatory-care-sensitive")

    ac_methods <- bind_rows(
        methods__all
    )

    ac_methods
}
