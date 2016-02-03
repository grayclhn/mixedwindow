    library(testthat)
    filename <- tempfile(fileext = ".db")

    data(morley)
    test_that("head and tail return the right number of records", {
      dbf <- dbframe("tab1", dbname = filename, data = morley)
      expect_that(nrow(head(dbf)), equals(6))
      expect_that(nrow(tail(dbf)), equals(6))
  
      nrec <- sample(1:nrow(morley), 1)
      expect_that(nrow(head(dbf, nrec)), equals(nrec))
      expect_that(nrow(tail(dbf, nrec)), equals(nrec))

      expect_that(nrow(head(dbf, -nrec)), equals(nrow(morley) - nrec))
      expect_that(nrow(tail(dbf, -nrec)), equals(nrow(morley) - nrec))
    })
