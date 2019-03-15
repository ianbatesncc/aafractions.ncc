#
# Create tables
#

# Create the lu__uid_cid table

require("aafractions.ncc")
require("dplyr")

#' expand len3 icd10
#'
#' @param x (character) of the form Axx
#'
#' @return (character vector) expand Axx{, 0, 1, ..., 9, X}
#'
expand_icd10 <- function(x) {
    if (!grepl("^[A-Z][0-9]{2}$", x))
        stop("x not of expected format ^[A-Z][0-9]{2}$")
    paste0(x, c(seq(0, 9), "X", ""))
}

#' Generate sequence of icd10 codes
#'
#' Enumerate a sequence of icd10 codes given a start and and end range.
#'
#' @param i1 (character) Axx[x]
#' @param i2 (character) Byy[y]
#' @param len (integer)
#'
#' @details
#'
#' When endpoints are different, or
#'
#' @return (character string) sequence of icd10 codes
#'
#' @examples
#' seq_icd10("A00", "A01")
#' seq_icd10("A00", "A01", len = 4)
#'
seq_icd10 <- function(i1, i2, len = 3) {
    chr2asc <- function(x) {as.numeric(charToRaw(x))}
    asc2chr <- function(x) {rawToChar(as.raw(x))}

    ij <- sort(c(i1, i2))
    i1 <- ij[1]
    i2 <- ij[2]

    ncj <- nchar(ij)

    len_default <- 3
    len_auto <- max(ncj)

    if (missing(len))
        len <- max(len_default, len_auto)

    if (any(ncj < len) | any(diff(ncj) != 0))
        cat(
            "WARNING: seq_icd10: "
            , "sequence end points different lengths to specified len "
            , "... odd results may occur"
            , "\n"
        )

    vmin <- 0
    vmax <- 10^(len - 1) - 1 # 99 or 999


    if (ncj[1] < len)
        i1 <- paste0(i1, rep("0", len - ncj[1]))

    if (ncj[2] < len)
        i2 <- paste0(i2, rep("9", len - ncj[2]))

    v1 <- as.numeric(substr(i1, 2, len))
    v2 <- as.numeric(substr(i2, 2, len))

    c1 <- chr2asc(substr(i1, 1, 1))
    c2 <- chr2asc(substr(i2, 1, 1))
    cs <- seq(c1, c2)

    purrr::cross_df(
        list(c = cs, n = seq(vmin, vmax))
    ) %>%
        mutate(
            todrop = (
                (c == c1) & (n < v1)
            ) | (
                (c == c2) & (n > v2)
            )
        ) %>%
        filter(!todrop) %>%
        arrange(c, n) %>%
        mutate(
            cc = sapply(c, asc2chr)
            , nn = formatC(n, flag = 0, width = len - 1)
            , icd10 = paste0(cc, nn)
        ) %>%
        .$icd10
}

#' Truncate a string to a maximum length
#'
#' @param s (character, possibly vector) string(s) to manipulate
#' @param n (integer) maximum length of string)
#' @param suffix (character) truncation indicator
#'
ensure_max_len <- function(s, n = 80, suffix = " ...") {
    nsuffix = nchar(suffix)

    ns <- nchar(s)

    is <- which(ns > n)

    s[is] <- paste0(substr(s[is], 1, n - nsuffix), suffix)

    s
}

