#
# data_raw.R
#
# Process raw data
#

source("./data-raw/extract_lus.R")
source("./data-raw/expand_diagnoses.R")

extract_data_raw <- function(bWriteCSV = TRUE) {
    main__extract_lus(bWriteCSV = bWriteCSV)
    main__expand_diagnoses(bWriteCSV = bWriteCSV)
}

extract_data_raw()
