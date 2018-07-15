#
# test_reconstruct
#

context("reconstruct")
library("aafractions.ncc")

test_that("reconstruct works", {

    t1 <- reconstruct()

    expect_true("data.frame" %in% class(t1))

    t2 <- purrr::cross(list(
        x = c("aaf_2017_phe", "aaf_2014_ljucph", "aaf_2008_ljucph", "aaf_2007_ni39")
        , y = c("morbidity", "mortality")
    )) %>%
        lapply(function(l){
            cat("INFO: (x, y) =(", paste(l$x, l$y, sep = ", "), ")", "\n")
            reconstruct(l$x, l$y)
        })

    expect_length(t2, 8)

})
