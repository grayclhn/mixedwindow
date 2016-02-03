    library(testthat)
    data(chickwts)
    chickwts$feed <- as.character(chickwts$feed)
    test_that("insert and select work", {
          expect_that(chickwts, is_equivalent_to(select(chickwts)))
              testdbfile <- tempfile(fileext = ".db")
              testdbframe <- dbframe("select1", testdbfile)
              clear(testdbframe)
          insert(testdbframe) <- chickwts
          expect_that(chickwts, is_equivalent_to(select(testdbframe)))
              unlink(testdbfile)})
    test_that("column renaming scheme works", {
          expect_that(
            c("feed", "AverageWeight"),
            is_identical_to(names(select(chickwts,
                 c(AverageWeight = "avg(weight)"), group.by = "feed"))))
              testdbfile <- tempfile(fileext = ".db")
              testdbframe <- dbframe("select1", testdbfile)
              clear(testdbframe)
          insert(testdbframe) <- chickwts
          expect_that(
            c("feed", "AverageWeight"),
            is_identical_to(names(select(testdbframe,
                 c(AverageWeight = "avg(weight)"), group.by = "feed"))))
              unlink(testdbfile)})
    ## test_that("joins work", {
    ##           testdbfile <- tempfile(fileext = ".db")
    ##           testdbframe <- dbframe("select1", testdbfile)
    ##           clear(testdbframe)
    ##       expect_that(select(list(A = chickwts,B =  chickwts),
    ##                       c("feed", weightA = "A.weight", weightB = "B.weight"),
    ##                       using = "feed", order.by = c("feed", "weightA", "weightB")),
    ##                   equals({
    ##                     d <- merge(chickwts, chickwts, by = "feed",
    ##                                                            suffixes = c("A", "B"))
    ##                     d$feed <- as.character(d$feed)
    ##                     d[do.call(order, d),]
    ##                   }, check.attributes = FALSE))

    ##       avgwts <- dbframe("select2", dbname = testdbfile, clear = TRUE,
    ##                          data = select(chickwts, c(averageweight = "avg(weight)"),
    ##                                                   group.by = c(thefeed = "feed")))
    ##       expect_that(select(list(a = chickwts, b = avgwts),
    ##                          c("feed", "weight", "averageweight"),
    ##                          on = ("feed = thefeed"), order.by = "feed, weight"),
    ##                   equals({
    ##                     d <- merge(chickwts, select(avgwts), by.x = "feed",
    ##                                                                  by.y = "thefeed")
    ##                     d$feed <- as.character(d$feed)
    ##                     d[do.call(order, d),]
    ##                   }, check.attributes = FALSE))
    ##           unlink(testdbfile)})
