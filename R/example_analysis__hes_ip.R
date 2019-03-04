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

    len <- as.numeric(substr(len, 4, 1))

    retval <- list(c = LETTERS, nn = seq(0, 10^(len - 1) - 1)) %>%
        purrr::cross() %>%
        purrr::map_chr(function(x) {
            paste0(x$c, formatC(x$nn, flag = "0", width = len))
        })
    }

    retval
}

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
    , mix_type = c("5050aalen34mix", "len3", "len4", "len34", "aa_only")
    , nmultiple = 1
) {

    mix_type <- match.arg(mix_type)

    codes <- NULL

    if (mix_type %in% c("len3", "len4", "len34")) {
        codes <- gen_codes(len = mix_type)
    } else {
        # aa_only, 5050mix
        codes <- unique(aafractions.ncc::lu_aac_icd10$icd10)
    }

    # return n character strings ...

    if (nmultiple == 1) {
        # ... each containing one icd10 code

        if (!(mix_type == "5050aalen34mix")) {
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
            n, paste(ricd10(sample.int(nmultiple, 1)), collapse = ";")
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
#' @param bWriteCSV (bool) save to disk .. or not
#'
#' @return (data.frame) dummy HES table
#'
#' @family examples_of_analysis
#'
create__dummy_hesip <- function(
    n = 1024
    , bWriteCSV = FALSE
) {

    ip <- data.frame(
        Generated_Record_Identifier = 1e6 + seq(1, n)
        , Diagnosis_ICD_1 = NA
        , Diagnosis_ICD_Concatenated_D = ricd10(n, nmultiple = 20)

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
                Local_Authority_District == "E99999999", "E01999999", GIS_LSOA_2011_D
            )
        )

    ip
}

#' Create ageband labels
#'
#' Given breaks construct ageband labels of the form "xx-yy Yrs" and "zz+
#' Yrs"
#'
#' @param breaks (integer vector) breaks
#'
#' @return (character vector) labels
#'
#' @family examples_of_analysis
#'
ab_labels_from_breaks <- function(breaks) {
    nlabs <- length(breaks)
    dlabs <- data.frame(
        from = breaks[seq(1, nlabs - 1)]
        , to = breaks[seq(2, nlabs)]
    ) %>%
        mutate(
            lab = formatC(from, flag = "0", width = 2)
            , lab = ifelse(
                to == max(breaks)
                , paste0(lab, "+")
                , paste0(lab, "-", formatC(to - 1, flag = "0", width = 2))
            )
            , lab = paste0(lab, " Yrs")
        )
    dlabs$lab
}

#' Create age band looks for aa and esp
#'
#' @return (data.frame) with fields
#'
#' @examples
#' require("dplyr")
#' aafractions.ncc:::create_lu_ageband() %>% mutate_if(is.character, as.factor) %>% summary(20)
#' aafractions.ncc:::create_lu_ageband() %>% select(starts_with("ab_")) %>% unique()
#'
#' @family examples_of_analysis
#'
create_lu_ageband <- function() {

    breaks_esp <- c(seq(0, 95, 5), 120)
    breaks_aa <- c(0, 16, 25, 35, 45, 55, 65, 75, 120)

    lu <- data.frame(
        age = seq(0, 120)
    ) %>%
        mutate(
            ab_esp2013 = cut(
                age
                , breaks = breaks_esp
                , labels = ab_labels_from_breaks(breaks_esp)
                , right = FALSE, include.lowest = TRUE
            )
            , ab_aaf = cut(
                age
                , breaks = breaks_aa
                , labels = ab_labels_from_breaks(breaks_aa)
                , right = FALSE, include.lowest = TRUE
            )
        ) %>%
        mutate_if(is.factor, as.character)

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
#' - suitable for vignette
#'
#'
#' @family examples_of_analysis
#'
main__example_analysis__hes_ip <- function(
) {
    ip <- create__dummy_hesip()

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
                        filter(Version == "aaf_2017_phe")
                    , by = "condition_uid"
                )
            , by.x = "icd10", by.y = "icd10"
            , all.x = FALSE, all.y = FALSE
        ) %>%
        arrange(GRID, pos, icd10)

    # Tag on attributable fraction

    lu_ageband <- create_lu_ageband()
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
            , by.x = c("Version", "condition_uid", "AgeBand_AA", "GenderC")
            , by.y = c("Version", "condition_uid", "aa_ageband", "sex")
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
