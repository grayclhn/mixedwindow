    library(testthat)
    library(xtable)
    filename <- tempfile(fileext = ".db")

    data(longley)
    test_that("booktabs executes at all", {
      expect_that(booktabs(longley), is_a("character"))
    })

    test_that("Columns that are labeled 'numberformat' are formatted", {
      d <- data.frame(x = c(-1.324, 0.93), y = c(10.443, 1.235))
      expect_that(booktabs(d, numberformat = TRUE, 
                           purgeduplicates = FALSE, digits = 2, align = "c"),
        prints_text("\\$\\\\\\\\\\!\\\\\\\\\\!-1.32\\$ & \\$10.44\\$"))
      expect_that(booktabs(d, numberformat = TRUE,
                           purgeduplicates = FALSE, digits = 2, align = "c"),
        prints_text("\\$\\\\\\\\enskip0.93\\$ & \\$\\\\\\\\enskip1.24\\$"))
    })

    test_that("Argument checking works as expected", {
      expect_that(booktabs(longley, drop = "WXYZ"),
        gives_warning("'drop' contains some columns not in 'dframe'"))
    })