#' Expand icd10 codes
#'
#' Expand a list of codes to individual rows.  Can be separated by semicolons,
#' specified by range, length 3 or length 4, with exclusions applied
#'
#' @param x (data.frame) condition_uid and compact_icd columns
#' @param name (character) start of file/variable name
#' @param suffix (character) suffix to add to variable
#' @param bWriteCSV (bool) if TRUE then save .csv and pacakge .rda
#'
#' @details
#'
#' The final variable name is \code{name_suffix}, or just \code{name} if
#' \code{suffix} is \code{NULL}.
#'
#' @return (data.frame) diagnosis code to condition_uid lookup
#'
expand_diagnoses <- function(
    x
    , name = "lu_uid_icd"
    , suffix = NULL
    , bWriteCSV = FALSE
) {
    if (!is.data.frame(x))
        stop("Expecting data.frame")

    names(x) <- c("condition_uid", "codes")

    # Clean the codes string for later parsing

    t2 <- x %>%
        mutate(
            # ", " separators to ";"
            c2 = gsub(", {1,}([A-Z])", ";\\1", codes)

            # "..[0-9][, ][A-Z]" separators to ";"
            # ... care about e.g. J81X;
            # Xnnn,Ynnn -> Xnnn;Ynnn
            # Xnnn Ynnn -> Xnnn;Ynnn
            , c2 = gsub("([0-9]), *([A-Z])", "\\1;\\2", c2)
            , c2 = gsub("([0-9]) {1,}([A-Z])", "\\1;\\2", c2)

            # "[0-9]{2}.[0-9]" remove "."
            , c2 = gsub("([0-9]{2})\\.([0-9])", "\\1\\2", c2)

            # Trailing "." (end of sentence not part of icd code)
            , c2 = gsub("\\.$", "", c2)

            # : 0.1-0.2 ->  (.1 - .2)
            , c2 = gsub(": 0(\\.[0-9]) *- *0(\\.[0-9])", " (\\1 -\\2)", c2)

            # V120-122 -> V120-V122
            , c2 = gsub("([A-Z])([0-9]{3})-([0-9]{3})", "\\1\\2-\\1\\3", c2)

            # " (excl. K854)" -> ;-K854
            , c2 = gsub(" \\(excl\\. ([A-Z][0-9]{2,3})\\)", ";-\\1", c2)

            # some remaining spaces : "; " -> ";"
            , c2 = gsub("; {1,}", ";", c2)
        )

    t3 <- t2 %>%
        # expand string of codes separated by ";" into individual rows
        split(.$condition_uid) %>%
        purrr::map_dfr(function(x) {
            this_cuid <- unique(x$condition_uid)
            these_codes <- strsplit(x$c2, ";")[[1]]
            t0 <- data.frame(
                condition_uid = this_cuid
                , icd10 = these_codes
                , stringsAsFactors = FALSE
            )
        }) %>%
        # expand each individual code.  Complex.
        split(list(.$condition_uid, .$icd10), drop = TRUE) %>%
        purrr::map_dfr(function(x) {
            this_cuid <- x$condition_uid
            this_icd10 <- x$icd10
            len <- nchar(this_icd10)

            # loop through further cases

            these_codes <- this_icd10

            torm = FALSE

            if (grepl("^-", this_icd10)) {
                cat("INFO: to REMOVE:", this_cuid, this_icd10, "\n")
                torm = TRUE
                this_icd10 <- sub("^-", "", this_icd10)
            }

            if (grepl("^[A-Z][0-9]{3}$", this_icd10)) {
                # E244
                these_codes <- this_icd10

            } else if (grepl("^[A-Z][0-9]{2}$", this_icd10)) {
                # F10 -> F10{0, 1, 2, ... 9, X, }
                these_codes <- expand_icd10(this_icd10)

            } else if (grepl("^[A-Z][0-9]{2}-[A-Z][0-9]{2}$", this_icd10)) {
                # C18-C20 -> C{18, ..., 20}{0, 1, 2, ... 9, X, }
                these_codes <- seq_icd10(
                    substr(this_icd10, 1, 3), substr(this_icd10, 5, 7)
                ) %>%
                    purrr::map(expand_icd10) %>%
                    unlist()

            } else if (grepl("^[A-Z][0-9]{0,1}$", this_icd10)) {
                # F -> F00-F99, W0 -> W00-W09
                icd10_v <- seq(1, 2) %>%
                    sapply(
                        function(i, x, y) {
                            paste0(c(x, rep(y[i], 2 - nchar(x) + 1)), collapse = "")
                        }
                        , x = this_icd10
                        , y = c("0", "9")
                    )

                these_codes <- seq_icd10(icd10_v[1], icd10_v[2]) %>%
                    purrr::map(expand_icd10) %>%
                    unlist()

            } else if (grepl("^[A-Z][0-9]{3}-[A-Z][0-9]{3}$", this_icd10)) {
                # I690-I692 -> {I690, ... I692}
                icd10_v <- unlist(strsplit(this_icd10, split = "-"))
                these_codes <- seq_icd10(icd10_v[1], icd10_v[2], len = 4)

            } else if (grepl("^[A-Z][0-9]{0,2}-[A-Z][0-9]{0,2}$", this_icd10)) {
                # W1-W19 -> W10-W19 (W10-W19 case caught above)
                icd10_v <- seq(1, 2) %>%
                    sapply(
                        function(i, x, y) {
                            paste0(c(x[i], rep(y[i], 2 - nchar(x[i]) + 1)), collapse = "")
                        }
                        , x = unlist(strsplit(this_icd10, split = "-"))
                        , y = c("0", "9")
                    )

                these_codes <- seq_icd10(icd10_v[1], icd10_v[2]) %>%
                    purrr::map(expand_icd10) %>%
                    unlist()

            } else if (
                grepl(
                    paste0(
                        "^[A-Z][0-9]{2}-[A-Z][0-9]{2}"
                        , " "
                        , "\\(\\.[0-9]((,)|( *-)) *\\.[0-9]\\)$"
                    )
                    , this_icd10
                )
            ) {
                # V20-V28 (.3 -.9) -> {V20-V28}{3 ... 9} # range
                # V02-V04 (.1, .9) -> {V02-V04}{1,    9} # set
                these_subcodes <- this_icd10 %>%
                    regmatches(gregexpr("\\.[0-9]{1}", .)) %>%
                    unlist() %>%
                    gsub("^\\.", "", .) %>%
                    as.numeric()

                if (!grepl(", ", this_icd10))
                    # range NOT set
                    these_subcodes <- seq(
                        min(these_subcodes), max(these_subcodes)
                    )

                these_codes <- seq_icd10(
                    substr(this_icd10, 1, 3), substr(this_icd10, 5, 7)
                ) %>%
                    purrr::map(expand_icd10) %>%
                    unlist() %>%
                    .[substr(., 4, 4) %in% these_subcodes]

            } else {
                cat("WARNING: unhandled case:", this_cuid, this_icd10, "\n")
            }

            if (torm == TRUE)
                cat("INFO: to REMOVE:", this_cuid, paste(these_codes, sep = ", "), "\n")

            data.frame(
                condition_uid = this_cuid
                , icd10_orig = this_icd10
                , icd10 = these_codes
                , torm = torm
                , stringsAsFactors = FALSE
            )
        })

    t4 <- t3 %>%
        # remove the exclusions from each condition
        split(.$condition_uid) %>%
        purrr::map_dfr(function(x) {
            these_codes_torm <- filter(x, torm == TRUE) %>% .$icd10
            filter(x, torm == FALSE, !(icd10 %in% these_codes_torm)) %>%
                select(condition_uid, icd10)
        })

    # save

    if (bWriteCSV) {
        this_stub <- paste(c(name, suffix), collapse = "_")
        this_csv <- paste0("./data-raw/", this_stub, ".csv")

        #' Wrapper to use_data to save variable with given name
        #'
        #' @param x (R object)
        #' @param varname (character) name to save the variable as
        #'
        #' @return invisible()
        #'
        use_data2 <- function(x, varname) {
            assign(varname, x)
            eval(parse(text = paste0(
                "usethis::use_data("
                , varname
                , ", overwrite = TRUE"
                , ")"
            )))
            rm(list = varname)
            invisible()
        }

        cat("INFO: saving", this_csv, "...", "\n")
        data.table::fwrite(t4, this_csv)

        #usethis::use_data(lu_aac_icd10, overwrite = TRUE)
        use_data2(t4, this_stub)

    }

    t4
}

#' Do the business

main__expand_diagnoses <- function(
    what = c("aa", "sa", "uc", "ac")
    , bWriteCSV = TRUE
) {
    what <- match.arg(what, several.ok = TRUE)

    rv <- list()

    if ("aa" %in% what) {
        rv[["aa"]] <- expand_diagnoses(
            aafractions.ncc::aa_conditions %>%
                select(condition_uid, codes)
            , name = "lu_aac_icd10"
            , suffix = NULL
            , bWriteCSV = bWriteCSV
        )
    }

    if ("sa" %in% what) {
        rv[["sa"]] <- expand_diagnoses(
            aafractions.ncc::sa_conditions %>%
                select(condition_uid, icd_10_code)
            , name = "lu_sac_icd10"
            , suffix = NULL
            , bWriteCSV = bWriteCSV
        )
    }

    if ("uc" %in% what) {
        rv[["uc"]] <- expand_diagnoses(
            aafractions.ncc::uc_conditions %>%
                select(condition_uid, primary_diagnosis)
            , name = "lu_ucc_icd10"
            , suffix = NULL
            , bWriteCSV = bWriteCSV
        )
    }

    invisible(rv)
}

