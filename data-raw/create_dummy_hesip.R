#
# Create dummy HES table
#

library("dplyr", warn.conflicts = FALSE)
library("data.table", warn.conflicts = FALSE)

create__dummy_hesip <- function(
    n = 1024
    , bWriteCSV = TRUE
) {

    #' Return a random icd10 code.
    #'
    #' @param nmultiple (integer) return up to this many codes separated by ";"
    #'
    #' @value (character)
    #'
    #'
    ricd10 <- function(
        n = 1024
        , mix_type = c("5050aalen34mix", "len3", "len4", "len34", "aa_only")
        , nmultiple = 1
    ) {

        mix_type <- match.arg(mix_type)

        #' generate icd code space
        #'
        #' @param len Xnn or Xnnn
        #'
        #' @value (character vector) All possible codes
        #'
        gen_codes <- function(len = c("3", "4", "34")) {
            len <- match.arg(len)
            len <- as.numeric(len)
            list(c = LETTERS, nn = seq(0, 10^(len - 1) - 1)) %>%
                purrr::cross() %>%
                purrr::map_chr(function(x) {
                    paste0(x$c, formatC(x$nn, flag = "0", width = len))
                })
        }

        codes <- NULL

        if (mix_type == "aa_only") {
            codes <- unique(lu_aac_icd10$icd10)
        } else if (mix_type == "len3") {
            codes <- gen_codes(len = 3)
        } else if (mix_type == "len4") {
            codes <- gen_codes(len = 4)
        } else if (mix_type == "len34") {
            codes <- c(gen_codes(len = 3), gen_codes(len = 4))
        } else {
            # also for 5050mix
            codes <- unique(lu_aac_icd10$icd10)
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
                    , paste0(
                        # n letters A-Z
                        sample(LETTERS, n, replace = TRUE)
                        # n numbers, [x]xx, zero padded
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
                , paste(ricd10(sample.int(nmultiple, 1)), collapse = ";")
            )

        }

        retval
    }

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
            Diagnosis_ICD_1 = tstrsplit(
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

#' Create age band looks for aa and esp
#'
#'
create_lu_ageband <- function() {

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
example_analysis <- function(
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
            lu_aac_icd10 %>%
                merge(
                    aa_versions %>% filter(Version == "aaf_2017_phe")
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
            aa_fractions %>% filter(analysis_type == "morbidity")
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
            , (pos == 1) | (icd10 %like% "^[VWXY]")
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

    methods <- bind_rows(
        methods__broad
        , methods__narrow
        , methods__specific
    )

}
