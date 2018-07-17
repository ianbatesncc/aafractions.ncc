#
# test_reconstruct
#

context("reconstruct")
library("aafractions.ncc")

test_that("reconstruct works", {

    t1 <- reconstruct(verbose = FALSE)

    expect_is(t1, "data.frame")

})

test_that("reconstruct all versions and types", {

    these_versions <- eval(formals(reconstruct)[[1]])
    # c("aaf_2017_phe", "aaf_2014_ljucph", "aaf_2008_ljucph", "aaf_2007_ni39")
    these_analysistypes <- eval(formals(reconstruct)[[2]])
    # c("morbidity", "mortality")

    t2 <- merge(
        data.frame(
            this_version = these_versions
            , stringsAsFactors = FALSE
        )
        , data.frame(
            this_analysistype = these_analysistypes
            , stringsAsFactors = FALSE
        )
    ) %>% mutate(tname = paste(this_version, this_analysistype, sep = "__")) %>%
    {mapply(
        function(v0, v1, v2){list(reconstruct(v1, v2, verbose = FALSE))}
        , .$tname, .$this_version, .$this_analysistype
    )}

    expect_length(t2, length(these_versions) * length(these_analysistypes))



})
