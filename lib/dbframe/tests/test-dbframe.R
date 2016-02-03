    library(testthat)

    data(morley)
    filename <- tempfile(fileext = ".db")

    test_that("Basic constructor works", {
      d1 <- dbframe("test1", dbname = filename, data = morley)
      expect_that(d1, is_a("dbframe_sqlite"))
      expect_that(morley, is_equivalent_to(select(d1)))
    })

    test_that("Simple methods work", {
      d1 <- dbframe("test2", dbname = filename, data = morley)
      expect_that(nrow(morley), equals(nrow(d1)))
    })
