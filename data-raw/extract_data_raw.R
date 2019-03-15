#
# data_raw.R
#
# Process raw data
#

source("./data-raw/extract_lus.R")
source("./data-raw/expand_diagnoses.R")

#' Extract and expand
#'
#' @param bWriteCSV (logical) to save or not
#'
extract_data_raw <- function(bWriteCSV = TRUE) {
    rv <- main__extract_lus(bWriteCSV = bWriteCSV)
    main__expand_diagnoses(rv, bWriteCSV = bWriteCSV)
}

# extract_data_raw(bWriteCSV = FALSE)
extract_data_raw(bWriteCSV = TRUE)
